import PraxisState

public enum PraxisTransitionPhase: String, Sendable, Codable {
  case idle
  case planning
  case executing
  case paused
  case completed
  case failed
}

public struct PraxisTransitionRule: Sendable, Equatable, Codable {
  public let from: PraxisTransitionPhase
  public let to: PraxisTransitionPhase
  public let summary: String

  public init(from: PraxisTransitionPhase, to: PraxisTransitionPhase, summary: String) {
    self.from = from
    self.to = to
    self.summary = summary
  }
}

public struct PraxisTransitionTable: Sendable, Equatable, Codable {
  public let rules: [PraxisTransitionRule]

  public init(rules: [PraxisTransitionRule]) {
    self.rules = rules
  }
}

public struct PraxisNextActionDecision: Sendable, Equatable, Codable {
  public let actionName: String
  public let reason: String

  public init(actionName: String, reason: String) {
    self.actionName = actionName
    self.reason = reason
  }
}
