# Stage 7 — Testing and release gate

## Executed in the cloud workspace

- Official Luau compiler successfully compiled every shipped `.luau` file. This is syntax/bytecode validation, not Roblox-aware static type analysis.
- 36 assertions passed against the actual DataService, MonetizationService, BackpackService, RankService, ShopService, PrestigeService and RetentionService implementations in a mocked engine. Includes session-lock contention, durable rejoin, copy isolation, rejected/busy transactions, receipt replay, unknown/offline receipts, write outage/recovery, selling, upgrades, prestige and duplicate claims.
- Economy workbook generated with formulas and cached scenario values; free first-prestige baseline approximately 5.67 hours. This is not observed player timing.
- Place XML generated and script count/source round-trip checked. Studio opening/runtime is unverified.

Luau CLI used: upstream luau-lang/luau commit `32c28089305f488f901aaf1dbf3fd1cb65fa3d11`, compiled locally using its Makefile. Runtime tests use mocked Roblox services and do not simulate engine/network/DataStore scheduling fully.

## Unpublished Studio startup correction

DataStore acquisition is now lazy and occurs inside the protected persistence path. In-memory Studio mode never requests a real DataStore. Five new regression assertions exercise module loading, transactions, save/release and rejoin against an unpublished-place mock that throws if GetDataStore is called. All five pass; the same regression fails on the prior version with the reported error. The original 36 service assertions also pass. Actual Studio execution remains pending.

## Required Studio/manual checks — all pending

### First playable slice

- [ ] Open the shipped .rbxlx without import warnings; Play produces no errors.
- [ ] Fresh account can mine, fill a bag, sell, upgrade and reach C.
- [ ] First reward within 30 seconds; no purchase prompt interrupts onboarding.
- [ ] Full bag never grants beyond capacity; sell button fails far from authorised pads.
- [ ] Touch hold/aim, mouse input and gamepad input work. UI never overlaps default touch controls.
- [ ] Return to safety works from the bottom of the pit; walking/jumping cannot trap players.
- [ ] Two players final-hit one block: total reward is granted once.
- [ ] Reset countdown warns, relocates miners safely and preserves backpacks.

### Data safety

- [ ] Test datastore namespace is separate from production; StudioMemory=false only on the test experience.
- [ ] Leave/rejoin and server shutdown preserve expected data.
- [ ] Two servers cannot own one profile simultaneously; stale owner cannot save over a new lease.
- [ ] Simulated timeout/denial refuses play rather than replacing profile with defaults.
- [ ] Crash after mining can lose only documented unsaved progress; paid grants remain durable.
- [ ] Unsupported schema version is refused; additive v1 fields migrate correctly.
- [ ] High purchase history/profile size remains under current platform limits.

### Monetization and recovery

- [ ] Every pass/product ID matches the displayed offering and owning experience.
- [ ] Receipt replay, disconnect, cross-server retry and crash-after-save-before-ack grant exactly once.
- [ ] Unknown products defer; pending older product IDs remain mapped.
- [ ] Storage failure never returns PurchaseGranted before confirmed durable grant.
- [ ] Boost extends time, never stacks strength; offline expiry is explained.
- [ ] Reset credit survives crash before redemption; pending redemption recovers after reconnect.
- [ ] Crash after reset-before-clear may cause a second safe reset but no second credit or money grant.
- [ ] Pass ownership refresh works; purchased perks are visible and free progression remains satisfying.

### Security

- [ ] Invoke remotes with tables, nil, huge strings, NaN, infinity, unregistered/destroyed parts and locked tiers.
- [ ] Spam Mine/Sell/Shop concurrently; limits hold, wallets never go negative, goods never duplicate.
- [ ] Out-of-range/through-wall mining fails; client-written health/currency has no authority.
- [ ] Visit refuses locked mines; prestige requires Z, funds and explicit confirmation.
- [ ] Test teleport/speed abuse. Existing distance/cadence checks are not comprehensive movement detection.
- [ ] Products and codes cannot be granted by client purchase-finished callbacks.

### Expanded mode and economy

- [ ] Complete A–Z cycle and prestige; verify reset/retention list exactly.
- [ ] Test rank × prestige × pass × boost × capped event/friend category once, final rounding once.
- [ ] Fortune respects capacity; Chain/Burst cannot exceed 12 targets or bypass locked mine access.
- [ ] Daily UTC boundary, missed day, seven-day cap and code replay work.
- [ ] Scheduled event starts/ends on server time; expired event has no bonus.
- [ ] Collect time-to-rank distributions and compare against workbook; revise tuning with evidence.
- [ ] Leaderboards update without throttling; cached values never overwrite authoritative profiles.
- [ ] Analytics first-event/D1 markers and dashboard ingestion work in published test servers.

### Mobile, accessibility and launch

- [ ] Eight-client expanded test, simultaneous resets, repeated enchants, memory soak and reconnect storm.
- [ ] Profile on a real low-end phone, tablet, desktop and gamepad device. Target 30 FPS minimum.
- [ ] Effects/music toggles work after rejoin; reduced motion avoids bobbing and screen motion.
- [ ] Labels readable at small screens; ore distinguishable without colour; purchase amounts unambiguous.
- [ ] Only original/licensed assets; uploaded audio permissions work for another account.
- [ ] Current Creator Hub APIs, policies, content maturity settings and actual prices reviewed.

Do not treat unchecked items as passed. Public monetization stays off until the relevant gates pass.
