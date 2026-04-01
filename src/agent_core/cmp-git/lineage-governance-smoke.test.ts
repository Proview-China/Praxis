import assert from "node:assert/strict";
import test from "node:test";

import { createCmpGitBranchRef } from "./cmp-git-types.js";
import { CmpGitLineageRegistry } from "./lineage-registry.js";
import {
  assertCmpGitPromotionKeepsAncestorsInvisible,
  createCmpGitPromotionPullRequest,
  promoteCmpGitMerge,
} from "./governance.js";
import { createCmpGitSyncRuntimeOrchestrator } from "./orchestrator.js";

test("cmp git smoke keeps 3-level lineage promotion inside the direct parent boundary", () => {
  const orchestrator = createCmpGitSyncRuntimeOrchestrator();
  orchestrator.registry.register({
    projectId: "project.cmp.smoke",
    agentId: "root",
  });
  orchestrator.registry.register({
    projectId: "project.cmp.smoke",
    agentId: "parent",
    parentAgentId: "root",
    depth: 1,
  });
  orchestrator.registry.register({
    projectId: "project.cmp.smoke",
    agentId: "leaf",
    parentAgentId: "parent",
    depth: 2,
  });

  const synced = orchestrator.syncCommitDelta({
    projectId: "project.cmp.smoke",
    commitSha: "commit-leaf-1",
    branchRef: createCmpGitBranchRef({ kind: "cmp", agentId: "leaf" }),
    delta: {
      deltaId: "delta-leaf-1",
      agentId: "leaf",
    },
    syncIntent: "submit_to_parent",
  });

  orchestrator.markCandidateChecked({
    candidateId: synced.candidate.candidateId,
    snapshotId: "snapshot-leaf-1",
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

  assert.equal(promoted.promotion.targetAgentId, "parent");
  assert.equal(promoted.promotion.visibility, "parent_only");
  assert.equal(orchestrator.getBranchHead("refs/heads/cmp/parent")?.promotedRefName, promoted.promotedRef.refName);
  assert.equal(orchestrator.getBranchHead("refs/heads/cmp/root"), undefined);
  assert.doesNotThrow(() => {
    assertCmpGitPromotionKeepsAncestorsInvisible({
      promotion: promoted.promotion,
      ancestorAgentId: "root",
    });
  });
});

test("cmp git smoke treats peer exchange as local sibling sync, not upward promotion", () => {
  const registry = new CmpGitLineageRegistry();
  registry.register({
    projectId: "project.cmp.peer",
    agentId: "root",
  });
  registry.register({
    projectId: "project.cmp.peer",
    agentId: "peer-a",
    parentAgentId: "root",
    depth: 1,
  });
  registry.register({
    projectId: "project.cmp.peer",
    agentId: "peer-b",
    parentAgentId: "root",
    depth: 1,
  });

  const orchestrator = createCmpGitSyncRuntimeOrchestrator({ registry });
  const synced = orchestrator.syncCommitDelta({
    projectId: "project.cmp.peer",
    commitSha: "commit-peer-a-1",
    branchRef: createCmpGitBranchRef({ kind: "cmp", agentId: "peer-a" }),
    delta: {
      deltaId: "delta-peer-a-1",
      agentId: "peer-a",
    },
    syncIntent: "peer_exchange",
  });

  assert.equal(orchestrator.listPromotions().length, 0);
  assert.equal(orchestrator.listPullRequests().length, 0);
  assert.equal(orchestrator.getBranchHead("refs/heads/cmp/root"), undefined);

  assert.throws(() => {
    createCmpGitPromotionPullRequest({
      registry,
      candidate: synced.candidate,
      targetAgentId: "peer-b",
    });
  }, /not the direct parent/i);
});

test("cmp git smoke keeps critical escalation out of the promotion/ref path", () => {
  const promotion = promoteCmpGitMerge({
    merge: {
      mergeId: "merge-escalation-1",
      projectId: "project.cmp.escalation",
      pullRequestId: "pr-escalation-1",
      sourceAgentId: "leaf",
      targetAgentId: "parent",
      sourceCommitSha: "commit-escalation-1",
      targetBranchRef: createCmpGitBranchRef({ kind: "cmp", agentId: "parent" }),
      mergedAt: new Date("2026-03-24T10:00:00.000Z").toISOString(),
      status: "merged_to_parent",
    },
    candidate: {
      candidateId: "candidate-escalation-1",
      projectId: "project.cmp.escalation",
      agentId: "leaf",
      branchRef: createCmpGitBranchRef({ kind: "cmp", agentId: "leaf" }),
      commitSha: "commit-escalation-1",
      deltaId: "delta-escalation-1",
      createdAt: new Date("2026-03-24T09:59:00.000Z").toISOString(),
      status: "checked",
    },
    promoterAgentId: "parent",
    promotedAt: new Date("2026-03-24T10:01:00.000Z").toISOString(),
    visibility: "parent_promoted",
  });

  assert.throws(() => {
    assertCmpGitPromotionKeepsAncestorsInvisible({
      promotion,
      ancestorAgentId: "root",
    });
  }, /must not directly expose raw promoted state to ancestor/i);
});
