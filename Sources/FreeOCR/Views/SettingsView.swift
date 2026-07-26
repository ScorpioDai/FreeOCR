import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        TabView {
            Form {
                Section(model.text("界面", "Interface")) {
                    Picker(model.text("界面语言", "Interface Language"), selection: $model.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.nativeTitle).tag(language)
                        }
                    }
                }

                Section(model.text("识别", "Recognition")) {
                    Toggle(model.text("导入后自动开始识别", "Start recognition after import"), isOn: $model.autoRecognize)
                    LabeledContent(model.text("当前模型", "Current Model")) {
                        Text(model.currentModelName)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(model.text("语言", "Language")) {
                        Text(model.languageDescription)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(model.text("历史记录", "History")) {
                    LabeledContent(model.text("存储位置", "Storage Location")) {
                        Text(model.historyDirectoryPath)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)
                    }
                    HStack {
                        Text(model.text(
                            "识别完成后自动保存原文件、预览与结果。",
                            "Original files, previews, and results are saved automatically."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Spacer()
                        Button(model.text("在 Finder 中显示", "Show in Finder"), systemImage: "folder") {
                            model.revealHistoryDirectory()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label(model.text("通用", "General"), systemImage: "gearshape") }

            Form {
                Section(model.text("本地 API", "Local API")) {
                    LabeledContent(model.text("端口", "Port")) {
                        TextField(model.text("端口", "Port"), value: $model.apiPort, format: .number.grouping(.never))
                            .frame(width: 90)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle(model.text("允许局域网设备访问", "Allow access from LAN devices"), isOn: $model.allowLAN)
                    LabeledContent("Bearer Token (\(model.text("可选", "optional")))") {
                        SecureField(model.text("留空则不鉴权", "Leave blank for no authentication"), text: $model.apiKey)
                            .frame(width: 230)
                    }
                }

                Section(model.text("地址", "Endpoints")) {
                    EndpointRow(label: model.text("本机", "Local"), value: model.localAPIURL)
                    if model.allowLAN {
                        EndpointRow(label: model.text("局域网", "LAN"), value: model.lanAPIURL)
                    }
                    Text(model.text(
                        "修改端口、局域网访问或 Token 后，请重新启动服务。",
                        "Restart the service after changing the port, LAN access, or token."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if model.allowLAN && model.apiKey.isEmpty {
                        Label(
                            model.text("允许局域网访问时建议设置 Bearer Token。", "A Bearer Token is recommended when LAN access is enabled."),
                            systemImage: "exclamationmark.shield"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }

                HStack {
                    ServiceStatusView(model: model)
                        .frame(width: 280)
                    Spacer()
                    Button(model.text("重新启动 API 服务", "Restart API Service"), systemImage: "arrow.clockwise") {
                        Task { await model.restartService() }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("API", systemImage: "network") }

            Form {
                Section(model.text("离线组件", "Offline Components")) {
                    LabeledContent(model.text("内置模型", "Bundled Model"), value: "PP-OCRv6 medium · ONNX Runtime CPU")
                    LabeledContent(model.text("架构", "Architecture"), value: "Apple Silicon (arm64)")
                    if let modelPath = ResourceLocator.bundledModelsRoot?.path {
                        LabeledContent(model.text("模型位置", "Model Location")) {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(modelPath)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                                    .lineLimit(3)
                                Text(model.text(
                                    "显示 App 内模型的实际位置；移动 App 后会自动更新。",
                                    "This is the actual in-app path and updates automatically when the app moves."
                                ))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Text(model.text(
                        "文档内容只在这台 Mac 上处理。FreeOCR 不会把图片、PDF 或识别文字上传到网络。",
                        "Documents are processed only on this Mac. FreeOCR does not upload images, PDFs, or recognized text."
                    ))
                    .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label(model.text("模型", "Models"), systemImage: "cpu") }
        }
        .frame(width: 650, height: 470)
        .scenePadding()
    }
}

private struct EndpointRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label) {
            HStack {
                Text(value)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(value, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
