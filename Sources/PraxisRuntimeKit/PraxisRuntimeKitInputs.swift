import PraxisCmpTypes
import PraxisMpTypes
import PraxisTapTypes

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

/// Archive input for one scoped MP memory mutation.
public struct PraxisRuntimeMpMemoryArchiveInput: Sendable, Equatable {
  public let archivedAt: String?
  public let reason: String?

  public init(archivedAt: String? = nil, reason: String? = nil) {
    self.archivedAt = archivedAt
    self.reason = reason
  }
}
