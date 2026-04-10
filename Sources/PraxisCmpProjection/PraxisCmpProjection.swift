import PraxisCheckpoint
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement models such as ProjectionRecord, MaterializationPlan, VisibilityPolicy, and ProjectionRecovery.
// - Implement projection rebuild, runtime snapshot, visibility enforcement, and recovery rules.
// - Keep projection focused on how context is projected instead of calling stores directly.
// - This file can later be split into ProjectionRecord.swift, Materializer.swift, VisibilityPolicy.swift, and ProjectionRecovery.swift.

public enum PraxisCmpProjectionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpProjection",
    responsibility: "CMP projection、materialization、visibility、runtime snapshot 与 recovery model。",
    tsModules: [
      "src/agent_core/cmp-runtime/materialization.ts",
      "src/agent_core/cmp-runtime/visibility-enforcement.ts",
      "src/agent_core/cmp-runtime/runtime-snapshot.ts",
      "src/agent_core/cmp-runtime/runtime-recovery.ts",
    ],
  )
}
