import AppKit
import SwiftUI

@main
@MainActor
struct FreeOCRApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: AppModel

    init() {
        let model = AppModel()
        _model = State(initialValue: model)
        AppDelegate.runtime = model
    }

    var body: some Scene {
        Window("FreeOCR", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 980, minHeight: 640)
                .task { await model.launch() }
        }
        .defaultSize(width: 1_420, height: 880)
        .defaultLaunchBehavior(.presented)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(model.text("导入图片或 PDF…", "Import Image or PDF…")) { model.openImportPanel() }
                    .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu(model.text("识别", "Recognition")) {
                Button(model.text("开始识别", "Start Recognition")) { model.requestRecognitionSelected() }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(model.selectedDocument == nil)
                Divider()
                Button(model.copyActionTitle) { model.copyFullResult() }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .disabled(model.selectedDocument?.result == nil)
                Button(model.text("保存结果…", "Save Result…")) { model.saveResult() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(model.selectedDocument?.result == nil)
            }
        }

        Settings {
            SettingsView(model: model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var runtime: AppModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        guard !flag else { return true }

        if let mainWindow = sender.windows.first(where: {
            $0.identifier?.rawValue == "main" || $0.title == "FreeOCR"
        }) {
            mainWindow.makeKeyAndOrderFront(nil)
            sender.activate(ignoringOtherApps: true)
        }

        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        Self.runtime?.shutdown()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Self.runtime?.importDocuments(urls)
    }
}
