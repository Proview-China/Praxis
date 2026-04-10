import PraxisCheckpoint
import PraxisCmpTypes
import PraxisJournal

public struct PraxisCheckpointRecord: Sendable, Equatable, Codable {
  public let pointer: PraxisCheckpointPointer
  public let snapshot: PraxisCheckpointSnapshot

  public init(pointer: PraxisCheckpointPointer, snapshot: PraxisCheckpointSnapshot) {
    self.pointer = pointer
    self.snapshot = snapshot
  }
}

public struct PraxisJournalRecordBatch: Sendable, Equatable, Codable {
  public let events: [PraxisJournalEvent]

  public init(events: [PraxisJournalEvent]) {
    self.events = events
  }
}

public struct PraxisProjectionRecordDescriptor: Sendable, Equatable, Codable {
  public let projectionID: PraxisCmpProjectionID
  public let summary: String

  public init(projectionID: PraxisCmpProjectionID, summary: String) {
    self.projectionID = projectionID
    self.summary = summary
  }
}

public struct PraxisPublishedMessage: Sendable, Equatable, Codable {
  public let topic: String
  public let payloadSummary: String

  public init(topic: String, payloadSummary: String) {
    self.topic = topic
    self.payloadSummary = payloadSummary
  }
}
