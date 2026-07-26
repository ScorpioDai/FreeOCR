import Foundation

enum ResourceLocator {
    static var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var serviceScript: URL? {
        let candidates = [
            Bundle.main.resourceURL?.appending(path: "Runtime/freeocr_service.py"),
            projectRoot.appending(path: "Runtime/freeocr_service.py")
        ].compactMap { $0 }
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static var pythonExecutable: URL? {
        let candidates = [
            Bundle.main.resourceURL?.appending(path: "Runtime/python/bin/python3"),
            Bundle.main.resourceURL?.appending(path: "Runtime/venv/bin/python3"),
            projectRoot.appending(path: "Runtime/.venv/bin/python")
        ].compactMap { $0 }
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static var traditionalDetectionModelDirectory: URL? {
        onnxModelDirectory(
            bundledName: "PP-OCRv6_medium_det_onnx",
            environmentKey: "FREEOCR_TRADITIONAL_DET_PATH"
        )
    }

    static var traditionalRecognitionModelDirectory: URL? {
        onnxModelDirectory(
            bundledName: "PP-OCRv6_medium_rec_onnx",
            environmentKey: "FREEOCR_TRADITIONAL_REC_PATH"
        )
    }

    static var bundledModelsRoot: URL? {
        Bundle.main.resourceURL?.appending(path: "Models")
    }

    private static func onnxModelDirectory(bundledName: String, environmentKey: String) -> URL? {
        if let bundled = Bundle.main.resourceURL?.appending(path: "Models/\(bundledName)"),
           isONNXModelDirectory(bundled) {
            return bundled
        }
        if let override = ProcessInfo.processInfo.environment[environmentKey] {
            let url = URL(fileURLWithPath: override)
            if isONNXModelDirectory(url) { return url }
        }
        return siblingModel(containing: bundledName, validator: isONNXModelDirectory)
    }

    private static func siblingModel(containing name: String, validator: (URL) -> Bool) -> URL? {
        let parent = projectRoot.deletingLastPathComponent()
        let children = (try? FileManager.default.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return children.first { url in
            url.lastPathComponent.localizedCaseInsensitiveContains(name)
                && validator(url)
        }
    }

    static var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let cache = base.appending(path: "FreeOCR/Cache", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        return cache
    }

    static var historyDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "FreeOCR", directoryHint: .isDirectory)
    }

    private static func isONNXModelDirectory(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.appending(path: "inference.onnx").path)
    }
}
