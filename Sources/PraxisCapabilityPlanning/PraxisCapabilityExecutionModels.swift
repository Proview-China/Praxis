import PraxisCapabilityContracts

public enum PraxisCapabilityExecutionState: String, Sendable, Codable {
  case queued
  case running
  case completed
  case cancelled
  case failed
}

public struct PraxisCapabilityBackpressureState: Sendable, Equatable, Codable {
  public let queueDepth: Int
  public let inflightCount: Int
  public let isDraining: Bool

  public init(queueDepth: Int, inflightCount: Int, isDraining: Bool) {
    self.queueDepth = queueDepth
    self.inflightCount = inflightCount
    self.isDraining = isDraining
  }
}

public struct PraxisPreparedCapabilityCall: Sendable, Equatable, Codable {
  public let preparedID: String
  public let capabilityID: PraxisCapabilityID
  public let bindingKey: String
  public let inputSummary: String
  public let metadata: [String: String]

  public init(
    preparedID: String,
    capabilityID: PraxisCapabilityID,
    bindingKey: String,
    inputSummary: String,
    metadata: [String: String] = [:]
  ) {
    self.preparedID = preparedID
    self.capabilityID = capabilityID
    self.bindingKey = bindingKey
    self.inputSummary = inputSummary
    self.metadata = metadata
  }
}

public struct PraxisCapabilityExecutionHandle: Sendable, Equatable, Codable {
  public let executionID: String
  public let preparedID: String
  public let state: PraxisCapabilityExecutionState
  public let startedAt: String

  public init(
    executionID: String,
    preparedID: String,
    state: PraxisCapabilityExecutionState,
    startedAt: String
  ) {
    self.executionID = executionID
    self.preparedID = preparedID
    self.state = state
    self.startedAt = startedAt
  }
}

public struct PraxisCapabilityQueueEntry: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let prioritySummary: String
  public let enqueuedAt: String

  public init(capabilityID: PraxisCapabilityID, prioritySummary: String, enqueuedAt: String) {
    self.capabilityID = capabilityID
    self.prioritySummary = prioritySummary
    self.enqueuedAt = enqueuedAt
  }
}

public struct PraxisCapabilityPortIntent: Sendable, Equatable, Codable {
  public let intentID: String
  public let capabilityID: PraxisCapabilityID
  public let correlationID: String?
  public let payloadSummary: String
  public let createdAt: String

  public init(
    intentID: String,
    capabilityID: PraxisCapabilityID,
    correlationID: String? = nil,
    payloadSummary: String,
    createdAt: String
  ) {
    self.intentID = intentID
    self.capabilityID = capabilityID
    self.correlationID = correlationID
    self.payloadSummary = payloadSummary
    self.createdAt = createdAt
  }
}

public struct PraxisCapabilityPortResult: Sendable, Equatable, Codable {
  public let intentID: String
  public let executionID: String?
  public let state: PraxisCapabilityExecutionState
  public let summary: String

  public init(
    intentID: String,
    executionID: String? = nil,
    state: PraxisCapabilityExecutionState,
    summary: String
  ) {
    self.intentID = intentID
    self.executionID = executionID
    self.state = state
    self.summary = summary
  }
}
