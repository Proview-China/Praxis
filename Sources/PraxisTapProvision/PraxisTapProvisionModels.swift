import PraxisCapabilityContracts
import PraxisTapTypes

public enum PraxisProvisionReplayPolicy: String, Sendable, Codable {
  case none
  case manual
  case autoAfterVerify = "auto_after_verify"
  case reReviewThenDispatch = "re_review_then_dispatch"
}

public enum PraxisProvisionAssetStatus: String, Sendable, Codable {
  case readyForReview = "ready_for_review"
  case activating
  case active
  case failed
  case superseded
}

public struct PraxisProvisionRequest: Sendable, Equatable, Codable {
  public let kind: PraxisTapProvisionKind
  public let capabilityID: PraxisCapabilityID?
  public let requestedTier: PraxisTapCapabilityTier?
  public let mode: PraxisTapMode?
  public let summary: String
  public let expectedArtifacts: [String]
  public let requiredVerification: [String]
  public let replayPolicy: PraxisProvisionReplayPolicy

  public init(
    kind: PraxisTapProvisionKind,
    capabilityID: PraxisCapabilityID? = nil,
    requestedTier: PraxisTapCapabilityTier? = nil,
    mode: PraxisTapMode? = nil,
    summary: String,
    expectedArtifacts: [String] = [],
    requiredVerification: [String] = [],
    replayPolicy: PraxisProvisionReplayPolicy = .reReviewThenDispatch
  ) {
    self.kind = kind
    self.capabilityID = capabilityID
    self.requestedTier = requestedTier
    self.mode = mode
    self.summary = summary
    self.expectedArtifacts = expectedArtifacts
    self.requiredVerification = requiredVerification
    self.replayPolicy = replayPolicy
  }
}

public struct PraxisProvisionAsset: Sendable, Equatable, Codable {
  public let name: String
  public let capabilityID: PraxisCapabilityID?
  public let status: PraxisProvisionAssetStatus
  public let supportedModes: [PraxisTapMode]

  public init(
    name: String,
    capabilityID: PraxisCapabilityID?,
    status: PraxisProvisionAssetStatus = .readyForReview,
    supportedModes: [PraxisTapMode] = []
  ) {
    self.name = name
    self.capabilityID = capabilityID
    self.status = status
    self.supportedModes = supportedModes
  }
}

public struct PraxisProvisionRegistryEntry: Sendable, Equatable, Codable {
  public let asset: PraxisProvisionAsset
  public let supportedModes: [PraxisTapMode]
  public let summary: String

  public init(asset: PraxisProvisionAsset, supportedModes: [PraxisTapMode], summary: String = "") {
    self.asset = asset
    self.supportedModes = supportedModes
    self.summary = summary
  }
}

public struct PraxisProvisionPlan: Sendable, Equatable, Codable {
  public let request: PraxisProvisionRequest
  public let selectedAssets: [PraxisProvisionAsset]
  public let summary: String
  public let requiresApproval: Bool
  public let verificationPlan: [String]
  public let rollbackPlan: [String]

  public init(
    request: PraxisProvisionRequest,
    selectedAssets: [PraxisProvisionAsset],
    summary: String,
    requiresApproval: Bool = false,
    verificationPlan: [String] = [],
    rollbackPlan: [String] = []
  ) {
    self.request = request
    self.selectedAssets = selectedAssets
    self.summary = summary
    self.requiresApproval = requiresApproval
    self.verificationPlan = verificationPlan
    self.rollbackPlan = rollbackPlan
  }
}
