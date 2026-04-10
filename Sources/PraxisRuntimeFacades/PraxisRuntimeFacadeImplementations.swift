import PraxisGoal
import PraxisRuntimeComposition
import PraxisRuntimeUseCases
import PraxisRun

public final class PraxisRuntimeFacade: Sendable {
  public let runFacade: PraxisRunFacade
  public let inspectionFacade: PraxisInspectionFacade

  public init(
    runFacade: PraxisRunFacade,
    inspectionFacade: PraxisInspectionFacade
  ) {
    self.runFacade = runFacade
    self.inspectionFacade = inspectionFacade
  }

  public convenience init(dependencies: PraxisDependencyGraph) {
    self.init(
      runFacade: .init(dependencies: dependencies),
      inspectionFacade: .init(dependencies: dependencies)
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
  public let inspectCmpUseCase: any PraxisInspectCmpUseCaseProtocol
  public let inspectMpUseCase: any PraxisInspectMpUseCaseProtocol
  public let buildCapabilityCatalogUseCase: any PraxisBuildCapabilityCatalogUseCaseProtocol

  public init(
    inspectTapUseCase: any PraxisInspectTapUseCaseProtocol,
    inspectCmpUseCase: any PraxisInspectCmpUseCaseProtocol,
    inspectMpUseCase: any PraxisInspectMpUseCaseProtocol,
    buildCapabilityCatalogUseCase: any PraxisBuildCapabilityCatalogUseCaseProtocol
  ) {
    self.inspectTapUseCase = inspectTapUseCase
    self.inspectCmpUseCase = inspectCmpUseCase
    self.inspectMpUseCase = inspectMpUseCase
    self.buildCapabilityCatalogUseCase = buildCapabilityCatalogUseCase
  }

  public convenience init(dependencies: PraxisDependencyGraph) {
    self.init(
      inspectTapUseCase: PraxisInspectTapUseCase(dependencies: dependencies),
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
