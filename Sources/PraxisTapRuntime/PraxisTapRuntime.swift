import PraxisCapabilityPlanning
import PraxisCheckpoint
import PraxisCoreTypes
import PraxisSession
import PraxisTapGovernance
import PraxisTapProvision
import PraxisTapReview
import PraxisTapTypes

// TODO(reboot-plan):
// - The current implementation already covers the minimal coordination surface for control-plane state, replay policy, pending replays, and human-gate events.
// - Next, add checkpoint/recovery, activation-attempt ledgers, and fuller state evolution across review, provision, and runtime.
// - Keep this target focused on TAP runtime semantics without absorbing provider, workspace, or UI side effects.
// - This file can later be split into ControlPlaneState.swift, ActivationLifecycle.swift, ReplayPolicy.swift, and TapRuntimeSnapshot.swift.

public enum PraxisTapRuntimeModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapRuntime",
    responsibility: "control plane、activation lifecycle、human gate、replay、governance snapshot 与 recovery 模型。",
    legacyReferences: [
      "src/agent_core/ta-pool-runtime",
    ],
  )
}
