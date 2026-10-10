class_name SalesArt
## Sales buildings and their vehicles, five tiers each.
## Depot: plank shed -> brick depot -> Cookie Express -> logistics hub -> royal post office.
## Van: cream van -> sage truck -> charcoal + brass -> box truck -> royal coach.
## Train: little tank engine -> ... -> streamlined golden express.
## Airship: canvas blimp -> ... -> royal zeppelin with gold fins.


static func site(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	match kind:
		"dock":
			_depot(k, t)
		"train":
			# platform, rails, a stone tunnel portal on the left
			k.rbox(Vector3(6.0, 0.35, 1.6), 0.04, Pal.STONE, MeshKit.at(0, 0.17, 0.4))
			k.rbox(Vector3(6.0, 0.06, 0.18), 0.02, Pal.CREAM, MeshKit.at(0, 0.36, -0.3))
			k.rbox(Vector3(6.0, 0.08, 2.0), 0.02, Color(0.5, 0.46, 0.42), MeshKit.at(0, 0.03, -1.4))
			for i in 12:
				k.rbox(Vector3(0.2, 0.06, 1.6), 0.01, Pal.WOOD_DARK, MeshKit.at(-2.8 + i * 0.5, 0.08, -1.4))
			for sz in [-0.55, 0.55]:
				k.rbox(Vector3(6.0, 0.08, 0.07), 0.01, Pal.STEEL, MeshKit.at(0, 0.14, -1.4 + sz))
			var stone: Color = [Pal.STONE_DARK, Pal.STONE_DARK, Pal.BRICK_DARK, Pal.STEEL_DARK, Color(0.86, 0.82, 0.74)][t]
			k.rbox(Vector3(0.9, 3.2, 3.0), 0.08, stone, MeshKit.at(-2.6, 1.6, -1.4))
			k.rbox(Vector3(0.95, 2.1, 1.8), 0.4, Color(0.08, 0.06, 0.05), MeshKit.at(-2.55, 1.05, -1.4))
			k.rbox(Vector3(1.0, 0.25, 3.2), 0.05, stone.darkened(0.15), MeshKit.at(-2.6, 3.25, -1.4))
			# platform canopy per tier
			var posts: Color = [Pal.WOOD_DARK, Pal.WOOD_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.GOLD][t]
			for sx in [-1.0, 1.0]:
				k.cyl(0.06, 2.4, posts, MeshKit.at(sx * 1.6, 0.35, 0.9), 8)
			var can: Color = [Pal.TERRACOTTA, Pal.SAGE, Pal.CREAM, Pal.STEEL, Pal.CHOCO][t]
			k.rbox(Vector3(4.0, 0.08, 1.6), 0.03, can, MeshKit.xf(Vector3(0, 2.85, 0.5), Vector3(-8, 0, 0)))
			if t >= 2:
				k.rbox(Vector3(1.2, 0.35, 0.06), 0.05, Pal.CREAM, MeshKit.at(0, 2.45, 1.25))
			if t >= 3:
				k.cyl(0.3, 0.05, Color(0.95, 0.94, 0.9), MeshKit.xf(Vector3(1.6, 2.4, 1.0), Vector3(90, 0, 0)), 14)
		"airship":
			# a mooring mast
			var steel: Color = [Pal.WOOD, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.STEEL, Pal.GOLD][t]
			k.rbox(Vector3(3.0, 0.3, 3.0), 0.06, Pal.STONE, MeshKit.at(0, 0.15, -0.6))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.rbox(Vector3(0.12, 4.0, 0.12), 0.02, steel, MeshKit.xf(Vector3(sx * 0.5, 2.1, -0.6 + sz * 0.5), Vector3(-sz * 4, 0, sx * 4)))
			for y in [1.2, 2.4, 3.6]:
				k.rbox(Vector3(1.0, 0.06, 1.0), 0.02, steel, MeshKit.at(0, y, -0.6))
			k.cyl(0.35, 0.3, steel, MeshKit.at(0, 4.1, -0.6), 12, 0.03)
			k.sphere(0.12, Color(1.0, 0.4, 0.3, 0.3), MeshKit.at(0, 4.55, -0.6), 8, 5)
	return k.commit()


## The Delivery Van's depot: a paved bay with a cookie turntable in front
## (the van parks on it), the depot building along the back. Local: footprint
## x -2..2, z -3..3, the street side at +z. Five looks: a plank shed, a brick
## depot, the two-storey Cookie Express, a steel logistics hub, a royal post
## office.
const BAY_Z := 0.75              # turntable centre (local z)
const DEPOT_Z := -2.25           # depot centre (local z), 1.5 m deep


static func _depot(k: MeshKit, t: int) -> void:
	var pave: Color = [Color(0.66, 0.6, 0.52), Color(0.68, 0.64, 0.6), Color(0.74, 0.7, 0.64), Color(0.56, 0.57, 0.58), Color(0.86, 0.82, 0.74)][t]
	var paint: Color = [Pal.CREAM, Pal.CREAM, Pal.CREAM, Color(0.96, 0.8, 0.3), Pal.GOLD][t]
	# the bay: paving, painted edge lines, the turntable
	k.rbox(Vector3(3.9, 0.06, 4.6), 0.04, pave, MeshKit.at(0, 0.03, 0.7))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.08, 0.02, 4.2), 0.01, paint, MeshKit.at(sx * 1.82, 0.065, 0.8))
	if t == 4:
		k.rbox(Vector3(1.2, 0.02, 1.5), 0.01, Color(0.66, 0.22, 0.22), MeshKit.at(0, 0.065, 2.55))
	# depot
	match t:
		0:
			# a plank shed with a lean-to roof and a hand-painted sign
			k.rbox(Vector3(3.8, 2.0, 1.4), 0.04, Pal.WOOD, MeshKit.at(0, 1.0, DEPOT_Z))
			for i in 7:
				k.rbox(Vector3(0.03, 1.9, 0.02), 0.005, Pal.WOOD_DARK, MeshKit.at(-1.6 + i * 0.53, 1.0, DEPOT_Z + 0.71))
			TownArt.gable(k, Vector3(0, 2.0, DEPOT_Z), 3.8, 1.5, 0.6, Pal.TERRACOTTA, Pal.WOOD)
			k.rbox(Vector3(1.6, 1.4, 0.05), 0.03, Pal.WOOD_DARK, MeshKit.at(0, 0.75, DEPOT_Z + 0.72))
			k.rbox(Vector3(1.4, 0.36, 0.06), 0.04, Pal.CREAM, MeshKit.at(0, 1.75, DEPOT_Z + 0.75))
			Items.cookie_into(k, "shortbread", 0.12, 0.03, MeshKit.xf(Vector3(-0.45, 1.75, DEPOT_Z + 0.8), Vector3(90, 0, 0)))
		1:
			# a brick depot under a tiled gable, a roller door and a lamp
			k.rbox(Vector3(3.8, 2.3, 1.4), 0.05, Pal.BRICK, MeshKit.at(0, 1.15, DEPOT_Z))
			k.rbox(Vector3(3.9, 0.14, 1.5), 0.03, Pal.STONE, MeshKit.at(0, 2.3, DEPOT_Z))
			TownArt.gable(k, Vector3(0, 2.36, DEPOT_Z), 3.8, 1.5, 0.75, Pal.TERRACOTTA, Pal.BRICK)
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.71), 1.8, 1.7, Color(0.84, 0.82, 0.78))
			k.rbox(Vector3(1.6, 0.34, 0.06), 0.04, Pal.CREAM, MeshKit.at(0, 2.0, DEPOT_Z + 0.74))
			Items.cookie_into(k, "sugar", 0.12, 0.03, MeshKit.xf(Vector3(-0.5, 2.0, DEPOT_Z + 0.79), Vector3(90, 0, 0)))
			TownArt.lamp_post(k, Vector3(1.75, 0, DEPOT_Z + 1.0), 1.8)
		2:
			# the Cookie Express: two storeys, a clock, an awning over the bay
			k.rbox(Vector3(3.8, 3.4, 1.4), 0.05, Color(0.94, 0.9, 0.8), MeshKit.at(0, 1.7, DEPOT_Z))
			k.rbox(Vector3(3.9, 0.12, 1.5), 0.03, Pal.SAGE, MeshKit.at(0, 1.95, DEPOT_Z))
			TownArt.gable(k, Vector3(0, 3.4, DEPOT_Z), 3.8, 1.5, 0.8, Pal.SAGE, Color(0.94, 0.9, 0.8))
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.71), 2.0, 1.75, Pal.SAGE.lightened(0.2))
			for sx in [-1.0, 1.0]:
				TownArt.window(k, Vector3(sx * 1.15, 2.6, DEPOT_Z + 0.71), 0.6, 0.6, Pal.SAGE, Color(0.6, 0.72, 0.78), true)
			k.cyl(0.32, 0.08, Pal.CREAM, MeshKit.xf(Vector3(0, 2.75, DEPOT_Z + 0.74), Vector3(90, 0, 0)), 16)
			k.torus(0.32, 0.04, Pal.BRASS, MeshKit.xf(Vector3(0, 2.75, DEPOT_Z + 0.78), Vector3(90, 0, 0)), 16, 4)
			k.rbox(Vector3(0.04, 0.22, 0.03), 0.01, Pal.INK, MeshKit.xf(Vector3(0, 2.83, DEPOT_Z + 0.8), Vector3(0, 0, 0)))
			k.rbox(Vector3(0.16, 0.035, 0.03), 0.01, Pal.INK, MeshKit.at(0.07, 2.75, DEPOT_Z + 0.8))
			_awning(k, 3.8, Pal.SAGE, Pal.CREAM)
		3:
			# a steel logistics hub: flat roof, vents, a lit sign, floodlights
			k.rbox(Vector3(3.9, 3.0, 1.45), 0.04, Color(0.72, 0.74, 0.76), MeshKit.at(0, 1.5, DEPOT_Z))
			for i in 9:
				k.rbox(Vector3(0.03, 2.9, 0.02), 0.005, Color(0.6, 0.62, 0.64), MeshKit.at(-1.8 + i * 0.45, 1.5, DEPOT_Z + 0.73))
			k.rbox(Vector3(4.0, 0.16, 1.55), 0.03, Pal.STEEL_DARK, MeshKit.at(0, 3.05, DEPOT_Z))
			for sx in [-1.0, 1.0]:
				k.cyl(0.18, 0.4, Pal.STEEL, MeshKit.at(sx * 1.2, 3.1, DEPOT_Z - 0.2), 10, 0.03)
				k.sphere(0.13, Color(1.0, 0.96, 0.85, 0.35), MeshKit.at(sx * 1.85, 2.7, DEPOT_Z + 0.85), 8, 5)
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.74), 2.6, 2.1, Color(0.86, 0.66, 0.24))
			k.rbox(Vector3(2.2, 0.42, 0.08), 0.06, Pal.STEEL_DARK, MeshKit.at(0, 2.55, DEPOT_Z + 0.78))
			k.rbox(Vector3(2.0, 0.3, 0.09), 0.05, Color(1.0, 0.88, 0.5, 0.5), MeshKit.at(0, 2.55, DEPOT_Z + 0.79))
			_canopy(k, Pal.STEEL_DARK)
		_:
			# a royal post office: cream stone, gold trim, a dome and flags
			var stone := Color(0.95, 0.92, 0.86)
			k.rbox(Vector3(3.9, 3.2, 1.45), 0.05, stone, MeshKit.at(0, 1.6, DEPOT_Z))
			k.rbox(Vector3(4.0, 0.2, 1.55), 0.04, Pal.GOLD, MeshKit.at(0, 3.2, DEPOT_Z))
			for sx in [-1.5, -0.5, 0.5, 1.5]:
				k.cyl(0.13, 3.0, stone.darkened(0.06), MeshKit.at(sx * 1.2, 0, DEPOT_Z + 0.8), 10, 0.02)
				k.cyl(0.17, 0.14, Pal.GOLD, MeshKit.at(sx * 1.2, 2.95, DEPOT_Z + 0.8), 10)
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.73), 1.9, 2.1, Pal.CHOCO)
			k.lathe(PackedVector2Array([Vector2(0.75, 0), Vector2(0.72, 0.35), Vector2(0.55, 0.7), Vector2(0.25, 0.92), Vector2(0.0, 1.0)]), Pal.GOLD, MeshKit.at(0, 3.3, DEPOT_Z), 16)
			k.cyl(0.78, 0.3, stone, MeshKit.at(0, 3.0, DEPOT_Z), 16, 0.03)
			k.sphere(0.12, Pal.GOLD, MeshKit.at(0, 4.4, DEPOT_Z), 8, 5)
			for sx in [-1.0, 1.0]:
				TownArt.flag(k, Vector3(sx * 1.8, 3.3, DEPOT_Z), 1.4, Color(0.66, 0.22, 0.22), Pal.GOLD)
			k.rbox(Vector3(1.4, 0.4, 0.08), 0.1, Pal.CHOCO, MeshKit.at(0, 2.65, DEPOT_Z + 0.82))
			Items.cookie_into(k, "royal", 0.16, 0.04, MeshKit.xf(Vector3(0, 2.65, DEPOT_Z + 0.88), Vector3(90, 0, 0)))
			_canopy(k, Pal.GOLD)
	# windows on the back, for the view from across the street
	var wf: Color = [Pal.WOOD_DARK, Pal.CREAM, Pal.SAGE, Pal.STEEL_DARK, Pal.GOLD][t]
	for sx in [-1.0, 1.0]:
		TownArt.window(k, Vector3(sx * 1.0, 1.3, DEPOT_Z - 0.76), 0.6, 0.55, wf, Color(0.6, 0.72, 0.78), t >= 2)
	# a loading platform along the depot front
	k.rbox(Vector3(3.8, 0.5, 0.36), 0.04, Pal.STONE if t != 3 else Pal.STEEL_DARK, MeshKit.at(0, 0.25, DEPOT_Z + 0.88))
	TownArt.crate(k, Vector3(-1.5, 0.5, DEPOT_Z + 0.88), 0.32)


static func _roller(k: MeshKit, at: Vector3, w: float, h: float, col: Color) -> void:
	k.rbox(Vector3(w + 0.16, h + 0.08, 0.06), 0.03, Pal.STEEL_DARK, MeshKit.at(at.x, h * 0.5, at.z))
	for i in int(h / 0.22):
		k.rbox(Vector3(w, 0.18, 0.05), 0.02, col if i % 2 == 0 else col.darkened(0.06), MeshKit.at(at.x, 0.12 + i * 0.22, at.z + 0.02))


## A striped awning over the front of the depot.
static func _awning(k: MeshKit, w: float, a: Color, b: Color) -> void:
	var n := int(w / 0.48)
	for i in n:
		k.rbox(Vector3(0.48, 0.05, 0.9), 0.015, a if i % 2 == 0 else b, MeshKit.xf(Vector3(-w * 0.5 + 0.24 + i * 0.48, 2.05, DEPOT_Z + 1.1), Vector3(-16, 0, 0)))


## A canopy on posts over the back of the bay.
static func _canopy(k: MeshKit, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		k.cyl(0.07, 2.9, col, MeshKit.at(sx * 1.85, 0, -0.3), 8, 0.02)
	k.rbox(Vector3(4.0, 0.1, 2.0), 0.04, col, MeshKit.at(0, 2.95, -0.75))
	k.rbox(Vector3(4.0, 0.06, 1.9), 0.02, Color(0.9, 0.9, 0.88, 0.75), MeshKit.at(0, 2.88, -0.75))


## The turntable the van parks on: turns it around while it's loaded.
static func turntable(t: int) -> Mesh:
	var k := MeshKit.new()
	var rim: Color = [Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.BRASS, Pal.STEEL_DARK, Pal.GOLD][t]
	k.cyl(1.82, 0.05, rim, MeshKit.at(0, 0.0, 0), 32, 0.02)
	k.cyl(1.7, 0.06, Color(0.5, 0.48, 0.46) if t != 4 else Color(0.62, 0.22, 0.22), MeshKit.at(0, 0.01, 0), 32, 0.02)
	# a big cookie painted in the middle
	k.cyl(0.62, 0.02, Pal.COOKIE, MeshKit.at(0, 0.07, 0), 20)
	for i in 5:
		var a := TAU * i / 5.0
		k.cyl(0.08, 0.02, Pal.CHOCO, MeshKit.at(cos(a) * 0.35, 0.08, sin(a) * 0.35), 8)
	for i in 8:
		var a2 := TAU * i / 8.0
		k.rbox(Vector3(0.9, 0.012, 0.05), 0.005, rim, MeshKit.xf(Vector3(cos(a2) * 1.2, 0.07, sin(a2) * 1.2), Vector3(0, -rad_to_deg(a2), 0)))
	return k.commit()


## Spots around the depot for the things it gains as it levels up.
const DOCK_PROPS := [
	[Vector3(-1.65, 0, 2.75), 0.0], [Vector3(1.6, 0, 2.75), 0.0], [Vector3(1.85, 0, -0.85), 0.0],
	[Vector3(-0.75, 0.5, -1.38), 0.0], [Vector3(-1.85, 0, 2.05), 0.0], [Vector3(-1.85, 0, -0.85), 0.0],
	[Vector3(1.8, 0, 2.0), 90.0], [Vector3(0.75, 0.5, -1.38), 0.0],
]


## Front = +x. Bed / load at -x.
static func van(t: int) -> Mesh:
	var k := MeshKit.new()
	var cab: Color = [Color(0.92, 0.89, 0.81), Color(0.52, 0.6, 0.46), Color(0.24, 0.24, 0.25), Color(0.86, 0.84, 0.8), Color(0.32, 0.18, 0.14)][t]
	var trim: Color = [Pal.TERRACOTTA, Pal.CREAM, Pal.BRASS, Pal.TERRACOTTA, Pal.GOLD][t]
	var dark := Pal.STEEL_DARK
	var glass := Color(0.55, 0.66, 0.72, 0.85)
	k.rbox(Vector3(3.3, 0.24, 1.4), 0.04, dark, MeshKit.at(0, 0.45, 0))
	k.rbox(Vector3(1.05, 1.0, 1.5), 0.12, cab, MeshKit.at(1.1, 1.05, 0))
	k.rbox(Vector3(0.7, 0.3, 1.52), 0.1, cab, MeshKit.at(1.38, 0.68, 0))
	k.rbox(Vector3(0.06, 0.42, 1.26), 0.03, glass, MeshKit.at(1.63, 1.3, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(0.58, 0.38, 0.04), 0.03, glass, MeshKit.at(1.08, 1.3, sz * 0.76))
		k.rbox(Vector3(1.06, 0.06, 0.03), 0.01, trim, MeshKit.at(1.1, 0.86, sz * 0.765))
		k.sphere(0.07, Color(1.0, 0.95, 0.8, 0.5), MeshKit.at(1.73, 0.74, sz * 0.52), 8, 5)
	k.rbox(Vector3(0.05, 0.22, 0.9), 0.02, dark, MeshKit.at(1.75, 0.68, 0))
	k.rbox(Vector3(0.1, 0.12, 1.56), 0.03, dark, MeshKit.at(1.76, 0.48, 0))
	Items.cookie_into(k, "choc", 0.13, 0.03, MeshKit.xf(Vector3(1.05, 1.0, 0.77), Vector3(90, 0, 0)))
	match t:
		0, 1, 2:
			# open slatted bed
			k.rbox(Vector3(2.1, 0.08, 1.5), 0.02, Pal.WOOD_DARK, MeshKit.at(-0.55, 0.62, 0))
			for sz in [-1.0, 1.0]:
				for yy in [0.78, 0.96, 1.14]:
					k.rbox(Vector3(2.1, 0.11, 0.05), 0.015, Pal.WOOD, MeshKit.at(-0.55, yy, sz * 0.72))
				for xx in [-1.55, -0.55, 0.45]:
					k.rbox(Vector3(0.07, 0.6, 0.07), 0.015, dark, MeshKit.at(xx, 0.93, sz * 0.72))
			if t >= 1:
				k.rbox(Vector3(0.6, 0.08, 1.2), 0.03, dark, MeshKit.at(1.1, 1.59, 0))
			if t >= 2:
				for sz in [-1.0, 1.0]:
					k.cyl(0.05, 0.9, Pal.BRASS, MeshKit.at(0.58, 0.9, sz * 0.62), 8, 0.01)
		_:
			# box body with a low open top so the load still shows, roof rails
			k.rbox(Vector3(2.2, 0.08, 1.5), 0.02, dark, MeshKit.at(-0.55, 0.62, 0))
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(2.2, 0.6, 0.06), 0.03, cab.lightened(0.05), MeshKit.at(-0.55, 0.95, sz * 0.73))
				k.rbox(Vector3(2.2, 0.06, 0.07), 0.01, trim, MeshKit.at(-0.55, 1.26, sz * 0.73))
				k.rbox(Vector3(0.8, 0.3, 0.02), 0.04, Pal.CREAM, MeshKit.at(-0.55, 0.95, sz * 0.765))
			k.rbox(Vector3(0.06, 0.6, 1.5), 0.03, cab.lightened(0.05), MeshKit.at(-1.65, 0.95, 0))
			if t == 4:
				for sz in [-1.0, 1.0]:
					k.cyl(0.04, 1.2, Pal.GOLD, MeshKit.xf(Vector3(1.0, 1.65, sz * 0.5), Vector3(0, 0, 90)), 6)
				k.sphere(0.12, Pal.GOLD, MeshKit.at(1.1, 1.72, 0), 8, 5)
	return k.commit()


## Locomotive at -x (front), an open wagon behind it. Load sits at x ~ 0.8.
static func train(t: int) -> Mesh:
	var k := MeshKit.new()
	var body: Color = [Color(0.3, 0.42, 0.36), Color(0.62, 0.3, 0.26), Color(0.24, 0.24, 0.26), Color(0.86, 0.84, 0.8), Color(0.32, 0.18, 0.14)][t]
	var trim: Color = [Pal.BRASS, Pal.CREAM, Pal.BRASS, Pal.TERRACOTTA, Pal.GOLD][t]
	var dark := Pal.STEEL_DARK
	# wheels
	for x in [-2.2, -1.6, -1.0, 0.0, 0.8, 1.6, 2.2]:
		for sz in [-0.55, 0.55]:
			k.cyl(0.24, 0.1, dark, MeshKit.xf(Vector3(x, 0.24, sz), Vector3(90, 0, 0)), 12, 0.02)
	k.rbox(Vector3(5.0, 0.2, 1.2), 0.03, dark, MeshKit.at(0, 0.45, 0))
	if t < 3:
		# steam engine: boiler, cab, chimney
		k.cyl(0.45, 1.6, body, MeshKit.xf(Vector3(-2.6, 1.0, 0), Vector3(0, 0, -90)), 14, 0.04)
		for x in [-2.4, -1.9, -1.4]:
			k.torus(0.46, 0.03, trim, MeshKit.xf(Vector3(x, 1.0, 0), Vector3(0, 0, 90)), 14, 3)
		k.rbox(Vector3(0.9, 1.3, 1.2), 0.08, body, MeshKit.at(-0.65, 1.2, 0))
		k.rbox(Vector3(1.0, 0.1, 1.3), 0.03, dark, MeshKit.at(-0.65, 1.9, 0))
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.4, 0.35, 0.03), 0.03, Color(0.55, 0.66, 0.72, 0.85), MeshKit.at(-0.65, 1.45, sz * 0.61))
		k.cyl(0.13, 0.5, dark, MeshKit.at(-2.65, 1.4, 0), 10, 0.02, 0.17)
		k.cyl(0.19, 0.06, trim, MeshKit.at(-2.65, 1.9, 0), 10)
		k.sphere(0.12, Color(1.0, 0.95, 0.75, 0.4), MeshKit.at(-2.95, 0.9, 0), 8, 5)
	else:
		# streamlined express
		k.rbox(Vector3(2.4, 1.4, 1.24), 0.4, body, MeshKit.at(-1.6, 1.15, 0))
		k.ellipsoid(Vector3(0.7, 0.62, 0.62), body, MeshKit.at(-2.75, 1.05, 0), 12, 8)
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(2.0, 0.08, 0.03), 0.01, trim, MeshKit.at(-1.5, 0.95, sz * 0.62))
			k.rbox(Vector3(1.6, 0.3, 0.03), 0.06, Color(0.55, 0.66, 0.72, 0.85), MeshKit.at(-1.4, 1.45, sz * 0.62))
		k.sphere(0.12, Color(1.0, 0.95, 0.75, 0.4), MeshKit.at(-3.4, 1.0, 0), 8, 5)
		if t == 4:
			k.rbox(Vector3(2.4, 0.06, 0.08), 0.02, Pal.GOLD, MeshKit.at(-1.6, 1.88, 0))
	# open wagon
	var wag: Color = [Pal.WOOD, Pal.WOOD, Pal.STEEL_DARK, Pal.STEEL, Color(0.94, 0.92, 0.86)][t]
	k.rbox(Vector3(2.6, 0.08, 1.3), 0.02, wag.darkened(0.2), MeshKit.at(0.95, 0.62, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(2.6, 0.32, 0.06), 0.02, wag, MeshKit.at(0.95, 0.82, sz * 0.63))
		k.rbox(Vector3(2.6, 0.05, 0.07), 0.01, trim, MeshKit.at(0.95, 0.98, sz * 0.63))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.06, 0.32, 1.3), 0.02, wag, MeshKit.at(0.95 + sx * 1.27, 0.82, 0))
	return k.commit()


## The gondola hangs under the envelope; origin = gondola top.
static func airship(t: int) -> Mesh:
	var k := MeshKit.new()
	var env: Color = [Color(0.92, 0.88, 0.8), Color(0.86, 0.84, 0.8), Color(0.58, 0.64, 0.54), Color(0.78, 0.8, 0.82), Color(0.94, 0.9, 0.8)][t]
	var trim: Color = [Pal.TERRACOTTA, Pal.TERRACOTTA, Pal.CREAM, Pal.STEEL_DARK, Pal.GOLD][t]
	var len := 2.6 + t * 0.25
	k.ellipsoid(Vector3(len, 1.0 + t * 0.06, 1.0 + t * 0.06), env, MeshKit.at(0, 1.3, 0), 18, 10)
	for i in 3:
		k.torus(1.0 + t * 0.06 - absf(i - 1) * 0.25, 0.03, trim, MeshKit.xf(Vector3(-1.0 + i * 1.0, 1.3, 0), Vector3(0, 0, 90), Vector3(1, 1, 1)), 16, 3)
	# fins
	for a in 4:
		k.rbox(Vector3(0.8, 0.05, 0.6), 0.02, trim, MeshKit.xf(Vector3(-len + 0.3, 1.3, 0), Vector3(a * 90.0, 0, 0)) * MeshKit.at(0, 0, 0.7))
	# gondola
	var g: Color = [Pal.WOOD, Pal.WOOD, Pal.WOOD_DARK, Pal.STEEL, Color(0.32, 0.18, 0.14)][t]
	k.rbox(Vector3(1.8, 0.7, 1.0), 0.12, g, MeshKit.at(0, -0.35, 0))
	k.rbox(Vector3(1.6, 0.06, 0.9), 0.02, g.darkened(0.2), MeshKit.at(0, -1.15, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(1.2, 0.24, 0.03), 0.04, Color(0.55, 0.66, 0.72, 0.85), MeshKit.at(0, -0.3, sz * 0.51))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.015, 1.0, Pal.STEEL_DARK, MeshKit.at(sx * 0.8, -1.15, sz * 0.45), 4)
	k.cyl(0.08, 0.3, Pal.STEEL_DARK, MeshKit.xf(Vector3(1.0, -0.35, 0), Vector3(0, 0, -90)), 8)
	for i in 3:
		k.rbox(Vector3(0.04, 0.6, 0.08), 0.02, Pal.BRASS, MeshKit.xf(Vector3(1.32, -0.35, 0), Vector3(i * 60, 0, 0)))
	if t == 4:
		for i in 5:
			var a2 := TAU * i / 5.0
			k.cone(0.06, 0.2, Pal.GOLD, MeshKit.at(cos(a2) * 0.2, 2.35, sin(a2) * 0.2), 6)
	return k.commit()
