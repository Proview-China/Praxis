import type {
  AgentCoreCmpMpCandidateExportV1,
  AgentCoreCmpTapReviewApertureV1,
  AgentCoreCmpWorksiteApi,
  AgentCoreCmpWorksiteState,
  AgentCoreCmpWorksiteTurnArtifactInput,
} from "../cmp-api/index.js";
import type { CoreCmpWorksitePackageV1 } from "../core-prompt/types.js";
import type { CmpFiveAgentSummary, CmpFiveAgentRuntimeSnapshot } from "../cmp-five-agent/index.js";
import type { CheckedSnapshot, CmpStoredSection } from "../cmp-types/index.js";
import { createMpScopeDescriptor, type MpMemoryKind } from "../mp-types/index.js";
import type { AgentCoreCmpStateStore } from "./state-store.js";
import type { AgentCoreCmpWorksiteStateRecord } from "./state-store.js";

function makeWorksiteKey(sessionId: string, agentId: string): string {
  return `${sessionId}::${agentId}`;
}

function toDeliveryStatus(
  cmp: AgentCoreCmpWorksiteTurnArtifactInput["cmp"],
): AgentCoreCmpWorksiteState["deliveryStatus"] {
  if (cmp.syncStatus === "skipped") {
    return "skipped";
  }
  if (cmp.syncStatus === "warming" || cmp.syncStatus === "ingested" || cmp.syncStatus === "checked" || cmp.syncStatus === "materialized") {
    return "pending";
  }
  if (cmp.syncStatus === "failed") {
    return "partial";
  }
  const values = [
    cmp.packageId,
    cmp.packageRef,
    cmp.projectionId,
    cmp.snapshotId,
    cmp.intent,
    cmp.operatorGuide,
    cmp.childGuide,
    cmp.checkerReason,
    cmp.routeRationale,
    cmp.scopePolicy,
    cmp.packageStrategy,
    cmp.timelineStrategy,
  ].map((value) => value.trim().toLowerCase());
  if (values.some((value) => value === "pending")) {
    return "pending";
  }
  if (values.some((value) => value === "missing")) {
    return "partial";
  }
  return "available";
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : undefined;
}

function readString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

function readCmpSummary(
  value: AgentCoreCmpWorksiteTurnArtifactInput["cmp"],
): CmpFiveAgentSummary | undefined {
  const summary = (value as Record<string, unknown>).summary;
  return summary && typeof summary === "object"
    ? summary as CmpFiveAgentSummary
    : undefined;
}

function readStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return [...new Set(value
    .filter((entry): entry is string => typeof entry === "string" && entry.trim().length > 0)
    .map((entry) => entry.trim()))];
}

function isCmpStoredSectionLike(value: unknown): value is CmpStoredSection {
  const record = asRecord(value);
  return Boolean(
    record
    && typeof record.id === "string"
    && typeof record.projectId === "string"
    && typeof record.agentId === "string"
    && typeof record.sourceSectionId === "string"
    && typeof record.plane === "string"
    && typeof record.storageRef === "string"
    && typeof record.state === "string"
    && typeof record.visibility === "string"
    && typeof record.persistedAt === "string"
    && typeof record.updatedAt === "string",
  );
}

function readCmpStoredSectionsFromSnapshot(snapshot: CheckedSnapshot): CmpStoredSection[] {
  const storedSections = snapshot.metadata?.cmpStoredSections;
  if (!Array.isArray(storedSections)) {
    return [];
  }
  return storedSections
    .filter(isCmpStoredSectionLike)
    .map((section) => ({
      ...section,
      metadata: section.metadata ? structuredClone(section.metadata) : undefined,
    }));
}

function filterExportableCmpStoredSections(storedSections: CmpStoredSection[]): CmpStoredSection[] {
  return storedSections.filter((section) =>
    section.state === "stored"
    || section.state === "checked"
    || section.state === "promoted"
    || section.state === "dispatched");
}

function readSourceAnchorRefs(snapshot: CmpFiveAgentRuntimeSnapshot, summary: CmpFiveAgentSummary): string[] {
  const dispatcherBundle = asRecord(summary.latestRoleMetadata.dispatcher?.bundle);
  const fromDispatcher = readStringArray(dispatcherBundle?.sourceAnchorRefs);
  if (fromDispatcher.length > 0) {
    return fromDispatcher;
  }
  const icmaOutput = asRecord(summary.latestRoleMetadata.icma?.structuredOutput);
  const fromIcma = readStringArray(icmaOutput?.sourceAnchorRefs);
  if (fromIcma.length > 0) {
    return fromIcma;
  }
  return snapshot.dispatcherRecords.at(-1)?.bundle.sourceAnchorRefs ?? [];
}

function createLatestStages(summary: CmpFiveAgentSummary): string[] {
  return Object.entries(summary.latestStages)
    .filter(([, stage]) => typeof stage === "string" && stage.trim().length > 0)
    .map(([role, stage]) => `${role}:${stage}`);
}

function createReviewStateSummary(summary: CmpFiveAgentSummary): string | undefined {
  const parts = [
    summary.parentPromoteReviewCount > 0 ? `parent review ${summary.parentPromoteReviewCount}` : undefined,
    summary.flow.pendingPeerApprovalCount > 0 ? `peer approval pending ${summary.flow.pendingPeerApprovalCount}` : undefined,
    summary.flow.reinterventionPendingCount > 0 ? `reintervention pending ${summary.flow.reinterventionPendingCount}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(", ") : undefined;
}

function createUnresolvedStateSummary(summary: CmpFiveAgentSummary): string | undefined {
  const parts = [
    summary.flow.pendingPeerApprovalCount > 0 ? `pending peer approvals=${summary.flow.pendingPeerApprovalCount}` : undefined,
    summary.parentPromoteReviewCount > 0 ? `parent reviews=${summary.parentPromoteReviewCount}` : undefined,
    summary.flow.reinterventionPendingCount > 0 ? `reinterventions=${summary.flow.reinterventionPendingCount}` : undefined,
    summary.recovery.missingCheckpointRoles.length > 0
      ? `missing checkpoints=${summary.recovery.missingCheckpointRoles.join("|")}`
      : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(", ") : undefined;
}

function createRouteStateSummary(summary: CmpFiveAgentSummary): string | undefined {
  const dispatcherBundle = asRecord(summary.latestRoleMetadata.dispatcher?.bundle);
  const target = asRecord(dispatcherBundle?.target);
  const body = asRecord(dispatcherBundle?.body);
  const pieces = [
    readString(target?.targetIngress),
    readString(body?.bodyStrategy),
    readString(body?.packageKind),
  ].filter((value): value is string => Boolean(value));
  return pieces.length > 0 ? pieces.join(" / ") : undefined;
}

function createPackageFamilySummary(snapshot: CmpFiveAgentRuntimeSnapshot): string | undefined {
  const family = snapshot.packageFamilies.at(-1);
  if (!family) {
    return undefined;
  }
  const taskSnapshotIds = Array.isArray(family.taskSnapshotIds) ? family.taskSnapshotIds : [];
  const parts = [
    `family ${family.familyId}`,
    `primary ${family.primaryPackageRef}`,
    family.timelinePackageRef ? `timeline ${family.timelinePackageRef}` : undefined,
    taskSnapshotIds.length > 0 ? `task snapshots ${taskSnapshotIds.length}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.join(", ");
}

function createActiveLineSummary(input: {
  summary: CmpFiveAgentSummary;
  snapshot: CmpFiveAgentRuntimeSnapshot;
}): string | undefined {
  const family = input.snapshot.packageFamilies.at(-1);
  const latestDispatch = input.snapshot.dispatcherRecords.at(-1);
  const parts = [
    family?.familyId ? `family ${family.familyId}` : undefined,
    latestDispatch?.packageMode ? `mode ${latestDispatch.packageMode}` : undefined,
    latestDispatch?.targetAgentId ? `target ${latestDispatch.targetAgentId}` : undefined,
    input.summary.flow.childSeedToIcmaCount > 0 ? `child seeds ${input.summary.flow.childSeedToIcmaCount}` : undefined,
    input.summary.flow.passiveReturnCount > 0 ? `passive returns ${input.summary.flow.passiveReturnCount}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(", ") : undefined;
}

function createOrchestrationSummary(summary: CmpFiveAgentSummary): string | undefined {
  const parts = [
    summary.parentPromoteReviewCount > 0 ? `parent reviews ${summary.parentPromoteReviewCount}` : undefined,
    summary.flow.pendingPeerApprovalCount > 0 ? `peer approvals ${summary.flow.pendingPeerApprovalCount}` : undefined,
    summary.flow.reinterventionPendingCount > 0 ? `reinterventions ${summary.flow.reinterventionPendingCount}` : undefined,
    summary.flow.childSeedToIcmaCount > 0 ? `child seeds ${summary.flow.childSeedToIcmaCount}` : undefined,
    summary.flow.passiveReturnCount > 0 ? `passive returns ${summary.flow.passiveReturnCount}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(", ") : undefined;
}

function createTimelineSummary(snapshot: CmpFiveAgentRuntimeSnapshot): string | undefined {
  const family = snapshot.packageFamilies.at(-1);
  if (!family) {
    return undefined;
  }
  const taskSnapshotIds = Array.isArray(family.taskSnapshotIds) ? family.taskSnapshotIds : [];
  const parts = [
    family.timelinePackageRef ? `timeline ${family.timelinePackageRef}` : undefined,
    taskSnapshotIds.length > 0 ? `task snapshots ${taskSnapshotIds.length}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(", ") : undefined;
}

function resolvePackageFamilySummary(record: AgentCoreCmpWorksiteStateRecord): string | undefined {
  return record.derived.packageFamilySummary
    ?? (record.latestCmp.packageRef ? `primary ${record.latestCmp.packageRef}` : undefined);
}

function resolveActiveLineSummary(record: AgentCoreCmpWorksiteStateRecord): string | undefined {
  return record.derived.activeLineSummary
    ?? [
      record.latestCmp.packageRef ? `package ${record.latestCmp.packageRef}` : undefined,
      record.latestCmp.routeRationale ? `route ${record.latestCmp.routeRationale}` : undefined,
    ].filter((value): value is string => Boolean(value)).join(", ");
}

function resolveOrchestrationSummary(record: AgentCoreCmpWorksiteStateRecord): string | undefined {
  return record.derived.orchestrationSummary
    ?? record.derived.reviewStateSummary
    ?? record.derived.unresolvedStateSummary;
}

function resolveTimelineSummary(record: AgentCoreCmpWorksiteStateRecord): string | undefined {
  return record.derived.timelineSummary
    ?? record.latestCmp.timelineStrategy;
}

function inferMpMemoryKind(storedSection: CmpStoredSection): MpMemoryKind {
  const sectionKind = typeof storedSection.metadata?.sectionKind === "string"
    ? storedSection.metadata.sectionKind
    : undefined;
  switch (sectionKind) {
    case "runtime_context":
      return "status_snapshot";
    case "historical_context":
      return "episodic";
    default:
      return "semantic";
  }
}

function createMpCandidateConfidence(
  record: AgentCoreCmpWorksiteStateRecord,
  snapshot: CheckedSnapshot,
): "high" | "medium" | "low" {
  if (record.deliveryStatus === "available" && snapshot.qualityLabel === "usable") {
    return "high";
  }
  if (record.deliveryStatus === "partial") {
    return "low";
  }
  return "medium";
}

function buildMpCandidateExport(
  record: AgentCoreCmpWorksiteStateRecord,
  snapshot: CheckedSnapshot | undefined,
  input: {
    currentObjective?: string;
    limit?: number;
  },
): AgentCoreCmpMpCandidateExportV1 {
  const storedSections = snapshot ? filterExportableCmpStoredSections(readCmpStoredSectionsFromSnapshot(snapshot)) : [];
  const limit = typeof input.limit === "number" && Number.isFinite(input.limit) && input.limit > 0
    ? Math.max(1, Math.floor(input.limit))
    : storedSections.length;
  const sourceRefs = [
    ...record.derived.sourceAnchorRefs,
    record.latestCmp.packageRef,
    snapshot?.snapshotId,
  ].filter((value): value is string => typeof value === "string" && value.trim().length > 0);
  const candidates = record.deliveryStatus === "available" && snapshot
    ? storedSections.slice(0, limit).map((storedSection, index) => ({
      storedSection,
      checkedSnapshotRef: snapshot.snapshotId,
      branchRef: snapshot.branchRef,
      scope: createMpScopeDescriptor({
        projectId: storedSection.projectId,
        agentId: storedSection.agentId,
        sessionId: record.sessionId,
        scopeLevel: "agent_isolated",
        sessionMode: "bridged",
        lineagePath: [storedSection.agentId],
        metadata: {
          source: "cmp_worksite_export",
          cmpSuggestedScopeLevel: "project",
          cmpPackageRef: record.latestCmp.packageRef,
        },
      }),
      confidence: createMpCandidateConfidence(record, snapshot),
      observedAt: snapshot.checkedAt,
      capturedAt: record.updatedAt,
      sourceRefs,
      memoryKind: inferMpMemoryKind(storedSection),
      metadata: {
        schemaVersion: "cmp-mp-candidate/v1",
        candidateSource: "cmp_worksite_export",
        candidateOrdinal: index + 1,
        cmpSessionId: record.sessionId,
        cmpAgentId: record.agentId,
        cmpCurrentObjective: input.currentObjective ?? record.currentObjective,
        cmpPackageId: record.latestCmp.packageId,
        cmpPackageRef: record.latestCmp.packageRef,
        cmpPackageFamilyId: record.derived.packageFamilyId,
        cmpPackageFamilySummary: record.derived.packageFamilySummary,
        cmpPrimaryPackageRef: record.derived.primaryPackageRef,
        cmpProjectionId: record.latestCmp.projectionId,
        cmpSnapshotId: snapshot.snapshotId,
        cmpRouteRationale: record.latestCmp.routeRationale,
        cmpRouteStateSummary: record.derived.routeStateSummary,
        cmpScopePolicy: record.latestCmp.scopePolicy,
        cmpReviewStateSummary: record.derived.reviewStateSummary,
        cmpUnresolvedStateSummary: record.derived.unresolvedStateSummary,
        cmpOrchestrationSummary: record.derived.orchestrationSummary,
        cmpTimelineSummary: record.derived.timelineSummary,
        cmpSourceAnchorRefs: [...record.derived.sourceAnchorRefs],
        cmpRecoveryStatus: record.derived.recoveryStatus,
        cmpTaskSummary: record.latestCmp.intent,
        cmpOperatorGuide: record.latestCmp.operatorGuide,
      },
    }))
    : [];

  return {
    schemaVersion: "cmp-mp-candidate-export/v1",
    sessionId: record.sessionId,
    agentId: record.agentId,
    currentObjective: input.currentObjective ?? record.currentObjective,
    packageRef: record.latestCmp.packageRef,
    packageFamilyId: record.derived.packageFamilyId,
    snapshotId: snapshot?.snapshotId ?? record.latestCmp.snapshotId,
    routeRationale: record.latestCmp.routeRationale,
    scopePolicy: record.latestCmp.scopePolicy,
    routeStateSummary: record.derived.routeStateSummary,
    reviewStateSummary: record.derived.reviewStateSummary,
    unresolvedStateSummary: record.derived.unresolvedStateSummary,
    packageFamilySummary: resolvePackageFamilySummary(record),
    activeLineSummary: resolveActiveLineSummary(record),
    orchestrationSummary: resolveOrchestrationSummary(record),
    timelineSummary: resolveTimelineSummary(record),
    candidateExportSummary: `policy=checked_governed_package_grade, exportable=${storedSections.length}, emitted=${candidates.length}`,
    sourceAnchorRefs: [...record.derived.sourceAnchorRefs],
    candidates,
  };
}

function toConfidenceLabel(
  deliveryStatus: CoreCmpWorksitePackageV1["deliveryStatus"],
): NonNullable<CoreCmpWorksitePackageV1["governance"]>["confidenceLabel"] {
  if (deliveryStatus === "available") {
    return "high";
  }
  if (deliveryStatus === "partial") {
    return "medium";
  }
  return "low";
}

function toFreshness(
  deliveryStatus: CoreCmpWorksitePackageV1["deliveryStatus"],
): NonNullable<CoreCmpWorksitePackageV1["governance"]>["freshness"] {
  if (deliveryStatus === "available") {
    return "fresh";
  }
  if (deliveryStatus === "partial") {
    return "aging";
  }
  return "stale";
}

function toPublicState(
  record: AgentCoreCmpWorksiteStateRecord,
): AgentCoreCmpWorksiteState {
  return {
    sessionId: record.sessionId,
    agentId: record.agentId,
    activeTurnIndex: record.activeTurnIndex,
    currentObjective: record.currentObjective,
    updatedAt: record.updatedAt,
    deliveryStatus: record.deliveryStatus,
    packageId: record.latestCmp.packageId,
    packageRef: record.latestCmp.packageRef,
    packageMode: record.latestCmp.packageMode,
    snapshotId: record.latestCmp.snapshotId,
  };
}

function findCurrentRecord(
  store: AgentCoreCmpStateStore,
  input: { sessionId: string; agentId?: string },
) {
  const matched = [...store.worksiteRecords.values()]
    .filter((record) =>
      record.sessionId === input.sessionId
      && (!input.agentId || record.agentId === input.agentId))
    .sort((left, right) =>
      right.activeTurnIndex - left.activeTurnIndex
      || right.updatedAt.localeCompare(left.updatedAt));
  return matched[0];
}

function createDerivedState(input: {
  summary: CmpFiveAgentSummary;
  snapshot: CmpFiveAgentRuntimeSnapshot;
}): AgentCoreCmpWorksiteStateRecord["derived"] {
  const packageFamily = input.snapshot.packageFamilies.at(-1);
  return {
    packageFamilyId: packageFamily?.familyId,
    primaryPackageId: packageFamily?.primaryPackageId,
    primaryPackageRef: packageFamily?.primaryPackageRef,
    packageFamilySummary: createPackageFamilySummary(input.snapshot),
    activeLineSummary: createActiveLineSummary(input),
    orchestrationSummary: createOrchestrationSummary(input.summary),
    timelineSummary: createTimelineSummary(input.snapshot),
    sourceAnchorRefs: readSourceAnchorRefs(input.snapshot, input.summary),
    reviewStateSummary: createReviewStateSummary(input.summary),
    routeStateSummary: createRouteStateSummary(input.summary),
    unresolvedStateSummary: createUnresolvedStateSummary(input.summary),
    pendingPeerApprovalCount: input.summary.flow.pendingPeerApprovalCount,
    approvedPeerApprovalCount: input.summary.flow.approvedPeerApprovalCount,
    parentPromoteReviewCount: input.summary.parentPromoteReviewCount,
    reinterventionPendingCount: input.summary.flow.reinterventionPendingCount,
    reinterventionServedCount: input.summary.flow.reinterventionServedCount,
    childSeedToIcmaCount: input.summary.flow.childSeedToIcmaCount,
    passiveReturnCount: input.summary.flow.passiveReturnCount,
    latestStages: createLatestStages(input.summary),
    recoveryStatus: input.summary.recovery.missingCheckpointRoles.length === 0 ? "healthy" : "degraded",
  };
}

export function createAgentCoreCmpWorksiteService(
  stateStore: AgentCoreCmpStateStore,
): AgentCoreCmpWorksiteApi {
  return {
    observeTurn(input) {
      const deliveryStatus = toDeliveryStatus(input.cmp);
      const updatedAt = input.observedAt ?? new Date().toISOString();
      const summary = readCmpSummary(input.cmp)
        ?? stateStore.runtime.getCmpFiveAgentRuntimeSummary(input.cmp.agentId);
      const snapshot = stateStore.runtime.getCmpFiveAgentRuntimeSnapshot(input.cmp.agentId);
      const record = {
        sessionId: input.sessionId,
        agentId: input.cmp.agentId,
        activeTurnIndex: input.turnIndex,
        currentObjective: input.currentObjective,
        updatedAt,
        deliveryStatus,
        latestCmp: {
          ...input.cmp,
        },
        derived: createDerivedState({
          summary,
          snapshot,
        }),
      };
      stateStore.worksiteRecords.set(makeWorksiteKey(input.sessionId, input.cmp.agentId), record);
      return toPublicState(record);
    },
    getCurrent(input) {
      const record = findCurrentRecord(stateStore, input);
      return record ? toPublicState(record) : undefined;
    },
    clearSession(input) {
      for (const [key, record] of stateStore.worksiteRecords.entries()) {
        if (record.sessionId !== input.sessionId) {
          continue;
        }
        if (input.agentId && record.agentId !== input.agentId) {
          continue;
        }
        stateStore.worksiteRecords.delete(key);
      }
    },
    exportCorePackage(input) {
      const record = findCurrentRecord(stateStore, input);
      if (!record) {
        return {
          schemaVersion: "core-cmp-worksite-package/v1",
          deliveryStatus: "absent",
          objective: {
            currentObjective: input.currentObjective,
            taskSummary: "no active CMP worksite is available yet",
          },
          governance: {
            operatorGuide: "proceed from the explicit current user objective and verified current evidence",
            confidenceLabel: "low",
            freshness: "stale",
            recoveryStatus: "degraded",
          },
        };
      }
      const deliveryStatus = record.deliveryStatus;

      return {
        schemaVersion: "core-cmp-worksite-package/v1",
        deliveryStatus,
        identity: {
          sessionId: record.sessionId,
          agentId: record.agentId,
          packageId: record.latestCmp.packageId,
          packageRef: record.latestCmp.packageRef,
          packageKind: record.latestCmp.packageKind,
          packageMode: record.latestCmp.packageMode,
          projectionId: record.latestCmp.projectionId,
          snapshotId: record.latestCmp.snapshotId,
          packageFamilyId: record.derived.packageFamilyId,
          primaryPackageId: record.derived.primaryPackageId,
          primaryPackageRef: record.derived.primaryPackageRef,
        },
        objective: {
          currentObjective: input.currentObjective ?? record.currentObjective,
          taskSummary: record.latestCmp.intent,
          requestedAction: record.latestCmp.operatorGuide,
          activeTurnIndex: record.activeTurnIndex,
        },
        payload: {
          primaryContext: record.derived.packageFamilyId
            ? `active package family ${record.derived.packageFamilyId} with primary ${record.derived.primaryPackageRef}`
            : `latest package ${record.latestCmp.packageRef}`,
          backgroundContext: record.latestCmp.childGuide,
          timelineSummary: resolveTimelineSummary(record),
          packageFamilySummary: resolvePackageFamilySummary(record),
          activeLineSummary: resolveActiveLineSummary(record),
          orchestrationSummary: resolveOrchestrationSummary(record),
          sourceAnchorRefs: record.derived.sourceAnchorRefs,
          unresolvedStateSummary: record.derived.unresolvedStateSummary,
          reviewStateSummary: record.derived.reviewStateSummary,
          routeStateSummary: record.derived.routeStateSummary,
        },
        governance: {
          operatorGuide: record.latestCmp.operatorGuide,
          childGuide: record.latestCmp.childGuide,
          checkerReason: record.latestCmp.checkerReason,
          routeRationale: record.latestCmp.routeRationale,
          scopePolicy: record.latestCmp.scopePolicy,
          fidelityLabel: record.latestCmp.fidelityLabel,
          confidenceLabel: toConfidenceLabel(deliveryStatus),
          freshness: toFreshness(deliveryStatus),
          recoveryStatus: record.derived.recoveryStatus,
        },
        flow: {
          pendingPeerApprovalCount: record.derived.pendingPeerApprovalCount,
          approvedPeerApprovalCount: record.derived.approvedPeerApprovalCount,
          parentPromoteReviewCount: record.derived.parentPromoteReviewCount,
          reinterventionPendingCount: record.derived.reinterventionPendingCount,
          reinterventionServedCount: record.derived.reinterventionServedCount,
          childSeedToIcmaCount: record.derived.childSeedToIcmaCount,
          passiveReturnCount: record.derived.passiveReturnCount,
          latestStages: record.derived.latestStages,
        },
      };
    },
    exportTapPackage(input) {
      const record = findCurrentRecord(stateStore, input);
      if (!record) {
        return undefined;
      }
      return {
        schemaVersion: "cmp-tap-review-aperture/v1",
        sessionId: record.sessionId,
        agentId: record.agentId,
        currentObjective: input.currentObjective ?? record.currentObjective,
        requestedCapabilityKey: input.requestedCapabilityKey,
        packageRef: record.latestCmp.packageRef,
        packageFamilyId: record.derived.packageFamilyId,
        snapshotId: record.latestCmp.snapshotId,
        checkerReason: record.latestCmp.checkerReason,
        routeRationale: record.latestCmp.routeRationale,
        routeStateSummary: record.derived.routeStateSummary,
        reviewStateSummary: record.derived.reviewStateSummary,
        unresolvedStateSummary: record.derived.unresolvedStateSummary,
        sourceAnchorRefs: record.derived.sourceAnchorRefs,
        pendingPeerApprovalCount: record.derived.pendingPeerApprovalCount,
        parentPromoteReviewCount: record.derived.parentPromoteReviewCount,
        reinterventionPendingCount: record.derived.reinterventionPendingCount,
      };
    },
    exportMpCandidates(input) {
      const record = findCurrentRecord(stateStore, input);
      if (!record) {
        return {
          schemaVersion: "cmp-mp-candidate-export/v1",
          sessionId: input.sessionId,
          agentId: input.agentId ?? "unknown",
          currentObjective: input.currentObjective,
          candidates: [],
        };
      }
      const snapshot = stateStore.runtime.getCmpCheckedSnapshot(record.latestCmp.snapshotId);
      return buildMpCandidateExport(record, snapshot, input);
    },
  };
}
