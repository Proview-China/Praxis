import PraxisRun

public protocol PraxisRunGoalUseCaseProtocol: Sendable {
  func execute(_ command: PraxisRunGoalCommand) async throws -> PraxisRunExecution
}

public protocol PraxisResumeRunUseCaseProtocol: Sendable {
  func execute(_ command: PraxisResumeRunCommand) async throws -> PraxisRunExecution
}

public protocol PraxisInspectTapUseCaseProtocol: Sendable {
  func execute() async throws -> PraxisTapInspection
}

public protocol PraxisInspectCmpUseCaseProtocol: Sendable {
  func execute() async throws -> PraxisCmpInspection
}

public protocol PraxisOpenCmpSessionUseCaseProtocol: Sendable {
  func execute(_ command: PraxisOpenCmpSessionCommand) async throws -> PraxisCmpSession
}

public protocol PraxisReadbackCmpProjectUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackCmpProjectCommand) async throws -> PraxisCmpProjectReadback
}

public protocol PraxisBootstrapCmpProjectUseCaseProtocol: Sendable {
  func execute(_ command: PraxisBootstrapCmpProjectCommand) async throws -> PraxisCmpProjectBootstrap
}

public protocol PraxisIngestCmpFlowUseCaseProtocol: Sendable {
  func execute(_ command: PraxisIngestCmpFlowCommand) async throws -> PraxisCmpFlowIngest
}

public protocol PraxisCommitCmpFlowUseCaseProtocol: Sendable {
  func execute(_ command: PraxisCommitCmpFlowCommand) async throws -> PraxisCmpFlowCommit
}

public protocol PraxisResolveCmpFlowUseCaseProtocol: Sendable {
  func execute(_ command: PraxisResolveCmpFlowCommand) async throws -> PraxisCmpFlowResolve
}

public protocol PraxisMaterializeCmpFlowUseCaseProtocol: Sendable {
  func execute(_ command: PraxisMaterializeCmpFlowCommand) async throws -> PraxisCmpFlowMaterialize
}

public protocol PraxisDispatchCmpFlowUseCaseProtocol: Sendable {
  func execute(_ command: PraxisDispatchCmpFlowCommand) async throws -> PraxisCmpFlowDispatch
}

public protocol PraxisRequestCmpHistoryUseCaseProtocol: Sendable {
  func execute(_ command: PraxisRequestCmpHistoryCommand) async throws -> PraxisCmpFlowHistory
}

public protocol PraxisReadbackCmpStatusUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackCmpStatusCommand) async throws -> PraxisCmpStatusReadback
}

public protocol PraxisSmokeCmpProjectUseCaseProtocol: Sendable {
  func execute(_ command: PraxisSmokeCmpProjectCommand) async throws -> PraxisCmpProjectSmoke
}

public protocol PraxisInspectMpUseCaseProtocol: Sendable {
  func execute() async throws -> PraxisMpInspection
}

public protocol PraxisBuildCapabilityCatalogUseCaseProtocol: Sendable {
  func execute() async throws -> String
}
