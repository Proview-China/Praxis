import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement shared CMP object models, including base types for section, request, package, projection, and lineage.
// - Freeze identifiers, state tags, priorities, and transport labels shared across CMP subdomains.
// - Keep only shared semantics here without mixing in delivery or projection-specific rules.
// - This file can later be split into CmpIdentifiers.swift, CmpSectionTypes.swift, CmpPackageTypes.swift, and CmpLineageTypes.swift.

public enum PraxisCmpTypesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpTypes",
    responsibility: "CMP canonical object model、lineage、section、request、package、snapshot 基础类型。",
    tsModules: [
      "src/agent_core/cmp-types",
    ],
  )
}
