public struct PraxisPromptRequest: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}

public struct PraxisPromptResponse: Sendable, Equatable, Codable {
  public let content: String

  public init(content: String) {
    self.content = content
  }
}

public struct PraxisPermissionRequest: Sendable, Equatable, Codable {
  public let scope: String

  public init(scope: String) {
    self.scope = scope
  }
}

public struct PraxisTerminalEvent: Sendable, Equatable, Codable {
  public let title: String
  public let detail: String

  public init(title: String, detail: String) {
    self.title = title
    self.detail = detail
  }
}

public struct PraxisConversationPresentation: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}
