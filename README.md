# Cookie Empire

A premium 3D idle factory game made in **Godot 4.7** (GDScript, Mobile renderer, portrait).

Start at the kitchen table: one wheat field, a short production line (Dough Mixer, two glass tubes, an Oven) and a delivery van on four plots of endless meadow. Carry wheat to the mixer, cookies to the van, and your first money comes in seconds. Then build anything, anywhere: farms, kitchens, more lines, shops, a rail depot, an airship mast, decorations. Buy more land as you grow, unlock 17 cookie recipes, and after about two weeks of play crown your empire with the **Grand Cookie Palace**.

**Look:** muted, grown-up production site (steel silos, glass tubes, brick and tiled ovens, dry-stone farm walls, copper kitchens) on a soft endless meadow with four biomes, staffed by cute toy farmers and factory workers. Every building has **five looks** as it levels up: a wooden fence becomes a brick wall with a windmill and a brass gate arch; a brick dome oven becomes a tiled bakery oven, a stainless deck oven, then a royal copper tunnel oven with a crown. UI: chunky wooden and coloured game buttons, ribbon-titled panels, Lilita One.

All 3D art is procedural low-poly (`world/mesh_kit.gd`). The 2D icons, app icon and logo were generated for this game with the OpenAI Images API (`tools/gen_icons.py`), and all sound and music is synthesized in code (`tools/gen_audio.py`). No third-party art or audio.

## How to play

| | |
|---|---|
| Move | drag anywhere (floating joystick); WASD / arrows on desktop |
| Pick up / drop off | stand on a pad: items fly onto or off your stack |
| Build | **Build**, pick a card, slide the land under the ghost, **Rotate**, **Place** |
| A building | tap it: what it's doing, staff, upgrade (and its next look), Move, Sell |
| Land | tap a **For Sale** sign beyond the dashed line |
| Drop | the red button whenever you carry something: empties your hands |
| Zoom | pinch, or the mouse wheel |

### Production lines must connect
A line is a straight row, end to end, all facing the same way: **Dough Mixer -> glass tubes / Hoppers -> Oven**.
- The Mixer takes wheat and pushes dough balls into the tube.
- Each **Hopper** holds one ingredient and doses every ball that needs it. A hopper can replace a tube.
- The **Oven** bakes the balls into cookies on its output bench.
- A line bakes the **most valuable recipe** whose ingredients all have a hopper on it. The recipe book (Research > Recipes) shows them all.
- Unconnected ends show a red-striped cap. A lone oven says *Connect to a Mixer*.

### Chutes: placement matters
Buildings that **touch** hand items over by a little roller chute, no worker needed:
- a wheat field next to a mixer feeds it;
- a dairy beside a butter churn keeps it busy;
- an oven beside a van, shop or packer loads it.

Chutes get faster with the *Faster Chutes* research.

### Recipes and ingredients
- **17 cookies**: Shortbread, Sugar Cookie, Cocoa Crinkle, Milk Biscuit, Butter Ring, Chocolate Chip, Oat Crumble, Double Chocolate, Jam Thumbprint, Hazelnut Crunch, Honey Oat, Caramel Stroopwafel, Vanilla Sablé, Praline Dream, Cinnamon Swirl, Orange Florentine, Royal Empire.
- **12 farms**: wheat, sugar cane, cocoa, hens, dairy, oats, strawberries, hazelnuts, bees, vanilla orchids, cinnamon, oranges.
- **6 kitchens** turn ingredients into better ones: Butter Churn, Chocolatier, Jam Kettle, Caramel Pot, Praline Roaster, Candy Kitchen.
- **Packing**: the Box Packer packs 6 cookies into a box (+25%), and the Gift Wrapper wraps a box into a gift (+60%).

### Selling
- **Delivery Van**: drives into its garage and sells the load.
- **Cookie Shop**: customers stroll in from the countryside and pay 30% more. Decor nearby brings more of them.
- **Order Board**: special orders pay big rewards plus **gems**.
- **Rail Depot**: huge loads, +15%.
- **Airship Mast**: gifts sell for double.
- **Trending cookies**: one recipe sells for more every 15 minutes.

### Staff
Build a **Staff Cabin** to hire. Each role has its own outfit, ring and badge:

| Role | Look | Job |
|---|---|---|
| Farmer | plaid shirt, overalls, straw hat | works one farm faster (assign on the farm) |
| Chef | chef whites, toque, whisk | runs one oven or kitchen faster (assign on it) |
| Gatherer | field vest, cap, basket | farm crates -> kitchens, pantry, hoppers |
| Feeder | hi-vis, hard hat, scoop | pantry, kitchens -> mixers, hoppers, kitchens |
| Collector | mauve pastry apron, tray | ovens -> packers, racks, sales |
| Loader | work jacket, beanie, hand truck | racks, packers -> vans, shops, trains, orders |

Haulers ask a logistics broker for the most useful job and walk A* paths around your buildings.

### Land, biomes and decor
The world is an endless meadow in 16 m chunks. Chunks next to your land are for sale, and each costs more than the last. Biomes give farms +40%:
- **Meadow**: wheat, oats, eggs.
- **Orchard Hills**: berries, hazelnuts, honey, oranges.
- **Tropical Lowland**: sugar cane, cocoa, vanilla, cinnamon.
- **Highland**: milk, oats, hazelnuts.

Decor has area effects:
- **Wells**: farms nearby work faster.
- **Fountains**: workers nearby walk faster.
- **Flower beds, lamps, trees, benches**: shops nearby get more customers. Flower beds also make Bee Meadows busier.
- **Golden Cookie Statue**: +5% on every sale.

### Progression
- **Empire level** (XP = money earned) unlocks buildings: 60 levels from Kitchen Table to Legendary Empire.
- **Building levels** (up to 60): speed, capacity, yield, and a new look at five milestones.
- **Research** (money): carry, speed, recipes (+10% per level), worker boots and baskets, hiring, roads, marketing, night shift (offline hours), rush.
- **Perks** (gems from orders): Golden Touch, Fertile Soil, Swift Staff, Big Batches, Busy Board, Second Wind.
- **Cookie Rush**: everything runs at 2x for a while.
- **Offline earnings** from your automation.
- **The Grand Cookie Palace** (level 35): five stages (Foundations, Biscuit Walls, Cream Towers, Golden Domes, The Crown). Each stage needs Royal Empire cookies delivered and a big payment. Finishing it wins the game.

## Project layout

```
boot.gd/.tscn        crest + loading bar, then fades into the game
main.gd/.tscn        World + HUD; dev flags (--demo, --showcase, --bot, --shot ...)
autoload/game.gd     state: money, gems, level, placed buildings, land, research, perks, workers, orders, save/load
core/defs.gd         items, recipes, cookie looks, buildings, roles, biomes, palace stages
core/bal.gd          every number: building effects per level, prices, research, perks, land, xp
world/
  world.gd           spawns buildings, connects lines, logistics broker, workers, save state
  grid.gd            2 m building grid, occupancy, A* walking paths
  terrain.gd         endless ground (biomes, land overlay), streamed decor, For Sale signs
  building.gd        base for everything placeable (footprint, ports, zones, tiers, save)
  b_farm.gd  b_mixer.gd  b_tube.gd  b_hopper.gd  b_oven.gd  b_line.gd
  b_machine.gd  b_storage.gd  b_vehicle.gd  b_shop.gd  b_board.gd  b_cabin.gd  b_decor.gd  b_palace.gd
  line.gd            a connected line at work: recipe, dough balls, dosing, baking
  farm_art.gd  line_art.gd  kitchen_art.gd  sales_art.gd  previews.gd   (five looks per building)
  holder.gd  zone.gd  items.gd  crops.gd  animal.gd  character.gd  player.gd  worker.gd  farm_worker.gd  customer.gd
ui/                  title menu, HUD, placement mode, build / building / staff / research / settings panels, goals
render/              toon, ground (biomes + land), glass, belt, pad shaders
assets/              icons (generated), UI skins, audio (synthesized), fonts (OFL)
tests/               headless logic tests + the autopilot bot
tools/               check, test, bot, screenshot scripts; icon, UI and audio generators
dev/                 art bench (every building x 5 tiers), screenshot helper, perf probes
```

**Adding content is mostly data:**
- **A building** is a row in `Defs.BUILDINGS`, plus a `Building` subclass (or an existing one) and its art in the matching `*_art.gd`.
- **A recipe** is a row in `Defs.RECIPES` and `Defs.COOKIE_LOOK`, plus an icon `ck_<id>`.
- **An ingredient** is a row in `Defs.ITEMS`, a mesh in `Items`, and a farm or kitchen that makes it.
- **Research or a perk** is a row in `Bal.RESEARCH` / `Bal.PERKS`, read with `Game.research(id)` / `Game.perk(id)`.

## Running, testing, building

```bash
godot --path .                   # play (desktop window 450x800, mouse = touch)
tools/check.sh                   # parse every script
tools/test.sh                    # headless tests (data, balance, game state, grid, a real world baking)
tools/bot.sh 60                  # the autopilot plays 60 game-minutes (fixed-step, faster than real time)
tools/shot.sh res://main.tscn out.png -- --demo
tools/shot.sh res://dev/bench.tscn out.png -- --kinds=oven,mixer --spacing=7   # five tiers side by side
```

Dev flags (after `--`):
- `--fresh` starts a new game.
- `--demo` loads a mid-game empire.
- `--showcase` places every building, `--showcase --tier=4` at its top look.
- `--place=hopper:sugar` opens the placement mode.
- `--select=oven` opens a building panel.
- `--panel=build|staff|research|settings` opens a panel.
- `--title` shows the title menu in screenshots.
- `--perf` prints render stats.
- `--wdbg` prints worker and building states.

PACING_TABLE

Export presets:
- **Android**: arm64 APK.
- **iOS**: exports an Xcode project.
- **Web**: Compatibility renderer, PWA.

Older phones fall back to the OpenGL renderer and step quality down automatically.

## Performance notes
- **Few materials.** Most meshes are merged per prop and share one toon material through vertex colours.
- **Cheap stacks and decor.** Crates, trays and racks draw one MultiMesh per item type. The streamed decor (trees, shrubs, rocks, flowers, grass) is one MultiMesh per kind around the camera.
- **One ground plane.** It follows the camera; a shader colours the biomes and the land you own.
- **Grid pathfinding.** Workers walk an `AStarGrid2D` over owned land, rebuilt only when land is bought.
