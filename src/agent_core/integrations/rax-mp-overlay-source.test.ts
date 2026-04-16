import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import {
  discoverMpOverlayArtifacts,
  discoverMpOverlayEntries,
  normalizeCmpCandidateExportInput,
} from "./rax-mp-overlay-source.js";

function createMemoryRoot(): string {
  const root = mkdtempSync(path.join(tmpdir(), "praxis-mp-overlay-source-"));
  const memoryRoot = path.join(root, "memory");
  mkdirSync(path.join(memoryRoot, "decisions"), { recursive: true });
  writeFileSync(
    path.join(memoryRoot, "current-context.md"),
    "# Current Context\n\nCurrent repository state and active architecture facts.\n",
    "utf8",
  );
  writeFileSync(
    path.join(memoryRoot, "decisions", "ADR-0001-test.md"),
    "# ADR-0001 Test\n\n## 状态\n\n已接受\n\nDecision log for test gates.\n",
    "utf8",
  );
  return root;
}

test("discoverMpOverlayEntries resolves MP-native memory overlay entries", async () => {
  const cwd = createMemoryRoot();
  const calls: string[] = [];
  const session = {
    runtime: {
      getMpManagedRecords() {
        return [];
      },
    },
  };
  const facade = {
    mp: {
      create() {
        calls.push("create");
        return session;
      },
      async bootstrap() {
        calls.push("bootstrap");
        return { status: "bootstrapped" };
      },
      async routeForCore() {
        calls.push("routeForCore");
        return {
          status: "routed",
          routeKind: "resolve",
          primaryRecords: [
            {
              memoryId: "memory-1",
              semanticGroupId: "semantic:context",
              bodyRef: "body:memory-1",
              sourceStoredSectionId: "stored:memory-1",
              memoryKind: "summary",
              freshness: { status: "fresh" },
              confidence: "high",
              alignment: { alignmentStatus: "aligned" },
              tags: ["context"],
            },
          ],
          supportingRecords: [],
          fallbackEntries: [],
          readback: {
            receiptId: "receipt-1",
            routeKind: "resolve",
            deliveryStatus: "available",
            objectiveSummary: "继续 context 对齐",
            objectiveMatchSummary: "matched context memory",
            governanceReason: "selected via MP resolve routing discipline",
            primaryMemoryRefs: ["memory-1"],
            supportingMemoryRefs: [],
            omittedMemoryRefs: [],
            candidateCount: 1,
          },
        };
      },
    },
  };

  const entries = await discoverMpOverlayEntries({
    cwd,
    userMessage: "继续 context 对齐",
    facade: facade as never,
  });

  assert.deepEqual(calls, ["create", "bootstrap", "routeForCore"]);
  assert.equal(entries[0]?.id, "memory:memory-1");
  assert.match(entries[0]?.summary ?? "", /summary \/ fresh \/ aligned \/ high/u);
});

test("discoverMpOverlayEntries falls back to managed records when resolve returns empty bundle", async () => {
  const cwd = createMemoryRoot();
  const session = {
    runtime: {
      getMpManagedRecords() {
        return [
          {
            memoryId: "memory-2",
            semanticGroupId: "semantic:fallback",
            bodyRef: "body:memory-2",
            sourceStoredSectionId: "stored:memory-2",
            memoryKind: "status_snapshot",
            freshness: { status: "aging" },
            confidence: "medium",
            alignment: { alignmentStatus: "unreviewed" },
            tags: ["fallback"],
          },
        ];
      },
    },
  };
  const facade = {
    mp: {
      create() {
        return session;
      },
      async bootstrap() {
        return { status: "bootstrapped" };
      },
      async routeForCore() {
        return {
          status: "routed",
          routeKind: "fallback",
          primaryRecords: [],
          supportingRecords: [],
          fallbackEntries: [],
          readback: {
            receiptId: "receipt-fallback",
            routeKind: "fallback",
            deliveryStatus: "absent",
            objectiveSummary: "继续 fallback",
            objectiveMatchSummary: "no native bundle",
            governanceReason: "native routing had no eligible memories after scope and freshness filtering",
            fallbackReason: "no native bundle",
            primaryMemoryRefs: [],
            supportingMemoryRefs: [],
            omittedMemoryRefs: [],
            candidateCount: 0,
          },
        };
      },
    },
  };

  const entries = await discoverMpOverlayEntries({
    cwd,
    userMessage: "继续 fallback",
    facade: facade as never,
  });

  assert.equal(entries[0]?.id, "memory:memory-2");
  assert.match(entries[0]?.summary ?? "", /status_snapshot \/ aging \/ unreviewed \/ medium/u);
});

test("discoverMpOverlayArtifacts returns an absent routed package when repo memory snapshot is empty", async () => {
  const cwd = mkdtempSync(path.join(tmpdir(), "praxis-mp-overlay-empty-"));
  const artifacts = await discoverMpOverlayArtifacts({
    cwd,
    userMessage: "继续空目录",
    facade: {
      mp: {
        create() {
          return { runtime: {} };
        },
        async bootstrap() {
          return { status: "bootstrapped" };
        },
        async routeForCore() {
          return {
            status: "routed",
            routeKind: "resolve",
            primaryRecords: [],
            supportingRecords: [],
            fallbackEntries: [],
            readback: {
              receiptId: "receipt-empty",
              routeKind: "resolve",
              deliveryStatus: "absent",
              objectiveSummary: "继续空目录",
              objectiveMatchSummary: "no native bundle",
              governanceReason: "native routing had no eligible memories after scope and freshness filtering",
              fallbackReason: "no native bundle and no fallback entries were available",
              primaryMemoryRefs: [],
              supportingMemoryRefs: [],
              omittedMemoryRefs: [],
              candidateCount: 0,
            },
          };
        },
      },
    } as never,
  });

  assert.deepEqual(artifacts.entries, []);
  assert.equal(artifacts.routedPackage.deliveryStatus, "absent");
  assert.equal(artifacts.routedPackage.schemaVersion, "core-mp-routed-package/v2");
  assert.match(artifacts.routedPackage.summary, /currently unavailable|fell back/i);
  assert.equal(artifacts.routedPackage.retrieval?.fallbackStage, "repo_memory_snapshot");
});

test("discoverMpOverlayArtifacts preserves memory-body refs without double prefix", async () => {
  const cwd = createMemoryRoot();
  const session = {
    runtime: {
      getMpManagedRecords() {
        return [];
      },
    },
  };
  const facade = {
    mp: {
      create() {
        return session;
      },
      async bootstrap() {
        return { status: "bootstrapped" };
      },
      async routeForCore() {
        return {
          status: "routed",
          routeKind: "resolve",
          primaryRecords: [
            {
              memoryId: "memory-3",
              semanticGroupId: "semantic:context",
              bodyRef: "memory-body:current-context.md",
              sourceStoredSectionId: "stored:memory-3",
              memoryKind: "summary",
              freshness: { status: "fresh" },
              confidence: "high",
              alignment: { alignmentStatus: "aligned" },
              tags: ["context"],
            },
          ],
          supportingRecords: [],
          fallbackEntries: [],
          readback: {
            receiptId: "receipt-bodyref",
            routeKind: "resolve",
            deliveryStatus: "available",
            objectiveSummary: "继续 bodyRef 对齐",
            objectiveMatchSummary: "matched context memory",
            governanceReason: "selected via MP resolve routing discipline",
            primaryMemoryRefs: ["memory-3"],
            supportingMemoryRefs: [],
            omittedMemoryRefs: [],
            candidateCount: 1,
          },
        };
      },
    },
  };

  const artifacts = await discoverMpOverlayArtifacts({
    cwd,
    userMessage: "继续 bodyRef 对齐",
    facade: facade as never,
  });

  assert.equal(artifacts.entries[0]?.bodyRef, "memory-body:current-context.md");
});

test("discoverMpOverlayArtifacts tries MP-native routing before declaring repo-memory empty", async () => {
  const cwd = mkdtempSync(path.join(tmpdir(), "praxis-mp-overlay-native-empty-"));
  const calls: string[] = [];
  const artifacts = await discoverMpOverlayArtifacts({
    cwd,
    userMessage: "继续 native memory",
    facade: {
      mp: {
        create() {
          calls.push("create");
          return { runtime: {} };
        },
        async bootstrap() {
          calls.push("bootstrap");
          return { status: "bootstrapped" };
        },
        async routeForCore() {
          calls.push("routeForCore");
          return {
            status: "routed",
            routeKind: "resolve",
            primaryRecords: [
              {
                memoryId: "memory-native-1",
                semanticGroupId: "semantic:native",
                bodyRef: "body:native-1",
                sourceStoredSectionId: "stored:native-1",
                memoryKind: "design_note",
                freshness: { status: "fresh" },
                confidence: "high",
                alignment: { alignmentStatus: "aligned" },
                tags: ["native"],
              },
            ],
            supportingRecords: [],
            fallbackEntries: [],
            readback: {
              receiptId: "receipt-native",
              routeKind: "resolve",
              deliveryStatus: "available",
              objectiveSummary: "继续 native memory",
              objectiveMatchSummary: "matched native memory",
              governanceReason: "selected via MP resolve routing discipline",
              primaryMemoryRefs: ["memory-native-1"],
              supportingMemoryRefs: [],
              omittedMemoryRefs: [],
              candidateCount: 1,
            },
          };
        },
      },
    } as never,
  });

  assert.deepEqual(calls, ["create", "bootstrap", "routeForCore"]);
  assert.equal(artifacts.entries[0]?.id, "memory:memory-native-1");
  assert.equal(artifacts.routedPackage.sourceClass, "mp_native_resolve");
});

test("discoverMpOverlayArtifacts materializes CMP candidates before native routing and marks cmp-seeded source", async () => {
  const cwd = createMemoryRoot();
  const calls: string[] = [];
  let receivedRouteInput: unknown;
  const artifacts = await discoverMpOverlayArtifacts({
    cwd,
    userMessage: "继续当前实现",
    currentObjective: "继续当前实现",
    cmpWorksitePackage: {
      schemaVersion: "core-cmp-worksite-package/v1",
      deliveryStatus: "available",
      identity: {
        sessionId: "session-1",
        agentId: "cmp-main",
        packageId: "cmp-pkg-1",
        packageRef: "cmp-package:1",
      },
      objective: {
        currentObjective: "继续当前实现",
        taskSummary: "推进当前 worksite",
        requestedAction: "聚焦当前主线",
      },
      payload: {
        sourceAnchorRefs: ["snapshot:1"],
        routeStateSummary: "core worksite return",
      },
      governance: {
        routeRationale: "core worksite return",
        scopePolicy: "project_shared",
        freshness: "fresh",
        confidenceLabel: "high",
      },
    },
    cmpCandidatePayloads: [{
      storedSection: {
        id: "stored-candidate-1",
        projectId: "project.mp-overlay.test",
        agentId: "main",
        sourceSectionId: "section-candidate-1",
        plane: "postgresql",
        storageRef: "postgresql:stored-candidate-1",
        state: "promoted",
        visibility: "parent",
        persistedAt: "2026-04-16T00:00:00.000Z",
        updatedAt: "2026-04-16T00:00:00.000Z",
      },
      checkedSnapshotRef: "snapshot:candidate-1",
      branchRef: "mp/main",
      scope: {
        projectId: "project.mp-overlay.test",
        agentId: "main",
        scopeLevel: "project",
        sessionMode: "shared",
        visibilityState: "project_shared",
        promotionState: "promoted_to_project",
        lineagePath: ["main"],
      },
      confidence: "high",
    }],
    facade: {
      mp: {
        create() {
          calls.push("create");
          return { runtime: {} };
        },
        async bootstrap() {
          calls.push("bootstrap");
          return { status: "bootstrapped" };
        },
        async materializeFromCmpCandidates(input: any) {
          calls.push("materializeFromCmpCandidates");
          assert.equal(input.payload.candidates.length, 1);
          return {
            status: "materialized_from_cmp_candidates",
            records: [],
            supersededMemoryIds: [],
            staleMemoryIds: [],
          };
        },
        async routeForCore(input: any) {
          calls.push("routeForCore");
          receivedRouteInput = input;
          return {
            status: "routed",
            routeKind: "resolve",
            primaryRecords: [
              {
                memoryId: "memory-cmp-1",
                semanticGroupId: "semantic:cmp",
                bodyRef: "body:cmp-1",
                sourceStoredSectionId: "stored:cmp-1",
                memoryKind: "summary",
                freshness: { status: "fresh" },
                confidence: "high",
                alignment: { alignmentStatus: "aligned" },
                tags: ["cmp"],
              },
            ],
            supportingRecords: [],
            fallbackEntries: [],
            readback: {
              receiptId: "receipt-cmp-seeded",
              routeKind: "resolve",
              deliveryStatus: "available",
              objectiveSummary: "继续当前实现",
              objectiveMatchSummary: "matched cmp-seeded memory",
              governanceReason: "governed by CMP route hint: core worksite return",
              primaryMemoryRefs: ["memory-cmp-1"],
              supportingMemoryRefs: [],
              omittedMemoryRefs: [],
              candidateCount: 1,
            },
          };
        },
      },
    } as never,
  });

  assert.deepEqual(calls, ["create", "bootstrap", "materializeFromCmpCandidates", "routeForCore"]);
  assert.equal(artifacts.routedPackage.sourceClass, "cmp_seeded_memory");
  assert.equal(artifacts.routedPackage.retrieval?.candidateIntakeCount, 1);
  assert.equal(artifacts.routedPackage.retrieval?.candidateRejectedCount, 0);
  assert.match(artifacts.routedPackage.retrieval?.candidateProvenanceSummary ?? "", /package:cmp-package:1/u);
  assert.match(artifacts.routedPackage.governance?.qualityGateSummary ?? "", /accepted 1 candidate/u);
  assert.equal(artifacts.routedPackage.retrieval?.fallbackSuppressed, true);
  assert.equal(artifacts.routedPackage.retrieval?.fallbackStage, "none");
  assert.equal((receivedRouteInput as { payload: { currentObjective?: string } }).payload.currentObjective, "继续当前实现");
  assert.match(
    (receivedRouteInput as { payload: { queryText: string } }).payload.queryText,
    /推进当前 worksite/u,
  );
  assert.deepEqual(
    (receivedRouteInput as { payload: { fallbackEntries?: unknown[] } }).payload.fallbackEntries,
    [],
  );
});

test("normalizeCmpCandidateExportInput accepts only package-grade CMP candidates", () => {
  const normalized = normalizeCmpCandidateExportInput({
    schemaVersion: "cmp-mp-candidate-export/v1",
    sessionId: "session-1",
    agentId: "cmp-main",
    packageRef: "cmp-package:1",
    packageFamilyId: "family-1",
    snapshotId: "snapshot-1",
    routeRationale: "core worksite return",
    scopePolicy: "project_shared",
    candidates: [
      {
        storedSection: { id: "stored-1", storageRef: "postgresql:stored-1" },
        checkedSnapshotRef: "snapshot-1",
        branchRef: "mp/main",
        scope: {
          projectId: "proj-1",
          agentId: "main",
          scopeLevel: "project",
          sessionMode: "shared",
        },
        confidence: "high",
      },
      {
        storedSection: { id: "stored-missing-snapshot", storageRef: "postgresql:stored-missing-snapshot" },
        branchRef: "mp/main",
        scope: {
          projectId: "proj-1",
          agentId: "main",
          scopeLevel: "project",
          sessionMode: "shared",
        },
      },
      {
        storedSection: { id: "stored-1", storageRef: "postgresql:stored-1" },
        checkedSnapshotRef: "snapshot-1",
        branchRef: "mp/main",
        scope: {
          projectId: "proj-1",
          agentId: "main",
          scopeLevel: "project",
          sessionMode: "shared",
        },
      },
      "bad-candidate",
    ],
  });

  assert.equal(normalized.acceptedCount, 1);
  assert.equal(normalized.rejectedCount, 3);
  assert.equal(normalized.candidates[0]?.checkedSnapshotRef, "snapshot-1");
  assert.equal(normalized.provenance.packageRef, "cmp-package:1");
  assert.equal(normalized.rejectedByReason.missing_required_fields, 1);
  assert.equal(normalized.rejectedByReason.duplicate_candidate, 1);
  assert.equal(normalized.rejectedByReason.invalid_candidate_shape, 1);
});

test("discoverMpOverlayArtifacts filters invalid CMP candidates and keeps intake diagnostics", async () => {
  const cwd = createMemoryRoot();
  const calls: string[] = [];
  const artifacts = await discoverMpOverlayArtifacts({
    cwd,
    userMessage: "继续 payment refactor",
    currentObjective: "继续 payment refactor",
    cmpCandidatePayloads: {
      schemaVersion: "cmp-mp-candidate-export/v1",
      packageRef: "cmp-package:quality",
      snapshotId: "snapshot-quality",
      candidates: [
        {
          storedSection: { id: "stored-valid", storageRef: "postgresql:stored-valid" },
          checkedSnapshotRef: "snapshot-valid",
          branchRef: "mp/main",
          scope: {
            projectId: "proj-1",
            agentId: "main",
            scopeLevel: "project",
            sessionMode: "shared",
          },
        },
        {
          storedSection: { id: "stored-invalid", storageRef: "postgresql:stored-invalid" },
          branchRef: "mp/main",
          scope: {
            projectId: "proj-1",
            agentId: "main",
            scopeLevel: "project",
            sessionMode: "shared",
          },
        },
        {
          storedSection: { id: "stored-valid", storageRef: "postgresql:stored-valid" },
          checkedSnapshotRef: "snapshot-valid",
          branchRef: "mp/main",
          scope: {
            projectId: "proj-1",
            agentId: "main",
            scopeLevel: "project",
            sessionMode: "shared",
          },
        },
      ],
    },
    facade: {
      mp: {
        create() {
          calls.push("create");
          return { runtime: { getMpManagedRecords() { return []; } } };
        },
        async bootstrap() {
          calls.push("bootstrap");
          return { status: "bootstrapped" };
        },
        async materializeFromCmpCandidates(input: any) {
          calls.push("materializeFromCmpCandidates");
          assert.equal(input.payload.candidates.length, 1);
          assert.equal(input.payload.candidates[0]?.checkedSnapshotRef, "snapshot-valid");
          return {
            status: "materialized_from_cmp_candidates",
            records: [],
            supersededMemoryIds: [],
            staleMemoryIds: [],
            summary: undefined,
          };
        },
        async routeForCore() {
          calls.push("routeForCore");
          return {
            status: "routed",
            routeKind: "resolve",
            primaryRecords: [
              {
                memoryId: "memory-valid",
                semanticGroupId: "payment-refactor",
                bodyRef: "payment-refactor",
                sourceStoredSectionId: "stored-valid",
                memoryKind: "summary",
                freshness: { status: "fresh" },
                confidence: "high",
                alignment: { alignmentStatus: "aligned" },
                tags: ["payment"],
              },
            ],
            supportingRecords: [],
            fallbackEntries: [],
            readback: {
              receiptId: "receipt-valid",
              routeKind: "resolve",
              deliveryStatus: "available",
              objectiveSummary: "继续 payment refactor",
              objectiveMatchSummary: "matched payment memory",
              governanceReason: "selected via MP resolve routing discipline",
              primaryMemoryRefs: ["memory-valid"],
              supportingMemoryRefs: [],
              omittedMemoryRefs: [],
              candidateCount: 1,
            },
          };
        },
      },
    } as never,
  });

  assert.deepEqual(calls, ["create", "bootstrap", "materializeFromCmpCandidates", "routeForCore"]);
  assert.equal(artifacts.routedPackage.retrieval?.candidateIntakeCount, 1);
  assert.equal(artifacts.routedPackage.retrieval?.candidateRejectedCount, 2);
  assert.match(artifacts.routedPackage.retrieval?.candidateRejectionSummary ?? "", /missing_required_fields:1/u);
  assert.match(artifacts.routedPackage.retrieval?.candidateRejectionSummary ?? "", /duplicate_candidate:1/u);
  assert.match(artifacts.routedPackage.retrieval?.candidateProvenanceSummary ?? "", /package:cmp-package:quality/u);
  assert.equal(artifacts.routedPackage.retrieval?.fallbackStage, "none");
});

test("discoverMpOverlayArtifacts suppresses repo fallback during CMP-seeded route and only re-enables it as a last resort", async () => {
  const cwd = createMemoryRoot();
  let receivedFallbackEntries: unknown[] | undefined;
  const artifacts = await discoverMpOverlayArtifacts({
    cwd,
    userMessage: "继续 last resort fallback",
    currentObjective: "继续 last resort fallback",
    cmpCandidatePayloads: {
      schemaVersion: "cmp-mp-candidate-export/v1",
      packageRef: "cmp-package:fallback",
      candidates: [{
        storedSection: { id: "stored-fallback", storageRef: "postgresql:stored-fallback" },
        checkedSnapshotRef: "snapshot-fallback",
        branchRef: "mp/main",
        scope: {
          projectId: "proj-1",
          agentId: "main",
          scopeLevel: "project",
          sessionMode: "shared",
        },
      }],
    },
    facade: {
      mp: {
        create() {
          return {
            runtime: {
              getMpManagedRecords() {
                return [];
              },
            },
          };
        },
        async bootstrap() {
          return { status: "bootstrapped" };
        },
        async materializeFromCmpCandidates() {
          return {
            status: "materialized_from_cmp_candidates",
            records: [],
            supersededMemoryIds: [],
            staleMemoryIds: [],
          };
        },
        async routeForCore(input: any) {
          receivedFallbackEntries = input.payload.fallbackEntries;
          return {
            status: "routed",
            routeKind: "resolve",
            primaryRecords: [],
            supportingRecords: [],
            fallbackEntries: [],
            readback: {
              receiptId: "receipt-no-bundle",
              routeKind: "resolve",
              deliveryStatus: "absent",
              objectiveSummary: "继续 last resort fallback",
              objectiveMatchSummary: "no native bundle after cmp intake",
              governanceReason: "native route had no eligible bundle",
              fallbackReason: "no native bundle",
              primaryMemoryRefs: [],
              supportingMemoryRefs: [],
              omittedMemoryRefs: [],
              candidateCount: 0,
            },
          };
        },
      },
    } as never,
  });

  assert.deepEqual(receivedFallbackEntries, []);
  assert.equal(artifacts.routedPackage.sourceClass, "repo_memory_fallback");
  assert.equal(artifacts.routedPackage.retrieval?.fallbackSuppressed, true);
  assert.equal(artifacts.routedPackage.retrieval?.fallbackStage, "repo_memory_snapshot");
  assert.match(artifacts.routedPackage.governance?.governanceReason ?? "", /re-enabled as a last resort/u);
});
