import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 workspace read/search/write 的完整协议族与结果类型。
// - 增加多文件读取、symbol search、patch apply、写入保护等契约。
// - 明确 workspace 只描述宿主能力，不承接业务规划逻辑。
// - 文件可继续拆分：WorkspaceReader.swift、WorkspaceSearcher.swift、WorkspaceWriter.swift、WorkspaceChangeTypes.swift。

public enum PraxisWorkspaceContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisWorkspaceContracts",
    responsibility: "workspace read/search/write 协议族。",
    tsModules: [
      "src/agent_core/integrations/workspace-read-adapter.ts",
      "src/agent_core/integrations/tap-tooling-adapter.ts",
    ],
  )
}
