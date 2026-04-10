import PraxisRuntimePresentationBridge
import SwiftUI

// TODO(reboot-plan):
// - Replace the current blueprint list screen with a real SwiftUI app shell, navigation flow, and run/session views.
// - Keep all page state sourced from PraxisRuntimePresentationBridge instead of consuming lower-level modules directly.
// - Reserve platform-specific presentation for macOS, iOS, and iPadOS while sharing the runtime bridge model.
// - This file can later be split into AppleAppScene.swift, RootNavigationView.swift, RunDashboardView.swift, and BridgeStore.swift.

public struct PraxisAppleUIRootView: View {
  private let blueprint = PraxisRuntimePresentationBridgeModule.bootstrap

  public init() {}

  public var body: some View {
    List {
      Section("Foundation") {
        ForEach(blueprint.foundationModules) { module in
          VStack(alignment: .leading, spacing: 4) {
            Text(module.name)
              .font(.headline)
            Text(module.responsibility)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
      }

      Section("Domains") {
        ForEach(blueprint.functionalDomainModules) { module in
          VStack(alignment: .leading, spacing: 4) {
            Text(module.name)
              .font(.headline)
            Text(module.responsibility)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
      }

      Section("Host") {
        ForEach(blueprint.hostContractModules + blueprint.runtimeModules) { module in
          VStack(alignment: .leading, spacing: 4) {
            Text(module.name)
              .font(.headline)
            Text(module.responsibility)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
      }
    }
    .navigationTitle("Praxis")
  }
}
