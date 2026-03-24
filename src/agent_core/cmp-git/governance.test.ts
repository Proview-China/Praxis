import assert from "node:assert/strict";
import test from "node:test";

import { createCmpGitBranchRef, type CmpGitSnapshotCandidateRecord } from "./cmp-git-types.js";
import { CmpGitLineageRegistry } from "./lineage-registry.js";
import {
  assertCmpGitPromotionKeepsAncestorsInvisible,
  createCmpGitPromotionPullRequest,
  mergeCmpGitPromotionPullRequest,
  promoteCmpGitMerge,
} from "./governance.js";

function createCandidate(agentId: string): CmpGitSnapshotCandidateRecord {
  return {
    candidateId: "candidate-1",
    projectId: "project.cmp",
    agentId,
    branchRef: createCmpGitBranchRef({ kind: "cmp", agentId }),
    commitSha: "abc123",
    deltaId: "delta-1",
    createdAt: new Date("2026-03-24T00:00:00.000Z").toISOString(),
    status: "pending_check",
  };
}

test("cmp git governance only allows a child to open a PR to its direct parent", () => {
  const registry = new CmpGitLineageRegistry();
  registry.register({ projectId: "project.cmp", agentId: "main" });
  registry.register({ projectId: "project.cmp", agentId: "child", parentAgentId: "main", depth: 1 });

  const candidate = createCandidate("child");
  const pullRequest = createCmpGitPromotionPullRequest({
    registry,
    candidate,
    targetAgentId: "main",
  });

  assert.equal(pullRequest.sourceAgentId, "child");
  assert.equal(pullRequest.targetAgentId, "main");
  assert.equal(pullRequest.status, "open");

  assert.throws(() => {
    createCmpGitPromotionPullRequest({
      registry,
      candidate,
      targetAgentId: "someone-else",
    });
  }, /not the direct parent/i);
});

test("cmp git governance only allows the direct parent to merge and promote", () => {
  const registry = new CmpGitLineageRegistry();
  registry.register({ projectId: "project.cmp", agentId: "root" });
  registry.register({ projectId: "project.cmp", agentId: "parent", parentAgentId: "root", depth: 1 });
  registry.register({ projectId: "project.cmp", agentId: "child", parentAgentId: "parent", depth: 2 });

  const candidate = createCandidate("child");
  const pullRequest = createCmpGitPromotionPullRequest({
    registry,
    candidate,
    targetAgentId: "parent",
  });

  assert.throws(() => {
    mergeCmpGitPromotionPullRequest({
      pullRequest,
      candidate,
      actorAgentId: "root",
    });
  }, /can only be merged by direct parent/i);

  const merge = mergeCmpGitPromotionPullRequest({
    pullRequest,
    candidate,
    actorAgentId: "parent",
  });
  assert.equal(merge.status, "merged_to_parent");

  assert.throws(() => {
    promoteCmpGitMerge({
      merge,
      candidate,
      promoterAgentId: "root",
    });
  }, /can only be issued by parent/i);

  const promotion = promoteCmpGitMerge({
    merge,
    candidate,
    promoterAgentId: "parent",
  });
  assert.equal(promotion.status, "promoted");
  assert.equal(promotion.visibility, "parent_only");

  assert.doesNotThrow(() => {
    assertCmpGitPromotionKeepsAncestorsInvisible({
      promotion,
      ancestorAgentId: "root",
    });
  });
});
