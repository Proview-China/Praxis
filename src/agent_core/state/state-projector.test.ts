import assert from "node:assert/strict";
import test from "node:test";

import type { KernelEvent } from "../types/index.js";
import { applyStateDelta } from "./state-delta.js";
import { createInitialAgentState } from "./state-types.js";
import {
  assertValidAgentState,
  assertValidAgentStateDelta
} from "./state-validator.js";
import { projectStateFromEvents } from "./state-projector.js";

test("createInitialAgentState returns the four required sections", () => {
  const state = createInitialAgentState();

  assert.deepEqual(state.control, {
    status: "created",
    phase: "decision",
    retryCount: 0
  });
  assert.deepEqual(state.working, {});
  assert.deepEqual(state.observed, {
    artifactRefs: []
  });
  assert.deepEqual(state.recovery, {});
});

test("applyStateDelta merges working state recursively and clears top-level keys", () => {
  const initial = createInitialAgentState();
  const next = applyStateDelta(initial, {
    working: {
      plan: {
        branch: "a",
        depth: 1
      },
      obsolete: "drop-me"
    }
  });
  const final = applyStateDelta(next, {
    working: {
      plan: {
        depth: 2
      }
    },
    clearWorkingKeys: ["obsolete"]
  });

  assert.deepEqual(final.working, {
    plan: {
      branch: "a",
      depth: 2
    }
  });
});

test("applyStateDelta rejects forbidden top-level history-like keys", () => {
  assert.throws(
    () =>
      applyStateDelta(createInitialAgentState(), {
        working: {
          history: "should not be here"
        }
      }),
    /history/
  );
});

test("projectStateFromEvents replays event sequence into state", () => {
  const events: KernelEvent[] = [
    {
      eventId: "evt-1",
      type: "run.created",
      sessionId: "session-1",
      runId: "run-1",
      createdAt: "2026-03-17T10:00:00.000Z",
      payload: {
        goalId: "goal-1"
      }
    },
    {
      eventId: "evt-2",
      type: "intent.queued",
      sessionId: "session-1",
      runId: "run-1",
      createdAt: "2026-03-17T10:00:01.000Z",
      payload: {
        intentId: "intent-1",
        kind: "capability_call",
        priority: "high"
      }
    },
    {
      eventId: "evt-3",
      type: "intent.dispatched",
      sessionId: "session-1",
      runId: "run-1",
      createdAt: "2026-03-17T10:00:02.000Z",
      payload: {
        intentId: "intent-1",
        dispatchTarget: "websearch"
      }
    },
    {
      eventId: "evt-4",
      type: "capability.result_received",
      sessionId: "session-1",
      runId: "run-1",
      createdAt: "2026-03-17T10:00:03.000Z",
      payload: {
        requestId: "request-1",
        resultId: "result-1",
        status: "success"
      }
    },
    {
      eventId: "evt-5",
      type: "state.delta_applied",
      sessionId: "session-1",
      runId: "run-1",
      createdAt: "2026-03-17T10:00:04.000Z",
      payload: {
        delta: {
          working: {
            plan: {
              step: "summarize"
            }
          },
          observed: {
            artifactRefs: ["artifact-1"]
          }
        },
        previousStatus: "acting",
        nextStatus: "deciding"
      }
    },
    {
      eventId: "evt-6",
      type: "checkpoint.created",
      sessionId: "session-1",
      runId: "run-1",
      createdAt: "2026-03-17T10:00:05.000Z",
      payload: {
        checkpointId: "checkpoint-1",
        tier: "fast"
      }
    }
  ];

  const state = projectStateFromEvents(events);

  assert.equal(state.control.phase, "commit");
  assert.equal(state.control.pendingIntentId, undefined);
  assert.equal(state.observed.lastResultId, "result-1");
  assert.equal(state.observed.lastResultStatus, "success");
  assert.deepEqual(state.observed.artifactRefs, ["artifact-1"]);
  assert.deepEqual(state.working, {
    plan: {
      step: "summarize"
    }
  });
  assert.equal(state.recovery.lastCheckpointRef, "checkpoint-1");
  assert.equal(state.recovery.resumePointer, "evt-6");
});

test("validator accepts a serializable state and serializable delta", () => {
  const state = createInitialAgentState();
  const delta = {
    working: {
      plan: {
        step: "collect"
      }
    },
    observed: {
      artifactRefs: ["artifact-1"]
    }
  };

  assert.doesNotThrow(() => assertValidAgentState(state));
  assert.doesNotThrow(() => assertValidAgentStateDelta(delta));
  assert.doesNotThrow(() => JSON.stringify(applyStateDelta(state, delta)));
});
