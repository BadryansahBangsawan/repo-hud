import Combine
import Foundation

struct WatchRecord: Codable, Equatable, Identifiable {
    var path: String
    var id: String { path }
}

struct RepoRow: Equatable, Identifiable {
    var path: String
    var watchPath: String
    var name: String
    var branch: String
    var dirty: Int
    var ahead: Int
    var behind: Int
    var error: String?

    var id: String { path }
}

final class RepoHUDModel: ObservableObject {
    static let bundleId = "engineer.badry.repohud"
    static let displayName = "Repo HUD"
    static let repoCap = 80
    static let maxDepth = 3
    private static let skipNames: Set<String> = ["node_modules", ".build", "DerivedData", ".git"]

    @Published var watches: [WatchRecord] = []
    @Published var repos: [RepoRow] = []
    @Published var loadError: String?
    @Published var actionError: String?
    @Published var scanError: String?
    @Published var gitMissing = false
    @Published var isScanning = false
    @Published var fetchingPath: String?

    private let queue = DispatchQueue(label: "engineer.badry.repohud.scan", qos: .userInitiated)
    private var pending: DispatchWorkItem?
    private let watcher = FSEventWatcher()
    private let pathLock = NSLock()
    private var pathSnapshot: [String] = []

    private var supportDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(Self.displayName)", isDirectory: true)
    }

    private var watchesURL: URL {
        supportDir.appendingPathComponent("watches.json")
    }

    init() {
        watcher.onChange = { [weak self] in
            self?.scheduleScan(immediate: false)
        }
        loadWatches()
        restartWatcher()
        scheduleScan(immediate: true)
    }

    func addWatch(path: String) {
        let standardized = (path as NSString).standardizingPath
        guard !standardized.isEmpty else { return }
        if watches.contains(where: { $0.path == standardized }) { return }
        watches.append(WatchRecord(path: standardized))
        rememberPaths()
        persistWatches()
        restartWatcher()
        scheduleScan(immediate: true)
    }

    func removeWatch(path: String) {
        watches.removeAll { $0.path == path }
        rememberPaths()
        persistWatches()
        restartWatcher()
        scheduleScan(immediate: true)
    }

    func addFoldersFromPanel() {
        for path in DirectoryPicker.select() {
            addWatch(path: path)
        }
    }

    func open(_ repo: RepoRow) {
        do {
            try RepoOpener.open(repo.path)
            actionError = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    func copyBranch(_ repo: RepoRow) {
        RepoOpener.copy(repo.branch)
    }

    func reveal(_ repo: RepoRow) {
        RepoOpener.reveal(repo.path)
    }

    func fetch(_ repo: RepoRow) {
        fetchingPath = repo.path
        actionError = nil
        queue.async { [weak self] in
            guard let self else { return }
            do {
                guard let git = GitClient.locate() else {
                    self.publish {
                        self.gitMissing = true
                        self.fetchingPath = nil
                        self.actionError = "git not in PATH"
                    }
                    return
                }
                try git.fetch(repoPath: repo.path)
                self.publish {
                    self.fetchingPath = nil
                    self.actionError = nil
                }
                self.scan(watchPaths: self.currentWatchPaths())
            } catch {
                self.publish {
                    self.fetchingPath = nil
                    self.actionError = error.localizedDescription
                }
            }
        }
    }

    func scheduleScan(immediate: Bool) {
        pending?.cancel()
        let paths = currentWatchPaths()
        let item = DispatchWorkItem { [weak self] in
            self?.scan(watchPaths: paths)
        }
        pending = item
        if immediate {
            queue.async(execute: item)
        } else {
            queue.asyncAfter(deadline: .now() + 0.5, execute: item)
        }
    }

    private func rememberPaths() {
        pathLock.lock()
        pathSnapshot = watches.map(\.path)
        pathLock.unlock()
    }

    private func currentWatchPaths() -> [String] {
        pathLock.lock()
        defer { pathLock.unlock() }
        return pathSnapshot
    }

    private func loadWatches() {
        let url = watchesURL
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            watches = Self.defaultWatches()
            rememberPaths()
            persistWatches()
            return
        }
        do {
            let data = try Data(contentsOf: url)
            do {
                watches = try JSONDecoder().decode([WatchRecord].self, from: data)
                loadError = nil
            } catch {
                watches = []
                loadError = error.localizedDescription
            }
            rememberPaths()
        } catch {
            watches = []
            loadError = error.localizedDescription
            rememberPaths()
        }
    }

    private func persistWatches() {
        do {
            try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(watches)
            try data.write(to: watchesURL, options: .atomic)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private static func defaultWatches() -> [WatchRecord] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let relatives = ["Developer", "Downloads/project-fun", "Documents", "src"]
        var records: [WatchRecord] = []
        for rel in relatives {
            let url = home.appendingPathComponent(rel)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                records.append(WatchRecord(path: url.standardizedFileURL.path))
            }
        }
        return records
    }

    private func restartWatcher() {
        watcher.setPaths(watches.map(\.path))
    }

    private func scan(watchPaths: [String]) {
        publish { self.isScanning = true }
        let git = GitClient.locate()
        var discovered: [(url: URL, watch: String)] = []
        var walkErrors: [String] = []
        for watch in watchPaths {
            let root = URL(fileURLWithPath: watch, isDirectory: true)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir), isDir.boolValue else {
                walkErrors.append("Watch missing: \(watch)")
                continue
            }
            discover(
                root: root,
                watch: watch,
                depth: 0,
                into: &discovered,
                errors: &walkErrors
            )
            if discovered.count >= Self.repoCap { break }
        }
        if discovered.count > Self.repoCap {
            discovered = Array(discovered.prefix(Self.repoCap))
        }

        var rows: [RepoRow] = []
        rows.reserveCapacity(discovered.count)
        for item in discovered {
            let name = item.url.lastPathComponent
            var row = RepoRow(
                path: item.url.path,
                watchPath: item.watch,
                name: name,
                branch: "—",
                dirty: 0,
                ahead: 0,
                behind: 0,
                error: nil
            )
            if let git {
                do {
                    let status = try git.status(repoPath: item.url.path)
                    row.branch = status.branch
                    row.dirty = status.dirty
                    row.ahead = status.ahead
                    row.behind = status.behind
                } catch {
                    row.error = error.localizedDescription
                }
            }
            rows.append(row)
        }
        rows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let banner: String?
        if let first = walkErrors.first {
            banner = first
        } else {
            banner = nil
        }

        publish {
            self.gitMissing = (git == nil)
            self.repos = rows
            self.isScanning = false
            self.scanError = banner
        }
    }

    private func discover(
        root: URL,
        watch: String,
        depth: Int,
        into discovered: inout [(url: URL, watch: String)],
        errors: inout [String]
    ) {
        if discovered.count >= Self.repoCap { return }
        let name = root.lastPathComponent
        if Self.skipNames.contains(name), depth > 0 { return }

        let gitURL = root.appendingPathComponent(".git")
        if FileManager.default.fileExists(atPath: gitURL.path) {
            discovered.append((root.standardizedFileURL, watch))
        }

        guard depth < Self.maxDepth else { return }

        let children: [URL]
        do {
            children = try FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: []
            )
        } catch {
            if depth == 0 {
                errors.append(error.localizedDescription)
            }
            return
        }

        for child in children {
            if discovered.count >= Self.repoCap { return }
            let childName = child.lastPathComponent
            if Self.skipNames.contains(childName) { continue }
            do {
                let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if values.isSymbolicLink == true { continue }
                if values.isDirectory != true { continue }
            } catch {
                continue
            }
            discover(root: child, watch: watch, depth: depth + 1, into: &discovered, errors: &errors)
        }
    }

    private func publish(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            objectWillChange.send()
            block()
        } else {
            DispatchQueue.main.async {
                self.objectWillChange.send()
                block()
            }
        }
    }
}
