import PraxisCmpTypes
import PraxisRun
import PraxisRuntimeFacades
import PraxisSession

public enum PraxisRuntimeInterfaceResponseStatus: String, Sendable, Equatable, Codable {
  case success
  case failure
}

public enum PraxisRuntimeInterfaceErrorCode: String, Sendable, Equatable, Codable {
  case sessionNotFound = "session_not_found"
  case missingRequiredField = "missing_required_field"
  case checkpointNotFound = "checkpoint_not_found"
  case invalidInput = "invalid_input"
  case dependencyMissing = "dependency_missing"
  case unsupportedOperation = "unsupported_operation"
  case invalidTransition = "invalid_transition"
  case invariantViolation = "invariant_violation"
  case unknown = "unknown_error"
}

public enum PraxisRuntimeInterfaceCommandKind: String, Sendable, Equatable, Codable {
  case inspectArchitecture
  case runGoal
  case resumeRun
  case inspectTap
  case openCmpSession
  case readbackCmpProject
  case readbackCmpStatus
  case bootstrapCmpProject
  case ingestCmpFlow
  case commitCmpFlow
  case resolveCmpFlow
  case materializeCmpFlow
  case dispatchCmpFlow
  case requestCmpHistory
  case smokeCmpProject
  case inspectCmp
  case inspectMp
  case buildCapabilityCatalog
}

/// Stable opaque handle used to address one runtime interface session inside a registry.
///
/// This handle identifies the interface-side session lifecycle only. It does not imply an
/// isolated runtime persistence sandbox, because multiple handles may still share the same
/// host-backed stores underneath the facade layer.
public struct PraxisRuntimeInterfaceSessionHandle: RawRepresentable, Hashable, Sendable, Equatable, Codable {
  public let rawValue: String

  /// Creates a session handle from a stable raw value.
  ///
  /// - Parameter rawValue: Opaque handle identifier managed by the registry layer.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisRuntimeInterfaceRunGoalRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let goalID: String
  public let goalTitle: String
  public let sessionID: String?

  public init(
    payloadSummary: String,
    goalID: String,
    goalTitle: String,
    sessionID: String? = nil
  ) {
    self.payloadSummary = payloadSummary
    self.goalID = goalID
    self.goalTitle = goalTitle
    self.sessionID = sessionID
  }
}

public struct PraxisRuntimeInterfaceResumeRunRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let runID: String

  public init(payloadSummary: String, runID: String) {
    self.payloadSummary = payloadSummary
    self.runID = runID
  }
}

public struct PraxisRuntimeInterfaceOpenCmpSessionRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let sessionID: String?

  public init(
    payloadSummary: String,
    projectID: String,
    sessionID: String? = nil
  ) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
    self.sessionID = sessionID
  }
}

public struct PraxisRuntimeInterfaceCmpProjectRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String

  public init(payloadSummary: String, projectID: String) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
  }
}

public struct PraxisRuntimeInterfaceCmpStatusRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let agentID: String?

  public init(
    payloadSummary: String,
    projectID: String,
    agentID: String? = nil
  ) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
    self.agentID = agentID
  }
}

public struct PraxisRuntimeInterfaceBootstrapCmpProjectRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let agentIDs: [String]
  public let defaultAgentID: String?
  public let repoName: String?
  public let repoRootPath: String?
  public let defaultBranchName: String?
  public let databaseName: String?
  public let namespaceRoot: String?

  public init(
    payloadSummary: String,
    projectID: String,
    agentIDs: [String] = [],
    defaultAgentID: String? = nil,
    repoName: String? = nil,
    repoRootPath: String? = nil,
    defaultBranchName: String? = nil,
    databaseName: String? = nil,
    namespaceRoot: String? = nil
  ) {
    self.payloadSummary = payloadSummary
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

public struct PraxisRuntimeInterfaceIngestCmpFlowRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
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
    payloadSummary: String,
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
    self.payloadSummary = payloadSummary
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

public struct PraxisRuntimeInterfaceCommitCmpFlowRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
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
    payloadSummary: String,
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
    self.payloadSummary = payloadSummary
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

public struct PraxisRuntimeInterfaceResolveCmpFlowRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let agentID: String
  public let lineageID: String?
  public let branchRef: String?

  public init(
    payloadSummary: String,
    projectID: String,
    agentID: String,
    lineageID: String? = nil,
    branchRef: String? = nil
  ) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
    self.agentID = agentID
    self.lineageID = lineageID
    self.branchRef = branchRef
  }
}

public struct PraxisRuntimeInterfaceMaterializeCmpFlowRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let agentID: String
  public let targetAgentID: String
  public let snapshotID: String?
  public let projectionID: String?
  public let packageKind: PraxisCmpContextPackageKind
  public let fidelityLabel: PraxisCmpContextPackageFidelityLabel?

  public init(
    payloadSummary: String,
    projectID: String,
    agentID: String,
    targetAgentID: String,
    snapshotID: String? = nil,
    projectionID: String? = nil,
    packageKind: PraxisCmpContextPackageKind,
    fidelityLabel: PraxisCmpContextPackageFidelityLabel? = nil
  ) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.snapshotID = snapshotID
    self.projectionID = projectionID
    self.packageKind = packageKind
    self.fidelityLabel = fidelityLabel
  }
}

public struct PraxisRuntimeInterfaceDispatchCmpFlowRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let agentID: String
  public let contextPackage: PraxisCmpContextPackage
  public let targetKind: PraxisCmpDispatchTargetKind
  public let reason: String

  public init(
    payloadSummary: String,
    projectID: String,
    agentID: String,
    contextPackage: PraxisCmpContextPackage,
    targetKind: PraxisCmpDispatchTargetKind,
    reason: String
  ) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
    self.agentID = agentID
    self.contextPackage = contextPackage
    self.targetKind = targetKind
    self.reason = reason
  }
}

public struct PraxisRuntimeInterfaceRequestCmpHistoryPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let projectID: String
  public let requesterAgentID: String
  public let reason: String
  public let query: PraxisCmpHistoricalContextQuery

  public init(
    payloadSummary: String,
    projectID: String,
    requesterAgentID: String,
    reason: String,
    query: PraxisCmpHistoricalContextQuery
  ) {
    self.payloadSummary = payloadSummary
    self.projectID = projectID
    self.requesterAgentID = requesterAgentID
    self.reason = reason
    self.query = query
  }
}

public enum PraxisRuntimeInterfaceRequest: Sendable, Equatable, Codable {
  case inspectArchitecture
  case runGoal(PraxisRuntimeInterfaceRunGoalRequestPayload)
  case resumeRun(PraxisRuntimeInterfaceResumeRunRequestPayload)
  case inspectTap
  case openCmpSession(PraxisRuntimeInterfaceOpenCmpSessionRequestPayload)
  case readbackCmpProject(PraxisRuntimeInterfaceCmpProjectRequestPayload)
  case readbackCmpStatus(PraxisRuntimeInterfaceCmpStatusRequestPayload)
  case bootstrapCmpProject(PraxisRuntimeInterfaceBootstrapCmpProjectRequestPayload)
  case ingestCmpFlow(PraxisRuntimeInterfaceIngestCmpFlowRequestPayload)
  case commitCmpFlow(PraxisRuntimeInterfaceCommitCmpFlowRequestPayload)
  case resolveCmpFlow(PraxisRuntimeInterfaceResolveCmpFlowRequestPayload)
  case materializeCmpFlow(PraxisRuntimeInterfaceMaterializeCmpFlowRequestPayload)
  case dispatchCmpFlow(PraxisRuntimeInterfaceDispatchCmpFlowRequestPayload)
  case requestCmpHistory(PraxisRuntimeInterfaceRequestCmpHistoryPayload)
  case smokeCmpProject(PraxisRuntimeInterfaceCmpProjectRequestPayload)
  case inspectCmp
  case inspectMp
  case buildCapabilityCatalog

  public var kind: PraxisRuntimeInterfaceCommandKind {
    switch self {
    case .inspectArchitecture:
      return .inspectArchitecture
    case .runGoal:
      return .runGoal
    case .resumeRun:
      return .resumeRun
    case .inspectTap:
      return .inspectTap
    case .openCmpSession:
      return .openCmpSession
    case .readbackCmpProject:
      return .readbackCmpProject
    case .readbackCmpStatus:
      return .readbackCmpStatus
    case .bootstrapCmpProject:
      return .bootstrapCmpProject
    case .ingestCmpFlow:
      return .ingestCmpFlow
    case .commitCmpFlow:
      return .commitCmpFlow
    case .resolveCmpFlow:
      return .resolveCmpFlow
    case .materializeCmpFlow:
      return .materializeCmpFlow
    case .dispatchCmpFlow:
      return .dispatchCmpFlow
    case .requestCmpHistory:
      return .requestCmpHistory
    case .smokeCmpProject:
      return .smokeCmpProject
    case .inspectCmp:
      return .inspectCmp
    case .inspectMp:
      return .inspectMp
    case .buildCapabilityCatalog:
      return .buildCapabilityCatalog
    }
  }

  public var payloadSummary: String {
    switch self {
    case .runGoal(let payload):
      return payload.payloadSummary
    case .resumeRun(let payload):
      return payload.payloadSummary
    case .openCmpSession(let payload):
      return payload.payloadSummary
    case .readbackCmpProject(let payload):
      return payload.payloadSummary
    case .readbackCmpStatus(let payload):
      return payload.payloadSummary
    case .bootstrapCmpProject(let payload):
      return payload.payloadSummary
    case .ingestCmpFlow(let payload):
      return payload.payloadSummary
    case .commitCmpFlow(let payload):
      return payload.payloadSummary
    case .resolveCmpFlow(let payload):
      return payload.payloadSummary
    case .materializeCmpFlow(let payload):
      return payload.payloadSummary
    case .dispatchCmpFlow(let payload):
      return payload.payloadSummary
    case .requestCmpHistory(let payload):
      return payload.payloadSummary
    case .smokeCmpProject(let payload):
      return payload.payloadSummary
    case .inspectArchitecture, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return ""
    }
  }

  public var sessionID: String? {
    switch self {
    case .runGoal(let payload):
      return payload.sessionID
    case .openCmpSession(let payload):
      return payload.sessionID
    case .ingestCmpFlow(let payload):
      return payload.sessionID
    case .commitCmpFlow(let payload):
      return payload.sessionID
    case .inspectArchitecture, .resumeRun, .inspectTap, .readbackCmpProject, .readbackCmpStatus, .bootstrapCmpProject, .resolveCmpFlow, .materializeCmpFlow, .dispatchCmpFlow, .requestCmpHistory, .smokeCmpProject, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return nil
    }
  }

  public var runID: String? {
    switch self {
    case .resumeRun(let payload):
      return payload.runID
    case .ingestCmpFlow(let payload):
      return payload.runID
    case .commitCmpFlow(let payload):
      return payload.runID
    case .inspectArchitecture, .runGoal, .inspectTap, .openCmpSession, .readbackCmpProject, .readbackCmpStatus, .bootstrapCmpProject, .resolveCmpFlow, .materializeCmpFlow, .dispatchCmpFlow, .requestCmpHistory, .smokeCmpProject, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return nil
    }
  }

  public var projectID: String? {
    switch self {
    case .openCmpSession(let payload):
      return payload.projectID
    case .readbackCmpProject(let payload):
      return payload.projectID
    case .readbackCmpStatus(let payload):
      return payload.projectID
    case .bootstrapCmpProject(let payload):
      return payload.projectID
    case .ingestCmpFlow(let payload):
      return payload.projectID
    case .commitCmpFlow(let payload):
      return payload.projectID
    case .resolveCmpFlow(let payload):
      return payload.projectID
    case .materializeCmpFlow(let payload):
      return payload.projectID
    case .dispatchCmpFlow(let payload):
      return payload.projectID
    case .requestCmpHistory(let payload):
      return payload.projectID
    case .smokeCmpProject(let payload):
      return payload.projectID
    case .inspectArchitecture, .runGoal, .resumeRun, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case runGoal
    case resumeRun
    case openCmpSession
    case readbackCmpProject
    case readbackCmpStatus
    case bootstrapCmpProject
    case ingestCmpFlow
    case commitCmpFlow
    case resolveCmpFlow
    case materializeCmpFlow
    case dispatchCmpFlow
    case requestCmpHistory
    case smokeCmpProject
    case payloadSummary
    case goalID
    case goalTitle
    case sessionID
    case runID
    case projectID
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(PraxisRuntimeInterfaceCommandKind.self, forKey: .kind)

    switch kind {
    case .inspectArchitecture:
      self = .inspectArchitecture
    case .runGoal:
      if let payload = try container.decodeIfPresent(PraxisRuntimeInterfaceRunGoalRequestPayload.self, forKey: .runGoal) {
        self = .runGoal(payload)
      } else {
        self = .runGoal(
          .init(
            payloadSummary: try container.decodeIfPresent(String.self, forKey: .payloadSummary) ?? "",
            goalID: try container.decodeIfPresent(String.self, forKey: .goalID) ?? "external.goal",
            goalTitle: try container.decodeIfPresent(String.self, forKey: .goalTitle) ?? "External requested goal",
            sessionID: try container.decodeIfPresent(String.self, forKey: .sessionID)
          )
        )
      }
    case .resumeRun:
      if let payload = try container.decodeIfPresent(PraxisRuntimeInterfaceResumeRunRequestPayload.self, forKey: .resumeRun) {
        self = .resumeRun(payload)
      } else {
        self = .resumeRun(
          .init(
            payloadSummary: try container.decodeIfPresent(String.self, forKey: .payloadSummary) ?? "",
            runID: try container.decodeIfPresent(String.self, forKey: .runID) ?? ""
          )
        )
      }
    case .inspectTap:
      self = .inspectTap
    case .openCmpSession:
      self = .openCmpSession(
        try container.decode(
          PraxisRuntimeInterfaceOpenCmpSessionRequestPayload.self,
          forKey: .openCmpSession
        )
      )
    case .readbackCmpProject:
      self = .readbackCmpProject(
        try container.decode(
          PraxisRuntimeInterfaceCmpProjectRequestPayload.self,
          forKey: .readbackCmpProject
        )
      )
    case .readbackCmpStatus:
      self = .readbackCmpStatus(
        try container.decode(
          PraxisRuntimeInterfaceCmpStatusRequestPayload.self,
          forKey: .readbackCmpStatus
        )
      )
    case .bootstrapCmpProject:
      self = .bootstrapCmpProject(
        try container.decode(
          PraxisRuntimeInterfaceBootstrapCmpProjectRequestPayload.self,
          forKey: .bootstrapCmpProject
        )
      )
    case .ingestCmpFlow:
      self = .ingestCmpFlow(
        try container.decode(
          PraxisRuntimeInterfaceIngestCmpFlowRequestPayload.self,
          forKey: .ingestCmpFlow
        )
      )
    case .commitCmpFlow:
      self = .commitCmpFlow(
        try container.decode(
          PraxisRuntimeInterfaceCommitCmpFlowRequestPayload.self,
          forKey: .commitCmpFlow
        )
      )
    case .resolveCmpFlow:
      self = .resolveCmpFlow(
        try container.decode(
          PraxisRuntimeInterfaceResolveCmpFlowRequestPayload.self,
          forKey: .resolveCmpFlow
        )
      )
    case .materializeCmpFlow:
      self = .materializeCmpFlow(
        try container.decode(
          PraxisRuntimeInterfaceMaterializeCmpFlowRequestPayload.self,
          forKey: .materializeCmpFlow
        )
      )
    case .dispatchCmpFlow:
      self = .dispatchCmpFlow(
        try container.decode(
          PraxisRuntimeInterfaceDispatchCmpFlowRequestPayload.self,
          forKey: .dispatchCmpFlow
        )
      )
    case .requestCmpHistory:
      self = .requestCmpHistory(
        try container.decode(
          PraxisRuntimeInterfaceRequestCmpHistoryPayload.self,
          forKey: .requestCmpHistory
        )
      )
    case .smokeCmpProject:
      self = .smokeCmpProject(
        try container.decode(
          PraxisRuntimeInterfaceCmpProjectRequestPayload.self,
          forKey: .smokeCmpProject
        )
      )
    case .inspectCmp:
      self = .inspectCmp
    case .inspectMp:
      self = .inspectMp
    case .buildCapabilityCatalog:
      self = .buildCapabilityCatalog
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(kind, forKey: .kind)

    switch self {
    case .runGoal(let payload):
      try container.encode(payload, forKey: .runGoal)
    case .resumeRun(let payload):
      try container.encode(payload, forKey: .resumeRun)
    case .openCmpSession(let payload):
      try container.encode(payload, forKey: .openCmpSession)
    case .readbackCmpProject(let payload):
      try container.encode(payload, forKey: .readbackCmpProject)
    case .readbackCmpStatus(let payload):
      try container.encode(payload, forKey: .readbackCmpStatus)
    case .bootstrapCmpProject(let payload):
      try container.encode(payload, forKey: .bootstrapCmpProject)
    case .ingestCmpFlow(let payload):
      try container.encode(payload, forKey: .ingestCmpFlow)
    case .commitCmpFlow(let payload):
      try container.encode(payload, forKey: .commitCmpFlow)
    case .resolveCmpFlow(let payload):
      try container.encode(payload, forKey: .resolveCmpFlow)
    case .materializeCmpFlow(let payload):
      try container.encode(payload, forKey: .materializeCmpFlow)
    case .dispatchCmpFlow(let payload):
      try container.encode(payload, forKey: .dispatchCmpFlow)
    case .requestCmpHistory(let payload):
      try container.encode(payload, forKey: .requestCmpHistory)
    case .smokeCmpProject(let payload):
      try container.encode(payload, forKey: .smokeCmpProject)
    case .inspectArchitecture, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      break
    }
  }
}

public enum PraxisRuntimeInterfaceSnapshotKind: String, Sendable, Equatable, Codable {
  case architecture
  case run
  case cmpSession
  case cmpProject
  case cmpStatus
  case cmpBootstrap
  case cmpFlow
  case smoke
  case inspection
  case catalog
}

public struct PraxisRuntimeInterfaceSnapshot: Sendable, Equatable, Codable {
  public let kind: PraxisRuntimeInterfaceSnapshotKind
  public let title: String
  public let summary: String
  public let projectID: String?
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?
  public let phase: PraxisRunPhase?
  public let tickCount: Int?
  public let lifecycleDisposition: PraxisRunLifecycleDisposition?
  public let checkpointReference: String?
  public let pendingIntentID: String?
  public let recoveredEventCount: Int?

  public init(
    kind: PraxisRuntimeInterfaceSnapshotKind,
    title: String,
    summary: String,
    projectID: String? = nil,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil,
    phase: PraxisRunPhase? = nil,
    tickCount: Int? = nil,
    lifecycleDisposition: PraxisRunLifecycleDisposition? = nil,
    checkpointReference: String? = nil,
    pendingIntentID: String? = nil,
    recoveredEventCount: Int? = nil
  ) {
    self.kind = kind
    self.title = title
    self.summary = summary
    self.projectID = projectID
    self.runID = runID
    self.sessionID = sessionID
    self.phase = phase
    self.tickCount = tickCount
    self.lifecycleDisposition = lifecycleDisposition
    self.checkpointReference = checkpointReference
    self.pendingIntentID = pendingIntentID
    self.recoveredEventCount = recoveredEventCount
  }
}

public struct PraxisRuntimeInterfaceEvent: Sendable, Equatable, Codable {
  public let name: String
  public let detail: String
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?
  public let intentID: String?

  public init(
    name: String,
    detail: String,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil,
    intentID: String? = nil
  ) {
    self.name = name
    self.detail = detail
    self.runID = runID
    self.sessionID = sessionID
    self.intentID = intentID
  }
}

public struct PraxisRuntimeInterfaceErrorEnvelope: Sendable, Equatable, Codable {
  public let code: PraxisRuntimeInterfaceErrorCode
  public let message: String
  public let retryable: Bool
  public let missingField: String?
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?

  public init(
    code: PraxisRuntimeInterfaceErrorCode,
    message: String,
    retryable: Bool = false,
    missingField: String? = nil,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil
  ) {
    self.code = code
    self.message = message
    self.retryable = retryable
    self.missingField = missingField
    self.runID = runID
    self.sessionID = sessionID
  }
}

public struct PraxisRuntimeInterfaceResponse: Sendable, Equatable, Codable {
  public let status: PraxisRuntimeInterfaceResponseStatus
  public let snapshot: PraxisRuntimeInterfaceSnapshot?
  public let events: [PraxisRuntimeInterfaceEvent]
  public let error: PraxisRuntimeInterfaceErrorEnvelope?

  public init(
    status: PraxisRuntimeInterfaceResponseStatus,
    snapshot: PraxisRuntimeInterfaceSnapshot? = nil,
    events: [PraxisRuntimeInterfaceEvent] = [],
    error: PraxisRuntimeInterfaceErrorEnvelope? = nil
  ) {
    self.status = status
    self.snapshot = snapshot
    self.events = events
    self.error = error
  }

  public static func success(
    snapshot: PraxisRuntimeInterfaceSnapshot,
    events: [PraxisRuntimeInterfaceEvent] = []
  ) -> PraxisRuntimeInterfaceResponse {
    .init(
      status: .success,
      snapshot: snapshot,
      events: events,
      error: nil
    )
  }

  public static func failure(
    error: PraxisRuntimeInterfaceErrorEnvelope,
    events: [PraxisRuntimeInterfaceEvent] = []
  ) -> PraxisRuntimeInterfaceResponse {
    .init(
      status: .failure,
      snapshot: nil,
      events: events,
      error: error
    )
  }

  public var isSuccess: Bool {
    status == .success
  }
}
