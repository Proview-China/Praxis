import PraxisCmpTypes

public enum PraxisCmpGitBootstrapStatus: String, Sendable, Codable {
  case bootstrapped
  case alreadyExists
  case conflicted
}

public struct PraxisCmpProjectRepoBootstrapPlan: Sendable, Equatable, Codable {
  public let projectID: String
  public let repoName: String
  public let repoRootPath: String
  public let defaultBranchName: String

  public init(
    projectID: String,
    repoName: String,
    repoRootPath: String,
    defaultBranchName: String
  ) {
    self.projectID = projectID
    self.repoName = repoName
    self.repoRootPath = repoRootPath
    self.defaultBranchName = defaultBranchName
  }
}

public struct PraxisCmpGitBranchRuntime: Sendable, Equatable, Codable {
  public let lineageID: PraxisCmpLineageID
  public let worktreePath: String
  public let branchNames: [String]

  public init(lineageID: PraxisCmpLineageID, worktreePath: String, branchNames: [String]) {
    self.lineageID = lineageID
    self.worktreePath = worktreePath
    self.branchNames = branchNames
  }
}

public struct PraxisCmpGitBackendReceipt: Sendable, Equatable, Codable {
  public let repoName: String
  public let status: PraxisCmpGitBootstrapStatus
  public let createdBranchNames: [String]

  public init(repoName: String, status: PraxisCmpGitBootstrapStatus, createdBranchNames: [String]) {
    self.repoName = repoName
    self.status = status
    self.createdBranchNames = createdBranchNames
  }
}
