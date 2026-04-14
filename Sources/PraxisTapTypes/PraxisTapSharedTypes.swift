import Foundation

/// Represents the capability tier that determines how much trust and review budget a TAP request consumes.
public enum PraxisTapCapabilityTier: String, CaseIterable, Sendable, Codable {
  case b0 = "B0"
  case b1 = "B1"
  case b2 = "B2"
  case b3 = "B3"
}

/// Represents the canonical TAP mode used by governance rules.
public enum PraxisTapCanonicalMode: String, CaseIterable, Sendable, Codable {
  case bapr
  case yolo
  case permissive
  case standard
  case restricted
}

/// Represents a TAP mode, including canonical values and legacy aliases.
/// This type is responsible for accepting legacy configuration input, but downstream rule evaluation should normalize through `canonicalMode`.
public enum PraxisTapMode: String, CaseIterable, Sendable, Codable {
  case bapr
  case yolo
  case permissive
  case standard
  case restricted
  case strict
  case balanced

  public var canonicalMode: PraxisTapCanonicalMode {
    switch self {
    case .bapr:
      .bapr
    case .yolo:
      .yolo
    case .permissive, .balanced:
      .permissive
    case .standard, .strict:
      .standard
    case .restricted:
      .restricted
    }
  }

  public var isLegacyAlias: Bool {
    switch self {
    case .strict, .balanced:
      true
    case .bapr, .yolo, .permissive, .standard, .restricted:
      false
    }
  }
}

/// Represents the coarse-grained risk level used by TAP policy branching instead of a fine-grained score.
public enum PraxisTapRiskLevel: String, CaseIterable, Sendable, Codable {
  case normal
  case risky
  case dangerous

  public var requiresEscalation: Bool {
    switch self {
    case .dangerous:
      true
    case .normal, .risky:
      false
    }
  }
}

public enum PraxisTapReviewKind: String, Sendable, Codable {
  case automated
  case human
  case tool
}

public enum PraxisTapReviewVote: String, Sendable, Codable {
  case allow
  case allowWithConstraints = "allow_with_constraints"
  case deny
  case deferred = "defer"
  case escalateToHuman = "escalate_to_human"
  case redirectToProvisioning = "redirect_to_provisioning"
}

public enum PraxisTapReviewDecisionKind: String, Sendable, Codable {
  case approved
  case partiallyApproved = "partially_approved"
  case denied
  case deferred
  case escalatedToHuman = "escalated_to_human"
  case redirectedToProvisioning = "redirected_to_provisioning"
}

public enum PraxisTapProvisionKind: String, Sendable, Codable {
  case capability
  case tool
  case workspace
}

public enum PraxisHumanGateState: String, Sendable, Codable {
  case notRequired
  case waitingApproval
  case approved
  case rejected
}

/// Represents a minimal TAP policy configuration set.
/// This type answers which capabilities are baseline, review-only, or denied, but it does not own runtime execution or host side effects.
public struct PraxisTapCapabilityProfile: Sendable, Equatable, Codable {
  public let profileID: String
  public let agentClass: String
  public let defaultMode: PraxisTapMode
  public let baselineTier: PraxisTapCapabilityTier
  public let baselineCapabilities: [String]
  public let allowedCapabilityPatterns: [String]
  public let reviewOnlyCapabilities: [String]
  public let reviewOnlyCapabilityPatterns: [String]
  public let deniedCapabilityPatterns: [String]
  public let notes: String?

  public init(
    profileID: String,
    agentClass: String,
    defaultMode: PraxisTapMode = .balanced,
    baselineTier: PraxisTapCapabilityTier = .b0,
    baselineCapabilities: [String] = [],
    allowedCapabilityPatterns: [String] = [],
    reviewOnlyCapabilities: [String] = [],
    reviewOnlyCapabilityPatterns: [String] = [],
    deniedCapabilityPatterns: [String] = [],
    notes: String? = nil
  ) {
    self.profileID = profileID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.agentClass = agentClass.trimmingCharacters(in: .whitespacesAndNewlines)
    self.defaultMode = defaultMode
    self.baselineTier = baselineTier
    self.baselineCapabilities = Self.normalize(baselineCapabilities)
    self.allowedCapabilityPatterns = Self.normalize(allowedCapabilityPatterns)
    self.reviewOnlyCapabilities = Self.normalize(reviewOnlyCapabilities)
    self.reviewOnlyCapabilityPatterns = Self.normalize(reviewOnlyCapabilityPatterns)
    self.deniedCapabilityPatterns = Self.normalize(deniedCapabilityPatterns)
    self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
  }

  /// The canonical mode is what governance rules should branch on after config parsing.
  public var canonicalDefaultMode: PraxisTapCanonicalMode {
    defaultMode.canonicalMode
  }

  /// Determines whether a capability is explicitly denied by the current TAP profile.
  ///
  /// - Parameters:
  ///   - capabilityKey: The capability identifier to check.
  /// - Returns: `true` when the capability matches a deny rule; otherwise `false`.
  public func isCapabilityDenied(_ capabilityKey: String) -> Bool {
    praxisTapMatchesCapabilityPattern(
      capabilityKey: capabilityKey,
      exactMatches: [],
      patterns: deniedCapabilityPatterns
    )
  }

  /// Determines whether a capability must go through review instead of the baseline fast path.
  ///
  /// - Parameters:
  ///   - capabilityKey: The capability identifier to check.
  /// - Returns: `true` when the capability matches a review-only rule; otherwise `false`.
  public func isCapabilityReviewOnly(_ capabilityKey: String) -> Bool {
    if reviewOnlyCapabilities.contains(capabilityKey) {
      return true
    }
    return praxisTapMatchesCapabilityPattern(
      capabilityKey: capabilityKey,
      exactMatches: [],
      patterns: reviewOnlyCapabilityPatterns
    )
  }

  /// Determines whether a capability is baseline-allowed under the current TAP profile.
  ///
  /// - Parameters:
  ///   - capabilityKey: The capability identifier to check.
  /// - Returns: `true` when the capability can be allowed directly at the profile layer; otherwise `false`.
  public func isCapabilityAllowed(_ capabilityKey: String) -> Bool {
    if isCapabilityDenied(capabilityKey) {
      return false
    }
    if baselineCapabilities.contains(capabilityKey) {
      return true
    }
    if isCapabilityReviewOnly(capabilityKey) {
      return false
    }
    return praxisTapMatchesCapabilityPattern(
      capabilityKey: capabilityKey,
      exactMatches: [],
      patterns: allowedCapabilityPatterns
    )
  }

  private static func normalize(_ values: [String]) -> [String] {
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
}

/// Determines whether a capability key matches TAP profile rules by exact match or wildcard patterns.
///
/// - Parameters:
///   - capabilityKey: The capability identifier to match.
///   - exactMatches: The capability list that must match exactly.
///   - patterns: The pattern list that supports the `*` wildcard.
/// - Returns: `true` when any exact match or pattern matches; otherwise `false`.
public func praxisTapMatchesCapabilityPattern(
  capabilityKey: String,
  exactMatches: [String] = [],
  patterns: [String] = []
) -> Bool {
  if exactMatches.contains(capabilityKey) {
    return true
  }

  for pattern in patterns where praxisTapMatchesCapabilityPattern(capabilityKey: capabilityKey, pattern: pattern) {
    return true
  }

  return false
}

/// Determines whether a capability key matches a single wildcard pattern.
///
/// - Parameters:
///   - capabilityKey: The capability identifier to match.
///   - pattern: A TAP pattern string that supports `*`.
/// - Returns: `true` when the capability key matches the pattern; otherwise `false`.
public func praxisTapMatchesCapabilityPattern(
  capabilityKey: String,
  pattern: String
) -> Bool {
  let normalizedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
  if normalizedPattern.isEmpty {
    return false
  }
  if normalizedPattern == "*" {
    return true
  }
  if !normalizedPattern.contains("*") {
    return capabilityKey == normalizedPattern
  }

  let parts = normalizedPattern.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
  var searchStart = capabilityKey.startIndex
  var isFirstPart = true

  for rawPart in parts {
    let part = rawPart
    if part.isEmpty {
      isFirstPart = false
      continue
    }

    guard let range = capabilityKey.range(of: part, range: searchStart..<capabilityKey.endIndex) else {
      return false
    }

    if isFirstPart && !normalizedPattern.hasPrefix("*") && range.lowerBound != capabilityKey.startIndex {
      return false
    }

    searchStart = range.upperBound
    isFirstPart = false
  }

  if !normalizedPattern.hasSuffix("*"), let lastPart = parts.last, !lastPart.isEmpty {
    return capabilityKey.hasSuffix(lastPart)
  }

  return true
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
