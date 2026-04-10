import PraxisCapabilityContracts

public protocol PraxisCapabilityResultNormalizing: Sendable {
  func normalize(rawSummary: String, capabilityID: PraxisCapabilityID) -> PraxisCapabilityResultEnvelope
}

public struct PraxisDefaultCapabilityResultNormalizer: Sendable {
  public init() {}
}
