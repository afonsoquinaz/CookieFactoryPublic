class_name GrowthParts
## The things buildings gain as they level up (see Growth), each in four
## grades: the first upgrade puts a small one down, later ones make it
## bigger, then add a second, then make it glow. Every part is drawn at the
## origin facing +Z, in the colours of the building's tier (t 0..4: garage
## wood, steel, white and teal, dark steel with blue LEDs, black and brass).
##   floor parts stand on the ground in about 0.75 x 0.75 m
##   top parts sit on a flat roof or wall top in about 0.7 x 0.5 m
##   wall parts hang on a wall face (the wall is at z = 0)

const FLOOR := ["cabinet", "crates", "battery", "plant", "lamp", "robot", "tanks", "drums", "reels", "kiosk",
	"chiller", "pallet", "mast", "dish", "solar", "drone", "gen", "bench", "bikes", "sandbags", "wafers", "books", "pumps", "ore"]
const TOP := ["ac", "dish_s", "antenna", "solar_s", "vent", "tank_s", "beacon", "sign"]
const WALL := ["screen", "ledbar", "neon", "panel"]


## What each part is called (for "Next level: ..." and the pop-up).
const NAMES := {
	"cabinet": "Server Cabinet", "crates": "GPU Crates", "battery": "Battery Pack", "plant": "Plants", "lamp": "Lights",
	"robot": "Robot", "tanks": "Gas Tanks", "drums": "Drums", "reels": "Cable Reels", "kiosk": "Info Screen",
	"chiller": "Chiller", "pallet": "Token Pallet", "mast": "Antenna Mast", "dish": "Satellite Dish", "solar": "Solar Panels",
	"drone": "Drone Pad", "gen": "Generator", "bench": "Bench", "bikes": "E-Scooters", "sandbags": "Sand Sacks",
	"wafers": "Wafer Boxes", "books": "Paper Stacks", "pumps": "Coolant Pumps", "ore": "Ore Cart",
	"ac": "Rooftop AC", "dish_s": "Rooftop Dish", "antenna": "Antennas", "solar_s": "Rooftop Solar", "vent": "Vents",
	"tank_s": "Water Tank", "beacon": "Beacon", "sign": "Rooftop Sign",
	"screen": "Dashboard", "ledbar": "LED Strip", "neon": "Neon Sign", "panel": "Patch Panel",
}

## How each grade reads: new, bigger, more, glowing.
const GRADE_WORDS := ["New", "Bigger", "More", "Glowing"]


static func body(t: int) -> Color:
	return [Color(0.8, 0.74, 0.62), Color(0.72, 0.74, 0.77), Color(0.94, 0.95, 0.96), Color(0.32, 0.34, 0.38), Color(0.18, 0.19, 0.22)][clampi(t, 0, 4)]


static func trim(t: int) -> Color:
	return [Pal.WOOD, Color(0.42, 0.44, 0.48), Color(0.3, 0.66, 0.68), Color(0.24, 0.26, 0.3), Pal.BRASS][clampi(t, 0, 4)]


static func led(t: int) -> Color:
	return [Color(1.0, 0.82, 0.5), Color(0.6, 1.0, 0.62), Color(0.42, 0.96, 0.9), Color(0.45, 0.75, 1.0), Color(1.0, 0.86, 0.5)][clampi(t, 0, 4)]


static func lit(c: Color, a := 0.4) -> Color:
	return Items.lit(c, a)


## Draws part `name` at grade g (0..3) into k at transform x.
static func draw(k: MeshKit, name: String, g: int, t: int, x: Transform3D, col := Color(0.3, 0.66, 0.68)) -> void:
	g = clampi(g, 0, 3)
	var b := body(t)
	var tr := trim(t)
	var l := led(t)
	match name:
		# ---------------------------------------------------------------- floor
		"cabinet":
			# an outdoor server cabinet; then a taller one; then a pair; then glowing
			var n := 2 if g >= 2 else 1
			var h: float = [0.7, 1.05, 1.05, 1.15][g]
			for i in n:
				var cx := 0.0 if n == 1 else -0.2 + i * 0.4
				var w := 0.5 if n == 1 else 0.36
				k.rbox(Vector3(w, h, 0.45), 0.03, b, x * MeshKit.at(cx, h * 0.5, 0))
				k.rbox(Vector3(w - 0.08, h - 0.16, 0.02), 0.02, b.darkened(0.12), x * MeshKit.at(cx, h * 0.5, 0.23))
				k.rbox(Vector3(w + 0.04, 0.05, 0.49), 0.02, tr, x * MeshKit.at(cx, h + 0.02, 0))
				var rows := 2 + g
				for j in rows:
					k.rbox(Vector3(0.05, 0.03, 0.01), 0.008, lit(l if j % 3 else Color(0.5, 1.0, 0.6)), x * MeshKit.at(cx - w * 0.25, h - 0.15 - j * 0.12, 0.245))
				if g >= 3:
					k.rbox(Vector3(0.025, h - 0.2, 0.01), 0.008, lit(l, 0.3), x * MeshKit.at(cx + w * 0.3, h * 0.5, 0.245))
		"crates":
			# GPU shipping crates stacking up, the last one open with a glowing card
			var wood: Color = Pal.WOOD if t < 2 else Color(0.36, 0.4, 0.46)
			var sizes := [[Vector3(0, 0, 0), 0.5, 0.0], [Vector3(0.05, 0.5, 0.02), 0.42, 14.0], [Vector3(-0.02, 0.92, -0.02), 0.34, -10.0]]
			for i in mini(g + 1, 3):
				var s: Array = sizes[i]
				var p: Vector3 = s[0]
				var sz: float = s[1]
				var cx := x * MeshKit.xf(p + Vector3(0, sz * 0.5, 0), Vector3(0, s[2], 0))
				k.rbox(Vector3(sz * 1.3, sz, sz), 0.03, wood, cx)
				k.rbox(Vector3(sz * 1.32, 0.05, sz * 1.02), 0.01, wood.darkened(0.2), cx * MeshKit.at(0, sz * 0.3, 0))
				k.rbox(Vector3(sz * 0.5, sz * 0.3, 0.01), 0.01, Color(0.96, 0.94, 0.88), cx * MeshKit.at(0, 0, sz * 0.5 + 0.005))
				k.rbox(Vector3(0.08, 0.08, 0.012), 0.01, col, cx * MeshKit.at(-sz * 0.12, 0, sz * 0.5 + 0.01))
			if g >= 3:
				# a graphics card leaning on the stack
				k.rbox(Vector3(0.5, 0.26, 0.06), 0.02, Color(0.16, 0.17, 0.2), x * MeshKit.xf(Vector3(0.0, 0.3, 0.42), Vector3(-12, 0, 0)))
				for sx in [-0.12, 0.12]:
					k.cyl(0.08, 0.02, Color(0.3, 0.32, 0.36), x * MeshKit.xf(Vector3(sx, 0.31, 0.455), Vector3(78, 0, 0)), 12)
				k.rbox(Vector3(0.44, 0.03, 0.02), 0.01, lit(l, 0.3), x * MeshKit.xf(Vector3(0, 0.18, 0.45), Vector3(-12, 0, 0)))
		"battery":
			# a battery pack with charge bars; then two; then glowing tops
			var n2 := 1 if g < 2 else 2
			var h2: float = [0.55, 0.85, 0.85, 0.85][g]
			for i in n2:
				var cx2 := 0.0 if n2 == 1 else -0.19 + i * 0.38
				var w2 := 0.55 if n2 == 1 else 0.34
				k.rbox(Vector3(w2, h2, 0.42), 0.04, Color(0.92, 0.93, 0.94) if t != 4 else Color(0.2, 0.21, 0.24), x * MeshKit.at(cx2, h2 * 0.5, 0))
				k.rbox(Vector3(w2 + 0.02, 0.06, 0.44), 0.02, Color(0.46, 0.82, 0.52), x * MeshKit.at(cx2, h2 - 0.03, 0))
				for j in 4:
					var on := j < 2 + (g % 2) + i
					k.rbox(Vector3(w2 * 0.6, 0.05, 0.01), 0.01, lit(Color(0.5, 1.0, 0.6)) if on else Color(0.4, 0.42, 0.46), x * MeshKit.at(cx2, 0.12 + j * 0.09, 0.215))
				if g >= 3:
					k.rbox(Vector3(w2 - 0.06, 0.02, 0.36), 0.01, lit(Color(0.5, 1.0, 0.6), 0.3), x * MeshKit.at(cx2, h2 + 0.01, 0))
		"plant":
			# a potted plant; a shrub; a little tree; a tree in a lit planter
			var pot: Color = [Pal.TERRACOTTA, Color(0.86, 0.87, 0.88), Color(0.94, 0.95, 0.96), Color(0.3, 0.32, 0.36), Color(0.2, 0.21, 0.24)][clampi(t, 0, 4)]
			match g:
				0:
					k.cyl(0.16, 0.26, pot, x * MeshKit.at(0, 0, 0), 10, 0.02, 0.12)
					k.sphere(0.2, Pal.LEAF, x * MeshKit.at(0, 0.4, 0), 9, 6)
				1:
					k.cyl(0.24, 0.34, pot, x * MeshKit.at(0, 0, 0), 12, 0.02, 0.19)
					k.sphere(0.28, Pal.LEAF_DARK, x * MeshKit.at(0, 0.56, 0), 10, 7)
					k.sphere(0.2, Pal.LEAF, x * MeshKit.at(0.12, 0.72, 0.06), 9, 6)
				_:
					k.rbox(Vector3(0.62, 0.36, 0.62), 0.05, pot, x * MeshKit.at(0, 0.18, 0))
					k.rbox(Vector3(0.54, 0.04, 0.54), 0.02, Pal.SOIL, x * MeshKit.at(0, 0.36, 0))
					k.cyl(0.05, 0.7, Pal.WOOD_DARK, x * MeshKit.at(0, 0.36, 0), 6)
					k.sphere(0.36, Pal.LEAF_DARK, x * MeshKit.at(0, 1.2, 0), 10, 7)
					k.sphere(0.26, Pal.LEAF, x * MeshKit.at(0.14, 1.38, 0.1), 9, 6)
					if g >= 3:
						k.rbox(Vector3(0.64, 0.03, 0.03), 0.01, lit(l, 0.3), x * MeshKit.at(0, 0.3, 0.31))
		"lamp":
			# a bollard light; a taller one; a lamp post; a lamp post with a banner
			match g:
				0, 1:
					var h3 := 0.55 if g == 0 else 0.85
					k.cyl(0.08, h3, b if t != 0 else Pal.WOOD_DARK, x * MeshKit.at(0, 0, 0), 10)
					k.cyl(0.085, 0.1, lit(l), x * MeshKit.at(0, h3 - 0.16, 0), 10)
					k.cyl(0.1, 0.04, tr, x * MeshKit.at(0, h3, 0), 10)
				_:
					k.cyl(0.12, 0.12, tr, x * MeshKit.at(0, 0, 0), 10)
					k.cyl(0.045, 2.2, b if t >= 2 else Color(0.3, 0.32, 0.36), x * MeshKit.at(0, 0.1, 0), 8)
					k.rbox(Vector3(0.5, 0.07, 0.16), 0.03, b if t >= 2 else Color(0.3, 0.32, 0.36), x * MeshKit.at(0.18, 2.3, 0))
					k.rbox(Vector3(0.36, 0.03, 0.12), 0.01, lit(Color(0.92, 0.97, 1.0), 0.35), x * MeshKit.at(0.22, 2.25, 0))
					if g >= 3:
						k.rbox(Vector3(0.03, 0.7, 0.36), 0.01, col, x * MeshKit.at(-0.06, 1.75, 0.2))
						k.rbox(Vector3(0.035, 0.08, 0.38), 0.01, tr, x * MeshKit.at(-0.06, 2.12, 0.2))
		"robot":
			# a cleaning robot; a robot dog; a helper robot; it gets a glowing visor
			match g:
				0:
					k.cyl(0.2, 0.08, Color(0.94, 0.95, 0.96), x * MeshKit.at(0, 0.02, 0), 14, 0.03)
					k.cyl(0.05, 0.02, lit(l), x * MeshKit.at(0, 0.1, 0.05), 8)
				1:
					k.rbox(Vector3(0.22, 0.18, 0.46), 0.07, Color(0.92, 0.82, 0.3), x * MeshKit.at(0, 0.36, 0))
					k.rbox(Vector3(0.16, 0.14, 0.18), 0.05, Color(0.2, 0.21, 0.24), x * MeshKit.at(0, 0.48, 0.28))
					for sx in [-0.09, 0.09]:
						for sz in [-0.16, 0.16]:
							k.cyl(0.025, 0.28, Color(0.2, 0.21, 0.24), x * MeshKit.at(sx, 0.0, sz), 6)
				_:
					k.rbox(Vector3(0.3, 0.36, 0.22), 0.08, Color(0.95, 0.95, 0.94), x * MeshKit.at(0, 0.62, 0))
					k.rbox(Vector3(0.26, 0.22, 0.22), 0.08, Color(0.95, 0.95, 0.94), x * MeshKit.at(0, 0.98, 0))
					k.rbox(Vector3(0.2, 0.07, 0.02), 0.03, lit(Color(0.5, 0.95, 1.0)) if g >= 3 else Color(0.2, 0.21, 0.24), x * MeshKit.at(0, 1.0, 0.115))
					for sx in [-0.09, 0.09]:
						k.capsule(0.05, 0.42, Color(0.3, 0.32, 0.36), x * MeshKit.at(sx, 0.02, 0), 8, 3)
					for sx in [-1.0, 1.0]:
						k.capsule(0.04, 0.34, Color(0.95, 0.95, 0.94), x * MeshKit.xf(Vector3(sx * 0.2, 0.46, 0.0), Vector3(0, 0, sx * 10)), 8, 3)
					if g >= 3:
						k.cyl(0.24, 0.03, lit(l, 0.3), x * MeshKit.at(0, 0.0, 0), 16)
		"tanks":
			# gas cylinders: one, two, three on a rack, then with a glowing gauge
			var n4 := mini(g + 1, 3)
			for i in n4:
				var cx4: float = [0.0, -0.17, 0.17][i] if n4 > 1 else 0.0
				if n4 == 2:
					cx4 = -0.12 + i * 0.24
				var tc := col.lerp(Color(0.9, 0.9, 0.9), 0.35)
				k.cyl(0.1, 0.82, tc, x * MeshKit.at(cx4, 0, -0.05 + (i % 2) * 0.08), 10, 0.03)
				k.sphere(0.1, tc, x * MeshKit.at(cx4, 0.82, -0.05 + (i % 2) * 0.08), 10, 5)
				k.cyl(0.03, 0.1, Pal.STEEL_DARK, x * MeshKit.at(cx4, 0.9, -0.05 + (i % 2) * 0.08), 6)
			if g >= 2:
				k.rbox(Vector3(0.6, 0.04, 0.04), 0.01, Pal.STEEL_DARK, x * MeshKit.at(0, 0.55, 0.12))
			if g >= 3:
				k.cyl(0.07, 0.02, lit(l), x * MeshKit.xf(Vector3(0.0, 0.66, 0.1), Vector3(90, 0, 0)), 10)
		"drums":
			# chemical drums in the building's colour
			var spots := [Vector3(0, 0, 0), Vector3(-0.2, 0, 0.12), Vector3(0.22, 0, 0.1), Vector3(0.0, 0.62, 0.02)]
			for i in g + 1:
				var p4: Vector3 = spots[i]
				if g >= 1 and i == 0:
					p4 = Vector3(0.0, 0, -0.18)
				k.cyl(0.17, 0.58, col.darkened(0.1 * (i % 2)), x * MeshKit.at(p4.x, p4.y, p4.z), 12, 0.02)
				k.cyl(0.175, 0.03, col.darkened(0.3), x * MeshKit.at(p4.x, p4.y + 0.2, p4.z), 12)
				k.cyl(0.175, 0.03, col.darkened(0.3), x * MeshKit.at(p4.x, p4.y + 0.4, p4.z), 12)
				k.rbox(Vector3(0.14, 0.12, 0.01), 0.01, Color(0.96, 0.8, 0.26), x * MeshKit.at(p4.x, p4.y + 0.3, p4.z + 0.17))
		"reels":
			# cable reels on their side
			var cols := [Color(0.3, 0.5, 0.86), Color(0.96, 0.6, 0.3), Color(0.24, 0.24, 0.28), col]
			for i in mini(g + 1, 3):
				var p5 := Vector3([0.0, -0.18, 0.2][i], 0, [0.0, 0.18, -0.12][i])
				var s5: float = [0.32, 0.26, 0.22][i]
				for sz in [-1.0, 1.0]:
					k.cyl(s5, 0.05, Pal.WOOD if t < 3 else Color(0.3, 0.32, 0.36), x * MeshKit.xf(p5 + Vector3(0, s5, sz * 0.13), Vector3(90, 0, 0)), 14)
				k.cyl(s5 * 0.72, 0.24, cols[(i + g) % 4], x * MeshKit.xf(p5 + Vector3(0, s5, 0.12), Vector3(90, 0, 0)), 14)
			if g >= 3:
				k.cyl(0.33, 0.02, lit(l, 0.3), x * MeshKit.xf(Vector3(0, 0.32, 0.17), Vector3(90, 0, 0)), 16)
		"kiosk":
			# a sign; a screen totem; a bigger one; glowing
			match g:
				0:
					k.cyl(0.025, 0.7, Pal.STEEL_DARK, x * MeshKit.at(0, 0, 0), 5)
					k.rbox(Vector3(0.46, 0.32, 0.04), 0.03, b, x * MeshKit.at(0, 0.82, 0))
					k.rbox(Vector3(0.14, 0.14, 0.01), 0.03, col, x * MeshKit.at(-0.1, 0.84, 0.025))
				_:
					var h6: float = [0.0, 1.1, 1.5, 1.5][g]
					k.rbox(Vector3(0.44, h6, 0.18), 0.05, b, x * MeshKit.at(0, h6 * 0.5, 0))
					k.rbox(Vector3(0.36, h6 * 0.55, 0.02), 0.03, lit(Color(0.5, 0.86, 1.0), 0.4 if g >= 3 else 0.6) if g >= 2 else Color(0.14, 0.15, 0.18), x * MeshKit.at(0, h6 * 0.62, 0.095))
					k.rbox(Vector3(0.46, 0.06, 0.2), 0.02, tr, x * MeshKit.at(0, h6 + 0.03, 0))
					if g >= 3:
						k.cyl(0.24, 0.03, lit(l, 0.3), x * MeshKit.at(0, 0.0, 0), 14)
		"chiller":
			# an air-cooled chiller: one fan, two fans, two units, glowing panel
			var n7 := 1 if g < 2 else 2
			for i in n7:
				var cz7 := 0.0 if n7 == 1 else -0.17 + i * 0.36
				var w7 := 0.6 if g >= 1 else 0.44
				k.rbox(Vector3(w7, 0.42, 0.34), 0.04, Color(0.9, 0.91, 0.92) if t != 4 else Color(0.22, 0.23, 0.26), x * MeshKit.at(0, 0.21, cz7))
				var fans := 2 if g >= 1 else 1
				for f in fans:
					var fx := 0.0 if fans == 1 else -0.15 + f * 0.3
					k.cyl(0.12, 0.03, Color(0.24, 0.25, 0.28), x * MeshKit.at(fx, 0.42, cz7), 12)
					k.rbox(Vector3(0.2, 0.01, 0.03), 0.005, Color(0.5, 0.52, 0.56), x * MeshKit.xf(Vector3(fx, 0.455, cz7), Vector3(0, 30 + f * 40, 0)))
				for j in 4:
					k.rbox(Vector3(w7 - 0.08, 0.02, 0.01), 0.005, Color(0.66, 0.7, 0.74), x * MeshKit.at(0, 0.08 + j * 0.07, cz7 + 0.17))
			if g >= 3:
				k.rbox(Vector3(0.12, 0.08, 0.01), 0.01, lit(Color(0.4, 0.9, 1.0)), x * MeshKit.at(0.2, 0.32, 0.36))
		"pallet":
			# a pallet of token boxes, one to three layers, then shrink-wrapped and labelled
			k.rbox(Vector3(0.7, 0.1, 0.6), 0.02, Pal.WOOD if t < 3 else Color(0.36, 0.4, 0.46), x * MeshKit.at(0, 0.05, 0))
			for ly in mini(g + 1, 3):
				for i in 2:
					for j in 2:
						k.rbox(Vector3(0.32, 0.22, 0.27), 0.03, Color(0.82, 0.68, 0.48) if (i + j + ly) % 2 == 0 else Color(0.76, 0.62, 0.42), x * MeshKit.at(-0.17 + i * 0.34, 0.21 + ly * 0.23, -0.14 + j * 0.28))
				k.rbox(Vector3(0.12, 0.08, 0.01), 0.01, col, x * MeshKit.at(-0.17, 0.21 + ly * 0.23, 0.28))
			if g >= 3:
				# strapped and labelled
				for sx in [-0.17, 0.17]:
					k.rbox(Vector3(0.04, 0.72, 0.62), 0.01, Color(0.24, 0.25, 0.28), x * MeshKit.at(sx, 0.43, 0))
				k.rbox(Vector3(0.26, 0.18, 0.01), 0.01, Color(0.96, 0.96, 0.95), x * MeshKit.at(0, 0.5, 0.29))
				k.rbox(Vector3(0.08, 0.08, 0.012), 0.01, lit(l), x * MeshKit.at(0.06, 0.5, 0.3))
		"mast":
			# a lattice antenna mast, taller each grade, a blinking beacon at the top
			var h8: float = [1.2, 1.8, 2.5, 3.0][g]
			var mc := Color(0.86, 0.3, 0.26) if t < 3 else Color(0.84, 0.86, 0.88)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.cyl(0.02, h8, mc, x * MeshKit.xf(Vector3(sx * 0.13, 0, sz * 0.13), Vector3(-sz * 2.5, 0, sx * 2.5)), 5)
			for i in int(h8 / 0.3):
				var y8 := 0.15 + i * 0.3
				var r8 := 0.13 * (1.0 - y8 / h8 * 0.5)
				k.rbox(Vector3(r8 * 2.0, 0.02, 0.02), 0.005, Color(0.94, 0.94, 0.92), x * MeshKit.at(0, y8, r8))
				k.rbox(Vector3(0.02, 0.02, r8 * 2.0), 0.005, Color(0.94, 0.94, 0.92), x * MeshKit.at(r8, y8, 0))
			k.sphere(0.05, lit(Color(1.0, 0.3, 0.3)), x * MeshKit.at(0, h8 + 0.05, 0), 6, 4)
			if g >= 1:
				k.cyl(0.08, 0.16, Color(0.94, 0.94, 0.92), x * MeshKit.xf(Vector3(0.1, h8 * 0.7, 0), Vector3(0, 0, -90)), 8)
			if g >= 2:
				k.cyl(0.11, 0.04, Color(0.94, 0.94, 0.92), x * MeshKit.xf(Vector3(0.0, h8 * 0.55, 0.1), Vector3(90, 0, 0)), 12, 0.0, 0.03)
		"dish":
			# a ground satellite dish, bigger each grade, then a glowing feed
			var r9: float = [0.28, 0.38, 0.48, 0.48][g]
			k.cyl(0.18, 0.08, Pal.STONE if t < 2 else b, x * MeshKit.at(0, 0, 0), 10)
			k.cyl(0.04, 0.45 + r9 * 0.5, Color(0.6, 0.62, 0.66), x * MeshKit.at(0, 0.08, 0), 6)
			var dx := x * MeshKit.xf(Vector3(0, 0.55 + r9 * 0.5, 0.04), Vector3(-55, 0, 0))
			k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r9 * 0.5, 0.03), Vector2(r9, 0.14), Vector2(r9 - 0.02, 0.14), Vector2(r9 * 0.5, 0.05), Vector2(0.0, 0.02)]), Color(0.95, 0.95, 0.94), dx, 16)
			k.cyl(0.012, r9 * 0.9, Color(0.5, 0.52, 0.56), dx * MeshKit.at(0, 0.02, 0), 4)
			k.sphere(0.04, lit(Color(1.0, 0.4, 0.3)) if g >= 3 else Color(0.3, 0.32, 0.36), dx * MeshKit.at(0, r9 * 0.92, 0), 6, 4)
		"solar":
			# ground solar panels, one to three, then with a glowing inverter
			for i in mini(g + 1, 3):
				var cx9: float = 0.0 if g == 0 else [-0.2, 0.2, 0.0][i]
				var cz9: float = [0.0, 0.0, -0.28][i] if g > 0 else 0.0
				var w9 := 0.62 if g == 0 else 0.38
				k.cyl(0.025, 0.3, Pal.STEEL_DARK, x * MeshKit.at(cx9, 0, cz9), 5)
				k.rbox(Vector3(w9, 0.03, 0.46), 0.01, Color(0.18, 0.26, 0.48), x * MeshKit.xf(Vector3(cx9, 0.34, cz9), Vector3(28, 0, 0)))
				k.rbox(Vector3(w9 + 0.02, 0.02, 0.48), 0.005, Color(0.84, 0.86, 0.88), x * MeshKit.xf(Vector3(cx9, 0.32, cz9), Vector3(28, 0, 0)))
			if g >= 3:
				k.rbox(Vector3(0.18, 0.24, 0.1), 0.02, Color(0.9, 0.91, 0.92), x * MeshKit.at(0.0, 0.12, 0.3))
				k.rbox(Vector3(0.06, 0.03, 0.01), 0.005, lit(Color(0.5, 1.0, 0.6)), x * MeshKit.at(0.0, 0.18, 0.355))
		"drone":
			# a drone pad; a drone lands on it; a second drone; glowing ring
			k.cyl(0.36, 0.05, Color(0.3, 0.32, 0.36), x * MeshKit.at(0, 0, 0), 16)
			k.torus(0.26, 0.012, Color(0.96, 0.8, 0.26), x * MeshKit.at(0, 0.055, 0), 16, 4)
			if g >= 1:
				var dz := x * MeshKit.at(0, 0.12, 0)
				k.rbox(Vector3(0.16, 0.06, 0.16), 0.03, Color(0.94, 0.95, 0.96), dz)
				for i in 4:
					var a := TAU * (i + 0.5) / 4.0
					k.rbox(Vector3(0.2, 0.02, 0.02), 0.005, Color(0.3, 0.32, 0.36), dz * MeshKit.xf(Vector3(cos(a) * 0.09, 0.02, sin(a) * 0.09), Vector3(0, -rad_to_deg(a), 0)))
					k.cyl(0.06, 0.01, Color(0.5, 0.52, 0.56, 1.0), dz * MeshKit.at(cos(a) * 0.17, 0.04, sin(a) * 0.17), 10)
			if g >= 2:
				k.rbox(Vector3(0.22, 0.14, 0.18), 0.03, Color(0.82, 0.68, 0.48), x * MeshKit.at(0.2, 0.07, 0.3))
			if g >= 3:
				k.torus(0.34, 0.015, lit(l, 0.3), x * MeshKit.at(0, 0.06, 0), 20, 4)
		"gen":
			# a backup generator, bigger, with a fuel tank, then a status light
			var w10: float = [0.5, 0.66, 0.7, 0.7][g]
			k.rbox(Vector3(w10, 0.42 + g * 0.06, 0.4), 0.05, Color(0.34, 0.58, 0.42), x * MeshKit.at(0, 0.21 + g * 0.03, 0))
			for i in 4:
				k.rbox(Vector3(0.03, 0.2, 0.01), 0.005, Color(0.26, 0.46, 0.33), x * MeshKit.at(-w10 * 0.3 + i * 0.06, 0.24, 0.205))
			k.cyl(0.04, 0.2, Color(0.42, 0.42, 0.44), x * MeshKit.at(w10 * 0.3, 0.42 + g * 0.06, -0.08), 6)
			if g >= 2:
				k.cyl(0.13, 0.62, Color(0.92, 0.92, 0.9), x * MeshKit.xf(Vector3(0.31, 0.14, 0.3), Vector3(0, 0, 90)), 10)
			if g >= 3:
				k.rbox(Vector3(0.08, 0.05, 0.01), 0.01, lit(Color(0.5, 1.0, 0.6)), x * MeshKit.at(-0.15, 0.4, 0.205))
		"bench":
			# a bench; with a planter; with a lamp; with a glowing strip
			var bc: Color = Pal.WOOD if t != 4 else Color(0.24, 0.25, 0.28)
			k.rbox(Vector3(0.7, 0.06, 0.32), 0.02, bc, x * MeshKit.at(0, 0.38, 0))
			k.rbox(Vector3(0.7, 0.26, 0.05), 0.02, bc, x * MeshKit.xf(Vector3(0, 0.6, -0.15), Vector3(-10, 0, 0)))
			for sx in [-0.3, 0.3]:
				k.rbox(Vector3(0.05, 0.38, 0.3), 0.01, Pal.STEEL_DARK, x * MeshKit.at(sx, 0.19, 0))
			if g >= 1:
				k.sphere(0.12, Pal.LEAF, x * MeshKit.at(0.0, 0.5, -0.32), 8, 5)
				k.rbox(Vector3(0.66, 0.16, 0.18), 0.03, tr, x * MeshKit.at(0, 0.08, -0.3))
			if g >= 2:
				k.rbox(Vector3(0.12, 0.08, 0.1), 0.02, Color(0.24, 0.25, 0.28), x * MeshKit.at(0.18, 0.45, 0.02))
				k.rbox(Vector3(0.06, 0.04, 0.012), 0.01, lit(Color(1.0, 0.6, 0.4)), x * MeshKit.at(0.18, 0.46, 0.075))
			if g >= 3:
				k.rbox(Vector3(0.66, 0.02, 0.02), 0.005, lit(l, 0.3), x * MeshKit.at(0, 0.34, 0.16))
		"bikes":
			# an e-scooter; two; a bike; a charging rack
			var bcs := [Color(0.3, 0.6, 0.86), Color(0.96, 0.6, 0.3), Color(0.3, 0.66, 0.68)]
			for i in mini(g + 1, 3):
				var bx := -0.22 + i * 0.22
				k.rbox(Vector3(0.06, 0.03, 0.42), 0.01, bcs[i], x * MeshKit.at(bx, 0.08, 0))
				k.cyl(0.05, 0.03, Pal.RUBBER, x * MeshKit.xf(Vector3(bx, 0.05, 0.18), Vector3(0, 0, 90)), 8)
				k.cyl(0.05, 0.03, Pal.RUBBER, x * MeshKit.xf(Vector3(bx, 0.05, -0.18), Vector3(0, 0, 90)), 8)
				k.cyl(0.015, 0.62, Pal.STEEL_DARK, x * MeshKit.xf(Vector3(bx, 0.08, 0.18), Vector3(-8, 0, 0)), 5)
				k.rbox(Vector3(0.2, 0.02, 0.02), 0.005, Pal.STEEL_DARK, x * MeshKit.at(bx, 0.7, 0.26))
			if g >= 3:
				k.rbox(Vector3(0.7, 0.5, 0.06), 0.02, b, x * MeshKit.at(0, 0.25, -0.3))
				k.rbox(Vector3(0.6, 0.03, 0.01), 0.005, lit(Color(0.5, 1.0, 0.6)), x * MeshKit.at(0, 0.42, -0.265))
		"sandbags":
			# quartz sand: one sack, a heap, a pallet of sacks, a hopper
			var sand := Color(0.88, 0.8, 0.6)
			var sk := [Vector3(0, 0, 0), Vector3(0.24, 0, 0.04), Vector3(-0.24, 0, 0.02), Vector3(0.0, 0.17, 0.02), Vector3(0.12, 0.34, 0.0)]
			for i in [1, 3, 4, 5][g]:
				k.ellipsoid(Vector3(0.14, 0.09, 0.2), sand.darkened(0.04 * (i % 3)), x * MeshKit.at(sk[i].x, 0.09 + sk[i].y, sk[i].z), 10, 6)
			if g >= 2:
				k.rbox(Vector3(0.72, 0.06, 0.48), 0.02, Pal.WOOD, x * MeshKit.at(0, 0.0, 0))
			if g >= 3:
				k.cyl(0.03, 0.62, Pal.STEEL_DARK, x * MeshKit.at(-0.3, 0, -0.2), 5)
				k.cyl(0.03, 0.62, Pal.STEEL_DARK, x * MeshKit.at(0.3, 0, -0.2), 5)
				k.rbox(Vector3(0.66, 0.05, 0.05), 0.01, lit(l, 0.35), x * MeshKit.at(0, 0.62, -0.2))
		"wafers":
			# silicon wafer crates: a box, a stack, a cart, a glowing wafer on top
			for i in mini(g + 1, 3):
				k.rbox(Vector3(0.42, 0.18, 0.42), 0.04, Color(0.86, 0.9, 0.96), x * MeshKit.at(0, 0.09 + i * 0.19, 0))
				k.rbox(Vector3(0.36, 0.02, 0.01), 0.005, col, x * MeshKit.at(0, 0.12 + i * 0.19, 0.212))
			if g >= 3:
				k.cyl(0.18, 0.015, Color(0.5, 0.6, 0.9, 0.4), x * MeshKit.at(0, 0.58, 0), 18)
		"books":
			# stacks of papers and books
			var bk := [Color(0.86, 0.3, 0.26), Color(0.3, 0.5, 0.86), Color(0.96, 0.8, 0.3), Color(0.94, 0.94, 0.9), Color(0.3, 0.66, 0.5)]
			for s in mini(g + 1, 3):
				var sx: float = [0.0, -0.22, 0.22][s]
				for i in 3 + g:
					k.rbox(Vector3(0.22, 0.06, 0.3), 0.01, bk[(i + s) % 5], x * MeshKit.xf(Vector3(sx, 0.03 + i * 0.065, 0), Vector3(0, (i * 13) % 20 - 10, 0)))
			if g >= 3:
				k.cyl(0.02, 0.5, Pal.BRASS, x * MeshKit.at(0.0, 0, -0.25), 6)
				k.sphere(0.08, lit(Color(1.0, 0.9, 0.7)), x * MeshKit.at(0.0, 0.56, -0.25), 8, 5)
		"pumps":
			# a pump with pipes; bigger; two; with a glowing flow meter
			var pc := Color(0.3, 0.62, 0.86)
			var n11 := 1 if g < 2 else 2
			for i in n11:
				var cx11 := 0.0 if n11 == 1 else -0.18 + i * 0.36
				var s11 := 0.8 if g == 0 else 1.0
				k.rbox(Vector3(0.28 * s11, 0.24 * s11, 0.34 * s11), 0.04, Color(0.3, 0.32, 0.36), x * MeshKit.at(cx11, 0.12 * s11, 0))
				k.cyl(0.11 * s11, 0.3 * s11, pc, x * MeshKit.xf(Vector3(cx11, 0.3 * s11, -0.15), Vector3(90, 0, 0)), 10)
				k.cyl(0.04, 0.5, pc.darkened(0.2), x * MeshKit.at(cx11, 0.0, -0.3), 6)
			if g >= 3:
				k.rbox(Vector3(0.1, 0.1, 0.02), 0.03, lit(Color(0.4, 0.9, 1.0)), x * MeshKit.at(0.0, 0.42, 0.2))
		"ore":
			# an ore cart on rails, heaped higher, a second cart, glowing crystals
			k.rbox(Vector3(0.04, 0.03, 0.7), 0.01, Pal.STEEL, x * MeshKit.at(-0.12, 0.015, 0))
			k.rbox(Vector3(0.04, 0.03, 0.7), 0.01, Pal.STEEL, x * MeshKit.at(0.12, 0.015, 0))
			var nc := 1 if g < 2 else 2
			for i in nc:
				var cz12 := 0.0 if nc == 1 else -0.18 + i * 0.36
				k.rbox(Vector3(0.36, 0.2, 0.3), 0.03, Color(0.42, 0.44, 0.48), x * MeshKit.at(0, 0.17, cz12))
				k.ellipsoid(Vector3(0.15, 0.06 + g * 0.03, 0.13), col, x * MeshKit.at(0, 0.28, cz12), 8, 4)
			if g >= 3:
				for i in 3:
					k.cone(0.04, 0.16, lit(col.lightened(0.3), 0.35), x * MeshKit.xf(Vector3(-0.06 + i * 0.06, 0.32, 0.0), Vector3(0, 0, -15 + i * 15)), 5)
		# ---------------------------------------------------------------- top
		"ac":
			# a rooftop condenser: one fan, two fans, a second unit, glowing panel
			var n13 := 1 if g < 2 else 2
			for i in n13:
				var cx13 := 0.0 if n13 == 1 else -0.17 + i * 0.34
				var w13: float = 0.42 if g == 0 else (0.5 if n13 == 1 else 0.3)
				k.rbox(Vector3(w13, 0.3, 0.42), 0.03, Color(0.9, 0.91, 0.92) if t != 4 else Color(0.22, 0.23, 0.26), x * MeshKit.at(cx13, 0.15, 0))
				k.cyl(minf(0.15, w13 * 0.38), 0.03, Color(0.22, 0.23, 0.26), x * MeshKit.at(cx13, 0.3, 0), 12)
				for j in 3:
					k.rbox(Vector3(w13 - 0.06, 0.015, 0.01), 0.004, Color(0.66, 0.7, 0.74), x * MeshKit.at(cx13, 0.06 + j * 0.06, 0.212))
			if g >= 3:
				k.rbox(Vector3(0.12, 0.05, 0.01), 0.01, lit(Color(0.4, 0.9, 1.0)), x * MeshKit.at(0.0, 0.25, 0.215))
		"dish_s":
			var r14: float = [0.18, 0.25, 0.32, 0.32][g]
			k.cyl(0.08, 0.06, Color(0.5, 0.52, 0.56), x * MeshKit.at(0, 0, 0), 8)
			k.cyl(0.025, 0.2 + r14 * 0.4, Color(0.6, 0.62, 0.66), x * MeshKit.at(0, 0.05, 0), 6)
			var dx14 := x * MeshKit.xf(Vector3(0, 0.25 + r14 * 0.4, 0.03), Vector3(-50, 20, 0))
			k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r14 * 0.5, 0.02), Vector2(r14, 0.09), Vector2(r14 - 0.015, 0.09), Vector2(r14 * 0.5, 0.035), Vector2(0.0, 0.015)]), Color(0.95, 0.95, 0.94), dx14, 14)
			k.cyl(0.01, r14 * 0.8, Color(0.5, 0.52, 0.56), dx14 * MeshKit.at(0, 0.015, 0), 4)
			k.sphere(0.03, lit(Color(1.0, 0.4, 0.3)) if g >= 3 else Color(0.3, 0.32, 0.36), dx14 * MeshKit.at(0, r14 * 0.82, 0), 6, 4)
		"antenna":
			for i in mini(g + 1, 3):
				var p15 := Vector3([0.0, -0.18, 0.18][i], 0, [0.0, 0.06, -0.06][i])
				var h15: float = [0.9, 0.6, 0.75][i] + g * 0.15
				k.cyl(0.05, 0.05, Color(0.3, 0.32, 0.36), x * MeshKit.at(p15.x, 0, p15.z), 6)
				k.cyl(0.015, h15, Color(0.84, 0.86, 0.88), x * MeshKit.at(p15.x, 0.05, p15.z), 4)
				for j in 2:
					k.rbox(Vector3(0.16 - j * 0.05, 0.012, 0.012), 0.003, Color(0.84, 0.86, 0.88), x * MeshKit.at(p15.x, 0.05 + h15 * (0.6 + j * 0.2), p15.z))
				k.sphere(0.03, lit(Color(1.0, 0.3, 0.3)) if (g >= 3 or i == 0) else Color(0.84, 0.86, 0.88), x * MeshKit.at(p15.x, 0.07 + h15, p15.z), 6, 4)
		"solar_s":
			for i in mini(g + 1, 3):
				var cx16: float = 0.0 if g == 0 else [-0.17, 0.17, 0.0][i]
				var cz16: float = 0.0 if g == 0 else [0.06, 0.06, -0.2][i]
				var w16 := 0.5 if g == 0 else 0.3
				k.rbox(Vector3(w16, 0.025, 0.3), 0.008, Color(0.18, 0.26, 0.48), x * MeshKit.xf(Vector3(cx16, 0.12, cz16), Vector3(22, 0, 0)))
				k.rbox(Vector3(0.03, 0.12, 0.03), 0.005, Pal.STEEL_DARK, x * MeshKit.at(cx16, 0.05, cz16 - 0.06))
			if g >= 3:
				k.rbox(Vector3(0.6, 0.02, 0.02), 0.005, lit(l, 0.3), x * MeshKit.at(0, 0.02, 0.2))
		"vent":
			for i in mini(g + 1, 3):
				var p17 := Vector3([0.0, -0.18, 0.18][i], 0, [0.0, 0.05, 0.05][i])
				var h17: float = [0.42, 0.3, 0.34][i] + g * 0.06
				k.cyl(0.07, h17, Color(0.66, 0.68, 0.7), x * MeshKit.at(p17.x, 0, p17.z), 10)
				k.cyl(0.1, 0.05, Color(0.5, 0.52, 0.56), x * MeshKit.at(p17.x, h17, p17.z), 10)
				k.cone(0.11, 0.08, Color(0.5, 0.52, 0.56), x * MeshKit.at(p17.x, h17 + 0.1, p17.z), 10)
			if g >= 3:
				k.cyl(0.075, 0.03, lit(l, 0.3), x * MeshKit.at(0, 0.18, 0), 10)
		"tank_s":
			var r18: float = [0.16, 0.2, 0.24, 0.24][g]
			for sx in [-1.0, 1.0]:
				k.cyl(0.015, 0.2, Pal.STEEL_DARK, x * MeshKit.at(sx * r18 * 0.6, 0, 0), 4)
			k.cyl(r18, 0.4 + g * 0.06, Color(0.92, 0.92, 0.9) if t < 3 else Color(0.66, 0.7, 0.74), x * MeshKit.at(0, 0.2, 0), 12, 0.03)
			k.cone(r18 + 0.01, 0.1, Color(0.6, 0.62, 0.64), x * MeshKit.at(0, 0.6 + g * 0.06, 0), 12)
			if g >= 2:
				k.cyl(r18 + 0.005, 0.03, col, x * MeshKit.at(0, 0.35, 0), 12)
			if g >= 3:
				k.cyl(r18 + 0.008, 0.02, lit(l, 0.3), x * MeshKit.at(0, 0.48, 0), 12)
		"beacon":
			var h19: float = [0.3, 0.45, 0.6, 0.7][g]
			k.cyl(0.03, h19, Pal.STEEL_DARK, x * MeshKit.at(0, 0, 0), 6)
			k.sphere(0.06 + g * 0.015, lit(Color(1.0, 0.35, 0.3) if t < 3 else l, 0.35), x * MeshKit.at(0, h19 + 0.04, 0), 8, 5)
			if g >= 2:
				k.cyl(0.12, 0.03, Pal.STEEL_DARK, x * MeshKit.at(0, 0, 0), 10)
		"sign":
			# a rooftop sign with the building's colour, bigger, then lit
			var w20: float = [0.5, 0.7, 0.9, 0.9][g]
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.03, 0.3, 0.03), 0.005, Pal.STEEL_DARK, x * MeshKit.at(sx * w20 * 0.35, 0.15, -0.02))
			k.rbox(Vector3(w20, 0.28, 0.05), 0.04, Color(0.14, 0.15, 0.18) if t >= 3 else b, x * MeshKit.at(0, 0.44, 0))
			k.rbox(Vector3(0.18, 0.18, 0.02), 0.05, lit(col, 0.5) if g >= 2 else col, x * MeshKit.at(-w20 * 0.3, 0.44, 0.03))
			for i in 2:
				k.rbox(Vector3(w20 * 0.45 - i * 0.06, 0.035, 0.01), 0.008, lit(l, 0.4) if g >= 3 else Color(0.5, 0.52, 0.56), x * MeshKit.at(w20 * 0.1, 0.48 - i * 0.08, 0.03))
		# ---------------------------------------------------------------- wall
		"screen":
			# a monitor; a wide dashboard; a two-screen video wall; brighter
			var w21: float = [0.5, 0.8, 1.1, 1.1][g]
			var h21: float = [0.32, 0.42, 0.5, 0.5][g]
			k.rbox(Vector3(w21 + 0.06, h21 + 0.06, 0.06), 0.02, Color(0.16, 0.17, 0.2), x * MeshKit.at(0, 0, 0.03))
			var scr := lit(Color(0.36, 0.7, 0.96), 0.5 if g < 3 else 0.35)
			if g == 0:
				scr = Color(0.2, 0.32, 0.42)
			if g >= 2:
				for sx in [-1.0, 1.0]:
					k.rbox(Vector3(w21 * 0.5 - 0.04, h21 - 0.02, 0.01), 0.01, scr, x * MeshKit.at(sx * w21 * 0.25, 0, 0.065))
			else:
				k.rbox(Vector3(w21 - 0.04, h21 - 0.04, 0.01), 0.01, scr, x * MeshKit.at(0, 0, 0.065))
			if g >= 1:
				# a little bar chart on it
				for i in 5:
					var bh := 0.05 + float((i * 37) % 5) * 0.03
					k.rbox(Vector3(0.04, bh, 0.008), 0.004, Color(1.0, 0.86, 0.5, 0.4), x * MeshKit.at(-w21 * 0.4 + 0.05 + i * 0.06, -h21 * 0.3 + bh * 0.5, 0.072))
		"ledbar":
			var w22: float = [0.45, 0.75, 1.05, 1.05][g]
			k.rbox(Vector3(w22, 0.06, 0.04), 0.015, Color(0.24, 0.25, 0.28), x * MeshKit.at(0, 0, 0.02))
			k.rbox(Vector3(w22 - 0.04, 0.03, 0.01), 0.01, lit(l, 0.4 if g < 3 else 0.28), x * MeshKit.at(0, 0, 0.042))
			if g >= 2:
				k.rbox(Vector3(w22, 0.06, 0.04), 0.015, Color(0.24, 0.25, 0.28), x * MeshKit.at(0, -0.12, 0.02))
				k.rbox(Vector3(w22 - 0.04, 0.03, 0.01), 0.01, lit(col, 0.4), x * MeshKit.at(0, -0.12, 0.042))
		"neon":
			# a poster; a framed print; a neon token sign; brighter with a frame
			match g:
				0:
					k.rbox(Vector3(0.36, 0.48, 0.015), 0.005, Color(0.96, 0.94, 0.88), x * MeshKit.at(0, 0, 0.01))
					k.rbox(Vector3(0.24, 0.2, 0.01), 0.01, col, x * MeshKit.at(0, 0.06, 0.02))
				1:
					k.rbox(Vector3(0.52, 0.62, 0.04), 0.01, tr, x * MeshKit.at(0, 0, 0.02))
					k.rbox(Vector3(0.44, 0.54, 0.01), 0.005, Color(0.96, 0.94, 0.88), x * MeshKit.at(0, 0, 0.045))
					k.sphere(0.12, col, x * MeshKit.xf(Vector3(0, 0.04, 0.05), Vector3.ZERO, Vector3(1, 1, 0.15)), 12, 6)
				_:
					if g >= 3:
						k.rbox(Vector3(0.66, 0.66, 0.03), 0.04, Color(0.14, 0.15, 0.18), x * MeshKit.at(0, 0, 0.015))
					k.torus(0.22, 0.025, lit(col, 0.4), x * MeshKit.xf(Vector3(0, 0, 0.06), Vector3(90, 0, 0)), 18, 5)
					k.torus(0.12, 0.02, lit(l, 0.4), x * MeshKit.xf(Vector3(0, 0, 0.06), Vector3(90, 0, 0)), 14, 5)
		"panel":
			# a patch panel; two; three; with glowing cable runs
			for r in mini(g + 1, 3):
				var y23 := -r * 0.14
				k.rbox(Vector3(0.7, 0.11, 0.05), 0.01, Color(0.2, 0.21, 0.24), x * MeshKit.at(0, y23, 0.025))
				for i in 8:
					k.rbox(Vector3(0.04, 0.03, 0.01), 0.005, lit(l if (i + r) % 3 else Color(0.5, 1.0, 0.6)) if i % 2 == 0 else Color(0.1, 0.1, 0.12), x * MeshKit.at(-0.28 + i * 0.08, y23, 0.055))
			if g >= 3:
				for i in 3:
					k.cyl(0.012, 0.4, lit([Color(0.3, 0.6, 1.0), Color(1.0, 0.6, 0.3), Color(0.5, 1.0, 0.6)][i], 0.4), x * MeshKit.at(-0.2 + i * 0.2, -0.75, 0.04), 4)
		_:
			push_warning("GrowthParts: unknown part " + name)
