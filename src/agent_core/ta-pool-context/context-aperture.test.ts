import assert from "node:assert/strict";
import test from "node:test";

import { createAgentCapabilityProfile } from "../ta-pool-types/index.js";
import {
  CONTEXT_APERTURE_FORBIDDEN_OBJECTS,
  createProvisionContextAperture,
  createReviewContextAperture,
} from "./context-aperture.js";
import { formatPlainLanguageRisk } from "./plain-language-risk.js";

test("review context aperture upgrades placeholder fields to v1 structure", () => {
  const profile = createAgentCapabilityProfile({
    profileId: "profile-main",
    agentClass: "main-agent",
    baselineCapabilities: ["docs.read"],
  });

  const aperture = createReviewContextAperture({
    runSummary: {
      summary: "Need browser screenshot capability.",
      status: "ready",
      source: "test",
    },
    profileSnapshot: profile,
    inventorySnapshot: {
      totalCapabilities: 3,
      availableCapabilityKeys: ["docs.read", "search.web", "mcp.playwright"],
      pendingProvisionKeys: ["computer.use"],
    },
    userIntentSummary: "用户要一个真实浏览器能力来做截图。",
    riskSummary: {
      requestedAction: "install and enable playwright capability",
      capabilityKey: "mcp.playwright",
      riskLevel: "risky",
    },
    modeSnapshot: "strict",
  });

  assert.equal(aperture.projectSummary.status, "placeholder");
  assert.equal(aperture.runSummary.summary, "Need browser screenshot capability.");
  assert.equal(aperture.profileSnapshot?.profileId, "profile-main");
  assert.equal(aperture.inventorySnapshot.totalCapabilities, 3);
  assert.equal(aperture.capabilityInventorySnapshot.totalCapabilities, 3);
  assert.equal(aperture.memorySummaryPlaceholder.status, "placeholder");
  assert.equal(aperture.userIntentSummary.status, "ready");
  assert.equal(aperture.riskSummary.plainLanguageRisk.riskLevel, "risky");
  assert.equal(aperture.forbiddenObjects, CONTEXT_APERTURE_FORBIDDEN_OBJECTS);
});

test("provision context aperture upgrades requested capability input to v1 structure", () => {
  const aperture = createProvisionContextAperture({
    requestedCapabilityKey: "mcp.playwright",
    inventorySnapshot: {
      knownBindings: ["binding:websearch"],
      knownTools: ["websearch"],
    },
    reviewerInstructions: "先说明风险与范围，再决定是否继续 provisioning。",
  });

  assert.equal(aperture.requestedCapabilityKey, "mcp.playwright");
  assert.equal(aperture.capabilitySpec.capabilityKey, "mcp.playwright");
  assert.equal(aperture.inventorySnapshot?.knownTools[0], "websearch");
  assert.equal(aperture.existingSiblingCapabilitySummary.status, "placeholder");
  assert.equal(aperture.allowedBuildScope.status, "placeholder");
  assert.equal(aperture.allowedSideEffects.length, 2);
  assert.equal(aperture.reviewerInstructions.status, "ready");
});

test("context aperture rejects forbidden live handles and secret slots", () => {
  assert.throws(() => createReviewContextAperture({
    runSummary: "run-1",
    userIntentSummary: "执行 capability review",
    riskSummary: {
      requestedAction: "review the capability request",
      riskLevel: "normal",
    },
    metadata: {
      runtimeHandle: {
        id: "live-runtime",
      },
    },
  }), /runtime handle/i);

  assert.throws(() => createProvisionContextAperture({
    requestedCapabilityKey: "mcp.playwright",
    metadata: {
      apiKey: "sk-live-secret",
    },
  }), /secret literal/i);
});

test("plain-language risk formatter generates valid user-facing copy", () => {
  const payload = formatPlainLanguageRisk({
    requestedAction: "install and enable playwright capability",
    capabilityKey: "mcp.playwright",
    riskLevel: "risky",
  });

  assert.match(payload.plainLanguageSummary, /install and enable playwright capability/);
  assert.equal(payload.riskLevel, "risky");
  assert.equal(payload.availableUserActions[0]?.kind, "approve");
});
