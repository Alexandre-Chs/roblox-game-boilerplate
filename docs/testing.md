# Verification

`pnpm run check` checks formatting without modifying files, analyzes house Luau against pinned Roblox definitions, runs local assertions, validates skill discovery/source paths, then builds a place. Use `pnpm run format` to apply formatting intentionally.

Local tests cover pure modules. Engine-dependent behavior requires Studio; Lune is not a Roblox server emulator.

## First Studio smoke test

1. Build, open build/game.rbxlx in a separate Studio window, and connect Rojo on localhost:34873.
2. Identify that window using MCP. Run Play and inspect server/client logs; both Bootstraps should set Ready and the Ping roundtrip should complete.
3. Verify spawn, camera, reset and server/client startup. Stop Play afterwards.
4. Use Studio's multi-client server test for replication, independent player data and disconnect cleanup. A solo test cannot certify multiplayer behavior.
5. Test reconnect/persistence in a separate test universe with the intended DataStore permissions. Studio mock fallback is not persistence verification.
6. Before monetization, test duplicate receipts, unknown products, save failure, reconnect and concurrent callbacks. Local mocked tests are only a regression guard.

Record which checks were actually run. Never call a prototype production-safe based solely on a successful build.
