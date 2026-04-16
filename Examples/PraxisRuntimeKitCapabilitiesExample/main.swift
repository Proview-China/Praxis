import Foundation
import PraxisRuntimeKit

@main
struct PraxisRuntimeKitCapabilitiesExampleMain {
  static func main() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-runtime-kit-capabilities-example", isDirectory: true)
      .appendingPathComponent(UUID().uuidString.lowercased(), isDirectory: true)
    try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)
    let catalog = client.capabilities.catalog()
    let session = try await client.capabilities.openSession(
      .init(
        sessionID: "runtime.capabilities.example",
        title: "Runtime Capability Example"
      )
    )
    let generated = try await client.capabilities.generate(
      .init(
        prompt: "Summarize the RuntimeKit thin capability baseline",
        preferredModel: "local-example-model",
        requiredCapabilities: ["generate.create", "tool.call"]
      )
    )
    let streamed = try await client.capabilities.stream(
      .init(
        prompt: "Provide a short streaming capability summary",
        preferredModel: "local-example-model"
      ),
      chunkCharacterCount: 28
    )
    let embedded = try await client.capabilities.embed(
      .init(
        content: "runtime capability baseline example",
        preferredModel: "local-embed-example"
      )
    )
    let sandbox = try await client.capabilities.describeCodeSandbox(
      .init(
        workingDirectory: rootDirectory.path,
        requestedRuntime: .swift
      )
    )
    let codeSummary: String
    if catalog.capabilityIDs.map(\.rawValue).contains("code.run") {
      let code = try await client.capabilities.runCode(
        .init(
          summary: "Print a bounded code marker",
          runtime: .swift,
          source: "print(\"runtime-kit-code-example\")",
          workingDirectory: rootDirectory.path,
          timeoutSeconds: 2
        )
      )
      codeSummary = "runtime=\(code.runtime.rawValue) risk=\(code.riskLabel) exit=\(code.exitCode) output=\(code.stdout.trimmingCharacters(in: .whitespacesAndNewlines))"
    } else {
      codeSummary = "unavailable on this host profile"
    }
    let patchSummary: String
    if catalog.capabilityIDs.map(\.rawValue).contains("code.patch") {
      let patchTargetURL = rootDirectory.appendingPathComponent("example-patch.txt", isDirectory: false)
      try "before\nvalue\n".write(to: patchTargetURL, atomically: true, encoding: .utf8)
      let patch = try await client.capabilities.patchCode(
        .init(
          summary: "Patch one bounded workspace file",
          changes: [
            .init(
              path: "example-patch.txt",
              patch: """
              @@ -1,2 +1,2 @@
               before
              -value
              +patched
              """
            )
          ]
        )
      )
      patchSummary = "count=\(patch.appliedChangeCount) paths=\(patch.changedPaths.joined(separator: ", ")) risk=\(patch.riskLabel)"
    } else {
      patchSummary = "unavailable on this host profile"
    }
    let shell = try await client.capabilities.runShell(
      .init(
        summary: "Print a bounded shell marker",
        command: "printf 'runtime-kit-shell-example\\n'",
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
        summary: "Request bounded shell execution for the capabilities example"
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
        reason: "Exercise the provider skill baseline"
      )
    )
    let listedProviderMCPTools = try await client.capabilities.listProviderMCPTools()
    let toolCall = try await client.capabilities.callTool(
      .init(
        toolName: "web.search",
        summary: "Find capability baseline docs",
        serverName: "local-example"
      )
    )
    let uploadedFile = try await client.capabilities.uploadFile(
      .init(
        summary: "runtime capability example artifact",
        purpose: "analysis"
      )
    )
    let submittedBatch = try await client.capabilities.submitBatch(
      .init(
        summary: "runtime capability example batch",
        itemCount: 3
      )
    )

    print("Thin capability catalog: \(catalog.capabilityIDs.map(\.rawValue).joined(separator: ", "))")
    print("Opened session: \(session.sessionID.rawValue) (\(session.title))")
    print("Generate summary: \(generated.summary)")
    print("Generate output: \(generated.outputText)")
    print("Stream chunks: \(streamed.chunks.map(\.text).joined(separator: " | "))")
    print("Embedding vector length: \(embedded.vectorLength)")
    print("Code sandbox: profile=\(sandbox.profile.rawValue) enforcement=\(sandbox.enforcementMode.rawValue) writableRoots=\(sandbox.writableRoots.joined(separator: ", "))")
    print("Code run: \(codeSummary)")
    print("Code patch: \(patchSummary)")
    print("Shell approval: capability=\(shellApproval.approvedCapabilityID.rawValue) outcome=\(shellApproval.outcome)")
    print("Shell approval readback found: \(shellApprovalReadback.found)")
    print("Shell run: risk=\(shell.riskLabel) exit=\(shell.exitCode) output=\(shell.stdout.trimmingCharacters(in: .whitespacesAndNewlines))")
    print("Skill list: \(listedSkills.skillKeys.joined(separator: ", "))")
    print("Skill activate: \(activatedSkill.skillKey) activated=\(activatedSkill.activated)")
    print("Provider MCP tools: \(listedProviderMCPTools.toolNames.joined(separator: ", "))")
    print("Tool call: \(toolCall.toolName) -> \(toolCall.summary)")
    print("Uploaded file ID: \(uploadedFile.fileID)")
    print("Submitted batch ID: \(submittedBatch.batchID)")
  }
}
