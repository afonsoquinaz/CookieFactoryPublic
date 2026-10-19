class_name Defs
## Static game definitions: resources, models, buildings, staff roles, biomes.
## Everything data-like lives here or in Bal so new content is a table entry.
##
## Token Empire follows the AI supply chain: sources make raw resources
## (power, web data, silicon, labels...), labs turn them into better ones
## (GPUs, datasets, fine-tunes...), and an Inference Server feeds every
## request through the modules its model needs and puts out tokens.
##
## Item ids:
##   resources      "power", "gpu", ...             (raw from sources, refined in labs)
##   tokens         "t:<model>"  e.g. "t:chat7"
##   token batches  "b:<model>"  (6 tokens, batched)
##   agent runs     "a:<model>"  (a batch wrapped into an agent workflow)

const RAW: Array[String] = ["power", "data", "coolant", "silicon", "copper", "code", "labels", "feedback", "rare", "papers", "fiber", "experts"]
const PROCESSED: Array[String] = ["gpu", "dataset", "finetune", "hbm", "reward", "synth"]

## h = stacking height (m) in a carry column.
const ITEMS := {
	"power": {"name": "Power Cells", "h": 0.22, "color": Color(0.46, 0.82, 0.52)},
	"data": {"name": "Web Data", "h": 0.2, "color": Color(0.36, 0.74, 0.92)},
	"coolant": {"name": "Coolant", "h": 0.28, "color": Color(0.42, 0.68, 0.9)},
	"silicon": {"name": "Silicon", "h": 0.2, "color": Color(0.62, 0.66, 0.72)},
	"copper": {"name": "Copper", "h": 0.16, "color": Color(0.84, 0.5, 0.3)},
	"code": {"name": "Code", "h": 0.12, "color": Color(0.5, 0.42, 0.78)},
	"labels": {"name": "Labels", "h": 0.16, "color": Color(0.96, 0.78, 0.34)},
	"feedback": {"name": "Feedback", "h": 0.2, "color": Color(0.94, 0.52, 0.56)},
	"rare": {"name": "Rare Earths", "h": 0.2, "color": Color(0.72, 0.46, 0.8)},
	"papers": {"name": "Research", "h": 0.16, "color": Color(0.95, 0.93, 0.86)},
	"fiber": {"name": "Bandwidth", "h": 0.2, "color": Color(0.98, 0.64, 0.86)},
	"experts": {"name": "Expert Data", "h": 0.18, "color": Color(0.86, 0.68, 0.32)},
	"gpu": {"name": "GPUs", "h": 0.14, "color": Color(0.3, 0.62, 0.42)},
	"dataset": {"name": "Datasets", "h": 0.24, "color": Color(0.28, 0.6, 0.86)},
	"finetune": {"name": "Fine-Tunes", "h": 0.14, "color": Color(0.96, 0.6, 0.3)},
	"hbm": {"name": "HBM Memory", "h": 0.1, "color": Color(0.24, 0.36, 0.56)},
	"reward": {"name": "Reward Models", "h": 0.2, "color": Color(0.94, 0.76, 0.3)},
	"synth": {"name": "Synthetic Data", "h": 0.22, "color": Color(0.66, 0.42, 0.92)},
}

## Models. An Inference Server serves the model you choose (or the best one
## it can feed); every request burns power plus a dose of each module's
## resource, one module bay each. Order = how they unlock.
## params / lat (ms) / tag are flavour for the model picker.
const RECIPES := [
	{"id": "pico", "name": "Pico 1B", "ings": [], "price": 3.0, "params": "1B", "lat": 15, "tag": "Runs on a gaming GPU. Tiny, local, instant."},
	{"id": "mini", "name": "Mini 3B", "ings": ["data"], "price": 6.0, "params": "3B", "lat": 22, "tag": "Knows a little about everything on the web."},
	{"id": "chat7", "name": "Chat 7B", "ings": ["data", "coolant"], "price": 11.0, "params": "7B", "lat": 35, "tag": "A friendly chat model. Runs warm."},
	{"id": "chat13", "name": "Chat 13B", "ings": ["data", "coolant", "gpu"], "price": 17.0, "params": "13B", "lat": 55, "tag": "Bigger, smarter, needs real accelerators."},
	{"id": "wiki13", "name": "Wiki 13B", "ings": ["data", "gpu", "dataset"], "price": 24.0, "params": "13B", "lat": 60, "tag": "Trained on clean data. Fewer made-up facts."},
	{"id": "code13", "name": "Code 13B", "ings": ["data", "gpu", "code"], "price": 30.0, "params": "13B", "lat": 60, "tag": "Writes code, fixes bugs, explains regex."},
	{"id": "tool30", "name": "Tool 30B", "ings": ["data", "code", "dataset"], "price": 38.0, "params": "30B", "lat": 80, "tag": "Calls tools and APIs on its own."},
	{"id": "vision70", "name": "Vision 70B", "ings": ["data", "coolant", "gpu", "dataset"], "price": 48.0, "params": "70B", "lat": 110, "tag": "Sees images, reads charts."},
	{"id": "assist70", "name": "Assist 70B", "ings": ["data", "dataset", "finetune"], "price": 60.0, "params": "70B", "lat": 110, "tag": "Fine-tuned to follow instructions."},
	{"id": "code70", "name": "Code 70B", "ings": ["data", "gpu", "code", "finetune"], "price": 80.0, "params": "70B", "lat": 120, "tag": "Ships whole features. Writes the tests too."},
	{"id": "align70", "name": "Aligned 70B", "ings": ["feedback", "finetune", "gpu", "coolant"], "price": 98.0, "params": "70B", "lat": 120, "tag": "Helpful, honest, harmless, tuned on feedback."},
	{"id": "long120", "name": "Long 120B", "ings": ["data", "gpu", "coolant", "hbm"], "price": 125.0, "params": "120B", "lat": 180, "tag": "A million tokens of context. Needs a lot of memory."},
	{"id": "reason200", "name": "Reason 200B", "ings": ["data", "gpu", "dataset", "coolant", "papers"], "price": 170.0, "params": "200B", "lat": 260, "tag": "Thinks step by step before it answers."},
	{"id": "sage400", "name": "Sage 400B", "ings": ["data", "gpu", "dataset", "finetune", "reward"], "price": 220.0, "params": "400B", "lat": 320, "tag": "Polished by reinforcement learning from feedback."},
	{"id": "omni400", "name": "Omni 400B", "ings": ["data", "gpu", "coolant", "hbm", "fiber"], "price": 270.0, "params": "400B", "lat": 340, "tag": "Text, images, audio and video, all at once."},
	{"id": "moe", "name": "Expert MoE", "ings": ["papers", "hbm", "gpu", "synth"], "price": 340.0, "params": "8x220B", "lat": 300, "tag": "A mixture of experts, trained on synthetic data."},
	{"id": "frontier", "name": "Frontier 1T", "ings": ["data", "coolant", "gpu", "finetune", "papers", "reward", "hbm"], "price": 600.0, "params": "1T", "lat": 450, "tag": "The best model in the world. For now."},
]

## Token looks per model: colour, coin shape and the glyph on its face.
const MODEL_LOOK := {
	"pico": {"base": Color(0.62, 0.82, 0.68), "glyph": "dot", "shape": "round"},
	"mini": {"base": Color(0.46, 0.76, 0.9), "glyph": "dots", "shape": "round"},
	"chat7": {"base": Color(0.4, 0.62, 0.92), "glyph": "bubble", "shape": "round"},
	"chat13": {"base": Color(0.36, 0.48, 0.88), "glyph": "bubble2", "shape": "hex"},
	"wiki13": {"base": Color(0.92, 0.9, 0.84), "glyph": "book", "shape": "hex"},
	"code13": {"base": Color(0.42, 0.36, 0.7), "glyph": "brackets", "shape": "square"},
	"tool30": {"base": Color(0.86, 0.6, 0.3), "glyph": "gear", "shape": "hex"},
	"vision70": {"base": Color(0.32, 0.72, 0.72), "glyph": "eye", "shape": "round"},
	"assist70": {"base": Color(0.96, 0.64, 0.38), "glyph": "star", "shape": "hex"},
	"code70": {"base": Color(0.3, 0.26, 0.56), "glyph": "brackets2", "shape": "square"},
	"align70": {"base": Color(0.94, 0.56, 0.62), "glyph": "heart", "shape": "round"},
	"long120": {"base": Color(0.26, 0.4, 0.62), "glyph": "wave", "shape": "wide"},
	"reason200": {"base": Color(0.64, 0.46, 0.86), "glyph": "steps", "shape": "hex"},
	"sage400": {"base": Color(0.96, 0.82, 0.4), "glyph": "medal", "shape": "round"},
	"omni400": {"base": Color(0.92, 0.5, 0.78), "glyph": "prism", "shape": "hex"},
	"moe": {"base": Color(0.48, 0.3, 0.72), "glyph": "cubes", "shape": "square"},
	"frontier": {"base": Color(0.98, 0.94, 0.86), "glyph": "crown", "shape": "star"},
}

const TOKEN_H := 0.085
const BATCH_H := 0.26
const AGENT_H := 0.34

# ---------------------------------------------------------------- buildings
## size = footprint in grid cells (Grid.CELL m), x = width, y = depth (front
## faces +Z when unrotated; the entrance is the cell in front of the middle of
## the front edge, where the road arrives).
## Everything can be built from the start: what to invest in is up to you.
## cost = first purchase, growth = price factor per copy you already own;
## gems = price in sparks instead (builder huts); limit = most copies you can
## have (none = unlimited). up = upgrade cost 1 -> 2, max = top level,
## time = seconds to build it.
const TABS := [
	["source", "Sources", "src_power"],
	["server", "Compute", "server"],
	["pack", "Storage", "depot"],
	["sell", "Sales", "van"],
	["town", "Campus", "builder"],
	["decor", "Decor", "planter"],
]

const SOURCE_TIERS: Array[int] = [1, 5, 10, 20, 35]
const MACHINE_TIERS: Array[int] = [1, 5, 12, 25, 40]
const SERVER_TIERS: Array[int] = [1, 5, 12, 22, 32]

const BUILDINGS := {
	# ---- campus
	"hut": {"name": "Builder's Hut", "cat": "staff", "tab": "town", "icon": "builder", "size": Vector2i(2, 2), "limit": 5, "cost": 0, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"gems": [0, 0, 60, 150, 300], "desc": "Each hut houses a builder. More builders, more things built at once."},
	"dorm": {"name": "Staff Housing", "cat": "staff", "tab": "town", "icon": "dorm", "size": Vector2i(2, 2), "cost": 150, "growth": 2.5, "up": 90, "max": 20, "time": 30,
		"desc": "Houses more staff: couriers, technicians and engineers."},

	# ---- sources (3x3): raw resources
	"src_power": {"name": "Solar Farm", "cat": "source", "tab": "source", "icon": "src_power", "res": "power", "size": Vector2i(3, 3), "cost": 30, "growth": 2.2, "up": 12, "max": 60, "time": 5,
		"desc": "Panels charge power cells. Every request burns power."},
	"src_data": {"name": "Web Crawler", "cat": "source", "tab": "source", "icon": "src_data", "res": "data", "size": Vector2i(3, 3), "cost": 40, "growth": 2.2, "up": 18, "max": 60, "time": 5,
		"desc": "Crawls the web for text. Every model after the first needs data."},
	"src_coolant": {"name": "Cooling Tower", "cat": "source", "tab": "source", "icon": "src_coolant", "res": "coolant", "size": Vector2i(3, 3), "cost": 120, "growth": 2.2, "up": 30, "max": 60, "time": 10,
		"desc": "Chills coolant for the bigger, hotter models."},
	"src_silicon": {"name": "Silicon Works", "cat": "source", "tab": "source", "icon": "src_silicon", "res": "silicon", "size": Vector2i(3, 3), "cost": 250, "growth": 2.2, "up": 45, "max": 60, "time": 20,
		"desc": "Melts sand and pulls pure silicon crystals, for chips and memory."},
	"src_copper": {"name": "Copper Mine", "cat": "source", "tab": "source", "icon": "src_copper", "res": "copper", "size": Vector2i(3, 3), "cost": 400, "growth": 2.2, "up": 70, "max": 60, "time": 30,
		"desc": "Copper for the wiring inside every chip."},
	"src_code": {"name": "Code Commons", "cat": "source", "tab": "source", "icon": "src_code", "res": "code", "size": Vector2i(3, 3), "cost": 1500, "growth": 2.2, "up": 250, "max": 60, "time": 60,
		"desc": "Open-source developers write code for coding models."},
	"src_labels": {"name": "Labeling Studio", "cat": "source", "tab": "source", "icon": "src_labels", "res": "labels", "size": Vector2i(3, 3), "cost": 3000, "growth": 2.2, "up": 600, "max": 60, "time": 90,
		"desc": "People label examples, for the fine-tune lab."},
	"src_feedback": {"name": "Feedback Lounge", "cat": "source", "tab": "source", "icon": "src_feedback", "res": "feedback", "size": Vector2i(3, 3), "cost": 12000, "growth": 2.2, "up": 2200, "max": 60, "time": 300,
		"desc": "Raters compare answers and say which is better."},
	"src_rare": {"name": "Rare Earth Mine", "cat": "source", "tab": "source", "icon": "src_rare", "res": "rare", "size": Vector2i(3, 3), "cost": 30000, "growth": 2.2, "up": 5000, "max": 60, "time": 600,
		"desc": "Glittering rare earths for memory chips. Decor nearby keeps the miners happy."},
	"src_papers": {"name": "Research Campus", "cat": "source", "tab": "source", "icon": "src_papers", "res": "papers", "size": Vector2i(3, 3), "cost": 150000, "growth": 2.2, "up": 30000, "max": 60, "time": 1200,
		"desc": "Researchers turn ideas into papers. Precious."},
	"src_fiber": {"name": "Fiber Hub", "cat": "source", "tab": "source", "icon": "src_fiber", "res": "fiber", "size": Vector2i(3, 3), "cost": 1.2e6, "growth": 2.2, "up": 2.8e5, "max": 60, "time": 1800,
		"desc": "Spools of fibre-optic bandwidth for multimodal models."},
	"src_experts": {"name": "Expert Network", "cat": "source", "tab": "source", "icon": "src_experts", "res": "experts", "size": Vector2i(3, 3), "cost": 6.0e6, "growth": 2.2, "up": 1.6e6, "max": 60, "time": 3600,
		"desc": "Doctors, lawyers and professors write expert examples."},

	# ---- compute: the inference server, a whole serving stack in one building
	"server": {"name": "Inference Server", "cat": "server", "tab": "server", "icon": "server", "size": Vector2i(5, 3), "cost": 400, "growth": 8.0, "up": 40, "max": 40, "time": 10,
		"desc": "Router, request bus, module bays and a GPU core in one. Choose the model it serves; upgrades add bays for bigger models."},

	# ---- labs (2x2): turn resources into better ones
	"fab": {"name": "Chip Fab", "cat": "lab", "tab": "server", "icon": "fab", "size": Vector2i(2, 2), "cost": 600, "growth": 2.4, "up": 110, "max": 50, "time": 60,
		"in": {"silicon": 2, "copper": 1}, "out": {"gpu": 1}, "craft": 3.0, "desc": "Silicon and copper become GPUs."},
	"refinery": {"name": "Data Refinery", "cat": "lab", "tab": "server", "icon": "refinery", "size": Vector2i(2, 2), "cost": 900, "growth": 2.4, "up": 170, "max": 50, "time": 90,
		"in": {"data": 3}, "out": {"dataset": 2}, "craft": 3.5, "desc": "Cleans and dedupes web data into datasets."},
	"tune_lab": {"name": "Fine-Tune Lab", "cat": "lab", "tab": "server", "icon": "tune_lab", "size": Vector2i(2, 2), "cost": 5000, "growth": 2.4, "up": 900, "max": 50, "time": 300,
		"in": {"labels": 2, "dataset": 1}, "out": {"finetune": 1}, "craft": 4.0, "desc": "Labels and a dataset become a fine-tune."},
	"hbm_works": {"name": "HBM Works", "cat": "lab", "tab": "server", "icon": "hbm_works", "size": Vector2i(2, 2), "cost": 60000, "growth": 2.4, "up": 13000, "max": 50, "time": 900,
		"in": {"silicon": 2, "rare": 1}, "out": {"hbm": 1}, "craft": 4.5, "desc": "Silicon and rare earths become stacked HBM memory."},
	"rlhf_gym": {"name": "RLHF Gym", "cat": "lab", "tab": "server", "icon": "rlhf_gym", "size": Vector2i(2, 2), "cost": 400000, "growth": 2.4, "up": 75000, "max": 50, "time": 1800,
		"in": {"feedback": 2, "finetune": 1}, "out": {"reward": 1}, "craft": 5.0, "desc": "Feedback and a fine-tune train a reward model."},
	"synth_lab": {"name": "Synth Lab", "cat": "lab", "tab": "server", "icon": "synth_lab", "size": Vector2i(2, 2), "cost": 1.0e7, "growth": 2.4, "up": 2.5e6, "max": 50, "time": 3600,
		"in": {"experts": 1, "data": 2}, "out": {"synth": 1}, "craft": 5.0, "desc": "Expert seeds and web data grow into synthetic data."},

	# ---- storage + packing (2x2)
	"depot": {"name": "Supply Depot", "cat": "pack", "tab": "pack", "icon": "depot", "size": Vector2i(2, 2), "cost": 200, "growth": 2.0, "up": 45, "max": 40, "time": 30,
		"desc": "Stores resources close to where they're needed."},
	"cache": {"name": "Token Cache", "cat": "pack", "tab": "pack", "icon": "cache", "size": Vector2i(2, 2), "cost": 300, "growth": 2.0, "up": 100, "max": 40, "time": 30,
		"desc": "Stores tokens, batches and agents until they're sold."},
	"batcher": {"name": "Batcher", "cat": "pack", "tab": "pack", "icon": "batcher", "size": Vector2i(2, 2), "cost": 2500, "growth": 2.4, "up": 400, "max": 50, "time": 300,
		"desc": "Batches 6 tokens into a response worth 25% more."},
	"agent_studio": {"name": "Agent Studio", "cat": "pack", "tab": "pack", "icon": "agent_studio", "size": Vector2i(2, 2), "cost": 200000, "growth": 2.4, "up": 48000, "max": 50, "time": 1800,
		"desc": "Wraps a batch into an agent run worth 60% more."},

	# ---- sales
	"van": {"name": "API Depot", "cat": "sell", "tab": "sell", "icon": "van", "size": Vector2i(2, 3), "cost": 300, "growth": 3.0, "up": 45, "max": 50, "time": 10,
		"desc": "Couriers load tokens; the API van drives off to town and sells them."},
	"cafe": {"name": "Chat Café", "cat": "sell", "tab": "sell", "icon": "cafe", "size": Vector2i(3, 2), "cost": 500, "growth": 3.0, "up": 75, "max": 50, "time": 60,
		"desc": "People drop in to chat with your models and pay 30% more. Decor nearby brings more of them."},
	"desk": {"name": "Enterprise Desk", "cat": "sell", "tab": "sell", "icon": "desk", "size": Vector2i(2, 1), "limit": 1, "cost": 800, "growth": 1.0, "up": 0, "max": 1, "time": 120,
		"desc": "Enterprise contracts: deliver them for big rewards and sparks."},
	"hyperloop": {"name": "Hyperloop Station", "cat": "sell", "tab": "sell", "icon": "hyperloop", "size": Vector2i(3, 3), "cost": 20000, "growth": 3.0, "up": 3500, "max": 50, "time": 3600,
		"desc": "A hyperloop pod takes huge loads to the city."},
	"droneport": {"name": "Drone Port", "cat": "sell", "tab": "sell", "icon": "droneport", "size": Vector2i(3, 3), "cost": 2.0e7, "growth": 3.0, "up": 3.9e6, "max": 50, "time": 7200,
		"desc": "Cargo drones fly agent runs around the world: agents sell for double."},

	# ---- decor (no builder needed; auras work in a radius of cells)
	"planter": {"name": "Planter", "cat": "decor", "tab": "decor", "icon": "planter", "size": Vector2i(1, 1), "cost": 25, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.04}, "desc": "Rare Earth Mines nearby dig faster. The Chat Café nearby gets more visitors."},
	"tree": {"name": "Shade Tree", "cat": "decor", "tab": "decor", "icon": "tree", "size": Vector2i(1, 1), "cost": 20, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.02}, "desc": "Pretty, and cafés nearby get more visitors."},
	"hedge": {"name": "Hedge", "cat": "decor", "tab": "decor", "icon": "hedge", "size": Vector2i(1, 1), "cost": 12, "growth": 1.04, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 1, "v": 0.01}, "desc": "A neat hedge."},
	"lamp": {"name": "Smart Lamp", "cat": "decor", "tab": "decor", "icon": "lamp", "size": Vector2i(1, 1), "cost": 30, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.03}, "desc": "Soft LED light. Cafés nearby get more visitors."},
	"substation": {"name": "Substation", "cat": "decor", "tab": "decor", "icon": "substation", "size": Vector2i(1, 1), "cost": 90, "growth": 1.8, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "source", "r": 3, "v": 0.2}, "desc": "Sources within 3 tiles work 20% faster."},
	"bench": {"name": "Bench", "cat": "decor", "tab": "decor", "icon": "bench", "size": Vector2i(1, 1), "cost": 40, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.03}, "desc": "Cafés nearby get more visitors."},
	"bikes": {"name": "Bike Rack", "cat": "decor", "tab": "decor", "icon": "bikes", "size": Vector2i(1, 1), "cost": 60, "growth": 1.08, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.03}, "desc": "Campus bikes. Cafés nearby get more visitors."},
	"flag": {"name": "Company Flag", "cat": "decor", "tab": "decor", "icon": "flag", "size": Vector2i(1, 1), "cost": 90, "growth": 1.08, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.04}, "desc": "Your colours. Cafés nearby get more visitors."},
	"robot": {"name": "Robot Statue", "cat": "decor", "tab": "decor", "icon": "robot", "size": Vector2i(1, 1), "cost": 140, "growth": 1.08, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.04}, "desc": "A friendly little robot. Cafés nearby get more visitors."},
	"battery": {"name": "Battery Bank", "cat": "decor", "tab": "decor", "icon": "battery", "size": Vector2i(2, 2), "cost": 900, "growth": 1.5, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "source", "r": 3, "v": 0.12}, "desc": "Sources within 3 tiles work 12% faster."},
	"foodtruck": {"name": "Food Truck", "cat": "decor", "tab": "decor", "icon": "foodtruck", "size": Vector2i(2, 2), "cost": 2500, "growth": 1.6, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 5, "v": 0.12}, "desc": "Cafés within 5 tiles get 12% more visitors."},
	"coffee": {"name": "Coffee Cart", "cat": "decor", "tab": "decor", "icon": "coffee", "size": Vector2i(2, 2), "cost": 1800, "growth": 2.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "walk", "r": 5, "v": 0.2}, "desc": "Staff within 5 tiles move 20% faster. Visitors love it too."},
	"turbine": {"name": "Wind Turbine", "cat": "decor", "tab": "decor", "icon": "turbine", "size": Vector2i(2, 2), "cost": 15000, "growth": 1.9, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "source", "r": 5, "v": 0.25}, "desc": "Sources within 5 tiles work 25% faster."},
	"net_cab": {"name": "Network Cabinet", "cat": "decor", "tab": "decor", "icon": "net_cab", "size": Vector2i(1, 1), "cost": 400, "growth": 1.35, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 2, "v": 0.05}, "desc": "Switches and patch cables. Servers and labs within 2 tiles work 5% faster."},
	"rack_row": {"name": "Rack Row", "cat": "decor", "tab": "decor", "icon": "rack_row", "size": Vector2i(2, 2), "cost": 6000, "growth": 1.6, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 3, "v": 0.1}, "desc": "Open racks with blinking lights. Servers and labs within 3 tiles work 10% faster."},
	"chiller": {"name": "Chiller Unit", "cat": "decor", "tab": "decor", "icon": "chiller", "size": Vector2i(2, 2), "cost": 45000, "growth": 1.7, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 4, "v": 0.15}, "desc": "Big fans keep the chips cool. Servers and labs within 4 tiles work 15% faster."},
	"generator": {"name": "Backup Generator", "cat": "decor", "tab": "decor", "icon": "generator", "size": Vector2i(2, 2), "cost": 3.0e5, "growth": 1.8, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 5, "v": 0.2}, "desc": "Never a brown-out. Servers and labs within 5 tiles work 20% faster."},
	"transformer": {"name": "Transformer Yard", "cat": "decor", "tab": "decor", "icon": "transformer", "size": Vector2i(3, 3), "cost": 2.5e6, "growth": 2.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 6, "v": 0.25}, "desc": "High voltage straight from the grid. Servers and labs within 6 tiles work 25% faster."},
	"gpu_statue": {"name": "Golden GPU", "cat": "decor", "tab": "decor", "icon": "gpu_statue", "size": Vector2i(2, 2), "cost": 1.3e6, "growth": 4.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "global_price", "r": 0, "v": 0.05}, "desc": "Every token in the empire sells for 5% more."},

	# ---- the wonder
	"mega": {"name": "AGI Megacluster", "cat": "wonder", "tab": "town", "icon": "mega", "size": Vector2i(5, 5), "limit": 1, "cost": 2.0e8, "growth": 1.0, "up": 0, "max": 1, "time": 28800,
		"desc": "The crown of your empire. Build it in five stages to win."},
}

## Order of cards in the build menu.
const BUILD_ORDER: Array[String] = [
	"src_power", "src_data", "src_coolant", "src_silicon", "src_copper", "src_code", "src_labels", "src_feedback", "src_rare", "src_papers", "src_fiber", "src_experts",
	"server", "fab", "refinery", "tune_lab", "hbm_works", "rlhf_gym", "synth_lab",
	"depot", "cache", "batcher", "agent_studio",
	"van", "cafe", "desk", "hyperloop", "droneport",
	"hut", "dorm", "mega",
	"planter", "tree", "hedge", "lamp", "substation", "bench", "bikes", "flag", "robot", "battery", "foodtruck", "coffee", "turbine", "net_cab", "rack_row", "chiller", "generator", "transformer", "gpu_statue",
]

## Lab levels: lifetime tokens served needed, and the sparks each level brings.
const EMPIRE := [
	{"xp": 0, "gems": 0},
	{"xp": 50, "gems": 5},
	{"xp": 150, "gems": 5},
	{"xp": 650, "gems": 8},
	{"xp": 1300, "gems": 10},
	{"xp": 2600, "gems": 12},
	{"xp": 6500, "gems": 15},
	{"xp": 16000, "gems": 18},
	{"xp": 36000, "gems": 20},
	{"xp": 83000, "gems": 25},
	{"xp": 190000, "gems": 30},
	{"xp": 440000, "gems": 35},
	{"xp": 1.0e6, "gems": 40},
	{"xp": 2.3e6, "gems": 45},
	{"xp": 5.3e6, "gems": 60},
]

## Megacluster stages: money, frontier-token deliveries and build time.
const MEGA_STAGES := [
	{"name": "Groundbreaking", "cost": 2.0e8, "need": 0, "time": 28800},
	{"name": "Power Plant", "cost": 1.5e9, "need": 200, "time": 43200},
	{"name": "Cooling Halls", "cost": 9.0e9, "need": 600, "time": 86400},
	{"name": "GPU Halls", "cost": 5.0e10, "need": 1500, "time": 129600},
	{"name": "The Core", "cost": 1.6e11, "need": 4000, "time": 172800},
]
## The model whose tokens the Megacluster needs.
const MEGA_MODEL := "frontier"

## Obstacles on your land: clear them (money + a builder) for space and sparks.
const OBSTACLES := {
	"bush": {"name": "Bramble Bush", "size": Vector2i(1, 1), "time": 5},
	"rock": {"name": "Boulder", "size": Vector2i(1, 1), "time": 10},
	"ewaste": {"name": "E-Waste Pile", "size": Vector2i(1, 1), "time": 8},
	"oak": {"name": "Old Oak", "size": Vector2i(2, 2), "time": 20},
	"pine": {"name": "Tall Pine", "size": Vector2i(1, 1), "time": 15},
	"container": {"name": "Rusty Container", "size": Vector2i(2, 2), "time": 30},
}

# ---------------------------------------------------------------- staff
## Staff roles. Couriers carry everything along the roads (the broker picks
## the most useful job); technicians and engineers are assigned to one
## building and make it faster. Builders come with Builder's Huts.
const ROLES := {
	"courier": {
		"name": "Courier", "icon": "courier", "color": Color(0.3, 0.42, 0.62),
		"desc": "Carries resources and tokens along the roads to wherever they're needed.",
	},
	"tech": {
		"name": "Technician", "icon": "tech", "color": Color(0.94, 0.6, 0.22),
		"desc": "Works one source. Every technician makes it faster.", "assign": "source",
	},
	"engineer": {
		"name": "Engineer", "icon": "engineer", "color": Color(0.36, 0.3, 0.5),
		"desc": "Works one server or lab, making it faster.", "assign": "machine",
	},
}
const ROLE_ORDER: Array[String] = ["courier", "tech", "engineer"]

# ---------------------------------------------------------------- land
## Biomes per land chunk; sources of the listed resources work 40% faster
## there (cheap sun in the desert, free cooling up north, talent in the valley,
## ore in the hills).
const BIOMES := {
	"valley": {"name": "Tech Valley", "bonus": ["data", "code", "labels", "feedback"], "grass": Color(0.5, 0.62, 0.4)},
	"desert": {"name": "Sun Desert", "bonus": ["power", "silicon"], "grass": Color(0.88, 0.76, 0.52)},
	"tundra": {"name": "Cold North", "bonus": ["coolant", "fiber", "papers"], "grass": Color(0.8, 0.85, 0.85)},
	"highland": {"name": "Mining Hills", "bonus": ["copper", "rare", "experts"], "grass": Color(0.56, 0.56, 0.42)},
}
const BIOME_ORDER: Array[String] = ["valley", "desert", "tundra", "highland"]

## The village turns into a datacenter as your lab grows: each era starts at
## a Lab level and changes the ground, the roads, the street furniture and
## the skyline (see render/ground.gdshader and Terrain).
const ERAS := [
	{"level": 1, "name": "Garage", "icon": "server", "desc": "Grass, cobbles and a gaming PC."},
	{"level": 3, "name": "Startup Campus", "icon": "desk", "desc": "Concrete aprons, paver paths, an asphalt High Street and smart lamps."},
	{"level": 6, "name": "Data Park", "icon": "substation", "desc": "Your land is paved, power pylons march along the street."},
	{"level": 9, "name": "Hyperscale", "icon": "cache", "desc": "Raised-floor tiles, LED lane lines, datacenter halls on the horizon."},
	{"level": 12, "name": "Megacluster", "icon": "mega", "desc": "A circuit-board floor with light pulsing along its traces."},
]


## The era for a Lab level (0..4).
static func era_for(lvl: int) -> int:
	var e := 0
	for i in ERAS.size():
		if lvl >= int(ERAS[i]["level"]):
			e = i
	return e


## Titles for each Lab level.
const LEVEL_TITLES := [
	"Garage Lab", "Home Lab", "Weekend Project", "Seed Startup", "Series A",
	"Series B", "Scale-up", "Unicorn", "AI Lab", "Frontier Lab",
	"Hyperscaler", "Tech Giant", "Global Platform", "Compute Superpower", "AGI Pioneer",
]


static func item_name(t: String) -> String:
	if is_product(t):
		var r := recipe(t.substr(2))
		var n: String = r.get("name", "Model")
		match t[0]:
			"b": return n + " Batch"
			"a": return n + " Agent"
		return n + " Tokens"
	return ITEMS[t]["name"] if ITEMS.has(t) else t


## Short product name without the suffix ("Chat 7B").
static func model_name(id: String) -> String:
	return str(recipe(id).get("name", id))


## "raw" | "proc" | "token" | "batch" | "agent"
static func cat(t: String) -> String:
	if is_product(t):
		match t[0]:
			"t": return "token"
			"b": return "batch"
			"a": return "agent"
	return "proc" if PROCESSED.has(t) else "raw"


static func is_ingredient(t: String) -> bool:
	return ITEMS.has(t)


static func is_product(t: String) -> bool:
	return t.length() > 2 and t[1] == ":"


static func recipe_of(t: String) -> String:
	return t.substr(2) if is_product(t) else ""


static func recipe(id: String) -> Dictionary:
	for r in RECIPES:
		if r["id"] == id:
			return r
	return {}


## Tokens a product stands for (a batch and an agent run hold 6).
static func token_count(t: String) -> int:
	match cat(t):
		"token": return 1
		"batch", "agent": return 6
	return 0


static func item_height(t: String) -> float:
	match cat(t):
		"token": return TOKEN_H
		"batch": return BATCH_H
		"agent": return AGENT_H
	return ITEMS[t]["h"] if ITEMS.has(t) else 0.2


static func item_color(t: String) -> Color:
	if is_product(t):
		return MODEL_LOOK.get(recipe_of(t), {"base": Color(0.5, 0.7, 0.9)})["base"]
	return ITEMS[t]["color"] if ITEMS.has(t) else Color.WHITE


static func item_icon(t: String) -> String:
	match cat(t):
		"token": return "tk_" + recipe_of(t)
		"batch": return "batch"
		"agent": return "agent"
	return t


static func level_title(lvl: int) -> String:
	return LEVEL_TITLES[clampi(lvl - 1, 0, LEVEL_TITLES.size() - 1)]


## Which building produces a resource ("" for none).
static func producer_of(ing: String) -> String:
	for k in BUILDINGS:
		var d: Dictionary = BUILDINGS[k]
		if d.get("res", "") == ing:
			return k
		if d.has("out") and (d["out"] as Dictionary).has(ing):
			return k
	return ""


static func size_of(kind: String) -> Vector2i:
	return BUILDINGS[kind]["size"]


## Most copies of a building you can own (-1 = unlimited).
static func limit_of(kind: String) -> int:
	return int(BUILDINGS[kind].get("limit", -1))


## Module bays a server has at level l (one resource each).
static func server_slots(l: int) -> int:
	return clampi(1 + (l - 1) / 3, 1, 7)


## Server level needed for a model with n resources.
static func slots_level(n: int) -> int:
	return maxi(1, (n - 1) * 3 + 1)


static func is_instant(kind: String) -> bool:
	return int(BUILDINGS[kind].get("time", 0)) <= 0 and BUILDINGS[kind]["cat"] == "decor"
