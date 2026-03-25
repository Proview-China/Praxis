import { randomUUID } from "node:crypto";

import type { CapabilityAdapter, CapabilityInvocationPlan, CapabilityLease, CapabilityResultEnvelope, PreparedCapabilityCall } from "../capability-types/index.js";
import type { ProviderId, SdkLayer } from "../../rax/types.js";
import type {
  McpCallInput,
  McpCallResult,
  McpListToolsInput,
  McpListToolsResult,
  McpReadResourceInput,
  McpReadResourceResult,
  McpConnectInput,
  McpInMemoryTransportConfig,
  McpStdioTransportConfig,
  McpStreamableHttpTransportConfig,
} from "../../rax/mcp-types.js";
import type { RaxFacade } from "../../rax/facade.js";
import { rax } from "../../rax/index.js";
import { createPreparedCapabilityCall } from "../capability-invocation/index.js";
import {
  createMcpCapabilityPackage,
  isSupportedMcpCapabilityPackageKey,
  type SupportedMcpCapabilityPackageKey,
} from "../capability-package/index.js";
import { createCapabilityResultEnvelope } from "../capability-result/index.js";

type SupportedMcpAction =
  | "mcp.call"
  | "mcp.listTools"
  | "mcp.readResource"
  | "mcp.native.execute";

interface McpRouteSelection {
  provider: ProviderId;
  model: string;
  layer?: SdkLayer;
  variant?: string;
  compatibilityProfileId?: string;
}

interface McpActionPayloadMap {
  "mcp.call": McpCallInput;
  "mcp.listTools": McpListToolsInput;
  "mcp.readResource": McpReadResourceInput;
  "mcp.native.execute": McpConnectInput;
}

type SupportedMcpPreparedPayload = {
  action: SupportedMcpAction;
  route: McpRouteSelection;
  input: McpCallInput | McpListToolsInput | McpReadResourceInput | McpConnectInput;
  invocation?: Awaited<ReturnType<RaxFacade["mcp"]["native"]["build"]>>;
};

const DEFAULT_MCP_CAPABILITY_PACKAGES = new Map(
  (["mcp.call", "mcp.native.execute"] as const).map((capabilityKey) => [
    capabilityKey,
    createMcpCapabilityPackage({ capabilityKey }),
  ]),
);

export interface RaxMcpAdapterPlanInput<TAction extends SupportedMcpAction = SupportedMcpAction> {
  route: McpRouteSelection;
  input: McpActionPayloadMap[TAction];
}

export interface CreateRaxMcpCapabilityAdapterOptions {
  facade?: Pick<RaxFacade, "mcp">;
}

export interface CreateRaxMcpCapabilityManifestOptions {
  capabilityKey: SupportedMcpCapabilityPackageKey;
  capabilityId?: string;
  version?: string;
  generation?: number;
  description?: string;
  metadata?: Record<string, unknown>;
}

function isSupportedAction(action: string): action is SupportedMcpAction {
  return (
    action === "mcp.call" ||
    action === "mcp.listTools" ||
    action === "mcp.readResource" ||
    action === "mcp.native.execute"
  );
}

function asObject(value: unknown): Record<string, unknown> | undefined {
  if (!value || Array.isArray(value) || typeof value !== "object") {
    return undefined;
  }
  return value as Record<string, unknown>;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function asStringRecord(
  value: unknown,
): Record<string, string> | undefined {
  const record = asObject(value);
  if (!record) {
    return undefined;
  }

  return Object.fromEntries(
    Object.entries(record).filter((entry): entry is [string, string] => {
      return typeof entry[1] === "string";
    }),
  );
}

function asArrayOfStrings(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) {
    return undefined;
  }

  return value.filter((entry): entry is string => typeof entry === "string");
}

function getCapabilityPackageMetadata(
  action: SupportedMcpAction,
): Record<string, unknown> | undefined {
  if (!isSupportedMcpCapabilityPackageKey(action)) {
    return undefined;
  }

  const capabilityPackage = DEFAULT_MCP_CAPABILITY_PACKAGES.get(action);
  if (!capabilityPackage) {
    return undefined;
  }

  return {
    capabilityPackageKey: capabilityPackage.manifest.capabilityKey,
    capabilityPackageVersion: capabilityPackage.manifest.version,
    recommendedMode: capabilityPackage.policy.recommendedMode,
    riskLevel: capabilityPackage.policy.riskLevel,
    reviewRequirements: capabilityPackage.policy.reviewRequirements,
    humanGateRequirements: capabilityPackage.policy.humanGateRequirements,
  };
}

function parseRouteSelection(input: Record<string, unknown>): McpRouteSelection {
  const route = asObject(input.route);
  const provider = asString(route?.provider) as ProviderId | undefined;
  const model = asString(route?.model);
  if (!provider) {
    throw new Error("MCP adapter input is missing route.provider.");
  }
  if (!model) {
    throw new Error("MCP adapter input is missing route.model.");
  }

  const layerCandidate = asString(route?.layer);
  const layer: SdkLayer | undefined =
    layerCandidate === "api" || layerCandidate === "agent" || layerCandidate === "auto"
      ? layerCandidate
      : undefined;

  return {
    provider,
    model,
    layer,
    variant: asString(route?.variant),
    compatibilityProfileId: asString(route?.compatibilityProfileId),
  };
}

function parseCallInput(input: Record<string, unknown>): McpCallInput {
  const payload = asObject(input.input);
  const connectionId = asString(payload?.connectionId);
  const toolName = asString(payload?.toolName);
  if (!connectionId) {
    throw new Error("MCP call input is missing connectionId.");
  }
  if (!toolName) {
    throw new Error("MCP call input is missing toolName.");
  }
  return {
    connectionId,
    toolName,
    arguments: asObject(payload?.arguments),
  };
}

function parseListToolsInput(input: Record<string, unknown>): McpListToolsInput {
  const payload = asObject(input.input);
  const connectionId = asString(payload?.connectionId);
  if (!connectionId) {
    throw new Error("MCP listTools input is missing connectionId.");
  }
  return { connectionId };
}

function parseReadResourceInput(input: Record<string, unknown>): McpReadResourceInput {
  const payload = asObject(input.input);
  const connectionId = asString(payload?.connectionId);
  const uri = asString(payload?.uri);
  if (!connectionId) {
    throw new Error("MCP readResource input is missing connectionId.");
  }
  if (!uri) {
    throw new Error("MCP readResource input is missing uri.");
  }
  return { connectionId, uri };
}

function parseNativeExecuteInput(input: Record<string, unknown>): McpConnectInput {
  const payload = asObject(input.input);
  const transport = asObject(payload?.transport);
  const kind = asString(transport?.kind);
  if (!kind || (kind !== "stdio" && kind !== "streamable-http" && kind !== "in-memory")) {
    throw new Error("MCP native.execute input is missing a supported transport.kind.");
  }
  const strategyCandidate = asString(payload?.strategy);
  const strategy = strategyCandidate === "auto"
    || strategyCandidate === "shared-runtime"
    || strategyCandidate === "provider-native"
    ? strategyCandidate
    : undefined;
  const connectionId = asString(payload?.connectionId);
  const metadata = asObject(payload?.metadata);

  switch (kind) {
    case "stdio": {
      const command = asString(transport?.command);
      if (!command) {
        throw new Error("MCP native.execute stdio transport requires a non-empty command.");
      }
      const stdioTransport: McpStdioTransportConfig = {
        kind,
        command,
        args: asArrayOfStrings(transport?.args),
        env: asStringRecord(transport?.env),
        cwd: asString(transport?.cwd),
        stderr: transport?.stderr as McpStdioTransportConfig["stderr"],
      };
      return {
        connectionId,
        strategy,
        metadata,
        transport: stdioTransport,
      };
    }
    case "streamable-http": {
      const url = asString(transport?.url);
      if (!url) {
        throw new Error("MCP native.execute streamable-http transport requires a non-empty url.");
      }
      const streamableHttpTransport: McpStreamableHttpTransportConfig = {
        kind,
        url,
        headers: asStringRecord(transport?.headers),
      };
      return {
        connectionId,
        strategy,
        metadata,
        transport: streamableHttpTransport,
      };
    }
    case "in-memory": {
      if (!transport?.transport || typeof transport.transport !== "object") {
        throw new Error("MCP native.execute in-memory transport requires a transport object.");
      }
      const inMemoryTransport: McpInMemoryTransportConfig = {
        kind,
        transport: transport.transport as McpInMemoryTransportConfig["transport"],
      };
      return {
        connectionId,
        strategy,
        metadata,
        transport: inMemoryTransport,
      };
    }
  }
}

function parsePreparedPayload(action: SupportedMcpAction, input: Record<string, unknown>): SupportedMcpPreparedPayload {
  const route = parseRouteSelection(input);
  switch (action) {
    case "mcp.call":
      return {
        action,
        route,
        input: parseCallInput(input),
      };
    case "mcp.listTools":
      return {
        action,
        route,
        input: parseListToolsInput(input),
      };
    case "mcp.readResource":
      return {
        action,
        route,
        input: parseReadResourceInput(input),
      };
    case "mcp.native.execute":
      return {
        action,
        route,
        input: parseNativeExecuteInput(input),
      };
  }
}

function createFailureEnvelope(params: {
  executionId: string;
  code: string;
  error: unknown;
  metadata?: Record<string, unknown>;
}): CapabilityResultEnvelope {
  return createCapabilityResultEnvelope({
    executionId: params.executionId,
    status: "failed",
    error: {
      code: params.code,
      message: params.error instanceof Error ? params.error.message : String(params.error),
    },
    metadata: params.metadata,
  });
}

function createExecutionMetadata(action: SupportedMcpAction, route: McpRouteSelection, extra?: Record<string, unknown>): Record<string, unknown> {
  return {
    capability: action,
    provider: route.provider,
    model: route.model,
    layer: route.layer,
    ...getCapabilityPackageMetadata(action),
    ...extra,
  };
}

export function createRaxMcpCapabilityManifest(
  options: CreateRaxMcpCapabilityManifestOptions,
) {
  const capabilityPackage = createMcpCapabilityPackage({
    capabilityKey: options.capabilityKey,
    version: options.version,
    generation: options.generation,
  });

  return {
    capabilityId:
      options.capabilityId
      ?? `cap.${options.capabilityKey.replace(/\./g, "-")}`,
    capabilityKey: capabilityPackage.manifest.capabilityKey,
    kind: capabilityPackage.manifest.capabilityKind,
    version: capabilityPackage.manifest.version,
    generation: capabilityPackage.manifest.generation,
    description: options.description ?? capabilityPackage.manifest.description,
    supportsPrepare: true,
    supportsCancellation: options.capabilityKey === "mcp.native.execute",
    routeHints: capabilityPackage.manifest.routeHints,
    tags: capabilityPackage.manifest.tags,
    metadata: {
      ...(options.metadata ?? {}),
      capabilityPackage,
      riskLevel: capabilityPackage.policy.riskLevel,
      recommendedMode: capabilityPackage.policy.recommendedMode,
      truthfulness: capabilityPackage.metadata?.truthfulness,
    },
  };
}

export class RaxMcpCapabilityAdapter implements CapabilityAdapter {
  readonly id = "rax.mcp.adapter";
  readonly runtimeKind = "rax-mcp";
  readonly #facade: Pick<RaxFacade, "mcp">;
  readonly #preparedPayloads = new Map<string, SupportedMcpPreparedPayload>();

  constructor(options: CreateRaxMcpCapabilityAdapterOptions = {}) {
    this.#facade = options.facade ?? rax;
  }

  supports(plan: CapabilityInvocationPlan): boolean {
    return isSupportedAction(plan.capabilityKey);
  }

  async prepare(plan: CapabilityInvocationPlan, lease: CapabilityLease): Promise<PreparedCapabilityCall> {
    if (!this.supports(plan)) {
      throw new Error(`Unsupported MCP capability action: ${plan.capabilityKey}.`);
    }

    const action = plan.capabilityKey as SupportedMcpAction;
    const parsed = parsePreparedPayload(action, plan.input);

    let preparedPayload: SupportedMcpPreparedPayload;
    if (parsed.action === "mcp.native.execute") {
      const invocation = this.#facade.mcp.native.build({
        provider: parsed.route.provider,
        model: parsed.route.model,
        layer: parsed.route.layer,
        variant: parsed.route.variant,
        compatibilityProfileId: parsed.route.compatibilityProfileId,
        input: parsed.input as McpConnectInput,
      });
      preparedPayload = { ...parsed, invocation };
    } else {
      preparedPayload = parsed;
    }

    const prepared = createPreparedCapabilityCall({
      lease,
      capabilityKey: plan.capabilityKey,
      executionMode: parsed.action === "mcp.native.execute" ? "long-running" : "direct",
      preparedPayloadRef: `${this.id}:${plan.planId}`,
      cacheKey: plan.idempotencyKey,
      metadata: {
        ...(plan.metadata ?? {}),
        ...getCapabilityPackageMetadata(parsed.action),
      },
    });
    this.#preparedPayloads.set(prepared.preparedId, preparedPayload);
    return prepared;
  }

  async execute(prepared: PreparedCapabilityCall): Promise<CapabilityResultEnvelope> {
    const payload = this.#preparedPayloads.get(prepared.preparedId);
    if (!payload) {
      return createFailureEnvelope({
        executionId: prepared.preparedId,
        code: "rax_mcp_prepared_payload_missing",
        error: new Error(`Prepared payload ${prepared.preparedId} was not found.`),
      });
    }

    try {
      switch (payload.action) {
        case "mcp.call":
          return this.#executeCall(prepared.preparedId, payload.route, payload.input as McpCallInput);
        case "mcp.listTools":
          return this.#executeListTools(prepared.preparedId, payload.route, payload.input as McpListToolsInput);
        case "mcp.readResource":
          return this.#executeReadResource(prepared.preparedId, payload.route, payload.input as McpReadResourceInput);
        case "mcp.native.execute":
          return this.#executeNative(
            prepared.preparedId,
            payload.route,
            payload.invocation as Awaited<ReturnType<RaxFacade["mcp"]["native"]["build"]>>,
          );
      }
    } catch (error) {
      return createFailureEnvelope({
        executionId: prepared.preparedId,
        code: "rax_mcp_execute_failed",
        error,
        metadata: createExecutionMetadata(payload.action, payload.route),
      });
    }
  }

  async #executeCall(
    executionId: string,
    route: McpRouteSelection,
    input: McpCallInput,
  ): Promise<CapabilityResultEnvelope> {
    const result = await this.#facade.mcp.call({
      provider: route.provider,
      model: route.model,
      layer: route.layer,
      variant: route.variant,
      compatibilityProfileId: route.compatibilityProfileId,
      input,
    });

    return createCapabilityResultEnvelope({
        executionId,
        status: this.#resultStatusFromCallResult(result),
        output: result,
        metadata: createExecutionMetadata("mcp.call", route, {
          connectionId: input.connectionId,
          toolName: input.toolName,
        }),
        error: result.isError
          ? {
              code: "rax_mcp_call_error",
              message: result.errorMessage ?? "MCP call returned isError=true.",
            }
          : undefined,
      });
  }

  async #executeListTools(
    executionId: string,
    route: McpRouteSelection,
    input: McpListToolsInput,
  ): Promise<CapabilityResultEnvelope> {
    const result = await this.#facade.mcp.listTools({
      provider: route.provider,
      model: route.model,
      layer: route.layer,
      variant: route.variant,
      compatibilityProfileId: route.compatibilityProfileId,
      input,
    });

    return createCapabilityResultEnvelope({
      executionId,
      status: "success",
      output: result,
      metadata: createExecutionMetadata("mcp.listTools", route, {
        connectionId: input.connectionId,
        toolCount: result.tools.length,
      }),
    });
  }

  async #executeReadResource(
    executionId: string,
    route: McpRouteSelection,
    input: McpReadResourceInput,
  ): Promise<CapabilityResultEnvelope> {
    const result = await this.#facade.mcp.readResource({
      provider: route.provider,
      model: route.model,
      layer: route.layer,
      variant: route.variant,
      compatibilityProfileId: route.compatibilityProfileId,
      input,
    });

    return createCapabilityResultEnvelope({
      executionId,
      status: "success",
      output: result,
      metadata: createExecutionMetadata("mcp.readResource", route, {
        connectionId: input.connectionId,
        uri: input.uri,
      }),
    });
  }

  async #executeNative(
    executionId: string,
    route: McpRouteSelection,
    invocation: Awaited<ReturnType<RaxFacade["mcp"]["native"]["build"]>>,
  ): Promise<CapabilityResultEnvelope> {
    const result = await this.#facade.mcp.native.execute(invocation);
    return createCapabilityResultEnvelope({
      executionId,
      status: "success",
      output: result,
      metadata: createExecutionMetadata("mcp.native.execute", route, {
        invocationKey: invocation.key,
        adapterId: invocation.adapterId,
      }),
    });
  }

  #resultStatusFromCallResult(result: McpCallResult): CapabilityResultEnvelope["status"] {
    return result.isError ? "failed" : "success";
  }
}

export function createRaxMcpCapabilityAdapter(
  options: CreateRaxMcpCapabilityAdapterOptions = {},
): RaxMcpCapabilityAdapter {
  return new RaxMcpCapabilityAdapter(options);
}
