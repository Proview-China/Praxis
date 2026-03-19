import assert from "node:assert/strict";
import test from "node:test";

import type { CapabilityAdapter, CapabilityInvocationPlan } from "../capability-types/index.js";
import { CapabilityPoolRegistry } from "../capability-pool/pool-registry.js";
import { createPoolActivationSpec } from "../ta-pool-types/index.js";
import { createActivationFactoryResolver } from "./activation-factory-resolver.js";
import { activateProvisionAsset } from "./activation-driver.js";
import { materializeProvisionAssetActivation } from "./activation-materializer.js";

function createAdapter(id: string): CapabilityAdapter {
  return {
    id,
    runtimeKind: "tool",
    supports(_plan: CapabilityInvocationPlan) {
      return true;
    },
    async prepare(plan, lease) {
      return {
        preparedId: `${id}:prepared`,
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
        output: {
          ok: true,
        },
        completedAt: "2026-03-19T13:00:02.000Z",
      };
    },
  };
}

function createAsset() {
  const activationSpec = createPoolActivationSpec({
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registerOrReplace: "register_or_replace",
    generationStrategy: "create_next_generation",
    drainStrategy: "graceful",
    manifestPayload: {
      capabilityKey: "computer.use",
      capabilityId: "capability.computer.use",
      version: "1.0.0",
      generation: 1,
      description: "Computer use capability",
      kind: "tool",
    },
    bindingPayload: {
      adapterId: "adapter.computer.use",
      runtimeKind: "tool",
    },
    adapterFactoryRef: "factory:computer.use",
  });

  return {
    assetId: "asset-1",
    provisionId: "provision-1",
    bundleId: "bundle-1",
    capabilityKey: "computer.use",
    status: "ready_for_review" as const,
    toolArtifact: { artifactId: "tool-1", kind: "tool", ref: "tool:computer.use" },
    bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:computer.use" },
    verificationArtifact: { artifactId: "verification-1", kind: "verification", ref: "verification:computer.use" },
    usageArtifact: { artifactId: "usage-1", kind: "usage", ref: "usage:computer.use" },
    activation: {
      bindingArtifact: { artifactId: "binding-1", kind: "binding", ref: "binding:computer.use" },
      bindingArtifactRef: "binding:computer.use",
      targetPool: "ta-capability-pool",
      adapterFactoryRef: "factory:computer.use",
      spec: activationSpec,
    },
    replayPolicy: "re_review_then_dispatch" as const,
    createdAt: "2026-03-19T13:00:00.000Z",
    updatedAt: "2026-03-19T13:00:00.000Z",
  };
}

test("activation driver registers a ready asset into the capability pool registry", async () => {
  const asset = createAsset();
  const registry = new CapabilityPoolRegistry();
  const factories = createActivationFactoryResolver();
  factories.register("factory:computer.use", () => createAdapter("adapter.computer.use"));

  const result = await activateProvisionAsset({
    asset,
    materialized: materializeProvisionAssetActivation({ asset }),
    poolRegistry: registry,
    factoryResolver: factories,
    clock: () => new Date("2026-03-19T13:00:01.000Z"),
    idFactory: () => "attempt-1",
  });

  assert.equal(result.status, "activated");
  assert.equal(result.asset.status, "active");
  assert.equal(result.receipt.bindingId, result.binding.bindingId);
  assert.equal(registry.getActiveRegistrationsForCapability("computer.use").length, 1);
  assert.equal(result.adapter.id, "adapter.computer.use");
});

test("activation driver uses replace semantics when an active binding already exists", async () => {
  const asset = createAsset();
  const registry = new CapabilityPoolRegistry();
  const factories = createActivationFactoryResolver();
  factories.register("factory:computer.use", () => createAdapter("adapter.computer.use"));

  registry.register({
    capabilityId: "capability.computer.use",
    capabilityKey: "computer.use",
    kind: "tool",
    version: "0.9.0",
    generation: 1,
    description: "old computer use capability",
  }, createAdapter("adapter.old"));

  const result = await activateProvisionAsset({
    asset,
    materialized: materializeProvisionAssetActivation({ asset }),
    poolRegistry: registry,
    factoryResolver: factories,
    clock: () => new Date("2026-03-19T13:10:01.000Z"),
    idFactory: () => "attempt-2",
  });

  assert.equal(result.status, "activated");
  assert.equal(result.binding.generation, 2);
  assert.equal(registry.getActiveRegistrationsForCapability("computer.use").length, 1);
});

test("activation driver fails cleanly when no adapter factory is registered", async () => {
  const asset = createAsset();
  const registry = new CapabilityPoolRegistry();
  const factories = createActivationFactoryResolver();

  const result = await activateProvisionAsset({
    asset,
    materialized: materializeProvisionAssetActivation({ asset }),
    poolRegistry: registry,
    factoryResolver: factories,
    clock: () => new Date("2026-03-19T13:20:01.000Z"),
    idFactory: () => "attempt-3",
  });

  assert.equal(result.status, "failed");
  assert.equal(result.asset.status, "failed");
  assert.match(result.failure.message, /No activation adapter factory/i);
});
