import PraxisCapabilityContracts
import PraxisCoreTypes

/// Stable identifiers for the Phase 3 thin-capability baseline.
public enum PraxisThinCapabilityKey: String, Sendable, Codable, CaseIterable {
  case generateCreate = "generate.create"
  case generateStream = "generate.stream"
  case embedCreate = "embed.create"
  case codeRun = "code.run"
  case codePatch = "code.patch"
  case codeSandbox = "code.sandbox"
  case shellApprove = "shell.approve"
  case shellRun = "shell.run"
  case skillList = "skill.list"
  case skillActivate = "skill.activate"
  case toolCall = "tool.call"
  case fileUpload = "file.upload"
  case batchSubmit = "batch.submit"
  case sessionOpen = "session.open"
  case searchWeb = "search.web"
  case searchFetch = "search.fetch"
  case searchGround = "search.ground"

  /// Returns the typed capability identifier for the baseline key.
  public var capabilityID: PraxisCapabilityID {
    PraxisCapabilityID(rawValue: rawValue)
  }
}

/// Baseline manifest collection for the first Phase 3 capability slice.
public struct PraxisThinCapabilityBaseline: Sendable, Equatable, Codable {
  public let summary: String
  public let manifests: [PraxisCapabilityManifest]

  /// Creates the thin-capability baseline description.
  ///
  /// - Parameters:
  ///   - summary: Human-readable baseline summary.
  ///   - manifests: Capability manifests included in the baseline.
  public init(
    summary: String,
    manifests: [PraxisCapabilityManifest]
  ) {
    self.summary = summary
    self.manifests = manifests
  }
}

public extension PraxisCapabilityCatalogBuilder {
  /// Builds the initial Phase 3 thin-capability baseline manifests.
  ///
  /// - Returns: The baseline summary and manifests for the thin capability slice.
  func buildThinCapabilityBaseline() -> PraxisThinCapabilityBaseline {
    let manifests: [PraxisCapabilityManifest] = [
      .init(
        id: PraxisThinCapabilityKey.generateCreate.capabilityID,
        name: "Generate Create",
        summary: "Run one bounded generation request through the current provider inference lane.",
        kind: .model,
        supportsPrepare: false,
        hotPath: true,
        routeHints: [
          .init(key: "backend", value: "provider.inference")
        ],
        tags: ["phase3", "thin-baseline", "generation"]
      ),
      .init(
        id: PraxisThinCapabilityKey.generateStream.capabilityID,
        name: "Generate Stream",
        summary: "Expose a bounded streaming-style generation lane without leaking transport events.",
        kind: .model,
        supportsStreaming: true,
        supportsPrepare: false,
        hotPath: true,
        routeHints: [
          .init(key: "backend", value: "provider.inference")
        ],
        tags: ["phase3", "thin-baseline", "generation", "streaming"]
      ),
      .init(
        id: PraxisThinCapabilityKey.embedCreate.capabilityID,
        name: "Embed Create",
        summary: "Create one embedding request through the current embedding lane.",
        kind: .model,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.embedding")
        ],
        tags: ["phase3", "thin-baseline", "embedding"]
      ),
      .init(
        id: PraxisThinCapabilityKey.codeRun.capabilityID,
        name: "Code Run",
        summary: "Run one bounded code snippet through the current host code lane with explicit side-effect labeling.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "host.code")
        ],
        tags: ["phase5", "bounded-execution", "code", "risky"]
      ),
      .init(
        id: PraxisThinCapabilityKey.codePatch.capabilityID,
        name: "Code Patch",
        summary: "Apply one bounded workspace patch through the current host patch lane with explicit side-effect labeling.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "host.workspace.patch")
        ],
        tags: ["phase5", "bounded-execution", "code", "patch", "risky"]
      ),
      .init(
        id: PraxisThinCapabilityKey.codeSandbox.capabilityID,
        name: "Code Sandbox",
        summary: "Describe the current bounded code sandbox contract, including enforcement mode and declared workspace roots.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "host.code.sandbox")
        ],
        tags: ["phase5", "bounded-execution", "code", "sandbox", "contract"]
      ),
      .init(
        id: PraxisThinCapabilityKey.shellApprove.capabilityID,
        name: "Shell Approve",
        summary: "Request bounded shell execution approval through the current CMP/TAP review path without leaking host approval internals.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "cmp.peer-approval")
        ],
        tags: ["phase5", "bounded-execution", "shell", "approval", "risky"]
      ),
      .init(
        id: PraxisThinCapabilityKey.shellRun.capabilityID,
        name: "Shell Run",
        summary: "Run one bounded shell command through the current host shell lane with explicit side-effect labeling.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "host.shell")
        ],
        tags: ["phase5", "bounded-execution", "shell", "risky"]
      ),
      .init(
        id: PraxisThinCapabilityKey.skillList.capabilityID,
        name: "Skill List",
        summary: "List registered provider skill keys through the current provider skill registry lane.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.skill-registry")
        ],
        tags: ["phase5", "provider-surface", "skill"]
      ),
      .init(
        id: PraxisThinCapabilityKey.skillActivate.capabilityID,
        name: "Skill Activate",
        summary: "Activate one registered provider skill key through the current provider skill lane.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.skill-activation")
        ],
        tags: ["phase5", "provider-surface", "skill"]
      ),
      .init(
        id: PraxisThinCapabilityKey.toolCall.capabilityID,
        name: "Tool Call",
        summary: "Call one registered provider-hosted tool lane through the current MCP executor.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.mcp")
        ],
        tags: ["phase3", "thin-baseline", "tooling"]
      ),
      .init(
        id: PraxisThinCapabilityKey.fileUpload.capabilityID,
        name: "File Upload",
        summary: "Upload one provider file payload through the current file-store lane.",
        kind: .resource,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.file-store")
        ],
        tags: ["phase3", "thin-baseline", "files"]
      ),
      .init(
        id: PraxisThinCapabilityKey.batchSubmit.capabilityID,
        name: "Batch Submit",
        summary: "Submit one provider batch workload through the current batch lane.",
        kind: .runtime,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.batch")
        ],
        tags: ["phase3", "thin-baseline", "batch"]
      ),
      .init(
        id: PraxisThinCapabilityKey.sessionOpen.capabilityID,
        name: "Session Open",
        summary: "Open one runtime session header for repeated caller workflows.",
        kind: .runtime,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "runtime.session")
        ],
        tags: ["phase3", "thin-baseline", "session"]
      ),
      .init(
        id: PraxisThinCapabilityKey.searchWeb.capabilityID,
        name: "Search Web",
        summary: "Search the web through the current provider web-search lane.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "provider.web-search")
        ],
        tags: ["phase3", "search-chain", "web-search"]
      ),
      .init(
        id: PraxisThinCapabilityKey.searchFetch.capabilityID,
        name: "Search Fetch",
        summary: "Fetch one candidate page through the current browser navigation lane.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "browser.fetch")
        ],
        tags: ["phase3", "search-chain", "fetch"]
      ),
      .init(
        id: PraxisThinCapabilityKey.searchGround.capabilityID,
        name: "Search Ground",
        summary: "Collect grounded evidence for one candidate page through the current browser grounding lane.",
        kind: .tool,
        supportsPrepare: false,
        routeHints: [
          .init(key: "backend", value: "browser.grounding")
        ],
        tags: ["phase3", "search-chain", "grounding"]
      ),
    ]

    return PraxisThinCapabilityBaseline(
      summary: "Thin capability baseline covers generation, embeddings, bounded code execution, patching, and sandbox contracts, bounded shell execution surfaces, tool calls, file upload, batch submission, runtime session opening, and the first search chain.",
      manifests: manifests
    )
  }
}
