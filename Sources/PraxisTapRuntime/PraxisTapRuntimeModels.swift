import PraxisCheckpoint
import PraxisSession
import PraxisTapGovernance
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

  public init(allowsResume: Bool, allowsHumanOverride: Bool) {
    self.allowsResume = allowsResume
    self.allowsHumanOverride = allowsHumanOverride
  }
}

public struct PraxisTapRuntimeSnapshot: Sendable, Equatable, Codable {
  public let controlPlaneState: PraxisTapControlPlaneState
  public let checkpointPointer: PraxisCheckpointPointer?

  public init(controlPlaneState: PraxisTapControlPlaneState, checkpointPointer: PraxisCheckpointPointer?) {
    self.controlPlaneState = controlPlaneState
    self.checkpointPointer = checkpointPointer
  }
}
