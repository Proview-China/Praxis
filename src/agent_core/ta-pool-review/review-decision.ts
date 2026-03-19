import type {
  AccessRequest,
  AccessRequestScope,
  CapabilityGrant,
  CompiledGrantEnvelope,
  GrantCompilerInput,
  ProvisionRequest,
  ReviewDecision,
  ReviewDecisionKind,
} from "../ta-pool-types/index.js";
import {
  TA_CAPABILITY_TIERS,
  createCapabilityGrant,
  createDecisionToken,
  createProvisionRequest,
} from "../ta-pool-types/index.js";

export function reviewDecisionHasGrant(
  decision: ReviewDecision,
): decision is ReviewDecision & { grant: CapabilityGrant } {
  return decision.grant !== undefined;
}

export function reviewDecisionRequiresProvisioning(decision: ReviewDecision): boolean {
  return decision.decision === "redirected_to_provisioning";
}

export function reviewDecisionRequiresHuman(decision: ReviewDecision): boolean {
  return decision.decision === "escalated_to_human";
}

export function reviewDecisionBlocksExecution(decision: ReviewDecision): boolean {
  return (
    decision.decision === "denied" ||
    decision.decision === "deferred" ||
    decision.decision === "escalated_to_human" ||
    decision.decision === "redirected_to_provisioning"
  );
}

function assertDecisionModeCompatibleWithRequest(
  request: AccessRequest,
  decision: ReviewDecision,
): void {
  if (decision.mode !== request.mode || decision.canonicalMode !== request.canonicalMode) {
    throw new Error(
      `Review decision ${decision.decisionId} rewrites ta-pool mode from ${request.mode} to ${decision.mode}.`,
    );
  }
}

function getTierRank(tier: AccessRequest["requestedTier"]): number {
  return TA_CAPABILITY_TIERS.indexOf(tier);
}

function assertTierNotWidened(params: {
  requestedTier: AccessRequest["requestedTier"];
  grantedTier: CapabilityGrant["grantedTier"];
  label: string;
}): void {
  const requestedRank = getTierRank(params.requestedTier);
  const grantedRank = getTierRank(params.grantedTier);
  if (requestedRank === -1 || grantedRank === -1) {
    throw new Error(`Unknown ta capability tier while checking ${params.label}.`);
  }
  if (grantedRank > requestedRank) {
    throw new Error(
      `${params.label} widens tier from ${params.requestedTier} to ${params.grantedTier}.`,
    );
  }
}

function assertSubsetList(params: {
  field: string;
  requested?: readonly string[];
  granted?: readonly string[];
  label: string;
}): void {
  if (!params.requested || params.requested.length === 0 || !params.granted || params.granted.length === 0) {
    return;
  }

  const requested = new Set(params.requested);
  for (const value of params.granted) {
    if (!requested.has(value)) {
      throw new Error(
        `${params.label} widens ${params.field} with ${value}.`,
      );
    }
  }
}

function assertScopeNotWidened(params: {
  request: AccessRequest;
  grantedScope?: AccessRequestScope;
  label: string;
}): void {
  const requestedScope = params.request.requestedScope;
  if (!requestedScope || !params.grantedScope) {
    return;
  }

  assertSubsetList({
    field: "pathPatterns",
    requested: requestedScope.pathPatterns,
    granted: params.grantedScope.pathPatterns,
    label: params.label,
  });
  assertSubsetList({
    field: "allowedOperations",
    requested: requestedScope.allowedOperations,
    granted: params.grantedScope.allowedOperations,
    label: params.label,
  });
  assertSubsetList({
    field: "providerHints",
    requested: requestedScope.providerHints,
    granted: params.grantedScope.providerHints,
    label: params.label,
  });
}

function assertCapabilityGrantCompatibleWithRequest(params: {
  request: AccessRequest;
  grant: CapabilityGrant;
  label: string;
}): void {
  const { request, grant, label } = params;

  if (grant.requestId !== request.requestId) {
    throw new Error(
      `${label} ${grant.grantId} does not belong to access request ${request.requestId}.`,
    );
  }

  if (grant.capabilityKey !== request.requestedCapabilityKey) {
    throw new Error(
      `${label} ${grant.grantId} targets ${grant.capabilityKey}, expected ${request.requestedCapabilityKey}.`,
    );
  }

  if (grant.mode !== request.mode || grant.canonicalMode !== request.canonicalMode) {
    throw new Error(
      `${label} ${grant.grantId} rewrites ta-pool mode from ${request.mode} to ${grant.mode}.`,
    );
  }

  assertTierNotWidened({
    requestedTier: request.requestedTier,
    grantedTier: grant.grantedTier,
    label: `${label} ${grant.grantId}`,
  });
  assertScopeNotWidened({
    request,
    grantedScope: grant.grantedScope,
    label: `${label} ${grant.grantId}`,
  });
}

function assertGrantCompilerDirectiveCompatibleWithRequest(params: {
  request: AccessRequest;
  decision: ReviewDecision;
}): void {
  const { request, decision } = params;
  const directive = decision.grantCompilerDirective;
  if (!directive) {
    return;
  }

  if (
    directive.capabilityKey &&
    directive.capabilityKey !== request.requestedCapabilityKey
  ) {
    throw new Error(
      `Grant compiler directive on review decision ${decision.decisionId} targets ${directive.capabilityKey}, expected ${request.requestedCapabilityKey}.`,
    );
  }

  if (directive.grantedTier) {
    assertTierNotWidened({
      requestedTier: request.requestedTier,
      grantedTier: directive.grantedTier,
      label: `Grant compiler directive on review decision ${decision.decisionId}`,
    });
  }

  assertScopeNotWidened({
    request,
    grantedScope: directive.grantedScope,
    label: `Grant compiler directive on review decision ${decision.decisionId}`,
  });
}

function mergeDirectiveScope(params: {
  requestedScope?: AccessRequestScope;
  directiveScope?: AccessRequestScope;
  directiveDenyPatterns?: readonly string[];
}): AccessRequestScope | undefined {
  const requestedScope = params.requestedScope;
  const directiveScope = params.directiveScope;
  if (!requestedScope && !directiveScope && (!params.directiveDenyPatterns || params.directiveDenyPatterns.length === 0)) {
    return undefined;
  }

  const mergedDenyPatterns = [
    ...(requestedScope?.denyPatterns ?? []),
    ...(directiveScope?.denyPatterns ?? []),
    ...(params.directiveDenyPatterns ?? []),
  ];
  const uniqueDenyPatterns = mergedDenyPatterns.length > 0 ? [...new Set(mergedDenyPatterns)] : undefined;

  return {
    pathPatterns: directiveScope?.pathPatterns ?? requestedScope?.pathPatterns,
    allowedOperations: directiveScope?.allowedOperations ?? requestedScope?.allowedOperations,
    providerHints: directiveScope?.providerHints ?? requestedScope?.providerHints,
    denyPatterns: uniqueDenyPatterns,
    metadata: {
      ...(requestedScope?.metadata ?? {}),
      ...(directiveScope?.metadata ?? {}),
    },
  };
}

export function assertReviewDecisionCompatibleWithRequest(params: {
  request: AccessRequest;
  decision: ReviewDecision;
}): void {
  const { request, decision } = params;
  if (request.requestId !== decision.requestId) {
    throw new Error(
      `Review decision ${decision.decisionId} does not belong to access request ${request.requestId}.`,
    );
  }

  assertDecisionModeCompatibleWithRequest(request, decision);
  assertGrantCompilerDirectiveCompatibleWithRequest({ request, decision });

  if (reviewDecisionHasGrant(decision)) {
    assertCapabilityGrantCompatibleWithRequest({
      request,
      grant: decision.grant,
      label: "Capability grant",
    });
  }
}

export function resolveExecutionReadiness(decision: ReviewDecision): {
  ready: boolean;
  blockedBy: ReviewDecisionKind | "none";
  grant?: CapabilityGrant;
} {
  if (reviewDecisionHasGrant(decision)) {
    return {
      ready: true,
      blockedBy: "none",
      grant: decision.grant,
    };
  }

  return {
    ready: false,
    blockedBy: decision.decision,
  };
}

export function compileGrantFromReviewDecision(
  input: GrantCompilerInput,
): CompiledGrantEnvelope {
  const { request, reviewDecision } = input;
  const allowVote =
    reviewDecision.vote === "allow" || reviewDecision.vote === "allow_with_constraints";
  if (!allowVote) {
    throw new Error(
      `Review vote ${reviewDecision.vote} cannot be compiled into a capability grant.`,
    );
  }

  const directive = reviewDecision.grantCompilerDirective;
  const grantedTier = directive?.grantedTier ?? request.requestedTier;
  const capabilityKey = directive?.capabilityKey ?? request.requestedCapabilityKey;

  if (capabilityKey !== request.requestedCapabilityKey) {
    throw new Error(
      `Compiled grant ${input.compiledGrantId} targets ${capabilityKey}, expected ${request.requestedCapabilityKey}.`,
    );
  }

  assertTierNotWidened({
    requestedTier: request.requestedTier,
    grantedTier,
    label: `Compiled grant ${input.compiledGrantId}`,
  });

  const grantedScope = mergeDirectiveScope({
    requestedScope: request.requestedScope,
    directiveScope: directive?.grantedScope,
    directiveDenyPatterns: directive?.denyPatterns,
  });
  assertScopeNotWidened({
    request: request as AccessRequest,
    grantedScope,
    label: `Compiled grant ${input.compiledGrantId}`,
  });

  const expiresAt = directive?.expiresAt ?? input.expiresAt;
  const decisionToken = createDecisionToken({
    requestId: request.requestId,
    decisionId: reviewDecision.decisionId,
    compiledGrantId: input.compiledGrantId,
    mode: request.mode,
    issuedAt: input.issuedAt,
    expiresAt,
    signatureOrIntegrityMarker: input.integrityMarker,
    metadata: {
      compilerVersion: input.compilerVersion,
      reviewVote: reviewDecision.vote,
    },
  });

  const grant = createCapabilityGrant({
    grantId: input.compiledGrantId,
    requestId: request.requestId,
    capabilityKey,
    grantedTier,
    grantedScope,
    mode: request.mode,
    issuedAt: input.issuedAt,
    expiresAt,
    reviewVote: reviewDecision.vote,
    sourceDecisionId: reviewDecision.decisionId,
    decisionTokenId: decisionToken.compiledGrantId,
    compilerVersion: input.compilerVersion,
    integrityMarker: input.integrityMarker,
    constraints: directive?.constraints,
    metadata: {
      source: "ta-pool-grant-compiler",
      reviewVote: reviewDecision.vote,
      ...(directive?.metadata ?? {}),
    },
  });

  return {
    grant,
    decisionToken,
    plainLanguageRisk: reviewDecision.plainLanguageRisk,
  };
}

export function toProvisionRequestFromReviewDecision(params: {
  request: AccessRequest;
  decision: ReviewDecision;
  provisionId: string;
  createdAt: string;
}): ProvisionRequest {
  const { request, decision, provisionId, createdAt } = params;
  if (!reviewDecisionRequiresProvisioning(decision)) {
    throw new Error(
      `Review decision ${decision.decisionId} does not require provisioning.`,
    );
  }

  return createProvisionRequest({
    provisionId,
    sourceRequestId: request.requestId,
    requestedCapabilityKey: decision.provisionCapabilityKey ?? request.requestedCapabilityKey,
    requestedTier: request.requestedTier,
    reason: `${request.reason} [redirected-to-provisioning:${decision.decisionId}]`,
    desiredProviderOrRuntime: request.requestedScope?.providerHints?.[0],
    requiredVerification: ["smoke", "ready"],
    expectedArtifacts: ["tool", "binding", "verification", "usage"],
    createdAt,
    metadata: {
      sourceDecisionId: decision.decisionId,
      sourceMode: request.mode,
    },
  });
}
