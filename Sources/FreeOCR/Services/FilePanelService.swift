import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum FilePanelService {
    static func chooseDocuments(language: AppLanguage) -> [URL] {
        let panel = NSOpenPanel()
        panel.title = language == .chinese ? "选择图片或 PDF" : "Choose Images or PDFs"
        panel.prompt = language == .chinese ? "导入" : "Import"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = supportedTypes
        return panel.runModal() == .OK ? panel.urls : []
    }

    static func save(text: String, suggestedName: String, type: UTType, language: AppLanguage) throws {
        let panel = NSSavePanel()
        panel.title = language == .chinese ? "保存 OCR 结果" : "Save OCR Result"
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [type]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    static var supportedTypes: [UTType] {
        var types: [UTType] = [.pdf, .png, .jpeg, .heic, .tiff, .bmp, .gif]
        if let heif = UTType(filenameExtension: "heif") { types.append(heif) }
        if let webp = UTType(filenameExtension: "webp") { types.append(webp) }
        return types
    }
}
