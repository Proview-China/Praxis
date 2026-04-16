import Foundation
import Testing
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisMpTypes
import PraxisRuntimeComposition
import PraxisRuntimeGateway
import PraxisRuntimeKit
import PraxisRuntimeUseCases
import PraxisTapRuntime
import PraxisTapTypes

private func makeRuntimeKitTemporaryDirectory() throws -> URL {
  let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent("praxis-runtime-kit-tests-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  return directory
}

struct PraxisRuntimeKitTests {
  @Test
  func defaultClientBuildsAndReadsTapInspectionThroughScopedEntry() async throws {
    let client = try PraxisRuntimeClient.makeDefault()
    let inspection = try await client.tap.inspect()

    #expect(inspection.summary.isEmpty == false)
    #expect(inspection.governanceSummary.isEmpty == false)
    #expect(inspection.projectSummary.contains("cmp.local-runtime"))
    #expect(inspection.requestedAction.contains("reviewer context"))
    #expect(inspection.sections.isEmpty == false)
    #expect(inspection.sections.contains { $0.sectionID == "provider-skills" && $0.summary.contains("runtime.inspect") })
    #expect(inspection.sections.contains { $0.sectionID == "provider-mcp-tools" && $0.summary.contains("web.search") })
    #expect(inspection.advisorySummaries.isEmpty == false)
  }

  @Test
  func explicitRootDirectoryBuildsAndReadsMpInspectionThroughScopedEntry() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let inspection = try await client.mp.inspect()

    #expect(inspection.summary.isEmpty == false)
    #expect(inspection.memoryStoreSummary.isEmpty == false)
  }

  @Test
  func runsClientExecutesPlainTextGoalAndResumeWithoutLeakingGoalPreparationTypes() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let run = try await client.runs.run(
      .init(
        task: "  Summarize repository status  ",
        sessionID: "session.runtime-kit"
      )
    )
    let resumed = try await client.runs.resumeRun(.init(run.runID.rawValue))

    #expect(run.sessionID.rawValue == "session.runtime-kit")
    #expect(run.runID.rawValue.isEmpty == false)
    #expect(run.phaseSummary.isEmpty == false)
    #expect(resumed.runID == run.runID)
    #expect(resumed.sessionID == run.sessionID)
  }

  @Test
  func runtimeKitRecoversRunAndTapReviewerStateAcrossFreshClients() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let firstClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let startedRun = try await firstClient.runs.run(
      .init(
        task: "Recover runtime checkpoint state",
        sessionID: "session.runtime-kit-recovery"
      )
    )

    let cmpProject = firstClient.cmp.project("cmp.local-runtime")
    _ = try await cmpProject.openSession("cmp.runtime-kit-recovery")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Escalate git access to checker for recovery coverage"
      )
    )
    _ = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved git access for recovery coverage"
      )
    )

    let secondClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let resumedRun = try await secondClient.runs.resume(.init(startedRun.runID.rawValue))
    let recoveredInspection = try await secondClient.tap.inspect()
    let recoveredWorkbench = try await secondClient.tap.project("cmp.local-runtime").reviewWorkbench(
      for: "checker.local",
      limit: 10
    )

    #expect(resumedRun.runID == startedRun.runID)
    #expect(resumedRun.checkpointReference == startedRun.checkpointReference)
    #expect(recoveredInspection.latestDecisionSummary?.contains("Approved git access for recovery coverage") == true)
    #expect(recoveredWorkbench.latestDecisionSummary?.contains("Approved git access for recovery coverage") == true)
    #expect(recoveredWorkbench.pendingItems.isEmpty)
  }

  @Test
  func cmpInspectionLivesBehindScopedClient() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let cmpInspection = try await client.cmp.inspect()

    #expect(cmpInspection.summary.isEmpty == false)
    #expect(cmpInspection.hostRuntimeSummary.isEmpty == false)
    #expect(cmpInspection.hostRuntimeSummary.contains("provider skills"))
    #expect(cmpInspection.hostRuntimeSummary.contains("provider mcp tools"))
  }

  @Test
  func scopedTapAndCmpClientsExposeProjectCentricWorkflow() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")

    let session = try await cmpProject.openSession(session: "cmp.runtime-kit")
    let requested = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Escalate git access to checker"
      )
    )
    let decided = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved git access for checker"
      )
    )
    let approvalQuery = PraxisRuntimeCmpApprovalQuery(
      agentID: "runtime.local",
      targetAgentID: "checker.local",
      capabilityID: "tool.git"
    )
    let approvalReadback = try await cmpProject.approvals.readback(approvalQuery)
    let tapOverview = try await tapProject.overview(.init(agentID: "checker.local", limit: 10))
    let reviewWorkbench = try await tapProject.reviewWorkbench(.init(agentID: "checker.local", limit: 10))
    let cmpOverview = try await cmpProject.overview(.init(agentID: "checker.local"))
    let approvalOverview = try await cmpProject.approvalOverview(approvalQuery)

    #expect(session.sessionID == "cmp.runtime-kit")
    #expect(requested.capabilityKey.rawValue == "tool.git")
    #expect(decided.outcome == .approvedByHuman)
    #expect(approvalReadback.found)
    #expect(tapOverview.status.availableCapabilityIDs.map(\.rawValue).contains("tool.git"))
    #expect(tapOverview.history.entries.contains { $0.capabilityKey.rawValue == "tool.git" })
    #expect(cmpOverview.status.projectID == "cmp.local-runtime")
    #expect(cmpOverview.readback.projectSummary.projectID == "cmp.local-runtime")
    #expect(approvalOverview.approval.found)
    #expect(tapOverview.latestDecisionSummary?.contains("Approved git access") == true)
    #expect(tapOverview.hasWaitingHumanReview == false)
    #expect(reviewWorkbench.projectID == "cmp.local-runtime")
    #expect(reviewWorkbench.latestDecisionSummary?.contains("Approved git access") == true)
    #expect(reviewWorkbench.queueItems.isEmpty == false)
    #expect(reviewWorkbench.pendingItems.isEmpty)
    #expect(reviewWorkbench.summary.contains("registered capability surface"))
  }

  @Test
  func capabilityClientAppendsProviderCapabilityAuditEventsIntoTapHistory() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    _ = try await client.capabilities.activateSkill(
      .init(
        skillKey: "runtime.inspect",
        reason: "Audit coverage for provider skill activation"
      )
    )
    _ = try await client.capabilities.callTool(
      .init(
        toolName: "web.search",
        summary: "Audit coverage for provider MCP tool calls",
        serverName: "local-test"
      )
    )

    let tapProject = client.tap.project("cmp.local-runtime")
    let overview = try await tapProject.overview(.init(agentID: "runtime.local", limit: 10))
    let inspection = try await tapProject.inspect(historyLimit: 10)
    let workbench = try await tapProject.reviewWorkbench(.init(agentID: "runtime.local", limit: 10))

    #expect(overview.history.entries.contains { $0.capabilityKey.rawValue == "skill.activate" })
    #expect(overview.history.entries.contains { $0.capabilityKey.rawValue == "tool.call" })
    #expect(inspection.latestDecisionSummary?.contains("Called provider MCP tool web.search") == true)
    #expect(workbench.latestDecisionSummary?.contains("Called provider MCP tool web.search") == true)
    #expect(workbench.inspection.sections.contains {
      $0.sectionID == "provider-activity" && $0.summary.contains("web.search")
    })
    #expect(workbench.inspection.advisorySummaries.contains {
      $0.contains("Recent direct provider capability activity")
    })
    #expect(workbench.pendingItems.isEmpty)
  }

  @Test
  func projectScopedTapClientStagesProvisioningAndSurfacesReplayEvidence() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")

    _ = try await cmpProject.openSession("cmp.runtime-kit-provisioning")
    let requested = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Redirect shell execution to provisioning"
      )
    )
    let staged = try await tapProject.provision(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Stage shell execution provisioning for checker",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"]
      )
    )
    let provisioning = try await tapProject.provisioning()
    let inspection = try await tapProject.inspect(historyLimit: 10)
    let reviewWorkbench = try await tapProject.reviewWorkbench(for: "checker.local", limit: 10)

    #expect(requested.outcome == .redirectedToProvisioning)
    #expect(staged.capabilityID == "tool.shell.exec")
    #expect(staged.selectedAssetNames.isEmpty == false)
    #expect(staged.pendingReplayNextAction.rawValue == "re_review_then_dispatch")
    #expect(provisioning.found)
    #expect(provisioning.capabilityID == "tool.shell.exec")
    #expect(provisioning.activeReplayCount == 1)
    #expect(provisioning.activationBindingKey == nil)
    #expect(inspection.runSummary.contains("replay record"))
    #expect(inspection.sections.contains { $0.sectionID == "activation-replay" })
    #expect(reviewWorkbench.provisioning == provisioning)
    #expect(reviewWorkbench.hasProvisioningEvidence)
    #expect(reviewWorkbench.hasActiveReplay)
    #expect(reviewWorkbench.provisioning.primaryReplay?.replayID == staged.pendingReplayID)
    #expect(reviewWorkbench.summary.contains("activation status pending"))
    #expect(reviewWorkbench.provisioning.activationSummary?.contains("Activation staged attempt") == true)
    #expect(reviewWorkbench.latestDecisionSummary == reviewWorkbench.tapOverview.latestDecisionSummary)
  }

  @Test
  func runtimeKitRecoversProvisioningWorkbenchStateAcrossFreshClients() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let firstClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let firstCmpProject = firstClient.cmp.project("cmp.local-runtime")
    let firstTapProject = firstClient.tap.project("cmp.local-runtime")

    _ = try await firstCmpProject.openSession("cmp.runtime-kit-provisioning-recovery")
    _ = try await firstCmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Redirect shell execution to provisioning for recovery coverage"
      )
    )
    let staged = try await firstTapProject.provision(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Stage shell execution provisioning before fresh-client recovery",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"]
      )
    )

    let secondClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let recoveredTapProject = secondClient.tap.project("cmp.local-runtime")
    let recoveredProvisioning = try await recoveredTapProject.provisioning()
    let recoveredWorkbench = try await recoveredTapProject.reviewWorkbench(for: "checker.local", limit: 10)

    #expect(recoveredProvisioning.found)
    #expect(recoveredProvisioning.activeReplayCount == 1)
    #expect(recoveredProvisioning.primaryReplay?.replayID == staged.pendingReplayID)
    #expect(recoveredWorkbench.provisioning == recoveredProvisioning)
    #expect(recoveredWorkbench.hasProvisioningEvidence)
    #expect(recoveredWorkbench.hasActiveReplay)
    #expect(recoveredWorkbench.provisioning.activationSummary?.contains("Activation staged attempt") == true)
    #expect(recoveredWorkbench.latestDecisionSummary == recoveredWorkbench.tapOverview.latestDecisionSummary)
  }

  @Test
  func projectScopedTapClientAdvancesReplayLifecycleThroughExplicitActivation() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")

    _ = try await cmpProject.openSession("cmp.runtime-kit-replay-advance")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Redirect shell execution to provisioning before explicit activation"
      )
    )
    let staged = try await tapProject.provision(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Stage shell execution provisioning before explicit activation",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"]
      )
    )

    let activated = try await tapProject.advanceReplay(
      .init(
        agentID: "runtime.local",
        replayID: .init(staged.pendingReplayID),
        action: .activate
      )
    )
    let workbench = try await tapProject.reviewWorkbench(for: "checker.local", limit: 10)

    #expect(activated.activationStatus == .completed)
    #expect(activated.activationBindingKey?.contains("binding.cmp.local-runtime.tool.shell.exec") == true)
    #expect(activated.primaryReplay?.replayID == staged.pendingReplayID)
    #expect(activated.primaryReplay?.status == .ready)
    #expect(activated.activeReplayCount == 1)
    #expect(workbench.provisioning == activated)
    #expect(workbench.hasActiveReplay)
    #expect(workbench.provisioning.activationSummary?.contains("is ready") == true)
    #expect(workbench.latestDecisionSummary == workbench.tapOverview.latestDecisionSummary)
  }

  @Test
  func reviewWorkbenchPrefersNewestDecisionSummaryOverPreservedProvisioningActivationText() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")

    _ = try await cmpProject.openSession("cmp.runtime-kit-workbench-summary")
    _ = try await tapProject.provision(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Stage shell execution provisioning before reviewer rejection coverage",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"]
      )
    )
    let stagedWorkbench = try await tapProject.reviewWorkbench(for: "checker.local", limit: 10)
    let preservedActivationSummary = try #require(stagedWorkbench.provisioning.activationSummary)
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Request git approval after provisioning evidence exists"
      )
    )
    _ = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .reject,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Reviewer rejected git access after provisioning was staged"
      )
    )
    let updatedWorkbench = try await tapProject.reviewWorkbench(for: "checker.local", limit: 10)

    #expect(preservedActivationSummary.contains("Activation staged attempt") == true)
    #expect(
      updatedWorkbench.latestDecisionSummary?.contains("Reviewer rejected git access after provisioning was staged")
        == true
    )
    #expect(updatedWorkbench.latestDecisionSummary != preservedActivationSummary)
  }

  @Test
  func projectScopedCmpFlowClientMaterializesAndDispatchesPersistedPackage() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let hostAdapters = PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory)
    let dependencies = try PraxisRuntimeGatewayFactory.makeCompositionRoot(hostAdapters: hostAdapters).makeDependencyGraph()
    let bootstrapProjectUseCase = PraxisBootstrapCmpProjectUseCase(dependencies: dependencies)
    let ingestFlowUseCase = PraxisIngestCmpFlowUseCase(dependencies: dependencies)
    let commitFlowUseCase = PraxisCommitCmpFlowUseCase(dependencies: dependencies)
    let runGoalUseCase = PraxisRunGoalUseCase(dependencies: dependencies)
    let resolveFlowUseCase = PraxisResolveCmpFlowUseCase(dependencies: dependencies)
    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")

    _ = try await bootstrapProjectUseCase.execute(
      PraxisBootstrapCmpProjectCommand(
        projectID: "cmp.local-runtime",
        agentIDs: ["runtime.local", "checker.local"],
        defaultAgentID: "runtime.local"
      )
    )
    let ingest = try await ingestFlowUseCase.execute(
      PraxisIngestCmpFlowCommand(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        sessionID: "cmp.runtime-kit-flow",
        taskSummary: "Capture runtime context for RuntimeKit package dispatch coverage",
        materials: [.init(kind: .userInput, ref: "payload:user:runtime-kit-dispatch")],
        requiresActiveSync: true
      )
    )
    _ = try await commitFlowUseCase.execute(
      PraxisCommitCmpFlowCommand(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        sessionID: "cmp.runtime-kit-flow",
        eventIDs: ingest.result.acceptedEventIDs,
        changeSummary: "Commit RuntimeKit dispatch context",
        syncIntent: .toParent
      )
    )
    _ = try await runGoalUseCase.execute(
      PraxisRunGoalCommand(
        goal: .init(
          normalizedGoal: .init(
            id: .init(rawValue: "goal.runtime-kit-dispatch"),
            title: "RuntimeKit Dispatch Seed",
            summary: "Seed projection for RuntimeKit persisted package dispatch coverage"
          ),
          intentSummary: "Seed projection for RuntimeKit persisted package dispatch coverage"
        ),
        sessionID: .init(rawValue: "session.runtime-kit-flow")
      )
    )
    _ = try await resolveFlowUseCase.execute(
      PraxisResolveCmpFlowCommand(projectID: "cmp.local-runtime", agentID: "runtime.local")
    )
    let staged = try await tapProject.provision(
      PraxisRuntimeTapProvisionRequest(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: PraxisTapCapabilityTier.b2,
        summary: "Stage shell execution provisioning before RuntimeKit package dispatch",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"]
      )
    )
    _ = try await tapProject.advanceReplay(
      .init(
        agentID: "runtime.local",
        replayID: .init(staged.pendingReplayID),
        action: .activate
      )
    )

    let materialized = try await cmpProject.flows.materialize(
      PraxisRuntimeCmpMaterializeRequest(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        packageKind: PraxisCmpContextPackageKind.runtimeFill,
        fidelityLabel: PraxisCmpContextPackageFidelityLabel.highSignal
      )
    )
    let dispatched = try await cmpProject.flows.dispatch(
      PraxisRuntimeCmpDispatchRequest(
        agentID: "runtime.local",
        packageID: PraxisRuntimeCmpPackageRef(materialized.packageID.rawValue),
        targetKind: PraxisCmpDispatchTargetKind.peer,
        reason: "Dispatch persisted package through RuntimeKit flow wrapper"
      )
    )
    let provisioning = try await tapProject.provisioning()

    #expect(materialized.packageID.rawValue.isEmpty == false)
    #expect(materialized.targetAgentID == "checker.local")
    #expect(dispatched.status == PraxisCmpDispatchStatus.delivered)
    #expect(dispatched.targetAgentID == "checker.local")
    #expect(provisioning.activationStatus == PraxisActivationAttemptStatus.completed)
    #expect(provisioning.activeReplayCount == 0)
    #expect(provisioning.replayRecords.first?.status == PraxisReplayStatus.consumed)
  }

  @Test
  func projectScopedTapWorkbenchDoesNotReuseDefaultInspectionProject() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let defaultCmpProject = client.cmp.project("cmp.local-runtime")
    let otherCmpProject = client.cmp.project("other-project")
    let otherTapProject = client.tap.project("other-project")

    _ = try await defaultCmpProject.openSession("cmp.runtime-kit-default")
    _ = try await otherCmpProject.openSession("cmp.runtime-kit-other")
    _ = try await defaultCmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Default project approval should stay scoped"
      )
    )
    _ = try await defaultCmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved only for default project"
      )
    )

    let otherInspection = try await otherTapProject.inspect()
    let otherWorkbench = try await otherTapProject.reviewWorkbench(for: "checker.local", limit: 10)

    #expect(otherInspection.projectSummary.contains("other-project"))
    #expect(otherInspection.projectSummary.contains("cmp.local-runtime") == false)
    #expect(otherInspection.runSummary.contains("tap.session.snapshot.other-project"))
    #expect(otherInspection.runSummary.contains("available for inspection and recovery") == false)
    #expect(otherInspection.latestDecisionSummary?.contains("Approved only for default project") == false)
    #expect(otherWorkbench.projectID == "other-project")
    #expect(otherWorkbench.inspection.projectSummary.contains("other-project"))
    #expect(otherWorkbench.inspection.runSummary.contains("tap.session.snapshot.other-project"))
    #expect(otherWorkbench.hasProvisioningEvidence == false)
    #expect(otherWorkbench.hasActiveReplay == false)
    #expect(otherWorkbench.latestDecisionSummary?.contains("Approved only for default project") == false)
    #expect(otherWorkbench.pendingItems.isEmpty)
  }

  @Test
  func scopedMpClientExposesProjectSearchResolveAndMemoryLifecycle() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let mpProject = client.mp.project("mp.local-runtime")

    let overview = try await mpProject.overview(.init(limit: 5))
    let search = try await mpProject.search(
      .init(
        query: "onboarding",
        scopeLevels: [.project],
        limit: 5
      )
    )
    let resolve = try await mpProject.resolve(
      .init(
        query: "onboarding",
        requesterAgentID: "runtime.local",
        scopeLevels: [.project],
        limit: 5
      )
    )
    let history = try await mpProject.history(
      .init(
        query: "onboarding",
        requesterAgentID: "runtime.local",
        reason: "Need historical context",
        scopeLevels: [.project],
        limit: 5
      )
    )
    let memoryLifecycle = mpProject.memory("memory.runtime-kit")

    #expect(overview.smoke.projectID == "mp.local-runtime")
    #expect(overview.smoke.summary.isEmpty == false)
    #expect(overview.readback.projectID == "mp.local-runtime")
    #expect(overview.readback.totalMemoryCount >= 0)
    #expect(search.projectID == "mp.local-runtime")
    #expect(search.query == "onboarding")
    #expect(resolve.projectID == "mp.local-runtime")
    #expect(resolve.query == "onboarding")
    #expect(history.projectID == "mp.local-runtime")
    #expect(history.reason == "Need historical context")
    #expect(String(describing: type(of: memoryLifecycle)) == "PraxisRuntimeMpMemoryClient")
  }

  @Test
  func runtimeKitConveniencesReduceRequestWrapperCeremonyWithoutChangingTypedSemantics() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let started = try await client.runs.run(
      task: "Summarize repository status",
      sessionID: "session.runtime-kit-convenience"
    )
    let resumed = try await client.runs.resume(.init(started.runID.rawValue))

    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")
    let mpProject = client.mp.project("mp.local-runtime")

    let session = try await cmpProject.openSession("cmp.runtime-kit-convenience")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Escalate git access to checker"
      )
    )
    _ = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved git access for checker"
      )
    )
    let cmpOverview = try await cmpProject.overview(for: "checker.local")
    let cmpSmoke = try await cmpProject.smoke()
    let tapOverview = try await tapProject.overview(for: "checker.local", limit: 10)
    let mpOverview = try await mpProject.overview(limit: 5)
    let mpSmoke = try await mpProject.smoke()
    let mpSearch = try await mpProject.search(query: "onboarding", scopeLevels: [.project], limit: 5)

    #expect(started.runID == resumed.runID)
    #expect(session.sessionID == "cmp.runtime-kit-convenience")
    #expect(cmpOverview.projectID == "cmp.local-runtime")
    #expect(cmpOverview.smokeChecks.count == cmpSmoke.smokeResult.checks.count)
    #expect(tapOverview.projectID == "cmp.local-runtime")
    #expect(mpOverview.projectID == "mp.local-runtime")
    #expect(mpOverview.smokeChecks.count == mpSmoke.smokeResult.checks.count)
    #expect(mpSearch.query == "onboarding")
  }

  @Test
  func runtimeKitErrorDiagnosticsMapCoreErrorCategoriesIntoCallerFacingRemediation() {
    let invalidInput = PraxisRuntimeErrorDiagnostics.diagnose(
      PraxisError.invalidInput("Field projectID must not be empty.")
    )
    let dependencyMissing = PraxisRuntimeErrorDiagnostics.diagnose(
      PraxisError.dependencyMissing("MP resolve requires a semantic memory store adapter.")
    )
    let unsupportedOperation = PraxisRuntimeErrorDiagnostics.diagnose(
      PraxisError.unsupportedOperation("System git execution is only wired for the macOS local runtime baseline today.")
    )
    let invariantViolation = PraxisRuntimeErrorDiagnostics.diagnose(
      PraxisError.invariantViolation("Failed to open local runtime SQLite database.")
    )

    #expect(invalidInput.category == .invalidInput)
    #expect(invalidInput.remediation.contains("required fields"))
    #expect(dependencyMissing.category == .dependencyMissing)
    #expect(dependencyMissing.remediation.contains("host adapter"))
    #expect(unsupportedOperation.category == .unsupportedOperation)
    #expect(unsupportedOperation.remediation.contains("supported runtime profile"))
    #expect(invariantViolation.category == .invariantViolation)
    #expect(invariantViolation.remediation.contains("runtime bug"))
  }

  @Test
  func capabilityClientExposesThinCapabilityBaselineWithoutLeakingProviderContracts() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }
    let patchTargetFileURL = rootDirectory.appendingPathComponent("code-patch.txt", isDirectory: false)
    try "before\nvalue\n".write(to: patchTargetFileURL, atomically: true, encoding: .utf8)

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let catalog = client.capabilities.catalog()
    let openedSession = try await client.capabilities.openSession(
      .init(
        sessionID: "runtime.capabilities.test",
        title: "Runtime Capability Test"
      )
    )
    let generated = try await client.capabilities.generate(
      .init(
        prompt: "Summarize the thin capability baseline",
        preferredModel: "local-test-model",
        requiredCapabilities: ["generate.create", "embed.create"]
      )
    )
    let streamed = try await client.capabilities.stream(
      .init(
        prompt: "Stream one short capability summary",
        preferredModel: "local-test-model"
      ),
      chunkCharacterCount: 24
    )
    let embedded = try await client.capabilities.embed(
      .init(
        content: "runtime capability baseline test",
        preferredModel: "local-embed-test"
      )
    )
    let sandbox = try await client.capabilities.describeCodeSandbox(
      .init(
        workingDirectory: rootDirectory.path,
        requestedRuntime: .swift
      )
    )
    let codeCatalogAvailable = catalog.capabilityIDs.map(\.rawValue).contains("code.run")
#if os(macOS)
    let patch = try await client.capabilities.patchCode(
      .init(
        summary: "Apply one bounded runtime code patch",
        changes: [
          .init(
            path: "code-patch.txt",
            patch: """
            @@ -1,2 +1,2 @@
             before
            -value
            +after
            """
          )
        ]
      )
    )
#endif
    let code = codeCatalogAvailable ? try await client.capabilities.runCode(
      .init(
        summary: "Emit a bounded runtime code marker",
        runtime: .swift,
        source: "print(\"runtime-kit-code-test\")",
        workingDirectory: rootDirectory.path,
        timeoutSeconds: 2
      )
    ) : nil
    let shell = try await client.capabilities.runShell(
      .init(
        summary: "Emit a bounded runtime shell marker",
        command: "printf 'runtime-kit-capability-test\\n'",
        workingDirectory: rootDirectory.path,
        timeoutSeconds: 2
      )
    )
    let shellApproval = try await client.capabilities.requestShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        requestedTier: .b2,
        summary: "Request bounded shell approval for RuntimeKit capability coverage"
      )
    )
    let shellApprovalReadback = try await client.capabilities.readbackShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local"
      )
    )
    let listedSkills = try await client.capabilities.listSkills()
    let activatedSkill = try await client.capabilities.activateSkill(
      .init(
        skillKey: "runtime.inspect",
        reason: "RuntimeKit capability coverage"
      )
    )
    let listedProviderMCPTools = try await client.capabilities.listProviderMCPTools()
    let toolCall = try await client.capabilities.callTool(
      .init(
        toolName: "web.search",
        summary: "Find RuntimeKit docs",
        serverName: "local-test"
      )
    )
    let fileUpload = try await client.capabilities.uploadFile(
      .init(
        summary: "runtime capability test artifact",
        purpose: "analysis"
      )
    )
    let batchSubmit = try await client.capabilities.submitBatch(
      .init(
        summary: "runtime capability test batch",
        itemCount: 4
      )
    )
    let webSearch = try await client.capabilities.searchWeb(
      .init(
        query: "Swift runtime capability baseline",
        locale: "en-US",
        preferredDomains: ["example.com", "docs.example.com"],
        limit: 2
      )
    )
    let fetched = try await client.capabilities.fetchSearchResult(
      .init(
        url: webSearch.results.first?.url ?? "https://example.com/search/swift-runtime-capability-baseline",
        preferredTitle: "Capability Search Result",
        waitPolicy: .networkIdle
      )
    )
    let grounded = try await client.capabilities.groundSearchResult(
      .init(
        taskSummary: "Verify capability baseline docs page",
        exampleURL: fetched.finalURL,
        requestedFacts: ["final_url", "host", "page_title"],
        locale: "en-US",
        maxPages: 2
      )
    )

    #expect(catalog.capabilityIDs.map(\.rawValue).contains("generate.create"))
#if os(macOS)
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("code.patch"))
#else
    #expect(!catalog.capabilityIDs.map(\.rawValue).contains("code.patch"))
#endif
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("code.sandbox"))
    #expect(codeCatalogAvailable == PraxisLocalHostPlatformSupport.supportsBoundedCodeExecution)
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("session.open"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("shell.approve"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("shell.run"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("skill.list"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("skill.activate"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("search.web"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("search.fetch"))
    #expect(catalog.capabilityIDs.map(\.rawValue).contains("search.ground"))
    #expect(openedSession.sessionID.rawValue == "runtime.capabilities.test")
    #expect(openedSession.title == "Runtime Capability Test")
    #expect(generated.capabilityID.rawValue == "generate.create")
    #expect(generated.outputText.isEmpty == false)
    #expect(streamed.capabilityID.rawValue == "generate.stream")
    #expect(streamed.chunks.isEmpty == false)
    #expect(embedded.capabilityID.rawValue == "embed.create")
    #expect(embedded.vectorLength > 0)
    #expect(sandbox.capabilityID.rawValue == "code.sandbox")
    #expect(sandbox.profile == .workspaceWriteLimited)
    #expect(sandbox.writableRoots == [rootDirectory.path])
    #expect(sandbox.readableRoots.contains(rootDirectory.path))
    #expect(sandbox.allowsNetworkAccess == false)
    #expect(sandbox.allowsSubprocesses == false)
#if os(macOS)
    if PraxisLocalHostPlatformSupport.supportsBoundedCodeExecution {
      #expect(sandbox.enforcementMode == .declaredOnly)
      #expect(sandbox.allowedRuntimes == [.swift])
    } else {
      #expect(sandbox.enforcementMode == .placeholder)
      #expect(sandbox.allowedRuntimes.isEmpty)
    }
#else
    #expect(sandbox.enforcementMode == .placeholder)
    #expect(sandbox.allowedRuntimes.isEmpty)
#endif
    if let code {
      #expect(code.capabilityID.rawValue == "code.run")
      #expect(code.runtime == .swift)
      #expect(code.riskLabel == "risky")
      #expect(code.outputMode == .buffered)
#if os(macOS)
      #expect(code.succeeded)
      #expect(code.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "runtime-kit-code-test")
#else
      #expect(code.terminationReason == .failedToLaunch)
      #expect(code.stderr.isEmpty == false)
#endif
    } else {
      #expect(!PraxisLocalHostPlatformSupport.supportsBoundedCodeExecution)
    }
#if os(macOS)
    #expect(patch.capabilityID.rawValue == "code.patch")
    #expect(patch.appliedChangeCount == 1)
    #expect(patch.changedPaths == ["code-patch.txt"])
    #expect(patch.riskLabel == "risky")
    #expect(try String(contentsOf: patchTargetFileURL, encoding: .utf8) == "before\nafter")
#endif
    #expect(shellApproval.capabilityID.rawValue == "shell.approve")
    #expect(shellApproval.approvedCapabilityID.rawValue == "shell.run")
    #expect(shellApproval.riskLevel == "risky")
    #expect(shellApproval.outcome == "review_required")
    #expect(shellApprovalReadback.found)
    #expect(shellApprovalReadback.approvedCapabilityID?.rawValue == "shell.run")
    #expect(shellApprovalReadback.riskLevel == "risky")
    #expect(shellApprovalReadback.outcome == "review_required")
    #expect(shell.capabilityID.rawValue == "shell.run")
    #expect(shell.riskLabel == "risky")
    #expect(shell.environmentKeys.isEmpty)
#if os(macOS)
    #expect(shell.succeeded)
    #expect(shell.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "runtime-kit-capability-test")
#else
      #expect(shell.terminationReason == .failedToLaunch)
      #expect(shell.stderr.isEmpty == false)
#endif
    #expect(listedSkills.capabilityID.rawValue == "skill.list")
    #expect(listedSkills.skillKeys.contains("runtime.inspect"))
    #expect(activatedSkill.capabilityID.rawValue == "skill.activate")
    #expect(activatedSkill.skillKey == "runtime.inspect")
    #expect(activatedSkill.activated)
    #expect(listedProviderMCPTools.capabilityID.rawValue == "tool.call")
    #expect(listedProviderMCPTools.toolNames == ["web.search"])
    #expect(toolCall.capabilityID.rawValue == "tool.call")
    #expect(toolCall.toolName == "web.search")
    #expect(fileUpload.capabilityID.rawValue == "file.upload")
    #expect(fileUpload.fileID.isEmpty == false)
    #expect(batchSubmit.capabilityID.rawValue == "batch.submit")
    #expect(batchSubmit.batchID.isEmpty == false)
    #expect(webSearch.capabilityID.rawValue == "search.web")
    #expect(webSearch.results.isEmpty == false)
    #expect(fetched.capabilityID.rawValue == "search.fetch")
    #expect(fetched.finalURL.isEmpty == false)
    let snapshotPath = try #require(fetched.snapshotPath)
    let snapshotContents = try String(contentsOfFile: snapshotPath, encoding: .utf8)
    #expect(snapshotContents.contains("Wait policy: networkIdle"))
    #expect(grounded.capabilityID.rawValue == "search.ground")
    #expect(grounded.pages.isEmpty == false)
    #expect(grounded.facts.count == 3)
  }

  @Test
  func capabilityClientRejectsUnregisteredProviderSkillActivation() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.activateSkill(
        .init(
          skillKey: "not.registered",
          reason: "Negative capability coverage"
        )
      )
    }
  }

  @Test
  func capabilityClientRejectsUnregisteredProviderMCPToolCalls() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.callTool(
        .init(
          toolName: "not.registered",
          summary: "Negative MCP capability coverage",
          serverName: "local-test"
        )
      )
    }
  }

  @Test
  func capabilityClientRecoversShellApprovalAcrossFreshClientsWithoutLeakingLegacyCapabilityKeys() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let firstClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let requested = try await firstClient.capabilities.requestShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        requestedTier: .b2,
        summary: "Request bounded shell approval for recovery coverage"
      )
    )

    let secondClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let recovered = try await secondClient.capabilities.readbackShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local"
      )
    )

    #expect(requested.capabilityID.rawValue == "shell.approve")
    #expect(requested.approvedCapabilityID.rawValue == "shell.run")
    #expect(requested.riskLevel == "risky")
    #expect(recovered.found)
    #expect(recovered.approvedCapabilityID?.rawValue == "shell.run")
    #expect(recovered.riskLevel == "risky")
    #expect(recovered.outcome == requested.outcome)
    #expect(recovered.humanGateState == requested.humanGateState)
  }

  @Test
  func capabilityClientRejectsUnsupportedCodeStreamingRequests() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.runCode(
        .init(
          summary: "Attempt unsupported RuntimeKit code streaming",
          runtime: .swift,
          source: "print(\"streaming\")",
          workingDirectory: rootDirectory.path,
          timeoutSeconds: 2,
          outputMode: .streaming
        )
      )
    }
  }

  @Test
  func capabilityClientRejectsCodeExecutionOutsideSandboxWritableRoots() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-runtime-kit-code-sandbox-guard-\(UUID().uuidString)", isDirectory: true)
    let outsideDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-runtime-kit-code-outside-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outsideDirectory, withIntermediateDirectories: true)
    defer {
      try? FileManager.default.removeItem(at: rootDirectory)
      try? FileManager.default.removeItem(at: outsideDirectory)
    }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let catalog = client.capabilities.catalog()
    guard catalog.capabilityIDs.map(\.rawValue).contains("code.run") else {
      #expect(!PraxisLocalHostPlatformSupport.supportsBoundedCodeExecution)
      return
    }

    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.runCode(
        .init(
          summary: "Attempt RuntimeKit code execution outside writable sandbox roots",
          runtime: .swift,
          source: "print(\"outside-sandbox\")",
          workingDirectory: outsideDirectory.path,
          timeoutSeconds: 2
        )
      )
    }
  }

  @Test
  func capabilityClientRejectsEmptyCodePatchRequests() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.patchCode(
        .init(
          summary: "Attempt empty RuntimeKit code patch",
          changes: []
        )
      )
    }
  }

  @Test
  func capabilityClientRejectsUnsupportedShellStreamingAndPTYRequests() async throws {
    let rootDirectory = try makeRuntimeKitTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.runShell(
        .init(
          summary: "Attempt unsupported RuntimeKit shell streaming",
          command: "printf 'streaming\\n'",
          workingDirectory: rootDirectory.path,
          timeoutSeconds: 2,
          outputMode: .streaming
        )
      )
    }
    await #expect(throws: PraxisError.self) {
      _ = try await client.capabilities.runShell(
        .init(
          summary: "Attempt unsupported RuntimeKit shell PTY",
          command: "printf 'pty\\n'",
          workingDirectory: rootDirectory.path,
          timeoutSeconds: 2,
          requiresPTY: true
        )
      )
    }
  }
}
