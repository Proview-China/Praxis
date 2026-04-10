import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement state-domain models such as StateSnapshot, StateDelta, and ProjectionState.
// - Implement state projection, validation, invariant checks, and minimal diff rules.
// - Keep this target pure so it only expresses state truth instead of transition or run orchestration logic.
// - This file can later be split into StateModels.swift, StateProjection.swift, StateValidation.swift, and StateDelta.swift.

public struct PraxisStateBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

public enum PraxisStateModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisState",
    responsibility: "事件投影、状态快照与状态校验。",
    tsModules: [
      "src/agent_core/state",
    ],
  )

  public static let blueprint = PraxisStateBlueprint(
    responsibilities: [
      "project",
      "validate",
      "diff",
    ],
  )
}
