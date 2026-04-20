# Codex HUD

<div align="center">

![Codex HUD Visitor Count](https://count.getloli.com/get/@codex-hud?theme=rule34)

<p>
  <b>如果这个项目对你有帮助，欢迎给仓库点一个 <a href="https://github.com/Pangu-Immortal/codex-hud/stargazers">Star</a>。</b>
</p>

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-black.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-339933.svg)](https://nodejs.org)
[![Codex CLI](https://img.shields.io/badge/OpenAI-Codex%20CLI-10a37f.svg)](https://openai.com/codex)
[![Terminal HUD](https://img.shields.io/badge/UI-CLI%20HUD-purple.svg)](LICENSE)

[简体中文](README.md) | [English](README.en.md)

</div>

> 只面向 `Codex CLI` 的跨平台终端 HUD。它不是菜单栏应用，也不是桌面端插件，而是直接包裹 `codex` 命令，在同一个终端顶部保留 HUD，下面继续正常使用 Codex。

## 它解决什么问题

如果你的唯一工作方式是：

```bash
codex
```

那么你真正想要的是：

- 终端里直接看到 HUD
- 不跳出当前 CLI 工作流
- macOS / Linux / Windows 行为一致
- 还能实时看到会话数、热点线程、后台 Agent 估算、告警数

`Codex HUD` 的目标就是这个，而不是系统菜单栏。

## 当前能力

- `codex-hud snapshot`
  直接输出当前 `Codex` 状态快照
- `codex-hud run -- codex`
  直接包裹交互式 Codex CLI，会在终端顶部保留 HUD
- 支持紧凑模式与主题
  - `--compact`
  - `--theme cyan|amber|plain`
- 支持输出限额
  - `--project-limit`
  - `--warning-limit`
- 基于真实本地状态生成 HUD
  - `~/.codex/state_5.sqlite`
  - `~/.codex/logs_2.sqlite`
  - `~/.codex/log/*.log`
  - 当前工作目录
- 非交互命令自动直通
  - 例如 `codex --version`
  - 不强行加 HUD

## 安装

### 环境要求

- Node.js 20+
- 本机已安装并可运行 `codex`

### 本地开发运行

```bash
git clone git@github.com:Pangu-Immortal/codex-hud.git
cd codex-hud
npm install
npm run build
```

### 全局安装

```bash
npm install -g .
codex-hud snapshot
codex-hud run -- codex
```

## 使用方式

### 1. 看当前快照

```bash
npx tsx src/index.ts snapshot
```

JSON 版本：

```bash
npx tsx src/index.ts snapshot --json
```

紧凑模式：

```bash
npx tsx src/index.ts snapshot --compact --theme plain
```

### 2. 包裹 Codex 交互会话

```bash
npx tsx src/index.ts run -- codex
```

如果已经全局安装：

```bash
codex-hud run -- codex
```

带初始提示词：

```bash
npx tsx src/index.ts run -- codex "分析当前项目"
```

带自定义 `codex home`：

```bash
npx tsx src/index.ts run -- --codex-home ~/.codex codex
```

紧凑 HUD：

```bash
codex-hud run --compact --theme amber -- codex
```

限制快照输出：

```bash
codex-hud snapshot --project-limit 3 --warning-limit 2
```

## 本地配置文件

支持在用户目录下放一个 `~/.codex-hud.json`，避免每次都手写参数。

示例：

```json
{
  "refreshMs": 1200,
  "hotThreadWindowMs": 900000,
  "compact": false,
  "theme": "cyan",
  "projectLimit": 5,
  "warningLimit": 3
}
```

## 技术边界

当前 `Codex CLI` 没有像 Claude Code 那样清晰公开的原生 statusline 插件入口，所以这个项目采用的是 **wrapper / sidecar** 方案，而不是硬塞进 Codex 自己的 TUI 内部。

也就是说：

- 它是“CLI 内 HUD”
- 但不是 Codex 官方内建状态栏 API
- 它通过终端顶部保留 HUD、下方继续跑 Codex 会话来逼近这种体验

## 访问计数

这个仓库默认展示访问计数器，和我名下其他开源项目保持同一风格：

```markdown
![Codex HUD Visitor Count](https://count.getloli.com/get/@codex-hud?theme=rule34)
```

## Star 趋势

[![Star History Chart](https://api.star-history.com/svg?repos=Pangu-Immortal/codex-hud&type=Date)](https://www.star-history.com/#Pangu-Immortal/codex-hud&Date)

## 开发命令

```bash
npm install
npm run build
npm test
npm run snapshot
npm run start
```

## 许可证

MIT，见 [LICENSE](LICENSE)。
