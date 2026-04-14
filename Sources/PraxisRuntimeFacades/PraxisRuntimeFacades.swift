import PraxisCoreTypes
import PraxisRuntimeUseCases
import PraxisRun

/// Shared host-neutral runtime boundary rules reused by runtime gateway and architecture guard
/// tests.
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
    "PraxisFFI",
  ]

  public static let middleLayerRule =
    "PraxisRuntimeInterface / PraxisRuntimeGateway / PraxisRuntimeFacades / PraxisRuntimeUseCases 构成宿主无关中间层；request / response / event / DTO 不能泄漏 CLI、GUI、SwiftUI、terminal、platform 或 provider raw payload 语义。"

  public static let gatewayEntryRule =
    "Framework 调用面与导出入口只能经由 RuntimeGateway -> RuntimeInterface 进入系统。"

  public static let gatewayScopeRule =
    "RuntimeGateway 只负责 framework-first bootstrap 与 runtime access，不吸收 CLI、GUI、SwiftUI、terminal 或 platform 细节。"

  public static let gatewayBlueprintRules = [
    middleLayerRule,
    gatewayEntryRule,
    gatewayScopeRule,
  ]

  public static let middleLayerForbiddenPresentationImports = [
    "SwiftUI",
    "AppKit",
    "UIKit",
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
    responsibility: "对 framework public API 与 FFI 暴露的 facade 与稳定入口模型。",
    legacyReferences: [
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
