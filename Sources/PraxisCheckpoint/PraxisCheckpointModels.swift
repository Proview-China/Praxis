import PraxisCoreTypes
import PraxisJournal
import PraxisSession

public struct PraxisCheckpointID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisCheckpointPointer: Sendable, Equatable, Codable {
  public let checkpointID: PraxisCheckpointID
  public let sessionID: PraxisSessionID

  public init(checkpointID: PraxisCheckpointID, sessionID: PraxisSessionID) {
    self.checkpointID = checkpointID
    self.sessionID = sessionID
  }
}

public struct PraxisCheckpointSnapshot: Sendable, Equatable, Codable {
  public let id: PraxisCheckpointID
  public let sessionID: PraxisSessionID
  public let lastCursor: PraxisJournalCursor?

  public init(id: PraxisCheckpointID, sessionID: PraxisSessionID, lastCursor: PraxisJournalCursor?) {
    self.id = id
    self.sessionID = sessionID
    self.lastCursor = lastCursor
  }
}

public struct PraxisRecoveryEnvelope: Sendable, Equatable, Codable {
  public let pointer: PraxisCheckpointPointer
  public let snapshot: PraxisCheckpointSnapshot

  public init(pointer: PraxisCheckpointPointer, snapshot: PraxisCheckpointSnapshot) {
    self.pointer = pointer
    self.snapshot = snapshot
  }
}
