import Testing
@testable import PraxisCapabilityCatalog
@testable import PraxisCapabilityContracts
@testable import PraxisCapabilityPlanning
@testable import PraxisCapabilityResults

// TODO(reboot-plan):
// - Add one-way dependency tests for the Capability domain to prevent reverse edges into TAP, CMP, or Host layers.
// - Add blueprint guards for the four-way split across contracts, planning, results, and catalog.
// - This file can later be split into CapabilityBoundaryTests.swift, CapabilityDependencyTests.swift, and CapabilityBlueprintTests.swift.

struct CapabilityTopologyTests {
  @Test
  func capabilityDomainSplitIntoFourSubmodules() {
    #expect(PraxisCapabilityContractsModule.boundary.name == "PraxisCapabilityContracts")
    #expect(PraxisCapabilityPlanningModule.boundary.name == "PraxisCapabilityPlanning")
    #expect(PraxisCapabilityResultsModule.boundary.name == "PraxisCapabilityResults")
    #expect(PraxisCapabilityCatalogModule.boundary.name == "PraxisCapabilityCatalog")
  }
}
