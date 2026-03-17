import { randomUUID } from "node:crypto";

import type {
  CompleteRunInput,
  CreateRunInput,
  FailRunInput,
  PauseRunInput,
  ResumeRunInput,
  RunCoordinatorClock
} from "./run-types.js";
import type {
  RunCompletedEvent,
  RunCreatedEvent,
  RunFailedEvent,
  RunPausedEvent,
  RunResumedEvent
} from "../types/kernel-events.js";
import type { RunRecord } from "../types/kernel-run.js";

export function createRunRecord(
  input: CreateRunInput,
  clock: RunCoordinatorClock
): RunRecord {
  const now = clock.now().toISOString();
  return {
    runId: input.runId ?? randomUUID(),
    sessionId: input.sessionId,
    status: "created",
    phase: "decision",
    goal: input.goal,
    currentStep: 0,
    startedAt: now,
    metadata: input.metadata
  };
}

export function createRunCreatedEvent(
  run: RunRecord,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): RunCreatedEvent {
  return {
    eventId: eventIdFactory(),
    type: "run.created",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    payload: {
      goalId: run.goal.goalId
    }
  };
}

export function createRunResumedEvent(
  run: RunRecord,
  input: ResumeRunInput,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): RunResumedEvent {
  return {
    eventId: eventIdFactory(),
    type: "run.resumed",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    payload: {
      checkpointId: input.checkpointId
    }
  };
}

export function createRunPausedEvent(
  run: RunRecord,
  input: PauseRunInput,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): RunPausedEvent {
  return {
    eventId: eventIdFactory(),
    type: "run.paused",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    payload: {
      reason: input.reason
    }
  };
}

export function createRunCompletedEvent(
  run: RunRecord,
  input: CompleteRunInput,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): RunCompletedEvent {
  return {
    eventId: eventIdFactory(),
    type: "run.completed",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    payload: {
      resultId: input.resultId
    }
  };
}

export function createRunFailedEvent(
  run: RunRecord,
  input: FailRunInput,
  clock: RunCoordinatorClock,
  eventIdFactory: () => string
): RunFailedEvent {
  return {
    eventId: eventIdFactory(),
    type: "run.failed",
    sessionId: run.sessionId,
    runId: run.runId,
    createdAt: clock.now().toISOString(),
    payload: {
      code: input.code,
      message: input.message
    }
  };
}
