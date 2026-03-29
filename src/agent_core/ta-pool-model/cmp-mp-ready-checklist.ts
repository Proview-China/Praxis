import type { ReviewContextApertureSnapshot, ProvisionContextApertureSnapshot } from "../ta-pool-context/context-aperture.js";

export interface TapCmpMpChecklistItem {
  itemId: string;
  status: "ready" | "partial" | "planned";
  summary: string;
}

export interface TapCmpMpReadyChecklist {
  checklistId: string;
  reviewerSectionRegistryReady: boolean;
  provisionSectionRegistryReady: boolean;
  requiredSectionFields: Array<"schema" | "source" | "freshness" | "trustLevel">;
  items: TapCmpMpChecklistItem[];
}

export function createTapCmpMpReadyChecklist(input: {
  reviewerContext?: ReviewContextApertureSnapshot;
  provisionContext?: ProvisionContextApertureSnapshot;
}): TapCmpMpReadyChecklist {
  const reviewerReady = (input.reviewerContext?.sections.length ?? 0) > 0;
  const provisionReady = (input.provisionContext?.sections.length ?? 0) > 0;

  return {
    checklistId: "tap-cmp-mp-ready-checklist:v1",
    reviewerSectionRegistryReady: reviewerReady,
    provisionSectionRegistryReady: provisionReady,
    requiredSectionFields: ["schema", "source", "freshness", "trustLevel"],
    items: [
      {
        itemId: "reviewer-section-consumption",
        status: reviewerReady ? "ready" : "planned",
        summary: reviewerReady
          ? "Reviewer can already consume structured sections through its default aperture."
          : "Reviewer section consumption still needs a concrete registry-fed aperture.",
      },
      {
        itemId: "provision-section-consumption",
        status: provisionReady ? "ready" : "planned",
        summary: provisionReady
          ? "Provision/TMA can already consume structured provision context sections."
          : "Provision section consumption still needs a concrete registry-fed aperture.",
      },
      {
        itemId: "shared-section-registry-schema",
        status: reviewerReady && provisionReady ? "partial" : "planned",
        summary: "Shared CMP/MP registry schema is partially represented via section records, but a real external registry is still pending.",
      },
    ],
  };
}
