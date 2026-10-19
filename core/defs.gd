class_name Defs
## Static game definitions: resources, models, buildings, staff roles, biomes.
## Everything data-like lives here or in Bal so new content is a table entry.
##
## Token Empire follows the AI supply chain (see DESIGN.md): sources make
## raw resources (power, coolant, silicon, web data, labels...), labs turn
## them into hardware and training data (GPUs, HBM, datasets, fine-tunes...),
## servers fitted with GPUs serve the models you own to customers who call
## your API, and a Training Cluster turns data into new models.
##
## Item ids (things couriers carry):
##   resources      "power", "gpu", ...             (raw from sources, refined in labs)
## Model ids ("pico", "chat7"...) name models; "t:<model>" is only used to
## draw a model's token (icons, signs).

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

## Models (see DESIGN.md). Inference doesn't use data: a model is a set of
## weights that needs enough VRAM on a server; the server then turns GPU
## time and power into tokens. Amounts are in thousands of tokens (K):
##   vram    GB a server needs to load it
##   tps     K tokens/s one GPU serves of it
##   price   $ per K tokens
##   demand  K tokens/s its market wants at Lab level 1 (before channels)
##   open    licence to download open weights ($), -1 = train it yourself
##   train   training data the Training Cluster needs, compute = GPU-seconds
##   agent   agents can use it (Agent Hub demand)
const RECIPES := [
	{"id": "pico", "name": "Pico 1B", "params": "1B", "lat": 15, "tag": "Runs on a gaming GPU. Tiny, local, instant.", "vram": 2, "tps": 1.0, "price": 3.0, "demand": 0.6, "open": 0, "train": {}, "compute": 0, "agent": false},
	{"id": "mini", "name": "Mini 3B", "params": "3B", "lat": 22, "tag": "Open weights. Knows a little about everything on the web.", "vram": 6, "tps": 0.8, "price": 6.0, "demand": 0.6, "open": 40, "train": {}, "compute": 0, "agent": false},
	{"id": "chat7", "name": "Chat 7B", "params": "7B", "lat": 35, "tag": "Open weights. A friendly chat model.", "vram": 16, "tps": 0.6, "price": 11.0, "demand": 0.6, "open": 400, "train": {}, "compute": 0, "agent": false},
	{"id": "chat13", "name": "Chat 13B", "params": "13B", "lat": 55, "tag": "Your first own model. Bigger, smarter, needs a real GPU.", "vram": 28, "tps": 0.45, "price": 17.0, "demand": 0.5, "open": -1, "train": {"dataset": 20}, "compute": 600, "agent": false},
	{"id": "wiki13", "name": "Wiki 13B", "params": "13B", "lat": 60, "tag": "Trained on clean, labelled data. Fewer made-up facts.", "vram": 28, "tps": 0.45, "price": 24.0, "demand": 0.4, "open": -1, "train": {"dataset": 30, "labels": 10}, "compute": 900, "agent": false},
	{"id": "code13", "name": "Code 13B", "params": "13B", "lat": 60, "tag": "Writes code, fixes bugs, explains regex.", "vram": 28, "tps": 0.42, "price": 30.0, "demand": 0.4, "open": -1, "train": {"dataset": 15, "code": 30}, "compute": 900, "agent": false},
	{"id": "tool30", "name": "Tool 30B", "params": "30B", "lat": 80, "tag": "Calls tools and APIs on its own. Agents love it.", "vram": 64, "tps": 0.35, "price": 38.0, "demand": 0.35, "open": -1, "train": {"dataset": 30, "code": 25, "finetune": 8}, "compute": 2400, "agent": true},
	{"id": "vision70", "name": "Vision 70B", "params": "70B", "lat": 110, "tag": "Sees images, reads charts.", "vram": 150, "tps": 0.3, "price": 48.0, "demand": 0.3, "open": -1, "train": {"data": 60, "dataset": 50, "labels": 30}, "compute": 6000, "agent": false},
	{"id": "assist70", "name": "Assist 70B", "params": "70B", "lat": 110, "tag": "Fine-tuned to follow instructions.", "vram": 150, "tps": 0.28, "price": 60.0, "demand": 0.3, "open": -1, "train": {"dataset": 50, "finetune": 30}, "compute": 6000, "agent": true},
	{"id": "code70", "name": "Code 70B", "params": "70B", "lat": 120, "tag": "Ships whole features. Writes the tests too.", "vram": 150, "tps": 0.25, "price": 80.0, "demand": 0.3, "open": -1, "train": {"code": 80, "finetune": 25, "dataset": 40}, "compute": 8000, "agent": true},
	{"id": "align70", "name": "Aligned 70B", "params": "70B", "lat": 120, "tag": "Helpful, honest, harmless, tuned on feedback.", "vram": 150, "tps": 0.24, "price": 98.0, "demand": 0.25, "open": -1, "train": {"finetune": 30, "feedback": 40}, "compute": 9000, "agent": false},
	{"id": "long120", "name": "Long 120B", "params": "120B", "lat": 180, "tag": "A million tokens of context. Needs a lot of memory.", "vram": 260, "tps": 0.2, "price": 125.0, "demand": 0.25, "open": -1, "train": {"dataset": 100, "papers": 10, "hbm": 4}, "compute": 16000, "agent": false},
	{"id": "reason200", "name": "Reason 200B", "params": "200B", "lat": 260, "tag": "Thinks step by step before it answers.", "vram": 420, "tps": 0.16, "price": 170.0, "demand": 0.2, "open": -1, "train": {"dataset": 120, "papers": 30, "reward": 15}, "compute": 30000, "agent": true},
	{"id": "sage400", "name": "Sage 400B", "params": "400B", "lat": 320, "tag": "Polished by reinforcement learning from feedback.", "vram": 820, "tps": 0.13, "price": 220.0, "demand": 0.2, "open": -1, "train": {"reward": 50, "finetune": 50, "dataset": 120}, "compute": 60000, "agent": true},
	{"id": "omni400", "name": "Omni 400B", "params": "400B", "lat": 340, "tag": "Text, images, audio and video, all at once.", "vram": 860, "tps": 0.12, "price": 270.0, "demand": 0.2, "open": -1, "train": {"dataset": 150, "labels": 60, "fiber": 30}, "compute": 70000, "agent": true},
	{"id": "moe", "name": "Expert MoE", "params": "8x220B", "lat": 300, "tag": "A mixture of experts: huge, yet fast. Trained on synthetic data.", "vram": 1000, "tps": 0.12, "price": 340.0, "demand": 0.18, "open": -1, "train": {"synth": 60, "papers": 40, "dataset": 150}, "compute": 80000, "agent": true},
	{"id": "frontier", "name": "Frontier 1T", "params": "1T", "lat": 450, "tag": "The best model in the world. For now.", "vram": 1800, "tps": 0.08, "price": 600.0, "demand": 0.15, "open": -1, "train": {"synth": 100, "reward": 80, "papers": 60, "experts": 60, "dataset": 250}, "compute": 200000, "agent": true},
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
	["sell", "Customers", "gateway"],
	["space", "Space", "launchpad"],
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
		"desc": "Panels charge power cells. Every GPU burns power while it serves."},
	"src_data": {"name": "Web Crawler", "cat": "source", "tab": "source", "icon": "src_data", "res": "data", "size": Vector2i(3, 3), "cost": 40, "growth": 2.2, "up": 18, "max": 60, "time": 5,
		"desc": "Crawls the web for text: the raw material of training."},
	"src_coolant": {"name": "Cooling Tower", "cat": "source", "tab": "source", "icon": "src_coolant", "res": "coolant", "size": Vector2i(3, 3), "cost": 120, "growth": 2.2, "up": 30, "max": 60, "time": 10,
		"desc": "Chills coolant. Servers with real GPUs run hot: without coolant they throttle."},
	"src_silicon": {"name": "Silicon Works", "cat": "source", "tab": "source", "icon": "src_silicon", "res": "silicon", "size": Vector2i(3, 3), "cost": 250, "growth": 2.2, "up": 45, "max": 60, "time": 20,
		"desc": "Melts sand and pulls pure silicon crystals, for chips and memory."},
	"src_copper": {"name": "Copper Mine", "cat": "source", "tab": "source", "icon": "src_copper", "res": "copper", "size": Vector2i(3, 3), "cost": 400, "growth": 2.2, "up": 70, "max": 60, "time": 30,
		"desc": "Copper for the wiring inside every chip."},
	"src_code": {"name": "Code Commons", "cat": "source", "tab": "source", "icon": "src_code", "res": "code", "size": Vector2i(3, 3), "cost": 1500, "growth": 2.2, "up": 250, "max": 60, "time": 60,
		"desc": "Open-source developers write code, to train coding models."},
	"src_labels": {"name": "Labeling Studio", "cat": "source", "tab": "source", "icon": "src_labels", "res": "labels", "size": Vector2i(3, 3), "cost": 3000, "growth": 2.2, "up": 600, "max": 60, "time": 90,
		"desc": "People label examples, for training and the fine-tune lab."},
	"src_feedback": {"name": "Feedback Lounge", "cat": "source", "tab": "source", "icon": "src_feedback", "res": "feedback", "size": Vector2i(3, 3), "cost": 12000, "growth": 2.2, "up": 2200, "max": 60, "time": 300,
		"desc": "Raters compare answers and say which is better."},
	"src_rare": {"name": "Rare Earth Mine", "cat": "source", "tab": "source", "icon": "src_rare", "res": "rare", "size": Vector2i(3, 3), "cost": 30000, "growth": 2.2, "up": 5000, "max": 60, "time": 600,
		"desc": "Glittering rare earths for memory chips. Decor nearby keeps the miners happy."},
	"src_papers": {"name": "Research Campus", "cat": "source", "tab": "source", "icon": "src_papers", "res": "papers", "size": Vector2i(3, 3), "cost": 150000, "growth": 2.2, "up": 30000, "max": 60, "time": 1200,
		"desc": "Researchers turn ideas into papers. Precious."},
	"src_fiber": {"name": "Fiber Hub", "cat": "source", "tab": "source", "icon": "src_fiber", "res": "fiber", "size": Vector2i(3, 3), "cost": 1.2e6, "growth": 2.2, "up": 2.8e5, "max": 60, "time": 1800,
		"desc": "Spools of fibre: install them in API Gateways for bandwidth, or train multimodal models."},
	"src_experts": {"name": "Expert Network", "cat": "source", "tab": "source", "icon": "src_experts", "res": "experts", "size": Vector2i(3, 3), "cost": 6.0e6, "growth": 2.2, "up": 1.6e6, "max": 60, "time": 3600,
		"desc": "Doctors, lawyers and professors write expert examples."},

	# ---- compute: inference servers and the training cluster
	"server": {"name": "Inference Server", "cat": "server", "tab": "server", "icon": "server", "size": Vector2i(5, 3), "cost": 400, "growth": 6.0, "up": 40, "max": 40, "time": 10,
		"desc": "Answers API calls with the model you load. Couriers slot in GPUs and HBM (more speed, more memory) and keep it fed with power and coolant. Engineers tune it."},
	"trainer": {"name": "Training Cluster", "cat": "train", "tab": "server", "icon": "trainer", "size": Vector2i(4, 4), "cost": 500, "growth": 3.0, "up": 80, "max": 40, "time": 60,
		"desc": "Trains new models from data, and refreshes old ones. Couriers bring the data; its GPUs do the maths."},

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
		"desc": "Stores resources close to where they're needed: spare GPUs, datasets, power cells."},
	"gateway": {"name": "API Gateway", "cat": "sell", "tab": "sell", "icon": "gateway", "size": Vector2i(2, 3), "cost": 300, "growth": 3.0, "up": 45, "max": 50, "time": 10,
		"desc": "Where developers' API calls come in: more customers, and the bandwidth to answer them. Install fiber spools for more bandwidth."},
	"cafe": {"name": "Chat Café", "cat": "sell", "tab": "sell", "icon": "cafe", "size": Vector2i(3, 2), "cost": 500, "growth": 3.0, "up": 75, "max": 50, "time": 60,
		"desc": "People drop in to chat with your models live and pay 30% more, more for snappy models. Decor nearby brings more of them."},
	"desk": {"name": "Enterprise Desk", "cat": "sell", "tab": "sell", "icon": "desk", "size": Vector2i(2, 1), "limit": 1, "cost": 800, "growth": 1.0, "up": 0, "max": 1, "time": 120,
		"desc": "Enterprise contracts: serve their tokens through your API for big rewards and sparks."},
	"edge": {"name": "Edge PoP", "cat": "sell", "tab": "sell", "icon": "edge", "size": Vector2i(3, 3), "cost": 20000, "growth": 3.0, "up": 3500, "max": 50, "time": 3600,
		"desc": "A point of presence near your customers: lower latency for every model, and customers in new regions."},
	"agent_hub": {"name": "Agent Hub", "cat": "sell", "tab": "sell", "icon": "agent_hub", "size": Vector2i(3, 3), "cost": 2.0e6, "growth": 3.0, "up": 4.0e5, "max": 50, "time": 7200,
		"desc": "AI agents run long jobs on tool-capable models (Tool 30B and up), paying double per token."},

	# ---- space
	"launchpad": {"name": "Launch Complex", "cat": "space", "tab": "space", "icon": "launchpad", "size": Vector2i(4, 4), "cost": 5.0e7, "growth": 3.0, "up": 1.0e7, "max": 20, "time": 7200,
		"desc": "Assembles orbital server modules (24 GPUs, 8 HBM, 60 power cells) and launches them. In orbit: free solar power and cooling, a little more latency."},
	"groundstation": {"name": "Ground Station", "cat": "space", "tab": "space", "icon": "groundstation", "size": Vector2i(3, 3), "cost": 2.0e7, "growth": 2.5, "up": 4.0e6, "max": 30, "time": 3600,
		"desc": "Big dishes that link your orbital datacenter: each carries the bandwidth of a few modules."},

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
	# ---- exclusive decor: earned (streaks, quests, the League, the Lab Pass, Community Day), see LiveDefs.EXCLUSIVE
	"neon_sign": {"name": "Neon Token Sign", "cat": "decor", "tab": "decor", "icon": "neon_sign", "size": Vector2i(1, 1), "limit": 1, "cost": 500, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.06}, "desc": "A glowing token on a post. Cafés within 3 tiles get 6% more visitors."},
	"holo_bot": {"name": "Hologram Assistant", "cat": "decor", "tab": "decor", "icon": "holo_bot", "size": Vector2i(1, 1), "limit": 1, "cost": 2000, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "walk", "r": 4, "v": 0.15}, "desc": "A friendly hologram points the way. Staff within 4 tiles move 15% faster."},
	"server_fountain": {"name": "Liquid-Cooled Fountain", "cat": "decor", "tab": "decor", "icon": "server_fountain", "size": Vector2i(2, 2), "limit": 1, "cost": 5000, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 5, "v": 0.15}, "desc": "Coolant that sparkles. Cafés within 5 tiles get 15% more visitors."},
	"trophy": {"name": "Benchmark Trophy", "cat": "decor", "tab": "decor", "icon": "trophy", "size": Vector2i(1, 1), "limit": 1, "cost": 3000, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 5, "v": 0.15}, "desc": "Proof you topped the leaderboard. Servers and labs within 5 tiles work 15% faster."},
	"streak_flame": {"name": "Eternal Flame", "cat": "decor", "tab": "decor", "icon": "flame", "size": Vector2i(1, 1), "limit": 1, "cost": 3000, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "source", "r": 4, "v": 0.2}, "desc": "Lit by a 30-day streak. Sources within 4 tiles work 20% faster."},
	"quantum_core": {"name": "Quantum Core", "cat": "decor", "tab": "decor", "icon": "quantum_core", "size": Vector2i(2, 2), "limit": 1, "cost": 20000, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "compute", "r": 6, "v": 0.3}, "desc": "A breakthrough in a box. Servers and labs within 6 tiles work 30% faster."},
	"gpu_statue": {"name": "Golden GPU", "cat": "decor", "tab": "decor", "icon": "gpu_statue", "size": Vector2i(2, 2), "cost": 1.3e6, "growth": 4.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "global_price", "r": 0, "v": 0.05}, "desc": "Every token in the empire sells for 5% more."},

	# ---- the wonder
	"mega": {"name": "AGI Megacluster", "cat": "wonder", "tab": "town", "icon": "mega", "size": Vector2i(5, 5), "limit": 1, "cost": 2.0e8, "growth": 1.0, "up": 0, "max": 1, "time": 28800,
		"desc": "The crown of your empire. Build it in five stages to win."},
}

## Order of cards in the build menu.
const BUILD_ORDER: Array[String] = [
	"src_power", "src_data", "src_coolant", "src_silicon", "src_copper", "src_code", "src_labels", "src_feedback", "src_rare", "src_papers", "src_fiber", "src_experts",
	"server", "trainer", "fab", "refinery", "tune_lab", "hbm_works", "rlhf_gym", "synth_lab",
	"depot",
	"gateway", "cafe", "desk", "edge", "agent_hub",
	"launchpad", "groundstation",
	"hut", "dorm", "mega",
	"planter", "tree", "hedge", "lamp", "substation", "bench", "bikes", "flag", "robot", "battery", "foodtruck", "coffee", "turbine", "net_cab", "rack_row", "chiller", "generator", "transformer", "gpu_statue",
	"neon_sign", "holo_bot", "server_fountain", "trophy", "streak_flame", "quantum_core",
]

## Lab levels: lifetime tokens served needed, and the sparks each level brings.
const EMPIRE := [
	{"xp": 0, "gems": 0},
	{"xp": 50, "gems": 5},
	{"xp": 150, "gems": 5},
	{"xp": 900, "gems": 8},
	{"xp": 2000, "gems": 10},
	{"xp": 4500, "gems": 12},
	{"xp": 12000, "gems": 15},
	{"xp": 32000, "gems": 18},
	{"xp": 75000, "gems": 20},
	{"xp": 170000, "gems": 25},
	{"xp": 400000, "gems": 30},
	{"xp": 900000, "gems": 35},
	{"xp": 2.0e6, "gems": 40},
	{"xp": 4.6e6, "gems": 45},
	{"xp": 1.05e7, "gems": 60},
]

## Megacluster stages: money, frontier-token deliveries and build time.
const MEGA_STAGES := [
	{"name": "Groundbreaking", "cost": 2.0e8, "need": 0, "time": 28800},
	{"name": "Power Plant", "cost": 1.5e9, "need": 20000, "time": 43200},
	{"name": "Cooling Halls", "cost": 9.0e9, "need": 60000, "time": 86400},
	{"name": "GPU Halls", "cost": 5.0e10, "need": 150000, "time": 129600},
	{"name": "The Core", "cost": 1.6e11, "need": 400000, "time": 172800},
]
## The model whose tokens (K, served while a stage waits) the Megacluster needs.
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
	{"level": 9, "name": "Hyperscale", "icon": "rack_row", "desc": "Raised-floor tiles, LED lane lines, datacenter halls on the horizon."},
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


static func is_instant(kind: String) -> bool:
	return int(BUILDINGS[kind].get("time", 0)) <= 0 and BUILDINGS[kind]["cat"] == "decor"
