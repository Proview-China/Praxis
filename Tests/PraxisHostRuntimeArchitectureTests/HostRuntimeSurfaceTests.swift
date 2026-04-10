import Testing
import Foundation
import PraxisCheckpoint
import PraxisCoreTypes
import PraxisGoal
import PraxisInfraContracts
import PraxisJournal
import PraxisRun
import PraxisSession
import PraxisState
import PraxisToolingContracts
import PraxisWorkspaceContracts
@testable import PraxisRuntimeComposition
@testable import PraxisRuntimeFacades
@testable import PraxisRuntimeInterface
@testable import PraxisRuntimePresentationBridge

private func encodeTestJSON<T: Encodable>(_ value: T) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]
  guard let string = String(data: try encoder.encode(value), encoding: .utf8) else {
    throw PraxisError.invariantViolation("Failed to encode test runtime payload as UTF-8 JSON.")
  }
  return string
}

private func decodeTestJSON<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
  guard let data = string.data(using: .utf8) else {
    throw PraxisError.invalidInput("Failed to decode test runtime payload from UTF-8 JSON.")
  }
  return try JSONDecoder().decode(type, from: data)
}

private func runHostTestProcess(
  executablePath: String,
  arguments: [String],
  currentDirectoryURL: URL? = nil
) throws -> (stdout: String, stderr: String, exitCode: Int32) {
  let process = Process()
  let stdoutPipe = Pipe()
  let stderrPipe = Pipe()
  process.executableURL = URL(fileURLWithPath: executablePath, isDirectory: false)
  process.arguments = arguments
  process.currentDirectoryURL = currentDirectoryURL
  process.standardOutput = stdoutPipe
  process.standardError = stderrPipe
  try process.run()
  process.waitUntilExit()
  return (
    stdout: String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
    stderr: String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
    exitCode: process.terminationStatus
  )
}

private func makeCheckpointRecord(
  status: PraxisAgentStatus,
  sessionID: PraxisSessionID,
  runID: PraxisRunID,
  tickCount: Int,
  lastCursor: PraxisJournalCursor?,
  lastErrorCode: String? = nil,
  lastErrorMessage: String? = nil
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
  let state = PraxisStateSnapshot(
    control: .init(status: status, phase: .recovery, retryCount: status == .failed ? 1 : 0),
    working: [:],
    observed: .init(),
    recovery: .init(
      lastCheckpointRef: checkpointID.rawValue,
      resumePointer: lastCursor.map { "cursor.\($0.sequence)" },
      lastErrorCode: lastErrorCode,
      lastErrorMessage: lastErrorMessage
    )
  )
  let aggregate = PraxisRunAggregate(
    id: runID,
    phase: phase,
    tickCount: tickCount,
    lastEventID: "evt.seed.\(runID.rawValue)",
    lastCheckpointReference: checkpointID.rawValue,
    failure: status == .failed ? .init(summary: lastErrorMessage ?? "Run failed.", code: lastErrorCode) : nil,
    latestState: state
  )
  let header = PraxisSessionHeader(
    id: sessionID,
    title: "Restored \(status.rawValue) run",
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
    createdAt: "2026-04-10T20:00:00Z",
    lastCursor: lastCursor,
    payload: [
      "runAggregateJSON": .string(try encodeTestJSON(aggregate)),
      "sessionHeaderJSON": .string(try encodeTestJSON(header)),
      "goalTitle": .string("Restored \(status.rawValue) run"),
    ]
  )
  return PraxisCheckpointRecord(
    pointer: .init(checkpointID: checkpointID, sessionID: sessionID),
    snapshot: snapshot
  )
}

struct HostRuntimeSurfaceTests {
  @Test
  func runtimeSurfaceModelsCaptureLocalHostProfileAndSmokeViews() {
    let hostProfile = PraxisLocalRuntimeHostProfile(
      executionStyle: "local-first",
      structuredStore: "sqlite",
      deliveryStore: "sqlite",
      messageTransport: "in_process_actor_bus",
      gitAccess: "system_git",
      semanticIndex: "accelerate"
    )
    let runtimeSummary = PraxisCmpProjectLocalRuntimeSummary(
      projectID: "project-1",
      hostProfile: hostProfile,
      componentStatuses: [
        "structuredStore": .ready,
        "messageTransport": .ready,
        "gitAccess": .degraded,
      ],
      issues: ["system git may require Command Line Tools installation"]
    )
    let smoke = PraxisRuntimeSmokeResult(
      summary: "local runtime mostly ready",
      checks: [
        .init(id: "cmp.host.sqlite", gate: "host", status: .ready, summary: "SQLite host profile ready"),
        .init(id: "cmp.host.git", gate: "host", status: .degraded, summary: "git may still need first-run installation")
      ]
    )

    #expect(runtimeSummary.hostProfile.executionStyle == "local-first")
    #expect(runtimeSummary.componentStatuses["gitAccess"] == PraxisTruthLayerStatus.degraded)
    #expect(smoke.checks.count == 2)
  }

  @Test
  func runtimeFacadeAndBridgeExposeHostBackedInspectionFlow() async throws {
    let hostAdapters = PraxisHostAdapterRegistry.scaffoldDefaults()
    let compositionRoot = PraxisRuntimeBridgeFactory.makeCompositionRoot(hostAdapters: hostAdapters)
    let dependencies = try compositionRoot.makeDependencyGraph()
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)
    let bridge = try PraxisRuntimeBridgeFactory.makeCLICommandBridge(hostAdapters: hostAdapters)

    let architectureState = try await bridge.handle(.init(intent: .inspectArchitecture, payloadSummary: ""))
    let tapState = try await bridge.handle(.init(intent: .inspectTap, payloadSummary: ""))
    let cmpState = try await bridge.handle(.init(intent: .inspectCmp, payloadSummary: ""))
    let mpState = try await bridge.handle(.init(intent: .inspectMp, payloadSummary: ""))
    let catalog = try await runtimeFacade.inspectionFacade.buildCapabilityCatalogSnapshot()

    #expect(architectureState.title == "Praxis Architecture")
    #expect(tapState.title == "TAP Inspection")
    #expect(cmpState.title == "CMP Inspection")
    #expect(mpState.title == "MP Inspection")
    #expect(tapState.summary.contains("checkpoint snapshot"))
    #expect(cmpState.summary.contains("sqlite persistence"))
    #expect(cmpState.summary.contains("install_prompt_expected"))
    #expect(mpState.summary.contains("Store:"))
    #expect(mpState.summary.contains("0 primary records"))
    #expect(catalog.summary.contains("Capability catalog assembled from current boundaries:"))
    #expect(catalog.summary.contains("Registered host capability surfaces:"))
    #expect(catalog.summary.contains("PraxisCmpFiveAgent"))
    #expect(dependencies.hostAdapters.providerInferenceExecutor != nil)
    #expect(dependencies.hostAdapters.checkpointStore != nil)

    let runState = try await bridge.handle(.init(intent: .runGoal, payloadSummary: "Bridge next action smoke"))
    let bridgeEvents = await bridge.snapshotEvents()

    #expect(runState.title == "Run run:session.cli.goal:cli.goal")
    #expect(runState.summary.contains("Next action model_inference"))
    #expect(runState.pendingIntentID == "evt.created.run:session.cli.goal:cli.goal:model")
    #expect(runState.events.map(\.name) == ["run.started", "run.follow_up_ready"])
    #expect(bridgeEvents.map(\.name) == ["run.started", "run.follow_up_ready"])
    #expect(bridgeEvents.last?.intentID == "evt.created.run:session.cli.goal:cli.goal:model")
  }

  @Test
  func ffiBridgeRoutesEncodedRuntimeInterfaceRequestsAcrossSessionHandles() async throws {
    let ffiBridge = try PraxisRuntimeBridgeFactory.makeFFIBridge()
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let handle = try await ffiBridge.openRuntimeSession()

    let request = PraxisRuntimeInterfaceRequest.runGoal(
      .init(
        payloadSummary: "FFI bridge smoke test",
        goalID: "goal.ffi-smoke",
        goalTitle: "FFI Smoke Goal",
        sessionID: "session.ffi-smoke"
      )
    )
    let responseData = try await ffiBridge.handleEncodedRequest(
      codec.encode(request),
      on: handle
    )
    let response = try codec.decodeResponse(responseData)
    let eventData = try await ffiBridge.drainEncodedEvents(for: handle)
    let eventEnvelope = try JSONDecoder().decode(PraxisFFIEventEnvelope.self, from: eventData)

    #expect(response.status == .success)
    #expect(response.snapshot?.sessionID?.rawValue == "session.ffi-smoke")
    #expect(response.events.map(\.name) == ["run.started", "run.follow_up_ready"])
    #expect(eventEnvelope.status == .success)
    #expect(eventEnvelope.handle == handle)
    #expect(eventEnvelope.events.map(\.name) == ["run.started", "run.follow_up_ready"])
    #expect(eventEnvelope.error == nil)
    #expect(await ffiBridge.activeRuntimeSessionHandles() == [handle])
  }

  @Test
  func ffiBridgeReturnsStructuredFailuresForInvalidPayloadAndClosedHandle() async throws {
    let ffiBridge = try PraxisRuntimeBridgeFactory.makeFFIBridge()
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let handle = try await ffiBridge.openRuntimeSession()

    let invalidResponseData = try await ffiBridge.handleEncodedRequest(
      Data("not-json".utf8),
      on: handle
    )
    let invalidResponse = try codec.decodeResponse(invalidResponseData)

    #expect(invalidResponse.status == .failure)
    #expect(invalidResponse.error?.code == .invalidInput)
    #expect(invalidResponse.error?.message.contains("Failed to decode runtime interface request payload") == true)

    #expect(await ffiBridge.closeRuntimeSession(handle))

    let closedResponseData = try await ffiBridge.handleEncodedRequest(
      codec.encode(.inspectArchitecture),
      on: handle
    )
    let closedResponse = try codec.decodeResponse(closedResponseData)
    let closedEventData = try await ffiBridge.snapshotEncodedEvents(for: handle)
    let closedEventEnvelope = try JSONDecoder().decode(PraxisFFIEventEnvelope.self, from: closedEventData)

    #expect(closedResponse.status == .failure)
    #expect(closedResponse.error?.code == .sessionNotFound)
    #expect(closedEventEnvelope.status == .failure)
    #expect(closedEventEnvelope.error?.code == .sessionNotFound)
    #expect(closedEventEnvelope.handle == handle)
  }

  @Test
  func ffiBridgeAcceptsLegacyFlatRuntimeInterfaceRequests() async throws {
    let ffiBridge = try PraxisRuntimeBridgeFactory.makeFFIBridge()
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let handle = try await ffiBridge.openRuntimeSession()
    let legacyRunGoalJSON = """
    {"kind":"runGoal","payloadSummary":"Legacy flat FFI request","goalID":"goal.legacy-ffi","goalTitle":"Legacy FFI Goal","sessionID":"session.legacy-ffi"}
    """

    let responseData = try await ffiBridge.handleEncodedRequest(
      Data(legacyRunGoalJSON.utf8),
      on: handle
    )
    let response = try codec.decodeResponse(responseData)

    #expect(response.status == .success)
    #expect(response.snapshot?.runID?.rawValue == "run:session.legacy-ffi:goal.legacy-ffi")
    #expect(response.snapshot?.sessionID?.rawValue == "session.legacy-ffi")
    #expect(response.events.map(\.name) == ["run.started", "run.follow_up_ready"])
  }

  @Test
  func runFacadePersistsCheckpointedLifecycleForResume() async throws {
    let checkpointStore = PraxisFakeCheckpointStore()
    let journalStore = PraxisFakeJournalStore()
    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: checkpointStore,
      journalStore: journalStore
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)

    let started = try await runtimeFacade.runFacade.runGoal(
      .init(
        goal: .init(
          normalizedGoal: .init(
            id: .init(rawValue: "goal.host-runtime"),
            title: "Host Runtime Goal",
            summary: "Verify Wave6 run orchestration"
          ),
          intentSummary: "Verify Wave6 run orchestration"
        ),
        sessionID: .init(rawValue: "session.host-runtime")
      )
    )

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: started.runID))
    let resumedCheckpoint = try await checkpointStore.load(
      pointer: .init(
        checkpointID: .init(rawValue: "checkpoint.\(started.runID.rawValue)"),
        sessionID: started.sessionID
      )
    )
    let resumedAggregate = try decodeTestJSON(
      PraxisRunAggregate.self,
      from: resumedCheckpoint?.snapshot.payload?["runAggregateJSON"]?.stringValue ?? ""
    )

    #expect(started.runID.rawValue == "run:session.host-runtime:goal.host-runtime")
    #expect(started.sessionID.rawValue == "session.host-runtime")
    #expect(started.phase == .running)
    #expect(started.tickCount == 1)
    #expect(started.checkpointReference == "checkpoint.run:session.host-runtime:goal.host-runtime")
    #expect(started.phaseSummary.contains("journal 1"))
    #expect(started.phaseSummary.contains("Next action model_inference"))
    #expect(started.followUpAction?.kind.rawValue == "model_inference")
    #expect(started.followUpAction?.intentKind?.rawValue == "model_inference")
    #expect(resumed.runID == started.runID)
    #expect(resumed.sessionID == started.sessionID)
    #expect(resumed.phase == .running)
    #expect(resumed.tickCount == 2)
    #expect(resumed.recoveredEventCount == 0)
    #expect(resumed.phaseSummary.contains("replayed 0 events"))
    #expect(resumed.phaseSummary.contains("journal 2"))
    #expect(resumed.phaseSummary.contains("Next action internal_step"))
    #expect(resumed.followUpAction?.kind.rawValue == "internal_step")
    #expect(resumed.followUpAction?.intentKind?.rawValue == "internal_step")
    #expect(resumedCheckpoint?.snapshot.lastCursor == .init(sequence: 2))
    #expect(resumedAggregate.phase == .running)
    #expect(resumedAggregate.pendingIntentID == "evt.resumed.run:session.host-runtime:goal.host-runtime:resume")
  }

  @Test
  func resumeFacadeRecoversPausedCheckpointAndBridgeExposesEventStream() async throws {
    let sessionID = PraxisSessionID(rawValue: "session.paused")
    let runID = PraxisRunID(rawValue: "run:session.paused:goal.paused")
    let checkpointRecord = try makeCheckpointRecord(
      status: .paused,
      sessionID: sessionID,
      runID: runID,
      tickCount: 3,
      lastCursor: .init(sequence: 4)
    )
    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: PraxisFakeCheckpointStore(seedRecords: [checkpointRecord]),
      journalStore: PraxisFakeJournalStore()
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)
    let bridge = try PraxisRuntimeBridgeFactory.makeCLICommandBridge(hostAdapters: hostAdapters)

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: runID))
    let state = try await bridge.handle(.init(intent: .resumeRun, payloadSummary: runID.rawValue))
    let events = await bridge.drainEvents()

    #expect(resumed.phase == .running)
    #expect(resumed.tickCount == 4)
    #expect(resumed.recoveredEventCount == 0)
    #expect(resumed.followUpAction?.intentID == "evt.resumed.run:session.paused:goal.paused:resume")
    #expect(state.pendingIntentID == "evt.resumed.run:session.paused:goal.paused:resume")
    #expect(state.events.map(\.name) == ["run.resumed", "run.follow_up_ready"])
    #expect(events.map(\.name) == ["run.resumed", "run.follow_up_ready"])
  }

  @Test
  func resumeFacadeRecoversFailedCheckpointAndPreservesReplayEvidence() async throws {
    let sessionID = PraxisSessionID(rawValue: "session.failed")
    let runID = PraxisRunID(rawValue: "run:session.failed:goal.failed")
    let checkpointRecord = try makeCheckpointRecord(
      status: .failed,
      sessionID: sessionID,
      runID: runID,
      tickCount: 5,
      lastCursor: .init(sequence: 1),
      lastErrorCode: "tool_failure",
      lastErrorMessage: "Provider timed out"
    )
    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: PraxisFakeCheckpointStore(seedRecords: [checkpointRecord]),
      journalStore: PraxisFakeJournalStore(seedEvents: [
        .init(
          sequence: 2,
          sessionID: sessionID,
          runReference: runID.rawValue,
          type: "capability.result_received",
          summary: "Late replay evidence"
        )
      ])
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: runID))

    #expect(resumed.phase == .running)
    #expect(resumed.tickCount == 6)
    #expect(resumed.recoveredEventCount == 1)
    #expect(resumed.checkpointReference == "checkpoint.run:session.failed:goal.failed")
    #expect(resumed.followUpAction?.kind.rawValue == "internal_step")
    #expect(resumed.phaseSummary.contains("replayed 1 events"))
  }

  @Test
  func resumeFacadeUsesReplayedTerminalJournalStateBeforeIssuingResume() async throws {
    let sessionID = PraxisSessionID(rawValue: "session.replayed-terminal")
    let runID = PraxisRunID(rawValue: "run:session.replayed-terminal:goal.replayed-terminal")
    let checkpointRecord = try makeCheckpointRecord(
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
          summary: "Run completed with result result-terminal",
          metadata: [
            "kernelEventType": .string("run.completed"),
            "kernelEventID": .string("evt.completed.\(runID.rawValue)"),
            "createdAt": .string("2026-04-10T21:00:00Z"),
            "resultID": .string("result-terminal"),
          ]
        )
      ])
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: runID))

    #expect(resumed.phase == .completed)
    #expect(resumed.recoveredEventCount == 1)
    #expect(resumed.followUpAction == nil)
    #expect(resumed.phaseSummary.contains("Recovered completed run"))
    #expect(!resumed.phaseSummary.contains("Next action internal_step"))
  }

  @Test
  func resumeFacadeReplaysCheckpointJournalBeyondSinglePageLimit() async throws {
    let sessionID = PraxisSessionID(rawValue: "session.replayed-many-events")
    let runID = PraxisRunID(rawValue: "run:session.replayed-many-events:goal.replayed-many-events")
    let checkpointRecord = try makeCheckpointRecord(
      status: .paused,
      sessionID: sessionID,
      runID: runID,
      tickCount: 2,
      lastCursor: .init(sequence: 1)
    )

    var replayEvents: [PraxisJournalEvent] = (2...60).map { sequence in
      PraxisJournalEvent(
        sequence: sequence,
        sessionID: sessionID,
        runReference: runID.rawValue,
        type: "checkpoint.created",
        summary: "Checkpoint replay-\(sequence) created in fast tier",
        metadata: [
          "kernelEventType": .string("checkpoint.created"),
          "kernelEventID": .string("evt.replayed.\(sequence).\(runID.rawValue)"),
          "createdAt": .string("2026-04-10T21:\(String(format: "%02d", sequence)):00Z"),
          "checkpointID": .string("checkpoint.replayed.\(sequence)"),
          "tier": .string("fast"),
        ]
      )
    }
    replayEvents.append(
      PraxisJournalEvent(
        sequence: 61,
        sessionID: sessionID,
        runReference: runID.rawValue,
        type: "run.completed",
        summary: "Run completed with result result-many-events",
        metadata: [
          "kernelEventType": .string("run.completed"),
          "kernelEventID": .string("evt.completed.\(runID.rawValue)"),
          "createdAt": .string("2026-04-10T22:01:00Z"),
          "resultID": .string("result-many-events"),
        ]
      )
    )

    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: PraxisFakeCheckpointStore(seedRecords: [checkpointRecord]),
      journalStore: PraxisFakeJournalStore(seedEvents: replayEvents)
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: runID))

    #expect(resumed.phase == .completed)
    #expect(resumed.recoveredEventCount == 60)
    #expect(resumed.followUpAction == nil)
    #expect(resumed.phaseSummary.contains("replayed 60 events"))
    #expect(resumed.phaseSummary.contains("Recovered completed run"))
  }

  @Test
  func resumeFacadeSupportsLegacyDotSeparatedRunIDsWithDottedSessionIDs() async throws {
    let sessionID = PraxisSessionID(rawValue: "session.host-runtime")
    let runID = PraxisRunID(rawValue: "run.session.host-runtime.goal.host-runtime")
    let checkpointRecord = try makeCheckpointRecord(
      status: .paused,
      sessionID: sessionID,
      runID: runID,
      tickCount: 2,
      lastCursor: .init(sequence: 3)
    )
    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: PraxisFakeCheckpointStore(seedRecords: [checkpointRecord]),
      journalStore: PraxisFakeJournalStore()
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: runID))

    #expect(resumed.sessionID == sessionID)
    #expect(resumed.phase == .running)
    #expect(resumed.checkpointReference == "checkpoint.run.session.host-runtime.goal.host-runtime")
  }

  @Test
  func resumeFacadePreservesLegacyColonRunIDsWithPercentEscapedLiteralSessions() async throws {
    let sessionID = PraxisSessionID(rawValue: "team%3Aalpha")
    let runID = PraxisRunID(rawValue: "run:team%3Aalpha:goal.percent-literal")
    let checkpointRecord = try makeCheckpointRecord(
      status: .paused,
      sessionID: sessionID,
      runID: runID,
      tickCount: 2,
      lastCursor: .init(sequence: 3)
    )
    let hostAdapters = PraxisHostAdapterRegistry(
      checkpointStore: PraxisFakeCheckpointStore(seedRecords: [checkpointRecord]),
      journalStore: PraxisFakeJournalStore()
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: hostAdapters)

    let resumed = try await runtimeFacade.runFacade.resumeRun(.init(runID: runID))

    #expect(resumed.sessionID == sessionID)
    #expect(resumed.phase == .running)
    #expect(resumed.checkpointReference == "checkpoint.run:team%3Aalpha:goal.percent-literal")
  }

  @Test
  func localDefaultsPersistCheckpointAndJournalAcrossIndependentRegistries() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-local-defaults-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let sessionID = PraxisSessionID(rawValue: "session.local-defaults")
    let runID = PraxisRunID(rawValue: "run:session.local-defaults:goal.local-defaults")
    let checkpointRecord = try makeCheckpointRecord(
      status: .paused,
      sessionID: sessionID,
      runID: runID,
      tickCount: 2,
      lastCursor: .init(sequence: 1)
    )

    let firstRegistry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    let secondRegistry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    let journalEvent = PraxisJournalEvent(
      sequence: 0,
      sessionID: sessionID,
      runReference: runID.rawValue,
      type: "run.created",
      summary: "Local defaults wrote one journal event"
    )

    _ = try await firstRegistry.checkpointStore?.save(checkpointRecord)
    _ = try await firstRegistry.journalStore?.append(.init(events: [journalEvent]))

    let loadedCheckpoint = try await secondRegistry.checkpointStore?.load(pointer: checkpointRecord.pointer)
    let loadedJournal = try await secondRegistry.journalStore?.read(
      .init(sessionID: sessionID.rawValue, limit: 10)
    )
    let gitReport = await secondRegistry.gitAvailabilityProbe?.probeGitReadiness()

    #expect(loadedCheckpoint?.snapshot.id == checkpointRecord.snapshot.id)
    #expect(loadedJournal?.events.count == 1)
    #expect(loadedJournal?.events.first?.summary == "Local defaults wrote one journal event")
    #expect(gitReport != nil)
    #expect(gitReport?.notes.isEmpty == false)
  }

  @Test
  func localDefaultsProvideRealWorkspaceAndLineageAdapters() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-local-workspace-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let firstRegistry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    let secondRegistry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)

    _ = try await firstRegistry.workspaceWriter?.apply(
      .init(
        changes: [
          .init(
            kind: .createFile,
            path: "Package.swift",
            content: "// swift-tools-version: 6.0\n"
          ),
          .init(
            kind: .createFile,
            path: "SWIFT_REFACTOR_PLAN.md",
            content: "# Local Test Plan\n"
          ),
          .init(
            kind: .createFile,
            path: "notes/runtime.txt",
            content: "alpha\nbeta\n"
          ),
        ],
        changeSummary: "Seed local workspace files"
      )
    )
    let initialRead = try await secondRegistry.workspaceReader?.read(
      .init(path: "notes/runtime.txt", includeRevisionToken: true)
    )
    _ = try await secondRegistry.workspaceWriter?.apply(
      .init(
        changes: [
          .init(
            kind: .updateFile,
            path: "notes/runtime.txt",
            content: "alpha\nbeta\nrelease\n",
            expectedRevisionToken: initialRead?.revisionToken
          )
        ],
        changeSummary: "Update workspace note"
      )
    )

    let rangedRead = try await secondRegistry.workspaceReader?.read(
      .init(path: "notes/runtime.txt", range: .init(startLine: 2, endLine: 3), includeRevisionToken: true)
    )
    let searchMatches = try await secondRegistry.workspaceSearcher?.search(
      .init(query: "release", kind: .fullText, maxResults: 5)
    )

    let lineageStore = PraxisLocalLineageStore(fileURL: rootDirectory.appendingPathComponent("lineages.json", isDirectory: false))
    try await lineageStore.save(
      .init(
        lineageID: .init(rawValue: "lineage.local"),
        branchRef: "cmp/local",
        summary: "Local lineage descriptor"
      )
    )
    let lineageDescriptor = try await secondRegistry.lineageStore?.describe(
      .init(lineageID: .init(rawValue: "lineage.local"))
    )

    #expect(rangedRead?.content == "beta\nrelease")
    #expect(rangedRead?.revisionToken != nil)
    #expect(searchMatches?.first?.path == "notes/runtime.txt")
    #expect(lineageDescriptor?.branchRef == "cmp/local")
  }

  @Test
  func localGitExecutorVerifiesRepositoryAndCmpInspectionReportsLocalAdapters() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-local-git-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }
    try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

    let gitInit = try runHostTestProcess(
      executablePath: "/usr/bin/git",
      arguments: ["init", "-q"],
      currentDirectoryURL: rootDirectory
    )
    #expect(gitInit.exitCode == 0)

    let registry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    _ = try await registry.projectionStore?.save(
      .init(
        projectID: "cmp.local-runtime",
        projectionID: .init(rawValue: "projection.local"),
        lineageID: .init(rawValue: "lineage.local"),
        agentID: "agent.local",
        visibilityLevel: .localOnly,
        storageKey: "sqlite://cmp/projection.local",
        updatedAt: "2026-04-11T02:00:00Z",
        summary: "Local runtime projection"
      )
    )
    let lineageStore = PraxisLocalLineageStore(fileURL: rootDirectory.appendingPathComponent("lineages.json", isDirectory: false))
    try await lineageStore.save(
      .init(
        lineageID: .init(rawValue: "lineage.local"),
        branchRef: "cmp/agent.local",
        summary: "Resolved local lineage"
      )
    )

    let gitReceipt = try await registry.gitExecutor?.apply(
      .init(
        operationID: "host-runtime.git.verify",
        repositoryRoot: rootDirectory.path,
        steps: [
          .init(kind: .verifyRepository, summary: "Verify local temp repository")
        ],
        summary: "Verify local git repository"
      )
    )
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: registry)
    let cmpSnapshot = try await runtimeFacade.inspectionFacade.inspectCmp()

    #expect(gitReceipt?.status == .applied)
    #expect(cmpSnapshot.summary.contains("workspace, git, and lineage state"))
    #expect(cmpSnapshot.hostRuntimeSummary.contains("workspace (ready)"))
    #expect(cmpSnapshot.hostRuntimeSummary.contains("lineage store (ready)"))
    #expect(cmpSnapshot.hostRuntimeSummary.contains("system git executor (ready)"))
    #expect(cmpSnapshot.persistenceSummary.contains("Lineage persistence resolved 1 of 1 projected lineages"))
  }

  @Test
  func cmpInspectionDoesNotRequirePraxisSentinelFilesForWorkspaceReadiness() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-workspace-health-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }
    try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

    let registry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: registry)
    let cmpSnapshot = try await runtimeFacade.inspectionFacade.inspectCmp()

    #expect(cmpSnapshot.hostRuntimeSummary.contains("workspace (ready)"))
    #expect(cmpSnapshot.hostRuntimeSummary.contains("system git executor (degraded)"))
    #expect(cmpSnapshot.persistenceSummary.contains("Lineage store is wired"))
  }

  @Test
  func cmpInspectionVerifiesGitAgainstConfiguredWorkspaceRoot() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-git-root-mismatch-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }
    try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

    let registry = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    let runtimeFacade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade(hostAdapters: registry)
    let cmpSnapshot = try await runtimeFacade.inspectionFacade.inspectCmp()

    #expect(cmpSnapshot.hostRuntimeSummary.contains("system git executor (degraded)"))
    #expect(cmpSnapshot.summary.contains("workspace, git, and lineage state"))
  }

  @Test
  func defaultBridgeFactoryReusesSharedLocalHostAdaptersAcrossBridgeInstances() async throws {
    let facade = try PraxisRuntimeBridgeFactory.makeRuntimeFacade()
    let goal = PraxisCompiledGoal(
      normalizedGoal: .init(
        id: .init(rawValue: "goal.shared-factory"),
        title: "Shared Factory Goal",
        summary: "Verify shared local adapters"
      ),
      intentSummary: "Verify shared local adapters"
    )
    let started = try await facade.runFacade.runGoal(
      .init(
        goal: goal,
        sessionID: .init(rawValue: "session.shared-factory")
      )
    )

    let bridge = try PraxisRuntimeBridgeFactory.makeCLICommandBridge()
    let resumedState = try await bridge.handle(
      .init(intent: .resumeRun, payloadSummary: started.runID.rawValue)
    )

    #expect(resumedState.title == "Run \(started.runID.rawValue)")
    #expect(resumedState.summary.contains("Resumed running run"))
    #expect(resumedState.pendingIntentID == "evt.resumed.\(started.runID.rawValue):resume")
  }
}
