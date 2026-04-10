public protocol PraxisJournalAppending: Sendable {
  func append(_ event: PraxisJournalEvent) async throws
}

public protocol PraxisJournalReading: Sendable {
  func read(after cursor: PraxisJournalCursor?) async throws -> PraxisJournalSlice
}

public actor PraxisInMemoryJournalBuffer {
  public private(set) var events: [PraxisJournalEvent]

  public init(events: [PraxisJournalEvent] = []) {
    self.events = events
  }
}
