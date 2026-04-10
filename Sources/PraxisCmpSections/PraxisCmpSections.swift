import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement ingest contracts, section builders, section lowering, and ownership rules.
// - Implement context slicing, trimming, visibility boundaries, and section rule evaluation.
// - Keep sections focused on structuring context without taking on projection or delivery side effects directly.
// - This file can later be split into SectionIngress.swift, SectionBuilder.swift, SectionLowering.swift, and SectionRules.swift.

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
