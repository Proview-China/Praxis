export const TMA_EXECUTION_LANES = [
  "bootstrap",
  "extended",
] as const;
export type TmaExecutionLane = (typeof TMA_EXECUTION_LANES)[number];

export const TMA_EXECUTION_REPORT_STATUSES = [
  "completed",
  "failed",
  "cancelled",
] as const;
export type TmaExecutionReportStatus = (typeof TMA_EXECUTION_REPORT_STATUSES)[number];

export const TMA_VERIFICATION_EVIDENCE_STATUSES = [
  "passed",
  "failed",
  "skipped",
] as const;
export type TmaVerificationEvidenceStatus = (typeof TMA_VERIFICATION_EVIDENCE_STATUSES)[number];

export const TMA_VERIFICATION_EVIDENCE_KINDS = [
  "smoke",
  "health",
  "test",
  "usage",
] as const;
export type TmaVerificationEvidenceKind = (typeof TMA_VERIFICATION_EVIDENCE_KINDS)[number];

export interface TmaBuildPlan {
  planId: string;
  provisionId: string;
  requestedCapabilityKey: string;
  requestedLane: TmaExecutionLane;
  summary: string;
  implementationSteps: string[];
  expectedArtifacts: string[];
  verificationPlan: string[];
  rollbackPlan: string[];
  requiresApproval: boolean;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTmaBuildPlanInput {
  planId: string;
  provisionId: string;
  requestedCapabilityKey: string;
  requestedLane: TmaExecutionLane;
  summary: string;
  implementationSteps?: string[];
  expectedArtifacts?: string[];
  verificationPlan?: string[];
  rollbackPlan?: string[];
  requiresApproval?: boolean;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface TmaRollbackHandle {
  handleId: string;
  summary: string;
  strategy: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTmaRollbackHandleInput {
  handleId: string;
  summary: string;
  strategy: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface TmaVerificationEvidence {
  evidenceId: string;
  planId: string;
  provisionId: string;
  kind: TmaVerificationEvidenceKind;
  status: TmaVerificationEvidenceStatus;
  summary: string;
  createdAt: string;
  ref?: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTmaVerificationEvidenceInput {
  evidenceId: string;
  planId: string;
  provisionId: string;
  kind: TmaVerificationEvidenceKind;
  status: TmaVerificationEvidenceStatus;
  summary: string;
  createdAt: string;
  ref?: string;
  metadata?: Record<string, unknown>;
}

export interface TmaExecutionReport {
  reportId: string;
  planId: string;
  provisionId: string;
  lane: TmaExecutionLane;
  status: TmaExecutionReportStatus;
  summary: string;
  startedAt: string;
  completedAt?: string;
  producedArtifactRefs: string[];
  verificationEvidenceIds: string[];
  rollbackHandleId?: string;
  metadata?: Record<string, unknown>;
}

export interface CreateTmaExecutionReportInput {
  reportId: string;
  planId: string;
  provisionId: string;
  lane: TmaExecutionLane;
  status: TmaExecutionReportStatus;
  summary: string;
  startedAt: string;
  completedAt?: string;
  producedArtifactRefs?: string[];
  verificationEvidenceIds?: string[];
  rollbackHandleId?: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

function normalizeStringArray(values: string[] | undefined): string[] {
  if (!values) {
    return [];
  }

  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

export function createTmaBuildPlan(input: CreateTmaBuildPlanInput): TmaBuildPlan {
  const plan: TmaBuildPlan = {
    planId: assertNonEmpty(input.planId, "TMA build plan planId"),
    provisionId: assertNonEmpty(input.provisionId, "TMA build plan provisionId"),
    requestedCapabilityKey: assertNonEmpty(
      input.requestedCapabilityKey,
      "TMA build plan requestedCapabilityKey",
    ),
    requestedLane: input.requestedLane,
    summary: assertNonEmpty(input.summary, "TMA build plan summary"),
    implementationSteps: normalizeStringArray(input.implementationSteps),
    expectedArtifacts: normalizeStringArray(input.expectedArtifacts),
    verificationPlan: normalizeStringArray(input.verificationPlan),
    rollbackPlan: normalizeStringArray(input.rollbackPlan),
    requiresApproval: input.requiresApproval ?? true,
    createdAt: input.createdAt,
    metadata: input.metadata,
  };

  if (plan.implementationSteps.length === 0) {
    throw new Error("TMA build plan requires at least one implementation step.");
  }

  return plan;
}

export function createTmaRollbackHandle(
  input: CreateTmaRollbackHandleInput,
): TmaRollbackHandle {
  return {
    handleId: assertNonEmpty(input.handleId, "TMA rollback handle handleId"),
    summary: assertNonEmpty(input.summary, "TMA rollback handle summary"),
    strategy: assertNonEmpty(input.strategy, "TMA rollback handle strategy"),
    createdAt: input.createdAt,
    metadata: input.metadata,
  };
}

export function createTmaVerificationEvidence(
  input: CreateTmaVerificationEvidenceInput,
): TmaVerificationEvidence {
  return {
    evidenceId: assertNonEmpty(input.evidenceId, "TMA verification evidence evidenceId"),
    planId: assertNonEmpty(input.planId, "TMA verification evidence planId"),
    provisionId: assertNonEmpty(input.provisionId, "TMA verification evidence provisionId"),
    kind: input.kind,
    status: input.status,
    summary: assertNonEmpty(input.summary, "TMA verification evidence summary"),
    createdAt: input.createdAt,
    ref: input.ref?.trim() || undefined,
    metadata: input.metadata,
  };
}

export function createTmaExecutionReport(
  input: CreateTmaExecutionReportInput,
): TmaExecutionReport {
  return {
    reportId: assertNonEmpty(input.reportId, "TMA execution report reportId"),
    planId: assertNonEmpty(input.planId, "TMA execution report planId"),
    provisionId: assertNonEmpty(input.provisionId, "TMA execution report provisionId"),
    lane: input.lane,
    status: input.status,
    summary: assertNonEmpty(input.summary, "TMA execution report summary"),
    startedAt: input.startedAt,
    completedAt: input.completedAt,
    producedArtifactRefs: normalizeStringArray(input.producedArtifactRefs),
    verificationEvidenceIds: normalizeStringArray(input.verificationEvidenceIds),
    rollbackHandleId: input.rollbackHandleId?.trim() || undefined,
    metadata: input.metadata,
  };
}
