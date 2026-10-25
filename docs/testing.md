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
   [DebugService] Studio commands ready: ...
   ```

   Any `[System.Init]`/`[System.Start]` error, `[UIController] ... screen disabled` or missing line is a failure. `DataStores unavailable ... using mock data` is expected in an unpublished place.
3. Feature pass, using the Studio test commands (docs/architecture.md):
   - The loading screen fades out, then the daily reward window opens by itself. Claim it: a notification shows the coins and the counter rises.
   - Walk into a gold coin with `character_navigation`: the counter rises by one and the coin reappears after ten seconds.
   - Open the player list: `Coins` matches the counter.
   - Type `/cash 20` in chat, open Shop and buy the Red Hat: `Owned`, counter minus three, a notification. Buying again says `You already own this.`
   - Click the Robux buttons: with ids at 0, a notification says the offer is not on sale yet.
   - `/pass DoubleCoins`, then pick up a coin: plus two.
   - Settings: press minus on Music; the value drops by 10%. Stop and replay: with mock data it resets, which is expected.
   - `/daily`, reopen Daily: day 2 is claimable.
   Take a `screen_capture` of the Hud, Shop and Settings, including a narrow (mobile) viewport.
4. Verify spawn, camera, reset and server/client startup. Stop Play afterwards.
5. Use Studio's multi-client server test for replication, independent player data and disconnect cleanup. A solo test cannot certify multiplayer behavior.
6. Test reconnect/persistence in a separate test universe with the intended DataStore permissions. Studio mock fallback is not persistence verification.
7. Before monetization, test duplicate receipts, unknown products, save failure, reconnect and concurrent callbacks. Local mocked tests are only a regression guard.

Record which checks were actually run. Never call a prototype production-safe based solely on a successful build.
