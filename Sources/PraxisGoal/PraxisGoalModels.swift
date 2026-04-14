import PraxisCoreTypes

/// Stable identifier for a goal flowing through normalization and compilation.
public struct PraxisGoalID: PraxisIdentifier {
  public let rawValue: String

  /// Creates a stable goal identifier.
  ///
  /// - Parameter rawValue: The string form persisted across boundaries.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

/// Describes where a goal request originated from.
public enum PraxisGoalSourceKind: String, Sendable, Codable {
  case user
  case system
  case resume
  case followUp = "follow_up"
}

/// A single success or failure checkpoint attached to a goal.
public struct PraxisGoalCriterion: Sendable, Equatable, Codable {
  public let id: String
  public let description: String
  public let required: Bool

  /// Creates a single success or failure criterion for a goal.
  ///
  /// - Parameters:
  ///   - id: Stable criterion identifier.
  ///   - description: Human-readable criterion text.
  ///   - required: Whether the criterion must be satisfied for the goal to count as complete.
  public init(
    id: String,
    description: String,
    required: Bool = true
  ) {
    self.id = id
    self.description = description
    self.required = required
  }
}

/// A structured constraint that downstream planners and executors must respect.
public struct PraxisGoalConstraint: Sendable, Equatable, Codable {
  public let key: String
  public let value: PraxisValue
  public let description: String?

  /// Creates a structured goal constraint.
  ///
  /// - Parameters:
  ///   - key: Constraint name used by planners or executors.
  ///   - value: Constraint payload in plain-data form.
  ///   - description: Optional human-readable explanation for prompts and debugging.
  public init(
    key: String,
    value: PraxisValue,
    description: String? = nil
  ) {
    self.key = key
    self.value = value
    self.description = description
  }
}

public extension PraxisGoalConstraint {
  /// Human-readable summary used in prompts and debugging output.
  var summary: String {
    let suffix = description.map { " (\($0))" } ?? ""
    return "\(key)=\(value.canonicalDescription)\(suffix)"
  }
}

/// Raw goal input captured from a user or system surface.
public struct PraxisGoalSource: Sendable, Equatable, Codable {
  public let id: PraxisGoalID
  public let kind: PraxisGoalSourceKind
  public let sessionID: String?
  public let runID: String?
  public let userInput: String
  public let inputRefs: [String]
  public let constraints: [PraxisGoalConstraint]
  public let metadata: [String: PraxisValue]?
  public let traceTags: [PraxisTraceTag]

  /// Creates a raw goal source captured from a user or system entry surface.
  ///
  /// - Parameters:
  ///   - id: Stable identifier for the goal request.
  ///   - kind: Origin of the request.
  ///   - sessionID: Optional session scope containing the goal.
  ///   - runID: Optional run scope already associated with the goal.
  ///   - userInput: Primary natural-language input.
  ///   - inputRefs: Attached references or handles that contextualize the request.
  ///   - constraints: Structured constraints already known at source time.
  ///   - metadata: Extra plain-data metadata preserved across boundaries.
  ///   - traceTags: Trace tags used for observability and correlation.
  public init(
    id: PraxisGoalID,
    kind: PraxisGoalSourceKind,
    sessionID: String? = nil,
    runID: String? = nil,
    userInput: String,
    inputRefs: [String] = [],
    constraints: [PraxisGoalConstraint] = [],
    metadata: [String: PraxisValue]? = nil,
    traceTags: [PraxisTraceTag] = [],
  ) {
    self.id = id
    self.kind = kind
    self.sessionID = sessionID
    self.runID = runID
    self.userInput = userInput
    self.inputRefs = inputRefs
    self.constraints = constraints
    self.metadata = metadata
    self.traceTags = traceTags
  }

  /// Creates a source using the backward-compatible `rawInput` naming.
  ///
  /// - Parameters:
  ///   - id: Stable identifier for the goal request.
  ///   - kind: Origin of the request.
  ///   - rawInput: Primary natural-language input.
  ///   - traceTags: Trace tags used for observability and correlation.
  public init(
    id: PraxisGoalID,
    kind: PraxisGoalSourceKind,
    rawInput: String,
    traceTags: [PraxisTraceTag] = []
  ) {
    self.init(
      id: id,
      kind: kind,
      userInput: rawInput,
      traceTags: traceTags
    )
  }
}

public extension PraxisGoalSource {
  /// Backward-compatible alias for older call sites that still use `rawInput`.
  var rawInput: String {
    userInput
  }
}

/// Goal data after input cleanup and defaulting, ready for compilation.
public struct PraxisNormalizedGoal: Sendable, Equatable, Codable {
  public let id: PraxisGoalID
  public let taskStatement: String
  public let title: String
  public let summary: String
  public let successCriteria: [PraxisGoalCriterion]
  public let failureCriteria: [PraxisGoalCriterion]
  public let constraints: [PraxisGoalConstraint]
  public let inputRefs: [String]
  public let metadata: [String: PraxisValue]?

  /// Creates a normalized goal ready for validation and compilation.
  ///
  /// - Parameters:
  ///   - id: Stable goal identifier.
  ///   - taskStatement: Canonical task statement after normalization.
  ///   - title: Optional short title. Defaults to `taskStatement`.
  ///   - summary: Optional summary. Defaults to `taskStatement`.
  ///   - successCriteria: Criteria that define successful completion.
  ///   - failureCriteria: Criteria that define blocking or failed execution.
  ///   - constraints: Structured constraints preserved for downstream use.
  ///   - inputRefs: References carried forward from the source layer.
  ///   - metadata: Extra plain-data metadata carried across boundaries.
  public init(
    id: PraxisGoalID,
    taskStatement: String,
    title: String? = nil,
    summary: String? = nil,
    successCriteria: [PraxisGoalCriterion] = [],
    failureCriteria: [PraxisGoalCriterion] = [],
    constraints: [PraxisGoalConstraint] = [],
    inputRefs: [String] = [],
    metadata: [String: PraxisValue]? = nil
  ) {
    let resolvedTitle = title ?? taskStatement
    let resolvedSummary = summary ?? taskStatement
    self.id = id
    self.taskStatement = taskStatement
    self.title = resolvedTitle
    self.summary = resolvedSummary
    self.successCriteria = successCriteria
    self.failureCriteria = failureCriteria
    self.constraints = constraints
    self.inputRefs = inputRefs
    self.metadata = metadata
  }

  /// Creates a normalized goal using the older `title + summary` construction style.
  ///
  /// - Parameters:
  ///   - id: Stable goal identifier.
  ///   - title: Display title for the goal.
  ///   - summary: Canonical summary also used as the task statement.
  ///   - constraints: Structured constraints preserved for downstream use.
  public init(
    id: PraxisGoalID,
    title: String,
    summary: String,
    constraints: [PraxisGoalConstraint] = [],
  ) {
    self.init(
      id: id,
      taskStatement: summary,
      title: title,
      summary: summary,
      constraints: constraints
    )
  }
}

/// Prompt-ready goal package enriched with cache metadata.
public struct PraxisCompiledGoal: Sendable, Equatable, Codable {
  public let normalizedGoal: PraxisNormalizedGoal
  public let instructionText: String
  public let cacheKey: String
  public let metadata: [String: PraxisValue]?

  /// Creates a compiled goal that can be handed to runtime execution layers.
  ///
  /// - Parameters:
  ///   - normalizedGoal: The normalized goal used as the compilation source of truth.
  ///   - instructionText: Rendered instruction text for downstream execution.
  ///   - cacheKey: Deterministic cache key for reuse or snapshot comparison.
  ///   - metadata: Additional plain-data metadata merged during compilation.
  public init(
    normalizedGoal: PraxisNormalizedGoal,
    instructionText: String,
    cacheKey: String,
    metadata: [String: PraxisValue]? = nil
  ) {
    self.normalizedGoal = normalizedGoal
    self.instructionText = instructionText
    self.cacheKey = cacheKey
    self.metadata = metadata
  }

  /// Creates a compiled goal using the backward-compatible `intentSummary` naming.
  ///
  /// - Parameters:
  ///   - normalizedGoal: The normalized goal used as the source of truth.
  ///   - intentSummary: Rendered instruction text for downstream execution.
  public init(
    normalizedGoal: PraxisNormalizedGoal,
    intentSummary: String
  ) {
    self.init(
      normalizedGoal: normalizedGoal,
      instructionText: intentSummary,
      cacheKey: "manual.\(normalizedGoal.id.rawValue)",
      metadata: normalizedGoal.metadata
    )
  }
}

public extension PraxisCompiledGoal {
  /// Convenience accessor mirroring the normalized goal identifier.
  var goalID: PraxisGoalID {
    normalizedGoal.id
  }

  /// Backward-compatible alias for the compiled instruction text.
  var intentSummary: String {
    instructionText
  }

  /// Convenience accessor mirroring normalized success criteria.
  var successCriteria: [PraxisGoalCriterion] {
    normalizedGoal.successCriteria
  }

  /// Convenience accessor mirroring normalized failure criteria.
  var failureCriteria: [PraxisGoalCriterion] {
    normalizedGoal.failureCriteria
  }

  /// Convenience accessor mirroring normalized constraints.
  var constraints: [PraxisGoalConstraint] {
    normalizedGoal.constraints
  }

  /// Convenience accessor mirroring normalized input refs.
  var inputRefs: [String] {
    normalizedGoal.inputRefs
  }
}

/// Validation issue produced while checking goal input or normalized output.
public struct PraxisGoalValidationIssue: Sendable, Equatable, Codable {
  public let message: String

  /// Creates a validation issue.
  ///
  /// - Parameter message: Human-readable validation message.
  public init(message: String) {
    self.message = message
  }
}
