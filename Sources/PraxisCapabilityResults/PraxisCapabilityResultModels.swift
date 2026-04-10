import PraxisCapabilityContracts

public struct PraxisNormalizedCapabilityOutput: Sendable, Equatable, Codable {
  public let summary: String
  public let structuredFields: [String: String]

  public init(summary: String, structuredFields: [String: String] = [:]) {
    self.summary = summary
    self.structuredFields = structuredFields
  }
}

public enum PraxisCapabilityFailure: Sendable, Equatable, Codable {
  case unavailable(String)
  case invalidResult(String)
  case executionFailed(String)
}

public struct PraxisCapabilityResultEnvelope: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let output: PraxisNormalizedCapabilityOutput?
  public let failure: PraxisCapabilityFailure?

  public init(
    capabilityID: PraxisCapabilityID,
    output: PraxisNormalizedCapabilityOutput?,
    failure: PraxisCapabilityFailure?,
  ) {
    self.capabilityID = capabilityID
    self.output = output
    self.failure = failure
  }
}
