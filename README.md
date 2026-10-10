# Cookie Empire

A premium 3D idle base-builder about cookies, made in **Godot 4.7** (GDScript, Mobile renderer, portrait).

You start on four plots of endless meadow along the **High Street**: a Wheat Field, a Bakery and a Pantry on one side, a Staff Cabin, a Delivery Van depot and two Builder's Huts on the other. Porters carry wheat along the roads to the Bakery, it bakes cookies, and the van drives off down the High Street to sell them. Everything can be built from the start: farms, kitchens, more bakeries, shops, trains and airships. Only money and builders stand in the way, so where to invest is up to you. Every building gets a cobbled road to the High Street on its own. After about two weeks, crown your empire with the **Grand Cookie Palace**.

**Look:** a muted, grown-up production village (cream timber halls, brick and copper ovens, glass tubes, dry-stone farm walls, cobbled lanes) on a soft endless meadow with four biomes, staffed by cute toy porters, farmers, chefs and builders. Every building has five looks as it levels up, and in between it gains crates, planters, lamps, barrels, flags and benches, one for each of its first upgrades and then every so often up to its top level. The van depot goes from a plank shed to a brick depot, the Cookie Express, a steel logistics hub and a royal post office.

All 3D art is procedural low-poly (`world/mesh_kit.gd`, `world/town_art.gd`). The 2D icons, app icon and logo were generated for this game with the OpenAI Images API (`tools/gen_icons.py`). All sound and music is synthesized in code (`tools/gen_audio.py`). No third-party art or audio.

## How to play

| | |
|---|---|
| Look around | drag to slide the land, pinch (or mouse wheel) to zoom |
| A building | tap it: it lights up and its actions appear (Info, Upgrade, Bake, Staff, Move, Finish) |
| Build | **Build**, pick a card. The building appears on the nearest free spot, facing the High Street, with its road previewed. Slide the land to move it, **Rotate**, **Place** |
| Timers | the floating timer over anything being built. Under 30 seconds it says FREE: tap it |
| Obstacles | tap a bush, stump or boulder to clear it. Many hide gems |
| Land | tap a **For Sale** sign beyond the dashed line |

### Your empire
Nothing is locked. Every building is in the build menu from the start, and only its price, a free builder and room to build decide whether you can have it. A kitchen card says when nothing makes what it needs yet. Builder's Huts (5), the Order Board and the Palace are the only ones with a limit.

Your **Empire level** (15 levels, from Kitchen Table to Legendary Empire) grows with everything you earn. It shows top right with a progress bar, and every level pays gems.

The tutorial is three hints: upgrade the Bakery, finish a short job free, open Build. After that the hint card only speaks up when something is wrong, like a building without a road or a Bakery missing an ingredient.

### Builders and timers
Building and upgrading take a builder and some time: seconds at first, up to about eight hours for the top levels. Builders keep working while you're away. You start with two Builder's Huts; up to three more cost gems. Finish a job early with gems; jobs with 30 seconds or less left finish for free.

### Roads
The **High Street** runs straight through your land from horizon to horizon: two lanes of setts with kerbs and a dashed centre line. Every building has an entrance: the middle of its front edge, marked by an arrow while you place it. A cobbled road builds itself from there to the nearest road and on to the High Street, going around buildings (never through them), turning as little as it can. Porters only walk on roads.
- You can't build on an entrance or on the High Street.
- You can't build somewhere that would cut another building off: the game tells you which one.

### The Bakery
One building with the whole line inside: a Mixer, a glass tube, ingredient silos and an Oven.
- Porters fill the wheat bin and the silos.
- Dough balls roll down the tube, stop under each silo for a dose, and the oven puts a batch of cookies on the bench.
- **Bake** picks the recipe. **Auto** always bakes the best recipe your farms and kitchens can supply.
- Every 3 levels adds a silo (up to 7), so richer recipes need a bigger bakery. Each extra bakery costs a lot more than the last.

### Recipes and ingredients
- **17 cookies**: Shortbread, Sugar Cookie, Cocoa Crinkle, Milk Biscuit, Butter Ring, Chocolate Chip, Oat Crumble, Double Chocolate, Jam Thumbprint, Hazelnut Crunch, Honey Oat, Caramel Stroopwafel, Vanilla Sablé, Praline Dream, Cinnamon Swirl, Orange Florentine, Royal Empire.
- **12 farms**: wheat, sugar cane, cocoa, hens, dairy, oats, strawberries, hazelnuts, bees, vanilla orchids, cinnamon, oranges.
- **6 kitchens** turn ingredients into better ones: Butter Churn, Chocolatier, Jam Kettle, Caramel Pot, Praline Roaster, Candy Kitchen.
- **Packing**: the Box Packer packs 6 cookies into a box (+25%); the Gift Wrapper wraps a box into a gift (+60%).

### Selling
- **Delivery Van**: drives out of its depot along its road onto the High Street and off to town in the eastbound lane, sells the load, and comes back in the westbound lane. In the depot a turntable turns it around, ready for the next load.
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

Everyone you hire starts as a porter. On a farm, bakery or kitchen, **Staff > +** turns a porter into its farmer or chef. One porter always stays a porter. Staff Cabins decide how many people you can house; you start with one.

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
- **The Grand Cookie Palace** ($200M): five stages (Foundations, Biscuit Walls, Cream Towers, Golden Domes, The Crown). Each stage needs Royal Empire cookies delivered, a big payment and many hours of building. Finishing The Crown wins the game.

## Project layout

```
boot.gd/.tscn        crest + loading bar; warms up every mesh, shader and panel (render/warmup.gd), then fades in
main.gd/.tscn        World + HUD; dev flags (--demo, --showcase, --bot, --shot, --tour ...)
autoload/game.gd     state: money, gems, the Empire level, game clock, buildings, builder jobs, land, obstacles,
                     research, perks, staff, orders, save/load and time away
core/defs.gd         items, recipes, cookie looks, buildings (prices, limits), Empire levels, roles, biomes,
                     obstacles, palace stages
core/bal.gd          every number: building effects per level, prices, build and upgrade times, gems to finish,
                     research, perks, land
world/
  world.gd           spawns buildings, construction sites and scaffolding, roads, obstacles, logistics broker,
                     staff and builders
  roads.gd           the High Street and the self-building side roads (cheapest paths, few turns), porter routes
  grid.gd            2 m building grid, occupancy, obstacles, A* walking paths
  terrain.gd         endless ground (biomes, land, cobbled roads), streamed decor, For Sale signs
  camera_rig.gd      free pan / zoom camera with a little glide
  building.gd        base for everything placeable (footprint, entrance, ports, tiers, save)
  b_bakery.gd  b_hut.gd  b_site.gd  b_farm.gd  b_machine.gd  b_storage.gd
  b_vehicle.gd  b_shop.gd  b_board.gd  b_cabin.gd  b_decor.gd  b_palace.gd
  town_art.gd  farm_art.gd  line_art.gd  kitchen_art.gd  sales_art.gd  previews.gd   (the looks)
  level_art.gd       the props buildings gain as they level up
  holder.gd  items.gd  crops.gd  animal.gd  character.gd  worker.gd  builder.gd  farm_worker.gd  customer.gd
ui/                  title menu, HUD, action bar, job timers, placement, build / building / recipe / staff /
                     research / settings panels, goals (tutorial)
render/              toon, ground (biomes, land, roads, the High Street), glass, belt shaders; warmup.gd
assets/              icons (generated), UI skins, audio (synthesized), fonts (OFL)
tests/               headless logic tests + the autopilot bot
tools/               check, test, bot, screenshot scripts; icon, UI and audio generators
dev/                 art bench (every building x 5 tiers), screenshot helper, perf probes
```

**Adding content is mostly data:**
- **A building** is a row in `Defs.BUILDINGS` (price, growth, build time, optional limit), plus a `Building` subclass (or an existing one) and its art in the matching `*_art.gd`.
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
tools/shot.sh res://dev/bench.tscn out.png -- --kinds=bakery,dock --spacing=12   # five looks side by side
tools/shot.sh res://dev/bench.tscn out.png -- --kinds=dock --levels=1,3,5,14,40   # looks + level props
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
- `--hitch` runs every common action and prints its cost and the slowest frame after it; `--boottime` (on the boot scene) times the loading screen; `--film=<dir> --van` saves a screenshot sequence of the van's trip.

## Pacing

The game is tuned for about **two weeks**, base-builder style. Nothing is locked, so money paces the first hours; after that builder timers do. Upgrades take seconds for the first levels (finish them free), minutes in the middle and up to eight hours at the top, and you have at most five builders. Timers keep running while you're away.

The first two hours, measured by the autopilot bot (`tools/bot.sh`, a careful player who never spends gems on timers or huts):

| Milestone | Play time |
|---|---|
| First sale | about 30 s |
| Empire level 2 | about 1.5 min |
| Empire level 3 | about 5 min |
| Empire level 4 | about 13 min |
| Empire level 5 | about 23 min |
| Chocolate Chip cookies | about 55 min |
| Empire level 8 | about 70 min |

The Grand Cookie Palace ($200M) takes 8 h to start and 12 h, 24 h, 36 h and 48 h for its stages, plus money and Royal Empire cookie deliveries. Royal Empire cookies need seven ingredients from five farms and three kitchens, and a Bakery with seven silos.

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
- **Cheap pathfinding.** Porters walk an `AStarGrid2D` over road cells. Roads are rebuilt only when something is built, moved, sold or cleared (a few ms: side roads only have to reach the High Street).
- **No first-time freezes.** WebGL compiles a shader the first time it's drawn, every session, and GDScript builds meshes on first use. The loading screen does all of that up front (`render/warmup.gd`): every building at every look, construction sites, ghosts, items, people, decor, every material, every panel and effect, in small steps so the bar keeps moving. Long panels then add their rows a few per frame while they slide in.
