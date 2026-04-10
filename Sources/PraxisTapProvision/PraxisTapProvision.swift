import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCoreTypes
import PraxisTapGovernance
import PraxisTapTypes

// TODO(reboot-plan):
// - The current implementation already covers the minimal rule surface for provision requests, assets, registry, and plans.
// - Next, add asset indexes, activation specs, and finer replay-recommendation models.
// - Keep provision focused on answering what should be provisioned instead of performing installs, repo writes, or network execution directly.
// - This file can later be split into ProvisionRequest.swift, ProvisionRegistry.swift, AssetIndex.swift, and ProvisionPlanner.swift.

public enum PraxisTapProvisionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapProvision",
    responsibility: "provision registry、asset index、planner 与 provisioning 计划模型。",
    tsModules: [
      "src/agent_core/ta-pool-provision",
    ],
  )
}
