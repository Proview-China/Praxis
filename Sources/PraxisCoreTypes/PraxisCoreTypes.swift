// TODO(reboot-plan):
// - 实现跨子域共用的 ID、错误、版本、边界标签和 lightweight protocol。
// - 冻结可被 FFI 与宿主层安全复用的基础值类型，避免把高层语义塞回这里。
// - 为所有子域补充统一命名、追踪标签和最小共享枚举，而不是继续堆 shared/util。
// - 文件可继续拆分：BoundaryDescriptor.swift、CoreIdentifiers.swift、CoreErrors.swift、CoreConventions.swift。

public struct PraxisBoundaryDescriptor: Sendable, Equatable, Identifiable {
  public let name: String
  public let responsibility: String
  public let tsModules: [String]

  public var id: String {
    name
  }

  public init(
    name: String,
    responsibility: String,
    tsModules: [String] = [],
  ) {
    self.name = name
    self.responsibility = responsibility
    self.tsModules = tsModules
  }
}

public enum PraxisCoreTypesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCoreTypes",
    responsibility: "共享基础类型、模块边界描述与跨子域共用标识。",
    tsModules: [
      "src/agent_core/types",
      "src/agent_core/cmp-types",
      "src/agent_core/ta-pool-types",
    ],
  )
}
