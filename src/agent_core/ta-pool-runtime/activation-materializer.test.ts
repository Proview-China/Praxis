import assert from "node:assert/strict";
import test from "node:test";

import { createCapabilityPackageFixture } from "../capability-package/index.js";
import type { CapabilityAdapter } from "../capability-types/index.js";
import { createActivationFactoryResolver } from "./activation-factory-resolver.js";
import {
  materializeActivationRegistration,
  materializeCapabilityManifestFromActivation,
  materializeProvisionAssetActivation,
} from "./activation-materializer.js";

function createTestAdapter(): CapabilityAdapter {
  return {
    id: "adapter.playwright",
    runtimeKind: "mcp",
    supports() {
      return true;
    },
    async prepare(plan, lease) {
      return {
        preparedId: `${plan.planId}:prepared`,
        leaseId: lease.leaseId,
        capabilityKey: plan.capabilityKey,
        bindingId: lease.bindingId,
        generation: lease.generation,
        executionMode: "direct",
      };
    },
    async execute(prepared) {
      return {
        executionId: `${prepared.preparedId}:execution`,
        resultId: `${prepared.preparedId}:result`,
        status: "success",
        completedAt: "2026-03-19T13:00:00.000Z",
      };
    },
  };
}

function createAsset() {
  return {
    assetId: "asset-1",
    provisionId: "provision-1",
    bundleId: "bundle-1",
    capabilityKey: "mcp.playwright",
    status: "ready_for_review" as const,
    toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tool:mcp.playwright" },
    bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:mcp.playwright" },
    verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "verify:mcp.playwright" },
    usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "usage:mcp.playwright" },
    activation: {
      bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:mcp.playwright" },
      bindingArtifactRef: "binding:mcp.playwright",
      targetPool: "ta-capability-pool",
      adapterFactoryRef: "factory:playwright",
      spec: {
        targetPool: "ta-capability-pool",
        activationMode: "activate_after_verify" as const,
        registerOrReplace: "register_or_replace" as const,
        generationStrategy: "create_next_generation" as const,
        drainStrategy: "graceful" as const,
        manifestPayload: {
          capabilityKey: "mcp.playwright",
          capabilityId: "capability:mcp.playwright:1",
          version: "1.0.0",
          generation: 1,
          kind: "tool",
          description: "Playwright MCP capability",
        },
        bindingPayload: {
          adapterId: "adapter.playwright",
          runtimeKind: "mcp",
        },
        adapterFactoryRef: "factory:playwright",
      },
    },
    replayPolicy: "re_review_then_dispatch" as const,
    createdAt: "2026-03-19T13:00:00.000Z",
    updatedAt: "2026-03-19T13:00:00.000Z",
  };
}

test("activation factory resolver registers and materializes adapter factories", async () => {
  const resolver = createActivationFactoryResolver();
  const asset = createAsset();
  const materialized = materializeProvisionAssetActivation({ asset });

  resolver.register("factory:playwright", ({ materialized }) => {
    assert.equal(materialized?.bindingPayload.adapterId, "adapter.playwright");
    assert.equal(materialized?.manifest.capabilityKey, asset.capabilityKey);
    return createTestAdapter();
  });

  const adapter = await resolver.materialize({
    asset,
    materialized,
    activationSpec: asset.activation.spec,
    manifest: materialized.manifest,
    bindingPayload: materialized.bindingPayload,
  });

  assert.equal(adapter.id, "adapter.playwright");
  assert.equal(resolver.has("factory:playwright"), true);
});

test("activation materializer turns provision asset activation spec into pool registration input", async () => {
  const asset = createAsset();
  const resolver = createActivationFactoryResolver();
  resolver.register("factory:playwright", () => createTestAdapter());

  const materialized = materializeProvisionAssetActivation({ asset });
  const adapter = await resolver.materialize({
    asset,
    materialized,
    activationSpec: asset.activation.spec,
    manifest: materialized.manifest,
    bindingPayload: materialized.bindingPayload,
  });

  assert.equal(materialized.targetPool, "ta-capability-pool");
  assert.equal(materialized.registrationStrategy, "register_or_replace");
  assert.match(materialized.manifest.capabilityId, /^capability:mcp\.playwright(?::1)?$/);
  assert.equal(materialized.manifest.capabilityKey, "mcp.playwright");
  assert.equal(adapter.id, "adapter.playwright");
  assert.equal(materialized.bindingPayload.adapterId, "adapter.playwright");
});

test("activation materializer can build a package-backed registration", async () => {
  const capabilityPackage = createCapabilityPackageFixture({
    capabilityKey: "mcp.playwright",
  });
  const resolver = createActivationFactoryResolver();
  resolver.register("factory:playwright", () => createTestAdapter());

  const materialized = await materializeActivationRegistration({
    capabilityPackage,
    factoryResolver: resolver,
    capabilityIdPrefix: "capability",
  });

  assert.match(materialized.manifest.capabilityId, /^capability:mcp\.playwright(?::1)?$/);
  assert.equal(materialized.adapter.id, "adapter.playwright");
  assert.equal(materialized.targetPool, capabilityPackage.activationSpec?.targetPool);
});

test("activation materializer rejects mismatched capability keys between package and activation spec", () => {
  const capabilityPackage = createCapabilityPackageFixture({
    capabilityKey: "mcp.playwright",
    activationSpec: {
      targetPool: "ta-capability-pool",
      activationMode: "activate_after_verify",
      registerOrReplace: "register_or_replace",
      generationStrategy: "create_next_generation",
      drainStrategy: "graceful",
      manifestPayload: {
        capabilityKey: "shell.exec",
        capabilityId: "capability:shell.exec:1",
        version: "1.0.0",
        generation: 1,
        kind: "tool",
        description: "mismatch",
      },
      bindingPayload: {
        adapterId: "adapter.playwright",
        runtimeKind: "mcp",
      },
      adapterFactoryRef: "factory:playwright",
    },
  });

  assert.throws(
    () => materializeCapabilityManifestFromActivation({
      capabilityPackage,
      activationSpec: capabilityPackage.activationSpec!,
    }),
    /does not match capability package/i,
  );
});
