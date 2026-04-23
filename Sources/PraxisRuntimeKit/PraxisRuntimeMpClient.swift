import PraxisCmpTypes
import PraxisMpTypes
import PraxisRuntimeFacades

/// Caller-friendly MP entrypoint that groups project-scoped search and memory workflows.
///
/// This surface keeps transport-neutral MP commands behind a narrower Swift framework API.
public struct PraxisRuntimeMpClient: Sendable {
  private let mpFacade: PraxisMpFacade
  private let inspectionFacade: PraxisInspectionFacade

  init(mpFacade: PraxisMpFacade, inspectionFacade: PraxisInspectionFacade) {
    self.mpFacade = mpFacade
    self.inspectionFacade = inspectionFacade
  }

  /// Reads the current MP inspection snapshot.
  ///
  /// - Returns: An MP inspection snapshot projected by the runtime facade.
  /// - Throws: Any inspection error raised by the underlying runtime use cases.
  public func inspect() async throws -> PraxisMpInspectionSnapshot {
    try await inspectionFacade.inspectMp()
  }

  /// Creates an MP client scoped to one project identifier.
  ///
  /// - Parameter project: Stable project identifier used for follow-up MP calls.
  /// - Returns: A project-scoped MP client.
  public func project(_ project: PraxisRuntimeProjectRef) -> PraxisRuntimeMpProjectClient {
    PraxisRuntimeMpProjectClient(project: project, mpFacade: mpFacade)
  }
}

/// Project-scoped MP surface for repeated search, readback, and memory lifecycle calls.
public struct PraxisRuntimeMpProjectClient: Sendable {
  private let project: PraxisRuntimeProjectRef
  private let mpFacade: PraxisMpFacade

  init(project: PraxisRuntimeProjectRef, mpFacade: PraxisMpFacade) {
    self.project = project
    self.mpFacade = mpFacade
  }

  /// Searches MP memory records for the scoped project.
  ///
  /// - Parameter request: Structured MP search request for one project query.
  /// - Returns: An MP search snapshot projected by the runtime facade.
  /// - Throws: Any search error raised by the underlying runtime use cases.
  public func search(
    _ request: PraxisRuntimeMpSearchRequest
  ) async throws -> PraxisMpSearchSnapshot {
    try await mpFacade.search(
      .init(
        projectID: project.rawValue,
        query: request.query,
        scopeLevels: request.scopeLevels,
        limit: request.limit,
        agentID: request.agentID?.rawValue,
        sessionID: request.sessionID?.rawValue,
        includeSuperseded: request.includeSuperseded
      )
    )
  }

  /// Searches MP memory records from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - query: Search query string.
  ///   - scopeLevels: Scope levels to include in the search.
  ///   - limit: Maximum number of hits to return.
  ///   - agent: Optional agent filter.
  ///   - session: Optional session filter.
  ///   - includeSuperseded: Whether superseded records should remain visible.
  /// - Returns: An MP search snapshot projected by the runtime facade.
  /// - Throws: Any search error raised by the underlying runtime use cases.
  public func search(
    query: String,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 5,
    agent: PraxisRuntimeAgentRef? = nil,
    session: PraxisRuntimeSessionRef? = nil,
    includeSuperseded: Bool = false
  ) async throws -> PraxisMpSearchSnapshot {
    try await search(
      .init(
        query: query,
        scopeLevels: scopeLevels,
        limit: limit,
        agentID: agent,
        sessionID: session,
        includeSuperseded: includeSuperseded
      )
    )
  }

  /// Reads one MP project overview for the scoped project.
  ///
  /// - Parameter options: Structured MP overview options for one project read.
  /// - Returns: An MP project overview composed from readback and smoke snapshots.
  /// - Throws: Any readback or smoke error raised by the underlying runtime use cases.
  public func overview(
    _ options: PraxisRuntimeMpOverviewOptions = .init()
  ) async throws -> PraxisRuntimeMpProjectOverview {
    async let readback = mpFacade.readback(
      .init(
        projectID: project.rawValue,
        query: options.query,
        scopeLevels: options.scopeLevels,
        limit: options.limit,
        agentID: options.agentID?.rawValue,
        sessionID: options.sessionID?.rawValue,
        includeSuperseded: options.includeSuperseded
      )
    )
    async let smoke = mpFacade.smoke(.init(projectID: project.rawValue))

    return try await PraxisRuntimeMpProjectOverview(
      readback: readback,
      smoke: smoke
    )
  }

  /// Reads one MP project overview from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - readbackQuery: Optional overview query string.
  ///   - scopeLevels: Scope levels to include in the overview readback.
  ///   - limit: Maximum number of records to summarize.
  ///   - agent: Optional agent filter.
  ///   - session: Optional session filter.
  ///   - includeSuperseded: Whether superseded records should remain visible.
  /// - Returns: An MP project overview composed from readback and smoke snapshots.
  /// - Throws: Any readback or smoke error raised by the underlying runtime use cases.
  public func overview(
    readbackQuery: String = "",
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 10,
    agent: PraxisRuntimeAgentRef? = nil,
    session: PraxisRuntimeSessionRef? = nil,
    includeSuperseded: Bool = false
  ) async throws -> PraxisRuntimeMpProjectOverview {
    try await overview(
      .init(
        query: readbackQuery,
        scopeLevels: scopeLevels,
        limit: limit,
        agentID: agent,
        sessionID: session,
        includeSuperseded: includeSuperseded
      )
    )
  }

  /// Resolves one MP workflow bundle for the scoped project.
  ///
  /// - Parameter request: Structured MP resolve request for one project query.
  /// - Returns: An MP resolve snapshot projected by the runtime facade.
  /// - Throws: Any resolve error raised by the underlying runtime use cases.
  public func resolve(
    _ request: PraxisRuntimeMpResolveRequest
  ) async throws -> PraxisMpResolveSnapshot {
    try await mpFacade.resolve(
      .init(
        projectID: project.rawValue,
        query: request.query,
        requesterAgentID: request.requesterAgentID.rawValue,
        requesterSessionID: request.requesterSessionID?.rawValue,
        scopeLevels: request.scopeLevels,
        limit: request.limit
      )
    )
  }

  /// Resolves one MP workflow bundle from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - query: Resolve query string.
  ///   - requesterAgent: Requesting agent identifier.
  ///   - requesterSession: Optional requesting session identifier.
  ///   - scopeLevels: Scope levels to include during resolution.
  ///   - limit: Maximum number of records to resolve.
  /// - Returns: An MP resolve snapshot projected by the runtime facade.
  /// - Throws: Any resolve error raised by the underlying runtime use cases.
  public func resolve(
    query: String,
    requesterAgent: PraxisRuntimeAgentRef,
    requesterSession: PraxisRuntimeSessionRef? = nil,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 5
  ) async throws -> PraxisMpResolveSnapshot {
    try await resolve(
      .init(
        query: query,
        requesterAgentID: requesterAgent,
        requesterSessionID: requesterSession,
        scopeLevels: scopeLevels,
        limit: limit
      )
    )
  }

  /// Requests historical MP context for the scoped project.
  ///
  /// - Parameter request: Structured MP history request for one project query.
  /// - Returns: An MP history snapshot projected by the runtime facade.
  /// - Throws: Any history error raised by the underlying runtime use cases.
  public func history(
    _ request: PraxisRuntimeMpHistoryRequest
  ) async throws -> PraxisMpHistorySnapshot {
    try await mpFacade.requestHistory(
      .init(
        projectID: project.rawValue,
        requesterAgentID: request.requesterAgentID.rawValue,
        requesterSessionID: request.requesterSessionID?.rawValue,
        reason: request.reason,
        query: request.query,
        scopeLevels: request.scopeLevels,
        limit: request.limit
      )
    )
  }

  /// Requests historical MP context from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - query: History query string.
  ///   - requesterAgent: Requesting agent identifier.
  ///   - reason: Human-readable history reason.
  ///   - requesterSession: Optional requesting session identifier.
  ///   - scopeLevels: Scope levels to include in the history request.
  ///   - limit: Maximum number of records to return.
  /// - Returns: An MP history snapshot projected by the runtime facade.
  /// - Throws: Any history error raised by the underlying runtime use cases.
  public func history(
    query: String,
    requesterAgent: PraxisRuntimeAgentRef,
    reason: String,
    requesterSession: PraxisRuntimeSessionRef? = nil,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    limit: Int = 5
  ) async throws -> PraxisMpHistorySnapshot {
    try await history(
      .init(
        query: query,
        requesterAgentID: requesterAgent,
        reason: reason,
        requesterSessionID: requesterSession,
        scopeLevels: scopeLevels,
        limit: limit
      )
    )
  }

  /// Reads one direct MP smoke snapshot for the scoped project.
  ///
  /// - Returns: An MP smoke snapshot projected by the runtime facade.
  /// - Throws: Any smoke error raised by the underlying runtime use cases.
  public func smoke() async throws -> PraxisMpSmokeSnapshot {
    try await mpFacade.smoke(.init(projectID: project.rawValue))
  }

  /// Ingests one MP memory record for the scoped project.
  public func ingest(_ input: PraxisRuntimeMpIngestInput) async throws -> PraxisMpIngestSnapshot {
    try await mpFacade.ingest(
      .init(
        projectID: project.rawValue,
        agentID: input.agentID.rawValue,
        sessionID: input.sessionID?.rawValue,
        scopeLevel: input.scopeLevel,
        summary: input.summary,
        checkedSnapshotRef: .init(rawValue: input.checkedSnapshotRef),
        branchRef: input.branchRef,
        storageKey: input.storageKey,
        memoryKind: input.memoryKind,
        observedAt: input.observedAt,
        capturedAt: input.capturedAt,
        semanticGroupID: input.semanticGroupID,
        tags: input.tags,
        sourceRefs: input.sourceRefs,
        confidence: input.confidence
      )
    )
  }

  /// Returns one memory-scoped MP client for lifecycle mutations.
  public func memory(_ memory: PraxisRuntimeMemoryRef) -> PraxisRuntimeMpMemoryClient {
    PraxisRuntimeMpMemoryClient(project: project, memory: memory, mpFacade: mpFacade)
  }
}

/// Caller-friendly input for one MP memory ingest operation.
public struct PraxisRuntimeMpIngestInput: Sendable, Equatable {
  public let agentID: PraxisRuntimeAgentRef
  public let sessionID: PraxisRuntimeSessionRef?
  public let scopeLevel: PraxisMpScopeLevel
  public let summary: String
  public let checkedSnapshotRef: String
  public let branchRef: String
  public let storageKey: String?
  public let memoryKind: PraxisMpMemoryKind
  public let observedAt: String?
  public let capturedAt: String?
  public let semanticGroupID: String?
  public let tags: [String]
  public let sourceRefs: [String]
  public let confidence: PraxisMpMemoryConfidenceLevel

  public init(
    agentID: PraxisRuntimeAgentRef,
    sessionID: PraxisRuntimeSessionRef? = nil,
    scopeLevel: PraxisMpScopeLevel = .agentIsolated,
    summary: String,
    checkedSnapshotRef: String,
    branchRef: String,
    storageKey: String? = nil,
    memoryKind: PraxisMpMemoryKind = .semantic,
    observedAt: String? = nil,
    capturedAt: String? = nil,
    semanticGroupID: String? = nil,
    tags: [String] = [],
    sourceRefs: [String] = [],
    confidence: PraxisMpMemoryConfidenceLevel = .medium
  ) {
    self.agentID = agentID
    self.sessionID = sessionID
    self.scopeLevel = scopeLevel
    self.summary = summary
    self.checkedSnapshotRef = checkedSnapshotRef
    self.branchRef = branchRef
    self.storageKey = storageKey
    self.memoryKind = memoryKind
    self.observedAt = observedAt
    self.capturedAt = capturedAt
    self.semanticGroupID = semanticGroupID
    self.tags = tags
    self.sourceRefs = sourceRefs
    self.confidence = confidence
  }
}

/// Aggregated MP read model for one scoped project.
public struct PraxisRuntimeMpProjectOverview: Sendable {
  public let readback: PraxisMpReadbackSnapshot
  public let smoke: PraxisMpSmokeSnapshot

  public init(
    readback: PraxisMpReadbackSnapshot,
    smoke: PraxisMpSmokeSnapshot
  ) {
    self.readback = readback
    self.smoke = smoke
  }

  /// Stable project identifier shared by the aggregated MP snapshots.
  public var projectID: String {
    readback.projectID
  }

  /// High-level MP overview summary suitable for direct caller logging.
  public var summary: String {
    readback.summary
  }

  /// MP smoke checks exposed without leaking the lower smoke result wrapper.
  public var smokeChecks: [PraxisRuntimeSmokeCheck] {
    smoke.smokeResult.checks
  }
}

/// Memory-scoped MP lifecycle surface for one persisted record.
public struct PraxisRuntimeMpMemoryClient: Sendable {
  private let project: PraxisRuntimeProjectRef
  private let memory: PraxisRuntimeMemoryRef
  private let mpFacade: PraxisMpFacade

  init(project: PraxisRuntimeProjectRef, memory: PraxisRuntimeMemoryRef, mpFacade: PraxisMpFacade) {
    self.project = project
    self.memory = memory
    self.mpFacade = mpFacade
  }

  /// Aligns one persisted MP memory for the scoped project.
  public func align(
    _ input: PraxisRuntimeMpMemoryAlignmentInput = .init()
  ) async throws -> PraxisMpAlignSnapshot {
    try await mpFacade.align(
      .init(
        projectID: project.rawValue,
        memoryID: memory.rawValue,
        alignedAt: input.alignedAt,
        queryText: input.queryText
      )
    )
  }

  /// Promotes one MP memory for the scoped project.
  public func promote(
    _ input: PraxisRuntimeMpMemoryPromotionInput
  ) async throws -> PraxisMpPromoteSnapshot {
    try await mpFacade.promote(
      .init(
        projectID: project.rawValue,
        memoryID: memory.rawValue,
        targetPromotionState: input.targetPromotionState,
        targetSessionID: input.targetSessionID?.rawValue,
        promotedAt: input.promotedAt,
        reason: input.reason
      )
    )
  }

  /// Archives one MP memory for the scoped project.
  public func archive(
    _ input: PraxisRuntimeMpMemoryArchiveInput = .init()
  ) async throws -> PraxisMpArchiveSnapshot {
    try await mpFacade.archive(
      .init(
        projectID: project.rawValue,
        memoryID: memory.rawValue,
        archivedAt: input.archivedAt,
        reason: input.reason
      )
    )
  }
}
