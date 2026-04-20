# Architecture

## Overview

Codex HUD is a native macOS menu bar app that turns local Codex execution traces into a compact operational dashboard.

## Layers

### 1. Process Layer

Files:

- `Sources/CodexHUD/ProcessExecutor.swift`
- `Sources/CodexHUD/CodexDataSources.swift`

Responsibilities:

- run `ps`
- resolve cwd with `lsof`
- classify interactive Codex vs `app-server`

### 2. State Layer

Reads `~/.codex/state_5.sqlite` and extracts:

- non-archived threads
- spawned child threads
- agent jobs

This is where Codex HUD finds “hot threads” and part of the background agent signal.

### 3. Log Layer

Reads `~/.codex/logs_2.sqlite` and extracts recent:

- `WARN`
- `ERROR`

This powers the warning cards and the signal stream.

### 4. Workspace Layer

Reads `~/.codex/.codex-global-state.json` and extracts:

- active workspace roots
- project order

This lets project cards prioritize what the user is actively working on.

### 5. Aggregation Layer

`CodexSnapshotBuilder` merges all signals into one `DashboardSnapshot`.

That snapshot is the single source of truth for:

- menu bar label
- HUD panel
- diagnostics export
- marketing screenshot generation

### 6. Preferences Layer

Files:

- `Sources/CodexHUD/DashboardPreferences.swift`
- `Sources/CodexHUD/AppModel.swift`

Responsibilities:

- persist local display settings with `UserDefaults`
- control refresh interval and hot thread window
- filter project scope and warning severity
- cap visible item counts for each section

## Why Not Use One Source?

Because “what Codex is doing right now” is spread across multiple local surfaces.

- Process list tells you what is alive now.
- SQLite state tells you what threads and jobs exist.
- Log history tells you what recently failed or warned.

Using only one of them would make the HUD misleading.
