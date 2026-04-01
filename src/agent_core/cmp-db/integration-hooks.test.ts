import assert from "node:assert/strict";
import test from "node:test";

import {
  createAgentLineage,
  createCheckedSnapshot,
  createCmpBranchFamily,
  createContextPackage,
  createDispatchReceipt,
} from "../cmp-types/index.js";
import {
  createCmpGitPromotionPullRequest,
  createCmpGitBranchFamily,
  createCmpGitLineageNode,
  createCmpGitSnapshotCandidateFromBinding,
  createCmpGitCommitDeltaBinding,
  mergeCmpGitPromotionPullRequest,
  promoteCmpGitMerge,
  CmpGitLineageRegistry,
} from "../cmp-git/index.js";
import {
  createCmpContextPackageRecord,
} from "../cmp-runtime/index.js";
import { createCmpDbAgentRuntimeSyncState } from "./dbagent-sync.js";
import {
  syncCmpDbDeliveryPipeline,
  syncCmpDbProjectionFromGitPromotion,
} from "./integration-hooks.js";

test("part3 e2e hook can project a child checked snapshot into a parent-promoted DB projection", () => {
  const registry = new CmpGitLineageRegistry();
  registry.register({
    projectId: "cmp-e2e-project",
    agentId: "parent",
    depth: 0,
  });
  registry.register({
    projectId: "cmp-e2e-project",
    agentId: "child",
    parentAgentId: "parent",
    depth: 1,
  });

  const binding = createCmpGitCommitDeltaBinding({
    projectId: "cmp-e2e-project",
    agentId: "child",
    branchRef: createCmpGitBranchFamily("child").cmp,
    commitSha: "cmpcommit1",
    delta: {
      deltaId: "delta-1",
      agentId: "child",
    },
    syncIntent: "submit_to_parent",
  });
  const candidate = createCmpGitSnapshotCandidateFromBinding(binding);
  const pullRequest = createCmpGitPromotionPullRequest({
    registry,
    candidate,
    targetAgentId: "parent",
  });
  const merge = mergeCmpGitPromotionPullRequest({
    pullRequest,
    candidate,
    actorAgentId: "parent",
  });
  const promotion = promoteCmpGitMerge({
    merge,
    candidate,
    promoterAgentId: "parent",
  });

  const state = createCmpDbAgentRuntimeSyncState();
  const snapshot = createCheckedSnapshot({
    snapshotId: "snapshot-child-1",
    agentId: "child",
    lineageRef: "cmp-e2e-project:child",
    branchRef: "cmp/child",
    commitRef: "cmpcommit1",
    checkedAt: "2026-03-24T12:00:00.000Z",
    metadata: {
      projectId: "cmp-e2e-project",
    },
  });
  const projected = syncCmpDbProjectionFromGitPromotion({
    state,
    snapshot,
    promotion,
  });

  assert.equal(projected.state, "promoted_by_parent");
  assert.equal(state.projections.get(projected.projectionId)?.state, "promoted_by_parent");
});

test("part3 e2e hook can sync package and delivery without exposing raw history", () => {
  const state = createCmpDbAgentRuntimeSyncState();
  const projection = syncCmpDbProjectionFromGitPromotion({
    state,
    snapshot: createCheckedSnapshot({
      snapshotId: "snapshot-parent-1",
      agentId: "parent",
      lineageRef: "cmp-e2e-project:parent",
      branchRef: "cmp/parent",
      commitRef: "cmpcommit2",
      checkedAt: "2026-03-24T12:10:00.000Z",
      metadata: {
        projectId: "cmp-e2e-project",
      },
    }),
  });
  const contextPackage = createContextPackage({
    packageId: "package-child-seed",
    sourceProjectionId: projection.projectionId,
    targetAgentId: "child-a",
    packageKind: "child_seed",
    packageRef: "cmp-package:child-seed",
    fidelityLabel: "checked_high_fidelity",
    createdAt: "2026-03-24T12:11:00.000Z",
  });
  const receipt = createDispatchReceipt({
    dispatchId: "dispatch-child-seed",
    packageId: "package-child-seed",
    sourceAgentId: "parent",
    targetAgentId: "child-a",
    status: "delivered",
    deliveredAt: "2026-03-24T12:12:00.000Z",
  });

  const synced = syncCmpDbDeliveryPipeline({
    state,
    contextPackage,
    projection: {
      projectionId: projection.projectionId,
      snapshotId: projection.snapshotId,
      agentId: projection.agentId,
    },
    receipt,
  });

  assert.equal(synced.packageRecord.state, "delivered");
  assert.equal(synced.deliveryRecord.state, "delivered");
  assert.equal(
    state.packages.get(contextPackage.packageId)?.packageRef,
    "cmp-package:child-seed",
  );
});
