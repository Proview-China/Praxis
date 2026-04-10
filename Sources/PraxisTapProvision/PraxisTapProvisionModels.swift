import PraxisCapabilityContracts
import PraxisTapTypes

public struct PraxisProvisionRequest: Sendable, Equatable, Codable {
  public let kind: PraxisTapProvisionKind
  public let summary: String

  public init(kind: PraxisTapProvisionKind, summary: String) {
    self.kind = kind
    self.summary = summary
  }
}

public struct PraxisProvisionAsset: Sendable, Equatable, Codable {
  public let name: String
  public let capabilityID: PraxisCapabilityID?

  public init(name: String, capabilityID: PraxisCapabilityID?) {
    self.name = name
    self.capabilityID = capabilityID
  }
}

public struct PraxisProvisionRegistryEntry: Sendable, Equatable, Codable {
  public let asset: PraxisProvisionAsset
  public let supportedModes: [PraxisTapMode]

  public init(asset: PraxisProvisionAsset, supportedModes: [PraxisTapMode]) {
    self.asset = asset
    self.supportedModes = supportedModes
  }
}

public struct PraxisProvisionPlan: Sendable, Equatable, Codable {
  public let request: PraxisProvisionRequest
  public let selectedAssets: [PraxisProvisionAsset]

  public init(request: PraxisProvisionRequest, selectedAssets: [PraxisProvisionAsset]) {
    self.request = request
    self.selectedAssets = selectedAssets
  }
}
