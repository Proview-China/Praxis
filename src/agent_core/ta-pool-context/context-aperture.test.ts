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

  assert.equal(aperture.projectSummary.status, "ready");
  assert.equal(aperture.runSummary.summary, "Need browser screenshot capability.");
  assert.equal(aperture.profileSnapshot?.profileId, "profile-main");
  assert.equal(aperture.inventorySnapshot.totalCapabilities, 3);
  assert.equal(aperture.capabilityInventorySnapshot.totalCapabilities, 3);
  assert.equal(aperture.memorySummaryPlaceholder.status, "placeholder");
  assert.equal(aperture.userIntentSummary.status, "ready");
  assert.equal(aperture.riskSummary.plainLanguageRisk.riskLevel, "risky");
  assert.equal(aperture.forbiddenObjects, CONTEXT_APERTURE_FORBIDDEN_OBJECTS);
});

test("review context aperture can derive a safe memory summary from provided sections", () => {
  const aperture = createReviewContextAperture({
    userIntentSummary: "审查高风险能力请求。",
    riskSummary: {
      requestedAction: "review computer.use capability",
      capabilityKey: "computer.use",
      riskLevel: "risky",
    },
    sections: [
      {
        sectionId: "request",
        title: "Request",
        summary: "computer.use 请求已进入 reviewer。",
        status: "ready",
      },
      {
        sectionId: "inventory",
        title: "Inventory",
        summary: "当前 capability inventory 已加载。",
        status: "ready",
      },
    ],
  });

  assert.equal(aperture.memorySummaryPlaceholder.status, "ready");
  assert.match(aperture.memorySummaryPlaceholder.summary, /Section-backed context is available/i);
  assert.equal(aperture.memorySummaryPlaceholder.metadata?.sectionCount, 2);
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
  assert.equal(aperture.projectSummary.status, "ready");
  assert.equal(aperture.existingSiblingCapabilitySummary.status, "ready");
  assert.match(aperture.existingSiblingCapabilitySummary.summary, /No sibling capability inventory/i);
  assert.equal(aperture.allowedBuildScope.status, "ready");
  assert.equal(aperture.allowedSideEffects.length, 2);
  assert.equal(aperture.allowedSideEffects.every((effect) => effect.status === "ready"), true);
  assert.equal(aperture.reviewerInstructions.status, "ready");
});

test("context aperture normalizes structured sections for future CMP/MP handoff", () => {
  const aperture = createReviewContextAperture({
    userIntentSummary: "需要审查真实浏览器能力。",
    riskSummary: {
      requestedAction: "review browser automation capability",
      capabilityKey: "mcp.playwright",
      riskLevel: "risky",
    },
    sections: [
      {
        sectionId: "project-state",
        title: "Project State",
        summary: "Praxis 正在推进 TAP final closure。",
        status: "ready",
        source: "cmp-placeholder",
        freshness: "fresh",
        trustLevel: "declared",
      },
      "Memory slot placeholder for later registry wiring.",
    ],
  });

  assert.equal(aperture.sections.length, 2);
  assert.equal(aperture.sections[0]?.sectionId, "project-state");
  assert.equal(aperture.sections[0]?.freshness, "fresh");
  assert.equal(aperture.sections[0]?.trustLevel, "declared");
  assert.equal(aperture.sections[1]?.sectionId, "section-2");
  assert.equal(aperture.sections[1]?.status, "ready");
});

test("context aperture rejects duplicate section ids", () => {
  assert.throws(() => createReviewContextAperture({
    userIntentSummary: "duplicate sections should fail",
    riskSummary: {
      requestedAction: "review duplicate section ids",
      riskLevel: "normal",
    },
    sections: [
      {
        sectionId: "dup",
        title: "First",
        summary: "first summary",
        status: "ready",
      },
      {
        sectionId: "dup",
        title: "Second",
        summary: "second summary",
        status: "ready",
      },
    ],
  }), /duplicate sectionId/i);
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
