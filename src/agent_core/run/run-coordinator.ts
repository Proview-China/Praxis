import { evaluateTransition } from "../transition/index.js";
import { projectStateFromEvents } from "../state/index.js";
import type { KernelEvent } from "../types/kernel-events.js";
import type { KernelIntent } from "../types/kernel-intents.js";
import type { RunRecord } from "../types/kernel-run.js";
import type { AgentState } from "../types/kernel-state.js";
import {
  createIntentQueuedEvent,
  createStateDeltaAppliedEvent,
  defaultIdFactory
} from "./run-dispatch.js";
import {
  createRunCompletedEvent,
  createRunCreatedEvent,
  createRunFailedEvent,
  createRunPausedEvent,
  createRunRecord,
  createRunResumedEvent
} from "./run-lifecycle.js";
import { recoverRunContext } from "./run-resume.js";
import type {
  CompleteRunInput,
  CreateRunInput,
  FailRunInput,
  PauseRunInput,
  ResolvedRunContext,
  ResumeRunInput,
  RunCoordinatorOptions,
  RunTransitionOutcome,
  TickRunInput
} from "./run-types.js";

const DEFAULT_CLOCK = {
  now: () => new Date()
};

export class AgentRunCoordinator {
  readonly #journal: RunCoordinatorOptions["journal"];
  readonly #checkpointStore: RunCoordinatorOptions["checkpointStore"];
  readonly #clock;
  readonly #idFactory;
  readonly #runs = new Map<string, RunRecord>();
  readonly #activeTicks = new Set<string>();

  constructor(options: RunCoordinatorOptions) {
    this.#journal = options.journal;
    this.#checkpointStore = options.checkpointStore;
    this.#clock = options.clock ?? DEFAULT_CLOCK;
    this.#idFactory = options.idFactory ?? defaultIdFactory;
  }

  async createRun(input: CreateRunInput): Promise<RunTransitionOutcome> {
    const run = createRunRecord(input, this.#clock);
    this.#runs.set(run.runId, run);

    const createdEvent = createRunCreatedEvent(run, this.#clock, this.#idFactory);

    return this.tickRun({
      runId: run.runId,
      incomingEvent: createdEvent
    });
  }

  async tickRun(input: TickRunInput): Promise<RunTransitionOutcome> {
    const incomingEvent = input.incomingEvent ?? this.#latestEventOrThrow(input.runId);
    const { run, state, eventAlreadyPersisted } = this.#resolveRunContext(
      input.runId,
      incomingEvent
    );

    if (this.#activeTicks.has(input.runId)) {
      throw new Error(`Run ${input.runId} is already ticking.`);
    }

    this.#activeTicks.add(input.runId);
    try {
      const decision = evaluateTransition(state, incomingEvent, run.goal);
      const emittedEvents: KernelEvent[] = [];

      if (!eventAlreadyPersisted) {
        this.#journal.appendEvent(incomingEvent);
      }

      const stateDeltaEvent = createStateDeltaAppliedEvent(
        run,
        decision,
        incomingEvent,
        this.#clock,
        this.#idFactory
      );
      if (stateDeltaEvent) {
        this.#journal.appendEvent(stateDeltaEvent);
        emittedEvents.push(stateDeltaEvent);
      }

      let queuedIntent: KernelIntent | undefined;
      if (decision.nextAction?.intent) {
        queuedIntent = decision.nextAction.intent;
        const queuedEvent = createIntentQueuedEvent(
          run,
          queuedIntent,
          this.#clock,
          this.#idFactory
        );
        this.#journal.appendEvent(queuedEvent);
        emittedEvents.push(queuedEvent);
      }

      const nextState = this.#projectRunState(run.runId);
      const nextRun = this.#updateRunRecord(run, nextState, decision, queuedIntent);
      this.#runs.set(run.runId, nextRun);

      return {
        run: nextRun,
        state: nextState,
        incomingEvent,
        decision,
        emittedEvents,
        queuedIntent
      };
    } finally {
      this.#activeTicks.delete(input.runId);
    }
  }

  async resumeRun(input: ResumeRunInput): Promise<RunTransitionOutcome> {
    const current = this.#runs.get(input.runId) ?? this.#restoreRunRecord(input.runId);
    if (!current) {
      throw new Error(`Run ${input.runId} was not found.`);
    }

    const { recoveredRun } = await recoverRunContext({
      ...input,
      checkpointStore: this.#checkpointStore,
      journal: this.#journal
    });
    const run = recoveredRun ?? current;
    this.#runs.set(run.runId, run);

    const resumedEvent = createRunResumedEvent(run, input, this.#clock, this.#idFactory);

    return this.tickRun({
      runId: run.runId,
      incomingEvent: resumedEvent
    });
  }

  async suspendRun(input: PauseRunInput): Promise<RunTransitionOutcome> {
    return this.pauseRun(input);
  }

  async pauseRun(input: PauseRunInput): Promise<RunTransitionOutcome> {
    const run = this.#requireRun(input.runId);
    const event = createRunPausedEvent(run, input, this.#clock, this.#idFactory);
    return this.tickRun({
      runId: run.runId,
      incomingEvent: event
    });
  }

  async failRun(input: FailRunInput): Promise<RunTransitionOutcome> {
    const run = this.#requireRun(input.runId);
    const event = createRunFailedEvent(run, input, this.#clock, this.#idFactory);
    return this.tickRun({
      runId: run.runId,
      incomingEvent: event
    });
  }

  async completeRun(input: CompleteRunInput): Promise<RunTransitionOutcome> {
    const run = this.#requireRun(input.runId);
    const event = createRunCompletedEvent(run, input, this.#clock, this.#idFactory);
    return this.tickRun({
      runId: run.runId,
      incomingEvent: event
    });
  }

  getRun(runId: string): RunRecord | undefined {
    return this.#runs.get(runId);
  }

  listRuns(): readonly RunRecord[] {
    return [...this.#runs.values()];
  }

  #resolveRunContext(
    runId: string,
    incomingEvent: KernelEvent
  ): ResolvedRunContext & { eventAlreadyPersisted: boolean } {
    const run = this.#requireRun(runId);
    const events = this.#journal.readRunEvents(runId);
    const eventAlreadyPersisted = events.some((entry) => entry.event.eventId === incomingEvent.eventId);
    const priorEvents = eventAlreadyPersisted
      ? events.filter((entry) => entry.event.eventId !== incomingEvent.eventId)
      : events;
    const state = projectStateFromEvents(priorEvents.map((entry) => entry.event));
    return {
      run,
      state,
      events: priorEvents,
      eventAlreadyPersisted
    };
  }

  #projectRunState(runId: string): AgentState {
    const events = this.#journal.readRunEvents(runId).map((entry) => entry.event);
    return projectStateFromEvents(events);
  }

  #restoreRunRecord(runId: string): RunRecord | undefined {
    const latest = this.#journal.getLatestEvent(runId);
    if (!latest) {
      return undefined;
    }

    const runCreated = this.#journal.readRunEvents(runId)
      .map((entry) => entry.event)
      .find((event) => event.type === "run.created");
    if (!runCreated) {
      return undefined;
    }

    const recoveredState = this.#projectRunState(runId);
    const existing = this.#runs.get(runId);
    if (existing) {
      return {
        ...existing,
        status: recoveredState.control.status,
        phase: recoveredState.control.phase,
        lastEventId: latest.event.eventId
      };
    }

    return undefined;
  }

  #latestEventOrThrow(runId: string): KernelEvent {
    const latest = this.#journal.getLatestEvent(runId);
    if (!latest) {
      throw new Error(`Run ${runId} has no journal events to drive a tick.`);
    }
    return latest.event;
  }

  #requireRun(runId: string): RunRecord {
    const run = this.#runs.get(runId);
    if (!run) {
      throw new Error(`Run ${runId} was not found.`);
    }
    return run;
  }

  #updateRunRecord(
    run: RunRecord,
    state: AgentState,
    decision: RunTransitionOutcome["decision"],
    queuedIntent?: KernelIntent
  ): RunRecord {
    const effectiveStatus = queuedIntent ? "waiting" : state.control.status;
    const effectivePhase = queuedIntent ? "execution" : state.control.phase;
    const terminal =
      effectiveStatus === "completed" ||
      effectiveStatus === "failed" ||
      effectiveStatus === "cancelled";

    return {
      ...run,
      status: effectiveStatus,
      phase: effectivePhase,
      currentStep: run.currentStep + 1,
      pendingIntentId: queuedIntent?.intentId ?? state.control.pendingIntentId,
      lastEventId: this.#journal.getLatestEvent(run.runId)?.event.eventId ?? run.lastEventId,
      lastCheckpointRef: state.recovery.lastCheckpointRef ?? run.lastCheckpointRef,
      endedAt: terminal ? this.#clock.now().toISOString() : run.endedAt,
      metadata: {
        ...(run.metadata ?? {}),
        lastTransitionReason: decision.reason
      }
    };
  }
}
