import PraxisCapabilityContracts
import PraxisTapTypes

public enum PraxisContextSummaryStatus: String, Sendable, Codable {
  case pending
  case ready
}

public enum PraxisContextFreshnessLevel: String, Sendable, Codable {
  case unknown
  case stale
  case fresh
  case live
}

public enum PraxisContextTrustLevel: String, Sendable, Codable {
  case unknown
  case derived
  case declared
  case verified
}

public struct PraxisContextSummarySlot: Sendable, Equatable, Codable {
  public let summary: String
  public let status: PraxisContextSummaryStatus
  public let source: String?

  public init(summary: String, status: PraxisContextSummaryStatus, source: String? = nil) {
    self.summary = summary
    self.status = status
    self.source = source
  }
}

public struct PraxisContextSectionRecord: Sendable, Equatable, Codable {
  public let sectionID: String
  public let title: String
  public let summary: String
  public let status: PraxisContextSummaryStatus
  public let freshness: PraxisContextFreshnessLevel
  public let trustLevel: PraxisContextTrustLevel

  public init(
    sectionID: String,
    title: String,
    summary: String,
    status: PraxisContextSummaryStatus,
    freshness: PraxisContextFreshnessLevel,
    trustLevel: PraxisContextTrustLevel
  ) {
    self.sectionID = sectionID
    self.title = title
    self.summary = summary
    self.status = status
    self.freshness = freshness
    self.trustLevel = trustLevel
  }
}

public enum PraxisContextForbiddenObjectKind: String, Sendable, Codable {
  case runtimeHandle
  case toolHandle
  case rawPatchObject
  case rawShellHandle
  case secretLiteral
}

public struct PraxisContextForbiddenObject: Sendable, Equatable, Codable {
  public let kind: PraxisContextForbiddenObjectKind
  public let summary: String

  public init(kind: PraxisContextForbiddenObjectKind, summary: String) {
    self.kind = kind
    self.summary = summary
  }
}

public struct PraxisTapInventorySnapshot: Sendable, Equatable, Codable {
  public let totalCapabilities: Int
  public let availableCapabilityIDs: [PraxisCapabilityID]
  public let pendingCapabilityIDs: [PraxisCapabilityID]

  public init(
    totalCapabilities: Int,
    availableCapabilityIDs: [PraxisCapabilityID],
    pendingCapabilityIDs: [PraxisCapabilityID] = []
  ) {
    self.totalCapabilities = totalCapabilities
    self.availableCapabilityIDs = availableCapabilityIDs
    self.pendingCapabilityIDs = pendingCapabilityIDs
  }
}

public struct PraxisPlainLanguageRiskUserAction: Sendable, Equatable, Codable {
  public let actionID: String
  public let label: String
  public let summary: String

  public init(actionID: String, label: String, summary: String) {
    self.actionID = actionID
    self.label = label
    self.summary = summary
  }
}

public struct PraxisPlainLanguageRiskPayload: Sendable, Equatable, Codable {
  public let requestedAction: String
  public let riskLevel: PraxisTapRiskLevel
  public let plainLanguageSummary: String
  public let whyItIsRisky: String
  public let possibleConsequence: String
  public let whatHappensIfNotRun: String
  public let availableUserActions: [PraxisPlainLanguageRiskUserAction]

  public init(
    requestedAction: String,
    riskLevel: PraxisTapRiskLevel,
    plainLanguageSummary: String,
    whyItIsRisky: String,
    possibleConsequence: String,
    whatHappensIfNotRun: String,
    availableUserActions: [PraxisPlainLanguageRiskUserAction]
  ) {
    self.requestedAction = requestedAction
    self.riskLevel = riskLevel
    self.plainLanguageSummary = plainLanguageSummary
    self.whyItIsRisky = whyItIsRisky
    self.possibleConsequence = possibleConsequence
    self.whatHappensIfNotRun = whatHappensIfNotRun
    self.availableUserActions = availableUserActions
  }
}

public struct PraxisReviewContextAperture: Sendable, Equatable, Codable {
  public let projectSummary: PraxisContextSummarySlot
  public let runSummary: PraxisContextSummarySlot
  public let userIntentSummary: PraxisContextSummarySlot
  public let inventorySnapshot: PraxisTapInventorySnapshot
  public let riskSummary: PraxisPlainLanguageRiskPayload
  public let sections: [PraxisContextSectionRecord]
  public let forbiddenObjects: [PraxisContextForbiddenObject]
  public let mode: PraxisTapMode?

  public init(
    projectSummary: PraxisContextSummarySlot,
    runSummary: PraxisContextSummarySlot,
    userIntentSummary: PraxisContextSummarySlot,
    inventorySnapshot: PraxisTapInventorySnapshot,
    riskSummary: PraxisPlainLanguageRiskPayload,
    sections: [PraxisContextSectionRecord],
    forbiddenObjects: [PraxisContextForbiddenObject],
    mode: PraxisTapMode? = nil
  ) {
    self.projectSummary = projectSummary
    self.runSummary = runSummary
    self.userIntentSummary = userIntentSummary
    self.inventorySnapshot = inventorySnapshot
    self.riskSummary = riskSummary
    self.sections = sections
    self.forbiddenObjects = forbiddenObjects
    self.mode = mode
  }
}

public struct PraxisProvisionContextAperture: Sendable, Equatable, Codable {
  public let projectSummary: PraxisContextSummarySlot
  public let requestedCapabilityID: PraxisCapabilityID?
  public let reviewerInstructions: PraxisContextSummarySlot
  public let allowedOperations: [String]
  public let sections: [PraxisContextSectionRecord]
  public let forbiddenObjects: [PraxisContextForbiddenObject]

  public init(
    projectSummary: PraxisContextSummarySlot,
    requestedCapabilityID: PraxisCapabilityID?,
    reviewerInstructions: PraxisContextSummarySlot,
    allowedOperations: [String],
    sections: [PraxisContextSectionRecord],
    forbiddenObjects: [PraxisContextForbiddenObject]
  ) {
    self.projectSummary = projectSummary
    self.requestedCapabilityID = requestedCapabilityID
    self.reviewerInstructions = reviewerInstructions
    self.allowedOperations = allowedOperations
    self.sections = sections
    self.forbiddenObjects = forbiddenObjects
  }
}
