import assert from "node:assert/strict";
import test from "node:test";

import { buildShellSessionEnvelope, trimCommandOutput } from "./command-runtime.js";
import type { ShellSessionRuntimeState } from "./shared.js";

function createState(overrides: Partial<ShellSessionRuntimeState> = {}): ShellSessionRuntimeState {
  return {
    sessionId: "shell-session-1",
    child: {} as ReturnType<typeof import("node:child_process").spawn>,
    stdoutBuffer: "stdout payload",
    stderrBuffer: "stderr payload",
    startedAt: 0,
    cwd: "/tmp/workspace",
    relativeWorkspaceCwd: ".",
    commandSummary: "npm test",
    commandKind: "test",
    maxOutputChars: 4_000,
    ...overrides,
  };
}

test("buildShellSessionEnvelope marks non-zero poll results as failed", () => {
  const envelope = buildShellSessionEnvelope({
    preparedId: "prepared-shell",
    state: createState({
      closedAt: Date.now(),
      exitCode: 2,
      signal: null,
    }),
    action: "poll",
  });

  assert.equal(envelope.status, "failed");
  assert.equal((envelope.output as { state?: string }).state, "failed");
});

test("buildShellSessionEnvelope treats terminate as success even after non-zero exit", () => {
  const envelope = buildShellSessionEnvelope({
    preparedId: "prepared-shell",
    state: createState({
      closedAt: Date.now(),
      exitCode: 143,
      signal: "SIGTERM",
    }),
    action: "terminate",
  });

  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { action?: string }).action, "terminate");
});

test("trimCommandOutput preserves head and tail when truncating", () => {
  const trimmed = trimCommandOutput(`${"a".repeat(80)}${"b".repeat(80)}`, 100);

  assert.equal(trimmed.truncated, true);
  assert.match(trimmed.text, /^a+/);
  assert.match(trimmed.text, /\.\.\[truncated /);
  assert.match(trimmed.text, /b+$/);
});
