public struct PraxisWorkspaceReadRequest: Sendable, Equatable, Codable {
  public let path: String

  public init(path: String) {
    self.path = path
  }
}

public struct PraxisWorkspaceSearchRequest: Sendable, Equatable, Codable {
  public let query: String

  public init(query: String) {
    self.query = query
  }
}

public struct PraxisWorkspaceSearchMatch: Sendable, Equatable, Codable {
  public let path: String
  public let summary: String

  public init(path: String, summary: String) {
    self.path = path
    self.summary = summary
  }
}

public struct PraxisWorkspaceChangeRequest: Sendable, Equatable, Codable {
  public let changeSummary: String

  public init(changeSummary: String) {
    self.changeSummary = changeSummary
  }
}
