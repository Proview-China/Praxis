import PraxisSession

public struct PraxisJournalEvent: Sendable, Equatable, Codable {
  public let sequence: Int
  public let sessionID: PraxisSessionID
  public let summary: String

  public init(sequence: Int, sessionID: PraxisSessionID, summary: String) {
    self.sequence = sequence
    self.sessionID = sessionID
    self.summary = summary
  }
}

public struct PraxisJournalCursor: Sendable, Equatable, Codable {
  public let sequence: Int

  public init(sequence: Int) {
    self.sequence = sequence
  }
}

public struct PraxisJournalSlice: Sendable, Equatable, Codable {
  public let events: [PraxisJournalEvent]
  public let nextCursor: PraxisJournalCursor?

  public init(events: [PraxisJournalEvent], nextCursor: PraxisJournalCursor?) {
    self.events = events
    self.nextCursor = nextCursor
  }
}
