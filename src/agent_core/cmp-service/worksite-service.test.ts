import assert from "node:assert/strict";
import test from "node:test";

import { createAgentLineage, createCmpBranchFamily } from "../index.js";
import { createAgentCoreRuntime } from "../runtime.js";

function seedCheckedSnapshot(input: {
  runtime: ReturnType<typeof createAgentCoreRuntime>;
  projectId: string;
  sessionId: string;
  agentId: string;
  materialRef: string;
}) {
  const ingest = input.runtime.ingestRuntimeContext({
    agentId: input.agentId,
    sessionId: input.sessionId,
    taskSummary: `seed cmp worksite snapshot for ${input.sessionId}`,
    materials: [{ kind: "user_input", ref: input.materialRef }],
    lineage: createAgentLineage({
      agentId: input.agentId,
      depth: 0,
      projectId: input.projectId,
      branchFamily: createCmpBranchFamily({
        workBranch: `work/${input.agentId}`,
        cmpBranch: `cmp/${input.agentId}`,
        mpBranch: `mp/${input.agentId}`,
        tapBranch: `tap/${input.agentId}`,
      }),
    }),
  });
  input.runtime.commitContextDelta({
    agentId: input.agentId,
    sessionId: input.sessionId,
    eventIds: ingest.acceptedEventIds,
    changeSummary: `commit cmp worksite snapshot for ${input.sessionId}`,
    syncIntent: "local_record",
  });
  const snapshot = input.runtime.listCmpCheckedSnapshots()
    .filter((record) => record.agentId === input.agentId)
    .at(-1);
  assert.ok(snapshot, `expected checked snapshot for ${input.agentId}`);
  return snapshot;
}

test("CMP worksite observeTurn exports a core worksite package and tap aperture", () => {
  const runtime = createAgentCoreRuntime();

  const observed = runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-1",
    turnIndex: 3,
    currentObjective: "继续修复 worksite contract",
    observedAt: "2026-04-16T10:00:00.000Z",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-main",
      packageId: "pkg-worksite-1",
      packageRef: "cmp-package:worksite-1",
      packageKind: "active_reseed",
      packageMode: "core_return",
      fidelityLabel: "checked_high_fidelity",
      projectionId: "projection-worksite-1",
      snapshotId: "snapshot-worksite-1",
      intent: "keep current project worksite aligned",
      operatorGuide: "focus on the checked project worksite only",
      childGuide: "child work should enter child icma only",
      checkerReason: "checked package is usable",
      routeRationale: "core return keeps the current worksite stable",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary_package_plus_timeline",
      timelineStrategy: "timeline package retained for continuity",
    },
  });

  assert.equal(observed.deliveryStatus, "available");
  assert.equal(observed.activeTurnIndex, 3);

  const worksite = runtime.cmp.worksite.exportCorePackage({
    sessionId: "session-worksite-1",
    currentObjective: "现在先看当前 project worksite",
  });

  assert.equal(worksite.schemaVersion, "core-cmp-worksite-package/v1");
  assert.equal(worksite.deliveryStatus, "available");
  assert.equal(worksite.identity?.sessionId, "session-worksite-1");
  assert.equal(worksite.identity?.agentId, "cmp-live-cli-main");
  assert.equal(worksite.identity?.packageRef, "cmp-package:worksite-1");
  assert.equal(worksite.objective?.currentObjective, "现在先看当前 project worksite");
  assert.equal(worksite.objective?.taskSummary, "keep current project worksite aligned");
  assert.equal(worksite.objective?.activeTurnIndex, 3);
  assert.match(worksite.payload?.primaryContext ?? "", /latest package|active package family/);
  assert.equal(worksite.governance?.recoveryStatus, "degraded");

  const aperture = runtime.cmp.worksite.exportTapPackage({
    sessionId: "session-worksite-1",
    currentObjective: "审核当前 capability request",
    requestedCapabilityKey: "code.grep",
  });

  assert.equal(aperture?.schemaVersion, "cmp-tap-review-aperture/v1");
  assert.equal(aperture?.requestedCapabilityKey, "code.grep");
  assert.equal(aperture?.currentObjective, "审核当前 capability request");
  assert.equal(aperture?.packageRef, "cmp-package:worksite-1");
  assert.equal(aperture?.routeStateSummary, undefined);
});

test("CMP worksite clearSession removes the current worksite record", () => {
  const runtime = createAgentCoreRuntime();

  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-clear",
    turnIndex: 1,
    currentObjective: "做一轮 worksite 清理测试",
    cmp: {
      syncStatus: "failed",
      agentId: "cmp-live-cli-main",
      packageId: "pending",
      packageRef: "pending",
      projectionId: "pending",
      snapshotId: "pending",
      intent: "failed cmp sync",
      operatorGuide: "fall back to verified user objective",
      childGuide: "pending",
      checkerReason: "pending",
      routeRationale: "pending",
      scopePolicy: "pending",
      packageStrategy: "pending",
      timelineStrategy: "pending",
    },
  });

  assert.equal(runtime.cmp.worksite.getCurrent({
    sessionId: "session-worksite-clear",
  })?.deliveryStatus, "partial");

  runtime.cmp.worksite.clearSession({
    sessionId: "session-worksite-clear",
  });

  assert.equal(runtime.cmp.worksite.getCurrent({
    sessionId: "session-worksite-clear",
  }), undefined);
  assert.equal(runtime.cmp.worksite.exportCorePackage({
    sessionId: "session-worksite-clear",
    currentObjective: "重新开始",
  }).deliveryStatus, "absent");
});

test("CMP worksite snapshot survives runtime snapshot and recovery", () => {
  const runtime = createAgentCoreRuntime();

  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-recover",
    turnIndex: 2,
    currentObjective: "恢复后继续当前 worksite",
    observedAt: "2026-04-16T12:00:00.000Z",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-recover",
      packageId: "pkg-worksite-recover",
      packageRef: "cmp-package:recover-1",
      packageKind: "active_reseed",
      packageMode: "core_return",
      fidelityLabel: "checked_high_fidelity",
      projectionId: "projection-worksite-recover",
      snapshotId: "snapshot-worksite-recover",
      intent: "continue from recovered worksite",
      operatorGuide: "resume from the recovered worksite package",
      childGuide: "keep child work routed separately",
      checkerReason: "recovered package still valid",
      routeRationale: "current worksite remains valid after recovery",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary_package_plus_timeline",
      timelineStrategy: "timeline stays attached to the recovered worksite",
    },
  });

  const snapshot = runtime.createCmpRuntimeSnapshot();
  const recoveredRuntime = createAgentCoreRuntime();
  recoveredRuntime.recoverCmpRuntimeSnapshot(snapshot);

  const recovered = recoveredRuntime.cmp.worksite.exportCorePackage({
    sessionId: "session-worksite-recover",
    currentObjective: "恢复后继续当前 worksite",
  });

  assert.equal(recovered.deliveryStatus, "available");
  assert.equal(recovered.identity?.packageRef, "cmp-package:recover-1");
  assert.equal(recovered.objective?.taskSummary, "continue from recovered worksite");
  assert.equal(recovered.governance?.checkerReason, "recovered package still valid");
});

test("CMP worksite exportMpCandidates returns governed CMP candidates for MP intake", () => {
  const runtime = createAgentCoreRuntime();
  const snapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-mp-candidates",
    sessionId: "session-worksite-mp-candidates",
    agentId: "cmp-live-cli-session-mp-candidates",
    materialRef: "turn:mp-candidates:user",
  });

  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-mp-candidates",
    turnIndex: 4,
    currentObjective: "把当前 governed worksite 导出给 MP",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-mp-candidates",
      packageId: "pkg-worksite-mp-candidates",
      packageRef: "cmp-package:worksite-mp-candidates",
      packageKind: "active_reseed",
      packageMode: "core_return",
      fidelityLabel: "checked_high_fidelity",
      projectionId: "projection-worksite-mp-candidates",
      snapshotId: snapshot.snapshotId,
      intent: "export governed worksite material as MP candidates",
      operatorGuide: "keep the current worksite stable while exporting only high-signal candidates",
      childGuide: "child work stays separate",
      checkerReason: "checked package remains usable",
      routeRationale: "current worksite should seed downstream memory routing",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary_package_plus_timeline",
      timelineStrategy: "timeline retained for continuity",
    },
  });

  const exported = runtime.cmp.worksite.exportMpCandidates({
    sessionId: "session-worksite-mp-candidates",
    currentObjective: "把当前 governed worksite 导出给 MP",
    limit: 4,
  });

  assert.equal(exported.schemaVersion, "cmp-mp-candidate-export/v1");
  assert.equal(exported.packageRef, "cmp-package:worksite-mp-candidates");
  assert.equal(exported.snapshotId, snapshot.snapshotId);
  assert.ok(exported.candidates.length >= 1);
  assert.match(exported.candidateExportSummary ?? "", /policy=checked_governed_package_grade/u);
  assert.match(exported.packageFamilySummary ?? "", /primary|family/u);
  assert.equal(exported.candidates[0]?.checkedSnapshotRef, snapshot.snapshotId);
  assert.equal(exported.candidates[0]?.branchRef, snapshot.branchRef);
  assert.equal(exported.candidates[0]?.scope.scopeLevel, "agent_isolated");
  assert.equal(exported.candidates[0]?.scope.sessionMode, "bridged");
  assert.equal(exported.candidates[0]?.confidence, "high");
  assert.equal(
    (exported.candidates[0]?.metadata as { cmpPackageRef?: string } | undefined)?.cmpPackageRef,
    "cmp-package:worksite-mp-candidates",
  );
});

test("CMP worksite exportMpCandidates survives runtime snapshot and recovery", () => {
  const runtime = createAgentCoreRuntime();
  const snapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-mp-recover",
    sessionId: "session-worksite-mp-recover",
    agentId: "cmp-live-cli-session-mp-recover",
    materialRef: "turn:mp-recover:user",
  });

  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-mp-recover",
    turnIndex: 5,
    currentObjective: "恢复后继续导出 cmp governed candidates",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-mp-recover",
      packageId: "pkg-worksite-mp-recover",
      packageRef: "cmp-package:worksite-mp-recover",
      projectionId: "projection-worksite-mp-recover",
      snapshotId: snapshot.snapshotId,
      intent: "resume governed candidate export after recovery",
      operatorGuide: "continue from the recovered worksite only",
      childGuide: "keep child work separate",
      checkerReason: "recovered package still usable",
      routeRationale: "recovery should not lose worksite candidate export",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary_package_plus_timeline",
      timelineStrategy: "timeline survives recovery",
    },
  });

  const snapshotBeforeRecovery = runtime.createCmpRuntimeSnapshot();
  const recoveredRuntime = createAgentCoreRuntime();
  recoveredRuntime.recoverCmpRuntimeSnapshot(snapshotBeforeRecovery);

  const exported = recoveredRuntime.cmp.worksite.exportMpCandidates({
    sessionId: "session-worksite-mp-recover",
    currentObjective: "恢复后继续导出 cmp governed candidates",
  });

  assert.equal(exported.snapshotId, snapshot.snapshotId);
  assert.ok(exported.candidates.length >= 1);
  assert.equal(exported.candidates[0]?.checkedSnapshotRef, snapshot.snapshotId);
  assert.equal(exported.candidates[0]?.scope.sessionId, "session-worksite-mp-recover");
});

test("CMP worksite exportMpCandidates follows the latest turn inside one session", () => {
  const runtime = createAgentCoreRuntime();
  const firstSnapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-mp-latest",
    sessionId: "session-worksite-mp-latest",
    agentId: "cmp-live-cli-session-mp-latest",
    materialRef: "turn:mp-latest:1:user",
  });
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-mp-latest",
    turnIndex: 1,
    currentObjective: "第一轮 objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-mp-latest",
      packageId: "pkg-worksite-mp-latest-1",
      packageRef: "cmp-package:worksite-mp-latest-1",
      projectionId: "projection-worksite-mp-latest-1",
      snapshotId: firstSnapshot.snapshotId,
      intent: "first worksite package",
      operatorGuide: "follow first package",
      childGuide: "keep child work separate",
      checkerReason: "first package usable",
      routeRationale: "first route",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-1",
    },
  });

  const secondSnapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-mp-latest",
    sessionId: "session-worksite-mp-latest",
    agentId: "cmp-live-cli-session-mp-latest",
    materialRef: "turn:mp-latest:2:user",
  });
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-mp-latest",
    turnIndex: 2,
    currentObjective: "第二轮 objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-mp-latest",
      packageId: "pkg-worksite-mp-latest-2",
      packageRef: "cmp-package:worksite-mp-latest-2",
      projectionId: "projection-worksite-mp-latest-2",
      snapshotId: secondSnapshot.snapshotId,
      intent: "second worksite package",
      operatorGuide: "follow second package",
      childGuide: "keep child work separate",
      checkerReason: "second package usable",
      routeRationale: "second route",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-2",
    },
  });

  const exported = runtime.cmp.worksite.exportMpCandidates({
    sessionId: "session-worksite-mp-latest",
    currentObjective: "第二轮 objective",
  });

  assert.equal(exported.packageRef, "cmp-package:worksite-mp-latest-2");
  assert.equal(exported.snapshotId, secondSnapshot.snapshotId);
  assert.notEqual(exported.snapshotId, firstSnapshot.snapshotId);
  assert.equal(exported.currentObjective, "第二轮 objective");
});

test("CMP worksite keeps core tap and mp exports aligned after recovery in a multi-turn chain", () => {
  const runtime = createAgentCoreRuntime();
  const firstSnapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-aligned-recovery",
    sessionId: "session-worksite-aligned-recovery",
    agentId: "cmp-live-cli-session-aligned-recovery",
    materialRef: "turn:aligned-recovery:1:user",
  });
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-aligned-recovery",
    turnIndex: 1,
    currentObjective: "第一轮 worksite objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-aligned-recovery",
      packageId: "pkg-aligned-recovery-1",
      packageRef: "cmp-package:aligned-recovery-1",
      projectionId: "projection-aligned-recovery-1",
      snapshotId: firstSnapshot.snapshotId,
      intent: "first aligned worksite package",
      operatorGuide: "follow first aligned package",
      childGuide: "keep child work separate",
      checkerReason: "first aligned checker",
      routeRationale: "first aligned route",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-1",
    },
  });

  const secondSnapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-aligned-recovery",
    sessionId: "session-worksite-aligned-recovery",
    agentId: "cmp-live-cli-session-aligned-recovery",
    materialRef: "turn:aligned-recovery:2:user",
  });
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-aligned-recovery",
    turnIndex: 2,
    currentObjective: "第二轮 worksite objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-aligned-recovery",
      packageId: "pkg-aligned-recovery-2",
      packageRef: "cmp-package:aligned-recovery-2",
      projectionId: "projection-aligned-recovery-2",
      snapshotId: secondSnapshot.snapshotId,
      intent: "second aligned worksite package",
      operatorGuide: "follow second aligned package",
      childGuide: "keep child work separate",
      checkerReason: "second aligned checker",
      routeRationale: "second aligned route",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-2",
    },
  });

  const recoveredRuntime = createAgentCoreRuntime();
  recoveredRuntime.recoverCmpRuntimeSnapshot(runtime.createCmpRuntimeSnapshot());

  const worksite = recoveredRuntime.cmp.worksite.exportCorePackage({
    sessionId: "session-worksite-aligned-recovery",
  });
  const aperture = recoveredRuntime.cmp.worksite.exportTapPackage({
    sessionId: "session-worksite-aligned-recovery",
    requestedCapabilityKey: "repo.write",
  });
  const candidates = recoveredRuntime.cmp.worksite.exportMpCandidates({
    sessionId: "session-worksite-aligned-recovery",
  });

  assert.equal(worksite.identity?.packageRef, "cmp-package:aligned-recovery-2");
  assert.equal(aperture?.packageRef, "cmp-package:aligned-recovery-2");
  assert.equal(candidates.packageRef, "cmp-package:aligned-recovery-2");
  assert.equal(worksite.identity?.snapshotId, secondSnapshot.snapshotId);
  assert.equal(aperture?.snapshotId, secondSnapshot.snapshotId);
  assert.equal(candidates.snapshotId, secondSnapshot.snapshotId);
  assert.equal(worksite.objective?.currentObjective, "第二轮 worksite objective");
  assert.equal(candidates.currentObjective, "第二轮 worksite objective");
  assert.match(worksite.payload?.activeLineSummary ?? "", /package|route|family|mode/u);
  assert.match(worksite.payload?.timelineSummary ?? "", /timeline|task snapshots/u);
  assert.match(candidates.candidateExportSummary ?? "", /exportable=/u);
});

test("CMP worksite exportMpCandidates stays isolated across sessions", () => {
  const runtime = createAgentCoreRuntime();
  const sessionASnapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-mp-isolation",
    sessionId: "session-worksite-mp-isolation-a",
    agentId: "cmp-live-cli-session-mp-isolation-a",
    materialRef: "turn:mp-isolation:a:user",
  });
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-mp-isolation-a",
    turnIndex: 1,
    currentObjective: "session a objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-mp-isolation-a",
      packageId: "pkg-worksite-mp-isolation-a",
      packageRef: "cmp-package:worksite-mp-isolation-a",
      projectionId: "projection-worksite-mp-isolation-a",
      snapshotId: sessionASnapshot.snapshotId,
      intent: "session a package",
      operatorGuide: "follow session a package",
      childGuide: "keep child work separate",
      checkerReason: "session a checker",
      routeRationale: "session a route",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-a",
    },
  });

  const sessionBSnapshot = seedCheckedSnapshot({
    runtime,
    projectId: "proj-worksite-mp-isolation",
    sessionId: "session-worksite-mp-isolation-b",
    agentId: "cmp-live-cli-session-mp-isolation-b",
    materialRef: "turn:mp-isolation:b:user",
  });
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-worksite-mp-isolation-b",
    turnIndex: 1,
    currentObjective: "session b objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-session-mp-isolation-b",
      packageId: "pkg-worksite-mp-isolation-b",
      packageRef: "cmp-package:worksite-mp-isolation-b",
      projectionId: "projection-worksite-mp-isolation-b",
      snapshotId: sessionBSnapshot.snapshotId,
      intent: "session b package",
      operatorGuide: "follow session b package",
      childGuide: "keep child work separate",
      checkerReason: "session b checker",
      routeRationale: "session b route",
      scopePolicy: "current_worksite_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-b",
    },
  });

  const sessionAExport = runtime.cmp.worksite.exportMpCandidates({
    sessionId: "session-worksite-mp-isolation-a",
    currentObjective: "session a objective",
  });
  const sessionBExport = runtime.cmp.worksite.exportMpCandidates({
    sessionId: "session-worksite-mp-isolation-b",
    currentObjective: "session b objective",
  });

  assert.equal(sessionAExport.packageRef, "cmp-package:worksite-mp-isolation-a");
  assert.equal(sessionAExport.snapshotId, sessionASnapshot.snapshotId);
  assert.equal(sessionBExport.packageRef, "cmp-package:worksite-mp-isolation-b");
  assert.equal(sessionBExport.snapshotId, sessionBSnapshot.snapshotId);
  assert.notEqual(sessionAExport.snapshotId, sessionBExport.snapshotId);
  assert.notEqual(
    sessionAExport.candidates[0]?.storedSection.id,
    sessionBExport.candidates[0]?.storedSection.id,
  );
});

test("CMP worksite export does not drift when two sessions previously shared one live cmp agent id", () => {
  const runtime = createAgentCoreRuntime();
  const originalGetSummary = runtime.getCmpFiveAgentRuntimeSummary.bind(runtime);
  const originalGetSnapshot = runtime.getCmpFiveAgentRuntimeSnapshot.bind(runtime);
  let phase: "session-a" | "session-b" | "drifted" = "session-a";

  (runtime as unknown as {
    getCmpFiveAgentRuntimeSummary: typeof runtime.getCmpFiveAgentRuntimeSummary;
    getCmpFiveAgentRuntimeSnapshot: typeof runtime.getCmpFiveAgentRuntimeSnapshot;
  }).getCmpFiveAgentRuntimeSummary = ((agentId?: string) => {
    if (agentId !== "cmp-live-cli-main") {
      return originalGetSummary(agentId);
    }
    const summary = originalGetSummary(agentId);
    return {
      ...summary,
      latestRoleMetadata: {
        ...summary.latestRoleMetadata,
        dispatcher: {
          ...summary.latestRoleMetadata.dispatcher,
          bundle: {
            sourceAnchorRefs: phase === "session-a"
              ? ["turn:a:user"]
              : phase === "session-b"
                ? ["turn:b:user"]
                : ["turn:drifted:user"],
          },
        },
      },
      parentPromoteReviewCount: phase === "session-a" ? 1 : phase === "session-b" ? 2 : 9,
      flow: {
        ...summary.flow,
        pendingPeerApprovalCount: phase === "session-a" ? 1 : phase === "session-b" ? 2 : 9,
      },
    };
  }) as typeof runtime.getCmpFiveAgentRuntimeSummary;
  (runtime as unknown as {
    getCmpFiveAgentRuntimeSummary: typeof runtime.getCmpFiveAgentRuntimeSummary;
    getCmpFiveAgentRuntimeSnapshot: typeof runtime.getCmpFiveAgentRuntimeSnapshot;
  }).getCmpFiveAgentRuntimeSnapshot = ((agentId?: string) => {
    if (agentId !== "cmp-live-cli-main") {
      return originalGetSnapshot(agentId);
    }
    const snapshot = originalGetSnapshot(agentId);
    return {
      ...snapshot,
      packageFamilies: [{
        familyId: phase === "session-a" ? "family-a" : phase === "session-b" ? "family-b" : "family-drifted",
        primaryPackageId: phase === "session-a" ? "pkg-a" : phase === "session-b" ? "pkg-b" : "pkg-drifted",
        primaryPackageRef: phase === "session-a" ? "cmp-package:a" : phase === "session-b" ? "cmp-package:b" : "cmp-package:drifted",
        candidatePackageIds: [],
        createdAt: "2026-04-16T12:00:00.000Z",
        updatedAt: "2026-04-16T12:00:00.000Z",
        metadata: {},
      }],
    };
  }) as typeof runtime.getCmpFiveAgentRuntimeSnapshot;

  runtime.cmp.worksite.observeTurn({
    sessionId: "session-a",
    turnIndex: 1,
    currentObjective: "session a objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-main",
      packageId: "pkg-a",
      packageRef: "cmp-package:a",
      projectionId: "projection-a",
      snapshotId: "snapshot-a",
      intent: "session a intent",
      operatorGuide: "session a guide",
      childGuide: "session a child guide",
      checkerReason: "session a checker",
      routeRationale: "session a route",
      scopePolicy: "session_a_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-a",
    },
  });

  phase = "session-b";
  runtime.cmp.worksite.observeTurn({
    sessionId: "session-b",
    turnIndex: 1,
    currentObjective: "session b objective",
    cmp: {
      syncStatus: "synced",
      agentId: "cmp-live-cli-main",
      packageId: "pkg-b",
      packageRef: "cmp-package:b",
      projectionId: "projection-b",
      snapshotId: "snapshot-b",
      intent: "session b intent",
      operatorGuide: "session b guide",
      childGuide: "session b child guide",
      checkerReason: "session b checker",
      routeRationale: "session b route",
      scopePolicy: "session_b_only",
      packageStrategy: "primary",
      timelineStrategy: "timeline-b",
    },
  });

  phase = "drifted";
  const sessionA = runtime.cmp.worksite.exportCorePackage({
    sessionId: "session-a",
  });
  const sessionB = runtime.cmp.worksite.exportCorePackage({
    sessionId: "session-b",
  });

  assert.equal(sessionA.identity?.packageFamilyId, "family-a");
  assert.deepEqual(sessionA.payload?.sourceAnchorRefs, ["turn:a:user"]);
  assert.equal(sessionA.flow?.pendingPeerApprovalCount, 1);
  assert.equal(sessionB.identity?.packageFamilyId, "family-b");
  assert.deepEqual(sessionB.payload?.sourceAnchorRefs, ["turn:b:user"]);
  assert.equal(sessionB.flow?.pendingPeerApprovalCount, 2);
});
