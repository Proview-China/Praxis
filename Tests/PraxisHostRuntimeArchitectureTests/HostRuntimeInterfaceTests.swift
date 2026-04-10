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
@testable import PraxisRuntimeInterface
@testable import PraxisRuntimePresentationBridge

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

struct HostRuntimeInterfaceTests {
  @Test
  func runtimeInterfaceBuildsNeutralRunResponseAndBuffersEvents() async throws {
    let hostAdapters = PraxisHostAdapterRegistry.scaffoldDefaults()
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(hostAdapters: hostAdapters)

    let response = try await runtimeInterface.handle(
      .init(
        kind: .runGoal,
        payloadSummary: "Drive host-neutral runtime interface",
        goalID: "goal.runtime-interface",
        goalTitle: "Runtime Interface Goal",
        sessionID: "session.runtime-interface"
      )
    )
    let bufferedEvents = await runtimeInterface.snapshotEvents()

    #expect(response.snapshot.kind == .run)
    #expect(response.snapshot.title == "Run run:session.runtime-interface:goal.runtime-interface")
    #expect(response.snapshot.sessionID?.rawValue == "session.runtime-interface")
    #expect(response.snapshot.phase == .running)
    #expect(response.snapshot.lifecycleDisposition == .started)
    #expect(response.snapshot.pendingIntentID == "evt.created.run:session.runtime-interface:goal.runtime-interface:model")
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

    let response = try await runtimeInterface.handle(
      .init(
        kind: .resumeRun,
        payloadSummary: "Replay and reconcile",
        runID: runID.rawValue
      )
    )

    #expect(response.snapshot.phase == .completed)
    #expect(response.snapshot.lifecycleDisposition == .recoveredWithoutResume)
    #expect(response.snapshot.recoveredEventCount == 1)
    #expect(response.snapshot.pendingIntentID == nil)
    #expect(response.events.map(\.name) == ["run.recovered"])
  }

  @Test
  func runtimeInterfaceRoundTripsColonContainingSessionIDsAcrossRunAndResume() async throws {
    let runtimeInterface = try PraxisRuntimeBridgeFactory.makeRuntimeInterface(
      hostAdapters: PraxisHostAdapterRegistry.scaffoldDefaults()
    )

    let started = try await runtimeInterface.handle(
      .init(
        kind: .runGoal,
        payloadSummary: "Lossless session identifier roundtrip",
        goalID: "goal.lossless-session",
        goalTitle: "Lossless Session Goal",
        sessionID: "team:alpha"
      )
    )
    let resumed = try await runtimeInterface.handle(
      .init(
        kind: .resumeRun,
        payloadSummary: "Resume lossless session run",
        runID: started.snapshot.runID?.rawValue
      )
    )

    #expect(started.snapshot.sessionID?.rawValue == "team:alpha")
    #expect(resumed.snapshot.sessionID?.rawValue == "team:alpha")
    #expect(resumed.snapshot.phase == .running)
    #expect(resumed.snapshot.lifecycleDisposition == .resumed)
    #expect(resumed.events.map(\.name) == ["run.resumed", "run.follow_up_ready"])
  }

  @Test
  func runtimeInterfaceCodecRoundTripsRequestAndResponse() async throws {
    let codec = PraxisJSONRuntimeInterfaceCodec()
    let request = PraxisRuntimeInterfaceRequest(
      kind: .resumeRun,
      payloadSummary: "Resume this run",
      runID: "run:session.codec:goal.codec"
    )
    let response = PraxisRuntimeInterfaceResponse(
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
      ]
    )

    let requestData = try codec.encode(request)
    let decodedRequest = try codec.decodeRequest(requestData)
    let responseData = try codec.encode(response)
    let decodedResponse = try codec.decodeResponse(responseData)

    #expect(decodedRequest == request)
    #expect(decodedResponse == response)
  }
}
