import assert from "node:assert/strict";
import test from "node:test";

import { createInitialAgentState } from "../state/state-types.js";
import { createTapPoolRuntimeSnapshot } from "../ta-pool-runtime/index.js";
import { createPoolRuntimeCheckpointSnapshot, mergePoolRuntimeSnapshotsIntoCheckpointSnapshot, readTapPoolRuntimeSnapshots } from "./pool-runtime-checkpoint.js";

function createRunRecord(runId: string, sessionId: string) {
  return {
    runId,
    sessionId,
    status: "deciding" as const,
    phase: "decision" as const,
    goal: {
      goalId: `${runId}:goal`,
      instructionText: "Do thing",
      successCriteria: [],
      failureCriteria: [],
      constraints: [],
      inputRefs: [],
      cacheKey: `${runId}:goal-cache`,
    },
    currentStep: 1,
    pendingIntentId: undefined,
    lastEventId: undefined,
    lastResult: undefined,
    lastCheckpointRef: undefined,
    startedAt: "2026-03-19T16:30:00.000Z",
    endedAt: undefined,
    metadata: undefined,
  };
}

test("pool runtime checkpoint snapshot carries TAP runtime state alongside run and state", () => {
  const snapshot = createPoolRuntimeCheckpointSnapshot({
    run: createRunRecord("run-1", "session-1"),
    state: createInitialAgentState(),
    poolRuntimeSnapshots: {
      tap: createTapPoolRuntimeSnapshot({
        humanGates: [],
        humanGateEvents: [],
        pendingReplays: [],
        activationAttempts: [],
        resumeEnvelopes: [],
      }),
    },
  });

  assert.equal(snapshot.poolRuntimeSnapshots?.tap?.humanGates.length, 0);
  assert.equal(snapshot.run.sessionId, "session-1");
});

test("pool runtime checkpoint helper can merge and read TAP snapshot fragments", () => {
  const base = createPoolRuntimeCheckpointSnapshot({
    run: createRunRecord("run-2", "session-2"),
    state: createInitialAgentState(),
  });
  const merged = mergePoolRuntimeSnapshotsIntoCheckpointSnapshot({
    snapshot: base,
    poolRuntimeSnapshots: {
      tap: createTapPoolRuntimeSnapshot({
        humanGates: [],
        humanGateEvents: [],
        pendingReplays: [],
        activationAttempts: [],
        resumeEnvelopes: [],
      }),
    },
  });

  const tap = readTapPoolRuntimeSnapshots({
    poolRuntimeSnapshots: merged.poolRuntimeSnapshots,
  });

  assert.equal(tap?.pendingReplays.length, 0);
});
