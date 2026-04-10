import PraxisCapabilityContracts
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement shared TAP object models, including base value types for governance, review, provision, and human-gate flows.
// - Freeze enums, state tags, review levels, and availability-related types shared across TAP subdomains.
// - Keep only shared semantics here without packing in runtime rules or host execution details.
// - This file can later be split into TapGovernanceTypes.swift, TapReviewTypes.swift, TapProvisionTypes.swift, and TapAvailabilityTypes.swift.

public enum PraxisTapTypesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapTypes",
    responsibility: "TAP review/provision/TMA/human-gate 共享类型。",
    tsModules: [
      "src/agent_core/ta-pool-types",
    ],
  )
}
