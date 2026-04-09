import PraxisCapabilityCatalog
import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCapabilityResults
import PraxisCheckpoint
import PraxisCmpDbModel
import PraxisCmpDelivery
import PraxisCmpFiveAgent
import PraxisCmpGitModel
import PraxisCmpMqModel
import PraxisCmpProjection
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisGoal
import PraxisInfraContracts
import PraxisJournal
import PraxisProviderContracts
import PraxisRun
import PraxisSession
import PraxisState
import PraxisTapAvailability
import PraxisTapGovernance
import PraxisTapProvision
import PraxisTapReview
import PraxisTapRuntime
import PraxisTapTypes
import PraxisToolingContracts
import PraxisTransition
import PraxisUserIOContracts
import PraxisWorkspaceContracts

// TODO(reboot-plan):
// - 实现 composition root、dependency graph、adapter registry 和 bootstrap validation。
// - 定义 Core 子域与五类 HostContracts 的组装方式，但不把业务规则再次吸进来。
// - 明确 runtime 中哪些依赖是必选、可替换、可测试 fake。
// - 文件可继续拆分：CompositionRoot.swift、DependencyGraph.swift、AdapterRegistry.swift、BootstrapValidation.swift。

public enum PraxisRuntimeCompositionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeComposition",
    responsibility: "composition root 与跨域装配边界。",
    tsModules: [
      "src/agent_core/runtime.ts",
      "src/rax/runtime.ts",
    ],
  )
}
