import PraxisCoreTypes
import PraxisInfraContracts
import PraxisRuntimeComposition

/// Projects MP host inspection and smoke snapshots from adapter readiness.
///
/// This service keeps host-facing readiness wording and projection shape out of
/// individual MP use cases. It does not own MP workflow rules or persistence.
public struct PraxisMpHostInspectionService: Sendable {
  private let diagnosticsService: PraxisMpHostDiagnosticsService

  public init(
    diagnosticsService: PraxisMpHostDiagnosticsService = PraxisMpHostDiagnosticsService()
  ) {
    self.diagnosticsService = diagnosticsService
  }

  /// Builds one host-neutral MP smoke result from current adapter readiness.
  ///
  /// - Parameters:
  ///   - projectID: Project identifier under inspection.
  ///   - hostAdapters: Current host adapter registry.
  /// - Returns: One compact smoke snapshot for MP runtime gates.
  public func smoke(
    projectID: String,
    hostAdapters: PraxisHostAdapterRegistry
  ) -> PraxisMpSmoke {
    let providerInferenceProvenance = hostAdapters.providerInferenceSurfaceProvenance
    let browserGroundingProvenance = hostAdapters.browserGroundingSurfaceProvenance
    let checks: [PraxisRuntimeSmokeCheckRecord] = [
      smokeCheck(
        id: "mp.memory.store",
        gate: .memoryStore,
        ready: hostAdapters.semanticMemoryStore != nil,
        readyStatus: .ready,
        missingStatus: .missing,
        readySummary: "Semantic memory store is available for MP workflow persistence.",
        fallbackSummary: "Semantic memory store is missing."
      ),
      smokeCheck(
        id: "mp.semantic.search",
        gate: .semanticSearch,
        ready: hostAdapters.semanticSearchIndex != nil,
        readyStatus: .ready,
        missingStatus: .missing,
        readySummary: "Semantic search index is available for MP retrieval reranking.",
        fallbackSummary: "Semantic search index is missing."
      ),
      smokeCheck(
        id: "mp.provider.inference",
        gate: .providerInference,
        ready: providerInferenceProvenance != .unavailable,
        readyStatus: .ready,
        missingStatus: .degraded,
        readySummary: providerInferenceReadySummary(for: providerInferenceProvenance),
        fallbackSummary: providerInferenceUnavailableSummary()
      ),
      smokeCheck(
        id: "mp.browser.grounding",
        gate: .browserGrounding,
        ready: browserGroundingProvenance != .unavailable,
        readyStatus: .ready,
        missingStatus: .degraded,
        readySummary: browserGroundingReadySummary(for: browserGroundingProvenance),
        fallbackSummary: "Browser grounding collector is absent; browser-backed memory capture remains unavailable."
      ),
    ]
    let readyChecks = checks.filter { $0.status == .ready }.count
    return PraxisMpSmoke(
      projectID: projectID,
      summary: diagnosticsService.smokeSummary(
        readyChecks: readyChecks,
        totalChecks: checks.count,
        projectID: projectID
      ),
      checks: checks
    )
  }

  /// Builds one MP inspection snapshot from current host adapters.
  ///
  /// - Parameters:
  ///   - projectID: Project identifier used for local-runtime inspection.
  ///   - inspectionQuery: Semantic search probe used during inspection.
  ///   - hostAdapters: Current host adapter registry.
  /// - Returns: One MP inspection snapshot.
  /// - Throws: Propagates semantic memory or semantic search adapter failures.
  public func inspect(
    projectID: String,
    inspectionQuery: String = "host runtime",
    hostAdapters: PraxisHostAdapterRegistry
  ) async throws -> PraxisMpInspection {
    let memoryBundle = try await hostAdapters.semanticMemoryStore?.bundle(
      .init(
        projectID: projectID,
        query: "",
        scopeLevels: [.global, .project, .agent, .session],
        includeSuperseded: false
      )
    )
    let semanticMatches = try await hostAdapters.semanticSearchIndex?.search(
      .init(query: inspectionQuery, limit: 3)
    ) ?? []

    return PraxisMpInspection(
      summary: "MP workflow surface is reading HostRuntime memory and current adapter provenance.",
      workflowSummary: workflowSummary(providerInferenceProvenance: hostAdapters.providerInferenceSurfaceProvenance),
      memoryStoreSummary: memoryStoreSummary(
        bundle: memoryBundle,
        semanticMatchCount: semanticMatches.count
      ),
      multimodalSummary: multimodalSummary(from: hostAdapters),
      issues: inspectionIssues(
        hostAdapters: hostAdapters,
        semanticMatchCount: semanticMatches.count
      )
    )
  }

  private func smokeCheck(
    id: String,
    gate: PraxisRuntimeSmokeGate,
    ready: Bool,
    readyStatus: PraxisRuntimeTruthLayerStatus,
    missingStatus: PraxisRuntimeTruthLayerStatus,
    readySummary: String,
    fallbackSummary: String
  ) -> PraxisRuntimeSmokeCheckRecord {
    PraxisRuntimeSmokeCheckRecord(
      id: id,
      gate: gate,
      status: ready ? readyStatus : missingStatus,
      summary: ready ? readySummary : fallbackSummary
    )
  }

  private func providerInferenceReadySummary(
    for provenance: PraxisHostAdapterSurfaceProvenance
  ) -> String {
    switch provenance {
    case .scaffoldPlaceholder:
      return "Provider inference surface is wired through scaffold placeholders for assembly smoke coverage and does not claim a live provider-backed lane."
    case .localBaseline:
      return "Provider inference surface is wired through a local heuristic baseline for MP enrichment smoke coverage."
    case .composed:
      return "Provider inference surface is composed for MP enrichment."
    case .unavailable:
      return providerInferenceUnavailableSummary()
    }
  }

  private func browserGroundingReadySummary(
    for provenance: PraxisHostAdapterSurfaceProvenance
  ) -> String {
    switch provenance {
    case .scaffoldPlaceholder:
      return "Browser grounding surface is wired through scaffold placeholders and does not claim fetched or verified evidence."
    case .localBaseline:
      return "Browser grounding surface is wired through a local baseline collector that yields candidate evidence without claiming a fetched browser session."
    case .composed:
      return "Browser grounding collector is composed for evidence-backed memory capture."
    case .unavailable:
      return "Browser grounding collector is absent; browser-backed memory capture remains unavailable."
    }
  }

  private func workflowSummary(
    providerInferenceProvenance: PraxisHostAdapterSurfaceProvenance
  ) -> String {
    switch providerInferenceProvenance {
    case .scaffoldPlaceholder:
      return "ICMA / Iterator / Checker / DbAgent / Dispatcher lanes can exercise provider inference contracts through scaffold placeholders; this profile does not claim local-baseline execution or an external provider-backed service."
    case .localBaseline:
      return "ICMA / Iterator / Checker / DbAgent / Dispatcher lanes can exercise a provider inference lane through a local heuristic baseline; this profile does not claim an external provider-backed service."
    case .composed:
      return "ICMA / Iterator / Checker / DbAgent / Dispatcher lanes have a composed provider inference surface available."
    case .unavailable:
      return "Five-agent lanes remain Core-side protocols because no provider inference surface is currently registered."
    }
  }

  private func providerInferenceUnavailableSummary() -> String {
    "Provider inference is absent; MP does not currently expose a provider inference lane."
  }

  private func memoryStoreSummary(
    bundle: PraxisSemanticMemoryBundle?,
    semanticMatchCount: Int
  ) -> String {
    let baseSummary: String
    if let bundle {
      baseSummary =
        "Semantic memory bundle exposes \(bundle.primaryMemoryIDs.count) primary records and omits \(bundle.omittedSupersededMemoryIDs.count) superseded records."
    } else {
      baseSummary = "Semantic memory store is not wired into HostRuntime yet."
    }
    return "\(baseSummary) Semantic search matches for inspection query: \(semanticMatchCount)."
  }

  private func inspectionIssues(
    hostAdapters: PraxisHostAdapterRegistry,
    semanticMatchCount: Int
  ) -> [String] {
    var issues: [String] = []
    if hostAdapters.semanticMemoryStore == nil {
      issues.append("MP runtime still needs a semantic memory store adapter on the Swift side.")
    }
    if hostAdapters.semanticSearchIndex == nil {
      issues.append("MP runtime still needs a semantic search index adapter on the Swift side.")
    }
    if semanticMatchCount == 0 {
      issues.append("No semantic search matches are currently available for the local MP inspection query.")
    }
    if [
      hostAdapters.providerInferenceSurfaceProvenance,
      hostAdapters.browserGroundingSurfaceProvenance,
      hostAdapters.audioTranscriptionSurfaceProvenance,
      hostAdapters.speechSynthesisSurfaceProvenance,
      hostAdapters.imageGenerationSurfaceProvenance,
    ].contains(.localBaseline) {
      issues.append(
        "Some provider and multimodal lanes are currently wired through local baselines; availability does not imply an external host-backed service."
      )
    }
    if [
      hostAdapters.providerInferenceSurfaceProvenance,
      hostAdapters.browserGroundingSurfaceProvenance,
      hostAdapters.audioTranscriptionSurfaceProvenance,
      hostAdapters.speechSynthesisSurfaceProvenance,
      hostAdapters.imageGenerationSurfaceProvenance,
    ].contains(.scaffoldPlaceholder) {
      issues.append(
        "Some provider and multimodal lanes are currently scaffold placeholders; availability only confirms assembly coverage, not local-baseline or host-backed execution."
      )
    }
    if hostAdapters.browserGroundingCollector == nil
      || hostAdapters.audioTranscriptionDriver == nil
      || hostAdapters.speechSynthesisDriver == nil
      || hostAdapters.imageGenerationDriver == nil {
      issues.append("Browser grounding and multimodal chips still need the full host adapter set.")
    }
    return issues
  }

  private func multimodalSummary(from hostAdapters: PraxisHostAdapterRegistry) -> String {
    let chips = [
      chipSummary(
        id: "audio.transcribe",
        provenance: hostAdapters.audioTranscriptionSurfaceProvenance
      ),
      chipSummary(
        id: "speech.synthesize",
        provenance: hostAdapters.speechSynthesisSurfaceProvenance
      ),
      chipSummary(
        id: "image.generate",
        provenance: hostAdapters.imageGenerationSurfaceProvenance
      ),
      chipSummary(
        id: "browser.ground",
        provenance: hostAdapters.browserGroundingSurfaceProvenance
      ),
    ].compactMap { $0 }

    if chips.isEmpty {
      return "No multimodal host chips are currently registered."
    }
    return "Multimodal host chips: \(chips.joined(separator: ", "))"
  }

  private func chipSummary(
    id: String,
    provenance: PraxisHostAdapterSurfaceProvenance
  ) -> String? {
    switch provenance {
    case .unavailable:
      return nil
    case .scaffoldPlaceholder:
      return "\(id) (scaffold-placeholder)"
    case .localBaseline:
      return "\(id) (local-baseline)"
    case .composed:
      return id
    }
  }
}
