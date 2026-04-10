public struct PraxisProviderWebSearchRequest: Sendable, Equatable, Codable {
  public let query: String
  public let locale: String?

  public init(query: String, locale: String? = nil) {
    self.query = query
    self.locale = locale
  }
}

public struct PraxisProviderWebSearchResult: Sendable, Equatable, Codable {
  public let title: String
  public let snippet: String
  public let url: String

  public init(title: String, snippet: String, url: String) {
    self.title = title
    self.snippet = snippet
    self.url = url
  }
}

public struct PraxisProviderWebSearchResponse: Sendable, Equatable, Codable {
  public let query: String
  public let results: [PraxisProviderWebSearchResult]

  public init(query: String, results: [PraxisProviderWebSearchResult]) {
    self.query = query
    self.results = results
  }
}
