class_name Defs
## Static game definitions: items, ingredients, worker roles, buildings.
## Everything data-like lives here or in Bal so new content is a table entry.

const INGREDIENTS: Array[String] = ["wheat", "sugar", "cocoa", "egg", "milk"]

## Item types that can be carried. h = stacking height (m) in a carry column.
const ITEMS := {
	"wheat": {"name": "Wheat", "h": 0.2, "color": Color(0.86, 0.7, 0.38)},
	"sugar": {"name": "Sugar Cane", "h": 0.18, "color": Color(0.6, 0.7, 0.42)},
	"cocoa": {"name": "Cocoa", "h": 0.2, "color": Color(0.7, 0.42, 0.26)},
	"egg": {"name": "Eggs", "h": 0.19, "color": Color(0.9, 0.84, 0.72)},
	"milk": {"name": "Milk", "h": 0.31, "color": Color(0.62, 0.72, 0.8)},
	"cookie": {"name": "Cookie", "h": 0.085, "color": Color(0.8, 0.6, 0.38)},
}

const FARM_NAMES := {
	"wheat": "Wheat Field",
	"sugar": "Sugar Cane Grove",
	"cocoa": "Cocoa Orchard",
	"egg": "Chicken Coop",
	"milk": "Dairy Pasture",
}

## Worker roles. Each is a from -> to job with a look that can't be mistaken:
## colour (shirt + ring + badge), hat, tool and work animation.
const ROLES := {
	"farmer": {
		"name": "Farmer", "icon": "farmer", "color": Color(0.47, 0.58, 0.36),
		"hat": "straw", "tool": "hoe",
		"from": "farm", "to": "farm",
		"desc": "Works the fields. Every farmer on a farm grows its crop faster.",
		"needs": "cabin",
	},
	"gatherer": {
		"name": "Gatherer", "icon": "gatherer", "color": Color(0.38, 0.5, 0.62),
		"hat": "cap", "tool": "basket",
		"from": "farm", "to": "pantry",
		"desc": "Collects ingredients from farm crates and stores them in the Pantry (straight into the hoppers if you have no Feeders).",
		"needs": "pantry",
	},
	"feeder": {
		"name": "Feeder", "icon": "feeder", "color": Color(0.8, 0.6, 0.3),
		"hat": "hardhat", "tool": "scoop",
		"from": "pantry", "to": "hopper",
		"desc": "Takes ingredients from the Pantry and fills the emptiest hoppers on the line.",
		"needs": "pantry",
	},
	"collector": {
		"name": "Collector", "icon": "collector", "color": Color(0.93, 0.9, 0.84),
		"hat": "chef", "tool": "tray",
		"from": "oven", "to": "shelf",
		"desc": "Picks up fresh cookies at the oven and stacks them on the Packing Shelf (straight onto a truck if you have no Loaders).",
		"needs": "shelf",
	},
	"loader": {
		"name": "Loader", "icon": "loader", "color": Color(0.72, 0.4, 0.3),
		"hat": "redcap", "tool": "dolly",
		"from": "shelf", "to": "truck",
		"desc": "Moves cookies from the Packing Shelf into a waiting delivery truck.",
		"needs": "shelf",
	},
}
const ROLE_ORDER: Array[String] = ["farmer", "gatherer", "feeder", "collector", "loader"]

## Buildings unlocked with build pads in the world. A pad only appears once
## you reach its level, so the island starts calm and grows with you.
## plot_<ingredient> unlocks that farm and its hopper on every line.
const BUILDINGS := {
	"plot_sugar": {"name": "Sugar Cane Field", "cost": 25, "lvl": 1, "icon": "sugar", "desc": "Sweeter cookies, sold for more"},
	"cabin": {"name": "Staff Cabin", "cost": 60, "lvl": 2, "icon": "worker", "desc": "Hire workers"},
	"plot_cocoa": {"name": "Cocoa Orchard", "cost": 150, "lvl": 2, "icon": "cocoa", "desc": "Chocolate chip cookies"},
	"pantry": {"name": "Pantry", "cost": 260, "lvl": 3, "icon": "storage", "desc": "Ingredient storage for Gatherers & Feeders"},
	"plot_egg": {"name": "Hen House", "cost": 420, "lvl": 3, "icon": "egg", "desc": "Richer, buttery cookies"},
	"shelf": {"name": "Packing Shelf", "cost": 650, "lvl": 4, "icon": "storage", "desc": "Cookie storage for Collectors & Loaders"},
	"plot_milk": {"name": "Dairy Pasture", "cost": 950, "lvl": 4, "icon": "milk", "desc": "The full recipe: premium cookies"},
	"dock2": {"name": "Second Dock", "cost": 2200, "lvl": 5, "icon": "truck", "desc": "Another delivery van"},
	"line2": {"name": "Production Line 2", "cost": 3800, "lvl": 6, "icon": "conveyor", "desc": "Double your production"},
	"dock3": {"name": "Third Dock", "cost": 14000, "lvl": 8, "icon": "truck", "desc": "A third delivery van"},
	"line3": {"name": "Production Line 3", "cost": 36000, "lvl": 10, "icon": "conveyor", "desc": "Triple production"},
}
const BUILD_ORDER: Array[String] = ["plot_sugar", "cabin", "plot_cocoa", "pantry", "plot_egg", "shelf", "plot_milk", "dock2", "line2", "dock3", "line3"]

## Cookie names by how many ingredients the recipe uses.
const COOKIE_GRADES := ["Plain Shortbread", "Sugar Cookie", "Chocolate Chip", "Butter Chocolate Chip", "Premium Chocolate Chip"]

const LEVEL_TITLES := [
	"Kitchen Table", "Home Bakery", "Corner Bakery", "Artisan Bakery", "Cookie Workshop",
	"Cookie House", "Cookie Company", "Regional Brand", "National Brand", "Cookie Group",
	"Cookie Holdings", "Cookie Empire", "Global Empire", "Cookie Dynasty", "Legendary Empire",
]


static func item_name(t: String) -> String:
	return ITEMS[t]["name"] if ITEMS.has(t) else t


static func level_title(lvl: int) -> String:
	return LEVEL_TITLES[clampi(lvl - 1, 0, LEVEL_TITLES.size() - 1)]
