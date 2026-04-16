import Foundation
import PraxisTapTypes

/// Converts a capability request into a risk classification result that TAP policy can consume.
public protocol PraxisRiskClassifying: Sendable {
  func classify(
    capabilityKey: String,
    requestedTier: PraxisTapCapabilityTier?
  ) -> PraxisTapRiskClassification
}

/// Provides centralized policy lookup for mode+tier and mode+risk combinations.
/// This protocol keeps the TAP matrix in one place so review, runtime, and availability do not duplicate the same encoding.
public protocol PraxisModePolicyProviding: Sendable {
  func modePolicy(mode: PraxisTapMode, tier: PraxisTapCapabilityTier) -> PraxisModePolicy
  func modePolicyEntry(mode: PraxisTapMode, tier: PraxisTapCapabilityTier) -> PraxisModePolicyEntry
  func riskPolicyEntry(mode: PraxisTapMode, riskLevel: PraxisTapRiskLevel) -> PraxisModeRiskPolicyEntry
}

/// Performs the final TAP safety boundary decision before a request crosses from planning into execution.
public protocol PraxisTapSafetyIntercepting: Sendable {
  func evaluate(_ input: PraxisTapSafetyInterception) -> PraxisTapSafetyDecision
}

private struct PraxisModePolicyMatrixEntry: Sendable {
  let executionPath: PraxisTapExecutionPath
  let reviewerStrategy: PraxisTapReviewerStrategy
  let reviewRequirement: PraxisTapReviewRequirement
  let autoApprove: Bool
  let allowProvisioningRedirect: Bool
  let allowEmergencyInterrupt: Bool
  let defaultDecisionHint: PraxisTapReviewDecisionKind
}

/// Default TAP risk classifier.
/// This type ports risk-pattern rules from the legacy TypeScript implementation into Swift Core, but it does not read external host or provider evidence.
public struct PraxisDefaultRiskClassifier: PraxisRiskClassifying, Sendable {
  public let riskyCapabilityPatterns: [String]
  public let dangerousCapabilityPatterns: [String]

  public init(
    riskyCapabilityPatterns: [String]? = nil,
    dangerousCapabilityPatterns: [String]? = nil
  ) {
    self.riskyCapabilityPatterns = Self.normalizePatterns(riskyCapabilityPatterns ?? Self.defaultRiskyPatterns)
    self.dangerousCapabilityPatterns = Self.normalizePatterns(dangerousCapabilityPatterns ?? Self.defaultDangerousPatterns)
  }

  /// Classifies the risk of a capability request for reuse by TAP policy, review, and runtime safeguards.
  ///
  /// - Parameters:
  ///   - capabilityKey: The capability identifier of the current request.
  ///   - requestedTier: The capability tier declared by the current request. When `nil`, evaluation falls back to capability-key rules only.
  /// - Returns: A structured risk classification containing the risk level, reason, and matched patterns.
  public func classify(
    capabilityKey: String,
    requestedTier: PraxisTapCapabilityTier? = nil
  ) -> PraxisTapRiskClassification {
    if let matchedPattern = firstMatch(capabilityKey: capabilityKey, patterns: dangerousCapabilityPatterns) {
      return PraxisTapRiskClassification(
        capabilityKey: capabilityKey,
        riskLevel: .dangerous,
        reason: .dangerousPattern,
        matchedPattern: matchedPattern
      )
    }

    if let matchedPattern = firstMatch(capabilityKey: capabilityKey, patterns: riskyCapabilityPatterns) {
      return PraxisTapRiskClassification(
        capabilityKey: capabilityKey,
        riskLevel: .risky,
        reason: .riskyPattern,
        matchedPattern: matchedPattern
      )
    }

    if requestedTier == .b3 {
      return PraxisTapRiskClassification(
        capabilityKey: capabilityKey,
        riskLevel: .risky,
        reason: .criticalTier
      )
    }

    return PraxisTapRiskClassification(
      capabilityKey: capabilityKey,
      riskLevel: .normal,
      reason: .defaultNormal
    )
  }

  private func firstMatch(capabilityKey: String, patterns: [String]) -> String? {
    patterns.first { praxisTapMatchesCapabilityPattern(capabilityKey: capabilityKey, pattern: $0) }
  }

  private static func normalizePatterns(_ values: [String]) -> [String] {
    var seen = Set<String>()
    var normalized: [String] = []
    for value in values {
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty || seen.contains(trimmed) {
        continue
      }
      seen.insert(trimmed)
      normalized.append(trimmed)
    }
    return normalized
  }

  private static let defaultRiskyPatterns = [
    "shell.*",
    "system.*",
    "computer.use*",
    "workspace.outside.*",
    "filesystem.delete.*",
    "git.reset.*",
    "git.checkout.discard",
    "sudo",
    "mcp.root.*",
    "mcp.call",
    "mcp.native.execute",
    "mcp.browser.control",
    "mcp.playwright",
    "browser.playwright",
    "computer_use.*",
    "code.exec.*",
    "code.run",
    "code.patch",
    "code.sandbox",
    "shell.exec",
    "shell.run",
    "delete.*",
    "rm.*",
  ]

  private static let defaultDangerousPatterns = [
    "shell.rm*",
    "shell.delete*",
    "system.sudo",
    "git.reset.hard",
    "git.checkout.discard",
    "filesystem.delete.*",
    "workspace.outside.write",
    "workspace.outside.delete",
    "computer.use.dangerous",
  ]
}

/// Default TAP mode policy provider.
/// This type centralizes the current TAP mode matrix for shared use across review, provision, runtime, and availability.
public struct PraxisDefaultModePolicyProvider: PraxisModePolicyProviding, Sendable {
  public init() {}

  /// Builds a full TAP policy snapshot from a mode and tier.
  ///
  /// - Parameters:
  ///   - mode: The TAP mode used by the current request.
  ///   - tier: The capability tier declared by the current request.
  /// - Returns: A full policy snapshot that review, runtime, and availability can read directly.
  public func modePolicy(mode: PraxisTapMode, tier: PraxisTapCapabilityTier) -> PraxisModePolicy {
    let canonicalMode = mode.canonicalMode
    let entry = Self.modeMatrix[canonicalMode]?[tier] ?? Self.fallbackEntry

    return PraxisModePolicy(
      mode: canonicalMode,
      tier: tier,
      requestPath: requestPath(for: entry.executionPath),
      executionPath: entry.executionPath,
      reviewerStrategy: entry.reviewerStrategy,
      reviewRequirement: entry.reviewRequirement,
      autoApprove: entry.autoApprove,
      allowProvisioningRedirect: entry.allowProvisioningRedirect,
      allowEmergencyInterrupt: entry.allowEmergencyInterrupt,
      defaultDecisionHint: entry.defaultDecisionHint
    )
  }

  /// Builds a compact policy view for decision-making from a mode and tier.
  ///
  /// - Parameters:
  ///   - mode: The TAP mode used by the current request.
  ///   - tier: The capability tier declared by the current request.
  /// - Returns: A compact decision result used by rule engines and test assertions.
  public func modePolicyEntry(mode: PraxisTapMode, tier: PraxisTapCapabilityTier) -> PraxisModePolicyEntry {
    let policy = modePolicy(mode: mode, tier: tier)
    let decision: PraxisTapModePolicyDecision

    if policy.requiresHumanGate {
      decision = .escalateToHuman
    } else if policy.executionPath == .guardedExecution {
      decision = .interrupt
    } else if policy.reviewRequirement == .strictReview {
      decision = .reviewStrict
    } else if policy.reviewRequirement == .explicitReview {
      decision = .review
    } else {
      decision = .allow
    }

    return PraxisModePolicyEntry(
      mode: policy.mode,
      tier: tier,
      decision: decision,
      requiresReview: policy.requiresReview,
      allowsAutoGrant: policy.allowsAutoGrant,
      requiresHuman: policy.requiresHumanGate,
      actsAsSafetyAirbag: policy.allowEmergencyInterrupt && policy.mode == .yolo
    )
  }

  /// Builds the risk policy required by runtime safeguards from a mode and risk level.
  ///
  /// - Parameters:
  ///   - mode: The TAP mode used by the current request.
  ///   - riskLevel: The risk level associated with the current request or observation.
  /// - Returns: The risk policy result consumed by runtime safeguards.
  public func riskPolicyEntry(mode: PraxisTapMode, riskLevel: PraxisTapRiskLevel) -> PraxisModeRiskPolicyEntry {
    let canonicalMode = mode.canonicalMode

    switch canonicalMode {
    case .bapr:
      return PraxisModeRiskPolicyEntry(
        mode: canonicalMode,
        riskLevel: riskLevel,
        decision: .allow,
        baselineFastPath: true,
        defaultVote: .allow
      )
    case .yolo:
      if riskLevel == .dangerous {
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .deny,
          baselineFastPath: false,
          defaultVote: .deny
        )
      }
      return PraxisModeRiskPolicyEntry(
        mode: canonicalMode,
        riskLevel: riskLevel,
        decision: .allow,
        baselineFastPath: true,
        defaultVote: .allow
      )
    case .permissive:
      switch riskLevel {
      case .normal:
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .allow,
          baselineFastPath: true,
          defaultVote: .allow
        )
      case .risky:
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .review,
          baselineFastPath: false,
          defaultVote: .deferred
        )
      case .dangerous:
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .humanGate,
          baselineFastPath: false,
          defaultVote: .escalateToHuman
        )
      }
    case .standard:
      switch riskLevel {
      case .normal:
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .review,
          baselineFastPath: true,
          defaultVote: .deferred
        )
      case .risky:
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .review,
          baselineFastPath: false,
          defaultVote: .deferred
        )
      case .dangerous:
        return PraxisModeRiskPolicyEntry(
          mode: canonicalMode,
          riskLevel: riskLevel,
          decision: .humanGate,
          baselineFastPath: false,
          defaultVote: .escalateToHuman
        )
      }
    case .restricted:
      return PraxisModeRiskPolicyEntry(
        mode: canonicalMode,
        riskLevel: riskLevel,
        decision: .humanGate,
        baselineFastPath: riskLevel == .normal,
        defaultVote: .escalateToHuman
      )
    }
  }

  private func requestPath(for executionPath: PraxisTapExecutionPath) -> PraxisTapRequestPath {
    switch executionPath {
    case .baselineFastPath:
      .baseline
    case .reviewPath:
      .review
    case .guardedExecution:
      .guarded
    case .humanGate:
      .human
    }
  }

  private static let fallbackEntry = PraxisModePolicyMatrixEntry(
    executionPath: .reviewPath,
    reviewerStrategy: .normal,
    reviewRequirement: .explicitReview,
    autoApprove: false,
    allowProvisioningRedirect: false,
    allowEmergencyInterrupt: false,
    defaultDecisionHint: .deferred
  )

  private static let modeMatrix: [PraxisTapCanonicalMode: [PraxisTapCapabilityTier: PraxisModePolicyMatrixEntry]] = [
    .bapr: [
      .b0: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b1: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b2: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b3: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
    ],
    .yolo: [
      .b0: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b1: .init(executionPath: .baselineFastPath, reviewerStrategy: .interruptOnly, reviewRequirement: .interruptibleExecution, autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: .approved),
      .b2: .init(executionPath: .guardedExecution, reviewerStrategy: .interruptOnly, reviewRequirement: .interruptibleExecution, autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: .approved),
      .b3: .init(executionPath: .guardedExecution, reviewerStrategy: .interruptOnly, reviewRequirement: .interruptibleExecution, autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: .denied),
    ],
    .permissive: [
      .b0: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b1: .init(executionPath: .reviewPath, reviewerStrategy: .fast, reviewRequirement: .explicitReview, autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .deferred),
      .b2: .init(executionPath: .reviewPath, reviewerStrategy: .normal, reviewRequirement: .explicitReview, autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: .deferred),
      .b3: .init(executionPath: .guardedExecution, reviewerStrategy: .strict, reviewRequirement: .strictReview, autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: .denied),
    ],
    .standard: [
      .b0: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b1: .init(executionPath: .reviewPath, reviewerStrategy: .normal, reviewRequirement: .explicitReview, autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .deferred),
      .b2: .init(executionPath: .reviewPath, reviewerStrategy: .strict, reviewRequirement: .strictReview, autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: .deferred),
      .b3: .init(executionPath: .humanGate, reviewerStrategy: .humanGate, reviewRequirement: .humanEscalation, autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: .escalatedToHuman),
    ],
    .restricted: [
      .b0: .init(executionPath: .baselineFastPath, reviewerStrategy: .skip, reviewRequirement: .none, autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: .approved),
      .b1: .init(executionPath: .humanGate, reviewerStrategy: .humanGate, reviewRequirement: .humanEscalation, autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: .escalatedToHuman),
      .b2: .init(executionPath: .humanGate, reviewerStrategy: .humanGate, reviewRequirement: .humanEscalation, autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: .escalatedToHuman),
      .b3: .init(executionPath: .humanGate, reviewerStrategy: .humanGate, reviewRequirement: .humanEscalation, autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: .escalatedToHuman),
    ],
  ]
}

/// Default TAP safety interceptor.
/// This type maps a risk policy into the minimal executable verdict, such as allow, downgrade, interrupt, block, or escalateToHuman.
public struct PraxisDefaultSafetyInterceptor: PraxisTapSafetyIntercepting, Sendable {
  public let modePolicyProvider: PraxisDefaultModePolicyProvider

  public init(modePolicyProvider: PraxisDefaultModePolicyProvider = .init()) {
    self.modePolicyProvider = modePolicyProvider
  }

  /// Applies the final safety decision for a potential execution using TAP risk policy.
  ///
  /// - Parameters:
  ///   - input: The mode, tier, capability, and risk information evaluated by this safety interception.
  /// - Returns: The resulting safety decision, which may allow, downgrade, interrupt, block, or escalate to human review.
  public func evaluate(_ input: PraxisTapSafetyInterception) -> PraxisTapSafetyDecision {
    let riskPolicy = modePolicyProvider.riskPolicyEntry(mode: input.mode, riskLevel: input.riskLevel)

    switch riskPolicy.decision {
    case .allow:
      return PraxisTapSafetyDecision(
        outcome: .allow,
        summary: "Current TAP policy allows \(input.capabilityKey) in \(input.mode.rawValue) mode."
      )
    case .review:
      // Downgrade keeps the request alive but forces it back onto a reviewed path.
      return PraxisTapSafetyDecision(
        outcome: .downgrade,
        summary: "Current TAP policy requires a reviewed path for \(input.capabilityKey).",
        downgradedMode: .standard
      )
    case .deny:
      if input.mode.canonicalMode == .yolo {
        return PraxisTapSafetyDecision(
          outcome: .interrupt,
          summary: "Yolo mode must interrupt dangerous capability \(input.capabilityKey)."
        )
      }
      return PraxisTapSafetyDecision(
        outcome: .block,
        summary: "Current TAP policy blocks dangerous capability \(input.capabilityKey)."
      )
    case .humanGate:
      return PraxisTapSafetyDecision(
        outcome: .escalateToHuman,
        summary: "Current TAP policy requires human approval for \(input.capabilityKey).",
        downgradedMode: .restricted
      )
    }
  }
}
