import PraxisCmpTypes
import PraxisCmpSections

public enum PraxisFiveAgentRole: String, Sendable, Codable {
  case icma
  case iterator
  case checker
  case dbAgent
  case dispatcher
}

public struct PraxisAgentHandOff: Sendable, Equatable, Codable {
  public let from: PraxisFiveAgentRole
  public let to: PraxisFiveAgentRole
  public let summary: String

  public init(from: PraxisFiveAgentRole, to: PraxisFiveAgentRole, summary: String) {
    self.from = from
    self.to = to
    self.summary = summary
  }
}

public struct PraxisRoleAssignment: Sendable, Equatable, Codable {
  public let role: PraxisFiveAgentRole
  public let sectionIDs: [PraxisCmpSectionID]

  public init(role: PraxisFiveAgentRole, sectionIDs: [PraxisCmpSectionID]) {
    self.role = role
    self.sectionIDs = sectionIDs
  }
}

public struct PraxisFiveAgentProtocolDefinition: Sendable, Equatable, Codable {
  public let roles: [PraxisFiveAgentRole]
  public let handOffRules: [PraxisAgentHandOff]

  public init(roles: [PraxisFiveAgentRole], handOffRules: [PraxisAgentHandOff]) {
    self.roles = roles
    self.handOffRules = handOffRules
  }
}
