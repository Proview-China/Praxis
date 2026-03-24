import assert from "node:assert/strict";
import test from "node:test";

import { createCmpGitBranchRef, type CmpGitSnapshotCandidateRecord } from "./cmp-git-types.js";
import { createCmpGitPromotedSnapshotRef, createCmpGitCheckedSnapshotRef, reconcileCmpGitBranchHeadState } from "./refs-lifecycle.js";
import type { CmpGitPromotionRecord } from "./governance.js";

function createCandidate(): CmpGitSnapshotCandidateRecord {
  return {
    candidateId: "candidate-1",
    projectId: "project.cmp",
    agentId: "child",
    branchRef: createCmpGitBranchRef({ kind: "cmp", agentId: "child" }),
    commitSha: "abc123",
    deltaId: "delta-1",
    createdAt: new Date("2026-03-24T00:00:00.000Z").toISOString(),
    status: "pending_check",
  };
}

test("cmp git checked ref and branch head lifecycle stay consistent", () => {
  const candidate = createCandidate();
  const checkedRef = createCmpGitCheckedSnapshotRef({
    candidate,
    snapshotId: "snapshot-1",
  });

  const head = reconcileCmpGitBranchHeadState({
    branchRef: candidate.branchRef,
    headCommitSha: candidate.commitSha,
    checkedRef,
    updatedAt: checkedRef.updatedAt,
  });

  assert.equal(head.checkedRefName, checkedRef.refName);
  assert.equal(head.headCommitSha, checkedRef.commitSha);
});

test("cmp git promoted ref must target the same branch head and commit", () => {
  const promotion: CmpGitPromotionRecord = {
    promotionId: "promotion-1",
    projectId: "project.cmp",
    mergeId: "merge-1",
    sourceAgentId: "child",
    targetAgentId: "parent",
    candidateId: "snapshot-1",
    checkedCommitSha: "abc123",
    visibility: "parent_only",
    status: "promoted",
    promotedAt: new Date("2026-03-24T00:00:01.000Z").toISOString(),
  };

  const targetBranchRef = createCmpGitBranchRef({ kind: "cmp", agentId: "parent" });
  const promotedRef = createCmpGitPromotedSnapshotRef({
    promotion,
    targetBranchRef,
  });

  const head = reconcileCmpGitBranchHeadState({
    branchRef: targetBranchRef,
    headCommitSha: "abc123",
    promotedRef,
    updatedAt: promotedRef.updatedAt,
  });

  assert.equal(head.promotedRefName, promotedRef.refName);

  assert.throws(() => {
    reconcileCmpGitBranchHeadState({
      branchRef: targetBranchRef,
      headCommitSha: "different",
      promotedRef,
      updatedAt: promotedRef.updatedAt,
    });
  }, /must equal branch head commit/i);
});
