import Foundation
import PraxisGoal
import PraxisRuntimeFacades
import PraxisRun
import PraxisSession

public protocol PraxisRuntimeInterfaceServing: Sendable {
  /// Returns the baseline architecture snapshot without mutating runtime state.
  ///
  /// - Returns: A host-neutral snapshot describing the current runtime topology.
  func bootstrapSnapshot() -> PraxisRuntimeInterfaceSnapshot

  /// Handles one host-neutral runtime request and returns a neutral response envelope.
  ///
  /// - Parameter request: The request to execute against the runtime surface.
  /// - Returns: A host-neutral response containing the latest snapshot and newly emitted events.
  /// - Throws: Any validation or runtime error raised while handling the request.
  func handle(_ request: PraxisRuntimeInterfaceRequest) async throws -> PraxisRuntimeInterfaceResponse

  /// Returns all accumulated runtime interface events without clearing them.
  ///
  /// - Returns: The current buffered event list.
  func snapshotEvents() async -> [PraxisRuntimeInterfaceEvent]

  /// Returns and clears all accumulated runtime interface events.
  ///
  /// - Returns: The drained event list.
  func drainEvents() async -> [PraxisRuntimeInterfaceEvent]
}

public protocol PraxisRuntimeInterfaceCoding: Sendable {
  /// Encodes a runtime interface request.
  ///
  /// - Parameter request: The request to encode.
  /// - Returns: Serialized request data.
  /// - Throws: Any encoding error produced by the codec.
  func encode(_ request: PraxisRuntimeInterfaceRequest) throws -> Data

  /// Decodes a runtime interface request.
  ///
  /// - Parameter data: Serialized request data.
  /// - Returns: The decoded request envelope.
  /// - Throws: Any decoding error produced by the codec.
  func decodeRequest(_ data: Data) throws -> PraxisRuntimeInterfaceRequest

  /// Encodes a runtime interface response.
  ///
  /// - Parameter response: The response to encode.
  /// - Returns: Serialized response data.
  /// - Throws: Any encoding error produced by the codec.
  func encode(_ response: PraxisRuntimeInterfaceResponse) throws -> Data

  /// Decodes a runtime interface response.
  ///
  /// - Parameter data: Serialized response data.
  /// - Returns: The decoded response envelope.
  /// - Throws: Any decoding error produced by the codec.
  func decodeResponse(_ data: Data) throws -> PraxisRuntimeInterfaceResponse
}

public struct PraxisJSONRuntimeInterfaceCodec: Sendable, PraxisRuntimeInterfaceCoding {
  public init() {}

  public func encode(_ request: PraxisRuntimeInterfaceRequest) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(request)
  }

  public func decodeRequest(_ data: Data) throws -> PraxisRuntimeInterfaceRequest {
    try JSONDecoder().decode(PraxisRuntimeInterfaceRequest.self, from: data)
  }

  public func encode(_ response: PraxisRuntimeInterfaceResponse) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(response)
  }

  public func decodeResponse(_ data: Data) throws -> PraxisRuntimeInterfaceResponse {
    try JSONDecoder().decode(PraxisRuntimeInterfaceResponse.self, from: data)
  }
}

public actor PraxisRuntimeInterfaceSession: PraxisRuntimeInterfaceServing {
  public let runtimeFacade: PraxisRuntimeFacade
  public let blueprint: PraxisRuntimeBlueprint

  private var events: [PraxisRuntimeInterfaceEvent]

  public init(
    runtimeFacade: PraxisRuntimeFacade,
    blueprint: PraxisRuntimeBlueprint,
    events: [PraxisRuntimeInterfaceEvent] = []
  ) {
    self.runtimeFacade = runtimeFacade
    self.blueprint = blueprint
    self.events = events
  }

  public nonisolated func bootstrapSnapshot() -> PraxisRuntimeInterfaceSnapshot {
    PraxisRuntimeInterfaceSnapshot(
      kind: .architecture,
      title: "Praxis Architecture",
      summary: "Foundation \(blueprint.foundationModules.count) / Domain \(blueprint.functionalDomainModules.count) / Host \(blueprint.hostContractModules.count + blueprint.runtimeModules.count)"
    )
  }

  public func handle(_ request: PraxisRuntimeInterfaceRequest) async throws -> PraxisRuntimeInterfaceResponse {
    switch request.kind {
    case .inspectArchitecture:
      return .init(snapshot: bootstrapSnapshot())
    case .runGoal:
      let goal = PraxisCompiledGoal(
        normalizedGoal: .init(
          id: .init(rawValue: request.goalID ?? "external.goal"),
          title: request.goalTitle ?? "External requested goal",
          summary: request.payloadSummary
        ),
        intentSummary: request.payloadSummary
      )
      let summary = try await runtimeFacade.runFacade.runGoal(
        .init(
          goal: goal,
          sessionID: request.sessionID.map(PraxisSessionID.init(rawValue:))
        )
      )
      let response = response(from: summary)
      events.append(contentsOf: response.events)
      return response
    case .resumeRun:
      guard let runID = request.runID, !runID.isEmpty else {
        throw PraxisRuntimeInterfaceError.missingRequiredField("runID")
      }
      let summary = try await runtimeFacade.runFacade.resumeRun(
        .init(runID: .init(rawValue: runID))
      )
      let response = response(from: summary)
      events.append(contentsOf: response.events)
      return response
    case .inspectTap:
      let inspection = try await runtimeFacade.inspectionFacade.inspectTap()
      return .init(
        snapshot: .init(
          kind: .inspection,
          title: "TAP Inspection",
          summary: "\(inspection.summary) Governance: \(inspection.governanceSummary)"
        )
      )
    case .inspectCmp:
      let inspection = try await runtimeFacade.inspectionFacade.inspectCmp()
      return .init(
        snapshot: .init(
          kind: .inspection,
          title: "CMP Inspection",
          summary: "\(inspection.projectID): \(inspection.hostRuntimeSummary)"
        )
      )
    case .inspectMp:
      let inspection = try await runtimeFacade.inspectionFacade.inspectMp()
      return .init(
        snapshot: .init(
          kind: .inspection,
          title: "MP Inspection",
          summary: "\(inspection.summary) Store: \(inspection.memoryStoreSummary)"
        )
      )
    case .buildCapabilityCatalog:
      let inspection = try await runtimeFacade.inspectionFacade.buildCapabilityCatalogSnapshot()
      return .init(
        snapshot: .init(
          kind: .catalog,
          title: "Capability Catalog",
          summary: inspection.summary
        )
      )
    }
  }

  public func snapshotEvents() async -> [PraxisRuntimeInterfaceEvent] {
    events
  }

  public func drainEvents() async -> [PraxisRuntimeInterfaceEvent] {
    let snapshot = events
    events = []
    return snapshot
  }

  private func response(from summary: PraxisRunSummary) -> PraxisRuntimeInterfaceResponse {
    let snapshot = PraxisRuntimeInterfaceSnapshot(
      kind: .run,
      title: "Run \(summary.runID.rawValue)",
      summary: summary.phaseSummary,
      runID: summary.runID,
      sessionID: summary.sessionID,
      phase: summary.phase,
      tickCount: summary.tickCount,
      lifecycleDisposition: summary.lifecycleDisposition,
      checkpointReference: summary.checkpointReference,
      pendingIntentID: summary.followUpAction?.intentID,
      recoveredEventCount: summary.recoveredEventCount
    )
    return .init(snapshot: snapshot, events: makeEvents(from: summary))
  }

  private func makeEvents(from summary: PraxisRunSummary) -> [PraxisRuntimeInterfaceEvent] {
    let lifecycleEventName: String
    switch summary.lifecycleDisposition {
    case .started:
      lifecycleEventName = "run.started"
    case .resumed:
      lifecycleEventName = "run.resumed"
    case .recoveredWithoutResume:
      lifecycleEventName = "run.recovered"
    }

    var mapped: [PraxisRuntimeInterfaceEvent] = [
      .init(
        name: lifecycleEventName,
        detail: summary.phaseSummary,
        runID: summary.runID,
        sessionID: summary.sessionID,
        intentID: summary.followUpAction?.intentID
      )
    ]

    if let followUpAction = summary.followUpAction {
      mapped.append(
        .init(
          name: "run.follow_up_ready",
          detail: "\(followUpAction.kind.rawValue): \(followUpAction.reason)",
          runID: summary.runID,
          sessionID: summary.sessionID,
          intentID: followUpAction.intentID
        )
      )
    }

    return mapped
  }
}

public enum PraxisRuntimeInterfaceError: Error, Sendable, Equatable {
  case missingRequiredField(String)
}
