# Feature catalog

Every feature the starter ships, for agents who need to use, change or remove one. Each entry says what it does, where it lives, what to configure, how to test it in Studio and what only works on a published game. Architecture rules (services decide, controllers display, pure modules tested) are in [architecture.md](architecture.md); removal order and cross-references are in its Example features tables; art and layout rules are in [assets.md](assets.md).

Conventions used below: **Server** files are under `src/server`, **Client** under `src/client`, **Shared** under `src/shared`. "Inert at 0" means an id of 0 keeps the feature present but disabled until a real Creator Dashboard id is pasted.

## Map

| Feature | Player sees | Main files | Config |
| --- | --- | --- | --- |
| [Coins](#coins) | gold coins to pick up, counter top-centre | `Components/Coin.luau`, `Screens/Hud.luau` | `GameConfig.Coin` |
| [Shop](#shop) | Shop window: Deals, Items, Coins, Passes | `ShopService/`, `Screens/Shop.luau` | `Config/ShopCatalog.luau` |
| [Robux offers](#robux-offers) | coin packs and game passes | `GamePassService`, `PurchaseService/` | `Config/Monetization.luau` |
| [Inventory](#inventory) | owned items, Equip | `InventoryService/`, `Screens/Inventory.luau` | `ShopCatalog` `Effect` |
| [Daily reward](#daily-reward) | 7-day streak window | `DailyRewardService`, `Screens/DailyReward.luau` | `GameConfig.DailyRewards` |
| [Starter quests](#starter-quests) | checklist top-left, paid once each | `TutorialService`, `Screens/Tutorial.luau` | `Config/Tutorial.luau` |
| [Rewards: codes](#promo-codes) | code box | `CodesService/`, `Screens/Rewards.luau` | `src/server/Config/Codes.luau` |
| [Rewards: community](#community-rewards) | group reward, invite, favorite, friend bonus | `CommunityService`, `Screens/Rewards.luau` | `GameConfig.Community` |
| [Global leaderboard](#global-leaderboard) | wooden board near the spawn | `LeaderboardService/`, `Components/Leaderboard.luau` | `GameConfig.Leaderboard` |
| [Player list stat](#player-list-stat) | Coins column in the player list | `LeaderstatsService` | none |
| [Badges](#badges) | Roblox badges | `AchievementService` | `Config/Badges.luau` |
| [Settings and sound](#settings-and-sound) | music and effects volume | `SettingsService`, `SoundController` | `Config/Sounds.luau` |
| [Notifications](#notifications) | toasts bottom-centre | `NotificationService`, `Screens/Notifications.luau` | none |
| [Loading screen](#loading-screen) | sky background and progress bar | `src/first/Loading.client.luau` | `src/first/LoadingImages.luau` (generated) |
| [Regional policy](#regional-policy) | random paid offers hidden where banned | `ComplianceService` | `ShopCatalog` `Random` |
| [Translation](#translation) | UI in en, fr, es, pt-br | `Utils/Locale.luau` | `assets/localization/Strings.csv` |
| [Screen fitting](#screen-fitting) | UI sized for phone to big monitor | `UIController/DeviceScale.luau` | `DesignWidth`/`DesignHeight` attributes |
| [Analytics](#analytics) | nothing (Creator Dashboard) | `TelemetryService` | step lists in the service |
| [Studio test commands](#studio-test-commands) | chat commands in Studio only | `DebugService/` | none |
| [Illustrated UI kit](#illustrated-ui-kit) | every window's art | `assets/source/ui/*`, `build_ui.py` | `roblox-ids.json` per kit |

The Hud dock on the right opens Shop, Inventory, Daily, Rewards and Settings (`Screens/Hud.luau`, `BUTTONS`).

## Coins

- **What:** tagged `Coin` parts in `assets/world/Coins.model.json`. Touching one on the server pays coins and hides it for `RespawnSeconds`.
- **Payout:** `Utils/CoinReward.luau` (pure, tested): `Value` × 2 with the `DoubleCoins` pass × (1 + 10% per friend in the server, max 3). The fractional part becomes a chance of one extra coin.
- **Also triggers:** economy analytics (`Gameplay`), onboarding funnel `FirstCoin`, starter quest `FirstCoin`.
- **Test:** walk into a coin; `/pass DoubleCoins` then pick one up for 2.

## Shop

- **What:** four tabs. Deals has a daily discounted item (`Utils/DailyDeal.luau`, shared so client and server agree on the price) with a countdown, the two biggest coin packs and a pass. Items shows rarity cards. Coins shows Robux packs with POPULAR / BEST VALUE banners. Passes lists game passes.
- **Server:** `ShopService` (`BuyItem` packet, `Purchasing.luau` pure). It checks ownership, price and the regional policy, then charges and grants in the same frame.
- **Config:** `Config/ShopCatalog.luau` items: `Id`, `Name`, `Price`, `Order`, `Icon`, `Rarity`, optional `Effect` (see Inventory) and `Random` (see Regional policy). `GameConfig.ShopDealDiscount` sets the discount.
- **Also triggers:** shop funnel analytics, `FirstPurchase` onboarding, badge `FirstPurchase`, quest `FirstPurchase`.
- **Test:** `/cash 100`, buy, `/unlock`, `/reset`.

## Robux offers

- **Coin packs** (developer products) in `Monetization.CoinPacks`, granted by `PurchaseService/Products.luau`. The grant is followed by a saved receipt (`WaitForSave`), retried every 7 s, so a purchase is never lost or doubled.
- **Game passes** in `Monetization.GamePasses`. Ownership is cached by `GamePassService` as the `Pass_<Name>` player attribute; read it with `GamePassService:Owns(player, name)`.
- **Inert at 0:** the shop shows "Soon" and notifies.
- **Live only:** real prompts and receipts. Validate in a separate test universe ([release.md](release.md)).

## Inventory

- **What:** a window listing owned items with Equip / Equipped. One item is equipped at a time and saved (`PlayerData.Equipped`, `""` for none).
- **Server:** `InventoryService` (`Equip` packet, `Equipping.luau` pure). It mirrors the item as the `Equipped` player attribute and applies `Effect` on every spawn. `Effect.WalkSpeed` is the example (Speed Boots → 24, default `GameConfig.WalkSpeed`).
- **Add an effect:** add a field to `Effect` in the catalog type and apply it in `InventoryService.apply`. Visual accessories are not included.
- **Test:** `/unlock`, open Inventory, equip Speed Boots, check `Humanoid.WalkSpeed`.

## Daily reward

- **What:** opens by itself when a reward is waiting. It shows 7 day tiles (claimed with a check, today in gold) and pays `GameConfig.DailyRewards[day]`. Missing a day restarts the streak.
- **Server:** `DailyRewardService` (`ClaimDaily`, server clock, `Utils/DailyReward.luau` pure). It also completes quest `ClaimedDaily` and awards badge `Streak7` at 7 days.
- **Test:** `/daily` makes it claimable again with the streak continuing.

## Starter quests

- **What:** a "STARTER QUESTS" checklist top-left. Default quests: collect a coin, claim the daily reward, open the shop, buy an item, equip an item. They can be done in any order, and each pays its reward once. The first open quest is highlighted, and an arrow points at its Hud button (`Target`) or a golden beam leads to the nearest coin. The list hides when all are done. The chat window is moved bottom-left (`AppController`) to free the corner.
- **Data:** `PlayerData.Tutorial` is the set of completed quest ids.
- **Server:** `TutorialService:Reached(player, milestone)` never yields. It pays, saves, notifies and logs economy `Onboarding`. Milestones are reported by `Coin.luau`, `DailyRewardService`, the `ShopOpened` packet, `ShopService` and `InventoryService`.
- **Add a quest:** add `{ Id, Text, Reward, Icon, Target? }` to `Config/Tutorial.luau`, then call `services.TutorialService:Reached(player, "<Id>")` where it happens (add `TutorialService` to that system's Dependencies).
- **Test:** `/reset` clears quests.

## Promo codes

- **What:** the code box in Rewards. Codes are case-insensitive, used once per player, and may expire.
- **Config:** `src/server/Config/Codes.luau` (server-only, so clients cannot read unreleased codes): `CODE = { Coins = n, Expires = unixTime or 0 }`.
- **Server:** `CodesService` (`RedeemCode`, limited to 3 per 10 s; `Redeeming.luau` pure). It records `Redeemed["Code_<CODE>"]` in the same frame as the coins.
- **Test:** type `welcome` (+50), then again ("already used").

## Community rewards

- **Group reward:** a one-time `GroupReward` for members of `GameConfig.Community.GroupId` (`ClaimGroupReward`, recorded as `Redeemed.Social_Group`). The row is hidden while `GroupId` is 0.
- **Friend bonus:** `CommunityService` keeps the `FriendsInServer` player attribute up to date. Coins pay +`FriendBonus` per friend, up to `MaxFriends`. The Invite row shows the current bonus and opens the Roblox invite prompt.
- **Favorite:** the Favorite button, plus one automatic prompt per session after `FavoritePromptAfter` seconds (published games only).
- **Live only:** group membership, invites and favorites need a published game.

## Global leaderboard

- **What:** a wooden board (`assets/world/Leaderboard.model.json`, tag `Leaderboard`) beside the spawn. It shows the top 10 of `GameConfig.Leaderboard.Stat` with gold, silver and bronze medals.
- **Server:** `LeaderboardService` writes each player's stat to an OrderedDataStore and reads the top every `RefreshSeconds`. It publishes JSON in the `Leaderboard` attribute of ReplicatedStorage. `Ranking.luau` (pure) merges live values over stored ones.
- **Client:** `Components/Leaderboard.luau` renders any tagged board, so you can place several.
- **Studio:** without API access it shows this server's players only and stops calling the DataStore.

## Player list stat

`LeaderstatsService` mirrors `Cash` as the `Coins` leaderstat through `DataService.Changed`.

## Badges

- **What:** `AchievementService:Award(player, name)` for Welcome (on load), FirstPurchase and Streak7. It never yields and retries on the next trigger if Roblox fails.
- **Inert at 0:** `Config/Badges.luau`. In Studio it prints `[AchievementService] <name> earned (no badge id yet)`.
- **Add one:** add the name to `Config/Badges.luau` and call `Award` where it is earned.

## Settings and sound

- **Settings:** a Music / Effects volume window with − and + buttons (`SetSetting`, `PlayerData.CleanSetting`), saved in `PlayerData.Settings`.
- **Sound:** `SoundController` plays `Sounds.Music` in a loop and `PlaySfx(name)` for Click, Coin, Purchase, Reward, Error and Open. Two SoundGroups follow the saved volumes.
- **Sound ids:** Creator Store audio verified in Studio (`IsLoaded`, measured length) with the `roblox-sfx` skill; licences are in `assets/catalog.json`. Never invent ids; empty ids are silent.

## Notifications

`NotificationService:Send(player, text)` on the server, `context.Notify(text)` in screens. At most 4 toasts are shown, each for 3 s. Use toasts for feedback instead of per-screen message labels.

## Loading screen

Built in code in ReplicatedFirst (it runs before StarterGui replicates): a tropical sky, "Loading..." and a bar that fills while waiting. It hides when `AppController` sets the `ClientReady` attribute (data loaded), or after 20 s. Its image ids come from the generated `src/first/LoadingImages.luau`.

## Regional policy

`ComplianceService` reads `PolicyService` per player and sets the `PolicyLoaded` and `PaidRandomItemsRestricted` attributes. If the lookup fails, the player is treated as restricted. Catalog items with `Random = true` (paid loot boxes) are hidden by the shop and refused by `ShopService` unless allowed. Mark every paid random reward this way.

## Translation

- **Static text:** GUI text matching a `Source` in `assets/localization/Strings.csv` (LocalizationTable `Strings` in LocalizationService) is translated by Roblox for en, fr, es and pt-br.
- **Dynamic text:** `Locale.Format(player?, key, args, "English {1}")`, with keys in the CSV. It never yields: until `Locale.Prepare(player)` has loaded the translator it returns the English fallback. Examples: `DailyPreview`, `DayLabel`, `FriendsBonus`.
- **Server notifications** are still English. Use `Locale.Format(player, ...)` on the server to translate one.
- **Test:** Studio, Test tab, test language/region.

## Screen fitting

Every window has a fixed design size in pixels. Its `DeviceScale` UIScale carries `DesignWidth`/`DesignHeight` attributes, and `UIController/DeviceScale.luau` scales it to fit the viewport, between 0.5 (phones) and 1.3 (big monitors and Retina windows). Hud pieces have a `DeviceScale` without attributes and follow a 960x540 reference. Open animations ease toward the `Fitted` attribute, never toward 1.

- **New window:** use `modal(...)` in `build_ui.py`, which adds the scale automatically.
- **Test:** the Studio device emulator.

## Analytics

`TelemetryService` covers the onboarding funnel (Joined, FirstCoin, OpenedShop, FirstPurchase), the shop funnel, the coin economy (every source and sink, including codes, group reward and quests) and custom events. In Studio events print as `[Analytics] ...`; in a published game they appear in the Creator Dashboard. Details in [architecture.md](architecture.md#analytics).

## Studio test commands

Chat commands exist only when `RunService:IsStudio()`. They need `TextChatService.ChatVersion = TextChatService`, which the project sets; reopen a freshly built place after changing it.

| Command | Effect |
| --- | --- |
| `/cash <n>` | add or remove coins |
| `/reset` | coins, inventory, equipped item, redeemed codes, daily streak and starter quests back to zero |
| `/unlock` | own every shop item |
| `/daily` | daily reward claimable again |
| `/pass <Name>` | toggle a game pass for this session |
| `/notify <text>` | show a toast |

Agents type them through `user_keyboard_input`. If synthetic chat input does not reach the bar, `TextChannels.RBXGeneral:SendAsync("/unlock")` from the client in `task.spawn` works.

## Illustrated UI kit

- **Art kits:** generated by a delegated image model, uploaded with the Studio MCP and recorded per kit in `assets/source/ui/<kit>/` (`manifest.json`, `prompts.json`, `roblox-ids.json`, `verify.py`, `contact_sheet.png`):
  - `shop`: windows, buttons, tabs, slots, daily tiles, settings controls, dock, loading;
  - `promo`: discount tag, banners, VIP and premium badges, premium icons;
  - `social`: group, invite, heart, trophy, medals, backpack, input field, hint banner, board.
- **Layouts:** every window and the world board are generated by `assets/source/ui/shop/build_ui.py` into `assets/ui/*.model.json`, `assets/world/Leaderboard.model.json`, `Config/UiImages.luau` and `src/first/LoadingImages.luau`. Edit the builder, never the outputs.
- **Checks:** `pnpm run check` fails if a model uses an image id no kit records, or writes attributes with a capital `Attributes` (Rojo only reads `attributes`).
- **Motion** is deliberately calm (`UIController/Effects.luau`): a small press dip, short fades, no hover growth, no bounce, no pulsing.

## What only a published game can prove

Real DataStore saves, the cross-server leaderboard, Robux prompts and receipts, badges, group reward, invites, favorites, regional policy for real players and analytics dashboards. Use a separate test universe and the checklist in [release.md](release.md).
