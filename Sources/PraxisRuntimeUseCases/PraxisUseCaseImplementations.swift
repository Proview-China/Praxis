import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisRuntimeComposition
import PraxisTapGovernance
import PraxisTapReview
import PraxisTapRuntime
import PraxisTapTypes
import PraxisRun
import PraxisSession

public final class PraxisRunGoalUseCase: PraxisRunGoalUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Generates or restores a runtime-recognizable run identifier from a goal command.
  ///
  /// - Parameters:
  ///   - command: The run-goal command to execute.
  /// - Returns: The corresponding run identifier.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute(_ command: PraxisRunGoalCommand) async throws -> PraxisRunID {
    if let sessionID = command.sessionID {
      return PraxisRunID(rawValue: "run.\(sessionID.rawValue).\(command.goal.normalizedGoal.id.rawValue)")
    }
    return PraxisRunID(rawValue: "run.\(command.goal.normalizedGoal.id.rawValue)")
  }
}

public final class PraxisResumeRunUseCase: PraxisResumeRunUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Returns the run identifier that should continue executing.
  ///
  /// - Parameters:
  ///   - command: The run command to resume.
  /// - Returns: The run identifier that should be resumed.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute(_ command: PraxisResumeRunCommand) async throws -> PraxisRunID {
    command.runID
  }
}

public final class PraxisInspectTapUseCase: PraxisInspectTapUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds the current Swift TAP domain inspection snapshot for facades and presentation bridges.
  ///
  /// - Returns: A TAP inspection that aggregates governance, context, tool-review, and runtime layers.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> PraxisTapInspection {
    let governance = PraxisTapGovernanceObject(
      mode: .standard,
      riskLevel: .risky,
      capabilityIDs: [
        PraxisCapabilityID(rawValue: "workspace.read"),
        PraxisCapabilityID(rawValue: "tool.shell"),
      ]
    )
    let governanceSnapshot = PraxisGovernanceSnapshot(
      governance: governance,
      summary: "当前 TAP inspection 汇总了 governance、context、tool-review 和 runtime 四层状态。"
    )
    let reviewContext = PraxisReviewContextAperture(
      projectSummary: .init(summary: "Swift TAP domain rules are available for inspection.", status: .ready, source: "usecase"),
      runSummary: .init(summary: "tap inspection snapshot", status: .ready, source: "usecase"),
      userIntentSummary: .init(summary: "Inspect current TAP domain state", status: .ready, source: "usecase"),
      inventorySnapshot: .init(
        totalCapabilities: governance.capabilityIDs.count,
        availableCapabilityIDs: governance.capabilityIDs
      ),
      riskSummary: .init(
        requestedAction: "Inspect current TAP domain state",
        riskLevel: .risky,
        plainLanguageSummary: "这次 inspection 只读取 Swift TAP 领域快照，不会触发真实工具执行。",
        whyItIsRisky: "当前返回的是领域规则和 inspection 快照，不是 live host runtime 状态。",
        possibleConsequence: "如果把 inspection 文案误当成 live capability 状态，后续集成判断会偏。",
        whatHappensIfNotRun: "TAP 当前规则面仍然缺少一条稳定的 inspection 说明入口。",
        availableUserActions: [
          .init(actionID: "review-domain", label: "查看规则", summary: "先确认 TAP 领域规则和 inspection 输出")
        ]
      ),
      sections: [
        .init(
          sectionID: "tap-bridge",
          title: "TAP bridge",
          summary: "UseCase 会返回结构化 TAP inspection snapshot。",
          status: .ready,
          freshness: .fresh,
          trustLevel: .verified
        )
      ],
      forbiddenObjects: [
        .init(kind: .runtimeHandle, summary: "Live runtime handle 不会直接进入 governance aperture。")
      ],
      mode: governance.mode
    )
    let toolReviewReport = PraxisToolReviewReport(
      session: .init(
        sessionID: "tap-tool-review.snapshot",
        status: .open,
        actions: [
          .init(
            reviewID: "review.snapshot",
            sessionID: "tap-tool-review.snapshot",
            governanceKind: .activation,
            capabilityID: governance.capabilityIDs.last,
            status: .recorded,
            summary: "Current inspection includes a recorded governance action without live handoff execution.",
            recordedAt: "2026-04-10T12:00:00Z"
          )
        ]
      ),
      latestDecision: .init(route: .toolReview, summary: "High-side-effect capabilities still route through the tool-review surface."),
      latestResult: nil,
      signals: [
        .init(kind: "governance_snapshot", active: true, summary: "Inspection currently reports governance evidence without executing runtime handoff.")
      ],
      advisories: [
        .init(code: "runtime_integration_pending", severity: .risky, summary: "Inspection is backed by Swift TAP domain rules, but not yet by live provider/tool adapters.")
      ]
    )
    let runtimeSnapshot = PraxisTapRuntimeSnapshot(
      controlPlaneState: .init(
        sessionID: PraxisSessionID(rawValue: "tap.session.snapshot"),
        governance: governance,
        humanGateState: .notRequired
      ),
      checkpointPointer: nil
    )
    return PraxisTapInspection(
      summary: "TAP inspection reports the current Swift TAP domain snapshot through HostRuntime.",
      governanceSnapshot: governanceSnapshot,
      reviewContext: reviewContext,
      toolReviewReport: toolReviewReport,
      runtimeSnapshot: runtimeSnapshot
    )
  }
}

public final class PraxisInspectCmpUseCase: PraxisInspectCmpUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds the inspection output for the current CMP local-runtime assumptions.
  ///
  /// - Returns: An inspection result that describes the current Swift CMP runtime profile.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> PraxisCmpInspection {
    let runtimeProfile = PraxisCmpLocalRuntimeProfile(
      structuredStoreSummary: "SQLite-backed projection, checkpoint, and journal storage is the default macOS host assumption.",
      deliveryStoreSummary: "Delivery truth is expected to persist locally instead of relying on Redis.",
      messageBusSummary: "Neighborhood fan-out should stay inside an in-process actor message bus until multi-process needs appear.",
      gitSummary: "System git remains an on-demand host tool and may trigger Command Line Tools installation when first invoked.",
      semanticIndexSummary: "Semantic search should stay local-first, with SQLite metadata plus Accelerate similarity execution."
    )
    let issues = [
      "CMP local runtime profile still needs concrete SQLite and message-bus implementations.",
      "System git readiness and semantic index execution still need live host adapters.",
    ]
    return PraxisCmpInspection(
      runtimeProfile: runtimeProfile,
      summary: "CMP inspection now assumes a macOS-local runtime profile.",
      projectID: "cmp.local-runtime",
      issues: issues,
      hostSummary: "macOS local runtime / SQLite / actor message bus / system git / Accelerate"
    )
  }
}

public final class PraxisInspectMpUseCase: PraxisInspectMpUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds the inspection output for the current reserved MP workflow surface.
  ///
  /// - Returns: An inspection result that describes the MP workflow, memory store, and multimodal surface.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> PraxisMpInspection {
    PraxisMpInspection(
      summary: "MP workflow surface is reserved in HostRuntime for five-agent memory orchestration.",
      workflowSummary: "ICMA / Iterator / Checker / DbAgent / Dispatcher lanes are expected to remain Core-side role protocols plus host-backed execution surfaces.",
      memoryStoreSummary: "Local semantic memory should stay product-neutral in Swift: SQLite metadata plus pluggable vector storage/index, without hard-coding LanceDB into Core contracts.",
      multimodalSummary: "User I/O and tooling should expose audio.transcribe, speech.synthesize, image.generate, and browser grounding evidence as host contracts rather than CLI-only helpers.",
      issues: [
        "MP runtime still needs live host adapters on the Swift side.",
        "Browser grounding and multimodal chips still need real host adapter implementations.",
      ]
    )
  }
}

public final class PraxisBuildCapabilityCatalogUseCase: PraxisBuildCapabilityCatalogUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Returns a summary description of the capability catalog from the current dependency graph.
  ///
  /// - Returns: A textual capability-catalog summary containing the current set of boundary names.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> String {
    let boundaryNames = dependencies.boundaries.map(\.name).joined(separator: ", ")
    return "Capability catalog assembled from current boundaries: \(boundaryNames)"
  }
}
