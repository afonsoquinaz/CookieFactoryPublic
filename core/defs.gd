class_name Defs
## Static game definitions: items, ingredients, worker roles, buildings.
## Everything data-like lives here or in Bal so new content is a table entry.

const INGREDIENTS: Array[String] = ["wheat", "sugar", "cocoa", "egg", "milk"]

## Item types that can be carried. h = stacking height (m) in a carry column.
const ITEMS := {
	"wheat": {"name": "Wheat", "h": 0.2, "color": Color(1.0, 0.8, 0.3)},
	"sugar": {"name": "Sugar Cane", "h": 0.18, "color": Color(0.55, 0.85, 0.35)},
	"cocoa": {"name": "Cocoa", "h": 0.2, "color": Color(0.85, 0.45, 0.2)},
	"egg": {"name": "Eggs", "h": 0.19, "color": Color(1.0, 0.95, 0.85)},
	"milk": {"name": "Milk", "h": 0.34, "color": Color(0.55, 0.75, 1.0)},
	"cookie": {"name": "Cookie", "h": 0.085, "color": Color(0.93, 0.7, 0.4)},
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
		"name": "Farmer", "icon": "farmer", "color": Color(0.42, 0.78, 0.3),
		"hat": "straw", "tool": "hoe",
		"from": "farm", "to": "farm",
		"desc": "Works the fields. Every farmer on a farm grows its crop faster.",
		"needs": "cabin",
	},
	"gatherer": {
		"name": "Gatherer", "icon": "gatherer", "color": Color(0.3, 0.6, 0.98),
		"hat": "cap", "tool": "basket",
		"from": "farm", "to": "pantry",
		"desc": "Collects ingredients from farm crates and stores them in the Pantry (straight into the hoppers if you have no Feeders).",
		"needs": "pantry",
	},
	"feeder": {
		"name": "Feeder", "icon": "feeder", "color": Color(1.0, 0.58, 0.18),
		"hat": "hardhat", "tool": "scoop",
		"from": "pantry", "to": "hopper",
		"desc": "Takes ingredients from the Pantry and fills the emptiest hoppers on the line.",
		"needs": "pantry",
	},
	"collector": {
		"name": "Collector", "icon": "collector", "color": Color(0.98, 0.98, 0.98),
		"hat": "chef", "tool": "tray",
		"from": "oven", "to": "shelf",
		"desc": "Picks up fresh cookies at the oven and stacks them on the Packing Shelf (straight onto a truck if you have no Loaders).",
		"needs": "shelf",
	},
	"loader": {
		"name": "Loader", "icon": "loader", "color": Color(0.95, 0.32, 0.32),
		"hat": "redcap", "tool": "dolly",
		"from": "shelf", "to": "truck",
		"desc": "Moves cookies from the Packing Shelf into a waiting delivery truck.",
		"needs": "shelf",
	},
}
const ROLE_ORDER: Array[String] = ["farmer", "gatherer", "feeder", "collector", "loader"]

## Buildings unlocked with build pads in the world.
## lvl = empire level needed before the pad accepts money.
const BUILDINGS := {
	"cabin": {"name": "Staff Cabin", "cost": 60, "lvl": 1, "icon": "worker", "desc": "Hire workers"},
	"pantry": {"name": "Pantry", "cost": 180, "lvl": 2, "icon": "storage", "desc": "Ingredient storage for Gatherers & Feeders"},
	"shelf": {"name": "Packing Shelf", "cost": 350, "lvl": 3, "icon": "storage", "desc": "Cookie storage for Collectors & Loaders"},
	"dock2": {"name": "Second Dock", "cost": 1800, "lvl": 5, "icon": "truck", "desc": "Another delivery truck"},
	"line2": {"name": "Assembly Line 2", "cost": 2500, "lvl": 6, "icon": "conveyor", "desc": "Double your production"},
	"dock3": {"name": "Third Dock", "cost": 15000, "lvl": 9, "icon": "truck", "desc": "A third delivery truck"},
	"line3": {"name": "Assembly Line 3", "cost": 40000, "lvl": 11, "icon": "conveyor", "desc": "Triple production"},
}
const BUILD_ORDER: Array[String] = ["cabin", "pantry", "shelf", "dock2", "line2", "dock3", "line3"]

const LEVEL_TITLES := [
	"Tiny Workshop", "Home Bakery", "Corner Bakery", "Cookie Shop", "Cookie Workshop",
	"Cookie Factory", "Busy Factory", "Cookie Plant", "Cookie Works", "Big Cookie Co.",
	"Cookie Industries", "Cookie Corporation", "Cookie Conglomerate", "Cookie Empire",
	"Cookie Superpower", "Galactic Cookies",
]


static func item_name(t: String) -> String:
	return ITEMS[t]["name"] if ITEMS.has(t) else t


static func level_title(lvl: int) -> String:
	return LEVEL_TITLES[clampi(lvl - 1, 0, LEVEL_TITLES.size() - 1)]
