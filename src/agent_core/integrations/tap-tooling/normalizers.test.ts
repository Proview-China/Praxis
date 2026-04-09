import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";

import type { CapabilityInvocationPlan } from "../../capability-types/index.js";
import { normalizeCommandInput, normalizeCodePatchInput } from "./normalizers.js";

function createPlan(
  capabilityKey: CapabilityInvocationPlan["capabilityKey"],
  input: Record<string, unknown>,
): CapabilityInvocationPlan {
  return {
    planId: "plan-normalizers",
    intentId: "intent-normalizers",
    sessionId: "session-normalizers",
    runId: "run-normalizers",
    capabilityKey,
    operation: capabilityKey,
    input,
    priority: "normal",
    metadata: {
      grantedScope: {
        pathPatterns: ["workspace/**"],
        allowedOperations: ["exec", "shell.restricted", "test", "test.run"],
      },
    },
  };
}

test("normalizeCommandInput rejects destructive shell.restricted args", () => {
  assert.throws(
    () =>
      normalizeCommandInput({
        plan: createPlan("shell.restricted", {
          command: "git",
          args: ["reset", "--hard"],
        }),
        workspaceRoot: "/tmp/workspace",
        defaultTimeoutMs: 15_000,
        capabilityKey: "shell.restricted",
        operationCandidates: ["exec", "shell.restricted"],
      }),
    /destructive arguments/i,
  );
});

test("normalizeCommandInput blocks non-test executables for test.run", () => {
  assert.throws(
    () =>
      normalizeCommandInput({
        plan: createPlan("test.run", {
          command: "bash",
          args: ["-lc", "echo nope"],
        }),
        workspaceRoot: "/tmp/workspace",
        defaultTimeoutMs: 30_000,
        capabilityKey: "test.run",
        operationCandidates: ["exec", "test", "test.run"],
      }),
    /only allows test-oriented commands/i,
  );
});

test("normalizeCodePatchInput parses add and update operations", () => {
  const normalized = normalizeCodePatchInput({
    planId: "plan-patch",
    intentId: "intent-patch",
    sessionId: "session-patch",
    runId: "run-patch",
    capabilityKey: "code.patch",
    operation: "code.patch",
    input: {
      patch: [
        "*** Begin Patch",
        "*** Add File: notes/hello.txt",
        "+hello",
        "*** Update File: src/sample.ts",
        "@@",
        "-const before = true;",
        "+const after = true;",
        "*** End Patch",
        "",
      ].join("\n"),
    },
    priority: "normal",
  });

  assert.equal(normalized.operations.length, 2);
  assert.equal(normalized.operations[0]?.type, "add");
  assert.equal(normalized.operations[1]?.type, "update");
});
