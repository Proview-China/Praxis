import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement protocol-layer models such as CapabilityManifest, InvocationContract, BindingSpec, and CapabilityIdentity.
// - Define capability request, response, lifecycle state, and error semantics.
// - Freeze the lowest Capability boundary so planning, results, and catalog do not leak back into contracts.
// - This file can later be split into CapabilityIdentity.swift, CapabilityManifest.swift, InvocationContract.swift, and CapabilityErrors.swift.

public enum PraxisCapabilityContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityContracts",
    responsibility: "capability manifest、binding、invocation contract 与共享协议。",
    tsModules: [
      "src/agent_core/capability-types",
      "src/agent_core/capability-model",
    ],
  )
}
