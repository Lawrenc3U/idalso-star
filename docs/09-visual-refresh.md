# HUD and quarry visual refresh

## What changed

The HUD now separates money/tokens, rank/reset timer, next goal and backpack capacity into small readable cards. The main navigation has only **Upgrades**, **Mines** and **Menu**. Wallet amounts use compact notation, the bag bar becomes orange when full, and targeting shows a block outline and health bar.

“Go to sell” requests an authorised server teleport to the current mine's sell stall. It changes to “Sell all” near the stall. Empty bags show guidance instead of sending a pointless request. The sell stall also has a ProximityPrompt with a server-side distance check; the workshop prompt opens the upgrade menu. Mouse hold, touch hold and gamepad mining stay free. B opens upgrades, M opens mines, N opens the menu; gamepad Y opens upgrades and X travels to/sells at the counter.

Menus use separate cards with an upgrade's benefit and cost. Unaffordable options are muted and explain why they cannot be bought. Ordinary wallet updates preserve focused buttons, scroll position and typed reward codes. Motion can be disabled. A mining finger stays active when a separate joystick finger releases.

## World and models

`WorldArt` creates a cohesive sandstone-and-teal quarry: stone pit walls, timber safety rim, warning markings, mine entrance, barred perimeter wall, guard tower, low-poly rock outcrops and trees, planters, lanterns, benches, ore cart, supply crates, workshop and sell stalls, Warden Milo and a VIP gazebo. Ores have distinct material/colour and raised copper/crystal details. Pickaxes have a handle, head, wedge tips, grip bands and collar, with upgrade/skin colours replicated by the server.

The ready-to-play map uses Roblox Parts/WedgeParts and built-in materials. It needs no mesh uploads, external model IDs or Toolbox scripts. Decoration generally has collision/query/touch disabled so it does not block mining raycasts. Structural walls, ground and pit liners collide. Server-owned block hitboxes and reward rules remain in MineService.

## Previews

- `assets/blender/quarry-preview.png`: actual Blender render of geometry exported from the WorldArt module. It is **not a Roblox screenshot**. Blender adds small flat bevels; Roblox lighting and primitives will look different.
- `docs/previews/hud-desktop.svg`, `hud-phone.svg`, `hud-landscape.svg`: layout references generated from actual HUD widgets under a mock. These are **not Studio captures**; fonts, wrapping, safe areas and controls still need real-device checks.

## Original editable Blender assets

Open `assets/blender/Yardwork-Art-Library.blend` in Blender 4.3+. It contains the quarry scene and original model geometry. All eight FBXs were re-imported in Blender with material and outward-volume checks. Eight separate FBX files are provided: guard tower, Warden Milo, ore cart, workshop stall, sell stall, supply crate, pickaxe and tree. `model-manifest.json` records source triangle counts and object counts. No third-party assets or textures were used.

The FBX files are optional art-editing/import assets; the game already has procedural counterparts. In Studio, use the 3D Importer for each FBX and compare scale against an avatar. Target Warden height is about 5.2 studs; tower height about 14 studs. Set anchored decorations and review collision/query settings. Palette materials may need reassignment in the importer. Upload/publish imported meshes through your own experience owner if using them in a published place.

Do not put an imported duplicate over a runtime-generated model: it would overlap. To substitute one, retain the runtime-owned sell zone/prompt, mine region and block registry, and replace only that decorative model's constructor in WorldArt. Keep mine block hitboxes registered in MineService. Imported pickaxe meshes need a correct Handle and welds; the supplied game tool is already assembled from runtime parts.

## Updating an existing Studio place

Safest: stop Play and open the newly rebuilt `dist/Yardwork.rbxlx`. This keeps the prior unpublished-Studio DataStore fix and includes every new module.

To keep your own unrelated Studio edits, stop Play and replace Bootstrap, MineService and Game; add WorldArt under ServerScriptService/Services, HUDLayout under ReplicatedStorage/Shared, and HUDController under StarterPlayer/StarterPlayerScripts. These are ModuleScripts except Bootstrap (Script) and Game (LocalScript). Do not leave a second Game LocalScript or old manually copied HUD running. Keep your configured product IDs and datastore namespace unchanged. No data migration is required by this refresh.

## Rebuild and validation

```sh
python3 tools/test_services.py --luau /path/to/luau
python3 tools/test_hud_layout.py --luau /path/to/luau
python3 tools/test_hud_interactions.py --luau /path/to/luau
python3 tools/export_art_scene.py --luau /path/to/luau
blender --background --python tools/build_blender_assets.py
python3 tools/preview_hud.py --luau /path/to/luau
python3 tools/build_place.py
python3 tools/package_release.py
```

All 18 Luau files compile. The existing 41 service checks, 290 layout assertions over nine viewports, and 15 mocked HUD interaction checks pass. WorldArt construction produced 348 visible parts in the single-yard art scene, including the sample mine and tool. This is a construction/render export, not a full Roblox simulation. Expanded mode replicates the yard kit per mine; measure server and mobile costs before enabling 26 mines publicly. Real Studio rendering, UI/gamepad navigation, prompt behaviour, mobile safe areas and performance remain unverified in this cloud environment.
