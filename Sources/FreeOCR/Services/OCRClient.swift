import Foundation

actor OCRClient {
    enum ClientError: LocalizedError {
        case invalidResponse
        case server(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: "OCR 服务返回了无效响应。"
            case let .server(code, message): "OCR 服务错误（\(code)）：\(message)"
            }
        }
    }

    private let baseURL: URL
    private let apiKey: String
    private let decoder: JSONDecoder

    init(port: Int, apiKey: String) {
        self.baseURL = URL(string: "http://127.0.0.1:\(port)")!
        self.apiKey = apiKey
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func health() async throws -> ServiceHealth {
        var request = URLRequest(url: baseURL.appending(path: "health"))
        request.timeoutInterval = 3
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(ServiceHealth.self, from: data)
    }

    func startRecognition(fileURL: URL) async throws -> OCRJobStatus {
        let boundary = "FreeOCR-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "v1/ocr/jobs"))
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let fileData = try Data(contentsOf: fileURL)
        var body = Data()
        body.appendFormField(name: "max_pages", value: "500", boundary: boundary)
        body.appendFile(
            name: "file",
            filename: fileURL.lastPathComponent,
            mimeType: Self.mimeType(for: fileURL),
            data: fileData,
            boundary: boundary
        )
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(OCRJobStatus.self, from: data)
    }

    func recognitionStatus(id: String) async throws -> OCRJobStatus {
        var request = URLRequest(url: baseURL.appending(path: "v1/ocr/jobs/\(id)"))
        request.timeoutInterval = 10
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(OCRJobStatus.self, from: data)
    }

    func prettyJSON(for result: OCRResponse) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return String(decoding: try encoder.encode(result), as: UTF8.self)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String
            throw ClientError.server(http.statusCode, detail ?? String(decoding: data, as: UTF8.self))
        }
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": "application/pdf"
        case "jpg", "jpeg": "image/jpeg"
        case "heic": "image/heic"
        case "heif": "image/heif"
        case "tif", "tiff": "image/tiff"
        case "webp": "image/webp"
        case "bmp": "image/bmp"
        case "gif": "image/gif"
        default: "image/png"
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func appendFormField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func appendFile(
        name: String,
        filename: String,
        mimeType: String,
        data: Data,
        boundary: String
    ) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        append("\r\n")
    }
}
