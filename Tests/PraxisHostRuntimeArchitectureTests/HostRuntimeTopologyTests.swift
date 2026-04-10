import Testing
@testable import PraxisRuntimeComposition
@testable import PraxisRuntimeFacades
@testable import PraxisRuntimePresentationBridge
@testable import PraxisRuntimeUseCases

// TODO(reboot-plan):
// - Add responsibility guard tests for composition, use cases, facades, and the presentation bridge.
// - Add explicit tests to ensure entry points can reach the system only through PresentationBridge.
// - This file can later be split into HostRuntimeBoundaryTests.swift, HostRuntimeDependencyTests.swift, and PresentationBridgeRuleTests.swift.

struct HostRuntimeTopologyTests {
  @Test
  func runtimeSplitIntoFourLayers() {
    #expect(PraxisRuntimeCompositionModule.boundary.name == "PraxisRuntimeComposition")
    #expect(PraxisRuntimeUseCasesModule.boundary.name == "PraxisRuntimeUseCases")
    #expect(PraxisRuntimeFacadesModule.boundary.name == "PraxisRuntimeFacades")
    #expect(PraxisRuntimePresentationBridgeModule.boundary.name == "PraxisRuntimePresentationBridge")
  }

  @Test
  func presentationBridgeBlueprintMatchesSplit() {
    #expect(PraxisRuntimePresentationBridgeModule.bootstrap.hostContractModules.count == 5)
    #expect(PraxisRuntimePresentationBridgeModule.bootstrap.runtimeModules.count == 4)
    #expect(PraxisRuntimePresentationBridgeModule.bootstrap.rules.contains("Entry 只能经由 RuntimePresentationBridge 进入系统。"))
  }
}
