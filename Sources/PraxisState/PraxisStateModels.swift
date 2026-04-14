import PraxisCoreTypes

/// Plain-data record used by runtime state sections.
public typealias PraxisStateRecord = [String: PraxisValue]

/// Top-level keys that are intentionally forbidden in state records.
public let PraxisForbiddenStateTopLevelKeys: Set<String> = [
  "history",
  "events",
  "journal",
]

/// High-level lifecycle status for an agent run.
public enum PraxisAgentStatus: String, Sendable, Codable, CaseIterable {
  case created
  case idle
  case deciding
  case acting
  case waiting
  case paused
  case completed
  case failed
  case cancelled
}

/// Runtime phase used to interpret the current step in the kernel loop.
public enum PraxisAgentPhase: String, Sendable, Codable, CaseIterable {
  case decision
  case execution
  case commit
  case recovery
}

/// Control-plane state for the current agent run.
public struct PraxisAgentControlState: Sendable, Equatable, Codable {
  public let status: PraxisAgentStatus
  public let phase: PraxisAgentPhase
  public let retryCount: Int
  public let pendingIntentID: String?
  public let pendingCheckpointReason: String?

  /// Creates the control-plane state for a run.
  ///
  /// - Parameters:
  ///   - status: Current lifecycle status.
  ///   - phase: Current runtime phase.
  ///   - retryCount: Number of retries already consumed.
  ///   - pendingIntentID: Identifier of the currently queued or in-flight intent.
  ///   - pendingCheckpointReason: Optional reason explaining why a checkpoint is pending.
  public init(
    status: PraxisAgentStatus,
    phase: PraxisAgentPhase,
    retryCount: Int,
    pendingIntentID: String? = nil,
    pendingCheckpointReason: String? = nil
  ) {
    self.status = status
    self.phase = phase
    self.retryCount = retryCount
    self.pendingIntentID = pendingIntentID
    self.pendingCheckpointReason = pendingCheckpointReason
  }
}

/// Observed execution results and artifact references for a run.
public struct PraxisAgentObservedState: Sendable, Equatable, Codable {
  public let lastObservationRef: String?
  public let lastResultID: String?
  public let lastResultStatus: String?
  public let artifactRefs: [String]

  /// Creates the observed state section.
  ///
  /// - Parameters:
  ///   - lastObservationRef: Reference to the latest observation artifact.
  ///   - lastResultID: Identifier of the latest result.
  ///   - lastResultStatus: Status string associated with the latest result.
  ///   - artifactRefs: Collected artifact references visible to the runtime.
  public init(
    lastObservationRef: String? = nil,
    lastResultID: String? = nil,
    lastResultStatus: String? = nil,
    artifactRefs: [String] = []
  ) {
    self.lastObservationRef = lastObservationRef
    self.lastResultID = lastResultID
    self.lastResultStatus = lastResultStatus
    self.artifactRefs = artifactRefs
  }
}

/// Recovery-oriented state used for resume and failure handling.
public struct PraxisAgentRecoveryState: Sendable, Equatable, Codable {
  public let lastCheckpointRef: String?
  public let resumePointer: String?
  public let lastErrorCode: String?
  public let lastErrorMessage: String?

  /// Creates the recovery state section.
  ///
  /// - Parameters:
  ///   - lastCheckpointRef: Latest checkpoint reference.
  ///   - resumePointer: Event or cursor used to resume processing.
  ///   - lastErrorCode: Most recent error code captured during execution.
  ///   - lastErrorMessage: Most recent error message captured during execution.
  public init(
    lastCheckpointRef: String? = nil,
    resumePointer: String? = nil,
    lastErrorCode: String? = nil,
    lastErrorMessage: String? = nil
  ) {
    self.lastCheckpointRef = lastCheckpointRef
    self.resumePointer = resumePointer
    self.lastErrorCode = lastErrorCode
    self.lastErrorMessage = lastErrorMessage
  }
}

/// Partial update for the control-plane state section.
public struct PraxisAgentControlDelta: Sendable, Equatable, Codable {
  public let status: PraxisAgentStatus?
  public let phase: PraxisAgentPhase?
  public let retryCount: Int?
  public let pendingIntentID: String?
  public let pendingCheckpointReason: String?

  /// Creates a partial control-state patch.
  ///
  /// - Parameters:
  ///   - status: Replacement lifecycle status.
  ///   - phase: Replacement runtime phase.
  ///   - retryCount: Replacement retry count.
  ///   - pendingIntentID: Replacement pending intent identifier.
  ///   - pendingCheckpointReason: Replacement checkpoint reason.
  public init(
    status: PraxisAgentStatus? = nil,
    phase: PraxisAgentPhase? = nil,
    retryCount: Int? = nil,
    pendingIntentID: String? = nil,
    pendingCheckpointReason: String? = nil
  ) {
    self.status = status
    self.phase = phase
    self.retryCount = retryCount
    self.pendingIntentID = pendingIntentID
    self.pendingCheckpointReason = pendingCheckpointReason
  }
}

/// Partial update for the observed state section.
public struct PraxisAgentObservedDelta: Sendable, Equatable, Codable {
  public let lastObservationRef: String?
  public let lastResultID: String?
  public let lastResultStatus: String?
  public let artifactRefs: [String]?

  /// Creates a partial observed-state patch.
  ///
  /// - Parameters:
  ///   - lastObservationRef: Replacement latest observation reference.
  ///   - lastResultID: Replacement latest result identifier.
  ///   - lastResultStatus: Replacement latest result status.
  ///   - artifactRefs: Replacement full artifact reference list.
  public init(
    lastObservationRef: String? = nil,
    lastResultID: String? = nil,
    lastResultStatus: String? = nil,
    artifactRefs: [String]? = nil
  ) {
    self.lastObservationRef = lastObservationRef
    self.lastResultID = lastResultID
    self.lastResultStatus = lastResultStatus
    self.artifactRefs = artifactRefs
  }
}

/// Partial update for the recovery state section.
public struct PraxisAgentRecoveryDelta: Sendable, Equatable, Codable {
  public let lastCheckpointRef: String?
  public let resumePointer: String?
  public let lastErrorCode: String?
  public let lastErrorMessage: String?

  /// Creates a partial recovery-state patch.
  ///
  /// - Parameters:
  ///   - lastCheckpointRef: Replacement latest checkpoint reference.
  ///   - resumePointer: Replacement resume pointer.
  ///   - lastErrorCode: Replacement latest error code.
  ///   - lastErrorMessage: Replacement latest error message.
  public init(
    lastCheckpointRef: String? = nil,
    resumePointer: String? = nil,
    lastErrorCode: String? = nil,
    lastErrorMessage: String? = nil
  ) {
    self.lastCheckpointRef = lastCheckpointRef
    self.resumePointer = resumePointer
    self.lastErrorCode = lastErrorCode
    self.lastErrorMessage = lastErrorMessage
  }
}

/// Full runtime snapshot used by projection, validation, and transition logic.
public struct PraxisStateSnapshot: Sendable, Equatable, Codable {
  public let control: PraxisAgentControlState
  public let working: PraxisStateRecord
  public let observed: PraxisAgentObservedState
  public let recovery: PraxisAgentRecoveryState
  public let derived: PraxisStateRecord?

  /// Creates a full runtime snapshot.
  ///
  /// - Parameters:
  ///   - control: Control-plane state.
  ///   - working: Mutable working record for execution hints and intermediate data.
  ///   - observed: Observed execution results and artifact references.
  ///   - recovery: Recovery-oriented state for resume and failure handling.
  ///   - derived: Optional derived record rebuilt from other state when needed.
  public init(
    control: PraxisAgentControlState,
    working: PraxisStateRecord,
    observed: PraxisAgentObservedState,
    recovery: PraxisAgentRecoveryState,
    derived: PraxisStateRecord? = nil
  ) {
    self.control = control
    self.working = working
    self.observed = observed
    self.recovery = recovery
    self.derived = derived
  }
}

/// Partial snapshot patch applied by runtime events and transition decisions.
public struct PraxisStateDelta: Sendable, Equatable, Codable {
  public let control: PraxisAgentControlDelta?
  public let working: PraxisStateRecord?
  public let clearWorkingKeys: [String]
  public let observed: PraxisAgentObservedDelta?
  public let recovery: PraxisAgentRecoveryDelta?
  public let derived: PraxisStateRecord?
  public let clearDerivedKeys: [String]

  /// Creates a state delta.
  ///
  /// - Parameters:
  ///   - control: Partial control-state patch.
  ///   - working: Partial working-record patch.
  ///   - clearWorkingKeys: Top-level working keys to remove after merging.
  ///   - observed: Partial observed-state patch.
  ///   - recovery: Partial recovery-state patch.
  ///   - derived: Partial replacement patch for the derived record.
  ///   - clearDerivedKeys: Top-level derived keys to remove after merging.
  public init(
    control: PraxisAgentControlDelta? = nil,
    working: PraxisStateRecord? = nil,
    clearWorkingKeys: [String] = [],
    observed: PraxisAgentObservedDelta? = nil,
    recovery: PraxisAgentRecoveryDelta? = nil,
    derived: PraxisStateRecord? = nil,
    clearDerivedKeys: [String] = []
  ) {
    self.control = control
    self.working = working
    self.clearWorkingKeys = clearWorkingKeys
    self.observed = observed
    self.recovery = recovery
    self.derived = derived
    self.clearDerivedKeys = clearDerivedKeys
  }
}

/// Validation issue emitted while checking state snapshots or deltas.
public enum PraxisStateInvariantViolation: Sendable, Equatable, Codable {
  case missingValue(String)
  case invalidValue(String)
}

/// Event type identifiers emitted by the runtime kernel.
public enum PraxisKernelEventType: String, Sendable, Equatable, Codable {
  case runCreated = "run.created"
  case runResumed = "run.resumed"
  case runPaused = "run.paused"
  case runCompleted = "run.completed"
  case runFailed = "run.failed"
  case stateDeltaApplied = "state.delta_applied"
  case intentQueued = "intent.queued"
  case intentDispatched = "intent.dispatched"
  case capabilityResultReceived = "capability.result_received"
  case checkpointCreated = "checkpoint.created"
}

/// Event payload variants consumed by state projection and transition evaluation.
public enum PraxisKernelEventPayload: Sendable, Equatable {
  case runCreated(goalID: String)
  case runResumed(checkpointID: String?)
  case runPaused(reason: String)
  case runCompleted(resultID: String?)
  case runFailed(code: String, message: String)
  case stateDeltaApplied(
    delta: PraxisStateDelta,
    previousStatus: PraxisAgentStatus?,
    nextStatus: PraxisAgentStatus?
  )
  case intentQueued(intentID: String, kind: String, priority: String)
  case intentDispatched(intentID: String, dispatchTarget: String)
  case capabilityResultReceived(requestID: String, resultID: String, status: String)
  case checkpointCreated(checkpointID: String, tier: String)
}

public extension PraxisKernelEventPayload {
  /// Stable event type derived from the payload case.
  var type: PraxisKernelEventType {
    switch self {
    case .runCreated:
      .runCreated
    case .runResumed:
      .runResumed
    case .runPaused:
      .runPaused
    case .runCompleted:
      .runCompleted
    case .runFailed:
      .runFailed
    case .stateDeltaApplied:
      .stateDeltaApplied
    case .intentQueued:
      .intentQueued
    case .intentDispatched:
      .intentDispatched
    case .capabilityResultReceived:
      .capabilityResultReceived
    case .checkpointCreated:
      .checkpointCreated
    }
  }
}

public struct PraxisKernelEvent: Sendable, Equatable {
  public let eventID: String
  public let sessionID: String
  public let runID: String
  public let createdAt: String
  public let correlationID: String?
  public let causationID: String?
  public let payload: PraxisKernelEventPayload
  public let metadata: [String: PraxisValue]?

  /// Creates a kernel event.
  ///
  /// - Parameters:
  ///   - eventID: Stable event identifier.
  ///   - sessionID: Session containing the event.
  ///   - runID: Run containing the event.
  ///   - createdAt: Event creation timestamp string.
  ///   - correlationID: Optional correlation identifier shared across related work.
  ///   - causationID: Optional parent event identifier.
  ///   - payload: Domain payload carried by the event.
  ///   - metadata: Extra plain-data metadata attached to the event.
  public init(
    eventID: String,
    sessionID: String,
    runID: String,
    createdAt: String,
    correlationID: String? = nil,
    causationID: String? = nil,
    payload: PraxisKernelEventPayload,
    metadata: [String: PraxisValue]? = nil
  ) {
    self.eventID = eventID
    self.sessionID = sessionID
    self.runID = runID
    self.createdAt = createdAt
    self.correlationID = correlationID
    self.causationID = causationID
    self.payload = payload
    self.metadata = metadata
  }
}

public extension PraxisKernelEvent {
  /// Stable event type derived from the underlying payload.
  var type: PraxisKernelEventType {
    payload.type
  }
}
