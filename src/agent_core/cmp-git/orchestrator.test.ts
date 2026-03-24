import assert from "node:assert/strict";
import test from "node:test";

import { createCmpGitSyncRuntimeOrchestrator } from "./orchestrator.js";

test("cmp git orchestrator advances commit -> checked ref -> PR -> merge -> promotion in order", () => {
  const orchestrator = createCmpGitSyncRuntimeOrchestrator();
  orchestrator.registry.register({
    projectId: "project.cmp",
    agentId: "root",
  });
  orchestrator.registry.register({
    projectId: "project.cmp",
    agentId: "parent",
    parentAgentId: "root",
    depth: 1,
  });
  orchestrator.registry.register({
    projectId: "project.cmp",
    agentId: "child",
    parentAgentId: "parent",
    depth: 2,
  });

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
  });

  const checkedRef = orchestrator.markCandidateChecked({
    candidateId: synced.candidate.candidateId,
    snapshotId: "snapshot-1",
  });
  assert.equal(checkedRef.snapshotId, "snapshot-1");

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

  assert.equal(promoted.promotion.status, "promoted");
  assert.equal(promoted.promotedRef.targetAgentId, "parent");
  assert.equal(promoted.branchHead.promotedRefName, promoted.promotedRef.refName);
  assert.equal(orchestrator.listPullRequests()[0]?.status, "merged");
  assert.equal(orchestrator.getBranchHead("refs/heads/cmp/parent")?.headCommitSha, "abc123");
});
