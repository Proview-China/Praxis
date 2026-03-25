import assert from "node:assert/strict";
import test from "node:test";

import { createAgentCapabilityProfile } from "../ta-pool-types/index.js";
import {
  createDefaultCapabilityGrant,
  resolveBaselineCapability,
  toCapabilityAccessAssignment,
} from "./profile-baseline.js";

const profile = createAgentCapabilityProfile({
  profileId: "profile.main",
  agentClass: "main-agent",
  defaultMode: "balanced",
  baselineTier: "B0",
  baselineCapabilities: ["docs.read", "code.read"],
  allowedCapabilityPatterns: ["search.*", "mcp.*"],
  reviewOnlyCapabilities: ["dependency.install"],
  reviewOnlyCapabilityPatterns: ["computer.*"],
  deniedCapabilityPatterns: ["shell.*", "system.*"],
});

test("profile baseline resolves direct baseline capability hits", () => {
  const resolution = resolveBaselineCapability({
    profile,
    capabilityKey: "docs.read",
  });

  assert.equal(resolution.status, "baseline_allowed");
  assert.equal(resolution.tier, "B0");
});

test("profile baseline keeps denied patterns ahead of allow patterns", () => {
  const resolution = resolveBaselineCapability({
    profile,
    capabilityKey: "shell.exec",
    requestedTier: "B3",
  });

  assert.equal(resolution.status, "denied");
  assert.equal(resolution.tier, "B3");
});

test("profile baseline can classify allowed patterns without baseline grants", () => {
  const resolution = resolveBaselineCapability({
    profile,
    capabilityKey: "search.web",
    requestedTier: "B1",
  });

  assert.equal(resolution.status, "pattern_allowed");
  assert.equal(toCapabilityAccessAssignment(resolution.status), "allowed_pattern");
});

test("profile baseline marks review-only capabilities without promoting them to baseline", () => {
  const explicitReviewOnly = resolveBaselineCapability({
    profile,
    capabilityKey: "dependency.install",
    requestedTier: "B2",
  });
  const patternReviewOnly = resolveBaselineCapability({
    profile,
    capabilityKey: "computer.browser",
    requestedTier: "B2",
  });

  assert.equal(explicitReviewOnly.status, "review_only");
  assert.equal(patternReviewOnly.status, "review_only");
  assert.equal(toCapabilityAccessAssignment(explicitReviewOnly.status), "review_only");
});

test("profile baseline builds default grants for downstream control plane use", () => {
  const grant = createDefaultCapabilityGrant({
    requestId: "req-1",
    capabilityKey: "docs.read",
    issuedAt: "2026-03-18T01:30:00.000Z",
  });

  assert.equal(grant.capabilityKey, "docs.read");
  assert.equal(grant.constraints?.source, "default-profile");
});
