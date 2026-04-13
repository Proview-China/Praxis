# Remove Tracked TypeScript Implementation

## Summary

- Removed the tracked TypeScript / Node.js implementation tree from the repository.
- Removed tracked Node build artifacts and manifests so the repo no longer presents a live TS runtime.
- Renamed boundary metadata from `tsModules` to `legacyReferences` to make the remaining provenance strings explicitly historical.

## Removed

- `src/`
- `dist/`
- `scripts/`
- `package.json`
- `package-lock.json`
- `tsconfig.json`

## Notes

- Existing `legacyReferences` strings in Swift boundary descriptors are historical lineage markers only.
- Root docs were updated so the repo truth is now Swift-first and framework-oriented.
- Deeper archive docs under `docs/` and `memory/` still contain many old `src/**` references and should be cleaned incrementally in later passes instead of being rewritten wholesale in this step.
