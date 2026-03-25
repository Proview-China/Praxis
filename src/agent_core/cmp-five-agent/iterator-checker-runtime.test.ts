import assert from "node:assert/strict";
import test from "node:test";

import { createCmpIteratorCheckerRuntime } from "./iterator-checker-runtime.js";

test("CmpIteratorCheckerRuntime keeps commit as minimum review unit and separates checked from promote", () => {
  const runtime = createCmpIteratorCheckerRuntime();

  const iterator = runtime.advanceIterator({
    agentId: "child-a",
    deltaId: "delta-1",
    candidateId: "candidate-1",
    branchRef: "refs/heads/cmp/child-a",
    commitRef: "commit-1",
    reviewRef: "refs/review/candidate-1",
    createdAt: "2026-03-25T00:00:00.000Z",
  });
  assert.equal(iterator.stage, "update_review_ref");
  assert.equal(iterator.metadata?.minimumReviewUnit, "commit");

  const checked = runtime.evaluateChecker({
    agentId: "child-a",
    candidateId: "candidate-1",
    checkedSnapshotId: "checked-1",
    checkedAt: "2026-03-25T00:00:01.000Z",
    suggestPromote: true,
    parentAgentId: "parent-a",
  });
  assert.equal(checked.checkerRecord.stage, "suggest_promote");
  assert.equal(checked.promoteRequest?.reviewerRole, "dbagent");
});
