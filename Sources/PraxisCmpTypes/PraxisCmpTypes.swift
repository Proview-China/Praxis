import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 CMP 共用对象模型，包括 section/request/package/projection/lineage 基础类型。
// - 冻结跨 CMP 子域共享的标识、状态、优先级和传输标签。
// - 保持这里只放共用语义，不混入 delivery/projection 的具体规则。
// - 文件可继续拆分：CmpIdentifiers.swift、CmpSectionTypes.swift、CmpPackageTypes.swift、CmpLineageTypes.swift。

public enum PraxisCmpTypesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpTypes",
    responsibility: "CMP canonical object model、lineage、section、request、package、snapshot 基础类型。",
    tsModules: [
      "src/agent_core/cmp-types",
    ],
  )
}
