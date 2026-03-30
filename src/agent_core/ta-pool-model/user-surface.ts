import type { TapGovernanceObject } from "./governance-object.js";
import type {
  TapCapabilityGovernanceSnapshot,
  TapGovernanceCapabilityStage,
  TapGovernanceSnapshot,
} from "../ta-pool-runtime/governance-snapshot.js";

export interface TapUserSurfaceSnapshot {
  visibleMode: TapGovernanceObject["userSurface"]["visibleMode"];
  automationDepth: TapGovernanceObject["userSurface"]["automationDepth"];
  explanationStyle: TapGovernanceObject["userSurface"]["explanationStyle"];
  currentLayer: "runtime" | "reviewer" | "tool_reviewer" | "tma";
  pendingHumanGateCount: number;
  blockingCapabilityKeys: string[];
  activeCapabilityKeys: string[];
  canToggleMode: boolean;
  canToggleAutomationDepth: boolean;
  canOverrideToolPolicy: boolean;
  summary: string;
}

const RUNTIME_ACTIVE_STAGES = new Set<TapGovernanceCapabilityStage>([
  "activation_pending",
  "replay_pending",
  "resume_pending",
  "tma_pending",
]);

function listCapabilitiesByStage(
  snapshot: TapGovernanceSnapshot | undefined,
  stage: TapGovernanceCapabilityStage,
): TapCapabilityGovernanceSnapshot[] {
  return snapshot?.capabilities.filter((capability) => capability.stage === stage) ?? [];
}

function formatCapabilityLaneSummary(capabilities: TapCapabilityGovernanceSnapshot[]): string {
  const capabilityKeys = capabilities.map((capability) => capability.capabilityKey);
  if (capabilityKeys.length === 0) {
    return "the current capability lanes";
  }
  if (capabilityKeys.length === 1) {
    return capabilityKeys[0]!;
  }
  return `${capabilityKeys.join(", ")}`;
}

function resolveCurrentLayer(snapshot: TapGovernanceSnapshot | undefined): TapUserSurfaceSnapshot["currentLayer"] {
  const leadCapability = snapshot?.capabilities.find((capability) => capability.stage !== "settled");
  if (!leadCapability) {
    return "runtime";
  }

  if (leadCapability.stage === "waiting_human") {
    return (snapshot?.counts.toolReviewerSessions.waitingHuman ?? 0) > 0
      && (snapshot?.counts.humanGates.waitingHuman ?? 0) === 0
      ? "tool_reviewer"
      : "reviewer";
  }

  if (leadCapability.stage === "tool_review_blocked") {
    return "tool_reviewer";
  }

  if (leadCapability.stage === "tma_pending") {
    return "tma";
  }

  return "runtime";
}

function createSurfaceSummary(
  snapshot: TapGovernanceSnapshot | undefined,
  governance: TapGovernanceObject,
): string {
  const leadCapability = snapshot?.capabilities.find((capability) => capability.stage !== "settled");
  if (!leadCapability) {
    return `TAP is running in ${governance.userSurface.visibleMode} mode with no blocking governance backlog.`;
  }

  switch (leadCapability.stage) {
    case "waiting_human": {
      const currentLayer = resolveCurrentLayer(snapshot);
      const waitingCount = currentLayer === "tool_reviewer"
        ? snapshot?.counts.toolReviewerSessions.waitingHuman ?? 0
        : (snapshot?.counts.humanGates.waitingHuman ?? 0) + (snapshot?.counts.toolReviewerSessions.waitingHuman ?? 0);
      const waitingCapabilities = listCapabilitiesByStage(snapshot, "waiting_human");
      return currentLayer === "tool_reviewer"
        ? `Tool review is waiting for ${waitingCount} human decision(s) before ${formatCapabilityLaneSummary(waitingCapabilities)} can continue.`
        : `TAP is waiting for ${waitingCount} human approval step(s) before ${formatCapabilityLaneSummary(waitingCapabilities)} can continue.`;
    }
    case "tool_review_blocked": {
      const blockedCapabilities = listCapabilitiesByStage(snapshot, "tool_review_blocked");
      return `Tool review is blocking ${blockedCapabilities.length} capability lane(s): ${formatCapabilityLaneSummary(blockedCapabilities)}.`;
    }
    case "activation_failed": {
      const failedCapabilities = listCapabilitiesByStage(snapshot, "activation_failed");
      return `Runtime has ${failedCapabilities.length} activation failure lane(s): ${formatCapabilityLaneSummary(failedCapabilities)}.`;
    }
    case "activation_pending": {
      const activatingCapabilities = listCapabilitiesByStage(snapshot, "activation_pending");
      return `Runtime is activating ${activatingCapabilities.length} capability lane(s): ${formatCapabilityLaneSummary(activatingCapabilities)}.`;
    }
    case "replay_pending": {
      const replayCapabilities = listCapabilitiesByStage(snapshot, "replay_pending");
      return `Runtime is holding ${replayCapabilities.length} replay handoff lane(s): ${formatCapabilityLaneSummary(replayCapabilities)}.`;
    }
    case "resume_pending": {
      const resumableCapabilities = listCapabilitiesByStage(snapshot, "resume_pending");
      return `Runtime has ${resumableCapabilities.length} resumable capability lane(s): ${formatCapabilityLaneSummary(resumableCapabilities)}.`;
    }
    case "tma_pending": {
      const tmaCapabilities = listCapabilitiesByStage(snapshot, "tma_pending");
      return `TMA is still working on ${tmaCapabilities.length} capability lane(s): ${formatCapabilityLaneSummary(tmaCapabilities)}.`;
    }
    case "idle":
    case "settled":
      return `TAP is running in ${governance.userSurface.visibleMode} mode with no blocking governance backlog.`;
  }
}

export function createTapUserSurfaceSnapshot(input: {
  governance: TapGovernanceObject;
  governanceSnapshot?: TapGovernanceSnapshot;
}): TapUserSurfaceSnapshot {
  const waitingHuman = (input.governanceSnapshot?.counts.humanGates.waitingHuman ?? 0)
    + (input.governanceSnapshot?.counts.toolReviewerSessions.waitingHuman ?? 0);
  const blockingCapabilityKeys = input.governanceSnapshot?.blockingCapabilityKeys ?? [];
  const activeCapabilityKeys = input.governanceSnapshot?.capabilities
    .filter((capability) => RUNTIME_ACTIVE_STAGES.has(capability.stage))
    .map((capability) => capability.capabilityKey) ?? [];

  return {
    visibleMode: input.governance.userSurface.visibleMode,
    automationDepth: input.governance.userSurface.automationDepth,
    explanationStyle: input.governance.userSurface.explanationStyle,
    currentLayer: resolveCurrentLayer(input.governanceSnapshot),
    pendingHumanGateCount: waitingHuman,
    blockingCapabilityKeys,
    activeCapabilityKeys,
    canToggleMode: input.governance.userSurface.canToggleMode,
    canToggleAutomationDepth: input.governance.userSurface.canToggleAutomationDepth,
    canOverrideToolPolicy: input.governance.userSurface.canOverrideToolPolicy,
    summary: createSurfaceSummary(input.governanceSnapshot, input.governance),
  };
}
