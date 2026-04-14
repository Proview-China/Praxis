import PraxisCapabilityContracts
import PraxisCapabilityResults
import PraxisTapGovernance
import PraxisTapTypes

public struct PraxisReviewRequest: Sendable, Equatable, Codable {
  public let reviewKind: PraxisTapReviewKind
  public let capabilityID: PraxisCapabilityID?
  public let requestedTier: PraxisTapCapabilityTier?
  public let mode: PraxisTapMode?
  public let riskLevel: PraxisTapRiskLevel?
  public let summary: String
  public let resultEnvelope: PraxisCapabilityResultEnvelope?

  public init(
    reviewKind: PraxisTapReviewKind,
    capabilityID: PraxisCapabilityID? = nil,
    requestedTier: PraxisTapCapabilityTier? = nil,
    mode: PraxisTapMode? = nil,
    riskLevel: PraxisTapRiskLevel? = nil,
    summary: String,
    resultEnvelope: PraxisCapabilityResultEnvelope? = nil,
  ) {
    self.reviewKind = reviewKind
    self.capabilityID = capabilityID
    self.requestedTier = requestedTier
    self.mode = mode
    self.riskLevel = riskLevel
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

public enum PraxisReviewRoutingOutcome: String, Sendable, Codable {
  case baselineApproved = "baseline_approved"
  case reviewRequired = "review_required"
  case redirectedToProvisioning = "redirected_to_provisioning"
  case escalatedToHuman = "escalated_to_human"
  case denied
}

public struct PraxisReviewInventory: Sendable, Equatable, Codable {
  public let availableCapabilityIDs: [PraxisCapabilityID]
  public let pendingProvisionCapabilityIDs: [PraxisCapabilityID]
  public let readyProvisionCapabilityIDs: [PraxisCapabilityID]
  public let activeProvisionCapabilityIDs: [PraxisCapabilityID]

  public init(
    availableCapabilityIDs: [PraxisCapabilityID] = [],
    pendingProvisionCapabilityIDs: [PraxisCapabilityID] = [],
    readyProvisionCapabilityIDs: [PraxisCapabilityID] = [],
    activeProvisionCapabilityIDs: [PraxisCapabilityID] = []
  ) {
    self.availableCapabilityIDs = availableCapabilityIDs
    self.pendingProvisionCapabilityIDs = pendingProvisionCapabilityIDs
    self.readyProvisionCapabilityIDs = readyProvisionCapabilityIDs
    self.activeProvisionCapabilityIDs = activeProvisionCapabilityIDs
  }
}

public struct PraxisReviewDecision: Sendable, Equatable, Codable {
  public let route: PraxisReviewerRoute
  public let decisionKind: PraxisTapReviewDecisionKind
  public let vote: PraxisTapReviewVote?
  public let capabilityID: PraxisCapabilityID?
  public let mode: PraxisTapMode?
  public let riskLevel: PraxisTapRiskLevel?
  public let summary: String
  public let deferredReason: String?
  public let escalationTarget: String?
  public let provisionCapabilityID: PraxisCapabilityID?

  public init(
    route: PraxisReviewerRoute,
    decisionKind: PraxisTapReviewDecisionKind? = nil,
    vote: PraxisTapReviewVote? = nil,
    capabilityID: PraxisCapabilityID? = nil,
    mode: PraxisTapMode? = nil,
    riskLevel: PraxisTapRiskLevel? = nil,
    summary: String,
    deferredReason: String? = nil,
    escalationTarget: String? = nil,
    provisionCapabilityID: PraxisCapabilityID? = nil
  ) {
    self.route = route
    self.decisionKind = decisionKind ?? Self.defaultDecisionKind(for: route)
    self.vote = vote ?? Self.defaultVote(for: self.decisionKind)
    self.capabilityID = capabilityID
    self.mode = mode
    self.riskLevel = riskLevel
    self.summary = summary
    self.deferredReason = deferredReason
    self.escalationTarget = escalationTarget
    self.provisionCapabilityID = provisionCapabilityID
  }

  private static func defaultDecisionKind(for route: PraxisReviewerRoute) -> PraxisTapReviewDecisionKind {
    switch route {
    case .autoApprove:
      .approved
    case .toolReview:
      .deferred
    case .humanReview:
      .escalatedToHuman
    case .reject:
      .denied
    }
  }

  private static func defaultVote(for decisionKind: PraxisTapReviewDecisionKind) -> PraxisTapReviewVote? {
    switch decisionKind {
    case .approved:
      .allow
    case .partiallyApproved:
      .allowWithConstraints
    case .denied:
      .deny
    case .deferred:
      .deferred
    case .escalatedToHuman:
      .escalateToHuman
    case .redirectedToProvisioning:
      .redirectToProvisioning
    }
  }
}

public struct PraxisReviewRoutingResult: Sendable, Equatable, Codable {
  public let outcome: PraxisReviewRoutingOutcome
  public let policy: PraxisModePolicy
  public let decision: PraxisReviewDecision

  public init(
    outcome: PraxisReviewRoutingOutcome,
    policy: PraxisModePolicy,
    decision: PraxisReviewDecision
  ) {
    self.outcome = outcome
    self.policy = policy
    self.decision = decision
  }
}

public struct PraxisReviewTrail: Sendable, Equatable, Codable {
  public let decisions: [PraxisReviewDecision]

  public init(decisions: [PraxisReviewDecision]) {
    self.decisions = decisions
  }

  public var latestDecision: PraxisReviewDecision? {
    decisions.last
  }
}
