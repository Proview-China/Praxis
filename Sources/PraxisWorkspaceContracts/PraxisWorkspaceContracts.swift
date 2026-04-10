import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement the full contract families and result types for workspace read, search, and write operations.
// - Add contracts for multi-file reads, symbol search, patch apply, write protection, and related operations.
// - Make it explicit that workspace describes host capabilities only and does not carry business-planning logic.
// - This file can later be split into WorkspaceReader.swift, WorkspaceSearcher.swift, WorkspaceWriter.swift, and WorkspaceChangeTypes.swift.

public enum PraxisWorkspaceContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisWorkspaceContracts",
    responsibility: "workspace read/search/write 协议族。",
    tsModules: [
      "src/agent_core/integrations/workspace-read-adapter.ts",
      "src/agent_core/integrations/tap-tooling-adapter.ts",
    ],
  )
}
