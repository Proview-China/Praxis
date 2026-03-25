import type {
  ToolReviewActivationInputShell,
  ToolReviewActivationOutputShell,
  ToolReviewGovernanceInputShell,
  ToolReviewGovernanceOutputShell,
  ToolReviewReplayInputShell,
  ToolReviewReplayOutputShell,
  ToolReviewHumanGateInputShell,
  ToolReviewHumanGateOutputShell,
  ToolReviewLifecycleInputShell,
  ToolReviewLifecycleOutputShell,
} from "./tool-review-contract.js";
import { resolveLifecycleTargetBindingState } from "./tool-review-contract.js";

export const TA_TOOL_REVIEW_RUNTIME_STATUSES = [
  "recorded",
  "ready_for_handoff",
  "waiting_human",
  "blocked",
] as const;
export type TaToolReviewRuntimeStatus =
  (typeof TA_TOOL_REVIEW_RUNTIME_STATUSES)[number];

export interface ToolReviewerRuntimeSubmitInput {
  governanceAction: ToolReviewGovernanceInputShell;
}

export interface ToolReviewerRuntimeResult {
  reviewId: string;
  placeholder: true;
  governanceKind: ToolReviewGovernanceInputShell["kind"];
  runtimeStatus: TaToolReviewRuntimeStatus;
  output: ToolReviewGovernanceOutputShell;
  recordedAt: string;
  metadata?: Record<string, unknown>;
}

export interface ToolReviewerRuntimeOptions {
  recordHook?: (result: ToolReviewerRuntimeResult) => Promise<void> | void;
}

function createActivationOutput(
  input: ToolReviewActivationInputShell,
): ToolReviewActivationOutputShell {
  const failure = input.latestFailure
    ?? (input.currentAttempt?.status === "failed" ? input.currentAttempt.failure : undefined);

  if (failure) {
    return {
      kind: "activation",
      actionId: input.trace.actionId,
      status: "activation_failed",
      capabilityKey: input.capabilityKey,
      provisionId: input.provisionId,
      targetPool: input.activationSpec.targetPool,
      attemptId: input.currentAttempt?.attemptId ?? failure.attemptId,
      failure,
      summary: `Activation handoff for ${input.capabilityKey} is blocked by ${failure.code}.`,
      metadata: input.metadata,
    };
  }

  return {
    kind: "activation",
    actionId: input.trace.actionId,
    status: "ready_for_activation_handoff",
    capabilityKey: input.capabilityKey,
    provisionId: input.provisionId,
    targetPool: input.activationSpec.targetPool,
    attemptId: input.currentAttempt?.attemptId,
    receipt: input.latestReceipt,
    summary: `Activation handoff is staged for ${input.capabilityKey} into ${input.activationSpec.targetPool}.`,
    metadata: input.metadata,
  };
}

function createLifecycleOutput(
  input: ToolReviewLifecycleInputShell,
): ToolReviewLifecycleOutputShell {
  return {
    kind: "lifecycle",
    actionId: input.trace.actionId,
    status: "ready_for_lifecycle_handoff",
    capabilityKey: input.capabilityKey,
    lifecycleAction: input.lifecycleAction,
    targetPool: input.targetPool,
    bindingId: input.binding?.bindingId,
    targetBindingState: resolveLifecycleTargetBindingState(input.lifecycleAction),
    summary: `Lifecycle ${input.lifecycleAction} is staged for ${input.capabilityKey} in ${input.targetPool}.`,
    metadata: input.metadata,
  };
}

function createHumanGateOutput(
  input: ToolReviewHumanGateInputShell,
): ToolReviewHumanGateOutputShell {
  const status = input.gate.status;
  return {
    kind: "human_gate",
    actionId: input.trace.actionId,
    status,
    capabilityKey: input.capabilityKey,
    gateId: input.gate.gateId,
    gateStatus: status,
    latestEventType: input.latestEvent?.type,
    summary: status === "waiting_human"
      ? `Human gate ${input.gate.gateId} is waiting for approval before ${input.capabilityKey} continues.`
      : status === "approved"
        ? `Human gate ${input.gate.gateId} approved ${input.capabilityKey}.`
        : `Human gate ${input.gate.gateId} rejected ${input.capabilityKey}.`,
    metadata: input.metadata,
  };
}

function createReplayOutput(
  input: ToolReviewReplayInputShell,
): ToolReviewReplayOutputShell {
  const status = input.replay.status === "skipped"
    ? "replay_skipped"
    : input.replay.nextAction === "re_review_then_dispatch"
      ? "ready_for_re_review"
      : "pending_replay";

  return {
    kind: "replay",
    actionId: input.trace.actionId,
    status,
    capabilityKey: input.capabilityKey,
    replayId: input.replay.replayId,
    nextAction: input.replay.nextAction,
    summary: status === "replay_skipped"
      ? `Replay ${input.replay.replayId} is intentionally skipped for ${input.capabilityKey}.`
      : status === "ready_for_re_review"
        ? `Replay ${input.replay.replayId} is staged for re-review before dispatch.`
        : `Replay ${input.replay.replayId} remains pending for ${input.capabilityKey}.`,
    metadata: input.metadata,
  };
}

function toRuntimeStatus(
  output: ToolReviewGovernanceOutputShell,
): TaToolReviewRuntimeStatus {
  switch (output.kind) {
    case "activation":
      return output.status === "activation_failed" ? "blocked" : "ready_for_handoff";
    case "lifecycle":
      return output.status === "lifecycle_blocked" ? "blocked" : "ready_for_handoff";
    case "human_gate":
      return output.status === "waiting_human"
        ? "waiting_human"
        : output.status === "approved"
          ? "recorded"
          : "blocked";
    case "replay":
      return output.status === "ready_for_re_review"
        ? "ready_for_handoff"
        : "recorded";
  }
}

export class ToolReviewerRuntime {
  readonly #recordHook?: ToolReviewerRuntimeOptions["recordHook"];

  constructor(options: ToolReviewerRuntimeOptions = {}) {
    this.#recordHook = options.recordHook;
  }

  async submit(
    input: ToolReviewerRuntimeSubmitInput,
  ): Promise<ToolReviewerRuntimeResult> {
    const output = this.createOutputShell(input.governanceAction);
    const result: ToolReviewerRuntimeResult = {
      reviewId: `tool-review:${input.governanceAction.trace.actionId}`,
      placeholder: true,
      governanceKind: input.governanceAction.kind,
      runtimeStatus: toRuntimeStatus(output),
      output,
      recordedAt: input.governanceAction.trace.createdAt,
      metadata: {
        actorId: input.governanceAction.trace.actorId,
        sourceDecisionId: input.governanceAction.trace.sourceDecision?.decisionId,
      },
    };

    await this.#recordHook?.(result);
    return result;
  }

  createOutputShell(
    input: ToolReviewGovernanceInputShell,
  ): ToolReviewGovernanceOutputShell {
    switch (input.kind) {
      case "activation":
        return createActivationOutput(input);
      case "lifecycle":
        return createLifecycleOutput(input);
      case "human_gate":
        return createHumanGateOutput(input);
      case "replay":
        return createReplayOutput(input);
    }
  }
}

export function createToolReviewerRuntime(
  options: ToolReviewerRuntimeOptions = {},
): ToolReviewerRuntime {
  return new ToolReviewerRuntime(options);
}
