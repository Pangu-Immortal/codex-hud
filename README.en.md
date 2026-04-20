# Codex HUD

<div align="center">

![Codex HUD Visitor Count](https://count.getloli.com/get/@codex-hud?theme=rule34)

<p>
  <b>If this project helps you, please <a href="https://github.com/Pangu-Immortal/codex-hud/stargazers">Star</a> the repo.</b>
</p>

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-black.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-339933.svg)](https://nodejs.org)
[![Codex CLI](https://img.shields.io/badge/OpenAI-Codex%20CLI-10a37f.svg)](https://openai.com/codex)
[![Terminal HUD](https://img.shields.io/badge/UI-CLI%20HUD-purple.svg)](LICENSE)

[简体中文](README.md) | [English](README.en.md)

</div>

> A cross-platform terminal HUD built only for `Codex CLI`. It is not a menu bar app and not a desktop plugin. It wraps the `codex` command so the HUD stays at the top of the same terminal while Codex keeps running below it.

## What It Solves

If your only workflow is:

```bash
codex
```

then what you really want is:

- a HUD directly inside the terminal
- no context switch away from CLI
- consistent behavior on macOS, Linux, and Windows
- live visibility into session count, hot threads, estimated background agents, and warnings

That is the actual target of `Codex HUD`.

## Current Capabilities

- `codex-hud snapshot`
  prints the current Codex status snapshot
- `codex-hud run -- codex`
  wraps an interactive Codex CLI session and keeps a HUD at the top of the terminal
- supports compact mode and themes
  - `--compact`
  - `--theme cyan|amber|plain`
- supports output limits
  - `--project-limit`
  - `--warning-limit`
- reads real local Codex state
  - `~/.codex/state_5.sqlite`
  - `~/.codex/logs_2.sqlite`
  - `~/.codex/log/*.log`
  - current workspace
- non-interactive commands bypass the HUD
  - for example `codex --version`

## Install

### Requirements

- Node.js 20+
- `codex` installed and available locally

### Local Development

```bash
git clone git@github.com:Pangu-Immortal/codex-hud.git
cd codex-hud
npm install
npm run build
```

### Global Install

```bash
npm install -g .
codex-hud snapshot
codex-hud run -- codex
```

## Usage

### 1. Print a snapshot

```bash
npx tsx src/index.ts snapshot
```

JSON mode:

```bash
npx tsx src/index.ts snapshot --json
```

Compact mode:

```bash
npx tsx src/index.ts snapshot --compact --theme plain
```

### 2. Wrap an interactive Codex session

```bash
npx tsx src/index.ts run -- codex
```

If installed globally:

```bash
codex-hud run -- codex
```

With an initial prompt:

```bash
npx tsx src/index.ts run -- codex "Analyze the current project"
```

With a custom `codex home`:

```bash
npx tsx src/index.ts run -- --codex-home ~/.codex codex
```

Compact HUD:

```bash
codex-hud run --compact --theme amber -- codex
```

Limit snapshot output:

```bash
codex-hud snapshot --project-limit 3 --warning-limit 2
```

## Local Config File

You can place a `~/.codex-hud.json` file to avoid repeating the same flags.

Example:

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

## Technical Boundary

At the moment, `Codex CLI` does not expose a clearly documented native statusline plugin API like Claude Code. So this project uses a **wrapper / sidecar** approach instead of injecting directly into Codex internals.

That means:

- it is a terminal HUD
- but not an official built-in Codex statusline API
- it approximates that experience by reserving a HUD area at the top of the terminal

## Visitor Counter

This repository uses the same visitor counter style as my other open-source projects:

```markdown
![Codex HUD Visitor Count](https://count.getloli.com/get/@codex-hud?theme=rule34)
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Pangu-Immortal/codex-hud&type=Date)](https://www.star-history.com/#Pangu-Immortal/codex-hud&Date)

## Development Commands

```bash
npm install
npm run build
npm test
npm run snapshot
npm run start
```

## License

MIT. See [LICENSE](LICENSE).
