import { randomUUID } from "node:crypto";

import {
  createPoolActivationSpec,
  createProvisionArtifactBundle,
  type ProvisionArtifactBundle,
  type ProvisionArtifactRef,
  type ProvisionRequest,
} from "../ta-pool-types/index.js";
import { ProvisionAssetIndex } from "./provision-asset-index.js";
import {
  createDefaultProvisionerWorkerOutput,
  createProvisionerWorkerBridgeInput,
  defaultProvisionerWorkerBridge,
  validateProvisionerWorkerOutput,
  type ProvisionerWorkerBridge,
} from "./provisioner-worker-bridge.js";
import { ProvisionRegistry } from "./provision-registry.js";

export interface ProvisionBuildArtifacts {
  toolArtifact: ProvisionArtifactRef;
  bindingArtifact: ProvisionArtifactRef;
  verificationArtifact: ProvisionArtifactRef;
  usageArtifact: ProvisionArtifactRef;
  metadata?: Record<string, unknown>;
}

export interface ProvisionerRuntimeOptions {
  registry?: ProvisionRegistry;
  assetIndex?: ProvisionAssetIndex;
  workerBridge?: ProvisionerWorkerBridge;
  builder?: (request: ProvisionRequest) => Promise<ProvisionBuildArtifacts>;
  clock?: () => Date;
  idFactory?: () => string;
}

export interface ProvisionerRuntimeLike {
  submit(request: ProvisionRequest): Promise<ProvisionArtifactBundle>;
  getBundleHistory(provisionId: string): readonly ProvisionArtifactBundle[];
}

function defaultMockBuilder(request: ProvisionRequest): Promise<ProvisionBuildArtifacts> {
  const capabilityKey = request.requestedCapabilityKey;
  return Promise.resolve({
    toolArtifact: {
      artifactId: `${capabilityKey}:tool`,
      kind: "tool",
      ref: `mock-tools/${capabilityKey}`,
    },
    bindingArtifact: {
      artifactId: `${capabilityKey}:binding`,
      kind: "binding",
      ref: `mock-bindings/${capabilityKey}`,
    },
    verificationArtifact: {
      artifactId: `${capabilityKey}:verification`,
      kind: "verification",
      ref: `mock-smoke/${capabilityKey}`,
    },
    usageArtifact: {
      artifactId: `${capabilityKey}:usage`,
      kind: "usage",
      ref: `mock-usage/${capabilityKey}.md`,
    },
    metadata: {
      builder: "mock",
    },
  });
}

function adaptLegacyBuilder(
  builder: (request: ProvisionRequest) => Promise<ProvisionBuildArtifacts>,
): ProvisionerWorkerBridge {
  return async (input) => {
    const artifacts = await builder(input.request);
    const defaultOutput = createDefaultProvisionerWorkerOutput(input);
    return {
      ...defaultOutput,
      toolArtifact: artifacts.toolArtifact,
      bindingArtifact: artifacts.bindingArtifact,
      verificationArtifact: artifacts.verificationArtifact,
      usageArtifact: artifacts.usageArtifact,
      metadata: {
        ...(defaultOutput.metadata ?? {}),
        ...(artifacts.metadata ?? {}),
        bridgeImplementation: "legacy-builder-adapter",
      },
    };
  };
}

export class ProvisionerRuntime implements ProvisionerRuntimeLike {
  readonly registry: ProvisionRegistry;
  readonly assetIndex: ProvisionAssetIndex;
  readonly #workerBridge: ProvisionerWorkerBridge;
  readonly #clock: () => Date;
  readonly #idFactory: () => string;
  readonly #bundleHistory = new Map<string, ProvisionArtifactBundle[]>();

  constructor(options: ProvisionerRuntimeOptions = {}) {
    this.registry = options.registry ?? new ProvisionRegistry();
    this.assetIndex = options.assetIndex ?? new ProvisionAssetIndex();
    this.#workerBridge = options.workerBridge
      ?? (options.builder ? adaptLegacyBuilder(options.builder) : defaultProvisionerWorkerBridge);
    this.#clock = options.clock ?? (() => new Date());
    this.#idFactory = options.idFactory ?? randomUUID;
  }

  async submit(request: ProvisionRequest): Promise<ProvisionArtifactBundle> {
    this.registry.registerRequest(request);

    const buildingBundle = createProvisionArtifactBundle({
      bundleId: this.#idFactory(),
      provisionId: request.provisionId,
      status: "building",
      metadata: {
        source: "provisioner-runtime",
        requestedCapabilityKey: request.requestedCapabilityKey,
      },
    });
    this.#recordBundle(buildingBundle);

    try {
      const bridgeInput = createProvisionerWorkerBridgeInput(request);
      const output = await this.#workerBridge(bridgeInput);
      validateProvisionerWorkerOutput(output);
      const readyBundle = createProvisionArtifactBundle({
        bundleId: this.#idFactory(),
        provisionId: request.provisionId,
        status: "ready",
        toolArtifact: output.toolArtifact,
        bindingArtifact: output.bindingArtifact,
        verificationArtifact: output.verificationArtifact,
        usageArtifact: output.usageArtifact,
        activationSpec: createPoolActivationSpec(output.activationPayload),
        replayPolicy: output.replayRecommendation.policy,
        completedAt: this.#clock().toISOString(),
        metadata: {
          source: "provisioner-runtime",
          buildSummary: output.buildSummary,
          workerBridge: true,
          workerLane: bridgeInput.lane,
          workerPromptPackId: bridgeInput.promptPack.promptPackId,
          replayRecommendation: output.replayRecommendation,
          ...(output.metadata ?? {}),
        },
      });
      this.#recordBundle(readyBundle);
      return readyBundle;
    } catch (error) {
      const failedBundle = createProvisionArtifactBundle({
        bundleId: this.#idFactory(),
        provisionId: request.provisionId,
        status: "failed",
        completedAt: this.#clock().toISOString(),
        error: {
          code: "ta_pool_provision_build_failed",
          message: error instanceof Error ? error.message : String(error),
        },
        metadata: {
          source: "provisioner-runtime",
          requestedCapabilityKey: request.requestedCapabilityKey,
        },
      });
      this.#recordBundle(failedBundle);
      return failedBundle;
    }
  }

  getBundleHistory(provisionId: string): readonly ProvisionArtifactBundle[] {
    return this.#bundleHistory.get(provisionId) ?? [];
  }

  #recordBundle(bundle: ProvisionArtifactBundle): void {
    const history = this.#bundleHistory.get(bundle.provisionId) ?? [];
    history.push(bundle);
    this.#bundleHistory.set(bundle.provisionId, history);
    this.registry.attachBundle(bundle);
    const record = this.registry.get(bundle.provisionId);
    if (record) {
      this.assetIndex.ingest(record);
    }
  }
}

export function createProvisionerRuntime(
  options: ProvisionerRuntimeOptions = {},
): ProvisionerRuntime {
  return new ProvisionerRuntime(options);
}
