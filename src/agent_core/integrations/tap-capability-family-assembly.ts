import type { CapabilityAdapter, CapabilityManifest } from "../capability-types/index.js";
import type { CapabilityPackage } from "../capability-package/index.js";
import type { ActivationAdapterFactory } from "../ta-pool-runtime/index.js";
import type { WorkspaceReadActivationFactoryOptions } from "./workspace-read-adapter.js";
import { registerFirstClassToolingBaselineCapabilities } from "./workspace-read-adapter.js";
import type { TapToolingAdapterOptions } from "./tap-tooling-adapter.js";
import { registerTapToolingBaseline } from "./tap-tooling-adapter.js";
import type { RaxWebsearchAdapterOptions } from "./rax-websearch-adapter.js";
import { registerRaxWebsearchCapability } from "./rax-websearch-adapter.js";
import type { RegisterRaxSkillCapabilityFamilyInput } from "./rax-skill-adapter.js";
import { registerRaxSkillCapabilityFamily } from "./rax-skill-adapter.js";
import type { RegisterRaxMcpCapabilitiesInput } from "./rax-mcp-adapter.js";
import { registerRaxMcpCapabilities } from "./rax-mcp-adapter.js";

export interface TapCapabilityFamilyAssemblyTarget {
  registerCapabilityAdapter(
    manifest: CapabilityManifest,
    adapter: CapabilityAdapter,
  ): unknown;
  registerTaActivationFactory(
    ref: string,
    factory: ActivationAdapterFactory,
  ): void;
}

export interface RegisterTapCapabilityFamilyAssemblyInput {
  runtime: TapCapabilityFamilyAssemblyTarget;
  foundation: {
    workspaceRoot: string;
    read?: Partial<Omit<WorkspaceReadActivationFactoryOptions, "workspaceRoot" | "capabilityKey">>;
    tooling?: Omit<TapToolingAdapterOptions, "workspaceRoot">;
  };
  websearch?: Omit<RaxWebsearchAdapterOptions, "capabilityKey">;
  skill?: Omit<RegisterRaxSkillCapabilityFamilyInput, "runtime">;
  mcp?: Omit<RegisterRaxMcpCapabilitiesInput, "runtime">;
  includeFamilies?: {
    foundation?: boolean;
    websearch?: boolean;
    skill?: boolean;
    mcp?: boolean;
  };
}

export interface RegisterTapCapabilityFamilyAssemblyResult {
  packages: CapabilityPackage[];
  bindings: unknown[];
  activationFactoryRefs: string[];
  familyKeys: {
    foundation: string[];
    websearch: string[];
    skill: string[];
    mcp: string[];
  };
}

export function registerTapCapabilityFamilyAssembly(
  input: RegisterTapCapabilityFamilyAssemblyInput,
): RegisterTapCapabilityFamilyAssemblyResult {
  const packages: CapabilityPackage[] = [];
  const bindings: unknown[] = [];
  const activationFactoryRefs = new Set<string>();
  const familyKeys: RegisterTapCapabilityFamilyAssemblyResult["familyKeys"] = {
    foundation: [],
    websearch: [],
    skill: [],
    mcp: [],
  };
  const includeFamilies = {
    foundation: input.includeFamilies?.foundation ?? true,
    websearch: input.includeFamilies?.websearch ?? true,
    skill: input.includeFamilies?.skill ?? true,
    mcp: input.includeFamilies?.mcp ?? true,
  };

  if (includeFamilies.foundation) {
    const firstClass = registerFirstClassToolingBaselineCapabilities({
      runtime: input.runtime,
      workspaceRoot: input.foundation.workspaceRoot,
    });
    const tapTooling = registerTapToolingBaseline(input.runtime, {
      workspaceRoot: input.foundation.workspaceRoot,
      ...(input.foundation.tooling ?? {}),
    });
    packages.push(...firstClass.packages, ...tapTooling);
    bindings.push(...firstClass.bindings);
    familyKeys.foundation.push(
      ...firstClass.capabilityKeys,
      ...tapTooling.map((entry) => entry.manifest.capabilityKey),
    );
    for (const capabilityPackage of [...firstClass.packages, ...tapTooling]) {
      const ref = capabilityPackage.activationSpec?.adapterFactoryRef;
      if (ref) {
        activationFactoryRefs.add(ref);
      }
    }
  }

  if (includeFamilies.websearch) {
    const registration = registerRaxWebsearchCapability({
      runtime: input.runtime,
      facade: input.websearch?.facade,
    });
    packages.push(registration.capabilityPackage);
    bindings.push(registration.binding);
    familyKeys.websearch.push(registration.manifest.capabilityKey);
    activationFactoryRefs.add(registration.activationFactoryRef);
  }

  if (includeFamilies.skill) {
    const registration = registerRaxSkillCapabilityFamily({
      runtime: input.runtime,
      ...input.skill,
    });
    packages.push(...registration.packages);
    bindings.push(...registration.bindings);
    familyKeys.skill.push(...registration.capabilityKeys);
    for (const ref of registration.activationFactoryRefs) {
      activationFactoryRefs.add(ref);
    }
  }

  if (includeFamilies.mcp) {
    const registration = registerRaxMcpCapabilities({
      runtime: input.runtime,
      ...input.mcp,
    });
    packages.push(...registration.packages);
    bindings.push(...registration.bindings);
    familyKeys.mcp.push(...registration.capabilityKeys);
    for (const ref of registration.activationFactoryRefs) {
      activationFactoryRefs.add(ref);
    }
  }

  return {
    packages,
    bindings,
    activationFactoryRefs: [...activationFactoryRefs],
    familyKeys,
  };
}
