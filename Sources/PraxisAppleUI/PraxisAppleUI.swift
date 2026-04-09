import PraxisRuntimePresentationBridge
import SwiftUI

// TODO(reboot-plan):
// - 把当前蓝图列表页替换成真正的 SwiftUI app shell、navigation、run/session 视图。
// - 所有页面状态都应来自 PraxisRuntimePresentationBridge，而不是直接消费底层模块。
// - 预留 macOS/iOS/iPadOS 的差异化 presentation，但共享运行时桥接模型。
// - 文件可继续拆分：AppleAppScene.swift、RootNavigationView.swift、RunDashboardView.swift、BridgeStore.swift。

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
