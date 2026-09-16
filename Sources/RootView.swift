import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: RepoHUDModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            if model.gitMissing {
                Label("git not in PATH", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let loadError = model.loadError {
                Label(loadError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionError = model.actionError {
                Label(actionError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let scanError = model.scanError {
                Label(scanError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if model.repos.isEmpty && !model.isScanning {
                ExtraEmptyState(
                    title: "No repositories",
                    detail: "Add a folder that contains git repos.",
                    actionTitle: "Add folder",
                    action: { model.addFoldersFromPanel() }
                )
            } else if model.repos.isEmpty {
                VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                        ForEach(model.repos) { repo in
                            RepoRowView(repo: repo)
                        }
                    }
                }
                .frame(maxHeight: 420)
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.repos)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.gitMissing)
        .funPanel()
        .onAppear {
            model.scheduleScan(immediate: true)
        }
    }
}

struct RepoRowView: View {
    @EnvironmentObject private var model: RepoHUDModel
    let repo: RepoRow

    var body: some View {
        Button {
            model.open(repo)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.name)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(1)
                    Text(repo.branch)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let error = repo.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    if model.fetchingPath == repo.path {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("\(repo.dirty) dirty")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(repo.dirty > 0 ? Color.primary : Color.secondary)
                        HStack(spacing: 6) {
                            if repo.ahead > 0 {
                                Text("↑\(repo.ahead)")
                            }
                            if repo.behind > 0 {
                                Text("↓\(repo.behind)")
                            }
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .extraRowSurface()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Fetch") {
                model.fetch(repo)
            }
            Button("Copy branch") {
                model.copyBranch(repo)
            }
            Button("Reveal in Finder") {
                model.reveal(repo)
            }
            Divider()
            Button("Remove watch", role: .destructive) {
                model.removeWatch(path: repo.watchPath)
            }
        }
        .help("Open in editor")
    }
}
