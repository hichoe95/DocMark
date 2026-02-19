import Foundation

struct GitService {
    private static let gitExecutablePath = "/usr/bin/git"

    private static func runGit(args: [String], in directory: String) -> String? {
        guard FileManager.default.fileExists(atPath: directory) else {
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitExecutablePath)
        process.currentDirectoryPath = directory
        process.arguments = args

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !output.isEmpty else {
            return nil
        }

        return output
    }

    static func isGitRepository(at path: String) -> Bool {
        guard let output = runGit(args: ["rev-parse", "--is-inside-work-tree"], in: path) else {
            return false
        }

        return output.lowercased() == "true"
    }

    static func currentBranch(at path: String) -> String? {
        return runGit(args: ["rev-parse", "--abbrev-ref", "HEAD"], in: path)
    }

    static func lastCommitDate(at path: String) -> Date? {
        guard let output = runGit(args: ["log", "-1", "--format=%aI"], in: path) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: output) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: output)
    }

    static func lastCommitMessage(at path: String) -> String? {
        return runGit(args: ["log", "-1", "--format=%s"], in: path)
    }

    static func hasUncommittedChanges(at path: String) -> Bool {
        return runGit(args: ["status", "--porcelain"], in: path) != nil
    }

    static func changedFiles(at path: String) -> [String] {
        guard let output = runGit(args: ["status", "--porcelain"], in: path) else {
            return []
        }

        var paths: [String] = []

        for line in output.components(separatedBy: "\n") {
            guard line.count > 3 else {
                continue
            }

            let pathPart = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            if !pathPart.isEmpty {
                paths.append(pathPart)
            }
        }

        return paths
    }

    static func isFileModified(_ filePath: String, in repoPath: String) -> Bool {
        guard let output = runGit(args: ["status", "--porcelain", "--", filePath], in: repoPath) else {
            return false
        }

        for line in output.components(separatedBy: "\n") {
            guard line.count > 3 else {
                continue
            }

            let statusPath = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            if statusPath == filePath {
                return true
            }

            if statusPath.components(separatedBy: " -> ").last == filePath {
                return true
            }
        }

        return false
    }

    static func remoteURL(at path: String) -> String? {
        return runGit(args: ["remote", "get-url", "origin"], in: path)
    }

    // MARK: - Diff & Change Details

    static func changedFilesWithStatus(at path: String) -> [(status: GitFileStatus, relativePath: String)] {
        guard let output = runGit(args: ["status", "--porcelain"], in: path) else {
            return []
        }

        var results: [(GitFileStatus, String)] = []

        for line in output.components(separatedBy: "\n") {
            guard line.count >= 3 else { continue }

            let indexStatus = line[line.startIndex]
            let worktreeStatus = line[line.index(after: line.startIndex)]
            let filePath = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            guard !filePath.isEmpty else { continue }

            let status: GitFileStatus
            if indexStatus == "?" && worktreeStatus == "?" {
                status = .untracked
            } else if indexStatus == "A" {
                status = .added
            } else if indexStatus == "D" || worktreeStatus == "D" {
                status = .deleted
            } else if indexStatus == "R" {
                status = .renamed
            } else {
                status = .modified
            }

            let actualPath: String
            if let arrowRange = filePath.range(of: " -> ") {
                actualPath = String(filePath[arrowRange.upperBound...])
            } else {
                actualPath = filePath
            }

            results.append((status, actualPath))
        }

        return results
    }

    static func diff(for filePath: String, in repoPath: String, isUntracked: Bool = false) -> String? {
        if isUntracked {
            let fullPath = URL(fileURLWithPath: repoPath)
                .appendingPathComponent(filePath).path
            guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
                return nil
            }
            let lines = content.components(separatedBy: "\n")
            var result = "--- /dev/null\n+++ b/\(filePath)\n@@ -0,0 +1,\(lines.count) @@\n"
            for line in lines {
                result += "+\(line)\n"
            }
            return result
        }

        return runGit(args: ["diff", "HEAD", "--", filePath], in: repoPath)
    }

    static func diffStat(at path: String) -> String? {
        return runGit(args: ["diff", "HEAD", "--stat"], in: path)
    }
}
