import {
  createPlainLanguageRiskPayload,
  validatePlainLanguageRiskPayload,
  type PlainLanguageRiskPayload,
  type PlainLanguageRiskUserAction,
  type TaPoolRiskLevel,
} from "../ta-pool-types/index.js";

export interface PlainLanguageRiskFormatterInput {
  requestedAction: string;
  riskLevel?: TaPoolRiskLevel;
  capabilityKey?: string;
  whyItIsRisky?: string;
  possibleConsequence?: string;
  whatHappensIfNotRun?: string;
  availableUserActions?: PlainLanguageRiskUserAction[];
  metadata?: Record<string, unknown>;
}

export interface CreateReviewRiskSummaryInput extends PlainLanguageRiskFormatterInput {
  plainLanguageRisk?: PlainLanguageRiskPayload;
}

const DEFAULT_RISK_COPY: Record<
  TaPoolRiskLevel,
  {
    summaryPrefix: string;
    why: string;
    consequence: string;
    blocked: string;
  }
> = {
  normal: {
    summaryPrefix: "这是常规开发/读取动作，默认副作用较小。",
    why: "它主要是读取信息或做常规范围内的改动，通常不会直接影响更大系统边界。",
    consequence: "如果执行结果不理想，通常只需要在当前工作范围内回滚或重试。",
    blocked: "如果不执行，这一步通常只是让当前任务推进变慢，不会立刻造成严重后果。",
  },
  risky: {
    summaryPrefix: "这是有明显副作用的动作，需要先把影响范围说清楚。",
    why: "它会改动工具、配置、依赖或较大范围的工作区内容，影响面已经超出普通读取。",
    consequence: "如果执行方向错了，可能导致工具失效、环境漂移，或让后续任务进入额外修复流程。",
    blocked: "如果不执行，当前任务大概率会卡在缺能力、缺依赖或缺权限的阶段。",
  },
  dangerous: {
    summaryPrefix: "这是高危动作，一旦做错，损失可能很难补救。",
    why: "它涉及明显破坏性行为、越界写入，或可能直接伤到系统/关键数据的操作。",
    consequence: "如果执行错误，可能造成数据丢失、环境损坏或需要人工紧急恢复。",
    blocked: "如果不执行，当前任务会停住，但至少可以保留现状并寻找更安全替代方案。",
  },
};

function defaultUserActions(
  riskLevel: TaPoolRiskLevel,
): PlainLanguageRiskUserAction[] {
  const base: PlainLanguageRiskUserAction[] = [
    {
      actionId: "view-details",
      label: "查看细节",
      kind: "view_details",
      description: "先看清这次操作到底会动到哪里。",
    },
    {
      actionId: "deny",
      label: "先不要执行",
      kind: "deny",
      description: "保留当前状态，避免马上引入副作用。",
    },
  ];

  if (riskLevel === "dangerous") {
    return [
      {
        actionId: "ask-safer-alternative",
        label: "换更安全的方案",
        kind: "ask_for_safer_alternative",
        description: "让系统先给出副作用更小的替代路径。",
      },
      ...base,
    ];
  }

  return [
    {
      actionId: "approve-once",
      label: "继续这次操作",
      kind: "approve",
      description: "只批准这一次，继续当前任务。",
    },
    ...base,
  ];
}

export function formatPlainLanguageRisk(
  input: PlainLanguageRiskFormatterInput,
): PlainLanguageRiskPayload {
  const riskLevel = input.riskLevel ?? "normal";
  const requestedAction = input.requestedAction.trim();
  const capabilitySuffix = input.capabilityKey?.trim()
    ? `（能力：${input.capabilityKey.trim()}）`
    : "";
  const defaults = DEFAULT_RISK_COPY[riskLevel];

  const payload = createPlainLanguageRiskPayload({
    plainLanguageSummary: `${defaults.summaryPrefix} 这次要做的是：${requestedAction}${capabilitySuffix}。`,
    requestedAction,
    riskLevel,
    whyItIsRisky: input.whyItIsRisky?.trim() || defaults.why,
    possibleConsequence: input.possibleConsequence?.trim() || defaults.consequence,
    whatHappensIfNotRun: input.whatHappensIfNotRun?.trim() || defaults.blocked,
    availableUserActions: input.availableUserActions ?? defaultUserActions(riskLevel),
    metadata: input.metadata,
  });

  validatePlainLanguageRiskPayload(payload);
  return payload;
}

export function validateFormattedPlainLanguageRisk(
  payload: PlainLanguageRiskPayload,
): PlainLanguageRiskPayload {
  validatePlainLanguageRiskPayload(payload);
  return payload;
}
