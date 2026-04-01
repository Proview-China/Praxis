import assert from "node:assert/strict";
import test from "node:test";

import { CmpGitLineageRegistry } from "./lineage-registry.js";
import {
  assertCmpGitCriticalEscalationAllowed,
  assertCmpGitNonSkippingPromotion,
  assertCmpGitPeerExchangeStaysLocal,
  createCmpGitCriticalEscalationAlert,
  resolveCmpGitLineageRelation,
} from "./lineage-guard.js";

function seedTree() {
  const registry = new CmpGitLineageRegistry();
  registry.register({ projectId: "project.cmp", agentId: "root" });
  registry.register({ projectId: "project.cmp", agentId: "parent-a", parentAgentId: "root", depth: 1 });
  registry.register({ projectId: "project.cmp", agentId: "parent-b", parentAgentId: "root", depth: 1 });
  registry.register({ projectId: "project.cmp", agentId: "child-a1", parentAgentId: "parent-a", depth: 2 });
  registry.register({ projectId: "project.cmp", agentId: "child-a2", parentAgentId: "parent-a", depth: 2 });
  registry.register({ projectId: "project.cmp", agentId: "child-b1", parentAgentId: "parent-b", depth: 2 });
  return registry;
}

test("cmp git lineage guard resolves parent peer child and ancestor relations", () => {
  const registry = seedTree();
  assert.equal(resolveCmpGitLineageRelation({
    registry,
    sourceAgentId: "child-a1",
    targetAgentId: "parent-a",
  }), "parent");
  assert.equal(resolveCmpGitLineageRelation({
    registry,
    sourceAgentId: "parent-a",
    targetAgentId: "child-a1",
  }), "child");
  assert.equal(resolveCmpGitLineageRelation({
    registry,
    sourceAgentId: "child-a1",
    targetAgentId: "child-a2",
  }), "peer");
  assert.equal(resolveCmpGitLineageRelation({
    registry,
    sourceAgentId: "child-a1",
    targetAgentId: "root",
  }), "ancestor");
});

test("cmp git non-skipping promotion only allows direct-parent promotion", () => {
  const registry = seedTree();
  assert.equal(assertCmpGitNonSkippingPromotion({
    registry,
    sourceAgentId: "child-a1",
    targetAgentId: "parent-a",
  }), "parent");
  assert.throws(() => {
    assertCmpGitNonSkippingPromotion({
      registry,
      sourceAgentId: "child-a1",
      targetAgentId: "root",
    });
  }, /direct parent only/i);
});

test("cmp git peer exchange stays local and does not imply upward promotion", () => {
  const registry = seedTree();
  assert.equal(assertCmpGitPeerExchangeStaysLocal({
    registry,
    sourceAgentId: "child-a1",
    targetAgentId: "child-a2",
  }), "peer");
  assert.throws(() => {
    assertCmpGitPeerExchangeStaysLocal({
      registry,
      sourceAgentId: "child-a1",
      targetAgentId: "parent-a",
    });
  }, /requires a peer relation/i);
});

test("cmp git critical escalation only allows ancestor alert when parent is unavailable", () => {
  const registry = seedTree();
  const alert = createCmpGitCriticalEscalationAlert({
    alertId: "alert-1",
    projectId: "project.cmp",
    sourceAgentId: "child-a1",
    targetAncestorId: "root",
    severity: "critical",
    reason: "parent chain unavailable",
    evidenceRef: "evidence:1",
    createdAt: new Date("2026-03-24T00:00:00.000Z").toISOString(),
  });

  assert.doesNotThrow(() => {
    assertCmpGitCriticalEscalationAllowed({
      registry,
      alert,
      parentReachability: "unavailable",
    });
  });
  assert.throws(() => {
    assertCmpGitCriticalEscalationAllowed({
      registry,
      alert,
      parentReachability: "healthy",
    });
  }, /requires unavailable parent reachability/i);
});
