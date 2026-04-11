# Praxis TUI Replica Blueprint

## Goal

Build a real Praxis REPL that feels structurally close to Claude Code while
remaining faithful to Praxis semantics:

- `core` for run closure
- `TAP` for governance
- `CMP` for context governance
- `MP` for memory/project surface

The rule is:

- replicate product structure and workflow
- do not copy Claude Code source

## Design Principles

### 1. Product shell first

The first front-end milestone is a real REPL shell, not a prettier observer.

### 2. Shared state first

TUI and later GUI should share the same:

- message model
- task model
- panel snapshot model
- composer state model
- overlay state model
- event bus

### 3. Standard Ink first

Do not start by cloning Claude Code's full custom Ink runtime. First ship a
clean structure on current Ink. Only borrow deeper runtime ideas later if long
transcript performance really demands it.

### 4. Surface the real Praxis stack

The UI must not hide governance. A usable Praxis front end needs first-class
visibility for:

- current turn
- capabilities/tool use
- TAP block and approval state
- CMP readback and delivery state
- background work
- admin/debug/manual control

## Target Architecture

### AppShell

Responsibilities:

- terminal lifecycle
- global providers
- session bootstrap
- top-level error boundary
- alt-screen or non-alt-screen policy

### ReplScreen

Responsibilities:

- main application orchestration
- current screen mode
- current session and turn selection
- linkage between transcript, composer, panels, overlays, and tasks

This is the Praxis equivalent of the cc `REPL` layer.

### FullscreenLayout

Responsibilities:

- transcript scroll area
- fixed composer slot
- side rail or bottom panel area
- overlay layer
- modal layer
- sticky chrome area

This must be separated from business logic.

### Transcript System

Recommended model:

- `SurfaceMessage`
  - `user`
  - `assistant`
  - `system`
  - `status`
  - `tool_use`
  - `tool_result`
  - `error`

Recommended sublayers:

- normalization
- grouping/collapse
- row rendering
- search indexing
- unseen divider
- sticky prompt/header

Praxis source inputs should come from structured domain events, not raw JSONL
line interpretation.

### PromptInput System

Minimum responsibilities:

- edit buffer
- submit
- multiline mode
- history
- slash command mode
- focus ownership
- modal gating

Second-stage responsibilities:

- search mode
- queued command hints
- richer composer status
- optional vim mode

### Task Registry

Recommended task kinds:

- `core_turn`
- `capability_run`
- `tap_review`
- `tap_provision`
- `cmp_sync`
- `cmp_passive_reply`
- `mp_materialize`
- `human_gate`

Required task fields:

- id
- title
- kind
- status
- startedAt
- updatedAt
- summary
- detailRef
- foregroundable
- cancellable

### Overlay and Modal System

Required overlays:

- permission request
- human gate approval
- slash palette
- task detail
- message actions
- search UI

Required coordination:

- single focus owner
- keyboard routing
- escape semantics
- layout-safe rendering above composer

### Panel System

Recommended stable panels:

- `RunStatusPanel`
- `TapPanel`
- `CmpPanel`
- `MpPanel`
- `TaskPanel`
- `HistoryPanel`
- `DebugPanel`

Panel data must be selector-driven snapshots, not direct access to runtime
objects.

## Shared Event Contract

Recommended surface events:

- `session.started`
- `session.updated`
- `turn.started`
- `turn.completed`
- `message.appended`
- `message.delta`
- `run.state.updated`
- `task.started`
- `task.updated`
- `task.completed`
- `tap.snapshot.updated`
- `cmp.snapshot.updated`
- `mp.snapshot.updated`
- `overlay.opened`
- `overlay.closed`
- `error.reported`

Current likely producers:

- `live-agent-chat.ts`
- `runtime.ts`
- `rax.cmp.*`
- `rax.mp.*`

The important design move is:

- producers emit domain events
- front-end reducer builds surface state
- TUI and GUI render from that shared state

## Mapping Existing Praxis Code To The New Structure

### Reuse as backend harness

Keep and reuse:

- `src/agent_core/live-agent-chat.ts`
- `src/agent_core/runtime.ts`
- `src/agent_core/live-agent-chat/shared.ts`
- `src/rax/cmp-facade.ts`
- `src/rax/mp-facade.ts`

### Replace or refactor front-end shell

Refactor heavily:

- `src/agent_core/direct-tui.tsx`

It should stop being a log observer and become the first `PraxisReplScreen`.

### Reuse as first view-model seed

Reuse and generalize:

- `src/rax/cmp-status-panel.ts`

This file already demonstrates the right idea:

- convert runtime summary into stable panel rows

The same pattern should be applied to TAP, core, and MP.

## Surface Allocation

### Transcript

Belongs in transcript:

- user utterances
- assistant replies
- visible tool use/result messages
- user-facing status notes
- final errors

### Status rail or side panel

Belongs in side status:

- current run status
- current phase
- model route
- last capability
- TAP overview
- CMP overview
- MP overview

### Task view

Belongs in task view:

- long-running capability activity
- provisioning
- replay
- background sync
- historical reply fetch

### Overlay or modal

Belongs in overlays:

- permission request
- approve/reject
- task details
- search
- command palette

### Composer

Belongs in composer:

- active buffer
- draft state
- command mode
- submit hints
- input warnings

### Admin or debug

Belongs in admin/debug surface:

- raw event feed
- readback details
- smoke results
- manual control settings
- recovery controls

## Implementation Waves

### Wave 0

Deliver:

- report
- blueprint
- surface data model
- surface event model
- component boundaries

Do not:

- deeply rewrite the existing TUI

### Wave 1

Deliver:

- `AppShell`
- `ReplScreen`
- `FullscreenLayout`
- first reducer/store
- backend event bridge

Result:

- `direct-tui.tsx` becomes a real shell instead of a log watcher

### Wave 2

Deliver:

- transcript normalization
- row rendering
- composer subsystem
- overlay/modal system

Result:

- first truly usable Praxis REPL

### Wave 3

Deliver:

- task registry
- TAP lanes
- CMP side panel
- MP side panel
- permission and human-gate overlays

Result:

- front-end shows the real governance stack rather than hiding it

### Wave 4

Deliver:

- long transcript performance work
- optional virtual list
- optional sticky chrome
- optional deeper terminal/runtime upgrades

Only at this stage should we seriously consider borrowing Claude Code style
runtime ideas such as:

- retained screen buffer
- stronger scroll container primitives
- deeper alt-screen/cursor handling

## Practical Build Order

The most pragmatic order is:

1. create `surface-types.ts`
2. create `surface-events.ts`
3. create reducer/selectors
4. create `AppShell`
5. create `ReplScreen`
6. create `FullscreenLayout`
7. adapt `direct-tui.tsx` to the new shell
8. add transcript rendering
9. add prompt input subsystem
10. add TAP/CMP/MP panels
11. add task registry and overlays

## Final Product Standard

A successful Praxis TUI should feel like:

- a real interactive REPL
- with product-grade shell structure
- with first-class governance visibility
- with reusable front-end contracts for GUI later

It should not feel like:

- an Ink-wrapped debug log

