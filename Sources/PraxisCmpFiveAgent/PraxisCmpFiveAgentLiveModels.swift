import PraxisTapTypes

public enum PraxisCmpRoleLiveMode: String, Sendable, Codable {
  case rulesOnly
  case llmAssisted
  case llmRequired
}

public enum PraxisCmpRoleLiveStatus: String, Sendable, Codable {
  case rulesOnly
  case succeeded
  case fallback
  case failed
}

public struct PraxisCmpRoleLiveRequest: Sendable, Equatable, Codable {
  public let requestID: String
  public let role: PraxisFiveAgentRole
  public let stage: String
  public let mode: PraxisCmpRoleLiveMode
  public let promptSummary: String

  public init(
    requestID: String,
    role: PraxisFiveAgentRole,
    stage: String,
    mode: PraxisCmpRoleLiveMode,
    promptSummary: String
  ) {
    self.requestID = requestID
    self.role = role
    self.stage = stage
    self.mode = mode
    self.promptSummary = promptSummary
  }
}

public struct PraxisCmpRoleLiveTrace: Sendable, Equatable, Codable {
  public let attemptID: String
  public let role: PraxisFiveAgentRole
  public let mode: PraxisCmpRoleLiveMode
  public let status: PraxisCmpRoleLiveStatus
  public let provider: String?
  public let model: String?
  public let createdAt: String

  public init(
    attemptID: String,
    role: PraxisFiveAgentRole,
    mode: PraxisCmpRoleLiveMode,
    status: PraxisCmpRoleLiveStatus,
    provider: String? = nil,
    model: String? = nil,
    createdAt: String
  ) {
    self.attemptID = attemptID
    self.role = role
    self.mode = mode
    self.status = status
    self.provider = provider
    self.model = model
    self.createdAt = createdAt
  }
}

public struct PraxisCmpFiveAgentTapBridgePayload: Sendable, Equatable, Codable {
  public let role: PraxisFiveAgentRole
  public let capabilityKey: String
  public let reason: String
  public let humanGateState: PraxisHumanGateState?

  public init(
    role: PraxisFiveAgentRole,
    capabilityKey: String,
    reason: String,
    humanGateState: PraxisHumanGateState? = nil
  ) {
    self.role = role
    self.capabilityKey = capabilityKey
    self.reason = reason
    self.humanGateState = humanGateState
  }
}
