# Praxis Search Chain Guide

This guide summarizes the current Phase 3 search chain exposed through `PraxisRuntimeKit`.

## Current Search Chain

The current search chain is:

- `search.web`
- `search.fetch`
- `search.ground`

## What This Surface Is For

Use this path when you want one SDK-facing chain from query, to fetched page, to grounded facts without reaching directly into host/browser internals.

On the current macOS local baseline, this chain uses the deterministic local search baseline.
On Linux, support remains a placeholder-backed SDK seam until a real browser/search substrate exists.

## Example Path

Start with:

```bash
swift run PraxisRuntimeKitSearchExample
```

What this example demonstrates:

- one `search.web` call
- one `search.fetch` call for the first result
- one `search.ground` call producing grounded facts

## Verification Path

Use:

```bash
swift run PraxisRuntimeKitSmoke --suite search
```

This smoke path should confirm the search-chain contract still returns search results, one fetched final URL, and grounded facts.

## Related Docs

- [Praxis Support Matrix](./PraxisSupportMatrix.md)
- [Praxis Capability Guide](./PraxisCapabilityGuide.md)
