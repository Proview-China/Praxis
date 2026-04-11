import Foundation
import Testing
import PraxisCheckpoint
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisInfraContracts
import PraxisJournal
import PraxisRun
import PraxisSession
import PraxisState
@testable import PraxisRuntimeComposition
@testable import PraxisRuntimeFacades
@testable import PraxisRuntimeInterface
@testable import PraxisRuntimePresentationBridge
import PraxisRuntimeUseCases
import PraxisTransition

private func encodeRuntimeInterfaceTestJSON<T: Encodable>(_ value: T) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]
  guard let string = String(data: try encoder.encode(value), encoding: .utf8) else {
    throw PraxisError.invariantViolation("Failed to encode runtime interface test payload as UTF-8 JSON.")
  }
  return string
}

private func makeRuntimeInterfaceCheckpointRecord(
  status: PraxisAgentStatus,
  sessionID: PraxisSessionID,
  runID: PraxisRunID,
  tickCount: Int,
  lastCursor: PraxisJournalCursor?
) throws -> PraxisCheckpointRecord {
  let phase: PraxisRunPhase
  switch status {
  case .paused:
    phase = .paused
  case .failed:
    phase = .failed
  case .waiting, .acting:
    phase = .running
  case .idle, .deciding:
    phase = .queued
  case .created:
    phase = .created
  case .completed:
    phase = .completed
  case .cancelled:
    phase = .cancelled
  }

  let checkpointID = PraxisCheckpointID(rawValue: "checkpoint.\(runID.rawValue)")
  let aggregate = PraxisRunAggregate(
    id: runID,
    phase: phase,
    tickCount: tickCount,
    lastEventID: "evt.seed.\(runID.rawValue)",
    lastCheckpointReference: checkpointID.rawValue,
    latestState: .init(
      control: .init(status: status, phase: .recovery, retryCount: 0),
      working: [:],
      observed: .init(),
      recovery: .init(
        lastCheckpointRef: checkpointID.rawValue,
        resumePointer: lastCursor.map { "cursor.\($0.sequence)" }
      )
    )
  )
  let header = PraxisSessionHeader(
    id: sessionID,
    title: "Recovered Interface Run",
    temperature: .warm,
    activeRunReference: runID.rawValue,
    runReferences: [runID.rawValue],
    lastCheckpointReference: checkpointID.rawValue,
    lastJournalSequence: lastCursor?.sequence
  )
  let snapshot = PraxisCheckpointSnapshot(
    id: checkpointID,
    sessionID: sessionID,
    tier: .fast,
    createdAt: "2026-04-10T22:00:00Z",
    lastCursor: lastCursor,
    payload: [
      "runAggregateJSON": .string(try encodeRuntimeInterfaceTestJSON(aggregate)),
      "sessionHeaderJSON": .string(try encodeRuntimeInterfaceTestJSON(header)),
      "goalTitle": .string("Recovered Interface Run"),
    ]
  )
  return PraxisCheckpointRecord(
    pointer: .init(checkpointID: checkpointID, sessionID: sessionID),
    snapshot: snapshot
  )
}

private struct RuntimeInterfaceUnexpectedInvocationError: Error, Sendable, Equatable {
  let operation: String
}

private struct RuntimeInterfaceUnknownSmokeError: Error, Sendable, Equatable {
  let summary: String
}

private struct StubRunGoalUseCase: PraxisRunGoalUseCaseProtocol {
  let executeBody: @Sendable (PraxisRunGoalCommand) async throws -> PraxisRunExecution

  func execute(_ command: PraxisRunGoalCommand) async throws -> PraxisRunExecution {
    try await executeBody(command)
  }
}

private struct StubResumeRunUseCase: PraxisResumeRunUseCaseProtocol {
  let executeBody: @Sendable (PraxisResumeRunCommand) async throws -> PraxisRunExecution

  func execute(_ command: PraxisResumeRunCommand) async throws -> PraxisRunExecution {
    try await executeBody(command)
  }
}

private struct StubInspectTapUseCase: PraxisInspectTapUseCaseProtocol {
  let executeBody: @Sendable () async throws -> PraxisTapInspection

  func execute() async throws -> PraxisTapInspection {
    try await executeBody()
  }
}

private struct StubInspectCmpUseCase: PraxisInspectCmpUseCaseProtocol {
  let executeBody: @Sendable () async throws -> PraxisCmpInspection

  func execute() async throws -> PraxisCmpInspection {
    try await executeBody()
  }
}

private struct StubOpenCmpSessionUseCase: PraxisOpenCmpSessionUseCaseProtocol {
  let executeBody: @Sendable (PraxisOpenCmpSessionCommand) async throws -> PraxisCmpSession

  func execute(_ command: PraxisOpenCmpSessionCommand) async throws -> PraxisCmpSession {
    try await executeBody(command)
  }
}

private struct StubReadbackCmpProjectUseCase: PraxisReadbackCmpProjectUseCaseProtocol {
  let executeBody: @Sendable (PraxisReadbackCmpProjectCommand) async throws -> PraxisCmpProjectReadback

  func execute(_ command: PraxisReadbackCmpProjectCommand) async throws -> PraxisCmpProjectReadback {
    try await executeBody(command)
  }
}

private struct StubBootstrapCmpProjectUseCase: PraxisBootstrapCmpProjectUseCaseProtocol {
  let executeBody: @Sendable (PraxisBootstrapCmpProjectCommand) async throws -> PraxisCmpProjectBootstrap

  func execute(_ command: PraxisBootstrapCmpProjectCommand) async throws -> PraxisCmpProjectBootstrap {
    try await executeBody(command)
  }
}

private struct StubIngestCmpFlowUseCase: PraxisIngestCmpFlowUseCaseProtocol {
  let executeBody: @Sendable (PraxisIngestCmpFlowCommand) async throws -> PraxisCmpFlowIngest

  func execute(_ command: PraxisIngestCmpFlowCommand) async throws -> PraxisCmpFlowIngest {
    try await executeBody(command)
  }
}

private struct StubCommitCmpFlowUseCase: PraxisCommitCmpFlowUseCaseProtocol {
  let executeBody: @Sendable (PraxisCommitCmpFlowCommand) async throws -> PraxisCmpFlowCommit

  func execute(_ command: PraxisCommitCmpFlowCommand) async throws -> PraxisCmpFlowCommit {
    try await executeBody(command)
  }
}

private struct StubResolveCmpFlowUseCase: PraxisResolveCmpFlowUseCaseProtocol {
  let executeBody: @Sendable (PraxisResolveCmpFlowCommand) async throws -> PraxisCmpFlowResolve

  func execute(_ command: PraxisResolveCmpFlowCommand) async throws -> PraxisCmpFlowResolve {
    try await executeBody(command)
  }
}

private struct StubMaterializeCmpFlowUseCase: PraxisMaterializeCmpFlowUseCaseProtocol {
  let executeBody: @Sendable (PraxisMaterializeCmpFlowCommand) async throws -> PraxisCmpFlowMaterialize

  func execute(_ command: PraxisMaterializeCmpFlowCommand) async throws -> PraxisCmpFlowMaterialize {
    try await executeBody(command)
  }
}

private struct StubDispatchCmpFlowUseCase: PraxisDispatchCmpFlowUseCaseProtocol {
  let executeBody: @Sendable (PraxisDispatchCmpFlowCommand) async throws -> PraxisCmpFlowDispatch

  func execute(_ command: PraxisDispatchCmpFlowCommand) async throws -> PraxisCmpFlowDispatch {
    try await executeBody(command)
  }
}

private struct StubRequestCmpHistoryUseCase: PraxisRequestCmpHistoryUseCaseProtocol {
  let executeBody: @Sendable (PraxisRequestCmpHistoryCommand) async throws -> PraxisCmpFlowHistory

  func execute(_ command: PraxisRequestCmpHistoryCommand) async throws -> PraxisCmpFlowHistory {
    try await executeBody(command)
  }
}

private struct StubReadbackCmpStatusUseCase: PraxisReadbackCmpStatusUseCaseProtocol {
  let executeBody: @Sendable (PraxisReadbackCmpStatusCommand) async throws -> PraxisCmpStatusReadback

  func execute(_ command: PraxisReadbackCmpStatusCommand) async throws -> PraxisCmpStatusReadback {
    try await executeBody(command)
  }
}

private struct StubSmokeCmpProjectUseCase: PraxisSmokeCmpProjectUseCaseProtocol {
  let executeBody: @Sendable (PraxisSmokeCmpProjectCommand) async throws -> PraxisCmpProjectSmoke

  func execute(_ command: PraxisSmokeCmpProjectCommand) async throws -> PraxisCmpProjectSmoke {
    try await executeBody(command)
  }
}

private struct StubInspectMpUseCase: PraxisInspectMpUseCaseProtocol {
  let executeBody: @Sendable () async throws -> PraxisMpInspection

  func execute() async throws -> PraxisMpInspection {
    try await executeBody()
  }
}

private struct StubBuildCapabilityCatalogUseCase: PraxisBuildCapabilityCatalogUseCaseProtocol {
  let executeBody: @Sendable () async throws -> String

  func execute() async throws -> String {
    try await executeBody()
  }
}

private func makeThrowingRuntimeInterface(
  runGoalError: Error? = nil,
  resumeRunError: Error? = nil,
  inspectTapError: Error? = nil,
  inspectCmpError: Error? = nil,
  openCmpSessionError: Error? = nil,
  readbackCmpProjectError: Error? = nil,
  bootstrapCmpProjectError: Error? = nil,
  ingestCmpFlowError: Error? = nil,
  commitCmpFlowError: Error? = nil,
  resolveCmpFlowError: Error? = nil,
  materializeCmpFlowError: Error? = nil,
  dispatchCmpFlowError: Error? = nil,
  requestCmpHistoryError: Error? = nil,
  readbackCmpStatusError: Error? = nil,
  smokeCmpProjectError: Error? = nil,
  inspectMpError: Error? = nil,
  buildCapabilityCatalogError: Error? = nil
) -> PraxisRuntimeInterfaceSession {
  let runFacade = PraxisRunFacade(
    runGoalUseCase: StubRunGoalUseCase { _ in
      if let runGoalError {
        throw runGoalError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "runGoal")
    },
    resumeRunUseCase: StubResumeRunUseCase { _ in
      if let resumeRunError {
        throw resumeRunError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "resumeRun")
    }
  )
  let inspectionFacade = PraxisInspectionFacade(
    inspectTapUseCase: StubInspectTapUseCase {
      if let inspectTapError {
        throw inspectTapError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "inspectTap")
    },
    inspectCmpUseCase: StubInspectCmpUseCase {
      if let inspectCmpError {
        throw inspectCmpError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "inspectCmp")
    },
    inspectMpUseCase: StubInspectMpUseCase {
      if let inspectMpError {
        throw inspectMpError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "inspectMp")
    },
    buildCapabilityCatalogUseCase: StubBuildCapabilityCatalogUseCase {
      if let buildCapabilityCatalogError {
        throw buildCapabilityCatalogError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "buildCapabilityCatalog")
    }
  )
  let cmpFacade = PraxisCmpFacade(
    openCmpSessionUseCase: StubOpenCmpSessionUseCase { _ in
      if let openCmpSessionError {
        throw openCmpSessionError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "openCmpSession")
    },
    readbackCmpProjectUseCase: StubReadbackCmpProjectUseCase { _ in
      if let readbackCmpProjectError {
        throw readbackCmpProjectError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "readbackCmpProject")
    },
    bootstrapCmpProjectUseCase: StubBootstrapCmpProjectUseCase { _ in
      if let bootstrapCmpProjectError {
        throw bootstrapCmpProjectError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "bootstrapCmpProject")
    },
    ingestCmpFlowUseCase: StubIngestCmpFlowUseCase { _ in
      if let ingestCmpFlowError {
        throw ingestCmpFlowError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "ingestCmpFlow")
    },
    commitCmpFlowUseCase: StubCommitCmpFlowUseCase { _ in
      if let commitCmpFlowError {
        throw commitCmpFlowError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "commitCmpFlow")
    },
    resolveCmpFlowUseCase: StubResolveCmpFlowUseCase { _ in
      if let resolveCmpFlowError {
        throw resolveCmpFlowError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "resolveCmpFlow")
    },
    materializeCmpFlowUseCase: StubMaterializeCmpFlowUseCase { _ in
      if let materializeCmpFlowError {
        throw materializeCmpFlowError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "materializeCmpFlow")
    },
    dispatchCmpFlowUseCase: StubDispatchCmpFlowUseCase { _ in
      if let dispatchCmpFlowError {
        throw dispatchCmpFlowError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "dispatchCmpFlow")
    },
    requestCmpHistoryUseCase: StubRequestCmpHistoryUseCase { _ in
      if let requestCmpHistoryError {
        throw requestCmpHistoryError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "requestCmpHistory")
    },
    readbackCmpStatusUseCase: StubReadbackCmpStatusUseCase { _ in
      if let readbackCmpStatusError {
        throw readbackCmpStatusError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "readbackCmpStatus")
    },
    smokeCmpProjectUseCase: StubSmokeCmpProjectUseCase { _ in
      if let smokeCmpProjectError {
        throw smokeCmpProjectError
      }
      throw RuntimeInterfaceUnexpectedInvocationError(operation: "smokeCmpProject")
    }
  )

  return PraxisRuntimeInterfaceSession(
    runtimeFacade: .init(runFacade: runFacade, inspectionFacade: inspectionFacade, cmpFacade: cmpFacade),
    blueprint: PraxisRuntimePresentationBridgeModule.bootstrap
  )
}

struct HostRuntimeInterfaceTests {
  @Test
  func runtimeInterfaceBuildsNeutralRunResponseAndBuffersEvents() async throws {
    let hostAdapters = PraxisHostAdapterRegistry.scaffoldDefaults()
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(hostAdapters: hostAdapters)

    let response = await runtimeInterface.handle(
      .runGoal(
        .init(
          payloadSummary: "Drive host-neutral runtime interface",
          goalID: "goal.runtime-interface",
          goalTitle: "Runtime Interface Goal",
          sessionID: "session.runtime-interface"
        )
      )
    )
    let bufferedEvents = await runtimeInterface.snapshotEvents()

    #expect(response.status == .success)
    #expect(response.error == nil)
    #expect(response.snapshot?.kind == .run)
    #expect(response.snapshot?.title == "Run run:session.runtime-interface:goal.runtime-interface")
    #expect(response.snapshot?.sessionID?.rawValue == "session.runtime-interface")
    #expect(response.snapshot?.phase == .running)
    #expect(response.snapshot?.lifecycleDisposition == .started)
    #expect(response.snapshot?.pendingIntentID == "evt.created.run:session.runtime-interface:goal.runtime-interface:model")
    #expect(response.events.map(\.name) == ["run.started", "run.follow_up_ready"])
    #expect(bufferedEvents.map(\.name) == ["run.started", "run.follow_up_ready"])
  }

  @Test
  func runtimeInterfaceExposesReplayAwareResumeDisposition() async throws {
    let sessionID = PraxisSessionID(rawValue: "session.interface-terminal")
    let runID = PraxisRunID(rawValue: "run:session.interface-terminal:goal.interface-terminal")
    let checkpointRecord = try makeRuntimeInterfaceCheckpointRecord(
      status: .paused,
      sessionID: sessionID,
      runID: runID,
      tickCount: 2,
      lastCursor: .init(sequence: 1)
    )
    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: PraxisFakeCheckpointStore(seedRecords: [checkpointRecord]),
      journalStore: PraxisFakeJournalStore(seedEvents: [
        .init(
          sequence: 2,
          sessionID: sessionID,
          runReference: runID.rawValue,
          type: "run.completed",
          summary: "Run completed with result interface-terminal",
          metadata: [
            "kernelEventType": .string("run.completed"),
            "kernelEventID": .string("evt.completed.\(runID.rawValue)"),
            "createdAt": .string("2026-04-10T22:10:00Z"),
            "resultID": .string("interface-terminal"),
          ]
        )
      ])
    )
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(hostAdapters: hostAdapters)

    let response = await runtimeInterface.handle(
      .resumeRun(
        .init(
          payloadSummary: "Replay and reconcile",
          runID: runID.rawValue
        )
      )
    )

    #expect(response.status == .success)
    #expect(response.snapshot?.phase == .completed)
    #expect(response.snapshot?.lifecycleDisposition == .recoveredWithoutResume)
    #expect(response.snapshot?.recoveredEventCount == 1)
    #expect(response.snapshot?.pendingIntentID == nil)
    #expect(response.events.map(\.name) == ["run.recovered"])
  }

  @Test
  func runtimeInterfaceRoutesCmpSessionAndProjectRequests() async throws {
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(
      hostAdapters: PraxisHostAdapterRegistry.localDefaults()
    )

    let sessionResponse = await runtimeInterface.handle(
      .openCmpSession(
        .init(
          payloadSummary: "Open local CMP session",
          projectID: "cmp.local-runtime",
          sessionID: "cmp.session.test"
        )
      )
    )
    let readbackResponse = await runtimeInterface.handle(
      .readbackCmpProject(
        .init(
          payloadSummary: "Read back local CMP project",
          projectID: "cmp.local-runtime"
        )
      )
    )
    let statusReadbackResponse = await runtimeInterface.handle(
      .readbackCmpStatus(
        .init(
          payloadSummary: "Read back CMP status",
          projectID: "cmp.local-runtime",
          agentID: "runtime.local"
        )
      )
    )
    let bootstrapResponse = await runtimeInterface.handle(
      .bootstrapCmpProject(
        .init(
          payloadSummary: "Bootstrap local CMP project",
          projectID: "cmp.local-runtime",
          agentIDs: ["runtime.local", "checker.local"]
        )
      )
    )
    let ingestResponse = await runtimeInterface.handle(
      .ingestCmpFlow(
        .init(
          payloadSummary: "Ingest local CMP flow",
          projectID: "cmp.local-runtime",
          agentID: "runtime.local",
          sessionID: "cmp.flow.session",
          taskSummary: "Capture one runtime material",
          materials: [
            .init(kind: .userInput, ref: "payload:user:cmp")
          ],
          requiresActiveSync: true
        )
      )
    )
    let commitResponse = await runtimeInterface.handle(
      .commitCmpFlow(
        .init(
          payloadSummary: "Commit local CMP flow",
          projectID: "cmp.local-runtime",
          agentID: "runtime.local",
          sessionID: "cmp.flow.session",
          eventIDs: ["evt.cmp.1"],
          changeSummary: "Commit accepted flow event",
          syncIntent: .toParent
        )
      )
    )
    _ = await runtimeInterface.handle(
      .runGoal(
        .init(
          payloadSummary: "Seed projection for resolve",
          goalID: "goal.cmp-flow-resolve",
          goalTitle: "CMP Flow Resolve Seed",
          sessionID: "session.cmp-flow-resolve"
        )
      )
    )
    let resolveResponse = await runtimeInterface.handle(
      .resolveCmpFlow(
        .init(
          payloadSummary: "Resolve local CMP flow",
          projectID: "cmp.local-runtime",
          agentID: "runtime.local"
        )
      )
    )
    let materializeResponse = await runtimeInterface.handle(
      .materializeCmpFlow(
        .init(
          payloadSummary: "Materialize local CMP flow",
          projectID: "cmp.local-runtime",
          agentID: "runtime.local",
          targetAgentID: "checker.local",
          packageKind: .runtimeFill,
          fidelityLabel: .highSignal
        )
      )
    )
    let materializeSnapshot = try #require(materializeResponse.snapshot)
    let materializePackageID = try #require(materializeResponse.events.first?.intentID)
    let contextPackage = PraxisCmpContextPackage(
      id: .init(rawValue: materializePackageID),
      sourceProjectionID: .init(rawValue: "projection.seed.runtime.local"),
      sourceSnapshotID: .init(rawValue: "projection.seed.runtime.local:checked"),
      sourceAgentID: "runtime.local",
      targetAgentID: "checker.local",
      kind: .runtimeFill,
      packageRef: "context://cmp.local-runtime/projection.seed.runtime.local/checker.local/runtimeFill",
      fidelityLabel: .highSignal,
      createdAt: "2026-04-11T00:00:00Z",
      sourceSectionIDs: [.init(rawValue: "projection.seed.runtime.local:section")]
    )
    let dispatchResponse = await runtimeInterface.handle(
      .dispatchCmpFlow(
        .init(
          payloadSummary: "Dispatch local CMP flow",
          projectID: "cmp.local-runtime",
          agentID: "runtime.local",
          contextPackage: contextPackage,
          targetKind: .peer,
          reason: "Forward runtime fill to checker"
        )
      )
    )
    let historyResponse = await runtimeInterface.handle(
      .requestCmpHistory(
        .init(
          payloadSummary: "Request local CMP history",
          projectID: "cmp.local-runtime",
          requesterAgentID: "checker.local",
          reason: "Recover high-signal context",
          query: .init(
            snapshotID: .init(rawValue: "projection.seed.runtime.local:checked"),
            packageKindHint: .historicalReply
          )
        )
      )
    )
    let smokeResponse = await runtimeInterface.handle(
      .smokeCmpProject(
        .init(
          payloadSummary: "Smoke local CMP project",
          projectID: "cmp.local-runtime"
        )
      )
    )

    #expect(sessionResponse.status == .success)
    #expect(sessionResponse.snapshot?.kind == .cmpSession)
    #expect(sessionResponse.snapshot?.projectID == "cmp.local-runtime")
    #expect(sessionResponse.events.map(\.name) == ["cmp.session.opened"])
    #expect(readbackResponse.status == .success)
    #expect(readbackResponse.snapshot?.kind == .cmpProject)
    #expect(readbackResponse.snapshot?.projectID == "cmp.local-runtime")
    #expect(statusReadbackResponse.status == .success)
    #expect(statusReadbackResponse.snapshot?.kind == .cmpStatus)
    #expect(statusReadbackResponse.snapshot?.title == "CMP Status cmp.local-runtime")
    #expect(statusReadbackResponse.events.map(\.name) == ["cmp.status.readback"])
    #expect(bootstrapResponse.status == .success)
    #expect(bootstrapResponse.snapshot?.kind == .cmpBootstrap)
    #expect(bootstrapResponse.snapshot?.title == "CMP Bootstrap cmp.local-runtime")
    #expect(bootstrapResponse.events.map(\.name) == ["cmp.project.bootstrapped"])
    #expect(ingestResponse.status == .success)
    #expect(ingestResponse.snapshot?.kind == .cmpFlow)
    #expect(ingestResponse.snapshot?.title == "CMP Ingest cmp.local-runtime")
    #expect(ingestResponse.snapshot?.sessionID == .init(rawValue: "cmp.flow.session"))
    #expect(ingestResponse.events.map(\.name) == ["cmp.flow.ingested"])
    #expect(ingestResponse.events.first?.sessionID == .init(rawValue: "cmp.flow.session"))
    #expect(commitResponse.status == .success)
    #expect(commitResponse.snapshot?.kind == .cmpFlow)
    #expect(commitResponse.snapshot?.title == "CMP Commit cmp.local-runtime")
    #expect(commitResponse.events.map(\.name) == ["cmp.flow.committed"])
    #expect(resolveResponse.status == .success)
    #expect(resolveResponse.snapshot?.kind == .cmpFlow)
    #expect(resolveResponse.snapshot?.title == "CMP Resolve cmp.local-runtime")
    #expect(resolveResponse.events.map(\.name) == ["cmp.flow.resolved"])
    #expect(materializeResponse.status == .success)
    #expect(materializeSnapshot.kind == .cmpFlow)
    #expect(materializeSnapshot.title == "CMP Materialize cmp.local-runtime")
    #expect(materializeResponse.events.map(\.name) == ["cmp.flow.materialized"])
    #expect(dispatchResponse.status == .success)
    #expect(dispatchResponse.snapshot?.kind == .cmpFlow)
    #expect(dispatchResponse.snapshot?.title == "CMP Dispatch cmp.local-runtime")
    #expect(dispatchResponse.events.map(\.name) == ["cmp.flow.dispatched"])
    #expect(historyResponse.status == .success)
    #expect(historyResponse.snapshot?.kind == .cmpFlow)
    #expect(historyResponse.snapshot?.title == "CMP History cmp.local-runtime")
    #expect(historyResponse.events.map(\.name) == ["cmp.flow.history_requested"])
    #expect(smokeResponse.status == .success)
    #expect(smokeResponse.snapshot?.kind == .smoke)
    #expect(smokeResponse.snapshot?.title == "CMP Smoke cmp.local-runtime")
  }

  @Test
  func runtimeInterfaceRoundTripsColonContainingSessionIDsAcrossRunAndResume() async throws {
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(
      hostAdapters: PraxisHostAdapterRegistry.scaffoldDefaults()
    )

    let started = await runtimeInterface.handle(
      .runGoal(
        .init(
          payloadSummary: "Lossless session identifier roundtrip",
          goalID: "goal.lossless-session",
          goalTitle: "Lossless Session Goal",
          sessionID: "team:alpha"
        )
      )
    )
    let resumed = await runtimeInterface.handle(
      .resumeRun(
        .init(
          payloadSummary: "Resume lossless session run",
          runID: started.snapshot?.runID?.rawValue ?? ""
        )
      )
    )

    #expect(started.status == .success)
    #expect(resumed.status == .success)
    #expect(started.snapshot?.sessionID?.rawValue == "team:alpha")
    #expect(resumed.snapshot?.sessionID?.rawValue == "team:alpha")
    #expect(resumed.snapshot?.phase == .running)
    #expect(resumed.snapshot?.lifecycleDisposition == .resumed)
    #expect(resumed.events.map(\.name) == ["run.resumed", "run.follow_up_ready"])
  }

  @Test
  func runtimeInterfaceReturnsStructuredMissingFieldErrorEnvelope() async throws {
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(
      hostAdapters: PraxisHostAdapterRegistry.scaffoldDefaults()
    )

    let response = await runtimeInterface.handle(
      .resumeRun(
        .init(
          payloadSummary: "Missing run ID",
          runID: ""
        )
      )
    )

    #expect(response.status == .failure)
    #expect(response.snapshot == nil)
    #expect(response.events.isEmpty)
    #expect(response.error?.code == .missingRequiredField)
    #expect(response.error?.missingField == "runID")
    #expect(response.error?.retryable == false)
  }

  @Test
  func runtimeInterfaceReturnsStructuredCheckpointNotFoundErrorEnvelope() async throws {
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(
      hostAdapters: PraxisHostAdapterRegistry.scaffoldDefaults()
    )
    let runID = "run:pct~team%3Aalpha:goal.missing-checkpoint"

    let response = await runtimeInterface.handle(
      .resumeRun(
        .init(
          payloadSummary: "Resume missing checkpoint",
          runID: runID
        )
      )
    )

    #expect(response.status == .failure)
    #expect(response.snapshot == nil)
    #expect(response.events.isEmpty)
    #expect(response.error?.code == .checkpointNotFound)
    #expect(response.error?.runID?.rawValue == runID)
    #expect(response.error?.sessionID?.rawValue == "team:alpha")
    #expect(response.error?.retryable == false)
  }

  @Test
  func runtimeInterfaceMapsInvalidInputAndDependencyMissingIntoStableErrorCodes() async throws {
    let invalidInputInterface = makeThrowingRuntimeInterface(
      inspectTapError: PraxisError.invalidInput("TAP inspection arguments are invalid.")
    )
    let dependencyMissingInterface = makeThrowingRuntimeInterface(
      inspectCmpError: PraxisError.dependencyMissing("CMP structured store adapter is unavailable.")
    )

    let invalidInputResponse = await invalidInputInterface.handle(.inspectTap)
    let dependencyMissingResponse = await dependencyMissingInterface.handle(.inspectCmp)

    #expect(invalidInputResponse.status == .failure)
    #expect(invalidInputResponse.error?.code == .invalidInput)
    #expect(invalidInputResponse.error?.message == "TAP inspection arguments are invalid.")
    #expect(invalidInputResponse.error?.retryable == false)
    #expect(invalidInputResponse.events.isEmpty)

    #expect(dependencyMissingResponse.status == .failure)
    #expect(dependencyMissingResponse.error?.code == .dependencyMissing)
    #expect(dependencyMissingResponse.error?.message == "CMP structured store adapter is unavailable.")
    #expect(dependencyMissingResponse.error?.retryable == false)
    #expect(dependencyMissingResponse.events.isEmpty)
  }

  @Test
  func runtimeInterfaceMapsUnsupportedOperationAndInvariantViolationIntoStableErrorCodes() async throws {
    let unsupportedInterface = makeThrowingRuntimeInterface(
      inspectMpError: PraxisError.unsupportedOperation("MP inspection is not available in this host profile.")
    )
    let invariantInterface = makeThrowingRuntimeInterface(
      runGoalError: PraxisError.invariantViolation("Run goal fixture entered an impossible state."),
    )

    let unsupportedResponse = await unsupportedInterface.handle(.inspectMp)
    let invariantResponse = await invariantInterface.handle(
      .runGoal(
        .init(
          payloadSummary: "Invariant smoke test",
          goalID: "goal.invariant-smoke",
          goalTitle: "Invariant Smoke Goal",
          sessionID: "session.invariant-smoke"
        )
      )
    )

    #expect(unsupportedResponse.status == .failure)
    #expect(unsupportedResponse.error?.code == .unsupportedOperation)
    #expect(unsupportedResponse.error?.message == "MP inspection is not available in this host profile.")
    #expect(unsupportedResponse.error?.retryable == false)

    #expect(invariantResponse.status == .failure)
    #expect(invariantResponse.error?.code == .invariantViolation)
    #expect(invariantResponse.error?.message == "Run goal fixture entered an impossible state.")
    #expect(invariantResponse.error?.sessionID?.rawValue == "session.invariant-smoke")
    #expect(invariantResponse.error?.runID == nil)
  }

  @Test
  func runtimeInterfaceMapsInvalidTransitionAndUnknownErrorsIntoStableErrorCodes() async throws {
    let invalidTransitionRunID = "run:pct~team%3Aalpha:goal.invalid-transition"
    let invalidTransitionInterface = makeThrowingRuntimeInterface(
      resumeRunError: PraxisInvalidTransitionError(
        fromStatus: .deciding,
        eventType: .runResumed,
        message: "Cannot resume a run while the state machine is still deciding."
      )
    )
    let unknownInterface = makeThrowingRuntimeInterface(
      resumeRunError: RuntimeInterfaceUnknownSmokeError(summary: "bridge exploded")
    )

    let invalidTransitionResponse = await invalidTransitionInterface.handle(
      .resumeRun(
        .init(
          payloadSummary: "Invalid transition smoke test",
          runID: invalidTransitionRunID
        )
      )
    )
    let unknownResponse = await unknownInterface.handle(
      .resumeRun(
        .init(
          payloadSummary: "Unknown failure smoke test",
          runID: invalidTransitionRunID
        )
      )
    )

    #expect(invalidTransitionResponse.status == .failure)
    #expect(invalidTransitionResponse.error?.code == .invalidTransition)
    #expect(invalidTransitionResponse.error?.message == "Cannot resume a run while the state machine is still deciding.")
    #expect(invalidTransitionResponse.error?.runID?.rawValue == invalidTransitionRunID)
    #expect(invalidTransitionResponse.error?.sessionID?.rawValue == "team:alpha")
    #expect(invalidTransitionResponse.error?.retryable == false)

    #expect(unknownResponse.status == .failure)
    #expect(unknownResponse.error?.code == .unknown)
    #expect(unknownResponse.error?.message.contains("RuntimeInterfaceUnknownSmokeError") == true)
    #expect(unknownResponse.error?.runID?.rawValue == invalidTransitionRunID)
    #expect(unknownResponse.error?.sessionID?.rawValue == "team:alpha")
    #expect(unknownResponse.error?.retryable == true)
  }

  @Test
  func runtimeInterfaceRegistryRoutesRequestsAcrossIndependentHandles() async throws {
    let hostAdapters = PraxisHostAdapterRegistry.scaffoldDefaults()
    let registry = PraxisRuntimeBridgeFactory.makeRuntimeInterfaceRegistry(hostAdapters: hostAdapters)

    let firstHandle = try await registry.openSession()
    let secondHandle = try await registry.openSession()

    #expect(firstHandle != secondHandle)
    #expect(await registry.activeHandles() == [firstHandle, secondHandle])
    #expect(await registry.containsSession(firstHandle))
    #expect(await registry.containsSession(secondHandle))
    #expect(await registry.bootstrapSnapshot(for: firstHandle)?.kind == .architecture)

    let started = await registry.handle(
      .runGoal(
        .init(
          payloadSummary: "Registry first handle run",
          goalID: "goal.registry-shared",
          goalTitle: "Registry Shared Goal",
          sessionID: "session.registry-shared"
        )
      ),
      on: firstHandle
    )
    let resumed = await registry.handle(
      .resumeRun(
        .init(
          payloadSummary: "Registry second handle resume",
          runID: started.snapshot?.runID?.rawValue ?? ""
        )
      ),
      on: secondHandle
    )

    let firstEvents = await registry.snapshotEvents(for: firstHandle)
    let secondEvents = await registry.snapshotEvents(for: secondHandle)

    #expect(started.status == .success)
    #expect(resumed.status == .success)
    #expect(resumed.snapshot?.runID == started.snapshot?.runID)
    #expect(firstEvents?.map(\.name) == ["run.started", "run.follow_up_ready"])
    #expect(secondEvents?.map(\.name) == ["run.resumed", "run.follow_up_ready"])

    #expect(await registry.closeSession(firstHandle))
    #expect(!(await registry.containsSession(firstHandle)))
    #expect(await registry.containsSession(secondHandle))
    #expect(await registry.activeHandles() == [secondHandle])
  }

  @Test
  func runtimeInterfaceRegistryReturnsSessionNotFoundForClosedHandles() async throws {
    let registry = PraxisRuntimeBridgeFactory.makeRuntimeInterfaceRegistry(
      hostAdapters: PraxisHostAdapterRegistry.scaffoldDefaults()
    )
    let handle = try await registry.openSession()

    #expect(await registry.closeSession(handle))
    #expect(await registry.bootstrapSnapshot(for: handle) == nil)
    #expect(await registry.snapshotEvents(for: handle) == nil)
    #expect(await registry.drainEvents(for: handle) == nil)

    let response = await registry.handle(.inspectArchitecture, on: handle)

    #expect(response.status == .failure)
    #expect(response.snapshot == nil)
    #expect(response.events.isEmpty)
    #expect(response.error?.code == .sessionNotFound)
    #expect(response.error?.message == "Runtime interface session handle \(handle.rawValue) was not found.")
    #expect(response.error?.retryable == false)
  }

  @Test
  func runtimeInterfaceCodecRoundTripsRequestAndResponse() async throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let request = PraxisRuntimeInterfaceRequest.resumeRun(
      .init(
        payloadSummary: "Resume this run",
        runID: "run:session.codec:goal.codec"
      )
    )
    let response = PraxisRuntimeInterfaceResponse(
      status: .success,
      snapshot: .init(
        kind: .run,
        title: "Run run:session.codec:goal.codec",
        summary: "Resumed running run run:session.codec:goal.codec.",
        runID: .init(rawValue: "run:session.codec:goal.codec"),
        sessionID: .init(rawValue: "session.codec"),
        phase: .running,
        tickCount: 2,
        lifecycleDisposition: .resumed,
        checkpointReference: "checkpoint.run:session.codec:goal.codec",
        pendingIntentID: "evt.resumed.run:session.codec:goal.codec:resume",
        recoveredEventCount: 1
      ),
      events: [
        .init(
          name: "run.resumed",
          detail: "Resumed running run run:session.codec:goal.codec.",
          runID: .init(rawValue: "run:session.codec:goal.codec"),
          sessionID: .init(rawValue: "session.codec"),
          intentID: "evt.resumed.run:session.codec:goal.codec:resume"
        )
      ],
      error: nil
    )

    let requestData = try codec.encode(request)
    let requestJSON = String(decoding: requestData, as: UTF8.self)
    let decodedRequest = try codec.decodeRequest(requestData)
    let responseData = try codec.encode(response)
    let responseJSON = String(decoding: responseData, as: UTF8.self)
    let decodedResponse = try codec.decodeResponse(responseData)

    #expect(
      requestJSON ==
        #"{"kind":"resumeRun","resumeRun":{"payloadSummary":"Resume this run","runID":"run:session.codec:goal.codec"}}"#
    )
    #expect(responseJSON.contains(#""status":"success""#))
    #expect(!responseJSON.contains(#""error":"#))
    #expect(responseJSON.contains(#""snapshot":{"#))
    #expect(decodedRequest == request)
    #expect(decodedResponse == response)
  }

  @Test
  func runtimeInterfaceCodecEncodesCmpProjectRequestsAsNestedPayloads() throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let request = PraxisRuntimeInterfaceRequest.readbackCmpProject(
      .init(
        payloadSummary: "Read back project",
        projectID: "cmp.local-runtime"
      )
    )

    let requestData = try codec.encode(request)
    let requestJSON = String(decoding: requestData, as: UTF8.self)
    let decodedRequest = try codec.decodeRequest(requestData)

    #expect(
      requestJSON ==
        #"{"kind":"readbackCmpProject","readbackCmpProject":{"payloadSummary":"Read back project","projectID":"cmp.local-runtime"}}"#
    )
    #expect(decodedRequest == request)
  }

  @Test
  func runtimeInterfaceCodecEncodesCmpBootstrapRequestsAsNestedPayloads() throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let request = PraxisRuntimeInterfaceRequest.bootstrapCmpProject(
      .init(
        payloadSummary: "Bootstrap project",
        projectID: "cmp.local-runtime",
        agentIDs: ["runtime.local", "checker.local"],
        defaultAgentID: "runtime.local",
        repoName: "praxis",
        defaultBranchName: "main",
        databaseName: "cmp_local_runtime",
        namespaceRoot: "cmp/cmp.local-runtime"
      )
    )

    let requestData = try codec.encode(request)
    let decodedRequest = try codec.decodeRequest(requestData)

    #expect(decodedRequest == request)
  }

  @Test
  func runtimeInterfaceCodecEncodesCmpFlowRequestsAsNestedPayloads() throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let ingestRequest = PraxisRuntimeInterfaceRequest.ingestCmpFlow(
      .init(
        payloadSummary: "Ingest flow",
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        sessionID: "cmp.flow.session",
        taskSummary: "Capture input",
        materials: [
          .init(kind: .userInput, ref: "payload:user:cmp")
        ],
        requiresActiveSync: true
      )
    )
    let historyRequest = PraxisRuntimeInterfaceRequest.requestCmpHistory(
      .init(
        payloadSummary: "Request history",
        projectID: "cmp.local-runtime",
        requesterAgentID: "checker.local",
        reason: "Recover context",
        query: .init(
          snapshotID: .init(rawValue: "projection.runtime.local:checked"),
          packageKindHint: .historicalReply
        )
      )
    )

    let ingestData = try codec.encode(ingestRequest)
    let historyData = try codec.encode(historyRequest)
    let decodedIngestRequest = try codec.decodeRequest(ingestData)
    let decodedHistoryRequest = try codec.decodeRequest(historyData)

    #expect(decodedIngestRequest == ingestRequest)
    #expect(decodedHistoryRequest == historyRequest)
  }

  @Test
  func runtimeInterfaceCodecEncodesCmpStatusRequestsAsNestedPayloads() throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let request = PraxisRuntimeInterfaceRequest.readbackCmpStatus(
      .init(
        payloadSummary: "Read back status",
        projectID: "cmp.local-runtime",
        agentID: "runtime.local"
      )
    )

    let requestData = try codec.encode(request)
    let decodedRequest = try codec.decodeRequest(requestData)

    #expect(decodedRequest == request)
  }

  @Test
  func runtimeInterfaceCodecDecodesLegacyFlatRunGoalAndResumeRequests() throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let legacyRunGoalJSON = """
    {"kind":"runGoal","payloadSummary":"Legacy run goal","goalID":"goal.legacy-flat","goalTitle":"Legacy Flat Goal","sessionID":"session.legacy-flat"}
    """
    let legacyResumeJSON = """
    {"kind":"resumeRun","payloadSummary":"Legacy resume","runID":"run:session.legacy-flat:goal.legacy-flat"}
    """

    let decodedRunGoal = try codec.decodeRequest(Data(legacyRunGoalJSON.utf8))
    let decodedResume = try codec.decodeRequest(Data(legacyResumeJSON.utf8))

    #expect(
      decodedRunGoal ==
        .runGoal(
          .init(
            payloadSummary: "Legacy run goal",
            goalID: "goal.legacy-flat",
            goalTitle: "Legacy Flat Goal",
            sessionID: "session.legacy-flat"
          )
        )
    )
    #expect(
      decodedResume ==
        .resumeRun(
          .init(
            payloadSummary: "Legacy resume",
            runID: "run:session.legacy-flat:goal.legacy-flat"
          )
        )
    )
  }
}
