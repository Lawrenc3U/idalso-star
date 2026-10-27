# Stage 2 — Architecture and Studio inventory

## Layout

```
ReplicatedStorage/
  Shared/ Config, Types, HUDLayout
ServerScriptService/
  Bootstrap (Script)
  Services/ DataService, EconomyService, BackpackService, MineService,
    RankService, PrestigeService, ShopService, MonetizationService,
    RetentionService, AnalyticsService, LeaderboardService, WorldArt
StarterPlayer/StarterPlayerScripts/
  Game (LocalScript), HUDController (ModuleScript)
```

Every listed item except Bootstrap and Game is a ModuleScript. Source names ending `.server.luau` map to Scripts; `.client.luau` to LocalScripts; other `.luau` files to ModuleScripts. `default.project.json` is the canonical Rojo service mapping. `tools/build_place.py` generates the same hierarchy without Rojo. Plain Studio users should open `dist/Yardwork.rbxlx`; manual pasting is supported using this exact tree and removing file suffixes from instance names.

## Responsibilities

| Module | Authority and purpose |
| --- | --- |
| Config | Shared tuning, zero-by-default product/pass/audio IDs, prototype flag; public, never put secrets here |
| Types | Profile type declaration; no runtime authority |
| DataService | Only owner of mutable profiles, copy-on-read, session lease, serialized transactions, durable writes, migrations |
| EconomyService | Pass cache, friend/event and sell multiplier calculation |
| BackpackService | Count/capacity and ore-to-money conversion |
| MineService | Procedural world, tagged block registry, health, reach/raycast checks, enchants, generation resets |
| RankService | Cost deduction and rank advancement |
| PrestigeService | Confirmation-backed reset and retained permanent rewards |
| ShopService | Cash and token upgrade validation |
| MonetizationService | Receipt handler and verified pass ownership |
| RetentionService | UTC daily claims, codes, D1 milestone |
| AnalyticsService | Persistent first-event markers and custom event logging |
| LeaderboardService | Budgeted ordered-store writes and cached top-ten reads |
| Bootstrap | Wiring, lifecycle, remotes, request validation/rate limiting, state projection |
| WorldArt | Original procedural quarry models, signs, ore details, pickaxes and lighting |
| HUDLayout | Pure responsive placement arithmetic shared with layout tests |
| HUDController | HUD cards, menus, targeting, accessibility preferences and action callbacks |
| Game | Input, purchase prompts, local feedback, HUD wiring and cosmetic follower |

The client separates input/gameplay (Game) from presentation (HUDController) and pure layout arithmetic (HUDLayout). UI is generated at runtime; there is no separate StarterGui dependency. See Stage 9 for the visual refresh and optional Blender assets.

## Remotes and trust

Bootstrap creates `ReplicatedStorage/YardworkRemotes` with Action, State and Notice RemoteEvents. Clients never create or grant authoritative inventory. Action accepts only whitelisted verbs: Sync, Mine, Sell, Rank, Prestige, Shop, Visit, VisitSell, VIP, Daily, Code, Reset and Setting. Each branch checks expected arguments. A per-player token bucket and in-flight guard bound requests; mining additionally enforces the equipped upgrade's server interval, range, raycast, rank and capacity. Invalid requests grant nothing.

State sends only the HUD projection: wallet, rank, upgrades, inventory count, capacity, effects/settings, ownership cache, reset timers and leaderboard display. Receipt IDs, redeemed code history, lock ownership and profile records remain server-only. Notice carries plain feedback text. There are no client-submitted monetary amounts, damage values, product grants or timestamps.

## Profile schema and lifecycle

`YardworkProfiles_v1`, key `p_<UserId>`, stores `{Data, Lock, Revision}`. Data v1 contains money/tokens/rank/prestiges, cash equipment, ore counts keyed `tier:ore`, enchant levels, timed boost expiry, reset credits and pending reset tier, receipt IDs, daily/code state, milestones and settings. See `Types.luau` for fields.

Acquisition uses UpdateAsync with an expiring 180-second token-owned lease. Autosave renews every 45 seconds; mutations stop before lease expiry. Reads return copies. Transactions use candidate profiles; durable operations commit before replacing in-memory state. A write revision confirms the returned record corresponds to that write. A busy profile rejects ordinary transactions rather than yielding in mining critical sections. Loading failure never overwrites a record with defaults. Versions newer than supported are refused; v1 additive fields are filled from defaults.

Purchases, upgrades, rank/prestige changes, codes and daily claims save durably. Ordinary mining and sales are in-memory until the next autosave or clean departure, so a hard server crash can lose up to roughly one autosave interval of ordinary progress. Receipt grants are durable before acknowledgement. Leave and shutdown attempt release saves; timeouts are possible. An uncertain failed write freezes the session; the player must reconnect after lock recovery. Do not claim exactly-once external analytics or crash-proof ordinary mining.

Receipt IDs are retained indefinitely for replay protection. Before unusually large purchase histories approach DataStore size limits, add a reviewed durable archival design. Never solve size pressure by silently deleting receipt IDs.

## Runtime world

World instances live under `Workspace/YardworkWorld`. Mines have `MineRegion` tags and Tier attributes. Blocks have `MineBlock` tags plus Tier/Health/MaxHealth. Sell pads have `SellZone` tags. Runtime generation is authoritative: tagging arbitrary parts alone does not register them for mining. Custom-map support requires extending registration code; see Stage 4.
