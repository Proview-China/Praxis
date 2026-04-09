import PraxisCapabilityPlanning
import PraxisCmpProjection
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisTapTypes

// TODO(reboot-plan):
// - 实现 ContextPackage、DeliveryPlan、DispatchInstruction、FallbackPlan 等模型。
// - 实现 active/passive delivery、dispatch routing 和历史回退规则。
// - 保证 delivery 只给出投递计划，不直接触碰 bus 或 DB。
// - 文件可继续拆分：ContextPackage.swift、DeliveryPlan.swift、DispatchInstruction.swift、DeliveryFallback.swift。

public enum PraxisCmpDeliveryModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpDelivery",
    responsibility: "CMP delivery、dispatch instruction、active/passive flow 与 historical fallback planning。",
    tsModules: [
      "src/agent_core/cmp-runtime/delivery.ts",
      "src/agent_core/cmp-runtime/delivery-routing.ts",
      "src/agent_core/cmp-runtime/passive-delivery.ts",
      "src/agent_core/cmp-runtime/active-line.ts",
    ],
  )
}
