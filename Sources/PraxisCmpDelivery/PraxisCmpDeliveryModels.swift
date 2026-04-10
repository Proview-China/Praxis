import PraxisCmpTypes

public struct PraxisContextPackage: Sendable, Equatable, Codable {
  public let id: PraxisCmpPackageID
  public let projectionID: PraxisCmpProjectionID
  public let summary: String

  public init(id: PraxisCmpPackageID, projectionID: PraxisCmpProjectionID, summary: String) {
    self.id = id
    self.projectionID = projectionID
    self.summary = summary
  }
}

public struct PraxisDispatchInstruction: Sendable, Equatable, Codable {
  public let destination: String
  public let summary: String

  public init(destination: String, summary: String) {
    self.destination = destination
    self.summary = summary
  }
}

public struct PraxisDeliveryPlan: Sendable, Equatable, Codable {
  public let contextPackage: PraxisContextPackage
  public let instructions: [PraxisDispatchInstruction]

  public init(contextPackage: PraxisContextPackage, instructions: [PraxisDispatchInstruction]) {
    self.contextPackage = contextPackage
    self.instructions = instructions
  }
}

public struct PraxisDeliveryFallbackPlan: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}
