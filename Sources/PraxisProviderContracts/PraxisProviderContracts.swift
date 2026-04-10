import PraxisCapabilityContracts
import PraxisCapabilityResults
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement protocol models for provider request/receipt, inference, embedding, skill, and MCP surfaces.
// - Refine the layering between capability executors and provider executors to avoid semantic overlap.
// - Standardize the mapping boundary from raw provider capabilities to Core request/result semantics.
// - This file can later be split into ProviderRequests.swift, ProviderReceipts.swift, InferenceProtocols.swift, and SkillAndMCPProtocols.swift.

public enum PraxisProviderContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisProviderContracts",
    responsibility: "provider 推理与 capability 执行协议族。",
    tsModules: [
      "src/agent_core/integrations/model-inference.ts",
      "src/integrations",
      "src/rax/facade.ts",
    ],
  )
}
