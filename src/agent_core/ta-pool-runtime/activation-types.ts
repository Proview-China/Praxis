import type { PoolActivationMode, PoolRegistrationStrategy } from "../ta-pool-types/index.js";

export const TA_ACTIVATION_ATTEMPT_STATUSES = [
  "pending",
  "started",
  "succeeded",
  "failed",
  "rolled_back",
] as const;
export type TaActivationAttemptStatus = (typeof TA_ACTIVATION_ATTEMPT_STATUSES)[number];

export interface TaActivationReceipt {
  attemptId: string;
  provisionId: string;
  capabilityKey: string;
  targetPool: string;
  capabilityId: string;
  bindingId: string;
  generation: number;
  registrationStrategy: PoolRegistrationStrategy;
  activatedAt: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTaActivationReceiptInput {
  attemptId: string;
  provisionId: string;
  capabilityKey: string;
  targetPool: string;
  capabilityId: string;
  bindingId: string;
  generation: number;
  registrationStrategy: PoolRegistrationStrategy;
  activatedAt: string;
  metadata?: Record<string, unknown>;
}

export interface TaActivationFailure {
  attemptId: string;
  provisionId: string;
  capabilityKey: string;
  failedAt: string;
  code: string;
  message: string;
  retryable: boolean;
  metadata?: Record<string, unknown>;
}

export interface CreateTaActivationFailureInput {
  attemptId: string;
  provisionId: string;
  capabilityKey: string;
  failedAt: string;
  code: string;
  message: string;
  retryable?: boolean;
  metadata?: Record<string, unknown>;
}

export interface TaActivationAttemptRecord {
  attemptId: string;
  provisionId: string;
  capabilityKey: string;
  targetPool: string;
  activationMode: PoolActivationMode;
  registrationStrategy: PoolRegistrationStrategy;
  status: TaActivationAttemptStatus;
  startedAt: string;
  updatedAt: string;
  completedAt?: string;
  receipt?: TaActivationReceipt;
  failure?: TaActivationFailure;
  metadata?: Record<string, unknown>;
}

export interface CreateTaActivationAttemptRecordInput {
  attemptId: string;
  provisionId: string;
  capabilityKey: string;
  targetPool: string;
  activationMode: PoolActivationMode;
  registrationStrategy: PoolRegistrationStrategy;
  startedAt: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export function createTaActivationReceipt(
  input: CreateTaActivationReceiptInput,
): TaActivationReceipt {
  if (!Number.isInteger(input.generation) || input.generation < 0) {
    throw new Error("Activation receipt generation must be a non-negative integer.");
  }

  return {
    attemptId: assertNonEmpty(input.attemptId, "Activation receipt attemptId"),
    provisionId: assertNonEmpty(input.provisionId, "Activation receipt provisionId"),
    capabilityKey: assertNonEmpty(input.capabilityKey, "Activation receipt capabilityKey"),
    targetPool: assertNonEmpty(input.targetPool, "Activation receipt targetPool"),
    capabilityId: assertNonEmpty(input.capabilityId, "Activation receipt capabilityId"),
    bindingId: assertNonEmpty(input.bindingId, "Activation receipt bindingId"),
    generation: input.generation,
    registrationStrategy: input.registrationStrategy,
    activatedAt: input.activatedAt,
    metadata: input.metadata,
  };
}

export function createTaActivationFailure(
  input: CreateTaActivationFailureInput,
): TaActivationFailure {
  return {
    attemptId: assertNonEmpty(input.attemptId, "Activation failure attemptId"),
    provisionId: assertNonEmpty(input.provisionId, "Activation failure provisionId"),
    capabilityKey: assertNonEmpty(input.capabilityKey, "Activation failure capabilityKey"),
    failedAt: input.failedAt,
    code: assertNonEmpty(input.code, "Activation failure code"),
    message: assertNonEmpty(input.message, "Activation failure message"),
    retryable: input.retryable ?? true,
    metadata: input.metadata,
  };
}

export function createTaActivationAttemptRecord(
  input: CreateTaActivationAttemptRecordInput,
): TaActivationAttemptRecord {
  return {
    attemptId: assertNonEmpty(input.attemptId, "Activation attempt attemptId"),
    provisionId: assertNonEmpty(input.provisionId, "Activation attempt provisionId"),
    capabilityKey: assertNonEmpty(input.capabilityKey, "Activation attempt capabilityKey"),
    targetPool: assertNonEmpty(input.targetPool, "Activation attempt targetPool"),
    activationMode: input.activationMode,
    registrationStrategy: input.registrationStrategy,
    status: "pending",
    startedAt: input.startedAt,
    updatedAt: input.startedAt,
    metadata: input.metadata,
  };
}
