# Stage 4 — Studio setup, testing and publishing

## Fast start (plain Studio)

1. Open `dist/Yardwork.rbxlx` as a local place. Keep an untouched backup.
2. Inspect Explorer: Shared modules under ReplicatedStorage, Bootstrap/Services under ServerScriptService, Game under StarterPlayerScripts. Do not copy multiple Bootstraps into one place.
3. Play. Walk toward the mine, aim at a visible block, click/hold or use the touch Hold button. The backpack fills only when blocks break. Walk to the green sell pad, press Sell All, then open Workshop for equipment and ranks. Return to safety is in Choose mine.
4. Test two clients using Studio's server/client test mode. Each client sees a shared mine. A final valid hit wins a block's reward. Use Output to inspect script errors.
5. Turn off Play before editing source. Saving a local place during Play does not preserve runtime-generated world instances as authoring source.

## Persistent saves

Publish a private **test** experience under your own account/group. Enable the relevant Studio API access setting only for that test experience, then set Config.StudioMemory=false. Confirm leave/rejoin across sessions, lock contention and receipt replay tests. Never enable Studio against a live production datastore namespace casually: Studio requests can modify real records. Use a distinct Config.DataStore name for test versus production. Keep StudioMemory=true for disposable blockout tests.

The in-memory Studio mode cannot test cross-process locks or restart persistence. No Open Cloud API key is needed for ordinary in-experience DataStoreService access. No credentials belong in Config, client modules or Git.

## World layout and tags

The current world is generated automatically; no manual tags or remotes are required. Prototype mine centre is `(0,-6,0)` with a 24×12×24 block volume, a safe rim, a sell pad near `(-18,0,22)`, and spawn near `(0,1,25)`. Expanded mines are 90 studs apart along X. Keep the central hole clear and preserve the floor under the deepest blocks. The menu's Return to safety avoids trapping a player at the bottom.

For a custom art pass, add decorative models outside block volumes and safe relocation points. Keep visual props out of mining ray paths. Use CollectionService tags MineRegion, MineBlock and SellZone for inspection. Tags alone are not registration: MineService's registry and reset state own mining eligibility. Modify the procedural dimensions/positions and safe-point function together if changing the map. Do not duplicate tagged regions and expect the system to discover a complete custom mine automatically.

## Configure expanded features

- Set Prototype=false for A–Z and prestige; save a separate test copy first.
- Event.Start/Finish are UTC Unix timestamps; inactive when both zero. Bonus=1 means +100% inside the social/event category.
- Edit server reward codes, amounts, expiry handling before a campaign. The current starter code is WELCOME; it is not a secret.
- Set experience maximum players to 8 initially, matching Config.PlayerCap. This configuration is a target setting, not a server admission-control implementation.
- Upload `assets/audio/*.wav` under the experience's owner and grant the experience permission. Paste the resulting asset IDs into Config.Audio. Confirm copyright and platform permissions for any replacements.

## Monetization

Create passes and developer products in Creator Dashboard for the correct experience. Fill unique nonzero IDs in Config; the Robux fields in product config are pricing proposals only and do not set platform prices. Actual purchase prompts are the authority for price. Test every ID/product mapping and ownership check before enabling storefront buttons. Account for regional pricing and current Roblox rules on Creator Hub. Do not use real purchases as casual automated tests.

Passes: Money, Tokens, Auto, Backpack, VIP. Product kinds: Starter, Money, Boost and Reset. Keep old product IDs mapped for delayed receipts. Repeat starter purchases grant their fixed money again and keep the same skin; describe that clearly if using a repeatable developer product. Prefer a one-time pass/bundle design if you want truly single-purchase semantics.

## Publish checklist

Choose an original available name, set correct content maturity/audience information, verify all assets and ownership, set device support and player cap, configure icons/thumbnails, and publish privately. Run the Stage 7 checklist with real devices and at least two accounts. Confirm saving, rejoin, resets, purchase grants and free progression. Only then make public and enable deliberate promotion. Publishing is manual; this repository does not publish or change your Roblox account.

## Rebuilding and Rojo

Plain Studio: after source changes outside Studio, run `python3 tools/build_place.py` and reopen the newly generated place; preserve Studio art edits in a separate authored place/model to avoid overwriting them. The generator produces a fresh source-based place, not a merge of Studio edits.

Rojo users may run `rojo serve default.project.json` and connect via the Rojo Studio plugin in a test copy, or `rojo build default.project.json -o Yardwork.rbxlx`. Source service layout is compatible; manually enable Workspace.StreamingEnabled for the Rojo route. Pin a trusted Rojo version and install from official sources. No Rojo installation is required for the supplied place.
