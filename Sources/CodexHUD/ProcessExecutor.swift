// 功能：封装本地命令执行能力，供 `ps`、`lsof`、`sqlite3` 与 `open` 等采集动作复用。
// 函数简介：同步执行系统命令，并返回标准输出、标准错误与退出码。

import Foundation
import OSLog

private let processLogger = Logger(subsystem: "com.panguimmortal.codex-hud", category: "process")

struct ProcessResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

enum ProcessExecutionError: LocalizedError {
    case failed(executable: String, code: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case let .failed(executable, code, stderr):
            return "\(executable) 执行失败，退出码 \(code)：\(stderr)"
        }
    }
}

enum ProcessExecutor {
    @discardableResult
    static func run(
        executable: String,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        allowFailure: Bool = false
    ) throws -> ProcessResult {
        // 关键逻辑：统一通过 `Process` 启动，避免 shell 拼接带来的转义问题。
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        processLogger.debug("执行命令：\(executable, privacy: .public) \(arguments.joined(separator: " "), privacy: .public)")

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(decoding: stdoutData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let stderr = String(decoding: stderrData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)

        let result = ProcessResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)

        if !allowFailure, result.exitCode != 0 {
            processLogger.error("命令失败：\(executable, privacy: .public) code=\(result.exitCode) stderr=\(stderr, privacy: .public)")
            throw ProcessExecutionError.failed(executable: executable, code: result.exitCode, stderr: stderr)
        }

        return result
    }
}
