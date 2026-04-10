import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement the capability catalog, family registry, baseline set, and discoverability models.
// - Implement the rules that build catalog and filtered views from manifest and planning data.
// - Keep catalog focused on describing what capabilities exist in the system, not on executing them.
// - This file can later be split into CapabilityCatalogModels.swift, CapabilityCatalogBuilder.swift, CapabilityFamilyRegistry.swift, CapabilityDiscoveryPolicy.swift, and CapabilityCatalogMPModels.swift.

public enum PraxisCapabilityCatalogModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityCatalog",
    responsibility: "capability package、baseline capability sets 与 family catalog。",
    tsModules: [
      "src/agent_core/capability-package",
      "src/agent_core/capability-package/mp-family-capability-package.ts",
    ],
  )
}
