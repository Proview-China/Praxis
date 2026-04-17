# Praxis Native Demo Host

`PraxisDemoHostApp` is the first native macOS demo host currently shipped in this repository. It is a small SwiftUI app that opens one runtime session, negotiates exported schema versions, runs one fixed demo goal, and renders the returned response and drained event evidence in a native window.

This document is intentionally narrow. It explains what the demo host proves today, what it does not prove, and how it relates to the command-line embedding examples already in the repo.

## What It Is

The native demo host is a thin host baseline, not a product shell.

- It is a real macOS app target: `PraxisDemoHostApp`.
- It uses the same FFI/runtime interface boundary that the embedding examples use.
- Its UI is deliberately small: one window, one "Connect And Run Demo" action, and one result summary.
- The result view shows negotiated request/response/event schema versions, session handle, response status, snapshot kind, session ID, and drained event names.

If you are evaluating Praxis and want to see a native host surface instead of only terminal output, this is the shortest path in the current repo.

## What It Proves Today

Today the native demo host proves that Praxis can be embedded in a native macOS SwiftUI host and still complete the same baseline bridge flow the repository already exposes elsewhere:

- a host can open a runtime session through the shipped FFI bridge
- a host can negotiate the exported architecture baseline before sending business requests
- a host can submit one fixed demo goal and receive a successful runtime response
- a host can drain the returned event buffer and show the evidence in a native window
- the repository includes a stable local app build/run entrypoint through `./script/build_and_run.sh`

In plain terms: this is evidence that Praxis is not limited to command-line examples for its first Apple-side embedding story.

## What It Does Not Prove

The native demo host is intentionally not a claim that Praxis already ships a full desktop product or a broad native host SDK surface.

It does not prove:

- multi-goal orchestration, arbitrary task authoring, or a general execution console
- persistence, settings, multi-window navigation, background work, or product-grade UX
- unrestricted shell, PTY, or cross-platform host parity
- Linux or Windows native host readiness
- stronger runtime isolation guarantees than the docs already claim elsewhere

If you need broader host support truth, read [PraxisSupportMatrix.md](./PraxisSupportMatrix.md) and the corresponding capability and runtime docs rather than extrapolating from this app.

## Build And Run

Use these commands from the repository root:

```bash
swift build --product PraxisDemoHostApp
./script/build_and_run.sh
```

Useful variants:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

`swift build --product PraxisDemoHostApp` proves the app target builds. `./script/build_and_run.sh` stages `dist/PraxisDemoHostApp.app` and opens it as a normal macOS app bundle. `--verify` is the shortest non-interactive check when you want confirmation that the app process actually launched.

## Relationship To The Embedding Examples

The three entrypoints are related, but they are not interchangeable:

- `PraxisFFIEmbeddingExample` is the smallest bridge-level example. It opens a handle, sends one encoded request, decodes the response, and drains events.
- `PraxisAppleHostEmbeddingExample` is the host-like command-line example. It negotiates architecture first, then runs the goal and prints the returned evidence.
- `PraxisDemoHostApp` takes that same narrow host story and wraps it in a native macOS SwiftUI window with a project-local build/run script.

The practical reading order is:

1. Start with `PraxisFFIEmbeddingExample` if you want the minimum encoded bridge flow.
2. Start with `PraxisAppleHostEmbeddingExample` if you want to inspect the Apple-side embedding sequence in terminal form.
3. Start with `PraxisDemoHostApp` if you want to verify that the same baseline flow can be hosted in a native macOS app instead of only a command-line example.
