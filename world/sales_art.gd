class_name SalesArt
## Sales buildings and their vehicles, five tiers each.
## Van: cream van -> sage truck -> charcoal + brass -> box truck -> royal coach.
## Train: little tank engine -> ... -> streamlined golden express.
## Airship: canvas blimp -> ... -> royal zeppelin with gold fins.


static func site(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	match kind:
		"dock":
			# driveway + garage with a roller door at the back
			k.rbox(Vector3(3.6, 0.05, 4.8), 0.03, Color(0.55, 0.54, 0.52), MeshKit.at(0, 0.02, -0.4))
			for i in 4:
				k.rbox(Vector3(0.1, 0.06, 0.6), 0.02, Pal.CREAM, MeshKit.at(0, 0.05, 1.4 - i * 1.1))
			var wall: Color = [Color(0.92, 0.88, 0.8), Color(0.88, 0.84, 0.76), Pal.BRICK, Color(0.7, 0.72, 0.74), Color(0.94, 0.92, 0.86)][t]
			var roof: Color = [Pal.TERRACOTTA, Pal.SAGE, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.CHOCO][t]
			k.rbox(Vector3(4.0, 2.6, 1.4), 0.06, wall, MeshKit.at(0, 1.3, -2.3))
			k.rbox(Vector3(4.2, 0.14, 1.6), 0.04, roof, MeshKit.at(0, 2.68, -2.3))
			k.rbox(Vector3(3.0, 2.2, 0.05), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 1.1, -1.58))
			if t >= 2:
				k.rbox(Vector3(1.4, 0.4, 0.06), 0.05, Pal.CREAM, MeshKit.at(0, 2.45, -1.55))
				Items.cookie_into(k, "choc", 0.14, 0.04, MeshKit.xf(Vector3(0, 2.45, -1.5), Vector3(90, 0, 0)))
			if t >= 3:
				for sx in [-1.0, 1.0]:
					k.sphere(0.12, Color(1.0, 0.92, 0.7, 0.4), MeshKit.at(sx * 1.75, 2.3, -1.5), 8, 5)
			if t >= 4:
				k.rbox(Vector3(4.24, 0.08, 1.64), 0.02, Pal.GOLD, MeshKit.at(0, 2.78, -2.3))
				for sx in [-1.0, 1.0]:
					k.cone(0.12, 0.4, Pal.GOLD, MeshKit.at(sx * 1.9, 2.8, -1.6), 8)
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


static func garage_door() -> Mesh:
	var k := MeshKit.new()
	# hangs from its top edge (origin) and shrinks upward to open
	for i in 8:
		k.rbox(Vector3(2.9, 0.26, 0.06), 0.02, Color(0.84, 0.82, 0.78) if i % 2 == 0 else Color(0.78, 0.76, 0.72), MeshKit.at(0, -0.14 - i * 0.27, 0))
	return k.commit()


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
