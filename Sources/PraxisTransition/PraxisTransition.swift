import PraxisCoreTypes
import PraxisState

// TODO(reboot-plan):
// - 实现 TransitionTable、TransitionGuard、NextActionDecision 等模型。
// - 实现状态转移规则、guard 检查和 next-action 选择逻辑。
// - 明确 transition 只消费 state，不反向知道 run/tap/cmp 的宿主细节。
// - 文件可继续拆分：TransitionTable.swift、TransitionGuards.swift、NextActionEvaluator.swift、TransitionPolicy.swift。

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
    tsModules: [
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
