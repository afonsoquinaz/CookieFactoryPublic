class_name Defs
## Static game definitions: items, recipes, buildings, worker roles, biomes.
## Everything data-like lives here or in Bal so new content is a table entry.
##
## Item ids:
##   ingredients    "wheat", "butter", ...            (raw from farms, processed in kitchens)
##   cookies        "c:<recipe>"   e.g. "c:choc"
##   cookie boxes   "b:<recipe>"   (6 cookies, packed)
##   gift boxes     "g:<recipe>"   (a wrapped box)

const RAW: Array[String] = ["wheat", "sugar", "cocoa", "egg", "milk", "oats", "berry", "hazelnut", "honey", "vanilla", "cinnamon", "orange"]
const PROCESSED: Array[String] = ["butter", "chocolate", "jam", "caramel", "praline", "candied"]

## h = stacking height (m) in a carry column.
const ITEMS := {
	"wheat": {"name": "Wheat", "h": 0.2, "color": Color(0.86, 0.7, 0.38)},
	"sugar": {"name": "Sugar Cane", "h": 0.18, "color": Color(0.6, 0.7, 0.42)},
	"cocoa": {"name": "Cocoa Pods", "h": 0.2, "color": Color(0.7, 0.42, 0.26)},
	"egg": {"name": "Eggs", "h": 0.19, "color": Color(0.9, 0.84, 0.72)},
	"milk": {"name": "Milk", "h": 0.31, "color": Color(0.62, 0.72, 0.8)},
	"oats": {"name": "Oats", "h": 0.22, "color": Color(0.84, 0.76, 0.56)},
	"berry": {"name": "Strawberries", "h": 0.18, "color": Color(0.82, 0.3, 0.3)},
	"hazelnut": {"name": "Hazelnuts", "h": 0.17, "color": Color(0.62, 0.42, 0.26)},
	"honey": {"name": "Honey", "h": 0.26, "color": Color(0.92, 0.66, 0.2)},
	"vanilla": {"name": "Vanilla", "h": 0.14, "color": Color(0.36, 0.26, 0.2)},
	"cinnamon": {"name": "Cinnamon", "h": 0.15, "color": Color(0.66, 0.38, 0.22)},
	"orange": {"name": "Oranges", "h": 0.2, "color": Color(0.94, 0.56, 0.2)},
	"butter": {"name": "Butter", "h": 0.16, "color": Color(0.97, 0.88, 0.52)},
	"chocolate": {"name": "Chocolate", "h": 0.1, "color": Color(0.36, 0.22, 0.15)},
	"jam": {"name": "Jam", "h": 0.24, "color": Color(0.72, 0.16, 0.22)},
	"caramel": {"name": "Caramel", "h": 0.14, "color": Color(0.82, 0.52, 0.22)},
	"praline": {"name": "Praline", "h": 0.13, "color": Color(0.46, 0.3, 0.2)},
	"candied": {"name": "Candied Orange", "h": 0.12, "color": Color(0.95, 0.6, 0.25)},
}

## Cookie recipes. A Bakery bakes the recipe you choose (or the best one you
## can make); every recipe needs wheat plus its ingredients, one silo each.
## Order = how they unlock (each needs its ingredients' buildings).
const RECIPES := [
	{"id": "shortbread", "name": "Shortbread", "ings": [], "price": 3.0},
	{"id": "sugar", "name": "Sugar Cookie", "ings": ["sugar"], "price": 6.0},
	{"id": "cocoa", "name": "Cocoa Crinkle", "ings": ["sugar", "cocoa"], "price": 11.0},
	{"id": "milk", "name": "Milk Biscuit", "ings": ["sugar", "egg", "milk"], "price": 17.0},
	{"id": "butter", "name": "Butter Ring", "ings": ["sugar", "egg", "butter"], "price": 24.0},
	{"id": "choc", "name": "Chocolate Chip", "ings": ["sugar", "egg", "chocolate"], "price": 30.0},
	{"id": "oat", "name": "Oat Crumble", "ings": ["sugar", "oats", "butter"], "price": 38.0},
	{"id": "double", "name": "Double Chocolate", "ings": ["sugar", "egg", "cocoa", "chocolate"], "price": 48.0},
	{"id": "jam", "name": "Jam Thumbprint", "ings": ["sugar", "butter", "jam"], "price": 60.0},
	{"id": "hazel", "name": "Hazelnut Crunch", "ings": ["sugar", "egg", "hazelnut", "chocolate"], "price": 80.0},
	{"id": "honey", "name": "Honey Oat", "ings": ["oats", "honey", "butter", "egg"], "price": 98.0},
	{"id": "caramel", "name": "Caramel Stroopwafel", "ings": ["sugar", "egg", "butter", "caramel"], "price": 125.0},
	{"id": "vanilla", "name": "Vanilla Sablé", "ings": ["sugar", "egg", "butter", "milk", "vanilla"], "price": 170.0},
	{"id": "praline", "name": "Praline Dream", "ings": ["sugar", "egg", "butter", "chocolate", "praline"], "price": 220.0},
	{"id": "cinnamon", "name": "Cinnamon Swirl", "ings": ["sugar", "egg", "butter", "milk", "cinnamon"], "price": 270.0},
	{"id": "florentine", "name": "Orange Florentine", "ings": ["honey", "hazelnut", "chocolate", "candied"], "price": 340.0},
	{"id": "royal", "name": "Royal Empire", "ings": ["sugar", "egg", "butter", "milk", "vanilla", "praline", "caramel"], "price": 600.0},
]

## Cookie looks (dough tone, top colour, decoration style) per recipe.
const COOKIE_LOOK := {
	"shortbread": {"base": Color(0.93, 0.8, 0.55), "deco": "pricks", "shape": "square"},
	"sugar": {"base": Color(0.95, 0.84, 0.62), "deco": "sparkle", "shape": "round"},
	"cocoa": {"base": Color(0.38, 0.24, 0.17), "deco": "crinkle", "shape": "round"},
	"milk": {"base": Color(0.97, 0.9, 0.74), "deco": "flower", "shape": "round"},
	"butter": {"base": Color(0.94, 0.78, 0.48), "deco": "ring", "shape": "ring"},
	"choc": {"base": Color(0.86, 0.64, 0.38), "deco": "chips", "shape": "round"},
	"oat": {"base": Color(0.8, 0.62, 0.4), "deco": "oats", "shape": "rustic"},
	"double": {"base": Color(0.3, 0.19, 0.13), "deco": "white_chips", "shape": "round"},
	"jam": {"base": Color(0.93, 0.78, 0.52), "deco": "jam", "shape": "round"},
	"hazel": {"base": Color(0.78, 0.56, 0.34), "deco": "nuts", "shape": "round"},
	"honey": {"base": Color(0.86, 0.64, 0.32), "deco": "glaze", "shape": "rustic"},
	"caramel": {"base": Color(0.86, 0.62, 0.34), "deco": "waffle", "shape": "flat"},
	"vanilla": {"base": Color(0.97, 0.88, 0.7), "deco": "specks", "shape": "round"},
	"praline": {"base": Color(0.62, 0.42, 0.28), "deco": "swirl", "shape": "round"},
	"cinnamon": {"base": Color(0.86, 0.64, 0.42), "deco": "spiral", "shape": "round"},
	"florentine": {"base": Color(0.86, 0.58, 0.26), "deco": "lace", "shape": "flat"},
	"royal": {"base": Color(0.98, 0.95, 0.88), "deco": "royal", "shape": "round"},
}

const COOKIE_H := 0.085
const BOX_H := 0.26
const GIFT_H := 0.34

# ---------------------------------------------------------------- buildings
## size = footprint in grid cells (Grid.CELL m), x = width, y = depth (front
## faces +Z when unrotated; the entrance is the cell in front of the middle of
## the front edge, where the road arrives).
## hall = Cookie Hall level that unlocks it; n = Hall levels at which each copy
## unlocks (n = [1, 4] -> one at Hall 1, a second at Hall 4; no n = unlimited).
## cost = first purchase, growth = price factor per copy you already own;
## gems = price in gems instead (builder huts). up = upgrade cost 1 -> 2,
## max = top level (also capped by the Hall), time = seconds to build it.
const TABS := [
	["farm", "Farms", "farm"],
	["bake", "Bakery", "bakery"],
	["pack", "Storage", "storage"],
	["sell", "Sales", "truck"],
	["town", "Town", "hall"],
	["decor", "Decor", "flowers"],
]

const FARM_TIERS: Array[int] = [1, 5, 10, 20, 35]
const MACHINE_TIERS: Array[int] = [1, 5, 12, 25, 40]
const BAKERY_TIERS: Array[int] = [1, 5, 12, 22, 32]
const HALL_TIERS: Array[int] = [1, 3, 6, 9, 12]

const BUILDINGS := {
	# ---- the heart of the empire
	"hall": {"name": "Cookie Hall", "cat": "hall", "tab": "town", "icon": "hall", "size": Vector2i(4, 4), "hall": 1, "n": [1], "cost": 0, "growth": 1.0, "up": 0, "max": 15, "time": 0,
		"desc": "Your headquarters. Upgrade it to unlock new buildings, more of each, and higher levels."},
	"hut": {"name": "Builder's Hut", "cat": "staff", "tab": "town", "icon": "builder", "size": Vector2i(2, 2), "hall": 1, "n": [1, 1, 3, 6, 9], "cost": 0, "growth": 1.0, "up": 0, "max": 1, "time": 0,
		"gems": [0, 0, 60, 150, 300], "desc": "Each hut houses a builder. More builders, more things built at once."},
	"cabin": {"name": "Staff Cabin", "cat": "staff", "tab": "town", "icon": "cabin", "size": Vector2i(2, 2), "hall": 2, "n": [2, 4, 6, 8, 10, 12, 14], "cost": 150, "growth": 2.5, "up": 90, "max": 20, "time": 30,
		"desc": "Houses more staff: porters, farmers and chefs."},

	# ---- farms (3x3)
	"farm_wheat": {"name": "Wheat Field", "cat": "farm", "tab": "farm", "icon": "wheat", "crop": "wheat", "size": Vector2i(3, 3), "hall": 1, "n": [1, 2, 4, 7, 10, 13], "cost": 30, "growth": 2.2, "up": 12, "max": 60, "time": 5,
		"desc": "Golden wheat. Every cookie starts with it."},
	"farm_sugar": {"name": "Sugar Cane Field", "cat": "farm", "tab": "farm", "icon": "sugar", "crop": "sugar", "size": Vector2i(3, 3), "hall": 1, "n": [1, 3, 6, 9, 12], "cost": 40, "growth": 2.2, "up": 18, "max": 60, "time": 5,
		"desc": "Sweetens every recipe after the first."},
	"farm_cocoa": {"name": "Cocoa Grove", "cat": "farm", "tab": "farm", "icon": "cocoa", "crop": "cocoa", "size": Vector2i(3, 3), "hall": 2, "n": [2, 5, 9, 13], "cost": 120, "growth": 2.2, "up": 30, "max": 60, "time": 10,
		"desc": "Cocoa pods for crinkles, and for chocolate."},
	"farm_egg": {"name": "Hen House", "cat": "farm", "tab": "farm", "icon": "egg", "crop": "egg", "size": Vector2i(3, 3), "hall": 3, "n": [3, 6, 10, 13], "cost": 250, "growth": 2.2, "up": 45, "max": 60, "time": 20,
		"desc": "Fresh eggs for richer doughs."},
	"farm_milk": {"name": "Dairy Barn", "cat": "farm", "tab": "farm", "icon": "milk", "crop": "milk", "size": Vector2i(3, 3), "hall": 3, "n": [3, 7, 11, 14], "cost": 400, "growth": 2.2, "up": 70, "max": 60, "time": 30,
		"desc": "Milk for biscuits, and for the butter churn."},
	"farm_oats": {"name": "Oat Field", "cat": "farm", "tab": "farm", "icon": "oats", "crop": "oats", "size": Vector2i(3, 3), "hall": 5, "n": [5, 8, 12], "cost": 1500, "growth": 2.2, "up": 250, "max": 60, "time": 60,
		"desc": "Hearty oats for crumbles."},
	"farm_berry": {"name": "Strawberry Patch", "cat": "farm", "tab": "farm", "icon": "berry", "crop": "berry", "size": Vector2i(3, 3), "hall": 6, "n": [6, 9, 13], "cost": 3000, "growth": 2.2, "up": 600, "max": 60, "time": 90,
		"desc": "Sweet berries for the jam kettle."},
	"farm_hazelnut": {"name": "Hazel Orchard", "cat": "farm", "tab": "farm", "icon": "hazelnut", "crop": "hazelnut", "size": Vector2i(3, 3), "hall": 7, "n": [7, 10, 14], "cost": 12000, "growth": 2.2, "up": 2200, "max": 60, "time": 300,
		"desc": "Crunchy hazelnuts."},
	"farm_honey": {"name": "Bee Meadow", "cat": "farm", "tab": "farm", "icon": "beehive", "crop": "honey", "size": Vector2i(3, 3), "hall": 8, "n": [8, 11, 14], "cost": 30000, "growth": 2.2, "up": 5000, "max": 60, "time": 600,
		"desc": "Hives make honey. Flower beds nearby make them busier."},
	"farm_vanilla": {"name": "Orchid Greenhouse", "cat": "farm", "tab": "farm", "icon": "greenhouse", "crop": "vanilla", "size": Vector2i(3, 3), "hall": 9, "n": [9, 12, 15], "cost": 150000, "growth": 2.2, "up": 30000, "max": 60, "time": 1200,
		"desc": "Precious vanilla pods."},
	"farm_cinnamon": {"name": "Spice Garden", "cat": "farm", "tab": "farm", "icon": "cinnamon", "crop": "cinnamon", "size": Vector2i(3, 3), "hall": 11, "n": [11, 13, 15], "cost": 1.2e6, "growth": 2.2, "up": 2.8e5, "max": 60, "time": 1800,
		"desc": "Cinnamon bark, warm and fragrant."},
	"farm_orange": {"name": "Orange Grove", "cat": "farm", "tab": "farm", "icon": "orange", "crop": "orange", "size": Vector2i(3, 3), "hall": 12, "n": [12, 14, 15], "cost": 6.0e6, "growth": 2.2, "up": 1.6e6, "max": 60, "time": 3600,
		"desc": "Sunny oranges for candied peel."},

	# ---- the bakery: one building, a whole production line inside
	"bakery": {"name": "Bakery", "cat": "bake", "tab": "bake", "icon": "bakery", "size": Vector2i(5, 3), "hall": 1, "n": [1, 4, 7, 10, 13], "cost": 400, "growth": 8.0, "up": 40, "max": 40, "time": 10,
		"desc": "Mixer, glass tube, ingredient silos and an oven in one. Choose what it bakes; upgrades add silos for richer recipes."},

	# ---- kitchens (2x2): turn ingredients into better ones
	"churn": {"name": "Butter Churn", "cat": "kitchen", "tab": "bake", "icon": "churn", "size": Vector2i(2, 2), "hall": 4, "n": [4, 8, 12], "cost": 600, "growth": 2.4, "up": 110, "max": 50, "time": 60,
		"in": {"milk": 2}, "out": {"butter": 1}, "craft": 3.0, "desc": "Milk becomes butter."},
	"chocolatier": {"name": "Chocolatier", "cat": "kitchen", "tab": "bake", "icon": "chocolatier", "size": Vector2i(2, 2), "hall": 4, "n": [4, 8, 12], "cost": 900, "growth": 2.4, "up": 170, "max": 50, "time": 90,
		"in": {"cocoa": 2, "sugar": 1}, "out": {"chocolate": 2}, "craft": 3.5, "desc": "Cocoa and sugar become chocolate."},
	"kettle": {"name": "Jam Kettle", "cat": "kitchen", "tab": "bake", "icon": "kettle", "size": Vector2i(2, 2), "hall": 6, "n": [6, 10, 14], "cost": 5000, "growth": 2.4, "up": 900, "max": 50, "time": 300,
		"in": {"berry": 2, "sugar": 1}, "out": {"jam": 1}, "craft": 4.0, "desc": "Strawberries and sugar become jam."},
	"caramel_pot": {"name": "Caramel Pot", "cat": "kitchen", "tab": "bake", "icon": "caramel_pot", "size": Vector2i(2, 2), "hall": 8, "n": [8, 12], "cost": 60000, "growth": 2.4, "up": 13000, "max": 50, "time": 900,
		"in": {"sugar": 2, "butter": 1}, "out": {"caramel": 1}, "craft": 4.5, "desc": "Sugar and butter become caramel."},
	"roaster": {"name": "Praline Roaster", "cat": "kitchen", "tab": "bake", "icon": "roaster", "size": Vector2i(2, 2), "hall": 10, "n": [10, 13], "cost": 400000, "growth": 2.4, "up": 75000, "max": 50, "time": 1800,
		"in": {"hazelnut": 2, "chocolate": 1}, "out": {"praline": 1}, "craft": 5.0, "desc": "Hazelnuts and chocolate become praline."},
	"candy": {"name": "Candy Kitchen", "cat": "kitchen", "tab": "bake", "icon": "candy", "size": Vector2i(2, 2), "hall": 12, "n": [12, 14], "cost": 1.0e7, "growth": 2.4, "up": 2.5e6, "max": 50, "time": 3600,
		"in": {"orange": 1, "sugar": 2}, "out": {"candied": 1}, "craft": 5.0, "desc": "Oranges and sugar become candied peel."},

	# ---- storage + packing (2x2)
	"pantry": {"name": "Pantry", "cat": "pack", "tab": "pack", "icon": "pantry", "size": Vector2i(2, 2), "hall": 2, "n": [2, 5, 8, 11], "cost": 200, "growth": 2.0, "up": 45, "max": 40, "time": 30,
		"desc": "Stores ingredients close to where they're needed."},
	"rack": {"name": "Cookie Rack", "cat": "pack", "tab": "pack", "icon": "rack", "size": Vector2i(2, 2), "hall": 3, "n": [3, 6, 9, 12], "cost": 300, "growth": 2.0, "up": 100, "max": 40, "time": 30,
		"desc": "Stores cookies, boxes and gifts until they're sold."},
	"packer": {"name": "Box Packer", "cat": "pack", "tab": "pack", "icon": "packer", "size": Vector2i(2, 2), "hall": 5, "n": [5, 9, 13], "cost": 2500, "growth": 2.4, "up": 400, "max": 50, "time": 300,
		"desc": "Packs 6 cookies into a box worth 25% more."},
	"wrapper": {"name": "Gift Wrapper", "cat": "pack", "tab": "pack", "icon": "wrapper", "size": Vector2i(2, 2), "hall": 9, "n": [9, 13], "cost": 200000, "growth": 2.4, "up": 48000, "max": 50, "time": 1800,
		"desc": "Wraps boxes into gifts worth 60% more."},

	# ---- sales
	"dock": {"name": "Delivery Van", "cat": "sell", "tab": "sell", "icon": "truck", "size": Vector2i(2, 3), "hall": 1, "n": [1, 3, 6, 9, 12], "cost": 300, "growth": 3.0, "up": 45, "max": 50, "time": 10,
		"desc": "Porters load cookies; the van drives off and sells them."},
	"shop": {"name": "Cookie Shop", "cat": "sell", "tab": "sell", "icon": "market", "size": Vector2i(3, 2), "hall": 2, "n": [2, 5, 8, 11], "cost": 500, "growth": 3.0, "up": 75, "max": 50, "time": 60,
		"desc": "Customers walk in and pay 30% more. Decor nearby brings more of them."},
	"board": {"name": "Order Board", "cat": "sell", "tab": "sell", "icon": "board", "size": Vector2i(2, 1), "hall": 4, "n": [4], "cost": 800, "growth": 1.0, "up": 0, "max": 1, "time": 120,
		"desc": "Special orders: deliver them for big rewards and gems."},
	"train": {"name": "Rail Depot", "cat": "sell", "tab": "sell", "icon": "train", "size": Vector2i(3, 3), "hall": 7, "n": [7, 11], "cost": 20000, "growth": 3.0, "up": 3500, "max": 50, "time": 3600,
		"desc": "A freight train takes huge loads to the city."},
	"airship": {"name": "Airship Mast", "cat": "sell", "tab": "sell", "icon": "airship", "size": Vector2i(3, 3), "hall": 11, "n": [11, 14], "cost": 2.0e7, "growth": 3.0, "up": 3.9e6, "max": 50, "time": 7200,
		"desc": "Flies gifts to royal courts: gifts sell for double."},

	# ---- decor (no builder needed; auras work in a radius of cells)
	"flowers": {"name": "Flower Bed", "cat": "decor", "tab": "decor", "icon": "flowers", "size": Vector2i(1, 1), "hall": 1, "cost": 25, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.04}, "desc": "Bee Meadows nearby make more honey. Shops nearby get more customers."},
	"tree": {"name": "Shade Tree", "cat": "decor", "tab": "decor", "icon": "tree", "size": Vector2i(1, 1), "hall": 1, "cost": 20, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.02}, "desc": "Pretty, and shops nearby get more customers."},
	"hedge": {"name": "Hedge", "cat": "decor", "tab": "decor", "icon": "hedge", "size": Vector2i(1, 1), "hall": 1, "cost": 12, "growth": 1.04, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 1, "v": 0.01}, "desc": "A neat hedge."},
	"lamp": {"name": "Street Lamp", "cat": "decor", "tab": "decor", "icon": "lamp", "size": Vector2i(1, 1), "hall": 2, "cost": 30, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.03}, "desc": "Warm light. Shops nearby get more customers."},
	"well": {"name": "Well", "cat": "decor", "tab": "decor", "icon": "well", "size": Vector2i(1, 1), "hall": 2, "cost": 90, "growth": 1.8, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "farm", "r": 3, "v": 0.2}, "desc": "Farms within 3 tiles work 20% faster."},
	"bench": {"name": "Bench", "cat": "decor", "tab": "decor", "icon": "bench", "size": Vector2i(1, 1), "hall": 2, "cost": 40, "growth": 1.06, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.03}, "desc": "Shops nearby get more customers."},
	"picnic": {"name": "Picnic Table", "cat": "decor", "tab": "decor", "icon": "picnic", "size": Vector2i(1, 1), "hall": 3, "cost": 60, "growth": 1.08, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.03}, "desc": "Shops nearby get more customers."},
	"banner": {"name": "Banner", "cat": "decor", "tab": "decor", "icon": "banner", "size": Vector2i(1, 1), "hall": 4, "cost": 90, "growth": 1.08, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 3, "v": 0.04}, "desc": "Your colours. Shops nearby get more customers."},
	"topiary": {"name": "Topiary", "cat": "decor", "tab": "decor", "icon": "topiary", "size": Vector2i(1, 1), "hall": 5, "cost": 140, "growth": 1.08, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 2, "v": 0.04}, "desc": "A tidy round bush. Shops nearby get more customers."},
	"pond": {"name": "Pond", "cat": "decor", "tab": "decor", "icon": "pond", "size": Vector2i(2, 2), "hall": 6, "cost": 900, "growth": 1.5, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "farm", "r": 3, "v": 0.12}, "desc": "Farms within 3 tiles work 12% faster."},
	"gazebo": {"name": "Gazebo", "cat": "decor", "tab": "decor", "icon": "gazebo", "size": Vector2i(2, 2), "hall": 7, "cost": 2500, "growth": 1.6, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "charm", "r": 5, "v": 0.12}, "desc": "Shops within 5 tiles get 12% more customers."},
	"fountain": {"name": "Fountain", "cat": "decor", "tab": "decor", "icon": "fountain", "size": Vector2i(2, 2), "hall": 8, "cost": 1800, "growth": 2.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "walk", "r": 5, "v": 0.2}, "desc": "Staff within 5 tiles walk 20% faster. Shops love it."},
	"windmill": {"name": "Windmill", "cat": "decor", "tab": "decor", "icon": "windmill", "size": Vector2i(2, 2), "hall": 9, "cost": 15000, "growth": 1.9, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "farm", "r": 5, "v": 0.25}, "desc": "Farms within 5 tiles work 25% faster."},
	"statue": {"name": "Golden Cookie Statue", "cat": "decor", "tab": "decor", "icon": "statue", "size": Vector2i(2, 2), "hall": 13, "cost": 1.3e6, "growth": 4.0, "up": 0, "max": 1, "time": 0,
		"aura": {"what": "global_price", "r": 0, "v": 0.05}, "desc": "Every cookie in the empire sells for 5% more."},

	# ---- the wonder
	"palace": {"name": "Grand Cookie Palace", "cat": "wonder", "tab": "town", "icon": "palace", "size": Vector2i(5, 5), "hall": 12, "n": [12], "cost": 2.0e8, "growth": 1.0, "up": 0, "max": 1, "time": 14400,
		"desc": "The crown of your empire. Build it in five stages to win."},
}

## Order of cards in the build menu.
const BUILD_ORDER: Array[String] = [
	"farm_wheat", "farm_sugar", "farm_cocoa", "farm_egg", "farm_milk", "farm_oats", "farm_berry", "farm_hazelnut", "farm_honey", "farm_vanilla", "farm_cinnamon", "farm_orange",
	"bakery", "churn", "chocolatier", "kettle", "caramel_pot", "roaster", "candy",
	"pantry", "rack", "packer", "wrapper",
	"dock", "shop", "board", "train", "airship",
	"hut", "cabin", "palace",
	"flowers", "tree", "hedge", "lamp", "well", "bench", "picnic", "banner", "topiary", "pond", "gazebo", "fountain", "windmill", "statue",
]

## Cookie Hall levels: upgrade price, build time (s), gems on completion,
## and the hall's own storage / porter housing.
const HALL := [
	{"cost": 0, "time": 0, "gems": 0},
	{"cost": 150, "time": 10, "gems": 5},
	{"cost": 700, "time": 60, "gems": 5},
	{"cost": 3000, "time": 300, "gems": 8},
	{"cost": 10000, "time": 900, "gems": 10},
	{"cost": 32000, "time": 1800, "gems": 12},
	{"cost": 100000, "time": 3600, "gems": 15},
	{"cost": 320000, "time": 7200, "gems": 18},
	{"cost": 1.0e6, "time": 10800, "gems": 20},
	{"cost": 3.2e6, "time": 14400, "gems": 25},
	{"cost": 1.0e7, "time": 21600, "gems": 30},
	{"cost": 3.2e7, "time": 28800, "gems": 35},
	{"cost": 1.0e8, "time": 36000, "gems": 40},
	{"cost": 3.2e8, "time": 43200, "gems": 45},
	{"cost": 1.0e9, "time": 57600, "gems": 60},
]

## Palace stages: money, royal deliveries and build time for each.
const PALACE_STAGES := [
	{"name": "Foundations", "cost": 2.0e8, "need": 0, "time": 14400},
	{"name": "Biscuit Walls", "cost": 1.5e9, "need": 200, "time": 28800},
	{"name": "Cream Towers", "cost": 9.0e9, "need": 600, "time": 43200},
	{"name": "Golden Domes", "cost": 5.0e10, "need": 1500, "time": 57600},
	{"name": "The Crown", "cost": 1.6e11, "need": 4000, "time": 86400},
]

## Obstacles on your land: clear them (money + a builder) for space and gems.
const OBSTACLES := {
	"bush": {"name": "Bramble Bush", "size": Vector2i(1, 1), "time": 5},
	"rock": {"name": "Boulder", "size": Vector2i(1, 1), "time": 10},
	"stump": {"name": "Old Stump", "size": Vector2i(1, 1), "time": 8},
	"oak": {"name": "Old Oak", "size": Vector2i(2, 2), "time": 20},
	"pine": {"name": "Tall Pine", "size": Vector2i(1, 1), "time": 15},
	"boulders": {"name": "Boulder Pile", "size": Vector2i(2, 2), "time": 30},
}

# ---------------------------------------------------------------- staff
## Staff roles. Porters carry everything along the roads (the broker picks the
## most useful job); farmers and chefs are assigned to one building and make
## it faster. Builders come with Builder's Huts.
const ROLES := {
	"porter": {
		"name": "Porter", "icon": "porter", "color": Color(0.72, 0.4, 0.3),
		"desc": "Carries harvests, ingredients and cookies along the roads to wherever they're needed.",
	},
	"farmer": {
		"name": "Farmer", "icon": "farmer", "color": Color(0.47, 0.58, 0.36),
		"desc": "Works one farm. Every farmer makes it faster.", "assign": "farm",
	},
	"chef": {
		"name": "Chef", "icon": "chef", "color": Color(0.95, 0.93, 0.88),
		"desc": "Works one bakery or kitchen, making it faster.", "assign": "machine",
	},
}
const ROLE_ORDER: Array[String] = ["porter", "farmer", "chef"]

# ---------------------------------------------------------------- land
## Biomes per land chunk; farms of the listed crops grow 40% faster there.
const BIOMES := {
	"meadow": {"name": "Meadow", "bonus": ["wheat", "oats", "egg"], "grass": Color(0.52, 0.62, 0.38)},
	"orchard": {"name": "Orchard Hills", "bonus": ["berry", "hazelnut", "honey", "orange"], "grass": Color(0.58, 0.64, 0.36)},
	"tropic": {"name": "Tropical Lowland", "bonus": ["sugar", "cocoa", "vanilla", "cinnamon"], "grass": Color(0.38, 0.56, 0.34)},
	"highland": {"name": "Highland", "bonus": ["milk", "oats", "hazelnut"], "grass": Color(0.46, 0.56, 0.42)},
}
const BIOME_ORDER: Array[String] = ["meadow", "orchard", "tropic", "highland"]

## Titles for each Cookie Hall level.
const LEVEL_TITLES := [
	"Kitchen Table", "Home Bakery", "Village Bakery", "Artisan Bakery", "Cookie Workshop",
	"Cookie House", "Cookie Company", "Regional Brand", "Cookie Guild", "National Brand",
	"Cookie Holdings", "Royal Supplier", "Continental Empire", "Cookie Dynasty", "Legendary Empire",
]


static func item_name(t: String) -> String:
	if t.length() > 2 and t[1] == ":":
		var r := recipe(t.substr(2))
		var n: String = r.get("name", "Cookie")
		match t[0]:
			"b": return n + " Box"
			"g": return n + " Gift"
		return n
	return ITEMS[t]["name"] if ITEMS.has(t) else t


## "raw" | "proc" | "cookie" | "box" | "gift"
static func cat(t: String) -> String:
	if t.length() > 2 and t[1] == ":":
		match t[0]:
			"c": return "cookie"
			"b": return "box"
			"g": return "gift"
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


static func item_height(t: String) -> float:
	match cat(t):
		"cookie": return COOKIE_H
		"box": return BOX_H
		"gift": return GIFT_H
	return ITEMS[t]["h"] if ITEMS.has(t) else 0.2


static func item_color(t: String) -> Color:
	if is_product(t):
		return COOKIE_LOOK.get(recipe_of(t), {"base": Color(0.86, 0.64, 0.38)})["base"]
	return ITEMS[t]["color"] if ITEMS.has(t) else Color.WHITE


static func item_icon(t: String) -> String:
	match cat(t):
		"cookie": return "ck_" + recipe_of(t)
		"box": return "box"
		"gift": return "gift"
	return t


static func level_title(lvl: int) -> String:
	return LEVEL_TITLES[clampi(lvl - 1, 0, LEVEL_TITLES.size() - 1)]


## Which building produces an ingredient ("" for none).
static func producer_of(ing: String) -> String:
	for k in BUILDINGS:
		var d: Dictionary = BUILDINGS[k]
		if d.get("crop", "") == ing:
			return k
		if d.has("out") and (d["out"] as Dictionary).has(ing):
			return k
	return ""


## Earliest Cookie Hall level an ingredient can be produced at.
static func ingredient_level(ing: String) -> int:
	var p := producer_of(ing)
	if p == "":
		return 1
	var l := int(BUILDINGS[p]["hall"])
	if BUILDINGS[p].has("in"):
		for i in BUILDINGS[p]["in"]:
			l = maxi(l, ingredient_level(i))
	return l


## Earliest Cookie Hall level a recipe can be baked at.
static func recipe_level(id: String) -> int:
	var l := 1
	for i in recipe(id)["ings"]:
		l = maxi(l, ingredient_level(i))
	return l


static func size_of(kind: String) -> Vector2i:
	return BUILDINGS[kind]["size"]


## Copies of a building allowed at a Cookie Hall level (-1 = unlimited).
static func max_count(kind: String, hall: int) -> int:
	var d: Dictionary = BUILDINGS[kind]
	if not d.has("n"):
		return -1 if hall >= int(d["hall"]) else 0
	var n := 0
	for h in d["n"]:
		if hall >= int(h):
			n += 1
	return n


## The Hall level at which the next copy unlocks (-1 when there is none).
static func next_count_hall(kind: String, owned: int) -> int:
	var d: Dictionary = BUILDINGS[kind]
	if not d.has("n") or owned >= (d["n"] as Array).size():
		return -1
	return int(d["n"][owned])


## Silos a bakery has at level l (one ingredient each).
static func bakery_slots(l: int) -> int:
	return clampi(1 + (l - 1) / 3, 1, 7)


## Bakery level needed for a recipe with n ingredients.
static func slots_level(n: int) -> int:
	return maxi(1, (n - 1) * 3 + 1)


static func is_instant(kind: String) -> bool:
	return int(BUILDINGS[kind].get("time", 0)) <= 0 and BUILDINGS[kind]["cat"] == "decor"
