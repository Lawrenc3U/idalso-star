# Stage 3 — Core implementation

All runnable files are in `src/`, embedded in `dist/Yardwork.rbxlx`. They use `--!strict`; dynamic profile/config/service boundaries currently use explicit `any`. Compilation has been checked; full Roblox-aware type analysis and Studio runtime validation remain outstanding.

## Implemented capability map

| System | Implementation | Release caveat |
| --- | --- | --- |
| Mine and reset | Weighted ore, health, safe relocation, generation checks, 3 reset batches/mine | Fixed small grids; no part pool; measure simultaneous resets |
| Mining | Mouse/touch/gamepad holds, cooldown, distance/raycast checks | Client character movement is replicated; not a comprehensive movement anti-cheat |
| Enchants | Fortune, bounded adjacent Chain/Burst selection | Area-target iteration order is not a deterministic spatial ordering; cap 12; profile first |
| Economy | Capacity, sell-pad proximity, single final rounding and multiplier categories | No trading, no offline income |
| Ranks/prestige | A–C default, A–Z expanded, permanent sell multiplier and tokens | First-release rank perks are sell bonuses; same ore mix in prototype |
| Upgrades | Cash pick/bag, token enchants/capacity and fixed cosmetic skin/buddy | Pet is a local cosmetic part, not a complex collection system |
| Saving | Leased profile lock, autosaves, retries, leave/shutdown | Production DataStore failure testing required |
| Purchases | Pass checks and durable replay-safe product grants | All IDs disabled; platform tests required |
| Reset product | Durable credit and pending reset intent; warning and recovery | At-least-once world reset on a crash; no duplicated currency grant |
| Retention | Daily, server-defined codes, event multiplier and friends | Disabled in prototype; event off until UTC times configured |
| UI | HUD, bars, shop/rank/prestige, notifications, settings, crosshair | Device layout/accessibility pass required |
| Analytics/leaders | First-event custom metrics and top-ten ordered-store cache | Live platform APIs unverified; leaderboard updates every 120 seconds |

## Reset and receipt recovery

A reset product first grants a durable credit. Redeeming it persists both credit consumption and `ResetPending=mineTier` before scheduling a warning. The intent clears after the rebuild. A joining player with a pending intent requeues the reset. A crash after rebuilding but before clearing may produce an extra reset on recovery; this harmless at-least-once effect is preferable to silently losing a purchase. On reconnect the warning is re-established. Never promise precise wall-clock delivery across server outages.

Receipt processing accepts only configured products and a loaded profile. Duplicate receipt IDs acknowledge the saved grant without adding goods again. Unknown products or missing players defer. Do not remove an old product mapping while pending purchases may exist. ProcessReceipt must have exactly one owner in the experience.

## Default versus expanded

Keep Prototype=true for the first external test. Default monetization IDs are zero and the UI shows no purchasable options. Set Prototype=false only in a separate test copy to exercise prestige, enchants, full mines, daily claims, codes and leaderboards. Token cosmetics are deterministic; there are no random paid items.

Expanded mode builds 26 compact mines at server start, not an infinite world. Streaming reduces client replication; it does not reduce server instance count. The reset implementation uses bounded creation batches rather than pooling. Do not market this as lag-free before profiling.

## Current boundaries

The generated art is a usable blockout: functional parts, a simple warden, a visible pickaxe, basic reward effects and an optional local buddy. It is not a finished commissioned art package. Original generated WAV files are included; upload them to Roblox and enter audio IDs for audible feedback. Purchases, platform analytics, current policy compliance, name availability, real saves, device performance and public publishing need Studio/Creator Dashboard access that this environment lacks.
