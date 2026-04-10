import PraxisCoreTypes
import PraxisState
import PraxisTransition

public struct PraxisRunID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public enum PraxisRunPhase: String, Sendable, Codable {
  case created
  case queued
  case running
  case paused
  case completed
  case failed
}

public struct PraxisRunAggregate: Sendable, Equatable, Codable {
  public let id: PraxisRunID
  public let phase: PraxisRunPhase
  public let latestState: PraxisStateSnapshot

  public init(id: PraxisRunID, phase: PraxisRunPhase, latestState: PraxisStateSnapshot) {
    self.id = id
    self.phase = phase
    self.latestState = latestState
  }
}

public struct PraxisRunTick: Sendable, Equatable, Codable {
  public let sequence: Int
  public let decision: PraxisNextActionDecision?

  public init(sequence: Int, decision: PraxisNextActionDecision? = nil) {
    self.sequence = sequence
    self.decision = decision
  }
}

public struct PraxisRunFailure: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}
