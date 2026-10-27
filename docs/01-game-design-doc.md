# Yardwork: Prison Mining Simulator

Stage 1 — Game Design Doc, draft for feedback  
Working title; check availability and branding before release.  
Status: design only. No game code or Studio runtime has been built or tested yet.

## 1. Pitch and assumptions

Turn a drab cartoon prison yard into a bright community workshop by mining unusual ore, selling your haul, and earning increasingly ridiculous job titles. A friendly warden rewards progress with better equipment and access to new work yards. Prestige means graduating from one rehabilitation program and volunteering for a tougher one. The fantasy is growth, collection, and satisfying destruction, with no realistic violence or punishment.

Your confirmed production plan is solo development, Roblox Studio parts for initial art, a broad family audience roughly 9+, plain Studio editing, and a first release with one mine, selling, and three ranks. The later architecture will also support Rojo. The audience target is not a final platform age-rating or compliance determination.

Start with one playable mine, selling, and three ranks. Expand only after mining feels good and saving is dependable. No live purchases in the first prototype.

Genre references are general simulator mechanics: gathering, capacity management, upgrades, and prestige. Characters, names, geometry, interface, sounds, and assets must be original or appropriately licensed. Do not reproduce another game's map or economy.

## 2. Player promise and tone

- Every short trip produces visible progress without spending Robux.
- Breaking blocks feels chunky, readable, and responsive on a phone.
- Players always see one achievable next goal.
- Humour comes from bureaucracy, cheerful guards, novelty ore, and silly job titles.
- Cooperative play is welcome; players cannot steal stored resources, damage each other, or obstruct selling.

Example warden line: “Excellent paperwork. You may now hit slightly shinier rocks.” Avoid humiliation, coercive labour themes, graphic injury, or realistic incarceration messaging. Describe the activity as an optional cartoon workshop program.

## 3. Three loops

**30 seconds:** Walk into the mine, target blocks, and click or hold to chip them away. Health feedback, particles, and a small reward number confirm each break. Collect ore until the backpack approaches full, return to the sell counter, and receive money. Spend on a reachable upgrade or see progress toward the next rank. A new player receives their first sale reward within 30 seconds through a short, nearby starter route.

**Five minutes:** Complete several mining-and-selling trips, improve a tool or backpack, and make visible progress toward a rank. Five minutes is a session milestone, not a promise of a rank every five minutes: the initial target is 10–15 minutes per early rank for a typical free player. Milestones include a new ore discovery, upgrade purchase, and rank-progress checkpoint. Rank-ups unlock a mine and a small explicit perk in the expanded game.

**Multiple days:** Reach rank Z, prestige, and restart with a permanent earnings bonus and tokens. Buy deterministic token upgrades and collect cosmetics. Later releases add pets, social goals, and leaderboards. Each return presents a useful goal without threatening loss of earned progress for missing a day.

## 4. Playable prototype: first gate

One small mine serves ranks A–C. Rank changes grant a fixed sell bonus within that mine; separate per-rank mines and ore progression are deferred until expansion. This is an intentional prototype exception to the final one-mine-per-rank design.

Include:

- One original courtyard, spawn, mine entrance, shop counter, and sell pad.
- Three block types, server-owned health, one starter pickaxe, and two pickaxe upgrades.
- Backpack capacity, two capacity upgrades, and selling of stored ore.
- Ranks A, B, and C; C is the prototype completion milestone.
- A visible mine-reset countdown and safe reset handling.
- Money, rank, ore inventory, and purchased upgrades saved with session ownership protection.
- Mobile-first HUD, contextual instructions, notifications, and basic settings.
- A small funnel: first mine, first sale, first upgrade, first rank-up.

Defer prestige, pets, enchants, daily rewards, codes, events, passes, products, global leaderboards, and VIP to later gates. Never present a purchasable item whose fulfilment is unfinished.

Prototype acceptance: a new test player can join, break ore, fill a bag, sell, buy an upgrade, reach C, leave, and rejoin with correct saved progress. Two players can mine simultaneously without duplicate rewards. Touch controls and reset recovery must work in Studio device emulation and on a real mobile device.

## 5. Expanded progression

### Ranks

Use A–Z for navigation, with optional humorous subtitles. Early examples: A — New Arrival, B — Yard Apprentice, C — Trusted Digger. Full progression has 26 ranks and 25 paid rank transitions. A rank unlocks its corresponding mine and one clearly stated perk, such as a small sell bonus or access to a new ore family. Rank perks must not silently multiply several economy factors.

New mines should change colour, silhouettes, ore distribution, and one visual landmark. Avoid producing 26 unrelated large maps: use an original modular kit and compact mine rooms, stream distant areas, and activate block populations based on players nearby. Target client and server budgets will be measured during implementation.

Rank-up consumes money and preserves equipment, cosmetics, tokens, and backpack contents. The prototype has one shared mine; full progression offers a mine selector with server-verified access. Show the next cost and unlock before confirmation.

### Pickaxes and enchants

Money buys base pickaxe tiers and backpacks. Base tools improve damage or swing interval with a minimum server-enforced interval. Later token enchants are deterministic purchases: Fortune adds bonus ore, Chain breaks a limited set of adjacent blocks, and Burst affects a small bounded radius. Each has explicit caps, server-calculated targets, and a work budget per action. Extra drops consume bag capacity; overflow is not silently destroyed.

Prototype: no enchants. Expanded v1: Fortune first; Chain and Burst follow only after profiling and contention tests. Damage does not imply permission to mine through walls or in locked mines.

### Prestige

At Z and a displayed final money goal, the player may confirm prestige. It resets money, rank, cash-bought tools, cash-bought capacity, and unsold ore, so the next cycle has meaningful goals. The confirmation lists every loss and retained benefit. It retains cosmetics, passes, tokens, token upgrades, and statistics. This equipment-reset choice is provisional and should be playtested.

Prestige grants a fixed token award per cycle plus a permanent additive sell bonus. Initial model: +20% per prestige, with the total prestige multiplier capped at 5× until longer-term balancing supports expansion. Tokens buy deterministic upgrades and cosmetics; no paid random rewards. Prestige-shop utility starts with modest base capacity and Fortune improvements, each with a cap.

Target first prestige: approximately 5–8 hours of active free play over multiple sessions, subject to spreadsheet modelling and playtests. Later cycles should feel meaningfully faster without reducing the whole loop to seconds. Higher-cycle goals and optional cosmetic milestones provide longer-term sinks.

## 6. Economy model and initial tuning hypotheses

Use two currencies: money and tokens. Ore is capacity-limited inventory, not a third wallet currency. Robux purchases use Roblox purchase APIs directly. Cosmetic events should initially reuse tokens or direct milestones instead of adding a currency.

| Resource | Sources | Sinks |
| --- | --- | --- |
| Money | Ore sales; bounded daily/code rewards later; optional fixed money products | Ranks, cash tools, backpack tiers; reset on prestige |
| Tokens | Prestige; capped milestones/events; optional 2× token pass | Deterministic enchant levels, permanent capped utility, cosmetics |
| Ore | Server-confirmed broken blocks and Fortune | Sell inventory; explicit prestige reset |

No trading in initial releases. This reduces duplication, scam exposure, and uncontrolled transfers while the economy is being calibrated. Avoid recurring upkeep, repair charges, or penalties that strand a player unable to mine.

**Sale rule:** calculate the base value of all ore server-side, then multiply once by each category: rank × prestige × money pass × active money boost × social/event bonus. Bonuses within the social/event category add together and are capped. Round down once at the final total. Show active categories in a tooltip. Token multipliers apply only to eligible token awards, never ore money.

Initial caps: money pass 2×; money boosts at most 2×; friend bonus +5% per eligible friend in the server up to +15%; event bonus at most +100%; combined social/event category at most 2.15×. Buying another timed boost extends its duration rather than increasing its multiplier. These factors must be modelled together before live monetization.

Prototype modelling anchors, not verified balance:

- Ore values 1 / 3 / 8; distribution 70% / 25% / 5%; mean 1.85 money per stored unit before multipliers.
- Starter bag: 30 units. Nominal mining: 2 units/second during active mining, subject to block health and travel.
- A nominal trip takes 15 seconds mining plus 10 seconds travel/selling, yielding about 133 base money/minute at full efficiency.
- At a conservative 65% realised efficiency, revenue is about 87/minute. A first rank goal around 900 plus roughly 200 spent on upgrades suggests about 12.6 minutes before upgrade acceleration.
- B→C must be recalculated using its actual upgrades, perk, ore mix, and travel time; simply doubling costs would not prove the timing target.

The later .xlsx model must include editable ore weights/health, bag size, damage, swing interval, travel, efficiency, upgrade spend, rank bonuses, all monetization factors, prestige reset rules, and token costs. Use a geometric rank-cost curve as a starting hypothesis, then tune individual tiers. Sum all 25 transition times plus the final prestige goal: early 10–15 minute ranks and a 5–8 hour prestige must reconcile in the same model. Report free baseline and paid/boosted scenarios separately. Do not advertise these targets as measured results.

Inflation control comes from bounded sources, rank and upgrade spending, prestige resets, capped permanent power, and cosmetic token sinks. Track unspent wallet distributions and time-to-goal before changing rewards. Never secretly devalue an existing balance to push a purchase.

## 7. Mining, resets, and selling rules

The client requests an action against a known block; the server verifies identity, distance, mine access, tool ownership, timing, player state, and remaining capacity. The server owns block health, break resolution, ore rolls, and rewards. Simultaneous final hits yield one break reward according to a defined last-valid-hit rule; communicate shared-mine contention through fast feedback. Reconsider instanced mining if playtests show frustration.

Hold-to-mine touch input is free accessibility functionality. A future Auto-Mine pass may provide optional repeated targeting within a short valid reach while actively present; it must not be required for holding the button, grant AFK income, or bypass access and rate rules.

Sell pads offer a clear button; selling all is also available in the HUD while physically near an authorised sell point. The button does not provide remote selling in the free baseline. A full bag displays a clear route to sell. Money grants and inventory consumption occur as one server-owned state change.

Prototype reset hypothesis: every 5 minutes, with a 30-second warning. Move affected players to the safe rim before rebuilding. Cancel stale mining requests using a reset generation, generate in bounded batches, and disable mining until ready. Reset never deletes backpack contents or traps players. Avoid spawning all blocks in one frame. Final grid size, pooling strategy, and reset interval depend on profiling.

## 8. Monetization after safety and fun gates

All progression must be attainable for free. Paid advantages are disclosed acceleration or convenience with bounded stacking. Exact Robux prices, fees, eligibility, regional pricing, purchase APIs, and current platform policies must be verified on the Creator Hub before release. This document makes no revenue promise.

| Offering | Intended benefit | Constraint |
| --- | --- | --- |
| 2× Money pass | Doubles ore-sale money | Visible category; included in balance scenarios |
| 2× Tokens pass | Doubles eligible prestige token grants | Does not multiply money or paid grants |
| Auto-Mine pass | Optional nearby auto-target assistance | Free tap/hold stays available; no offline income |
| Backpack pass | +50% capacity over earned capacity | Free upgrades remain useful |
| VIP pass | Tag and decorative lounge | No exclusive progression ore or mandatory upgrades |
| Money products | Fixed clearly displayed amounts | No hidden scaling at fulfilment time |
| Timed boosts | 2× money for 15/30/60 minutes | Same-strength time extension; server timestamp; disclose offline expiry |
| Mine reset product | Additional reset opportunity | Later release only; cannot erase active miners' progress |

Instant-reset design remains gated: use personal mines or a clearly communicated safe shared reset with a cooldown, warning, and queued intent. A paid receipt must not perform an unrecoverable world effect before its persistent grant is recorded. If the server closes, a saved unconsumed reset credit remains available. Do not sell this product until the recovery path is tested.

Starter pack: one fixed, clearly described cosmetic-led bundle with a modest fixed money amount. Best-value highlighting compares a consistent measurable benefit such as boost minutes per Robux; do not invent a crossed-out price or imply an unverified discount. No purchase prompts during onboarding, active mining, or failure. Show the shop on deliberate interaction or an optional post-sale panel.

Developer-product receipts require server-side product lookup, durable idempotency by purchase ID, safe session ownership, and persistence of the grant before returning PurchaseGranted. Failures defer acknowledgement. Test repeated receipts, concurrent servers, disconnects, and a crash between durable grant and acknowledgement. Pass ownership uses supported platform checks. Client purchase-finished messages never grant goods.

## 9. Retention, social play, and analytics

After the prototype, add an optional daily claim with a short streak that pauses or gently restarts without removing earned items. Use UTC day boundaries, server time, and an explicit next-claim timer. Rewards should help without making attendance mandatory. Codes are server-configured, capped, and redeemed once per account. No secret admin codes shipped in client modules.

Events such as Workshop Weekend offer disclosed double rewards on a scheduled server-time window. Avoid calling a reward limited-time unless the end date is real. Friends can mine together, receive the capped friend bonus, and share celebration effects. Trading and pet power are v2 work requiring separate design and exploit review.

Global leaderboards: most prestiges, highest rank, and richest. Richest reflects paid acceleration and is not a fair skill contest; provide no exclusive power prizes. Use cached, budgeted updates, not a write on every sale. Ordered display data must not become the authoritative save.

Funnel events: first mine → first sale → first upgrade → first rank-up → first prestige; separately record first confirmed purchase and day-1 return. Persistent milestones prevent first-time events firing on every join. Define day-1 as a return on the next UTC calendar day and retain session-duration data for context. Use current supported analytics APIs and dashboards; never log private chat, credentials, or unnecessary personal data.

Measure onboarding completion, time to first sale, bag-full friction, median time per rank, session length, D1/D7/D30 retention, purchase conversion, and economy source/sink totals. Initially establish baselines; do not optimise session duration with forced waiting or treat correlation as proof of an improvement. Small audiences may not support meaningful A/B results.

## 10. UX and art direction

Bright chunky low-poly cartoon: warm sandstone buildings, teal equipment, orange uniforms, indigo shadows, and mint reward accents. Use strong silhouettes and readable ore patterns so colour alone is not required. The detailed asset manifest, budgets, and lighting recipe belong to Stage 5.

HUD shows money, bag bar, current rank, next goal, and mine countdown. Phone layouts use large thumb-accessible mine/sell controls, safe-area spacing, concise numbers with exact-value details, and no overlap with default movement controls. Support mouse and gamepad without assuming hover. Shops show owned state, price, before/after effect, and why an item is locked.

Settings include music, effects volume, reduced effects, reduced camera motion, and auto-mine preferences where applicable. Break feedback includes a health cue, restrained particles, and a short sound. Sales use one summary burst; rank-up uses a skippable celebration. Effects must not obscure hazards, target selection, or controls. Audio must be original or licensed for this experience.

First 60 seconds: spawn facing the mine, receive a tool automatically, highlight a starter block, mine a small reward, follow a nearby sell marker, and see the first useful upgrade. No full-screen shop or paid prompt before this sequence completes.

## 11. Data safety, security, and performance gates

Use versioned profiles with session locking, migration, autosave, leave/shutdown saves, bounded retries, and safe lock recovery. On a load failure, show retry/leave messaging and disable economy actions; never replace an existing profile with defaults after an error. Track receipt grants durably and test recovery before enabling purchases.

Every remote needs argument validation, rate limits, state checks, and server-side computation. Reject non-finite numbers and impossible action sequences. Avoid punishment based on a single latency-sensitive anomaly; reject invalid actions and inspect aggregated signals. No credentials or authoritative prices in client-controlled state.

Profile reset spikes, active block counts, replication, enchant bursts, memory, and save budgets. Initial performance goal is stable 30 FPS on a chosen low-end mobile test device at the declared player cap, with no sustained reset stalls. This is a target, not a verified claim. Choose the release player cap from multi-client measurements. Streaming and pooling do not replace measurement.

## 12. Release gates and scope

| Gate | Scope | Evidence required |
| --- | --- | --- |
| Prototype | One mine, A–C, mine/sell/upgrades/save, essential HUD | Complete fresh-player loop, two-player contention, rejoin, touch input, reset safety |
| Expanded v1 | A–Z compact mines, prestige/tokens, basic Fortune, daily rewards/codes, baseline analytics | Economy model reconciles targets; full-cycle playtest; migration and crash recovery |
| Monetized v1 | Verified passes, fixed products/boosts, starter bundle, VIP cosmetics | Receipt replay/crash tests, stacking tests, purchase clarity, current policy review |
| v2 | Pets/skins collection, more enchants, events, leaderboards, optional personal mines | Performance and retention evidence; separate economy and abuse reviews |

Avoid schedules that imply one developer can safely ship all requested systems at once. Advance when the preceding gate works. A full 26-mine world is an expansion of the validated slice, not the first coding task.

## 13. Deliverable sequence and feedback gate

1. This Game Design Doc.
2. Architecture and full Script/LocalScript/ModuleScript inventory, Rojo layout, and plain Studio mapping.
3. Runnable core files, beginning with the minimal playable slice and then expanding through the gates.
4. Studio setup and publishing guide.
5. Detailed style guide and asset manifest.
6. Formula-driven .xlsx economy model with assumptions and scenario comparisons.
7. Testing checklist covering data, exploit attempts, devices, performance, and onboarding.
8. Launch materials, verified pricing proposals, and a three-month update roadmap.

Pause after each numbered stage for your feedback. Your solo/tool/audience assumptions and three-rank first-release scope are confirmed. Stage 1 feedback should settle the title/tone, 10–15 minute early-rank target, prestige reset losses, and whether the optional Auto-Mine pass feels fair. Stage 2 begins after that feedback; no later deliverables are being presented as completed here.

## Implementation update

You approved continuing through all stages. The shipped prototype retains one mine and A–C; expanded features are configurable. The implemented rank curve is 900 for A→B, then `floor(1800 × 1.34^(rank−2))`. The generated workbook estimates a 5.67-hour first prestige under its stated expanded-mode assumptions. These supersede early curve hypotheses above and remain unverified by player testing. See Stage 3 for implementation boundaries and Stage 7 for required Studio checks.
