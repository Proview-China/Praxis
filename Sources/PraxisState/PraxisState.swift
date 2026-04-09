import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 StateSnapshot、StateDelta、ProjectionState 等状态领域模型。
// - 实现状态投影、校验、不变量检查和最小 diff 规则。
// - 保持这里纯化，只表达状态真相，不承接 transition/run 的编排逻辑。
// - 文件可继续拆分：StateModels.swift、StateProjection.swift、StateValidation.swift、StateDelta.swift。

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
