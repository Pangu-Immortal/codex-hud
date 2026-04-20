# Data Sources

## `ps`

Purpose:

- enumerate live Codex-related processes
- compute interactive session count

Why it matters:

- it is the strongest signal for “running now”

## `lsof`

Purpose:

- map a PID to its current working directory

Why it matters:

- users care about projects, not just PIDs

## `~/.codex/state_5.sqlite`

Tables used:

- `threads`
- `thread_spawn_edges`
- `agent_jobs`

Purpose:

- hot thread list
- background agent estimate

## `~/.codex/logs_2.sqlite`

Tables used:

- `logs`

Purpose:

- recent warning and error signal
- operator visibility into failures

## `~/.codex/.codex-global-state.json`

Fields used:

- `active-workspace-roots`
- `project-order`

Purpose:

- highlight which workspaces are active in the Codex app / environment

## Reliability Notes

- These sources are local implementation details and may evolve.
- Codex HUD is built to fail softly: empty arrays are preferred over crashes.
- Diagnostics export is included so regressions can be reported with context.
