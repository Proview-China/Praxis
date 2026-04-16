import PraxisCoreTypes

/// Aggregates provider-backed request surfaces behind one future-extractable seam.
///
/// This boundary exists so higher runtime layers can depend on one provider request surface instead
/// of reaching into individual provider executors directly. It does not own browser, shell, or
/// other non-provider host capabilities.
public protocol PraxisProviderRequestSurfaceProtocol: Sendable {
  var supportsInference: Bool { get }
  var supportsWebSearch: Bool { get }
  var supportsEmbedding: Bool { get }
  var supportsFileUpload: Bool { get }
  var supportsBatchSubmission: Bool { get }
  var supportsSkillRegistry: Bool { get }
  var supportsSkillActivation: Bool { get }
  var supportsMCPToolRegistry: Bool { get }
  var supportsToolCalls: Bool { get }

  /// Runs one provider inference request through the aggregated surface.
  ///
  /// - Parameter request: Normalized inference request.
  /// - Returns: Normalized inference response.
  /// - Throws: `PraxisError.dependencyMissing` when no inference backend is wired.
  func infer(_ request: PraxisProviderInferenceRequest) async throws -> PraxisProviderInferenceResponse

  /// Runs one provider web-search request through the aggregated surface.
  ///
  /// - Parameter request: Normalized web-search request.
  /// - Returns: Normalized web-search response.
  /// - Throws: `PraxisError.dependencyMissing` when no web-search backend is wired.
  func search(_ request: PraxisProviderWebSearchRequest) async throws -> PraxisProviderWebSearchResponse

  /// Runs one provider embedding request through the aggregated surface.
  ///
  /// - Parameter request: Normalized embedding request.
  /// - Returns: Normalized embedding response.
  /// - Throws: `PraxisError.dependencyMissing` when no embedding backend is wired.
  func embed(_ request: PraxisProviderEmbeddingRequest) async throws -> PraxisProviderEmbeddingResponse

  /// Uploads one provider file payload through the aggregated surface.
  ///
  /// - Parameter request: Normalized file upload request.
  /// - Returns: File upload receipt.
  /// - Throws: `PraxisError.dependencyMissing` when no file store is wired.
  func upload(_ request: PraxisProviderFileUploadRequest) async throws -> PraxisProviderFileUploadReceipt

  /// Enqueues one provider batch request through the aggregated surface.
  ///
  /// - Parameter request: Normalized batch request.
  /// - Returns: Batch submission receipt.
  /// - Throws: `PraxisError.dependencyMissing` when no batch backend is wired.
  func enqueue(_ request: PraxisProviderBatchRequest) async throws -> PraxisProviderBatchReceipt

  /// Lists provider skill keys through the aggregated surface.
  ///
  /// - Returns: Stable provider skill keys.
  /// - Throws: `PraxisError.dependencyMissing` when no skill registry is wired.
  func listSkillKeys() async throws -> [String]

  /// Activates one provider skill through the aggregated surface.
  ///
  /// - Parameter request: Normalized skill activation request.
  /// - Returns: Skill activation receipt.
  /// - Throws: `PraxisError.dependencyMissing` when no skill activator is wired.
  func activate(_ request: PraxisProviderSkillActivationRequest) async throws -> PraxisProviderSkillActivationReceipt

  /// Lists provider MCP tool names through the aggregated surface.
  ///
  /// - Returns: Stable provider MCP tool names.
  /// - Throws: `PraxisError.dependencyMissing` when no MCP tool registry is wired.
  func listToolNames() async throws -> [String]

  /// Calls one provider MCP tool through the aggregated surface.
  ///
  /// - Parameter request: Normalized MCP tool-call request.
  /// - Returns: Tool-call receipt.
  /// - Throws: `PraxisError.dependencyMissing` when no MCP executor is wired.
  func callTool(_ request: PraxisProviderMCPToolCallRequest) async throws -> PraxisProviderMCPToolCallReceipt
}

/// Default value-type implementation for the aggregated provider request seam.
public struct PraxisProviderRequestSurface: PraxisProviderRequestSurfaceProtocol, Sendable {
  private let inferenceExecutor: (any PraxisProviderInferenceExecutor)?
  private let webSearchExecutor: (any PraxisProviderWebSearchExecutor)?
  private let embeddingExecutor: (any PraxisProviderEmbeddingExecutor)?
  private let fileStore: (any PraxisProviderFileStore)?
  private let batchExecutor: (any PraxisProviderBatchExecutor)?
  private let skillRegistry: (any PraxisProviderSkillRegistry)?
  private let skillActivator: (any PraxisProviderSkillActivator)?
  private let mcpToolRegistry: (any PraxisProviderMCPToolRegistry)?
  private let mcpExecutor: (any PraxisProviderMCPExecutor)?

  public init(
    inferenceExecutor: (any PraxisProviderInferenceExecutor)? = nil,
    webSearchExecutor: (any PraxisProviderWebSearchExecutor)? = nil,
    embeddingExecutor: (any PraxisProviderEmbeddingExecutor)? = nil,
    fileStore: (any PraxisProviderFileStore)? = nil,
    batchExecutor: (any PraxisProviderBatchExecutor)? = nil,
    skillRegistry: (any PraxisProviderSkillRegistry)? = nil,
    skillActivator: (any PraxisProviderSkillActivator)? = nil,
    mcpToolRegistry: (any PraxisProviderMCPToolRegistry)? = nil,
    mcpExecutor: (any PraxisProviderMCPExecutor)? = nil
  ) {
    self.inferenceExecutor = inferenceExecutor
    self.webSearchExecutor = webSearchExecutor
    self.embeddingExecutor = embeddingExecutor
    self.fileStore = fileStore
    self.batchExecutor = batchExecutor
    self.skillRegistry = skillRegistry
    self.skillActivator = skillActivator
    self.mcpToolRegistry = mcpToolRegistry
    self.mcpExecutor = mcpExecutor
  }

  public var supportsInference: Bool {
    inferenceExecutor != nil
  }

  public var supportsWebSearch: Bool {
    webSearchExecutor != nil
  }

  public var supportsEmbedding: Bool {
    embeddingExecutor != nil
  }

  public var supportsFileUpload: Bool {
    fileStore != nil
  }

  public var supportsBatchSubmission: Bool {
    batchExecutor != nil
  }

  public var supportsSkillRegistry: Bool {
    skillRegistry != nil
  }

  public var supportsSkillActivation: Bool {
    skillActivator != nil
  }

  public var supportsMCPToolRegistry: Bool {
    mcpToolRegistry != nil
  }

  public var supportsToolCalls: Bool {
    mcpToolRegistry != nil && mcpExecutor != nil
  }

  public func infer(_ request: PraxisProviderInferenceRequest) async throws -> PraxisProviderInferenceResponse {
    let executor = try requireDependency(
      inferenceExecutor,
      errorMessage: "Provider request surface requires an inference executor."
    )
    return try await executor.infer(request)
  }

  public func search(_ request: PraxisProviderWebSearchRequest) async throws -> PraxisProviderWebSearchResponse {
    let executor = try requireDependency(
      webSearchExecutor,
      errorMessage: "Provider request surface requires a web search executor."
    )
    return try await executor.search(request)
  }

  public func embed(_ request: PraxisProviderEmbeddingRequest) async throws -> PraxisProviderEmbeddingResponse {
    let executor = try requireDependency(
      embeddingExecutor,
      errorMessage: "Provider request surface requires an embedding executor."
    )
    return try await executor.embed(request)
  }

  public func upload(_ request: PraxisProviderFileUploadRequest) async throws -> PraxisProviderFileUploadReceipt {
    let store = try requireDependency(
      fileStore,
      errorMessage: "Provider request surface requires a file store."
    )
    return try await store.upload(request)
  }

  public func enqueue(_ request: PraxisProviderBatchRequest) async throws -> PraxisProviderBatchReceipt {
    let executor = try requireDependency(
      batchExecutor,
      errorMessage: "Provider request surface requires a batch executor."
    )
    return try await executor.enqueue(request)
  }

  public func listSkillKeys() async throws -> [String] {
    let registry = try requireDependency(
      skillRegistry,
      errorMessage: "Provider request surface requires a skill registry."
    )
    return try await registry.listSkillKeys()
  }

  public func activate(
    _ request: PraxisProviderSkillActivationRequest
  ) async throws -> PraxisProviderSkillActivationReceipt {
    let activator = try requireDependency(
      skillActivator,
      errorMessage: "Provider request surface requires a skill activator."
    )
    return try await activator.activate(request)
  }

  public func listToolNames() async throws -> [String] {
    let registry = try requireDependency(
      mcpToolRegistry,
      errorMessage: "Provider request surface requires an MCP tool registry."
    )
    return try await registry.listToolNames()
  }

  public func callTool(_ request: PraxisProviderMCPToolCallRequest) async throws -> PraxisProviderMCPToolCallReceipt {
    let executor = try requireDependency(
      mcpExecutor,
      errorMessage: "Provider request surface requires an MCP executor."
    )
    return try await executor.callTool(request)
  }

  private func requireDependency<Dependency>(
    _ dependency: Dependency?,
    errorMessage: String
  ) throws -> Dependency {
    guard let dependency else {
      throw PraxisError.dependencyMissing(errorMessage)
    }
    return dependency
  }
}
