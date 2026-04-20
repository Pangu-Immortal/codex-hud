# Codex HUD

Open-source macOS menu bar HUD for OpenAI Codex. It shows live Codex sessions, background agent activity, hot threads, warning logs, and project-level status in one focused menu bar panel.

<p>
  <img src="docs/images/generated/codex-hud-preview.png" alt="Codex HUD preview showing OpenAI Codex sessions, background agents, hot threads, warnings, and project cards in a macOS menu bar dashboard" width="760" />
</p>

## Why This Exists

If you use Codex heavily, the missing piece is not another chat pane. It is observability.

`Codex HUD` is built for people who want to answer questions like these at a glance:

- How many Codex sessions are currently running on this Mac?
- Are there any background agents still working?
- Which projects are hot right now?
- Did Codex emit warnings or errors in the last few minutes?
- Is the IDE extension app-server alive?

This project targets the same category as Claude HUD or statusline utilities, but for OpenAI Codex on macOS.

## Features

- Live menu bar window for OpenAI Codex on macOS.
- Counts interactive Codex sessions from real running processes.
- Estimates background agent workload from `thread_spawn_edges` and `agent_jobs`.
- Reads hot threads from `~/.codex/state_5.sqlite`.
- Reads recent warning and error logs from `~/.codex/logs_2.sqlite`.
- Groups status by project path and active workspace roots.
- Exports a JSON diagnostics snapshot for bug reports.
- Generates a marketing screenshot from SwiftUI for README and release assets.

## Data Sources

Codex HUD uses real local Codex state. It does not fake metrics.

- Process layer: `ps` + `lsof`
- Thread layer: `~/.codex/state_5.sqlite`
- Log layer: `~/.codex/logs_2.sqlite`
- Workspace layer: `~/.codex/.codex-global-state.json`

More detail: [Architecture](docs/architecture.md) · [Data Sources](docs/data-sources.md)

## Install

### Requirements

- macOS 14 or later
- Xcode 16+ or the Swift toolchain bundled with Xcode

### Run Locally

```bash
git clone https://github.com/Pangu-Immortal/codex-hud.git
cd codex-hud
swift build
swift run codex-hud
```

### Generate Preview Screenshot

```bash
./scripts/generate_preview.sh
```

Or directly:

```bash
swift run codex-hud --render-demo-screenshot docs/images/generated/codex-hud-preview.png
```

## Usage

Launch the app, then click the menu bar item. The label shows:

- left number: interactive Codex sessions
- right number: estimated background agent count

Inside the panel you get:

- Core metrics
- Project cards
- Running processes
- Hot threads
- Activity signals
- Recent warnings
- JSON export shortcut

## How Background Agent Count Works

Codex does not currently expose one public “agent count” field for local macOS users. So Codex HUD merges multiple signals:

1. child threads from `thread_spawn_edges`
2. active rows from `agent_jobs`
3. recent thread update timestamps

That gives a practical approximation of “how much Codex is still doing in the background” instead of pretending there is one perfect source.

## SEO Keywords

This repository is intentionally optimized for discoverability around:

- OpenAI Codex menu bar app
- Codex status bar
- Codex HUD
- Codex background agent monitor
- Codex session monitor
- Codex macOS utility

## GEO / LLM-Friendly Docs

This repository also includes machine-readable docs for AI tools and answer engines:

- [llms.txt](llms.txt)
- [llms-full.txt](llms-full.txt)
- [FAQ](docs/faq.md)
- [Architecture](docs/architecture.md)
- [Data Sources](docs/data-sources.md)

## Roadmap

- Click-through drill down into a specific thread or project
- Configurable refresh interval and thresholds
- Native preferences window
- Log severity filters
- Optional notifications for new Codex errors
- Release packaging as a standalone `.app`

## Development

```bash
swift build
swift test
swift run codex-hud --refresh-seconds 3
```

## License

MIT. See [LICENSE](LICENSE).
