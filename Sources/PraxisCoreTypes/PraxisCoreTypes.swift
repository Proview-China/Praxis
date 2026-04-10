// TODO(reboot-plan):
// - 继续把跨子域公共约定稳定在 CoreTypes，不向高层回灌领域语义。
// - 当多个 target 出现重复基础值对象时，优先下沉到独立文件，而不是回并成 shared/util。

public enum PraxisCoreTypesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCoreTypes",
    responsibility: "共享基础类型、模块边界描述与跨子域共用标识。",
    tsModules: [
      "src/agent_core/types",
      "src/agent_core/cmp-types",
      "src/agent_core/ta-pool-types",
    ],
  )
}
