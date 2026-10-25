# Verification

`pnpm run check` checks formatting without modifying files, analyzes house Luau against pinned Roblox definitions, runs local assertions, validates skill discovery/source paths, then builds a place. Use `pnpm run format` to apply formatting intentionally.

Local tests cover pure modules. Engine-dependent behavior requires Studio; Lune is not a Roblox server emulator.

## First Studio smoke test

1. Build, open build/starter.rbxlx in a separate Studio window, and connect Rojo on localhost:34873. The file name is distinct on purpose: other projects also build a `game.rbxlx`, and opening the wrong one lets Rojo inject this starter into another game.
   Before anything else, confirm the window holds this starter: in Edit, `workspace.StarterMap` and `ServerScriptService.Services.TelemetryService` exist and `workspace` has no unrelated top-level content. Stop if it does not.
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
   - The Hud Shop button shows a SALE badge until the shop is opened once. Deals shows today's discounted item with a live countdown, the two biggest coin packs and the pass.
   - Items: an item you cannot afford shows `Need 💰 N` in red; clicking it notifies and switches to the Coins tab. Type `/cash 20`, buy the Red Hat: `Owned ✓`, counter minus three, a notification. Buying again says `You already own this.` The deal item is charged at the discounted price.
   - Robux buttons show `Soon` while ids are 0 and clicking them notifies; with real ids they show the Roblox price.
   - `/pass DoubleCoins`, then pick up a coin: plus two.
   - Settings: press minus on Music; the value drops by 10%. Stop and replay: with mock data it resets, which is expected.
   - Starter quests (top-left): claiming the daily reward and opening the shop tick their rows, notify `Quest complete` and pay; the counter reads 2/5.
   - `/unlock`, Inventory: equip Speed Boots; the button reads Equipped and `Humanoid.WalkSpeed` is 24.
   - Rewards: redeem `welcome` (+50), then again (`You already used that code.`).
   - The board beside the spawn lists you with a gold medal (refreshes every minute).
   - `/daily`, reopen Daily: day 2 is claimable.
   - The console shows `[Analytics]` lines in this order over the pass: `onboarding 1 Joined`, the daily `economy Source ... TimedReward`, `economy Source 1 Gameplay Coin`, `onboarding 2 FirstCoin`, `shop 1 Opened`, `onboarding 3 OpenedShop`, `economy Sink 3 Shop RedHat`, `shop 2 Purchased RedHat`, `onboarding 4 FirstPurchase`.
   Take a `screen_capture` of the Hud, Shop and Settings, including a narrow (mobile) viewport.
4. Verify spawn, camera, reset and server/client startup. Stop Play afterwards.
5. Use Studio's multi-client server test for replication, independent player data and disconnect cleanup. A solo test cannot certify multiplayer behavior.
6. Test reconnect/persistence in a separate test universe with the intended DataStore permissions. Studio mock fallback is not persistence verification.
7. Before monetization, test duplicate receipts, unknown products, save failure, reconnect and concurrent callbacks. Local mocked tests are only a regression guard.

Record which checks were actually run. Never call a prototype production-safe based solely on a successful build.
