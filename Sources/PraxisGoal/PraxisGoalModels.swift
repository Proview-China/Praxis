import PraxisCoreTypes

public struct PraxisGoalID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public enum PraxisGoalSourceKind: String, Sendable, Codable {
  case user
  case system
  case resume
  case followUp
}

public struct PraxisGoalConstraint: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}

public struct PraxisGoalSource: Sendable, Equatable, Codable {
  public let id: PraxisGoalID
  public let kind: PraxisGoalSourceKind
  public let rawInput: String
  public let traceTags: [PraxisTraceTag]

  public init(
    id: PraxisGoalID,
    kind: PraxisGoalSourceKind,
    rawInput: String,
    traceTags: [PraxisTraceTag] = [],
  ) {
    self.id = id
    self.kind = kind
    self.rawInput = rawInput
    self.traceTags = traceTags
  }
}

public struct PraxisNormalizedGoal: Sendable, Equatable, Codable {
  public let id: PraxisGoalID
  public let title: String
  public let summary: String
  public let constraints: [PraxisGoalConstraint]

  public init(
    id: PraxisGoalID,
    title: String,
    summary: String,
    constraints: [PraxisGoalConstraint] = [],
  ) {
    self.id = id
    self.title = title
    self.summary = summary
    self.constraints = constraints
  }
}

public struct PraxisCompiledGoal: Sendable, Equatable, Codable {
  public let normalizedGoal: PraxisNormalizedGoal
  public let intentSummary: String

  public init(
    normalizedGoal: PraxisNormalizedGoal,
    intentSummary: String,
  ) {
    self.normalizedGoal = normalizedGoal
    self.intentSummary = intentSummary
  }
}

public struct PraxisGoalValidationIssue: Sendable, Equatable, Codable {
  public let message: String

  public init(message: String) {
    self.message = message
  }
}
