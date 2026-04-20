# FAQ

## Is Codex HUD official?

No. It is an open-source third-party utility for OpenAI Codex users on macOS.

## Does it really show background agent count?

It shows a practical estimate by merging:

- spawned child threads
- active agent jobs
- recent thread activity

This is more honest than inventing a fake single source.

## Does it read my code?

It reads local Codex metadata and logs from `~/.codex`. It does not scan your repositories recursively.

## Can it work without the Codex app?

Yes. If local Codex CLI state exists and Codex-related processes are running, the HUD can still extract useful signals.

## Can I tune the HUD without editing code?

Yes.

The current settings window supports:

- refresh interval
- hot thread window
- project scope
- warning filter
- visible item limits
- custom Codex data directory override

## Why macOS first?

This project is currently optimized for the macOS menu bar experience and uses SwiftUI + AppKit.

## Can I generate the screenshot in CI?

Yes.

```bash
swift run codex-hud --render-demo-screenshot docs/images/generated/codex-hud-preview.png
```

## What should I do if Codex changes its internal schema?

1. Export diagnostics from the HUD.
2. Open an issue with the exported JSON.
3. Include your Codex version and a short reproduction note.
