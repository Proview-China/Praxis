import { TA_CAPABILITY_TIERS, type TaCapabilityTier } from "./ta-pool-profile.js";

export const PROVISION_ARTIFACT_STATUSES = [
  "pending",
  "building",
  "verifying",
  "ready",
  "failed",
  "superseded",
] as const;
export type ProvisionArtifactStatus = (typeof PROVISION_ARTIFACT_STATUSES)[number];

export const REPLAY_POLICIES = [
  "none",
  "manual",
  "auto_after_verify",
  "re_review_then_dispatch",
] as const;
export type ReplayPolicy = (typeof REPLAY_POLICIES)[number];

export const POOL_ACTIVATION_MODES = [
  "stage_only",
  "activate_after_verify",
  "activate_immediately",
] as const;
export type PoolActivationMode = (typeof POOL_ACTIVATION_MODES)[number];

export const POOL_REGISTRATION_STRATEGIES = [
  "register",
  "replace",
  "register_or_replace",
] as const;
export type PoolRegistrationStrategy = (typeof POOL_REGISTRATION_STRATEGIES)[number];

export const POOL_GENERATION_STRATEGIES = [
  "reuse_current_generation",
  "create_next_generation",
  "shadow_generation",
] as const;
export type PoolGenerationStrategy = (typeof POOL_GENERATION_STRATEGIES)[number];

export const POOL_DRAIN_STRATEGIES = [
  "none",
  "graceful",
  "force",
] as const;
export type PoolDrainStrategy = (typeof POOL_DRAIN_STRATEGIES)[number];

export interface ProvisionArtifactRef {
  artifactId: string;
  kind: string;
  ref?: string;
  metadata?: Record<string, unknown>;
}

export interface PoolActivationSpec {
  targetPool: string;
  activationMode: PoolActivationMode;
  registerOrReplace: PoolRegistrationStrategy;
  generationStrategy: PoolGenerationStrategy;
  drainStrategy: PoolDrainStrategy;
  manifestPayload: Record<string, unknown>;
  bindingPayload: Record<string, unknown>;
  adapterFactoryRef: string;
  rollbackHandle?: ProvisionArtifactRef;
  metadata?: Record<string, unknown>;
}

export interface CreatePoolActivationSpecInput {
  targetPool: string;
  activationMode: PoolActivationMode;
  registerOrReplace: PoolRegistrationStrategy;
  generationStrategy: PoolGenerationStrategy;
  drainStrategy: PoolDrainStrategy;
  manifestPayload: Record<string, unknown>;
  bindingPayload: Record<string, unknown>;
  adapterFactoryRef: string;
  rollbackHandle?: ProvisionArtifactRef;
  metadata?: Record<string, unknown>;
}

export interface ProvisionRequest {
  provisionId: string;
  sourceRequestId: string;
  requestedCapabilityKey: string;
  requestedTier: TaCapabilityTier;
  reason: string;
  desiredProviderOrRuntime?: string;
  requiredVerification?: string[];
  expectedArtifacts?: string[];
  replayPolicy?: ReplayPolicy;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CreateProvisionRequestInput {
  provisionId: string;
  sourceRequestId: string;
  requestedCapabilityKey: string;
  requestedTier?: TaCapabilityTier;
  reason: string;
  desiredProviderOrRuntime?: string;
  requiredVerification?: string[];
  expectedArtifacts?: string[];
  replayPolicy?: ReplayPolicy;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface ProvisionArtifactBundle {
  bundleId: string;
  provisionId: string;
  status: ProvisionArtifactStatus;
  toolArtifact?: ProvisionArtifactRef;
  bindingArtifact?: ProvisionArtifactRef;
  verificationArtifact?: ProvisionArtifactRef;
  usageArtifact?: ProvisionArtifactRef;
  activationSpec?: PoolActivationSpec;
  replayPolicy?: ReplayPolicy;
  completedAt?: string;
  error?: {
    code: string;
    message: string;
  };
  metadata?: Record<string, unknown>;
}

export interface CreateProvisionArtifactBundleInput {
  bundleId: string;
  provisionId: string;
  status: ProvisionArtifactStatus;
  toolArtifact?: ProvisionArtifactRef;
  bindingArtifact?: ProvisionArtifactRef;
  verificationArtifact?: ProvisionArtifactRef;
  usageArtifact?: ProvisionArtifactRef;
  activationSpec?: PoolActivationSpec;
  replayPolicy?: ReplayPolicy;
  completedAt?: string;
  error?: {
    code: string;
    message: string;
  };
  metadata?: Record<string, unknown>;
}

function normalizeStringArray(values?: string[]): string[] | undefined {
  if (!values || values.length === 0) {
    return undefined;
  }

  const normalized = [...new Set(values.map((value) => value.trim()).filter(Boolean))];
  return normalized.length > 0 ? normalized : undefined;
}

function validateArtifactRef(label: string, artifact?: ProvisionArtifactRef): void {
  if (!artifact) {
    return;
  }

  if (!artifact.artifactId.trim()) {
    throw new Error(`${label} requires a non-empty artifactId.`);
  }

  if (!artifact.kind.trim()) {
    throw new Error(`${label} requires a non-empty kind.`);
  }
}

export function validatePoolActivationSpec(spec: PoolActivationSpec): void {
  if (!spec.targetPool.trim()) {
    throw new Error("Pool activation spec requires a non-empty targetPool.");
  }

  if (!spec.adapterFactoryRef?.trim()) {
    throw new Error("Pool activation spec requires a non-empty adapterFactoryRef.");
  }

  if (!POOL_ACTIVATION_MODES.includes(spec.activationMode)) {
    throw new Error(`Unsupported activation mode: ${spec.activationMode}.`);
  }

  if (!POOL_REGISTRATION_STRATEGIES.includes(spec.registerOrReplace)) {
    throw new Error(`Unsupported registration strategy: ${spec.registerOrReplace}.`);
  }

  if (!POOL_GENERATION_STRATEGIES.includes(spec.generationStrategy)) {
    throw new Error(`Unsupported generation strategy: ${spec.generationStrategy}.`);
  }

  if (!POOL_DRAIN_STRATEGIES.includes(spec.drainStrategy)) {
    throw new Error(`Unsupported drain strategy: ${spec.drainStrategy}.`);
  }

  if (Object.keys(spec.manifestPayload).length === 0) {
    throw new Error("Pool activation spec requires a non-empty manifestPayload.");
  }

  if (Object.keys(spec.bindingPayload).length === 0) {
    throw new Error("Pool activation spec requires a non-empty bindingPayload.");
  }

  if (spec.rollbackHandle && !spec.rollbackHandle.kind.trim()) {
    throw new Error("Pool activation spec rollbackHandle requires a non-empty kind.");
  }
}

export function createPoolActivationSpec(
  input: CreatePoolActivationSpecInput,
): PoolActivationSpec {
  const spec: PoolActivationSpec = {
    targetPool: input.targetPool.trim(),
    activationMode: input.activationMode,
    registerOrReplace: input.registerOrReplace,
    generationStrategy: input.generationStrategy,
    drainStrategy: input.drainStrategy,
    manifestPayload: input.manifestPayload,
    bindingPayload: input.bindingPayload,
    adapterFactoryRef: input.adapterFactoryRef.trim(),
    rollbackHandle: input.rollbackHandle,
    metadata: input.metadata,
  };

  validatePoolActivationSpec(spec);
  return spec;
}

export function validateProvisionRequest(request: ProvisionRequest): void {
  if (!request.provisionId.trim()) {
    throw new Error("Provision request requires a non-empty provisionId.");
  }

  if (!request.sourceRequestId.trim()) {
    throw new Error("Provision request requires a non-empty sourceRequestId.");
  }

  if (!request.requestedCapabilityKey.trim()) {
    throw new Error("Provision request requires a non-empty requestedCapabilityKey.");
  }

  if (!request.reason.trim()) {
    throw new Error("Provision request requires a non-empty reason.");
  }

  if (!TA_CAPABILITY_TIERS.includes(request.requestedTier)) {
    throw new Error(`Unsupported provision request tier: ${request.requestedTier}.`);
  }
}

export function createProvisionRequest(input: CreateProvisionRequestInput): ProvisionRequest {
  const request: ProvisionRequest = {
    provisionId: input.provisionId.trim(),
    sourceRequestId: input.sourceRequestId.trim(),
    requestedCapabilityKey: input.requestedCapabilityKey.trim(),
    requestedTier: input.requestedTier ?? "B1",
    reason: input.reason.trim(),
    desiredProviderOrRuntime: input.desiredProviderOrRuntime?.trim() || undefined,
    requiredVerification: normalizeStringArray(input.requiredVerification),
    expectedArtifacts: normalizeStringArray(input.expectedArtifacts),
    replayPolicy: input.replayPolicy ?? "re_review_then_dispatch",
    createdAt: input.createdAt,
    metadata: input.metadata,
  };

  validateProvisionRequest(request);
  return request;
}

export function validateProvisionArtifactBundle(bundle: ProvisionArtifactBundle): void {
  if (!bundle.bundleId.trim()) {
    throw new Error("Provision artifact bundle requires a non-empty bundleId.");
  }

  if (!bundle.provisionId.trim()) {
    throw new Error("Provision artifact bundle requires a non-empty provisionId.");
  }

  validateArtifactRef("toolArtifact", bundle.toolArtifact);
  validateArtifactRef("bindingArtifact", bundle.bindingArtifact);
  validateArtifactRef("verificationArtifact", bundle.verificationArtifact);
  validateArtifactRef("usageArtifact", bundle.usageArtifact);

  if (bundle.activationSpec) {
    validatePoolActivationSpec(bundle.activationSpec);
  }

  if (bundle.status === "ready") {
    if (!bundle.toolArtifact || !bundle.bindingArtifact || !bundle.verificationArtifact || !bundle.usageArtifact) {
      throw new Error("Ready provision artifact bundles require all four artifact slots.");
    }
  }

  if (bundle.status === "failed" && !bundle.error) {
    throw new Error("Failed provision artifact bundles require an error.");
  }
}

export function createProvisionArtifactBundle(
  input: CreateProvisionArtifactBundleInput,
): ProvisionArtifactBundle {
  const bundle: ProvisionArtifactBundle = {
    bundleId: input.bundleId.trim(),
    provisionId: input.provisionId.trim(),
    status: input.status,
    toolArtifact: input.toolArtifact,
    bindingArtifact: input.bindingArtifact,
    verificationArtifact: input.verificationArtifact,
    usageArtifact: input.usageArtifact,
    activationSpec: input.activationSpec,
    replayPolicy: input.replayPolicy,
    completedAt: input.completedAt,
    error: input.error,
    metadata: input.metadata,
  };

  validateProvisionArtifactBundle(bundle);
  return bundle;
}
