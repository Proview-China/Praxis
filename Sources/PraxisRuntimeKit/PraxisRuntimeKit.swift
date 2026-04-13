import PraxisCoreTypes

/// Boundary metadata for the high-level Swift framework API.
///
/// This target owns caller-friendly runtime construction and common workflow helpers.
/// It does not own transport envelopes, FFI bindings, or host adapter composition rules.
public enum PraxisRuntimeKitModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeKit",
    responsibility: "面向 Swift 调用者的高层 framework API，负责默认 runtime 创建、goal 准备与常用 inspection / run 调用，不暴露 transport envelope。",
    legacyReferences: [
      "src/rax/facade.ts",
      "src/agent_core/runtime.ts",
    ],
  )
}
