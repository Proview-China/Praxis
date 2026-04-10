import PraxisCmpTypes

public struct PraxisSectionIngressRequest: Sendable, Equatable, Codable {
  public let title: String
  public let payloadSummary: String

  public init(title: String, payloadSummary: String) {
    self.title = title
    self.payloadSummary = payloadSummary
  }
}

public struct PraxisCmpSection: Sendable, Equatable, Codable {
  public let id: PraxisCmpSectionID
  public let title: String
  public let scope: PraxisCmpScope

  public init(id: PraxisCmpSectionID, title: String, scope: PraxisCmpScope) {
    self.id = id
    self.title = title
    self.scope = scope
  }
}

public struct PraxisSectionOwnershipRule: Sendable, Equatable, Codable {
  public let ownerRole: String
  public let summary: String

  public init(ownerRole: String, summary: String) {
    self.ownerRole = ownerRole
    self.summary = summary
  }
}

public struct PraxisSectionLoweringPlan: Sendable, Equatable, Codable {
  public let section: PraxisCmpSection
  public let targetSummary: String

  public init(section: PraxisCmpSection, targetSummary: String) {
    self.section = section
    self.targetSummary = targetSummary
  }
}
