import assert from "node:assert/strict";
import test from "node:test";

import {
  FIRST_WAVE_CAPABILITY_KEYS,
  createFirstWaveCapabilityPackage,
  createFirstWaveCapabilityPackageCatalog,
} from "./index.js";

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
