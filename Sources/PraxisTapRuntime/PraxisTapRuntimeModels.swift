import PraxisCheckpoint
import PraxisSession
import PraxisTapGovernance
import PraxisTapProvision
import PraxisTapTypes

public struct PraxisTapControlPlaneState: Sendable, Equatable, Codable {
  public let sessionID: PraxisSessionID
  public let governance: PraxisTapGovernanceObject
  public let humanGateState: PraxisHumanGateState

  public init(
    sessionID: PraxisSessionID,
    governance: PraxisTapGovernanceObject,
    humanGateState: PraxisHumanGateState,
  ) {
    self.sessionID = sessionID
    self.governance = governance
    self.humanGateState = humanGateState
  }
}

public struct PraxisReplayPolicy: Sendable, Equatable, Codable {
  public let allowsResume: Bool
  public let allowsHumanOverride: Bool
  public let nextAction: PraxisReplayNextAction
  public let summary: String

  public init(
    allowsResume: Bool,
    allowsHumanOverride: Bool,
    nextAction: PraxisReplayNextAction = .none,
    summary: String = ""
  ) {
    self.allowsResume = allowsResume
    self.allowsHumanOverride = allowsHumanOverride
    self.nextAction = nextAction
    self.summary = summary
  }
}

public struct PraxisTapRuntimeSnapshot: Sendable, Equatable, Codable {
  public let controlPlaneState: PraxisTapControlPlaneState
  public let checkpointPointer: PraxisCheckpointPointer?
  public let pendingReplays: [PraxisPendingReplay]
  public let humanGateEvents: [PraxisHumanGateEvent]

  public init(
    controlPlaneState: PraxisTapControlPlaneState,
    checkpointPointer: PraxisCheckpointPointer?,
    pendingReplays: [PraxisPendingReplay] = [],
    humanGateEvents: [PraxisHumanGateEvent] = []
  ) {
    self.controlPlaneState = controlPlaneState
    self.checkpointPointer = checkpointPointer
    self.pendingReplays = pendingReplays
    self.humanGateEvents = humanGateEvents
  }
}
