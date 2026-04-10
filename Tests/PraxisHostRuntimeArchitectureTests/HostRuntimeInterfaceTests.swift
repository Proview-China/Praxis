import Foundation
import Testing
import PraxisCheckpoint
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

  return PraxisRuntimeInterfaceSession(
    runtimeFacade: .init(runFacade: runFacade, inspectionFacade: inspectionFacade),
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
