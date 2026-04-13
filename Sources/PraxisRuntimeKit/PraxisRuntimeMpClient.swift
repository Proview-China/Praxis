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

  /// Returns one memory-scoped MP client for lifecycle mutations.
  public func memory(_ memory: PraxisRuntimeMemoryRef) -> PraxisRuntimeMpMemoryClient {
    PraxisRuntimeMpMemoryClient(project: project, memory: memory, mpFacade: mpFacade)
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
