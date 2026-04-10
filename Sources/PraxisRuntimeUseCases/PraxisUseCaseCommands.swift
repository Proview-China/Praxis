import PraxisGoal
import PraxisRun
import PraxisSession
import PraxisTapGovernance
import PraxisTapReview
import PraxisTapRuntime

public struct PraxisRunGoalCommand: Sendable, Equatable, Codable {
  public let goal: PraxisCompiledGoal
  public let sessionID: PraxisSessionID?

  public init(goal: PraxisCompiledGoal, sessionID: PraxisSessionID? = nil) {
    self.goal = goal
    self.sessionID = sessionID
  }
}

public struct PraxisResumeRunCommand: Sendable, Equatable, Codable {
  public let runID: PraxisRunID

  public init(runID: PraxisRunID) {
    self.runID = runID
  }
}

public struct PraxisTapInspection: Sendable, Equatable, Codable {
  public let summary: String
  public let governanceSnapshot: PraxisGovernanceSnapshot
  public let reviewContext: PraxisReviewContextAperture
  public let toolReviewReport: PraxisToolReviewReport
  public let runtimeSnapshot: PraxisTapRuntimeSnapshot

  public init(
    summary: String,
    governanceSnapshot: PraxisGovernanceSnapshot,
    reviewContext: PraxisReviewContextAperture,
    toolReviewReport: PraxisToolReviewReport,
    runtimeSnapshot: PraxisTapRuntimeSnapshot
  ) {
    self.summary = summary
    self.governanceSnapshot = governanceSnapshot
    self.reviewContext = reviewContext
    self.toolReviewReport = toolReviewReport
    self.runtimeSnapshot = runtimeSnapshot
  }
}

public struct PraxisCmpInspection: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let controlSurfaceSummary: String
  public let truthLayers: [String: String]
  public let issues: [String]
  public let smokeSummary: String

  public init(
    summary: String,
    projectID: String,
    controlSurfaceSummary: String,
    truthLayers: [String: String],
    issues: [String],
    smokeSummary: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.controlSurfaceSummary = controlSurfaceSummary
    self.truthLayers = truthLayers
    self.issues = issues
    self.smokeSummary = smokeSummary
  }
}
