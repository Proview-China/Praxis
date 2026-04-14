public protocol PraxisProviderWebSearchExecutor: Sendable {
  func search(_ request: PraxisProviderWebSearchRequest) async throws -> PraxisProviderWebSearchResponse
}
