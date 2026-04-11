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

public protocol PraxisReadbackTapStatusUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackTapStatusCommand) async throws -> PraxisTapStatusReadback
}

public protocol PraxisReadbackTapHistoryUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackTapHistoryCommand) async throws -> PraxisTapHistoryReadback
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

public protocol PraxisRecoverCmpProjectUseCaseProtocol: Sendable {
  func execute(_ command: PraxisRecoverCmpProjectCommand) async throws -> PraxisCmpProjectRecovery
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

public protocol PraxisRetryCmpDispatchUseCaseProtocol: Sendable {
  func execute(_ command: PraxisRetryCmpDispatchCommand) async throws -> PraxisCmpFlowDispatch
}

public protocol PraxisRequestCmpHistoryUseCaseProtocol: Sendable {
  func execute(_ command: PraxisRequestCmpHistoryCommand) async throws -> PraxisCmpFlowHistory
}

public protocol PraxisReadbackCmpRolesUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackCmpRolesCommand) async throws -> PraxisCmpRolesReadback
}

public protocol PraxisReadbackCmpControlUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackCmpControlCommand) async throws -> PraxisCmpControlReadback
}

public protocol PraxisUpdateCmpControlUseCaseProtocol: Sendable {
  func execute(_ command: PraxisUpdateCmpControlCommand) async throws -> PraxisCmpControlUpdate
}

public protocol PraxisRequestCmpPeerApprovalUseCaseProtocol: Sendable {
  func execute(_ command: PraxisRequestCmpPeerApprovalCommand) async throws -> PraxisCmpPeerApproval
}

public protocol PraxisDecideCmpPeerApprovalUseCaseProtocol: Sendable {
  func execute(_ command: PraxisDecideCmpPeerApprovalCommand) async throws -> PraxisCmpPeerApproval
}

public protocol PraxisReadbackCmpPeerApprovalUseCaseProtocol: Sendable {
  func execute(_ command: PraxisReadbackCmpPeerApprovalCommand) async throws -> PraxisCmpPeerApprovalReadback
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
