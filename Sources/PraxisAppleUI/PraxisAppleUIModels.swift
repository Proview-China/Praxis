public enum PraxisAppleRoute: String, Sendable, Codable {
  case architecture
  case runs
  case sessions
}

public struct PraxisRunDashboardViewState: Sendable, Equatable {
  public let title: String
  public let summary: String

  public init(title: String, summary: String) {
    self.title = title
    self.summary = summary
  }
}

public struct PraxisSessionListViewState: Sendable, Equatable {
  public let title: String
  public let items: [String]

  public init(title: String, items: [String]) {
    self.title = title
    self.items = items
  }
}
