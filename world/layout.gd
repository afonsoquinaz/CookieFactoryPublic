class_name Lay
## Where everything stands on the island (metres; x right, z toward the
## camera). Farms in a row along the top, assembly lines below them running
## left to right into their ovens, delivery docks on the east pier.

const FARM_X := {"wheat": -8.0, "sugar": -4.0, "cocoa": 0.0, "egg": 4.0, "milk": 8.0}
const FARM_Z := -12.6
const FARM_SIZE := Vector2(3.6, 4.4)
const CRATE_Z := -9.75          # crate just outside the farm gate
const CRATE_ZONE_Z := -8.55

const LINE_Z: Array[float] = [-4.0, 4.0, 12.0]
const LINE_IDS: Array[String] = ["line1", "line2", "line3"]
const TUBE_X0 := -10.6          # tube start (west)
const TUBE_X1 := 8.9            # tube end, oven mouth
const TUBE_Y := 1.75            # tube centre height (characters walk under)
const HOPPER_ZONE_DZ := -1.75   # hopper pads sit north of the tube
const OVEN_X := 10.6
const TRAY_X := 12.9

const DOCK_Z: Array[float] = [-2.4, 6.0, 14.0]
const DOCK_IDS: Array[String] = ["dock1", "dock2", "dock3"]
const DOCK_ZONE_X := 15.4
const TRUCK_X := 18.2

const PANTRY_POS := Vector3(-13.6, 0, -4.6)
const SHELF_POS := Vector3(12.9, 0, 0.6)
const CABIN_POS := Vector3(-13.4, 0, 6.0)
const PLAYER_START := Vector3(0.5, 0, -7.2)

const ISLAND_MIN := Vector2(-17.5, -17.0)
const ISLAND_MAX := Vector2(17.0, 18.5)


static func hopper_pos(line: int, ing: String) -> Vector3:
	return Vector3(FARM_X[ing], 0, LINE_Z[line])


static func hopper_zone(line: int, ing: String) -> Vector3:
	return Vector3(FARM_X[ing], 0, LINE_Z[line] + HOPPER_ZONE_DZ)


static func tray_zone(line: int) -> Vector3:
	return Vector3(TRAY_X, 0, LINE_Z[line] + 1.55)


static func dock_zone(d: int) -> Vector3:
	return Vector3(DOCK_ZONE_X, 0, DOCK_Z[d])


## Where a build pad for building id sits.
static func pad_pos(id: String) -> Vector3:
	match id:
		"cabin": return CABIN_POS + Vector3(1.6, 0, 0.6)
		"pantry": return PANTRY_POS + Vector3(1.6, 0, 0.0)
		"shelf": return SHELF_POS + Vector3(0, 0, 0)
		"dock2": return Vector3(DOCK_ZONE_X, 0, DOCK_Z[1])
		"dock3": return Vector3(DOCK_ZONE_X, 0, DOCK_Z[2])
		"line2": return Vector3(0.0, 0, LINE_Z[1])
		"line3": return Vector3(0.0, 0, LINE_Z[2])
	return Vector3.ZERO
