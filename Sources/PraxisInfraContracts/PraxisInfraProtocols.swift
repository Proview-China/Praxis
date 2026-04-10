import PraxisCmpTypes

public protocol PraxisCheckpointStoreContract: Sendable {
  func save(_ record: PraxisCheckpointRecord) async throws
}

public protocol PraxisJournalStoreContract: Sendable {
  func append(_ batch: PraxisJournalRecordBatch) async throws
}

public protocol PraxisProjectionStoreContract: Sendable {
  func describe(projectId: String) async throws -> PraxisProjectionRecordDescriptor
}

public protocol PraxisMessageBusContract: Sendable {
  func publish(_ message: PraxisPublishedMessage) async throws
}

public protocol PraxisLineageStoreContract: Sendable {
  func describe(lineageID: PraxisCmpLineageID) async throws -> String
}
