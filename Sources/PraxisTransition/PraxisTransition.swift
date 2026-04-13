import PraxisCoreTypes
import PraxisState

// TODO(reboot-plan):
// - Implement models such as TransitionTable, TransitionGuard, and NextActionDecision.
// - Implement state-transition rules, guard checks, and next-action selection logic.
// - Make it explicit that transition consumes state only and does not know host details from run, TAP, or CMP.
// - This file can later be split into TransitionTable.swift, TransitionGuards.swift, NextActionEvaluator.swift, and TransitionPolicy.swift.

public struct PraxisTransitionBlueprint: Sendable, Equatable {
  public let responsibilities: [String]
  public let dependsOn: [String]

  public init(
    responsibilities: [String],
    dependsOn: [String],
  ) {
    self.responsibilities = responsibilities
    self.dependsOn = dependsOn
  }
}

public enum PraxisTransitionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTransition",
    responsibility: "状态转移表、guard 和 next-action 决策。",
    legacyReferences: [
      "src/agent_core/transition",
    ],
  )

  public static let blueprint = PraxisTransitionBlueprint(
    responsibilities: [
      "table",
      "guard",
      "evaluate",
    ],
    dependsOn: [
      PraxisStateModule.boundary.name,
    ],
  )
}
