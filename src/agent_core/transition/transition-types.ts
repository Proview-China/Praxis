import type { KernelEvent, KernelEventType } from "../types/kernel-events.js";
import type { GoalFrameCompiled } from "../types/kernel-goal.js";
import type { CapabilityCallIntent, InternalStepIntent, ModelInferenceIntent } from "../types/kernel-intents.js";
import type { AgentState } from "../types/kernel-state.js";
import type { StepTransitionDecision } from "../types/kernel-transition.js";

export type TransitionPathKind = "hot" | "rare";

export type TransitionIntent =
  | CapabilityCallIntent
  | InternalStepIntent
  | ModelInferenceIntent;

export interface TransitionEvaluationContext {
  currentState: AgentState;
  incomingEvent: KernelEvent;
  goalFrame: GoalFrameCompiled;
}

export interface TransitionRule {
  name: string;
  path: TransitionPathKind;
  eventTypes: readonly KernelEventType[];
  matches(context: TransitionEvaluationContext): boolean;
  decide(context: TransitionEvaluationContext): StepTransitionDecision;
}

export class InvalidTransitionError extends Error {
  readonly fromStatus: AgentState["control"]["status"];
  readonly eventType: KernelEventType;

  constructor(params: {
    fromStatus: AgentState["control"]["status"];
    eventType: KernelEventType;
    message: string;
  }) {
    super(params.message);
    this.name = "InvalidTransitionError";
    this.fromStatus = params.fromStatus;
    this.eventType = params.eventType;
  }
}
