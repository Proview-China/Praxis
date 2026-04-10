import PraxisRuntimePresentationBridge
import SwiftUI

@MainActor
public final class PraxisBridgeStore: ObservableObject {
  @Published public var presentationState: PraxisPresentationState?

  public let bridge: PraxisApplePresentationBridge

  public init(
    bridge: PraxisApplePresentationBridge,
    presentationState: PraxisPresentationState? = nil,
  ) {
    self.bridge = bridge
    self.presentationState = presentationState ?? bridge.initialState()
  }

  public convenience init() throws {
    let bridge = try PraxisRuntimeBridgeFactory.makeApplePresentationBridge()
    self.init(bridge: bridge)
  }

  public func loadTapInspection() async throws {
    presentationState = try await bridge.inspectTapState()
  }

  public func loadCmpInspection() async throws {
    presentationState = try await bridge.inspectCmpState()
  }
}

@MainActor
public final class PraxisAppleAppModel: ObservableObject {
  @Published public var route: PraxisAppleRoute
  public let store: PraxisBridgeStore

  public init(route: PraxisAppleRoute = .architecture, store: PraxisBridgeStore) {
    self.route = route
    self.store = store
  }
}
