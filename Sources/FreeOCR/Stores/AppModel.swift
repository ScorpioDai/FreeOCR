import AppKit
import Foundation
import Observation
import OSLog
import UniformTypeIdentifiers

enum ModelServiceState: Equatable {
    case stopped
    case starting
    case loading
    case ready
    case failed(String)

    func label(language: AppLanguage, modelName: String) -> String {
        switch (self, language) {
        case (.stopped, .chinese): "服务未启动"
        case (.stopped, .english): "Service stopped"
        case (.starting, .chinese): "正在启动本地服务"
        case (.starting, .english): "Starting local service"
        case (.loading, .chinese): "正在加载 \(modelName)"
        case (.loading, .english): "Loading \(modelName)"
        case (.ready, .chinese): "模型已就绪"
        case (.ready, .english): "Model ready"
        case (.failed, .chinese): "模型加载失败"
        case (.failed, .english): "Model load failed"
        }
    }
}

@Observable
@MainActor
final class AppModel {
    private enum DefaultsKey {
        static let apiPort = "apiPort"
        static let allowLAN = "allowLAN"
        static let apiKey = "apiKey"
        static let autoRecognize = "autoRecognize"
        static let appLanguage = "appLanguage"
    }

    private let importLogger = Logger(subsystem: "com.scorpiodai.FreeOCR", category: "Import")
    private let recognitionLogger = Logger(subsystem: "com.scorpiodai.FreeOCR", category: "Recognition")
    private let serviceProcess = OCRServiceProcess()
    @ObservationIgnored private lazy var historyStore = OCRHistoryStore()
    private var client: OCRClient?
    private var pendingRecognitionIDs: [UUID] = []
    private var isDrainingQueue = false
    private var didLaunch = false

    var documents: [OCRDocument] = []
    var selectedDocumentID: UUID?
    var serviceState: ModelServiceState = .stopped
    var resultViewMode: ResultViewMode = .preview
    var isDropTargeted = false
    var lastError: String?
    var showsRescanConfirmation = false
    private var pendingRescanID: UUID?

    var apiPort: Int {
        didSet { UserDefaults.standard.set(apiPort, forKey: DefaultsKey.apiPort) }
    }
    var allowLAN: Bool {
        didSet { UserDefaults.standard.set(allowLAN, forKey: DefaultsKey.allowLAN) }
    }
    var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: DefaultsKey.apiKey) }
    }
    var autoRecognize: Bool {
        didSet { UserDefaults.standard.set(autoRecognize, forKey: DefaultsKey.autoRecognize) }
    }
    var appLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: DefaultsKey.appLanguage) }
    }
    init() {
        let defaults = UserDefaults.standard
        let storedPort = defaults.integer(forKey: DefaultsKey.apiPort)
        self.apiPort = storedPort == 0 ? 8766 : storedPort
        self.allowLAN = defaults.object(forKey: DefaultsKey.allowLAN) as? Bool ?? false
        self.apiKey = defaults.string(forKey: DefaultsKey.apiKey) ?? ""
        self.autoRecognize = defaults.object(forKey: DefaultsKey.autoRecognize) as? Bool ?? true
        self.appLanguage = AppLanguage(rawValue: defaults.string(forKey: DefaultsKey.appLanguage) ?? "") ?? .chinese
    }

    var selectedDocument: OCRDocument? {
        guard let selectedDocumentID else { return nil }
        return documents.first { $0.id == selectedDocumentID }
    }

    var localAPIURL: String {
        "http://127.0.0.1:\(apiPort)/v1/ocr"
    }

    var historyDirectoryPath: String {
        "~/Documents/FreeOCR"
    }

    var lanAPIURL: String {
        let address = NetworkAddress.localIPv4 ?? text("<本机局域网 IP>", "<local LAN IP>")
        return "http://\(address):\(apiPort)/v1/ocr"
    }

    var currentModelName: String {
        "PP-OCRv6 medium · ONNX"
    }

    var languageDescription: String {
        text(
            "统一多语言（50 种，无需选择）",
            "Unified multilingual (50 languages; no selection required)"
        )
    }

    func text(_ chinese: String, _ english: String) -> String {
        appLanguage == .chinese ? chinese : english
    }

    func launch() async {
        guard !didLaunch else { return }
        didLaunch = true
        await startService()
        await restoreHistory()
    }

    private func restoreHistory() async {
        do {
            let snapshots = try await historyStore.loadAll()
            let existingDirectories = Set(documents.compactMap { $0.historyDirectoryURL?.standardizedFileURL.path })
            for snapshot in snapshots where !existingDirectories.contains(snapshot.recordDirectoryURL.standardizedFileURL.path) {
                documents.append(
                    OCRDocument(
                        sourceURL: snapshot.sourceURL,
                        id: snapshot.id,
                        displayName: snapshot.displayName,
                        createdAt: snapshot.createdAt,
                        task: snapshot.task,
                        status: .completed,
                        result: snapshot.result,
                        jsonText: snapshot.jsonText,
                        historyDirectoryURL: snapshot.recordDirectoryURL
                    )
                )
            }
            sortDocumentsNewestFirst()
            if selectedDocumentID == nil {
                selectedDocumentID = documents.first?.id
            }
            recognitionLogger.info("Restored \(snapshots.count, privacy: .public) OCR history record(s)")
        } catch {
            lastError = text("无法读取历史记录：", "Could not load history: ") + error.localizedDescription
            recognitionLogger.error("History restore failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func startService() async {
        serviceState = .starting
        client = nil
        do {
            try serviceProcess.start(
                configuration: .init(
                    host: allowLAN ? "0.0.0.0" : "127.0.0.1",
                    port: apiPort,
                    apiKey: apiKey
                )
            )
            let newClient = OCRClient(port: apiPort, apiKey: apiKey)
            client = newClient

            for _ in 0..<240 {
                if !serviceProcess.isRunning {
                    throw ServiceLaunchError.missingService
                }
                do {
                    let health = try await newClient.health()
                    switch health.status {
                    case "ready":
                        serviceState = .ready
                        recognitionLogger.info("OCR engine ready: \(health.model, privacy: .public)")
                        startQueueIfNeeded()
                        return
                    case "failed":
                        throw RuntimeServiceError.modelFailed(health.error ?? text("未知模型错误", "Unknown model error"))
                    default:
                        serviceState = .loading
                    }
                } catch let error as RuntimeServiceError {
                    throw error
                } catch {
                    if serviceState != .loading { serviceState = .starting }
                }
                try await Task.sleep(for: .milliseconds(500))
            }
            throw RuntimeServiceError.timeout
        } catch {
            let message = localizedError(error)
            serviceState = .failed(message)
            lastError = message
            recognitionLogger.error("Service start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func restartService() async {
        serviceProcess.stop()
        serviceState = .stopped
        await startService()
    }

    func shutdown() {
        serviceProcess.stop()
        serviceState = .stopped
    }

    func openImportPanel() {
        importDocuments(FilePanelService.chooseDocuments(language: appLanguage))
    }

    func revealHistoryDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: ResourceLocator.historyDirectory,
                withIntermediateDirectories: true
            )
            NSWorkspace.shared.activateFileViewerSelecting([ResourceLocator.historyDirectory])
        } catch {
            lastError = text("无法打开历史记录文件夹：", "Could not open the history folder: ") + error.localizedDescription
        }
    }

    func importDocuments(_ urls: [URL]) {
        let accepted = urls.filter(Self.isSupportedDocument)
        guard !accepted.isEmpty else {
            lastError = text(
                "请选择 PDF、PNG、JPEG、HEIC、HEIF、TIFF、BMP、GIF 或 WebP 文件。",
                "Choose a PDF, PNG, JPEG, HEIC, HEIF, TIFF, BMP, GIF, or WebP file."
            )
            return
        }

        for url in accepted {
            let document = OCRDocument(sourceURL: url)
            documents.insert(document, at: 0)
            selectedDocumentID = document.id
            importLogger.info("Imported document type \(url.pathExtension.lowercased(), privacy: .public)")
            if autoRecognize {
                enqueueRecognition(document.id)
            }
        }
    }

    func importRemoteURL(_ url: URL) async {
        guard url.scheme == "http" || url.scheme == "https" else {
            importDocuments([url])
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let suggested = response.suggestedFilename ?? url.lastPathComponent
            let ext = URL(fileURLWithPath: suggested).pathExtension.isEmpty ? "png" : URL(fileURLWithPath: suggested).pathExtension
            let localURL = try persistDroppedData(data, fileExtension: ext)
            importDocuments([localURL])
        } catch {
            lastError = text("无法下载拖入的网页图片：", "Could not download the dropped web image: ") + error.localizedDescription
        }
    }

    func importImageData(_ data: Data, fileExtension: String = "png") {
        do {
            importDocuments([try persistDroppedData(data, fileExtension: fileExtension)])
        } catch {
            lastError = text("无法读取拖入的图片：", "Could not read the dropped image: ") + error.localizedDescription
        }
    }

    var copyActionTitle: String {
        resultViewMode.copyTitle(language: appLanguage)
    }

    var copyActionHelp: String {
        resultViewMode == .json
            ? text("复制当前文档的完整 JSON 结果", "Copy the complete JSON result for this document")
            : text("复制当前文档的完整 Markdown 结果", "Copy the complete Markdown result for this document")
    }

    func requestRecognitionSelected() {
        guard let selectedDocumentID,
              let document = documents.first(where: { $0.id == selectedDocumentID }) else { return }
        if document.status == .completed {
            pendingRescanID = selectedDocumentID
            showsRescanConfirmation = true
            recognitionLogger.info("Rescan confirmation requested")
        } else {
            enqueueRecognition(selectedDocumentID)
        }
    }

    func confirmRescan() {
        guard let pendingRescanID,
              let document = documents.first(where: { $0.id == pendingRescanID }) else { return }
        self.pendingRescanID = nil
        showsRescanConfirmation = false
        recognitionLogger.info("Rescan confirmed")
        if document.historyDirectoryURL != nil, document.result != nil {
            let rescannedDocument = OCRDocument(
                sourceURL: document.sourceURL,
                displayName: document.displayName,
                task: document.task
            )
            documents.insert(rescannedDocument, at: 0)
            selectedDocumentID = rescannedDocument.id
            enqueueRecognition(rescannedDocument.id)
        } else {
            enqueueRecognition(pendingRescanID)
        }
    }

    func cancelRescan() {
        pendingRescanID = nil
        showsRescanConfirmation = false
    }

    func removeSelected() {
        guard let selectedDocumentID,
              let document = documents.first(where: { $0.id == selectedDocumentID }) else { return }
        guard document.status != .recognizing else { return }

        if let directory = document.historyDirectoryURL {
            Task {
                do {
                    try await historyStore.delete(recordDirectory: directory)
                    removeDocumentFromMemory(selectedDocumentID)
                } catch {
                    lastError = text("无法删除历史记录：", "Could not delete the history record: ") + error.localizedDescription
                }
            }
        } else {
            removeDocumentFromMemory(selectedDocumentID)
        }
    }

    private func removeDocumentFromMemory(_ id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        pendingRecognitionIDs.removeAll { $0 == id }
        documents.remove(at: index)
        selectedDocumentID = documents.indices.contains(index) ? documents[index].id : documents.last?.id
    }

    func copyFullResult() {
        guard let document = selectedDocument, let result = document.result else { return }
        let text = resultViewMode == .json ? document.jsonText : result.markdown
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        recognitionLogger.info("Copied full OCR result")
    }

    func saveResult() {
        guard let document = selectedDocument, let result = document.result else { return }
        do {
            if resultViewMode == .json {
                try FilePanelService.save(
                    text: document.jsonText,
                    suggestedName: "\(document.displayName).json",
                    type: .json,
                    language: appLanguage
                )
            } else {
                try FilePanelService.save(
                    text: result.markdown,
                    suggestedName: "\(document.displayName).md",
                    type: UTType(filenameExtension: "md") ?? .plainText,
                    language: appLanguage
                )
            }
            recognitionLogger.info("Saved OCR result")
        } catch {
            lastError = text("保存失败：", "Save failed: ") + error.localizedDescription
        }
    }

    private func enqueueRecognition(_ id: UUID) {
        if !pendingRecognitionIDs.contains(id) {
            pendingRecognitionIDs.append(id)
        }
        if let document = documents.first(where: { $0.id == id }) {
            document.status = serviceState == .ready ? .queued : .waitingForModel
        }
        startQueueIfNeeded()
    }

    private func startQueueIfNeeded() {
        guard !isDrainingQueue, !pendingRecognitionIDs.isEmpty else { return }
        isDrainingQueue = true
        Task { await drainRecognitionQueue() }
    }

    private func drainRecognitionQueue() async {
        defer { isDrainingQueue = false }
        while !pendingRecognitionIDs.isEmpty {
            guard serviceState == .ready, let client else {
                for id in pendingRecognitionIDs {
                    documents.first(where: { $0.id == id })?.status = .waitingForModel
                }
                return
            }

            let id = pendingRecognitionIDs.removeFirst()
            guard let document = documents.first(where: { $0.id == id }) else { continue }
            document.status = .recognizing
            document.result = nil
            document.jsonText = ""
            document.clearHighlight()
            document.currentPage = 0
            document.resetRecognitionProgress()
            recognitionLogger.info("OCR started with PP-OCRv6 medium")
            do {
                var job = try await client.startRecognition(fileURL: document.sourceURL)
                document.apply(job: job)
                while job.status == "queued" || job.status == "running" {
                    try await Task.sleep(for: .milliseconds(500))
                    job = try await client.recognitionStatus(id: job.id)
                    document.apply(job: job)
                }

                if job.status == "failed" {
                    throw RuntimeServiceError.recognitionFailed(job.error ?? text("未知识别错误", "Unknown recognition error"))
                }
                guard let result = job.result else {
                    throw OCRClient.ClientError.invalidResponse
                }
                let jsonText = try await client.prettyJSON(for: result)
                document.progressStage = "saving_history"
                do {
                    let snapshot = try await historyStore.save(
                        id: document.id,
                        sourceURL: document.sourceURL,
                        displayName: document.displayName,
                        task: document.task,
                        result: result
                    )
                    document.sourceURL = snapshot.sourceURL
                    document.createdAt = snapshot.createdAt
                    document.historyDirectoryURL = snapshot.recordDirectoryURL
                    document.jsonText = snapshot.jsonText
                    document.result = snapshot.result
                    sortDocumentsNewestFirst()
                } catch {
                    document.jsonText = jsonText
                    document.result = result
                    lastError = text(
                        "识别已完成，但历史记录保存失败：",
                        "Recognition completed, but history could not be saved: "
                    ) + error.localizedDescription
                    recognitionLogger.error("History save failed: \(error.localizedDescription, privacy: .public)")
                }
                document.status = .completed
                recognitionLogger.info("OCR completed with \(result.pages.count, privacy: .public) page(s)")
            } catch {
                let message = localizedError(error)
                document.status = .failed(message)
                lastError = message
                recognitionLogger.error("OCR failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func persistDroppedData(_ data: Data, fileExtension: String) throws -> URL {
        let directory = ResourceLocator.cacheDirectory.appending(path: "Imports", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let safeExtension = fileExtension.lowercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let url = directory.appending(path: "web-image-\(UUID().uuidString).\(safeExtension.isEmpty ? "png" : safeExtension)")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func isSupportedDocument(_ url: URL) -> Bool {
        ["pdf", "png", "jpg", "jpeg", "heic", "heif", "tif", "tiff", "bmp", "gif", "webp"]
            .contains(url.pathExtension.lowercased())
    }

    private func sortDocumentsNewestFirst() {
        documents.sort { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func localizedError(_ error: Error) -> String {
        guard appLanguage == .english else { return error.localizedDescription }
        switch error {
        case RuntimeServiceError.timeout:
            return "The local OCR service timed out."
        case let RuntimeServiceError.modelFailed(message):
            return "Model load failed: \(message)"
        case let RuntimeServiceError.recognitionFailed(message):
            return "Recognition failed: \(message)"
        case ServiceLaunchError.missingPython:
            return "The bundled Python OCR runtime could not be found."
        case ServiceLaunchError.missingService:
            return "The FreeOCR API service script could not be found."
        case ServiceLaunchError.missingTraditionalDetectionModel:
            return "The PP-OCRv6 medium DET ONNX model could not be found."
        case ServiceLaunchError.missingTraditionalRecognitionModel:
            return "The PP-OCRv6 medium REC ONNX model could not be found."
        default:
            return error.localizedDescription
        }
    }
}

enum RuntimeServiceError: LocalizedError {
    case timeout
    case modelFailed(String)
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .timeout: "本地 OCR 服务启动超时。"
        case let .modelFailed(message): "模型加载失败：\(message)"
        case let .recognitionFailed(message): "识别失败：\(message)"
        }
    }
}
