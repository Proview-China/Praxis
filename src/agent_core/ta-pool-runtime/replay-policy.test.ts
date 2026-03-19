import assert from "node:assert/strict";
import test from "node:test";

import { createAccessRequest, createProvisionArtifactBundle } from "../ta-pool-types/index.js";
import { createTaPendingReplay } from "./replay-policy.js";

test("replay policy skeleton records pending re-review handoff by default", () => {
  const request = createAccessRequest({
    requestId: "req-replay-1",
    sessionId: "session-1",
    runId: "run-1",
    agentId: "agent-1",
    requestedCapabilityKey: "computer.use",
    requestedTier: "B2",
    reason: "Need computer use after provisioning.",
    mode: "balanced",
    createdAt: "2026-03-19T11:00:00.000Z",
  });
  const bundle = createProvisionArtifactBundle({
    bundleId: "bundle-replay-1",
    provisionId: "provision-replay-1",
    status: "ready",
    toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tool:1" },
    bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:1" },
    verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "verification:1" },
    usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "usage:1" },
    replayPolicy: "re_review_then_dispatch",
    completedAt: "2026-03-19T11:00:05.000Z",
  });

  const replay = createTaPendingReplay({
    replayId: "replay-1",
    request,
    provisionBundle: bundle,
    createdAt: "2026-03-19T11:00:06.000Z",
  });

  assert.equal(replay.policy, "re_review_then_dispatch");
  assert.equal(replay.status, "pending");
  assert.equal(replay.nextAction, "re_review_then_dispatch");
});
