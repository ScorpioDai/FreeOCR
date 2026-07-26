import SwiftUI

struct DocumentSidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        List(selection: $model.selectedDocumentID) {
            ForEach(documentGroups) { group in
                Section(dateTitle(group.date)) {
                    ForEach(group.documents) { document in
                    DocumentSidebarRow(document: document, language: model.appLanguage)
                        .tag(document.id)
                        .contextMenu {
                            Button(model.text("重新识别", "Recognize Again")) {
                                model.selectedDocumentID = document.id
                                model.requestRecognitionSelected()
                            }
                            Divider()
                            Button(model.text("移除", "Remove"), role: .destructive) {
                                model.selectedDocumentID = document.id
                                model.removeSelected()
                            }
                            .disabled(document.status == .recognizing)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            ServiceStatusView(model: model)
                .padding(10)
        }
        .overlay {
            if model.documents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                    Text(model.text("尚无文档", "No Documents"))
                        .font(.callout)
                    Text(model.text("拖入或点击导入", "Drop a file or click Import"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var documentGroups: [DocumentDateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: model.documents) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted(by: >).map { date in
            DocumentDateGroup(
                date: date,
                documents: (grouped[date] ?? []).sorted { $0.createdAt > $1.createdAt }
            )
        }
    }

    private func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        let currentYear = Calendar.current.component(.year, from: Date())
        let recordYear = Calendar.current.component(.year, from: date)
        if model.appLanguage == .chinese {
            formatter.locale = Locale(identifier: "zh_Hans_CN")
            formatter.dateFormat = currentYear == recordYear ? "M月d日" : "yyyy年M月d日"
        } else {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = currentYear == recordYear ? "MMM d" : "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }
}

private struct DocumentDateGroup: Identifiable {
    let date: Date
    let documents: [OCRDocument]

    var id: Date { date }
}

private struct DocumentSidebarRow: View {
    @Bindable var document: OCRDocument
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: document.isPDF ? "doc.richtext" : "photo")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayName)
                    .lineLimit(1)
                Text(document.status.label(language: language))
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
            if document.status == .recognizing || document.status == .waitingForModel {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 3)
    }

    private var statusColor: Color {
        switch document.status {
        case .completed: .green
        case .failed: .red
        default: .secondary
        }
    }
}

struct ServiceStatusView: View {
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(model.serviceState.label(language: model.appLanguage, modelName: model.currentModelName))
                Text(model.currentModelName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 0)
            if model.serviceState == .starting || model.serviceState == .loading {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }

    private var color: Color {
        switch model.serviceState {
        case .ready: .green
        case .failed: .red
        case .starting, .loading: .yellow
        case .stopped: .secondary
        }
    }
}
