class_name SalesArt
## Sales buildings and their vehicles, five tiers each.
## API Depot: a garage -> a server shed -> a glass API office -> a steel hub
##   with a dish -> a graphite HQ with a halo.
## API Van: a white e-van -> teal-striped -> graphite -> box van -> brass.
## Hyperloop Station: a tube portal and a platform; the pod slides into the tube.
## Drone Port: a landing tower; a cargo drone hovers over its pad.


static func lit(c: Color, a := 0.45) -> Color:
	return Color(c.r, c.g, c.b, a)


static func site(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	match kind:
		"van":
			_depot(k, t)
		"hyperloop":
			_station(k, t)
		"droneport":
			_tower(k, t)
	return k.commit()


## The API Depot: a paved bay with a turntable in front (the van parks on
## it), the depot building along the back. Local: footprint x -2..2,
## z -3..3, the street side at +z.
const BAY_Z := 0.75              # turntable centre (local z)
const DEPOT_Z := -2.25           # depot centre (local z), 1.5 m deep


static func _depot(k: MeshKit, t: int) -> void:
	var pave: Color = [Color(0.62, 0.62, 0.6), Color(0.66, 0.66, 0.66), Color(0.74, 0.75, 0.76), Color(0.52, 0.54, 0.58), Color(0.3, 0.31, 0.34)][t]
	var paint: Color = [Pal.CREAM, Pal.CREAM, Color(0.36, 0.76, 0.78), Color(0.96, 0.8, 0.3), Pal.BRASS][t]
	k.rbox(Vector3(3.9, 0.06, 4.6), 0.04, pave, MeshKit.at(0, 0.03, 0.7))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.08, 0.02, 4.2), 0.01, paint, MeshKit.at(sx * 1.82, 0.065, 0.8))
	# an EV charger by the bay
	k.rbox(Vector3(0.3, 1.1, 0.24), 0.05, Color(0.94, 0.95, 0.96), MeshKit.at(1.65, 0.55, -0.6))
	k.rbox(Vector3(0.2, 0.14, 0.02), 0.02, lit(Color(0.5, 1.0, 0.6)), MeshKit.at(1.65, 0.85, -0.47))
	k.cyl(0.02, 0.5, Color(0.2, 0.2, 0.22), MeshKit.xf(Vector3(1.52, 0.6, -0.48), Vector3(0, 0, 40)), 5)
	match t:
		0:
			# a garage with a roll-up door and a hand-painted "API" sign
			k.rbox(Vector3(3.8, 2.0, 1.4), 0.04, Color(0.84, 0.8, 0.72), MeshKit.at(0, 1.0, DEPOT_Z))
			TownArt.gable(k, Vector3(0, 2.0, DEPOT_Z), 3.8, 1.5, 0.5, Color(0.4, 0.42, 0.46), Color(0.84, 0.8, 0.72))
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.71), 2.0, 1.6, Color(0.86, 0.86, 0.84))
			k.rbox(Vector3(1.4, 0.36, 0.06), 0.04, Pal.WOOD, MeshKit.at(0, 1.78, DEPOT_Z + 0.75))
			Items.token_into(k, "pico", 0.12, 0.03, MeshKit.xf(Vector3(-0.45, 1.78, DEPOT_Z + 0.8), Vector3(90, 0, 0)))
			for i in 2:
				k.rbox(Vector3(0.4 - i * 0.12, 0.05, 0.02), 0.01, Color(0.2, 0.22, 0.26), MeshKit.at(0.2, 1.84 - i * 0.1, DEPOT_Z + 0.79))
		1:
			# a corrugated server shed with vents and a lamp
			k.rbox(Vector3(3.8, 2.3, 1.4), 0.05, Color(0.62, 0.66, 0.7), MeshKit.at(0, 1.15, DEPOT_Z))
			for i in 16:
				k.rbox(Vector3(0.03, 2.2, 0.02), 0.005, Color(0.54, 0.58, 0.62), MeshKit.at(-1.8 + i * 0.24, 1.15, DEPOT_Z + 0.71))
			k.rbox(Vector3(3.9, 0.12, 1.5), 0.03, Pal.STEEL_DARK, MeshKit.at(0, 2.32, DEPOT_Z))
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.72), 1.8, 1.7, Color(0.9, 0.9, 0.9))
			k.rbox(Vector3(1.6, 0.34, 0.06), 0.04, Color(0.14, 0.15, 0.18), MeshKit.at(0, 2.0, DEPOT_Z + 0.74))
			Items.token_into(k, "mini", 0.12, 0.03, MeshKit.xf(Vector3(-0.5, 2.0, DEPOT_Z + 0.79), Vector3(90, 0, 0)))
			k.rbox(Vector3(0.7, 0.06, 0.02), 0.02, lit(Color(0.5, 0.9, 1.0)), MeshKit.at(0.25, 2.0, DEPOT_Z + 0.78))
			TownArt.lamp_post(k, Vector3(1.75, 0, DEPOT_Z + 1.0), 1.8)
		2:
			# a white API office with a glass front and a teal band
			k.rbox(Vector3(3.8, 3.2, 1.4), 0.06, Color(0.95, 0.95, 0.96), MeshKit.at(0, 1.6, DEPOT_Z))
			k.rbox(Vector3(3.9, 0.14, 1.5), 0.03, Color(0.3, 0.66, 0.68), MeshKit.at(0, 1.95, DEPOT_Z))
			k.rbox(Vector3(3.9, 0.12, 1.5), 0.03, Color(0.86, 0.88, 0.9), MeshKit.at(0, 3.24, DEPOT_Z))
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.71), 2.0, 1.75, Color(0.9, 0.92, 0.94))
			k.rbox(Vector3(3.4, 0.9, 0.04), 0.03, Color(0.6, 0.82, 0.92, 0.75), MeshKit.at(0, 2.6, DEPOT_Z + 0.71))
			k.rbox(Vector3(1.2, 0.3, 0.06), 0.05, Color(0.14, 0.15, 0.18), MeshKit.at(1.2, 2.0, DEPOT_Z + 0.76))
			k.rbox(Vector3(0.9, 0.08, 0.02), 0.02, lit(Color(0.4, 0.95, 0.9)), MeshKit.at(1.2, 2.0, DEPOT_Z + 0.8))
			_awning(k, 3.8, Color(0.3, 0.66, 0.68), Color(0.95, 0.95, 0.96))
		3:
			# a steel hub with a satellite dish, a lit sign and floodlights
			k.rbox(Vector3(3.9, 3.0, 1.45), 0.04, Color(0.62, 0.66, 0.72), MeshKit.at(0, 1.5, DEPOT_Z))
			for i in 9:
				k.rbox(Vector3(0.03, 2.9, 0.02), 0.005, Color(0.54, 0.58, 0.64), MeshKit.at(-1.8 + i * 0.45, 1.5, DEPOT_Z + 0.73))
			k.rbox(Vector3(4.0, 0.16, 1.55), 0.03, Pal.STEEL_DARK, MeshKit.at(0, 3.05, DEPOT_Z))
			k.cyl(0.06, 0.6, Pal.STEEL_DARK, MeshKit.at(1.2, 3.1, DEPOT_Z), 6)
			k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.5, 0.15), Vector2(0.52, 0.18), Vector2(0, 0.04)]), Color(0.94, 0.95, 0.96), MeshKit.xf(Vector3(1.2, 3.7, DEPOT_Z), Vector3(-40, 0, 0)), 16)
			for sx in [-1.0, 1.0]:
				k.sphere(0.13, lit(Color(1.0, 0.96, 0.85), 0.35), MeshKit.at(sx * 1.85, 2.7, DEPOT_Z + 0.85), 8, 5)
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.74), 2.6, 2.1, Color(0.86, 0.66, 0.24))
			k.rbox(Vector3(2.2, 0.42, 0.08), 0.06, Pal.STEEL_DARK, MeshKit.at(-0.5, 2.55, DEPOT_Z + 0.78))
			k.rbox(Vector3(2.0, 0.3, 0.09), 0.05, lit(Color(0.4, 0.8, 1.0), 0.5), MeshKit.at(-0.5, 2.55, DEPOT_Z + 0.79))
			_canopy(k, Pal.STEEL_DARK)
		_:
			# a graphite HQ with brass fins and a glowing halo on the roof
			var g := Color(0.17, 0.18, 0.21)
			k.rbox(Vector3(3.9, 3.2, 1.45), 0.05, g, MeshKit.at(0, 1.6, DEPOT_Z))
			for sx in [-1.5, -0.5, 0.5, 1.5]:
				k.rbox(Vector3(0.08, 3.0, 0.1), 0.02, Pal.BRASS, MeshKit.at(sx * 1.2, 1.6, DEPOT_Z + 0.76))
			k.rbox(Vector3(4.0, 0.12, 1.55), 0.04, Pal.BRASS, MeshKit.at(0, 3.22, DEPOT_Z))
			_roller(k, Vector3(0, 0, DEPOT_Z + 0.73), 1.9, 2.1, Color(0.24, 0.25, 0.28))
			k.torus(0.7, 0.06, lit(Color(0.4, 0.95, 0.95), 0.4), MeshKit.at(0, 3.7, DEPOT_Z), 24, 5)
			k.cyl(0.08, 0.4, Pal.BRASS, MeshKit.at(0, 3.25, DEPOT_Z), 8)
			k.rbox(Vector3(1.4, 0.4, 0.08), 0.1, Color(0.1, 0.1, 0.12), MeshKit.at(0, 2.65, DEPOT_Z + 0.82))
			Items.token_into(k, "frontier", 0.16, 0.04, MeshKit.xf(Vector3(0, 2.65, DEPOT_Z + 0.88), Vector3(90, 0, 0)))
			_canopy(k, Pal.BRASS)
	# windows on the back, for the view from across the street
	var wf: Color = [Pal.WOOD_DARK, Pal.STEEL_DARK, Color(0.3, 0.66, 0.68), Pal.STEEL_DARK, Pal.BRASS][t]
	for sx in [-1.0, 1.0]:
		TownArt.window(k, Vector3(sx * 1.0, 1.3, DEPOT_Z - 0.76), 0.6, 0.55, wf, Color(0.6, 0.78, 0.86, 0.7) if t >= 3 else Color(0.6, 0.72, 0.78), false)
	# a loading platform along the depot front
	k.rbox(Vector3(3.8, 0.5, 0.36), 0.04, Pal.STONE if t < 3 else Pal.STEEL_DARK, MeshKit.at(0, 0.25, DEPOT_Z + 0.88))
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
	var rim: Color = [Pal.STEEL_DARK, Pal.STEEL_DARK, Color(0.3, 0.66, 0.68), Pal.STEEL_DARK, Pal.BRASS][t]
	k.cyl(1.82, 0.05, rim, MeshKit.at(0, 0.0, 0), 32, 0.02)
	k.cyl(1.7, 0.06, Color(0.42, 0.44, 0.48) if t != 4 else Color(0.18, 0.19, 0.22), MeshKit.at(0, 0.01, 0), 32, 0.02)
	# a big token painted in the middle
	Items.token_into(k, ["pico", "mini", "chat7", "code13", "frontier"][t], 0.62, 0.03, MeshKit.at(0, 0.06, 0))
	for i in 8:
		var a2 := TAU * i / 8.0
		k.rbox(Vector3(0.9, 0.012, 0.05), 0.005, lit(Color(0.4, 0.9, 1.0), 0.5) if t >= 3 else rim, MeshKit.xf(Vector3(cos(a2) * 1.2, 0.07, sin(a2) * 1.2), Vector3(0, -rad_to_deg(a2), 0)))
	return k.commit()


## The API van. Front = +x. Load bay at -x (open on top so the load shows).
static func van(t: int) -> Mesh:
	var k := MeshKit.new()
	var body: Color = [Color(0.95, 0.95, 0.94), Color(0.95, 0.95, 0.94), Color(0.2, 0.21, 0.24), Color(0.9, 0.91, 0.92), Color(0.16, 0.17, 0.2)][t]
	var trim: Color = [Color(0.3, 0.6, 0.86), Color(0.3, 0.66, 0.68), Color(0.4, 0.9, 0.9), Color(0.96, 0.6, 0.3), Pal.BRASS][t]
	var dark := Pal.STEEL_DARK
	var glass := Color(0.36, 0.46, 0.56, 0.85)
	k.rbox(Vector3(3.3, 0.24, 1.4), 0.04, dark, MeshKit.at(0, 0.45, 0))
	# a rounded electric cab with a big windscreen and a light bar
	k.rbox(Vector3(1.1, 1.05, 1.5), 0.25, body, MeshKit.at(1.08, 1.05, 0))
	k.rbox(Vector3(0.12, 0.5, 1.3), 0.08, glass, MeshKit.xf(Vector3(1.58, 1.25, 0), Vector3(0, 0, -12)))
	k.rbox(Vector3(0.05, 0.05, 1.2), 0.02, lit(Color(0.9, 0.97, 1.0), 0.4), MeshKit.at(1.66, 0.7, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(0.6, 0.38, 0.04), 0.06, glass, MeshKit.at(1.05, 1.3, sz * 0.76))
		k.rbox(Vector3(3.2, 0.08, 0.03), 0.01, trim, MeshKit.at(0.0, 0.8, sz * 0.765))
	k.rbox(Vector3(0.1, 0.12, 1.56), 0.03, dark, MeshKit.at(1.72, 0.48, 0))
	Items.token_into(k, "chat7", 0.13, 0.03, MeshKit.xf(Vector3(1.05, 0.98, 0.77), Vector3(90, 0, 0)))
	if t >= 1:
		# a roof antenna
		k.cyl(0.015, 0.4, Pal.STEEL_DARK, MeshKit.at(1.0, 1.55, 0.3), 5)
		k.sphere(0.04, lit(Color(1.0, 0.4, 0.4), 0.4), MeshKit.at(1.0, 1.96, 0.3), 6, 4)
	match t:
		0, 1, 2:
			# an open cargo tray with low sides
			k.rbox(Vector3(2.1, 0.08, 1.5), 0.02, dark, MeshKit.at(-0.55, 0.62, 0))
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(2.1, 0.4, 0.06), 0.03, body.darkened(0.05), MeshKit.at(-0.55, 0.86, sz * 0.72))
				k.rbox(Vector3(2.1, 0.05, 0.07), 0.01, trim, MeshKit.at(-0.55, 1.07, sz * 0.72))
			k.rbox(Vector3(0.06, 0.4, 1.5), 0.03, body.darkened(0.05), MeshKit.at(-1.62, 0.86, 0))
		_:
			# a box body with a low open top so the load still shows, roof rails
			k.rbox(Vector3(2.2, 0.08, 1.5), 0.02, dark, MeshKit.at(-0.55, 0.62, 0))
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(2.2, 0.6, 0.06), 0.03, body, MeshKit.at(-0.55, 0.95, sz * 0.73))
				k.rbox(Vector3(2.2, 0.06, 0.07), 0.01, trim, MeshKit.at(-0.55, 1.26, sz * 0.73))
				k.rbox(Vector3(0.8, 0.3, 0.02), 0.04, Color(0.14, 0.15, 0.18) if t == 3 else Pal.BRASS, MeshKit.at(-0.55, 0.95, sz * 0.765))
			k.rbox(Vector3(0.06, 0.6, 1.5), 0.03, body, MeshKit.at(-1.65, 0.95, 0))
			if t == 4:
				k.torus(0.3, 0.03, lit(Color(0.4, 0.95, 0.95), 0.4), MeshKit.at(1.05, 1.62, 0), 16, 4)
	return k.commit()


## The hyperloop station: a platform, a guideway and the tube portal the
## pod slides into (on the left).
static func _station(k: MeshKit, t: int) -> void:
	var plat: Color = [Color(0.72, 0.7, 0.66), Color(0.74, 0.75, 0.76), Color(0.9, 0.91, 0.92), Color(0.6, 0.64, 0.7), Color(0.22, 0.23, 0.26)][t]
	k.rbox(Vector3(6.0, 0.35, 1.6), 0.04, plat, MeshKit.at(0, 0.17, 0.4))
	k.rbox(Vector3(6.0, 0.06, 0.18), 0.02, Color(0.96, 0.8, 0.26) if t < 4 else Pal.BRASS, MeshKit.at(0, 0.36, -0.3))
	# the guideway: a concrete trough with a glowing magnetic rail
	k.rbox(Vector3(6.0, 0.08, 2.0), 0.02, Color(0.46, 0.48, 0.5), MeshKit.at(0, 0.03, -1.4))
	for sz in [-0.55, 0.55]:
		k.rbox(Vector3(6.0, 0.16, 0.14), 0.02, Color(0.62, 0.64, 0.66), MeshKit.at(0, 0.1, -1.4 + sz))
	k.rbox(Vector3(6.0, 0.03, 0.08), 0.01, lit(Color(0.4, 0.9, 1.0), 0.45), MeshKit.at(0, 0.09, -1.4))
	# the tube portal on the left
	var shell: Color = [Color(0.6, 0.6, 0.58), Color(0.62, 0.66, 0.7), Color(0.94, 0.95, 0.96), Color(0.5, 0.54, 0.6), Color(0.17, 0.18, 0.21)][t]
	k.rbox(Vector3(0.9, 3.2, 3.0), 0.12, shell, MeshKit.at(-2.6, 1.6, -1.4))
	k.cyl(1.0, 0.95, shell.darkened(0.15), MeshKit.xf(Vector3(-2.1, 1.05, -1.4), Vector3(0, 0, 90)), 20, 0.04)
	k.cyl(0.85, 1.0, Color(0.06, 0.06, 0.08), MeshKit.xf(Vector3(-2.08, 1.05, -1.4), Vector3(0, 0, 90)), 20)
	k.torus(0.92, 0.05, lit(Color(0.4, 0.9, 1.0), 0.4), MeshKit.xf(Vector3(-2.12, 1.05, -1.4), Vector3(0, 0, 90)), 20, 4)
	k.rbox(Vector3(1.0, 0.25, 3.2), 0.05, shell.darkened(0.15), MeshKit.at(-2.6, 3.25, -1.4))
	# platform canopy per tier
	var posts: Color = [Pal.WOOD_DARK, Pal.STEEL_DARK, Color(0.94, 0.95, 0.96), Pal.STEEL_DARK, Pal.BRASS][t]
	for sx in [-1.0, 1.0]:
		k.cyl(0.06, 2.4, posts, MeshKit.at(sx * 1.6, 0.35, 0.9), 8)
	var can: Color = [Color(0.4, 0.42, 0.46), Color(0.3, 0.6, 0.86), Color(0.95, 0.95, 0.96), Color(0.62, 0.66, 0.72), Color(0.17, 0.18, 0.21)][t]
	k.rbox(Vector3(4.0, 0.08, 1.6), 0.03, can, MeshKit.xf(Vector3(0, 2.85, 0.5), Vector3(-8, 0, 0)))
	if t >= 1:
		k.rbox(Vector3(4.0, 0.03, 0.04), 0.01, lit(Color(0.4, 0.9, 1.0), 0.45), MeshKit.xf(Vector3(0, 2.8, 1.28), Vector3(-8, 0, 0)))
	if t >= 2:
		k.rbox(Vector3(1.2, 0.35, 0.06), 0.05, Color(0.14, 0.15, 0.18), MeshKit.at(0, 2.45, 1.25))
		k.rbox(Vector3(1.0, 0.08, 0.02), 0.02, lit(Color(1.0, 0.8, 0.4), 0.45), MeshKit.at(0, 2.45, 1.29))
	if t >= 3:
		k.cyl(0.3, 0.05, Color(0.95, 0.94, 0.9), MeshKit.xf(Vector3(1.6, 2.4, 1.0), Vector3(90, 0, 0)), 14)


## The hyperloop pod at -x (nose), an open cargo carriage behind. Load
## sits at x ~ 0.95.
static func train(t: int) -> Mesh:
	var k := MeshKit.new()
	var body: Color = [Color(0.92, 0.93, 0.94), Color(0.92, 0.93, 0.94), Color(0.3, 0.6, 0.86), Color(0.86, 0.88, 0.9), Color(0.17, 0.18, 0.21)][t]
	var trim: Color = [Color(0.3, 0.6, 0.86), Color(0.96, 0.6, 0.3), Color(0.95, 0.95, 0.96), Color(0.4, 0.9, 0.9), Pal.BRASS][t]
	var dark := Pal.STEEL_DARK
	# maglev skids
	for sz in [-0.55, 0.55]:
		k.rbox(Vector3(5.0, 0.14, 0.18), 0.04, dark, MeshKit.at(0, 0.26, sz))
	k.rbox(Vector3(5.0, 0.16, 1.2), 0.04, dark, MeshKit.at(0, 0.42, 0))
	# the pod: a capsule with a pointed nose and a window band
	k.capsule(0.62, 2.6, body, MeshKit.xf(Vector3(-0.4, 1.1, 0), Vector3(0, 0, 90)), 18, 5)
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(1.6, 0.26, 0.04), 0.1, Color(0.3, 0.38, 0.48, 0.85), MeshKit.at(-1.6, 1.25, sz * 0.6))
		k.rbox(Vector3(2.4, 0.06, 0.04), 0.02, trim, MeshKit.at(-1.6, 0.92, sz * 0.61))
	k.sphere(0.1, lit(Color(0.9, 0.97, 1.0), 0.35), MeshKit.at(-3.05, 1.05, 0), 8, 5)
	if t == 4:
		k.rbox(Vector3(2.4, 0.05, 0.08), 0.02, Pal.BRASS, MeshKit.at(-1.6, 1.72, 0))
	# open cargo carriage
	var wag: Color = [Color(0.6, 0.62, 0.66), Color(0.6, 0.62, 0.66), Color(0.86, 0.88, 0.9), Color(0.62, 0.66, 0.72), Color(0.24, 0.25, 0.28)][t]
	k.rbox(Vector3(2.6, 0.08, 1.3), 0.02, wag.darkened(0.2), MeshKit.at(0.95, 0.62, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(2.6, 0.32, 0.06), 0.02, wag, MeshKit.at(0.95, 0.82, sz * 0.63))
		k.rbox(Vector3(2.6, 0.05, 0.07), 0.01, lit(trim, 0.5), MeshKit.at(0.95, 0.98, sz * 0.63))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.06, 0.32, 1.3), 0.02, wag, MeshKit.at(0.95 + sx * 1.27, 0.82, 0))
	return k.commit()


## The drone port: a landing tower with a pad on top.
static func _tower(k: MeshKit, t: int) -> void:
	var steel: Color = [Pal.WOOD, Pal.STEEL_DARK, Color(0.92, 0.93, 0.94), Color(0.5, 0.54, 0.6), Color(0.17, 0.18, 0.21)][t]
	k.rbox(Vector3(3.0, 0.3, 3.0), 0.06, Color(0.56, 0.57, 0.58), MeshKit.at(0, 0.15, -0.6))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.12, 3.8, 0.12), 0.02, steel, MeshKit.xf(Vector3(sx * 0.55, 2.0, -0.6 + sz * 0.55), Vector3(-sz * 3, 0, sx * 3)))
	for y in [1.2, 2.4]:
		k.rbox(Vector3(1.1, 0.06, 1.1), 0.02, steel, MeshKit.at(0, y, -0.6))
	# the pad: a disc with an H and a ring of lights
	k.cyl(1.25, 0.14, steel, MeshKit.at(0, 3.85, -0.6), 24, 0.03)
	k.cyl(1.1, 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0, 3.99, -0.6), 24)
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.1, 0.012, 0.7), 0.004, Color(0.96, 0.96, 0.94), MeshKit.at(sx * 0.25, 4.01, -0.6))
	k.rbox(Vector3(0.5, 0.012, 0.1), 0.004, Color(0.96, 0.96, 0.94), MeshKit.at(0, 4.01, -0.6))
	for i in 8:
		var a := TAU * i / 8.0
		k.sphere(0.05, lit(Color(0.4, 1.0, 0.6) if t < 4 else Color(1.0, 0.86, 0.5), 0.4), MeshKit.at(cos(a) * 1.15, 4.02, -0.6 + sin(a) * 1.15), 6, 4)
	if t >= 2:
		# a control cabin at the foot of the tower
		k.rbox(Vector3(1.0, 1.0, 0.8), 0.05, Color(0.94, 0.95, 0.96) if t != 4 else Color(0.24, 0.25, 0.28), MeshKit.at(1.0, 0.8, 0.4))
		k.rbox(Vector3(0.8, 0.4, 0.02), 0.03, Color(0.5, 0.72, 0.86, 0.8), MeshKit.at(1.0, 0.95, 0.81))
	if t >= 3:
		k.cyl(0.03, 1.0, Pal.STEEL_DARK, MeshKit.at(-1.1, 3.9, -0.6), 5)
		k.sphere(0.07, lit(Color(1.0, 0.3, 0.3), 0.35), MeshKit.at(-1.1, 4.95, -0.6), 6, 4)


## The cargo drone; origin = the top of its cargo basket (the load sits in
## the basket at y = -1.15).
static func airship(t: int) -> Mesh:
	var k := MeshKit.new()
	var body: Color = [Color(0.95, 0.95, 0.94), Color(0.95, 0.95, 0.94), Color(0.3, 0.6, 0.86), Color(0.86, 0.88, 0.9), Color(0.17, 0.18, 0.21)][t]
	var trim: Color = [Color(0.3, 0.6, 0.86), Color(0.96, 0.6, 0.3), Color(0.95, 0.95, 0.96), Color(0.4, 0.9, 0.9), Pal.BRASS][t]
	var s := 1.0 + t * 0.08
	# body
	k.rbox(Vector3(1.6, 0.5, 1.2) * s, 0.2, body, MeshKit.at(0, 0.35, 0))
	k.rbox(Vector3(1.62, 0.08, 1.22) * s, 0.03, trim, MeshKit.at(0, 0.3, 0))
	k.rbox(Vector3(0.4, 0.14, 0.04), 0.04, lit(Color(0.5, 0.95, 1.0), 0.4), MeshKit.at(0.82 * s, 0.38, 0))
	# four arms with rotors
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		var p := Vector3(cos(a) * 1.1 * s, 0.5, sin(a) * 1.1 * s)
		k.rbox(Vector3(1.0 * s, 0.1, 0.14), 0.04, Pal.STEEL_DARK, MeshKit.xf(p * 0.55 + Vector3(0, 0, 0), Vector3(0, -rad_to_deg(a), 0)))
		k.cyl(0.12, 0.18, Pal.STEEL_DARK, MeshKit.at(p.x, p.y - 0.05, p.z), 10, 0.02)
		k.cyl(0.42 * s, 0.02, Color(0.8, 0.84, 0.88, 0.85), MeshKit.at(p.x, p.y + 0.16, p.z), 20)
		k.torus(0.42 * s, 0.025, trim, MeshKit.at(p.x, p.y + 0.17, p.z), 20, 4)
	# the cargo basket hanging below
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.02, 1.1, Pal.STEEL_DARK, MeshKit.at(sx * 0.75, -1.15, sz * 0.45), 4)
	k.rbox(Vector3(1.8, 0.06, 1.0), 0.02, Pal.STEEL_DARK, MeshKit.at(0, -1.18, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(1.8, 0.22, 0.04), 0.02, body.darkened(0.08), MeshKit.at(0, -1.06, sz * 0.5))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.04, 0.22, 1.0), 0.02, body.darkened(0.08), MeshKit.at(sx * 0.9, -1.06, 0))
	if t == 4:
		k.sphere(0.12, lit(Color(1.0, 0.86, 0.5), 0.35), MeshKit.at(0, 0.7, 0), 10, 6)
	return k.commit()
