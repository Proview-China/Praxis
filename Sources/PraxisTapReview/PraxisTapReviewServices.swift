import PraxisTapGovernance
import PraxisTapTypes

/// Default TAP review decision engine.
/// This type decides where a review request should flow next, but it does not own reviewer workers, model hooks, or tool execution.
public struct PraxisReviewDecisionEngine: Sendable {
  public let modePolicyProvider: PraxisDefaultModePolicyProvider

  public init(modePolicyProvider: PraxisDefaultModePolicyProvider = .init()) {
    self.modePolicyProvider = modePolicyProvider
  }

  /// Decides where a review request should go next based on the profile, inventory, and TAP policy.
  ///
  /// - Parameters:
  ///   - request: The review request that is currently being processed.
  ///   - profile: The TAP capability profile currently in effect.
  ///   - inventory: The snapshot of currently available capabilities and provisioning state.
  /// - Returns: The review routing result, including the outcome, policy, and resulting decision.
  public func route(
    request: PraxisReviewRequest,
    profile: PraxisTapCapabilityProfile,
    inventory: PraxisReviewInventory = .init()
  ) -> PraxisReviewRoutingResult {
    let capabilityID = request.capabilityID
    let mode = request.mode ?? profile.defaultMode
    let tier = request.requestedTier ?? profile.baselineTier
    let policy = modePolicyProvider.modePolicy(mode: mode, tier: tier)

    guard let capabilityID else {
      let decision = PraxisReviewDecision(
        route: .reject,
        decisionKind: .denied,
        vote: .deny,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Review request is missing a target capability.",
        deferredReason: nil,
        escalationTarget: nil,
        provisionCapabilityID: nil
      )
      return PraxisReviewRoutingResult(outcome: .denied, policy: policy, decision: decision)
    }

    if profile.isCapabilityDenied(capabilityID.rawValue) {
      let decision = PraxisReviewDecision(
        route: .reject,
        decisionKind: .denied,
        vote: .deny,
        capabilityID: capabilityID,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Capability \(capabilityID.rawValue) is denied by the active TAP profile."
      )
      return PraxisReviewRoutingResult(outcome: .denied, policy: policy, decision: decision)
    }

    if inventory.pendingProvisionCapabilityIDs.contains(capabilityID) {
      let decision = PraxisReviewDecision(
        route: .toolReview,
        decisionKind: .deferred,
        vote: .deferred,
        capabilityID: capabilityID,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Capability \(capabilityID.rawValue) is already provisioning.",
        deferredReason: "Awaiting provision artifact bundle completion."
      )
      return PraxisReviewRoutingResult(outcome: .reviewRequired, policy: policy, decision: decision)
    }

    if inventory.readyProvisionCapabilityIDs.contains(capabilityID) || inventory.activeProvisionCapabilityIDs.contains(capabilityID) {
      let decision = PraxisReviewDecision(
        route: .toolReview,
        decisionKind: .deferred,
        vote: .deferred,
        capabilityID: capabilityID,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Capability \(capabilityID.rawValue) already has a provision artifact in handoff.",
        deferredReason: "Replay stays pending until activation and review complete."
      )
      return PraxisReviewRoutingResult(outcome: .reviewRequired, policy: policy, decision: decision)
    }

    if !inventory.availableCapabilityIDs.contains(capabilityID), policy.allowProvisioningRedirect {
      let decision = PraxisReviewDecision(
        route: .toolReview,
        decisionKind: .redirectedToProvisioning,
        vote: .redirectToProvisioning,
        capabilityID: capabilityID,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Capability \(capabilityID.rawValue) is not currently available and should be provisioned first.",
        provisionCapabilityID: capabilityID
      )
      return PraxisReviewRoutingResult(outcome: .redirectedToProvisioning, policy: policy, decision: decision)
    }

    if profile.isCapabilityAllowed(capabilityID.rawValue), policy.allowsAutoGrant {
      let decision = PraxisReviewDecision(
        route: .autoApprove,
        decisionKind: .approved,
        vote: .allow,
        capabilityID: capabilityID,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Capability \(capabilityID.rawValue) is baseline-allowed for the active TAP profile."
      )
      return PraxisReviewRoutingResult(outcome: .baselineApproved, policy: policy, decision: decision)
    }

    if policy.requiresHumanGate {
      let decision = PraxisReviewDecision(
        route: .humanReview,
        decisionKind: .escalatedToHuman,
        vote: .escalateToHuman,
        capabilityID: capabilityID,
        mode: mode,
        riskLevel: request.riskLevel,
        summary: "Capability \(capabilityID.rawValue) requires human approval in \(mode.rawValue) mode.",
        escalationTarget: "human-review"
      )
      return PraxisReviewRoutingResult(outcome: .escalatedToHuman, policy: policy, decision: decision)
    }

    let decision = PraxisReviewDecision(
      route: .toolReview,
      decisionKind: .deferred,
      vote: .deferred,
      capabilityID: capabilityID,
      mode: mode,
      riskLevel: request.riskLevel,
      summary: "Capability \(capabilityID.rawValue) requires reviewer handling.",
      deferredReason: "Route through reviewer strategy before execution in \(mode.rawValue) mode."
    )
    return PraxisReviewRoutingResult(outcome: .reviewRequired, policy: policy, decision: decision)
  }
}

/// Concurrency-safe coordinator that stores the latest review decision and an append-only decision trail.
public actor PraxisReviewerCoordinator {
  public private(set) var latestDecision: PraxisReviewDecision?
  public private(set) var trail: PraxisReviewTrail

  public init(latestDecision: PraxisReviewDecision? = nil) {
    self.latestDecision = latestDecision
    if let latestDecision {
      self.trail = PraxisReviewTrail(decisions: [latestDecision])
    } else {
      self.trail = PraxisReviewTrail(decisions: [])
    }
  }

  /// Appends a new review decision and updates both `latestDecision` and the decision trail.
  ///
  /// - Parameters:
  ///   - decision: The review decision to record.
  /// - Returns: None.
  public func record(_ decision: PraxisReviewDecision) {
    latestDecision = decision
    trail = PraxisReviewTrail(decisions: trail.decisions + [decision])
  }
}
