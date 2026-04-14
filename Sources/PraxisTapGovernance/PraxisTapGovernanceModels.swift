import PraxisCapabilityContracts
import PraxisTapTypes

public struct PraxisTapGovernanceObject: Sendable, Equatable, Codable {
  public let mode: PraxisTapMode
  public let riskLevel: PraxisTapRiskLevel
  public let capabilityIDs: [PraxisCapabilityID]

  public init(mode: PraxisTapMode, riskLevel: PraxisTapRiskLevel, capabilityIDs: [PraxisCapabilityID]) {
    self.mode = mode
    self.riskLevel = riskLevel
    self.capabilityIDs = capabilityIDs
  }

  public var canonicalMode: PraxisTapCanonicalMode {
    mode.canonicalMode
  }
}

public struct PraxisGovernanceSnapshot: Sendable, Equatable, Codable {
  public let governance: PraxisTapGovernanceObject
  public let summary: String

  public init(governance: PraxisTapGovernanceObject, summary: String) {
    self.governance = governance
    self.summary = summary
  }
}

public enum PraxisTapReviewerStrategy: String, Sendable, Codable {
  case skip
  case fast
  case normal
  case strict
  case interruptOnly = "interrupt_only"
  case humanGate = "human_gate"
}

public enum PraxisTapExecutionPath: String, Sendable, Codable {
  case baselineFastPath = "baseline_fast_path"
  case reviewPath = "review_path"
  case guardedExecution = "guarded_execution"
  case humanGate = "human_gate"
}

public enum PraxisTapReviewRequirement: String, Sendable, Codable {
  case none
  case explicitReview = "explicit_review"
  case strictReview = "strict_review"
  case humanEscalation = "human_escalation"
  case interruptibleExecution = "interruptible_execution"
}

public enum PraxisTapRequestPath: String, Sendable, Codable {
  case baseline
  case review
  case guarded
  case human
}

public enum PraxisTapModePolicyDecision: String, Sendable, Codable {
  case allow
  case review
  case reviewStrict = "review_strict"
  case interrupt
  case escalateToHuman = "escalate_to_human"
}

public enum PraxisTapModeRiskDecision: String, Sendable, Codable {
  case allow
  case review
  case deny
  case humanGate = "human_gate"
}

public enum PraxisTapRiskReason: String, Sendable, Codable {
  case defaultNormal = "default_normal"
  case riskyPattern = "risky_pattern"
  case dangerousPattern = "dangerous_pattern"
  case criticalTier = "critical_tier"
}

public struct PraxisTapRiskClassification: Sendable, Equatable, Codable {
  public let capabilityKey: String
  public let riskLevel: PraxisTapRiskLevel
  public let reason: PraxisTapRiskReason
  public let matchedPattern: String?

  public init(
    capabilityKey: String,
    riskLevel: PraxisTapRiskLevel,
    reason: PraxisTapRiskReason,
    matchedPattern: String? = nil
  ) {
    self.capabilityKey = capabilityKey
    self.riskLevel = riskLevel
    self.reason = reason
    self.matchedPattern = matchedPattern
  }
}

public struct PraxisModePolicy: Sendable, Equatable, Codable {
  public let mode: PraxisTapCanonicalMode
  public let tier: PraxisTapCapabilityTier
  public let requestPath: PraxisTapRequestPath
  public let executionPath: PraxisTapExecutionPath
  public let reviewerStrategy: PraxisTapReviewerStrategy
  public let reviewRequirement: PraxisTapReviewRequirement
  public let autoApprove: Bool
  public let allowProvisioningRedirect: Bool
  public let allowEmergencyInterrupt: Bool
  public let defaultDecisionHint: PraxisTapReviewDecisionKind

  public init(
    mode: PraxisTapCanonicalMode,
    tier: PraxisTapCapabilityTier,
    requestPath: PraxisTapRequestPath,
    executionPath: PraxisTapExecutionPath,
    reviewerStrategy: PraxisTapReviewerStrategy,
    reviewRequirement: PraxisTapReviewRequirement,
    autoApprove: Bool,
    allowProvisioningRedirect: Bool,
    allowEmergencyInterrupt: Bool,
    defaultDecisionHint: PraxisTapReviewDecisionKind
  ) {
    self.mode = mode
    self.tier = tier
    self.requestPath = requestPath
    self.executionPath = executionPath
    self.reviewerStrategy = reviewerStrategy
    self.reviewRequirement = reviewRequirement
    self.autoApprove = autoApprove
    self.allowProvisioningRedirect = allowProvisioningRedirect
    self.allowEmergencyInterrupt = allowEmergencyInterrupt
    self.defaultDecisionHint = defaultDecisionHint
  }

  public var shouldSkipReview: Bool {
    reviewerStrategy == .skip
  }

  public var requiresHumanGate: Bool {
    executionPath == .humanGate
  }

  public var allowsAutoGrant: Bool {
    autoApprove
  }

  public var requiresReview: Bool {
    switch reviewRequirement {
    case .explicitReview, .strictReview:
      true
    case .interruptibleExecution:
      !autoApprove
    case .none, .humanEscalation:
      false
    }
  }
}

public struct PraxisModePolicyEntry: Sendable, Equatable, Codable {
  public let mode: PraxisTapCanonicalMode
  public let tier: PraxisTapCapabilityTier
  public let decision: PraxisTapModePolicyDecision
  public let requiresReview: Bool
  public let allowsAutoGrant: Bool
  public let requiresHuman: Bool
  public let actsAsSafetyAirbag: Bool

  public init(
    mode: PraxisTapCanonicalMode,
    tier: PraxisTapCapabilityTier,
    decision: PraxisTapModePolicyDecision,
    requiresReview: Bool,
    allowsAutoGrant: Bool,
    requiresHuman: Bool,
    actsAsSafetyAirbag: Bool
  ) {
    self.mode = mode
    self.tier = tier
    self.decision = decision
    self.requiresReview = requiresReview
    self.allowsAutoGrant = allowsAutoGrant
    self.requiresHuman = requiresHuman
    self.actsAsSafetyAirbag = actsAsSafetyAirbag
  }
}

public struct PraxisModeRiskPolicyEntry: Sendable, Equatable, Codable {
  public let mode: PraxisTapCanonicalMode
  public let riskLevel: PraxisTapRiskLevel
  public let decision: PraxisTapModeRiskDecision
  public let baselineFastPath: Bool
  public let defaultVote: PraxisTapReviewVote

  public init(
    mode: PraxisTapCanonicalMode,
    riskLevel: PraxisTapRiskLevel,
    decision: PraxisTapModeRiskDecision,
    baselineFastPath: Bool,
    defaultVote: PraxisTapReviewVote
  ) {
    self.mode = mode
    self.riskLevel = riskLevel
    self.decision = decision
    self.baselineFastPath = baselineFastPath
    self.defaultVote = defaultVote
  }
}
