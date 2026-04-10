import XCTest
@testable import PraxisTapGovernance
@testable import PraxisTapReview
@testable import PraxisTapRuntime
@testable import PraxisTapTypes

final class TapGovernanceSupportTests: XCTestCase {
  func testTapContextModelsCaptureApertureRiskAndForbiddenObjects() {
    let projectSummary = PraxisContextSummarySlot(
      summary: "workspace ready",
      status: .ready,
      source: "test"
    )
    let risk = PraxisPlainLanguageRiskPayload(
      requestedAction: "run repo write tool",
      riskLevel: .high,
      plainLanguageSummary: "这次会改工作区内容。",
      whyItIsRisky: "可能影响多个文件。",
      possibleConsequence: "改错会引入额外修复。",
      whatHappensIfNotRun: "当前任务会卡住。",
      availableUserActions: [
        .init(actionID: "approve-once", label: "继续", summary: "只执行这一次")
      ]
    )
    let aperture = PraxisReviewContextAperture(
      projectSummary: projectSummary,
      runSummary: .init(summary: "run active", status: .ready),
      userIntentSummary: .init(summary: "fix build", status: .ready),
      inventorySnapshot: .init(totalCapabilities: 2, availableCapabilityIDs: []),
      riskSummary: risk,
      sections: [
        .init(
          sectionID: "code",
          title: "代码范围",
          summary: "只动 Sources/",
          status: .ready,
          freshness: .fresh,
          trustLevel: .verified
        )
      ],
      forbiddenObjects: [
        .init(kind: .secretLiteral, summary: "secret must never enter aperture")
      ],
      mode: .careful
    )

    XCTAssertEqual(aperture.riskSummary.riskLevel, .high)
    XCTAssertEqual(aperture.sections.first?.trustLevel, .verified)
    XCTAssertEqual(aperture.forbiddenObjects.first?.kind, .secretLiteral)
  }

  func testTapSupportModelsCoverSafetyToolReviewAndReplay() async throws {
    let safetyDecision = PraxisTapSafetyDecision(
      outcome: .escalateToHuman,
      summary: "dangerous capability requires approval",
      downgradedMode: .restricted
    )
    let session = PraxisToolReviewSessionSnapshot(
      sessionID: "tool-review-session",
      status: .waitingHuman,
      actions: [
        .init(
          reviewID: "review-1",
          sessionID: "tool-review-session",
          governanceKind: .activation,
          status: .waitingHuman,
          summary: "waiting for human gate",
          recordedAt: "2026-04-10T12:00:00Z"
        )
      ]
    )
    let runtimeSnapshot = PraxisTapRuntimeSnapshot(
      controlPlaneState: .init(
        sessionID: .init(rawValue: "session-1"),
        governance: .init(mode: .careful, riskLevel: .medium, capabilityIDs: []),
        humanGateState: .waitingApproval
      ),
      checkpointPointer: nil
    )
    let coordinator = PraxisTapRuntimeCoordinator(snapshot: runtimeSnapshot)
    let storedSnapshot = await coordinator.snapshot

    XCTAssertEqual(safetyDecision.outcome, .escalateToHuman)
    XCTAssertEqual(session.actions.first?.governanceKind, .activation)
    XCTAssertEqual(storedSnapshot?.controlPlaneState.humanGateState, .waitingApproval)
  }
}
