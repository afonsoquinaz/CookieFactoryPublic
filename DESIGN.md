# Token Empire 2: the inference economy

How the game works since the 2.0 rework. In Token Empire you build compute and you sell tokens through an API. The first version followed its cookie-factory ancestor too closely: models were "baked" from web data, physical tokens rolled out of the server and couriers carried them to a van. Version 2 keeps the hardware supply chain physical (power, coolant, chips, data) and makes inference work the way it does in real life. Customers call your API, your servers answer as fast as their GPUs allow, and every token served is paid for on the spot.

## The loop

```
 sources ──► labs ──► GPUs / HBM ──┐            customers (API calls)
 (power, silicon,  (Chip Fab,       │                    │
  copper, rare...)  HBM Works)      ▼                    ▼
                               SERVERS  ◄──── demand: gateways, Chat App,
 power + coolant ─────────────► (capacity)     enterprise contracts, edge,
                                    │          agents, rivals, prices
 data, code, labels ──► TRAINING ───┘ new models (VRAM, speed, price)
 feedback, papers...    CLUSTER
                                    ▼
                         tokens served x price = revenue
```

1. **Capacity.** A server's throughput depends on its accelerators: a garage graphics card to start, then up to 20 data-centre GPUs that couriers bring from a Chip Fab and slot in. Its level (better kernels and batching) and how well it's tuned also count. The model it runs matters too: small models are fast, big ones slow.
2. **Memory.** Each model needs a minimum amount of VRAM. The garage card has 12 GB, a GPU adds 80 GB and an HBM stack adds 40 GB. Bigger models need bigger servers.
3. **Running costs.** Accelerators burn power cells and, once real GPUs are in, coolant. With no power the server stops; with no coolant it throttles to 60%.
4. **Wear.** GPUs fail now and then. The slot goes dark and couriers bring a replacement, which keeps the Chip Fab busy for the whole game.
5. **Demand.** Each model you offer has its own market (thousands of tokens per second). How big it is depends on:
   - AI adoption, which grows with your Lab level;
   - your channels: API Gateways, the Chat App, Enterprise contracts, Edge PoPs and the Agent Hub;
   - your reputation, which drops when requests go unserved;
   - latency, which rises as servers fill up;
   - your price: higher prices mean fewer customers.
   Trending models and events push demand up.
6. **Serving.** Each second, every model serves whichever is smaller: its demand, the capacity of the servers running it, or what your gateways' bandwidth can carry. Revenue is tokens served times price. Demand you can't serve is lost and hurts your reputation.
7. **Tuning.** Engineers walk among a server's racks and tap the machines, tuning kernels, cache and batching. Each tap raises the server's tune by a little, up to +50% throughput, and the tune fades over time. You can tap a server to tune it yourself.
8. **Models.** Pico 1B is yours from the start. Mini 3B and Chat 7B are open weights you can download for a licence fee. Everything bigger has to be trained in a Training Cluster:
   - you choose a model;
   - couriers deliver its training data (web data, datasets, code, labels, fine-tunes, reward models, papers, synthetic data, expert data);
   - the cluster's GPUs grind through the compute;
   - the new model comes online.
   Models also go stale as rivals ship better ones. A refresh run on the cluster raises a model's quality, and quality drives its demand.
9. **Space.** Late in the game, a Launch Complex assembles orbital server modules (24 GPUs, 8 HBM stacks, 60 power cells each) and launches them on rockets. In orbit they get free solar power and radiative cooling, so they need no power or coolant, but each adds 80 ms of latency. A Ground Station downlinks their bandwidth. The orbital datacenter grows in the sky above your campus.

## Numbers

All token amounts below are in thousands of tokens (K). The HUD shows real token counts.

| Model | VRAM (GB) | K tok/s per GPU | $ per K tok | Base demand (K/s) | Get it |
|---|---|---|---|---|---|
| Pico 1B | 2 | 1.00 | 3 | 0.6 | start |
| Mini 3B | 6 | 0.80 | 6 | 0.6 | download $40 |
| Chat 7B | 16 | 0.60 | 11 | 0.6 | download $400 |
| Chat 13B | 28 | 0.45 | 17 | 0.5 | train |
| Wiki 13B | 28 | 0.45 | 24 | 0.4 | train |
| Code 13B | 28 | 0.42 | 30 | 0.4 | train |
| Tool 30B | 64 | 0.35 | 38 | 0.35 | train |
| Vision 70B | 150 | 0.30 | 48 | 0.3 | train |
| Assist 70B | 150 | 0.28 | 60 | 0.3 | train |
| Code 70B | 150 | 0.25 | 80 | 0.3 | train |
| Aligned 70B | 150 | 0.24 | 98 | 0.25 | train |
| Long 120B | 260 | 0.20 | 125 | 0.25 | train |
| Reason 200B | 420 | 0.16 | 170 | 0.2 | train |
| Sage 400B | 820 | 0.13 | 220 | 0.2 | train |
| Omni 400B | 860 | 0.12 | 270 | 0.2 | train |
| Expert MoE | 1000 | 0.12 | 340 | 0.18 | train |
| Frontier 1T | 1800 | 0.08 | 600 | 0.15 | train |

Revenue per GPU (speed times price) rises from $3/s on Pico to $48/s on Frontier. Every model's market has a limit, though, so you earn the most by serving a portfolio of models.

- **Adoption:** demand x 1.6 for every Lab level above 1.
- **Price:** the price you set (0.5x to 2x) multiplies demand by price^-1.6.
- **Latency:**
  - latency = the model's base latency x (1 + 3 x utilisation^3), minus 25 ms per Edge PoP, plus 80 ms when served from orbit;
  - demand x clamp(1.25 - latency / 800, 0.3, 1.2).
- **Reputation** (0.2 to 1): demand x (0.5 + reputation). It falls with the share of demand you leave unserved and recovers slowly while you keep up.
- **Channels:**
  - organic demand: x1;
  - each API Gateway: +0.6, plus 0.08 per level above 1;
  - each Edge PoP: +0.2 per level step;
  - Chat App visitors add their own demand at 1.3x price;
  - Enterprise contracts add demand for one model at 1.2x price, plus a bonus when finished;
  - the Agent Hub adds agent demand for tool-capable models at 2x price.
- **Bandwidth:** what you can serve is capped by what your gateways can carry: 2 K/s x 1.25^(level-1), plus 3 K/s per fiber spool installed. With no gateway at all there's a 1 K/s garage line.
- **Accelerators:**
  - the garage card is 0.5 accelerators x 1.12^(level-1);
  - each GPU is 1 accelerator;
  - a server level gives x(1 + 0.08 x (level-1));
  - full tune gives x1.5.
- **Slots:** a server holds 1 + (level-1)/2 GPUs (up to 20) and (level-1)/3 HBM stacks (up to 12), so a top server holds 1,892 GB: Frontier fits.
- **Power:** 1 power cell per accelerator every 6 s at full load. **Coolant:** 1 per GPU every 10 s.
- **GPU failures:** about one per GPU every 3 hours of use.

## Gems (sparks)

Sparks come from Lab levels, contracts, obstacles, quests, crates, the League and the Pass. You can also buy them:

- **The Shop** sells spark packs and a one-time Starter Pack. Purchases go through the platform store: Google Play Billing on Android, StoreKit on iOS. On the web and desktop, with no store connected, the shop says so instead of pretending.
- **The Spark Exchange** turns money into sparks at a rate that gets worse with each trade that day, so players everywhere can top up.
