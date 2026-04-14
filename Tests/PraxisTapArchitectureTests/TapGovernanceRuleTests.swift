import Testing
@testable import PraxisTapGovernance
@testable import PraxisTapTypes

struct TapGovernanceRuleTests {
  @Test
  func tapProfileNormalizesLegacyModesAndPatternMatching() {
    let profile = PraxisTapCapabilityProfile(
      profileID: " reviewer.profile ",
      agentClass: " reviewer ",
      defaultMode: .balanced,
      baselineTier: .b1,
      baselineCapabilities: ["workspace.read", "workspace.read"],
      allowedCapabilityPatterns: ["shell.*", "git.status"],
      reviewOnlyCapabilities: ["git.push"],
      reviewOnlyCapabilityPatterns: ["dangerous.*"],
      deniedCapabilityPatterns: ["filesystem.delete.*"]
    )

    #expect(profile.profileID == "reviewer.profile")
    #expect(profile.agentClass == "reviewer")
    #expect(profile.defaultMode.canonicalMode == .permissive)
    #expect(profile.baselineCapabilities == ["workspace.read"])
    #expect(profile.isCapabilityAllowed("workspace.read"))
    #expect(profile.isCapabilityAllowed("shell.exec"))
    #expect(!profile.isCapabilityAllowed("filesystem.delete.file"))
    #expect(profile.isCapabilityReviewOnly("dangerous.repo_write"))
    #expect(praxisTapMatchesCapabilityPattern(capabilityKey: "git.reset.hard", pattern: "git.reset.*"))
  }

  @Test
  func riskClassifierAndModePolicyFollowTapMatrix() {
    let classifier = PraxisDefaultRiskClassifier()
    let dangerous = classifier.classify(capabilityKey: "git.reset.hard", requestedTier: .b2)
    let criticalTier = classifier.classify(capabilityKey: "workspace.read", requestedTier: .b3)
    let provider = PraxisDefaultModePolicyProvider()
    let balancedB1 = provider.modePolicy(mode: .balanced, tier: .b1)
    let yoloDangerous = provider.riskPolicyEntry(mode: .yolo, riskLevel: .dangerous)

    #expect(dangerous.riskLevel == .dangerous)
    #expect(dangerous.reason == .dangerousPattern)
    #expect(dangerous.matchedPattern == "git.reset.hard")
    #expect(criticalTier.riskLevel == .risky)
    #expect(criticalTier.reason == .criticalTier)

    #expect(balancedB1.mode == .permissive)
    #expect(balancedB1.requestPath == .review)
    #expect(balancedB1.reviewRequirement == .explicitReview)
    #expect(!balancedB1.autoApprove)
    #expect(balancedB1.allowProvisioningRedirect)

    #expect(yoloDangerous.mode == .yolo)
    #expect(yoloDangerous.decision == .deny)
    #expect(yoloDangerous.defaultVote == .deny)
  }

  @Test
  func safetyInterceptorUsesRiskPolicyBoundaries() {
    let interceptor = PraxisDefaultSafetyInterceptor()

    let dangerousYolo = interceptor.evaluate(
      .init(
        mode: .yolo,
        requestedTier: .b2,
        capabilityKey: "workspace.outside.write",
        requestedOperation: "write outside workspace",
        riskLevel: .dangerous
      )
    )
    let riskyPermissive = interceptor.evaluate(
      .init(
        mode: .permissive,
        requestedTier: .b1,
        capabilityKey: "shell.exec",
        requestedOperation: "run shell command",
        riskLevel: .risky
      )
    )
    let dangerousRestricted = interceptor.evaluate(
      .init(
        mode: .restricted,
        requestedTier: .b1,
        capabilityKey: "workspace.outside.write",
        requestedOperation: "write outside workspace",
        riskLevel: .dangerous
      )
    )

    #expect(dangerousYolo.outcome == .interrupt)
    #expect(riskyPermissive.outcome == .downgrade)
    #expect(riskyPermissive.downgradedMode == .standard)
    #expect(dangerousRestricted.outcome == .escalateToHuman)
    #expect(dangerousRestricted.downgradedMode == .restricted)
  }
}
