import type { CapabilityPortBroker, CapabilityPortDefinition } from "../port/index.js";
import type { KernelResult, KernelResultStatus } from "../types/index.js";
import type { ProviderId, SdkLayer, WebSearchCreateInput, WebSearchOutput } from "../../rax/index.js";
import type { RaxFacade } from "../../rax/facade.js";
import { rax } from "../../rax/index.js";

export interface RaxSearchGroundCapabilityInput extends WebSearchCreateInput {
  provider: ProviderId;
  model: string;
  layer?: SdkLayer;
  variant?: string;
  compatibilityProfileId?: string;
  providerOptions?: Partial<Record<ProviderId, Record<string, unknown>>>;
}

export interface RegisterRaxSearchGroundCapabilityOptions {
  broker: CapabilityPortBroker;
  facade?: Pick<RaxFacade, "websearch">;
  capabilityKey?: string;
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

function mapCapabilityStatus(status: string): KernelResultStatus {
  switch (status) {
    case "success":
    case "partial":
    case "failed":
    case "blocked":
    case "timeout":
      return status;
    case "queued":
    case "running":
      return "failed";
    default:
      return "failed";
  }
}

function parseSearchGroundInput(input: Record<string, unknown>): RaxSearchGroundCapabilityInput {
  const provider = asString(input.provider) as ProviderId | undefined;
  const model = asString(input.model);
  const query = asString(input.query);

  if (!provider) {
    throw new Error("search.ground capability input is missing provider.");
  }

  if (!model) {
    throw new Error("search.ground capability input is missing model.");
  }

  if (!query) {
    throw new Error("search.ground capability input is missing query.");
  }

  return {
    provider,
    model,
    query,
    goal: asString(input.goal),
    urls: Array.isArray(input.urls) ? input.urls.filter((item): item is string => typeof item === "string") : undefined,
    allowedDomains: Array.isArray(input.allowedDomains) ? input.allowedDomains.filter((item): item is string => typeof item === "string") : undefined,
    blockedDomains: Array.isArray(input.blockedDomains) ? input.blockedDomains.filter((item): item is string => typeof item === "string") : undefined,
    maxSources: typeof input.maxSources === "number" ? input.maxSources : undefined,
    maxOutputTokens: typeof input.maxOutputTokens === "number" ? input.maxOutputTokens : undefined,
    searchContextSize:
      input.searchContextSize === "low" || input.searchContextSize === "medium" || input.searchContextSize === "high"
        ? input.searchContextSize
        : undefined,
    citations:
      input.citations === "required" || input.citations === "preferred" || input.citations === "off"
        ? input.citations
        : undefined,
    freshness:
      input.freshness === "any" ||
      input.freshness === "day" ||
      input.freshness === "week" ||
      input.freshness === "month" ||
      input.freshness === "year"
        ? input.freshness
        : undefined,
    userLocation: asObject(input.userLocation) as WebSearchCreateInput["userLocation"] | undefined,
    layer:
      input.layer === "api" || input.layer === "agent" || input.layer === "auto"
        ? input.layer
        : undefined,
    variant: asString(input.variant),
    compatibilityProfileId: asString(input.compatibilityProfileId),
    providerOptions: asObject(input.providerOptions) as RaxSearchGroundCapabilityInput["providerOptions"] | undefined,
  };
}

function toKernelResult(params: {
  requestId: string;
  sessionId: string;
  runId: string;
  capabilityResult: {
    status: string;
    output?: WebSearchOutput;
    evidence?: unknown[];
    error?: unknown;
    provider: ProviderId;
    model: string;
    layer: Exclude<SdkLayer, "auto">;
  };
}): KernelResult {
  const { requestId, sessionId, runId, capabilityResult } = params;
  return {
    resultId: requestId,
    sessionId,
    runId,
    source: "capability",
    status: mapCapabilityStatus(capabilityResult.status),
    output: capabilityResult.output,
    evidence: capabilityResult.evidence,
    error:
      capabilityResult.error && typeof capabilityResult.error === "object"
        ? {
            code: "rax_search_ground_failed",
            message: "Rax search.ground returned a non-success result.",
            details: capabilityResult.error as Record<string, unknown>,
          }
        : undefined,
    emittedAt: new Date().toISOString(),
    metadata: {
      provider: capabilityResult.provider,
      model: capabilityResult.model,
      layer: capabilityResult.layer,
      capability: "search.ground",
    },
  };
}

export function createRaxSearchGroundCapabilityDefinition(
  options: Omit<RegisterRaxSearchGroundCapabilityOptions, "broker"> = {},
): CapabilityPortDefinition {
  const facade = options.facade ?? rax;
  const capabilityKey = options.capabilityKey ?? "search.ground";

  return {
    capabilityKey,
    async handler(request) {
      const input = parseSearchGroundInput(request.input);
      const capabilityResult = await facade.websearch.create({
        provider: input.provider,
        model: input.model,
        layer: input.layer,
        variant: input.variant,
        compatibilityProfileId: input.compatibilityProfileId,
        providerOptions: input.providerOptions,
        input: {
          query: input.query,
          goal: input.goal,
          urls: input.urls,
          allowedDomains: input.allowedDomains,
          blockedDomains: input.blockedDomains,
          maxSources: input.maxSources,
          maxOutputTokens: input.maxOutputTokens,
          searchContextSize: input.searchContextSize,
          citations: input.citations,
          freshness: input.freshness,
          userLocation: input.userLocation,
        },
      });

      return {
        output: capabilityResult.output,
        evidence: capabilityResult.evidence,
        error:
          capabilityResult.status === "failed" || capabilityResult.status === "blocked" || capabilityResult.status === "timeout"
            ? {
                code: "rax_search_ground_failed",
                message: "Rax search.ground did not complete successfully.",
                details: asObject(capabilityResult.error) ?? { raw: capabilityResult.error },
              }
            : undefined,
        result: toKernelResult({
          requestId: request.requestId,
          sessionId: request.sessionId,
          runId: request.runId,
          capabilityResult,
        }),
        metadata: {
          provider: capabilityResult.provider,
          model: capabilityResult.model,
          layer: capabilityResult.layer,
          capabilityKey,
        },
      };
    },
  };
}

export function registerRaxSearchGroundCapability(
  options: RegisterRaxSearchGroundCapabilityOptions,
): CapabilityPortDefinition {
  const definition = createRaxSearchGroundCapabilityDefinition(options);
  options.broker.registerCapabilityPort(definition);
  return definition;
}
