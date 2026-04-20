// 功能：实现 Codex 数据采集与快照聚合。
// 函数简介：从进程、状态库、日志库与全局配置中读取信号，并合成为 HUD 可消费的聚合快照。

import Foundation
import OSLog

private let dataLogger = Logger(subsystem: "com.panguimmortal.codex-hud", category: "datasource")

final class CodexSnapshotBuilder {
    private let runtime: AppRuntime

    init(runtime: AppRuntime) {
        self.runtime = runtime
    }

    func loadSnapshot() throws -> DashboardSnapshot {
        // 关键逻辑：先采集基础数据，再进行统一聚合，确保 HUD 与导出 JSON 完全一致。
        let processes = try loadProcesses()
        let threads = try loadThreads()
        let spawnedAgents = try loadSpawnedAgents()
        let agentJobs = try loadAgentJobs()
        let warnings = try loadRecentWarnings()
        let globalState = try loadGlobalState()

        let now = Date()
        let hotCutoff = now.addingTimeInterval(-runtime.hotThreadWindowSeconds)

        // 关键逻辑：仅统计最近窗口内更新的非归档线程，避免历史线程冲淡当前态势。
        let hotThreads = threads
            .filter { !$0.archived && $0.updatedAt >= hotCutoff }
            .sorted { $0.updatedAt > $1.updatedAt }

        // 关键逻辑：后台 Agent 由 `spawn edges` 与 `agent jobs` 双路相加，更接近用户理解的“后台工作量”。
        let runningJobs = agentJobs.filter { ["running", "queued", "in_progress", "pending"].contains($0.status.lowercased()) }
        let recentSpawnedAgentThreads = spawnedAgents.filter { $0.updatedAt >= hotCutoff }
        let backgroundAgentCount = recentSpawnedAgentThreads.count + runningJobs.count

        let projects = buildProjects(
            processes: processes,
            hotThreads: hotThreads,
            spawnedAgentThreads: recentSpawnedAgentThreads,
            activeWorkspaceRoots: Set(globalState.activeWorkspaceRoots)
        )

        let warningCount = warnings.filter { $0.level.uppercased() == "WARN" }.count
        let errorCount = warnings.filter { $0.level.uppercased() == "ERROR" }.count
        let health = deriveHealth(
            warningCount: warningCount,
            errorCount: errorCount,
            interactiveSessionCount: processes.filter { $0.kind == .interactive }.count,
            backgroundAgentCount: backgroundAgentCount
        )
        let activitySignals = buildActivitySignals(
            processes: processes,
            hotThreads: hotThreads,
            spawnedAgentThreads: recentSpawnedAgentThreads,
            warnings: warnings,
            runningJobs: runningJobs
        )
        let notes = buildNotes(
            processCount: processes.count,
            threadCount: threads.count,
            workspaceCount: globalState.activeWorkspaceRoots.count
        )

        dataLogger.info("采集完成：会话=\(processes.filter { $0.kind == .interactive }.count) 热线程=\(hotThreads.count) 后台Agent=\(backgroundAgentCount) 告警=\(warnings.count)")

        return DashboardSnapshot(
            generatedAt: now,
            codexHomePath: runtime.codexHome.path,
            interactiveSessionCount: processes.filter { $0.kind == .interactive }.count,
            appServerCount: processes.filter { $0.kind == .appServer }.count,
            hotThreadCount: hotThreads.count,
            backgroundAgentCount: backgroundAgentCount,
            queuedJobCount: runningJobs.count,
            warningCount: warningCount,
            errorCount: errorCount,
            activeWorkspaces: globalState.activeWorkspaceRoots,
            projects: projects,
            processes: processes.sorted { $0.elapsedSeconds > $1.elapsedSeconds },
            hotThreads: hotThreads,
            activitySignals: activitySignals,
            recentWarnings: warnings,
            health: health,
            notes: notes
        )
    }

    private func loadProcesses() throws -> [CodexProcess] {
        // 关键逻辑：只读取真实的 Codex 运行体和 app-server，排除 `node /opt/homebrew/bin/codex` 这类包装层。
        let result = try ProcessExecutor.run(
            executable: "/bin/ps",
            arguments: ["-axo", "pid=,ppid=,%cpu=,%mem=,etime=,command="]
        )

        return result.stdout
            .split(separator: "\n")
            .compactMap { line in
                let parsed = parseProcessLine(String(line))
                guard let parsed else {
                    return nil
                }

                let commandLowercased = parsed.command.lowercased()
                let isInteractiveBinary = commandLowercased.contains("/codex/codex")
                let isAppServer = commandLowercased.contains("codex app-server")
                guard isInteractiveBinary || isAppServer else {
                    return nil
                }

                let workingDirectory = try? loadWorkingDirectory(for: parsed.pid)
                return CodexProcess(
                    pid: parsed.pid,
                    parentPid: parsed.parentPid,
                    cpuPercent: parsed.cpuPercent,
                    memoryPercent: parsed.memoryPercent,
                    elapsedTimeText: parsed.elapsedTimeText,
                    elapsedSeconds: parsed.elapsedSeconds,
                    command: parsed.command,
                    workingDirectory: workingDirectory,
                    kind: isAppServer ? .appServer : .interactive
                )
            }
    }

    private func loadWorkingDirectory(for pid: Int) throws -> String? {
        let result = try ProcessExecutor.run(
            executable: "/usr/sbin/lsof",
            arguments: ["-a", "-d", "cwd", "-p", "\(pid)", "-Fn"],
            allowFailure: true
        )

        // 关键逻辑：`lsof -Fn` 输出中以 `n` 开头的行即 cwd 路径。
        let pathLine = result.stdout
            .split(separator: "\n")
            .first { $0.hasPrefix("n") }

        guard let pathLine else {
            return nil
        }

        return String(pathLine.dropFirst())
    }

    private func loadThreads() throws -> [CodexThread] {
        let stateDatabaseURL = runtime.codexHome.appendingPathComponent("state_5.sqlite")
        guard FileManager.default.fileExists(atPath: stateDatabaseURL.path) else {
            return []
        }

        let sql = """
        SELECT
            id,
            title,
            source,
            cwd,
            archived,
            model,
            reasoning_effort,
            agent_nickname,
            agent_role,
            updated_at_ms
        FROM threads
        WHERE archived = 0
        ORDER BY updated_at_ms DESC
        LIMIT 80;
        """

        let rawRows: [ThreadRow] = try runSQLiteQuery(
            databaseURL: stateDatabaseURL,
            sql: sql,
            rowType: [ThreadRow].self
        )

        return rawRows.map { row in
            CodexThread(
                id: row.id,
                title: row.title,
                source: row.source,
                cwd: row.cwd,
                updatedAt: Date(timeIntervalSince1970: TimeInterval(row.updatedAtMilliseconds) / 1000),
                archived: row.archived == 1,
                model: row.model,
                reasoningEffort: row.reasoningEffort,
                agentNickname: row.agentNickname,
                agentRole: row.agentRole
            )
        }
    }

    private func loadSpawnedAgents() throws -> [CodexThread] {
        let stateDatabaseURL = runtime.codexHome.appendingPathComponent("state_5.sqlite")
        guard FileManager.default.fileExists(atPath: stateDatabaseURL.path) else {
            return []
        }

        let sql = """
        SELECT
            t.id,
            t.title,
            t.source,
            t.cwd,
            t.archived,
            t.model,
            t.reasoning_effort,
            t.agent_nickname,
            t.agent_role,
            t.updated_at_ms
        FROM thread_spawn_edges e
        JOIN threads t ON t.id = e.child_thread_id
        WHERE t.archived = 0
        ORDER BY t.updated_at_ms DESC
        LIMIT 80;
        """

        let rawRows: [ThreadRow] = try runSQLiteQuery(
            databaseURL: stateDatabaseURL,
            sql: sql,
            rowType: [ThreadRow].self
        )

        return rawRows.map { row in
            CodexThread(
                id: row.id,
                title: row.title,
                source: row.source,
                cwd: row.cwd,
                updatedAt: Date(timeIntervalSince1970: TimeInterval(row.updatedAtMilliseconds) / 1000),
                archived: row.archived == 1,
                model: row.model,
                reasoningEffort: row.reasoningEffort,
                agentNickname: row.agentNickname,
                agentRole: row.agentRole
            )
        }
    }

    private func loadAgentJobs() throws -> [CodexAgentJob] {
        let stateDatabaseURL = runtime.codexHome.appendingPathComponent("state_5.sqlite")
        guard FileManager.default.fileExists(atPath: stateDatabaseURL.path) else {
            return []
        }

        let sql = """
        SELECT
            id,
            name,
            status,
            updated_at
        FROM agent_jobs
        ORDER BY updated_at DESC
        LIMIT 80;
        """

        let rawRows: [AgentJobRow] = try runSQLiteQuery(
            databaseURL: stateDatabaseURL,
            sql: sql,
            rowType: [AgentJobRow].self
        )

        return rawRows.map { row in
            CodexAgentJob(
                id: row.id,
                name: row.name,
                status: row.status,
                updatedAt: Date(timeIntervalSince1970: TimeInterval(row.updatedAt))
            )
        }
    }

    private func loadRecentWarnings() throws -> [CodexLogEvent] {
        let logsDatabaseURL = runtime.codexHome.appendingPathComponent("logs_2.sqlite")
        guard FileManager.default.fileExists(atPath: logsDatabaseURL.path) else {
            return []
        }

        let sql = """
        SELECT
            ts,
            level,
            target,
            SUBSTR(COALESCE(feedback_log_body, ''), 1, 240) AS body
        FROM logs
        WHERE level IN ('WARN', 'ERROR')
        ORDER BY ts DESC
        LIMIT 20;
        """

        let rawRows: [LogRow] = try runSQLiteQuery(
            databaseURL: logsDatabaseURL,
            sql: sql,
            rowType: [LogRow].self
        )

        return rawRows.map { row in
            CodexLogEvent(
                timestamp: Date(timeIntervalSince1970: TimeInterval(row.ts)),
                level: row.level,
                target: row.target,
                body: row.body
            )
        }
    }

    private func loadGlobalState() throws -> CodexGlobalState {
        let globalStateURL = runtime.codexHome.appendingPathComponent(".codex-global-state.json")
        guard FileManager.default.fileExists(atPath: globalStateURL.path) else {
            return CodexGlobalState(activeWorkspaceRoots: [], projectOrder: [])
        }

        let data = try Data(contentsOf: globalStateURL)
        let rawState = try JSONDecoder().decode(RawGlobalState.self, from: data)
        return CodexGlobalState(
            activeWorkspaceRoots: rawState.activeWorkspaceRoots,
            projectOrder: rawState.projectOrder
        )
    }

    private func runSQLiteQuery<T: Decodable>(
        databaseURL: URL,
        sql: String,
        rowType: T.Type
    ) throws -> T {
        let result = try ProcessExecutor.run(
            executable: "/usr/bin/sqlite3",
            arguments: ["-json", databaseURL.path, sql]
        )

        if result.stdout.isEmpty {
            let emptyData = Data("[]".utf8)
            return try JSONDecoder().decode(rowType, from: emptyData)
        }

        let data = Data(result.stdout.utf8)
        return try JSONDecoder().decode(rowType, from: data)
    }

    private func parseProcessLine(_ line: String) -> ParsedProcessLine? {
        // 关键逻辑：`ps` 的前 5 列固定，余下内容全部视为命令字符串。
        let components = line.split(whereSeparator: \.isWhitespace)
        guard components.count >= 6 else {
            return nil
        }

        let pid = Int(components[0]) ?? 0
        let parentPid = Int(components[1]) ?? 0
        let cpuPercent = Double(components[2]) ?? 0
        let memoryPercent = Double(components[3]) ?? 0
        let elapsedTimeText = String(components[4])
        let command = components.dropFirst(5).joined(separator: " ")
        let elapsedSeconds = parseElapsedTime(text: elapsedTimeText)

        return ParsedProcessLine(
            pid: pid,
            parentPid: parentPid,
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent,
            elapsedTimeText: elapsedTimeText,
            elapsedSeconds: elapsedSeconds,
            command: command
        )
    }

    private func parseElapsedTime(text: String) -> Int {
        // 关键逻辑：兼容 `dd-hh:mm:ss`、`hh:mm:ss`、`mm:ss` 等多种 ps 输出格式。
        let dayAndRest = text.split(separator: "-")
        let dayValue = dayAndRest.count == 2 ? Int(dayAndRest[0]) ?? 0 : 0
        let timePortion = String(dayAndRest.last ?? Substring(text))
        let segments = timePortion.split(separator: ":").compactMap { Int($0) }

        switch segments.count {
        case 3:
            return dayValue * 86_400 + segments[0] * 3600 + segments[1] * 60 + segments[2]
        case 2:
            return dayValue * 86_400 + segments[0] * 60 + segments[1]
        case 1:
            return dayValue * 86_400 + segments[0]
        default:
            return 0
        }
    }

    private func buildProjects(
        processes: [CodexProcess],
        hotThreads: [CodexThread],
        spawnedAgentThreads: [CodexThread],
        activeWorkspaceRoots: Set<String>
    ) -> [ProjectSnapshot] {
        // 关键逻辑：按路径归并全部会话与线程，形成真正可观察的“项目维度”视图。
        var grouped: [String: ProjectAccumulator] = [:]

        for process in processes {
            let key = process.workingDirectory ?? "未知目录"
            var accumulator = grouped[key, default: ProjectAccumulator(path: key)]
            if process.kind == .interactive {
                accumulator.interactiveSessions += 1
            } else {
                accumulator.appServers += 1
            }
            grouped[key] = accumulator
        }

        for thread in hotThreads {
            var accumulator = grouped[thread.cwd, default: ProjectAccumulator(path: thread.cwd)]
            accumulator.hotThreads += 1
            accumulator.lastUpdatedAt = max(accumulator.lastUpdatedAt ?? .distantPast, thread.updatedAt)
            if let model = thread.model, !model.isEmpty {
                accumulator.latestModelNames.insert(model)
            }
            accumulator.latestTitles.append(thread.title)
            grouped[thread.cwd] = accumulator
        }

        for spawnedAgent in spawnedAgentThreads {
            var accumulator = grouped[spawnedAgent.cwd, default: ProjectAccumulator(path: spawnedAgent.cwd)]
            accumulator.backgroundAgents += 1
            accumulator.lastUpdatedAt = max(accumulator.lastUpdatedAt ?? .distantPast, spawnedAgent.updatedAt)
            grouped[spawnedAgent.cwd] = accumulator
        }

        return grouped.values
            .map { accumulator in
                ProjectSnapshot(
                    path: accumulator.path,
                    displayName: URL(fileURLWithPath: accumulator.path).lastPathComponent.isEmpty ? accumulator.path : URL(fileURLWithPath: accumulator.path).lastPathComponent,
                    interactiveSessions: accumulator.interactiveSessions,
                    hotThreads: accumulator.hotThreads,
                    backgroundAgents: accumulator.backgroundAgents,
                    appServers: accumulator.appServers,
                    latestModelNames: Array(accumulator.latestModelNames).sorted(),
                    latestTitles: Array(accumulator.latestTitles.prefix(3)),
                    workspaceActive: activeWorkspaceRoots.contains(accumulator.path),
                    lastUpdatedAt: accumulator.lastUpdatedAt
                )
            }
            .sorted { lhs, rhs in
                let leftScore = lhs.interactiveSessions + lhs.hotThreads + lhs.backgroundAgents
                let rightScore = rhs.interactiveSessions + rhs.hotThreads + rhs.backgroundAgents
                if leftScore == rightScore {
                    return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
                }
                return leftScore > rightScore
            }
    }

    private func deriveHealth(
        warningCount: Int,
        errorCount: Int,
        interactiveSessionCount: Int,
        backgroundAgentCount: Int
    ) -> DashboardHealth {
        // 关键逻辑：优先根据错误级别判断，再根据负载状态给出“繁忙”提示。
        if errorCount > 0 || warningCount >= 3 {
            return .warning
        }
        if interactiveSessionCount > 0 || backgroundAgentCount > 0 {
            return .busy
        }
        return .idle
    }

    private func buildActivitySignals(
        processes: [CodexProcess],
        hotThreads: [CodexThread],
        spawnedAgentThreads: [CodexThread],
        warnings: [CodexLogEvent],
        runningJobs: [CodexAgentJob]
    ) -> [ActivitySignal] {
        var signals: [ActivitySignal] = []

        if !processes.isEmpty {
            let interactiveSessions = processes.filter { $0.kind == .interactive }.count
            signals.append(
                ActivitySignal(
                    kind: .process,
                    title: "\(interactiveSessions) 个交互会话正在运行",
                    subtitle: "其中 app-server \(processes.filter { $0.kind == .appServer }.count) 个",
                    timestamp: .now
                )
            )
        }

        if let hottestThread = hotThreads.first {
            signals.append(
                ActivitySignal(
                    kind: .thread,
                    title: hottestThread.title,
                    subtitle: hottestThread.cwd,
                    timestamp: hottestThread.updatedAt
                )
            )
        }

        if !spawnedAgentThreads.isEmpty || !runningJobs.isEmpty {
            signals.append(
                ActivitySignal(
                    kind: .agent,
                    title: "\(spawnedAgentThreads.count + runningJobs.count) 个后台 Agent 仍在活跃",
                    subtitle: "spawn edges \(spawnedAgentThreads.count) + agent jobs \(runningJobs.count)",
                    timestamp: .now.addingTimeInterval(-20)
                )
            )
        }

        signals.append(contentsOf: warnings.prefix(6).map { warning in
            ActivitySignal(
                kind: .warning,
                title: "\(warning.level.uppercased()) · \(warning.target)",
                subtitle: warning.body.isEmpty ? "无附加日志正文" : warning.body,
                timestamp: warning.timestamp
            )
        })

        return signals.sorted { $0.timestamp > $1.timestamp }
    }

    private func buildNotes(processCount: Int, threadCount: Int, workspaceCount: Int) -> [String] {
        [
            "已读取 \(processCount) 个进程信号、\(threadCount) 条非归档线程、\(workspaceCount) 个活跃工作区。",
            "若你的 Codex 升级导致数据库结构变化，可直接用“导出诊断”附带现场数据提 issue。"
        ]
    }
}

private struct ParsedProcessLine {
    let pid: Int
    let parentPid: Int
    let cpuPercent: Double
    let memoryPercent: Double
    let elapsedTimeText: String
    let elapsedSeconds: Int
    let command: String
}

private struct ProjectAccumulator {
    let path: String
    var interactiveSessions: Int = 0
    var hotThreads: Int = 0
    var backgroundAgents: Int = 0
    var appServers: Int = 0
    var latestModelNames: Set<String> = []
    var latestTitles: [String] = []
    var lastUpdatedAt: Date?
}

private struct ThreadRow: Decodable {
    let id: String
    let title: String
    let source: String
    let cwd: String
    let archived: Int
    let model: String?
    let reasoningEffort: String?
    let agentNickname: String?
    let agentRole: String?
    let updatedAtMilliseconds: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case source
        case cwd
        case archived
        case model
        case reasoningEffort = "reasoning_effort"
        case agentNickname = "agent_nickname"
        case agentRole = "agent_role"
        case updatedAtMilliseconds = "updated_at_ms"
    }
}

private struct AgentJobRow: Decodable {
    let id: String
    let name: String
    let status: String
    let updatedAt: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case updatedAt = "updated_at"
    }
}

private struct LogRow: Decodable {
    let ts: Int
    let level: String
    let target: String
    let body: String
}

private struct RawGlobalState: Decodable {
    let activeWorkspaceRoots: [String]
    let projectOrder: [String]

    enum CodingKeys: String, CodingKey {
        case activeWorkspaceRoots = "active-workspace-roots"
        case projectOrder = "project-order"
    }
}
