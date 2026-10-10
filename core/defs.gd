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

## Cookie recipes. A production line bakes the most valuable recipe whose
## ingredients are all among its hoppers (wheat comes from the Mixer).
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
## size = footprint in grid cells (Grid.CELL m), x along the building's flow /
## width, y = depth (front faces +Z when unrotated).
## cost = first purchase, growth = price factor for every one you already own.
## up = base upgrade cost (level 1 -> 2), max = top level, tiers = levels where
## the building gets a new look.
const CATS := [
	["farm", "Farms", "farm"],
	["line", "Bakery", "oven"],
	["kitchen", "Kitchen", "chocolatier"],
	["pack", "Packing", "box"],
	["sell", "Sales", "truck"],
	["staff", "Staff", "hire"],
	["decor", "Decor", "flowers"],
]

const FARM_TIERS: Array[int] = [1, 5, 10, 20, 35]
const MACHINE_TIERS: Array[int] = [1, 5, 12, 25, 40]

const BUILDINGS := {
	# ---- farms (3x3)
	"farm_wheat": {"name": "Wheat Field", "cat": "farm", "icon": "wheat", "crop": "wheat", "size": Vector2i(3, 3), "lvl": 1, "cost": 30, "growth": 2.2, "up": 12, "max": 60,
		"desc": "Golden wheat. Every cookie starts with it."},
	"farm_sugar": {"name": "Sugar Cane Field", "cat": "farm", "icon": "sugar", "crop": "sugar", "size": Vector2i(3, 3), "lvl": 1, "cost": 25, "growth": 2.2, "up": 18, "max": 60,
		"desc": "Sweetens every recipe after the first."},
	"farm_cocoa": {"name": "Cocoa Grove", "cat": "farm", "icon": "cocoa", "crop": "cocoa", "size": Vector2i(3, 3), "lvl": 3, "cost": 90, "growth": 2.2, "up": 30, "max": 60,
		"desc": "Cocoa pods for crinkles, and for chocolate."},
	"farm_egg": {"name": "Hen House", "cat": "farm", "icon": "egg", "crop": "egg", "size": Vector2i(3, 3), "lvl": 4, "cost": 140, "growth": 2.2, "up": 45, "max": 60,
		"desc": "Fresh eggs for richer doughs."},
	"farm_milk": {"name": "Dairy Barn", "cat": "farm", "icon": "milk", "crop": "milk", "size": Vector2i(3, 3), "lvl": 5, "cost": 210, "growth": 2.2, "up": 70, "max": 60,
		"desc": "Milk for biscuits, and for the butter churn."},
	"farm_oats": {"name": "Oat Field", "cat": "farm", "icon": "oats", "crop": "oats", "size": Vector2i(3, 3), "lvl": 8, "cost": 760, "growth": 2.2, "up": 250, "max": 60,
		"desc": "Hearty oats for crumbles."},
	"farm_berry": {"name": "Strawberry Patch", "cat": "farm", "icon": "berry", "crop": "berry", "size": Vector2i(3, 3), "lvl": 10, "cost": 1800, "growth": 2.2, "up": 600, "max": 60,
		"desc": "Sweet berries for the jam kettle."},
	"farm_hazelnut": {"name": "Hazel Orchard", "cat": "farm", "icon": "hazelnut", "crop": "hazelnut", "size": Vector2i(3, 3), "lvl": 13, "cost": 6800, "growth": 2.2, "up": 2200, "max": 60,
		"desc": "Crunchy hazelnuts."},
	"farm_honey": {"name": "Bee Meadow", "cat": "farm", "icon": "beehive", "crop": "honey", "size": Vector2i(3, 3), "lvl": 15, "cost": 16000, "growth": 2.2, "up": 5000, "max": 60,
		"desc": "Hives make honey. Flower beds nearby make them busier."},
	"farm_vanilla": {"name": "Orchid Greenhouse", "cat": "farm", "icon": "greenhouse", "crop": "vanilla", "size": Vector2i(3, 3), "lvl": 19, "cost": 94000, "growth": 2.2, "up": 30000, "max": 60,
		"desc": "Precious vanilla pods."},
	"farm_cinnamon": {"name": "Spice Garden", "cat": "farm", "icon": "cinnamon", "crop": "cinnamon", "size": Vector2i(3, 3), "lvl": 24, "cost": 8.4e5, "growth": 2.2, "up": 2.8e5, "max": 60,
		"desc": "Cinnamon bark, warm and fragrant."},
	"farm_orange": {"name": "Orange Grove", "cat": "farm", "icon": "orange", "crop": "orange", "size": Vector2i(3, 3), "lvl": 28, "cost": 4.8e6, "growth": 2.2, "up": 1.6e6, "max": 60,
		"desc": "Sunny oranges for candied peel."},

	# ---- the bakery line (modules connect in a straight row: Mixer -> tubes/hoppers -> Oven)
	"mixer": {"name": "Dough Mixer", "cat": "line", "icon": "mixer", "size": Vector2i(1, 2), "lvl": 1, "cost": 120, "growth": 2.6, "up": 40, "max": 50,
		"desc": "Starts a production line. Feed it wheat; dough rolls out of it."},
	"tube": {"name": "Glass Tube", "cat": "line", "icon": "tube", "size": Vector2i(1, 2), "lvl": 1, "cost": 10, "growth": 1.05, "up": 0, "max": 1,
		"desc": "Connects line parts. Hoppers can replace a tube."},
	"hopper": {"name": "Hopper", "cat": "line", "icon": "hopper", "size": Vector2i(1, 2), "lvl": 1, "cost": 20, "growth": 1.25, "up": 15, "max": 40,
		"desc": "Adds one ingredient to every dough ball that passes."},
	"oven": {"name": "Oven", "cat": "line", "icon": "oven", "size": Vector2i(2, 2), "lvl": 1, "cost": 220, "growth": 2.6, "up": 60, "max": 50,
		"desc": "Ends a line. Must connect to a Mixer through tubes or hoppers."},

	# ---- kitchen (2x2): turns ingredients into better ones
	"churn": {"name": "Butter Churn", "cat": "kitchen", "icon": "churn", "size": Vector2i(2, 2), "lvl": 6, "cost": 320, "growth": 2.4, "up": 110, "max": 50,
		"in": {"milk": 2}, "out": {"butter": 1}, "time": 3.0, "desc": "Milk becomes butter."},
	"chocolatier": {"name": "Chocolatier", "cat": "kitchen", "icon": "chocolatier", "size": Vector2i(2, 2), "lvl": 7, "cost": 500, "growth": 2.4, "up": 170, "max": 50,
		"in": {"cocoa": 2, "sugar": 1}, "out": {"chocolate": 2}, "time": 3.5, "desc": "Cocoa and sugar become chocolate."},
	"kettle": {"name": "Jam Kettle", "cat": "kitchen", "icon": "kettle", "size": Vector2i(2, 2), "lvl": 11, "cost": 2800, "growth": 2.4, "up": 900, "max": 50,
		"in": {"berry": 2, "sugar": 1}, "out": {"jam": 1}, "time": 4.0, "desc": "Strawberries and sugar become jam."},
	"caramel_pot": {"name": "Caramel Pot", "cat": "kitchen", "icon": "caramel_pot", "size": Vector2i(2, 2), "lvl": 17, "cost": 39000, "growth": 2.4, "up": 13000, "max": 50,
		"in": {"sugar": 2, "butter": 1}, "out": {"caramel": 1}, "time": 4.5, "desc": "Sugar and butter become caramel."},
	"roaster": {"name": "Praline Roaster", "cat": "kitchen", "icon": "roaster", "size": Vector2i(2, 2), "lvl": 21, "cost": 225000, "growth": 2.4, "up": 75000, "max": 50,
		"in": {"hazelnut": 2, "chocolate": 1}, "out": {"praline": 1}, "time": 5.0, "desc": "Hazelnuts and chocolate become praline."},
	"candy": {"name": "Candy Kitchen", "cat": "kitchen", "icon": "candy", "size": Vector2i(2, 2), "lvl": 29, "cost": 7.5e6, "growth": 2.4, "up": 2.5e6, "max": 50,
		"in": {"orange": 1, "sugar": 2}, "out": {"candied": 1}, "time": 5.0, "desc": "Oranges and sugar become candied peel."},

	# ---- packing + storage (2x2)
	"pantry": {"name": "Pantry", "cat": "pack", "icon": "pantry", "size": Vector2i(2, 2), "lvl": 4, "cost": 130, "growth": 2.0, "up": 45, "max": 40,
		"desc": "Stores any ingredients. Gatherers fill it, Feeders empty it."},
	"rack": {"name": "Cookie Rack", "cat": "pack", "icon": "rack", "size": Vector2i(2, 2), "lvl": 6, "cost": 300, "growth": 2.0, "up": 100, "max": 40,
		"desc": "Stores cookies, boxes and gifts for the Loaders."},
	"packer": {"name": "Box Packer", "cat": "pack", "icon": "packer", "size": Vector2i(2, 2), "lvl": 9, "cost": 1200, "growth": 2.4, "up": 400, "max": 50,
		"desc": "Packs 6 cookies into a box worth 25% more."},
	"wrapper": {"name": "Gift Wrapper", "cat": "pack", "icon": "wrapper", "size": Vector2i(2, 2), "lvl": 20, "cost": 145000, "growth": 2.4, "up": 48000, "max": 50,
		"desc": "Wraps boxes into gifts worth 60% more."},

	# ---- sales
	"dock": {"name": "Delivery Van", "cat": "sell", "icon": "truck", "size": Vector2i(2, 3), "lvl": 1, "cost": 300, "growth": 3.0, "up": 45, "max": 50,
		"desc": "Load cookies; the van drives off and sells them."},
	"shop": {"name": "Cookie Shop", "cat": "sell", "icon": "market", "size": Vector2i(3, 2), "lvl": 5, "cost": 220, "growth": 3.0, "up": 75, "max": 50,
		"desc": "Customers walk in and pay 30% more. Decor nearby brings more of them."},
	"board": {"name": "Order Board", "cat": "sell", "icon": "board", "size": Vector2i(2, 1), "lvl": 6, "cost": 350, "growth": 1.0, "up": 0, "max": 1,
		"desc": "Special orders: deliver them for big rewards and gems."},
	"train": {"name": "Rail Depot", "cat": "sell", "icon": "train", "size": Vector2i(3, 3), "lvl": 14, "cost": 10500, "growth": 3.0, "up": 3500, "max": 50,
		"desc": "A freight train takes huge loads to the city."},
	"airship": {"name": "Airship Mast", "cat": "sell", "icon": "airship", "size": Vector2i(3, 3), "lvl": 30, "cost": 1.16e7, "growth": 3.0, "up": 3.9e6, "max": 50,
		"desc": "Flies gifts to royal courts: gifts sell for double."},

	# ---- staff
	"cabin": {"name": "Staff Cabin", "cat": "staff", "icon": "cabin", "size": Vector2i(2, 2), "lvl": 2, "cost": 60, "growth": 2.5, "up": 90, "max": 20,
		"desc": "Houses workers. More cabins, more staff."},

	# ---- decor (auras work in a radius of cells)
	"flowers": {"name": "Flower Bed", "cat": "decor", "icon": "flowers", "size": Vector2i(1, 1), "lvl": 2, "cost": 25, "growth": 1.06, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 3, "v": 0.04}, "desc": "Bee Meadows nearby make +15% honey. Shops nearby get more customers."},
	"lamp": {"name": "Street Lamp", "cat": "decor", "icon": "lamp", "size": Vector2i(1, 1), "lvl": 2, "cost": 30, "growth": 1.06, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 3, "v": 0.03}, "desc": "Warm light. Shops nearby get more customers."},
	"tree": {"name": "Shade Tree", "cat": "decor", "icon": "tree", "size": Vector2i(1, 1), "lvl": 2, "cost": 20, "growth": 1.06, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 2, "v": 0.02}, "desc": "Pretty, and shops nearby get more customers."},
	"hedge": {"name": "Hedge", "cat": "decor", "icon": "hedge", "size": Vector2i(1, 1), "lvl": 2, "cost": 12, "growth": 1.04, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 1, "v": 0.01}, "desc": "A neat hedge."},
	"bench": {"name": "Bench", "cat": "decor", "icon": "bench", "size": Vector2i(1, 1), "lvl": 3, "cost": 40, "growth": 1.06, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 2, "v": 0.03}, "desc": "Shops nearby get more customers."},
	"picnic": {"name": "Picnic Table", "cat": "decor", "icon": "picnic", "size": Vector2i(1, 1), "lvl": 4, "cost": 60, "growth": 1.08, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 2, "v": 0.03}, "desc": "Shops nearby get more customers."},
	"banner": {"name": "Banner", "cat": "decor", "icon": "banner", "size": Vector2i(1, 1), "lvl": 5, "cost": 90, "growth": 1.08, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 3, "v": 0.04}, "desc": "Your colours. Shops nearby get more customers."},
	"topiary": {"name": "Topiary", "cat": "decor", "icon": "topiary", "size": Vector2i(1, 1), "lvl": 6, "cost": 140, "growth": 1.08, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 2, "v": 0.04}, "desc": "A tidy round bush. Shops nearby get more customers."},
	"pond": {"name": "Pond", "cat": "decor", "icon": "pond", "size": Vector2i(2, 2), "lvl": 8, "cost": 900, "growth": 1.5, "up": 0, "max": 1,
		"aura": {"what": "farm", "r": 3, "v": 0.12}, "desc": "Farms within 3 tiles work 12% faster."},
	"gazebo": {"name": "Gazebo", "cat": "decor", "icon": "gazebo", "size": Vector2i(2, 2), "lvl": 9, "cost": 2500, "growth": 1.6, "up": 0, "max": 1,
		"aura": {"what": "charm", "r": 5, "v": 0.12}, "desc": "Shops within 5 tiles get 12% more customers."},
	"windmill": {"name": "Windmill", "cat": "decor", "icon": "windmill", "size": Vector2i(2, 2), "lvl": 12, "cost": 15000, "growth": 1.9, "up": 0, "max": 1,
		"aura": {"what": "farm", "r": 5, "v": 0.25}, "desc": "Farms within 5 tiles work 25% faster."},
	"well": {"name": "Well", "cat": "decor", "icon": "well", "size": Vector2i(1, 1), "lvl": 3, "cost": 90, "growth": 1.8, "up": 0, "max": 1,
		"aura": {"what": "farm", "r": 3, "v": 0.2}, "desc": "Farms within 3 tiles work 20% faster."},
	"fountain": {"name": "Fountain", "cat": "decor", "icon": "fountain", "size": Vector2i(2, 2), "lvl": 10, "cost": 1800, "growth": 2.0, "up": 0, "max": 1,
		"aura": {"what": "walk", "r": 5, "v": 0.2}, "desc": "Workers within 5 tiles walk 20% faster. Shops love it."},
	"statue": {"name": "Golden Cookie Statue", "cat": "decor", "icon": "statue", "size": Vector2i(2, 2), "lvl": 25, "cost": 1.3e6, "growth": 4.0, "up": 0, "max": 1,
		"aura": {"what": "global_price", "r": 0, "v": 0.05}, "desc": "Every cookie in the empire sells for 5% more."},

	# ---- the wonder
	"palace": {"name": "Grand Cookie Palace", "cat": "decor", "icon": "palace", "size": Vector2i(5, 5), "lvl": 35, "cost": 2.0e8, "growth": 1.0, "up": 0, "max": 1,
		"desc": "The crown of your empire. Build it in five stages to win."},
}

## Order of cards in the build menu.
const BUILD_ORDER: Array[String] = [
	"farm_wheat", "farm_sugar", "farm_cocoa", "farm_egg", "farm_milk", "farm_oats", "farm_berry", "farm_hazelnut", "farm_honey", "farm_vanilla", "farm_cinnamon", "farm_orange",
	"mixer", "hopper", "tube", "oven",
	"churn", "chocolatier", "kettle", "caramel_pot", "roaster", "candy",
	"pantry", "rack", "packer", "wrapper",
	"dock", "shop", "board", "train", "airship",
	"cabin",
	"flowers", "lamp", "tree", "hedge", "bench", "picnic", "banner", "topiary", "well", "pond", "gazebo", "windmill", "fountain", "statue", "palace",
]

## Building kinds a line is made of.
const LINE_KINDS: Array[String] = ["mixer", "tube", "hopper", "oven"]

## Palace stages: money + royal deliveries for each.
const PALACE_STAGES := [
	{"name": "Foundations", "cost": 2.0e8, "need": 0},
	{"name": "Biscuit Walls", "cost": 1.5e9, "need": 200},
	{"name": "Cream Towers", "cost": 9.0e9, "need": 600},
	{"name": "Golden Domes", "cost": 5.0e10, "need": 1500},
	{"name": "The Crown", "cost": 2.5e11, "need": 4000},
]

# ---------------------------------------------------------------- staff
## Worker roles. Farmers and Chefs work at one building (assigned there);
## the rest carry things around, each with its own look and job.
const ROLES := {
	"farmer": {
		"name": "Farmer", "icon": "farmer", "color": Color(0.47, 0.58, 0.36),
		"desc": "Works one farm. Every farmer makes it faster.", "assign": "farm",
	},
	"chef": {
		"name": "Chef", "icon": "chef", "color": Color(0.95, 0.93, 0.88),
		"desc": "Runs one oven or kitchen machine, making it faster.", "assign": "machine",
	},
	"gatherer": {
		"name": "Gatherer", "icon": "gatherer", "color": Color(0.38, 0.5, 0.62),
		"from": "Farms", "to": "Kitchens · Pantry · Hoppers",
		"desc": "Carries the harvest from farm crates to whoever needs it.",
	},
	"feeder": {
		"name": "Feeder", "icon": "feeder", "color": Color(0.8, 0.6, 0.3),
		"from": "Pantry · Kitchens", "to": "Hoppers · Kitchens",
		"desc": "Keeps hoppers and kitchen machines topped up.",
	},
	"collector": {
		"name": "Collector", "icon": "collector", "color": Color(0.72, 0.52, 0.66),
		"from": "Ovens", "to": "Packers · Racks · Sales",
		"desc": "Takes fresh cookies from the ovens.",
	},
	"loader": {
		"name": "Loader", "icon": "loader", "color": Color(0.72, 0.4, 0.3),
		"from": "Racks · Packers", "to": "Vans · Shops · Trains",
		"desc": "Takes cookies and boxes to be sold.",
	},
}
const ROLE_ORDER: Array[String] = ["gatherer", "feeder", "collector", "loader", "farmer", "chef"]
const HAULER_ROLES: Array[String] = ["gatherer", "feeder", "collector", "loader"]

# ---------------------------------------------------------------- land
## Biomes per land chunk; farms of the listed crops grow 40% faster there.
const BIOMES := {
	"meadow": {"name": "Meadow", "bonus": ["wheat", "oats", "egg"], "grass": Color(0.52, 0.62, 0.38)},
	"orchard": {"name": "Orchard Hills", "bonus": ["berry", "hazelnut", "honey", "orange"], "grass": Color(0.58, 0.64, 0.36)},
	"tropic": {"name": "Tropical Lowland", "bonus": ["sugar", "cocoa", "vanilla", "cinnamon"], "grass": Color(0.38, 0.56, 0.34)},
	"highland": {"name": "Highland", "bonus": ["milk", "oats", "hazelnut"], "grass": Color(0.46, 0.56, 0.42)},
}
const BIOME_ORDER: Array[String] = ["meadow", "orchard", "tropic", "highland"]

const LEVEL_TITLES := [
	"Kitchen Table", "Home Bakery", "Corner Bakery", "Village Bakery", "Artisan Bakery",
	"Cookie Workshop", "Cookie House", "Cookie Works", "Cookie Company", "Regional Brand",
	"Cookie Guild", "National Brand", "Cookie Group", "Cookie Holdings", "Cookie Empire",
	"Royal Supplier", "Continental Empire", "Global Empire", "Cookie Dynasty", "Legendary Empire",
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
	return LEVEL_TITLES[clampi((lvl - 1) / 2, 0, LEVEL_TITLES.size() - 1)]


## Which building produces an ingredient ("" for none).
static func producer_of(ing: String) -> String:
	for k in BUILDINGS:
		var d: Dictionary = BUILDINGS[k]
		if d.get("crop", "") == ing:
			return k
		if d.has("out") and (d["out"] as Dictionary).has(ing):
			return k
	return ""


## Earliest level an ingredient can be produced at.
static func ingredient_level(ing: String) -> int:
	var p := producer_of(ing)
	if p == "":
		return 1
	var l := int(BUILDINGS[p]["lvl"])
	if BUILDINGS[p].has("in"):
		for i in BUILDINGS[p]["in"]:
			l = maxi(l, ingredient_level(i))
	return l


## Earliest level a recipe can be baked at.
static func recipe_level(id: String) -> int:
	var l := 1
	for i in recipe(id)["ings"]:
		l = maxi(l, ingredient_level(i))
	return l


static func size_of(kind: String) -> Vector2i:
	return BUILDINGS[kind]["size"]
