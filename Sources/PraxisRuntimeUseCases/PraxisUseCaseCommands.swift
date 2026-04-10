import PraxisGoal
import PraxisRun
import PraxisSession
import PraxisTapGovernance
import PraxisTapReview
import PraxisTapRuntime
import PraxisTransition

public struct PraxisRunFollowUpAction: Sendable, Equatable, Codable {
  public let kind: PraxisStepActionKind
  public let reason: String
  public let intentID: String?
  public let intentKind: PraxisTransitionIntentKind?

  public init(
    kind: PraxisStepActionKind,
    reason: String,
    intentID: String? = nil,
    intentKind: PraxisTransitionIntentKind? = nil
  ) {
    self.kind = kind
    self.reason = reason
    self.intentID = intentID
    self.intentKind = intentKind
  }
}

public struct PraxisRunExecution: Sendable, Equatable, Codable {
  public let runID: PraxisRunID
  public let sessionID: PraxisSessionID
  public let phase: PraxisRunPhase
  public let tickCount: Int
  public let journalSequence: Int?
  public let checkpointReference: String?
  public let recoveredEventCount: Int
  public let resumeIssued: Bool
  public let followUpAction: PraxisRunFollowUpAction?

  public init(
    runID: PraxisRunID,
    sessionID: PraxisSessionID,
    phase: PraxisRunPhase,
    tickCount: Int,
    journalSequence: Int? = nil,
    checkpointReference: String? = nil,
    recoveredEventCount: Int = 0,
    resumeIssued: Bool = true,
    followUpAction: PraxisRunFollowUpAction? = nil
  ) {
    self.runID = runID
    self.sessionID = sessionID
    self.phase = phase
    self.tickCount = tickCount
    self.journalSequence = journalSequence
    self.checkpointReference = checkpointReference
    self.recoveredEventCount = recoveredEventCount
    self.resumeIssued = resumeIssued
    self.followUpAction = followUpAction
  }
}

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
  public let runtimeProfile: PraxisCmpLocalRuntimeProfile
  public let summary: String
  public let projectID: String
  public let issues: [String]
  public let hostSummary: String

  public init(
    runtimeProfile: PraxisCmpLocalRuntimeProfile,
    summary: String,
    projectID: String,
    issues: [String],
    hostSummary: String
  ) {
    self.runtimeProfile = runtimeProfile
    self.summary = summary
    self.projectID = projectID
    self.issues = issues
    self.hostSummary = hostSummary
  }
}

public struct PraxisCmpLocalRuntimeProfile: Sendable, Equatable, Codable {
  public let structuredStoreSummary: String
  public let deliveryStoreSummary: String
  public let messageBusSummary: String
  public let gitSummary: String
  public let semanticIndexSummary: String

  public init(
    structuredStoreSummary: String,
    deliveryStoreSummary: String,
    messageBusSummary: String,
    gitSummary: String,
    semanticIndexSummary: String
  ) {
    self.structuredStoreSummary = structuredStoreSummary
    self.deliveryStoreSummary = deliveryStoreSummary
    self.messageBusSummary = messageBusSummary
    self.gitSummary = gitSummary
    self.semanticIndexSummary = semanticIndexSummary
  }
}

public struct PraxisMpInspection: Sendable, Equatable, Codable {
  public let summary: String
  public let workflowSummary: String
  public let memoryStoreSummary: String
  public let multimodalSummary: String
  public let issues: [String]

  public init(
    summary: String,
    workflowSummary: String,
    memoryStoreSummary: String,
    multimodalSummary: String,
    issues: [String]
  ) {
    self.summary = summary
    self.workflowSummary = workflowSummary
    self.memoryStoreSummary = memoryStoreSummary
    self.multimodalSummary = multimodalSummary
    self.issues = issues
  }
}
