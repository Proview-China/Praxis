public protocol PraxisWorkspaceReader: Sendable {
  func read(_ request: PraxisWorkspaceReadRequest) async throws -> String
}

public protocol PraxisWorkspaceSearcher: Sendable {
  func search(_ request: PraxisWorkspaceSearchRequest) async throws -> [PraxisWorkspaceSearchMatch]
}

public protocol PraxisWorkspaceWriter: Sendable {
  func apply(_ request: PraxisWorkspaceChangeRequest) async throws
}
