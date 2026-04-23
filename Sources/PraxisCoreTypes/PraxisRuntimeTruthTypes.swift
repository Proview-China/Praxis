/// Host-neutral runtime smoke gate identifiers shared across runtime layers.
///
/// This type captures stable gate semantics only. It does not carry
/// presentation wording, platform-specific state, or adapter payloads.
public enum PraxisRuntimeSmokeGate: String, Sendable, Equatable, Codable {
  case host
  case memoryStore = "memory-store"
  case semanticSearch = "semantic-search"
  case providerConversation = "provider-conversation"
  case browserGrounding = "browser-grounding"
}

/// Host-neutral runtime truth-layer statuses used by smoke snapshots.
///
/// This type is intentionally minimal and only covers statuses currently
/// exposed by runtime smoke checks.
public enum PraxisRuntimeTruthLayerStatus: String, Sendable, Equatable, Codable {
  case ready
  case degraded
  case missing
}
