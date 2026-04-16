import path from "node:path";

import {
  createMpLineageNode,
} from "../index.js";
import { rax } from "../../rax/runtime.js";
import type {
  RaxMpCmpCandidateExportEnvelope,
  RaxMpCmpCandidatePayload,
} from "../../rax/mp-types.js";
import type {
  CoreCmpWorksitePackageV1,
  CoreMpRoutedPackageV1,
  CoreOverlayIndexEntryV1,
} from "../core-prompt/types.js";
import { createMemoryOverlayIndexEntries } from "../core-prompt/memory-overlay-index-producer.js";
import { loadRepoMemoryOverlaySnapshot } from "./repo-memory-overlay-source.js";

function createProjectId(cwd: string): string {
  const slug = cwd
    .replace(/[^a-z0-9]+/giu, "-")
    .replace(/^-+|-+$/gu, "")
    .toLowerCase()
    .slice(-48);
  return `project.mp-overlay.${slug || "default"}`;
}

function toOverlayEntry(record: {
  memoryId: string;
  semanticGroupId?: string;
  sourceStoredSectionId?: string;
  bodyRef?: string;
  memoryKind: string;
  freshness: { status: string };
  confidence: string;
  alignment: { alignmentStatus: string };
  tags: string[];
}): CoreOverlayIndexEntryV1 {
  const bodyRef = record.bodyRef
    ? (record.bodyRef.startsWith("memory-body:")
      ? record.bodyRef
      : `memory-body:${record.bodyRef}`)
    : undefined;
  return {
    id: `memory:${record.memoryId}`,
    label: record.semanticGroupId ?? record.sourceStoredSectionId ?? record.bodyRef ?? record.memoryId,
    summary: [
      record.memoryKind,
      record.freshness.status,
      record.alignment.alignmentStatus,
      record.confidence,
      record.tags.length > 0 ? `tags:${record.tags.slice(0, 3).join("|")}` : undefined,
    ].filter((part): part is string => Boolean(part)).join(" / "),
    bodyRef,
  };
}

function cloneFallbackEntry(entry: CoreOverlayIndexEntryV1): CoreOverlayIndexEntryV1 {
  return {
    id: entry.id,
    label: entry.label,
    summary: entry.summary,
    bodyRef: entry.bodyRef,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object";
}

function asNonEmptyString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

type CmpCandidateRejectionReason =
  | "invalid_candidate_shape"
  | "missing_stored_section_identity"
  | "missing_required_fields"
  | "missing_scope_descriptor"
  | "duplicate_candidate";

interface NormalizedCmpCandidateEnvelopeMetadata {
  sessionId?: string;
  agentId?: string;
  currentObjective?: string;
  packageRef?: string;
  packageFamilyId?: string;
  snapshotId?: string;
  routeRationale?: string;
  scopePolicy?: string;
  reviewStateSummary?: string;
  unresolvedStateSummary?: string;
  sourceAnchorRefs?: string[];
  metadata?: Record<string, unknown>;
}

function readStoredSectionIdentity(storedSection: Record<string, unknown>): {
  storedSectionId?: string;
  storageRef?: string;
} {
  return {
    storedSectionId: asNonEmptyString(storedSection.id) ?? asNonEmptyString(storedSection.storedSectionId),
    storageRef: asNonEmptyString(storedSection.storageRef),
  };
}

function normalizeScopeDescriptor(scope: unknown): RaxMpCmpCandidatePayload["scope"] | undefined {
  if (!isRecord(scope)) {
    return undefined;
  }
  const projectId = asNonEmptyString(scope.projectId);
  const agentId = asNonEmptyString(scope.agentId);
  const scopeLevel = asNonEmptyString(scope.scopeLevel);
  const sessionMode = asNonEmptyString(scope.sessionMode);
  if (!projectId || !agentId || !scopeLevel || !sessionMode) {
    return undefined;
  }
  return scope as unknown as RaxMpCmpCandidatePayload["scope"];
}

function normalizeCmpCandidatePayload(candidate: unknown): {
  candidate?: RaxMpCmpCandidatePayload;
  rejectionReason?: CmpCandidateRejectionReason;
} {
  if (!isRecord(candidate)) {
    return {
      rejectionReason: "invalid_candidate_shape",
    };
  }
  const storedSection = candidate.storedSection;
  const checkedSnapshotRef = asNonEmptyString(candidate.checkedSnapshotRef);
  const branchRef = asNonEmptyString(candidate.branchRef);
  if (!isRecord(storedSection)) {
    return {
      rejectionReason: "missing_required_fields",
    };
  }
  const scope = normalizeScopeDescriptor(candidate.scope);
  const storedSectionIdentity = readStoredSectionIdentity(storedSection);
  if (!storedSectionIdentity.storedSectionId && !storedSectionIdentity.storageRef) {
    return {
      rejectionReason: "missing_stored_section_identity",
    };
  }
  if (!checkedSnapshotRef || !branchRef) {
    return {
      rejectionReason: "missing_required_fields",
    };
  }
  if (!scope) {
    return {
      rejectionReason: "missing_scope_descriptor",
    };
  }
  const normalized: RaxMpCmpCandidatePayload = {
    storedSection: storedSection as unknown as RaxMpCmpCandidatePayload["storedSection"],
    checkedSnapshotRef,
    branchRef,
    scope,
  };
  const confidence = asNonEmptyString(candidate.confidence);
  if (confidence === "high" || confidence === "medium" || confidence === "low") {
    normalized.confidence = confidence;
  }
  const observedAt = asNonEmptyString(candidate.observedAt);
  if (observedAt) {
    normalized.observedAt = observedAt;
  }
  const capturedAt = asNonEmptyString(candidate.capturedAt);
  if (capturedAt) {
    normalized.capturedAt = capturedAt;
  }
  const memoryKind = asNonEmptyString(candidate.memoryKind);
  if (memoryKind) {
    normalized.memoryKind = memoryKind as RaxMpCmpCandidatePayload["memoryKind"];
  }
  if (Array.isArray(candidate.sourceRefs)) {
    const sourceRefs = candidate.sourceRefs
      .map((value) => asNonEmptyString(value))
      .filter((value): value is string => Boolean(value));
    if (sourceRefs.length > 0) {
      normalized.sourceRefs = sourceRefs;
    }
  }
  if (isRecord(candidate.metadata)) {
    normalized.metadata = candidate.metadata;
  }
  return {
    candidate: normalized,
  };
}

function buildCmpCandidateDedupKey(candidate: RaxMpCmpCandidatePayload): string {
  const storedSection = candidate.storedSection as unknown as Record<string, unknown>;
  const identity = readStoredSectionIdentity(storedSection);
  return [
    identity.storedSectionId ?? identity.storageRef ?? "unknown",
    candidate.checkedSnapshotRef,
    candidate.branchRef,
  ].join("|");
}

function summarizeCandidateRejections(
  rejectedByReason: Partial<Record<CmpCandidateRejectionReason, number>>,
): string | undefined {
  const entries = Object.entries(rejectedByReason)
    .filter((entry): entry is [CmpCandidateRejectionReason, number] => typeof entry[1] === "number" && entry[1] > 0);
  if (entries.length === 0) {
    return undefined;
  }
  return entries.map(([reason, count]) => `${reason}:${count}`).join(", ");
}

function summarizeCandidateProvenance(metadata: NormalizedCmpCandidateEnvelopeMetadata): string | undefined {
  const parts = [
    metadata.packageRef ? `package:${metadata.packageRef}` : undefined,
    metadata.packageFamilyId ? `family:${metadata.packageFamilyId}` : undefined,
    metadata.snapshotId ? `snapshot:${metadata.snapshotId}` : undefined,
    metadata.routeRationale ? `route:${metadata.routeRationale}` : undefined,
    metadata.scopePolicy ? `scope:${metadata.scopePolicy}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(" / ") : undefined;
}

function summarizeWorksiteCandidateProvenance(
  worksitePackage: CoreCmpWorksitePackageV1 | undefined,
): string | undefined {
  if (!worksitePackage) {
    return undefined;
  }
  const parts = [
    worksitePackage.identity?.packageRef ? `package:${worksitePackage.identity.packageRef}` : undefined,
    worksitePackage.identity?.packageFamilyId ? `family:${worksitePackage.identity.packageFamilyId}` : undefined,
    worksitePackage.payload?.sourceAnchorRefs?.[0] ? `anchor:${worksitePackage.payload.sourceAnchorRefs[0]}` : undefined,
    worksitePackage.governance?.routeRationale ? `route:${worksitePackage.governance.routeRationale}` : undefined,
    worksitePackage.governance?.scopePolicy ? `scope:${worksitePackage.governance.scopePolicy}` : undefined,
  ].filter((value): value is string => Boolean(value));
  return parts.length > 0 ? parts.join(" / ") : undefined;
}

function summarizeCandidateQualityGate(input: {
  acceptedCount: number;
  rejectedCount: number;
  rejectedByReason: Partial<Record<CmpCandidateRejectionReason, number>>;
}): string | undefined {
  if (input.acceptedCount === 0 && input.rejectedCount === 0) {
    return undefined;
  }
  const parts = [`accepted ${input.acceptedCount} candidate(s)`];
  if (input.rejectedCount > 0) {
    const rejectionSummary = summarizeCandidateRejections(input.rejectedByReason);
    parts.push(`rejected ${input.rejectedCount}${rejectionSummary ? ` (${rejectionSummary})` : ""}`);
  }
  return parts.join("; ");
}

export function normalizeCmpCandidateExportInput(input: unknown): {
  candidates: RaxMpCmpCandidatePayload[];
  acceptedCount: number;
  rejectedCount: number;
  rejectedByReason: Partial<Record<CmpCandidateRejectionReason, number>>;
  provenance: NormalizedCmpCandidateEnvelopeMetadata;
  metadata?: RaxMpCmpCandidateExportEnvelope["metadata"];
} {
  const envelope = isRecord(input) && Array.isArray(input.candidates)
    ? input as unknown as RaxMpCmpCandidateExportEnvelope
    : undefined;
  const provenance: NormalizedCmpCandidateEnvelopeMetadata = isRecord(input)
    ? {
      sessionId: asNonEmptyString(input.sessionId),
      agentId: asNonEmptyString(input.agentId),
      currentObjective: asNonEmptyString(input.currentObjective),
      packageRef: asNonEmptyString(input.packageRef),
      packageFamilyId: asNonEmptyString(input.packageFamilyId),
      snapshotId: asNonEmptyString(input.snapshotId),
      routeRationale: asNonEmptyString(input.routeRationale),
      scopePolicy: asNonEmptyString(input.scopePolicy),
      reviewStateSummary: asNonEmptyString(input.reviewStateSummary),
      unresolvedStateSummary: asNonEmptyString(input.unresolvedStateSummary),
      sourceAnchorRefs: Array.isArray(input.sourceAnchorRefs)
        ? input.sourceAnchorRefs.map((value) => asNonEmptyString(value)).filter((value): value is string => Boolean(value))
        : undefined,
      metadata: isRecord(input.metadata) ? input.metadata : undefined,
    }
    : {};
  const rawCandidates = Array.isArray(input)
    ? input
    : Array.isArray(envelope?.candidates)
      ? envelope.candidates
      : [];
  const rejectedByReason: Partial<Record<CmpCandidateRejectionReason, number>> = {};
  const candidates: RaxMpCmpCandidatePayload[] = [];
  const seenKeys = new Set<string>();
  for (const rawCandidate of rawCandidates) {
    const normalized = normalizeCmpCandidatePayload(rawCandidate);
    if (!normalized.candidate) {
      if (normalized.rejectionReason) {
        rejectedByReason[normalized.rejectionReason] = (rejectedByReason[normalized.rejectionReason] ?? 0) + 1;
      }
      continue;
    }
    const dedupKey = buildCmpCandidateDedupKey(normalized.candidate);
    if (seenKeys.has(dedupKey)) {
      rejectedByReason.duplicate_candidate = (rejectedByReason.duplicate_candidate ?? 0) + 1;
      continue;
    }
    seenKeys.add(dedupKey);
    candidates.push(normalized.candidate);
  }
  const rejectedCount = rawCandidates.length - candidates.length;
  return {
    candidates,
    acceptedCount: candidates.length,
    rejectedCount,
    rejectedByReason,
    provenance,
    metadata: provenance.metadata ?? envelope?.metadata,
  };
}

function createMpRoutingQueryText(input: {
  userMessage: string;
  currentObjective?: string;
  cmpWorksitePackage?: CoreCmpWorksitePackageV1;
}): string {
  const worksite = input.cmpWorksitePackage;
  const parts = [
    input.currentObjective,
    input.userMessage,
    worksite?.objective?.taskSummary,
    worksite?.objective?.requestedAction,
    worksite?.payload?.routeStateSummary,
    ...(worksite?.payload?.sourceAnchorRefs ?? []),
  ];
  return [...new Set(parts.map((value) => value?.trim()).filter((value): value is string => Boolean(value)))].join(" ");
}

function createMpRoutingGovernanceSignals(input: {
  cmpWorksitePackage?: CoreCmpWorksitePackageV1;
  fallbackPackage: CoreMpRoutedPackageV1;
}) {
  const worksite = input.cmpWorksitePackage;
  return {
    cmpPackageId: worksite?.identity?.packageId,
    cmpRouteRationale: worksite?.governance?.routeRationale,
    cmpScopePolicy: worksite?.governance?.scopePolicy,
    freshnessHint: worksite?.governance?.freshness ?? input.fallbackPackage.freshnessLabel,
    confidenceHint: worksite?.governance?.confidenceLabel ?? input.fallbackPackage.confidenceLabel,
  };
}

export async function discoverMpOverlayEntries(input: {
  cwd: string;
  userMessage: string;
  currentObjective?: string;
  limit?: number;
  projectId?: string;
  rootPath?: string;
  agentId?: string;
  cmpWorksitePackage?: CoreCmpWorksitePackageV1;
  cmpCandidatePayloads?: unknown;
  facade?: typeof rax;
}): Promise<CoreOverlayIndexEntryV1[]> {
  const artifacts = await discoverMpOverlayArtifacts(input);
  return artifacts.entries;
}

export async function discoverMpOverlayArtifacts(input: {
  cwd: string;
  userMessage: string;
  currentObjective?: string;
  limit?: number;
  projectId?: string;
  rootPath?: string;
  agentId?: string;
  cmpWorksitePackage?: CoreCmpWorksitePackageV1;
  cmpCandidatePayloads?: unknown;
  facade?: typeof rax;
}): Promise<{
  entries: CoreOverlayIndexEntryV1[];
  routedPackage: CoreMpRoutedPackageV1;
}> {
  const facade = input.facade ?? rax;
  const projectId = input.projectId ?? createProjectId(input.cwd);
  const rootPath = input.rootPath ?? path.join(input.cwd, "memory", "generated", "mp-overlay-cache");
  const agentId = input.agentId ?? "main";
  const snapshot = loadRepoMemoryOverlaySnapshot({
    rootDir: path.join(input.cwd, "memory"),
  });

  const repoFallback = createRepoFallbackArtifacts({
    projectId,
    userMessage: input.userMessage,
    snapshot,
    limit: input.limit,
  });

  try {
    const session = facade.mp.create({
      config: {
        projectId,
        defaultAgentId: agentId,
        lance: {
          rootPath,
        },
      },
    });

    await facade.mp.bootstrap({
      session,
      payload: {
        projectId,
        rootPath,
        agentIds: [agentId],
      },
    });

    const normalizedCmpCandidates = normalizeCmpCandidateExportInput(input.cmpCandidatePayloads);
    const candidateProvenanceSummary = summarizeCandidateProvenance(normalizedCmpCandidates.provenance)
      ?? summarizeWorksiteCandidateProvenance(input.cmpWorksitePackage);
    const candidateRejectionSummary = summarizeCandidateRejections(normalizedCmpCandidates.rejectedByReason);
    const qualityGateSummary = summarizeCandidateQualityGate(normalizedCmpCandidates);
    const fallbackSuppressed = normalizedCmpCandidates.acceptedCount > 0 && repoFallback.entries.length > 0;
    if (normalizedCmpCandidates.acceptedCount > 0) {
      await facade.mp.materializeFromCmpCandidates({
        session,
        payload: {
          candidates: normalizedCmpCandidates.candidates,
        },
      });
    }

    const requesterLineage = createMpLineageNode({
      projectId,
      agentId,
      depth: 0,
    });
    const routed = await facade.mp.routeForCore({
      session,
      payload: {
        queryText: createMpRoutingQueryText({
          userMessage: input.userMessage,
          currentObjective: input.currentObjective,
          cmpWorksitePackage: input.cmpWorksitePackage,
        }),
        currentObjective: input.currentObjective ?? input.userMessage,
        requesterLineage,
        sourceLineages: [requesterLineage],
        limit: input.limit ?? 6,
        routeHint: "resolve",
        fallbackEntries: fallbackSuppressed
          ? []
          : repoFallback.entries.map((entry) => cloneFallbackEntry(entry)),
        governanceSignals: createMpRoutingGovernanceSignals({
          cmpWorksitePackage: input.cmpWorksitePackage,
          fallbackPackage: repoFallback.routedPackage,
        }),
        metadata: {
          currentObjective: input.currentObjective ?? input.userMessage,
          cmpWorksitePackageRef: input.cmpWorksitePackage?.identity?.packageRef,
          cmpCandidateCount: normalizedCmpCandidates.acceptedCount,
          cmpCandidateRejectedCount: normalizedCmpCandidates.rejectedCount,
          cmpCandidateMetadata: normalizedCmpCandidates.metadata,
          cmpCandidateProvenance: normalizedCmpCandidates.provenance,
          cmpCandidateRejectedReasons: normalizedCmpCandidates.rejectedByReason,
          cmpFallbackSuppressed: fallbackSuppressed,
        },
      },
    });

    const fromResolve = [...routed.primaryRecords, ...routed.supportingRecords]
      .map((record) => toOverlayEntry(record))
      .slice(0, input.limit ?? 6);
    if (fromResolve.length > 0 || routed.fallbackEntries.length > 0) {
      return {
        entries: fromResolve.length > 0 ? fromResolve : routed.fallbackEntries.map((entry) => cloneFallbackEntry(entry)),
        routedPackage: toRoutedPackage({
          packageId: routed.readback.routeKind === "fallback" ? `mp-fallback:${projectId}` : `mp-route:${projectId}`,
          packageRef: routed.readback.receiptId,
          sourceClass: routed.readback.routeKind === "history"
            ? "mp_native_history"
            : routed.readback.routeKind === "fallback"
              ? "repo_memory_fallback"
              : normalizedCmpCandidates.acceptedCount > 0
                ? "cmp_seeded_memory"
                : "mp_native_resolve",
          records: [...routed.primaryRecords, ...routed.supportingRecords],
          primaryRecords: routed.primaryRecords,
          supportingRecords: routed.supportingRecords,
          deliveryStatus: routed.readback.deliveryStatus,
          objectiveSummary: routed.readback.objectiveSummary,
          objectiveMatchSummary: routed.readback.objectiveMatchSummary,
          governanceReason: routed.readback.governanceReason,
          fallbackReason: routed.readback.fallbackReason,
          receiptId: routed.readback.receiptId,
          omittedCount: routed.readback.omittedMemoryRefs.length,
          candidateIntakeCount: normalizedCmpCandidates.acceptedCount,
          candidateRejectedCount: normalizedCmpCandidates.rejectedCount,
          candidateProvenanceSummary,
          candidateRejectionSummary,
          qualityGateSummary,
          fallbackSuppressed,
          fallbackStage: routed.readback.routeKind === "fallback" ? "repo_memory_snapshot" : "none",
        }),
      };
    }

    const fallbackRecords = session.runtime.getMpManagedRecords?.() ?? [];
    if (fallbackRecords.length > 0) {
      const fallbackEntries = fallbackRecords
        .slice(0, input.limit ?? 6)
        .map((record) => toOverlayEntry(record));
      return {
        entries: fallbackEntries,
        routedPackage: toRoutedPackage({
          packageId: `mp-fallback:${projectId}`,
          packageRef: `mp-fallback:${projectId}:managed`,
          sourceClass: "repo_memory_fallback",
          records: fallbackRecords,
          primaryRecords: fallbackRecords.slice(0, input.limit ?? 3),
          supportingRecords: fallbackRecords.slice(input.limit ?? 3, input.limit ?? 6),
          deliveryStatus: "partial",
          objectiveSummary: input.userMessage,
          objectiveMatchSummary: `fallback to managed MP records for "${input.userMessage}"`,
          governanceReason: "native route returned no bundle, so managed MP records were used",
          fallbackReason: "managed_records_fallback",
          receiptId: `mp-fallback:${projectId}:managed`,
          omittedCount: 0,
          candidateIntakeCount: normalizedCmpCandidates.acceptedCount,
          candidateRejectedCount: normalizedCmpCandidates.rejectedCount,
          candidateProvenanceSummary,
          candidateRejectionSummary,
          qualityGateSummary,
          fallbackSuppressed,
          fallbackStage: "managed_records",
        }),
      };
    }

    if (fallbackSuppressed && repoFallback.entries.length > 0) {
      return {
        entries: repoFallback.entries,
        routedPackage: applyCmpDiagnosticsToFallbackPackage(repoFallback.routedPackage, {
          candidateIntakeCount: normalizedCmpCandidates.acceptedCount,
          candidateRejectedCount: normalizedCmpCandidates.rejectedCount,
          candidateProvenanceSummary,
          candidateRejectionSummary,
          qualityGateSummary,
          fallbackSuppressed,
          governanceReason: "CMP-seeded native route returned no eligible bundle, so repo-memory fallback was re-enabled as a last resort",
          fallbackReason: "repo_memory_bootstrap_after_cmp_seeded_route",
        }),
      };
    }
  } catch {
    const normalizedCmpCandidates = normalizeCmpCandidateExportInput(input.cmpCandidatePayloads);
    return {
      entries: repoFallback.entries,
      routedPackage: applyCmpDiagnosticsToFallbackPackage(repoFallback.routedPackage, {
        candidateIntakeCount: normalizedCmpCandidates.acceptedCount,
        candidateRejectedCount: normalizedCmpCandidates.rejectedCount,
        candidateProvenanceSummary: summarizeCandidateProvenance(normalizedCmpCandidates.provenance),
        candidateRejectionSummary: summarizeCandidateRejections(normalizedCmpCandidates.rejectedByReason),
        qualityGateSummary: summarizeCandidateQualityGate(normalizedCmpCandidates),
        fallbackSuppressed: normalizedCmpCandidates.acceptedCount > 0 && repoFallback.entries.length > 0,
      }),
    };
  }

  return repoFallback;
}

function applyCmpDiagnosticsToFallbackPackage(
  routedPackage: CoreMpRoutedPackageV1,
  input: {
    candidateIntakeCount: number;
    candidateRejectedCount: number;
    candidateProvenanceSummary?: string;
    candidateRejectionSummary?: string;
    qualityGateSummary?: string;
    fallbackSuppressed?: boolean;
    governanceReason?: string;
    fallbackReason?: string;
  },
): CoreMpRoutedPackageV1 {
  return {
    ...routedPackage,
    governance: {
      ...(routedPackage.governance ?? {}),
      governanceReason: input.governanceReason ?? routedPackage.governance?.governanceReason,
      fallbackReason: input.fallbackReason ?? routedPackage.governance?.fallbackReason,
      qualityGateSummary: input.qualityGateSummary,
    },
    retrieval: {
      ...(routedPackage.retrieval ?? {}),
      candidateIntakeCount: input.candidateIntakeCount,
      candidateRejectedCount: input.candidateRejectedCount,
      candidateProvenanceSummary: input.candidateProvenanceSummary,
      candidateRejectionSummary: input.candidateRejectionSummary,
      fallbackSuppressed: input.fallbackSuppressed,
      fallbackStage: routedPackage.retrieval?.fallbackStage ?? "repo_memory_snapshot",
    },
  };
}

function toRoutedPackage(input: {
  packageId: string;
  packageRef?: string;
  sourceClass: CoreMpRoutedPackageV1["sourceClass"];
  records: Array<{
    memoryId: string;
    freshness: { status: string };
    confidence: string;
  }>;
  primaryRecords: Array<{ memoryId: string }>;
  supportingRecords: Array<{ memoryId: string }>;
  deliveryStatus?: CoreMpRoutedPackageV1["deliveryStatus"];
  objectiveSummary?: string;
  objectiveMatchSummary?: string;
  governanceReason?: string;
  fallbackReason?: string;
  receiptId?: string;
  omittedCount?: number;
  candidateIntakeCount?: number;
  candidateRejectedCount?: number;
  candidateProvenanceSummary?: string;
  candidateRejectionSummary?: string;
  qualityGateSummary?: string;
  fallbackSuppressed?: boolean;
  fallbackStage?: "none" | "repo_memory_snapshot" | "managed_records";
}): CoreMpRoutedPackageV1 {
  const freshest = input.records[0];
  const deliveryStatus = input.deliveryStatus ?? (input.records.length > 0 ? "available" : "absent");
  return {
    schemaVersion: "core-mp-routed-package/v2",
    deliveryStatus,
    packageId: input.packageId,
    packageRef: input.packageRef,
    sourceClass: input.sourceClass,
    summary: input.records.length > 0
      ? `MP routed ${input.primaryRecords.length} primary and ${input.supportingRecords.length} supporting memories for "${input.objectiveSummary ?? "the current objective"}".`
      : input.fallbackReason
        ? `MP routed package fell back because ${input.fallbackReason}.`
        : "MP routed package is currently unavailable.",
    relevanceLabel: input.records.length > 0 ? "high" : "low",
    freshnessLabel: freshest
      ? (freshest.freshness.status === "fresh" || freshest.freshness.status === "aging" || freshest.freshness.status === "stale"
        ? freshest.freshness.status
        : "stale")
      : "stale",
    confidenceLabel: freshest && (freshest.confidence === "high" || freshest.confidence === "medium" || freshest.confidence === "low")
      ? freshest.confidence
      : "low",
    primaryMemoryRefs: input.primaryRecords.map((record) => record.memoryId),
    supportingMemoryRefs: input.supportingRecords.map((record) => record.memoryId),
    objective: {
      currentObjective: input.objectiveSummary,
      retrievalMode: input.sourceClass === "mp_native_history" ? "history" : input.sourceClass === "repo_memory_fallback" ? "fallback" : "resolve",
      objectiveMatchSummary: input.objectiveMatchSummary,
    },
    governance: {
      routeLabel: input.sourceClass,
      governanceReason: input.governanceReason,
      fallbackReason: input.fallbackReason,
      qualityGateSummary: input.qualityGateSummary,
    },
    retrieval: {
      receiptId: input.receiptId,
      primaryCount: input.primaryRecords.length,
      supportingCount: input.supportingRecords.length,
      omittedCount: input.omittedCount,
      candidateIntakeCount: input.candidateIntakeCount,
      candidateRejectedCount: input.candidateRejectedCount,
      candidateProvenanceSummary: input.candidateProvenanceSummary,
      candidateRejectionSummary: input.candidateRejectionSummary,
      fallbackSuppressed: input.fallbackSuppressed,
      fallbackStage: input.fallbackStage ?? "none",
    },
  };
}

function createRepoFallbackArtifacts(input: {
  projectId: string;
  userMessage: string;
  snapshot: ReturnType<typeof loadRepoMemoryOverlaySnapshot>;
  limit?: number;
}): {
  entries: CoreOverlayIndexEntryV1[];
  routedPackage: CoreMpRoutedPackageV1;
} {
  const entries = createMemoryOverlayIndexEntries({
    userMessage: input.userMessage,
    snapshot: input.snapshot,
    limit: input.limit,
  });
  return {
    entries,
    routedPackage: {
      schemaVersion: "core-mp-routed-package/v2",
      deliveryStatus: entries.length > 0 ? "partial" : "absent",
      packageId: `mp-fallback:${input.projectId}`,
      packageRef: `mp-fallback:${input.projectId}:repo`,
      sourceClass: "repo_memory_fallback",
      summary: entries.length > 0
        ? "MP-native routing is unavailable, so core is using repo-memory fallback entries for this turn."
        : "MP routed package is currently unavailable and repo-memory fallback produced no entries.",
      relevanceLabel: entries.length > 0 ? "medium" : "low",
      freshnessLabel: entries.length > 0 ? "aging" : "stale",
      confidenceLabel: entries.length > 0 ? "medium" : "low",
      primaryMemoryRefs: entries.slice(0, 3).map((entry) => entry.id),
      supportingMemoryRefs: entries.slice(3).map((entry) => entry.id),
      objective: {
        currentObjective: input.userMessage,
        retrievalMode: "fallback",
        objectiveMatchSummary: entries.length > 0
          ? `repo-memory fallback selected ${entries.length} entries for "${input.userMessage}"`
          : `no repo-memory fallback entries were available for "${input.userMessage}"`,
      },
      governance: {
        routeLabel: "repo_memory_fallback",
        governanceReason: "repo-memory bootstrap fallback remains enabled while MP-native routing is being strengthened",
        fallbackReason: entries.length > 0 ? "repo_memory_bootstrap_fallback" : "repo_memory_snapshot_empty",
      },
      retrieval: {
        receiptId: `mp-fallback:${input.projectId}:repo`,
        primaryCount: Math.min(entries.length, 3),
        supportingCount: Math.max(entries.length - 3, 0),
        omittedCount: 0,
        candidateIntakeCount: 0,
        candidateRejectedCount: 0,
        fallbackStage: "repo_memory_snapshot",
      },
    },
  };
}
