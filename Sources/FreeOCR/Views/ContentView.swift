import CoreTransferable
import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationSplitView {
            DocumentSidebarView(model: model)
                .navigationSplitViewColumnWidth(min: 210, ideal: 250, max: 320)
        } detail: {
            Group {
                if let document = model.selectedDocument {
                    DocumentWorkspaceView(model: model, document: document)
                } else {
                    WelcomeView(model: model)
                }
            }
            .overlay {
                if model.isDropTargeted {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 3, dash: [9, 7]))
                        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                        .padding(18)
                        .allowsHitTesting(false)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    model.openImportPanel()
                } label: {
                    Label(model.text("导入", "Import"), systemImage: "plus")
                }
                .help(model.text("导入图片或 PDF（⌘O）", "Import an image or PDF (⌘O)"))

                Button {
                    model.requestRecognitionSelected()
                } label: {
                    Label(model.text("识别", "Recognize"), systemImage: "viewfinder")
                }
                .help(model.text(
                    "识别当前文档；已完成的文档会先询问是否重新识别",
                    "Recognize the current document; completed documents ask before rescanning"
                ))
                .disabled(
                    model.selectedDocument == nil
                        || model.selectedDocument?.status == .recognizing
                        || model.serviceState != .ready
                )

                SettingsLink {
                    Label(model.text("设置", "Settings"), systemImage: "gearshape")
                }
                .help(model.text("打开 FreeOCR 设置", "Open FreeOCR Settings"))
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            for url in urls {
                Task { await model.importRemoteURL(url) }
            }
            return !urls.isEmpty
        } isTargeted: { model.isDropTargeted = $0 }
        .dropDestination(for: Data.self) { items, _ in
            for data in items {
                model.importImageData(data)
            }
            return !items.isEmpty
        } isTargeted: { model.isDropTargeted = $0 }
        .alert(
            "FreeOCR",
            isPresented: Binding(
                get: { model.lastError != nil },
                set: { if !$0 { model.lastError = nil } }
            )
        ) {
            Button(model.text("好", "OK")) { model.lastError = nil }
        } message: {
            Text(model.lastError ?? "")
        }
        .confirmationDialog(
            model.text("该文档已经识别完成", "This document has already been recognized"),
            isPresented: $model.showsRescanConfirmation,
            titleVisibility: .visible
        ) {
            Button(model.text("重新识别", "Recognize Again"), role: .destructive) { model.confirmRescan() }
            Button(model.text("取消", "Cancel"), role: .cancel) { model.cancelRescan() }
        } message: {
            Text(model.text("重新识别会替换当前结果，是否继续？", "Recognizing again will replace the current result. Continue?"))
        }
    }
}
