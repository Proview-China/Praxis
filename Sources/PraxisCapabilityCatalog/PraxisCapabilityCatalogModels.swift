import PraxisCapabilityContracts
import PraxisCapabilityPlanning

public struct PraxisCapabilityFamily: Sendable, Equatable, Codable {
  public let name: String
  public let capabilityIDs: [PraxisCapabilityID]

  public init(name: String, capabilityIDs: [PraxisCapabilityID]) {
    self.name = name
    self.capabilityIDs = capabilityIDs
  }
}

public struct PraxisCapabilityCatalogEntry: Sendable, Equatable, Codable {
  public let manifest: PraxisCapabilityManifest
  public let latestSelection: PraxisCapabilitySelection?

  public init(manifest: PraxisCapabilityManifest, latestSelection: PraxisCapabilitySelection?) {
    self.manifest = manifest
    self.latestSelection = latestSelection
  }
}

public struct PraxisCapabilityCatalogSnapshot: Sendable, Equatable, Codable {
  public let entries: [PraxisCapabilityCatalogEntry]
  public let families: [PraxisCapabilityFamily]

  public init(entries: [PraxisCapabilityCatalogEntry], families: [PraxisCapabilityFamily]) {
    self.entries = entries
    self.families = families
  }
}
