# Cookie Empire

A calm, premium 3D idle factory game made in **Godot 4.7** (GDScript, Mobile renderer, portrait).

Start at the kitchen table: one wheat field right next to a brick oven and a delivery truck. Your first cookies sell within seconds. Unlock the sugar cane field, cocoa orchard, hen house and dairy one at a time: each adds a hopper to the glass production line, upgrades the recipe (plain shortbread → sugar cookie → chocolate chip → butter → premium) and raises the price of every cookie. Hire staff, automate every step, upgrade everything and grow a cookie empire.

**Look:** muted, grown-up production site (steel silo hoppers, dark-steel tube frame, brick dome oven, dry-stone farm walls, cypress and olive trees, deep teal sea) with cute toy farmers and factory staff (faces, plaid shirts and overalls, hi-vis, chef whites). UI: a proper game UI with framed counters, a gold-star level badge, chunky wooden and coloured 9-patch buttons, ribbon-titled panels and the Lilita One display font (skins drawn by `tools/gen_ui.py`).

All 3D art is procedural low-poly (`world/mesh_kit.gd`). The 2D icons, app icon and logo were generated for this game with the OpenAI Images API (`tools/gen_icons.py`), and all sound and music is synthesized in code (`tools/gen_audio.py`). No third-party art or audio.

## How to play

| | |
|---|---|
| Move | drag anywhere (floating joystick); WASD / arrows on desktop |
| Pick up / drop off | stand on a coloured pad: items fly onto or off your stack by themselves |
| Build | stand on a gold pad to pay for a new building |
| Zoom | pinch, or the mouse wheel |
| Upgrades / Staff / Boost | the big buttons at the bottom |
| Drop | the red button on the left whenever you carry something: empties your hands, so you can never get stuck |

**The production loop**
1. **Farms** (top row): each has a farmer who harvests the crop, carries it to the crate at the gate, and repeats. Take from the crate's pad.
2. **Hoppers** sit on top of the tube, one per ingredient, each in its ingredient's colour with a badge. Drop items on the pad under a hopper.
3. **The tube**: an empty dough ball rolls in, stops under each hopper for its dose (the ball grows and changes colour), then goes into the oven. A red **!** on a hopper means the line is waiting for it.
4. **The oven** bakes each ball into a batch of cookies, which slide onto the tray. Pick them up there.
5. **Trucks** on the east pier: drop cookies on the truck's pad. A truck leaves when it is full, or a few seconds after its last load. Cookies are sold as it drives off. It comes back after its trip time.

**Workers.** Build the **Staff Cabin**, then open **Workers** to hire. Each role has its own shirt colour, hat, tool, ring and floating badge, and does one job in a loop. Each card shows the job as *FROM → TO* before you assign anyone. Tap a card to see the role's route drawn in the world.

| Role | Look | Job | Needs |
|---|---|---|---|
| Farmer | green, straw hat, hoe | works a farm (choose which); more farmers = faster farm | Cabin |
| Gatherer | blue cap, basket | farm crates → Pantry (straight to the hoppers if you have no Feeders) | Pantry |
| Feeder | orange hard hat, scoop | Pantry → the emptiest hopper | Pantry |
| Collector | chef hat, cookie tray | oven tray → Packing Shelf (straight to a truck if you have no Loaders) | Packing Shelf |
| Loader | red cap, hand truck | Packing Shelf → a parked truck | Packing Shelf |

Resting workers sit on the cabin bench with a "z z" until you give them a job.

**Progression**
- Cookies sold give XP. Each **empire level** pays a cash reward and unlocks new build pads. The levels go from Tiny Workshop to Galactic Cookies.
- **Buildings**: the four farms (each adds an ingredient and a hopper), Staff Cabin, Pantry, Packing Shelf, Second and Third Dock, Production Lines 2 and 3. A build pad only appears once you reach its level.
- **Upgrades**:
  - **Farms**: speed, crate size and harvest yield. The plots visibly grow at levels 5, 10, 15 and 20, with more crops and animals and nicer fences.
  - **Factory**: belt speed, oven speed, batch size, hopper size and the Secret Recipe (cookie price).
  - **Trucks**: capacity and trip time, plus Pantry and Shelf size.
  - **You**: carry and speed.
  - **Staff**: cabin size, worker speed and worker carry.
- **Cookie Rush**: everything runs 2× for 45 s, with a cooldown.
- **Offline earnings**: your automation keeps earning (a share of your recent income, up to 3 h) while you're away.
- A guided first session (`ui/goals.gd`): a goal card plus a bouncing arrow in the world (or a pointer on a button). After the tutorial it keeps suggesting the next building or job.

## Project layout

```
boot.gd/.tscn       crest (emblem + title, laid out to fit any screen) + loading bar, then fades into the game
main.gd/.tscn       creates the World and the HUD; dev flags (--demo, --bot, --shot …)
autoload/game.gd    game state: money, level/xp, upgrades, buildings, workers, save/load, offline
autoload/sfx.gd     sound effects + music
autoload/quality.gd lowers resolution/shadows on phones that can't hold 50 fps
core/defs.gd        items, ingredients, worker roles, buildings, level titles (data tables)
core/bal.gd         every number: upgrade costs and effects, hiring, xp curve
world/
  world.gd          builds the island, spawns buildings/workers, answers worker queries, saves holder contents
  layout.gd         where everything is on the island
  mesh_kit.gd       procedural rounded low-poly meshes with baked vertex colours (+ cache)
  holder.gd         anything that holds items (stacks, crates, hoppers, trucks) + flying transfers
  zone.gd           floor pads: take / give / pay
  farm.gd, farm_worker.gd, crops.gd, animal.gd    farms, farmers, crops, chickens and cows
  line.gd           glass tube, hoppers, dough balls, oven, tray
  dock.gd           truck dock + truck trips and sales
  storage.gd        Pantry and Packing Shelf
  cabin.gd, build_pad.gd, island.gd, env.gd, camera_rig.gd, fx.gd, items.gd, ui3d.gd
  character.gd      the chibi rig: body, face, hats, tools, procedural walk/work/carry animations
  player.gd, worker.gd   you, and hired workers (role AI on the navmesh)
ui/                 title menu, HUD, joystick, panels (upgrades, staff, settings), goals, UI kit + skins
render/             toon, ground, glass, sea, belt and pad shaders
assets/             icons (generated), UI skins (tools/gen_ui.py), audio (synthesized), fonts (Lilita One, Manrope, OFL), logo, splash
tests/              headless logic tests + the autopilot bot
tools/              check, test, bot, screenshot scripts; icon and audio generators
dev/                visual test bench, screenshot helper, perf/triangle probes
```

**Adding content is mostly data:**
- **A new upgrade** is a row in `Bal.UPGRADES`. If it needs a building, add `"needs"`.
- **A new building** is a row in `Defs.BUILDINGS`, plus a spawn case in `World._spawn_building` and a pad position in `Lay.pad_pos`.
- **A new worker role** is a row in `Defs.ROLES` (look, from/to, unlock), plus its decision branch in `Worker._decide`.
- **A new ingredient** is a row in `Defs.ITEMS` + `INGREDIENTS`, a mesh in `Items`, a crop in `Crops` and an x position in `Lay.FARM_X`.

## Running, testing, building

```bash
godot --path .                    # play (desktop window 450x800, mouse = touch)
tools/check.sh                    # parse every script
tools/test.sh                     # headless logic tests (economy, holders, save, a real line baking)
tools/bot.sh 30 10                # the autopilot plays 30 game-minutes at 10x and prints milestones
tools/shot.sh res://main.tscn out.png -- --demo --cam=2,-3     # screenshot (Xvfb + lavapipe)
```

Dev flags (after `--`):
- `--fresh` starts a new game.
- `--title` shows the title menu in screenshots; `--nomenu` skips it when playing.
- `--demo` loads a mid-game factory.
- `--money=N` and `--level=N` set your money and level.
- `--build=cabin,pantry` adds buildings.
- `--panel=upgrades|workers|settings` opens a panel.
- `--tscale=2` changes the time scale.
- `--perf` and `--tris` print render stats.

From a headless run of the bot (fresh save), the pacing is:

| Milestone | Time |
|---|---|
| First cookie | ~8 s |
| First sale | ~17 s |
| Sugar Cane Field | ~40 s |
| Staff Cabin + first worker | ~1 min |
| Cocoa Orchard | ~2.5 min |
| Level 5 | ~7 min |
| All five farms | ~15 min |

Export presets:
- **Android**: arm64 APK.
- **iOS**: exports an Xcode project.
- **Web**: Compatibility renderer, PWA.

Older phones fall back to the OpenGL renderer and step quality down automatically.

## Performance notes
- **Few materials.** Most meshes are merged per prop and share one toon material through vertex colours.
- **Stacks are cheap.** Crates, trays, shelves and truck beds render one MultiMesh per item type. Grass tufts, daisies and pebbles are three MultiMeshes.
- **Lighter shadow pass.** Character limbs, hats and tools skip it.
- **Global detail.** `MeshKit.detail` sets the tessellation for everything round, and it drops on weak devices.
- **Result.** A busy late-game view is about 480 draw calls and about 290k triangles.

## Play in the browser

`docs/` holds a Web build (Godot Compatibility renderer, single-threaded, so it runs on any static host). To play it online, enable **GitHub Pages** for this repository: Settings → Pages → Branch → `/docs`. Rebuild it with `tools/web.sh docs`.
