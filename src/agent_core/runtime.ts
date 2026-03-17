import { randomUUID } from "node:crypto";

import { CheckpointStore } from "./checkpoint/index.js";
import { compileGoal } from "./goal/goal-compiler.js";
import { normalizeGoal } from "./goal/goal-normalizer.js";
import { createGoalSource } from "./goal/goal-source.js";
import { executeModelInference, type ModelInferenceExecutionResult } from "./integrations/model-inference.js";
import { AppendOnlyEventJournal } from "./journal/index.js";
import type { JournalReadResult } from "./journal/journal-types.js";
import { CapabilityPortBroker, type CapabilityDispatchReceipt, type CapabilityPortDefinition } from "./port/index.js";
import { AgentRunCoordinator } from "./run/index.js";
import { SessionManager } from "./session/index.js";
import type {
  CapabilityCallIntent,
  ModelInferenceIntent,
  CapabilityPortResponse,
  GoalFrameCompiled,
  GoalFrameSource,
  KernelEvent,
  SessionHeader,
} from "./types/index.js";
import type { CreateSessionInput } from "./session/index.js";
import type { CreateRunInput, RunTransitionOutcome } from "./run/index.js";

export interface AgentCoreRuntimeOptions {
  journal?: AppendOnlyEventJournal;
  checkpointStore?: CheckpointStore;
  portBroker?: CapabilityPortBroker;
  runCoordinator?: AgentRunCoordinator;
  sessionManager?: SessionManager;
  modelInferenceExecutor?: (params: { intent: ModelInferenceIntent }) => Promise<ModelInferenceExecutionResult>;
}

export interface CreateAgentCoreRunInput extends Omit<CreateRunInput, "goal"> {
  goal: GoalFrameCompiled;
}

export interface CreateAgentCoreRunFromSourceInput extends Omit<CreateRunInput, "goal"> {
  source: GoalFrameSource;
}

export interface DispatchCapabilityIntentResult {
  enqueueResponse: CapabilityPortResponse;
  dispatchReceipt?: CapabilityDispatchReceipt;
  latestEvent?: KernelEvent;
  runOutcome?: RunTransitionOutcome;
}

export interface DispatchModelInferenceIntentResult {
  result: KernelEvent;
  kernelResult: ModelInferenceExecutionResult["result"];
  runOutcome: RunTransitionOutcome;
}

export class AgentCoreRuntime {
  readonly journal: AppendOnlyEventJournal;
  readonly checkpointStore: CheckpointStore;
  readonly portBroker: CapabilityPortBroker;
  readonly runCoordinator: AgentRunCoordinator;
  readonly sessionManager: SessionManager;
  readonly #modelInferenceExecutor: (params: { intent: ModelInferenceIntent }) => Promise<ModelInferenceExecutionResult>;

  constructor(options: AgentCoreRuntimeOptions = {}) {
    this.journal = options.journal ?? new AppendOnlyEventJournal();
    this.checkpointStore = options.checkpointStore ?? new CheckpointStore();
    this.portBroker = options.portBroker ?? new CapabilityPortBroker({
      journal: this.journal,
    });
    this.runCoordinator = options.runCoordinator ?? new AgentRunCoordinator({
      journal: this.journal,
      checkpointStore: this.checkpointStore,
    });
    this.sessionManager = options.sessionManager ?? new SessionManager();
    this.#modelInferenceExecutor = options.modelInferenceExecutor ?? executeModelInference;
  }

  createSession(input: CreateSessionInput = {}): SessionHeader {
    return this.sessionManager.createSession(input);
  }

  createCompiledGoal(source: GoalFrameSource): GoalFrameCompiled {
    return compileGoal(normalizeGoal(source), {});
  }

  async createRun(input: CreateAgentCoreRunInput): Promise<RunTransitionOutcome> {
    const outcome = await this.runCoordinator.createRun(input);
    this.sessionManager.attachRun({
      sessionId: input.sessionId,
      runId: outcome.run.runId,
      makeActive: true,
    });
    return outcome;
  }

  async createRunFromSource(input: CreateAgentCoreRunFromSourceInput): Promise<RunTransitionOutcome> {
    const compiledGoal = this.createCompiledGoal(input.source);
    return this.createRun({
      ...input,
      goal: compiledGoal,
    });
  }

  registerCapabilityPort(definition: CapabilityPortDefinition): void {
    this.portBroker.registerCapabilityPort(definition);
  }

  async dispatchCapabilityIntent(intent: CapabilityCallIntent): Promise<DispatchCapabilityIntentResult> {
    const enqueueResponse = this.portBroker.enqueueIntent({ intent });
    const dispatchReceipt = await this.portBroker.dispatchNext();
    if (!dispatchReceipt) {
      return { enqueueResponse };
    }

    const latestEvent = this.journal.getLatestEvent(intent.runId)?.event;
    const runOutcome =
      latestEvent && latestEvent.type === "capability.result_received"
        ? await this.runCoordinator.tickRun({
            runId: intent.runId,
            incomingEvent: latestEvent,
          })
        : undefined;

    if (runOutcome) {
      this.#syncSessionFromRun(runOutcome.run);
    }

    return {
      enqueueResponse,
      dispatchReceipt,
      latestEvent,
      runOutcome,
    };
  }

  async dispatchModelInferenceIntent(intent: ModelInferenceIntent): Promise<DispatchModelInferenceIntentResult> {
    const execution = await this.#modelInferenceExecutor({ intent });
    const resultEvent: KernelEvent = {
      eventId: randomUUID(),
      type: "capability.result_received",
      sessionId: intent.sessionId,
      runId: intent.runId,
      createdAt: new Date().toISOString(),
      correlationId: intent.correlationId ?? intent.intentId,
      payload: {
        requestId: intent.intentId,
        resultId: execution.result.resultId,
        status: execution.result.status,
      },
      metadata: {
        resultSource: "model",
        final: true,
      },
    };

    this.journal.appendEvent(resultEvent);
    let runOutcome = await this.runCoordinator.tickRun({
      runId: intent.runId,
      incomingEvent: resultEvent,
    });
    if (runOutcome.run.status === "completed") {
      runOutcome = await this.runCoordinator.completeRun({
        runId: intent.runId,
        resultId: execution.result.resultId,
      });
    }
    this.#syncSessionFromRun(runOutcome.run);

    return {
      result: resultEvent,
      kernelResult: execution.result,
      runOutcome,
    };
  }

  async dispatchIntent(intent: CapabilityCallIntent | ModelInferenceIntent) {
    if (intent.kind === "capability_call") {
      return this.dispatchCapabilityIntent(intent);
    }

    return this.dispatchModelInferenceIntent(intent);
  }

  async runUntilTerminal(params: {
    sessionId: string;
    source: GoalFrameSource;
    maxSteps?: number;
  }) {
    const created = await this.createRunFromSource({
      sessionId: params.sessionId,
      source: params.source,
    });

    let current = created;
    let lastModelResult: DispatchModelInferenceIntentResult["kernelResult"] | undefined;
    const maxSteps = params.maxSteps ?? 8;
    let steps = 0;

    while (steps < maxSteps) {
      steps += 1;
      const intent = current.queuedIntent;
      if (!intent) {
        break;
      }

      if (intent.kind === "model_inference") {
        const dispatched = await this.dispatchModelInferenceIntent(intent);
        lastModelResult = dispatched.kernelResult;
        current = dispatched.runOutcome;
        if (current.run.status === "completed" || current.run.status === "failed" || current.run.status === "cancelled") {
          break;
        }
        continue;
      }

      if (intent.kind === "capability_call") {
        const dispatched = await this.dispatchCapabilityIntent(intent);
        if (!dispatched.runOutcome) {
          break;
        }
        current = dispatched.runOutcome;
        if (current.run.status === "completed" || current.run.status === "failed" || current.run.status === "cancelled") {
          break;
        }
        continue;
      }

      throw new Error(`Unsupported queued intent kind for terminal runner: ${intent.kind}`);
    }

    return {
      session: this.sessionManager.loadSessionHeader(params.sessionId),
      outcome: current,
      answer:
        lastModelResult?.output && typeof lastModelResult.output === "object" && lastModelResult.output !== null && "text" in lastModelResult.output
          ? (lastModelResult.output as { text?: string }).text
          : undefined,
      steps,
      finalEvents: this.readRunEvents(current.run.runId),
    };
  }

  readRunEvents(runId: string): JournalReadResult[] {
    return this.journal.readRunEvents(runId);
  }

  #syncSessionFromRun(run: RunTransitionOutcome["run"]): void {
    if (run.status === "completed" || run.status === "failed" || run.status === "cancelled") {
      this.sessionManager.setActiveRun(run.sessionId, undefined);
      return;
    }

    this.sessionManager.setActiveRun(run.sessionId, run.runId);
  }
}

export function createAgentCoreRuntime(options: AgentCoreRuntimeOptions = {}): AgentCoreRuntime {
  return new AgentCoreRuntime(options);
}

export function createGoalSourceForSession(params: {
  sessionId: string;
  runId?: string;
  userInput: string;
  goalId?: string;
  inputRefs?: string[];
  constraints?: GoalFrameSource["constraints"];
  metadata?: Record<string, unknown>;
}): GoalFrameSource {
  return createGoalSource({
    goalId: params.goalId ?? randomUUID(),
    sessionId: params.sessionId,
    runId: params.runId,
    userInput: params.userInput,
    inputRefs: params.inputRefs,
    constraints: params.constraints,
    metadata: params.metadata,
  });
}
