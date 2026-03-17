import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { AppendOnlyEventJournal } from "../journal/append-only-log.js";
import type { KernelEvent, RunRecord } from "../types/index.js";
import { createInitialAgentState } from "../state/state-types.js";
import { CheckpointStore } from "./checkpoint-store.js";

function createRunRecord(overrides: Partial<RunRecord> = {}): RunRecord {
  return {
    runId: overrides.runId ?? "run-1",
    sessionId: overrides.sessionId ?? "session-1",
    status: overrides.status ?? "deciding",
    phase: overrides.phase ?? "decision",
    goal: overrides.goal ?? {
      goalId: "goal-1",
      instructionText: "Do the thing",
      successCriteria: [],
      failureCriteria: [],
      constraints: [],
      inputRefs: [],
      cacheKey: "compiled-goal-1"
    },
    currentStep: overrides.currentStep ?? 1,
    pendingIntentId: overrides.pendingIntentId,
    lastEventId: overrides.lastEventId,
    lastResult: overrides.lastResult,
    lastCheckpointRef: overrides.lastCheckpointRef,
    startedAt: overrides.startedAt ?? "2026-03-17T12:00:00.000Z",
    endedAt: overrides.endedAt,
    metadata: overrides.metadata
  };
}

function createEvent(overrides: Partial<KernelEvent> = {}): KernelEvent {
  return {
    eventId: overrides.eventId ?? `evt-${Math.random().toString(16).slice(2)}`,
    type: overrides.type ?? "run.created",
    sessionId: overrides.sessionId ?? "session-1",
    runId: overrides.runId ?? "run-1",
    createdAt: overrides.createdAt ?? new Date().toISOString(),
    payload: overrides.payload ?? { goalId: "goal-1" },
    correlationId: overrides.correlationId,
    causationId: overrides.causationId,
    metadata: overrides.metadata
  } as KernelEvent;
}

test("fast checkpoint write/read returns latest in-memory checkpoint", async () => {
  const store = new CheckpointStore();
  const snapshot = {
    run: createRunRecord(),
    state: createInitialAgentState()
  };

  const written = store.writeFastCheckpoint({
    checkpointId: "cp-fast-1",
    sessionId: "session-1",
    runId: "run-1",
    reason: "manual",
    createdAt: "2026-03-17T12:00:00.000Z",
    journalCursor: "journal:0:1",
    snapshot
  });

  assert.equal(written.record.tier, "fast");
  assert.equal(store.loadFastCheckpoint("cp-fast-1")?.record.journalCursor, "journal:0:1");
  assert.equal((await store.loadLatestCheckpoint("run-1"))?.record.checkpointId, "cp-fast-1");
});

test("durable checkpoint write/read persists to the filesystem", async () => {
  const durableDirectory = await mkdtemp(path.join(tmpdir(), "praxis-checkpoint-test-"));
  const store = new CheckpointStore({ durableDirectory });

  try {
    await store.writeDurableCheckpoint({
      checkpointId: "cp-durable-1",
      sessionId: "session-1",
      runId: "run-2",
      reason: "completion",
      createdAt: "2026-03-17T12:30:00.000Z",
      journalCursor: "journal:1:2",
      snapshot: {
        run: createRunRecord({ runId: "run-2", sessionId: "session-1" }),
        state: createInitialAgentState()
      }
    });

    const loaded = await store.loadDurableCheckpoint("cp-durable-1");
    assert.equal(loaded?.record.tier, "durable");
    assert.equal(loaded?.record.journalCursor, "journal:1:2");
  } finally {
    await rm(durableDirectory, { recursive: true, force: true });
  }
});

test("recoverRun replays journal events after checkpoint cursor", async () => {
  const journal = new AppendOnlyEventJournal();
  journal.appendEvent(createEvent({ eventId: "evt-1", type: "run.created", payload: { goalId: "goal-1" } }));
  const afterCursor = journal.appendEvent(createEvent({
    eventId: "evt-2",
    type: "state.delta_applied",
    payload: {
      delta: {
        working: {
          note: "after-checkpoint"
        }
      },
      previousStatus: "created",
      nextStatus: "deciding"
    }
  })).cursor;
  journal.appendEvent(createEvent({
    eventId: "evt-3",
    type: "checkpoint.created",
    payload: {
      checkpointId: "cp-fast-2",
      tier: "fast"
    }
  }));

  const store = new CheckpointStore();
  store.writeFastCheckpoint({
    checkpointId: "cp-fast-2",
    sessionId: "session-1",
    runId: "run-1",
    reason: "pause",
    createdAt: "2026-03-17T13:00:00.000Z",
    journalCursor: "journal:0:0",
    snapshot: {
      run: createRunRecord(),
      state: createInitialAgentState()
    }
  });

  const recovery = await store.recoverRun({
    runId: "run-1",
    journal
  });

  assert.equal(recovery.checkpoint?.record.checkpointId, "cp-fast-2");
  assert.equal(recovery.replayedEvents.at(0)?.cursor, afterCursor);
  assert.equal(recovery.state.working.note, "after-checkpoint");
  assert.equal(recovery.run?.lastCheckpointRef, "cp-fast-2");
});

test("recoverRun falls back to durable checkpoint when fast checkpoint is absent", async () => {
  const durableDirectory = await mkdtemp(path.join(tmpdir(), "praxis-checkpoint-recovery-"));
  const journal = new AppendOnlyEventJournal();
  journal.appendEvent(createEvent({ eventId: "evt-1", type: "run.created", payload: { goalId: "goal-1" } }));
  journal.appendEvent(createEvent({
    eventId: "evt-2",
    type: "run.failed",
    payload: {
      code: "simulated_crash",
      message: "crash-like recovery"
    }
  }));

  const store = new CheckpointStore({ durableDirectory });
  try {
    await store.writeDurableCheckpoint({
      checkpointId: "cp-durable-2",
      sessionId: "session-1",
      runId: "run-3",
      reason: "recovery",
      createdAt: "2026-03-17T14:00:00.000Z",
      journalCursor: "journal:0:0",
      snapshot: {
        run: createRunRecord({ runId: "run-3", sessionId: "session-1" }),
        state: createInitialAgentState()
      }
    });

    const recovery = await store.recoverRun({
      runId: "run-3",
      journal
    });

    assert.equal(recovery.checkpoint?.record.tier, "durable");
    assert.equal(recovery.state.control.status, "failed");
    assert.equal(recovery.state.recovery.lastErrorCode, "simulated_crash");
  } finally {
    await rm(durableDirectory, { recursive: true, force: true });
  }
});
