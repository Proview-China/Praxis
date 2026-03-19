# 03 Context Aperture V1 And Plain Language Risk

## 任务目标

冻结第二阶段 reviewer / provisioner 的 aperture 结构，并补白话风险说明生成。

## 必须完成

- reviewer aperture v1：
  - project summary
  - run summary
  - profile snapshot
  - inventory snapshot
  - memory summary placeholder
  - user intent summary
  - risk summary
- provisioner aperture v1：
  - capability spec
  - existing sibling capability summary
  - allowed build scope
  - allowed side effects
  - reviewer instructions
- 明确禁止进入 aperture 的对象：
  - runtime 句柄
  - tool handle
  - 原始 patch 对象
  - 原始 shell 句柄
  - 密钥原文
- 新增 plain-language risk formatter

## 允许修改范围

- `src/agent_core/ta-pool-context/**`
- `src/agent_core/ta-pool-review/**`
- 纯函数 formatter 模块

## 验收标准

- aperture 结构明确
- 白话说明生成可测试
- 明确“当前 memory 视角仍是 placeholder”
