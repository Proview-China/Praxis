import PraxisCapabilityContracts
import PraxisCoreTypes
import PraxisTapTypes

// TODO(reboot-plan):
// - The current implementation already covers the minimal rule surface for governance objects, risk classification, mode policy, and safety interception.
// - Next, add a more stable summary mapping between context aperture, user-facing surfaces, and live inspection.
// - Keep this target as pure governance logic without calling user I/O, tooling, or provider adapters directly.
// - This file can later be split into GovernanceObject.swift, RiskClassifier.swift, ModePolicy.swift, and SafetyInterception.swift.

public enum PraxisTapGovernanceModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapGovernance",
    responsibility: "风险分类、mode policy、safety interception、governance object 与 user surface snapshot。",
    tsModules: [
      "src/agent_core/ta-pool-model",
      "src/agent_core/ta-pool-context",
      "src/agent_core/ta-pool-safety",
    ],
  )
}
