import PraxisRuntimeFacades

/// Caller-friendly TAP entrypoint that hides lower-level command wrappers.
///
/// This surface exposes inspection and project-scoped TAP readback without leaking transport or
/// bootstrap details into framework callers.
public struct PraxisRuntimeTapClient: Sendable {
  private let inspectionFacade: PraxisInspectionFacade

  init(inspectionFacade: PraxisInspectionFacade) {
    self.inspectionFacade = inspectionFacade
  }

  /// Reads the current TAP inspection snapshot.
  ///
  /// - Returns: A TAP inspection snapshot projected by the runtime facade.
  /// - Throws: Any inspection error raised by the underlying runtime use cases.
  public func inspect() async throws -> PraxisTapInspectionSnapshot {
    try await inspectionFacade.inspectTap()
  }

  /// Creates a TAP client scoped to one project identifier.
  ///
  /// - Parameter project: Stable project identifier used for follow-up TAP reads.
  /// - Returns: A project-scoped TAP client.
  public func project(_ project: PraxisRuntimeProjectRef) -> PraxisRuntimeTapProjectClient {
    PraxisRuntimeTapProjectClient(project: project, inspectionFacade: inspectionFacade)
  }

}

/// Project-scoped TAP surface for repeated readback calls.
public struct PraxisRuntimeTapProjectClient: Sendable {
  private let project: PraxisRuntimeProjectRef
  private let inspectionFacade: PraxisInspectionFacade

  init(project: PraxisRuntimeProjectRef, inspectionFacade: PraxisInspectionFacade) {
    self.project = project
    self.inspectionFacade = inspectionFacade
  }

  /// Reads one TAP project overview for the scoped project.
  ///
  /// - Parameter options: Structured TAP overview options for one project read.
  /// - Returns: A TAP project overview composed from status and approval history snapshots.
  /// - Throws: Any readback error raised by the underlying runtime use cases.
  public func overview(
    _ options: PraxisRuntimeTapOverviewOptions = .init()
  ) async throws -> PraxisRuntimeTapProjectOverview {
    async let status = inspectionFacade.readbackTapStatus(
      .init(projectID: project.rawValue, agentID: options.agentID?.rawValue)
    )
    async let history = inspectionFacade.readbackTapHistory(
      .init(projectID: project.rawValue, agentID: options.agentID?.rawValue, limit: options.limit)
    )

    return try await PraxisRuntimeTapProjectOverview(
      status: status,
      history: history
    )
  }

  /// Reads one TAP project overview from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - agent: Optional agent identifier used to scope TAP reads.
  ///   - limit: Maximum number of TAP history entries to load.
  /// - Returns: A TAP project overview composed from status and approval history snapshots.
  /// - Throws: Any readback error raised by the underlying runtime use cases.
  public func overview(
    for agent: PraxisRuntimeAgentRef? = nil,
    limit: Int = 10
  ) async throws -> PraxisRuntimeTapProjectOverview {
    try await overview(.init(agentID: agent, limit: limit))
  }
}

/// Aggregated TAP read model for one scoped project.
public struct PraxisRuntimeTapProjectOverview: Sendable {
  public let status: PraxisTapStatusSnapshot
  public let history: PraxisTapHistorySnapshot

  public init(
    status: PraxisTapStatusSnapshot,
    history: PraxisTapHistorySnapshot
  ) {
    self.status = status
    self.history = history
  }

  /// Stable project identifier shared by the aggregated TAP snapshots.
  public var projectID: String {
    status.projectID
  }

  /// Stable scoped agent identifier when the TAP overview is agent-filtered.
  public var agentID: String? {
    status.agentID ?? history.agentID
  }

  /// Number of approvals that are still waiting for reviewer or human action.
  public var pendingApprovalCount: Int {
    status.pendingApprovalCount
  }

  /// Number of approvals that already reached an approved state.
  public var approvedApprovalCount: Int {
    status.approvedApprovalCount
  }

  /// Latest reviewer-facing decision summary for the scoped TAP overview.
  public var latestDecisionSummary: String? {
    status.latestDecisionSummary ?? history.entries.first?.decisionSummary
  }

  /// Whether the scoped TAP overview currently has at least one waiting approval.
  public var hasWaitingHumanReview: Bool {
    status.humanGateState == .waitingApproval || pendingApprovalCount > 0
  }
}
