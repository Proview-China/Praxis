import assert from "node:assert/strict";
import test from "node:test";

import { createCheckedSnapshot, createContextPackage } from "../cmp-types/index.js";
import { createCmpDbAgentRuntime, createCmpTimelinePackageRef } from "./dbagent-runtime.js";

test("CmpDbAgentRuntime materializes primary package plus timeline attachment and task snapshots", () => {
  const runtime = createCmpDbAgentRuntime();
  const materialized = runtime.materialize({
    checkedSnapshot: createCheckedSnapshot({
      snapshotId: "snapshot-1",
      agentId: "main",
      lineageRef: "proj:main",
      branchRef: "refs/heads/cmp/main",
      commitRef: "commit-1",
      checkedAt: "2026-03-25T00:00:00.000Z",
    }),
    projectionId: "projection-1",
    contextPackage: createContextPackage({
      packageId: "pkg-1",
      sourceProjectionId: "projection-1",
      targetAgentId: "main",
      packageRef: "cmp-package:snapshot-1:main:active",
      createdAt: "2026-03-25T00:00:00.000Z",
    }),
    createdAt: "2026-03-25T00:00:00.000Z",
    loopId: "dbagent-loop-1",
  });

  assert.equal(materialized.loop.stage, "attach_snapshots");
  assert.equal(materialized.family.timelinePackageRef, createCmpTimelinePackageRef("cmp-package:snapshot-1:main:active"));
  assert.equal(materialized.taskSnapshots.length, 1);
});
