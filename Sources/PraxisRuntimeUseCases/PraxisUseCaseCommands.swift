import PraxisCmpDelivery
import PraxisCmpDbModel
import PraxisCmpFiveAgent
import PraxisCmpProjection
import PraxisCmpGitModel
import PraxisCmpMqModel
import PraxisCmpSections
import PraxisCmpTypes
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

public struct PraxisCmpProjectHostProfile: Sendable, Equatable, Codable {
  public let executionStyle: String
  public let structuredStore: String
  public let deliveryStore: String
  public let messageTransport: String
  public let gitAccess: String
  public let semanticIndex: String

  public init(
    executionStyle: String,
    structuredStore: String,
    deliveryStore: String,
    messageTransport: String,
    gitAccess: String,
    semanticIndex: String
  ) {
    self.executionStyle = executionStyle
    self.structuredStore = structuredStore
    self.deliveryStore = deliveryStore
    self.messageTransport = messageTransport
    self.gitAccess = gitAccess
    self.semanticIndex = semanticIndex
  }
}

public struct PraxisOpenCmpSessionCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let sessionID: String?

  public init(projectID: String, sessionID: String? = nil) {
    self.projectID = projectID
    self.sessionID = sessionID
  }
}

public struct PraxisCmpSession: Sendable, Equatable, Codable {
  public let sessionID: String
  public let projectID: String
  public let summary: String
  public let createdAt: String
  public let hostProfile: PraxisCmpProjectHostProfile
  public let issues: [String]

  public init(
    sessionID: String,
    projectID: String,
    summary: String,
    createdAt: String,
    hostProfile: PraxisCmpProjectHostProfile,
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

public struct PraxisReadbackCmpProjectCommand: Sendable, Equatable, Codable {
  public let projectID: String

  public init(projectID: String) {
    self.projectID = projectID
  }
}

public struct PraxisCmpProjectReadback: Sendable, Equatable, Codable {
  public let projectID: String
  public let summary: String
  public let hostSummary: String
  public let persistenceSummary: String
  public let coordinationSummary: String
  public let hostProfile: PraxisCmpProjectHostProfile
  public let componentStatuses: [String: String]
  public let issues: [String]

  public init(
    projectID: String,
    summary: String,
    hostSummary: String,
    persistenceSummary: String,
    coordinationSummary: String,
    hostProfile: PraxisCmpProjectHostProfile,
    componentStatuses: [String: String],
    issues: [String]
  ) {
    self.projectID = projectID
    self.summary = summary
    self.hostSummary = hostSummary
    self.persistenceSummary = persistenceSummary
    self.coordinationSummary = coordinationSummary
    self.hostProfile = hostProfile
    self.componentStatuses = componentStatuses
    self.issues = issues
  }
}

public struct PraxisBootstrapCmpProjectCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentIDs: [String]
  public let defaultAgentID: String?
  public let repoName: String?
  public let repoRootPath: String?
  public let defaultBranchName: String?
  public let databaseName: String?
  public let namespaceRoot: String?

  public init(
    projectID: String,
    agentIDs: [String] = [],
    defaultAgentID: String? = nil,
    repoName: String? = nil,
    repoRootPath: String? = nil,
    defaultBranchName: String? = nil,
    databaseName: String? = nil,
    namespaceRoot: String? = nil
  ) {
    self.projectID = projectID
    self.agentIDs = agentIDs
    self.defaultAgentID = defaultAgentID
    self.repoName = repoName
    self.repoRootPath = repoRootPath
    self.defaultBranchName = defaultBranchName
    self.databaseName = databaseName
    self.namespaceRoot = namespaceRoot
  }
}

public struct PraxisCmpProjectBootstrap: Sendable, Equatable, Codable {
  public let projectID: String
  public let summary: String
  public let hostSummary: String
  public let persistenceSummary: String
  public let coordinationSummary: String
  public let hostProfile: PraxisCmpProjectHostProfile
  public let gitReceipt: PraxisCmpGitBackendReceipt
  public let gitBranchRuntimes: [PraxisCmpGitBranchRuntime]
  public let dbReceipt: PraxisCmpDbBootstrapReceipt
  public let mqReceipts: [PraxisCmpMqBootstrapReceipt]
  public let lineages: [PraxisCmpAgentLineage]
  public let issues: [String]

  public init(
    projectID: String,
    summary: String,
    hostSummary: String,
    persistenceSummary: String,
    coordinationSummary: String,
    hostProfile: PraxisCmpProjectHostProfile,
    gitReceipt: PraxisCmpGitBackendReceipt,
    gitBranchRuntimes: [PraxisCmpGitBranchRuntime],
    dbReceipt: PraxisCmpDbBootstrapReceipt,
    mqReceipts: [PraxisCmpMqBootstrapReceipt],
    lineages: [PraxisCmpAgentLineage],
    issues: [String]
  ) {
    self.projectID = projectID
    self.summary = summary
    self.hostSummary = hostSummary
    self.persistenceSummary = persistenceSummary
    self.coordinationSummary = coordinationSummary
    self.hostProfile = hostProfile
    self.gitReceipt = gitReceipt
    self.gitBranchRuntimes = gitBranchRuntimes
    self.dbReceipt = dbReceipt
    self.mqReceipts = mqReceipts
    self.lineages = lineages
    self.issues = issues
  }
}

public struct PraxisIngestCmpFlowCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let sessionID: String
  public let runID: String?
  public let lineageID: String?
  public let parentAgentID: String?
  public let taskSummary: String
  public let materials: [PraxisCmpRuntimeContextMaterial]
  public let requiresActiveSync: Bool

  public init(
    projectID: String,
    agentID: String,
    sessionID: String,
    runID: String? = nil,
    lineageID: String? = nil,
    parentAgentID: String? = nil,
    taskSummary: String,
    materials: [PraxisCmpRuntimeContextMaterial],
    requiresActiveSync: Bool = false
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.sessionID = sessionID
    self.runID = runID
    self.lineageID = lineageID
    self.parentAgentID = parentAgentID
    self.taskSummary = taskSummary
    self.materials = materials
    self.requiresActiveSync = requiresActiveSync
  }
}

public struct PraxisCmpFlowIngest: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let sessionID: String
  public let summary: String
  public let requestID: PraxisCmpRequestID
  public let result: PraxisIngestRuntimeContextResult
  public let ingress: PraxisSectionIngressRecord
  public let loweredSections: [PraxisSectionLoweringPlan]
  public let roleAssignments: [PraxisRoleAssignment]

  public init(
    projectID: String,
    agentID: String,
    sessionID: String,
    summary: String,
    requestID: PraxisCmpRequestID,
    result: PraxisIngestRuntimeContextResult,
    ingress: PraxisSectionIngressRecord,
    loweredSections: [PraxisSectionLoweringPlan],
    roleAssignments: [PraxisRoleAssignment]
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.sessionID = sessionID
    self.summary = summary
    self.requestID = requestID
    self.result = result
    self.ingress = ingress
    self.loweredSections = loweredSections
    self.roleAssignments = roleAssignments
  }
}

public struct PraxisCommitCmpFlowCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let sessionID: String
  public let runID: String?
  public let lineageID: String?
  public let parentAgentID: String?
  public let eventIDs: [String]
  public let baseRef: String?
  public let changeSummary: String
  public let syncIntent: PraxisCmpContextSyncIntent

  public init(
    projectID: String,
    agentID: String,
    sessionID: String,
    runID: String? = nil,
    lineageID: String? = nil,
    parentAgentID: String? = nil,
    eventIDs: [String],
    baseRef: String? = nil,
    changeSummary: String,
    syncIntent: PraxisCmpContextSyncIntent
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.sessionID = sessionID
    self.runID = runID
    self.lineageID = lineageID
    self.parentAgentID = parentAgentID
    self.eventIDs = eventIDs
    self.baseRef = baseRef
    self.changeSummary = changeSummary
    self.syncIntent = syncIntent
  }
}

public struct PraxisCmpFlowCommit: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let summary: String
  public let result: PraxisCommitContextDeltaResult
  public let snapshotCandidate: PraxisCmpSnapshotCandidate
  public let activeLine: PraxisCmpActiveLineRecord

  public init(
    projectID: String,
    agentID: String,
    summary: String,
    result: PraxisCommitContextDeltaResult,
    snapshotCandidate: PraxisCmpSnapshotCandidate,
    activeLine: PraxisCmpActiveLineRecord
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.summary = summary
    self.result = result
    self.snapshotCandidate = snapshotCandidate
    self.activeLine = activeLine
  }
}

public struct PraxisResolveCmpFlowCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let lineageID: String?
  public let branchRef: String?

  public init(
    projectID: String,
    agentID: String,
    lineageID: String? = nil,
    branchRef: String? = nil
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.lineageID = lineageID
    self.branchRef = branchRef
  }
}

public struct PraxisCmpFlowResolve: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let summary: String
  public let result: PraxisResolveCheckedSnapshotResult
  public let snapshot: PraxisCmpCheckedSnapshot?

  public init(
    projectID: String,
    agentID: String,
    summary: String,
    result: PraxisResolveCheckedSnapshotResult,
    snapshot: PraxisCmpCheckedSnapshot?
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.summary = summary
    self.result = result
    self.snapshot = snapshot
  }
}

public struct PraxisMaterializeCmpFlowCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let targetAgentID: String
  public let snapshotID: String?
  public let projectionID: String?
  public let packageKind: PraxisCmpContextPackageKind
  public let fidelityLabel: PraxisCmpContextPackageFidelityLabel?

  public init(
    projectID: String,
    agentID: String,
    targetAgentID: String,
    snapshotID: String? = nil,
    projectionID: String? = nil,
    packageKind: PraxisCmpContextPackageKind,
    fidelityLabel: PraxisCmpContextPackageFidelityLabel? = nil
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.snapshotID = snapshotID
    self.projectionID = projectionID
    self.packageKind = packageKind
    self.fidelityLabel = fidelityLabel
  }
}

public struct PraxisCmpFlowMaterialize: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let summary: String
  public let result: PraxisMaterializeContextPackageResult
  public let materializationPlan: PraxisMaterializationPlan

  public init(
    projectID: String,
    agentID: String,
    summary: String,
    result: PraxisMaterializeContextPackageResult,
    materializationPlan: PraxisMaterializationPlan
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.summary = summary
    self.result = result
    self.materializationPlan = materializationPlan
  }
}

public struct PraxisDispatchCmpFlowCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let contextPackage: PraxisCmpContextPackage
  public let targetKind: PraxisCmpDispatchTargetKind
  public let reason: String

  public init(
    projectID: String,
    agentID: String,
    contextPackage: PraxisCmpContextPackage,
    targetKind: PraxisCmpDispatchTargetKind,
    reason: String
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.contextPackage = contextPackage
    self.targetKind = targetKind
    self.reason = reason
  }
}

public struct PraxisCmpFlowDispatch: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let summary: String
  public let result: PraxisDispatchContextPackageResult
  public let deliveryPlan: PraxisDeliveryPlan

  public init(
    projectID: String,
    agentID: String,
    summary: String,
    result: PraxisDispatchContextPackageResult,
    deliveryPlan: PraxisDeliveryPlan
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.summary = summary
    self.result = result
    self.deliveryPlan = deliveryPlan
  }
}

public struct PraxisRequestCmpHistoryCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let requesterAgentID: String
  public let reason: String
  public let query: PraxisCmpHistoricalContextQuery

  public init(
    projectID: String,
    requesterAgentID: String,
    reason: String,
    query: PraxisCmpHistoricalContextQuery
  ) {
    self.projectID = projectID
    self.requesterAgentID = requesterAgentID
    self.reason = reason
    self.query = query
  }
}

public struct PraxisCmpFlowHistory: Sendable, Equatable, Codable {
  public let projectID: String
  public let requesterAgentID: String
  public let summary: String
  public let result: PraxisRequestHistoricalContextResult

  public init(
    projectID: String,
    requesterAgentID: String,
    summary: String,
    result: PraxisRequestHistoricalContextResult
  ) {
    self.projectID = projectID
    self.requesterAgentID = requesterAgentID
    self.summary = summary
    self.result = result
  }
}

public struct PraxisCmpControlSurface: Sendable, Equatable, Codable {
  public let executionStyle: String
  public let mode: String
  public let readbackPriority: String
  public let fallbackPolicy: String
  public let recoveryPreference: String
  public let automation: [String: Bool]

  public init(
    executionStyle: String,
    mode: String,
    readbackPriority: String,
    fallbackPolicy: String,
    recoveryPreference: String,
    automation: [String: Bool]
  ) {
    self.executionStyle = executionStyle
    self.mode = mode
    self.readbackPriority = readbackPriority
    self.fallbackPolicy = fallbackPolicy
    self.recoveryPreference = recoveryPreference
    self.automation = automation
  }
}

public struct PraxisCmpRoleReadback: Sendable, Equatable, Codable {
  public let role: PraxisFiveAgentRole
  public let assignmentCount: Int
  public let latestStage: String?
  public let summary: String

  public init(
    role: PraxisFiveAgentRole,
    assignmentCount: Int,
    latestStage: String? = nil,
    summary: String
  ) {
    self.role = role
    self.assignmentCount = assignmentCount
    self.latestStage = latestStage
    self.summary = summary
  }
}

public struct PraxisCmpObjectModelReadback: Sendable, Equatable, Codable {
  public let projectionCount: Int
  public let snapshotCount: Int
  public let packageCount: Int
  public let deliveryCount: Int
  public let packageStatusCounts: [String: Int]

  public init(
    projectionCount: Int,
    snapshotCount: Int,
    packageCount: Int,
    deliveryCount: Int,
    packageStatusCounts: [String: Int]
  ) {
    self.projectionCount = projectionCount
    self.snapshotCount = snapshotCount
    self.packageCount = packageCount
    self.deliveryCount = deliveryCount
    self.packageStatusCounts = packageStatusCounts
  }
}

public struct PraxisReadbackCmpStatusCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String?

  public init(projectID: String, agentID: String? = nil) {
    self.projectID = projectID
    self.agentID = agentID
  }
}

public struct PraxisCmpStatusReadback: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String?
  public let summary: String
  public let control: PraxisCmpControlSurface
  public let roles: [PraxisCmpRoleReadback]
  public let objectModel: PraxisCmpObjectModelReadback
  public let latestPackageID: String?
  public let latestDispatchStatus: String?
  public let latestTargetAgentID: String?
  public let issues: [String]

  public init(
    projectID: String,
    agentID: String? = nil,
    summary: String,
    control: PraxisCmpControlSurface,
    roles: [PraxisCmpRoleReadback],
    objectModel: PraxisCmpObjectModelReadback,
    latestPackageID: String? = nil,
    latestDispatchStatus: String? = nil,
    latestTargetAgentID: String? = nil,
    issues: [String]
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.summary = summary
    self.control = control
    self.roles = roles
    self.objectModel = objectModel
    self.latestPackageID = latestPackageID
    self.latestDispatchStatus = latestDispatchStatus
    self.latestTargetAgentID = latestTargetAgentID
    self.issues = issues
  }
}

public struct PraxisRuntimeSmokeCheckRecord: Sendable, Equatable, Codable, Identifiable {
  public let id: String
  public let gate: String
  public let status: String
  public let summary: String

  public init(id: String, gate: String, status: String, summary: String) {
    self.id = id
    self.gate = gate
    self.status = status
    self.summary = summary
  }
}

public struct PraxisSmokeCmpProjectCommand: Sendable, Equatable, Codable {
  public let projectID: String

  public init(projectID: String) {
    self.projectID = projectID
  }
}

public struct PraxisCmpProjectSmoke: Sendable, Equatable, Codable {
  public let projectID: String
  public let summary: String
  public let checks: [PraxisRuntimeSmokeCheckRecord]

  public init(
    projectID: String,
    summary: String,
    checks: [PraxisRuntimeSmokeCheckRecord]
  ) {
    self.projectID = projectID
    self.summary = summary
    self.checks = checks
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
