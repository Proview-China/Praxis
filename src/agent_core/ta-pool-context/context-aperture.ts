import type {
  AgentCapabilityProfile,
  PlainLanguageRiskPayload,
  TaCapabilityTier,
  TaPoolMode,
  TaPoolRiskLevel,
} from "../ta-pool-types/index.js";
import { validatePlainLanguageRiskPayload } from "../ta-pool-types/index.js";
import {
  formatPlainLanguageRisk,
  type CreateReviewRiskSummaryInput,
} from "./plain-language-risk.js";

export const CONTEXT_SUMMARY_STATUSES = [
  "placeholder",
  "ready",
] as const;
export type ContextSummaryStatus = (typeof CONTEXT_SUMMARY_STATUSES)[number];

export interface ContextSummarySlot {
  summary: string;
  status: ContextSummaryStatus;
  source?: string;
  metadata?: Record<string, unknown>;
}

export type ContextSummarySlotInput = string | ContextSummarySlot | undefined;

export interface ReviewInventorySnapshot {
  totalCapabilities: number;
  availableCapabilityKeys: string[];
  pendingProvisionKeys?: string[];
  metadata?: Record<string, unknown>;
}

export interface ReviewRiskSummary {
  riskLevel: TaPoolRiskLevel;
  requestedAction: string;
  plainLanguageRisk: PlainLanguageRiskPayload;
  source: "request" | "generated" | "test";
  metadata?: Record<string, unknown>;
}

export interface ProvisionCapabilitySpec {
  capabilityKey: string;
  requestedTier?: TaCapabilityTier;
  desiredProviderOrRuntime?: string;
  reason?: string;
  metadata?: Record<string, unknown>;
}

export interface ProvisionSiblingCapabilitySummary {
  summary: string;
  siblingCapabilityKeys: string[];
  status: ContextSummaryStatus;
  metadata?: Record<string, unknown>;
}

export interface ProvisionAllowedBuildScope {
  summary: string;
  pathPatterns?: string[];
  allowedOperations?: string[];
  deniedOperations?: string[];
  status: ContextSummaryStatus;
  metadata?: Record<string, unknown>;
}

export interface ProvisionAllowedSideEffect {
  effectId: string;
  description: string;
  status: ContextSummaryStatus;
  metadata?: Record<string, unknown>;
}

export const CONTEXT_APERTURE_FORBIDDEN_OBJECTS = [
  {
    kind: "runtime_handle",
    description: "Live runtime, session, or bridge handles must stay outside the aperture.",
  },
  {
    kind: "tool_handle",
    description: "Tool client handles must be reduced to summaries before entering the aperture.",
  },
  {
    kind: "raw_patch_object",
    description: "Raw patch objects are not allowed; only summarized intent or scope may enter.",
  },
  {
    kind: "raw_shell_handle",
    description: "Raw shell process handles are forbidden; keep only plain-language side-effect summaries.",
  },
  {
    kind: "secret_literal",
    description: "Secrets must never enter the aperture in literal form.",
  },
] as const;

export type ContextApertureForbiddenObject =
  (typeof CONTEXT_APERTURE_FORBIDDEN_OBJECTS)[number];

export interface ReviewContextAperture {
  projectSummary: ContextSummarySlot;
  runSummary: ContextSummarySlot;
  profileSnapshot?: AgentCapabilityProfile;
  inventorySnapshot: ReviewInventorySnapshot;
  capabilityInventorySnapshot: ReviewInventorySnapshot;
  memorySummaryPlaceholder: ContextSummarySlot;
  userIntentSummary: ContextSummarySlot;
  riskSummary: ReviewRiskSummary;
  modeSnapshot?: TaPoolMode;
  forbiddenObjects: readonly ContextApertureForbiddenObject[];
  metadata?: Record<string, unknown>;
}

export type ReviewContextApertureSnapshot = ReviewContextAperture;

export interface ProvisionContextAperture {
  projectSummary: ContextSummarySlot;
  requestedCapabilityKey: string;
  capabilitySpec: ProvisionCapabilitySpec;
  inventorySnapshot?: {
    knownBindings: string[];
    knownTools: string[];
    metadata?: Record<string, unknown>;
  };
  existingSiblingCapabilitySummary: ProvisionSiblingCapabilitySummary;
  allowedBuildScope: ProvisionAllowedBuildScope;
  allowedSideEffects: ProvisionAllowedSideEffect[];
  reviewerInstructions: ContextSummarySlot;
  forbiddenObjects: readonly ContextApertureForbiddenObject[];
  metadata?: Record<string, unknown>;
}

export type ProvisionContextApertureSnapshot = ProvisionContextAperture;

export interface CreateReviewContextApertureInput {
  projectSummary?: ContextSummarySlotInput;
  runSummary?: ContextSummarySlotInput;
  profileSnapshot?: AgentCapabilityProfile;
  inventorySnapshot?: ReviewInventorySnapshot;
  capabilityInventorySnapshot?: ReviewInventorySnapshot;
  memorySummaryPlaceholder?: ContextSummarySlotInput;
  userIntentSummary?: ContextSummarySlotInput;
  riskSummary?: CreateReviewRiskSummaryInput | ReviewRiskSummary;
  modeSnapshot?: TaPoolMode;
  metadata?: Record<string, unknown>;
}

export interface CreateProvisionContextApertureInput {
  projectSummary?: ContextSummarySlotInput;
  requestedCapabilityKey?: string;
  capabilitySpec?: ProvisionCapabilitySpec;
  inventorySnapshot?: {
    knownBindings?: string[];
    knownTools?: string[];
    metadata?: Record<string, unknown>;
  };
  existingSiblingCapabilitySummary?:
    | ProvisionSiblingCapabilitySummary
    | string;
  allowedBuildScope?: ProvisionAllowedBuildScope;
  allowedSideEffects?: ProvisionAllowedSideEffect[];
  reviewerInstructions?: ContextSummarySlotInput;
  metadata?: Record<string, unknown>;
}

function normalizeStringArray(values?: readonly string[]): string[] | undefined {
  if (!values || values.length === 0) {
    return undefined;
  }

  const normalized = [...new Set(values.map((value) => value.trim()).filter(Boolean))];
  return normalized.length > 0 ? normalized : undefined;
}

function createSummarySlot(params: {
  value?: ContextSummarySlotInput;
  fallbackSummary: string;
  fallbackStatus: ContextSummaryStatus;
  fallbackSource: string;
}): ContextSummarySlot {
  if (!params.value) {
    return {
      summary: params.fallbackSummary,
      status: params.fallbackStatus,
      source: params.fallbackSource,
    };
  }

  if (typeof params.value === "string") {
    return {
      summary: params.value.trim(),
      status: "ready",
      source: params.fallbackSource,
    };
  }

  return {
    summary: params.value.summary.trim(),
    status: params.value.status,
    source: params.value.source?.trim() || undefined,
    metadata: params.value.metadata,
  };
}

function validateSummarySlot(label: string, slot: ContextSummarySlot): void {
  if (!slot.summary.trim()) {
    throw new Error(`${label} requires a non-empty summary.`);
  }

  if (!CONTEXT_SUMMARY_STATUSES.includes(slot.status)) {
    throw new Error(`${label} contains an unsupported status: ${slot.status}.`);
  }
}

function normalizeReviewInventorySnapshot(
  input?: ReviewInventorySnapshot,
): ReviewInventorySnapshot {
  return {
    totalCapabilities: input?.totalCapabilities ?? 0,
    availableCapabilityKeys: normalizeStringArray(input?.availableCapabilityKeys) ?? [],
    pendingProvisionKeys: normalizeStringArray(input?.pendingProvisionKeys),
    metadata: input?.metadata,
  };
}

function validateReviewInventorySnapshot(snapshot: ReviewInventorySnapshot): void {
  if (snapshot.totalCapabilities < 0) {
    throw new Error("Review inventory snapshot totalCapabilities cannot be negative.");
  }
}

function normalizeProvisionInventorySnapshot(
  input?: CreateProvisionContextApertureInput["inventorySnapshot"],
): ProvisionContextAperture["inventorySnapshot"] {
  if (!input) {
    return undefined;
  }

  return {
    knownBindings: normalizeStringArray(input.knownBindings) ?? [],
    knownTools: normalizeStringArray(input.knownTools) ?? [],
    metadata: input.metadata,
  };
}

function normalizeReviewRiskSummary(
  input?: CreateReviewRiskSummaryInput | ReviewRiskSummary,
): ReviewRiskSummary {
  if (!input) {
    const payload = formatPlainLanguageRisk({
      requestedAction: "review the capability request before execution",
      riskLevel: "normal",
    });
    return {
      riskLevel: payload.riskLevel,
      requestedAction: payload.requestedAction,
      plainLanguageRisk: payload,
      source: "generated",
    };
  }

  if ("plainLanguageRisk" in input && "source" in input) {
    validatePlainLanguageRiskPayload(input.plainLanguageRisk);
    return {
      riskLevel: input.riskLevel,
      requestedAction: input.requestedAction.trim(),
      plainLanguageRisk: input.plainLanguageRisk,
      source: input.source,
      metadata: input.metadata,
    };
  }

  const payload = input.plainLanguageRisk
    ? input.plainLanguageRisk
    : formatPlainLanguageRisk(input);

  validatePlainLanguageRiskPayload(payload);
  return {
    riskLevel: input.riskLevel ?? payload.riskLevel,
    requestedAction: input.requestedAction.trim(),
    plainLanguageRisk: payload,
    source: input.plainLanguageRisk ? "request" : "generated",
    metadata: input.metadata,
  };
}

function validateReviewRiskSummary(input: ReviewRiskSummary): void {
  if (!input.requestedAction.trim()) {
    throw new Error("Review context riskSummary requires a non-empty requestedAction.");
  }

  validatePlainLanguageRiskPayload(input.plainLanguageRisk);
}

function normalizeProvisionCapabilitySpec(
  input: CreateProvisionContextApertureInput,
): ProvisionCapabilitySpec {
  const capabilityKey = input.capabilitySpec?.capabilityKey?.trim()
    || input.requestedCapabilityKey?.trim()
    || "";

  return {
    capabilityKey,
    requestedTier: input.capabilitySpec?.requestedTier,
    desiredProviderOrRuntime: input.capabilitySpec?.desiredProviderOrRuntime?.trim() || undefined,
    reason: input.capabilitySpec?.reason?.trim() || undefined,
    metadata: input.capabilitySpec?.metadata,
  };
}

function validateProvisionCapabilitySpec(spec: ProvisionCapabilitySpec): void {
  if (!spec.capabilityKey.trim()) {
    throw new Error("Provision context aperture requires a non-empty capabilitySpec.capabilityKey.");
  }
}

function normalizeSiblingSummary(
  input?: ProvisionSiblingCapabilitySummary | string,
): ProvisionSiblingCapabilitySummary {
  if (!input) {
    return {
      summary: "Sibling capability summary is still placeholder in Wave 1.",
      siblingCapabilityKeys: [],
      status: "placeholder",
    };
  }

  if (typeof input === "string") {
    return {
      summary: input.trim(),
      siblingCapabilityKeys: [],
      status: "ready",
    };
  }

  return {
    summary: input.summary.trim(),
    siblingCapabilityKeys: normalizeStringArray(input.siblingCapabilityKeys) ?? [],
    status: input.status,
    metadata: input.metadata,
  };
}

function validateSiblingSummary(input: ProvisionSiblingCapabilitySummary): void {
  if (!input.summary.trim()) {
    throw new Error("Provision context aperture requires a non-empty existingSiblingCapabilitySummary.");
  }
}

function normalizeAllowedBuildScope(
  input?: ProvisionAllowedBuildScope,
): ProvisionAllowedBuildScope {
  if (!input) {
    return {
      summary: "Build scope is placeholder-only in Wave 1: stage artifacts and verification notes, but do not wire a real worker bridge.",
      pathPatterns: ["src/agent_core/ta-pool-context/**", "src/agent_core/ta-pool-review/**"],
      allowedOperations: ["build_artifacts", "write_context_modules", "write_tests"],
      deniedOperations: ["execute_worker_bridge", "inject_runtime_handle"],
      status: "placeholder",
    };
  }

  return {
    summary: input.summary.trim(),
    pathPatterns: normalizeStringArray(input.pathPatterns),
    allowedOperations: normalizeStringArray(input.allowedOperations),
    deniedOperations: normalizeStringArray(input.deniedOperations),
    status: input.status,
    metadata: input.metadata,
  };
}

function validateAllowedBuildScope(input: ProvisionAllowedBuildScope): void {
  if (!input.summary.trim()) {
    throw new Error("Provision context aperture requires a non-empty allowedBuildScope.summary.");
  }
}

function normalizeAllowedSideEffects(
  input?: ProvisionAllowedSideEffect[],
): ProvisionAllowedSideEffect[] {
  if (!input || input.length === 0) {
    return [
      {
        effectId: "stage-artifact-placeholders",
        description: "May produce placeholder artifact summaries and verification notes for later provisioning work.",
        status: "placeholder",
      },
      {
        effectId: "review-input-shaping",
        description: "May reshape reviewer/provisioner input envelopes without connecting a live worker bridge.",
        status: "placeholder",
      },
    ];
  }

  return input.map((effect) => ({
    effectId: effect.effectId.trim(),
    description: effect.description.trim(),
    status: effect.status,
    metadata: effect.metadata,
  }));
}

function validateAllowedSideEffects(input: ProvisionAllowedSideEffect[]): void {
  if (input.length === 0) {
    throw new Error("Provision context aperture requires at least one allowedSideEffect.");
  }

  for (const effect of input) {
    if (!effect.effectId.trim()) {
      throw new Error("Provision context allowedSideEffect requires a non-empty effectId.");
    }

    if (!effect.description.trim()) {
      throw new Error("Provision context allowedSideEffect requires a non-empty description.");
    }
  }
}

function detectForbiddenObjectAtPath(
  path: string,
  key: string,
  value: unknown,
): string | undefined {
  if (typeof value === "function") {
    return `${path}.${key} contains a live function handle, which is forbidden in context aperture snapshots.`;
  }

  const joined = `${path}.${key}`;
  if (/runtimeHandle/i.test(key)) {
    return `${joined} looks like a runtime handle and cannot enter the aperture.`;
  }
  if (/toolHandle/i.test(key)) {
    return `${joined} looks like a tool handle and cannot enter the aperture.`;
  }
  if (/(rawPatch|patchObject)/i.test(key)) {
    return `${joined} looks like a raw patch object and cannot enter the aperture.`;
  }
  if (/shellHandle/i.test(key)) {
    return `${joined} looks like a raw shell handle and cannot enter the aperture.`;
  }
  if (/(secret|apiKey|accessToken|refreshToken|privateKey)/i.test(key)) {
    return `${joined} looks like a secret literal slot and cannot enter the aperture.`;
  }

  return undefined;
}

function assertNoForbiddenObjects(
  value: unknown,
  path: string,
  seen: WeakSet<object> = new WeakSet(),
): void {
  if (!value || typeof value !== "object") {
    return;
  }

  if (seen.has(value)) {
    return;
  }
  seen.add(value);

  for (const [key, nested] of Object.entries(value)) {
    const forbidden = detectForbiddenObjectAtPath(path, key, nested);
    if (forbidden) {
      throw new Error(forbidden);
    }

    if (key === "forbiddenObjects") {
      continue;
    }

    assertNoForbiddenObjects(nested, `${path}.${key}`, seen);
  }
}

export function validateReviewContextApertureSnapshot(
  input: ReviewContextApertureSnapshot,
): void {
  validateSummarySlot("Review context projectSummary", input.projectSummary);
  validateSummarySlot("Review context runSummary", input.runSummary);
  validateSummarySlot("Review context memorySummaryPlaceholder", input.memorySummaryPlaceholder);
  validateSummarySlot("Review context userIntentSummary", input.userIntentSummary);
  validateReviewInventorySnapshot(input.inventorySnapshot);
  validateReviewRiskSummary(input.riskSummary);

  if (input.memorySummaryPlaceholder.status !== "placeholder") {
    throw new Error("Review context memorySummaryPlaceholder must stay in placeholder status for Wave 1.");
  }

  assertNoForbiddenObjects(input, "reviewContext");
}

export function validateProvisionContextApertureSnapshot(
  input: ProvisionContextApertureSnapshot,
): void {
  validateSummarySlot("Provision context projectSummary", input.projectSummary);
  validateProvisionCapabilitySpec(input.capabilitySpec);
  validateSiblingSummary(input.existingSiblingCapabilitySummary);
  validateAllowedBuildScope(input.allowedBuildScope);
  validateAllowedSideEffects(input.allowedSideEffects);
  validateSummarySlot("Provision context reviewerInstructions", input.reviewerInstructions);

  if (!input.requestedCapabilityKey.trim()) {
    throw new Error("Provision context aperture snapshot requires a non-empty requestedCapabilityKey.");
  }

  assertNoForbiddenObjects(input, "provisionContext");
}

export function createReviewContextAperture(
  input: CreateReviewContextApertureInput = {},
): ReviewContextAperture {
  const inventorySnapshot = normalizeReviewInventorySnapshot(
    input.inventorySnapshot ?? input.capabilityInventorySnapshot,
  );
  const aperture: ReviewContextAperture = {
    projectSummary: createSummarySlot({
      value: input.projectSummary,
      fallbackSummary: "Project summary is still placeholder in Wave 1 aperture; only safe high-level state should be threaded in.",
      fallbackStatus: "placeholder",
      fallbackSource: "wave-1-context-aperture",
    }),
    runSummary: createSummarySlot({
      value: input.runSummary,
      fallbackSummary: "Run summary placeholder.",
      fallbackStatus: "placeholder",
      fallbackSource: "wave-1-context-aperture",
    }),
    profileSnapshot: input.profileSnapshot,
    inventorySnapshot,
    capabilityInventorySnapshot: inventorySnapshot,
    memorySummaryPlaceholder: createSummarySlot({
      value: input.memorySummaryPlaceholder,
      fallbackSummary: "Memory summary is intentionally placeholder-only in Wave 1; no project memory is injected yet.",
      fallbackStatus: "placeholder",
      fallbackSource: "wave-1-context-aperture",
    }),
    userIntentSummary: createSummarySlot({
      value: input.userIntentSummary,
      fallbackSummary: "User intent summary placeholder.",
      fallbackStatus: "placeholder",
      fallbackSource: "wave-1-context-aperture",
    }),
    riskSummary: normalizeReviewRiskSummary(input.riskSummary),
    modeSnapshot: input.modeSnapshot,
    forbiddenObjects: CONTEXT_APERTURE_FORBIDDEN_OBJECTS,
    metadata: input.metadata,
  };
  validateReviewContextApertureSnapshot(aperture);
  return aperture;
}

export function createProvisionContextAperture(
  input: CreateProvisionContextApertureInput,
): ProvisionContextAperture {
  const capabilitySpec = normalizeProvisionCapabilitySpec(input);
  const aperture: ProvisionContextAperture = {
    projectSummary: createSummarySlot({
      value: input.projectSummary,
      fallbackSummary: "Project state is still placeholder-only for Wave 1 provisioner aperture.",
      fallbackStatus: "placeholder",
      fallbackSource: "wave-1-context-aperture",
    }),
    requestedCapabilityKey: capabilitySpec.capabilityKey,
    capabilitySpec,
    inventorySnapshot: normalizeProvisionInventorySnapshot(input.inventorySnapshot),
    existingSiblingCapabilitySummary: normalizeSiblingSummary(
      input.existingSiblingCapabilitySummary,
    ),
    allowedBuildScope: normalizeAllowedBuildScope(input.allowedBuildScope),
    allowedSideEffects: normalizeAllowedSideEffects(input.allowedSideEffects),
    reviewerInstructions: createSummarySlot({
      value: input.reviewerInstructions,
      fallbackSummary: "Reviewer instructions are placeholder-only in Wave 1: describe scope and risk plainly, but do not dispatch a live worker bridge.",
      fallbackStatus: "placeholder",
      fallbackSource: "wave-1-context-aperture",
    }),
    forbiddenObjects: CONTEXT_APERTURE_FORBIDDEN_OBJECTS,
    metadata: input.metadata,
  };
  validateProvisionContextApertureSnapshot(aperture);
  return aperture;
}

export const createReviewContextApertureSnapshot = createReviewContextAperture;
export const createProvisionContextApertureSnapshot = createProvisionContextAperture;
