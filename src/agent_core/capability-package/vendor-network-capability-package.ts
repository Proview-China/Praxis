import type {
  ReplayPolicy,
  PoolActivationSpec,
  TaCapabilityTier,
} from "../ta-pool-types/index.js";
import { createPoolActivationSpec } from "../ta-pool-types/index.js";
import {
  createCapabilityPackage,
  createCapabilityPackageActivationSpecRef,
  createCapabilityPackageSupportMatrix,
  type CapabilityPackage,
} from "./capability-package.js";

export const TAP_VENDOR_NETWORK_CAPABILITY_KEYS = [
  "search.web",
  "search.fetch",
  "search.ground",
] as const;

export type TapVendorNetworkCapabilityKey =
  (typeof TAP_VENDOR_NETWORK_CAPABILITY_KEYS)[number];

export const TAP_VENDOR_NETWORK_ACTIVATION_FACTORY_REFS: Readonly<
  Record<TapVendorNetworkCapabilityKey, string>
> = {
  "search.web": "factory:tap.vendor-network:search.web",
  "search.fetch": "factory:tap.vendor-network:search.fetch",
  "search.ground": "factory:tap.vendor-network:search.ground",
};

export interface CreateTapVendorNetworkCapabilityPackageInput {
  capabilityKey: TapVendorNetworkCapabilityKey;
  tier?: TaCapabilityTier;
  version?: string;
  generation?: number;
  replayPolicy?: ReplayPolicy;
  activationSpec?: PoolActivationSpec;
}

interface NetworkCapabilityDefaults {
  description: string;
  tags: string[];
  tier: TaCapabilityTier;
  routeHints: Array<{ key: string; value: string }>;
  successCriteria: string[];
  failureSignals: string[];
  evidenceOutput: string[];
  bestPractices: string[];
  knownLimits: string[];
  exampleInput: Record<string, unknown>;
  exampleNotes: string;
  reviewRequirements: ("allow" | "allow_with_constraints")[];
  safetyFlags: string[];
  riskLevel: "normal" | "risky" | "dangerous";
}

const NETWORK_USAGE_DOC_REF =
  "docs/ability/66-tap-native-capability-family-and-backend-selection.md";

const NETWORK_PROVIDER_HINTS = ["openai", "anthropic", "deepmind", "generic"];

const NETWORK_CAPABILITY_DEFAULTS: Record<
  TapVendorNetworkCapabilityKey,
  NetworkCapabilityDefaults
> = {
  "search.web": {
    description:
      "Search the web through TAP vendor-native or portable network backends and return structured result links plus optional answer text.",
    tags: ["tap", "network", "search", "vendor-native", "portable"],
    tier: "B1",
    routeHints: [
      { key: "family", value: "tap-vendor-network" },
      { key: "backendKind", value: "hybrid" },
      { key: "selectionPolicy", value: "prefer_provider_native_then_portable" },
    ],
    successCriteria: [
      "search query returns structured sources or a provider answer",
      "provider/model route remains attached to the envelope metadata",
    ],
    failureSignals: [
      "provider/model/query input is missing",
      "search backend returns failed, blocked, or timeout",
    ],
    evidenceOutput: ["capability-result-envelope", "search-sources", "search-evidence"],
    bestPractices: [
      "Provide explicit query text and freshness hints when current information matters.",
      "Prefer search.web for discovery and broad result collection before targeted page fetches.",
    ],
    knownLimits: [
      "Actual result quality depends on the selected provider-native backend or portable runtime.",
      "Unofficial carriers may degrade from native search onto thinner portable paths.",
    ],
    exampleInput: {
      provider: "openai",
      model: "gpt-5.4",
      query: "current Praxis repository status",
      freshness: "day",
    },
    exampleNotes:
      "Discovery-style search that prefers provider-native search when available.",
    reviewRequirements: ["allow_with_constraints"],
    safetyFlags: ["network_access", "external_content"],
    riskLevel: "normal",
  },
  "search.fetch": {
    description:
      "Fetch and normalize targeted page content through TAP network backends, with portable fallback for plain text extraction.",
    tags: ["tap", "network", "fetch", "vendor-native", "portable"],
    tier: "B1",
    routeHints: [
      { key: "family", value: "tap-vendor-network" },
      { key: "backendKind", value: "hybrid" },
      { key: "selectionPolicy", value: "prefer_portable_fetch_with_vendor_overrides" },
    ],
    successCriteria: [
      "requested URL content is fetched into a readable text form",
      "final URL, transport, and truncation status remain attached to the output",
    ],
    failureSignals: [
      "url input is missing or invalid",
      "fetch backend returns failed, blocked, or timeout",
      "target resolves to a denied local or private address",
    ],
    evidenceOutput: ["capability-result-envelope", "fetched-pages", "fetch-metadata"],
    bestPractices: [
      "Use search.fetch after search.web has identified a promising target URL.",
      "Keep URL batches small so the follow-up summarizer receives high-signal page excerpts.",
    ],
    knownLimits: [
      "Portable fetch may rely on readability fallbacks for HTML-heavy pages.",
      "Authenticated or highly dynamic pages can still require browser or MCP-specific tooling.",
    ],
    exampleInput: {
      url: "https://example.com/post",
      prompt: "extract the current key facts",
    },
    exampleNotes:
      "Fetch one target page into a bounded text payload for later reasoning.",
    reviewRequirements: ["allow_with_constraints"],
    safetyFlags: ["network_access", "external_content", "ssrf_guard_required"],
    riskLevel: "normal",
  },
  "search.ground": {
    description:
      "Produce a grounded answer with citations and sources through TAP vendor-native search backends, with portable fallback lanes available behind TAP.",
    tags: ["tap", "network", "grounding", "vendor-native", "portable"],
    tier: "B1",
    routeHints: [
      { key: "family", value: "tap-vendor-network" },
      { key: "backendKind", value: "hybrid" },
      { key: "selectionPolicy", value: "prefer_provider_native_then_portable_grounding" },
    ],
    successCriteria: [
      "grounded answer returns citations or sources",
      "provider/model route remains attached to the result envelope",
    ],
    failureSignals: [
      "provider/model/query input is missing",
      "grounding backend returns failed, blocked, or timeout",
      "grounded answer returns no usable source evidence",
    ],
    evidenceOutput: ["capability-result-envelope", "websearch-evidence", "grounding-sources"],
    bestPractices: [
      "Use search.ground when the user needs a final answer with source evidence.",
      "Prefer required citations for current events, market data, and changing web facts.",
    ],
    knownLimits: [
      "Grounding quality depends on the selected backend and route compatibility.",
      "When provider-native search fails, TAP may need to degrade onto thinner portable evidence paths.",
    ],
    exampleInput: {
      provider: "anthropic",
      model: "claude-opus-4-6-thinking",
      query: "current international gold price in USD per ounce",
      citations: "required",
      freshness: "day",
    },
    exampleNotes:
      "Grounded answer flow that prefers the current provider-native search route.",
    reviewRequirements: ["allow_with_constraints"],
    safetyFlags: ["network_access", "external_content", "grounded_answer_required"],
    riskLevel: "normal",
  },
};

function createVendorNetworkSupportMatrix(
  capabilityKey: TapVendorNetworkCapabilityKey,
) {
  const notes = {
    openai:
      capabilityKey === "search.fetch"
        ? "OpenAI-family routes often need TAP portable fetch or an external fetch helper instead of a single official native fetch primitive."
        : "OpenAI-family routes should prefer provider-native search when the current carrier fully supports it.",
    anthropic:
      capabilityKey === "search.fetch"
        ? "Anthropic-family routes can later lower to Claude Code style native fetch while keeping this TAP package stable."
        : "Anthropic-family routes can prefer Claude Code or Messages-native grounded search backends.",
    deepmind:
      capabilityKey === "search.fetch"
        ? "DeepMind-family routes can later lower to Gemini URL-context or portable fetch without changing the capability contract."
        : "DeepMind-family routes can prefer Gemini grounded search backends where available.",
  };

  return createCapabilityPackageSupportMatrix({
    routes: [
      {
        provider: "openai",
        sdkLayer: "api",
        lowering: "package-runtime",
        status: "documented",
        preferred: capabilityKey !== "search.fetch",
        notes: [notes.openai],
      },
      {
        provider: "anthropic",
        sdkLayer: "api",
        lowering: "package-runtime",
        status: "documented",
        preferred: capabilityKey !== "search.fetch",
        notes: [notes.anthropic],
      },
      {
        provider: "deepmind",
        sdkLayer: "api",
        lowering: "package-runtime",
        status: "documented",
        preferred: capabilityKey !== "search.fetch",
        notes: [notes.deepmind],
      },
    ],
    metadata: {
      capabilityFamily: "tap-vendor-network",
      capabilityKey,
      backendKind:
        capabilityKey === "search.fetch" ? "hybrid-fetch" : "hybrid-search",
    },
  });
}

export function createTapVendorNetworkCapabilityPackage(
  input: CreateTapVendorNetworkCapabilityPackageInput,
): CapabilityPackage {
  const defaults = NETWORK_CAPABILITY_DEFAULTS[input.capabilityKey];
  const version = input.version ?? "1.0.0";
  const generation = input.generation ?? 1;
  const replayPolicy = input.replayPolicy ?? "re_review_then_dispatch";
  const adapterFactoryRef =
    TAP_VENDOR_NETWORK_ACTIVATION_FACTORY_REFS[input.capabilityKey];
  const adapterId = `adapter:${input.capabilityKey}`;
  const runtimeKind = "tap-vendor-network";

  const activationSpec =
    input.activationSpec ??
    createPoolActivationSpec({
      targetPool: "ta-capability-pool",
      activationMode: "activate_after_verify",
      registerOrReplace: "register_or_replace",
      generationStrategy: "create_next_generation",
      drainStrategy: "graceful",
      manifestPayload: {
        capabilityKey: input.capabilityKey,
        capabilityId: `capability:${input.capabilityKey}:${generation}`,
        version,
        generation,
        kind: "tool",
        description: defaults.description,
        supportsPrepare: true,
        supportsCancellation: false,
        routeHints: [
          { key: "runtime", value: runtimeKind },
          { key: "capability", value: input.capabilityKey },
        ],
        tags: defaults.tags,
      },
      bindingPayload: {
        adapterId,
        runtimeKind,
      },
      adapterFactoryRef,
      metadata: {
        packageKind: "tap-vendor-network-family",
      },
    });

  return createCapabilityPackage({
    manifest: {
      capabilityKey: input.capabilityKey,
      capabilityKind: "tool",
      tier: input.tier ?? defaults.tier,
      version,
      generation,
      description: defaults.description,
      dependencies: ["network.read"],
      tags: defaults.tags,
      routeHints: defaults.routeHints,
      supportedPlatforms: ["linux", "macos", "windows"],
      metadata: {
        family: "tap-vendor-network",
        backendKind:
          input.capabilityKey === "search.fetch" ? "hybrid" : "native-or-hybrid",
      },
    },
    supportMatrix: createVendorNetworkSupportMatrix(input.capabilityKey),
    adapter: {
      adapterId,
      runtimeKind,
      supports: [input.capabilityKey],
      prepare: {
        ref: "integrations/tap-vendor-network-adapter#prepare",
        description:
          "Normalize TAP vendor-network capability input into a prepared execution state.",
      },
      execute: {
        ref: "integrations/tap-vendor-network-adapter#execute",
        description:
          "Execute TAP vendor-network capability through provider-native search or portable fetch backends.",
      },
      resultMapping: {
        successStatuses: ["success", "partial"],
        artifactKinds: ["evidence", "citations", "sources", "fetched-pages"],
      },
      metadata: {
        activationFactoryRef: adapterFactoryRef,
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: input.tier ?? defaults.tier,
        mode: "standard",
        scope: {
          allowedOperations: ["network.read", "evidence.capture"],
          providerHints: NETWORK_PROVIDER_HINTS,
        },
      },
      recommendedMode: "standard",
      riskLevel: defaults.riskLevel,
      defaultScope: {
        allowedOperations: ["network.read", "evidence.capture"],
        providerHints: NETWORK_PROVIDER_HINTS,
      },
      reviewRequirements: defaults.reviewRequirements,
      safetyFlags: defaults.safetyFlags,
      humanGateRequirements: [],
    },
    builder: {
      builderId: `builder:${input.capabilityKey}:tap-vendor-network`,
      buildStrategy: "mount-existing-runtime",
      requiresNetwork: true,
      requiresInstall: false,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: replayPolicy,
    },
    verification: {
      smokeEntry: `smoke:${input.capabilityKey}`,
      healthEntry: `health:tap-vendor-network:${input.capabilityKey}`,
      successCriteria: defaults.successCriteria,
      failureSignals: defaults.failureSignals,
      evidenceOutput: defaults.evidenceOutput,
    },
    usage: {
      usageDocRef: NETWORK_USAGE_DOC_REF,
      bestPractices: defaults.bestPractices,
      knownLimits: defaults.knownLimits,
      exampleInvocations: [
        {
          exampleId: `example:${input.capabilityKey}`,
          capabilityKey: input.capabilityKey,
          operation: input.capabilityKey,
          input: defaults.exampleInput,
          notes: defaults.exampleNotes,
        },
      ],
    },
    lifecycle: {
      installStrategy:
        "register the TAP vendor-network adapter family and let TAP choose provider-native or portable backends at runtime",
      replaceStrategy: "register_or_replace active binding generation",
      rollbackStrategy: "restore the previous vendor-network binding generation",
      deprecateStrategy: "disable new dispatches before draining superseded bindings",
      cleanupStrategy: "clear superseded vendor-network binding artifacts after drain",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy,
    artifacts: {
      toolArtifact: {
        artifactId: `tool:${input.capabilityKey}`,
        kind: "tool",
        ref: `tool:${input.capabilityKey}`,
      },
      bindingArtifact: {
        artifactId: `binding:${input.capabilityKey}`,
        kind: "binding",
        ref: `binding:${input.capabilityKey}`,
      },
      verificationArtifact: {
        artifactId: `verification:${input.capabilityKey}`,
        kind: "verification",
        ref: `verification:${input.capabilityKey}`,
      },
      usageArtifact: {
        artifactId: `usage:${input.capabilityKey}`,
        kind: "usage",
        ref: `usage:${input.capabilityKey}`,
      },
    },
    metadata: {
      bundleId: `bundle:${input.capabilityKey}:tap-vendor-network`,
      provisionId: `provision:${input.capabilityKey}:tap-vendor-network`,
      packageKind: "tap-vendor-network-family",
    },
  });
}

export function createTapVendorNetworkCapabilityPackageCatalog(): CapabilityPackage[] {
  return TAP_VENDOR_NETWORK_CAPABILITY_KEYS.map((capabilityKey) =>
    createTapVendorNetworkCapabilityPackage({ capabilityKey }),
  );
}
