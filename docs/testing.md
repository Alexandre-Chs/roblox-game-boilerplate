# Verification

`pnpm run check` checks formatting without modifying files, analyzes house Luau against pinned Roblox definitions, runs local assertions, validates skill discovery/source paths, then builds a place. Use `pnpm run format` to apply formatting intentionally.

Local tests cover pure modules. Engine-dependent behavior requires Studio; Lune is not a Roblox server emulator.

## First Studio smoke test

1. Build, open build/game.rbxlx in a separate Studio window, and connect Rojo on localhost:34873.
2. Identify that window with `list_roblox_studios` and `set_active_studio`. Start Play with `start_stop_play`, wait a few seconds, then read `get_console_output`. A healthy start prints, in any order:

   ```text
   [Roblox House Starter] Server services ready
   [Roblox House Starter] Client controllers ready
   [Roblox House Starter] Player data loaded
   [Roblox House Starter] Packet round trip <n> ms
   ```

   Any `[System.Init]`/`[System.Start]` error, `[UIController] ... screen disabled` or missing line is a failure. `DataStores unavailable ... using mock data` is expected in an unpublished place.
3. Walk the character into a gold coin with `character_navigation`. The Hud should go from `Coins: 0` to `Coins: 1` (`screen_capture`), and the coin reappears after ten seconds. This proves component, DataService, Replica and UI end to end.
   With three coins, click `Shop` and buy the Red Hat: its button shows `Owned` and the counter drops by three. Buying it again shows `You already own this.`
4. Verify spawn, camera, reset and server/client startup. Stop Play afterwards.
5. Use Studio's multi-client server test for replication, independent player data and disconnect cleanup. A solo test cannot certify multiplayer behavior.
6. Test reconnect/persistence in a separate test universe with the intended DataStore permissions. Studio mock fallback is not persistence verification.
7. Before monetization, test duplicate receipts, unknown products, save failure, reconnect and concurrent callbacks. Local mocked tests are only a regression guard.

Record which checks were actually run. Never call a prototype production-safe based solely on a successful build.
