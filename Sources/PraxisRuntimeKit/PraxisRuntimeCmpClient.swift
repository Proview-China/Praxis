import PraxisCapabilityContracts
import PraxisCmpTypes
import PraxisRuntimeFacades
import PraxisTapTypes

/// Caller-friendly CMP entrypoint that groups session, project, and approval operations.
///
/// This surface keeps callers on project-scoped methods instead of the lower-level facade graph.
public struct PraxisRuntimeCmpClient: Sendable {
  private let cmpFacade: PraxisCmpFacade
  private let inspectionFacade: PraxisInspectionFacade

  init(cmpFacade: PraxisCmpFacade, inspectionFacade: PraxisInspectionFacade) {
    self.cmpFacade = cmpFacade
    self.inspectionFacade = inspectionFacade
  }

  /// Reads the current CMP inspection snapshot.
  ///
  /// - Returns: A CMP inspection snapshot projected by the runtime facade.
  /// - Throws: Any inspection error raised by the underlying runtime use cases.
  public func inspect() async throws -> PraxisCmpInspectionSnapshot {
    try await inspectionFacade.inspectCmp()
  }

  /// Creates a CMP client scoped to one project identifier.
  ///
  /// - Parameter project: Stable project identifier used for follow-up CMP calls.
  /// - Returns: A project-scoped CMP client.
  public func project(_ project: PraxisRuntimeProjectRef) -> PraxisRuntimeCmpProjectClient {
    PraxisRuntimeCmpProjectClient(
      project: project,
      cmpFacade: cmpFacade,
      inspectionFacade: inspectionFacade
    )
  }

}

/// Project-scoped CMP surface for repeated runtime coordination calls.
public struct PraxisRuntimeCmpProjectClient: Sendable {
  private let project: PraxisRuntimeProjectRef

  private let cmpFacade: PraxisCmpFacade

  init(
    project: PraxisRuntimeProjectRef,
    cmpFacade: PraxisCmpFacade,
    inspectionFacade _: PraxisInspectionFacade
  ) {
    self.project = project
    self.cmpFacade = cmpFacade
  }

  /// Opens one CMP session for the scoped project.
  ///
  /// - Parameter session: Optional explicit session identifier.
  /// - Returns: A CMP session snapshot projected by the runtime facade.
  /// - Throws: Any session opening error raised by the underlying runtime use cases.
  public func openSession(session: PraxisRuntimeSessionRef? = nil) async throws -> PraxisCmpSessionSnapshot {
    try await cmpFacade.openSession(.init(projectID: project.rawValue, sessionID: session?.rawValue))
  }

  /// Opens one CMP session through the shorter RuntimeKit convenience name.
  ///
  /// - Parameter session: Optional explicit session identifier.
  /// - Returns: A CMP session snapshot projected by the runtime facade.
  /// - Throws: Any session opening error raised by the underlying runtime use cases.
  public func openSession(_ session: PraxisRuntimeSessionRef? = nil) async throws -> PraxisCmpSessionSnapshot {
    try await openSession(session: session)
  }

  /// Bootstraps the scoped CMP project with caller-friendly options.
  ///
  /// - Parameter options: Structured bootstrap options for one project.
  /// - Returns: A CMP project bootstrap snapshot projected by the runtime facade.
  /// - Throws: Any bootstrap error raised by the underlying runtime use cases.
  public func bootstrap(
    _ options: PraxisRuntimeCmpBootstrapOptions = .init()
  ) async throws -> PraxisCmpProjectBootstrapSnapshot {
    try await cmpFacade.bootstrapProject(
      .init(
        projectID: project.rawValue,
        agentIDs: options.agentIDs.map(\.rawValue),
        defaultAgentID: options.defaultAgentID?.rawValue,
        repoName: options.repoName,
        repoRootPath: options.repoRootPath,
        defaultBranchName: options.defaultBranchName,
        databaseName: options.databaseName,
        namespaceRoot: options.namespaceRoot
      )
    )
  }

  /// Reads one CMP project overview for the scoped project.
  ///
  /// - Parameter options: Structured CMP overview options for one project read.
  /// - Returns: A CMP project overview composed from readback, smoke, and status snapshots.
  /// - Throws: Any readback or smoke error raised by the underlying runtime use cases.
  public func overview(
    _ options: PraxisRuntimeCmpOverviewOptions = .init()
  ) async throws -> PraxisRuntimeCmpProjectOverview {
    async let readback = cmpFacade.readbackProject(.init(projectID: project.rawValue))
    async let smoke = cmpFacade.smokeProject(.init(projectID: project.rawValue))
    async let status = cmpFacade.readbackStatus(
      .init(projectID: project.rawValue, agentID: options.agentID?.rawValue)
    )

    return try await PraxisRuntimeCmpProjectOverview(
      readback: readback,
      smoke: smoke,
      status: status
    )
  }

  /// Reads one CMP project overview from lightweight call-site parameters.
  ///
  /// - Parameter agent: Optional agent identifier used to scope status reads.
  /// - Returns: A CMP project overview composed from readback, smoke, and status snapshots.
  /// - Throws: Any readback or smoke error raised by the underlying runtime use cases.
  public func overview(
    for agent: PraxisRuntimeAgentRef? = nil
  ) async throws -> PraxisRuntimeCmpProjectOverview {
    try await overview(.init(agentID: agent))
  }

  /// Reads one direct CMP smoke snapshot for the scoped project.
  ///
  /// - Returns: A CMP smoke snapshot projected by the runtime facade.
  /// - Throws: Any smoke error raised by the underlying runtime use cases.
  public func smoke() async throws -> PraxisCmpProjectSmokeSnapshot {
    try await cmpFacade.smokeProject(.init(projectID: project.rawValue))
  }

  /// Peer approval workflow grouped behind a dedicated scoped client.
  public var approvals: PraxisRuntimeCmpApprovalClient {
    PraxisRuntimeCmpApprovalClient(project: project, cmpFacade: cmpFacade)
  }

  /// Reads one peer approval summary together with the current project overview.
  ///
  /// - Parameter query: Structured approval query for one scoped approval readback.
  /// - Returns: A CMP approval overview composed from approval readback and project overview.
  /// - Throws: Any approval or project readback error raised by the underlying runtime use cases.
  public func approvalOverview(
    _ query: PraxisRuntimeCmpApprovalQuery = .init()
  ) async throws -> PraxisRuntimeCmpApprovalOverview {
    async let overview = overview(.init(agentID: query.targetAgentID ?? query.agentID))
    async let approval = approvals.readback(query)

    return try await PraxisRuntimeCmpApprovalOverview(
      overview: overview,
      approval: approval
    )
  }

  /// Reads one peer approval summary from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - agent: Optional requesting agent identifier.
  ///   - targetAgent: Optional target agent identifier.
  ///   - capability: Optional capability identifier.
  /// - Returns: A CMP approval overview composed from approval readback and project overview.
  /// - Throws: Any approval or project readback error raised by the underlying runtime use cases.
  public func approvalOverview(
    agent: PraxisRuntimeAgentRef? = nil,
    targetAgent: PraxisRuntimeAgentRef? = nil,
    capability: PraxisRuntimeCapabilityRef? = nil
  ) async throws -> PraxisRuntimeCmpApprovalOverview {
    try await approvalOverview(
      .init(
        agentID: agent,
        targetAgentID: targetAgent,
        capabilityID: capability
      )
    )
  }
}

/// Aggregated CMP read model for one scoped project.
public struct PraxisRuntimeCmpProjectOverview: Sendable {
  public let readback: PraxisCmpProjectReadbackSnapshot
  public let smoke: PraxisCmpProjectSmokeSnapshot
  public let status: PraxisCmpStatusPanelSnapshot

  public init(
    readback: PraxisCmpProjectReadbackSnapshot,
    smoke: PraxisCmpProjectSmokeSnapshot,
    status: PraxisCmpStatusPanelSnapshot
  ) {
    self.readback = readback
    self.smoke = smoke
    self.status = status
  }

  /// Stable project identifier shared by the aggregated CMP snapshots.
  public var projectID: String {
    readback.projectSummary.projectID
  }

  /// Stable agent identifier when the aggregated status readback is agent-filtered.
  public var agentID: String? {
    status.agentID
  }

  /// High-level CMP overview summary suitable for direct caller logging.
  public var summary: String {
    readback.summary
  }

  /// CMP smoke checks exposed without leaking the lower smoke result wrapper.
  public var smokeChecks: [PraxisCmpProjectSmokeCheck] {
    smoke.smokeResult.checks
  }
}

/// Project-scoped CMP approval surface for repeated approval workflow calls.
public struct PraxisRuntimeCmpApprovalClient: Sendable {
  private let project: PraxisRuntimeProjectRef
  private let cmpFacade: PraxisCmpFacade

  init(project: PraxisRuntimeProjectRef, cmpFacade: PraxisCmpFacade) {
    self.project = project
    self.cmpFacade = cmpFacade
  }

  /// Requests peer approval for the scoped project.
  public func request(_ request: PraxisRuntimeCmpApprovalRequest) async throws -> PraxisCmpPeerApprovalSnapshot {
    try await cmpFacade.requestPeerApproval(
      .init(
        projectID: project.rawValue,
        agentID: request.agentID.rawValue,
        targetAgentID: request.targetAgentID.rawValue,
        capabilityKey: .init(rawValue: request.capabilityID.rawValue),
        requestedTier: request.requestedTier,
        summary: request.summary
      )
    )
  }

  /// Applies one peer approval decision for the scoped project.
  public func decide(_ input: PraxisRuntimeCmpApprovalDecisionInput) async throws -> PraxisCmpPeerApprovalSnapshot {
    try await cmpFacade.decidePeerApproval(
      .init(
        projectID: project.rawValue,
        agentID: input.agentID.rawValue,
        targetAgentID: input.targetAgentID.rawValue,
        capabilityKey: .init(rawValue: input.capabilityID.rawValue),
        decision: input.decision,
        reviewerAgentID: input.reviewerAgentID?.rawValue,
        decisionSummary: input.decisionSummary
      )
    )
  }

  /// Reads back one peer approval for the scoped project.
  public func readback(
    _ query: PraxisRuntimeCmpApprovalQuery = .init()
  ) async throws -> PraxisCmpPeerApprovalReadbackSnapshot {
    try await cmpFacade.readbackPeerApproval(
      .init(
        projectID: project.rawValue,
        agentID: query.agentID?.rawValue,
        targetAgentID: query.targetAgentID?.rawValue,
        capabilityKey: query.capabilityID.map { PraxisCapabilityID(rawValue: $0.rawValue) }
      )
    )
  }
}

/// Aggregated CMP approval read model that combines approval state with project state.
public struct PraxisRuntimeCmpApprovalOverview: Sendable {
  public let overview: PraxisRuntimeCmpProjectOverview
  public let approval: PraxisCmpPeerApprovalReadbackSnapshot

  public init(
    overview: PraxisRuntimeCmpProjectOverview,
    approval: PraxisCmpPeerApprovalReadbackSnapshot
  ) {
    self.overview = overview
    self.approval = approval
  }

  /// Stable project identifier shared by the approval and project snapshots.
  public var projectID: String {
    approval.projectID
  }

}
