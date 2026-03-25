import assert from "node:assert/strict";
import test from "node:test";

import {
  FIRST_WAVE_CAPABILITY_KEYS,
  createFirstWaveCapabilityPackage,
  createFirstWaveCapabilityPackageCatalog,
} from "./index.js";
import {
  createFirstWaveCapabilityPackageCatalogForFamily,
  getFirstWaveCapabilityFamilyDescriptor,
  listFirstWaveCapabilityFamilyDescriptors,
} from "./first-wave-capability-package.js";

test("first-wave capability package catalog freezes the expected registration assembly split", () => {
  const catalog = createFirstWaveCapabilityPackageCatalog();

  assert.equal(catalog.length, FIRST_WAVE_CAPABILITY_KEYS.length);

  const byKey = new Map(catalog.map((capabilityPackage) => [
    capabilityPackage.manifest.capabilityKey,
    capabilityPackage,
  ]));

  assert.equal(byKey.get("code.read")?.policy.registrationAssembly.profileAssignment, "baseline_capability");
  assert.equal(byKey.get("repo.write")?.policy.registrationAssembly.profileAssignment, "allowed_pattern");
  assert.equal(byKey.get("repo.write")?.policy.registrationAssembly.targetLane, "bootstrap_tma");
  assert.equal(byKey.get("dependency.install")?.policy.registrationAssembly.profileAssignment, "review_only");
  assert.equal(byKey.get("dependency.install")?.policy.registrationAssembly.targetLane, "extended_tma");
});

test("first-wave capability package carries allowed pattern only for allowed-pattern entries", () => {
  const allowedPatternPackage = createFirstWaveCapabilityPackage("shell.restricted");
  const reviewOnlyPackage = createFirstWaveCapabilityPackage("network.download");

  assert.equal(allowedPatternPackage.policy.registrationAssembly.allowedPattern, "shell.restricted");
  assert.equal(reviewOnlyPackage.policy.registrationAssembly.allowedPattern, undefined);
});

test("first-wave capability package families expose stable assembly descriptors", () => {
  const families = listFirstWaveCapabilityFamilyDescriptors();

  assert.deepEqual(
    families.map((descriptor) => descriptor.familyKey),
    ["reviewer_baseline", "bootstrap_tma", "extended_review_only"],
  );

  const reviewerBaseline = getFirstWaveCapabilityFamilyDescriptor("reviewer_baseline");
  assert.equal(reviewerBaseline.readOnly, true);
  assert.deepEqual(reviewerBaseline.capabilityKeys, ["code.read", "docs.read"]);

  const bootstrapCatalog = createFirstWaveCapabilityPackageCatalogForFamily("bootstrap_tma");
  assert.deepEqual(
    bootstrapCatalog.map((capabilityPackage) => capabilityPackage.manifest.capabilityKey),
    ["repo.write", "shell.restricted", "test.run", "skill.doc.generate"],
  );

  const extendedReviewOnly = getFirstWaveCapabilityFamilyDescriptor("extended_review_only");
  assert.equal(extendedReviewOnly.includesExternalSideEffects, true);
  assert.equal(extendedReviewOnly.profileAssignment, "review_only");
});
