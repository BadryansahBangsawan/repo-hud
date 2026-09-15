import Foundation

struct GitRunError: LocalizedError {
    let status: Int32
    let message: String

    var errorDescription: String? { message }
}

struct GitStatus {
    var branch: String
    var ahead: Int
    var behind: Int
    var dirty: Int
}

struct GitClient {
    let executable: String

    static func locate() -> GitClient? {
        let fm = FileManager.default
        var candidates: [String] = [
            "/opt/homebrew/bin/git",
            "/usr/local/bin/git",
            "/usr/bin/git"
        ]
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            for item in path.split(separator: ":") {
                candidates.append("\(item)/git")
            }
        }
        var seen = Set<String>()
        for raw in candidates {
            let path = (raw as NSString).standardizingPath
            if seen.contains(path) { continue }
            seen.insert(path)
            if fm.isExecutableFile(atPath: path) {
                return GitClient(executable: path)
            }
        }
        return nil
    }

    func run(arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment
        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            throw GitRunError(status: -1, message: error.localizedDescription)
        }
        process.waitUntilExit()
        let outData: Data
        let errData: Data
        do {
            outData = (try out.fileHandleForReading.readToEnd()) ?? Data()
            errData = (try err.fileHandleForReading.readToEnd()) ?? Data()
        } catch {
            throw GitRunError(status: process.terminationStatus, message: error.localizedDescription)
        }
        let stdout = String(data: outData, encoding: .utf8) ?? String(decoding: outData, as: UTF8.self)
        let stderr = String(data: errData, encoding: .utf8) ?? String(decoding: errData, as: UTF8.self)
        if process.terminationStatus != 0 {
            let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw GitRunError(
                status: process.terminationStatus,
                message: trimmed.isEmpty ? "git failed (\(process.terminationStatus))" : trimmed
            )
        }
        return stdout
    }

    func status(repoPath: String) throws -> GitStatus {
        let output = try run(arguments: ["-C", repoPath, "status", "-sb", "--porcelain=v1"])
        return GitClient.parsePorcelain(output)
    }

    func fetch(repoPath: String) throws {
        _ = try run(arguments: ["-C", repoPath, "fetch", "--quiet"])
    }

    static func parsePorcelain(_ text: String) -> GitStatus {
        let lines = text.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.first, header.hasPrefix("##") else {
            return GitStatus(branch: "unknown", ahead: 0, behind: 0, dirty: lines.count)
        }
        var body: String
        if header.hasPrefix("## ") {
            body = String(header.dropFirst(3))
        } else {
            body = String(header.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }

        var ahead = 0
        var behind = 0
        if let open = body.lastIndex(of: "["), let close = body.lastIndex(of: "]"), open < close {
            let inner = body[body.index(after: open)..<close]
            body = String(body[..<open]).trimmingCharacters(in: .whitespaces)
            for chunk in inner.split(separator: ",") {
                let token = chunk.trimmingCharacters(in: .whitespaces)
                if token.hasPrefix("ahead ") {
                    ahead = Int(token.dropFirst(6).trimmingCharacters(in: .whitespaces)) ?? 0
                } else if token.hasPrefix("behind ") {
                    behind = Int(token.dropFirst(7).trimmingCharacters(in: .whitespaces)) ?? 0
                }
            }
        }

        var branch = body
        if let dots = branch.range(of: "...") {
            branch = String(branch[..<dots.lowerBound])
        }
        if branch.hasPrefix("No commits yet on ") {
            branch = String(branch.dropFirst("No commits yet on ".count))
        }
        if branch.hasPrefix("HEAD") {
            branch = "HEAD"
        }
        branch = branch.trimmingCharacters(in: .whitespaces)
        if branch.isEmpty {
            branch = "unknown"
        }

        let dirty = max(0, lines.count - 1)
        return GitStatus(branch: branch, ahead: ahead, behind: behind, dirty: dirty)
    }
}
