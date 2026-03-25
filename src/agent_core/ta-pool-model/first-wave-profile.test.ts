import assert from "node:assert/strict";
import test from "node:test";

import {
  assembleCapabilityProfileFromPackages,
  createFirstWaveCapabilityProfile,
  resolveBaselineCapability,
  resolveFirstWaveCapabilityAssignment,
} from "./index.js";
import { createFirstWaveCapabilityPackageCatalog } from "../capability-package/index.js";

test("package-backed first-wave profile assembly preserves baseline, allowed-pattern, and review-only splits", () => {
  const profile = assembleCapabilityProfileFromPackages({
    profileId: "profile.first-wave",
    agentClass: "bootstrap-tma",
    packages: createFirstWaveCapabilityPackageCatalog(),
    defaultMode: "balanced",
  });

  assert.deepEqual(profile.baselineCapabilities, ["code.read", "docs.read"]);
  assert.deepEqual(
    profile.allowedCapabilityPatterns,
    ["repo.write", "shell.restricted", "test.run", "skill.doc.generate"],
  );
  assert.deepEqual(
    profile.reviewOnlyCapabilities,
    ["dependency.install", "network.download", "mcp.configure"],
  );

  assert.equal(resolveBaselineCapability({ profile, capabilityKey: "docs.read" }).status, "baseline_allowed");
  assert.equal(resolveBaselineCapability({ profile, capabilityKey: "repo.write" }).status, "pattern_allowed");
  assert.equal(resolveBaselineCapability({ profile, capabilityKey: "dependency.install" }).status, "review_only");
});

test("createFirstWaveCapabilityProfile publishes the same frozen first-wave assignment summary", () => {
  const profile = createFirstWaveCapabilityProfile({
    profileId: "profile.first-wave.default",
    agentClass: "reviewer",
  });

  assert.equal(resolveFirstWaveCapabilityAssignment("docs.read"), "baseline");
  assert.equal(resolveFirstWaveCapabilityAssignment("repo.write"), "allowed_pattern");
  assert.equal(resolveFirstWaveCapabilityAssignment("network.download"), "review_only");
  assert.equal(resolveFirstWaveCapabilityAssignment("search.ground"), "unmatched");
  assert.deepEqual(profile.metadata?.capabilityPackageAssembly, {
    baselineCapabilities: ["code.read", "docs.read"],
    allowedCapabilityPatterns: ["repo.write", "shell.restricted", "test.run", "skill.doc.generate"],
    reviewOnlyCapabilityKeys: ["dependency.install", "network.download", "mcp.configure"],
  });
});
