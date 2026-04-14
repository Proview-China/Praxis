import Testing
@testable import PraxisTapAvailability
@testable import PraxisTapGovernance
@testable import PraxisTapProvision
@testable import PraxisTapReview
@testable import PraxisTapRuntime
@testable import PraxisTapTypes
@testable import PraxisCapabilityContracts
@testable import PraxisSession

struct TapOperationalRuleTests {
  @Test
  func reviewDecisionEngineRoutesBaselineProvisioningAndHumanGate() {
    let engine = PraxisReviewDecisionEngine()
    let profile = PraxisTapCapabilityProfile(
      profileID: "review.profile",
      agentClass: "reviewer",
      defaultMode: .balanced,
      baselineTier: .b1,
      baselineCapabilities: ["workspace.read"],
      allowedCapabilityPatterns: ["shell.*"]
    )

    let baseline = engine.route(
      request: PraxisReviewRequest(
        reviewKind: .automated,
        capabilityID: .init(rawValue: "workspace.read"),
        requestedTier: .b0,
        mode: .bapr,
        riskLevel: .normal,
        summary: "baseline read"
      ),
      profile: profile,
      inventory: .init(availableCapabilityIDs: [.init(rawValue: "workspace.read")])
    )
    let provisioning = engine.route(
      request: PraxisReviewRequest(
        reviewKind: .tool,
        capabilityID: .init(rawValue: "shell.exec"),
        requestedTier: .b1,
        mode: .permissive,
        riskLevel: .risky,
        summary: "shell not ready"
      ),
      profile: profile,
      inventory: .init()
    )
    let humanGate = engine.route(
      request: PraxisReviewRequest(
        reviewKind: .human,
        capabilityID: .init(rawValue: "shell.exec"),
        requestedTier: .b3,
        mode: .restricted,
        riskLevel: .dangerous,
        summary: "dangerous shell"
      ),
      profile: profile,
      inventory: .init(availableCapabilityIDs: [.init(rawValue: "shell.exec")])
    )

    #expect(baseline.outcome == .baselineApproved)
    #expect(baseline.decision.vote == .allow)
    #expect(provisioning.outcome == .redirectedToProvisioning)
    #expect(provisioning.decision.provisionCapabilityID?.rawValue == "shell.exec")
    #expect(humanGate.outcome == .escalatedToHuman)
    #expect(humanGate.decision.route == .humanReview)
  }

  @Test
  func reviewDecisionEngineRedirectsUnavailableBaselineCapabilityBeforeAutoApproval() {
    let engine = PraxisReviewDecisionEngine()
    let profile = PraxisTapCapabilityProfile(
      profileID: "review.profile",
      agentClass: "reviewer",
      defaultMode: .balanced,
      baselineTier: .b1,
      baselineCapabilities: ["workspace.read"]
    )

    let result = engine.route(
      request: PraxisReviewRequest(
        reviewKind: .automated,
        capabilityID: .init(rawValue: "workspace.read"),
        requestedTier: .b0,
        mode: .bapr,
        riskLevel: .normal,
        summary: "baseline read without inventory"
      ),
      profile: profile,
      inventory: .init()
    )

    #expect(result.outcome == .redirectedToProvisioning)
    #expect(result.decision.vote == .redirectToProvisioning)
    #expect(result.decision.provisionCapabilityID?.rawValue == "workspace.read")
  }

  @Test
  func provisionPlannerBuildsPlanFromRegistry() {
    var registry = PraxisProvisionRegistry()
    registry.register(
      PraxisProvisionRegistryEntry(
        asset: PraxisProvisionAsset(
          name: "shell package",
          capabilityID: .init(rawValue: "shell.exec"),
          status: .readyForReview,
          supportedModes: [.permissive, .standard]
        ),
        supportedModes: [.permissive, .standard],
        summary: "repo-local shell package"
      )
    )

    let planner = PraxisProvisionPlanner(registry: registry)
    let plan = planner.plan(
      PraxisProvisionRequest(
        kind: .capability,
        capabilityID: .init(rawValue: "shell.exec"),
        requestedTier: .b1,
        mode: .permissive,
        summary: "provision shell tooling",
        requiredVerification: ["smoke", "targeted-test"],
        replayPolicy: .manual
      )
    )

    #expect(plan.selectedAssets.count == 1)
    #expect(plan.requiresApproval)
    #expect(plan.verificationPlan.count == 2)
    #expect(plan.summary.contains("shell.exec"))
  }

  @Test
  func provisionRegistryKeepsCapabilityFilterWhenModeIsNil() {
    var registry = PraxisProvisionRegistry()
    registry.register(
      PraxisProvisionRegistryEntry(
        asset: PraxisProvisionAsset(
          name: "shell package",
          capabilityID: .init(rawValue: "shell.exec"),
          status: .active
        ),
        supportedModes: [],
        summary: "shell package"
      )
    )
    registry.register(
      PraxisProvisionRegistryEntry(
        asset: PraxisProvisionAsset(
          name: "workspace package",
          capabilityID: .init(rawValue: "workspace.read"),
          status: .active
        ),
        supportedModes: [],
        summary: "workspace package"
      )
    )

    let assets = registry.assets(for: .init(rawValue: "shell.exec"), mode: nil)

    #expect(assets.count == 1)
    #expect(assets.first?.capabilityID?.rawValue == "shell.exec")
  }

  @Test
  func provisionRegistryNormalizesLegacyTapModeAliasesDuringLookup() {
    var registry = PraxisProvisionRegistry()
    registry.register(
      PraxisProvisionRegistryEntry(
        asset: PraxisProvisionAsset(
          name: "permissive shell package",
          capabilityID: .init(rawValue: "shell.exec"),
          status: .active
        ),
        supportedModes: [.permissive],
        summary: "permissive shell package"
      )
    )
    registry.register(
      PraxisProvisionRegistryEntry(
        asset: PraxisProvisionAsset(
          name: "standard shell package",
          capabilityID: .init(rawValue: "shell.exec"),
          status: .active
        ),
        supportedModes: [.standard],
        summary: "standard shell package"
      )
    )

    let balancedAssets = registry.assets(for: .init(rawValue: "shell.exec"), mode: .balanced)
    let strictAssets = registry.assets(for: .init(rawValue: "shell.exec"), mode: .strict)

    #expect(balancedAssets.count == 1)
    #expect(balancedAssets.first?.name == "permissive shell package")
    #expect(strictAssets.count == 1)
    #expect(strictAssets.first?.name == "standard shell package")
  }

  @Test
  func provisionPlannerRequiresApprovalForReviewOnlyAssets() {
    var registry = PraxisProvisionRegistry()
    registry.register(
      PraxisProvisionRegistryEntry(
        asset: PraxisProvisionAsset(
          name: "shell package",
          capabilityID: .init(rawValue: "shell.exec"),
          status: .readyForReview,
          supportedModes: [.permissive]
        ),
        supportedModes: [.permissive],
        summary: "review-gated shell package"
      )
    )

    let planner = PraxisProvisionPlanner(registry: registry)
    let plan = planner.plan(
      PraxisProvisionRequest(
        kind: .capability,
        capabilityID: .init(rawValue: "shell.exec"),
        requestedTier: .b1,
        mode: .balanced,
        summary: "provision shell tooling",
        replayPolicy: .autoAfterVerify
      )
    )

    #expect(plan.selectedAssets.count == 1)
    #expect(plan.requiresApproval)
  }

  @Test
  func runtimeLifecycleStagesReplayAndHumanGateEvents() async throws {
    let lifecycle = PraxisActivationLifecycleService()
    let replay = lifecycle.createPendingReplay(
      replayID: "replay-1",
      capabilityKey: "shell.exec",
      policy: .autoAfterVerify
    )
    let snapshot = PraxisTapRuntimeSnapshot(
      controlPlaneState: .init(
        sessionID: .init(rawValue: "session.tap"),
        governance: .init(mode: .standard, riskLevel: .risky, capabilityIDs: [.init(rawValue: "shell.exec")]),
        humanGateState: .notRequired
      ),
      checkpointPointer: nil
    )
    let updated = lifecycle.apply(
      humanGateState: .approved,
      to: snapshot,
      eventID: "gate-1",
      summary: "operator approved",
      createdAt: "2026-04-10T16:20:00Z"
    )
    let coordinator = PraxisTapRuntimeCoordinator(snapshot: snapshot)
    await coordinator.stageReplay(replay)
    await coordinator.record(
      humanGateEvent: .init(
        eventID: "gate-1",
        state: .approved,
        summary: "operator approved",
        createdAt: "2026-04-10T16:20:00Z"
      )
    )
    let stored = await coordinator.snapshot

    #expect(replay.nextAction == .verifyThenAuto)
    #expect(updated.controlPlaneState.humanGateState == .approved)
    #expect(updated.humanGateEvents.count == 1)
    #expect(stored?.pendingReplays.count == 1)
    #expect(stored?.humanGateEvents.count == 1)
  }

  @Test
  func availabilityAuditorSeparatesBaselineReviewAndBlockedRecords() {
    let auditor = PraxisAvailabilityAuditor()
    let report = auditor.audit(
      rules: [
        .init(
          capabilityID: .init(rawValue: "workspace.read"),
          summary: "baseline read capability",
          requiredMode: .standard
        ),
        .init(
          capabilityID: .init(rawValue: "shell.exec"),
          summary: "shell requires review",
          requiredMode: .standard,
          reviewRequired: true
        ),
        .init(
          capabilityID: .init(rawValue: "git.push"),
          summary: "push is blocked in current mode",
          requiredMode: .restricted
        ),
      ],
      currentMode: .standard,
      degradedCapabilities: [.init(rawValue: "shell.exec")]
    )

    let baseline = report.records.first { $0.capabilityID.rawValue == "workspace.read" }
    let reviewOnly = report.records.first { $0.capabilityID.rawValue == "shell.exec" }
    let blocked = report.records.first { $0.capabilityID.rawValue == "git.push" }

    #expect(report.state == .gated)
    #expect(baseline?.decision == .baseline)
    #expect(reviewOnly?.decision == .reviewOnly)
    #expect(reviewOnly?.failures == [.runtimeUnavailable])
    #expect(blocked?.decision == .blocked)
  }
}
