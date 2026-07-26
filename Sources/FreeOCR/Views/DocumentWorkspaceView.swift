import AppKit
import SwiftUI

struct DocumentWorkspaceView: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceHeader(model: model, document: document)
            Divider()

            switch document.status {
            case .completed:
                HSplitView {
                    DocumentPane(model: model, document: document)
                        .frame(minWidth: 360, idealWidth: 620)
                    ResultPane(model: model, document: document)
                        .frame(minWidth: 360, idealWidth: 620)
                }
            case .failed(let message):
                ContentUnavailableView(
                    model.text("识别失败", "Recognition Failed"),
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case .recognizing:
                RecognitionProgressView(model: model, document: document)
            case .waitingForModel:
                LoadingWorkspace(
                    title: model.text("正在加载模型", "Loading Model"),
                    subtitle: model.text("模型准备好后会自动开始识别。", "Recognition will start automatically when the model is ready.")
                )
            case .queued:
                LoadingWorkspace(
                    title: model.text("等待识别", "Queued for Recognition"),
                    subtitle: model.text("文档已加入本地识别队列。", "The document is in the local recognition queue.")
                )
            }
        }
    }
}

private struct WorkspaceHeader: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(document.sourceURL.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Label(model.text("快速 OCR", "Fast OCR"), systemImage: "bolt.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)

            Button(model.text("重新识别", "Recognize Again"), systemImage: "arrow.clockwise") {
                model.requestRecognitionSelected()
            }
            .disabled(document.status == .recognizing || model.serviceState != .ready)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct RecognitionProgressView: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument

    var body: some View {
        VStack(spacing: 16) {
            if document.progressTotal > 0 {
                ProgressView(value: document.progressFraction)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 420)

                Text(model.text(
                    "\(document.progressCurrent) / \(document.progressTotal) 个识别步骤",
                    "\(document.progressCurrent) / \(document.progressTotal) recognition steps"
                ))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.large)
            }

            Text(model.text("正在识别文档", "Recognizing Document"))
                .font(.title2.weight(.semibold))
            Text(stageDescription)
                .foregroundStyle(.secondary)

            HStack(spacing: 18) {
                Label(model.text("已用时 ", "Elapsed ") + formatDuration(document.elapsedSeconds), systemImage: "clock")
                if let remaining = document.estimatedRemainingSeconds,
                   document.progressCurrent > 0,
                   document.progressCurrent < document.progressTotal {
                    Label(model.text("预计剩余 ", "About ") + formatDuration(remaining) + model.text("", " remaining"), systemImage: "hourglass")
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var stageDescription: String {
        let pageText = document.progressPageCount > 0 && document.progressPage > 0
            ? model.text(
                "第 \(document.progressPage) / \(document.progressPageCount) 页",
                "Page \(document.progressPage) of \(document.progressPageCount)"
            )
            : model.text("正在准备页面", "Preparing pages")
        switch document.progressStage {
        case "recognizing_text": return pageText + model.text(" · 正在进行快速文字识别", " · Running fast text recognition")
        case "text_completed": return pageText + model.text(" · 文字识别完成", " · Text recognition complete")
        case "saving_history": return model.text("正在保存本地历史记录", "Saving local history")
        case "prepared": return model.text("页面准备完成，即将开始识别", "Pages are ready; recognition is starting")
        default: return model.text("正在读取并准备文档", "Reading and preparing the document")
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        if total < 60 { return model.text("\(total) 秒", "\(total) sec") }
        return model.text("\(total / 60) 分 \(total % 60) 秒", "\(total / 60) min \(total % 60) sec")
    }
}

private struct LoadingWorkspace: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DocumentPane: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument
    @State private var zoom = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(model.text("原始文档", "Original Document"), systemImage: "doc")
                    .font(.headline)
                Spacer()

                Button {
                    zoom = max(0.5, zoom - 0.15)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .disabled(zoom <= 0.5)

                Text("\(Int(zoom * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 42)

                Button {
                    zoom = min(3, zoom + 0.15)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .disabled(zoom >= 3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
            DocumentCanvasView(model: model, document: document, zoom: zoom)

            if let count = document.result?.pages.count, count > 1 {
                Divider()
                HStack {
                    Button(model.text("上一页", "Previous"), systemImage: "chevron.left") {
                        document.currentPage = max(0, document.currentPage - 1)
                        document.clearHighlight()
                    }
                    .disabled(document.currentPage == 0)

                    Spacer()
                    Text(model.text(
                        "第 \(document.currentPage + 1) / \(count) 页",
                        "Page \(document.currentPage + 1) of \(count)"
                    ))
                        .font(.callout.monospacedDigit())
                    Spacer()

                    Button(model.text("下一页", "Next"), systemImage: "chevron.right") {
                        document.currentPage = min(count - 1, document.currentPage + 1)
                        document.clearHighlight()
                    }
                    .labelStyle(.titleAndIcon)
                    .disabled(document.currentPage >= count - 1)
                }
                .padding(10)
            }
        }
    }
}

private struct DocumentCanvasView: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument
    let zoom: Double

    var body: some View {
        GeometryReader { proxy in
            if let page = document.currentPageResult,
               let image = NSImage(contentsOfFile: page.previewPath) {
                let baseSize = aspectFit(imageSize: image.size, container: proxy.size)
                let scaledSize = CGSize(width: baseSize.width * zoom, height: baseSize.height * zoom)

                ScrollView([.horizontal, .vertical]) {
                    PageImageOverlay(document: document, page: page, image: image, size: scaledSize)
                        .frame(width: scaledSize.width, height: scaledSize.height)
                        .frame(
                            minWidth: max(0, proxy.size.width - 40),
                            minHeight: max(0, proxy.size.height - 40),
                            alignment: .center
                        )
                        .padding(20)
                }
                .background(.quaternary.opacity(0.25))
            } else {
                ContentUnavailableView(model.text("无法预览页面", "Unable to Preview Page"), systemImage: "doc.questionmark")
            }
        }
    }

    private func aspectFit(imageSize: CGSize, container: CGSize) -> CGSize {
        let available = CGSize(width: max(100, container.width - 40), height: max(100, container.height - 40))
        let scale = min(available.width / imageSize.width, available.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

private struct PageImageOverlay: View {
    @Bindable var document: OCRDocument
    let page: OCRPage
    let image: NSImage
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .shadow(color: .black.opacity(0.16), radius: 12, y: 4)

            ForEach(page.blocks) { block in
                let rect = block.boundingRect
                let highlighted = document.highlightedBlockID == block.id
                RoundedRectangle(cornerRadius: 3)
                    .fill(.blue.opacity(highlighted ? 0.24 : 0.001))
                    .stroke(.blue.opacity(highlighted ? 0.95 : 0.28), lineWidth: highlighted ? 2 : 0.8)
                    .frame(
                        width: max(5, rect.width * size.width),
                        height: max(5, rect.height * size.height)
                    )
                    .position(
                        x: rect.midX * size.width,
                        y: rect.midY * size.height
                    )
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case let .active(location):
                let target = block(at: location)
                if document.highlightedBlockID != target?.id || document.highlightSource != .document {
                    document.highlight(target, source: .document)
                }
            case .ended:
                if document.highlightSource == .document {
                    document.highlight(nil, source: .document)
                }
            }
        }
    }

    private func block(at location: CGPoint) -> OCRBlock? {
        guard size.width > 0, size.height > 0 else { return nil }
        let point = CGPoint(x: location.x / size.width, y: location.y / size.height)
        let horizontalSlop = 3 / size.width
        let verticalSlop = 3 / size.height

        return page.block(
            at: point,
            tolerance: CGSize(width: horizontalSlop, height: verticalSlop)
        )
    }
}

private struct ResultPane: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument
    @State private var loadedModes: Set<ResultViewMode> = [.preview]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(model.text("识别结果", "Recognition Result"), systemImage: "text.page")
                    .font(.headline)
                Spacer()
                Picker(model.text("显示方式", "View"), selection: $model.resultViewMode) {
                    ForEach(ResultViewMode.allCases) { mode in
                        Text(mode.title(language: model.appLanguage)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 240)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
            if let result = document.result {
                ZStack {
                    BlockResultPreview(model: model, document: document, result: result)
                        .opacity(model.resultViewMode == .preview ? 1 : 0)
                        .allowsHitTesting(model.resultViewMode == .preview)
                        .accessibilityHidden(model.resultViewMode != .preview)

                    if loadedModes.contains(.markdown) {
                        LargeTextView(text: result.markdown)
                            .opacity(model.resultViewMode == .markdown ? 1 : 0)
                            .allowsHitTesting(model.resultViewMode == .markdown)
                            .accessibilityHidden(model.resultViewMode != .markdown)
                    }

                    if loadedModes.contains(.json) {
                        LargeTextView(text: document.jsonText)
                            .opacity(model.resultViewMode == .json ? 1 : 0)
                            .allowsHitTesting(model.resultViewMode == .json)
                            .accessibilityHidden(model.resultViewMode != .json)
                    }
                }
                .onAppear { loadedModes.insert(model.resultViewMode) }
                .onChange(of: model.resultViewMode) { _, mode in loadedModes.insert(mode) }
            }

            Divider()
            HStack {
                Text(model.text("语言：", "Language: ") + model.languageDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(model.copyActionTitle, systemImage: "doc.on.doc") { model.copyFullResult() }
                    .help(model.copyActionHelp)
                Button(model.text("保存…", "Save…"), systemImage: "square.and.arrow.down") { model.saveResult() }
            }
            .padding(10)
        }
    }

}

private struct BlockResultPreview: View {
    @Bindable var model: AppModel
    @Bindable var document: OCRDocument
    let result: OCRResponse

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(result.pages) { page in
                        if result.pages.count > 1 {
                            Text(model.text("第 \(page.index + 1) 页", "Page \(page.index + 1)"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, page.index == 0 ? 0 : 16)
                        }

                        if page.blocks.isEmpty {
                            Text(page.markdown)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(page.blocks) { block in
                                let highlighted = document.highlightedBlockID == block.id
                                Text(block.text)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        highlighted ? Color.blue.opacity(0.14) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .contentShape(Rectangle())
                                    .id(block.id)
                                    .onContinuousHover { phase in
                                        switch phase {
                                        case .active: document.highlight(block, source: .result)
                                        case .ended:
                                            if document.highlightedBlockID == block.id {
                                                document.highlight(nil, source: .result)
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: document.highlightedBlockID) { _, id in
                guard let id, document.highlightSource == .document else { return }
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }
}
