import assert from "node:assert/strict";
import test from "node:test";

import {
  createCapabilityPackage,
  createCapabilityPackageActivationSpecRef,
  createCapabilityPackageFixture,
  createCapabilityPackageFromProvisionBundle,
  createMcpCapabilityPackage,
} from "./index.js";
import { createPoolActivationSpec, createProvisionArtifactBundle } from "../ta-pool-types/index.js";

test("capability package fixture satisfies the frozen seven-part template", () => {
  const capabilityPackage = createCapabilityPackageFixture({
    capabilityKey: "mcp.playwright",
    replayPolicy: "auto_after_verify",
  });

  assert.equal(capabilityPackage.templateVersion, "tap-capability-package.v1");
  assert.equal(capabilityPackage.manifest.capabilityKey, "mcp.playwright");
  assert.equal(capabilityPackage.builder.replayCapability, "auto_after_verify");
  assert.equal(capabilityPackage.replayPolicy, "auto_after_verify");
  assert.equal(capabilityPackage.activationSpec?.targetPool, "ta-capability-pool");
  assert.equal(capabilityPackage.usage.exampleInvocations.length, 1);
});

test("capability package can be created directly from a ready provision bundle", () => {
  const activationSpec = createPoolActivationSpec({
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registerOrReplace: "register_or_replace",
    generationStrategy: "create_next_generation",
    drainStrategy: "graceful",
    manifestPayload: {
      capabilityKey: "mcp.playwright",
      version: "1.0.0",
    },
    bindingPayload: {
      adapterId: "adapter.playwright",
      runtimeKind: "mcp",
    },
    adapterFactoryRef: "factory:playwright",
  });
  const bundle = createProvisionArtifactBundle({
    bundleId: "bundle.playwright",
    provisionId: "provision.playwright",
    status: "ready",
    toolArtifact: { artifactId: "tool.playwright", kind: "tool", ref: "tool:playwright" },
    bindingArtifact: {
      artifactId: "binding.playwright",
      kind: "binding",
      ref: "binding:playwright",
    },
    verificationArtifact: {
      artifactId: "verification.playwright",
      kind: "verification",
      ref: "verification:playwright",
    },
    usageArtifact: { artifactId: "usage.playwright", kind: "usage", ref: "usage:playwright" },
    activationSpec,
    replayPolicy: "manual",
  });

  const capabilityPackage = createCapabilityPackageFromProvisionBundle({
    bundle,
    manifest: {
      capabilityKey: "mcp.playwright",
      capabilityKind: "tool",
      description: "Provisioned browser capability.",
      supportedPlatforms: ["linux"],
    },
    adapter: {
      adapterId: "adapter.playwright",
      runtimeKind: "mcp",
      supports: ["open_browser"],
      prepare: { ref: "adapter.prepare:playwright" },
      execute: { ref: "adapter.execute:playwright" },
    },
    policy: {
      defaultBaseline: {
        grantedTier: "B2",
        mode: "balanced",
      },
      recommendedMode: "standard",
      riskLevel: "risky",
      reviewRequirements: ["allow_with_constraints"],
    },
    builder: {
      builderId: "builder.playwright",
      buildStrategy: "install-and-register",
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: "manual",
    },
    verification: {
      smokeEntry: "smoke:mcp:playwright",
      healthEntry: "health:mcp:playwright",
    },
    usage: {
      usageDocRef: "docs/ability/25-tap-capability-package-template.md",
      exampleInvocations: [
        {
          exampleId: "example.playwright.open",
          capabilityKey: "mcp.playwright",
          operation: "open_browser",
        },
      ],
    },
    lifecycle: {
      installStrategy: "install into user space",
      replaceStrategy: "register_or_replace",
      rollbackStrategy: "restore previous binding",
      deprecateStrategy: "freeze new registrations before removal",
      cleanupStrategy: "cleanup old artifacts after drain",
    },
  });

  assert.equal(capabilityPackage.replayPolicy, "manual");
  assert.equal(capabilityPackage.artifacts?.bindingArtifact.ref, "binding:playwright");
  assert.equal(
    capabilityPackage.builder.activationSpecRef,
    "activation-spec:ta-capability-pool:activate_after_verify:factory:playwright",
  );
});

test("capability package validation rejects replay policy drift between builder and package", () => {
  assert.throws(
    () =>
      createCapabilityPackage({
        manifest: {
          capabilityKey: "mcp.playwright",
          capabilityKind: "tool",
          description: "Provisioned browser capability.",
          supportedPlatforms: ["linux"],
        },
        adapter: {
          adapterId: "adapter.playwright",
          runtimeKind: "mcp",
          supports: ["open_browser"],
          prepare: { ref: "adapter.prepare:playwright" },
          execute: { ref: "adapter.execute:playwright" },
        },
        policy: {
          defaultBaseline: {
            grantedTier: "B2",
            mode: "balanced",
          },
          recommendedMode: "standard",
          riskLevel: "risky",
          reviewRequirements: ["allow_with_constraints"],
        },
        builder: {
          builderId: "builder.playwright",
          buildStrategy: "install-and-register",
          activationSpecRef: "activation-spec:playwright",
          replayCapability: "manual",
        },
        verification: {
          smokeEntry: "smoke:mcp:playwright",
          healthEntry: "health:mcp:playwright",
        },
        usage: {
          usageDocRef: "docs/ability/25-tap-capability-package-template.md",
          exampleInvocations: [
            {
              exampleId: "example.playwright.open",
              capabilityKey: "mcp.playwright",
              operation: "open_browser",
            },
          ],
        },
        lifecycle: {
          installStrategy: "install into user space",
          replaceStrategy: "register_or_replace",
          rollbackStrategy: "restore previous binding",
          deprecateStrategy: "freeze new registrations before removal",
          cleanupStrategy: "cleanup old artifacts after drain",
        },
        replayPolicy: "auto_after_verify",
      }),
    /replayPolicy must match builder\.replayCapability/,
  );
});

test("capability package factory builds thick MCP call and native execute packages with frozen policy metadata", () => {
  const mcpCallPackage = createMcpCapabilityPackage({
    capabilityKey: "mcp.call",
  });
  const nativeExecutePackage = createMcpCapabilityPackage({
    capabilityKey: "mcp.native.execute",
  });

  assert.equal(mcpCallPackage.policy.riskLevel, "risky");
  assert.equal(mcpCallPackage.policy.recommendedMode, "standard");
  assert.equal(
    mcpCallPackage.policy.defaultScope?.denyPatterns?.includes("mcp.configure"),
    true,
  );
  assert.equal(nativeExecutePackage.policy.recommendedMode, "restricted");
  assert.equal(
    nativeExecutePackage.policy.humanGateRequirements[0],
    "operator_review_required_before_native_transport_execution",
  );
});

test("capability package validation rejects MCP packages that reopen mcp.configure or weaken native execute policy", () => {
  assert.throws(
    () =>
      createCapabilityPackage({
        manifest: {
          capabilityKey: "mcp.call",
          capabilityKind: "tool",
          description: "Invalid MCP call package.",
          supportedPlatforms: ["linux"],
        },
        adapter: {
          adapterId: "adapter.invalid-mcp-call",
          runtimeKind: "rax-mcp",
          supports: ["mcp.call"],
          prepare: { ref: "adapter.prepare:invalid" },
          execute: { ref: "adapter.execute:invalid" },
        },
        policy: {
          defaultBaseline: {
            grantedTier: "B1",
            mode: "standard",
            scope: {
              pathPatterns: ["workspace/**"],
              allowedOperations: ["mcp.call"],
            },
          },
          recommendedMode: "standard",
          riskLevel: "risky",
          defaultScope: {
            pathPatterns: ["workspace/**"],
            allowedOperations: ["mcp.call"],
          },
          reviewRequirements: ["allow_with_constraints"],
          safetyFlags: ["truthful_shared_runtime_surface"],
          humanGateRequirements: ["manual review"],
        },
        builder: {
          builderId: "builder.invalid-mcp-call",
          buildStrategy: "invalid",
          activationSpecRef: "activation-spec:tap:activate_after_verify:factory:invalid",
        },
        verification: {
          smokeEntry: "smoke:invalid",
          healthEntry: "health:invalid",
        },
        usage: {
          usageDocRef: "docs/ability/25-tap-capability-package-template.md",
          exampleInvocations: [
            {
              exampleId: "example.invalid-mcp-call",
              capabilityKey: "mcp.call",
              operation: "mcp.call",
            },
          ],
        },
        lifecycle: {
          installStrategy: "invalid",
          replaceStrategy: "invalid",
          rollbackStrategy: "invalid",
          deprecateStrategy: "invalid",
          cleanupStrategy: "invalid",
        },
      }),
    /must deny mcp\.configure/i,
  );

  assert.throws(
    () =>
      createCapabilityPackage({
        manifest: {
          capabilityKey: "mcp.native.execute",
          capabilityKind: "tool",
          description: "Invalid native execute package.",
          supportedPlatforms: ["linux"],
        },
        adapter: {
          adapterId: "adapter.invalid-mcp-native",
          runtimeKind: "rax-mcp",
          supports: ["mcp.native.execute"],
          prepare: { ref: "adapter.prepare:invalid-native" },
          execute: { ref: "adapter.execute:invalid-native" },
        },
        policy: {
          defaultBaseline: {
            grantedTier: "B2",
            mode: "standard",
            scope: {
              pathPatterns: ["workspace/**"],
              allowedOperations: ["mcp.native.execute"],
              denyPatterns: ["mcp.configure"],
            },
          },
          recommendedMode: "standard",
          riskLevel: "risky",
          defaultScope: {
            pathPatterns: ["workspace/**"],
            allowedOperations: ["mcp.native.execute"],
            denyPatterns: ["mcp.configure"],
          },
          reviewRequirements: ["escalate_to_human"],
          safetyFlags: ["native_transport_side_effects", "no_mcp_configure"],
          humanGateRequirements: [],
        },
        builder: {
          builderId: "builder.invalid-mcp-native",
          buildStrategy: "invalid",
          activationSpecRef: "activation-spec:tap:activate_after_verify:factory:invalid-native",
        },
        verification: {
          smokeEntry: "smoke:invalid-native",
          healthEntry: "health:invalid-native",
        },
        usage: {
          usageDocRef: "docs/ability/25-tap-capability-package-template.md",
          exampleInvocations: [
            {
              exampleId: "example.invalid-mcp-native",
              capabilityKey: "mcp.native.execute",
              operation: "mcp.native.execute",
            },
          ],
        },
        lifecycle: {
          installStrategy: "invalid",
          replaceStrategy: "invalid",
          rollbackStrategy: "invalid",
          deprecateStrategy: "invalid",
          cleanupStrategy: "invalid",
        },
      }),
    /must recommend restricted mode/i,
  );

  assert.throws(
    () =>
      createCapabilityPackage({
        manifest: {
          capabilityKey: "mcp.configure",
          capabilityKind: "tool",
          description: "Forbidden configure surface.",
          supportedPlatforms: ["linux"],
        },
        adapter: {
          adapterId: "adapter.mcp-configure",
          runtimeKind: "rax-mcp",
          supports: ["mcp.configure"],
          prepare: { ref: "adapter.prepare:mcp-configure" },
          execute: { ref: "adapter.execute:mcp-configure" },
        },
        policy: {
          defaultBaseline: {
            grantedTier: "B2",
            mode: "restricted",
            scope: {
              pathPatterns: ["workspace/**"],
              allowedOperations: ["mcp.configure"],
              denyPatterns: ["mcp.configure"],
            },
          },
          recommendedMode: "restricted",
          riskLevel: "dangerous",
          defaultScope: {
            pathPatterns: ["workspace/**"],
            allowedOperations: ["mcp.configure"],
            denyPatterns: ["mcp.configure"],
          },
          reviewRequirements: ["escalate_to_human"],
          safetyFlags: ["no_mcp_configure"],
          humanGateRequirements: ["human approval"],
        },
        builder: {
          builderId: "builder.mcp-configure",
          buildStrategy: "invalid",
          activationSpecRef: "activation-spec:tap:activate_after_verify:factory:mcp-configure",
        },
        verification: {
          smokeEntry: "smoke:mcp-configure",
          healthEntry: "health:mcp-configure",
        },
        usage: {
          usageDocRef: "docs/ability/25-tap-capability-package-template.md",
          exampleInvocations: [
            {
              exampleId: "example.mcp-configure",
              capabilityKey: "mcp.configure",
              operation: "mcp.configure",
            },
          ],
        },
        lifecycle: {
          installStrategy: "invalid",
          replaceStrategy: "invalid",
          rollbackStrategy: "invalid",
          deprecateStrategy: "invalid",
          cleanupStrategy: "invalid",
        },
      }),
    /must remain outside first-class TAP capability packages/i,
  );
});
