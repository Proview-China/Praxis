import type { GoalFrameCompiled } from "./kernel-goal.js";
import type { RunId, SessionId } from "./kernel-session.js";

export const KERNEL_INTENT_KINDS = [
  "internal_step",
  "model_inference",
  "capability_call"
] as const;
export type KernelIntentKind = (typeof KERNEL_INTENT_KINDS)[number];

export const INTENT_PRIORITIES = [
  "low",
  "normal",
  "high",
  "critical"
] as const;
export type IntentPriority = (typeof INTENT_PRIORITIES)[number];

export interface KernelIntentBase {
  intentId: string;
  sessionId: SessionId;
  runId: RunId;
  kind: KernelIntentKind;
  createdAt: string;
  priority: IntentPriority;
  correlationId?: string;
  idempotencyKey?: string;
  metadata?: Record<string, unknown>;
}

export interface InternalStepIntent extends KernelIntentBase {
  kind: "internal_step";
  instruction: string;
}

export interface ModelInferenceIntent extends KernelIntentBase {
  kind: "model_inference";
  frame: GoalFrameCompiled;
  stateSummary?: Record<string, unknown>;
}

export interface CapabilityPortRequest {
  requestId: string;
  intentId: string;
  sessionId: SessionId;
  runId: RunId;
  capabilityKey: string;
  input: Record<string, unknown>;
  priority: IntentPriority;
  timeoutMs?: number;
  idempotencyKey?: string;
  metadata?: Record<string, unknown>;
}

export interface CapabilityCallIntent extends KernelIntentBase {
  kind: "capability_call";
  request: CapabilityPortRequest;
}

export type KernelIntent =
  | InternalStepIntent
  | ModelInferenceIntent
  | CapabilityCallIntent;
