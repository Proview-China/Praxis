import PraxisCapabilityResults
import PraxisCoreTypes
import PraxisTapGovernance
import PraxisTapTypes

// TODO(reboot-plan):
// - The current implementation already covers review requests, decisions, trails, and baseline routing rules.
// - Next, add finer tool-review decisions, constraint merging, and review-evidence aggregation rules.
// - Keep this target focused on how review works without absorbing worker bridges, model hooks, or tool execution details.
// - This file can later be split into ReviewRequest.swift, ReviewDecision.swift, ReviewRouter.swift, and ReviewAuditTrail.swift.

public enum PraxisTapReviewModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapReview",
    responsibility: "reviewer / tool reviewer 决策、路由与审查结果模型。",
    legacyReferences: [
      "src/agent_core/ta-pool-review",
      "src/agent_core/ta-pool-tool-review",
    ],
  )
}
