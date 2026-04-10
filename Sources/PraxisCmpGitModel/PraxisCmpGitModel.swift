import PraxisCmpProjection
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement models such as GitBranchFamily, GitRefLifecycle, LineageRule, and GitSyncPlan.
// - Implement pure rules for ref lifecycles, branch lineage, and sync planning.
// - Keep this target as a Git planner/model layer rather than a concrete git CLI or libgit implementation.
// - This file can later be split into GitBranchFamily.swift, GitRefLifecycle.swift, GitSyncPlan.swift, and GitGovernance.swift.

public enum PraxisCmpGitModelModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpGitModel",
    responsibility: "CMP git branch family、refs lifecycle、lineage governance 与 sync planning model。",
    tsModules: [
      "src/agent_core/cmp-git",
    ],
  )
}
