import PraxisTapTypes

public enum PraxisAvailabilityState: String, Sendable, Codable {
  case available
  case gated
  case degraded
  case unavailable
}

public struct PraxisTapGateRule: Sendable, Equatable, Codable {
  public let summary: String
  public let requiredMode: PraxisTapMode

  public init(summary: String, requiredMode: PraxisTapMode) {
    self.summary = summary
    self.requiredMode = requiredMode
  }
}

public enum PraxisTapFailureTaxonomy: String, Sendable, Codable {
  case policyBlocked
  case reviewFailed
  case dependencyMissing
  case runtimeUnavailable
}

public struct PraxisAvailabilityReport: Sendable, Equatable, Codable {
  public let state: PraxisAvailabilityState
  public let summary: String

  public init(state: PraxisAvailabilityState, summary: String) {
    self.state = state
    self.summary = summary
  }
}
