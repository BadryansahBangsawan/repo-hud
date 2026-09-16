import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: RepoHUDModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var loginError: String?
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Watch folders") {
                if model.watches.isEmpty {
                    Text("Add a folder that contains git repos")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.watches) { watch in
                    HStack(alignment: .firstTextBaseline) {
                        Text(PathDisplay.abbreviate(watch.path))
                            .lineLimit(2)
                            .textSelection(.enabled)
                        Spacer()
                        Button("Remove") {
                            model.removeWatch(path: watch.path)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                Button("Add folder") {
                    model.addFoldersFromPanel()
                }
            }

            Section {
                Toggle("Open at Login", isOn: loginBinding)
                if let loginError {
                    Label(loginError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: FunTheme.panelWidth, alignment: .leading)
        .padding(12)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.watches)
        .animation(reduceMotion ? nil : FunTheme.spring, value: loginError)
    }

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { loginEnabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                    loginEnabled = SMAppService.mainApp.status == .enabled
                    loginError = nil
                } catch {
                    loginEnabled = SMAppService.mainApp.status == .enabled
                    loginError = error.localizedDescription
                }
            }
        )
    }
}
