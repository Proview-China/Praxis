import PraxisCapabilityPlanning
import PraxisCmpProjection
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisTapTypes

// TODO(reboot-plan):
// - Implement models such as ContextPackage, DeliveryPlan, DispatchInstruction, and FallbackPlan.
// - Implement active/passive delivery, dispatch routing, and historical fallback rules.
// - Keep delivery focused on producing dispatch plans without touching the bus or DB directly.
// - This file can later be split into ContextPackage.swift, DeliveryPlan.swift, DispatchInstruction.swift, and DeliveryFallback.swift.

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
