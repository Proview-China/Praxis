import Foundation
import PraxisRuntimeKit

private struct DurableRuntimeExampleFailure: LocalizedError {
  let message: String

  var errorDescription: String? {
    message
  }
}

private func makeRuntimeRoot(named name: String) throws -> URL {
  let rootDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("praxis-examples", isDirectory: true)
    .appendingPathComponent(name, isDirectory: true)
    .appendingPathComponent(UUID().uuidString.lowercased(), isDirectory: true)
  try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
  return rootDirectory
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
  guard condition() else {
    throw DurableRuntimeExampleFailure(message: message)
  }
}

private func requireValue<T>(_ value: T?, _ message: String) throws -> T {
  guard let value else {
    throw DurableRuntimeExampleFailure(message: message)
  }
  return value
}

@main
struct PraxisRuntimeKitDurableRuntimeExample {
  static func main() async throws {
    let rootDirectory = try makeRuntimeRoot(named: "runtime-kit-durable")
    let initialClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    let startedRun = try await initialClient.runs.run(
      .init(
        task: "Recover durable runtime caller-facing evidence",
        sessionID: "session.runtime-kit-durable"
      )
    )

    let resumedClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let resumedRun = try await resumedClient.runs.resume(.init(startedRun.runID.rawValue))

    let projectID: PraxisRuntimeProjectRef = "cmp.runtime-kit-durable"
    let cmpProject = resumedClient.cmp.project(projectID)
    let tapProject = resumedClient.tap.project(projectID)

    _ = try await cmpProject.openSession("cmp.runtime-kit-durable")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Redirect durable runtime example into provisioning"
      )
    )

    let stagedProvisioning = try await tapProject.provision(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Stage durable runtime example provisioning for checker",
        expectedArtifacts: ["shell.exec binding"],
        requiredVerification: ["shell.exec smoke"],
        replayPolicy: .reReviewThenDispatch
      )
    )
    let provisioningReadback = try await tapProject.provisioning()
    let activatedProvisioning = try await tapProject.advanceReplay(
      .init(
        agentID: "runtime.local",
        replayID: .init(stagedProvisioning.pendingReplayID),
        action: .activate
      )
    )

    let recoveredClient = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let recoveredTapProject = recoveredClient.tap.project(projectID)
    let recoveredProvisioning = try await recoveredTapProject.provisioning()
    let recoveredWorkbench = try await recoveredTapProject.reviewWorkbench(for: "checker.local", limit: 10)

    try require(resumedRun.runID == startedRun.runID, "Expected the resumed run to keep the original run ID.")
    try require(
      resumedRun.checkpointReference == startedRun.checkpointReference,
      "Expected the resumed run to keep the original checkpoint reference."
    )
    try require(provisioningReadback.found, "Expected project-scoped provisioning readback to be available after staging.")
    try require(
      provisioningReadback.primaryReplay?.replayID == stagedProvisioning.pendingReplayID,
      "Expected staged replay ID to round-trip through provisioning readback."
    )
    try require(recoveredProvisioning.found, "Expected recovered provisioning readback to stay available on a fresh client.")
    try require(
      recoveredProvisioning.primaryReplay?.replayID == stagedProvisioning.pendingReplayID,
      "Expected the fresh client to recover the staged replay ID."
    )
    try require(
      recoveredWorkbench.provisioning == recoveredProvisioning,
      "Expected the recovered workbench to embed the same durable provisioning readback."
    )

    let resumedCheckpointReference = try requireValue(
      resumedRun.checkpointReference,
      "Expected the resumed run to surface a checkpoint reference."
    )
    let recoveredReplayStatus = try requireValue(
      recoveredProvisioning.primaryReplay?.status,
      "Expected the recovered provisioning readback to expose a replay status."
    )
    let activationStatus = try requireValue(
      activatedProvisioning.activationStatus,
      "Expected replay activation to surface an activation status."
    )

    try require(
      activationStatus == .completed,
      "Expected replay activation to complete for the durable runtime example."
    )

    print("Praxis RuntimeKit Durable Runtime Example")
    print("run.id: \(startedRun.runID.rawValue)")
    print("resumed.checkpoint: \(resumedCheckpointReference)")
    print("staged.replay: \(stagedProvisioning.pendingReplayID)")
    print("provisioning.activationStatus: \(activationStatus.rawValue)")
    print("recovered.replayStatus: \(recoveredReplayStatus.rawValue)")
    print("recovered.workbench.provisioningSummary: \(recoveredWorkbench.provisioning.summary)")
  }
}
