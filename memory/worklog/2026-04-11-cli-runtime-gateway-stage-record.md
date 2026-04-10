# 2026-04-11 CLI Runtime Gateway Stage Record

## Stage Summary

- Introduced `PraxisRuntimeGateway` as the portal-agnostic bootstrap and runtime access layer.
- Moved `PraxisCLI` onto `PraxisRuntimeGateway -> PraxisRuntimeInterface` for runtime requests.
- Kept `PraxisRuntimePresentationBridge` as the native presentation-specific layer instead of the only entry path.
- Hardened CLI execution semantics so shell-visible failures and cross-process event replay now behave predictably.

## What Changed

### Runtime Gateway

- Added `Sources/PraxisRuntimeGateway/PraxisRuntimeGateway.swift`.
- Defined:
  - `PraxisRuntimeGatewayModule`
  - `PraxisRuntimeGatewayFactory`
- Centralized neutral bootstrap for:
  - `makeCompositionRoot()`
  - `makeRuntimeFacade()`
  - `makeRuntimeInterface()`
  - `makeRuntimeInterfaceRegistry()`

### CLI Runtime Path

- `PraxisCLI` no longer takes its default runtime session from `PraxisRuntimePresentationBridge`.
- CLI runtime requests now flow through:
  - `PraxisCLICommandParser`
  - `PraxisRuntimeInterfaceRequest`
  - `PraxisRuntimeGatewayFactory.makeRuntimeInterface()`
- `PraxisCLI` remains a thin shell-facing adapter:
  - argument parsing
  - terminal rendering
  - persisted CLI event buffering
  - exit-code surfacing

### CLI Behavior Hardening

- `run-goal` now generates unique `goalID` and `sessionID` values per invocation.
- Runtime failures are now surfaced as failing CLI exits instead of success-status text output.
- `events` now uses a persisted file-backed CLI event store instead of only relying on one in-memory process-local buffer.

## Architecture Direction Confirmed

- CLI / exported libraries / cross-language hosts should prefer `PraxisRuntimeGateway -> PraxisRuntimeInterface`.
- Native Apple UI may still add `PraxisRuntimePresentationBridge` on top when it needs presentation mapping.
- `PraxisRuntimePresentationBridge` is no longer treated as the universal upstream entry protocol.

## Verification

- `swift test --filter PraxisCLITests`
- `swift test`
- Binary smoke checks against `.build/debug/praxis-cli`:
  - missing `resume-run` now exits with status `1`
  - `run-goal` produces unique run/session identities
  - `events --drain` can replay persisted CLI events across independent processes

## Current Test Snapshot

- `123` tests
- `39` suites

## Remaining Follow-up

- Consider moving CLI-only persisted state under a dedicated subdirectory instead of colocating `cli-events.json` beside runtime persistence files.
- If exported library work starts next, promote the current `PraxisFFIBridge` path on top of `PraxisRuntimeGateway` rather than adding new entry-specific runtime contracts.
