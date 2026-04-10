import PraxisTapProvision
import PraxisTapTypes

/// Service that owns pure runtime transition rules between provision results and replay or human-gate state.
public struct PraxisActivationLifecycleService: Sendable {
  public init() {}

  /// Maps a provisioning-layer replay policy into a replay policy that runtime can consume directly.
  ///
  /// - Parameters:
  ///   - policy: The replay policy declared by the provision layer.
  /// - Returns: The runtime-side replay policy snapshot.
  public func replayPolicy(for policy: PraxisProvisionReplayPolicy) -> PraxisReplayPolicy {
    switch policy {
    case .none:
      return PraxisReplayPolicy(
        allowsResume: false,
        allowsHumanOverride: false,
        nextAction: .none,
        summary: "Replay is disabled for this provision result."
      )
    case .manual:
      return PraxisReplayPolicy(
        allowsResume: true,
        allowsHumanOverride: true,
        nextAction: .manual,
        summary: "Replay can continue only after an explicit manual resume or approved human handoff."
      )
    case .autoAfterVerify:
      return PraxisReplayPolicy(
        allowsResume: true,
        allowsHumanOverride: false,
        nextAction: .verifyThenAuto,
        summary: "Replay is staged for automatic continue after verification succeeds."
      )
    case .reReviewThenDispatch:
      return PraxisReplayPolicy(
        allowsResume: true,
        allowsHumanOverride: false,
        nextAction: .reReviewThenDispatch,
        summary: "Replay is staged for re-review before dispatch once activation is ready."
      )
    }
  }

  /// Creates a pending replay record for runtime.
  ///
  /// - Parameters:
  ///   - replayID: The stable identifier for the replay record.
  ///   - capabilityKey: The associated capability identifier.
  ///   - policy: The provisioning policy that the replay should follow.
  /// - Returns: A pending replay record that can be written into the runtime snapshot.
  public func createPendingReplay(
    replayID: String,
    capabilityKey: String,
    policy: PraxisProvisionReplayPolicy
  ) -> PraxisPendingReplay {
    let replayPolicy = replayPolicy(for: policy)
    let status: PraxisReplayStatus = replayPolicy.nextAction == .none ? .skipped : .pending

    return PraxisPendingReplay(
      replayID: replayID,
      capabilityKey: capabilityKey,
      policy: policy,
      status: status,
      nextAction: replayPolicy.nextAction,
      summary: replayPolicy.summary,
      recommendedAction: replayPolicy.nextAction.rawValue
    )
  }

  /// Applies a human-gate state transition to a runtime snapshot and returns the updated snapshot.
  ///
  /// - Parameters:
  ///   - humanGateState: The human-gate state to write.
  ///   - snapshot: The previous TAP runtime snapshot.
  ///   - eventID: The event identifier associated with the state transition.
  ///   - summary: A human-readable summary of the transition.
  ///   - createdAt: The timestamp when the event occurred.
  /// - Returns: A new TAP runtime snapshot containing the appended human-gate event and latest state.
  public func apply(
    humanGateState: PraxisHumanGateState,
    to snapshot: PraxisTapRuntimeSnapshot,
    eventID: String,
    summary: String,
    createdAt: String
  ) -> PraxisTapRuntimeSnapshot {
    let event = PraxisHumanGateEvent(
      eventID: eventID,
      state: humanGateState,
      summary: summary,
      createdAt: createdAt
    )
    return PraxisTapRuntimeSnapshot(
      controlPlaneState: PraxisTapControlPlaneState(
        sessionID: snapshot.controlPlaneState.sessionID,
        governance: snapshot.controlPlaneState.governance,
        humanGateState: humanGateState
      ),
      checkpointPointer: snapshot.checkpointPointer,
      pendingReplays: snapshot.pendingReplays,
      humanGateEvents: snapshot.humanGateEvents + [event]
    )
  }
}

/// Minimal actor-backed TAP runtime store.
/// This type stores runtime snapshots and event history for tests and future host assembly.
public actor PraxisTapRuntimeCoordinator {
  public private(set) var snapshot: PraxisTapRuntimeSnapshot?

  public init(snapshot: PraxisTapRuntimeSnapshot? = nil) {
    self.snapshot = snapshot
  }

  /// Replaces the currently stored runtime snapshot.
  ///
  /// - Parameters:
  ///   - snapshot: The new runtime snapshot to store.
  /// - Returns: None.
  public func store(_ snapshot: PraxisTapRuntimeSnapshot) {
    self.snapshot = snapshot
  }

  /// Appends a human-gate event and synchronizes the corresponding state back into the control-plane state.
  ///
  /// - Parameters:
  ///   - humanGateEvent: The human-gate event to record.
  /// - Returns: None.
  public func record(humanGateEvent: PraxisHumanGateEvent) {
    guard let snapshot else { return }
    self.snapshot = PraxisTapRuntimeSnapshot(
      controlPlaneState: PraxisTapControlPlaneState(
        sessionID: snapshot.controlPlaneState.sessionID,
        governance: snapshot.controlPlaneState.governance,
        humanGateState: humanGateEvent.state
      ),
      checkpointPointer: snapshot.checkpointPointer,
      pendingReplays: snapshot.pendingReplays,
      humanGateEvents: snapshot.humanGateEvents + [humanGateEvent]
    )
  }

  /// Adds a replay record to the pending replay list of the current runtime snapshot.
  ///
  /// - Parameters:
  ///   - replay: The pending replay record to append to the snapshot.
  /// - Returns: None.
  public func stageReplay(_ replay: PraxisPendingReplay) {
    guard let snapshot else { return }
    self.snapshot = PraxisTapRuntimeSnapshot(
      controlPlaneState: snapshot.controlPlaneState,
      checkpointPointer: snapshot.checkpointPointer,
      pendingReplays: snapshot.pendingReplays + [replay],
      humanGateEvents: snapshot.humanGateEvents
    )
  }
}
