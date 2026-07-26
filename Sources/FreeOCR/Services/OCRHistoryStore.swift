import Foundation
import OSLog

struct OCRHistorySnapshot: Sendable {
    let id: UUID
    let createdAt: Date
    let sourceURL: URL
    let displayName: String
    let task: OCRTask
    let result: OCRResponse
    let jsonText: String
    let recordDirectoryURL: URL
}

actor OCRHistoryStore {
    private struct Manifest: Codable {
        let schemaVersion: Int
        let id: UUID
        let createdAt: Date
        let displayName: String
        let originalFileName: String
        let sourcePath: String
        let task: OCRTask
        let result: OCRResponse
    }

    private let rootDirectory: URL
    private let logger = Logger(subsystem: "com.scorpiodai.FreeOCR", category: "History")

    init(rootDirectory: URL = ResourceLocator.historyDirectory) {
        self.rootDirectory = rootDirectory
    }

    func loadAll() throws -> [OCRHistorySnapshot] {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let recordDirectories = try fileManager.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var snapshots: [OCRHistorySnapshot] = []
        for directory in recordDirectories {
            guard (try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
            let manifestURL = directory.appending(path: "record.json")
            guard fileManager.fileExists(atPath: manifestURL.path) else { continue }
            do {
                let manifest = try Self.decoder.decode(Manifest.self, from: Data(contentsOf: manifestURL))
                guard manifest.schemaVersion == 1 else {
                    logger.error("Skipped unsupported history schema in \(directory.lastPathComponent, privacy: .public)")
                    continue
                }
                snapshots.append(try snapshot(from: manifest, in: directory))
            } catch {
                logger.error("Skipped unreadable history record \(directory.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        return snapshots.sorted { $0.createdAt > $1.createdAt }
    }

    func save(
        id: UUID,
        sourceURL: URL,
        displayName: String,
        task: OCRTask,
        result: OCRResponse
    ) throws -> OCRHistorySnapshot {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        let createdAt = Date()
        let finalDirectory = uniqueRecordDirectory(displayName: displayName, createdAt: createdAt)
        let temporaryDirectory = rootDirectory.appending(
            path: ".pending-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )

        do {
            let sourceDirectory = temporaryDirectory.appending(path: "Source", directoryHint: .isDirectory)
            let previewsDirectory = temporaryDirectory.appending(path: "Previews", directoryHint: .isDirectory)
            try fileManager.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: previewsDirectory, withIntermediateDirectories: true)

            let sourceFileName = safeFileName(sourceURL.lastPathComponent, fallback: "original")
            let sourceRelativePath = "Source/\(sourceFileName)"
            try fileManager.copyItem(
                at: sourceURL,
                to: temporaryDirectory.appending(path: sourceRelativePath)
            )

            var persistedPages: [OCRPage] = []
            for page in result.pages {
                let previewURL = URL(fileURLWithPath: page.previewPath)
                guard fileManager.fileExists(atPath: previewURL.path) else {
                    throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: previewURL.path])
                }
                let rawExtension = previewURL.pathExtension.lowercased()
                let fileExtension = rawExtension.isEmpty ? "png" : rawExtension
                let previewName = String(format: "page-%03d.%@", page.index + 1, fileExtension)
                let relativePath = "Previews/\(previewName)"
                try fileManager.copyItem(
                    at: previewURL,
                    to: temporaryDirectory.appending(path: relativePath)
                )
                persistedPages.append(Self.page(page, previewPath: relativePath))
            }

            let persistedResult = Self.result(result, pages: persistedPages)
            let manifest = Manifest(
                schemaVersion: 1,
                id: id,
                createdAt: createdAt,
                displayName: displayName,
                originalFileName: sourceURL.lastPathComponent,
                sourcePath: sourceRelativePath,
                task: task,
                result: persistedResult
            )
            try Data(persistedResult.markdown.utf8).write(
                to: temporaryDirectory.appending(path: "result.md"),
                options: .atomic
            )
            try Self.resultEncoder.encode(persistedResult).write(
                to: temporaryDirectory.appending(path: "result.json"),
                options: .atomic
            )
            try Self.encoder.encode(manifest).write(
                to: temporaryDirectory.appending(path: "record.json"),
                options: .atomic
            )
            try fileManager.moveItem(at: temporaryDirectory, to: finalDirectory)
            logger.info("Saved OCR history record \(finalDirectory.lastPathComponent, privacy: .public)")
            return try snapshot(from: manifest, in: finalDirectory)
        } catch {
            try? fileManager.removeItem(at: temporaryDirectory)
            throw error
        }
    }

    func delete(recordDirectory: URL) throws {
        let root = rootDirectory.standardizedFileURL
        let candidate = recordDirectory.standardizedFileURL
        guard candidate.deletingLastPathComponent() == root else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSFilePathErrorKey: candidate.path])
        }
        if FileManager.default.fileExists(atPath: candidate.path) {
            try FileManager.default.removeItem(at: candidate)
            logger.info("Deleted OCR history record \(candidate.lastPathComponent, privacy: .public)")
        }
    }

    private func snapshot(from manifest: Manifest, in directory: URL) throws -> OCRHistorySnapshot {
        let sourceURL = directory.appending(path: manifest.sourcePath)
        let pages = manifest.result.pages.map { page in
            let path = page.previewPath.hasPrefix("/")
                ? page.previewPath
                : directory.appending(path: page.previewPath).path
            return Self.page(page, previewPath: path)
        }
        let resolvedResult = Self.result(manifest.result, pages: pages)
        return OCRHistorySnapshot(
            id: manifest.id,
            createdAt: manifest.createdAt,
            sourceURL: sourceURL,
            displayName: manifest.displayName,
            task: manifest.task,
            result: resolvedResult,
            jsonText: String(decoding: try Self.resultEncoder.encode(resolvedResult), as: UTF8.self),
            recordDirectoryURL: directory
        )
    }

    private func uniqueRecordDirectory(displayName: String, createdAt: Date) -> URL {
        let baseName = "\(safeFileName(displayName, fallback: "OCR"))_\(Self.timestampFormatter.string(from: createdAt))"
        var candidate = rootDirectory.appending(path: baseName, directoryHint: .isDirectory)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = rootDirectory.appending(path: "\(baseName)_\(suffix)", directoryHint: .isDirectory)
            suffix += 1
        }
        return candidate
    }

    private func safeFileName(_ value: String, fallback: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\").union(.controlCharacters)
        let components = value.components(separatedBy: invalid).filter { !$0.isEmpty }
        let cleaned = components.joined(separator: "-")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        let limited = String(cleaned.prefix(120))
        return limited.isEmpty ? fallback : limited
    }

    private static func page(_ page: OCRPage, previewPath: String) -> OCRPage {
        OCRPage(
            index: page.index,
            width: page.width,
            height: page.height,
            markdown: page.markdown,
            text: page.text,
            previewPath: previewPath,
            blocks: page.blocks
        )
    }

    private static func result(_ result: OCRResponse, pages: [OCRPage]) -> OCRResponse {
        OCRResponse(
            id: result.id,
            model: result.model,
            task: result.task,
            languageMode: result.languageMode,
            markdown: result.markdown,
            text: result.text,
            pages: pages
        )
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()

    private static let resultEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}
