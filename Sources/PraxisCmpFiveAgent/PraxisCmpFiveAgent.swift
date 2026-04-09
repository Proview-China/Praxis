import PraxisCapabilityPlanning
import PraxisCmpDelivery
import PraxisCmpProjection
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisTapReview
import PraxisTapRuntime

// TODO(reboot-plan):
// - 实现 ICMA / iterator / checker / dbagent / dispatcher 的角色模型与交互协议。
// - 实现多 agent hand-off、职责边界、窗口约束和上下文分配规则。
// - 保持这里描述 five-agent 协议，不直接承担 runtime composition。
// - 文件可继续拆分：FiveAgentRoles.swift、FiveAgentProtocol.swift、FiveAgentHandOff.swift、FiveAgentPolicies.swift。

public enum PraxisCmpFiveAgentModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpFiveAgent",
    responsibility: "CMP five-agent role protocol 与 ICMA/iterator/checker/dbagent/dispatcher 纯职责模型。",
    tsModules: [
      "src/agent_core/cmp-five-agent",
    ],
  )
}
