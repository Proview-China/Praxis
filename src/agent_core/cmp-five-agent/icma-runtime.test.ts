import assert from "node:assert/strict";
import test from "node:test";

import { createCmpBranchFamily } from "../cmp-types/index.js";
import { createCmpIcmaRuntime } from "./icma-runtime.js";

test("CmpIcmaRuntime captures by task intent and only keeps allowed fragment kinds", () => {
  const runtime = createCmpIcmaRuntime();
  const captured = runtime.capture({
    ingest: {
      agentId: "main",
      sessionId: "session-1",
      taskSummary: "整理当前任务上下文",
      materials: [
        { kind: "user_input", ref: "msg:1" },
        { kind: "tool_result", ref: "tool:1" },
      ],
      lineage: {
        agentId: "main",
        projectId: "proj-1",
        depth: 0,
        status: "active",
        branchFamily: createCmpBranchFamily({
          workBranch: "work/main",
          cmpBranch: "cmp/main",
          mpBranch: "mp/main",
          tapBranch: "tap/main",
        }),
      },
      metadata: {
        cmpSystemFragmentKinds: ["constraint", "risk", "invalid", "flow"],
      },
    },
    createdAt: "2026-03-25T00:00:00.000Z",
    loopId: "icma-loop-1",
  });

  assert.equal(captured.loop.stage, "attach_fragment");
  assert.deepEqual(captured.fragments.map((fragment) => fragment.kind), ["constraint", "risk", "flow"]);
  assert.equal(captured.loop.metadata?.gitWriteAccess, false);

  const emitted = runtime.emit({
    recordId: captured.loop.loopId,
    eventIds: ["evt-1", "evt-2"],
    emittedAt: "2026-03-25T00:00:01.000Z",
  });
  assert.equal(emitted.stage, "emit");
});
