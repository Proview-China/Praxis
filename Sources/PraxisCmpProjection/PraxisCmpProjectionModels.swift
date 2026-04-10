import PraxisCheckpoint
import PraxisCmpTypes

public struct PraxisProjectionRecord: Sendable, Equatable, Codable {
  public let id: PraxisCmpProjectionID
  public let sectionIDs: [PraxisCmpSectionID]

  public init(id: PraxisCmpProjectionID, sectionIDs: [PraxisCmpSectionID]) {
    self.id = id
    self.sectionIDs = sectionIDs
  }
}

public struct PraxisMaterializationPlan: Sendable, Equatable, Codable {
  public let projectionID: PraxisCmpProjectionID
  public let summary: String

  public init(projectionID: PraxisCmpProjectionID, summary: String) {
    self.projectionID = projectionID
    self.summary = summary
  }
}

public struct PraxisVisibilityPolicy: Sendable, Equatable, Codable {
  public let scope: PraxisCmpScope
  public let summary: String

  public init(scope: PraxisCmpScope, summary: String) {
    self.scope = scope
    self.summary = summary
  }
}

public struct PraxisProjectionRecoveryPlan: Sendable, Equatable, Codable {
  public let projectionID: PraxisCmpProjectionID
  public let checkpointPointer: PraxisCheckpointPointer?

  public init(projectionID: PraxisCmpProjectionID, checkpointPointer: PraxisCheckpointPointer?) {
    self.projectionID = projectionID
    self.checkpointPointer = checkpointPointer
  }
}
