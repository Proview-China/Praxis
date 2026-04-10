import Foundation

public protocol PraxisCheckpointCoding: Sendable {
  func encode(_ snapshot: PraxisCheckpointSnapshot) throws -> Data
}

public struct PraxisJSONCheckpointCodec: Sendable {
  public init() {}
}

public struct PraxisCheckpointRecoveryService: Sendable {
  public init() {}
}
