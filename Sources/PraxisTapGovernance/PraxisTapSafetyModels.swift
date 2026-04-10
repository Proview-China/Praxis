import PraxisTapTypes

public enum PraxisTapSafetyOutcome: String, Sendable, Codable {
  case allow
  case interrupt
  case block
  case downgrade
  case escalateToHuman
}

public struct PraxisTapSafetyInterception: Sendable, Equatable, Codable {
  public let mode: PraxisTapMode
  public let requestedTier: PraxisTapCapabilityTier?
  public let capabilityKey: String
  public let requestedOperation: String
  public let riskLevel: PraxisTapRiskLevel

  public init(
    mode: PraxisTapMode,
    requestedTier: PraxisTapCapabilityTier? = nil,
    capabilityKey: String,
    requestedOperation: String,
    riskLevel: PraxisTapRiskLevel
  ) {
    self.mode = mode
    self.requestedTier = requestedTier
    self.capabilityKey = capabilityKey
    self.requestedOperation = requestedOperation
    self.riskLevel = riskLevel
  }
}

public struct PraxisTapSafetyDecision: Sendable, Equatable, Codable {
  public let outcome: PraxisTapSafetyOutcome
  public let summary: String
  public let downgradedMode: PraxisTapMode?

  public init(
    outcome: PraxisTapSafetyOutcome,
    summary: String,
    downgradedMode: PraxisTapMode? = nil
  ) {
    self.outcome = outcome
    self.summary = summary
    self.downgradedMode = downgradedMode
  }
}
