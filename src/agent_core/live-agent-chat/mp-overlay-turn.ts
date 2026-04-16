import type { CoreMpRoutedPackageV1, CoreOverlayIndexEntryV1 } from "../core-prompt/types.js";
import { discoverMpOverlayArtifacts } from "../integrations/rax-mp-overlay-source.js";

export interface LiveMpOverlayRefreshStateLike {
  sessionId: string;
  runtime: {
    cmp: {
      worksite: {
        exportCorePackage(input: {
          sessionId: string;
          currentObjective?: string;
        }): unknown;
        exportMpCandidates?: (input: {
          sessionId: string;
          agentId?: string;
          currentObjective?: string;
          limit?: number;
        }) => unknown;
      };
    };
  };
  memoryOverlayEntries?: CoreOverlayIndexEntryV1[];
  mpRoutedPackage?: CoreMpRoutedPackageV1;
  mpOverlayReady?: Promise<void>;
}

export function readCmpMpCandidatePayloads(
  state: LiveMpOverlayRefreshStateLike,
  currentObjective: string,
): unknown {
  const worksite = state.runtime.cmp.worksite;
  if (typeof worksite.exportMpCandidates !== "function") {
    return undefined;
  }
  return worksite.exportMpCandidates({
    sessionId: state.sessionId,
    currentObjective,
    limit: 12,
  });
}

export async function refreshLiveMpOverlayForTurn(
  state: LiveMpOverlayRefreshStateLike,
  workspaceRoot: string,
  currentObjective: string,
  dependencies: {
    discoverMpOverlayArtifactsImpl?: typeof discoverMpOverlayArtifacts;
  } = {},
): Promise<void> {
  const discoverMpOverlayArtifactsImpl = dependencies.discoverMpOverlayArtifactsImpl ?? discoverMpOverlayArtifacts;
  const cmpWorksitePackage = state.runtime.cmp.worksite.exportCorePackage({
    sessionId: state.sessionId,
    currentObjective,
  });
  const cmpCandidatePayloads = readCmpMpCandidatePayloads(state, currentObjective);
  const refresh = discoverMpOverlayArtifactsImpl({
    cwd: workspaceRoot,
    userMessage: currentObjective,
    currentObjective,
    cmpWorksitePackage: cmpWorksitePackage as Parameters<typeof discoverMpOverlayArtifacts>[0]["cmpWorksitePackage"],
    cmpCandidatePayloads,
  }).then((mpOverlay) => {
    state.memoryOverlayEntries = mpOverlay.entries;
    state.mpRoutedPackage = mpOverlay.routedPackage;
  }).catch(() => undefined);
  state.mpOverlayReady = refresh.then(() => undefined);
  await refresh;
}
