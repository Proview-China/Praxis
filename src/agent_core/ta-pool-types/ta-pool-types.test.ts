import assert from "node:assert/strict";
import test from "node:test";

import {
  POOL_ACTIVATION_MODES,
  PROVISION_ARTIFACT_STATUSES,
  REPLAY_POLICIES,
  REVIEW_DECISION_KINDS,
  REVIEW_VOTES,
  TA_CAPABILITY_TIERS,
  TA_POOL_LEGACY_MODES,
  TA_POOL_MODES,
  TA_POOL_RISK_LEVELS,
  createAccessRequest,
  createAgentCapabilityProfile,
  createCapabilityGrant,
  createDecisionToken,
  createPlainLanguageRiskPayload,
  createPoolActivationSpec,
  createProvisionArtifactBundle,
  createProvisionRequest,
  createReviewDecision,
  createTmaBuildPlan,
  createTmaExecutionReport,
  createTmaRollbackHandle,
  createTmaVerificationEvidence,
  decisionKindToReviewVote,
  isCapabilityAllowedByProfile,
  isCapabilityDeniedByProfile,
  isCapabilityReviewOnlyByProfile,
  isTerminalReviewDecision,
  reviewVoteToDecisionKind,
  TMA_EXECUTION_LANES,
  TMA_EXECUTION_REPORT_STATUSES,
  TMA_VERIFICATION_EVIDENCE_KINDS,
  TMA_VERIFICATION_EVIDENCE_STATUSES,
  toCanonicalTaPoolMode,
} from "./index.js";

test("ta-pool protocol constants expose the frozen second-wave enums", () => {
  assert.deepEqual(TA_CAPABILITY_TIERS, ["B0", "B1", "B2", "B3"]);
  assert.deepEqual(TA_POOL_MODES, [
    "bapr",
    "yolo",
    "permissive",
    "standard",
    "restricted",
  ]);
  assert.deepEqual(TA_POOL_LEGACY_MODES, ["strict", "balanced"]);
  assert.deepEqual(TA_POOL_RISK_LEVELS, ["normal", "risky", "dangerous"]);
  assert.deepEqual(REVIEW_VOTES, [
    "allow",
    "allow_with_constraints",
    "deny",
    "defer",
    "escalate_to_human",
    "redirect_to_provisioning",
  ]);
  assert.deepEqual(REVIEW_DECISION_KINDS, [
    "approved",
    "partially_approved",
    "denied",
    "deferred",
    "escalated_to_human",
    "redirected_to_provisioning",
  ]);
  assert.deepEqual(REPLAY_POLICIES, [
    "none",
    "manual",
    "auto_after_verify",
    "re_review_then_dispatch",
  ]);
  assert.deepEqual(POOL_ACTIVATION_MODES, [
    "stage_only",
    "activate_after_verify",
    "activate_immediately",
  ]);
  assert.deepEqual(PROVISION_ARTIFACT_STATUSES, [
    "pending",
    "building",
    "verifying",
    "ready",
    "failed",
    "superseded",
  ]);
  assert.deepEqual(TMA_EXECUTION_LANES, ["bootstrap", "extended"]);
  assert.deepEqual(TMA_EXECUTION_REPORT_STATUSES, ["completed", "failed", "cancelled"]);
  assert.deepEqual(TMA_VERIFICATION_EVIDENCE_KINDS, ["smoke", "health", "test", "usage"]);
  assert.deepEqual(TMA_VERIFICATION_EVIDENCE_STATUSES, ["passed", "failed", "skipped"]);
});

test("agent capability profile preserves baseline semantics and exposes canonical mode mapping", () => {
  const profile = createAgentCapabilityProfile({
    profileId: "profile.main",
    agentClass: "main-agent",
    defaultMode: "balanced",
    baselineCapabilities: ["docs.read", "code.read"],
    allowedCapabilityPatterns: ["search.*", "code.write.*"],
    reviewOnlyCapabilities: ["dependency.install"],
    reviewOnlyCapabilityPatterns: ["computer.*"],
    deniedCapabilityPatterns: ["shell.*", "system.*"],
  });

  assert.equal(profile.defaultMode, "balanced");
  assert.equal(profile.canonicalDefaultMode, "permissive");
  assert.equal(toCanonicalTaPoolMode("strict"), "standard");
  assert.equal(isCapabilityAllowedByProfile({ profile, capabilityKey: "docs.read" }), true);
  assert.equal(isCapabilityAllowedByProfile({ profile, capabilityKey: "search.web" }), true);
  assert.equal(isCapabilityReviewOnlyByProfile({ profile, capabilityKey: "dependency.install" }), true);
  assert.equal(isCapabilityReviewOnlyByProfile({ profile, capabilityKey: "computer.browser" }), true);
  assert.equal(isCapabilityAllowedByProfile({ profile, capabilityKey: "dependency.install" }), false);
  assert.equal(isCapabilityAllowedByProfile({ profile, capabilityKey: "shell.exec" }), false);
  assert.equal(isCapabilityDeniedByProfile({ profile, capabilityKey: "system.sudo" }), true);
});

test("review votes freeze compiler-facing semantics without forcing runtime grant issuance", () => {
  const plainLanguageRisk = createPlainLanguageRiskPayload({
    plainLanguageSummary: "这次会安装并注册一个新的浏览器能力。",
    requestedAction: "安装并启用 playwright capability",
    riskLevel: "risky",
    whyItIsRisky: "它会下载依赖并改动本地工具接入状态。",
    possibleConsequence: "如果装错版本，后续浏览器自动化可能失效。",
    whatHappensIfNotRun: "当前任务会卡在无法实际驱动浏览器的阶段。",
    availableUserActions: [
      {
        actionId: "approve-once",
        label: "继续这次安装",
        kind: "approve",
      },
      {
        actionId: "deny",
        label: "先不要安装",
        kind: "deny",
      },
    ],
  });

  const request = createAccessRequest({
    requestId: "req-1",
    sessionId: "session-1",
    runId: "run-1",
    agentId: "agent-main",
    requestedCapabilityKey: "mcp.playwright",
    requestedTier: "B2",
    reason: "User explicitly requested a real browser session.",
    requestedAction: "open browser with playwright",
    mode: "balanced",
    riskLevel: "risky",
    plainLanguageRisk,
    createdAt: "2026-03-19T00:00:00.000Z",
  });

  const reviewDecision = createReviewDecision({
    decisionId: "decision-1",
    requestId: request.requestId,
    vote: "allow_with_constraints",
    mode: request.mode,
    reason: "允许继续，但要走 GrantCompiler 机械收口。",
    riskLevel: request.riskLevel,
    plainLanguageRisk,
    grantCompilerDirective: {
      grantedTier: "B1",
      grantedScope: {
        pathPatterns: ["workspace/**"],
        allowedOperations: ["read", "exec"],
        denyPatterns: ["rm -rf /", "sudo *"],
      },
      constraints: {
        requiresVerification: true,
      },
    },
    createdAt: "2026-03-19T00:00:01.000Z",
  });

  assert.equal(request.canonicalMode, "permissive");
  assert.equal(reviewDecision.decision, "partially_approved");
  assert.equal(reviewDecision.vote, "allow_with_constraints");
  assert.equal(reviewDecision.canonicalMode, "permissive");
  assert.equal(isTerminalReviewDecision(reviewDecision.decision), true);
  assert.equal(decisionKindToReviewVote("approved"), "allow");
  assert.equal(reviewVoteToDecisionKind("redirect_to_provisioning"), "redirected_to_provisioning");

  const grant = createCapabilityGrant({
    grantId: "grant-1",
    requestId: request.requestId,
    capabilityKey: request.requestedCapabilityKey,
    grantedTier: "B1",
    grantedScope: {
      pathPatterns: ["workspace/**"],
      allowedOperations: ["read", "exec"],
      denyPatterns: ["sudo *"],
    },
    mode: "restricted",
    reviewVote: reviewDecision.vote,
    sourceDecisionId: reviewDecision.decisionId,
    decisionTokenId: "token:grant-1",
    compilerVersion: "wave-0",
    integrityMarker: "sha256:grant-1",
    issuedAt: "2026-03-19T00:00:02.000Z",
  });

  const token = createDecisionToken({
    requestId: request.requestId,
    decisionId: reviewDecision.decisionId,
    compiledGrantId: grant.grantId,
    mode: grant.mode,
    issuedAt: "2026-03-19T00:00:03.000Z",
    signatureOrIntegrityMarker: "sha256:decision-token",
  });

  assert.equal(grant.canonicalMode, "restricted");
  assert.equal(grant.reviewVote, "allow_with_constraints");
  assert.equal(token.canonicalMode, "restricted");
});

test("provision contracts carry activation and replay metadata for post-build re-entry", () => {
  const request = createProvisionRequest({
    provisionId: "provision-1",
    sourceRequestId: "req-1",
    requestedCapabilityKey: "mcp.playwright",
    reason: "No matching capability is currently installed.",
    expectedArtifacts: ["tool", "binding", "verification", "usage"],
    createdAt: "2026-03-19T00:00:00.000Z",
  });

  const activationSpec = createPoolActivationSpec({
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    manifestPayload: {
      capabilityKey: "mcp.playwright",
      version: "1.0.0",
    },
    bindingPayload: {
      adapterId: "adapter.playwright",
      runtimeKind: "mcp",
    },
    adapterFactoryRef: "factory:playwright",
    registerOrReplace: "register_or_replace",
    generationStrategy: "create_next_generation",
    drainStrategy: "graceful",
    rollbackHandle: {
      artifactId: "binding-prev-1",
      kind: "binding-ref",
      ref: "binding:playwright:prev",
    },
  });

  const bundle = createProvisionArtifactBundle({
    bundleId: "bundle-1",
    provisionId: request.provisionId,
    status: "ready",
    toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tools/playwright" },
    bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:playwright" },
    verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "smoke:playwright" },
    usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "skills/playwright.md" },
    activationSpec,
    replayPolicy: "auto_after_verify",
    completedAt: "2026-03-19T00:00:05.000Z",
  });

  assert.equal(request.replayPolicy, "re_review_then_dispatch");
  assert.equal(bundle.replayPolicy, "auto_after_verify");
  assert.equal(bundle.activationSpec?.registerOrReplace, "register_or_replace");
});

test("tma contracts freeze planner, evidence, rollback, and execution report shapes", () => {
  const plan = createTmaBuildPlan({
    planId: "plan-1",
    provisionId: "provision-1",
    requestedCapabilityKey: "mcp.playwright",
    requestedLane: "extended",
    summary: "Install and verify playwright capability package.",
    implementationSteps: ["install dependency", "generate binding", "run smoke"],
    expectedArtifacts: ["tool", "binding", "verification", "usage"],
    verificationPlan: ["smoke playwright launch"],
    rollbackPlan: ["remove generated binding", "uninstall staged dependency"],
    createdAt: "2026-03-19T00:00:00.000Z",
  });

  const rollbackHandle = createTmaRollbackHandle({
    handleId: "rollback-1",
    summary: "Rollback staged playwright install.",
    strategy: "remove artifacts and restore previous binding",
    createdAt: "2026-03-19T00:00:01.000Z",
  });

  const evidence = createTmaVerificationEvidence({
    evidenceId: "evidence-1",
    planId: plan.planId,
    provisionId: plan.provisionId,
    kind: "smoke",
    status: "passed",
    summary: "Playwright smoke launch passed.",
    createdAt: "2026-03-19T00:00:02.000Z",
    ref: "smoke:playwright",
  });

  const report = createTmaExecutionReport({
    reportId: "report-1",
    planId: plan.planId,
    provisionId: plan.provisionId,
    lane: "extended",
    status: "completed",
    summary: "Capability package built successfully.",
    startedAt: "2026-03-19T00:00:03.000Z",
    completedAt: "2026-03-19T00:00:04.000Z",
    producedArtifactRefs: ["tool:playwright", "binding:playwright"],
    verificationEvidenceIds: [evidence.evidenceId],
    rollbackHandleId: rollbackHandle.handleId,
  });

  assert.equal(plan.requestedLane, "extended");
  assert.equal(plan.requiresApproval, true);
  assert.equal(rollbackHandle.strategy, "remove artifacts and restore previous binding");
  assert.equal(evidence.status, "passed");
  assert.equal(report.rollbackHandleId, rollbackHandle.handleId);
});
