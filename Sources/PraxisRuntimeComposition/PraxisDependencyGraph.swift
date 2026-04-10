import PraxisCoreTypes
import PraxisInfraContracts
import PraxisProviderContracts
import PraxisToolingContracts
import PraxisUserIOContracts
import PraxisWorkspaceContracts

public protocol PraxisDependencyResolving {
  func resolveBoundary(named name: String) -> PraxisBoundaryDescriptor?
}

public final class PraxisDependencyGraph: PraxisDependencyResolving, @unchecked Sendable {
  public let boundaries: [PraxisBoundaryDescriptor]
  public let providerInferenceExecutor: (any PraxisProviderInferenceExecutor)?
  public let workspaceReader: (any PraxisWorkspaceReader)?
  public let shellExecutor: (any PraxisShellExecutor)?
  public let checkpointStore: (any PraxisCheckpointStoreContract)?
  public let userInputDriver: (any PraxisUserInputDriver)?

  public init(
    boundaries: [PraxisBoundaryDescriptor],
    providerInferenceExecutor: (any PraxisProviderInferenceExecutor)? = nil,
    workspaceReader: (any PraxisWorkspaceReader)? = nil,
    shellExecutor: (any PraxisShellExecutor)? = nil,
    checkpointStore: (any PraxisCheckpointStoreContract)? = nil,
    userInputDriver: (any PraxisUserInputDriver)? = nil,
  ) {
    self.boundaries = boundaries
    self.providerInferenceExecutor = providerInferenceExecutor
    self.workspaceReader = workspaceReader
    self.shellExecutor = shellExecutor
    self.checkpointStore = checkpointStore
    self.userInputDriver = userInputDriver
  }

  public func resolveBoundary(named name: String) -> PraxisBoundaryDescriptor? {
    boundaries.first { $0.name == name }
  }
}
