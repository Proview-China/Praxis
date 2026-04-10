public struct PraxisReviewDecisionEngine: Sendable {
  public init() {}
}

public actor PraxisReviewerCoordinator {
  public private(set) var latestDecision: PraxisReviewDecision?

  public init(latestDecision: PraxisReviewDecision? = nil) {
    self.latestDecision = latestDecision
  }
}
