import {
  createTmaExecutionReport,
  createTmaRollbackHandle,
  createTmaVerificationEvidence,
  type TmaBuildPlan,
  type TmaExecutionLane,
  type TmaExecutionReport,
  type TmaRollbackHandle,
  type TmaVerificationEvidence,
} from "../ta-pool-types/index.js";

export interface ExecuteTmaPlanInput {
  plan: TmaBuildPlan;
  lane?: TmaExecutionLane;
  startedAt: string;
  completedAt?: string;
  producedArtifactRefs?: string[];
  verificationRefs?: string[];
  status?: "completed" | "failed" | "cancelled";
}

export interface TmaExecutorResult {
  report: TmaExecutionReport;
  verificationEvidence: TmaVerificationEvidence[];
  rollbackHandle: TmaRollbackHandle;
}

export function executeTmaPlan(
  input: ExecuteTmaPlanInput,
): TmaExecutorResult {
  const verificationEvidence = (input.plan.verificationPlan.length > 0
    ? input.plan.verificationPlan
    : ["smoke verification"])
    .map((summary, index) =>
      createTmaVerificationEvidence({
        evidenceId: `${input.plan.planId}:evidence:${index + 1}`,
        planId: input.plan.planId,
        provisionId: input.plan.provisionId,
        kind: "test",
        status: input.status === "failed" ? "failed" : "passed",
        summary,
        createdAt: input.completedAt ?? input.startedAt,
        ref: input.verificationRefs?.[index],
      }));

  const rollbackHandle = createTmaRollbackHandle({
    handleId: `${input.plan.planId}:rollback`,
    summary: input.plan.rollbackPlan[0] ?? `Rollback ${input.plan.requestedCapabilityKey}`,
    strategy: input.plan.rollbackPlan.join("; ") || "No-op rollback",
    createdAt: input.completedAt ?? input.startedAt,
  });

  const report = createTmaExecutionReport({
    reportId: `${input.plan.planId}:report`,
    planId: input.plan.planId,
    provisionId: input.plan.provisionId,
    lane: input.lane ?? input.plan.requestedLane,
    status: input.status ?? "completed",
    summary: `Executed plan for ${input.plan.requestedCapabilityKey}.`,
    startedAt: input.startedAt,
    completedAt: input.completedAt,
    producedArtifactRefs: input.producedArtifactRefs,
    verificationEvidenceIds: verificationEvidence.map((item) => item.evidenceId),
    rollbackHandleId: rollbackHandle.handleId,
  });

  return {
    report,
    verificationEvidence,
    rollbackHandle,
  };
}

export const executeTmaBuildPlan = executeTmaPlan;
