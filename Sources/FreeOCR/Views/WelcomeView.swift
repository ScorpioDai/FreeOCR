import SwiftUI

struct WelcomeView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.blue.opacity(0.09))
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.blue.gradient)
            }
            .frame(width: 112, height: 112)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))

            VStack(spacing: 8) {
                Text(model.text("把文档交给 FreeOCR", "Bring Your Documents to FreeOCR"))
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text(model.text(
                    "完全本地运行 · PP-OCRv6 · 图片与 PDF",
                    "Fully local · PP-OCRv6 · Images and PDFs"
                ))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                Button {
                    model.openImportPanel()
                } label: {
                    Label(model.text("选择图片或 PDF", "Choose Image or PDF"), systemImage: "plus")
                        .frame(minWidth: 180)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)

                Text(model.text(
                    "也可以从 Finder 或网页直接拖入图片",
                    "You can also drag an image from Finder or a web page"
                ))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(48)
    }
}
