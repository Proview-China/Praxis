import OpenAI from "openai";

import type { OpenAIInvocationPayload } from "../../integrations/openai/api/index.js";
import { loadLiveProviderConfig } from "../../rax/live-config.js";
import type { ProviderId, SdkLayer } from "../../rax/index.js";
import { rax } from "../../rax/index.js";
import type { ModelInferenceIntent, KernelResult } from "../types/index.js";
import type { RaxFacade as FullRaxFacade } from "../../rax/facade.js";

type GenerateFacade = Pick<FullRaxFacade, "generate">;

export interface ModelInferenceExecutionParams {
  intent: ModelInferenceIntent;
  facade?: GenerateFacade;
}

export interface ModelInferenceExecutionResult {
  result: KernelResult;
  provider: ProviderId;
  model: string;
  layer: Exclude<SdkLayer, "auto">;
  raw: unknown;
}

function readStringMetadata(
  metadata: Record<string, unknown> | undefined,
  key: string,
): string | undefined {
  const value = metadata?.[key];
  return typeof value === "string" ? value : undefined;
}

function parseOpenAITextResponse(raw: unknown): string {
  if (typeof raw === "string") {
    try {
      return parseOpenAITextResponse(JSON.parse(raw));
    } catch {
      return raw;
    }
  }

  if (raw && typeof raw === "object" && "output_text" in raw && typeof (raw as { output_text?: unknown }).output_text === "string") {
    return (raw as { output_text: string }).output_text;
  }

  if (
    raw &&
    typeof raw === "object" &&
    "choices" in raw &&
    Array.isArray((raw as { choices?: unknown[] }).choices)
  ) {
    const firstChoice = (raw as {
      choices: Array<{ message?: { content?: string | Array<{ type?: string; text?: string }> } }>;
    }).choices[0];
    const content = firstChoice?.message?.content;
    if (typeof content === "string") {
      return content;
    }
    if (Array.isArray(content)) {
      const textPart = content.find((item) => item?.type === "text" && typeof item.text === "string");
      if (textPart?.text) {
        return textPart.text;
      }
    }
  }

  return JSON.stringify(raw);
}

async function executeOpenAIInvocation(
  invocation: { payload: OpenAIInvocationPayload<Record<string, unknown>> },
): Promise<unknown> {
  const config = loadLiveProviderConfig().openai;
  const client = new OpenAI({
    apiKey: config.apiKey,
    baseURL: config.baseURL,
  });

  switch (invocation.payload.surface) {
    case "responses":
      return client.responses.create(invocation.payload.params as never);
    case "chat_completions":
      return client.chat.completions.create(invocation.payload.params as never);
    default:
      throw new Error(`Unsupported OpenAI generation surface for model inference: ${invocation.payload.surface}`);
  }
}

export async function executeModelInference(
  params: ModelInferenceExecutionParams,
): Promise<ModelInferenceExecutionResult> {
  const facade = params.facade ?? (rax as unknown as GenerateFacade);
  const metadata = params.intent.frame.metadata;
  const provider = (readStringMetadata(metadata, "provider") as ProviderId | undefined) ?? "openai";
  const model = readStringMetadata(metadata, "model") ?? loadLiveProviderConfig().openai.model;
  const layer = (readStringMetadata(metadata, "layer") as SdkLayer | undefined) ?? "api";
  const variant = readStringMetadata(metadata, "variant") ?? "chat_completions_compat";
  const compatibilityProfileId = readStringMetadata(metadata, "compatibilityProfileId");

  if (provider !== "openai") {
    throw new Error(`Model inference integration currently only supports provider ${"openai"}, received ${provider}.`);
  }

  const config = loadLiveProviderConfig().openai;
  const invocation = facade.generate.create({
    provider,
    model,
    layer,
    variant,
    compatibilityProfileId,
    input:
      variant === "chat_completions_compat"
        ? {
            model,
            messages: [{ role: "user", content: params.intent.frame.instructionText }],
            metadata: params.intent.frame.metadata,
            reasoningEffort: config.reasoningEffort as "low" | "medium" | "high" | undefined,
          }
        : {
            input: params.intent.frame.instructionText,
            metadata: params.intent.frame.metadata,
          },
  }) as {
    provider: ProviderId;
    model: string;
    layer: Exclude<SdkLayer, "auto">;
    payload: OpenAIInvocationPayload<Record<string, unknown>>;
  };

  const raw = await executeOpenAIInvocation(invocation);
  const text = parseOpenAITextResponse(raw);

  return {
    provider: invocation.provider,
    model: invocation.model,
    layer: invocation.layer,
    raw,
    result: {
      resultId: params.intent.intentId,
      sessionId: params.intent.sessionId,
      runId: params.intent.runId,
      source: "model",
      status: "success",
      output: {
        text,
        raw,
      },
      evidence: [],
      emittedAt: new Date().toISOString(),
      correlationId: params.intent.correlationId,
      metadata: {
        provider: invocation.provider,
        model: invocation.model,
        layer: invocation.layer,
        variant: invocation.payload.surface,
      },
    },
  };
}
