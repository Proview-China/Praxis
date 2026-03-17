import assert from "node:assert/strict";
import test from "node:test";

import { AppendOnlyEventJournal } from "../journal/append-only-log.js";
import { compileGoal } from "../goal/goal-compiler.js";
import { createGoalSource } from "../goal/goal-source.js";
import { normalizeGoal } from "../goal/goal-normalizer.js";
import { FastCheckpointStore } from "../checkpoint/checkpoint-fast.js";
import { CheckpointStore } from "../checkpoint/checkpoint-store.js";
import { AgentRunCoordinator } from "./run-coordinator.js";
import type { CapabilityCallIntent } from "../types/kernel-intents.js";

function createCompiledGoal() {
  const source = createGoalSource({
    goalId: "goal-1",
    sessionId: "session-1",
    runId: "run-1",
    userInput: "Find evidence and summarize it"
  });
  return compileGoal(normalizeGoal(source), {});
}

test("createRun creates a run and emits initial intent flow", async () => {
  const journal = new AppendOnlyEventJournal();
  const coordinator = new AgentRunCoordinator({
    journal,
    idFactory: (() => {
      let index = 0;
      return () => `id-${++index}`;
    })(),
    clock: {
      now: () => new Date("2026-03-17T00:00:00.000Z")
    }
  });

  const outcome = await coordinator.createRun({
    sessionId: "session-1",
    goal: createCompiledGoal()
  });

  assert.equal(outcome.run.status, "waiting");
  assert.equal(outcome.run.phase, "execution");
  assert.equal(outcome.queuedIntent?.kind, "model_inference");
  assert.deepEqual(
    journal.readRunEvents(outcome.run.runId).map((entry) => entry.event.type),
    ["run.created", "state.delta_applied", "intent.queued"]
  );
});

test("tickRun on capability result returns run to deciding and requeues next action", async () => {
  const journal = new AppendOnlyEventJournal();
  const coordinator = new AgentRunCoordinator({
    journal
  });

  const created = await coordinator.createRun({
    sessionId: "session-1",
    goal: createCompiledGoal()
  });

  const resultEvent = {
    eventId: "evt-result",
    type: "capability.result_received" as const,
    sessionId: "session-1",
    runId: created.run.runId,
    createdAt: new Date("2026-03-17T00:01:00.000Z").toISOString(),
    payload: {
      requestId: "req-1",
      resultId: "result-1",
      status: "success" as const
    }
  };
  journal.appendEvent(resultEvent);

  const outcome = await coordinator.tickRun({
    runId: created.run.runId,
    incomingEvent: resultEvent
  });

  assert.equal(outcome.decision.toStatus, "deciding");
  assert.equal(outcome.run.status, "waiting");
  assert.equal(outcome.state.observed.lastResultId, "result-1");
  assert.equal(outcome.queuedIntent?.kind, "model_inference");
});

test("pauseRun and resumeRun update status and emit lifecycle events", async () => {
  const journal = new AppendOnlyEventJournal();
  const checkpointStore = new CheckpointStore({
    fast: new FastCheckpointStore()
  });
  const coordinator = new AgentRunCoordinator({
    journal,
    checkpointStore
  });

  const created = await coordinator.createRun({
    sessionId: "session-1",
    goal: createCompiledGoal()
  });

  const paused = await coordinator.pauseRun({
    runId: created.run.runId,
    reason: "manual-stop"
  });
  assert.equal(paused.run.status, "paused");

  checkpointStore.writeFastCheckpoint({
    checkpointId: "cp-1",
    sessionId: "session-1",
    runId: created.run.runId,
    reason: "pause",
    createdAt: new Date("2026-03-17T00:02:00.000Z").toISOString(),
    snapshot: {
      run: paused.run,
      state: paused.state
    }
  });

  const resumed = await coordinator.resumeRun({
    runId: created.run.runId,
    checkpointId: "cp-1"
  });

  assert.equal(resumed.incomingEvent.type, "run.resumed");
  assert.equal(resumed.run.status, "waiting");
});

test("completeRun and failRun move run to terminal states", async () => {
  const journal = new AppendOnlyEventJournal();
  const coordinator = new AgentRunCoordinator({
    journal
  });

  const created = await coordinator.createRun({
    sessionId: "session-1",
    goal: createCompiledGoal()
  });

  const completed = await coordinator.completeRun({
    runId: created.run.runId,
    resultId: "result-final"
  });
  assert.equal(completed.run.status, "completed");
  assert.ok(completed.run.endedAt);

  const created2 = await coordinator.createRun({
    sessionId: "session-2",
    goal: createCompiledGoal()
  });
  const failed = await coordinator.failRun({
    runId: created2.run.runId,
    code: "boom",
    message: "failure"
  });
  assert.equal(failed.run.status, "failed");
  assert.ok(failed.run.endedAt);
});

test("repeated tick on same run is rejected while active", async () => {
  const journal = new AppendOnlyEventJournal();
  const coordinator = new AgentRunCoordinator({
    journal
  });

  const created = await coordinator.createRun({
    sessionId: "session-1",
    goal: createCompiledGoal()
  });

  const resultEvent = {
    eventId: "evt-result-2",
    type: "capability.result_received" as const,
    sessionId: "session-1",
    runId: created.run.runId,
    createdAt: new Date("2026-03-17T00:01:00.000Z").toISOString(),
    payload: {
      requestId: "req-2",
      resultId: "result-2",
      status: "success" as const
    }
  };
  journal.appendEvent(resultEvent);

  await assert.rejects(async () => {
    await Promise.all([
      coordinator.tickRun({ runId: created.run.runId, incomingEvent: resultEvent }),
      coordinator.tickRun({ runId: created.run.runId, incomingEvent: resultEvent })
    ]);
  });
});
