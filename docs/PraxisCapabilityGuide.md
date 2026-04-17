# Praxis Capability Guide

This guide summarizes the current thin capability baseline exposed through `PraxisRuntimeKit`.

## Current Capability Families

The current thin capability baseline includes:

- `generate.create`
- `generate.stream`
- `embed.create`
- `tool.call`
- `file.upload`
- `batch.submit`
- `session.open`
- `code.sandbox`
- bounded `code.run`
- bounded `code.patch`
- bounded `shell.approve`
- bounded `shell.run`

## What This Surface Is For

Use this surface when you want a caller-friendly Swift API for low-side-effect generation, embeddings, provider tooling, file/batch/session baselines, and bounded execution seams already carried by the local runtime.

This guide does not claim that every capability is equally backed on every platform. Support truth still follows `docs/PraxisSupportMatrix.md`.

## Example Path

Start with:

```bash
swift run PraxisRuntimeKitCapabilitiesExample
```

What this example demonstrates:

- capability catalog readback
- bounded generate / stream / embed calls
- code sandbox contract inspection
- bounded code / shell execution seams
- skill and MCP tool discovery
- file upload, batch submission, and session opening

## Verification Path

Use:

```bash
swift run PraxisRuntimeKitSmoke --suite capabilities
```

This smoke path should confirm the shipped capability baseline is callable and still projects the expected bounded contract/results.

## Related Docs

- [Praxis Support Matrix](./PraxisSupportMatrix.md)
- [Praxis High Risk Capability Safety](./PraxisHighRiskCapabilitySafety.md)
- [Praxis Search Chain Guide](./PraxisSearchChainGuide.md)
