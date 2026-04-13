# Slice 5: browser.playwright CLI defaults tail cleanup

- Scope stayed inside the TS non-UI live chat CLI shaping layer.
- `applyCliDefaultsToCapabilityRequest(...)` now accepts an optional prior browser context and only applies it to `browser.playwright`.
- Browser default precedence is now:
  - explicit request input
  - user-message headless inference
  - previous browser context (`headless` / `browser` / `isolated`)
  - existing fallback (`headless: false`, other fields left untouched)
- Added regression tests to lock:
  - explicit browser inputs are not overwritten by inferred or inherited defaults
  - inferred headless beats previous browser context while `browser` / `isolated` still inherit
- No Swift, UI, or TUI files were touched in this slice.
