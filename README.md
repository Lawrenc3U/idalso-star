# Yardwork — Prison Mining Simulator

An original cartoon mining game scaffold with a playable A–C prototype configuration and expandable A–Z progression. Solo-friendly, built from Studio parts. **Not yet playtested in Roblox Studio or cleared for public monetized release.**

## Play in Studio

1. Download/open `dist/Yardwork.rbxlx` in Roblox Studio (File → Open from File).
2. Press Play. The server creates the courtyard, mine, tools, redesigned HUD, quarry scenery, shops, and sell counter automatically.
3. Aim at blocks and click/hold. On mobile, aim the centre crosshair and hold the mine button. Use Go to sell to reach the counter, then Sell all (or its interaction prompt). Open Upgrades for gear/ranks, Mines for travel, and Menu for settings/rewards.
4. Studio uses temporary in-memory profiles by default. Stop/Play resets them. See [persistent testing](docs/04-studio-setup.md) before testing real saves.

Default: one mine, A–C, money, backpacks, pickaxes, safe timed resets and session-owned profiles. Set `Config.Prototype=false` for the expanded 26-mine mode, prestige, tokens, enchants, cosmetic buddy/skin, rewards and leaderboards. Paid IDs and audio IDs are zero by default; no purchases are offered until configured.

## Files

- [Design](docs/01-game-design-doc.md)
- [Architecture and script inventory](docs/02-architecture.md)
- [Core implementation notes](docs/03-implementation.md)
- [Studio setup and publishing](docs/04-studio-setup.md)
- [Art direction and manifest](docs/05-assets-and-style.md)
- [Economy workbook](docs/06-economy.xlsx)
- [Testing checklist and actual results](docs/07-testing.md)
- [Launch plan](docs/08-launch-plan.md)
- [New HUD, quarry art and Blender import guide](docs/09-visual-refresh.md)
- [Blender quarry preview](assets/blender/quarry-preview.png)
- [Phone HUD layout reference](docs/previews/hud-phone.svg)

`src/` contains the editable Luau files; `default.project.json` is Rojo-compatible. No plugins or third-party runtime packages are required. The `.rbxlx` is generated from exactly these source files, with streaming enabled.

## Build and checks

```sh
python3 tools/build_place.py
# Optional workbook regeneration: python3 -m pip install -r tools/requirements.txt
python3 tools/build_economy.py
python3 tools/test_services.py --luau /path/to/luau
python3 tools/test_hud_layout.py --luau /path/to/luau
python3 tools/test_hud_interactions.py --luau /path/to/luau
# Run luau-compile --null against every src/**/*.luau file.
python3 tools/package_release.py
```

Compiler validation and mocked service tests do not validate Roblox engine behaviour, device performance, publishing, real DataStores, analytics, ownership APIs, or purchases. Use a separate test experience and complete the release checklist. No credentials are included; no paid assets are required.
