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
}
