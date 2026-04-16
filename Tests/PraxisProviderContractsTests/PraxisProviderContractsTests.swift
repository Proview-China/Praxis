import PraxisCoreTypes
import Testing
@testable import PraxisCapabilityResults
@testable import PraxisProviderContracts

struct PraxisProviderContractsTests {
  @Test
  func inferenceEmbeddingAndCapabilityContractsStayStructured() async throws {
    let inferenceExecutor = PraxisStubProviderInferenceExecutor { request in
      let receipt = PraxisHostCapabilityReceipt(
        capabilityKey: "model.inference",
        backend: "openai",
        status: .succeeded,
        providerOperationID: "op-1",
        completedAt: "2026-04-10T22:00:00Z",
        summary: request.prompt
      )
      let output = PraxisNormalizedCapabilityOutput(
        summary: "Inference complete",
        structuredFields: ["model": "gpt-5.4"]
      )
      return PraxisProviderInferenceResponse(output: output, receipt: receipt)
    }
    let inference = try await inferenceExecutor.infer(
      .init(
        systemPrompt: "Be concise",
        prompt: "Summarize Wave5",
        contextSummary: "Host contract migration",
        preferredModel: "gpt-5.4",
        temperature: 0.2,
        requiredCapabilities: ["cmp.inspect"]
      )
    )

    #expect(inference.receipt.backend == "openai")
    #expect(inference.output.summary == "Inference complete")

    let embeddingExecutor = PraxisStubProviderEmbeddingExecutor { request in
      PraxisProviderEmbeddingResponse(vectorLength: request.content.count, model: request.preferredModel)
    }
    let embedding = try await embeddingExecutor.embed(
      .init(content: "CMP delivery baseline", preferredModel: "text-embedding-3-large")
    )

    #expect(embedding.model == "text-embedding-3-large")
    #expect(embedding.vectorLength == "CMP delivery baseline".count)

    let capabilityExecutor = PraxisStubCapabilityExecutor { request in
      PraxisHostCapabilityReceipt(
        capabilityKey: request.capabilityKey,
        backend: "host-capability",
        status: .queued,
        summary: request.payloadSummary
      )
    }
    let capabilityReceipt = try await capabilityExecutor.execute(
      .init(capabilityKey: "browser.grounding", payloadSummary: "Need browser evidence", traceID: "trace-1")
    )

    #expect(capabilityReceipt.status == .queued)
    #expect(capabilityReceipt.capabilityKey == "browser.grounding")
  }

  @Test
  func fileBatchSkillAndMcpContractsReturnDeterministicReceipts() async throws {
    let fileStore = PraxisFakeProviderFileStore(backend: "openai")
    let fileReceipt = try await fileStore.upload(.init(summary: "Upload transcript", purpose: "assistants"))
    #expect(fileReceipt.backend == "openai")
    #expect((await fileStore.allRequests()).first?.purpose == "assistants")

    let batchExecutor = PraxisFakeProviderBatchExecutor(backend: "openai")
    let batchReceipt = try await batchExecutor.enqueue(.init(summary: "Nightly embedding batch", itemCount: 8))
    #expect(batchReceipt.backend == "openai")
    #expect((await batchExecutor.allRequests()).first?.itemCount == 8)

    let registry = PraxisStubProviderSkillRegistry(skills: ["swift.test", "workspace.search"])
    #expect(try await registry.listSkillKeys() == ["swift.test", "workspace.search"])

    let activator = PraxisFakeProviderSkillActivator()
    let activationReceipt = try await activator.activate(.init(skillKey: "swift.test", reason: "Run verification"))
    #expect(activationReceipt.activated == true)
    #expect((await activator.allRequests()).first?.reason == "Run verification")

    let mcpRegistry = PraxisStubProviderMCPToolRegistry(toolNames: ["web.search", "workspace.search"])
    #expect(try await mcpRegistry.listToolNames() == ["web.search", "workspace.search"])

    let mcp = PraxisStubProviderMCPExecutor { request in
      PraxisProviderMCPToolCallReceipt(
        toolName: request.toolName,
        status: .succeeded,
        summary: request.summary
      )
    }
    let mcpReceipt = try await mcp.callTool(.init(toolName: "web.search", summary: "Find Swift docs", serverName: "openai"))
    #expect(mcpReceipt.toolName == "web.search")
    #expect(mcpReceipt.status == .succeeded)
  }

  @Test
  func providerRequestSurfaceExposesAvailabilityAndForwardsProviderRequests() async throws {
    let inferenceExecutor = PraxisStubProviderInferenceExecutor { request in
      PraxisProviderInferenceResponse(
        output: .init(summary: "Generated \(request.prompt)"),
        receipt: .init(
          capabilityKey: "provider.infer",
          backend: "openai",
          status: .succeeded,
          providerOperationID: "op-surface",
          completedAt: "2026-04-15T00:00:00Z",
          summary: request.prompt
        )
      )
    }
    let webSearchExecutor = PraxisStubProviderWebSearchExecutor { request in
      PraxisProviderWebSearchResponse(
        query: request.query,
        results: [
          .init(
            title: "Swift docs",
            snippet: "Official documentation",
            url: "https://swift.org/documentation/",
            source: "swift.org"
          )
        ],
        provider: "openai",
        summary: "Found one result."
      )
    }
    let embeddingExecutor = PraxisStubProviderEmbeddingExecutor { request in
      PraxisProviderEmbeddingResponse(vectorLength: request.content.count, model: request.preferredModel)
    }
    let fileStore = PraxisFakeProviderFileStore(backend: "openai")
    let batchExecutor = PraxisFakeProviderBatchExecutor(backend: "openai")
    let skillRegistry = PraxisStubProviderSkillRegistry(skills: ["swift.test", "workspace.search"])
    let skillActivator = PraxisFakeProviderSkillActivator()
    let mcpToolRegistry = PraxisStubProviderMCPToolRegistry(toolNames: ["web.search", "workspace.search"])
    let mcpExecutor = PraxisStubProviderMCPExecutor { request in
      PraxisProviderMCPToolCallReceipt(
        toolName: request.toolName,
        status: .succeeded,
        summary: request.summary
      )
    }
    let surface = PraxisProviderRequestSurface(
      inferenceExecutor: inferenceExecutor,
      webSearchExecutor: webSearchExecutor,
      embeddingExecutor: embeddingExecutor,
      fileStore: fileStore,
      batchExecutor: batchExecutor,
      skillRegistry: skillRegistry,
      skillActivator: skillActivator,
      mcpToolRegistry: mcpToolRegistry,
      mcpExecutor: mcpExecutor
    )

    #expect(surface.supportsInference == true)
    #expect(surface.supportsWebSearch == true)
    #expect(surface.supportsEmbedding == true)
    #expect(surface.supportsFileUpload == true)
    #expect(surface.supportsBatchSubmission == true)
    #expect(surface.supportsSkillRegistry == true)
    #expect(surface.supportsSkillActivation == true)
    #expect(surface.supportsMCPToolRegistry == true)
    #expect(surface.supportsToolCalls == true)

    let inference = try await surface.infer(.init(prompt: "Summarize Phase 4"))
    let webSearch = try await surface.search(.init(query: "Swift structured concurrency", limit: 1))
    let embedding = try await surface.embed(.init(content: "CMP delivery baseline", preferredModel: "text-embedding-3-large"))
    let fileReceipt = try await surface.upload(.init(summary: "Upload transcript", purpose: "assistants"))
    let batchReceipt = try await surface.enqueue(.init(summary: "Nightly embedding batch", itemCount: 8))
    let skillKeys = try await surface.listSkillKeys()
    let activationReceipt = try await surface.activate(.init(skillKey: "swift.test", reason: "Run verification"))
    let toolNames = try await surface.listToolNames()
    let mcpReceipt = try await surface.callTool(.init(toolName: "web.search", summary: "Find Swift docs", serverName: "openai"))

    #expect(inference.receipt.providerOperationID == "op-surface")
    #expect(webSearch.results.first?.url == "https://swift.org/documentation/")
    #expect(embedding.vectorLength == "CMP delivery baseline".count)
    #expect(fileReceipt.backend == "openai")
    #expect((await fileStore.allRequests()).first?.purpose == "assistants")
    #expect(batchReceipt.backend == "openai")
    #expect((await batchExecutor.allRequests()).first?.itemCount == 8)
    #expect(skillKeys == ["swift.test", "workspace.search"])
    #expect(activationReceipt.activated == true)
    #expect((await skillActivator.allRequests()).first?.reason == "Run verification")
    #expect(toolNames == ["web.search", "workspace.search"])
    #expect(mcpReceipt.toolName == "web.search")
    #expect(mcpReceipt.status == .succeeded)
  }

  @Test
  func providerRequestSurfaceReportsDependencyMissingForUnavailableCapability() async throws {
    let surface = PraxisProviderRequestSurface()

    #expect(surface.supportsInference == false)
    #expect(surface.supportsWebSearch == false)
    #expect(surface.supportsEmbedding == false)
    #expect(surface.supportsFileUpload == false)
    #expect(surface.supportsBatchSubmission == false)
    #expect(surface.supportsSkillRegistry == false)
    #expect(surface.supportsSkillActivation == false)
    #expect(surface.supportsMCPToolRegistry == false)
    #expect(surface.supportsToolCalls == false)

    do {
      _ = try await surface.infer(.init(prompt: "Summarize Phase 4"))
      Issue.record("Expected dependencyMissing when inference executor is unavailable.")
    } catch let error as PraxisError {
      #expect(error == .dependencyMissing("Provider request surface requires an inference executor."))
    }
  }
}
