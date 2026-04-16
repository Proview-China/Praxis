import PraxisCmpTypes
import PraxisMpTypes
import PraxisTapProvision
import PraxisTapRuntime
import PraxisTapTypes
import PraxisToolingContracts

/// Caller-friendly execution request for one runtime goal.
public struct PraxisRuntimeRunRequest: Sendable, Equatable {
  public let task: String
  public let sessionID: PraxisRuntimeSessionRef?

  public init(task: String, sessionID: PraxisRuntimeSessionRef? = nil) {
    self.task = task
    self.sessionID = sessionID
  }
}

/// Options for one scoped TAP overview query.
public struct PraxisRuntimeTapOverviewOptions: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef?
  public let limit: Int

  public init(agentID: PraxisRuntimeAgentRef? = nil, limit: Int = 10) {
    self.agentID = agentID
    self.limit = limit
  }
}

/// Provisioning request payload for one scoped TAP staging workflow.
public struct PraxisRuntimeTapProvisionRequest: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let targetAgentID: PraxisRuntimeAgentRef
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let requestedTier: PraxisTapCapabilityTier
  public let provisionKind: PraxisTapProvisionKind
  public let mode: PraxisTapMode?
  public let summary: String
  public let expectedArtifacts: [String]
  public let requiredVerification: [String]
  public let replayPolicy: PraxisProvisionReplayPolicy

  public init(
    agentID: PraxisRuntimeAgentRef,
    targetAgentID: PraxisRuntimeAgentRef,
    capabilityID: PraxisRuntimeCapabilityRef,
    requestedTier: PraxisTapCapabilityTier,
    provisionKind: PraxisTapProvisionKind = .capability,
    mode: PraxisTapMode? = nil,
    summary: String,
    expectedArtifacts: [String] = [],
    requiredVerification: [String] = [],
    replayPolicy: PraxisProvisionReplayPolicy = .reReviewThenDispatch
  ) {
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityID = capabilityID
    self.requestedTier = requestedTier
    self.provisionKind = provisionKind
    self.mode = mode
    self.summary = summary
    self.expectedArtifacts = expectedArtifacts
    self.requiredVerification = requiredVerification
    self.replayPolicy = replayPolicy
  }
}

/// Replay lifecycle request payload for one scoped TAP recovery transition.
public struct PraxisRuntimeTapReplayRequest: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let replayID: PraxisRuntimeReplayRef
  public let action: PraxisReplayLifecycleAction
  public let summary: String?

  public init(
    agentID: PraxisRuntimeAgentRef,
    replayID: PraxisRuntimeReplayRef,
    action: PraxisReplayLifecycleAction,
    summary: String? = nil
  ) {
    self.agentID = agentID
    self.replayID = replayID
    self.action = action
    self.summary = summary
  }
}

/// Options for one scoped CMP bootstrap call.
public struct PraxisRuntimeCmpBootstrapOptions: Sendable, Equatable {
  public let agentIDs: [PraxisRuntimeAgentRef]
  public let defaultAgentID: PraxisRuntimeAgentRef?
  public let repoName: String?
  public let repoRootPath: String?
  public let defaultBranchName: String?
  public let databaseName: String?
  public let namespaceRoot: String?

  public init(
    agentIDs: [PraxisRuntimeAgentRef] = [],
    defaultAgentID: PraxisRuntimeAgentRef? = nil,
    repoName: String? = nil,
    repoRootPath: String? = nil,
    defaultBranchName: String? = nil,
    databaseName: String? = nil,
    namespaceRoot: String? = nil
  ) {
    self.agentIDs = agentIDs
    self.defaultAgentID = defaultAgentID
    self.repoName = repoName
    self.repoRootPath = repoRootPath
    self.defaultBranchName = defaultBranchName
    self.databaseName = databaseName
    self.namespaceRoot = namespaceRoot
  }
}

/// Options for one scoped CMP overview query.
public struct PraxisRuntimeCmpOverviewOptions: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef?

  public init(agentID: PraxisRuntimeAgentRef? = nil) {
    self.agentID = agentID
  }
}

/// Approval request payload for one scoped CMP approval workflow.
public struct PraxisRuntimeCmpApprovalRequest: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let targetAgentID: PraxisRuntimeAgentRef
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let requestedTier: PraxisTapCapabilityTier
  public let summary: String

  public init(
    agentID: PraxisRuntimeAgentRef,
    targetAgentID: PraxisRuntimeAgentRef,
    capabilityID: PraxisRuntimeCapabilityRef,
    requestedTier: PraxisTapCapabilityTier,
    summary: String
  ) {
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityID = capabilityID
    self.requestedTier = requestedTier
    self.summary = summary
  }
}

/// Approval decision payload for one scoped CMP approval workflow.
public struct PraxisRuntimeCmpApprovalDecisionInput: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let targetAgentID: PraxisRuntimeAgentRef
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let decision: PraxisCmpPeerApprovalDecision
  public let reviewerAgentID: PraxisRuntimeAgentRef?
  public let decisionSummary: String

  public init(
    agentID: PraxisRuntimeAgentRef,
    targetAgentID: PraxisRuntimeAgentRef,
    capabilityID: PraxisRuntimeCapabilityRef,
    decision: PraxisCmpPeerApprovalDecision,
    reviewerAgentID: PraxisRuntimeAgentRef? = nil,
    decisionSummary: String
  ) {
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityID = capabilityID
    self.decision = decision
    self.reviewerAgentID = reviewerAgentID
    self.decisionSummary = decisionSummary
  }
}

/// Query payload for one scoped CMP approval readback.
public struct PraxisRuntimeCmpApprovalQuery: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef?
  public let targetAgentID: PraxisRuntimeAgentRef?
  public let capabilityID: PraxisRuntimeCapabilityRef?

  public init(
    agentID: PraxisRuntimeAgentRef? = nil,
    targetAgentID: PraxisRuntimeAgentRef? = nil,
    capabilityID: PraxisRuntimeCapabilityRef? = nil
  ) {
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.capabilityID = capabilityID
  }
}

/// Materialization request payload for one scoped CMP package assembly.
public struct PraxisRuntimeCmpMaterializeRequest: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let targetAgentID: PraxisRuntimeAgentRef
  public let snapshotID: PraxisRuntimeCmpSnapshotRef?
  public let projectionID: PraxisRuntimeCmpProjectionRef?
  public let packageKind: PraxisCmpContextPackageKind
  public let fidelityLabel: PraxisCmpContextPackageFidelityLabel?

  public init(
    agentID: PraxisRuntimeAgentRef,
    targetAgentID: PraxisRuntimeAgentRef,
    snapshotID: PraxisRuntimeCmpSnapshotRef? = nil,
    projectionID: PraxisRuntimeCmpProjectionRef? = nil,
    packageKind: PraxisCmpContextPackageKind,
    fidelityLabel: PraxisCmpContextPackageFidelityLabel? = nil
  ) {
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.snapshotID = snapshotID
    self.projectionID = projectionID
    self.packageKind = packageKind
    self.fidelityLabel = fidelityLabel
  }
}

/// Dispatch request payload for one persisted CMP package.
public struct PraxisRuntimeCmpDispatchRequest: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let packageID: PraxisRuntimeCmpPackageRef
  public let targetKind: PraxisCmpDispatchTargetKind
  public let reason: String

  public init(
    agentID: PraxisRuntimeAgentRef,
    packageID: PraxisRuntimeCmpPackageRef,
    targetKind: PraxisCmpDispatchTargetKind,
    reason: String
  ) {
    self.agentID = agentID
    self.packageID = packageID
    self.targetKind = targetKind
    self.reason = reason
  }
}

/// Retry request payload for one persisted CMP package dispatch.
public struct PraxisRuntimeCmpRetryDispatchRequest: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let packageID: PraxisRuntimeCmpPackageRef
  public let reason: String?

  public init(
    agentID: PraxisRuntimeAgentRef,
    packageID: PraxisRuntimeCmpPackageRef,
    reason: String? = nil
  ) {
    self.agentID = agentID
    self.packageID = packageID
    self.reason = reason
  }
}

/// Search request payload for one scoped MP query.
public struct PraxisRuntimeMpSearchRequest: Sendable, Equatable {
  public let query: String
  public let scopeLevels: [PraxisMpScopeLevel]
  public let limit: Int
  public let agentID: PraxisRuntimeAgentRef?
  public let sessionID: PraxisRuntimeSessionRef?
  public let includeSuperseded: Bool

  public init(
    query: String,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 5,
    agentID: PraxisRuntimeAgentRef? = nil,
    sessionID: PraxisRuntimeSessionRef? = nil,
    includeSuperseded: Bool = false
  ) {
    self.query = query
    self.scopeLevels = scopeLevels
    self.limit = limit
    self.agentID = agentID
    self.sessionID = sessionID
    self.includeSuperseded = includeSuperseded
  }
}

/// Overview options for one scoped MP summary query.
public struct PraxisRuntimeMpOverviewOptions: Sendable, Equatable {
  public let query: String
  public let scopeLevels: [PraxisMpScopeLevel]
  public let limit: Int
  public let agentID: PraxisRuntimeAgentRef?
  public let sessionID: PraxisRuntimeSessionRef?
  public let includeSuperseded: Bool

  public init(
    query: String = "",
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 10,
    agentID: PraxisRuntimeAgentRef? = nil,
    sessionID: PraxisRuntimeSessionRef? = nil,
    includeSuperseded: Bool = false
  ) {
    self.query = query
    self.scopeLevels = scopeLevels
    self.limit = limit
    self.agentID = agentID
    self.sessionID = sessionID
    self.includeSuperseded = includeSuperseded
  }
}

/// Resolve request payload for one scoped MP workflow query.
public struct PraxisRuntimeMpResolveRequest: Sendable, Equatable {
  public let query: String
  public let requesterAgentID: PraxisRuntimeAgentRef
  public let requesterSessionID: PraxisRuntimeSessionRef?
  public let scopeLevels: [PraxisMpScopeLevel]
  public let limit: Int

  public init(
    query: String,
    requesterAgentID: PraxisRuntimeAgentRef,
    requesterSessionID: PraxisRuntimeSessionRef? = nil,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 5
  ) {
    self.query = query
    self.requesterAgentID = requesterAgentID
    self.requesterSessionID = requesterSessionID
    self.scopeLevels = scopeLevels
    self.limit = limit
  }
}

/// History request payload for one scoped MP workflow query.
public struct PraxisRuntimeMpHistoryRequest: Sendable, Equatable {
  public let query: String
  public let requesterAgentID: PraxisRuntimeAgentRef
  public let reason: String
  public let requesterSessionID: PraxisRuntimeSessionRef?
  public let scopeLevels: [PraxisMpScopeLevel]
  public let limit: Int

  public init(
    query: String,
    requesterAgentID: PraxisRuntimeAgentRef,
    reason: String,
    requesterSessionID: PraxisRuntimeSessionRef? = nil,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 5
  ) {
    self.query = query
    self.requesterAgentID = requesterAgentID
    self.reason = reason
    self.requesterSessionID = requesterSessionID
    self.scopeLevels = scopeLevels
    self.limit = limit
  }
}

/// Alignment input for one scoped MP memory mutation.
public struct PraxisRuntimeMpMemoryAlignmentInput: Sendable, Equatable {
  public let alignedAt: String?
  public let queryText: String?

  public init(alignedAt: String? = nil, queryText: String? = nil) {
    self.alignedAt = alignedAt
    self.queryText = queryText
  }
}

/// Promotion input for one scoped MP memory mutation.
public struct PraxisRuntimeMpMemoryPromotionInput: Sendable, Equatable {
  public let targetPromotionState: PraxisMpPromotionState
  public let targetSessionID: PraxisRuntimeSessionRef?
  public let promotedAt: String?
  public let reason: String?

  public init(
    targetPromotionState: PraxisMpPromotionState,
    targetSessionID: PraxisRuntimeSessionRef? = nil,
    promotedAt: String? = nil,
    reason: String? = nil
  ) {
    self.targetPromotionState = targetPromotionState
    self.targetSessionID = targetSessionID
    self.promotedAt = promotedAt
    self.reason = reason
  }
}

/// Caller-friendly request for one thin generation call.
public struct PraxisRuntimeGenerateRequest: Sendable, Equatable {
  public let prompt: String
  public let systemPrompt: String?
  public let contextSummary: String?
  public let preferredModel: String?
  public let temperature: Double?
  public let requiredCapabilities: [PraxisRuntimeCapabilityRef]

  public init(
    prompt: String,
    systemPrompt: String? = nil,
    contextSummary: String? = nil,
    preferredModel: String? = nil,
    temperature: Double? = nil,
    requiredCapabilities: [PraxisRuntimeCapabilityRef] = []
  ) {
    self.prompt = prompt
    self.systemPrompt = systemPrompt
    self.contextSummary = contextSummary
    self.preferredModel = preferredModel
    self.temperature = temperature
    self.requiredCapabilities = requiredCapabilities
  }
}

/// Caller-friendly request for one thin embedding call.
public struct PraxisRuntimeEmbeddingRequest: Sendable, Equatable {
  public let content: String
  public let preferredModel: String?

  public init(
    content: String,
    preferredModel: String? = nil
  ) {
    self.content = content
    self.preferredModel = preferredModel
  }
}

/// Caller-friendly request for one bounded code execution.
public struct PraxisRuntimeCodeRunRequest: Sendable, Equatable {
  public let summary: String
  public let runtime: PraxisCodeRuntime
  public let source: String
  public let workingDirectory: String?
  public let environment: [String: String]
  public let timeoutSeconds: Double?
  public let outputMode: PraxisToolingOutputMode

  public init(
    summary: String,
    runtime: PraxisCodeRuntime = .swift,
    source: String,
    workingDirectory: String? = nil,
    environment: [String: String] = [:],
    timeoutSeconds: Double? = nil,
    outputMode: PraxisToolingOutputMode = .buffered
  ) {
    self.summary = summary
    self.runtime = runtime
    self.source = source
    self.workingDirectory = workingDirectory
    self.environment = environment
    self.timeoutSeconds = timeoutSeconds
    self.outputMode = outputMode
  }
}

/// One workspace patch change for the bounded code patch surface.
public struct PraxisRuntimeCodePatchChange: Sendable, Equatable {
  public let path: String
  public let patch: String
  public let expectedRevisionToken: String?

  public init(
    path: String,
    patch: String,
    expectedRevisionToken: String? = nil
  ) {
    self.path = path
    self.patch = patch
    self.expectedRevisionToken = expectedRevisionToken
  }
}

/// Caller-friendly request for one bounded workspace patch execution.
public struct PraxisRuntimeCodePatchRequest: Sendable, Equatable {
  public let summary: String
  public let changes: [PraxisRuntimeCodePatchChange]

  public init(
    summary: String,
    changes: [PraxisRuntimeCodePatchChange]
  ) {
    self.summary = summary
    self.changes = changes
  }
}

/// Caller-friendly request for one bounded code sandbox contract readback.
public struct PraxisRuntimeCodeSandboxRequest: Sendable, Equatable {
  public let profile: PraxisCodeSandboxProfile
  public let workingDirectory: String?
  public let requestedRuntime: PraxisCodeRuntime

  public init(
    profile: PraxisCodeSandboxProfile = .workspaceWriteLimited,
    workingDirectory: String? = nil,
    requestedRuntime: PraxisCodeRuntime = .swift
  ) {
    self.profile = profile
    self.workingDirectory = workingDirectory
    self.requestedRuntime = requestedRuntime
  }
}

/// Caller-friendly request for one bounded shell execution.
public struct PraxisRuntimeShellRunRequest: Sendable, Equatable {
  public let summary: String
  public let command: String
  public let workingDirectory: String?
  public let environment: [String: String]
  public let timeoutSeconds: Double?
  public let outputMode: PraxisToolingOutputMode
  public let requiresPTY: Bool

  public init(
    summary: String,
    command: String,
    workingDirectory: String? = nil,
    environment: [String: String] = [:],
    timeoutSeconds: Double? = nil,
    outputMode: PraxisToolingOutputMode = .buffered,
    requiresPTY: Bool = false
  ) {
    self.summary = summary
    self.command = command
    self.workingDirectory = workingDirectory
    self.environment = environment
    self.timeoutSeconds = timeoutSeconds
    self.outputMode = outputMode
    self.requiresPTY = requiresPTY
  }
}

/// Caller-friendly request for one bounded shell approval.
public struct PraxisRuntimeShellApprovalRequest: Sendable, Equatable {
  public let projectID: PraxisRuntimeProjectRef
  public let agentID: PraxisRuntimeAgentRef
  public let targetAgentID: PraxisRuntimeAgentRef
  public let requestedTier: PraxisTapCapabilityTier
  public let summary: String

  public init(
    projectID: PraxisRuntimeProjectRef,
    agentID: PraxisRuntimeAgentRef,
    targetAgentID: PraxisRuntimeAgentRef,
    requestedTier: PraxisTapCapabilityTier,
    summary: String
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.requestedTier = requestedTier
    self.summary = summary
  }
}

/// Caller-friendly query for one bounded shell approval readback.
public struct PraxisRuntimeShellApprovalQuery: Sendable, Equatable {
  public let projectID: PraxisRuntimeProjectRef
  public let agentID: PraxisRuntimeAgentRef?
  public let targetAgentID: PraxisRuntimeAgentRef?

  public init(
    projectID: PraxisRuntimeProjectRef,
    agentID: PraxisRuntimeAgentRef? = nil,
    targetAgentID: PraxisRuntimeAgentRef? = nil
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
  }
}

/// Caller-friendly query for registered provider skill keys.
public struct PraxisRuntimeSkillListRequest: Sendable, Equatable {
  public init() {}
}

/// Caller-friendly request for one provider-skill activation.
public struct PraxisRuntimeSkillActivateRequest: Sendable, Equatable {
  public let skillKey: String
  public let reason: String?

  public init(
    skillKey: String,
    reason: String? = nil
  ) {
    self.skillKey = skillKey
    self.reason = reason
  }
}

/// Caller-friendly query for registered provider MCP tool names.
public struct PraxisRuntimeProviderMCPToolListRequest: Sendable, Equatable {
  public init() {}
}

/// Caller-friendly request for one thin tool call.
public struct PraxisRuntimeToolCallRequest: Sendable, Equatable {
  public let toolName: String
  public let summary: String
  public let serverName: String?

  public init(
    toolName: String,
    summary: String,
    serverName: String? = nil
  ) {
    self.toolName = toolName
    self.summary = summary
    self.serverName = serverName
  }
}

/// Caller-friendly request for one thin file-upload call.
public struct PraxisRuntimeFileUploadRequest: Sendable, Equatable {
  public let summary: String
  public let purpose: String?

  public init(
    summary: String,
    purpose: String? = nil
  ) {
    self.summary = summary
    self.purpose = purpose
  }
}

/// Caller-friendly request for one thin batch-submit call.
public struct PraxisRuntimeBatchSubmitRequest: Sendable, Equatable {
  public let summary: String
  public let itemCount: Int

  public init(
    summary: String,
    itemCount: Int
  ) {
    self.summary = summary
    self.itemCount = itemCount
  }
}

/// Caller-friendly request for one thin runtime-session open call.
public struct PraxisRuntimeSessionOpenRequest: Sendable, Equatable {
  public let sessionID: PraxisRuntimeSessionRef?
  public let title: String?

  public init(
    sessionID: PraxisRuntimeSessionRef? = nil,
    title: String? = nil
  ) {
    self.sessionID = sessionID
    self.title = title
  }
}

/// Caller-friendly request for one web-search call.
public struct PraxisRuntimeWebSearchRequest: Sendable, Equatable {
  public let query: String
  public let locale: String?
  public let preferredDomains: [String]
  public let limit: Int

  public init(
    query: String,
    locale: String? = nil,
    preferredDomains: [String] = [],
    limit: Int = 5
  ) {
    self.query = query
    self.locale = locale
    self.preferredDomains = preferredDomains
    self.limit = limit
  }
}

/// Caller-friendly request for one fetched search candidate.
public struct PraxisRuntimeSearchFetchRequest: Sendable, Equatable {
  public let url: String
  public let preferredTitle: String?
  public let captureSnapshot: Bool
  public let waitPolicy: PraxisBrowserWaitPolicy
  public let timeoutSeconds: Double?

  public init(
    url: String,
    preferredTitle: String? = nil,
    captureSnapshot: Bool = true,
    waitPolicy: PraxisBrowserWaitPolicy = .domReady,
    timeoutSeconds: Double? = 2
  ) {
    self.url = url
    self.preferredTitle = preferredTitle
    self.captureSnapshot = captureSnapshot
    self.waitPolicy = waitPolicy
    self.timeoutSeconds = timeoutSeconds
  }
}

/// Caller-friendly request for one grounded search candidate.
public struct PraxisRuntimeSearchGroundRequest: Sendable, Equatable {
  public let taskSummary: String
  public let exampleURL: String?
  public let requestedFacts: [String]
  public let locale: String?
  public let maxPages: Int

  public init(
    taskSummary: String,
    exampleURL: String? = nil,
    requestedFacts: [String] = [],
    locale: String? = nil,
    maxPages: Int = 5
  ) {
    self.taskSummary = taskSummary
    self.exampleURL = exampleURL
    self.requestedFacts = requestedFacts
    self.locale = locale
    self.maxPages = maxPages
  }
}

/// Archive input for one scoped MP memory mutation.
public struct PraxisRuntimeMpMemoryArchiveInput: Sendable, Equatable {
  public let archivedAt: String?
  public let reason: String?

  public init(archivedAt: String? = nil, reason: String? = nil) {
    self.archivedAt = archivedAt
    self.reason = reason
  }
}
