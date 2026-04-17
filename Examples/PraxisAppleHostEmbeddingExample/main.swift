import Foundation
import PraxisFFI
import PraxisRuntimeInterface

private enum AppleHostEmbeddingError: Error, LocalizedError {
  case missingArchitectureSnapshot
  case unsupportedSchemaVersion(String)
  case failedResponse(String)

  var errorDescription: String? {
    switch self {
    case .missingArchitectureSnapshot:
      return "Architecture negotiation did not return a snapshot."
    case .unsupportedSchemaVersion(let message):
      return message
    case .failedResponse(let message):
      return message
    }
  }
}

private struct NegotiatedSchemaBaseline {
  let request: PraxisRuntimeInterfaceSchemaVersion
  let response: PraxisRuntimeInterfaceSchemaVersion
  let event: PraxisRuntimeInterfaceSchemaVersion
  let acceptsLegacyVersionlessPayloads: Bool
}

private struct AppleHostEmbeddingRunResult {
  let handle: PraxisRuntimeInterfaceSessionHandle
  let negotiatedSchema: NegotiatedSchemaBaseline
  let response: PraxisRuntimeInterfaceResponse
  let eventEnvelope: PraxisFFIEventEnvelope
}

private final class PraxisAppleHostEmbeddingClient {
  let bridge: PraxisFFIBridge
  let codec: PraxisJSONRuntimeInterfaceCodec

  init(
    bridge: PraxisFFIBridge = PraxisFFIFactory.makeFFIBridge(),
    codec: PraxisJSONRuntimeInterfaceCodec = PraxisJSONRuntimeInterfaceCodec()
  ) {
    self.bridge = bridge
    self.codec = codec
  }

  private func inspectArchitecture(
    handle: PraxisRuntimeInterfaceSessionHandle
  ) async throws -> NegotiatedSchemaBaseline {
    let requestData = try codec.encode(.inspectArchitecture)
    let responseData = try await bridge.handleEncodedRequest(requestData, on: handle)
    let response = try codec.decodeResponse(responseData)

    guard response.status == .success, let snapshot = response.snapshot else {
      throw AppleHostEmbeddingError.missingArchitectureSnapshot
    }
    guard snapshot.supportedRequestSchemaVersion == .v1,
          snapshot.supportedResponseSchemaVersion == .v1,
          snapshot.supportedEventSchemaVersion == .v1 else {
      throw AppleHostEmbeddingError.unsupportedSchemaVersion(
        "Host expected schema v1, but architecture negotiation reported request=\(snapshot.supportedRequestSchemaVersion?.rawValue ?? "nil") response=\(snapshot.supportedResponseSchemaVersion?.rawValue ?? "nil") event=\(snapshot.supportedEventSchemaVersion?.rawValue ?? "nil")."
      )
    }

    return .init(
      request: .v1,
      response: .v1,
      event: .v1,
      acceptsLegacyVersionlessPayloads: snapshot.acceptsLegacyVersionlessPayloads ?? false
    )
  }

  func runGoal() async throws -> AppleHostEmbeddingRunResult {
    let handle = try await bridge.openRuntimeSession()
    do {
      let negotiatedSchema = try await inspectArchitecture(handle: handle)

      let request = PraxisRuntimeInterfaceRequest.runGoal(
        .init(
          payloadSummary: "Run one Apple host embedding demo goal",
          goalID: "goal.apple-host-embedding",
          goalTitle: "Apple Host Embedding Demo",
          sessionID: "session.apple-host-embedding"
        )
      )
      let responseData = try await bridge.handleEncodedRequest(try codec.encode(request), on: handle)
      let response = try codec.decodeResponse(responseData)
      if response.status == .failure {
        throw AppleHostEmbeddingError.failedResponse(response.error?.message ?? "Unknown runtime interface failure.")
      }

      let eventData = try await bridge.drainEncodedEvents(for: handle)
      let eventEnvelope = try JSONDecoder().decode(PraxisFFIEventEnvelope.self, from: eventData)

      _ = await bridge.closeRuntimeSession(handle)

      return AppleHostEmbeddingRunResult(
        handle: handle,
        negotiatedSchema: negotiatedSchema,
        response: response,
        eventEnvelope: eventEnvelope
      )
    } catch {
      _ = await bridge.closeRuntimeSession(handle)
      throw error
    }
  }
}

@main
struct PraxisAppleHostEmbeddingExample {
  static func main() async throws {
    let client = PraxisAppleHostEmbeddingClient()
    let result = try await client.runGoal()

    print("Praxis Apple Host Embedding Example")
    print("handle: \(result.handle.rawValue)")
    print("negotiated.requestSchemaVersion: \(result.negotiatedSchema.request.rawValue)")
    print("negotiated.responseSchemaVersion: \(result.negotiatedSchema.response.rawValue)")
    print("negotiated.eventSchemaVersion: \(result.negotiatedSchema.event.rawValue)")
    print("acceptsLegacyVersionlessPayloads: \(result.negotiatedSchema.acceptsLegacyVersionlessPayloads)")
    print("response.status: \(result.response.status.rawValue)")
    print("response.snapshot.kind: \(result.response.snapshot?.kind.rawValue ?? "none")")
    print("response.snapshot.sessionID: \(result.response.snapshot?.sessionID?.rawValue ?? "none")")
    print("response.events: \(result.response.events.map { $0.name.rawValue }.joined(separator: ", "))")
    print("drained.events: \(result.eventEnvelope.events.map { $0.name.rawValue }.joined(separator: ", "))")
  }
}
