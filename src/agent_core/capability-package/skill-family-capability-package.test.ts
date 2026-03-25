import assert from "node:assert/strict";
import test from "node:test";

import { validateCapabilityPackage } from "./capability-package.js";
import {
  SKILL_FAMILY_CAPABILITY_KEYS,
  createRaxSkillCapabilityPackage,
  createRaxSkillCapabilityPackageCatalog,
  isSkillFamilyCapabilityKey,
} from "./skill-family-capability-package.js";

test("skill family capability package catalog freezes the supported skill.use/mount/prepare trio", () => {
  const catalog = createRaxSkillCapabilityPackageCatalog();

  assert.equal(catalog.length, SKILL_FAMILY_CAPABILITY_KEYS.length);

  for (const capabilityKey of SKILL_FAMILY_CAPABILITY_KEYS) {
    const capabilityPackage = catalog.find(
      (entry) => entry.manifest.capabilityKey === capabilityKey,
    );

    assert.equal(isSkillFamilyCapabilityKey(capabilityKey), true);
    assert.equal(capabilityPackage?.manifest.capabilityKey, capabilityKey);
    assert.equal(capabilityPackage?.adapter.adapterId, "rax.skill.adapter");
    assert.equal(capabilityPackage?.adapter.runtimeKind, "rax-skill");
    assert.deepEqual(capabilityPackage?.adapter.supports, [capabilityKey]);
    assert.equal(capabilityPackage?.policy.defaultScope?.allowedOperations?.includes(capabilityKey), true);
    assert.equal(
      capabilityPackage?.manifest.routeHints.some(
        (routeHint) =>
          routeHint.key === "capability_family" && routeHint.value === "skill",
      ),
      true,
    );
    assert.equal(capabilityPackage?.builder.replayCapability, "auto_after_verify");
    assert.equal(capabilityPackage?.metadata?.capabilityFamily, "skill");
  }
});

test("skill.use package keeps the formal shared-runtime defaults", () => {
  const capabilityPackage = createRaxSkillCapabilityPackage({
    capabilityKey: "skill.use",
  });

  assert.equal(capabilityPackage.policy.reviewRequirements[0], "allow_with_constraints");
  assert.equal(
    capabilityPackage.policy.safetyFlags.includes("source_or_reference_resolution"),
    true,
  );
  assert.equal(capabilityPackage.activationSpec?.adapterFactoryRef, "factory:rax.skill:use");
  assert.equal(
    capabilityPackage.usage.exampleInvocations[0]?.operation,
    "skill.use",
  );
});

test("skill family validation rejects packages that drift away from the shared skill adapter contract", () => {
  const capabilityPackage = createRaxSkillCapabilityPackage({
    capabilityKey: "skill.mount",
  });

  capabilityPackage.policy.defaultScope = {
    allowedOperations: ["read"],
    providerHints: ["openai", "anthropic", "deepmind"],
  };

  assert.throws(
    () => validateCapabilityPackage(capabilityPackage),
    /must allow skill\.mount in policy\.defaultScope/i,
  );
});

test("skill family factory rejects unsupported capability keys", () => {
  assert.throws(
    () =>
      createRaxSkillCapabilityPackage({
        capabilityKey: "skill.list" as never,
      }),
    /Unsupported skill family capability package key/i,
  );
});
