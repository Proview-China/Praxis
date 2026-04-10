import PraxisCapabilityResults
import PraxisCoreTypes
import PraxisTapGovernance
import PraxisTapTypes

// TODO(reboot-plan):
// - 实现 ReviewRequest、ReviewDecision、ReviewerRoute、ReviewTrail 等模型。
// - 实现 tool-review / human-review 的决策路由与结果归并规则。
// - 保证这里表达“如何审”，而不是“如何执行工具”。
// - 文件可继续拆分：ReviewRequest.swift、ReviewDecision.swift、ReviewRouter.swift、ReviewAuditTrail.swift。

public enum PraxisTapReviewModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapReview",
    responsibility: "reviewer / tool reviewer 决策、路由与审查结果模型。",
    tsModules: [
      "src/agent_core/ta-pool-review",
      "src/agent_core/ta-pool-tool-review",
    ],
  )
}
