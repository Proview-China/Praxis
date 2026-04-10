import Testing
@testable import PraxisInfraContracts
@testable import PraxisProviderContracts
@testable import PraxisToolingContracts
@testable import PraxisUserIOContracts
@testable import PraxisWorkspaceContracts

// TODO(reboot-plan):
// - Add guard tests to keep the five HostContracts families decoupled from one another.
// - Add minimal protocol-surface tests so business models do not quietly flow back into contracts.
// - This file can later be split into HostContractsBoundaryTests.swift, HostContractsDependencyTests.swift, and HostContractsProtocolSurfaceTests.swift.

struct HostContractsTopologyTests {
  @Test
  func hostContractsSplitIntoProtocolFamilies() {
    #expect(PraxisProviderContractsModule.boundary.name == "PraxisProviderContracts")
    #expect(PraxisWorkspaceContractsModule.boundary.name == "PraxisWorkspaceContracts")
    #expect(PraxisToolingContractsModule.boundary.name == "PraxisToolingContracts")
    #expect(PraxisInfraContractsModule.boundary.name == "PraxisInfraContracts")
    #expect(PraxisUserIOContractsModule.boundary.name == "PraxisUserIOContracts")
  }
}
