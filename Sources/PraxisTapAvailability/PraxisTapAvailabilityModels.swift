import PraxisCapabilityContracts
import PraxisTapGovernance
import PraxisTapTypes

public enum PraxisAvailabilityState: String, Sendable, Codable {
  case available
  case gated
  case degraded
  case unavailable
}

public enum PraxisAvailabilityGateDecision: String, Sendable, Codable {
  case baseline
  case reviewOnly = "review_only"
  case blocked
  case pendingBacklog = "pending_backlog"
}

public struct PraxisTapGateRule: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID?
  public let summary: String
  public let requiredMode: PraxisTapMode
  public let reviewRequired: Bool

  public init(
    capabilityID: PraxisCapabilityID? = nil,
    summary: String,
    requiredMode: PraxisTapMode,
    reviewRequired: Bool = false
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.requiredMode = requiredMode
    self.reviewRequired = reviewRequired
  }
}

public enum PraxisTapFailureTaxonomy: String, Sendable, Codable {
  case policyBlocked
  case reviewFailed
  case dependencyMissing
  case runtimeUnavailable
}

public struct PraxisTapCapabilityAvailabilityRecord: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let state: PraxisAvailabilityState
  public let decision: PraxisAvailabilityGateDecision
  public let summary: String
  public let reviewRequired: Bool
  public let runtimeAllowed: Bool
  public let failures: [PraxisTapFailureTaxonomy]

  public init(
    capabilityID: PraxisCapabilityID,
    state: PraxisAvailabilityState,
    decision: PraxisAvailabilityGateDecision,
    summary: String,
    reviewRequired: Bool,
    runtimeAllowed: Bool,
    failures: [PraxisTapFailureTaxonomy] = []
  ) {
    self.capabilityID = capabilityID
    self.state = state
    self.decision = decision
    self.summary = summary
    self.reviewRequired = reviewRequired
    self.runtimeAllowed = runtimeAllowed
    self.failures = failures
  }
}

public struct PraxisAvailabilityReport: Sendable, Equatable, Codable {
  public let state: PraxisAvailabilityState
  public let summary: String
  public let records: [PraxisTapCapabilityAvailabilityRecord]

  public init(
    state: PraxisAvailabilityState,
    summary: String,
    records: [PraxisTapCapabilityAvailabilityRecord] = []
  ) {
    self.state = state
    self.summary = summary
    self.records = records
  }
}
