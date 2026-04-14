import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement goal-domain models such as GoalSource, NormalizedGoal, and CompiledGoal.
// - Implement goal normalization, compilation, validation, and source-tracking rules.
// - Clarify the boundary between goal and run/session so this target only describes what the goal is, not how it executes.
// - This file can later be split into GoalModels.swift, GoalNormalization.swift, GoalCompiler.swift, and GoalValidation.swift.

public struct PraxisGoalBlueprint: Sendable, Equatable {
  public let sourceKinds: [String]
  public let responsibilities: [String]

  public init(
    sourceKinds: [String],
    responsibilities: [String],
  ) {
    self.sourceKinds = sourceKinds
    self.responsibilities = responsibilities
  }
}

public enum PraxisGoalModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisGoal",
    responsibility: "目标来源、归一化与编译协议。",
    legacyReferences: [
      "src/agent_core/goal",
    ],
  )

  public static let blueprint = PraxisGoalBlueprint(
    sourceKinds: ["user", "system", "resume", "follow_up"],
    responsibilities: [
      "source",
      "normalize",
      "compile",
    ],
  )
}
