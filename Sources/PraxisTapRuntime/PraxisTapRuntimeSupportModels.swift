import PraxisTapTypes

public enum PraxisActivationAttemptStatus: String, Sendable, Codable {
  case pending
  case running
  case failed
  case completed
}

public struct PraxisActivationAttemptRecord: Sendable, Equatable, Codable {
  public let attemptID: String
  public let capabilityKey: String
  public let status: PraxisActivationAttemptStatus
  public let createdAt: String

  public init(
    attemptID: String,
    capabilityKey: String,
    status: PraxisActivationAttemptStatus,
    createdAt: String
  ) {
    self.attemptID = attemptID
    self.capabilityKey = capabilityKey
    self.status = status
    self.createdAt = createdAt
  }
}

public struct PraxisActivationFailure: Sendable, Equatable, Codable {
  public let code: String
  public let message: String

  public init(code: String, message: String) {
    self.code = code
    self.message = message
  }
}

public struct PraxisActivationReceipt: Sendable, Equatable, Codable {
  public let capabilityKey: String
  public let bindingKey: String
  public let activatedAt: String

  public init(capabilityKey: String, bindingKey: String, activatedAt: String) {
    self.capabilityKey = capabilityKey
    self.bindingKey = bindingKey
    self.activatedAt = activatedAt
  }
}

public struct PraxisHumanGateEvent: Sendable, Equatable, Codable {
  public let eventID: String
  public let state: PraxisHumanGateState
  public let summary: String
  public let createdAt: String

  public init(eventID: String, state: PraxisHumanGateState, summary: String, createdAt: String) {
    self.eventID = eventID
    self.state = state
    self.summary = summary
    self.createdAt = createdAt
  }
}

public struct PraxisPendingReplay: Sendable, Equatable, Codable {
  public let replayID: String
  public let summary: String
  public let recommendedAction: String

  public init(replayID: String, summary: String, recommendedAction: String) {
    self.replayID = replayID
    self.summary = summary
    self.recommendedAction = recommendedAction
  }
}
