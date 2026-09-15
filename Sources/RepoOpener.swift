import AppKit
import Foundation

enum RepoOpener {
    static let editorCandidates = [
        "/usr/local/bin/cursor",
        "/opt/homebrew/bin/cursor",
        "/usr/local/bin/code",
        "/opt/homebrew/bin/code"
    ]

    static func open(_ path: String) throws {
        let fm = FileManager.default
        for bin in editorCandidates {
            if fm.isExecutableFile(atPath: bin) {
                try launch(executable: bin, arguments: [path])
                return
            }
        }
        if fm.isExecutableFile(atPath: "/usr/bin/xed") {
            try launch(executable: "/usr/bin/xed", arguments: [path])
            return
        }
        let ok = NSWorkspace.shared.open(URL(fileURLWithPath: path, isDirectory: true))
        if !ok {
            throw GitRunError(status: -1, message: "Could not open \(path)")
        }
    }

    static func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    static func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    private static func launch(executable: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }
}

enum DirectoryPicker {
    static func select() -> [String] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.prompt = "Add"
        panel.message = "Choose a folder that contains git repos"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return [] }
        return panel.urls.map { $0.standardizedFileURL.path }
    }
}

enum PathDisplay {
    static func abbreviate(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
