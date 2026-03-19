import type {
  CapabilityInvocationPlan,
  PreparedCapabilityCall,
} from "../capability-types/index.js";
import type {
  AccessRequestScope,
  CapabilityGrant,
  DecisionToken,
  TaCapabilityTier,
  TaPoolMode,
} from "../ta-pool-types/index.js";
import { validateDecisionToken } from "../ta-pool-types/index.js";

export const TA_ENFORCEMENT_METADATA_KEY = "taEnforcement";

export interface TaExecutionEnforcement {
  requestId: string;
  executionRequestId: string;
  capabilityKey: string;
  grantId: string;
  grantTier: TaCapabilityTier;
  mode: TaPoolMode;
  scope?: AccessRequestScope;
  constraints?: Record<string, unknown>;
  expiresAt?: string;
  tokenRequired: boolean;
  decisionToken?: DecisionToken;
}

interface CreateTaExecutionEnforcementInput {
  executionRequestId: string;
  capabilityKey: string;
  grant: CapabilityGrant;
  decisionToken?: DecisionToken;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function readTaExecutionEnforcement(
  metadata: Record<string, unknown> | undefined,
): TaExecutionEnforcement | undefined {
  if (!metadata) {
    return undefined;
  }

  const raw = metadata[TA_ENFORCEMENT_METADATA_KEY];
  const bridge = metadata.bridge;
  if (raw === undefined && bridge !== "ta-pool") {
    return undefined;
  }
  if (!isRecord(raw)) {
    throw new Error("T/A execution metadata is missing a valid taEnforcement payload.");
  }

  const decisionToken = raw.decisionToken;
  if (decisionToken !== undefined && !isRecord(decisionToken)) {
    throw new Error("T/A execution metadata carries a malformed decisionToken.");
  }

  return raw as unknown as TaExecutionEnforcement;
}

function assertNonEmptyString(value: unknown, label: string): asserts value is string {
  if (typeof value !== "string" || !value.trim()) {
    throw new Error(`T/A enforcement requires a non-empty ${label}.`);
  }
}

function assertDecisionTokenValid(
  enforcement: TaExecutionEnforcement,
  clock: () => Date,
): void {
  if (!enforcement.tokenRequired && !enforcement.decisionToken) {
    return;
  }

  if (!enforcement.decisionToken) {
    throw new Error(
      `T/A enforcement for request ${enforcement.requestId} requires a compiled DecisionToken.`,
    );
  }

  validateDecisionToken(enforcement.decisionToken);
  if (enforcement.decisionToken.requestId !== enforcement.requestId) {
    throw new Error(
      `DecisionToken request ${enforcement.decisionToken.requestId} does not match control-plane request ${enforcement.requestId}.`,
    );
  }
  if (enforcement.decisionToken.compiledGrantId !== enforcement.grantId) {
    throw new Error(
      `DecisionToken grant ${enforcement.decisionToken.compiledGrantId} does not match enforcement grant ${enforcement.grantId}.`,
    );
  }
  if (enforcement.decisionToken.mode !== enforcement.mode) {
    throw new Error(
      `DecisionToken mode ${enforcement.decisionToken.mode} does not match enforcement mode ${enforcement.mode}.`,
    );
  }

  const expiresAt = enforcement.decisionToken.expiresAt ?? enforcement.expiresAt;
  if (!expiresAt) {
    return;
  }

  const expiresAtMs = Date.parse(expiresAt);
  if (!Number.isFinite(expiresAtMs)) {
    throw new Error(`T/A enforcement carries an invalid expiry timestamp: ${expiresAt}.`);
  }
  if (expiresAtMs < clock().getTime()) {
    throw new Error(
      `DecisionToken for request ${enforcement.requestId} expired at ${expiresAt}.`,
    );
  }
}

function assertBaseEnforcementValid(
  enforcement: TaExecutionEnforcement,
  clock: () => Date,
): void {
  assertNonEmptyString(enforcement.requestId, "requestId");
  assertNonEmptyString(enforcement.executionRequestId, "executionRequestId");
  assertNonEmptyString(enforcement.capabilityKey, "capabilityKey");
  assertNonEmptyString(enforcement.grantId, "grantId");
  assertNonEmptyString(enforcement.mode, "mode");
  assertNonEmptyString(enforcement.grantTier, "grantTier");
  assertDecisionTokenValid(enforcement, clock);
}

export function createTaExecutionEnforcement(input: CreateTaExecutionEnforcementInput): TaExecutionEnforcement {
  const tokenRequired = !!input.grant.decisionTokenId;
  if (tokenRequired && !input.decisionToken) {
    throw new Error(
      `Grant ${input.grant.grantId} requires a DecisionToken before it can enter execution.`,
    );
  }

  return {
    requestId: input.grant.requestId,
    executionRequestId: input.executionRequestId,
    capabilityKey: input.capabilityKey,
    grantId: input.grant.grantId,
    grantTier: input.grant.grantedTier,
    mode: input.grant.mode,
    scope: input.grant.grantedScope,
    constraints: input.grant.constraints,
    expiresAt: input.grant.expiresAt,
    tokenRequired,
    decisionToken: input.decisionToken,
  };
}

export function validateTaPlanEnforcement(
  plan: CapabilityInvocationPlan,
  clock: () => Date = () => new Date(),
): TaExecutionEnforcement | undefined {
  const enforcement = readTaExecutionEnforcement(plan.metadata);
  if (!enforcement) {
    return undefined;
  }

  assertBaseEnforcementValid(enforcement, clock);
  if (enforcement.executionRequestId !== plan.planId) {
    throw new Error(
      `T/A enforcement execution request ${enforcement.executionRequestId} does not match invocation plan ${plan.planId}.`,
    );
  }
  if (enforcement.capabilityKey !== plan.capabilityKey) {
    throw new Error(
      `T/A enforcement capability ${enforcement.capabilityKey} does not match invocation plan ${plan.capabilityKey}.`,
    );
  }

  return enforcement;
}

export function validateTaPreparedEnforcement(
  prepared: PreparedCapabilityCall,
  clock: () => Date = () => new Date(),
): TaExecutionEnforcement | undefined {
  const enforcement = readTaExecutionEnforcement(prepared.metadata);
  if (!enforcement) {
    return undefined;
  }

  assertBaseEnforcementValid(enforcement, clock);
  if (enforcement.capabilityKey !== prepared.capabilityKey) {
    throw new Error(
      `T/A enforcement capability ${enforcement.capabilityKey} does not match prepared call ${prepared.capabilityKey}.`,
    );
  }
  const preparedPlanId = prepared.metadata?.planId;
  if (typeof preparedPlanId === "string" && preparedPlanId !== enforcement.executionRequestId) {
    throw new Error(
      `Prepared call ${prepared.preparedId} carries request ${preparedPlanId}, expected ${enforcement.executionRequestId}.`,
    );
  }

  return enforcement;
}
