import PraxisCoreTypes
import PraxisGoal
import PraxisRuntimeComposition
import PraxisRun
import PraxisSession

// TODO(reboot-plan):
// - Implement high-level use cases such as runGoal, resumeRun, inspectTap, inspectCmp, inspectMp, and buildCapabilityCatalog.
// - Keep use cases dependent only on capabilities exposed by composition instead of crossing layers to reach entry points or host implementations.
// - Design use-case inputs and outputs as stable DTOs that facades, CLI, SwiftUI, and FFI can reuse.
// - This file can later be split into GoalUseCases.swift, TapUseCases.swift, CmpUseCases.swift, MpUseCases.swift, and CapabilityUseCases.swift.

public struct PraxisUseCaseDescriptor: Sendable, Equatable, Identifiable {
  public let name: String
  public let summary: String

  public var id: String {
    name
  }

  public init(name: String, summary: String) {
    self.name = name
    self.summary = summary
  }
}

public enum PraxisRuntimeUseCasesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeUseCases",
    responsibility: "高层应用用例定义，例如 runGoal / inspectTap / inspectCmp / inspectMp。",
    tsModules: [
      "src/agent_core/runtime.ts",
      "src/agent_core/cmp-service",
      "src/agent_core/mp-runtime",
    ],
  )

  public static let useCases: [PraxisUseCaseDescriptor] = [
    .init(name: "runGoal", summary: "运行一轮目标编排"),
    .init(name: "resumeRun", summary: "恢复中断运行"),
    .init(name: "inspectTap", summary: "读取 TAP 治理视图"),
    .init(name: "inspectCmp", summary: "读取 CMP 项目视图"),
    .init(name: "recoverCmpProject", summary: "恢复 CMP 项目上下文导出"),
    .init(name: "inspectMp", summary: "读取 MP memory workflow 视图"),
  ]
}
