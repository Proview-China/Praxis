import Testing
@testable import PraxisCheckpoint
@testable import PraxisCmpProjection
@testable import PraxisCmpSections
@testable import PraxisCmpTypes

struct PraxisCmpProjectionTests {
  @Test
  func materializerBuildsProjectionVisibilityAndRecovery() {
    let snapshot = PraxisCmpCheckedSnapshot(
      id: .init(rawValue: "snapshot-1"),
      lineageID: .init(rawValue: "lineage-1"),
      agentID: "agent-1",
      branchRef: "cmp/agent-1",
      commitRef: "abc123",
      checkedAt: "2026-04-10T00:00:00Z",
      qualityLabel: .highSignal,
      promotable: true,
      sourceDeltaRefs: [.init(rawValue: "delta-1")]
    )
    let stored = PraxisCmpStoredSection(
      id: "stored-1",
      sectionID: .init(rawValue: "section-1"),
      plane: .git,
      state: .checked,
      scope: .local,
      storedRef: "git://section-1"
    )
    let materializer = PraxisProjectionMaterializer()

    let projection = materializer.createProjection(
      from: snapshot,
      storedSections: [stored],
      visibilityLevel: .submittedToParent,
      updatedAt: "2026-04-10T00:01:00Z"
    )
    let recovery = materializer.recoveryPlan(
      for: projection,
      availableSectionIDs: [stored.sectionID],
      checkpointPointer: .init(
        checkpointID: .init(rawValue: "checkpoint-1"),
        sessionID: .init(rawValue: "session-1")
      )
    )

    #expect(materializer.isVisible(projection, to: .parent))
    #expect(!materializer.isVisible(projection, to: .peer))
    #expect(recovery.resumable)
  }

  @Test
  func runtimeSnapshotChoosesLatestProjectionWithoutTrappingOnDuplicateAgents() {
    let materializer = PraxisProjectionMaterializer()
    let snapshots = [
      PraxisCmpCheckedSnapshot(
        id: .init(rawValue: "snapshot-1"),
        lineageID: .init(rawValue: "lineage-1"),
        agentID: "agent-1",
        branchRef: "cmp/agent-1",
        commitRef: "abc123",
        checkedAt: "2026-04-10T00:00:00Z",
        qualityLabel: .usable,
        promotable: true,
        sourceDeltaRefs: [.init(rawValue: "delta-1")]
      )
    ]
    let olderProjection = PraxisProjectionRecord(
      id: .init(rawValue: "projection-older"),
      snapshotID: .init(rawValue: "snapshot-1"),
      lineageID: .init(rawValue: "lineage-1"),
      agentID: "agent-1",
      sectionIDs: [],
      storedRefs: [],
      visibilityLevel: .localOnly,
      updatedAt: "2026-04-10T00:01:00Z"
    )
    let newerProjection = PraxisProjectionRecord(
      id: .init(rawValue: "projection-newer"),
      snapshotID: .init(rawValue: "snapshot-1"),
      lineageID: .init(rawValue: "lineage-1"),
      agentID: "agent-1",
      sectionIDs: [],
      storedRefs: [],
      visibilityLevel: .submittedToParent,
      updatedAt: "2026-04-10T00:02:00Z"
    )

    let runtimeSnapshot = materializer.createRuntimeSnapshot(
      checkedSnapshots: snapshots,
      projections: [olderProjection, newerProjection]
    )

    #expect(runtimeSnapshot.projectionIDs == [olderProjection.id, newerProjection.id])
    #expect(runtimeSnapshot.latestProjectionByAgentID["agent-1"] == newerProjection.id)
  }

  @Test
  func recoveryPlanMarksProjectionAsNonResumableWhenSectionsAreMissing() {
    let materializer = PraxisProjectionMaterializer()
    let projection = PraxisProjectionRecord(
      id: .init(rawValue: "projection-missing"),
      snapshotID: .init(rawValue: "snapshot-missing"),
      lineageID: .init(rawValue: "lineage-missing"),
      agentID: "agent-missing",
      sectionIDs: [
        .init(rawValue: "section-available"),
        .init(rawValue: "section-missing")
      ],
      storedRefs: ["git://section-available", "git://section-missing"],
      visibilityLevel: .submittedToParent,
      updatedAt: "2026-04-10T00:03:00Z"
    )

    let recovery = materializer.recoveryPlan(
      for: projection,
      availableSectionIDs: [.init(rawValue: "section-available")],
      checkpointPointer: .init(
        checkpointID: .init(rawValue: "checkpoint-missing"),
        sessionID: .init(rawValue: "session-missing")
      )
    )

    #expect(!recovery.resumable)
    #expect(recovery.missingSectionIDs == [.init(rawValue: "section-missing")])
    #expect(recovery.summary == "Projection is missing section state.")
  }

  @Test
  func hydrateRecoverySeparatesResumableAndMissingProjectionIDs() {
    let materializer = PraxisProjectionMaterializer()
    let snapshot = PraxisCmpRuntimeSnapshot(
      checkedSnapshotIDs: [.init(rawValue: "snapshot-1")],
      projectionIDs: [
        .init(rawValue: "projection-present"),
        .init(rawValue: "projection-missing")
      ],
      latestProjectionByAgentID: ["agent-1": .init(rawValue: "projection-present")],
      checkpointPointer: .init(
        checkpointID: .init(rawValue: "checkpoint-1"),
        sessionID: .init(rawValue: "session-1")
      )
    )

    let hydrated = materializer.hydrateRecovery(
      from: snapshot,
      availableProjectionIDs: [.init(rawValue: "projection-present")]
    )

    #expect(hydrated.resumableProjectionIDs == [.init(rawValue: "projection-present")])
    #expect(hydrated.missingProjectionIDs == [.init(rawValue: "projection-missing")])
    #expect(hydrated.issues == ["Projection projection-missing is missing during recovery."])
  }
}
