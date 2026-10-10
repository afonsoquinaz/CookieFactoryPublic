# Cookie Empire

A premium 3D idle base-builder about cookies, made in **Godot 4.7** (GDScript, Mobile renderer, portrait).

You start with a cozy Cookie Hall, a Bakery, a Wheat Field, a Delivery Van and two Builder's Huts on four plots of endless meadow. Porters carry wheat along the roads to the Bakery, it bakes cookies, the van sells them. You decide what to build, where, and what to upgrade next. Every building gets a cobbled road to its entrance on its own. Upgrade the Cookie Hall to unlock farms, kitchens, more bakeries, shops, trains and airships. After about two weeks, crown your empire with the **Grand Cookie Palace**.

**Look:** a muted, grown-up production village (cream timber halls, brick and copper ovens, glass tubes, dry-stone farm walls, cobbled lanes) on a soft endless meadow with four biomes, staffed by cute toy porters, farmers, chefs and builders. The Cookie Hall changes look at levels 3, 6, 9 and 12 (cottage, townhouse, guild hall with a clock tower, grand hall with a dome, royal palace with gold domes) and gets a pennant on the roof for every level. Every other building has five looks as it levels up.

All 3D art is procedural low-poly (`world/mesh_kit.gd`, `world/town_art.gd`). The 2D icons, app icon and logo were generated for this game with the OpenAI Images API (`tools/gen_icons.py`). All sound and music is synthesized in code (`tools/gen_audio.py`). No third-party art or audio.

## How to play

| | |
|---|---|
| Look around | drag to slide the land, pinch (or mouse wheel) to zoom |
| A building | tap it: it lights up and its actions appear (Info, Upgrade, Bake, Staff, Move, Finish) |
| Build | **Build**, pick a card. The building appears on the nearest free spot with its road previewed. Slide the land to move it, **Rotate**, **Place** |
| Timers | the floating timer over anything being built. Under 30 seconds it says FREE: tap it |
| Obstacles | tap a bush, stump or boulder to clear it. Many hide gems |
| Land | tap a **For Sale** sign beyond the dashed line |

### The Cookie Hall
Its level is your progress (15 levels, from Kitchen Table to Legendary Empire). Each level unlocks:
- **new buildings**;
- **more copies** of the ones you have (the build menu shows "built 1 / 2" and when the next one comes);
- **higher levels** for everything else.

Upgrading the Hall also pays gems.

### Builders and timers
Building and upgrading take a builder and some time: seconds at first, up to about eight hours for the top levels. Builders keep working while you're away. You start with two Builder's Huts; up to three more cost gems. Finish a job early with gems; jobs with 30 seconds or less left finish for free.

### Roads
Every building has an entrance: the middle of its front edge, marked by an arrow while you place it. A cobbled road builds itself from there to the nearest road, going around buildings (never through them), turning as little as it can. Porters only walk on roads.
- You can't build on an entrance.
- You can't build somewhere that would cut another building off from the Hall: the game tells you which one.

### The Bakery
One building with the whole line inside: a Mixer, a glass tube, ingredient silos and an Oven.
- Porters fill the wheat bin and the silos.
- Dough balls roll down the tube, stop under each silo for a dose, and the oven puts a batch of cookies on the bench.
- **Bake** picks the recipe. **Auto** always bakes the best recipe your farms and kitchens can supply.
- Every 3 levels adds a silo (up to 7), so richer recipes need a bigger bakery. More bakeries unlock at Hall 4, 7, 10 and 13.

### Recipes and ingredients
- **17 cookies**: Shortbread, Sugar Cookie, Cocoa Crinkle, Milk Biscuit, Butter Ring, Chocolate Chip, Oat Crumble, Double Chocolate, Jam Thumbprint, Hazelnut Crunch, Honey Oat, Caramel Stroopwafel, Vanilla Sablé, Praline Dream, Cinnamon Swirl, Orange Florentine, Royal Empire.
- **12 farms**: wheat, sugar cane, cocoa, hens, dairy, oats, strawberries, hazelnuts, bees, vanilla orchids, cinnamon, oranges.
- **6 kitchens** turn ingredients into better ones: Butter Churn, Chocolatier, Jam Kettle, Caramel Pot, Praline Roaster, Candy Kitchen.
- **Packing**: the Box Packer packs 6 cookies into a box (+25%); the Gift Wrapper wraps a box into a gift (+60%).

### Selling
- **Delivery Van**: drives into its garage and sells the load.
- **Cookie Shop**: customers stroll in from the countryside and pay 30% more. Decor nearby brings more of them.
- **Order Board**: special orders pay big rewards plus **gems**.
- **Rail Depot**: huge loads, +15%.
- **Airship Mast**: gifts sell for double.
- **Trending cookies**: one recipe sells for more every 15 minutes.

### Staff
| Role | Look | Job |
|---|---|---|
| Porter | work jacket, beanie, hand truck | carries everything along the roads: harvests, ingredients, cookies, orders |
| Farmer | plaid shirt, overalls, straw hat | works one farm faster |
| Chef | chef whites, toque, whisk | works one bakery or kitchen faster |
| Builder | orange overalls, hard hat, hammer | builds and upgrades (one per Builder's Hut) |

Everyone you hire starts as a porter. On a farm, bakery or kitchen, **Staff > +** turns a porter into its farmer or chef. One porter always stays a porter. The Hall and Staff Cabins decide how many people you can house.

### Land, biomes, obstacles and decor
- **Land**: the world is an endless meadow in 16 m plots. Plots next to yours are for sale, and each costs more than the last.
- **Obstacles**: new land comes with brambles, stumps, pines, old oaks and boulders to clear. Many hide gems.
- **Biomes** give farms +40%:
  - **Meadow**: wheat, oats, eggs.
  - **Orchard Hills**: berries, hazelnuts, honey, oranges.
  - **Tropical Lowland**: sugar cane, cocoa, vanilla, cinnamon.
  - **Highland**: milk, oats, hazelnuts.
- **Decor** is instant (no builder) and has area effects:
  - wells, ponds and windmills: farms work faster;
  - fountains: staff walk faster;
  - flowers, lamps, trees, benches, banners, topiaries, gazebos: shops get more customers;
  - the Golden Cookie Statue: +5% on every sale.

### Progression
- **Research** (money): recipes sell for more, porter boots and baskets, the Builder's Toolkit (faster builds), hiring, roads for vans, marketing, night shift (offline hours), rush.
- **Perks** (gems): Golden Touch, Fertile Soil, Swift Staff, Big Batches, Busy Board, Second Wind.
- **Boost**: everything runs at 2x for a while.
- **Offline**: builders keep building, and your staff keep earning for a few hours.
- **The Grand Cookie Palace** (Hall 12): five stages (Foundations, Biscuit Walls, Cream Towers, Golden Domes, The Crown). Each stage needs Royal Empire cookies delivered, a big payment and many hours of building. Finishing The Crown wins the game.

## Project layout

```
boot.gd/.tscn        crest + loading bar, then fades into the game
main.gd/.tscn        World + HUD; dev flags (--demo, --showcase, --bot, --shot, --tour ...)
autoload/game.gd     state: money, gems, the Hall level, game clock, buildings, builder jobs, land, obstacles,
                     research, perks, staff, orders, save/load and time away
core/defs.gd         items, recipes, cookie looks, buildings (Hall gating, copies), Hall levels, roles, biomes,
                     obstacles, palace stages
core/bal.gd          every number: building effects per level, prices, build and upgrade times, gems to finish,
                     research, perks, land
world/
  world.gd           spawns buildings, construction sites and scaffolding, roads, obstacles, logistics broker,
                     staff and builders
  roads.gd           the self-building road network (cheapest paths, few turns) and porter routes
  grid.gd            2 m building grid, occupancy, obstacles, A* walking paths
  terrain.gd         endless ground (biomes, land, cobbled roads), streamed decor, For Sale signs
  camera_rig.gd      free pan / zoom camera with a little glide
  building.gd        base for everything placeable (footprint, entrance, ports, tiers, save)
  b_hall.gd  b_bakery.gd  b_hut.gd  b_site.gd  b_farm.gd  b_machine.gd  b_storage.gd
  b_vehicle.gd  b_shop.gd  b_board.gd  b_cabin.gd  b_decor.gd  b_palace.gd
  town_art.gd  farm_art.gd  line_art.gd  kitchen_art.gd  sales_art.gd  previews.gd   (the looks)
  holder.gd  items.gd  crops.gd  animal.gd  character.gd  worker.gd  builder.gd  farm_worker.gd  customer.gd
ui/                  title menu, HUD, action bar, job timers, placement, build / building / recipe / staff /
                     research / settings panels, goals (tutorial)
render/              toon, ground (biomes + land), glass, belt, pad shaders
assets/              icons (generated), UI skins, audio (synthesized), fonts (OFL)
tests/               headless logic tests + the autopilot bot
tools/               check, test, bot, screenshot scripts; icon, UI and audio generators
dev/                 art bench (every building x 5 tiers), screenshot helper, perf probes
```

**Adding content is mostly data:**
- **A building** is a row in `Defs.BUILDINGS` (with its Hall level, copies and build time), plus a `Building` subclass (or an existing one) and its art in the matching `*_art.gd`.
- **A recipe** is a row in `Defs.RECIPES` and `Defs.COOKIE_LOOK`, plus an icon `ck_<id>`.
- **An ingredient** is a row in `Defs.ITEMS`, a mesh in `Items`, and a farm or kitchen that makes it.
- **Research or a perk** is a row in `Bal.RESEARCH` / `Bal.PERKS`, read with `Game.research(id)` / `Game.perk(id)`.

## Running, testing, building

```bash
godot --path .                   # play (desktop window 450x800, mouse = touch)
tools/check.sh                   # parse every script
tools/test.sh                    # headless tests (data, balance, game state, builders, roads, a real world)
tools/bot.sh 60                  # the autopilot plays 60 game-minutes (fixed-step, faster than real time)
tools/shot.sh res://main.tscn out.png -- --demo
tools/shot.sh res://dev/bench.tscn out.png -- --kinds=hall,bakery --spacing=12   # five looks side by side
```

Dev flags (after `--`):
- `--fresh` starts a new game.
- `--demo` loads a mid-game empire.
- `--showcase` places every building, `--showcase --tier=4` at its top look.
- `--place=farm_cocoa` opens the placement mode.
- `--select=bakery` selects a building (`--info` also opens its card); `--recipes` opens the recipe picker.
- `--panel=build|staff|research|settings` opens a panel.
- `--tut=N` jumps to a tutorial step; `--tour=<dir>` plays the opening and saves a screenshot per step.
- `--title` shows the title menu in screenshots.
- `--perf` prints render stats.
- `--wdbg` prints worker and building states.

## Pacing

The game is tuned for about **two weeks**, base-builder style: money paces the first hours, then builder timers do. Timers keep running while you're away.

The first hour, measured by the autopilot bot (`tools/bot.sh`, a careful player who never spends gems on timers):

| Milestone | Play time |
|---|---|
| First sale | about 1 min |
| Cookie Hall 2 | about 1.5 min |
| Cookie Hall 3 | about 5 min |
| Cookie Hall 4 | about 30 min |
| Cookie Hall 5 | about 55 min |
| Cookie Hall 6 | about 80 min |

After that the Hall's build time is the gate:

| Hall level | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|---|
| Build time | 1 h | 2 h | 4 h | 6 h | 8 h | 12 h | 16 h | 20 h | 24 h |

The Grand Cookie Palace (Hall 12) then takes 8 h to start and 12 h, 24 h, 36 h and 48 h for its stages, plus money and Royal Empire cookie deliveries.

That makes about 7 days of building at the very least. With a few check-ins a day, nights, and the money and cookies each stage needs, finishing takes roughly 10 to 14 days. Gems can shave some of it off.

## Export

Export presets:
- **Android**: arm64 APK.
- **iOS**: exports an Xcode project.
- **Web**: Compatibility renderer, PWA.

Older phones fall back to the OpenGL renderer and step quality down automatically.

## Performance notes
- **Few materials.** Most meshes are merged per prop and share one toon material through vertex colours.
- **Cheap stacks and decor.** Crates, trays and racks draw one MultiMesh per item type. The streamed decor (trees, shrubs, rocks, flowers, grass) is one MultiMesh per kind around the camera.
- **One ground plane.** It follows the camera; a shader colours the biomes and the land you own and draws the cobbled roads from a one-texel-per-cell texture.
- **Cheap pathfinding.** Porters walk an `AStarGrid2D` over road cells. Roads are rebuilt only when something is built, moved, sold or cleared.
