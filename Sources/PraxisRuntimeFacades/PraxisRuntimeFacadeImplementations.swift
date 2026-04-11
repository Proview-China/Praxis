import PraxisGoal
import PraxisRuntimeComposition
import PraxisRuntimeUseCases
import PraxisRun

public final class PraxisRuntimeFacade: Sendable {
  public let runFacade: PraxisRunFacade
  public let inspectionFacade: PraxisInspectionFacade
  public let cmpFacade: PraxisCmpFacade

  public init(
    runFacade: PraxisRunFacade,
    inspectionFacade: PraxisInspectionFacade,
    cmpFacade: PraxisCmpFacade
  ) {
    self.runFacade = runFacade
    self.inspectionFacade = inspectionFacade
    self.cmpFacade = cmpFacade
  }

  public convenience init(dependencies: PraxisDependencyGraph) {
    self.init(
      runFacade: .init(dependencies: dependencies),
      inspectionFacade: .init(dependencies: dependencies),
      cmpFacade: .init(dependencies: dependencies)
    )
  }
}

public final class PraxisRunFacade: Sendable {
  public let runGoalUseCase: any PraxisRunGoalUseCaseProtocol
  public let resumeRunUseCase: any PraxisResumeRunUseCaseProtocol

  public init(
    runGoalUseCase: any PraxisRunGoalUseCaseProtocol,
    resumeRunUseCase: any PraxisResumeRunUseCaseProtocol
  ) {
    self.runGoalUseCase = runGoalUseCase
    self.resumeRunUseCase = resumeRunUseCase
  }

  public convenience init(dependencies: PraxisDependencyGraph) {
    self.init(
      runGoalUseCase: PraxisRunGoalUseCase(dependencies: dependencies),
      resumeRunUseCase: PraxisResumeRunUseCase(dependencies: dependencies)
    )
  }

  public func runGoal(_ command: PraxisRunGoalCommand) async throws -> PraxisRunSummary {
    let execution = try await runGoalUseCase.execute(command)
    let journalSummary = execution.journalSequence.map { "journal \($0)" } ?? "journal unavailable"
    let checkpointSummary = execution.checkpointReference ?? "no checkpoint"
    let followUpSummary = execution.followUpAction.map {
      "Next action \($0.kind.rawValue): \($0.reason)"
    } ?? "No follow-up action emitted."
    return PraxisRunSummary(
      runID: execution.runID,
      sessionID: execution.sessionID,
      phase: execution.phase,
      tickCount: execution.tickCount,
      lifecycleDisposition: .started,
      journalSequence: execution.journalSequence,
      checkpointReference: execution.checkpointReference,
      recoveredEventCount: execution.recoveredEventCount,
      followUpAction: execution.followUpAction,
      phaseSummary: "Started \(execution.phase.rawValue) run for \(command.goal.normalizedGoal.title) in session \(execution.sessionID.rawValue); \(journalSummary); \(checkpointSummary). \(followUpSummary)"
    )
  }

  public func resumeRun(_ command: PraxisResumeRunCommand) async throws -> PraxisRunSummary {
    let execution = try await resumeRunUseCase.execute(command)
    let journalSummary = execution.journalSequence.map { "journal \($0)" } ?? "journal unavailable"
    let checkpointSummary = execution.checkpointReference ?? "no checkpoint"
    let followUpSummary = execution.followUpAction.map {
      "Next action \($0.kind.rawValue): \($0.reason)"
    } ?? "No follow-up action emitted."
    let lifecycleSummary: String
    if execution.resumeIssued {
      lifecycleSummary = "Resumed \(execution.phase.rawValue) run \(execution.runID.rawValue) in session \(execution.sessionID.rawValue)"
    } else {
      lifecycleSummary = "Recovered \(execution.phase.rawValue) run \(execution.runID.rawValue) from replayed journal in session \(execution.sessionID.rawValue) without issuing a new resume event"
    }
    return PraxisRunSummary(
      runID: execution.runID,
      sessionID: execution.sessionID,
      phase: execution.phase,
      tickCount: execution.tickCount,
      lifecycleDisposition: execution.resumeIssued ? .resumed : .recoveredWithoutResume,
      journalSequence: execution.journalSequence,
      checkpointReference: execution.checkpointReference,
      recoveredEventCount: execution.recoveredEventCount,
      followUpAction: execution.followUpAction,
      phaseSummary: "\(lifecycleSummary); replayed \(execution.recoveredEventCount) events; \(journalSummary); \(checkpointSummary). \(followUpSummary)"
    )
  }
}

public final class PraxisInspectionFacade: Sendable {
  public let inspectTapUseCase: any PraxisInspectTapUseCaseProtocol
  public let readbackTapStatusUseCase: any PraxisReadbackTapStatusUseCaseProtocol
  public let readbackTapHistoryUseCase: any PraxisReadbackTapHistoryUseCaseProtocol
  public let inspectCmpUseCase: any PraxisInspectCmpUseCaseProtocol
  public let inspectMpUseCase: any PraxisInspectMpUseCaseProtocol
  public let buildCapabilityCatalogUseCase: any PraxisBuildCapabilityCatalogUseCaseProtocol

  public init(
    inspectTapUseCase: any PraxisInspectTapUseCaseProtocol,
    readbackTapStatusUseCase: any PraxisReadbackTapStatusUseCaseProtocol,
    readbackTapHistoryUseCase: any PraxisReadbackTapHistoryUseCaseProtocol,
    inspectCmpUseCase: any PraxisInspectCmpUseCaseProtocol,
    inspectMpUseCase: any PraxisInspectMpUseCaseProtocol,
    buildCapabilityCatalogUseCase: any PraxisBuildCapabilityCatalogUseCaseProtocol
  ) {
    self.inspectTapUseCase = inspectTapUseCase
    self.readbackTapStatusUseCase = readbackTapStatusUseCase
    self.readbackTapHistoryUseCase = readbackTapHistoryUseCase
    self.inspectCmpUseCase = inspectCmpUseCase
    self.inspectMpUseCase = inspectMpUseCase
    self.buildCapabilityCatalogUseCase = buildCapabilityCatalogUseCase
  }

  public convenience init(dependencies: PraxisDependencyGraph) {
    self.init(
      inspectTapUseCase: PraxisInspectTapUseCase(dependencies: dependencies),
      readbackTapStatusUseCase: PraxisReadbackTapStatusUseCase(dependencies: dependencies),
      readbackTapHistoryUseCase: PraxisReadbackTapHistoryUseCase(dependencies: dependencies),
      inspectCmpUseCase: PraxisInspectCmpUseCase(dependencies: dependencies),
      inspectMpUseCase: PraxisInspectMpUseCase(dependencies: dependencies),
      buildCapabilityCatalogUseCase: PraxisBuildCapabilityCatalogUseCase(dependencies: dependencies)
    )
  }

  public func inspectTap() async throws -> PraxisTapInspectionSnapshot {
    let inspection = try await inspectTapUseCase.execute()
    return PraxisTapInspectionSnapshot(
      summary: inspection.summary,
      governanceSummary: inspection.governanceSnapshot.summary,
      reviewSummary: inspection.toolReviewReport.session.actions.first?.summary ?? inspection.reviewContext.riskSummary.plainLanguageSummary
    )
  }

  public func readbackTapStatus(_ command: PraxisReadbackTapStatusCommand) async throws -> PraxisTapStatusSnapshot {
    let status = try await readbackTapStatusUseCase.execute(command)
    return PraxisTapStatusSnapshot(
      summary: status.summary,
      readinessSummary: status.readinessSummary,
      projectID: status.projectID,
      agentID: status.agentID,
      tapMode: status.tapMode,
      riskLevel: status.riskLevel,
      humanGateState: status.humanGateState,
      availableCapabilityCount: status.availableCapabilityCount,
      availableCapabilityIDs: status.availableCapabilityIDs,
      pendingApprovalCount: status.pendingApprovalCount,
      approvedApprovalCount: status.approvedApprovalCount,
      latestCapabilityKey: status.latestCapabilityKey,
      latestDecisionSummary: status.latestDecisionSummary
    )
  }

  public func readbackTapHistory(_ command: PraxisReadbackTapHistoryCommand) async throws -> PraxisTapHistorySnapshot {
    let history = try await readbackTapHistoryUseCase.execute(command)
    return PraxisTapHistorySnapshot(
      summary: history.summary,
      projectID: history.projectID,
      agentID: history.agentID,
      totalCount: history.totalCount,
      entries: history.entries.map { entry in
        .init(
          agentID: entry.agentID,
          targetAgentID: entry.targetAgentID,
          capabilityKey: entry.capabilityKey,
          requestedTier: entry.requestedTier,
          route: entry.route,
          outcome: entry.outcome,
          humanGateState: entry.humanGateState,
          updatedAt: entry.updatedAt,
          decisionSummary: entry.decisionSummary
        )
      }
    )
  }

  public func inspectCmp() async throws -> PraxisCmpInspectionSnapshot {
    let inspection = try await inspectCmpUseCase.execute()
    return PraxisCmpInspectionSnapshot(
      summary: inspection.summary,
      projectID: inspection.projectID,
      hostRuntimeSummary: inspection.hostSummary,
      persistenceSummary: inspection.runtimeProfile.structuredStoreSummary,
      coordinationSummary: inspection.runtimeProfile.messageBusSummary
    )
  }

  public func inspectMp() async throws -> PraxisMpInspectionSnapshot {
    let inspection = try await inspectMpUseCase.execute()
    return PraxisMpInspectionSnapshot(
      summary: inspection.summary,
      workflowSummary: inspection.workflowSummary,
      memoryStoreSummary: inspection.memoryStoreSummary,
      multimodalSummary: inspection.multimodalSummary
    )
  }

  public func buildCapabilityCatalogSnapshot() async throws -> PraxisInspectionSnapshot {
    PraxisInspectionSnapshot(summary: try await buildCapabilityCatalogUseCase.execute())
  }
}

public final class PraxisCmpFacade: Sendable {
  public let openCmpSessionUseCase: any PraxisOpenCmpSessionUseCaseProtocol
  public let readbackCmpProjectUseCase: any PraxisReadbackCmpProjectUseCaseProtocol
  public let bootstrapCmpProjectUseCase: any PraxisBootstrapCmpProjectUseCaseProtocol
  public let ingestCmpFlowUseCase: any PraxisIngestCmpFlowUseCaseProtocol
  public let commitCmpFlowUseCase: any PraxisCommitCmpFlowUseCaseProtocol
  public let resolveCmpFlowUseCase: any PraxisResolveCmpFlowUseCaseProtocol
  public let materializeCmpFlowUseCase: any PraxisMaterializeCmpFlowUseCaseProtocol
  public let dispatchCmpFlowUseCase: any PraxisDispatchCmpFlowUseCaseProtocol
  public let retryCmpDispatchUseCase: any PraxisRetryCmpDispatchUseCaseProtocol
  public let requestCmpHistoryUseCase: any PraxisRequestCmpHistoryUseCaseProtocol
  public let readbackCmpRolesUseCase: any PraxisReadbackCmpRolesUseCaseProtocol
  public let readbackCmpControlUseCase: any PraxisReadbackCmpControlUseCaseProtocol
  public let updateCmpControlUseCase: any PraxisUpdateCmpControlUseCaseProtocol
  public let requestCmpPeerApprovalUseCase: any PraxisRequestCmpPeerApprovalUseCaseProtocol
  public let decideCmpPeerApprovalUseCase: any PraxisDecideCmpPeerApprovalUseCaseProtocol
  public let readbackCmpPeerApprovalUseCase: any PraxisReadbackCmpPeerApprovalUseCaseProtocol
  public let readbackCmpStatusUseCase: any PraxisReadbackCmpStatusUseCaseProtocol
  public let smokeCmpProjectUseCase: any PraxisSmokeCmpProjectUseCaseProtocol

  public init(
    openCmpSessionUseCase: any PraxisOpenCmpSessionUseCaseProtocol,
    readbackCmpProjectUseCase: any PraxisReadbackCmpProjectUseCaseProtocol,
    bootstrapCmpProjectUseCase: any PraxisBootstrapCmpProjectUseCaseProtocol,
    ingestCmpFlowUseCase: any PraxisIngestCmpFlowUseCaseProtocol,
    commitCmpFlowUseCase: any PraxisCommitCmpFlowUseCaseProtocol,
    resolveCmpFlowUseCase: any PraxisResolveCmpFlowUseCaseProtocol,
    materializeCmpFlowUseCase: any PraxisMaterializeCmpFlowUseCaseProtocol,
    dispatchCmpFlowUseCase: any PraxisDispatchCmpFlowUseCaseProtocol,
    retryCmpDispatchUseCase: any PraxisRetryCmpDispatchUseCaseProtocol,
    requestCmpHistoryUseCase: any PraxisRequestCmpHistoryUseCaseProtocol,
    readbackCmpRolesUseCase: any PraxisReadbackCmpRolesUseCaseProtocol,
    readbackCmpControlUseCase: any PraxisReadbackCmpControlUseCaseProtocol,
    updateCmpControlUseCase: any PraxisUpdateCmpControlUseCaseProtocol,
    requestCmpPeerApprovalUseCase: any PraxisRequestCmpPeerApprovalUseCaseProtocol,
    decideCmpPeerApprovalUseCase: any PraxisDecideCmpPeerApprovalUseCaseProtocol,
    readbackCmpPeerApprovalUseCase: any PraxisReadbackCmpPeerApprovalUseCaseProtocol,
    readbackCmpStatusUseCase: any PraxisReadbackCmpStatusUseCaseProtocol,
    smokeCmpProjectUseCase: any PraxisSmokeCmpProjectUseCaseProtocol
  ) {
    self.openCmpSessionUseCase = openCmpSessionUseCase
    self.readbackCmpProjectUseCase = readbackCmpProjectUseCase
    self.bootstrapCmpProjectUseCase = bootstrapCmpProjectUseCase
    self.ingestCmpFlowUseCase = ingestCmpFlowUseCase
    self.commitCmpFlowUseCase = commitCmpFlowUseCase
    self.resolveCmpFlowUseCase = resolveCmpFlowUseCase
    self.materializeCmpFlowUseCase = materializeCmpFlowUseCase
    self.dispatchCmpFlowUseCase = dispatchCmpFlowUseCase
    self.retryCmpDispatchUseCase = retryCmpDispatchUseCase
    self.requestCmpHistoryUseCase = requestCmpHistoryUseCase
    self.readbackCmpRolesUseCase = readbackCmpRolesUseCase
    self.readbackCmpControlUseCase = readbackCmpControlUseCase
    self.updateCmpControlUseCase = updateCmpControlUseCase
    self.requestCmpPeerApprovalUseCase = requestCmpPeerApprovalUseCase
    self.decideCmpPeerApprovalUseCase = decideCmpPeerApprovalUseCase
    self.readbackCmpPeerApprovalUseCase = readbackCmpPeerApprovalUseCase
    self.readbackCmpStatusUseCase = readbackCmpStatusUseCase
    self.smokeCmpProjectUseCase = smokeCmpProjectUseCase
  }

  public convenience init(dependencies: PraxisDependencyGraph) {
    self.init(
      openCmpSessionUseCase: PraxisOpenCmpSessionUseCase(dependencies: dependencies),
      readbackCmpProjectUseCase: PraxisReadbackCmpProjectUseCase(dependencies: dependencies),
      bootstrapCmpProjectUseCase: PraxisBootstrapCmpProjectUseCase(dependencies: dependencies),
      ingestCmpFlowUseCase: PraxisIngestCmpFlowUseCase(dependencies: dependencies),
      commitCmpFlowUseCase: PraxisCommitCmpFlowUseCase(dependencies: dependencies),
      resolveCmpFlowUseCase: PraxisResolveCmpFlowUseCase(dependencies: dependencies),
      materializeCmpFlowUseCase: PraxisMaterializeCmpFlowUseCase(dependencies: dependencies),
      dispatchCmpFlowUseCase: PraxisDispatchCmpFlowUseCase(dependencies: dependencies),
      retryCmpDispatchUseCase: PraxisRetryCmpDispatchUseCase(dependencies: dependencies),
      requestCmpHistoryUseCase: PraxisRequestCmpHistoryUseCase(dependencies: dependencies),
      readbackCmpRolesUseCase: PraxisReadbackCmpRolesUseCase(dependencies: dependencies),
      readbackCmpControlUseCase: PraxisReadbackCmpControlUseCase(dependencies: dependencies),
      updateCmpControlUseCase: PraxisUpdateCmpControlUseCase(dependencies: dependencies),
      requestCmpPeerApprovalUseCase: PraxisRequestCmpPeerApprovalUseCase(dependencies: dependencies),
      decideCmpPeerApprovalUseCase: PraxisDecideCmpPeerApprovalUseCase(dependencies: dependencies),
      readbackCmpPeerApprovalUseCase: PraxisReadbackCmpPeerApprovalUseCase(dependencies: dependencies),
      readbackCmpStatusUseCase: PraxisReadbackCmpStatusUseCase(dependencies: dependencies),
      smokeCmpProjectUseCase: PraxisSmokeCmpProjectUseCase(dependencies: dependencies)
    )
  }

  public func openSession(_ command: PraxisOpenCmpSessionCommand) async throws -> PraxisCmpSessionSnapshot {
    let session = try await openCmpSessionUseCase.execute(command)
    return PraxisCmpSessionSnapshot(
      sessionID: session.sessionID,
      projectID: session.projectID,
      summary: session.summary,
      createdAt: session.createdAt,
      hostProfile: mapHostProfile(session.hostProfile),
      issues: session.issues
    )
  }

  public func readbackProject(_ command: PraxisReadbackCmpProjectCommand) async throws -> PraxisCmpProjectReadbackSnapshot {
    let readback = try await readbackCmpProjectUseCase.execute(command)
    return PraxisCmpProjectReadbackSnapshot(
      summary: readback.summary,
      projectSummary: .init(
        projectID: readback.projectID,
        hostProfile: mapHostProfile(readback.hostProfile),
        componentStatuses: readback.componentStatuses.mapValues(mapTruthLayerStatus),
        issues: readback.issues
      ),
      persistenceSummary: readback.persistenceSummary,
      coordinationSummary: readback.coordinationSummary
    )
  }

  public func bootstrapProject(_ command: PraxisBootstrapCmpProjectCommand) async throws -> PraxisCmpProjectBootstrapSnapshot {
    let bootstrap = try await bootstrapCmpProjectUseCase.execute(command)
    let gitStatus: PraxisTruthLayerStatus
    switch bootstrap.gitReceipt.status {
    case .bootstrapped, .alreadyExists:
      gitStatus = .ready
    case .conflicted:
      gitStatus = .degraded
    }
    return PraxisCmpProjectBootstrapSnapshot(
      summary: bootstrap.summary,
      projectSummary: .init(
        projectID: bootstrap.projectID,
        hostProfile: mapHostProfile(bootstrap.hostProfile),
        componentStatuses: [
          "git": gitStatus,
          "db": bootstrap.dbReceipt.missingTargetCount == 0 ? .ready : .degraded,
          "mq": bootstrap.mqReceipts.isEmpty ? .failed : .ready,
          "lineage": bootstrap.lineages.isEmpty ? .failed : .ready,
        ],
        issues: bootstrap.issues
      ),
      gitSummary: "Git bootstrap \(bootstrap.gitReceipt.status.rawValue) with \(bootstrap.gitBranchRuntimes.count) branch runtimes and \(bootstrap.gitReceipt.createdBranches.count) created branch refs.",
      persistenceSummary: bootstrap.persistenceSummary,
      coordinationSummary: bootstrap.coordinationSummary
    )
  }

  public func ingestFlow(_ command: PraxisIngestCmpFlowCommand) async throws -> PraxisCmpFlowIngestSnapshot {
    let ingest = try await ingestCmpFlowUseCase.execute(command)
    return PraxisCmpFlowIngestSnapshot(
      summary: ingest.summary,
      projectID: ingest.projectID,
      agentID: ingest.agentID,
      sessionID: ingest.sessionID,
      requestID: ingest.requestID.rawValue,
      acceptedEventCount: ingest.result.acceptedEventIDs.count,
      sectionCount: ingest.ingress.sections.count,
      storedSectionCount: ingest.loweredSections.compactMap(\.storedSection).count,
      nextAction: ingest.result.nextAction
    )
  }

  public func commitFlow(_ command: PraxisCommitCmpFlowCommand) async throws -> PraxisCmpFlowCommitSnapshot {
    let commit = try await commitCmpFlowUseCase.execute(command)
    return PraxisCmpFlowCommitSnapshot(
      summary: commit.summary,
      projectID: commit.projectID,
      agentID: commit.agentID,
      deltaID: commit.result.delta.id.rawValue,
      snapshotCandidateID: commit.result.snapshotCandidateID?.rawValue,
      activeLineStage: commit.activeLine.stage.rawValue,
      branchRef: commit.snapshotCandidate.branchRef
    )
  }

  public func resolveFlow(_ command: PraxisResolveCmpFlowCommand) async throws -> PraxisCmpFlowResolveSnapshot {
    let resolve = try await resolveCmpFlowUseCase.execute(command)
    return PraxisCmpFlowResolveSnapshot(
      summary: resolve.summary,
      projectID: resolve.projectID,
      agentID: resolve.agentID,
      found: resolve.result.found,
      snapshotID: resolve.snapshot?.id.rawValue,
      branchRef: resolve.snapshot?.branchRef,
      qualityLabel: resolve.snapshot?.qualityLabel.rawValue
    )
  }

  public func materializeFlow(_ command: PraxisMaterializeCmpFlowCommand) async throws -> PraxisCmpFlowMaterializeSnapshot {
    let materialize = try await materializeCmpFlowUseCase.execute(command)
    return PraxisCmpFlowMaterializeSnapshot(
      summary: materialize.summary,
      projectID: materialize.projectID,
      agentID: materialize.agentID,
      packageID: materialize.result.contextPackage.id.rawValue,
      targetAgentID: materialize.result.contextPackage.targetAgentID,
      packageKind: materialize.result.contextPackage.kind.rawValue,
      selectedSectionCount: materialize.materializationPlan.selectedSectionIDs.count
    )
  }

  public func dispatchFlow(_ command: PraxisDispatchCmpFlowCommand) async throws -> PraxisCmpFlowDispatchSnapshot {
    let dispatch = try await dispatchCmpFlowUseCase.execute(command)
    return PraxisCmpFlowDispatchSnapshot(
      summary: dispatch.summary,
      projectID: dispatch.projectID,
      agentID: dispatch.agentID,
      dispatchID: dispatch.result.receipt.id.rawValue,
      targetAgentID: dispatch.result.receipt.targetAgentID,
      targetKind: dispatch.result.receipt.targetKind.rawValue,
      status: dispatch.result.receipt.status.rawValue
    )
  }

  public func retryDispatch(_ command: PraxisRetryCmpDispatchCommand) async throws -> PraxisCmpFlowDispatchSnapshot {
    let dispatch = try await retryCmpDispatchUseCase.execute(command)
    return PraxisCmpFlowDispatchSnapshot(
      summary: dispatch.summary,
      projectID: dispatch.projectID,
      agentID: dispatch.agentID,
      dispatchID: dispatch.result.receipt.id.rawValue,
      targetAgentID: dispatch.result.receipt.targetAgentID,
      targetKind: dispatch.result.receipt.targetKind.rawValue,
      status: dispatch.result.receipt.status.rawValue
    )
  }

  public func requestHistory(_ command: PraxisRequestCmpHistoryCommand) async throws -> PraxisCmpFlowHistorySnapshot {
    let history = try await requestCmpHistoryUseCase.execute(command)
    return PraxisCmpFlowHistorySnapshot(
      summary: history.summary,
      projectID: history.projectID,
      requesterAgentID: history.requesterAgentID,
      found: history.result.found,
      snapshotID: history.result.snapshot?.id.rawValue,
      packageID: history.result.contextPackage?.id.rawValue
    )
  }

  public func readbackRoles(_ command: PraxisReadbackCmpRolesCommand) async throws -> PraxisCmpRolesPanelSnapshot {
    let roles = try await readbackCmpRolesUseCase.execute(command)
    return PraxisCmpRolesPanelSnapshot(
      summary: roles.summary,
      projectID: roles.projectID,
      agentID: roles.agentID,
      roleCounts: Dictionary(uniqueKeysWithValues: roles.roles.map { ($0.role.rawValue, $0.assignmentCount) }),
      roleStages: Dictionary(uniqueKeysWithValues: roles.roles.compactMap { role in
        guard let latestStage = role.latestStage else {
          return nil
        }
        return (role.role.rawValue, latestStage)
      }),
      latestPackageID: roles.latestPackageID,
      latestDispatchStatus: roles.latestDispatchStatus
    )
  }

  public func readbackControl(_ command: PraxisReadbackCmpControlCommand) async throws -> PraxisCmpControlPanelSnapshot {
    let control = try await readbackCmpControlUseCase.execute(command)
    return PraxisCmpControlPanelSnapshot(
      summary: control.summary,
      projectID: control.projectID,
      agentID: control.agentID,
      executionStyle: control.control.executionStyle,
      mode: control.control.mode,
      readbackPriority: control.control.readbackPriority,
      fallbackPolicy: control.control.fallbackPolicy,
      recoveryPreference: control.control.recoveryPreference,
      automation: control.control.automation,
      latestPackageID: control.latestPackageID,
      latestDispatchStatus: control.latestDispatchStatus,
      latestTargetAgentID: control.latestTargetAgentID
    )
  }

  public func updateControl(_ command: PraxisUpdateCmpControlCommand) async throws -> PraxisCmpControlUpdateSnapshot {
    let update = try await updateCmpControlUseCase.execute(command)
    return PraxisCmpControlUpdateSnapshot(
      summary: update.summary,
      projectID: update.projectID,
      agentID: update.agentID,
      executionStyle: update.control.executionStyle,
      mode: update.control.mode,
      readbackPriority: update.control.readbackPriority,
      fallbackPolicy: update.control.fallbackPolicy,
      recoveryPreference: update.control.recoveryPreference,
      automation: update.control.automation,
      storedAt: update.storedAt
    )
  }

  public func requestPeerApproval(_ command: PraxisRequestCmpPeerApprovalCommand) async throws -> PraxisCmpPeerApprovalSnapshot {
    let approval = try await requestCmpPeerApprovalUseCase.execute(command)
    return PraxisCmpPeerApprovalSnapshot(
      summary: approval.summary,
      projectID: approval.projectID,
      agentID: approval.agentID,
      targetAgentID: approval.targetAgentID,
      capabilityKey: approval.capabilityKey,
      requestedTier: approval.requestedTier.rawValue,
      route: approval.route,
      outcome: approval.outcome,
      tapMode: approval.tapMode,
      riskLevel: approval.riskLevel,
      humanGateState: approval.humanGateState,
      requestedAt: approval.requestedAt,
      decisionSummary: approval.decisionSummary
    )
  }

  public func decidePeerApproval(_ command: PraxisDecideCmpPeerApprovalCommand) async throws -> PraxisCmpPeerApprovalSnapshot {
    let approval = try await decideCmpPeerApprovalUseCase.execute(command)
    return PraxisCmpPeerApprovalSnapshot(
      summary: approval.summary,
      projectID: approval.projectID,
      agentID: approval.agentID,
      targetAgentID: approval.targetAgentID,
      capabilityKey: approval.capabilityKey,
      requestedTier: approval.requestedTier.rawValue,
      route: approval.route,
      outcome: approval.outcome,
      tapMode: approval.tapMode,
      riskLevel: approval.riskLevel,
      humanGateState: approval.humanGateState,
      requestedAt: approval.requestedAt,
      decisionSummary: approval.decisionSummary
    )
  }

  public func readbackPeerApproval(_ command: PraxisReadbackCmpPeerApprovalCommand) async throws -> PraxisCmpPeerApprovalReadbackSnapshot {
    let readback = try await readbackCmpPeerApprovalUseCase.execute(command)
    return PraxisCmpPeerApprovalReadbackSnapshot(
      summary: readback.summary,
      projectID: readback.projectID,
      agentID: readback.agentID,
      targetAgentID: readback.targetAgentID,
      capabilityKey: readback.capabilityKey,
      requestedTier: readback.requestedTier?.rawValue,
      route: readback.route,
      outcome: readback.outcome,
      tapMode: readback.tapMode,
      riskLevel: readback.riskLevel,
      humanGateState: readback.humanGateState,
      requestedAt: readback.requestedAt,
      decisionSummary: readback.decisionSummary,
      found: readback.found
    )
  }

  public func readbackStatus(_ command: PraxisReadbackCmpStatusCommand) async throws -> PraxisCmpStatusPanelSnapshot {
    let status = try await readbackCmpStatusUseCase.execute(command)
    return PraxisCmpStatusPanelSnapshot(
      summary: status.summary,
      projectID: status.projectID,
      agentID: status.agentID,
      executionStyle: status.control.executionStyle,
      readbackPriority: status.control.readbackPriority,
      packageCount: status.objectModel.packageCount,
      latestPackageID: status.latestPackageID,
      latestDispatchStatus: status.latestDispatchStatus,
      roleCounts: Dictionary(uniqueKeysWithValues: status.roles.map { ($0.role.rawValue, $0.assignmentCount) }),
      roleStages: Dictionary(uniqueKeysWithValues: status.roles.compactMap { role in
        guard let latestStage = role.latestStage else {
          return nil
        }
        return (role.role.rawValue, latestStage)
      })
    )
  }

  public func smokeProject(_ command: PraxisSmokeCmpProjectCommand) async throws -> PraxisCmpProjectSmokeSnapshot {
    let smoke = try await smokeCmpProjectUseCase.execute(command)
    return PraxisCmpProjectSmokeSnapshot(
      projectID: smoke.projectID,
      smokeResult: .init(
        summary: smoke.summary,
        checks: smoke.checks.map { check in
          .init(
            id: check.id,
            gate: check.gate,
            status: mapTruthLayerStatus(check.status),
            summary: check.summary
          )
        }
      )
    )
  }

  private func mapHostProfile(_ profile: PraxisCmpProjectHostProfile) -> PraxisLocalRuntimeHostProfile {
    .init(
      executionStyle: profile.executionStyle,
      structuredStore: profile.structuredStore,
      deliveryStore: profile.deliveryStore,
      messageTransport: profile.messageTransport,
      gitAccess: profile.gitAccess,
      semanticIndex: profile.semanticIndex
    )
  }

  private func mapTruthLayerStatus(_ rawValue: String) -> PraxisTruthLayerStatus {
    switch rawValue {
    case "ready":
      return .ready
    case "failed", "missing":
      return .failed
    default:
      return .degraded
    }
  }
}
