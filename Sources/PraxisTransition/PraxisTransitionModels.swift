import PraxisCoreTypes
import PraxisState

/// Broad routing class for runtime transition paths.
public enum PraxisTransitionPath: String, Sendable, Equatable, Codable {
  case hot
  case rare
}

/// High-level action chosen after evaluating a transition.
public enum PraxisStepActionKind: String, Sendable, Equatable, Codable {
  case none
  case internalStep = "internal_step"
  case modelInference = "model_inference"
  case capabilityCall = "capability_call"
  case cmpAction = "cmp_action"
  case wait
  case pause
  case complete
  case fail
  case cancel
  case checkpoint
}

/// Intent category used when the runtime needs to enqueue follow-up work.
public enum PraxisTransitionIntentKind: String, Sendable, Equatable, Codable {
  case internalStep = "internal_step"
  case modelInference = "model_inference"
  case capabilityCall = "capability_call"
  case cmpAction = "cmp_action"
}

/// Priority assigned to a transition-generated intent.
public enum PraxisTransitionPriority: String, Sendable, Equatable, Codable {
  case low
  case normal
  case high
  case critical
}

/// Intent generated from a transition decision for downstream execution.
public struct PraxisTransitionIntent: Sendable, Equatable, Codable {
  public let intentID: String
  public let sessionID: String
  public let runID: String
  public let kind: PraxisTransitionIntentKind
  public let createdAt: String
  public let priority: PraxisTransitionPriority
  public let correlationID: String?
  public let instruction: String?
  public let capabilityKey: String?
  public let capabilityInput: PraxisStateRecord?
  public let cmpAction: String?
  public let cmpInput: PraxisStateRecord?

  /// Creates a transition intent.
  ///
  /// - Parameters:
  ///   - intentID: Stable intent identifier.
  ///   - sessionID: Session containing the intent.
  ///   - runID: Run containing the intent.
  ///   - kind: Kind of work the intent represents.
  ///   - createdAt: Intent creation timestamp string.
  ///   - priority: Scheduling priority for the intent.
  ///   - correlationID: Optional correlation identifier shared across related work.
  ///   - instruction: Optional natural-language instruction for model or internal work.
  ///   - capabilityKey: Optional capability identifier for capability calls.
  ///   - capabilityInput: Optional plain-data capability input payload.
  ///   - cmpAction: Optional CMP action identifier.
  ///   - cmpInput: Optional CMP input payload.
  public init(
    intentID: String,
    sessionID: String,
    runID: String,
    kind: PraxisTransitionIntentKind,
    createdAt: String,
    priority: PraxisTransitionPriority,
    correlationID: String? = nil,
    instruction: String? = nil,
    capabilityKey: String? = nil,
    capabilityInput: PraxisStateRecord? = nil,
    cmpAction: String? = nil,
    cmpInput: PraxisStateRecord? = nil
  ) {
    self.intentID = intentID
    self.sessionID = sessionID
    self.runID = runID
    self.kind = kind
    self.createdAt = createdAt
    self.priority = priority
    self.correlationID = correlationID
    self.instruction = instruction
    self.capabilityKey = capabilityKey
    self.capabilityInput = capabilityInput
    self.cmpAction = cmpAction
    self.cmpInput = cmpInput
  }
}

/// Follow-up action recommended by a transition decision.
public struct PraxisNextActionDecision: Sendable, Equatable, Codable {
  public let kind: PraxisStepActionKind
  public let reason: String
  public let intent: PraxisTransitionIntent?
  public let metadata: [String: PraxisValue]

  /// Creates a next-action decision.
  ///
  /// - Parameters:
  ///   - kind: Kind of follow-up action to perform.
  ///   - reason: Human-readable explanation for the chosen action.
  ///   - intent: Optional queued intent backing the action.
  ///   - metadata: Extra plain-data metadata attached to the action.
  public init(
    kind: PraxisStepActionKind,
    reason: String,
    intent: PraxisTransitionIntent? = nil,
    metadata: [String: PraxisValue] = [:]
  ) {
    self.kind = kind
    self.reason = reason
    self.intent = intent
    self.metadata = metadata
  }
}

/// Result of evaluating a runtime transition.
public struct PraxisTransitionDecision: Sendable, Equatable, Codable {
  public let fromStatus: PraxisAgentStatus
  public let toStatus: PraxisAgentStatus
  public let nextPhase: PraxisAgentPhase?
  public let reason: String
  public let stateDelta: PraxisStateDelta?
  public let nextAction: PraxisNextActionDecision?
  public let eventID: String?

  /// Creates a transition decision.
  ///
  /// - Parameters:
  ///   - fromStatus: Status before the event is applied.
  ///   - toStatus: Status after the transition completes.
  ///   - nextPhase: Optional next runtime phase.
  ///   - reason: Human-readable explanation of the transition.
  ///   - stateDelta: Optional snapshot patch produced by the transition.
  ///   - nextAction: Optional follow-up action to execute after the transition.
  ///   - eventID: Optional source event identifier.
  public init(
    fromStatus: PraxisAgentStatus,
    toStatus: PraxisAgentStatus,
    nextPhase: PraxisAgentPhase? = nil,
    reason: String,
    stateDelta: PraxisStateDelta? = nil,
    nextAction: PraxisNextActionDecision? = nil,
    eventID: String? = nil
  ) {
    self.fromStatus = fromStatus
    self.toStatus = toStatus
    self.nextPhase = nextPhase
    self.reason = reason
    self.stateDelta = stateDelta
    self.nextAction = nextAction
    self.eventID = eventID
  }
}

/// Declarative transition rule used for documentation and guard tests.
public struct PraxisTransitionRule: Sendable, Equatable, Codable {
  public let name: String
  public let path: PraxisTransitionPath
  public let eventType: PraxisKernelEventType
  public let fromStatuses: [PraxisAgentStatus]
  public let toStatus: PraxisAgentStatus
  public let nextPhase: PraxisAgentPhase?
  public let summary: String

  /// Creates a declarative transition rule.
  ///
  /// - Parameters:
  ///   - name: Stable rule identifier.
  ///   - path: Routing class for the rule.
  ///   - eventType: Event type handled by the rule.
  ///   - fromStatuses: Allowed source statuses.
  ///   - toStatus: Resulting status when the rule matches.
  ///   - nextPhase: Optional next phase associated with the rule.
  ///   - summary: Human-readable explanation of the rule.
  public init(
    name: String,
    path: PraxisTransitionPath,
    eventType: PraxisKernelEventType,
    fromStatuses: [PraxisAgentStatus],
    toStatus: PraxisAgentStatus,
    nextPhase: PraxisAgentPhase?,
    summary: String
  ) {
    self.name = name
    self.path = path
    self.eventType = eventType
    self.fromStatuses = fromStatuses
    self.toStatus = toStatus
    self.nextPhase = nextPhase
    self.summary = summary
  }
}

/// Collection of transition rules used by evaluators and architecture tests.
public struct PraxisTransitionTable: Sendable, Equatable, Codable {
  public let rules: [PraxisTransitionRule]

  /// Creates a transition table.
  ///
  /// - Parameter rules: Declarative transition rules available to the evaluator.
  public init(rules: [PraxisTransitionRule]) {
    self.rules = rules
  }
}

/// Error thrown when an event is illegal for the current runtime status.
public struct PraxisInvalidTransitionError: Error, Sendable, Equatable {
  public let fromStatus: PraxisAgentStatus
  public let eventType: PraxisKernelEventType
  public let message: String

  /// Creates an invalid-transition error.
  ///
  /// - Parameters:
  ///   - fromStatus: Status that rejected the incoming event.
  ///   - eventType: Event type that was rejected.
  ///   - message: Human-readable explanation of the failure.
  public init(
    fromStatus: PraxisAgentStatus,
    eventType: PraxisKernelEventType,
    message: String
  ) {
    self.fromStatus = fromStatus
    self.eventType = eventType
    self.message = message
  }
}
