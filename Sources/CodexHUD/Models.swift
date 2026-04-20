// 功能：定义 Codex HUD 的核心模型与运行时配置。
// 函数简介：承载会话、线程、项目、日志信号、聚合快照与演示数据。

import Foundation

struct AppRuntime: Sendable {
    // 关键逻辑：允许通过参数覆盖 `.codex` 目录，方便调试或截图脚本复用。
    let codexHome: URL
    let screenshotOutputURL: URL?
    let refreshIntervalSeconds: TimeInterval
    let hotThreadWindowSeconds: TimeInterval

    init(arguments: [String]) {
        var mutableCodexHome = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex")
        var mutableScreenshotOutputURL: URL?
        var mutableRefreshIntervalSeconds: TimeInterval = 5
        var mutableHotThreadWindowSeconds: TimeInterval = 15 * 60

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--codex-home", arguments.indices.contains(index + 1) {
                mutableCodexHome = URL(fileURLWithPath: arguments[index + 1]).standardizedFileURL
                index += 2
                continue
            }
            if argument == "--render-demo-screenshot", arguments.indices.contains(index + 1) {
                mutableScreenshotOutputURL = URL(fileURLWithPath: arguments[index + 1]).standardizedFileURL
                index += 2
                continue
            }
            if argument == "--refresh-seconds", arguments.indices.contains(index + 1) {
                mutableRefreshIntervalSeconds = TimeInterval(arguments[index + 1]) ?? mutableRefreshIntervalSeconds
                index += 2
                continue
            }
            if argument == "--hot-thread-seconds", arguments.indices.contains(index + 1) {
                mutableHotThreadWindowSeconds = TimeInterval(arguments[index + 1]) ?? mutableHotThreadWindowSeconds
                index += 2
                continue
            }
            index += 1
        }

        codexHome = mutableCodexHome
        screenshotOutputURL = mutableScreenshotOutputURL
        refreshIntervalSeconds = mutableRefreshIntervalSeconds
        hotThreadWindowSeconds = mutableHotThreadWindowSeconds
    }
}

struct DashboardSnapshot: Codable, Equatable {
    let generatedAt: Date
    let codexHomePath: String
    let interactiveSessionCount: Int
    let appServerCount: Int
    let hotThreadCount: Int
    let backgroundAgentCount: Int
    let queuedJobCount: Int
    let warningCount: Int
    let errorCount: Int
    let activeWorkspaces: [String]
    let projects: [ProjectSnapshot]
    let processes: [CodexProcess]
    let hotThreads: [CodexThread]
    let activitySignals: [ActivitySignal]
    let recentWarnings: [CodexLogEvent]
    let health: DashboardHealth
    let notes: [String]

    static let empty = DashboardSnapshot(
        generatedAt: .now,
        codexHomePath: "",
        interactiveSessionCount: 0,
        appServerCount: 0,
        hotThreadCount: 0,
        backgroundAgentCount: 0,
        queuedJobCount: 0,
        warningCount: 0,
        errorCount: 0,
        activeWorkspaces: [],
        projects: [],
        processes: [],
        hotThreads: [],
        activitySignals: [],
        recentWarnings: [],
        health: .idle,
        notes: ["等待首次采集 Codex 状态。"]
    )

    static let demo = DashboardSnapshot(
        generatedAt: .now,
        codexHomePath: "/Users/demo/.codex",
        interactiveSessionCount: 4,
        appServerCount: 1,
        hotThreadCount: 6,
        backgroundAgentCount: 3,
        queuedJobCount: 2,
        warningCount: 2,
        errorCount: 1,
        activeWorkspaces: [
            "/Users/demo/Projects/FireflyWallpaper",
            "/Users/demo/Projects/CodeBuddy"
        ],
        projects: [
            ProjectSnapshot(
                path: "/Users/demo/Projects/CodeBuddy",
                displayName: "CodeBuddy",
                interactiveSessions: 2,
                hotThreads: 3,
                backgroundAgents: 2,
                appServers: 1,
                latestModelNames: ["gpt-5.4", "gpt-5.3-codex"],
                latestTitles: ["构建 Codex HUD 菜单栏项目", "迁移 Claude 配置到 Codex"],
                workspaceActive: true,
                lastUpdatedAt: .now.addingTimeInterval(-45)
            ),
            ProjectSnapshot(
                path: "/Users/demo/Projects/FireflyWallpaper",
                displayName: "FireflyWallpaper",
                interactiveSessions: 1,
                hotThreads: 2,
                backgroundAgents: 1,
                appServers: 0,
                latestModelNames: ["gpt-5.4"],
                latestTitles: ["批量优化启动页设计稿", "修复设计系统映射"],
                workspaceActive: true,
                lastUpdatedAt: .now.addingTimeInterval(-130)
            ),
            ProjectSnapshot(
                path: "/Users/demo/Projects/mengqi",
                displayName: "mengqi",
                interactiveSessions: 1,
                hotThreads: 1,
                backgroundAgents: 0,
                appServers: 0,
                latestModelNames: ["gpt-5.4"],
                latestTitles: ["阶段一阅读源码"],
                workspaceActive: false,
                lastUpdatedAt: .now.addingTimeInterval(-420)
            )
        ],
        processes: [
            CodexProcess(
                pid: 97290,
                parentPid: 97289,
                cpuPercent: 3.6,
                memoryPercent: 0.3,
                elapsedTimeText: "14:10",
                elapsedSeconds: 850,
                command: "/opt/homebrew/lib/node_modules/@openai/codex/.../codex/codex",
                workingDirectory: "/Users/demo/Projects/CodeBuddy",
                kind: .interactive
            ),
            CodexProcess(
                pid: 58910,
                parentPid: 58908,
                cpuPercent: 0.0,
                memoryPercent: 0.0,
                elapsedTimeText: "04-20:33:43",
                elapsedSeconds: 361_000,
                command: "/Users/demo/.vscode/extensions/openai.chatgpt/bin/codex app-server --analytics-default-enabled",
                workingDirectory: "/Users/demo/Projects/CodeBuddy",
                kind: .appServer
            )
        ],
        hotThreads: [
            CodexThread(
                id: "019da970-6cbf-7130-8211-5c445ee323ea",
                title: "创建 Codex HUD 开源项目",
                source: "cli",
                cwd: "/Users/demo/Projects/CodeBuddy",
                updatedAt: .now.addingTimeInterval(-30),
                archived: false,
                model: "gpt-5.4",
                reasoningEffort: "xhigh",
                agentNickname: nil,
                agentRole: nil
            ),
            CodexThread(
                id: "019da954-9518-78d3-b0c5-870417a380b3",
                title: "继续阶段一阅读目录",
                source: "cli",
                cwd: "/Users/demo/Projects/mengqi",
                updatedAt: .now.addingTimeInterval(-180),
                archived: false,
                model: "gpt-5.4",
                reasoningEffort: "high",
                agentNickname: nil,
                agentRole: nil
            )
        ],
        activitySignals: [
            ActivitySignal(
                kind: .agent,
                title: "3 个后台 Agent 仍在活跃",
                subtitle: "来自 spawn edges + agent jobs 聚合结果",
                timestamp: .now.addingTimeInterval(-15)
            ),
            ActivitySignal(
                kind: .process,
                title: "4 个交互会话正在运行",
                subtitle: "CodeBuddy 占 2 个，FireflyWallpaper 占 1 个",
                timestamp: .now.addingTimeInterval(-40)
            ),
            ActivitySignal(
                kind: .warning,
                title: "检测到 1 条高优先级错误",
                subtitle: "建议打开诊断 JSON，排查最近一小时失败日志",
                timestamp: .now.addingTimeInterval(-80)
            )
        ],
        recentWarnings: [
            CodexLogEvent(
                timestamp: .now.addingTimeInterval(-90),
                level: "WARN",
                target: "codex_app_server::background_sync",
                body: "background sync delayed because the owning thread is waiting for approvals"
            ),
            CodexLogEvent(
                timestamp: .now.addingTimeInterval(-220),
                level: "ERROR",
                target: "codex_agent::runtime",
                body: "agent worker hit a transient tool error and scheduled a retry"
            )
        ],
        health: .busy,
        notes: [
            "三路信号融合：进程 + SQLite 状态库 + 日志事件。",
            "菜单栏标签优先展示交互会话数与后台 Agent 数。"
        ]
    )
}

enum DashboardHealth: String, Codable, Equatable {
    case healthy
    case busy
    case warning
    case idle

    var title: String {
        switch self {
        case .healthy:
            return "健康"
        case .busy:
            return "繁忙"
        case .warning:
            return "告警"
        case .idle:
            return "空闲"
        }
    }
}

struct ProjectSnapshot: Codable, Equatable, Identifiable {
    var id: String { path }

    let path: String
    let displayName: String
    let interactiveSessions: Int
    let hotThreads: Int
    let backgroundAgents: Int
    let appServers: Int
    let latestModelNames: [String]
    let latestTitles: [String]
    let workspaceActive: Bool
    let lastUpdatedAt: Date?
}

struct CodexProcess: Codable, Equatable, Identifiable {
    let pid: Int
    let parentPid: Int
    let cpuPercent: Double
    let memoryPercent: Double
    let elapsedTimeText: String
    let elapsedSeconds: Int
    let command: String
    let workingDirectory: String?
    let kind: ProcessKind

    var id: Int { pid }
}

enum ProcessKind: String, Codable, Equatable {
    case interactive
    case appServer
}

struct CodexThread: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let source: String
    let cwd: String
    let updatedAt: Date
    let archived: Bool
    let model: String?
    let reasoningEffort: String?
    let agentNickname: String?
    let agentRole: String?
}

struct CodexAgentJob: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let status: String
    let updatedAt: Date
}

struct CodexLogEvent: Codable, Equatable, Identifiable {
    let timestamp: Date
    let level: String
    let target: String
    let body: String

    var id: String {
        "\(timestamp.timeIntervalSince1970)-\(level)-\(target)"
    }
}

struct ActivitySignal: Codable, Equatable, Identifiable {
    let kind: ActivitySignalKind
    let title: String
    let subtitle: String
    let timestamp: Date

    var id: String {
        "\(kind.rawValue)-\(title)-\(timestamp.timeIntervalSince1970)"
    }
}

enum ActivitySignalKind: String, Codable, Equatable {
    case process
    case thread
    case agent
    case warning
}

struct CodexGlobalState: Codable, Equatable {
    let activeWorkspaceRoots: [String]
    let projectOrder: [String]
}
