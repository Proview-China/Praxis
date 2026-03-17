import type { CheckpointStore } from "../checkpoint/checkpoint-store.js";
import { projectStateFromEvents } from "../state/index.js";
import type { EventJournalLike } from "../journal/journal-types.js";
import type { AgentState } from "../types/kernel-state.js";
import type { RunRecord } from "../types/kernel-run.js";
import type { ResumeRunInput } from "./run-types.js";

export async function recoverRunContext(
  input: ResumeRunInput & {
    checkpointStore?: CheckpointStore;
    journal: EventJournalLike;
  }
): Promise<{
  recoveredRun?: RunRecord;
  recoveredState: AgentState;
}> {
  if (!input.checkpointStore) {
    const events = input.journal.readRunEvents(input.runId).map((entry) => entry.event);
    return {
      recoveredRun: undefined,
      recoveredState: projectStateFromEvents(events)
    };
  }

  const recovery = await input.checkpointStore.recoverRun({
    runId: input.runId,
    checkpointId: input.checkpointId,
    journal: input.journal
  });

  return {
    recoveredRun: recovery.run,
    recoveredState: recovery.state
  };
}
