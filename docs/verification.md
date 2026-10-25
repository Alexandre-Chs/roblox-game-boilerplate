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

Second pass (2026-10-25, Claude Fable 5.1): `pnpm run check` green with `lintErrors` now on; GitHub Actions run of the pushed commit green; `check_setup.py`, `preflight.py` and `place_state.py` run on macOS (Studio closed) and find the Rokit toolchain. `AdjustCash` no longer forces a save per call. Project `.mcp.json` added; a stdio probe of StudioMCP completed initialize, listed 28 tools and answered `list_roblox_studios` (empty, Studio closed). No playtest yet.

Third pass (2026-10-25, Claude Opus 5.5): added DataSessions tests with a fake ProfileStore, the Coin/Hud example feature, Studio smoke markers, `places.json` and a guarded `pnpm run publish`. `pnpm run check` green; the build contains the coins with their tags. The publish refusal paths are tested; an actual upload has not been run (no key, no test experience). The coin pickup and Hud have not been played in Studio.

Placeholder shop (2026-10-25): catalog, `BuyItem` packet, ShopService, `Inventory` data field and Shop screen added. Purchase rules and inventory validation are covered by Lune tests; the screen and server round trip have not been played in Studio.

Retention, monetization and tooling pass (2026-10-25): Studio-only chat commands, notifications, leaderstats, game pass and coin pack examples, Settings with SoundController, daily reward and ReplicatedFirst loading screen. `pnpm run check` green, with new Lune tests for settings cleaning, settings/daily validation, streak rules and command parsing. Not played in Studio: every screen, the chat commands, the loading screen and Marketplace prompts. Sound ids are empty, so nothing is audible yet.

Independent review by Claude Fable 5.1 (2026-10-25): verdict "conforme avec réserves". Fixed afterwards: private profile keys no longer replicate (`PlayerData.Private`, `PublicView`; `GetReplica` removed so `Set` is the only write path); per-event timers no longer accumulate in Troves (Coin, Notifications); `Lifecycle.new` asserts hooks, `Dependencies` and registry order, with `tests/lifecycle.luau`; receipt save retries every 7 s instead of 5 s; game pass checks retry with backoff; example-feature dependencies and deletion order documented; Studio DataStore note in release.md. `pnpm run check` green. Still not played in Studio.

Not verified: live Studio/MCP in this agent session, multiplayer, real persistence, real purchases, Blender animation/mesh exports, external image/3D generation or Open Cloud uploads. The shipped providers need their own optional setup. CI is configured but its remote result is separate from local verification.

Receipt pruning inherited from upstream was removed because it forgot old purchase IDs and could allow replay grants. Receipt history now grows with purchases; move to a durable receipt ledger before profile size becomes a constraint. These changes are not an exhaustive security audit of upstream packages or imported scripts.

Second review by Claude Fable 5.1, effort medium (2026-10-25): all previous findings confirmed fixed; every write path checked correct with the public/private split. Remaining doc contradictions (replica description, `SetValues`, `PlayerReleasing` exception) and the incomplete deletion table were fixed afterwards. Still open: an end-to-end Studio playtest of `DataService:Set` persistence (`/reset`, purchase, settings, then Stop and Play with API Services enabled).

Analytics (2026-10-25): `TelemetryService` with onboarding, Shop funnel, economy and custom events, plus `ShopOpened`. API checked against the current AnalyticsService reference. `tests/telemetry.luau` covers once-only onboarding, funnel sessions, economy arguments, Studio printing and contained failures. Not verified: events reaching the Creator Dashboard (needs the published test experience and real sessions).

First Studio playtest (2026-10-25, Claude Opus 5.5 through the Studio MCP, solo, mock data). Passed: server and client boot markers, daily reward auto-open and claim, coin pickup and leaderstats, shop purchase and `Owned`, settings change with modal exclusivity, all `[Analytics]` events in order, redesigned shop (tabs, daily deal countdown, rarity cards, need-more state, packs). Bugs found and fixed: the client bootstrap required siblings before replication finished; world parts all sat at the origin because Rojo ignores a Vector3 `Position` (now `CFrame`, guarded by a test); Rojo-built places defaulted to the legacy chat, so the Studio chat commands never existed (`TextChatService.ChatVersion` now set in the project, effective after reopening the built place); gradient-tinted button text, overlay order and a balance lookup collision in the shop. Not yet run in Studio: the chat commands, the Robux prompts, a narrow mobile viewport, multiplayer and real persistence.

Illustrated shop (2026-10-25): 32 images generated by a delegated Codex agent (gpt-6.1-sol, image_gen), verified by its script (sizes, alpha, no fringe, slice rects), uploaded through the Studio MCP and wired by `assets/source/ui/shop/build_ui.py`. Seen in Play: Deals tab (stall board, awning, sign, timer plate, deal card with burst, POPULAR/BEST VALUE packs), Items tab (cream and gold slots, price tags, need-more state), Hud (coin pill, icon buttons, SALE seal). Not yet seen: the Coins and Passes tabs at full length, a narrow mobile viewport, and the art on a live server after moderation.
