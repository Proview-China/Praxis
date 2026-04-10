import XCTest
@testable import PraxisRuntimeComposition
@testable import PraxisRuntimeFacades
@testable import PraxisRuntimePresentationBridge
@testable import PraxisRuntimeUseCases

final class HostRuntimeSurfaceTests: XCTestCase {
  func testRuntimeSurfaceModelsCaptureReadbackAndSmokeViews() {
    let control = PraxisRuntimeControlSurface(
      executionStyle: "manual",
      readbackPriority: "reconcile",
      fallbackPolicy: "strict_not_found"
    )
    let readback = PraxisCmpProjectReadbackSummary(
      projectID: "project-1",
      controlSurface: control,
      truthLayers: ["git": .ready, "db": .degraded],
      issues: ["db readback incomplete"]
    )
    let smoke = PraxisRuntimeSmokeResult(
      summary: "cmp readback degraded",
      checks: [
        .init(id: "cmp.truth.git", gate: "truth", status: .ready, summary: "git truth ready"),
        .init(id: "cmp.truth.db", gate: "truth", status: .degraded, summary: "db readback incomplete")
      ]
    )

    XCTAssertEqual(readback.controlSurface.executionStyle, "manual")
    XCTAssertEqual(readback.truthLayers["db"], .degraded)
    XCTAssertEqual(smoke.checks.count, 2)
  }

  func testRuntimeFacadeAndBridgeExposeStructuredPlaceholderFlow() async throws {
    let dependencies = PraxisDependencyGraph(
      boundaries: PraxisRuntimePresentationBridgeModule.bootstrap.foundationModules
        + PraxisRuntimePresentationBridgeModule.bootstrap.functionalDomainModules
        + PraxisRuntimePresentationBridgeModule.bootstrap.hostContractModules
        + PraxisRuntimePresentationBridgeModule.bootstrap.runtimeModules
    )
    let runtimeFacade = PraxisRuntimeFacade(
      runFacade: PraxisRunFacade(
        runGoalUseCase: PraxisRunGoalUseCase(dependencies: dependencies),
        resumeRunUseCase: PraxisResumeRunUseCase(dependencies: dependencies)
      ),
      inspectionFacade: PraxisInspectionFacade(
        inspectTapUseCase: PraxisInspectTapUseCase(dependencies: dependencies),
        inspectCmpUseCase: PraxisInspectCmpUseCase(dependencies: dependencies),
        buildCapabilityCatalogUseCase: PraxisBuildCapabilityCatalogUseCase(dependencies: dependencies)
      )
    )
    let bridge = PraxisCLICommandBridge(runtimeFacade: runtimeFacade)

    let architectureState = try await bridge.handle(.init(intent: .inspectArchitecture, payloadSummary: ""))
    let tapState = try await bridge.handle(.init(intent: .inspectTap, payloadSummary: ""))
    let cmpState = try await bridge.handle(.init(intent: .inspectCmp, payloadSummary: ""))
    let catalog = try await runtimeFacade.inspectionFacade.buildCapabilityCatalogSnapshot()

    XCTAssertEqual(architectureState.title, "Praxis Architecture")
    XCTAssertEqual(tapState.title, "TAP Inspection")
    XCTAssertEqual(cmpState.title, "CMP Inspection")
    XCTAssertTrue(catalog.summary.contains("Capability catalog placeholder"))
  }
}
