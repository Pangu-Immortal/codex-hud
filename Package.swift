// 功能：定义 Codex HUD 的 Swift Package 构建配置。
// 函数简介：声明 macOS 菜单栏应用目标、最低系统版本与测试目标。

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "codex-hud",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "codex-hud",
            targets: ["CodexHUD"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CodexHUD",
            path: "Sources/CodexHUD",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Combine")
            ]
        ),
        .testTarget(
            name: "CodexHUDTests",
            dependencies: ["CodexHUD"],
            path: "Tests/CodexHUDTests"
        )
    ]
)
