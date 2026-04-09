# 2026-04-09: Swift 依赖矩阵与宿主接口目录落地

## 做了什么

- 新增 `memory/architecture/swift-dependency-matrix.md`
- 新增 `memory/architecture/swift-host-interface-catalog.md`

## 这两份文档解决什么问题

- `swift-dependency-matrix.md`
  - 把 target 之间谁能依赖谁写死
  - 防止后续 SwiftPM target 互相乱引用
- `swift-host-interface-catalog.md`
  - 把 Host 层未来需要的协议族先冻结下来
  - 防止 provider / Git / DB / MQ / CLI / UI 能力继续无边界膨胀

## 当前阶段结论

- Swift 重构现在不缺“再多几个目录”，缺的是边界守卫。
- 当前这两份目录文档就是后续继续细化 target 和协议时的第一道守卫。

