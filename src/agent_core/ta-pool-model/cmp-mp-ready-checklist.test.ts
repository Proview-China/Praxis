import assert from "node:assert/strict";
import test from "node:test";

import {
  createProvisionContextApertureSnapshot,
  createReviewContextApertureSnapshot,
} from "../ta-pool-context/context-aperture.js";
import { createTapCmpMpReadyChecklist } from "./cmp-mp-ready-checklist.js";

test("tap cmp/mp ready checklist reflects section-backed reviewer and provision apertures", () => {
  const checklist = createTapCmpMpReadyChecklist({
    reviewerContext: createReviewContextApertureSnapshot({
      userIntentSummary: "cmp/mp readiness",
      riskSummary: {
        requestedAction: "review cmp/mp readiness",
        riskLevel: "normal",
      },
      sections: [
        {
          sectionId: "reviewer.section",
          title: "Reviewer Section",
          summary: "Reviewer can consume sections.",
          status: "ready",
          freshness: "fresh",
          trustLevel: "derived",
        },
      ],
    }),
    provisionContext: createProvisionContextApertureSnapshot({
      requestedCapabilityKey: "mcp.playwright",
      reviewerInstructions: "Check provision section readiness.",
      sections: [
        {
          sectionId: "provision.section",
          title: "Provision Section",
          summary: "Provision can consume sections.",
          status: "ready",
          freshness: "fresh",
          trustLevel: "derived",
        },
      ],
    }),
  });

  assert.equal(checklist.reviewerSectionRegistryReady, true);
  assert.equal(checklist.provisionSectionRegistryReady, true);
  assert.deepEqual(checklist.requiredSectionFields, ["schema", "source", "freshness", "trustLevel"]);
  assert.equal(checklist.items[0]?.status, "ready");
  assert.equal(checklist.items[1]?.status, "ready");
});
