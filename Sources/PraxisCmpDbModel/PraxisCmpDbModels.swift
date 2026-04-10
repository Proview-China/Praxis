import PraxisCmpTypes

public struct PraxisStorageTopology: Sendable, Equatable, Codable {
  public let schemaName: String
  public let tableNames: [String]

  public init(schemaName: String, tableNames: [String]) {
    self.schemaName = schemaName
    self.tableNames = tableNames
  }
}

public struct PraxisProjectionPersistencePlan: Sendable, Equatable, Codable {
  public let projectionID: PraxisCmpProjectionID
  public let topology: PraxisStorageTopology

  public init(projectionID: PraxisCmpProjectionID, topology: PraxisStorageTopology) {
    self.projectionID = projectionID
    self.topology = topology
  }
}

public struct PraxisPackagePersistencePlan: Sendable, Equatable, Codable {
  public let packageID: PraxisCmpPackageID
  public let topology: PraxisStorageTopology

  public init(packageID: PraxisCmpPackageID, topology: PraxisStorageTopology) {
    self.packageID = packageID
    self.topology = topology
  }
}

public struct PraxisDeliveryPersistencePlan: Sendable, Equatable, Codable {
  public let deliverySummary: String
  public let topology: PraxisStorageTopology

  public init(deliverySummary: String, topology: PraxisStorageTopology) {
    self.deliverySummary = deliverySummary
    self.topology = topology
  }
}
