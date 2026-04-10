import XCTest
@testable import PraxisCapabilityContracts
@testable import PraxisCapabilityPlanning

final class CapabilityExecutionSurfaceTests: XCTestCase {
  func testCapabilityPlanningBoundaryStillCoversExecutionPlaneModules() {
    XCTAssertTrue(PraxisCapabilityPlanningModule.boundary.tsModules.contains("src/agent_core/capability-gateway"))
    XCTAssertTrue(PraxisCapabilityPlanningModule.boundary.tsModules.contains("src/agent_core/capability-pool"))
    XCTAssertTrue(PraxisCapabilityPlanningModule.boundary.tsModules.contains("src/agent_core/port"))
  }

  func testCapabilityExecutionModelsCaptureGatewayPoolAndPortSurface() {
    let capabilityID = PraxisCapabilityID(rawValue: "code.read")
    let prepared = PraxisPreparedCapabilityCall(
      preparedID: "prepared-1",
      capabilityID: capabilityID,
      bindingKey: "binding.read",
      inputSummary: "read current file",
      metadata: ["scope": "workspace"]
    )
    let handle = PraxisCapabilityExecutionHandle(
      executionID: "exec-1",
      preparedID: prepared.preparedID,
      state: .running,
      startedAt: "2026-04-10T12:00:00Z"
    )
    let backpressure = PraxisCapabilityBackpressureState(
      queueDepth: 2,
      inflightCount: 1,
      isDraining: false
    )
    let intent = PraxisCapabilityPortIntent(
      intentID: "intent-1",
      capabilityID: capabilityID,
      correlationID: "corr-1",
      payloadSummary: "read app.swift",
      createdAt: "2026-04-10T12:00:00Z"
    )
    let result = PraxisCapabilityPortResult(
      intentID: intent.intentID,
      executionID: handle.executionID,
      state: .completed,
      summary: "returned 40 lines"
    )

    XCTAssertEqual(prepared.capabilityID, capabilityID)
    XCTAssertEqual(handle.preparedID, "prepared-1")
    XCTAssertEqual(backpressure.queueDepth, 2)
    XCTAssertEqual(intent.correlationID, "corr-1")
    XCTAssertEqual(result.executionID, "exec-1")
  }
}
