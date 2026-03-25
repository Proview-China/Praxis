import assert from "node:assert/strict";
import test from "node:test";

import { createContextPackage, createDispatchReceipt } from "../cmp-types/index.js";
import { createCmpDispatcherRuntime } from "./dispatcher-runtime.js";

test("CmpDispatcherRuntime records child seed via child ICMA and peer approval state", () => {
  const runtime = createCmpDispatcherRuntime();
  const child = runtime.dispatch({
    contextPackage: createContextPackage({
      packageId: "pkg-child",
      sourceProjectionId: "projection-1",
      targetAgentId: "child-a",
      packageKind: "child_seed",
      packageRef: "cmp-package:child",
      createdAt: "2026-03-25T00:00:00.000Z",
    }),
    dispatch: {
      agentId: "main",
      packageId: "pkg-child",
      sourceAgentId: "main",
      targetAgentId: "child-a",
      targetKind: "child",
    },
    receipt: createDispatchReceipt({
      dispatchId: "dispatch-child",
      packageId: "pkg-child",
      sourceAgentId: "main",
      targetAgentId: "child-a",
      status: "delivered",
      deliveredAt: "2026-03-25T00:00:00.000Z",
    }),
    createdAt: "2026-03-25T00:00:00.000Z",
    loopId: "dispatcher-child-1",
  });
  assert.equal(child.loop.packageMode, "child_seed_via_icma");

  const peer = runtime.dispatch({
    contextPackage: createContextPackage({
      packageId: "pkg-peer",
      sourceProjectionId: "projection-2",
      targetAgentId: "peer-b",
      packageKind: "peer_exchange",
      packageRef: "cmp-package:peer",
      createdAt: "2026-03-25T00:00:00.000Z",
    }),
    dispatch: {
      agentId: "peer-a",
      packageId: "pkg-peer",
      sourceAgentId: "peer-a",
      targetAgentId: "peer-b",
      targetKind: "peer",
    },
    receipt: createDispatchReceipt({
      dispatchId: "dispatch-peer",
      packageId: "pkg-peer",
      sourceAgentId: "peer-a",
      targetAgentId: "peer-b",
      status: "delivered",
      deliveredAt: "2026-03-25T00:00:00.000Z",
    }),
    createdAt: "2026-03-25T00:00:00.000Z",
    loopId: "dispatcher-peer-1",
  });
  assert.equal(peer.peerApproval?.metadata?.approvalStatus, "pending");
});
