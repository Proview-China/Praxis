import Foundation
import PraxisGoal
import PraxisCoreTypes
import PraxisRuntimeFacades
import PraxisRun
import PraxisSession
import PraxisTransition

public protocol PraxisRuntimeInterfaceServing: Sendable {
  /// Returns the baseline architecture snapshot without mutating runtime state.
  ///
  /// - Returns: A host-neutral snapshot describing the current runtime topology.
  func bootstrapSnapshot() -> PraxisRuntimeInterfaceSnapshot

  /// Handles one host-neutral runtime request and returns a neutral response envelope.
  ///
  /// - Parameter request: The request to execute against the runtime surface.
  /// - Returns: A host-neutral response containing the latest snapshot and newly emitted events.
  func handle(_ request: PraxisRuntimeInterfaceRequest) async -> PraxisRuntimeInterfaceResponse

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

public actor PraxisRuntimeInterfaceRegistry {
  public typealias SessionFactory =
    @Sendable (PraxisRuntimeInterfaceSessionHandle) async throws -> any PraxisRuntimeInterfaceServing

  private var sessions: [PraxisRuntimeInterfaceSessionHandle: any PraxisRuntimeInterfaceServing]
  private var nextHandleSequence: Int
  private let sessionFactory: SessionFactory

  /// Creates a registry that owns host-neutral runtime interface sessions by opaque handle.
  ///
  /// - Parameters:
  ///   - sessions: Seed sessions keyed by existing handles.
  ///   - nextHandleSequence: Sequence used to derive the next generated handle identifier.
  ///   - sessionFactory: Factory that materializes a new serving session for each opened handle.
  public init(
    sessions: [PraxisRuntimeInterfaceSessionHandle: any PraxisRuntimeInterfaceServing] = [:],
    nextHandleSequence: Int = 1,
    sessionFactory: @escaping SessionFactory
  ) {
    self.sessions = sessions
    self.nextHandleSequence = nextHandleSequence
    self.sessionFactory = sessionFactory
  }

  /// Opens a new interface session and returns its stable opaque handle.
  ///
  /// - Returns: A newly allocated runtime interface session handle.
  /// - Throws: Any error raised while materializing the underlying session.
  public func openSession() async throws -> PraxisRuntimeInterfaceSessionHandle {
    let handle = makeNextHandle()
    sessions[handle] = try await sessionFactory(handle)
    return handle
  }

  /// Returns the currently active interface session handles.
  ///
  /// - Returns: Stable handles sorted by their opaque raw value.
  public func activeHandles() -> [PraxisRuntimeInterfaceSessionHandle] {
    sessions.keys.sorted { $0.rawValue < $1.rawValue }
  }

  /// Reports whether the registry still owns the given session handle.
  ///
  /// - Parameter handle: The opaque handle to look up.
  /// - Returns: `true` when the session is still active.
  public func containsSession(_ handle: PraxisRuntimeInterfaceSessionHandle) -> Bool {
    sessions[handle] != nil
  }

  /// Closes and removes one interface session from the registry.
  ///
  /// - Parameter handle: The opaque handle to close.
  /// - Returns: `true` when a live handle was removed.
  public func closeSession(_ handle: PraxisRuntimeInterfaceSessionHandle) -> Bool {
    sessions.removeValue(forKey: handle) != nil
  }

  /// Returns the architecture bootstrap snapshot for a live handle.
  ///
  /// - Parameter handle: The opaque session handle to inspect.
  /// - Returns: The bootstrap snapshot when the handle exists, otherwise `nil`.
  public func bootstrapSnapshot(
    for handle: PraxisRuntimeInterfaceSessionHandle
  ) -> PraxisRuntimeInterfaceSnapshot? {
    guard let session = sessions[handle] else {
      return nil
    }
    return session.bootstrapSnapshot()
  }

  /// Routes one runtime request to the interface session identified by the handle.
  ///
  /// - Parameters:
  ///   - request: The host-neutral runtime request to execute.
  ///   - handle: The opaque session handle that owns the event buffer for this request.
  /// - Returns: A neutral response envelope. Missing handles map to `session_not_found`.
  public func handle(
    _ request: PraxisRuntimeInterfaceRequest,
    on handle: PraxisRuntimeInterfaceSessionHandle
  ) async -> PraxisRuntimeInterfaceResponse {
    guard let session = sessions[handle] else {
      return .failure(
        error: .init(
          code: .sessionNotFound,
          message: "Runtime interface session handle \(handle.rawValue) was not found."
        )
      )
    }
    return await session.handle(request)
  }

  /// Returns buffered events for a live handle without clearing them.
  ///
  /// - Parameter handle: The opaque session handle to inspect.
  /// - Returns: Buffered events when the handle exists, otherwise `nil`.
  public func snapshotEvents(
    for handle: PraxisRuntimeInterfaceSessionHandle
  ) async -> [PraxisRuntimeInterfaceEvent]? {
    guard let session = sessions[handle] else {
      return nil
    }
    return await session.snapshotEvents()
  }

  /// Returns and clears buffered events for a live handle.
  ///
  /// - Parameter handle: The opaque session handle to drain.
  /// - Returns: Drained events when the handle exists, otherwise `nil`.
  public func drainEvents(
    for handle: PraxisRuntimeInterfaceSessionHandle
  ) async -> [PraxisRuntimeInterfaceEvent]? {
    guard let session = sessions[handle] else {
      return nil
    }
    return await session.drainEvents()
  }

  private func makeNextHandle() -> PraxisRuntimeInterfaceSessionHandle {
    while true {
      let handle = PraxisRuntimeInterfaceSessionHandle(
        rawValue: "runtime-interface-session-\(nextHandleSequence)"
      )
      nextHandleSequence += 1
      if sessions[handle] == nil {
        return handle
      }
    }
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

  public func handle(_ request: PraxisRuntimeInterfaceRequest) async -> PraxisRuntimeInterfaceResponse {
    do {
      let response = try await handleThrowing(request)
      if response.isSuccess {
        events.append(contentsOf: response.events)
      }
      return response
    } catch {
      return failureResponse(for: error, request: request)
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
    return .success(snapshot: snapshot, events: makeEvents(from: summary))
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

  private func handleThrowing(_ request: PraxisRuntimeInterfaceRequest) async throws -> PraxisRuntimeInterfaceResponse {
    switch request {
    case .inspectArchitecture:
      return .success(snapshot: bootstrapSnapshot())
    case .runGoal(let payload):
      let goal = PraxisCompiledGoal(
        normalizedGoal: .init(
          id: .init(rawValue: payload.goalID),
          title: payload.goalTitle,
          summary: payload.payloadSummary
        ),
        intentSummary: payload.payloadSummary
      )
      let summary = try await runtimeFacade.runFacade.runGoal(
        .init(
          goal: goal,
          sessionID: payload.sessionID.map(PraxisSessionID.init(rawValue:))
        )
      )
      return response(from: summary)
    case .resumeRun(let payload):
      guard !payload.runID.isEmpty else {
        throw PraxisRuntimeInterfaceError.missingRequiredField("runID")
      }
      let summary = try await runtimeFacade.runFacade.resumeRun(
        .init(runID: .init(rawValue: payload.runID))
      )
      return response(from: summary)
    case .inspectTap:
      let inspection = try await runtimeFacade.inspectionFacade.inspectTap()
      return .success(
        snapshot: .init(
          kind: .inspection,
          title: "TAP Inspection",
          summary: "\(inspection.summary) Governance: \(inspection.governanceSummary)"
        )
      )
    case .inspectCmp:
      let inspection = try await runtimeFacade.inspectionFacade.inspectCmp()
      return .success(
        snapshot: .init(
          kind: .inspection,
          title: "CMP Inspection",
          summary: "\(inspection.projectID): \(inspection.hostRuntimeSummary)"
        )
      )
    case .inspectMp:
      let inspection = try await runtimeFacade.inspectionFacade.inspectMp()
      return .success(
        snapshot: .init(
          kind: .inspection,
          title: "MP Inspection",
          summary: "\(inspection.summary) Store: \(inspection.memoryStoreSummary)"
        )
      )
    case .buildCapabilityCatalog:
      let inspection = try await runtimeFacade.inspectionFacade.buildCapabilityCatalogSnapshot()
      return .success(
        snapshot: .init(
          kind: .catalog,
          title: "Capability Catalog",
          summary: inspection.summary
        )
      )
    }
  }

  private func failureResponse(
    for error: Error,
    request: PraxisRuntimeInterfaceRequest
  ) -> PraxisRuntimeInterfaceResponse {
    let runID = request.runID.map(PraxisRunID.init(rawValue:))
    let sessionID = request.sessionID.map(PraxisSessionID.init(rawValue:))
      ?? runID.map { PraxisSessionID(rawValue: PraxisRunIdentityCodec().sessionRawValue(from: $0)) }

    let envelope: PraxisRuntimeInterfaceErrorEnvelope
    switch error {
    case let interfaceError as PraxisRuntimeInterfaceError:
      switch interfaceError {
      case .missingRequiredField(let field):
        envelope = .init(
          code: .missingRequiredField,
          message: "Required field \(field) is missing.",
          missingField: field,
          runID: runID,
          sessionID: sessionID
        )
      }
    case let praxisError as PraxisError:
      envelope = errorEnvelope(from: praxisError, runID: runID, sessionID: sessionID)
    case let transitionError as PraxisInvalidTransitionError:
      envelope = .init(
        code: .invalidTransition,
        message: transitionError.message,
        runID: runID,
        sessionID: sessionID
      )
    default:
      envelope = .init(
        code: .unknown,
        message: String(describing: error),
        retryable: true,
        runID: runID,
        sessionID: sessionID
      )
    }

    return .failure(error: envelope)
  }

  private func errorEnvelope(
    from error: PraxisError,
    runID: PraxisRunID?,
    sessionID: PraxisSessionID?
  ) -> PraxisRuntimeInterfaceErrorEnvelope {
    switch error {
    case .invalidInput(let message):
      let code: PraxisRuntimeInterfaceErrorCode =
        message.hasPrefix("No checkpoint record found for run ") ? .checkpointNotFound : .invalidInput
      return .init(
        code: code,
        message: message,
        runID: runID,
        sessionID: sessionID
      )
    case .invariantViolation(let message):
      return .init(
        code: .invariantViolation,
        message: message,
        runID: runID,
        sessionID: sessionID
      )
    case .dependencyMissing(let message):
      return .init(
        code: .dependencyMissing,
        message: message,
        runID: runID,
        sessionID: sessionID
      )
    case .unsupportedOperation(let message):
      return .init(
        code: .unsupportedOperation,
        message: message,
        runID: runID,
        sessionID: sessionID
      )
    }
  }
}

public enum PraxisRuntimeInterfaceError: Error, Sendable, Equatable {
  case missingRequiredField(String)
}
