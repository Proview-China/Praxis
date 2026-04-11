import PraxisRun
import PraxisSession
import PraxisRuntimeUseCases

/// Describes which lifecycle path produced the current run summary.
public enum PraxisRunLifecycleDisposition: String, Sendable, Equatable, Codable {
  case started
  case resumed
  case recoveredWithoutResume
}

public struct PraxisRunSummary: Sendable, Equatable, Codable {
  public let runID: PraxisRunID
  public let sessionID: PraxisSessionID
  public let phase: PraxisRunPhase
  public let tickCount: Int
  public let lifecycleDisposition: PraxisRunLifecycleDisposition
  public let journalSequence: Int?
  public let checkpointReference: String?
  public let recoveredEventCount: Int
  public let followUpAction: PraxisRunFollowUpAction?
  public let phaseSummary: String

  public init(
    runID: PraxisRunID,
    sessionID: PraxisSessionID,
    phase: PraxisRunPhase,
    tickCount: Int,
    lifecycleDisposition: PraxisRunLifecycleDisposition,
    journalSequence: Int? = nil,
    checkpointReference: String? = nil,
    recoveredEventCount: Int = 0,
    followUpAction: PraxisRunFollowUpAction? = nil,
    phaseSummary: String
  ) {
    self.runID = runID
    self.sessionID = sessionID
    self.phase = phase
    self.tickCount = tickCount
    self.lifecycleDisposition = lifecycleDisposition
    self.journalSequence = journalSequence
    self.checkpointReference = checkpointReference
    self.recoveredEventCount = recoveredEventCount
    self.followUpAction = followUpAction
    self.phaseSummary = phaseSummary
  }
}

public struct PraxisInspectionSnapshot: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}

public struct PraxisTapInspectionSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let governanceSummary: String
  public let reviewSummary: String

  public init(summary: String, governanceSummary: String, reviewSummary: String) {
    self.summary = summary
    self.governanceSummary = governanceSummary
    self.reviewSummary = reviewSummary
  }
}

public struct PraxisTapStatusSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let readinessSummary: String
  public let projectID: String
  public let agentID: String?
  public let tapMode: String
  public let riskLevel: String
  public let humanGateState: String
  public let availableCapabilityCount: Int
  public let availableCapabilityIDs: [String]
  public let pendingApprovalCount: Int
  public let approvedApprovalCount: Int
  public let latestCapabilityKey: String?
  public let latestDecisionSummary: String?

  public init(
    summary: String,
    readinessSummary: String,
    projectID: String,
    agentID: String? = nil,
    tapMode: String,
    riskLevel: String,
    humanGateState: String,
    availableCapabilityCount: Int,
    availableCapabilityIDs: [String],
    pendingApprovalCount: Int,
    approvedApprovalCount: Int,
    latestCapabilityKey: String? = nil,
    latestDecisionSummary: String? = nil
  ) {
    self.summary = summary
    self.readinessSummary = readinessSummary
    self.projectID = projectID
    self.agentID = agentID
    self.tapMode = tapMode
    self.riskLevel = riskLevel
    self.humanGateState = humanGateState
    self.availableCapabilityCount = availableCapabilityCount
    self.availableCapabilityIDs = availableCapabilityIDs
    self.pendingApprovalCount = pendingApprovalCount
    self.approvedApprovalCount = approvedApprovalCount
    self.latestCapabilityKey = latestCapabilityKey
    self.latestDecisionSummary = latestDecisionSummary
  }
}

public struct PraxisTapHistoryEntrySnapshot: Sendable, Equatable, Codable {
  public let agentID: String
  public let targetAgentID: String
  public let capabilityKey: String
  public let requestedTier: String
  public let route: String
  public let outcome: String
  public let humanGateState: String
  public let updatedAt: String
  public let decisionSummary: String

  public init(
    agentID: String,
    targetAgentID: String,
    capabilityKey: String,
    requestedTier: String,
    route: String,
    outcome: String,
    humanGateState: String,
    updatedAt: String,
    decisionSummary: String
  ) {
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityKey = capabilityKey
    self.requestedTier = requestedTier
    self.route = route
    self.outcome = outcome
    self.humanGateState = humanGateState
    self.updatedAt = updatedAt
    self.decisionSummary = decisionSummary
  }
}

public struct PraxisTapHistorySnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let totalCount: Int
  public let entries: [PraxisTapHistoryEntrySnapshot]

  public init(
    summary: String,
    projectID: String,
    agentID: String? = nil,
    totalCount: Int,
    entries: [PraxisTapHistoryEntrySnapshot]
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.totalCount = totalCount
    self.entries = entries
  }
}

public struct PraxisCmpInspectionSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let hostRuntimeSummary: String
  public let persistenceSummary: String
  public let coordinationSummary: String

  public init(
    summary: String,
    projectID: String,
    hostRuntimeSummary: String,
    persistenceSummary: String,
    coordinationSummary: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.hostRuntimeSummary = hostRuntimeSummary
    self.persistenceSummary = persistenceSummary
    self.coordinationSummary = coordinationSummary
  }
}

public struct PraxisCmpSessionSnapshot: Sendable, Equatable, Codable {
  public let sessionID: String
  public let projectID: String
  public let summary: String
  public let createdAt: String
  public let hostProfile: PraxisLocalRuntimeHostProfile
  public let issues: [String]

  public init(
    sessionID: String,
    projectID: String,
    summary: String,
    createdAt: String,
    hostProfile: PraxisLocalRuntimeHostProfile,
    issues: [String]
  ) {
    self.sessionID = sessionID
    self.projectID = projectID
    self.summary = summary
    self.createdAt = createdAt
    self.hostProfile = hostProfile
    self.issues = issues
  }
}

public struct PraxisCmpProjectReadbackSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectSummary: PraxisCmpProjectLocalRuntimeSummary
  public let persistenceSummary: String
  public let coordinationSummary: String

  public init(
    summary: String,
    projectSummary: PraxisCmpProjectLocalRuntimeSummary,
    persistenceSummary: String,
    coordinationSummary: String
  ) {
    self.summary = summary
    self.projectSummary = projectSummary
    self.persistenceSummary = persistenceSummary
    self.coordinationSummary = coordinationSummary
  }
}

public struct PraxisCmpProjectBootstrapSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectSummary: PraxisCmpProjectLocalRuntimeSummary
  public let gitSummary: String
  public let persistenceSummary: String
  public let coordinationSummary: String

  public init(
    summary: String,
    projectSummary: PraxisCmpProjectLocalRuntimeSummary,
    gitSummary: String,
    persistenceSummary: String,
    coordinationSummary: String
  ) {
    self.summary = summary
    self.projectSummary = projectSummary
    self.gitSummary = gitSummary
    self.persistenceSummary = persistenceSummary
    self.coordinationSummary = coordinationSummary
  }
}

public struct PraxisCmpFlowIngestSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let sessionID: String
  public let requestID: String
  public let acceptedEventCount: Int
  public let sectionCount: Int
  public let storedSectionCount: Int
  public let nextAction: String

  public init(
    summary: String,
    projectID: String,
    agentID: String,
    sessionID: String,
    requestID: String,
    acceptedEventCount: Int,
    sectionCount: Int,
    storedSectionCount: Int,
    nextAction: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.sessionID = sessionID
    self.requestID = requestID
    self.acceptedEventCount = acceptedEventCount
    self.sectionCount = sectionCount
    self.storedSectionCount = storedSectionCount
    self.nextAction = nextAction
  }
}

public struct PraxisCmpFlowCommitSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let deltaID: String
  public let snapshotCandidateID: String?
  public let activeLineStage: String
  public let branchRef: String

  public init(
    summary: String,
    projectID: String,
    agentID: String,
    deltaID: String,
    snapshotCandidateID: String?,
    activeLineStage: String,
    branchRef: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.deltaID = deltaID
    self.snapshotCandidateID = snapshotCandidateID
    self.activeLineStage = activeLineStage
    self.branchRef = branchRef
  }
}

public struct PraxisCmpFlowResolveSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let found: Bool
  public let snapshotID: String?
  public let branchRef: String?
  public let qualityLabel: String?

  public init(
    summary: String,
    projectID: String,
    agentID: String,
    found: Bool,
    snapshotID: String?,
    branchRef: String?,
    qualityLabel: String?
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.found = found
    self.snapshotID = snapshotID
    self.branchRef = branchRef
    self.qualityLabel = qualityLabel
  }
}

public struct PraxisCmpFlowMaterializeSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let packageID: String
  public let targetAgentID: String
  public let packageKind: String
  public let selectedSectionCount: Int

  public init(
    summary: String,
    projectID: String,
    agentID: String,
    packageID: String,
    targetAgentID: String,
    packageKind: String,
    selectedSectionCount: Int
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.packageID = packageID
    self.targetAgentID = targetAgentID
    self.packageKind = packageKind
    self.selectedSectionCount = selectedSectionCount
  }
}

public struct PraxisCmpFlowDispatchSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let dispatchID: String
  public let targetAgentID: String
  public let targetKind: String
  public let status: String

  public init(
    summary: String,
    projectID: String,
    agentID: String,
    dispatchID: String,
    targetAgentID: String,
    targetKind: String,
    status: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.dispatchID = dispatchID
    self.targetAgentID = targetAgentID
    self.targetKind = targetKind
    self.status = status
  }
}

public struct PraxisCmpFlowHistorySnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let requesterAgentID: String
  public let found: Bool
  public let snapshotID: String?
  public let packageID: String?

  public init(
    summary: String,
    projectID: String,
    requesterAgentID: String,
    found: Bool,
    snapshotID: String?,
    packageID: String?
  ) {
    self.summary = summary
    self.projectID = projectID
    self.requesterAgentID = requesterAgentID
    self.found = found
    self.snapshotID = snapshotID
    self.packageID = packageID
  }
}

public struct PraxisCmpRolesPanelSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let roleCounts: [String: Int]
  public let roleStages: [String: String]
  public let latestPackageID: String?
  public let latestDispatchStatus: String?

  public init(
    summary: String,
    projectID: String,
    agentID: String? = nil,
    roleCounts: [String: Int],
    roleStages: [String: String],
    latestPackageID: String? = nil,
    latestDispatchStatus: String? = nil
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.roleCounts = roleCounts
    self.roleStages = roleStages
    self.latestPackageID = latestPackageID
    self.latestDispatchStatus = latestDispatchStatus
  }
}

public struct PraxisCmpControlPanelSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let executionStyle: String
  public let mode: String
  public let readbackPriority: String
  public let fallbackPolicy: String
  public let recoveryPreference: String
  public let automation: [String: Bool]
  public let latestPackageID: String?
  public let latestDispatchStatus: String?
  public let latestTargetAgentID: String?

  public init(
    summary: String,
    projectID: String,
    agentID: String? = nil,
    executionStyle: String,
    mode: String,
    readbackPriority: String,
    fallbackPolicy: String,
    recoveryPreference: String,
    automation: [String: Bool],
    latestPackageID: String? = nil,
    latestDispatchStatus: String? = nil,
    latestTargetAgentID: String? = nil
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.executionStyle = executionStyle
    self.mode = mode
    self.readbackPriority = readbackPriority
    self.fallbackPolicy = fallbackPolicy
    self.recoveryPreference = recoveryPreference
    self.automation = automation
    self.latestPackageID = latestPackageID
    self.latestDispatchStatus = latestDispatchStatus
    self.latestTargetAgentID = latestTargetAgentID
  }
}

public struct PraxisCmpControlUpdateSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let executionStyle: String
  public let mode: String
  public let readbackPriority: String
  public let fallbackPolicy: String
  public let recoveryPreference: String
  public let automation: [String: Bool]
  public let storedAt: String

  public init(
    summary: String,
    projectID: String,
    agentID: String? = nil,
    executionStyle: String,
    mode: String,
    readbackPriority: String,
    fallbackPolicy: String,
    recoveryPreference: String,
    automation: [String: Bool],
    storedAt: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.executionStyle = executionStyle
    self.mode = mode
    self.readbackPriority = readbackPriority
    self.fallbackPolicy = fallbackPolicy
    self.recoveryPreference = recoveryPreference
    self.automation = automation
    self.storedAt = storedAt
  }
}

public struct PraxisCmpPeerApprovalSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let targetAgentID: String
  public let capabilityKey: String
  public let requestedTier: String
  public let route: String
  public let outcome: String
  public let tapMode: String
  public let riskLevel: String
  public let humanGateState: String
  public let requestedAt: String
  public let decisionSummary: String

  public init(
    summary: String,
    projectID: String,
    agentID: String,
    targetAgentID: String,
    capabilityKey: String,
    requestedTier: String,
    route: String,
    outcome: String,
    tapMode: String,
    riskLevel: String,
    humanGateState: String,
    requestedAt: String,
    decisionSummary: String
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityKey = capabilityKey
    self.requestedTier = requestedTier
    self.route = route
    self.outcome = outcome
    self.tapMode = tapMode
    self.riskLevel = riskLevel
    self.humanGateState = humanGateState
    self.requestedAt = requestedAt
    self.decisionSummary = decisionSummary
  }
}

public struct PraxisCmpPeerApprovalReadbackSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let targetAgentID: String?
  public let capabilityKey: String?
  public let requestedTier: String?
  public let route: String?
  public let outcome: String?
  public let tapMode: String?
  public let riskLevel: String?
  public let humanGateState: String?
  public let requestedAt: String?
  public let decisionSummary: String?
  public let found: Bool

  public init(
    summary: String,
    projectID: String,
    agentID: String? = nil,
    targetAgentID: String? = nil,
    capabilityKey: String? = nil,
    requestedTier: String? = nil,
    route: String? = nil,
    outcome: String? = nil,
    tapMode: String? = nil,
    riskLevel: String? = nil,
    humanGateState: String? = nil,
    requestedAt: String? = nil,
    decisionSummary: String? = nil,
    found: Bool
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityKey = capabilityKey
    self.requestedTier = requestedTier
    self.route = route
    self.outcome = outcome
    self.tapMode = tapMode
    self.riskLevel = riskLevel
    self.humanGateState = humanGateState
    self.requestedAt = requestedAt
    self.decisionSummary = decisionSummary
    self.found = found
  }
}

public struct PraxisCmpStatusPanelSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let executionStyle: String
  public let readbackPriority: String
  public let packageCount: Int
  public let latestPackageID: String?
  public let latestDispatchStatus: String?
  public let roleCounts: [String: Int]
  public let roleStages: [String: String]

  public init(
    summary: String,
    projectID: String,
    agentID: String? = nil,
    executionStyle: String,
    readbackPriority: String,
    packageCount: Int,
    latestPackageID: String? = nil,
    latestDispatchStatus: String? = nil,
    roleCounts: [String: Int],
    roleStages: [String: String]
  ) {
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.executionStyle = executionStyle
    self.readbackPriority = readbackPriority
    self.packageCount = packageCount
    self.latestPackageID = latestPackageID
    self.latestDispatchStatus = latestDispatchStatus
    self.roleCounts = roleCounts
    self.roleStages = roleStages
  }
}

public struct PraxisCmpProjectSmokeSnapshot: Sendable, Equatable, Codable {
  public let projectID: String
  public let smokeResult: PraxisRuntimeSmokeResult

  public init(projectID: String, smokeResult: PraxisRuntimeSmokeResult) {
    self.projectID = projectID
    self.smokeResult = smokeResult
  }
}

public struct PraxisMpInspectionSnapshot: Sendable, Equatable, Codable {
  public let summary: String
  public let workflowSummary: String
  public let memoryStoreSummary: String
  public let multimodalSummary: String

  public init(
    summary: String,
    workflowSummary: String,
    memoryStoreSummary: String,
    multimodalSummary: String
  ) {
    self.summary = summary
    self.workflowSummary = workflowSummary
    self.memoryStoreSummary = memoryStoreSummary
    self.multimodalSummary = multimodalSummary
  }
}
