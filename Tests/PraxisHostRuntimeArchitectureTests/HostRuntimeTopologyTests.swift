import Testing
@testable import PraxisRuntimeComposition
@testable import PraxisRuntimeFacades
@testable import PraxisRuntimeGateway
@testable import PraxisRuntimeInterface
@testable import PraxisRuntimePresentationBridge
@testable import PraxisRuntimeUseCases

// TODO(reboot-plan):
// - Add responsibility guard tests for composition, use cases, facades, the runtime gateway, and the presentation bridge.
// - Add explicit tests to ensure portal-agnostic entries reach the system through RuntimeGateway -> RuntimeInterface.
// - This file can later be split into HostRuntimeBoundaryTests.swift, HostRuntimeDependencyTests.swift, and EntryRuleTests.swift.

struct HostRuntimeTopologyTests {
  @Test
  func runtimeSplitIntoSixLayers() {
    #expect(PraxisRuntimeCompositionModule.boundary.name == "PraxisRuntimeComposition")
    #expect(PraxisRuntimeUseCasesModule.boundary.name == "PraxisRuntimeUseCases")
    #expect(PraxisRuntimeFacadesModule.boundary.name == "PraxisRuntimeFacades")
    #expect(PraxisRuntimeInterfaceModule.boundary.name == "PraxisRuntimeInterface")
    #expect(PraxisRuntimeGatewayModule.boundary.name == "PraxisRuntimeGateway")
    #expect(PraxisRuntimePresentationBridgeModule.boundary.name == "PraxisRuntimePresentationBridge")
  }

  @Test
  func presentationBridgeBlueprintMatchesSplit() {
    #expect(PraxisRuntimePresentationBridgeModule.bootstrap.hostContractModules.count == 5)
    #expect(PraxisRuntimePresentationBridgeModule.bootstrap.runtimeModules.count == 6)
    #expect(
      PraxisRuntimePresentationBridgeModule.bootstrap.rules.contains(
        "CLI / 导出入口优先经由 RuntimeGateway -> RuntimeInterface；原生 UI 展示态通过 RuntimePresentationBridge 进入系统。"
      )
    )
  }
}
