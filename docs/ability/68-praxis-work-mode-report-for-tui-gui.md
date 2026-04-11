# Praxis Work Mode Report For TUI GUI

## Purpose

This report freezes the current best reading of Praxis work modes in the
`integrate-dev-master-cmp` worktree so a real TUI and later GUI can be designed
against the actual runtime, not against stale docs or log-shape guesses.

The main conclusion is simple:

- `core` is an event-sourced decision kernel with async execution bridges.
- `TAP` is a real governance control plane, not a thin reviewer wrapper.
- `CMP` is a real context-governance runtime with five-agent live surfaces.
- `MP` is already a formal runtime/facade/adapter family, not a placeholder.
- The current front end is still a harness/observer, not a product-grade REPL.

## Core

### What core really is

`core` is not one giant loop. The inner kernel is synchronous and event-driven:
it reads events, projects state, evaluates the next transition, and queues the
next intent. The outer runtime executes those intents asynchronously through
model inference, capability dispatch, TAP, and CMP.

Key anchors:

- `src/agent_core/runtime.ts`
- `src/agent_core/run/run-coordinator.ts`
- `src/agent_core/state/state-projector.ts`
- `src/agent_core/transition/transition-evaluator.ts`
- `src/agent_core/goal/{goal-source,goal-normalizer,goal-compiler}.ts`

### Core closed loop

1. User input becomes `GoalFrameSource -> normalize -> compile`.
2. `createRun()` emits `run.created`.
3. `tickRun()` projects run state from journal events.
4. `evaluateTransition()` decides the next kernel move.
5. The coordinator appends `state.delta_applied` and, when needed, `intent.queued`.
6. Runtime dispatch executes queued intents.
7. Async results come back as kernel events, usually `capability.result_received`.
8. The loop continues until `run.completed`, `run.failed`, or another terminal state.

### Sync vs async

Synchronous:

- goal normalization and compilation
- event projection
- transition evaluation
- session header updates
- surface snapshot derivation

Asynchronous:

- model inference
- capability gateway acquire/prepare/dispatch
- TAP reviewer/tool-review/provision/activation work
- checkpoint durable write and recovery
- CMP action execution

The truthful summary is:

- decision is synchronous
- execution is asynchronous
- closure happens through events

### What the UI must expose for core

Minimum user-visible core state:

- run status: `created/deciding/acting/waiting/paused/completed/failed/cancelled`
- current phase: decision, execution, commit, recovery
- pending intent id
- last dispatch status
- last task status
- last capability key
- last capability result status

Minimum core control surface:

- input/composer
- current run status bar
- current answer/result area
- event/history drawer
- TAP handoff entry when the run is blocked by human gate

## TAP

### What TAP really is

TAP is now a full governance control plane:

- policy selection
- safety interception
- review routing
- human gate
- tool review
- provisioning
- TMA planning/execution
- activation
- replay/resume
- checkpoint/recovery

Key anchors:

- `src/agent_core/runtime.ts`
- `src/agent_core/ta-pool-runtime/*`
- `src/agent_core/ta-pool-review/*`
- `src/agent_core/ta-pool-tool-review/*`
- `src/agent_core/ta-pool-provision/*`
- `src/agent_core/integrations/tap-capability-family-assembly.ts`

### TAP chain

1. Capability families and activation factories are registered.
2. A capability intent enters `dispatchCapabilityIntentViaTaPool(...)`.
3. TAP computes directive, tier, mode, and safety outcome.
4. It either grants fast-path execution or routes into review.
5. Reviewer can:
   - approve
   - partially approve
   - deny
   - defer
   - escalate to human
   - redirect to provisioning
6. Tool-review records governance-level handoff and quality state.
7. Provisioner and TMA build or repair the missing capability package.
8. Activation makes that asset live.
9. Replay/resume decides whether to continue automatically, manually, or through re-review.
10. Durable checkpoint/recovery keeps the whole TAP backlog resumable.

### Role split

- `reviewer` decides whether a capability request can pass now.
- `tool-reviewer` governs handoff and lifecycle, not execution.
- `provisioner` creates and tracks deliverable capability assets.
- `TMA` is the provisioner's planner/executor pipeline, not a reviewer.

### Important TAP states

These concepts matter for front-end design:

- mode: `bapr/yolo/permissive/standard/restricted`
- routing: `baseline_granted/review_required`
- human gate: `waiting_human/approved/rejected`
- review decision: `approved/partially_approved/denied/deferred/escalated_to_human/redirected_to_provisioning`
- tool-review governance status
- provision asset status
- activation attempt status
- replay status and `nextAction`
- recovery readiness

### What the UI must expose for TAP

The most useful TAP panels are:

- overview
- capability lanes
- human gate inbox
- tool-review timeline
- provision/TMA panel
- activation/replay/resume panel
- recovery/durable state panel
- policy matrix

For a first usable TUI, the most critical fields are:

- capability stage
- tool-review verdict
- human-gate status
- provision asset status
- activation status
- replay next action
- TMA session status
- presence of a resume envelope

## CMP

### What CMP really is

CMP already has a live mainline. It is not just a design memo. The runtime
contains:

- active ingest and commit
- passive historical reply
- child/parent/peer routing
- git, db, and MQ truth coordination
- five-agent runtime
- readback and smoke surfaces
- manual control surface
- recovery with reconciliation

Key anchors:

- `src/agent_core/runtime.ts`
- `src/agent_core/cmp-runtime/*`
- `src/agent_core/cmp-git/*`
- `src/agent_core/cmp-db/*`
- `src/agent_core/cmp-mq/*`
- `src/agent_core/cmp-five-agent/*`
- `src/rax/cmp-facade.ts`
- `src/rax/cmp-status-panel.ts`

### Active path

The active path is:

1. ingest runtime context
2. ICMA section-first lowering
3. git sync
4. iterator progression
5. checker checked snapshot
6. DB projection/package sync
7. optional parent promotion

### Passive path

The passive path is:

1. request historical context
2. choose checked snapshot and fallback strategy
3. serve passive package through DBAgent
4. deliver passive return through Dispatcher

### Parent-child and peer topology

- child seed and parent promotion are real routed paths
- peer exchange is implemented as `peer` delivery, not an informal side channel
- peer publication is still governed; it cannot bypass topology and approval guards

### Five-agent role map

- `ICMA`: context ingest and controlled fragments
- `Iterator`: git progression and review refs
- `Checker`: checked review and split/merge suggestions
- `DBAgent`: package/projection writer and passive reply source
- `Dispatcher`: final routing and delivery surface

### Live mode and observability

Role mode:

- `rules_only`
- `llm_assisted`
- `llm_required`

Observed live result:

- `succeeded`
- `fallback`
- `rules_only`

This means the UI can honestly show both:

- policy mode
- actual live result

### Truth model

Current truth split is stable enough for front-end design:

- git: checked/promoted/history truth
- db: projection/package truth
- redis or MQ layer: dispatch/ack/expiry truth

### What the UI must expose for CMP

The highest-value CMP view is not raw event spam. It is `rax.cmp.readback()` and
`rax.cmp.smoke()` output, because those already aggregate:

- truth-layer health
- bootstrap state
- infra state
- delivery drift
- recovery reconciliation
- five-agent summary
- acceptance checks
- status panel rows

The most valuable CMP panes are:

- truth layers
- five-agent live
- flow health
- recovery
- manual control

## MP

### What MP really is

MP is already a formal runtime/facade/adapter family on the `rax` side. It is
not only contract text.

Key anchors:

- `src/rax/mp-config.ts`
- `src/rax/mp-runtime.ts`
- `src/rax/mp-facade.ts`
- `src/agent_core/integrations/rax-mp-adapter.ts`
- `src/agent_core/capability-package/mp-family-capability-package.ts`

### Implemented entrypoints

MP currently covers a real family of actions including:

- ingest
- align
- resolve
- history.request
- search
- materialize
- promote
- archive
- split
- merge
- reindex
- compact

### Front-end value

For TUI/GUI the most valuable first MP view is not search results. It is the
`mp.readback` summary and status panel, because that surfaces:

- project bootstrap status
- record count
- freshness/alignment shape
- five-agent summary
- readiness/final acceptance
- issues

## Current Front-End Reality

### What exists now

Praxis already has:

- a direct Ink shell in `src/agent_core/direct-tui.tsx`
- a live backend harness in `src/agent_core/live-agent-chat.ts`
- lightweight CLI helpers in `src/agent_core/live-agent-chat/ui.ts`
- event/log protocol in `src/agent_core/live-agent-chat/shared.ts`
- a reusable CMP row-model in `src/rax/cmp-status-panel.ts`

### Why it is still not a product-grade TUI

Current front-end is still a harness because it lacks these boundaries:

- message model separate from debug/log lines
- task model
- overlay/modal model
- input subsystem
- product layout shell
- unified surface store

Right now it is closer to:

- Ink-wrapped observer

than to:

- a real REPL application shell

## Front-End Abstraction For Both TUI And GUI

The recommended shared model is:

- `SurfaceSession`
- `SurfaceTurn`
- `SurfaceMessage`
- `SurfaceTask`
- `SurfacePanelSnapshot`
- `SurfaceOverlay`

Recommended event bus:

- `session.started`
- `turn.started`
- `message.appended`
- `message.delta`
- `stage.started`
- `stage.ended`
- `capability.requested`
- `capability.updated`
- `capability.completed`
- `cmp.snapshot.updated`
- `tap.snapshot.updated`
- `overlay.opened`
- `overlay.closed`

Recommended panel split:

- transcript panel
- run status panel
- CMP panel
- TAP panel
- task panel
- composer panel
- overlay layer

## Product Summary

The best concise reading of Praxis today is:

- backend harness is already strong
- frontstage shell is still weak
- the right next step is not more ad hoc logs
- the right next step is a real REPL shell over shared front-end state

