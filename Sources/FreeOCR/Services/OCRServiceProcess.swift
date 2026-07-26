import Foundation
import OSLog

@MainActor
final class OCRServiceProcess {
    struct Configuration {
        let host: String
        let port: Int
        let apiKey: String
    }

    private let logger = Logger(subsystem: "com.scorpiodai.FreeOCR", category: "ModelService")
    private var process: Process?
    private var outputPipe: Pipe?

    var isRunning: Bool { process?.isRunning == true }

    func start(configuration: Configuration) throws {
        stop()
        guard let python = ResourceLocator.pythonExecutable else {
            throw ServiceLaunchError.missingPython
        }
        guard let script = ResourceLocator.serviceScript else {
            throw ServiceLaunchError.missingService
        }
        guard let detectionModel = ResourceLocator.traditionalDetectionModelDirectory else {
            throw ServiceLaunchError.missingTraditionalDetectionModel
        }
        guard let recognitionModel = ResourceLocator.traditionalRecognitionModelDirectory else {
            throw ServiceLaunchError.missingTraditionalRecognitionModel
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = python
        process.arguments = [
            script.path,
            "--detection-model-dir", detectionModel.path,
            "--recognition-model-dir", recognitionModel.path,
            "--cache-dir", ResourceLocator.cacheDirectory.path,
            "--host", configuration.host,
            "--port", String(configuration.port),
            "--api-key", configuration.apiKey,
            "--parent-pid", String(ProcessInfo.processInfo.processIdentifier)
        ]
        var environment = ProcessInfo.processInfo.environment
        environment["PYTHONUNBUFFERED"] = "1"
        environment["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"
        process.environment = environment
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [logger] handle in
            let data = handle.availableData
            guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
            logger.debug("\(line.trimmingCharacters(in: .whitespacesAndNewlines), privacy: .public)")
        }

        try process.run()
        self.process = process
        self.outputPipe = pipe
        logger.info("Started local OCR service on port \(configuration.port, privacy: .public)")
    }

    func stop() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        if let process, process.isRunning {
            process.terminate()
            logger.info("Stopped local OCR service")
        }
        process = nil
        outputPipe = nil
    }
}

enum ServiceLaunchError: LocalizedError {
    case missingPython
    case missingService
    case missingTraditionalDetectionModel
    case missingTraditionalRecognitionModel

    var errorDescription: String? {
        switch self {
        case .missingPython: "找不到随 App 提供的 Python OCR 运行环境。"
        case .missingService: "找不到 FreeOCR API 服务脚本。"
        case .missingTraditionalDetectionModel: "找不到 PP-OCRv6 medium DET ONNX 模型。"
        case .missingTraditionalRecognitionModel: "找不到 PP-OCRv6 medium REC ONNX 模型。"
        }
    }
}
