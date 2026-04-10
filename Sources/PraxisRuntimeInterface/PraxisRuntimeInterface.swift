import PraxisCoreTypes

// TODO(reboot-plan):
// - Keep this target host-agnostic and export-friendly; do not absorb CLI, SwiftUI, or ABI details.
// - Use plain Codable request/response/event models so future FFI layers can map them into stable language bindings.
// - Keep construction and host adapter wiring outside this target; composition still belongs to HostRuntime composition/bridge layers.

public enum PraxisRuntimeInterfaceModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeInterface",
    responsibility: "宿主无关的统一 runtime request/response/event surface，供未来导出层与跨语言绑定复用。",
    tsModules: [
      "src/rax/facade.ts",
      "src/agent_core/live-agent-chat/shared.ts",
    ],
  )
}
