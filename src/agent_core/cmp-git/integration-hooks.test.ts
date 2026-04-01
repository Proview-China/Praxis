import assert from "node:assert/strict";
import test from "node:test";

import { createCmpGitSyncRuntimeOrchestrator } from "./orchestrator.js";
import {
  createCmpGitProjectionSourceAnchor,
  createCmpGitRuntimeHooks,
  createCmpGitSyncReceipt,
} from "./integration-hooks.js";

test("cmp git integration hooks expose lineage hooks for part1 and part4 consumers", () => {
  const orchestrator = createCmpGitSyncRuntimeOrchestrator();
  orchestrator.registry.register({ projectId: "project.cmp", agentId: "root" });
  orchestrator.registry.register({ projectId: "project.cmp", agentId: "parent", parentAgentId: "root", depth: 1 });
  orchestrator.registry.register({ projectId: "project.cmp", agentId: "child", parentAgentId: "parent", depth: 2 });
  const hooks = createCmpGitRuntimeHooks(orchestrator);

  const childHook = hooks.getLineageHook("child");
  assert.equal(childHook?.parentAgentId, "parent");
  assert.equal(childHook?.cmpBranchRef, "refs/heads/cmp/child");
  assert.equal(hooks.listChildHooks("parent").length, 1);
  assert.equal(hooks.listPeerHooks("child").length, 0);
});

test("cmp git integration hooks can expose projection source anchors from orchestrated state", () => {
  const orchestrator = createCmpGitSyncRuntimeOrchestrator();
  orchestrator.registry.register({ projectId: "project.cmp", agentId: "root" });
  orchestrator.registry.register({ projectId: "project.cmp", agentId: "parent", parentAgentId: "root", depth: 1 });
  orchestrator.registry.register({ projectId: "project.cmp", agentId: "child", parentAgentId: "parent", depth: 2 });

  const synced = orchestrator.syncCommitDelta({
    projectId: "project.cmp",
    commitSha: "abc123",
    branchRef: {
      kind: "cmp",
      agentId: "child",
      branchName: "cmp/child",
      fullRef: "refs/heads/cmp/child",
    },
    delta: {
      deltaId: "delta-1",
      agentId: "child",
    },
    syncIntent: "submit_to_parent",
  });
  const checkedRef = orchestrator.markCandidateChecked({
    candidateId: synced.candidate.candidateId,
    snapshotId: "snapshot-1",
  });
  const pullRequest = orchestrator.openPullRequest({
    candidateId: synced.candidate.candidateId,
    targetAgentId: "parent",
  });
  const merge = orchestrator.mergePullRequest({
    pullRequestId: pullRequest.pullRequestId,
    actorAgentId: "parent",
  });
  const promoted = orchestrator.promoteMerge({
    mergeId: merge.mergeId,
    promoterAgentId: "parent",
  });

  const anchor = createCmpGitProjectionSourceAnchor({
    candidate: synced.candidate,
    checkedRef,
    promotedRef: promoted.promotedRef,
    branchHead: promoted.branchHead,
  });
  assert.equal(anchor.checkedRefName, checkedRef.refName);
  assert.equal(anchor.promotedRefName, promoted.promotedRef.refName);
  assert.equal(anchor.commitSha, "abc123");

  const receipt = createCmpGitSyncReceipt({
    candidate: synced.candidate,
    checkedRef,
    pullRequest,
    merge,
    promotion: promoted.promotion,
    promotedRef: promoted.promotedRef,
    branchHead: promoted.branchHead,
  });
  assert.equal(receipt.promotion?.status, "promoted");
});
