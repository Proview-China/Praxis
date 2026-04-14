// TODO(reboot-plan):
// - Keep stabilizing cross-domain shared conventions inside CoreTypes without reintroducing higher-level domain semantics.
// - When multiple targets repeat the same base value objects, move them into dedicated files instead of folding them back into shared/util buckets.

/// Boundary metadata for the `PraxisCoreTypes` target.
public enum PraxisCoreTypesModule {
  /// Describes the responsibility and historical module mapping for this target.
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCoreTypes",
    responsibility: "共享基础类型、模块边界描述与跨子域共用标识。",
    legacyReferences: [
      "src/agent_core/types",
      "src/agent_core/cmp-types",
      "src/agent_core/ta-pool-types",
    ],
  )
}
