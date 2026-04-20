/**
 * 功能：验证 CLI 参数解析与 HUD 渲染的基础行为。
 * 函数简介：用最小单元测试保证 snapshot/run 命令和 HUD 文本渲染稳定。
 */

import test from "node:test";
import assert from "node:assert/strict";
import { parseCli } from "./cli";
import { getHudHeight, renderHud } from "./render";
import type { HudSnapshot } from "./types";

test("parseCli 能识别 snapshot json 参数", () => {
  const parsed = parseCli(["snapshot", "--json"]);
  assert.equal(parsed.command, "snapshot");
  assert.equal(parsed.rawJson, true);
  assert.equal(parsed.theme, "cyan");
});

test("parseCli 能保留 run 子命令", () => {
  const parsed = parseCli(["run", "--", "codex", "分析当前目录"]);
  assert.equal(parsed.command, "run");
  assert.deepEqual(parsed.childCommand, ["codex", "分析当前目录"]);
});

test("renderHud 返回固定 3 行", () => {
  const snapshot: HudSnapshot = {
    workspace: "/tmp/project",
    codexHome: "/tmp/.codex",
    generatedAtMs: Date.now(),
    activeWorkspaceRoots: ["/tmp/project"],
    interactiveSessions: 2,
    appServers: 1,
    backgroundAgents: 1,
    hotThreads: 3,
    warnings: 2,
    errors: 1,
    recentThreadTitle: "测试线程",
    recentThreadCwd: "/tmp/project",
    recentTools: ["exec_command", "apply_patch"],
    projects: [],
    processes: [],
    warningEvents: []
  };

  const lines = renderHud(snapshot, 80, {
    compact: false,
    theme: "cyan",
    projectLimit: 5,
    warningLimit: 3
  });
  assert.equal(lines.length, 3);
});

test("compact 模式返回 2 行 HUD", () => {
  assert.equal(getHudHeight({
    compact: true,
    theme: "plain",
    projectLimit: 3,
    warningLimit: 2
  }), 2);
});
