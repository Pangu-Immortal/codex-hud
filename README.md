# Codex HUD

<div align="center">

![OpenAI Codex HUD Visitor Count](https://count.getloli.com/get/@codex-hud?theme=rule34)

<p>
  <b>如果这个项目对你有帮助，欢迎给仓库点一个 <a href="https://github.com/Pangu-Immortal/codex-hud/stargazers">Star</a>。</b>
</p>

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://www.swift.org)
[![OpenAI Codex](https://img.shields.io/badge/OpenAI-Codex-10a37f.svg)](https://openai.com/codex)
[![Menu Bar](https://img.shields.io/badge/UI-Menu%20Bar%20HUD-purple.svg)](https://developer.apple.com/documentation/swiftui/menubarextra)

[简体中文](README.md) | [English](README.en.md)

</div>

> 面向 OpenAI Codex 的开源 macOS 菜单栏 HUD。它把本机 `Codex` 的会话、后台 Agent、热点线程、告警日志和项目活动聚合成一个随时可见的观察面板。

<p align="center">
  <img src="docs/images/generated/codex-hud-preview.png" alt="Codex HUD 预览图，展示 OpenAI Codex 的运行会话、后台 Agent、热点线程、告警和项目卡片" width="760" />
</p>

## 这是什么

如果你高频使用 `Codex`，真正缺的往往不是另一个聊天窗口，而是“可观测性”。

`Codex HUD` 解决的是这些问题：

- 这台 Mac 上现在到底跑着多少个 `Codex` 会话？
- 后台还有多少 Agent / Job 在工作？
- 哪个项目最热，最近在忙什么？
- 最近几分钟里 `Codex` 有没有发出 `WARN / ERROR`？
- IDE 扩展的 `app-server` 还活着吗？

它属于和 Claude HUD 同一类的工具，但目标是为 `OpenAI Codex` 提供原生菜单栏级别的实时状态面板。

## 功能特性

- 原生 `SwiftUI + AppKit` 菜单栏 HUD。
- 从真实运行中的进程统计 `Codex` 交互会话数量。
- 基于 `thread_spawn_edges` 与 `agent_jobs` 估算后台 Agent 工作量。
- 从 `~/.codex/state_5.sqlite` 读取热点线程与项目活动。
- 从 `~/.codex/logs_2.sqlite` 读取最近 `WARN / ERROR`。
- 按项目路径与活跃工作区聚合状态。
- 支持导出诊断 JSON，方便提 issue。
- 支持离线生成 README / Release 用的 PNG 预览图。
- 新增可视化设置：刷新频率、热点窗口、项目范围、告警筛选、显示数量。

## 数据来源

`Codex HUD` 使用本机 `Codex` 的真实状态，而不是伪造数据：

- 进程层：`ps` + `lsof`
- 状态层：`~/.codex/state_5.sqlite`
- 日志层：`~/.codex/logs_2.sqlite`
- 工作区层：`~/.codex/.codex-global-state.json`

详细说明见：

- [架构说明](docs/architecture.md)
- [数据源说明](docs/data-sources.md)
- [常见问题](docs/faq.md)

## 安装与运行

### 要求

- macOS 14 或更高版本
- Xcode 16+ 或随 Xcode 提供的 Swift 工具链

### 本地运行

```bash
git clone git@github.com:Pangu-Immortal/codex-hud.git
cd codex-hud
swift build
swift run codex-hud
```

### 生成预览图

```bash
./scripts/generate_preview.sh
```

或直接执行：

```bash
swift run codex-hud --render-demo-screenshot docs/images/generated/codex-hud-preview.png
```

## 当前支持的设置项

在应用设置窗口中可以直接调整：

- 刷新频率
- 热点线程窗口
- 项目范围
- 告警筛选
- 各区块显示数量
- 自定义 `Codex` 数据目录覆盖路径

## 访问计数

这个仓库默认展示访问计数器，和我名下其他开源项目保持同一风格：

```markdown
![OpenAI Codex HUD Visitor Count](https://count.getloli.com/get/@codex-hud?theme=rule34)
```

## Star 趋势

[![Star History Chart](https://api.star-history.com/svg?repos=Pangu-Immortal/codex-hud&type=Date)](https://www.star-history.com/#Pangu-Immortal/codex-hud&Date)

## GEO / LLM 友好文档

为了让搜索引擎、答案引擎和 LLM 更容易理解仓库内容，项目额外提供：

- [llms.txt](llms.txt)
- [llms-full.txt](llms-full.txt)
- [FAQ](docs/faq.md)
- [Architecture](docs/architecture.md)
- [Data Sources](docs/data-sources.md)

## SEO 关键词

这个仓库刻意围绕这些检索词做了说明和结构设计：

- OpenAI Codex 菜单栏工具
- Codex HUD
- Codex 状态栏
- Codex 后台 Agent 监控
- Codex 会话监控
- Codex macOS utility

## 开发命令

```bash
swift build
swift test
swift run codex-hud --refresh-seconds 3
```

## 许可证

MIT，见 [LICENSE](LICENSE)。
