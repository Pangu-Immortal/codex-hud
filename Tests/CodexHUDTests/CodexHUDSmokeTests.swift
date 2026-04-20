// 功能：提供最小烟雾测试，确保核心演示快照保持稳定。
// 函数简介：验证 demo 数据结构与关键统计值，防止 README 截图生成链路退化。

import XCTest
@testable import CodexHUD

final class CodexHUDSmokeTests: XCTestCase {
    func testDemoSnapshotHasRichContent() {
        XCTAssertGreaterThan(DashboardSnapshot.demo.interactiveSessionCount, 0)
        XCTAssertGreaterThan(DashboardSnapshot.demo.backgroundAgentCount, 0)
        XCTAssertFalse(DashboardSnapshot.demo.projects.isEmpty)
        XCTAssertFalse(DashboardSnapshot.demo.activitySignals.isEmpty)
    }

    func testWarningFilterMatchesExpectedLevels() {
        let warning = CodexLogEvent(timestamp: .now, level: "WARN", target: "codex", body: "warn")
        let error = CodexLogEvent(timestamp: .now, level: "ERROR", target: "codex", body: "error")

        XCTAssertTrue(DashboardWarningFilter.all.matches(warning))
        XCTAssertTrue(DashboardWarningFilter.all.matches(error))
        XCTAssertTrue(DashboardWarningFilter.warningsOnly.matches(warning))
        XCTAssertFalse(DashboardWarningFilter.warningsOnly.matches(error))
        XCTAssertFalse(DashboardWarningFilter.errorsOnly.matches(warning))
        XCTAssertTrue(DashboardWarningFilter.errorsOnly.matches(error))
    }

    func testRuntimeAppliesPreferenceOverrides() {
        let baseRuntime = AppRuntime(
            codexHome: URL(fileURLWithPath: "/tmp/base"),
            screenshotOutputURL: nil,
            refreshIntervalSeconds: 5,
            hotThreadWindowSeconds: 900
        )
        let configuration = DashboardConfiguration(
            codexHomePathOverride: "/tmp/override",
            refreshIntervalSeconds: 10,
            hotThreadWindowSeconds: 1800,
            projectScope: .activeWorkspaceOnly,
            warningFilter: .errorsOnly,
            maxVisibleProjects: 4,
            maxVisibleProcesses: 4,
            maxVisibleThreads: 4,
            maxVisibleSignals: 6,
            maxVisibleWarnings: 4
        )

        let effectiveRuntime = baseRuntime.applying(configuration)
        XCTAssertEqual(effectiveRuntime.codexHome.path, "/tmp/override")
        XCTAssertEqual(effectiveRuntime.refreshIntervalSeconds, 10)
        XCTAssertEqual(effectiveRuntime.hotThreadWindowSeconds, 1800)
    }
}
