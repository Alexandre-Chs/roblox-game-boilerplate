# Verification performed on this starter

Local macOS checks completed:

- Pinned Rokit dependency installation, Wally packages and package type generation.
- StyLua format check, luau-lsp analysis of src, Rojo build.
- Tests for invalid player data, independent rate-limit buckets, duplicate receipt replay after 110 later purchases, failed-save retries, unknown products and disconnected players.
- CLI unknown-command failure, all Rojo source paths and shared Claude/Codex skill location.
- All 11 skill frontmatters validated; imported Python files parsed successfully.
- Local Rojo server starts on 34873 and responds HTTP 200; stopped after the check.
- Imported UI generator produced PNG, model JSON and Luau for its sample coin HUD.
- Imported minimal-map generator produced its plan and report. Report is WARN (no props and some movement constants uncalibrated), not a gameplay certification.

Second pass (2026-10-25, Claude Fable 5.1): `pnpm run check` green with `lintErrors` now on; GitHub Actions run of the pushed commit green; `check_setup.py`, `preflight.py` and `place_state.py` run on macOS (Studio closed) and find the Rokit toolchain. `AdjustCash` no longer forces a save per call.

Not verified: live Studio/MCP in this agent session, multiplayer, real persistence, real purchases, Blender animation/mesh exports, external image/3D generation or Open Cloud uploads. The shipped providers need their own optional setup. CI is configured but its remote result is separate from local verification.

Receipt pruning inherited from upstream was removed because it forgot old purchase IDs and could allow replay grants. Receipt history now grows with purchases; move to a durable receipt ledger before profile size becomes a constraint. These changes are not an exhaustive security audit of upstream packages or imported scripts.
