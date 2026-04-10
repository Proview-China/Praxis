import PraxisCmpTypes

public struct PraxisGitBranchFamily: Sendable, Equatable, Codable {
  public let lineageID: PraxisCmpLineageID
  public let branchNames: [String]

  public init(lineageID: PraxisCmpLineageID, branchNames: [String]) {
    self.lineageID = lineageID
    self.branchNames = branchNames
  }
}

public struct PraxisGitRefLifecycle: Sendable, Equatable, Codable {
  public let createdRef: String
  public let targetRef: String

  public init(createdRef: String, targetRef: String) {
    self.createdRef = createdRef
    self.targetRef = targetRef
  }
}

public struct PraxisGitLineagePolicy: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}

public struct PraxisGitSyncPlan: Sendable, Equatable, Codable {
  public let projectionID: PraxisCmpProjectionID
  public let summary: String

  public init(projectionID: PraxisCmpProjectionID, summary: String) {
    self.projectionID = projectionID
    self.summary = summary
  }
}
