# Token Empire

A 3D idle base-builder about the AI supply chain, made in **Godot 4.7** (GDScript, Mobile renderer, portrait). It's a complete remake of Cookie Empire: tokens instead of cookies.

You start in a garage. A gaming PC on a plywood desk runs **Pico 1B**, a tiny local model with 15 ms latency, powered by a small Solar Farm. Tokens aren't things you make and carry: **customers call your API**, your servers answer as fast as their GPUs allow, and every token answered is paid on the spot. The more servers you run, and the bigger they are, the more you can sell. From there you grow the whole AI supply chain and infrastructure: crawl the web for data, chill coolant, pull silicon, mine copper and rare earths, and pay people for code, labels, feedback, research and expert data. Your labs turn those into **GPUs and HBM** (couriers slot them into your servers) and **training data** (your Training Cluster turns it into new models). You serve 17 models, from Pico 1B up to **Frontier 1T**, sell through API Gateways, a Chat Café, enterprise contracts, Edge PoPs and Agent Hubs, and finally **launch servers into orbit**. Nothing is locked; only money and builders decide where you invest. After about two weeks, crown your lab with the **AGI Megacluster**. The full design is in [DESIGN.md](DESIGN.md).

**Goal:** serve more tokens. Your **Lab level** (15 levels, from Garage Lab to AGI Pioneer) grows with every token you serve, and with it the whole market for AI. The HUD shows tokens served, tokens per second and how loaded your servers are; tap it for the Market.

**Look:** a clean, toy-like tech campus on an endless landscape with four regions: Tech Valley, Sun Desert, Cold North and Mining Hills. White panels, graphite racks, glass request buses, teal and cyan glow and soft LED light, staffed by cute toy couriers, technicians, engineers and builders. Every building has five looks as it levels up: the server goes from a garage rig to a server closet, a white server room, a steel data hall and a graphite hyperscale hall. In between, buildings gain props: crates, planters, lamps, server cabinets, cable reels and glowing token plinths.

All 3D art is procedural low-poly (`world/mesh_kit.gd` and the `*_art.gd` files). The icons, app icon and logo are rendered from the game's own models (`dev/icons.gd`, `tools/icon_post.py`). All sound and music is synthesized in code (`tools/gen_audio.py`). No third-party art or audio.

## How to play

| | |
|---|---|
| Look around | drag to slide the land, pinch (or mouse wheel) to zoom |
| A building | tap it: it lights up and its actions appear (Info, Upgrade, Model, Tune, Train, Market, Staff, Move, Finish) |
| A server | tap it again and again: every tap tunes it (up to +50%, fading slowly), like its engineers do |
| Market | tap your tokens (top of the screen): demand, capacity, bandwidth, reputation, and your price for each model |
| Sparks | tap your sparks for the shop |
| Build | **Build**, pick a card. The building appears on the nearest free spot, facing the High Street, with its road previewed. Slide the land to move it, **Rotate**, **Place** |
| Timers | the floating timer over anything being built. Under 30 seconds it says FREE: tap it |
| Obstacles | tap a bush, e-waste pile, old container or boulder to clear it. Many hide sparks |
| Land | tap a **For Sale** sign beyond the dashed line |

### The supply chain

**12 sources** (3x3 lots of work stations, each with a technician) make raw resources:

| Source | Makes | Best region |
|---|---|---|
| Solar Farm | Power Cells: every request burns power | Sun Desert |
| Web Crawler | Web Data (crawler bots scurry over the lot) | Tech Valley |
| Cooling Tower | Coolant | Cold North |
| Silicon Works | Silicon (crystal pullers) | Sun Desert |
| Copper Mine | Copper | Mining Hills |
| Code Commons | Code (dev desks) | Tech Valley |
| Labeling Studio | Labels | Tech Valley |
| Feedback Lounge | Feedback (rating kiosks) | Tech Valley |
| Rare Earth Mine | Rare Earths (glowing crystals) | Mining Hills |
| Research Campus | Research (whiteboards) | Cold North |
| Fiber Hub | Bandwidth (fibre spools) | Cold North |
| Expert Network | Expert Data | Mining Hills |

**6 labs** (2x2) refine them:

| Lab | In | Out |
|---|---|---|
| Chip Fab | 2 silicon + 1 copper | 1 GPU |
| Data Refinery | 3 web data | 2 datasets |
| Fine-Tune Lab | 2 labels + 1 dataset | 1 fine-tune |
| HBM Works | 2 silicon + 1 rare earths | 1 HBM memory |
| RLHF Gym | 2 feedback + 1 fine-tune | 1 reward model |
| Synth Lab | 1 expert data + 2 web data | 1 synthetic data |

### The Inference Server
One building holds a whole serving stack: a Request Router, a glass request bus, GPU trays over it, an HBM shelf and a GPU Core.
- **Requests come in, tokens go out.** Customers' API calls arrive as glowing packets at the router, run down the bus under the GPU trays into the core, and a stream of tokens leaves through the vent. The busier the server, the more packets.
- **Accelerators.** It comes with a garage graphics card. Couriers bring **GPUs** from the Chip Fab and slot them into the trays: one slot to start, one more every two levels, up to 20. **HBM stacks** (HBM Works) go on the shelf: one slot every three levels, up to 12.
- **Memory decides what it can run.** The card has 12 GB, each GPU adds 80 GB and each HBM stack 40 GB. A model needs its VRAM: Pico 1B 2 GB, Chat 7B 16 GB, a 70B model 150 GB, Frontier 1T 1,800 GB (20 GPUs and 5 HBM stacks).
- **Power and cooling.** Every accelerator burns power cells while it serves: no power, no tokens. Real GPUs run hot and throttle to 60% without coolant.
- **Wear.** Under load a GPU fails now and then (about once every three hours): its board goes dark until a courier brings a new one.
- **Tuning.** Engineers walk the trays tapping them, and so can you: up to +50% throughput, fading slowly.
- **Model** picks what it serves (it shows each model's VRAM, what this server would serve and what customers want). **Auto** picks the model that earns most with the demand still unserved.

### Models
17 models, each with a size, VRAM, speed per GPU, latency and price: Pico 1B, Mini 3B, Chat 7B (open weights: download them), and Chat 13B, Wiki 13B, Code 13B, Tool 30B, Vision 70B, Assist 70B, Code 70B, Aligned 70B, Long 120B, Reason 200B, Sage 400B, Omni 400B, Expert MoE and Frontier 1T (train them yourself). Bigger models answer fewer tokens per GPU but sell for more, so each one earns more per GPU than the last. Tool 30B and up can run agents.

**The Training Cluster** trains them: couriers bring the data a model needs (datasets, code, labels, fine-tunes, research, reward models, synthetic data, expert data...) and its GPUs do the compute, from 10 minutes of GPU time for Chat 13B to 200,000 GPU-seconds for Frontier 1T (slot more GPUs into it). Models go stale as rivals ship better ones (quality drops toward 70%); a **refresh** run brings them back up to 150%. Auto trains the next model whose data you make.

### Customers: the market
Every model has its own demand (in tokens per second): the more AI catches on (your Lab level), the more customers, multiplied by your channels, your reputation, the model's quality, its latency and your price. Each model serves what its servers can answer; what leaves the campus has to fit through your gateways' bandwidth; the rest of the demand is lost.
- **API Gateway**: brings developers' calls (+60% customers, more each level) and carries the traffic. Couriers rack fiber spools (Fiber Hub) on it for more bandwidth.
- **Chat Café**: visitors sit down and chat live with your fastest model, phone in hand, and pay 30% more (snappy models up to 25% on top). They leave if the answers stop coming. Decor nearby brings more of them.
- **Enterprise Desk**: contracts ("serve 4.5M tokens of Code 13B") add their own demand at 1.2x and pay a big bonus plus **sparks** when served in full.
- **Edge PoP**: every model answers 25 ms sooner, and more customers find you.
- **Agent Hub**: AI agents run long jobs on tool-capable models and pay double; its robots trundle around the plaza.
- **Price**: in the Market, set each model's price from 0.5x to 2x. Customers are price-sensitive (demand x price^-1.6), so dearer earns more per token but loses customers.
- **Latency** rises steeply as servers fill up, and slow answers lose customers. **Reputation** falls when you're swamped and climbs back when you keep up.
- **Trending models**: one model is trending: twice the customers, and they pay more. It changes every 15 minutes.

### Space
- **Launch Complex**: couriers bring an orbital module's parts to its three assembly bays (24 GPUs, 8 HBM stacks, 60 power cells). Then the rocket rolls out, counts down and launches. The pad needs a while to turn around.
- **In orbit** each module adds 48 accelerators serving the best model that fits (2,240 GB): free solar power, radiative cooling, no wear, but 80 ms further away. The station floats in the sky over the pad, one module more per launch.
- **Ground Stations** downlink it: orbit serves only as much as they can carry (their beams pulse with the traffic).

### Staff
| Role | Look | Job |
|---|---|---|
| Courier | blue jacket and cap, hand truck | carries everything along the roads: resources, GPUs, HBM, fiber, training data, rocket parts |
| Technician | hi-vis vest, safety helmet, wrench | works one source faster |
| Engineer | hoodie, headphones, laptop | on a server: walks its GPU trays tapping each one (tuning it); on a lab: works it faster. Engineers without a post patrol the server that needs it most |
| Builder | orange overalls, hard hat, hammer | builds and upgrades (one per Builder's Hut) |

Everyone you hire starts as a courier. On a source, server or lab, **Staff > +** turns a courier into its technician or engineer. One courier always stays a courier. Staff Housing decides how many people you can house.

### Builders and timers
Building and upgrading take a builder and some time: seconds at first, up to about eight hours for the top levels. Builders keep working while you're away. You start with two Builder's Huts; up to three more cost sparks. Finish a job early with sparks; jobs with 30 seconds or less left finish for free.

### Roads
The **High Street** runs straight through your land. Every building has an entrance in the middle of its front edge. A road builds itself from there to the nearest road and on to the High Street, going around buildings and turning as little as it can. Couriers only walk on roads. You can't build on an entrance or on the High Street, or somewhere that would cut another building off.

### Land, regions, obstacles and decor
- **Land**: the world is an endless landscape in 16 m plots. Plots next to yours are for sale, and each costs more than the last.
- **Regions** make some sources work 40% faster: cheap sun in the Sun Desert, free cooling and research in the Cold North, talent in Tech Valley, ore and experts in the Mining Hills.
- **Decor** is instant and has area effects:
  - substations, battery banks and wind turbines: sources work faster;
  - the coffee cart: staff move faster;
  - datacenter gear (Network Cabinet, Rack Row, Chiller Unit, Backup Generator, Transformer Yard): servers and labs nearby work 5–25% faster (up to x2 in total);
  - planters, smart lamps, trees, benches, bike racks, flags, robot statues and the food truck: the Chat Café gets more visitors (and planters help Rare Earth Mines);
  - the Golden GPU: +5% on every sale.

### Every upgrade shows
Each building gains gear level by level: a new server cabinet, a rooftop AC, a dashboard on the wall, GPU crates by the gate. Later upgrades make each piece bigger, then add a second one, then make it glow. The first twenty or so upgrades of every building each add something; after that they come every level or two, up to the top level. Buildings also get a whole new look at their tier levels, and sources gain a work station every other level (three to start, up to six, or eight for the solar farm). The upgrade card says what the next level adds ("Next level: New Rooftop AC"), and the new piece pops in with its name.

### Eras: from garage to datacenter
The town changes as the Lab levels up. A card announces each new era, and the new look eases in.

| Lab level | Era | What changes |
|---|---|---|
| 1 | Garage | Grass, cobbled side roads, a gaming PC. |
| 3 | Startup Campus | Concrete aprons under your buildings, paver paths, an asphalt High Street with smart lamps. |
| 6 | Data Park | Your land is paved in slabs, side roads turn to asphalt, power poles and cables run along the street. |
| 9 | Hyperscale | Raised-floor tiles, LED lane lines and kerbs, glowing lot edges; datacenter halls, cooling towers, chillers and pylons spread over the wild land on the horizon. |
| 12 | Megacluster | A circuit-board floor with light pulsing along its traces, data streaks down the High Street, an even denser datacenter city around you. |

The ground shader blends the looks with an `era` uniform. Building lots are written into the road texture, so paving follows your buildings. Street props and the far-off sprawl are streamed MultiMeshes, like the trees.

### Progression
- **Research** (money): Scaling Laws (every token sells for more), KV Cache (servers serve more), Developer Relations (more customers), Speculative Decoding (lower latency), Profiling Tools (tuning counts more), E-Scooters and Cargo Carts for couriers, Prefab Modules (faster builds), Employer Brand (hiring), Hype Machine (trending models), Autoscaling (offline hours), Overclocking, Zoning Permits.
- **Perks** (sparks): Brand Moat, Supply Deals, Team Spirit, Continuous Batching, Sales Team, Liquid Cooling.
- **Overclock**: everything runs at 2x for a while.
- **Offline**: builders keep building, and your servers keep earning for a few hours.
- **The AGI Megacluster** ($200M): five stages (Groundbreaking, Power Plant, Cooling Halls, GPU Halls, The Core). Each stage needs Frontier 1T tokens served to customers since the last stage (anywhere: API, café, contracts, agents, orbit), a big payment and many hours of building. Finishing The Core wins the game.

### Every day: streaks, quests, leagues, seasons
A layer around the empire that gives you a reason to come back, borrowed from games that are good at it: a Duolingo-style streak, Pokémon GO's daily research and community events, and Clash Royale's crates and season pass. The **Today** button (right edge) opens Lab HQ, and its red dot counts what's waiting.

- **Daily goal and streak.** Serve about ten minutes' worth of tokens a day to keep the flame lit (the chip under your money). Miss a day and a **Streak Freeze** covers it (hold up to two; 10 sparks each, or free at 7 and 30 days). Lose a streak anyway and you can **repair** it for sparks the same day or the next. Milestones at 3, 7, 14, 30, 50, 100, 150, 200 and 365 days bring sparks, crates and, at 30, the **Eternal Flame**. The chip pulses in the evening if today's goal is still open.
- **Daily quests.** Three a day (easy, medium, hard), picked from what makes sense for your empire: serve tokens, serve through the API, install GPUs, tune servers, upgrade, welcome café visitors, finish contracts, sell the trending model, train a model, launch a module, serve agents, research, hire... One free swap a day. Finishing all three gives a Supply Crate and a **Breakthrough** stamp; seven stamps (not necessarily in a row) open a Breakthrough: a GPU Crate and, the first time, the **Quantum Core**.
- **Daily bonus.** A gift for opening the lab each day, on a 7-day loop that ends in a Server Crate. Missing a day doesn't reset it.
- **Crates.** Supply (3 h), Server (8 h), GPU (12 h) and Lab (24 h) crates sit in four slots and unlock one at a time, so it's worth starting one before you leave. Open early for sparks. Inside: money in proportion to your income, sparks, **Time Warps** (15 min / 1 h off a builder's job, from the job's action bar), **Overclock Charges** (skip the cooldown) and Streak Freezes. A crate that arrives with full slots waits in the inbox.
- **Benchmark League.** A weekly race (Monday to Sunday) against 29 rival AI labs, from Bronze through Silver, Gold, Sapphire, Ruby, Emerald, Amethyst, Pearl and Obsidian to Diamond. Points come from tokens served, quests, your daily goal, upgrades, contracts and Lab levels. The top 7 move up, the bottom 5 move down; the top 3 win crates (and the first time, the **Benchmark Trophy**). You join a week by earning a point in it. The rival labs are simulated, fixed for each week, with their own rhythms (and the odd lab that never shows up).
- **Lab Pass.** A season each calendar month with its own theme. Quests, daily goals, the daily bonus and Breakthroughs earn Pass points; 30 tiers, a free track (the **Neon Token Sign** at tier 10) and a premium track for 120 sparks (the **Hologram Assistant** at 15, a Lab Crate at 30). Rewards you didn't claim go to the inbox when the season ends.
- **Events**, on your local calendar so every player shares them: **Spotlight Hour** (Tuesdays 18:00-19:00, one model sells for 3x), **Hackathon Weekend** (builds and upgrades started at the weekend take 25% less time), **Community Day** (the second Saturday of the month, 14:00-17:00: tokens sell for 2x, triple Pass points and three special quests for the **Liquid-Cooled Fountain**), **Launch Week** (research 20% cheaper) and **Final Push** (double Pass points in a season's last two days). A banner shows what's on.
- **Album.** 13 badges with five tiers each (sparks per tier), and mastery stars for every model: serve 100, 1K, 10K and 100K of its tokens for sparks and +2% on its price per star. Models you haven't served show as silhouettes.
- **Sparks shop.** Tap your sparks: spark packs (80 to 7,000), a one-time **Starter Pack** (400 sparks, three 1-hour Time Warps and a Lab Crate), and the **Spark Exchange**, which trades money for 10 sparks up to five times a day (dearer each time). Packs are sold through Google Play Billing on Android and StoreKit on iOS (`autoload/store.gd`; add the Play Billing plugin / InAppStore plugin to the export and create the product ids from `Store.PACKS` and `starter`). Where there's no store (desktop, the web demo) the shop says so honestly and only the Exchange works. A production release should also validate receipts on a server.
- **Me.** Name your lab and pick its colour (it's how you appear in the League), share your friend code (a friend who enters it gets a welcome gift), share an invite or a snapshot of your lab with a stats banner, see your records, and choose your reminders.
- **Reminders.** When you leave, the game plans a few nudges: builders done, a crate unlocked, earnings at their cap, your streak at 19:30 if today's goal is open, tomorrow's quests at 9:00, an event starting, the League's last evening, a note after three days away. At most one of each, none between 22:00 and 08:00 (unless you turn quiet hours off), each kind can be switched off. On the web they use the browser's notifications (allow them in Me > Reminders) and fire while the tab stays open; Android and iOS exports use a local-notification plugin if there is one (a `LocalNotification` singleton with `show()` and `cancel_all()`).
- **Coming back** after three days or more brings a welcome-back gift (bigger after two weeks).
- **Exclusive decor** can't be bought, only earned: the Neon Token Sign, Hologram Assistant, Liquid-Cooled Fountain, Benchmark Trophy, Eternal Flame and Quantum Core, each with a strong aura.

Everything works offline. The daily layer saves in its own file next to the game save; dev flag `--days=N` moves its clock N days ahead to try streaks and resets.

## Project layout

```
boot.gd/.tscn        emblem + loading bar; warms up every mesh, shader and panel (render/warmup.gd), then fades in
main.gd/.tscn        World + HUD; dev flags (--demo, --showcase, --bot, --shot, --tour ...)
autoload/market.gd   the inference market: capacity, demand per model and channel, serving, bandwidth, prices,
                     reputation, latency, quality, the orbit (ticks 4x a second)
autoload/game.gd     state: money, sparks, tokens served, the Lab level, game clock, buildings, builder jobs,
                     land, obstacles, research, perks, staff, contracts, save/load (v1 saves migrate) and time away
autoload/store.gd    the sparks shop: Play Billing / StoreKit, packs, Starter Pack, Spark Exchange
autoload/live.gd     the daily layer: streak, quests, login bonus, crates, boosters, badges, mastery,
                     Benchmark League, Lab Pass, events, inbox, profile (own save file)
autoload/notifier.gd plans reminders and hands them to the browser or a mobile plugin
core/live_defs.gd    the daily layer's data: quests, rewards, crates, badges, leagues, Pass tracks, events, reminder text
core/defs.gd         resources, models, token looks, buildings (prices, limits), Lab levels, roles, regions,
                     obstacles, Megacluster stages
core/bal.gd          every number: building effects per level, prices, build and upgrade times, sparks to finish,
                     research, perks, land
world/
  world.gd           spawns buildings, construction sites and scaffolding, roads, obstacles, logistics broker,
                     staff and builders
  roads.gd           the High Street and the self-building side roads (cheapest paths, few turns), courier routes
  grid.gd            2 m building grid, occupancy, obstacles, A* walking paths
  terrain.gd         endless ground (regions, land, roads), streamed decor, For Sale signs
  camera_rig.gd      free pan / zoom camera with a little glide
  building.gd        base for everything placeable (footprint, entrance, ports, tiers, save)
  b_server.gd  b_source.gd  b_machine.gd (labs)  b_storage.gd  b_trainer.gd  b_channel.gd (gateway, edge,
  agent hub, ground station)  b_launch.gd  b_cafe.gd  b_desk.gd  b_dorm.gd  b_hut.gd  b_site.gd  b_decor.gd  b_mega.gd
  orbit_view.gd      the orbital datacenter in the sky and its downlink beams
  server_art.gd  source_art.gd  stations.gd  lab_art.gd  infra_art.gd  town_art.gd  previews.gd   (the looks)
  growth.gd          the gear buildings gain level by level (slots, schedule, roof heights)
  growth_parts.gd    that gear: cabinets, GPU crates, chillers, dishes, screens... in four grades
  growth_tops.gd     generated roof heights for roof gear (dev/tops.tscn --write)
  items.gd           resources (and token coins for icons and signs)
  holder.gd  animal.gd (crawler bots, drones, ore carts)  character.gd  worker.gd  builder.gd  tech_worker.gd  customer.gd
ui/                  title menu, HUD, action bar, job timers, placement, build / building / model / training /
                     market / shop / staff / research / settings panels, Lab HQ (live_panel.gd), sharing, goals (tutorial)
render/              toon, ground, glass, belt shaders; warmup.gd
assets/              icons (rendered), UI skins, audio (synthesized), fonts (OFL)
tests/               headless logic tests + the autopilot bot
tools/               check, test, bot, screenshot, icon scripts; UI and audio generators
dev/                 art bench (every building x 5 tiers), icon renderer, screenshot helper, perf probes
```

**Adding content is mostly data:**
- **A building** is a row in `Defs.BUILDINGS` (price, growth, build time, optional limit), plus a `Building` subclass (or an existing one) and its art in the matching `*_art.gd`.
- **A model** is a row in `Defs.RECIPES` (VRAM, speed, price, demand, open-weights price or training data and compute) and `Defs.MODEL_LOOK`; its icon `tk_<id>` is rendered by `tools/icons.sh`.
- **A resource** is a row in `Defs.ITEMS`, a mesh in `Items.resource_into`, and a source (with a station in `Stations`) or a lab that makes it.
- **Research or a perk** is a row in `Bal.RESEARCH` / `Bal.PERKS`, read with `Game.research(id)` / `Game.perk(id)`.

## Running, testing, building

```bash
godot --path .                   # play (desktop window 450x800, mouse = touch)
tools/check.sh                   # parse every script
tools/test.sh                    # headless tests (data, balance, game state, builders, roads, a real world)
tools/bot.sh 60                  # the autopilot plays 60 game-minutes (fixed-step, faster than real time)
tools/icons.sh                   # render every icon from the game's models (tools/icons.sh gpu tk_pico for some)
tools/shot.sh res://main.tscn out.png -- --demo
tools/shot.sh res://dev/bench.tscn out.png -- --kinds=server,gateway --spacing=12 --tiers=0,2,4   # looks side by side
tools/shot.sh res://dev/bench.tscn out.png -- --kinds=gateway --levels=1,3,5,14,40                # looks + level gear
RES=1280x1280 tools/shot.sh res://dev/growth.tscn out.png -- --kind=server --levels=1,3,6,10,20,40   # one building, many levels
RES=1280x1280 tools/shot.sh res://dev/growth.tscn out.png -- --parts=floor --tier=2                # every gear part in its grades
godot --headless --path . res://dev/tops.tscn -- --write                                          # regenerate roof heights
```

Dev flags (after `--`):
- `--fresh` starts a new game.
- `--demo` loads a mid-game empire; `--demo --space` adds a Launch Complex, Ground Stations and four modules in orbit.
- `--era=0..4` jumps to an era (sets the Lab level it starts at), e.g. `--demo --era=4 --zoom=2.2`.
- `--showcase` places every building, `--showcase --tier=4` at its top look, `--top` at its top level with all its gear.
- `--place=src_coolant` opens the placement mode.
- `--select=server` selects a building (`--info` also opens its card); `--recipes` opens the model picker.
- `--panel=build|staff|research|settings|market|shop` opens a panel; `--panel=today|league|pass|events|album|me` opens Lab HQ on that tab.
- `--days=N` moves the daily layer's clock N days ahead.
- `--tut=N` jumps to a tutorial step; `--tour=<dir>` plays the opening and saves a screenshot per step.
- `--title` shows the title menu in screenshots.
- `--perf` prints render stats.
- `--wdbg` prints worker and building states.
- `--hitch` runs every common action and prints its cost and the slowest frame after it; `--boottime` (on the boot scene) times the loading screen; `--film=<dir>` saves a screenshot sequence.
- `--store-sandbox` (debug builds) completes shop purchases at once, for free, to test the shop.

## Pacing

The game is tuned for about **two weeks**, base-builder style. Nothing is locked, so money paces the first hours; after that builder timers do. Upgrades take seconds for the first levels (finish them free), minutes in the middle and up to eight hours at the top, and you have at most five builders. Timers keep running while you're away.

The first two hours, measured by the autopilot bot (`tools/bot.sh`, a careful player who never spends sparks on timers or huts). The Lab level counts tokens served, and its thresholds are set so it keeps Cookie Empire's tested pacing; time away counts too (your servers keep serving):

| Milestone | Play time |
|---|---|
| First sale | about 30 s |
| Serving Mini 3B | about 1 min |
| Lab level 2 | about 2 min |
| Lab level 3 | about 5 min |
| Serving Chat 7B | about 8 min |
| Lab level 4 | about 14 min |
| Serving Chat 13B | about 18 min |
| Lab level 5 | about 21 min |
| Lab level 6 | about 30 min |
| Lab level 8 | about 77 min |

The AGI Megacluster ($200M) takes 8 h to start and 12 h, 24 h, 36 h and 48 h for its stages, plus money and Frontier 1T token deliveries.

## Export

Export presets:
- **Android**: arm64 APK.
- **iOS**: exports an Xcode project.
- **Web**: Compatibility renderer, PWA.

Older phones fall back to the OpenGL renderer and step quality down automatically.

## Performance notes
- **Few materials.** Most meshes are merged per prop and share one toon material through vertex colours (a colour with alpha below 1 glows: LEDs, screens, data).
- **Cheap stacks and decor.** Crates, benches and racks draw one MultiMesh per item type. The streamed decor (trees, cacti, snowy pines, rocks, flowers, grass) is one MultiMesh per kind around the camera.
- **One ground plane.** It follows the camera; a shader colours the regions and the land you own and draws the roads from a one-texel-per-cell texture.
- **Cheap pathfinding.** Couriers walk an `AStarGrid2D` over road cells. Roads are rebuilt only when something is built, moved, sold or cleared.
- **No first-time freezes.** WebGL compiles a shader the first time it's drawn, every session, and GDScript builds meshes on first use. The loading screen does all of that up front (`render/warmup.gd`): every building at every look, construction sites, ghosts, items, people, decor, every material, every panel and effect.
