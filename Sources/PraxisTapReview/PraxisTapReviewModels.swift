import PraxisCapabilityResults
import PraxisTapTypes

public struct PraxisReviewRequest: Sendable, Equatable, Codable {
  public let reviewKind: PraxisTapReviewKind
  public let summary: String
  public let resultEnvelope: PraxisCapabilityResultEnvelope?

  public init(
    reviewKind: PraxisTapReviewKind,
    summary: String,
    resultEnvelope: PraxisCapabilityResultEnvelope? = nil,
  ) {
    self.reviewKind = reviewKind
    self.summary = summary
    self.resultEnvelope = resultEnvelope
  }
}

public enum PraxisReviewerRoute: String, Sendable, Codable {
  case autoApprove
  case toolReview
  case humanReview
  case reject
}

public struct PraxisReviewDecision: Sendable, Equatable, Codable {
  public let route: PraxisReviewerRoute
  public let summary: String

  public init(route: PraxisReviewerRoute, summary: String) {
    self.route = route
    self.summary = summary
  }
}

public struct PraxisReviewTrail: Sendable, Equatable, Codable {
  public let decisions: [PraxisReviewDecision]

  public init(decisions: [PraxisReviewDecision]) {
    self.decisions = decisions
  }
}
