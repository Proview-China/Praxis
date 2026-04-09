import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 ingest contract、section builder、section lowering 与 ownership rules。
// - 实现上下文切片创建、裁剪、可见性边界和 section rule evaluation。
// - 保证 sections 只负责上下文结构化，不直接承担 projection/delivery 的副作用。
// - 文件可继续拆分：SectionIngress.swift、SectionBuilder.swift、SectionLowering.swift、SectionRules.swift。

public enum PraxisCmpSectionsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpSections",
    responsibility: "CMP ingest、section creation、section lowering 与 rules。",
    tsModules: [
      "src/agent_core/cmp-runtime/section-ingress.ts",
      "src/agent_core/cmp-runtime/section-rules.ts",
      "src/agent_core/cmp-runtime/ingress-contract.ts",
    ],
  )
}
