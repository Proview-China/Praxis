import PraxisCmpProjection
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 GitBranchFamily、GitRefLifecycle、LineageRule、GitSyncPlan 等模型。
// - 实现 refs 生命周期、分支谱系和同步规划的纯规则。
// - 保持这里是 Git planner/model，不落具体 git CLI 或 libgit 实现。
// - 文件可继续拆分：GitBranchFamily.swift、GitRefLifecycle.swift、GitSyncPlan.swift、GitGovernance.swift。

public enum PraxisCmpGitModelModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpGitModel",
    responsibility: "CMP git branch family、refs lifecycle、lineage governance 与 sync planning model。",
    tsModules: [
      "src/agent_core/cmp-git",
    ],
  )
}
