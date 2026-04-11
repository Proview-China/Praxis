import PraxisCoreTypes
import PraxisRuntimeUseCases
import PraxisRun

/// Shared host-neutral runtime boundary rules reused by runtime gateway, presentation bridge,
/// and architecture guard tests.
///
/// This type centralizes the normative strings and source guard inputs for package-level boundary
/// tests. It does not change runtime behavior or DTO shapes.
public enum PraxisHostNeutralRuntimeBoundary {
  public static let middleLayerModules = [
    "PraxisRuntimeInterface",
    "PraxisRuntimeGateway",
    "PraxisRuntimeFacades",
    "PraxisRuntimeUseCases",
  ]

  public static let gatewayEntrypoints = [
    "PraxisCLI",
    "PraxisFFI",
  ]

  public static let presentationBridgeEntrypoints = [
    "PraxisAppleUI",
  ]

  public static let middleLayerRule =
    "PraxisRuntimeInterface / PraxisRuntimeGateway / PraxisRuntimeFacades / PraxisRuntimeUseCases 构成宿主无关中间层；request / response / event / DTO 不能泄漏 CLI、SwiftUI、terminal、platform 或 provider raw payload 语义。"

  public static let gatewayEntryRule =
    "CLI / 导出入口只能经由 RuntimeGateway -> RuntimeInterface 进入系统。"

  public static let gatewayScopeRule =
    "RuntimeGateway 只负责 portal-agnostic bootstrap 与 runtime access，不吸收 CLI、SwiftUI、terminal 或 platform 细节。"

  public static let presentationBridgeRule =
    "RuntimePresentationBridge 只做展示映射，不定义宿主无关 runtime contract 真相。"

  public static let applePresentationEntryRule =
    "PraxisAppleUI 只能通过 PraxisRuntimePresentationBridge 访问 runtime；当前允许直接 import 的模块集合仅包含 PraxisRuntimePresentationBridge、SwiftUI、Foundation。"

  public static let gatewayBlueprintRules = [
    middleLayerRule,
    gatewayEntryRule,
    gatewayScopeRule,
  ]

  public static let presentationBridgeBlueprintRules = gatewayBlueprintRules + [
    presentationBridgeRule,
    applePresentationEntryRule,
  ]

  public static let cliForbiddenDirectImports = [
    "PraxisRuntimeComposition",
    "PraxisRuntimeUseCases",
    "PraxisRuntimeFacades",
    "PraxisRuntimePresentationBridge",
  ]

  public static let appleUIForbiddenDirectImports = [
    "PraxisRuntimeComposition",
    "PraxisRuntimeUseCases",
    "PraxisRuntimeFacades",
    "PraxisRuntimeInterface",
    "PraxisRuntimeGateway",
  ]

  public static let appleUIAllowedRuntimeImports = [
    "PraxisRuntimePresentationBridge",
    "SwiftUI",
    "Foundation",
  ]

  public static let middleLayerForbiddenPresentationImports = [
    "SwiftUI",
    "AppKit",
    "UIKit",
    "PraxisAppleUI",
  ]
}

public struct PraxisRuntimeBlueprint: Sendable, Equatable {
  public let foundationModules: [PraxisBoundaryDescriptor]
  public let functionalDomainModules: [PraxisBoundaryDescriptor]
  public let hostContractModules: [PraxisBoundaryDescriptor]
  public let runtimeModules: [PraxisBoundaryDescriptor]
  public let entrypoints: [String]
  public let rules: [String]

  public init(
    foundationModules: [PraxisBoundaryDescriptor],
    functionalDomainModules: [PraxisBoundaryDescriptor],
    hostContractModules: [PraxisBoundaryDescriptor],
    runtimeModules: [PraxisBoundaryDescriptor],
    entrypoints: [String],
    rules: [String],
  ) {
    self.foundationModules = foundationModules
    self.functionalDomainModules = functionalDomainModules
    self.hostContractModules = hostContractModules
    self.runtimeModules = runtimeModules
    self.entrypoints = entrypoints
    self.rules = rules
  }
}

public enum PraxisRuntimeFacadesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeFacades",
    responsibility: "对 CLI / UI / FFI 暴露的 facade 与稳定入口模型。",
    tsModules: [
      "src/rax/facade.ts",
      "src/rax/cmp/session.ts",
      "src/rax/cmp/project.ts",
      "src/rax/cmp/flow.ts",
      "src/rax/cmp/roles.ts",
      "src/rax/cmp/control.ts",
      "src/rax/mp-facade.ts",
      "src/agent_core/cmp-service",
    ],
  )
}
