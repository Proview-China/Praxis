import PraxisCapabilityPlanning
import PraxisCheckpoint
import PraxisCoreTypes
import PraxisSession
import PraxisTapGovernance
import PraxisTapProvision
import PraxisTapReview
import PraxisTapTypes

// TODO(reboot-plan):
// - 实现 TapControlPlaneState、ActivationLifecycle、ReplayPolicy、TapRuntimeSnapshot 等模型。
// - 实现 review/provision/checkpoint 之间的运行期协调和恢复规则。
// - 保持这里是 TAP 运行期语义，不吸收 provider、workspace、UI 副作用。
// - 文件可继续拆分：ControlPlaneState.swift、ActivationLifecycle.swift、ReplayPolicy.swift、TapRuntimeSnapshot.swift。

public enum PraxisTapRuntimeModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapRuntime",
    responsibility: "control plane、activation lifecycle、human gate、replay、governance snapshot 与 recovery 模型。",
    tsModules: [
      "src/agent_core/ta-pool-runtime",
      "src/agent_core/ta-pool-safety",
    ],
  )
}
