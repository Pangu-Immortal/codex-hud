// 功能：管理 HUD 的可视化设置与持久化偏好。
// 函数简介：将刷新频率、热点窗口、项目过滤、告警过滤和显示数量存入 UserDefaults。

import Foundation

@MainActor
final class DashboardPreferences: ObservableObject {
    static let refreshIntervalOptions: [TimeInterval] = [3, 5, 10, 15, 30]
    static let hotWindowOptions: [TimeInterval] = [5 * 60, 15 * 60, 30 * 60, 60 * 60]

    @Published var codexHomePathOverride: String {
        didSet { persist() }
    }

    @Published var refreshIntervalSeconds: TimeInterval {
        didSet { persist() }
    }

    @Published var hotThreadWindowSeconds: TimeInterval {
        didSet { persist() }
    }

    @Published var projectScope: DashboardProjectScope {
        didSet { persist() }
    }

    @Published var warningFilter: DashboardWarningFilter {
        didSet { persist() }
    }

    @Published var maxVisibleProjects: Int {
        didSet { persist() }
    }

    @Published var maxVisibleProcesses: Int {
        didSet { persist() }
    }

    @Published var maxVisibleThreads: Int {
        didSet { persist() }
    }

    @Published var maxVisibleSignals: Int {
        didSet { persist() }
    }

    @Published var maxVisibleWarnings: Int {
        didSet { persist() }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let defaults = DashboardConfiguration.defaults
        codexHomePathOverride = userDefaults.string(forKey: Keys.codexHomePathOverride) ?? defaults.codexHomePathOverride
        refreshIntervalSeconds = userDefaults.object(forKey: Keys.refreshIntervalSeconds) as? Double ?? defaults.refreshIntervalSeconds
        hotThreadWindowSeconds = userDefaults.object(forKey: Keys.hotThreadWindowSeconds) as? Double ?? defaults.hotThreadWindowSeconds
        projectScope = DashboardProjectScope(rawValue: userDefaults.string(forKey: Keys.projectScope) ?? "") ?? defaults.projectScope
        warningFilter = DashboardWarningFilter(rawValue: userDefaults.string(forKey: Keys.warningFilter) ?? "") ?? defaults.warningFilter
        maxVisibleProjects = userDefaults.object(forKey: Keys.maxVisibleProjects) as? Int ?? defaults.maxVisibleProjects
        maxVisibleProcesses = userDefaults.object(forKey: Keys.maxVisibleProcesses) as? Int ?? defaults.maxVisibleProcesses
        maxVisibleThreads = userDefaults.object(forKey: Keys.maxVisibleThreads) as? Int ?? defaults.maxVisibleThreads
        maxVisibleSignals = userDefaults.object(forKey: Keys.maxVisibleSignals) as? Int ?? defaults.maxVisibleSignals
        maxVisibleWarnings = userDefaults.object(forKey: Keys.maxVisibleWarnings) as? Int ?? defaults.maxVisibleWarnings
    }

    var snapshot: DashboardConfiguration {
        DashboardConfiguration(
            codexHomePathOverride: codexHomePathOverride,
            refreshIntervalSeconds: refreshIntervalSeconds,
            hotThreadWindowSeconds: hotThreadWindowSeconds,
            projectScope: projectScope,
            warningFilter: warningFilter,
            maxVisibleProjects: maxVisibleProjects,
            maxVisibleProcesses: maxVisibleProcesses,
            maxVisibleThreads: maxVisibleThreads,
            maxVisibleSignals: maxVisibleSignals,
            maxVisibleWarnings: maxVisibleWarnings
        )
    }

    func resetToDefaults() {
        let defaults = DashboardConfiguration.defaults
        codexHomePathOverride = defaults.codexHomePathOverride
        refreshIntervalSeconds = defaults.refreshIntervalSeconds
        hotThreadWindowSeconds = defaults.hotThreadWindowSeconds
        projectScope = defaults.projectScope
        warningFilter = defaults.warningFilter
        maxVisibleProjects = defaults.maxVisibleProjects
        maxVisibleProcesses = defaults.maxVisibleProcesses
        maxVisibleThreads = defaults.maxVisibleThreads
        maxVisibleSignals = defaults.maxVisibleSignals
        maxVisibleWarnings = defaults.maxVisibleWarnings
        persist()
    }

    private func persist() {
        // 关键逻辑：所有设置都以基础标量存储，避免版本演进时整包解码失败。
        userDefaults.set(codexHomePathOverride, forKey: Keys.codexHomePathOverride)
        userDefaults.set(refreshIntervalSeconds, forKey: Keys.refreshIntervalSeconds)
        userDefaults.set(hotThreadWindowSeconds, forKey: Keys.hotThreadWindowSeconds)
        userDefaults.set(projectScope.rawValue, forKey: Keys.projectScope)
        userDefaults.set(warningFilter.rawValue, forKey: Keys.warningFilter)
        userDefaults.set(maxVisibleProjects, forKey: Keys.maxVisibleProjects)
        userDefaults.set(maxVisibleProcesses, forKey: Keys.maxVisibleProcesses)
        userDefaults.set(maxVisibleThreads, forKey: Keys.maxVisibleThreads)
        userDefaults.set(maxVisibleSignals, forKey: Keys.maxVisibleSignals)
        userDefaults.set(maxVisibleWarnings, forKey: Keys.maxVisibleWarnings)
    }
}

private enum Keys {
    static let codexHomePathOverride = "codexHUD.codexHomePathOverride"
    static let refreshIntervalSeconds = "codexHUD.refreshIntervalSeconds"
    static let hotThreadWindowSeconds = "codexHUD.hotThreadWindowSeconds"
    static let projectScope = "codexHUD.projectScope"
    static let warningFilter = "codexHUD.warningFilter"
    static let maxVisibleProjects = "codexHUD.maxVisibleProjects"
    static let maxVisibleProcesses = "codexHUD.maxVisibleProcesses"
    static let maxVisibleThreads = "codexHUD.maxVisibleThreads"
    static let maxVisibleSignals = "codexHUD.maxVisibleSignals"
    static let maxVisibleWarnings = "codexHUD.maxVisibleWarnings"
}
