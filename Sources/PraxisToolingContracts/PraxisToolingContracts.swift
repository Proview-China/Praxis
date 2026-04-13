import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement the full contract boundaries for shell, browser, git, and process supervision.
// - Add host contracts for system git availability checks and first-time installation guidance.
// - Add contracts for execution results, timeouts, cancellation, streaming output, browser grounding evidence, and error taxonomies.
// - Keep tooling contracts as an executor-protocol layer without pulling domain rules back in.
// - This file can later be split into ShellExecutor.swift, BrowserExecutor.swift, GitAvailabilityProbe.swift, GitExecutor.swift, ProcessSupervisor.swift, and BrowserGroundingModels.swift.

public enum PraxisToolingContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisToolingContracts",
    responsibility: "shell / browser / system git / process tooling 协议族。",
    legacyReferences: [
      "src/agent_core/integrations/tap-tooling",
      "src/agent_core/cmp-git/git-cli-backend.ts",
      "src/agent_core/live-agent-chat/browser-grounding.ts",
    ],
  )
}
