import type { TapGovernanceObject } from "./governance-object.js";
import type { TapGovernanceSnapshot } from "../ta-pool-runtime/governance-snapshot.js";

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

export function createTapUserSurfaceSnapshot(input: {
  governance: TapGovernanceObject;
  governanceSnapshot?: TapGovernanceSnapshot;
}): TapUserSurfaceSnapshot {
  const waitingHuman = input.governanceSnapshot?.counts.humanGates.waitingHuman ?? 0;
  const blockingCapabilityKeys = input.governanceSnapshot?.blockingCapabilityKeys ?? [];
  const activeCapabilityKeys = input.governanceSnapshot?.capabilities
    .filter((capability) => capability.stage === "settled")
    .map((capability) => capability.capabilityKey) ?? [];
  const currentLayer: TapUserSurfaceSnapshot["currentLayer"] = waitingHuman > 0
    ? "reviewer"
    : blockingCapabilityKeys.some((key) => key.includes("tool") || key.includes("mcp"))
      ? "tool_reviewer"
      : blockingCapabilityKeys.length > 0
        ? "tma"
        : "runtime";

  return {
    visibleMode: input.governance.userSurface.visibleMode,
    automationDepth: input.governance.userSurface.automationDepth,
    explanationStyle: input.governance.userSurface.explanationStyle,
    currentLayer,
    pendingHumanGateCount: waitingHuman,
    blockingCapabilityKeys,
    activeCapabilityKeys,
    canToggleMode: input.governance.userSurface.canToggleMode,
    canToggleAutomationDepth: input.governance.userSurface.canToggleAutomationDepth,
    canOverrideToolPolicy: input.governance.userSurface.canOverrideToolPolicy,
    summary: waitingHuman > 0
      ? `TAP is currently waiting for ${waitingHuman} human approval step(s).`
      : blockingCapabilityKeys.length > 0
        ? `TAP still has ${blockingCapabilityKeys.length} blocking capability lane(s): ${blockingCapabilityKeys.join(", ")}.`
        : `TAP is running in ${input.governance.userSurface.visibleMode} mode with no blocking governance backlog.`,
  };
}
