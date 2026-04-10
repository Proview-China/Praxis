public struct PraxisSessionLifecycleService: Sendable {
  public init() {}
}

public actor PraxisSessionRegistry {
  public private(set) var sessions: [PraxisSessionHeader]

  public init(sessions: [PraxisSessionHeader] = []) {
    self.sessions = sessions
  }
}
