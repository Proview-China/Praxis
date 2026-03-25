import assert from "node:assert/strict";
import test from "node:test";

import {
  assembleCapabilityProfileFromPackages,
  createFirstWaveCapabilityProfile,
  getFirstWaveCapabilityProfileAssemblySummary,
  getFirstWaveProfileAssemblyDescriptor,
  listFirstWaveProfileAssemblyDescriptors,
  resolveBaselineCapability,
  resolveFirstWaveCapabilityAssignment,
} from "./index.js";
import {
  createFirstWaveCapabilityPackageCatalog,
} from "../capability-package/index.js";

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
    ["dependency.install", "network.download"],
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
    reviewOnlyCapabilityKeys: ["dependency.install", "network.download"],
  });
});

test("first-wave profile assembly presets expose reviewer and bootstrap boundaries clearly", () => {
  assert.deepEqual(
    listFirstWaveProfileAssemblyDescriptors().map((descriptor) => descriptor.target),
    ["baseline", "reviewer", "bootstrap_tma", "first_wave"],
  );

  const bootstrapDescriptor = getFirstWaveProfileAssemblyDescriptor("bootstrap_tma");
  assert.equal(bootstrapDescriptor.readOnly, false);
  assert.equal(bootstrapDescriptor.includesReviewOnly, false);
  assert.deepEqual(bootstrapDescriptor.familyKeys, ["reviewer_baseline", "bootstrap_tma"]);

  assert.deepEqual(getFirstWaveCapabilityProfileAssemblySummary("reviewer"), {
    baselineCapabilities: ["code.read", "docs.read"],
    allowedCapabilityPatterns: [],
    reviewOnlyCapabilityKeys: [],
  });
});

test("createFirstWaveCapabilityProfile can assemble reviewer-only and bootstrap-tma variants from the same family source", () => {
  const reviewerProfile = createFirstWaveCapabilityProfile({
    profileId: "profile.first-wave.reviewer",
    agentClass: "reviewer",
    assemblyTarget: "reviewer",
  });
  const bootstrapProfile = createFirstWaveCapabilityProfile({
    profileId: "profile.first-wave.bootstrap",
    agentClass: "bootstrap-tma",
    assemblyTarget: "bootstrap_tma",
  });

  assert.deepEqual(reviewerProfile.baselineCapabilities, ["code.read", "docs.read"]);
  assert.equal(reviewerProfile.allowedCapabilityPatterns, undefined);
  assert.equal(reviewerProfile.reviewOnlyCapabilities, undefined);
  assert.equal(reviewerProfile.metadata?.firstWaveAssemblyTarget, "reviewer");

  assert.deepEqual(
    bootstrapProfile.allowedCapabilityPatterns,
    ["repo.write", "shell.restricted", "test.run", "skill.doc.generate"],
  );
  assert.equal(bootstrapProfile.reviewOnlyCapabilities, undefined);
  assert.deepEqual(
    bootstrapProfile.metadata?.firstWaveAssemblyFamilies,
    ["reviewer_baseline", "bootstrap_tma"],
  );
});
