import XCTest
@testable import PraxisRuntimeComposition
@testable import PraxisRuntimeFacades
@testable import PraxisRuntimePresentationBridge
@testable import PraxisRuntimeUseCases

// TODO(reboot-plan):
// - 增加 composition/use cases/facades/presentation bridge 的职责守卫测试。
// - 增加 Entry 只能经由 PresentationBridge 进入系统的显式测试。
// - 后续可继续拆分：HostRuntimeBoundaryTests.swift、HostRuntimeDependencyTests.swift、PresentationBridgeRuleTests.swift。

final class HostRuntimeTopologyTests: XCTestCase {
  func testRuntimeSplitIntoFourLayers() {
    XCTAssertEqual(PraxisRuntimeCompositionModule.boundary.name, "PraxisRuntimeComposition")
    XCTAssertEqual(PraxisRuntimeUseCasesModule.boundary.name, "PraxisRuntimeUseCases")
    XCTAssertEqual(PraxisRuntimeFacadesModule.boundary.name, "PraxisRuntimeFacades")
    XCTAssertEqual(PraxisRuntimePresentationBridgeModule.boundary.name, "PraxisRuntimePresentationBridge")
  }

  func testPresentationBridgeBlueprintMatchesSplit() {
    XCTAssertEqual(PraxisRuntimePresentationBridgeModule.bootstrap.hostContractModules.count, 5)
    XCTAssertEqual(PraxisRuntimePresentationBridgeModule.bootstrap.runtimeModules.count, 4)
    XCTAssertTrue(PraxisRuntimePresentationBridgeModule.bootstrap.rules.contains("Entry 只能经由 RuntimePresentationBridge 进入系统。"))
  }
}
