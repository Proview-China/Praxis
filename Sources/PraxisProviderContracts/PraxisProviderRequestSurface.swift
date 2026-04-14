/// Aggregates provider-backed request surfaces behind one future-extractable seam.
///
/// This boundary exists so higher runtime layers can depend on one provider request surface instead
/// of reaching into individual provider executors directly. It does not own browser, shell, or
/// other non-provider host capabilities.
public protocol PraxisProviderRequestSurfaceProtocol: Sendable {
  var inferenceExecutor: (any PraxisProviderInferenceExecutor)? { get }
  var webSearchExecutor: (any PraxisProviderWebSearchExecutor)? { get }
  var embeddingExecutor: (any PraxisProviderEmbeddingExecutor)? { get }
  var fileStore: (any PraxisProviderFileStore)? { get }
  var batchExecutor: (any PraxisProviderBatchExecutor)? { get }
  var skillRegistry: (any PraxisProviderSkillRegistry)? { get }
  var skillActivator: (any PraxisProviderSkillActivator)? { get }
  var mcpExecutor: (any PraxisProviderMCPExecutor)? { get }
}

/// Default value-type implementation for the aggregated provider request seam.
public struct PraxisProviderRequestSurface: PraxisProviderRequestSurfaceProtocol, Sendable {
  public let inferenceExecutor: (any PraxisProviderInferenceExecutor)?
  public let webSearchExecutor: (any PraxisProviderWebSearchExecutor)?
  public let embeddingExecutor: (any PraxisProviderEmbeddingExecutor)?
  public let fileStore: (any PraxisProviderFileStore)?
  public let batchExecutor: (any PraxisProviderBatchExecutor)?
  public let skillRegistry: (any PraxisProviderSkillRegistry)?
  public let skillActivator: (any PraxisProviderSkillActivator)?
  public let mcpExecutor: (any PraxisProviderMCPExecutor)?

  public init(
    inferenceExecutor: (any PraxisProviderInferenceExecutor)? = nil,
    webSearchExecutor: (any PraxisProviderWebSearchExecutor)? = nil,
    embeddingExecutor: (any PraxisProviderEmbeddingExecutor)? = nil,
    fileStore: (any PraxisProviderFileStore)? = nil,
    batchExecutor: (any PraxisProviderBatchExecutor)? = nil,
    skillRegistry: (any PraxisProviderSkillRegistry)? = nil,
    skillActivator: (any PraxisProviderSkillActivator)? = nil,
    mcpExecutor: (any PraxisProviderMCPExecutor)? = nil
  ) {
    self.inferenceExecutor = inferenceExecutor
    self.webSearchExecutor = webSearchExecutor
    self.embeddingExecutor = embeddingExecutor
    self.fileStore = fileStore
    self.batchExecutor = batchExecutor
    self.skillRegistry = skillRegistry
    self.skillActivator = skillActivator
    self.mcpExecutor = mcpExecutor
  }
}
