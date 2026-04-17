import PraxisCoreTypes

// Boundary note:
// - Keep this target host-agnostic and export-friendly; do not absorb CLI, SwiftUI, terminal,
//   platform, or provider raw payload details.
// - Use plain Codable request/response/event models so future FFI layers can map them into stable
//   language bindings without presentation-specific shims.
// - Keep construction and host adapter wiring outside this target; composition still belongs to
//   HostRuntime composition / gateway layers.

/// Describes the exported host-neutral runtime interface boundary.
///
/// This target owns stable encoded request/response/event shapes that can be reused by
/// `PraxisFFI` and future language bindings without pulling in presentation concerns.
public enum PraxisRuntimeInterfaceModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeInterface",
    responsibility: "宿主无关的统一 runtime request/response/event surface，供未来导出层与跨语言绑定复用。",
    legacyReferences: [
      "src/rax/facade.ts",
      "src/agent_core/live-agent-chat/shared.ts",
    ],
  )
}
