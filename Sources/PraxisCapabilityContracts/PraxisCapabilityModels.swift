import PraxisCoreTypes

public struct PraxisCapabilityID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisCapabilityManifest: Sendable, Equatable, Codable {
  public let id: PraxisCapabilityID
  public let name: String
  public let summary: String

  public init(id: PraxisCapabilityID, name: String, summary: String) {
    self.id = id
    self.name = name
    self.summary = summary
  }
}

public struct PraxisCapabilityBinding: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let bindingKey: String

  public init(capabilityID: PraxisCapabilityID, bindingKey: String) {
    self.capabilityID = capabilityID
    self.bindingKey = bindingKey
  }
}

public struct PraxisCapabilityInvocationRequest: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let inputSummary: String

  public init(capabilityID: PraxisCapabilityID, inputSummary: String) {
    self.capabilityID = capabilityID
    self.inputSummary = inputSummary
  }
}

public struct PraxisCapabilityExecutionPolicy: Sendable, Equatable, Codable {
  public let requiresReview: Bool
  public let prefersStructuredOutput: Bool

  public init(requiresReview: Bool, prefersStructuredOutput: Bool) {
    self.requiresReview = requiresReview
    self.prefersStructuredOutput = prefersStructuredOutput
  }
}
