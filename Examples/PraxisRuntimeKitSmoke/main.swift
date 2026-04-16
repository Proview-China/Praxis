import Foundation
import PraxisCmpTypes
import PraxisMpTypes
import PraxisRuntimeFacades
import PraxisRuntimeGateway
import PraxisRuntimeKit
import PraxisTapProvision
import PraxisTapRuntime
import PraxisTapTypes

private enum PraxisRuntimeKitSmokeSuite: String, CaseIterable {
  case run
  case cmpTap = "cmp-tap"
  case provisioning
  case dispatch
  case recovery
  case mp
  case capabilities
  case code
  case codeSandbox = "code-sandbox"
  case codePatch = "code-patch"
  case shell
  case shellApproval = "shell-approval"
  case search
  case all

  static func parse(_ rawValue: String?) throws -> PraxisRuntimeKitSmokeSuite {
    guard let rawValue else {
      return .all
    }
    guard let suite = PraxisRuntimeKitSmokeSuite(rawValue: rawValue) else {
      throw PraxisRuntimeKitSmokeFailure.invalidArguments(
        "Unsupported suite '\(rawValue)'. Use one of: \(allCases.map(\.rawValue).joined(separator: ", "))."
      )
    }
    return suite
  }
}

private enum PraxisRuntimeKitSmokeStatus: String {
  case passed = "passed"
  case failed = "failed"
}

private struct PraxisRuntimeKitSmokeResult {
  let suite: PraxisRuntimeKitSmokeSuite
  let status: PraxisRuntimeKitSmokeStatus
  let summary: String
  let remediation: String?
}

private enum PraxisRuntimeKitSmokeFailure: Error {
  case assertion(String)
  case invalidArguments(String)
  case suiteFailures([PraxisRuntimeKitSmokeResult])
}

extension PraxisRuntimeKitSmokeFailure: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .assertion(let message), .invalidArguments(let message):
      return message
    case .suiteFailures(let results):
      let failed = results.filter { $0.status == .failed }
      return "Smoke failed for \(failed.count) suite(s): \(failed.map(\.suite.rawValue).joined(separator: ", "))."
    }
  }
}

private struct PraxisRuntimeKitSmokeHarness {
  let rootDirectory: URL
  let runtimeFacade: PraxisRuntimeFacade
  let client: PraxisRuntimeClient

  init(rootDirectory: URL) throws {
    self.rootDirectory = rootDirectory
    self.runtimeFacade = try PraxisRuntimeGatewayFactory.makeRuntimeFacade(rootDirectory: rootDirectory)
    self.client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
  }

  func run(_ suite: PraxisRuntimeKitSmokeSuite) async -> [PraxisRuntimeKitSmokeResult] {
    switch suite {
    case .run:
      return [await execute(.run, body: runSuite)]
    case .cmpTap:
      return [await execute(.cmpTap, body: cmpTapSuite)]
    case .provisioning:
      return [await execute(.provisioning, body: provisioningSuite)]
    case .dispatch:
      return [await execute(.dispatch, body: dispatchSuite)]
    case .mp:
      return [await execute(.mp, body: mpSuite)]
    case .recovery:
      return [await execute(.recovery, body: recoverySuite)]
    case .capabilities:
      return [await execute(.capabilities, body: capabilitiesSuite)]
    case .code:
      return [await execute(.code, body: codeSuite)]
    case .codeSandbox:
      return [await execute(.codeSandbox, body: codeSandboxSuite)]
    case .codePatch:
      return [await execute(.codePatch, body: codePatchSuite)]
    case .shell:
      return [await execute(.shell, body: shellSuite)]
    case .shellApproval:
      return [await execute(.shellApproval, body: shellApprovalSuite)]
    case .search:
      return [await execute(.search, body: searchSuite)]
    case .all:
      return [
        await execute(.run, body: runSuite),
        await execute(.cmpTap, body: cmpTapSuite),
        await execute(.provisioning, body: provisioningSuite),
        await execute(.dispatch, body: dispatchSuite),
        await execute(.recovery, body: recoverySuite),
        await execute(.mp, body: mpSuite),
        await execute(.capabilities, body: capabilitiesSuite),
        await execute(.code, body: codeSuite),
        await execute(.codeSandbox, body: codeSandboxSuite),
        await execute(.codePatch, body: codePatchSuite),
        await execute(.shell, body: shellSuite),
        await execute(.shellApproval, body: shellApprovalSuite),
        await execute(.search, body: searchSuite),
      ]
    }
  }

  private func execute(
    _ suite: PraxisRuntimeKitSmokeSuite,
    body: () async throws -> String
  ) async -> PraxisRuntimeKitSmokeResult {
    do {
      return PraxisRuntimeKitSmokeResult(
        suite: suite,
        status: .passed,
        summary: try await body(),
        remediation: nil
      )
    } catch {
      let diagnostic = PraxisRuntimeErrorDiagnostics.diagnose(error)
      return PraxisRuntimeKitSmokeResult(
        suite: suite,
        status: .failed,
        summary: diagnostic.summary,
        remediation: diagnostic.remediation
      )
    }
  }

  private func runSuite() async throws -> String {
    let started = try await client.runs.run(
      task: "Summarize repository status",
      sessionID: "session.runtime-kit-smoke"
    )
    let resumed = try await client.runs.resume(.init(started.runID.rawValue))

    try require(started.runID == resumed.runID, "Run smoke expected resumed run ID to match the started run.")
    try require(started.sessionID == resumed.sessionID, "Run smoke expected resumed session ID to match the started session.")

    return "runID=\(started.runID.rawValue) lifecycle=\(resumed.lifecycleDisposition.rawValue) summary=\(resumed.phaseSummary)"
  }

  private func cmpTapSuite() async throws -> String {
    let cmpProject = client.cmp.project("cmp.local-runtime")
    let tapProject = client.tap.project("cmp.local-runtime")

    _ = try await cmpProject.openSession("cmp.runtime-kit-smoke")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Escalate git access to checker"
      )
    )
    let decision = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved git access for checker"
      )
    )
    let smoke = try await cmpProject.smoke()
    let tapInspection = try await client.tap.inspect()
    let tapOverview = try await tapProject.overview(for: "checker.local", limit: 10)
    let reviewWorkbench = try await tapProject.reviewWorkbench(for: "checker.local", limit: 10)

    try require(decision.outcome == .approvedByHuman, "CMP + TAP smoke expected approved git access.")
    try require(
      tapOverview.status.availableCapabilityIDs.map(\.rawValue).contains("tool.git"),
      "CMP + TAP smoke expected tool.git to appear in TAP availability."
    )
    try require(
      tapInspection.latestDecisionSummary?.contains("Approved git access") == true,
      "CMP + TAP smoke expected inspectTap to surface the latest reviewer decision."
    )
    try require(
      reviewWorkbench.latestDecisionSummary?.contains("Approved git access") == true,
      "CMP + TAP smoke expected the reviewer workbench to surface the latest reviewer decision."
    )
    try require(
      reviewWorkbench.queueItems.isEmpty == false,
      "CMP + TAP smoke expected the reviewer workbench to expose at least one queue item."
    )

    return "projectID=\(smoke.projectID) smokeChecks=\(smoke.smokeResult.checks.count) tapHistory=\(tapOverview.history.totalCount) tapSections=\(tapInspection.sections.count) workbenchQueue=\(reviewWorkbench.queueItems.count)"
  }

  private func mpSuite() async throws -> String {
    let project = client.mp.project("mp.local-runtime")

    let overview = try await project.overview(limit: 5)
    let smoke = try await project.smoke()
    let search = try await project.search(query: "onboarding", scopeLevels: [.project], limit: 5)
    let resolve = try await project.resolve(
      query: "onboarding",
      requesterAgent: "runtime.local",
      scopeLevels: [.project],
      limit: 5
    )
    let history = try await project.history(
      query: "onboarding",
      requesterAgent: "runtime.local",
      reason: "Need historical context",
      scopeLevels: [.project],
      limit: 5
    )

    try require(overview.projectID == "mp.local-runtime", "MP smoke expected the project overview to keep the scoped project ID.")
    try require(smoke.projectID == "mp.local-runtime", "MP smoke expected the smoke snapshot to keep the scoped project ID.")
    try require(search.query == "onboarding", "MP smoke expected the search query to round-trip unchanged.")
    try require(resolve.query == "onboarding", "MP smoke expected the resolve query to round-trip unchanged.")
    try require(history.query == "onboarding", "MP smoke expected the history query to round-trip unchanged.")

    return "projectID=\(overview.projectID) smokeChecks=\(smoke.smokeResult.checks.count) hits=\(search.hits.count)"
  }

  private func provisioningSuite() async throws -> String {
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
        requiredVerification: ["shell.exec smoke"],
        replayPolicy: .reReviewThenDispatch
      )
    )
    let stagedProvisioning = try await tapProject.provisioning()
    let provisioning = try await tapProject.advanceReplay(
      .init(
        agentID: "runtime.local",
        replayID: .init(staged.pendingReplayID),
        action: .activate
      )
    )
    let inspection = try await tapProject.inspect(historyLimit: 10)
    let workbench = try await tapProject.reviewWorkbench(for: "checker.local", limit: 10)
    let recoveredClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let recoveredTapProject = recoveredClient.tap.project("cmp.local-runtime")
    let recoveredProvisioning = try await recoveredTapProject.provisioning()
    let recoveredWorkbench = try await recoveredTapProject.reviewWorkbench(for: "checker.local", limit: 10)

    try require(
      requested.outcome == .redirectedToProvisioning,
      "Provisioning smoke expected shell execution approval to redirect into provisioning."
    )
    try require(staged.capabilityID == "tool.shell.exec", "Provisioning smoke expected the staged capability ID to round-trip unchanged.")
    try require(
      staged.pendingReplayNextAction == .reReviewThenDispatch,
      "Provisioning smoke expected the pending replay to require re-review before dispatch."
    )
    try require(provisioning.found, "Provisioning smoke expected the durable provisioning readback to be available.")
    try require(
      stagedProvisioning.activeReplayCount == 1,
      "Provisioning smoke expected one active replay record immediately after staging."
    )
    try require(
      provisioning.activationStatus == .completed,
      "Provisioning smoke expected explicit replay activation to complete the activation receipt."
    )
    try require(
      provisioning.primaryReplay?.status == .ready,
      "Provisioning smoke expected explicit replay activation to move the replay into ready state."
    )
    try require(
      inspection.runSummary.contains("replay record"),
      "Provisioning smoke expected TAP inspection to surface persisted pending replay evidence."
    )
    try require(
      inspection.sections.contains { $0.sectionID == "activation-replay" },
      "Provisioning smoke expected TAP inspection to expose an activation/replay section."
    )
    try require(
      workbench.latestDecisionSummary?.contains("is ready") == true,
      "Provisioning smoke expected the reviewer workbench to surface the replay-ready activation summary."
    )
    try require(
      workbench.provisioning == provisioning,
      "Provisioning smoke expected the reviewer workbench to embed the same durable provisioning readback."
    )
    try require(
      recoveredProvisioning.activeReplayCount == provisioning.activeReplayCount,
      "Provisioning smoke expected a fresh client to recover the same active replay count."
    )
    try require(
      recoveredWorkbench.provisioning == recoveredProvisioning,
      "Provisioning smoke expected a recovered reviewer workbench to keep the durable provisioning readback."
    )

    return
      "capability=\(staged.capabilityID) replay=\(staged.pendingReplayID) activeReplays=\(provisioning.activeReplayCount) recoveredReplay=\(recoveredProvisioning.primaryReplay?.status.rawValue ?? "none")"
  }

  private func dispatchSuite() async throws -> String {
    let projectID = PraxisRuntimeProjectRef("cmp.local-runtime")
    let cmpProject = client.cmp.project(projectID)
    let tapProject = client.tap.project(projectID)

    _ = try await runtimeFacade.cmpFacade.bootstrapProject(
      .init(
        projectID: projectID.rawValue,
        agentIDs: ["runtime.local", "checker.local"],
        defaultAgentID: "runtime.local"
      )
    )
    let ingest = try await runtimeFacade.cmpFlowFacade.ingestCmpFlowUseCase.execute(
      .init(
        projectID: projectID.rawValue,
        agentID: "runtime.local",
        sessionID: "cmp.runtime-kit-dispatch",
        taskSummary: "Capture runtime context for dispatch smoke",
        materials: [.init(kind: .userInput, ref: "payload:user:runtime-kit-dispatch-smoke")],
        requiresActiveSync: true
      )
    )
    _ = try await runtimeFacade.cmpFlowFacade.commitCmpFlowUseCase.execute(
      .init(
        projectID: projectID.rawValue,
        agentID: "runtime.local",
        sessionID: "cmp.runtime-kit-dispatch",
        eventIDs: ingest.result.acceptedEventIDs,
        changeSummary: "Commit dispatch smoke context",
        syncIntent: .toParent
      )
    )
    _ = try await client.runs.run(
      task: "Seed dispatch smoke projection",
      sessionID: "session.runtime-kit-dispatch"
    )
    _ = try await runtimeFacade.cmpFlowFacade.resolveCmpFlowUseCase.execute(
      .init(projectID: projectID.rawValue, agentID: "runtime.local")
    )
    let staged = try await tapProject.provision(
      PraxisRuntimeTapProvisionRequest(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: PraxisTapCapabilityTier.b2,
        summary: "Stage shell execution provisioning before dispatch smoke",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"],
        replayPolicy: PraxisProvisionReplayPolicy.reReviewThenDispatch
      )
    )
    _ = try await tapProject.advanceReplay(
      PraxisRuntimeTapReplayRequest(
        agentID: "runtime.local",
        replayID: PraxisRuntimeReplayRef(staged.pendingReplayID),
        action: PraxisReplayLifecycleAction.activate
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
        reason: "Dispatch persisted package through RuntimeKit smoke"
      )
    )
    let provisioning = try await tapProject.provisioning()

    try require(dispatched.status == PraxisCmpDispatchStatus.delivered, "Dispatch smoke expected the persisted package dispatch to deliver.")
    try require(provisioning.activationStatus == PraxisActivationAttemptStatus.completed, "Dispatch smoke expected replay activation to remain completed after delivery.")
    try require(provisioning.activeReplayCount == 0, "Dispatch smoke expected delivery to consume the ready replay record.")
    try require(
      provisioning.replayRecords.first?.status == PraxisReplayStatus.consumed,
      "Dispatch smoke expected the primary replay record to transition into consumed."
    )

    return
      "package=\(materialized.packageID.rawValue) dispatch=\(dispatched.dispatchID.rawValue) status=\(dispatched.status.rawValue) replay=\(provisioning.replayRecords.first?.status.rawValue ?? "none")"
  }

  private func recoverySuite() async throws -> String {
    let recoveryProjectID = "cmp.recovery-runtime"
    let firstClient = client
    let startedRun = try await firstClient.runs.run(
      task: "Recover runtime checkpoint state",
      sessionID: "session.runtime-kit-recovery"
    )

    let cmpProject = firstClient.cmp.project(.init(recoveryProjectID))
    _ = try await cmpProject.openSession("cmp.runtime-kit-recovery")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Escalate git access to checker for recovery smoke"
      )
    )
    _ = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved git access for recovery smoke"
      )
    )

    let secondClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let resumedRun = try await secondClient.runs.resume(.init(startedRun.runID.rawValue))
    let recoveredTapProject = secondClient.tap.project(.init(recoveryProjectID))
    let recoveredInspection = try await recoveredTapProject.inspect(historyLimit: 10)
    let recoveredWorkbench = try await recoveredTapProject.reviewWorkbench(for: "checker.local", limit: 10)
    let recoveredOverview = try await recoveredTapProject.overview(for: "checker.local", limit: 10)

    try require(resumedRun.runID == startedRun.runID, "Recovery smoke expected the resumed run ID to match the started run.")
    try require(
      resumedRun.checkpointReference == startedRun.checkpointReference,
      "Recovery smoke expected the resumed run to keep the same checkpoint reference."
    )
    try require(
      recoveredInspection.latestDecisionSummary?.contains("Approved git access for recovery smoke") == true,
      "Recovery smoke expected a fresh client to recover the latest TAP approval decision from durable state."
    )
    try require(
      recoveredWorkbench.latestDecisionSummary?.contains("Approved git access for recovery smoke") == true,
      "Recovery smoke expected the recovered reviewer workbench to surface the latest TAP approval decision."
    )
    try require(
      recoveredWorkbench.pendingItems.isEmpty,
      "Recovery smoke expected no pending reviewer items after the approval was resolved."
    )
    try require(
      recoveredOverview.latestDecisionSummary?.contains("Approved git access for recovery smoke") == true,
      "Recovery smoke expected TAP overview to recover the latest approval decision after client restart."
    )

    return "runID=\(resumedRun.runID.rawValue) recoveredEvents=\(resumedRun.recoveredEventCount) checkpoint=\(resumedRun.checkpointReference ?? "none") reviewDecision=\(recoveredWorkbench.latestDecisionSummary ?? "none")"
  }

  private func capabilitiesSuite() async throws -> String {
    let catalog = client.capabilities.catalog()
    let openedSession = try await client.capabilities.openSession(
      .init(
        sessionID: "runtime.capabilities.smoke",
        title: "Runtime Capability Smoke"
      )
    )
    let generated = try await client.capabilities.generate(
      .init(
        prompt: "Summarize the local thin capability baseline",
        preferredModel: "local-smoke-model",
        requiredCapabilities: ["generate.create", "embed.create"]
      )
    )
    let streamed = try await client.capabilities.stream(
      .init(
        prompt: "Stream a short capability summary",
        preferredModel: "local-smoke-model"
      ),
      chunkCharacterCount: 32
    )
    let embedded = try await client.capabilities.embed(
      .init(
        content: "phase three thin capability baseline",
        preferredModel: "local-embed-smoke"
      )
    )
    let sandbox = try await client.capabilities.describeCodeSandbox(
      .init(
        workingDirectory: rootDirectory.path,
        requestedRuntime: .swift
      )
    )
    let codeAvailable = catalog.capabilityIDs.map(\.rawValue).contains("code.run")
    let code = codeAvailable ? try await client.capabilities.runCode(
      .init(
        summary: "Print a bounded code smoke marker",
        runtime: .swift,
        source: "print(\"runtime-kit-code-capability-smoke\")",
        workingDirectory: rootDirectory.path,
        timeoutSeconds: 2
      )
    ) : nil
    let shell = try await client.capabilities.runShell(
      .init(
        summary: "Print a bounded shell smoke marker",
        command: "printf 'runtime-kit-shell-capability-smoke\\n'",
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
        summary: "Request bounded shell approval during capability smoke"
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
        reason: "Capability smoke coverage"
      )
    )
    let listedProviderMCPTools = try await client.capabilities.listProviderMCPTools()
    let toolCall = try await client.capabilities.callTool(
      .init(
        toolName: "web.search",
        summary: "Find RuntimeKit capability docs",
        serverName: "local-smoke"
      )
    )
    let uploadedFile = try await client.capabilities.uploadFile(
      .init(
        summary: "runtime capability smoke artifact",
        purpose: "analysis"
      )
    )
    let submittedBatch = try await client.capabilities.submitBatch(
      .init(
        summary: "runtime capability smoke batch",
        itemCount: 2
      )
    )

    try require(catalog.capabilityIDs.map(\.rawValue).contains("generate.create"), "Capability smoke expected generate.create in the thin capability catalog.")
    try require(catalog.capabilityIDs.map(\.rawValue).contains("code.sandbox"), "Capability smoke expected code.sandbox in the thin capability catalog.")
    try require(catalog.capabilityIDs.map(\.rawValue).contains("shell.approve"), "Capability smoke expected shell.approve in the thin capability catalog.")
    try require(catalog.capabilityIDs.map(\.rawValue).contains("session.open"), "Capability smoke expected session.open in the thin capability catalog.")
    try require(catalog.capabilityIDs.map(\.rawValue).contains("shell.run"), "Capability smoke expected shell.run in the thin capability catalog.")
    try require(catalog.capabilityIDs.map(\.rawValue).contains("skill.list"), "Capability smoke expected skill.list in the thin capability catalog.")
    try require(catalog.capabilityIDs.map(\.rawValue).contains("skill.activate"), "Capability smoke expected skill.activate in the thin capability catalog.")
    try require(openedSession.sessionID.rawValue == "runtime.capabilities.smoke", "Capability smoke expected the opened session ID to round-trip unchanged.")
    try require(generated.outputText.isEmpty == false, "Capability smoke expected generate.create to produce output.")
    try require(streamed.chunks.isEmpty == false, "Capability smoke expected generate.stream to project at least one chunk.")
    try require(embedded.vectorLength > 0, "Capability smoke expected embed.create to return a positive vector length.")
    try require(sandbox.capabilityID.rawValue == "code.sandbox", "Capability smoke expected code.sandbox capability ID.")
    try require(sandbox.profile == .workspaceWriteLimited, "Capability smoke expected code.sandbox to keep the requested profile.")
    try require(sandbox.writableRoots == [rootDirectory.path], "Capability smoke expected code.sandbox to declare the workspace root as writable.")
    try require(sandbox.readableRoots.contains(rootDirectory.path), "Capability smoke expected code.sandbox to include the workspace root as readable.")
    try require(sandbox.allowsNetworkAccess == false, "Capability smoke expected code.sandbox to default network access to false.")
    try require(sandbox.allowsSubprocesses == false, "Capability smoke expected code.sandbox to default subprocess access to false.")
    if let code {
      try require(code.capabilityID.rawValue == "code.run", "Capability smoke expected code.run capability ID.")
      try require(code.runtime == .swift, "Capability smoke expected code.run to keep the requested runtime.")
      try require(code.riskLabel == "risky", "Capability smoke expected code.run to expose the risky side-effect label.")
    } else {
      try require(!codeAvailable, "Capability smoke expected code.run to be absent only when the catalog withholds it.")
    }
    try require(shellApproval.capabilityID.rawValue == "shell.approve", "Capability smoke expected shell.approve capability ID.")
    try require(shellApproval.approvedCapabilityID.rawValue == "shell.run", "Capability smoke expected shell.approve to point at shell.run.")
    try require(shellApproval.riskLevel == "risky", "Capability smoke expected shell.approve to preserve the risky shell classification.")
    try require(shellApproval.outcome == "review_required", "Capability smoke expected shell.approve to stay on the review path when shell.run is already registered.")
    try require(shellApprovalReadback.found, "Capability smoke expected shell.approve readback to recover the persisted approval state.")
    try require(shellApprovalReadback.riskLevel == "risky", "Capability smoke expected shell.approve readback to preserve the risky shell classification.")
    try require(shellApprovalReadback.outcome == "review_required", "Capability smoke expected shell.approve readback to preserve the review-required outcome.")
    try require(shell.riskLabel == "risky", "Capability smoke expected shell.run to expose the risky side-effect label.")
    try require(listedSkills.skillKeys.contains("runtime.inspect"), "Capability smoke expected skill.list to expose runtime.inspect.")
    try require(activatedSkill.skillKey == "runtime.inspect", "Capability smoke expected skill.activate to preserve the requested skill key.")
    try require(activatedSkill.activated, "Capability smoke expected skill.activate to report an activated receipt.")
    try require(listedProviderMCPTools.toolNames == ["web.search"], "Capability smoke expected provider MCP tool discovery to expose web.search.")
    try require(toolCall.toolName == "web.search", "Capability smoke expected tool.call to round-trip the tool name.")
    try require(uploadedFile.fileID.isEmpty == false, "Capability smoke expected file.upload to return a stable file ID.")
    try require(submittedBatch.batchID.isEmpty == false, "Capability smoke expected batch.submit to return a stable batch ID.")
    let patchSummary: String
    if catalog.capabilityIDs.map(\.rawValue).contains("code.patch") {
      let patchTargetURL = rootDirectory.appendingPathComponent("capability-patch.txt", isDirectory: false)
      try "before\nvalue\n".write(to: patchTargetURL, atomically: true, encoding: .utf8)
      let patch = try await client.capabilities.patchCode(
        .init(
          summary: "Patch one bounded workspace smoke file",
          changes: [
            .init(
              path: "capability-patch.txt",
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
      try require(patch.capabilityID.rawValue == "code.patch", "Capability smoke expected code.patch capability ID.")
      try require(patch.appliedChangeCount == 1, "Capability smoke expected code.patch to apply exactly one change.")
      try require(patch.changedPaths == ["capability-patch.txt"], "Capability smoke expected code.patch to preserve the changed path.")
      try require(patch.riskLabel == "risky", "Capability smoke expected code.patch to expose the risky side-effect label.")
      let patchedContents = try String(contentsOf: patchTargetURL, encoding: .utf8)
      try require(
        patchedContents == "before\nafter",
        "Capability smoke expected code.patch to update the target file contents."
      )
      patchSummary = "patchCount=\(patch.appliedChangeCount)"
    } else {
      patchSummary = "patch=unavailable"
    }

    let codeSummary = code?.riskLabel ?? "unavailable"
    return "catalogEntries=\(catalog.entries.count) session=\(openedSession.sessionID.rawValue) sandbox=\(sandbox.enforcementMode.rawValue) codeRisk=\(codeSummary) \(patchSummary) shellApproval=\(shellApproval.outcome) shellRisk=\(shell.riskLabel) skillActivation=\(activatedSkill.activated) mcpTools=\(listedProviderMCPTools.toolNames.count) streamChunks=\(streamed.chunks.count) batchID=\(submittedBatch.batchID)"
  }

  private func codeSuite() async throws -> String {
    let catalog = client.capabilities.catalog()
    guard catalog.capabilityIDs.map(\.rawValue).contains("code.run") else {
      return "unavailable"
    }

    let result = try await client.capabilities.runCode(
      .init(
        summary: "Emit one bounded code smoke marker",
        runtime: .swift,
        source: "print(\"runtime-kit-code-smoke\")",
        workingDirectory: rootDirectory.path,
        timeoutSeconds: 2
      )
    )

    try require(result.capabilityID.rawValue == "code.run", "Code smoke expected code.run capability ID.")
    try require(result.runtime == .swift, "Code smoke expected the runtime to stay on swift.")
    try require(result.riskLabel == "risky", "Code smoke expected risky side-effect labeling.")
    try require(result.environmentKeys.isEmpty, "Code smoke expected environment key projection to stay empty.")
#if os(macOS)
    try require(result.succeeded, "Code smoke expected the macOS baseline code executor to complete successfully.")
    try require(
      result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "runtime-kit-code-smoke",
      "Code smoke expected the bounded stdout marker to round-trip unchanged."
    )
#else
    try require(
      result.terminationReason == .failedToLaunch,
      "Code smoke expected non-macOS baseline to report placeholder launch failure."
    )
    try require(
      result.stderr.contains("not available") || result.stderr.contains("unsupported"),
      "Code smoke expected placeholder stderr to explain the unsupported code baseline."
    )
#endif

    return "exit=\(result.exitCode) runtime=\(result.runtime.rawValue) termination=\(result.terminationReason.rawValue) risk=\(result.riskLabel)"
  }

  private func codeSandboxSuite() async throws -> String {
    let catalog = client.capabilities.catalog()
    try require(
      catalog.capabilityIDs.map(\.rawValue).contains("code.sandbox"),
      "Code sandbox smoke expected code.sandbox in the thin capability catalog."
    )

    let result = try await client.capabilities.describeCodeSandbox(
      .init(
        workingDirectory: rootDirectory.path,
        requestedRuntime: .swift
      )
    )

    try require(result.capabilityID.rawValue == "code.sandbox", "Code sandbox smoke expected code.sandbox capability ID.")
    try require(result.profile == .workspaceWriteLimited, "Code sandbox smoke expected the workspace_write_limited profile.")
    try require(result.writableRoots == [rootDirectory.path], "Code sandbox smoke expected the workspace root to remain the writable root.")
    try require(result.readableRoots.contains(rootDirectory.path), "Code sandbox smoke expected the workspace root to remain readable.")
    try require(result.allowsNetworkAccess == false, "Code sandbox smoke expected network access to stay disabled.")
    try require(result.allowsSubprocesses == false, "Code sandbox smoke expected subprocess access to stay disabled.")

    return "profile=\(result.profile.rawValue) enforcement=\(result.enforcementMode.rawValue) runtimes=\(result.allowedRuntimes.map(\.rawValue).joined(separator: ",")) writableRoots=\(result.writableRoots.count)"
  }

  private func codePatchSuite() async throws -> String {
    let catalog = client.capabilities.catalog()
    guard catalog.capabilityIDs.map(\.rawValue).contains("code.patch") else {
      return "unavailable"
    }

    let patchTargetURL = rootDirectory.appendingPathComponent("code-patch-smoke.txt", isDirectory: false)
    try "alpha\nbeta\n".write(to: patchTargetURL, atomically: true, encoding: .utf8)
    let result = try await client.capabilities.patchCode(
      .init(
        summary: "Apply one bounded code patch smoke marker",
        changes: [
          .init(
            path: "code-patch-smoke.txt",
            patch: """
            @@ -1,2 +1,2 @@
             alpha
            -beta
            +patched
            """
          )
        ]
      )
    )

    try require(result.capabilityID.rawValue == "code.patch", "Code patch smoke expected code.patch capability ID.")
    try require(result.appliedChangeCount == 1, "Code patch smoke expected exactly one applied change.")
    try require(result.changedPaths == ["code-patch-smoke.txt"], "Code patch smoke expected the changed path to round-trip.")
    try require(result.riskLabel == "risky", "Code patch smoke expected risky side-effect labeling.")
    let patchedContents = try String(contentsOf: patchTargetURL, encoding: .utf8)
    try require(
      patchedContents == "alpha\npatched",
      "Code patch smoke expected the bounded patch to update file contents."
    )

    return "count=\(result.appliedChangeCount) path=\(result.changedPaths.joined(separator: ",")) risk=\(result.riskLabel)"
  }

  private func shellSuite() async throws -> String {
    let result = try await client.capabilities.runShell(
      .init(
        summary: "Emit one bounded shell smoke marker",
        command: "printf 'runtime-kit-shell-smoke\\n'",
        workingDirectory: rootDirectory.path,
        timeoutSeconds: 2
      )
    )

    try require(result.capabilityID.rawValue == "shell.run", "Shell smoke expected shell.run capability ID.")
    try require(result.riskLabel == "risky", "Shell smoke expected risky side-effect labeling.")
    try require(result.environmentKeys.isEmpty, "Shell smoke expected environment key projection to stay empty.")
#if os(macOS)
    try require(result.succeeded, "Shell smoke expected the macOS baseline shell executor to complete successfully.")
    try require(
      result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "runtime-kit-shell-smoke",
      "Shell smoke expected the bounded stdout marker to round-trip unchanged."
    )
#else
    try require(
      result.terminationReason == .failedToLaunch,
      "Shell smoke expected non-macOS baseline to report placeholder launch failure."
    )
    try require(
      result.stderr.contains("not available") || result.stderr.contains("unsupported"),
      "Shell smoke expected placeholder stderr to explain the unsupported shell baseline."
    )
#endif

    return "exit=\(result.exitCode) termination=\(result.terminationReason.rawValue) risk=\(result.riskLabel)"
  }

  private func shellApprovalSuite() async throws -> String {
    let requested = try await client.capabilities.requestShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        requestedTier: .b2,
        summary: "Request bounded shell approval during dedicated shell approval smoke"
      )
    )
    let readback = try await client.capabilities.readbackShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local"
      )
    )
    let recoveredClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let recoveredReadback = try await recoveredClient.capabilities.readbackShellApproval(
      .init(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local"
      )
    )

    try require(requested.capabilityID.rawValue == "shell.approve", "Shell approval smoke expected shell.approve capability ID.")
    try require(requested.approvedCapabilityID.rawValue == "shell.run", "Shell approval smoke expected shell.run to be the approved capability surface.")
    try require(requested.riskLevel == "risky", "Shell approval smoke expected the approval request to stay on a risky shell capability key.")
    try require(requested.outcome == "review_required", "Shell approval smoke expected the bounded shell approval to stay on the review path.")
    try require(readback.found, "Shell approval smoke expected persisted approval readback.")
    try require(readback.approvedCapabilityID?.rawValue == "shell.run", "Shell approval smoke expected the readback capability to stay normalized to shell.run.")
    try require(readback.riskLevel == "risky", "Shell approval smoke expected persisted readback to keep the risky shell classification.")
    try require(recoveredReadback.found, "Shell approval smoke expected a fresh client to recover the approval readback.")
    try require(recoveredReadback.outcome == readback.outcome, "Shell approval smoke expected recovered readback to preserve the latest approval outcome.")
    try require(recoveredReadback.humanGateState == readback.humanGateState, "Shell approval smoke expected recovered readback to preserve the human gate state.")

    return "outcome=\(requested.outcome) humanGate=\(readback.humanGateState ?? "none") recovered=\(recoveredReadback.outcome ?? "none")"
  }

  private func searchSuite() async throws -> String {
    let webSearch = try await client.capabilities.searchWeb(
      .init(
        query: "Swift runtime capability search chain",
        locale: "en-US",
        preferredDomains: ["example.com", "docs.example.com"],
        limit: 2
      )
    )
    let firstResult = try requireValue(webSearch.results.first, "Search smoke expected at least one web result.")
    let fetched = try await client.capabilities.fetchSearchResult(
      .init(
        url: firstResult.url,
        preferredTitle: firstResult.title,
        waitPolicy: .networkIdle
      )
    )
    let grounded = try await client.capabilities.groundSearchResult(
      .init(
        taskSummary: "Verify one runtime capability search result",
        exampleURL: fetched.finalURL,
        requestedFacts: ["final_url", "host", "page_title"],
        locale: "en-US",
        maxPages: 2
      )
    )

    try require(webSearch.capabilityID.rawValue == "search.web", "Search smoke expected search.web capability ID.")
    try require(fetched.capabilityID.rawValue == "search.fetch", "Search smoke expected search.fetch capability ID.")
    try require(grounded.capabilityID.rawValue == "search.ground", "Search smoke expected search.ground capability ID.")
    try require(grounded.pages.isEmpty == false, "Search smoke expected grounded pages.")
    try require(grounded.facts.count == 3, "Search smoke expected three grounded facts.")

    return "results=\(webSearch.results.count) finalURL=\(fetched.finalURL) groundedFacts=\(grounded.facts.count)"
  }

  private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
      throw PraxisRuntimeKitSmokeFailure.assertion(message)
    }
  }

  private func requireValue<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
      throw PraxisRuntimeKitSmokeFailure.assertion(message)
    }
    return value
  }
}

private enum PraxisRuntimeKitSmokeArguments {
  static func parse(_ arguments: [String]) throws -> (suite: PraxisRuntimeKitSmokeSuite, rootDirectory: URL) {
    var suiteRawValue: String?
    var rootDirectoryPath: String?

    var index = 0
    while index < arguments.count {
      switch arguments[index] {
      case "--suite":
        index += 1
        guard index < arguments.count else {
          throw PraxisRuntimeKitSmokeFailure.invalidArguments("Missing value after --suite.")
        }
        suiteRawValue = arguments[index]
      case "--root":
        index += 1
        guard index < arguments.count else {
          throw PraxisRuntimeKitSmokeFailure.invalidArguments("Missing value after --root.")
        }
        rootDirectoryPath = arguments[index]
      case "--help", "-h":
        throw PraxisRuntimeKitSmokeFailure.invalidArguments(
          "Usage: swift run PraxisRuntimeKitSmoke [--suite run|cmp-tap|provisioning|dispatch|recovery|mp|capabilities|code|code-patch|shell|shell-approval|search|all] [--root /tmp/praxis-runtime-kit-smoke]"
        )
      default:
        throw PraxisRuntimeKitSmokeFailure.invalidArguments("Unknown argument '\(arguments[index])'.")
      }
      index += 1
    }

    let suite = try PraxisRuntimeKitSmokeSuite.parse(suiteRawValue)
    let rootDirectory: URL
    if let rootDirectoryPath {
      rootDirectory = URL(fileURLWithPath: rootDirectoryPath, isDirectory: true)
    } else {
      rootDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("praxis-runtime-kit-smoke", isDirectory: true)
        .appendingPathComponent(UUID().uuidString.lowercased(), isDirectory: true)
    }

    return (suite, rootDirectory)
  }
}

@main
struct PraxisRuntimeKitSmokeMain {
  static func main() async throws {
    let parsed = try PraxisRuntimeKitSmokeArguments.parse(Array(CommandLine.arguments.dropFirst()))
    try FileManager.default.createDirectory(at: parsed.rootDirectory, withIntermediateDirectories: true)

    let harness = try PraxisRuntimeKitSmokeHarness(rootDirectory: parsed.rootDirectory)
    let results = await harness.run(parsed.suite)

    print("Praxis RuntimeKit Smoke")
    print("rootDirectory: \(parsed.rootDirectory.path)")
    print("suite: \(parsed.suite.rawValue)")
    for result in results {
      print("[\(result.status.rawValue)] \(result.suite.rawValue): \(result.summary)")
      if let remediation = result.remediation {
        print("  remediation: \(remediation)")
      }
    }

    let failedResults = results.filter { $0.status == .failed }
    if !failedResults.isEmpty {
      throw PraxisRuntimeKitSmokeFailure.suiteFailures(failedResults)
    }
  }
}
