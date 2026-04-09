import XCTest
@testable import PraxisCapabilityCatalog
@testable import PraxisCapabilityContracts
@testable import PraxisCapabilityPlanning
@testable import PraxisCapabilityResults

// TODO(reboot-plan):
// - 增加 Capability 子域单向依赖测试，防止反向依赖 TAP/CMP/Host。
// - 增加 contracts/planning/results/catalog 四分职责的 blueprint 守卫。
// - 后续可继续拆分：CapabilityBoundaryTests.swift、CapabilityDependencyTests.swift、CapabilityBlueprintTests.swift。

final class CapabilityTopologyTests: XCTestCase {
  func testCapabilityDomainSplitIntoFourSubmodules() {
    XCTAssertEqual(PraxisCapabilityContractsModule.boundary.name, "PraxisCapabilityContracts")
    XCTAssertEqual(PraxisCapabilityPlanningModule.boundary.name, "PraxisCapabilityPlanning")
    XCTAssertEqual(PraxisCapabilityResultsModule.boundary.name, "PraxisCapabilityResults")
    XCTAssertEqual(PraxisCapabilityCatalogModule.boundary.name, "PraxisCapabilityCatalog")
  }
}
