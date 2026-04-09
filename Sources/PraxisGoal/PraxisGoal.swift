import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 GoalSource、NormalizedGoal、CompiledGoal 等目标领域模型。
// - 实现目标归一化、编译、校验与来源追踪规则。
// - 抽清 goal 与 run/session 的边界，只保留“目标是什么”，不引入执行细节。
// - 文件可继续拆分：GoalModels.swift、GoalNormalization.swift、GoalCompiler.swift、GoalValidation.swift。

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
    tsModules: [
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
