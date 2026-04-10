import PraxisRun
import PraxisRuntimeFacades
import PraxisSession

public enum PraxisRuntimeInterfaceResponseStatus: String, Sendable, Equatable, Codable {
  case success
  case failure
}

public enum PraxisRuntimeInterfaceErrorCode: String, Sendable, Equatable, Codable {
  case sessionNotFound = "session_not_found"
  case missingRequiredField = "missing_required_field"
  case checkpointNotFound = "checkpoint_not_found"
  case invalidInput = "invalid_input"
  case dependencyMissing = "dependency_missing"
  case unsupportedOperation = "unsupported_operation"
  case invalidTransition = "invalid_transition"
  case invariantViolation = "invariant_violation"
  case unknown = "unknown_error"
}

public enum PraxisRuntimeInterfaceCommandKind: String, Sendable, Equatable, Codable {
  case inspectArchitecture
  case runGoal
  case resumeRun
  case inspectTap
  case inspectCmp
  case inspectMp
  case buildCapabilityCatalog
}

/// Stable opaque handle used to address one runtime interface session inside a registry.
///
/// This handle identifies the interface-side session lifecycle only. It does not imply an
/// isolated runtime persistence sandbox, because multiple handles may still share the same
/// host-backed stores underneath the facade layer.
public struct PraxisRuntimeInterfaceSessionHandle: RawRepresentable, Hashable, Sendable, Equatable, Codable {
  public let rawValue: String

  /// Creates a session handle from a stable raw value.
  ///
  /// - Parameter rawValue: Opaque handle identifier managed by the registry layer.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisRuntimeInterfaceRunGoalRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let goalID: String
  public let goalTitle: String
  public let sessionID: String?

  public init(
    payloadSummary: String,
    goalID: String,
    goalTitle: String,
    sessionID: String? = nil
  ) {
    self.payloadSummary = payloadSummary
    self.goalID = goalID
    self.goalTitle = goalTitle
    self.sessionID = sessionID
  }
}

public struct PraxisRuntimeInterfaceResumeRunRequestPayload: Sendable, Equatable, Codable {
  public let payloadSummary: String
  public let runID: String

  public init(payloadSummary: String, runID: String) {
    self.payloadSummary = payloadSummary
    self.runID = runID
  }
}

public enum PraxisRuntimeInterfaceRequest: Sendable, Equatable, Codable {
  case inspectArchitecture
  case runGoal(PraxisRuntimeInterfaceRunGoalRequestPayload)
  case resumeRun(PraxisRuntimeInterfaceResumeRunRequestPayload)
  case inspectTap
  case inspectCmp
  case inspectMp
  case buildCapabilityCatalog

  public var kind: PraxisRuntimeInterfaceCommandKind {
    switch self {
    case .inspectArchitecture:
      return .inspectArchitecture
    case .runGoal:
      return .runGoal
    case .resumeRun:
      return .resumeRun
    case .inspectTap:
      return .inspectTap
    case .inspectCmp:
      return .inspectCmp
    case .inspectMp:
      return .inspectMp
    case .buildCapabilityCatalog:
      return .buildCapabilityCatalog
    }
  }

  public var payloadSummary: String {
    switch self {
    case .runGoal(let payload):
      return payload.payloadSummary
    case .resumeRun(let payload):
      return payload.payloadSummary
    case .inspectArchitecture, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return ""
    }
  }

  public var sessionID: String? {
    switch self {
    case .runGoal(let payload):
      return payload.sessionID
    case .inspectArchitecture, .resumeRun, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return nil
    }
  }

  public var runID: String? {
    switch self {
    case .resumeRun(let payload):
      return payload.runID
    case .inspectArchitecture, .runGoal, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      return nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case runGoal
    case resumeRun
    case payloadSummary
    case goalID
    case goalTitle
    case sessionID
    case runID
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(PraxisRuntimeInterfaceCommandKind.self, forKey: .kind)

    switch kind {
    case .inspectArchitecture:
      self = .inspectArchitecture
    case .runGoal:
      if let payload = try container.decodeIfPresent(PraxisRuntimeInterfaceRunGoalRequestPayload.self, forKey: .runGoal) {
        self = .runGoal(payload)
      } else {
        self = .runGoal(
          .init(
            payloadSummary: try container.decodeIfPresent(String.self, forKey: .payloadSummary) ?? "",
            goalID: try container.decodeIfPresent(String.self, forKey: .goalID) ?? "external.goal",
            goalTitle: try container.decodeIfPresent(String.self, forKey: .goalTitle) ?? "External requested goal",
            sessionID: try container.decodeIfPresent(String.self, forKey: .sessionID)
          )
        )
      }
    case .resumeRun:
      if let payload = try container.decodeIfPresent(PraxisRuntimeInterfaceResumeRunRequestPayload.self, forKey: .resumeRun) {
        self = .resumeRun(payload)
      } else {
        self = .resumeRun(
          .init(
            payloadSummary: try container.decodeIfPresent(String.self, forKey: .payloadSummary) ?? "",
            runID: try container.decodeIfPresent(String.self, forKey: .runID) ?? ""
          )
        )
      }
    case .inspectTap:
      self = .inspectTap
    case .inspectCmp:
      self = .inspectCmp
    case .inspectMp:
      self = .inspectMp
    case .buildCapabilityCatalog:
      self = .buildCapabilityCatalog
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(kind, forKey: .kind)

    switch self {
    case .runGoal(let payload):
      try container.encode(payload, forKey: .runGoal)
    case .resumeRun(let payload):
      try container.encode(payload, forKey: .resumeRun)
    case .inspectArchitecture, .inspectTap, .inspectCmp, .inspectMp, .buildCapabilityCatalog:
      break
    }
  }
}

public enum PraxisRuntimeInterfaceSnapshotKind: String, Sendable, Equatable, Codable {
  case architecture
  case run
  case inspection
  case catalog
}

public struct PraxisRuntimeInterfaceSnapshot: Sendable, Equatable, Codable {
  public let kind: PraxisRuntimeInterfaceSnapshotKind
  public let title: String
  public let summary: String
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?
  public let phase: PraxisRunPhase?
  public let tickCount: Int?
  public let lifecycleDisposition: PraxisRunLifecycleDisposition?
  public let checkpointReference: String?
  public let pendingIntentID: String?
  public let recoveredEventCount: Int?

  public init(
    kind: PraxisRuntimeInterfaceSnapshotKind,
    title: String,
    summary: String,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil,
    phase: PraxisRunPhase? = nil,
    tickCount: Int? = nil,
    lifecycleDisposition: PraxisRunLifecycleDisposition? = nil,
    checkpointReference: String? = nil,
    pendingIntentID: String? = nil,
    recoveredEventCount: Int? = nil
  ) {
    self.kind = kind
    self.title = title
    self.summary = summary
    self.runID = runID
    self.sessionID = sessionID
    self.phase = phase
    self.tickCount = tickCount
    self.lifecycleDisposition = lifecycleDisposition
    self.checkpointReference = checkpointReference
    self.pendingIntentID = pendingIntentID
    self.recoveredEventCount = recoveredEventCount
  }
}

public struct PraxisRuntimeInterfaceEvent: Sendable, Equatable, Codable {
  public let name: String
  public let detail: String
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?
  public let intentID: String?

  public init(
    name: String,
    detail: String,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil,
    intentID: String? = nil
  ) {
    self.name = name
    self.detail = detail
    self.runID = runID
    self.sessionID = sessionID
    self.intentID = intentID
  }
}

public struct PraxisRuntimeInterfaceErrorEnvelope: Sendable, Equatable, Codable {
  public let code: PraxisRuntimeInterfaceErrorCode
  public let message: String
  public let retryable: Bool
  public let missingField: String?
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?

  public init(
    code: PraxisRuntimeInterfaceErrorCode,
    message: String,
    retryable: Bool = false,
    missingField: String? = nil,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil
  ) {
    self.code = code
    self.message = message
    self.retryable = retryable
    self.missingField = missingField
    self.runID = runID
    self.sessionID = sessionID
  }
}

public struct PraxisRuntimeInterfaceResponse: Sendable, Equatable, Codable {
  public let status: PraxisRuntimeInterfaceResponseStatus
  public let snapshot: PraxisRuntimeInterfaceSnapshot?
  public let events: [PraxisRuntimeInterfaceEvent]
  public let error: PraxisRuntimeInterfaceErrorEnvelope?

  public init(
    status: PraxisRuntimeInterfaceResponseStatus,
    snapshot: PraxisRuntimeInterfaceSnapshot? = nil,
    events: [PraxisRuntimeInterfaceEvent] = [],
    error: PraxisRuntimeInterfaceErrorEnvelope? = nil
  ) {
    self.status = status
    self.snapshot = snapshot
    self.events = events
    self.error = error
  }

  public static func success(
    snapshot: PraxisRuntimeInterfaceSnapshot,
    events: [PraxisRuntimeInterfaceEvent] = []
  ) -> PraxisRuntimeInterfaceResponse {
    .init(
      status: .success,
      snapshot: snapshot,
      events: events,
      error: nil
    )
  }

  public static func failure(
    error: PraxisRuntimeInterfaceErrorEnvelope,
    events: [PraxisRuntimeInterfaceEvent] = []
  ) -> PraxisRuntimeInterfaceResponse {
    .init(
      status: .failure,
      snapshot: nil,
      events: events,
      error: error
    )
  }

  public var isSuccess: Bool {
    status == .success
  }
}
