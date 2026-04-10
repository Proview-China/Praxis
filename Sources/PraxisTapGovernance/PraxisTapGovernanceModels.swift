import PraxisCapabilityContracts
import PraxisTapTypes

public struct PraxisTapGovernanceObject: Sendable, Equatable, Codable {
  public let mode: PraxisTapMode
  public let riskLevel: PraxisTapRiskLevel
  public let capabilityIDs: [PraxisCapabilityID]

  public init(mode: PraxisTapMode, riskLevel: PraxisTapRiskLevel, capabilityIDs: [PraxisCapabilityID]) {
    self.mode = mode
    self.riskLevel = riskLevel
    self.capabilityIDs = capabilityIDs
  }
}

public struct PraxisGovernanceSnapshot: Sendable, Equatable, Codable {
  public let governance: PraxisTapGovernanceObject
  public let summary: String

  public init(governance: PraxisTapGovernanceObject, summary: String) {
    self.governance = governance
    self.summary = summary
  }
}

public struct PraxisModePolicy: Sendable, Equatable, Codable {
  public let mode: PraxisTapMode
  public let description: String

  public init(mode: PraxisTapMode, description: String) {
    self.mode = mode
    self.description = description
  }
}
