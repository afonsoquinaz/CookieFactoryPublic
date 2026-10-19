class_name GrowthParts
## The things buildings gain as they level up (see Growth), each in four
## grades that read as the piece of gear evolving: the first upgrade puts a
## small one down, the next makes it bigger and better equipped, then it
## becomes a pair or a set on a plinth, then a busy, glowing installation.
## Every part is drawn at the origin facing +Z in the style of the building's
## tier, following ArchKit's five eras (not just its colours):
##   0 GARAGE      plywood, tin, tarps, duct tape, orange extension cords
##   1 WORKSHOP    galvanised steel, yellow safety paint, bolts, chain-link
##   2 CAMPUS      white panels, teal bands, glass, tidy and rounded
##   3 INDUSTRIAL  dark steel, louvres, heavy skids, blue LEDs
##   4 HYPERSCALE  graphite and brass, glowing fins and seams
##   floor parts stand on the ground in about 0.75 x 0.75 m (up to ~1.6 m tall)
##   top parts sit on a flat roof or wall top in about 0.7 x 0.5 m
##   wall parts hang on a wall face (the wall is at z = 0, at most 0.25 out)
## Mostly sharp boxes (12 triangles each) so a part can carry lots of detail:
## a part at grade 3 stays under ~1,500 triangles.

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
	return STY[clampi(t, 0, 4)]["shell"]


static func trim(t: int) -> Color:
	return STY[clampi(t, 0, 4)]["frame"]


static func led(t: int) -> Color:
	return STY[clampi(t, 0, 4)]["glow"]


static func lit(c: Color, a := 0.4) -> Color:
	return Items.lit(c, a)


## Per-era materials for gear.
##   shell/shell2  casings      frame  edges, posts, battens    metal  bare metal
##   dark          screens, rubber, shadows   accent/accent2  paint and highlights
##   glow          status lights (lit)        cable  wiring    base  skids and plinths
const STY := [
	{"shell": Color(0.76, 0.6, 0.42), "shell2": Color(0.66, 0.5, 0.34), "frame": Color(0.44, 0.31, 0.21), "metal": Color(0.64, 0.66, 0.68),
		"dark": Color(0.2, 0.19, 0.18), "accent": Color(0.26, 0.46, 0.78), "accent2": Color(0.86, 0.3, 0.24), "glow": Color(1.0, 0.82, 0.5),
		"cable": Color(0.95, 0.52, 0.18), "base": Color(0.62, 0.48, 0.32), "tape": Color(0.74, 0.75, 0.76), "card": Color(0.8, 0.64, 0.44)},
	{"shell": Color(0.72, 0.74, 0.77), "shell2": Color(0.6, 0.63, 0.67), "frame": Color(0.33, 0.35, 0.39), "metal": Color(0.8, 0.82, 0.84),
		"dark": Color(0.18, 0.19, 0.21), "accent": Color(0.97, 0.77, 0.18), "accent2": Color(0.8, 0.3, 0.25), "glow": Color(0.6, 1.0, 0.62),
		"cable": Color(0.14, 0.14, 0.16), "base": Color(0.36, 0.38, 0.42), "tape": Color(0.97, 0.77, 0.18), "card": Color(0.62, 0.48, 0.32)},
	{"shell": Color(0.95, 0.95, 0.96), "shell2": Color(0.84, 0.86, 0.88), "frame": Color(0.72, 0.75, 0.78), "metal": Color(0.84, 0.86, 0.88),
		"dark": Color(0.24, 0.27, 0.31), "accent": Color(0.3, 0.66, 0.68), "accent2": Color(0.98, 0.7, 0.3), "glow": Color(0.42, 0.96, 0.9),
		"cable": Color(0.3, 0.66, 0.68), "base": Color(0.8, 0.81, 0.82), "tape": Color(0.3, 0.66, 0.68), "card": Color(0.96, 0.96, 0.97)},
	{"shell": Color(0.4, 0.43, 0.49), "shell2": Color(0.31, 0.34, 0.39), "frame": Color(0.2, 0.22, 0.26), "metal": Color(0.62, 0.65, 0.7),
		"dark": Color(0.12, 0.13, 0.16), "accent": Color(0.98, 0.8, 0.22), "accent2": Color(0.3, 0.55, 0.9), "glow": Color(0.45, 0.75, 1.0),
		"cable": Color(0.1, 0.1, 0.12), "base": Color(0.52, 0.53, 0.55), "tape": Color(0.98, 0.8, 0.22), "card": Color(0.3, 0.33, 0.38)},
	{"shell": Color(0.19, 0.2, 0.23), "shell2": Color(0.26, 0.27, 0.31), "frame": Color(0.78, 0.63, 0.38), "metal": Color(0.4, 0.42, 0.46),
		"dark": Color(0.07, 0.07, 0.09), "accent": Color(0.78, 0.63, 0.38), "accent2": Color(0.42, 0.9, 1.0), "glow": Color(1.0, 0.86, 0.5),
		"cable": Color(0.78, 0.63, 0.38), "base": Color(0.13, 0.14, 0.16), "tape": Color(0.78, 0.63, 0.38), "card": Color(0.22, 0.23, 0.27)},
]


static func s(t: int, key: String) -> Color:
	return STY[clampi(t, 0, 4)][key]


## Draws part `name` at grade g (0..3) into k at transform x.
static func draw(k: MeshKit, name: String, g: int, t: int, x: Transform3D, col := Color(0.3, 0.66, 0.68)) -> void:
	g = clampi(g, 0, 3)
	t = clampi(t, 0, 4)
	match name:
		"cabinet": _cabinet(k, g, t, x, col)
		"crates": _crates(k, g, t, x, col)
		"battery": _battery(k, g, t, x, col)
		"solar": _solar(k, g, t, x, col)
		"chiller": _chiller(k, g, t, x, col)
		"gen": _gen(k, g, t, x, col)
		"plant": _plant(k, g, t, x, col)
		"lamp": _lamp_part(k, g, t, x, col)
		"robot": _robot(k, g, t, x, col)
		"tanks": _tanks(k, g, t, x, col)
		"drums": _drums(k, g, t, x, col)
		"reels": _reels(k, g, t, x, col)
		"kiosk": _kiosk(k, g, t, x, col)
		"pallet": _pallet(k, g, t, x, col)
		"mast": _mast(k, g, t, x, col)
		"dish": _dish(k, g, t, x, col)
		"drone": _drone(k, g, t, x, col)
		"bench": _bench(k, g, t, x, col)
		"bikes": _bikes(k, g, t, x, col)
		"sandbags": _sandbags(k, g, t, x, col)
		"wafers": _wafers(k, g, t, x, col)
		"books": _books(k, g, t, x, col)
		"pumps": _pumps(k, g, t, x, col)
		"ore": _ore(k, g, t, x, col)
		"ac": _ac(k, g, t, x, col)
		"dish_s": _dish_s(k, g, t, x, col)
		"antenna": _antenna(k, g, t, x, col)
		"solar_s": _solar_s(k, g, t, x, col)
		"vent": _vent_top(k, g, t, x, col)
		"tank_s": _tank_s(k, g, t, x, col)
		"beacon": _beacon_part(k, g, t, x, col)
		"sign": _sign_top(k, g, t, x, col)
		"screen": _screen(k, g, t, x, col)
		"ledbar": _ledbar(k, g, t, x, col)
		"neon": _neon(k, g, t, x, col)
		"panel": _panel_part(k, g, t, x, col)
		_:
			push_warning("GrowthParts: unknown part " + name)


# ================================================================ helpers

## A sharp box centred at p (local to x).
static func _b(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, c: Color) -> void:
	k.box(sz, c, x * MeshKit.at(p.x, p.y, p.z))


## A sharp box standing on p (bottom centre).
static func _u(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, c: Color) -> void:
	k.box(sz, c, x * MeshKit.at(p.x, p.y + sz.y * 0.5, p.z))


## A rotated box centred at p (degrees, Y then X then Z).
static func _r(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, rot: Vector3, c: Color) -> void:
	k.box(sz, c, x * MeshKit.xf(p, rot))


## Upright cylinder standing on p.
static func _cy(k: MeshKit, x: Transform3D, p: Vector3, r: float, h: float, c: Color, segs := 6, r2 := -1.0) -> void:
	k.cyl(r, h, c, x * MeshKit.at(p.x, p.y, p.z), segs, 0.0, r2)


## Cylinder from p along +z.
static func _cz(k: MeshKit, x: Transform3D, p: Vector3, r: float, h: float, c: Color, segs := 6) -> void:
	k.cyl(r, h, c, x * MeshKit.xf(p, Vector3(90, 0, 0)), segs)


## Cylinder from p along +x.
static func _cx(k: MeshKit, x: Transform3D, p: Vector3, r: float, h: float, c: Color, segs := 6) -> void:
	k.cyl(r, h, c, x * MeshKit.xf(p, Vector3(0, 0, -90)), segs)


## A square bar from a to b (cables, braces, struts).
static func _seg(k: MeshKit, x: Transform3D, a: Vector3, b: Vector3, th: float, c: Color) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.002:
		return
	var up := Vector3.UP if absf(d.y / l) < 0.95 else Vector3.RIGHT
	k.box(Vector3(th, th, l), c, x * Transform3D(Basis.looking_at(d, up), (a + b) * 0.5))


## A run of bars through points.
static func _run(k: MeshKit, x: Transform3D, pts: Array, th: float, c: Color) -> void:
	for i in pts.size() - 1:
		_seg(k, x, pts[i], pts[i + 1], th, c)


## The era's wiring through points (orange extension cord, black cable,
## teal cable, heavy black, brass conduit).
static func _cable(k: MeshKit, x: Transform3D, pts: Array, t: int, th := 0.025) -> void:
	_run(k, x, pts, th * (1.3 if t >= 3 else 1.0), s(t, "cable"))


## A status light (a bare bulb in the garage).
static func _lamp(k: MeshKit, x: Transform3D, p: Vector3, t: int, c := Color(0, 0, 0, 0), sz := 0.035) -> void:
	var lc: Color = c if c.a > 0.0 else s(t, "glow")
	if t == 0:
		_b(k, x, p, Vector3(sz, sz, sz), lit(lc, 0.3))
	else:
		_b(k, x, p, Vector3(sz, sz * 0.6, 0.012), lit(lc, 0.35))


## An equipment casing in the era's style standing on p, front at +z.
static func _shell(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, t: int, c := Color(0, 0, 0, 0)) -> void:
	var bc: Color = c if c.a > 0.0 else s(t, "shell")
	var fz := p.z + sz.z * 0.5
	var top := p.y + sz.y
	_u(k, x, p, sz, bc)
	match t:
		0:
			# plywood: plank seams, corner battens, a strip of duct tape
			var n := maxi(1, int(sz.y / 0.24))
			for i in n:
				_b(k, x, Vector3(p.x, p.y + (i + 1) * sz.y / (n + 1), fz + 0.003), Vector3(sz.x - 0.03, 0.012, 0.008), bc.darkened(0.22))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(p.x + sx * (sz.x * 0.5 - 0.012), p.y + sz.y * 0.5, fz + 0.008), Vector3(0.035, sz.y, 0.022), s(t, "frame"))
			for sz2: float in [-1.0, 1.0]:
				_b(k, x, Vector3(p.x, top + 0.012, p.z + sz2 * (sz.z * 0.5 - 0.02)), Vector3(sz.x + 0.02, 0.025, 0.045), s(t, "frame"))
			_b(k, x, Vector3(p.x - sz.x * 0.1, top + 0.002, p.z), Vector3(0.012, 0.006, sz.z - 0.06), bc.darkened(0.22))
			_r(k, x, Vector3(p.x + sz.x * 0.28, p.y + sz.y * 0.72, fz + 0.012), Vector3(0.05, minf(0.3, sz.y * 0.4), 0.008), Vector3(0, 0, 38), s(t, "tape"))
		1:
			# galvanised steel: dark cap and plinth, bolts, a yellow kick band
			_b(k, x, Vector3(p.x, top + 0.012, p.z), Vector3(sz.x + 0.03, 0.025, sz.z + 0.03), bc.darkened(0.1))
			_b(k, x, Vector3(p.x, top + 0.012, fz + 0.012), Vector3(sz.x + 0.035, 0.03, 0.012), s(t, "frame"))
			_u(k, x, Vector3(p.x, p.y, p.z), Vector3(sz.x + 0.02, 0.05, sz.z + 0.02), s(t, "frame"))
			_b(k, x, Vector3(p.x, p.y + 0.08, fz + 0.004), Vector3(sz.x, 0.04, 0.01), s(t, "accent"))
			for sx: float in [-1.0, 1.0]:
				for sy: float in [0.12, sz.y - 0.05]:
					_b(k, x, Vector3(p.x + sx * (sz.x * 0.5 - 0.03), p.y + sy, fz + 0.006), Vector3(0.018, 0.018, 0.012), s(t, "metal"))
		2:
			# white panels: an inset lid, a teal band, a shadow-gap plinth
			_b(k, x, Vector3(p.x, top + 0.008, p.z), Vector3(sz.x - 0.04, 0.016, sz.z - 0.04), s(t, "shell2"))
			_b(k, x, Vector3(p.x, p.y + sz.y * 0.86, p.z), Vector3(sz.x + 0.008, 0.035, sz.z + 0.008), s(t, "accent"))
			_u(k, x, p, Vector3(sz.x - 0.03, 0.035, sz.z + 0.004), s(t, "dark"))
		3:
			# dark steel: corner angles, a heavy lip and base, a blue LED line
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(p.x + sx * sz.x * 0.5, p.y + sz.y * 0.5, fz), Vector3(0.035, sz.y, 0.035), s(t, "frame"))
			_b(k, x, Vector3(p.x, top + 0.015, p.z), Vector3(sz.x + 0.04, 0.03, sz.z + 0.04), s(t, "shell2"))
			_b(k, x, Vector3(p.x, top + 0.015, fz + 0.02), Vector3(sz.x + 0.045, 0.035, 0.012), s(t, "frame"))
			_u(k, x, p, Vector3(sz.x + 0.04, 0.05, sz.z + 0.04), s(t, "frame"))
			_b(k, x, Vector3(p.x, top - 0.05, fz + 0.006), Vector3(sz.x - 0.07, 0.016, 0.01), lit(s(t, "glow"), 0.45))
		4:
			# graphite: brass edges and a glowing seam at the foot
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(p.x + sx * sz.x * 0.5, p.y + sz.y * 0.5, fz), Vector3(0.025, sz.y, 0.025), s(t, "frame"))
			_b(k, x, Vector3(p.x, top + 0.01, p.z), Vector3(sz.x + 0.02, 0.02, sz.z + 0.02), s(t, "shell2"))
			_b(k, x, Vector3(p.x, top + 0.012, fz + 0.01), Vector3(sz.x + 0.03, 0.024, 0.012), s(t, "frame"))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(p.x + sx * sz.x * 0.5, top + 0.012, p.z), Vector3(0.012, 0.024, sz.z + 0.02), s(t, "frame"))
			_b(k, x, Vector3(p.x, p.y + 0.03, fz + 0.005), Vector3(sz.x - 0.04, 0.014, 0.01), lit(s(t, "glow"), 0.4))


## A door on a +z face centred at c (c.z = the face).
static func _door(k: MeshKit, x: Transform3D, c: Vector3, w: float, h: float, t: int) -> void:
	var z := c.z
	match t:
		0:
			_b(k, x, Vector3(c.x, c.y, z + 0.008), Vector3(w, h, 0.016), s(t, "shell").lightened(0.08))
			for sy: float in [-0.32, 0.32]:
				_b(k, x, Vector3(c.x - w * 0.36, c.y + h * sy, z + 0.02), Vector3(w * 0.3, 0.025, 0.01), s(t, "dark"))
			_b(k, x, Vector3(c.x + w * 0.38, c.y, z + 0.022), Vector3(0.03, 0.05, 0.02), s(t, "metal"))
			_b(k, x, Vector3(c.x + w * 0.38, c.y - 0.04, z + 0.03), Vector3(0.025, 0.03, 0.015), Color(0.8, 0.66, 0.3))
			_r(k, x, Vector3(c.x - w * 0.05, c.y + h * 0.18, z + 0.02), Vector3(w * 0.32, w * 0.24, 0.004), Vector3(0, 0, -6), Color(0.97, 0.96, 0.9))
		1:
			_b(k, x, Vector3(c.x, c.y, z + 0.006), Vector3(w, h, 0.012), s(t, "frame"))
			_b(k, x, Vector3(c.x, c.y, z + 0.012), Vector3(w - 0.03, h - 0.03, 0.01), s(t, "shell2"))
			_b(k, x, Vector3(c.x + w * 0.36, c.y, z + 0.025), Vector3(0.02, 0.08, 0.02), s(t, "dark"))
			_b(k, x, Vector3(c.x + w * 0.36, c.y + 0.02, z + 0.035), Vector3(0.05, 0.015, 0.012), s(t, "dark"))
			_b(k, x, Vector3(c.x - w * 0.15, c.y + h * 0.3, z + 0.019), Vector3(w * 0.35, w * 0.2, 0.004), s(t, "accent"))
		2:
			_b(k, x, Vector3(c.x, c.y, z + 0.005), Vector3(w - 0.01, h, 0.01), s(t, "shell2").lightened(0.5))
			_b(k, x, Vector3(c.x + w * 0.38, c.y, z + 0.016), Vector3(0.016, h * 0.5, 0.016), s(t, "accent"))
			_b(k, x, Vector3(c.x - w * 0.08, c.y + h * 0.3, z + 0.012), Vector3(w * 0.45, h * 0.12, 0.006), Color(0.2, 0.3, 0.36))
		3:
			_b(k, x, Vector3(c.x, c.y, z + 0.006), Vector3(w, h, 0.012), s(t, "shell2"))
			for i in 4:
				_r(k, x, Vector3(c.x, c.y - h * 0.42 + i * 0.035, z + 0.02), Vector3(w * 0.8, 0.012, 0.02), Vector3(-35, 0, 0), s(t, "frame"))
			_b(k, x, Vector3(c.x + w * 0.38, c.y + 0.02, z + 0.025), Vector3(0.025, 0.1, 0.025), s(t, "accent"))
			_b(k, x, Vector3(c.x - w * 0.1, c.y + h * 0.32, z + 0.014), Vector3(w * 0.4, 0.04, 0.006), s(t, "accent"))
		4:
			_b(k, x, Vector3(c.x, c.y, z + 0.005), Vector3(w - 0.01, h, 0.01), s(t, "shell2"))
			_b(k, x, Vector3(c.x + w * 0.38, c.y, z + 0.016), Vector3(0.018, h * 0.6, 0.018), s(t, "frame"))
			_b(k, x, Vector3(c.x - w * 0.1, c.y, z + 0.012), Vector3(0.012, h * 0.8, 0.006), lit(s(t, "glow"), 0.4))


## A vent grille on a +z face centred at c.
static func _vent(k: MeshKit, x: Transform3D, c: Vector3, w: float, h: float, t: int) -> void:
	var z := c.z
	if t == 0:
		# holes drilled in the plywood
		for i in 3:
			for j in 2:
				_b(k, x, Vector3(c.x - w * 0.3 + i * w * 0.3, c.y - h * 0.22 + j * h * 0.44, z + 0.003), Vector3(w * 0.14, h * 0.24, 0.008), s(t, "dark"))
		return
	_b(k, x, Vector3(c.x, c.y, z + 0.004), Vector3(w, h, 0.008), s(t, "dark"))
	var n := maxi(2, int(h / 0.035))
	for i in n:
		var y := c.y - h * 0.5 + (i + 0.5) * h / n
		if t == 3:
			_r(k, x, Vector3(c.x, y, z + 0.014), Vector3(w, 0.012, 0.022), Vector3(-35, 0, 0), s(t, "shell"))
		else:
			_b(k, x, Vector3(c.x, y, z + 0.01), Vector3(w - 0.01, h / n * 0.45, 0.008), s(t, "shell2") if t != 4 else s(t, "frame"))


## A fan seen from its intake (local frame xf: fan disc in XZ facing +Y).
static func _fan(k: MeshKit, xf: Transform3D, r: float, t: int) -> void:
	var rim: Color = [s(0, "metal"), s(1, "frame"), s(2, "shell2"), s(3, "frame"), s(4, "frame")][t]
	k.cyl(r, 0.025, s(t, "dark"), xf, 8)
	for i in 3:
		k.box(Vector3(r * 1.7, 0.008, r * 0.32), Color(0.5, 0.52, 0.56) if t < 4 else s(t, "shell2"), xf * MeshKit.xf(Vector3(0, 0.03, 0), Vector3(0, i * 60.0, 0)))
	match t:
		0:
			# a square box fan
			for sx: float in [-1.0, 1.0]:
				k.box(Vector3(0.03, 0.05, r * 2.2), rim, xf * MeshKit.at(sx * r * 1.05, 0.02, 0))
				k.box(Vector3(r * 2.2, 0.05, 0.03), rim, xf * MeshKit.at(0, 0.02, sx * r * 1.05))
		1, 3:
			k.box(Vector3(r * 2.0, 0.012, 0.018), rim, xf * MeshKit.at(0, 0.045, 0))
			k.box(Vector3(0.018, 0.012, r * 2.0), rim, xf * MeshKit.at(0, 0.045, 0))
			k.cyl(r * 1.06, 0.035, rim, xf, 8, 0.0, -1.0, false)
		2:
			k.cyl(r * 1.08, 0.04, rim, xf, 8, 0.0, -1.0, false)
			k.cyl(r * 0.22, 0.05, s(t, "accent"), xf, 6)
		4:
			k.cyl(r * 1.08, 0.04, rim, xf, 8, 0.0, -1.0, false)
			k.cyl(r * 0.24, 0.05, lit(s(t, "glow"), 0.4), xf, 6)


## The base equipment stands on: a pallet (0), a steel skid (1), a concrete
## plinth (2), a pad and I-beams (3), a graphite plinth with a lit edge (4).
## Returns its height.
static func _skid(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, t: int) -> float:
	match t:
		0:
			for i in 3:
				_u(k, x, Vector3(p.x - w * 0.38 + i * w * 0.38, p.y, p.z), Vector3(0.07, 0.06, d), s(t, "frame"))
			for i in 4:
				_u(k, x, Vector3(p.x, p.y + 0.06, p.z - d * 0.39 + i * d * 0.26), Vector3(w, 0.025, d * 0.2), s(t, "base") if i % 2 == 0 else s(t, "base").darkened(0.1))
			return 0.085
		1:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x, p.y, p.z + sz * (d * 0.5 - 0.03)), Vector3(w, 0.06, 0.06), s(t, "frame"))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(p.x + sx * w * 0.25, p.y + 0.03, p.z + d * 0.5 + 0.001), Vector3(0.1, 0.03, 0.004), s(t, "accent"))
			_u(k, x, Vector3(p.x, p.y + 0.06, p.z), Vector3(w, 0.012, d), s(t, "base"))
			return 0.072
		2:
			_u(k, x, p, Vector3(w, 0.05, d), s(t, "base"))
			_b(k, x, Vector3(p.x, p.y + 0.05, p.z + d * 0.5 - 0.015), Vector3(w, 0.006, 0.03), s(t, "accent"))
			return 0.05
		3:
			_u(k, x, p, Vector3(w + 0.04, 0.04, d + 0.04), s(t, "base"))
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x, p.y + 0.04, p.z + sz * (d * 0.5 - 0.05)), Vector3(w, 0.05, 0.05), s(t, "frame"))
				_b(k, x, Vector3(p.x, p.y + 0.065, p.z + sz * (d * 0.5 - 0.05)), Vector3(w + 0.01, 0.012, 0.07), s(t, "frame"))
			_b(k, x, Vector3(p.x, p.y + 0.02, p.z + d * 0.5 + 0.021), Vector3(w * 0.7, 0.012, 0.004), s(t, "accent"))
			return 0.09
		_:
			_u(k, x, p, Vector3(w, 0.06, d), s(t, "base"))
			_b(k, x, Vector3(p.x, p.y + 0.03, p.z + d * 0.5 + 0.002), Vector3(w - 0.04, 0.012, 0.006), lit(s(t, "glow"), 0.35))
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.02), p.y, p.z + d * 0.5 - 0.02), Vector3(0.045, 0.065, 0.045), s(t, "frame"))
			return 0.06


## A warning sign facing +z centred at c: cardboard and marker (0), a yellow
## diamond (1), a white pictogram plate (2), yellow and black chevrons (3), a
## brass plate with a glowing glyph (4).
static func _sign(k: MeshKit, x: Transform3D, c: Vector3, w: float, t: int) -> void:
	var z := c.z
	match t:
		0:
			_r(k, x, Vector3(c.x, c.y, z + 0.004), Vector3(w, w * 0.7, 0.008), Vector3(0, 0, 4), s(t, "card"))
			for i in 2:
				_r(k, x, Vector3(c.x - w * 0.05, c.y + w * 0.12 - i * w * 0.2, z + 0.01), Vector3(w * (0.7 - i * 0.2), 0.012, 0.004), Vector3(0, 0, 4), Color(0.16, 0.14, 0.13))
			_r(k, x, Vector3(c.x - w * 0.42, c.y + w * 0.3, z + 0.01), Vector3(w * 0.25, 0.03, 0.004), Vector3(0, 0, 40), s(t, "tape"))
		1:
			_r(k, x, Vector3(c.x, c.y, z + 0.004), Vector3(w * 0.72, w * 0.72, 0.008), Vector3(0, 0, 45), Color(0.12, 0.12, 0.13))
			_r(k, x, Vector3(c.x, c.y, z + 0.009), Vector3(w * 0.6, w * 0.6, 0.006), Vector3(0, 0, 45), s(t, "accent"))
			_b(k, x, Vector3(c.x, c.y + w * 0.06, z + 0.014), Vector3(w * 0.08, w * 0.3, 0.004), Color(0.12, 0.12, 0.13))
			_b(k, x, Vector3(c.x, c.y - w * 0.2, z + 0.014), Vector3(w * 0.08, w * 0.08, 0.004), Color(0.12, 0.12, 0.13))
		2:
			_b(k, x, Vector3(c.x, c.y, z + 0.005), Vector3(w, w, 0.01), s(t, "shell"))
			_b(k, x, Vector3(c.x, c.y + w * 0.08, z + 0.012), Vector3(w * 0.5, w * 0.5, 0.004), s(t, "accent"))
			_b(k, x, Vector3(c.x, c.y - w * 0.34, z + 0.012), Vector3(w * 0.7, w * 0.08, 0.004), s(t, "dark"))
		3:
			_b(k, x, Vector3(c.x, c.y, z + 0.005), Vector3(w, w * 0.6, 0.01), s(t, "accent"))
			for i in 3:
				_r(k, x, Vector3(c.x - w * 0.3 + i * w * 0.3, c.y, z + 0.012), Vector3(w * 0.1, w * 0.62, 0.004), Vector3(0, 0, 30), Color(0.12, 0.12, 0.13))
		4:
			_b(k, x, Vector3(c.x, c.y, z + 0.005), Vector3(w, w * 0.6, 0.01), s(t, "frame"))
			_b(k, x, Vector3(c.x, c.y, z + 0.011), Vector3(w * 0.84, w * 0.44, 0.004), s(t, "dark"))
			_b(k, x, Vector3(c.x, c.y, z + 0.015), Vector3(w * 0.5, w * 0.08, 0.004), lit(s(t, "accent2"), 0.4))


## A shelter over gear: a tarp on sticks (0), a corrugated sheet on steel
## posts (1), a white canopy with a glass edge (2), a louvred dark roof (3), a
## graphite slab on brass posts with a lit underside (4). p = ground centre.
static func _canopy(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, h: float, t: int) -> void:
	p = Vector3(p.x, p.y, p.z - d * 0.2)
	d *= 0.6
	var bz := p.z - d * 0.5 + 0.03
	match t:
		0:
			for sx: float in [-1.0, 1.0]:
				_r(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y + h * 0.5, bz), Vector3(0.035, h + 0.06, 0.035), Vector3(0, 0, sx * 3.0), s(t, "frame"))
				_seg(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y + h, p.z + d * 0.45), Vector3(p.x + sx * (w * 0.5 + 0.02), p.y, p.z + d * 0.55), 0.008, Color(0.9, 0.86, 0.7))
			_r(k, x, Vector3(p.x, p.y + h - 0.02, p.z - d * 0.2), Vector3(w + 0.06, 0.012, d * 0.62), Vector3(-8, 0, 0), s(t, "accent"))
			_r(k, x, Vector3(p.x, p.y + h - 0.07, p.z + d * 0.3), Vector3(w + 0.04, 0.012, d * 0.45), Vector3(14, 0, 0), s(t, "accent").darkened(0.1))
		1:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y, bz), Vector3(0.04, h, 0.04), s(t, "frame"))
				_r(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y + h - 0.12, bz + 0.1), Vector3(0.025, 0.025, 0.26), Vector3(-45, 0, 0), s(t, "frame"))
			var cx := x * MeshKit.xf(Vector3(p.x, p.y + h + 0.02, p.z), Vector3(-6, 0, 0))
			k.box(Vector3(w + 0.06, 0.015, d), s(t, "metal"), cx)
			for i in 6:
				k.box(Vector3(0.02, 0.02, d), s(t, "shell2"), cx * MeshKit.at(-w * 0.5 + (i + 0.5) * w / 6.0, 0.012, 0))
			k.box(Vector3(w + 0.08, 0.035, 0.03), s(t, "accent"), cx * MeshKit.at(0, -0.01, d * 0.5))
		2:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y, bz), Vector3(0.03, h, 0.03), s(t, "shell"))
			_u(k, x, Vector3(p.x, p.y + h, p.z), Vector3(w + 0.04, 0.035, d), s(t, "shell"))
			_b(k, x, Vector3(p.x, p.y + h + 0.018, p.z + d * 0.5 + 0.006), Vector3(w + 0.04, 0.025, 0.012), s(t, "accent"))
			for i in 2:
				_u(k, x, Vector3(p.x - w * 0.25 + i * w * 0.5, p.y + h + 0.035, p.z - d * 0.05), Vector3(w * 0.5 - 0.05, 0.01, d * 0.7), Color(0.58, 0.8, 0.92))
			_u(k, x, Vector3(p.x, p.y + h + 0.035, p.z - d * 0.05), Vector3(0.025, 0.02, d * 0.74), s(t, "frame"))
		3:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y, bz), Vector3(0.05, h, 0.05), s(t, "frame"))
			_u(k, x, Vector3(p.x, p.y + h, bz), Vector3(w, 0.05, 0.05), s(t, "frame"))
			for i in 5:
				_r(k, x, Vector3(p.x, p.y + h + 0.03, bz + 0.05 + i * (d - 0.06) / 5.0), Vector3(w + 0.02, 0.012, (d - 0.06) / 5.0 * 0.9), Vector3(-25, 0, 0), s(t, "shell"))
			_b(k, x, Vector3(p.x, p.y + h - 0.01, bz + 0.03), Vector3(w - 0.06, 0.012, 0.012), lit(s(t, "glow"), 0.45))
		_:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.03), p.y, bz), Vector3(0.025, h, 0.025), s(t, "frame"))
			_u(k, x, Vector3(p.x, p.y + h, p.z), Vector3(w + 0.04, 0.04, d), s(t, "shell"))
			_b(k, x, Vector3(p.x, p.y + h + 0.02, p.z + d * 0.5 + 0.004), Vector3(w + 0.04, 0.02, 0.012), s(t, "frame"))
			_b(k, x, Vector3(p.x, p.y + h - 0.004, p.z + d * 0.3), Vector3(w - 0.06, 0.008, 0.02), lit(s(t, "glow"), 0.35))
			for i in 4:
				_u(k, x, Vector3(p.x - w * 0.375 + i * w * 0.25, p.y + h + 0.04, p.z), Vector3(0.018, 0.025, d - 0.04), s(t, "frame"))
			_u(k, x, Vector3(p.x, p.y + h + 0.04, p.z + d * 0.5 - 0.03), Vector3(w - 0.04, 0.012, 0.012), lit(s(t, "accent2"), 0.4))


## A meter box with a dial on a +z face centred at c.
static func _meter(k: MeshKit, x: Transform3D, c: Vector3, t: int) -> void:
	_b(k, x, Vector3(c.x, c.y, c.z + 0.025), Vector3(0.1, 0.13, 0.05), s(t, "shell2") if t != 2 else s(t, "shell"))
	_cz(k, x, Vector3(c.x, c.y + 0.02, c.z + 0.05), 0.03, 0.006, Color(0.95, 0.95, 0.9) if t < 3 else lit(s(t, "glow"), 0.5), 8)
	_r(k, x, Vector3(c.x, c.y + 0.025, c.z + 0.058), Vector3(0.004, 0.024, 0.003), Vector3(0, 0, 30), s(t, "accent2"))
	_b(k, x, Vector3(c.x, c.y - 0.04, c.z + 0.052), Vector3(0.05, 0.015, 0.004), s(t, "dark"))


## A conduit leaving a side face at a (x = the face), dropping into the ground.
static func _conduit(k: MeshKit, x: Transform3D, a: Vector3, side: float, t: int) -> void:
	var o := Vector3(a.x + side * 0.05, a.y, a.z)
	var r := 0.018 if t < 3 else 0.025
	var c: Color = s(t, "cable") if t == 0 else (s(t, "metal") if t != 4 else s(t, "frame"))
	_seg(k, x, a, o, r * 2.0, c)
	_seg(k, x, o, Vector3(o.x, 0.02, o.z), r * 2.0, c)
	_b(k, x, Vector3(o.x, a.y, o.z), Vector3(r * 3.0, r * 3.0, r * 3.0), c.darkened(0.15))
	_u(k, x, Vector3(o.x, 0.0, o.z), Vector3(0.08, 0.02, 0.08), Color(0.5, 0.5, 0.48) if t < 4 else s(t, "base"))


## A hazard band (yellow with black stripes) facing +z, centred at c.
static func _hazard(k: MeshKit, x: Transform3D, c: Vector3, w: float, h: float) -> void:
	_b(k, x, Vector3(c.x, c.y, c.z + 0.003), Vector3(w, h, 0.006), Color(0.97, 0.77, 0.18))
	var n := maxi(1, int(w / (h * 2.0)))
	for i in n:
		_r(k, x, Vector3(c.x - w * 0.5 + (i + 0.5) * w / n, c.y, c.z + 0.007), Vector3(h * 0.4, h * 1.2, 0.004), Vector3(0, 0, 40), Color(0.12, 0.12, 0.13))


## A cooling unit on top of gear (p = its base centre): box fans taped on
## (0), a casing with fans (1-4) and fins and glow on the later eras.
static func _cooler(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, t: int) -> void:
	var fans := maxi(1, int(w / 0.3))
	var r := minf(d * 0.36, w / fans * 0.38)
	if t == 0:
		for i in fans:
			var fx := p.x - w * 0.5 + (i + 0.5) * w / fans
			_fan(k, x * MeshKit.xf(Vector3(fx, p.y + 0.03, p.z), Vector3.ZERO), r, t)
			_b(k, x, Vector3(fx, p.y + 0.01, p.z), Vector3(r * 2.2, 0.02, r * 2.2), s(t, "shell2"))
		_b(k, x, Vector3(p.x, p.y + 0.04, p.z + r * 0.9), Vector3(w, 0.03, 0.04), s(t, "tape"))
		return
	var h := 0.14 + 0.02 * t
	_shell(k, x, p, Vector3(w, h, d), t)
	for i in fans:
		var fx2 := p.x - w * 0.5 + (i + 0.5) * w / fans
		_fan(k, x * MeshKit.at(fx2, p.y + h + 0.012, p.z), r, t)
	for sx: float in [-1.0, 1.0]:
		for j in 3:
			_b(k, x, Vector3(p.x + sx * (w * 0.5 + 0.004), p.y + 0.04 + j * (h - 0.06) / 3.0, p.z), Vector3(0.01, 0.014, d * 0.8), s(t, "dark") if t != 4 else lit(s(t, "glow"), 0.4))


# ================================================================ floor parts

## A server cabinet in the yard: a single outdoor cabinet with a door, vents
## and a light; a taller one with a conduit into the ground, a meter and a
## fan grille; a pair on a plinth with a cable tray and a canopy; a row with
## glowing status strips, a cooling unit and a warning sign.
static func _cabinet(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	match g:
		0:
			var y := _skid(k, x, Vector3(0, 0, 0), 0.5, 0.42, t)
			_cab_unit(k, x, Vector3(0, y, 0), Vector3(0.4, 0.72, 0.32), t, 0)
		1:
			var y := _skid(k, x, Vector3(0, 0, 0), 0.54, 0.44, t)
			_cab_unit(k, x, Vector3(0, y, 0), Vector3(0.42, 1.04, 0.34), t, 1)
			_conduit(k, x, Vector3(-0.21, y + 0.8, -0.05), -1.0, t)
			_meter(k, x * MeshKit.xf(Vector3(0.21, y + 0.62, 0.0), Vector3(0, 90, 0)), Vector3(0, 0, 0), t)
			_cable(k, x, [Vector3(0.21, y + 0.3, -0.12), Vector3(0.28, y + 0.25, -0.12), Vector3(0.3, 0.02, -0.2)], t)
		2:
			var y := _skid(k, x, Vector3(0, 0, 0), 0.74, 0.5, t)
			for sx: float in [-1.0, 1.0]:
				_cab_unit(k, x, Vector3(sx * 0.19, y, 0.02), Vector3(0.3, 1.0, 0.32), t, 2)
			# a cable tray bridging the pair
			var ty := y + 1.06
			_u(k, x, Vector3(0, ty, -0.04), Vector3(0.62, 0.015, 0.14), s(t, "metal"))
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(0, ty, -0.04 + sz * 0.07), Vector3(0.62, 0.05, 0.01), s(t, "metal"))
			for i in 3:
				_u(k, x, Vector3(0, ty + 0.015, -0.08 + i * 0.04), Vector3(0.6, 0.025, 0.03), [s(t, "cable"), Color(0.2, 0.4, 0.8), Color(0.9, 0.6, 0.2)][i])
			_canopy(k, x, Vector3(0, y, 0.0), 0.7, 0.52, 1.32, t)
		3:
			var y := _skid(k, x, Vector3(0, 0, 0), 0.76, 0.5, t)
			for i in 3:
				_cab_unit(k, x, Vector3(-0.245 + i * 0.245, y, 0.02), Vector3(0.23, 1.06, 0.34), t, 3)
			_cooler(k, x, Vector3(0, y + 1.1, 0.0), 0.7, 0.36, t)
			_sign(k, x * MeshKit.xf(Vector3(-0.375, y + 0.62, 0.0), Vector3(0, -90, 0)), Vector3(0, 0, 0), 0.16, t)
			_cable(k, x, [Vector3(0.34, y + 0.9, -0.1), Vector3(0.35, y + 0.9, -0.2), Vector3(0.35, 0.02, -0.28)], t, 0.035)
			if t >= 1:
				_hazard(k, x, Vector3(0, y + 0.02, 0.27), 0.7, 0.03)


## One cabinet of the set (lvl: how well equipped).
static func _cab_unit(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, t: int, lvl: int) -> void:
	_shell(k, x, p, sz, t)
	var fz := p.z + sz.z * 0.5
	var dh := sz.y * 0.8
	_door(k, x, Vector3(p.x - 0.01, p.y + sz.y * 0.47, fz), sz.x - 0.08, dh, t)
	if lvl >= 1 and sz.x > 0.26:
		var r := minf(sz.x * 0.3, 0.1)
		_fan(k, x * MeshKit.xf(Vector3(p.x - 0.01, p.y + sz.y * 0.68, fz + 0.02), Vector3(90, 0, 0)), r, t)
	_vent(k, x, Vector3(p.x - 0.01, p.y + sz.y * 0.2, fz + 0.016), sz.x * 0.6, 0.1, t)
	var lights := 1 + mini(lvl, 2)
	for i in lights:
		_lamp(k, x, Vector3(p.x - sz.x * 0.3 + i * 0.045, p.y + sz.y - 0.05, fz + 0.03), t, Color(0.5, 1.0, 0.6) if i == 0 else Color(0, 0, 0, 0))
	if lvl >= 3:
		_b(k, x, Vector3(p.x + sz.x * 0.38, p.y + sz.y * 0.5, fz + 0.025), Vector3(0.018, sz.y * 0.75, 0.01), lit(s(t, "glow"), 0.3))
	if lvl >= 2 and t == 0:
		# a lamp cord and a scrawled label
		_b(k, x, Vector3(p.x, p.y + sz.y - 0.12, fz + 0.022), Vector3(sz.x * 0.5, 0.05, 0.004), Color(0.97, 0.96, 0.9))


## GPU crates: one crate; two stacked with a hand truck; a pallet of them
## with an open one; a tall strapped stack with a glowing card on display.
## Cardboard and tape (0), wooden crates with stencils (1), white totes with
## teal lids (2), dark flight cases (3), graphite pods with brass (4).
static func _crates(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	match g:
		0:
			_crate(k, x, Vector3(0, 0, 0), Vector3(0.52, 0.34, 0.4), 4.0, t, col)
			_crate(k, x, Vector3(0.1, 0.34, -0.02), Vector3(0.28, 0.12, 0.22), -10.0, t, col)
			_r(k, x, Vector3(-0.12, 0.2, 0.205), Vector3(0.12, 0.14, 0.006), Vector3(0, 4, 3), Color(0.97, 0.96, 0.92))
			_b(k, x, Vector3(-0.12, 0.24, 0.21), Vector3(0.08, 0.012, 0.004), Color(0.16, 0.14, 0.13))
			k.torus(0.04, 0.015, s(t, "tape") if t != 4 else s(4, "frame"), x * MeshKit.at(-0.16, 0.355, -0.06), 8, 3)
			_cable(k, x, [Vector3(0.26, 0.05, 0.21), Vector3(0.3, 0.012, 0.28)], t, 0.012)
		1:
			_crate(k, x, Vector3(-0.1, 0, -0.06), Vector3(0.5, 0.36, 0.44), 0.0, t, col)
			_crate(k, x, Vector3(-0.08, 0.36, -0.06), Vector3(0.42, 0.3, 0.38), 8.0, t, col)
			_dolly(k, x * MeshKit.xf(Vector3(0.16, 0, 0.16), Vector3(0, -38, 0)), t)
		2:
			var y := _skid(k, x, Vector3(0, 0, -0.1), 0.72, 0.52, t)
			_crate(k, x, Vector3(-0.18, y, -0.12), Vector3(0.34, 0.34, 0.42), 0.0, t, col)
			_crate(k, x, Vector3(0.18, y, -0.12), Vector3(0.34, 0.34, 0.42), 0.0, t, col)
			_crate(k, x, Vector3(0.0, y + 0.34, -0.14), Vector3(0.48, 0.3, 0.38), -6.0, t, col)
			_open_crate(k, x * MeshKit.xf(Vector3(0.1, 0, 0.25), Vector3(0, -8, 0)), t, col, false)
		3:
			var y := _skid(k, x, Vector3(0, 0, -0.1), 0.72, 0.52, t)
			_crate(k, x, Vector3(-0.18, y, -0.12), Vector3(0.34, 0.34, 0.42), 0.0, t, col)
			_crate(k, x, Vector3(0.18, y, -0.12), Vector3(0.34, 0.34, 0.42), 0.0, t, col)
			_crate(k, x, Vector3(-0.17, y + 0.34, -0.12), Vector3(0.34, 0.3, 0.4), 3.0, t, col)
			_crate(k, x, Vector3(0.17, y + 0.34, -0.12), Vector3(0.32, 0.3, 0.4), -2.0, t, col)
			_crate(k, x, Vector3(0.0, y + 0.64, -0.12), Vector3(0.46, 0.28, 0.38), 5.0, t, col)
			# straps over the stack
			for sx: float in [-0.2, 0.2]:
				_u(k, x, Vector3(sx, y, 0.095), Vector3(0.03, 0.93, 0.008), s(t, "dark") if t != 1 else s(t, "accent"))
				_u(k, x, Vector3(sx, y + 0.92, -0.12), Vector3(0.03, 0.008, 0.44), s(t, "dark") if t != 1 else s(t, "accent"))
			_open_crate(k, x * MeshKit.xf(Vector3(0.0, 0, 0.25), Vector3(0, 0, 0)), t, col, true)


## One crate standing on p, turned yaw degrees.
static func _crate(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, yaw: float, t: int, col: Color, lite := false) -> void:
	var cx := x * MeshKit.xf(p, Vector3(0, yaw, 0))
	var h := sz.y
	var fz := sz.z * 0.5
	match t:
		0:
			var cb: Color = s(t, "card")
			k.box(sz, cb, cx * MeshKit.at(0, h * 0.5, 0))
			k.box(Vector3(sz.x * 0.2, 0.006, sz.z + 0.004), Color(0.86, 0.78, 0.62), cx * MeshKit.at(0, h, 0))
			k.box(Vector3(sz.x * 0.2, h * 0.3, 0.006), Color(0.86, 0.78, 0.62), cx * MeshKit.at(0, h * 0.85, fz))
			k.box(Vector3(sz.x * 0.36, 0.014, 0.004), Color(0.16, 0.14, 0.13), cx * MeshKit.at(-sz.x * 0.2, h * 0.45, fz + 0.002))
			k.box(Vector3(sz.x * 0.2, 0.014, 0.004), Color(0.16, 0.14, 0.13), cx * MeshKit.at(-sz.x * 0.26, h * 0.35, fz + 0.002))
			k.box(Vector3(0.07, 0.07, 0.004), s(t, "accent2"), cx * MeshKit.at(sz.x * 0.3, h * 0.4, fz + 0.002))
		1:
			k.box(sz, s(t, "card"), cx * MeshKit.at(0, h * 0.5, 0))
			for sy: float in [0.04, h - 0.04]:
				k.box(Vector3(sz.x + 0.01, 0.05, sz.z + 0.01), s(t, "card").darkened(0.18), cx * MeshKit.at(0, sy, 0))
			if not lite:
				for sx: float in [-1.0, 1.0]:
					k.box(Vector3(0.05, h, 0.01), s(t, "card").darkened(0.18), cx * MeshKit.at(sx * (sz.x * 0.5 - 0.02), h * 0.5, fz + 0.004))
			k.box(Vector3(sz.x * 0.45, h * 0.22, 0.004), Color(0.14, 0.14, 0.15), cx * MeshKit.at(0, h * 0.5, fz + 0.003))
			k.box(Vector3(0.025, h + 0.012, sz.z + 0.012), s(t, "metal"), cx * MeshKit.at(sz.x * 0.25, h * 0.5, 0))
		2:
			k.box(Vector3(sz.x, h * 0.85, sz.z), s(t, "shell"), cx * MeshKit.at(0, h * 0.425, 0))
			k.box(Vector3(sz.x + 0.02, h * 0.15, sz.z + 0.02), col.lerp(s(t, "accent"), 0.6), cx * MeshKit.at(0, h * 0.925, 0))
			k.box(Vector3(sz.x * 0.3, 0.03, 0.006), s(t, "dark"), cx * MeshKit.at(0, h * 0.65, fz + 0.002))
			k.box(Vector3(sz.x * 0.4, h * 0.25, 0.004), Color(1, 1, 1), cx * MeshKit.at(-sz.x * 0.15, h * 0.32, fz + 0.002))
			k.box(Vector3(0.05, 0.05, 0.005), col, cx * MeshKit.at(sz.x * 0.3, h * 0.32, fz + 0.003))
		3:
			k.box(sz, s(t, "shell2"), cx * MeshKit.at(0, h * 0.5, 0))
			k.box(Vector3(sz.x + 0.008, 0.02, sz.z + 0.008), s(t, "metal"), cx * MeshKit.at(0, h * 0.62, 0))
			for sx: float in [-1.0, 1.0]:
				if not lite:
					for sy: float in [0.025, h - 0.025]:
						k.box(Vector3(0.05, 0.05, 0.05), s(t, "metal"), cx * MeshKit.at(sx * (sz.x * 0.5 - 0.02), sy, fz - 0.02))
				k.box(Vector3(0.04, 0.05, 0.02), s(t, "metal"), cx * MeshKit.at(sx * sz.x * 0.22, h * 0.62, fz + 0.008))
			k.box(Vector3(sz.x * 0.3, 0.04, 0.004), s(t, "accent"), cx * MeshKit.at(0, h * 0.3, fz + 0.002))
		4:
			k.box(sz, s(t, "shell"), cx * MeshKit.at(0, h * 0.5, 0))
			for sx: float in [-1.0, 1.0]:
				k.box(Vector3(0.02, h, 0.02), s(t, "frame"), cx * MeshKit.at(sx * sz.x * 0.5, h * 0.5, fz))
			k.box(Vector3(sz.x + 0.004, 0.012, sz.z + 0.004), lit(s(t, "glow"), 0.4), cx * MeshKit.at(0, h * 0.7, 0))
			k.box(Vector3(sz.x * 0.4, 0.025, 0.02), s(t, "frame"), cx * MeshKit.at(0, h * 0.4, fz + 0.008))
			k.box(Vector3(0.05, 0.05, 0.004), col, cx * MeshKit.at(-sz.x * 0.3, h * 0.4, fz + 0.002))


## A hand truck leaning back (base on the ground, facing +z).
static func _dolly(k: MeshKit, x: Transform3D, t: int) -> void:
	var c: Color = [Color(0.78, 0.3, 0.26), s(1, "accent"), s(2, "accent"), s(3, "frame"), s(4, "frame")][t]
	var lx := x * MeshKit.xf(Vector3(0, 0.05, 0), Vector3(-18, 0, 0))
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(0.025, 0.8, 0.025), c, lx * MeshKit.at(sx * 0.1, 0.4, 0))
		k.cyl(0.05, 0.03, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(sx * 0.13, 0.05, -0.02), Vector3(0, 0, 90)), 8)
	for i in 3:
		k.box(Vector3(0.2, 0.02, 0.02), c, lx * MeshKit.at(0, 0.2 + i * 0.25, 0))
	k.box(Vector3(0.24, 0.015, 0.12), s(t, "metal"), x * MeshKit.at(0, 0.02, 0.07))
	k.box(Vector3(0.24, 0.025, 0.03), Color(0.15, 0.15, 0.16), lx * MeshKit.at(0, 0.8, 0))


## An open crate in front of the stack: packing and a card (glowing at g3).
static func _open_crate(k: MeshKit, x: Transform3D, t: int, col: Color, glow: bool) -> void:
	var c: Color = s(t, "card") if t < 2 else (s(t, "shell") if t == 2 else s(t, "shell2"))
	var w := 0.4
	var d := 0.22
	var h := 0.16
	k.box(Vector3(w, 0.02, d), c.darkened(0.1), x * MeshKit.at(0, 0.01, 0))
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(0.02, h, d), c, x * MeshKit.at(sx * w * 0.5, h * 0.5, 0))
		k.box(Vector3(w, h, 0.02), c, x * MeshKit.at(0, h * 0.5, sx * d * 0.5))
	# the lid leaning on it
	k.box(Vector3(w, 0.02, d), c, x * MeshKit.xf(Vector3(0, h + 0.06, -d * 0.5 - 0.03), Vector3(-70, 0, 0)))
	# packing foam and the card
	k.box(Vector3(w - 0.04, 0.05, d - 0.04), Color(0.3, 0.3, 0.33) if t >= 3 else Color(0.9, 0.88, 0.8), x * MeshKit.at(0, 0.06, 0))
	var card := x * MeshKit.xf(Vector3(0, 0.16, 0.0), Vector3(-25, 0, 0))
	k.box(Vector3(0.32, 0.12, 0.03), Color(0.14, 0.15, 0.18), card)
	for sx: float in [-0.08, 0.08]:
		k.cyl(0.045, 0.008, Color(0.32, 0.34, 0.38), card * MeshKit.xf(Vector3(sx, 0.0, 0.015), Vector3(90, 0, 0)), 8)
	k.box(Vector3(0.3, 0.015, 0.012), lit(s(t, "glow"), 0.3) if glow else col, card * MeshKit.at(0, -0.05, 0.016))
	k.box(Vector3(0.28, 0.02, 0.01), Pal.BRASS, card * MeshKit.at(0, -0.065, -0.004))
	if glow:
		k.box(Vector3(0.012, 0.11, 0.012), lit(s(t, "glow"), 0.3), card * MeshKit.at(0.15, 0, 0.016))


## A battery pack: one unit with charge bars; a bigger one with a display and
## a conduit; a pair with a junction box; a bank of three glowing, with a vent
## hood and a warning sign. In the garage it's car batteries on crates.
static func _battery(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	if t == 0:
		_battery_garage(k, g, x)
		return
	match g:
		0:
			var y := _skid(k, x, Vector3.ZERO, 0.5, 0.4, t)
			_batt_unit(k, x, Vector3(0, y, 0), Vector3(0.42, 0.6, 0.3), t, 0)
		1:
			var y := _skid(k, x, Vector3.ZERO, 0.58, 0.44, t)
			_batt_unit(k, x, Vector3(-0.02, y, 0), Vector3(0.46, 0.88, 0.32), t, 1)
			_conduit(k, x, Vector3(0.21, y + 0.7, -0.06), 1.0, t)
			_meter(k, x * MeshKit.xf(Vector3(-0.25, y + 0.55, 0.0), Vector3(0, -90, 0)), Vector3.ZERO, t)
		2:
			var y := _skid(k, x, Vector3.ZERO, 0.74, 0.5, t)
			for sx: float in [-1.0, 1.0]:
				_batt_unit(k, x, Vector3(sx * 0.19, y, -0.03), Vector3(0.3, 0.9, 0.3), t, 2)
			# a junction box between them with cables to each
			_shell(k, x, Vector3(0, y + 0.42, 0.16), Vector3(0.14, 0.18, 0.08), t)
			for sx: float in [-1.0, 1.0]:
				_cable(k, x, [Vector3(0, y + 0.5, 0.2), Vector3(sx * 0.12, y + 0.5, 0.18), Vector3(sx * 0.12, y + 0.6, 0.13)], t, 0.022)
			_cable(k, x, [Vector3(0, y + 0.42, 0.18), Vector3(0, 0.02, 0.24), Vector3(0.1, 0.02, 0.34)], t, 0.028)
		3:
			var y := _skid(k, x, Vector3.ZERO, 0.76, 0.52, t)
			for i in 3:
				_batt_unit(k, x, Vector3(-0.245 + i * 0.245, y, -0.03), Vector3(0.23, 0.98, 0.32), t, 3)
			# a ventilation hood over the bank
			_u(k, x, Vector3(0, y + 1.0, -0.03), Vector3(0.76, 0.04, 0.38), s(t, "frame"))
			for i in 3:
				_u(k, x, Vector3(-0.22 + i * 0.22, y + 1.04, -0.03), Vector3(0.18, 0.03, 0.32), s(t, "dark"))
				_r(k, x, Vector3(-0.22 + i * 0.22, y + 1.1, -0.03), Vector3(0.14, 0.012, 0.3), Vector3(0, 0, 20), s(t, "shell2"))
			_sign(k, x * MeshKit.xf(Vector3(0.38, y + 0.6, 0.0), Vector3(0, 90, 0)), Vector3.ZERO, 0.16, t)
			_hazard(k, x, Vector3(0, y + 0.02, 0.28), 0.72, 0.03)
			_cable(k, x, [Vector3(-0.35, y + 0.85, -0.12), Vector3(-0.36, y + 0.85, -0.12), Vector3(-0.36, 0.02, -0.2)], t, 0.034)


## One battery cabinet; lvl sets how many bars are lit and how much is on it.
static func _batt_unit(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, t: int, lvl: int) -> void:
	_shell(k, x, p, sz, t)
	var fz := p.z + sz.z * 0.5
	var on := 2 + mini(lvl, 2)
	var gc := Color(0.5, 1.0, 0.6) if t != 4 else s(t, "glow")
	match t:
		1:
			# lead-acid cabinet: charge windows, terminals on top, a sticker
			for j in 4:
				_b(k, x, Vector3(p.x, p.y + sz.y * 0.3 + j * 0.07, fz + 0.006), Vector3(sz.x * 0.55, 0.045, 0.01), lit(gc, 0.4) if j < on else s(t, "dark"))
			for sx: float in [-1.0, 1.0]:
				_cy(k, x, Vector3(p.x + sx * sz.x * 0.25, p.y + sz.y + 0.02, p.z), 0.03, 0.05, s(t, "accent2") if sx > 0 else s(t, "dark"), 6)
			_sign(k, x, Vector3(p.x, p.y + sz.y * 0.75, fz), 0.1, t)
		2:
			# a sleek wall battery: inset face, a vertical light bar, a logo
			_b(k, x, Vector3(p.x, p.y + sz.y * 0.45, fz + 0.005), Vector3(sz.x - 0.05, sz.y * 0.7, 0.01), s(t, "shell2").lightened(0.4))
			_b(k, x, Vector3(p.x, p.y + sz.y * 0.45, fz + 0.012), Vector3(0.025, sz.y * 0.1 * on, 0.006), lit(s(t, "glow"), 0.35) if lvl >= 1 else s(t, "accent"))
			_b(k, x, Vector3(p.x, p.y + sz.y * 0.78, fz + 0.012), Vector3(sz.x * 0.3, 0.03, 0.004), s(t, "accent"))
		3:
			# a rack with louvres and blue charge bars
			_vent(k, x, Vector3(p.x, p.y + sz.y * 0.2, fz + 0.004), sz.x * 0.75, 0.16, t)
			for j in 4:
				_b(k, x, Vector3(p.x, p.y + sz.y * 0.45 + j * 0.06, fz + 0.006), Vector3(sz.x * 0.6, 0.03, 0.01), lit(s(t, "glow"), 0.4) if j < on else s(t, "dark"))
			_b(k, x, Vector3(p.x, p.y + sz.y * 0.82, fz + 0.006), Vector3(sz.x * 0.4, 0.04, 0.008), s(t, "accent"))
		4:
			# a monolith with a grid of glowing cells
			for i in 2:
				for j in 4:
					_b(k, x, Vector3(p.x - sz.x * 0.18 + i * sz.x * 0.36, p.y + sz.y * 0.25 + j * sz.y * 0.15, fz + 0.006), Vector3(sz.x * 0.28, sz.y * 0.1, 0.01), lit(s(t, "glow"), 0.4) if j < on else s(t, "shell2"))
	if lvl >= 3:
		_b(k, x, Vector3(p.x + sz.x * 0.4, p.y + sz.y * 0.5, fz + 0.012), Vector3(0.016, sz.y * 0.7, 0.008), lit(gc, 0.3))


## Car batteries on crates, wired with jumper cables.
static func _battery_garage(k: MeshKit, g: int, x: Transform3D) -> void:
	var shelves: int = [1, 1, 2, 3][g]
	var per: int = [1, 2, 2, 2][g]
	var w := 0.62 if g >= 2 else 0.44
	var gap := 0.34
	# crate legs and plank shelves
	for i in shelves:
		var y := i * gap
		if i == 0:
			_u(k, x, Vector3(0, 0, 0), Vector3(w, 0.26, 0.34), s(0, "card"))
			_b(k, x, Vector3(0, 0.13, 0.172), Vector3(w * 0.6, 0.012, 0.004), Color(0.16, 0.14, 0.13))
		else:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * (w * 0.5 - 0.04), y - 0.08, 0), Vector3(0.07, 0.34, 0.3), s(0, "frame"))
			_u(k, x, Vector3(0, y + 0.24, 0), Vector3(w + 0.04, 0.025, 0.36), s(0, "base"))
		for j in per:
			var bx := 0.0 if per == 1 else -w * 0.25 + j * w * 0.5
			var by := 0.26 + (y + 0.025 if i > 0 else 0.0)
			_u(k, x, Vector3(bx, by, 0), Vector3(0.22, 0.15, 0.15), Color(0.14, 0.14, 0.15))
			_u(k, x, Vector3(bx, by + 0.15, 0), Vector3(0.2, 0.012, 0.13), Color(0.22, 0.22, 0.24))
			_cy(k, x, Vector3(bx - 0.06, by + 0.16, 0.03), 0.015, 0.025, Color(0.86, 0.3, 0.24))
			_cy(k, x, Vector3(bx + 0.06, by + 0.16, 0.03), 0.015, 0.025, Color(0.2, 0.2, 0.22))
			_b(k, x, Vector3(bx, by + 0.08, 0.077), Vector3(0.12, 0.05, 0.004), Color(0.95, 0.8, 0.3))
			# jumper cables
			_run(k, x, [Vector3(bx - 0.06, by + 0.19, 0.03), Vector3(bx - 0.1, by + 0.22, 0.12), Vector3(bx - 0.14, by - 0.02, 0.19)], 0.014, Color(0.86, 0.3, 0.24))
			_b(k, x, Vector3(bx - 0.06, by + 0.19, 0.03), Vector3(0.03, 0.03, 0.05), Color(0.86, 0.3, 0.24))
	# a charger with a dial and the extension cord
	if g >= 1:
		var cy := 0.26 + ((shelves - 1) * gap + 0.025 if shelves > 1 else 0.0)
		_u(k, x, Vector3(w * 0.5 - 0.02, cy, 0.12), Vector3(0.12, 0.1, 0.08), Color(0.86, 0.3, 0.24) if g < 3 else Color(0.3, 0.32, 0.36))
		_cz(k, x, Vector3(w * 0.5 - 0.02, cy + 0.06, 0.16), 0.025, 0.006, lit(s(0, "glow"), 0.4) if g >= 3 else Color(0.95, 0.95, 0.9), 8)
		_cable(k, x, [Vector3(w * 0.5 + 0.04, cy + 0.05, 0.12), Vector3(0.36, 0.1, 0.2), Vector3(0.34, 0.015, 0.34), Vector3(0.1, 0.015, 0.36)], 0)
	if g >= 3:
		# a bare bulb on a stick and a scrawled sign
		_u(k, x, Vector3(-w * 0.5 - 0.01, 0, -0.16), Vector3(0.03, 1.25, 0.03), s(0, "frame"))
		_u(k, x, Vector3(-w * 0.5 + 0.06, 1.2, -0.16), Vector3(0.16, 0.025, 0.025), s(0, "frame"))
		_run(k, x, [Vector3(-w * 0.5 + 0.12, 1.2, -0.16), Vector3(-w * 0.5 + 0.12, 1.1, -0.16)], 0.008, Color(0.15, 0.15, 0.16))
		k.sphere(0.04, lit(s(0, "glow"), 0.25), x * MeshKit.at(-w * 0.5 + 0.12, 1.07, -0.16), 6, 4)
		_sign(k, x, Vector3(0.0, 0.14, 0.172), 0.2, 0)


## Solar panels: one panel; two with storage; a rack of three with a
## combiner box; four with storage and glowing cells. The mount changes with
## the era: leaning on a crate with a car battery (0), a steel A-frame (1), a
## slim white rack (2), a dark tracker post (3), a brass heliostat (4).
static func _solar(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var n: int = [1, 2, 3, 4][g]
	if t == 4:
		# heliostats: one, a bigger one, two, a cluster round a glowing receiver
		match g:
			0: _heliostat(k, x, Vector3(0, 0, 0), 0.5, 0.75, t, false)
			1: _heliostat(k, x, Vector3(0, 0, 0), 0.62, 1.0, t, false)
			2:
				_heliostat(k, x, Vector3(-0.18, 0, -0.12), 0.38, 0.95, t, false)
				_heliostat(k, x, Vector3(0.2, 0, 0.14), 0.38, 0.7, t, false)
			3:
				_heliostat(k, x, Vector3(-0.2, 0, -0.16), 0.34, 0.95, t, true)
				_heliostat(k, x, Vector3(0.22, 0, -0.12), 0.32, 0.8, t, true)
				_heliostat(k, x, Vector3(-0.12, 0, 0.22), 0.3, 0.6, t, true)
				# the receiver: a brass column with a glowing crown
				_cy(k, x, Vector3(0.24, 0, 0.22), 0.1, 0.06, s(t, "shell"), 8)
				_cy(k, x, Vector3(0.24, 0.06, 0.22), 0.04, 1.24, s(t, "frame"), 6)
				_cy(k, x, Vector3(0.24, 1.3, 0.22), 0.08, 0.14, lit(s(t, "glow"), 0.3), 8)
				_cy(k, x, Vector3(0.24, 1.44, 0.22), 0.09, 0.02, s(t, "frame"), 8)
		return
	var rows := 1 if g < 3 else 2
	var per := n / rows
	for r in rows:
		for i in per:
			var px := -0.33 + (i + 0.5) * 0.66 / per
			var pz := -0.08 if rows == 1 else (-0.22 + r * 0.3)
			var w := 0.5 if g == 0 else 0.66 / per - 0.03
			if g == 0:
				px = 0.0
			_solar_unit(k, x, Vector3(px, 0, pz), w, 0.38 if rows == 1 else 0.26, t, r)
	if g == 0 and t != 0:
		_shell(k, x, Vector3(0.26, 0, 0.24), Vector3(0.1, 0.12, 0.06), t)
		_cable(k, x, [Vector3(0.21, 0.06, 0.24), Vector3(0.1, 0.05, 0.16), Vector3(0.05, 0.2, 0.0)], t, 0.016)
	elif g == 0:
		_u(k, x, Vector3(0.2, 0, 0.22), Vector3(0.18, 0.12, 0.12), Color(0.14, 0.14, 0.15))
		_cy(k, x, Vector3(0.16, 0.12, 0.24), 0.012, 0.02, Color(0.86, 0.3, 0.24))
		_cable(k, x, [Vector3(0.16, 0.14, 0.24), Vector3(0.05, 0.1, 0.18), Vector3(0.0, 0.18, 0.02)], 0, 0.014)
	# storage and wiring in front
	match t:
		0:
			if g >= 1:
				_u(k, x, Vector3(0.18, 0, 0.26), Vector3(0.22, 0.15, 0.15), Color(0.14, 0.14, 0.15))
				_cy(k, x, Vector3(0.13, 0.15, 0.28), 0.015, 0.025, Color(0.86, 0.3, 0.24))
				_cy(k, x, Vector3(0.23, 0.15, 0.28), 0.015, 0.025, Color(0.2, 0.2, 0.22))
				_cable(k, x, [Vector3(0.13, 0.17, 0.28), Vector3(0.0, 0.1, 0.22), Vector3(-0.1, 0.2, 0.06)], 0, 0.016)
			if g >= 2:
				_u(k, x, Vector3(-0.2, 0, 0.28), Vector3(0.16, 0.12, 0.1), Color(0.86, 0.3, 0.24))
				_cable(k, x, [Vector3(-0.12, 0.06, 0.28), Vector3(0.07, 0.03, 0.28)], 0, 0.016)
			if g >= 3:
				k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(-0.2, 0.16, 0.28), 6, 4)
		_:
			if g >= 1:
				var ix := 0.24 if g < 3 else 0.28
				_shell(k, x, Vector3(ix, 0, 0.27), Vector3(0.16, 0.22 + g * 0.03, 0.09), t)
				_lamp(k, x, Vector3(ix, 0.16 + g * 0.03, 0.32), t, Color(0.5, 1.0, 0.6) if t < 3 else Color(0, 0, 0, 0))
				_vent(k, x, Vector3(ix, 0.07, 0.315), 0.1, 0.06, t)
				_cable(k, x, [Vector3(ix - 0.08, 0.12, 0.27), Vector3(ix - 0.2, 0.12, 0.22), Vector3(ix - 0.22, 0.25, 0.04)], t, 0.018)
			if g >= 2:
				_shell(k, x, Vector3(-0.26, 0, 0.29), Vector3(0.18, 0.3, 0.1), t)
				_meter(k, x, Vector3(-0.26, 0.17, 0.34), t)
			if g >= 3:
				_b(k, x, Vector3(-0.26, 0.31, 0.345), Vector3(0.16, 0.012, 0.01), lit(s(t, "glow"), 0.3))


## One panel and its mount (p = ground under the panel centre).
static func _solar_unit(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, t: int, row: int) -> void:
	match t:
		0:
			# leaning on a crate (or a couple of bricks)
			var cy := 0.24
			_u(k, x, Vector3(p.x, 0, p.z - d * 0.32), Vector3(w * 0.7, cy, 0.16), s(0, "card") if row == 0 else Pal.BRICK)
			var tilt := rad_to_deg(atan2(cy + 0.02, d * 0.8))
			_panel(k, x * MeshKit.xf(Vector3(p.x, cy * 0.5 + 0.02, p.z), Vector3(tilt, 0, 1.5)), w, d, t, false)
		1:
			# a galvanised A-frame with yellow feet
			var h := 0.42
			for sx: float in [-1.0, 1.0]:
				var lx := p.x + sx * (w * 0.5 - 0.03)
				_seg(k, x, Vector3(lx, 0, p.z - d * 0.4), Vector3(lx, h, p.z - d * 0.3), 0.025, s(t, "metal"))
				_seg(k, x, Vector3(lx, 0, p.z + d * 0.4), Vector3(lx, 0.16, p.z + d * 0.32), 0.025, s(t, "metal"))
				_seg(k, x, Vector3(lx, 0.03, p.z - d * 0.4), Vector3(lx, 0.03, p.z + d * 0.4), 0.02, s(t, "metal"))
				for fz: float in [-0.4, 0.4]:
					_u(k, x, Vector3(lx, 0, p.z + d * fz), Vector3(0.05, 0.02, 0.05), s(t, "accent"))
			_panel(k, x * MeshKit.xf(Vector3(p.x, (h + 0.16) * 0.5 + 0.02, p.z), Vector3(30, 0, 0)), w, d, t, false)
		2:
			# a slim white post with a teal cap
			_u(k, x, Vector3(p.x, 0, p.z - 0.04), Vector3(0.1, 0.03, 0.1), s(t, "base"))
			_u(k, x, Vector3(p.x, 0, p.z - 0.04), Vector3(0.05, 0.3, 0.05), s(t, "shell"))
			_b(k, x, Vector3(p.x, 0.3, p.z - 0.04), Vector3(w * 0.8, 0.03, 0.05), s(t, "accent"))
			_panel(k, x * MeshKit.xf(Vector3(p.x, 0.34, p.z), Vector3(22, 0, 0)), w, d, t, false)
		3:
			# a single-axis tracker: a dark post, a motor, a torque tube
			_u(k, x, Vector3(p.x, 0, p.z), Vector3(0.12, 0.04, 0.12), s(t, "base"))
			_u(k, x, Vector3(p.x, 0.04, p.z), Vector3(0.05, 0.36, 0.05), s(t, "frame"))
			_b(k, x, Vector3(p.x + 0.05, 0.34, p.z), Vector3(0.06, 0.07, 0.07), s(t, "shell"))
			_lamp(k, x, Vector3(p.x + 0.05, 0.34, p.z + 0.04), t)
			_b(k, x, Vector3(p.x, 0.42, p.z), Vector3(w, 0.03, 0.03), s(t, "metal"))
			_panel(k, x * MeshKit.xf(Vector3(p.x, 0.45, p.z), Vector3(34, 0, 0)), w, d, t, true)


## A panel in its local XZ plane (facing +Y): cells, frame and grid lines.
static func _panel(k: MeshKit, xf: Transform3D, w: float, d: float, t: int, glow: bool) -> void:
	var fc: Color = [Color(0.66, 0.66, 0.62), Color(0.82, 0.84, 0.86), Color(0.96, 0.96, 0.97), Color(0.22, 0.24, 0.28), s(4, "frame")][t]
	k.box(Vector3(w, 0.025, d), fc, xf)
	k.box(Vector3(w - 0.03, 0.01, d - 0.03), Color(0.14, 0.22, 0.42) if t != 0 else Color(0.2, 0.26, 0.4), xf * MeshKit.at(0, 0.015, 0))
	var n := maxi(1, int(w / 0.14))
	for i in n:
		k.box(Vector3(0.006, 0.006, d - 0.04), Color(0.5, 0.58, 0.74), xf * MeshKit.at(-w * 0.5 + (i + 1) * w / (n + 1), 0.021, 0))
	k.box(Vector3(w - 0.04, 0.006, 0.006), Color(0.5, 0.58, 0.74), xf * MeshKit.at(0, 0.021, 0))
	if t == 0:
		# second-hand: a cracked cell and a taped corner
		k.box(Vector3(w * 0.3, 0.004, 0.008), Color(0.7, 0.74, 0.8), xf * MeshKit.xf(Vector3(w * 0.15, 0.022, d * 0.2), Vector3(0, 30, 0)))
		k.box(Vector3(0.08, 0.006, 0.05), s(0, "tape"), xf * MeshKit.at(-w * 0.5 + 0.04, 0.024, -d * 0.5 + 0.03))
	if glow:
		k.box(Vector3(w - 0.05, 0.004, 0.01), lit(s(t, "glow"), 0.4), xf * MeshKit.at(0, 0.024, d * 0.3))


## A brass heliostat: a post on a graphite base, a yoke and a mirror of cells.
static func _heliostat(k: MeshKit, x: Transform3D, p: Vector3, w: float, h: float, t: int, glow: bool) -> void:
	_cy(k, x, p, 0.09, 0.06, s(t, "shell"), 8)
	_b(k, x, Vector3(p.x, 0.03, p.z + 0.09), Vector3(0.08, 0.012, 0.006), lit(s(t, "glow"), 0.4))
	_cy(k, x, p + Vector3(0, 0.06, 0), 0.025, h - 0.12, s(t, "frame"), 6)
	for sx: float in [-1.0, 1.0]:
		_b(k, x, Vector3(p.x + sx * 0.06, p.y + h - 0.04, p.z), Vector3(0.02, 0.1, 0.03), s(t, "frame"))
	_b(k, x, Vector3(p.x, p.y + h - 0.09, p.z), Vector3(0.14, 0.02, 0.03), s(t, "frame"))
	var gx := x * MeshKit.xf(p + Vector3(0, h, 0), Vector3(40, 0, 0))
	k.cyl(0.03, 0.12, s(t, "frame"), gx * MeshKit.xf(Vector3(-0.06, 0, 0), Vector3(0, 0, -90)), 6)
	k.box(Vector3(w, 0.025, w * 0.75), s(t, "frame"), gx * MeshKit.at(0, 0.03, 0))
	k.box(Vector3(w - 0.03, 0.01, w * 0.75 - 0.03), s(t, "dark"), gx * MeshKit.at(0, 0.047, 0))
	for i in 3:
		for j in 2:
			k.box(Vector3(w / 3.0 - 0.025, 0.006, w * 0.375 - 0.025), lit(s(t, "accent2"), 0.45) if (glow or (i + j) % 2 == 0) else Color(0.16, 0.24, 0.4), gx * MeshKit.at(-w / 3.0 + i * w / 3.0, 0.054, -w * 0.1875 + j * w * 0.375))


## An air-cooled chiller: a small unit with one fan; a bigger one with two
## fans, coolant pipes into the ground and a gauge; a pair with a pipe
## manifold; with a guard rail, a glowing control panel and a sign. In the
## garage it's a beige window AC on bricks with hoses taped on.
static func _chiller(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var cc: Color = Color(0.86, 0.82, 0.72) if t == 0 else (Color(0.88, 0.89, 0.9) if t == 1 else Color(0, 0, 0, 0))
	match g:
		0:
			var y := _bricks(k, x, Vector3(0, 0, 0), 0.5, 0.34, t)
			_chill_unit(k, x, Vector3(0, y, 0), Vector3(0.5, 0.36, 0.34), t, 1, cc)
		1:
			var y := _bricks(k, x, Vector3(0, 0, -0.03), 0.7, 0.42, t)
			_chill_unit(k, x, Vector3(0, y, -0.03), Vector3(0.66, 0.46, 0.4), t, 2, cc)
			_chill_pipes(k, x, Vector3(0.18, y + 0.15, 0.17), t)
		_:
			var y := _bricks(k, x, Vector3(0, 0, 0), 0.72, 0.72, t)
			var w := 0.66 if g == 2 else 0.62
			_chill_unit(k, x, Vector3(-0.02, y, -0.18), Vector3(w, 0.44, 0.34), t, 2, cc)
			_chill_unit(k, x, Vector3(-0.02, y, 0.18), Vector3(w, 0.44, 0.34), t, 2, cc)
			# a supply and return manifold along the side
			for i in 2:
				var pc: Color = [Color(0.36, 0.6, 0.86), Color(0.86, 0.42, 0.32)][i]
				if t == 0:
					pc = Color(0.3, 0.55, 0.3)
				elif t == 4:
					pc = s(t, "frame") if i == 0 else lit(s(t, "accent2"), 0.5)
				var py := y + 0.12 + i * 0.12
				_seg(k, x, Vector3(0.33, py, -0.32), Vector3(0.33, py, 0.32), 0.045, pc)
				for sz: float in [-0.18, 0.18]:
					_seg(k, x, Vector3(0.29, py, sz), Vector3(0.36, py, sz), 0.06, pc.darkened(0.2))
				_seg(k, x, Vector3(0.33, py, 0.32), Vector3(0.33, 0.02, 0.36), 0.045, pc)
			if g == 3:
				# a glowing control panel on a post and a guard rail round the top
				_u(k, x, Vector3(-0.3, 0, 0.33), Vector3(0.03, 0.62, 0.03), s(t, "frame"))
				_shell(k, x, Vector3(-0.3, 0.5, 0.33), Vector3(0.16, 0.2, 0.05), t)
				_b(k, x, Vector3(-0.3, 0.62, 0.36), Vector3(0.11, 0.07, 0.006), lit(s(t, "glow"), 0.4))
				_sign(k, x * MeshKit.xf(Vector3(-0.335, y + 0.22, 0.0), Vector3(0, -90, 0)), Vector3.ZERO, 0.14, t)
				var rh := y + 0.44
				if t > 0:
					var rc: Color = s(t, "accent") if t != 2 else s(t, "frame")
					for sx: float in [-1.0, 1.0]:
						for sz: float in [-1.0, 1.0]:
							_u(k, x, Vector3(sx * 0.33, rh, sz * 0.34), Vector3(0.02, 0.18, 0.02), rc)
						_u(k, x, Vector3(sx * 0.33, rh + 0.18, 0), Vector3(0.02, 0.02, 0.7), rc)
					_u(k, x, Vector3(0, rh + 0.18, -0.34), Vector3(0.68, 0.02, 0.02), rc)
				else:
					k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(-0.3, 0.84, 0.36), 6, 4)


## Bricks (garage) or the era's skid under a unit; returns the height.
static func _bricks(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, t: int) -> float:
	if t != 0:
		return _skid(k, x, p, w, d, t)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.08), p.y, p.z + sz * (d * 0.5 - 0.06)), Vector3(0.14, 0.08, 0.1), Pal.BRICK if sx * sz > 0.0 else Pal.BRICK_DARK)
	return 0.08


## One chiller unit: casing, fans on top, coil fins on the front.
static func _chill_unit(k: MeshKit, x: Transform3D, p: Vector3, sz: Vector3, t: int, fans: int, c: Color) -> void:
	_shell(k, x, p, sz, t, c)
	var fz := p.z + sz.z * 0.5
	var r := minf(sz.z * 0.38, sz.x / fans * 0.36)
	for i in fans:
		_fan(k, x * MeshKit.at(p.x - sz.x * 0.5 + (i + 0.5) * sz.x / fans, p.y + sz.y + 0.012, p.z), r, t)
	# coil fins
	var n := int(sz.x / 0.075)
	_b(k, x, Vector3(p.x, p.y + sz.y * 0.45, fz + 0.004), Vector3(sz.x - 0.08, sz.y * 0.6, 0.008), s(t, "dark") if t != 2 else s(t, "shell2"))
	for i in n:
		_b(k, x, Vector3(p.x - sz.x * 0.5 + 0.06 + i * (sz.x - 0.12) / maxf(1, n - 1), p.y + sz.y * 0.45, fz + 0.012), Vector3(0.008, sz.y * 0.6, 0.01), c.darkened(0.15) if c.a > 0.0 else s(t, "shell").darkened(0.1))
	if t >= 3:
		_b(k, x, Vector3(p.x + sz.x * 0.3, p.y + sz.y * 0.88, fz + 0.01), Vector3(0.08, 0.03, 0.006), lit(s(t, "glow"), 0.4))


## Supply and return pipes from a unit down into the ground, with a gauge.
static func _chill_pipes(k: MeshKit, x: Transform3D, a: Vector3, t: int) -> void:
	for i in 2:
		var pc: Color = [Color(0.36, 0.6, 0.86), Color(0.86, 0.42, 0.32)][i]
		if t == 0:
			pc = Color(0.3, 0.55, 0.3)
		elif t == 4:
			pc = s(t, "frame") if i == 0 else lit(s(t, "accent2"), 0.5)
		var px := a.x + i * 0.1
		_run(k, x, [Vector3(px, a.y, a.z), Vector3(px, a.y, a.z + 0.1), Vector3(px, 0.02, a.z + 0.14)], 0.04, pc)
		if t == 0:
			_b(k, x, Vector3(px, a.y, a.z + 0.04), Vector3(0.05, 0.05, 0.03), s(0, "tape"))
	_cz(k, x, Vector3(a.x + 0.05, a.y + 0.08, a.z + 0.06), 0.03, 0.02, Color(0.95, 0.95, 0.9) if t < 3 else lit(s(t, "glow"), 0.45), 8)


## A generator: a small portable set; an enclosed set on a skid with an
## exhaust and a control panel; with a day tank and a taller stack; fenced,
## with a glowing panel and a warning sign. Red open frame in the garage,
## yellow plant in the workshop, a white enclosure on campus, a dark diesel
## set, a graphite fuel cell with glowing fins.
static func _gen(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var gc: Color = [Color(0.82, 0.28, 0.22), Color(0.96, 0.74, 0.18), Color(0.95, 0.95, 0.96), Color(0.36, 0.4, 0.46), Color(0.19, 0.2, 0.23)][t]
	if g == 0:
		# a portable set: a tube frame round an engine and a tank
		var fc: Color = Color(0.16, 0.16, 0.17) if t != 4 else s(t, "frame")
		_u(k, x, Vector3(0, 0.06, 0), Vector3(0.4, 0.2, 0.26), gc.darkened(0.25) if t != 4 else s(t, "shell2"))
		_u(k, x, Vector3(0.04, 0.26, 0), Vector3(0.3, 0.1, 0.22), gc)
		_cy(k, x, Vector3(0.1, 0.36, 0), 0.03, 0.02, Color(0.16, 0.16, 0.17))
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.21, 0.03, sz * 0.14), Vector3(0.022, 0.36, 0.022), fc)
			_u(k, x, Vector3(sx * 0.21, 0.37, 0), Vector3(0.022, 0.022, 0.3), fc)
			_u(k, x, Vector3(sx * 0.21, 0.03, 0), Vector3(0.022, 0.022, 0.3), fc)
		_cz(k, x, Vector3(-0.1, 0.14, 0.13), 0.07, 0.02, s(t, "dark"), 8)
		_b(k, x, Vector3(0.1, 0.14, 0.135), Vector3(0.12, 0.08, 0.01), s(t, "shell2") if t != 2 else s(t, "accent"))
		_lamp(k, x, Vector3(0.14, 0.16, 0.142), t, Color(0.5, 1.0, 0.6))
		for sx: float in [-1.0, 1.0]:
			k.cyl(0.04, 0.03, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(sx * 0.22, 0.04, -0.1), Vector3(0, 0, 90)), 8)
		if t == 0:
			# a jerry can
			_u(k, x, Vector3(-0.22, 0, 0.26), Vector3(0.1, 0.2, 0.15), Color(0.8, 0.22, 0.18))
			_u(k, x, Vector3(-0.22, 0.2, 0.26), Vector3(0.06, 0.02, 0.1), Color(0.16, 0.16, 0.17))
		_cable(k, x, [Vector3(0.16, 0.12, 0.14), Vector3(0.28, 0.05, 0.24), Vector3(0.3, 0.012, 0.34)], t, 0.02)
		return
	var w: float = [0.0, 0.6, 0.64, 0.6][g]
	var d := 0.36
	var gz := -0.12 if g >= 2 else -0.04
	var y := _skid(k, x, Vector3(0, 0, gz), w + 0.06, d + 0.06, t)
	var h := 0.42 + g * 0.04
	_shell(k, x, Vector3(0, y, gz), Vector3(w, h, d), t, gc)
	var fz := gz + d * 0.5
	if t == 4:
		# fuel cell stack: glowing fins instead of louvres
		for i in 6:
			_b(k, x, Vector3(-w * 0.35 + i * 0.07, y + h * 0.45, fz + 0.02), Vector3(0.025, h * 0.6, 0.04), s(t, "shell2"))
			_b(k, x, Vector3(-w * 0.35 + i * 0.07, y + h * 0.45, fz + 0.042), Vector3(0.008, h * 0.5, 0.004), lit(s(t, "glow"), 0.4))
	else:
		_vent(k, x, Vector3(-w * 0.2, y + h * 0.45, fz), w * 0.45, h * 0.55, t)
	# control panel
	_b(k, x, Vector3(w * 0.28, y + h * 0.55, fz + 0.012), Vector3(0.14, 0.12, 0.02), s(t, "dark"))
	_b(k, x, Vector3(w * 0.28, y + h * 0.58, fz + 0.024), Vector3(0.1, 0.05, 0.004), lit(s(t, "glow"), 0.4) if g >= 3 else Color(0.3, 0.42, 0.36))
	_lamp(k, x, Vector3(w * 0.25, y + h * 0.5, fz + 0.026), t, Color(0.5, 1.0, 0.6), 0.02)
	_lamp(k, x, Vector3(w * 0.31, y + h * 0.5, fz + 0.026), t, Color(1.0, 0.4, 0.3), 0.02)
	_b(k, x, Vector3(-w * 0.3, y + h * 0.85, fz + 0.004), Vector3(0.12, 0.04, 0.006), s(t, "accent") if t != 1 else s(t, "dark"))
	# on the roof: a radiator grille, lifting eyes, a muffler from grade 2
	var top := y + h + 0.02
	_u(k, x, Vector3(-w * 0.12, top, gz - d * 0.18), Vector3(w * 0.5, 0.012, d * 0.5), s(t, "dark"))
	for i in 5:
		_u(k, x, Vector3(-w * 0.12 - w * 0.2 + i * w * 0.1, top + 0.01, gz - d * 0.18), Vector3(0.012, 0.012, d * 0.48), gc.darkened(0.2) if t != 4 else s(4, "frame"))
	for sx: float in [-1.0, 1.0]:
		_u(k, x, Vector3(sx * (w * 0.5 - 0.05), top, gz + d * 0.3), Vector3(0.04, 0.04, 0.015), s(t, "metal") if t != 4 else s(4, "frame"))
	if g >= 2 and t != 4:
		k.cyl(0.05, w * 0.42, Color(0.36, 0.36, 0.38), x * MeshKit.xf(Vector3(-w * 0.12, top + 0.08, gz - 0.06), Vector3(0, 0, -90)), 8)
		for sx: float in [-0.05, 0.2]:
			_u(k, x, Vector3(sx * w, top, gz - 0.06), Vector3(0.02, 0.05, 0.08), Color(0.3, 0.3, 0.32))
	if g >= 3:
		_cy(k, x, Vector3(-w * 0.4, top, gz + d * 0.38), 0.03, 0.03, s(t, "dark"), 6)
		_cy(k, x, Vector3(-w * 0.4, top + 0.03, gz + d * 0.38), 0.028, 0.05, lit(Color(1.0, 0.6, 0.2) if t < 3 else s(t, "glow"), 0.35), 6)
	# exhaust (or a vent stack on the fuel cell)
	var stack := 0.25 + g * 0.12
	if t == 4:
		_u(k, x, Vector3(w * 0.3, y + h, gz - 0.06), Vector3(0.12, stack * 0.5, 0.12), s(t, "shell2"))
		_b(k, x, Vector3(w * 0.3, y + h + stack * 0.5 + 0.01, gz - 0.06), Vector3(0.1, 0.012, 0.1), lit(s(t, "accent2"), 0.4))
	else:
		_cy(k, x, Vector3(w * 0.3, y + h, gz - 0.06), 0.035, stack, Color(0.3, 0.3, 0.32), 6)
		_cy(k, x, Vector3(w * 0.3, y + h + stack * 0.4, gz - 0.06), 0.055, 0.12, Color(0.4, 0.4, 0.42), 6)
		_r(k, x, Vector3(w * 0.3, y + h + stack + 0.01, gz - 0.06), Vector3(0.08, 0.008, 0.08), Vector3(-20, 0, 0), Color(0.24, 0.24, 0.26))
	_cable(k, x, [Vector3(-w * 0.5, y + 0.12, gz), Vector3(-w * 0.5 - 0.04, 0.02, gz + 0.08), Vector3(-0.36, 0.015, 0.3)], t, 0.028)
	if g >= 2:
		# a day tank on saddles in front
		var tc: Color = [Color(0.86, 0.3, 0.24), s(1, "metal"), s(2, "shell2"), s(3, "shell2"), s(4, "frame")][t]
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.18, 0, 0.24), Vector3(0.06, 0.08, 0.16), s(t, "frame") if t != 4 else s(t, "shell"))
		k.cyl(0.08, 0.56, tc, x * MeshKit.xf(Vector3(-0.28, 0.15, 0.24), Vector3(0, 0, -90)), 8)
		_cy(k, x, Vector3(0.1, 0.22, 0.24), 0.025, 0.04, s(t, "dark"))
		_run(k, x, [Vector3(-0.2, 0.2, 0.2), Vector3(-0.2, y + 0.1, fz + 0.02)], 0.022, s(t, "dark"))
	if g >= 3:
		_sign(k, x, Vector3(-w * 0.3, y + h * 0.7, fz + 0.006), 0.13, t)
		var fh := 0.5
		if t >= 1:
			var fc2: Color = s(t, "frame") if t != 1 else s(t, "metal")
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.36, 0, gz - 0.2), Vector3(0.025, fh, 0.025), fc2)
				_u(k, x, Vector3(sx * 0.36, fh, -0.05), Vector3(0.02, 0.02, 0.32), fc2)
				_u(k, x, Vector3(sx * 0.36, 0, 0.11), Vector3(0.025, fh, 0.025), fc2)
				_b(k, x, Vector3(sx * 0.36, fh * 0.5, -0.05), Vector3(0.006, fh * 0.9, 0.3), Color(0.5, 0.52, 0.55) if t < 3 else s(t, "frame").lightened(0.1))
		else:
			k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(w * 0.28, y + h + 0.06, fz), 6, 4)


## Plants: a potted plant; a shrub with a second pot; a small tree in a
## planter with flowers; a bigger tree in a planter with a ledge and a
## glowing uplight. Buckets and tyres (0), half drums and steel boxes (1),
## white planters (2), concrete and steel (3), graphite and brass (4).
static func _plant(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	match g:
		0:
			_pot(k, x, Vector3(0, 0, 0), 0.15, 0.24, t)
			_bush(k, x, Vector3(0, 0.24, 0), 0.17, t, 2)
		1:
			_pot(k, x, Vector3(-0.06, 0, -0.04), 0.2, 0.3, t)
			_bush(k, x, Vector3(-0.06, 0.3, -0.04), 0.24, t, 3)
			_pot(k, x, Vector3(0.24, 0, 0.2), 0.1, 0.16, t)
			_bush(k, x, Vector3(0.24, 0.16, 0.2), 0.1, t, 1)
		_:
			var w := 0.66 if g == 2 else 0.72
			var h := 0.32 if g == 2 else 0.36
			_planter_box(k, x, Vector3(0, 0, 0), w, w * 0.8, h, t)
			_tree(k, x, Vector3(-0.06, h, -0.04), g, t)
			# flowers and ground cover along the front
			var fc := [Color(0.94, 0.5, 0.56), Color(0.98, 0.84, 0.32), Color(0.96, 0.96, 0.94), col.lightened(0.2)]
			for i in 5:
				var fx := -w * 0.38 + i * w * 0.19
				_b(k, x, Vector3(fx, h + 0.03, w * 0.26), Vector3(0.07, 0.05, 0.07), Pal.LEAF if i % 2 else Pal.LEAF_DARK)
				_b(k, x, Vector3(fx + 0.01, h + 0.065, w * 0.26), Vector3(0.035, 0.03, 0.035), fc[i % 4])
			if g == 3:
				# an uplight and a seat ledge on the front
				_u(k, x, Vector3(0.16, h, -0.02), Vector3(0.06, 0.05, 0.06), s(t, "dark"))
				_b(k, x, Vector3(0.16, h + 0.055, -0.02), Vector3(0.045, 0.012, 0.045), lit(s(t, "glow"), 0.3))
				var lt: Color = [s(0, "base"), Pal.WOOD_LIGHT, Pal.WOOD_LIGHT, Pal.WOOD, s(4, "frame")][t]
				_u(k, x, Vector3(0, h, w * 0.4 - 0.02), Vector3(w + 0.04, 0.03, 0.12), lt)
				for i in 3:
					_b(k, x, Vector3(-w * 0.3 + i * w * 0.3, h + 0.031, w * 0.4 - 0.02), Vector3(0.006, 0.004, 0.1), lt.darkened(0.2))
				if t >= 3:
					_b(k, x, Vector3(0, 0.03, w * 0.4 + 0.002), Vector3(w - 0.06, 0.012, 0.008), lit(s(t, "glow"), 0.35))
				elif t == 0:
					# a watering can
					_cy(k, x, Vector3(0.24, 0, 0.3), 0.06, 0.1, Color(0.36, 0.6, 0.4), 6)
					_seg(k, x, Vector3(0.28, 0.06, 0.3), Vector3(0.36, 0.12, 0.3), 0.02, Color(0.36, 0.6, 0.4))


## The planter's tree, by era: tomato canes and sunflowers then a fruit tree
## (0), a leafy tree (1), clipped topiary and a cypress (2), a birch with
## grasses (3), a bonsai with cloud pads (4). p = the soil under the trunk.
static func _tree(k: MeshKit, x: Transform3D, p: Vector3, g: int, t: int) -> void:
	var big := g >= 3
	var th: float = 0.55 if not big else 0.85
	match t:
		0:
			if not big:
				# sunflowers and tomato canes
				for i in 3:
					var sx := p.x - 0.12 + i * 0.14
					var sh := 0.55 + (i % 2) * 0.18
					_u(k, x, Vector3(sx, p.y, p.z + (i % 2) * 0.06), Vector3(0.02, sh, 0.02), Pal.LEAF_DARK)
					_r(k, x, Vector3(sx, p.y + sh, p.z + (i % 2) * 0.06 + 0.02), Vector3(0.14, 0.14, 0.02), Vector3(-20, 0, 45), Color(0.98, 0.8, 0.22))
					_b(k, x, Vector3(sx, p.y + sh, p.z + (i % 2) * 0.06 + 0.035), Vector3(0.06, 0.06, 0.02), Color(0.42, 0.28, 0.16))
					_b(k, x, Vector3(sx + 0.05, p.y + sh * 0.5, p.z), Vector3(0.08, 0.02, 0.05), Pal.LEAF)
				for i in 2:
					var cx := p.x + 0.26 - i * 0.08
					_u(k, x, Vector3(cx, p.y, p.z - 0.08), Vector3(0.015, 0.5, 0.015), Pal.WOOD_LIGHT)
					k.sphere(0.07, Pal.LEAF, x * MeshKit.at(cx, p.y + 0.3, p.z - 0.06), 6, 4)
					_b(k, x, Vector3(cx + 0.03, p.y + 0.24, p.z - 0.02), Vector3(0.04, 0.04, 0.04), Color(0.86, 0.24, 0.18))
				return
			_cy(k, x, p, 0.045, th, Pal.WOOD_DARK, 6)
			_seg(k, x, p + Vector3(0, th * 0.55, 0), p + Vector3(0.16, th * 0.85, 0.06), 0.03, Pal.WOOD_DARK)
			k.sphere(0.28, Pal.LEAF_DARK, x * MeshKit.at(p.x, p.y + th + 0.1, p.z), 8, 5)
			k.sphere(0.2, Pal.LEAF, x * MeshKit.at(p.x + 0.16, p.y + th + 0.14, p.z + 0.08), 7, 4)
			for i in 5:
				_b(k, x, Vector3(p.x - 0.18 + i * 0.09, p.y + th + 0.02 + (i % 2) * 0.16, p.z + 0.22 - (i % 3) * 0.05), Vector3(0.05, 0.05, 0.05), Color(0.96, 0.56, 0.18))
		2:
			# clipped topiary balls on a straight stem, and a cypress
			_cy(k, x, p, 0.025, th + 0.1, Pal.WOOD_DARK, 6)
			var r := 0.17 if not big else 0.21
			k.sphere(r, Color(0.42, 0.62, 0.36), x * MeshKit.at(p.x, p.y + th * 0.55, p.z), 9, 6)
			k.sphere(r * 0.75, Color(0.46, 0.66, 0.38), x * MeshKit.at(p.x, p.y + th * 0.55 + r * 1.6, p.z), 9, 6)
			k.cone(0.09, th * (0.9 if big else 0.75), Pal.LEAF_DARK, x * MeshKit.at(p.x + 0.24, p.y, p.z + 0.06), 7)
		3:
			# a birch: a white trunk with dark marks and a light crown, grasses
			_cy(k, x, p, 0.035, th + 0.2, Color(0.9, 0.9, 0.86), 6)
			for i in 4:
				_b(k, x, p + Vector3(0, 0.15 + i * th * 0.22, 0.034), Vector3(0.03, 0.012, 0.006), Color(0.2, 0.2, 0.2))
			for i in 3:
				var a := TAU * i / 3.0
				k.sphere(0.16 if not big else 0.2, Color(0.56, 0.7, 0.36), x * MeshKit.at(p.x + cos(a) * 0.1, p.y + th + 0.05 + i * 0.08, p.z + sin(a) * 0.1), 7, 4)
			for i in 3:
				k.cone(0.06, 0.24, Color(0.62, 0.66, 0.42), x * MeshKit.at(p.x + 0.22 - i * 0.1, p.y, p.z + 0.12), 5)
		4:
			# a bonsai: a twisted trunk with flat cloud pads
			var tc := Color(0.32, 0.25, 0.2)
			var s2 := 1.0 if not big else 1.35
			_seg(k, x, p, p + Vector3(0.1, 0.25, 0) * s2, 0.06, tc)
			_seg(k, x, p + Vector3(0.1, 0.25, 0) * s2, p + Vector3(-0.06, 0.5, 0.02) * s2, 0.05, tc)
			_seg(k, x, p + Vector3(0.05, 0.32, 0) * s2, p + Vector3(0.22, 0.42, 0.04) * s2, 0.035, tc)
			for c: Vector3 in [Vector3(-0.08, 0.56, 0.02), Vector3(0.22, 0.46, 0.04), Vector3(0.06, 0.68, -0.04)]:
				k.ellipsoid(Vector3(0.16, 0.06, 0.13) * s2, Color(0.3, 0.46, 0.32), x * MeshKit.at(p.x + c.x * s2, p.y + c.y * s2, p.z + c.z * s2), 8, 4)
			k.torus(0.2, 0.01, lit(s(4, "glow"), 0.3), x * MeshKit.at(p.x, p.y + 0.01, p.z), 12, 3)
		_:
			var tc2 := Pal.WOOD_DARK
			_cy(k, x, p, 0.035 + g * 0.006, th, tc2, 6)
			_seg(k, x, p + Vector3(0, th * 0.55, 0), p + Vector3(0.16, th * 0.85, 0.06), 0.03, tc2)
			var cr := 0.22 + (g - 2) * 0.06
			k.sphere(cr, Pal.LEAF_DARK, x * MeshKit.at(p.x, p.y + th + cr * 0.4, p.z), 8, 5)
			k.sphere(cr * 0.75, Pal.LEAF, x * MeshKit.at(p.x + 0.16, p.y + th + cr * 0.55, p.z + 0.1), 7, 5)
			k.sphere(cr * 0.65, Pal.LEAF, x * MeshKit.at(p.x - 0.14, p.y + th + cr * 0.2, p.z + 0.06), 7, 4)
			if big:
				k.sphere(cr * 0.55, Pal.LEAF_DARK.lightened(0.1), x * MeshKit.at(p.x + 0.08, p.y + th + cr * 1.05, p.z - 0.06), 7, 4)


## A round pot of the era, standing on p.
static func _pot(k: MeshKit, x: Transform3D, p: Vector3, r: float, h: float, t: int) -> void:
	match t:
		0:
			if r > 0.12:
				# an old tyre with a bucket in it
				k.torus(r * 1.05, 0.05, Color(0.15, 0.15, 0.16), x * MeshKit.at(p.x, p.y + 0.05, p.z), 10, 4)
				_cy(k, x, p, r * 0.8, h, Color(0.64, 0.66, 0.68), 8, r)
			else:
				_cy(k, x, p, r * 0.8, h, Color(0.64, 0.66, 0.68), 8, r)
				_seg(k, x, p + Vector3(-r, h, 0), p + Vector3(0, h + r * 0.8, 0), 0.008, Color(0.4, 0.42, 0.44))
				_seg(k, x, p + Vector3(r, h, 0), p + Vector3(0, h + r * 0.8, 0), 0.008, Color(0.4, 0.42, 0.44))
			_cy(k, x, p + Vector3(0, h - 0.02, 0), r * 1.02, 0.02, Color(0.56, 0.58, 0.6), 8)
		1:
			_cy(k, x, p, r, h, s(t, "accent"), 8)
			for f: float in [0.35, 0.75]:
				_cy(k, x, p + Vector3(0, h * f, 0), r * 1.04, 0.02, s(t, "accent").darkened(0.2), 8)
			_cy(k, x, p + Vector3(0, h, 0), r * 1.02, 0.015, s(t, "frame"), 8)
		2:
			_cy(k, x, p, r * 0.8, h, s(t, "shell"), 8, r)
			_cy(k, x, p + Vector3(0, h * 0.7, 0), r * 0.96, 0.03, s(t, "accent"), 8)
		3:
			_u(k, x, p, Vector3(r * 2.0, h, r * 2.0), s(t, "base"))
			_u(k, x, p + Vector3(0, h, 0), Vector3(r * 2.0 + 0.02, 0.02, r * 2.0 + 0.02), s(t, "frame"))
		4:
			_u(k, x, p, Vector3(r * 1.9, h, r * 1.9), s(t, "shell"))
			_u(k, x, p + Vector3(0, h, 0), Vector3(r * 1.9 + 0.02, 0.02, r * 1.9 + 0.02), s(t, "frame"))
			_b(k, x, p + Vector3(0, 0.03, r * 0.95 + 0.003), Vector3(r * 1.5, 0.012, 0.006), lit(s(t, "glow"), 0.35))
	_cy(k, x, p + Vector3(0, h - 0.03, 0), r * 0.85, 0.02, Pal.SOIL, 8)


## A planter box on p.
static func _planter_box(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, h: float, t: int) -> void:
	match t:
		0:
			# a wooden crate planter
			for i in 3:
				var c: Color = s(0, "base").darkened(0.06 * i)
				_b(k, x, Vector3(p.x, p.y + 0.055 + i * h / 3.0, p.z), Vector3(w, h / 3.0 - 0.015, d), c)
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.02), p.y, p.z + sz * (d * 0.5 - 0.02)), Vector3(0.045, h, 0.045), s(0, "frame"))
		1:
			_u(k, x, p, Vector3(w, h, d), s(t, "shell2"))
			_u(k, x, p + Vector3(0, h, 0), Vector3(w + 0.02, 0.025, d + 0.02), s(t, "frame"))
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.02), p.y, p.z + d * 0.5 + 0.004), Vector3(0.05, h, 0.012), s(t, "accent"))
		2:
			_u(k, x, p, Vector3(w, h, d), s(t, "shell"))
			_u(k, x, p + Vector3(0, h, 0), Vector3(w + 0.02, 0.02, d + 0.02), s(t, "shell2"))
			_b(k, x, Vector3(p.x, p.y + h * 0.5, p.z + d * 0.5 + 0.003), Vector3(w - 0.04, 0.03, 0.006), s(t, "accent"))
			_u(k, x, p, Vector3(w - 0.03, 0.03, d + 0.004), s(t, "dark"))
		3:
			_u(k, x, p, Vector3(w, h, d), s(t, "base"))
			_u(k, x, p + Vector3(0, h, 0), Vector3(w + 0.03, 0.03, d + 0.03), s(t, "frame"))
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * w * 0.5, p.y, p.z + d * 0.5), Vector3(0.03, h, 0.03), s(t, "frame"))
		4:
			_u(k, x, p, Vector3(w, h, d), s(t, "shell"))
			_u(k, x, p + Vector3(0, h, 0), Vector3(w + 0.02, 0.02, d + 0.02), s(t, "frame"))
			_b(k, x, Vector3(p.x, p.y + 0.04, p.z + d * 0.5 + 0.003), Vector3(w - 0.06, 0.012, 0.006), lit(s(t, "glow"), 0.35))
	_u(k, x, p + Vector3(0, h - 0.03, 0), Vector3(w - 0.04, 0.03, d - 0.04), Pal.SOIL)


## A bush of n leaf balls sitting on p.
static func _bush(k: MeshKit, x: Transform3D, p: Vector3, r: float, t: int, n: int) -> void:
	k.sphere(r, Pal.LEAF_DARK, x * MeshKit.at(p.x, p.y + r * 0.7, p.z), 8, 5)
	if n >= 2:
		k.sphere(r * 0.7, Pal.LEAF, x * MeshKit.at(p.x + r * 0.5, p.y + r * 1.1, p.z + r * 0.3), 7, 4)
	if n >= 3:
		k.sphere(r * 0.6, Pal.LEAF, x * MeshKit.at(p.x - r * 0.55, p.y + r * 0.9, p.z + r * 0.2), 7, 4)
	if t == 0 and n >= 2:
		# a garden stake
		_u(k, x, p + Vector3(r * 0.3, 0, -r * 0.4), Vector3(0.015, r * 2.2, 0.015), Pal.WOOD_LIGHT)


## Lights: a little light; a taller post; a street lamp; a double-headed lamp
## with a banner and a glowing base. A work light on a stake with its cord
## (0), caged lamps on steel posts with yellow guards (1), slim white posts
## with teal bands (2), heavy dark poles with LED floods (3), graphite poles
## with brass rings and a glowing halo (4).
static func _lamp_part(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var h: float = [0.55, 0.95, 1.85, 2.1][g]
	var pc: Color = [s(0, "frame"), s(1, "frame"), s(2, "shell"), s(3, "frame"), s(4, "shell")][t]
	# the foot
	match t:
		0:
			_u(k, x, Vector3(0, 0, 0), Vector3(0.14, 0.04, 0.14), Pal.STONE)
		1:
			_u(k, x, Vector3(0, 0, 0), Vector3(0.18, 0.04, 0.18), s(t, "base"))
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					_b(k, x, Vector3(sx * 0.07, 0.045, sz * 0.07), Vector3(0.02, 0.012, 0.02), s(t, "metal"))
		2:
			_cy(k, x, Vector3.ZERO, 0.11, 0.04, s(t, "base"), 8)
		3:
			_u(k, x, Vector3(0, 0, 0), Vector3(0.22, 0.12, 0.22), s(t, "base"))
			_u(k, x, Vector3(0, 0.12, 0), Vector3(0.12, 0.03, 0.12), s(t, "frame"))
		4:
			_cy(k, x, Vector3.ZERO, 0.13, 0.05, s(t, "shell"), 8)
			_cy(k, x, Vector3(0, 0.05, 0), 0.135, 0.015, s(t, "frame"), 8)
	if g >= 3:
		k.torus(0.2, 0.012, lit(s(t, "glow"), 0.3), x * MeshKit.at(0, 0.02, 0), 12, 3)
	# the post
	var pr := 0.025 + (0.01 if t == 3 else 0.0)
	if t == 0:
		_r(k, x, Vector3(0, h * 0.5, 0), Vector3(0.04, h, 0.04), Vector3(0, 0, 2), pc)
	else:
		_cy(k, x, Vector3(0, 0.04, 0), pr, h - 0.04, pc, 6)
	if t == 1 and g >= 1:
		# a yellow guard round the foot
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.14, 0, 0.0), Vector3(0.03, 0.3, 0.03), s(t, "accent"))
		_u(k, x, Vector3(0, 0.28, 0), Vector3(0.3, 0.03, 0.03), s(t, "accent"))
	if t == 4:
		for f: float in [0.3, 0.6, 0.9]:
			_cy(k, x, Vector3(0, h * f, 0), 0.034, 0.02, s(t, "frame"), 6)
	elif t == 2:
		_cy(k, x, Vector3(0, h * 0.72, 0), 0.03, 0.04, s(t, "accent"), 6)
	# heads
	var heads := 1 if g < 3 else 2
	for i in heads:
		var side := 1.0 if i == 0 else -1.0
		if g <= 1:
			_lamp_head(k, x * MeshKit.at(0, h, 0), t, false)
		else:
			var arm := 0.24
			_seg(k, x, Vector3(0, h - 0.06, 0), Vector3(side * arm, h, 0), 0.03, pc)
			_seg(k, x, Vector3(0, h - 0.25, 0), Vector3(side * arm * 0.6, h - 0.02, 0), 0.02, pc)
			_lamp_head(k, x * MeshKit.at(side * arm, h, 0), t, true)
	if t == 0:
		# the cord down the post to the ground
		_cable(k, x, [Vector3(0.03, h - 0.04, 0.02), Vector3(0.03, 0.1, 0.03), Vector3(0.12, 0.012, 0.16), Vector3(0.3, 0.012, 0.2)], 0, 0.014)
	if g >= 3:
		# a banner (or a hand-painted board) on the post
		var bc: Color = col if t != 0 else s(0, "card")
		_u(k, x, Vector3(0.0, h - 0.62, 0.03), Vector3(0.02, 0.5, 0.02), pc)
		_b(k, x, Vector3(0.0, h - 0.38, 0.13), Vector3(0.012, 0.42, 0.2), bc)
		_b(k, x, Vector3(0.0, h - 0.17, 0.13), Vector3(0.02, 0.02, 0.24), pc)
		_b(k, x, Vector3(0.007, h - 0.38, 0.13), Vector3(0.006, 0.08, 0.1), s(t, "shell") if t != 1 else s(t, "accent"))
	if g >= 1 and t >= 2:
		_b(k, x, Vector3(0, 0.3, pr + 0.002), Vector3(0.04, 0.08, 0.006), lit(s(t, "glow"), 0.4) if g >= 3 else s(t, "accent"))
	if g >= 1:
		# a junction box and a number plate on the post
		var jc: Color = [s(0, "card"), s(1, "shell2"), s(2, "shell2"), s(3, "shell"), s(4, "shell2")][t]
		_b(k, x, Vector3(0, 0.2, pr + 0.025), Vector3(0.07, 0.1, 0.04), jc)
		_b(k, x, Vector3(0, 0.22, pr + 0.046), Vector3(0.04, 0.025, 0.004), Color(0.97, 0.97, 0.95) if t != 4 else s(4, "frame"))
		if t == 0:
			# a bucket of sand holding the stake steady
			_cy(k, x, Vector3(0.12, 0, 0.06), 0.06, 0.12, Color(0.64, 0.66, 0.68), 6, 0.07)
			_cy(k, x, Vector3(0.12, 0.09, 0.06), 0.065, 0.02, Color(0.88, 0.8, 0.6), 6)


## One lamp head at the origin of hx (hanging down when `arm`).
static func _lamp_head(k: MeshKit, hx: Transform3D, t: int, arm: bool) -> void:
	var gl := lit(s(t, "glow") if t != 2 else Color(0.92, 0.98, 1.0), 0.3)
	match t:
		0:
			# a tin shade and a bare bulb
			k.cone(0.08, 0.06, s(0, "metal"), hx * MeshKit.xf(Vector3(0, -0.02 if arm else 0.08, 0), Vector3(180, 0, 0)), 6)
			k.sphere(0.035, gl, hx * MeshKit.at(0, -0.04 if arm else 0.03, 0), 6, 4)
		1:
			# a caged work lamp
			k.box(Vector3(0.1, 0.08, 0.1), s(1, "frame"), hx * MeshKit.at(0, 0.0 if arm else 0.04, 0))
			k.box(Vector3(0.08, 0.04, 0.08), gl, hx * MeshKit.at(0, -0.05 if arm else 0.1, 0))
			for i in 2:
				k.box(Vector3(0.1, 0.008, 0.008), s(1, "accent"), hx * MeshKit.at(0, -0.05 if arm else 0.1, -0.025 + i * 0.05))
		2:
			k.box(Vector3(0.18 if arm else 0.08, 0.035, 0.1 if arm else 0.08), s(2, "shell"), hx * MeshKit.at(0, 0.0, 0))
			k.box(Vector3(0.14 if arm else 0.06, 0.008, 0.07 if arm else 0.06), gl, hx * MeshKit.at(0, -0.02, 0))
			k.box(Vector3(0.18 if arm else 0.08, 0.008, 0.012), s(2, "accent"), hx * MeshKit.at(0, 0.02, 0.05 if arm else 0.04))
		3:
			# an LED flood panel
			var fx := hx * MeshKit.xf(Vector3(0, 0.0 if arm else 0.06, 0.02), Vector3(-35, 0, 0))
			k.box(Vector3(0.18, 0.04, 0.14), s(3, "shell2"), fx)
			k.box(Vector3(0.15, 0.008, 0.11), gl, fx * MeshKit.at(0, -0.022, 0))
			for i in 3:
				k.box(Vector3(0.18, 0.02, 0.006), s(3, "frame"), fx * MeshKit.at(0, 0.03, -0.05 + i * 0.05))
		4:
			# a glowing halo ring
			k.torus(0.09, 0.015, s(4, "frame"), hx * MeshKit.at(0, 0.0 if arm else 0.06, 0), 12, 3)
			k.torus(0.075, 0.01, gl, hx * MeshKit.at(0, -0.012 if arm else 0.048, 0), 12, 3)
			k.box(Vector3(0.02, 0.02, 0.17), s(4, "frame"), hx * MeshKit.at(0, 0.0 if arm else 0.06, 0))


## A robot helper: a little rover; a robot dog; a humanoid helper; the
## helper on a glowing charging dock with a tablet. Cardboard and tape with
## bottle-cap eyes (0), yellow industrial (1), white with a teal visor (2),
## dark armour with a blue visor (3), graphite with brass joints (4).
static func _robot(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var bc: Color = [s(0, "card"), s(1, "accent"), s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
	var jc: Color = [s(0, "tape"), s(1, "dark"), s(2, "shell2"), s(3, "frame"), s(4, "frame")][t]
	var eye := lit(s(t, "glow") if t != 2 else s(2, "glow"), 0.35)
	match g:
		0:
			# a rover: a box on four wheels with a sensor mast
			_u(k, x, Vector3(0, 0.07, 0), Vector3(0.3, 0.14, 0.38), bc)
			_u(k, x, Vector3(0, 0.21, -0.04), Vector3(0.24, 0.02, 0.26), jc)
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					k.cyl(0.06, 0.04, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(sx * 0.17, 0.06, sz * 0.13), Vector3(0, 0, 90)), 8)
			_u(k, x, Vector3(0.0, 0.21, 0.12), Vector3(0.02, 0.14, 0.02), jc)
			_u(k, x, Vector3(0.0, 0.35, 0.12), Vector3(0.12, 0.06, 0.06), bc)
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(sx * 0.03, 0.38, 0.152), Vector3(0.03, 0.025, 0.008), eye if t != 0 else Color(0.86, 0.3, 0.24))
			_b(k, x, Vector3(0, 0.14, 0.192), Vector3(0.2, 0.03, 0.006), s(t, "accent2") if t != 1 else s(t, "dark"))
			if t == 0:
				_r(k, x, Vector3(0.08, 0.2, 0.0), Vector3(0.16, 0.035, 0.4), Vector3(0, 0, 0), s(0, "tape"))
		1:
			# a robot dog
			_u(k, x, Vector3(0, 0.3, -0.02), Vector3(0.22, 0.14, 0.44), bc)
			_u(k, x, Vector3(0, 0.44, -0.04), Vector3(0.16, 0.03, 0.3), jc)
			_b(k, x, Vector3(0, 0.42, 0.25), Vector3(0.16, 0.12, 0.14), jc if t != 0 else bc)
			_b(k, x, Vector3(0, 0.43, 0.325), Vector3(0.12, 0.04, 0.01), eye)
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					var hip := Vector3(sx * 0.12, 0.32, sz * 0.17 - 0.02)
					var knee := Vector3(sx * 0.13, 0.17, sz * 0.17 + 0.04)
					_seg(k, x, hip, knee, 0.045, jc)
					_seg(k, x, knee, Vector3(sx * 0.13, 0.02, sz * 0.17 - 0.0), 0.035, bc if t != 4 else s(t, "shell2"))
					_b(k, x, knee, Vector3(0.05, 0.05, 0.05), s(t, "frame") if t != 0 else s(0, "tape"))
					_u(k, x, Vector3(sx * 0.13, 0, sz * 0.17), Vector3(0.05, 0.025, 0.06), Color(0.15, 0.15, 0.16))
			if t >= 3:
				_b(k, x, Vector3(0, 0.38, 0.2), Vector3(0.2, 0.012, 0.01), eye)
		_:
			if g == 3:
				# the charging dock
				_cy(k, x, Vector3.ZERO, 0.3, 0.04, s(t, "base") if t != 0 else s(0, "frame"), 10)
				k.torus(0.27, 0.012, lit(s(t, "glow"), 0.3), x * MeshKit.at(0, 0.045, 0), 14, 3)
				_shell(k, x, Vector3(0, 0, -0.3), Vector3(0.34, 0.9, 0.08), t)
				_b(k, x, Vector3(0, 0.62, -0.255), Vector3(0.22, 0.14, 0.008), lit(s(t, "accent2") if t >= 2 else s(t, "glow"), 0.4))
				_cable(k, x, [Vector3(0.12, 0.5, -0.25), Vector3(0.16, 0.6, -0.12)], t, 0.018)
			var y0 := 0.04 if g == 3 else 0.0
			# legs and feet
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.08, y0, 0.02), Vector3(0.09, 0.04, 0.14), Color(0.15, 0.15, 0.16) if t != 4 else s(t, "frame"))
				_u(k, x, Vector3(sx * 0.08, y0 + 0.04, 0), Vector3(0.07, 0.2, 0.08), jc)
				_u(k, x, Vector3(sx * 0.08, y0 + 0.24, 0), Vector3(0.09, 0.2, 0.1), bc)
				_b(k, x, Vector3(sx * 0.08, y0 + 0.24, 0.0), Vector3(0.08, 0.05, 0.09), s(t, "frame") if t != 0 else s(0, "tape"))
			# torso, chest panel, head
			_u(k, x, Vector3(0, y0 + 0.44, 0), Vector3(0.22, 0.06, 0.14), jc)
			_u(k, x, Vector3(0, y0 + 0.5, 0), Vector3(0.3, 0.3, 0.18), bc)
			_b(k, x, Vector3(0, y0 + 0.66, 0.092), Vector3(0.16, 0.1, 0.008), s(t, "dark"))
			_b(k, x, Vector3(-0.04, y0 + 0.67, 0.097), Vector3(0.04, 0.03, 0.004), eye)
			_b(k, x, Vector3(0.03, y0 + 0.65, 0.097), Vector3(0.05, 0.012, 0.004), col)
			if t == 1:
				_hazard(k, x, Vector3(0, y0 + 0.54, 0.09), 0.3, 0.03)
			_u(k, x, Vector3(0, y0 + 0.8, 0), Vector3(0.06, 0.04, 0.06), jc)
			_u(k, x, Vector3(0, y0 + 0.84, 0), Vector3(0.22, 0.17, 0.18), bc)
			_b(k, x, Vector3(0, y0 + 0.93, 0.092), Vector3(0.17, 0.05, 0.008), eye if (g >= 3 or t >= 2) else s(t, "dark"))
			if t == 0:
				for sx: float in [-1.0, 1.0]:
					_cz(k, x, Vector3(sx * 0.05, y0 + 0.93, 0.09), 0.025, 0.012, Color(0.86, 0.3, 0.24) if sx > 0 else Color(0.3, 0.5, 0.86), 6)
				_u(k, x, Vector3(0.0, y0 + 1.01, 0), Vector3(0.01, 0.1, 0.01), Color(0.4, 0.42, 0.44))
				_b(k, x, Vector3(0.0, y0 + 1.12, 0), Vector3(0.03, 0.03, 0.03), Color(0.86, 0.3, 0.24))
			elif t == 4:
				_u(k, x, Vector3(0, y0 + 1.01, 0), Vector3(0.23, 0.012, 0.19), s(t, "frame"))
			else:
				for sx: float in [-1.0, 1.0]:
					_b(k, x, Vector3(sx * 0.12, y0 + 0.92, 0), Vector3(0.03, 0.07, 0.07), jc)
			# arms
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(sx * 0.18, y0 + 0.76, 0), Vector3(0.07, 0.07, 0.08), jc)
				_seg(k, x, Vector3(sx * 0.19, y0 + 0.74, 0), Vector3(sx * 0.21, y0 + 0.55, 0.06), 0.06, bc)
				_seg(k, x, Vector3(sx * 0.21, y0 + 0.55, 0.06), Vector3(sx * 0.2, y0 + 0.5, 0.18), 0.05, jc)
			if g == 3:
				# holding a tablet
				_r(k, x, Vector3(0, y0 + 0.52, 0.2), Vector3(0.22, 0.14, 0.015), Vector3(-30, 0, 0), s(t, "dark"))
				_r(k, x, Vector3(0, y0 + 0.524, 0.207), Vector3(0.18, 0.1, 0.004), Vector3(-30, 0, 0), lit(s(t, "glow"), 0.4))


## Gas cylinders: one chained to a post; two on a hand cart; a rack of three
## with a regulator; a caged bay of four with a manifold, a glowing gauge
## and a hazard sign. Propane bottles tied to a wooden post (0), a steel
## rack with yellow paint (1), a white cage (2), a dark cage (3), a brass
## frame with glowing bands (4).
static func _tanks(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var tc: Color = col.lerp(Color(0.9, 0.9, 0.9), 0.3)
	if t == 0:
		tc = Color(0.92, 0.9, 0.86)
	elif t == 4:
		tc = s(t, "shell2")
	var fc: Color = [s(0, "frame"), s(1, "accent"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
	match g:
		0:
			_u(k, x, Vector3(0, 0, -0.16), Vector3(0.05, 0.95, 0.05), fc if t != 2 else s(t, "frame"))
			_bottle(k, x, Vector3(0, 0, -0.04), 0.1, 0.7, tc, t)
			_u(k, x, Vector3(0, 0.5, -0.04), Vector3(0.22, 0.02, 0.22), s(t, "dark") if t != 0 else Color(0.86, 0.8, 0.6))
		1:
			# a two-bottle hand cart
			var lx := x * MeshKit.xf(Vector3(0, 0.06, -0.02), Vector3(-10, 0, 0))
			for sx: float in [-1.0, 1.0]:
				k.box(Vector3(0.03, 0.95, 0.03), fc, lx * MeshKit.at(sx * 0.24, 0.47, -0.12))
				k.cyl(0.07, 0.04, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(sx * 0.27, 0.07, -0.08), Vector3(0, 0, 90)), 8)
			k.box(Vector3(0.52, 0.03, 0.03), fc, lx * MeshKit.at(0, 0.92, -0.12))
			k.box(Vector3(0.5, 0.025, 0.24), fc, lx * MeshKit.at(0, 0.0, 0.0))
			for sx: float in [-1.0, 1.0]:
				_bottle(k, lx, Vector3(sx * 0.12, 0.012, 0.0), 0.1, 0.72, tc if sx < 0 else tc.darkened(0.1), t)
			k.box(Vector3(0.5, 0.02, 0.02), s(t, "dark"), lx * MeshKit.at(0, 0.5, 0.11))
		_:
			var n := 3 if g == 2 else 4
			var w := 0.7
			# the rack: a back frame, a top rail, chains across
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * w * 0.5, 0, -0.2), Vector3(0.04, 1.05, 0.04), fc)
				if g == 3:
					_u(k, x, Vector3(sx * w * 0.5, 0, 0.3), Vector3(0.04, 1.05, 0.04), fc)
					_u(k, x, Vector3(sx * w * 0.5, 1.03, 0.05), Vector3(0.04, 0.04, 0.54), fc)
			_u(k, x, Vector3(0, 1.0, -0.2), Vector3(w, 0.04, 0.04), fc)
			_u(k, x, Vector3(0, 0, -0.2), Vector3(w, 0.04, 0.04), fc)
			_u(k, x, Vector3(0, 0, 0.04), Vector3(w, 0.03, 0.5), s(t, "base"))
			for i in n:
				var bx := -w * 0.5 + (i + 0.5) * w / n
				_bottle(k, x, Vector3(bx, 0.03, -0.06), 0.075 if n == 4 else 0.09, 0.82, tc.darkened(0.08 * (i % 2)), t)
			for cy: float in [0.35, 0.7]:
				_u(k, x, Vector3(0, cy, 0.04), Vector3(w, 0.015, 0.015), s(t, "metal") if t != 0 else Color(0.86, 0.8, 0.6))
			# regulator and the manifold
			_u(k, x, Vector3(0, 0.95, -0.12), Vector3(w - 0.1, 0.03, 0.03), s(t, "metal") if t != 4 else s(t, "frame"))
			_cz(k, x, Vector3(w * 0.32, 0.88, -0.12), 0.045, 0.03, Color(0.95, 0.95, 0.9) if g < 3 else lit(s(t, "glow"), 0.45), 8)
			_run(k, x, [Vector3(w * 0.4, 0.95, -0.12), Vector3(w * 0.48, 0.95, -0.12), Vector3(w * 0.48, 0.02, -0.2)], 0.025, s(t, "metal") if t < 4 else lit(s(t, "accent2"), 0.5))
			if g == 3:
				# mesh sides, a little roof, a sign
				for sx: float in [-1.0, 1.0]:
					_b(k, x, Vector3(sx * w * 0.5, 0.52, 0.05), Vector3(0.006, 0.95, 0.5), Color(0.5, 0.52, 0.55) if t < 3 else s(t, "frame").lightened(0.1))
				for i in 5:
					_r(k, x, Vector3(0, 1.1 - i * 0.012, -0.2 + i * 0.125), Vector3(w + 0.08, 0.02, 0.07), Vector3(-6, 0, 0), s(t, "shell") if t != 0 else s(0, "metal"))
				_sign(k, x, Vector3(-w * 0.3, 1.0, 0.32), 0.14, t)
				if t >= 3:
					_b(k, x, Vector3(0, 1.07, 0.35), Vector3(w - 0.04, 0.012, 0.01), lit(s(t, "glow"), 0.4))


## One gas bottle standing on p: body, shoulder, valve and cap.
static func _bottle(k: MeshKit, x: Transform3D, p: Vector3, r: float, h: float, c: Color, t: int) -> void:
	_cy(k, x, p, r, h - r, c, 8)
	k.sphere(r, c, x * MeshKit.xf(p + Vector3(0, h - r, 0), Vector3.ZERO, Vector3(1, 0.8, 1)), 8, 4)
	_cy(k, x, p + Vector3(0, h - 0.03, 0), 0.025, 0.08, Color(0.6, 0.5, 0.3) if t < 4 else s(t, "frame"), 6)
	_b(k, x, p + Vector3(0, h + 0.03, 0), Vector3(0.06, 0.02, 0.02), Color(0.2, 0.2, 0.22))
	_cy(k, x, p + Vector3(0, h * 0.68, 0), r * 1.03, 0.04, c.darkened(0.25) if t != 4 else lit(s(t, "glow"), 0.4), 8)
	if t == 0:
		_cy(k, x, p + Vector3(0, h - r * 0.5, 0), r * 1.02, 0.03, Color(0.78, 0.3, 0.24), 8)


## Drums: one drum; two with a funnel; four on a spill pallet; the pallet
## with one stacked, a drum pump, a glowing label and a hazard sign. Rusty
## drums with a rag (0), blue steel drums (1), white drums with teal lids
## (2), dark drums with hazard bands (3), graphite canisters with brass (4).
static func _drums(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	match g:
		0:
			_drum(k, x, Vector3(0, 0, 0), t, col, 0)
		1:
			_drum(k, x, Vector3(-0.16, 0, -0.12), t, col, 0)
			_drum(k, x, Vector3(0.18, 0, 0.1), t, col, 1)
			_cy(k, x, Vector3(0.18, 0.54, 0.1), 0.02, 0.06, s(t, "dark"))
			k.cone(0.09, 0.12, s(t, "accent") if t != 0 else Color(0.3, 0.32, 0.36), x * MeshKit.xf(Vector3(0.18, 0.72, 0.1), Vector3(180, 0, 0)), 8)
		_:
			# a spill pallet with a grated deck
			var pc: Color = [Color(0.2, 0.46, 0.3), s(1, "accent"), s(2, "accent"), s(3, "accent"), s(4, "frame")][t]
			if t == 0:
				_skid(k, x, Vector3(0, 0, 0), 0.74, 0.72, 0)
			else:
				_u(k, x, Vector3(0, 0, 0), Vector3(0.74, 0.1, 0.72), pc)
				for i in 6:
					_b(k, x, Vector3(-0.31 + i * 0.124, 0.105, 0), Vector3(0.02, 0.012, 0.68), s(t, "dark"))
			var y := 0.1 if t != 0 else 0.085
			for i in 4:
				_drum(k, x, Vector3(-0.18 + (i % 2) * 0.36, y, -0.18 + (i / 2) * 0.36), t, col, i)
			if g == 3:
				_drum(k, x, Vector3(-0.18, y + 0.56, -0.18), t, col, 2)
				# a drum pump with a hose
				_cy(k, x, Vector3(0.18, y + 0.53, 0.18), 0.02, 0.38, s(t, "metal"), 6)
				_u(k, x, Vector3(0.18, y + 0.86, 0.18), Vector3(0.1, 0.06, 0.06), s(t, "accent2"))
				_run(k, x, [Vector3(0.22, y + 0.86, 0.18), Vector3(0.3, y + 0.75, 0.24), Vector3(0.33, y + 0.4, 0.3)], 0.018, s(t, "dark"))
				_sign(k, x, Vector3(0.18, y + 0.3, 0.34), 0.12, t)
				_b(k, x, Vector3(-0.18, y + 0.32, 0.34), Vector3(0.12, 0.06, 0.006), lit(s(t, "glow"), 0.35))
				if t == 0:
					_r(k, x, Vector3(0.1, y + 0.57, -0.15), Vector3(0.16, 0.02, 0.12), Vector3(0, 30, 8), Color(0.86, 0.3, 0.24))


## One drum standing on p (i varies the shade).
static func _drum(k: MeshKit, x: Transform3D, p: Vector3, t: int, col: Color, i: int) -> void:
	var c: Color = [col.darkened(0.15), Color(0.26, 0.42, 0.7), s(2, "shell"), s(3, "shell"), s(4, "shell2")][t]
	if t == 1 and i % 2 == 1:
		c = col
	c = c.darkened(0.06 * (i % 2))
	var r := 0.15
	var h := 0.52
	_cy(k, x, p, r, h, c, 8)
	var rib: Color = c.darkened(0.25) if t != 4 else s(4, "frame")
	for f: float in [0.33, 0.66]:
		k.cyl(r * 1.04, 0.025, rib, x * MeshKit.at(p.x, p.y + h * f, p.z), 8, 0.0, -1.0, false)
	var lid: Color = [c.darkened(0.2), c.darkened(0.2), s(2, "accent"), s(3, "accent"), s(4, "frame")][t]
	_cy(k, x, p + Vector3(0, h, 0), r * 0.92, 0.012, lid, 8)
	_cy(k, x, p + Vector3(0.07, h, 0.03), 0.025, 0.025, s(t, "dark"), 6)
	if t == 0:
		# rust and a label scrap
		_b(k, x, p + Vector3(-0.06, h * 0.4, r * 0.95), Vector3(0.08, 0.1, 0.01), Color(0.6, 0.36, 0.22))
		_b(k, x, p + Vector3(0.02, h * 0.55, r * 0.97), Vector3(0.1, 0.07, 0.006), Color(0.96, 0.94, 0.88))
	elif t == 3:
		_cy(k, x, p + Vector3(0, h * 0.82, 0), r * 1.02, 0.05, s(3, "accent"), 8)
	elif t == 4:
		_b(k, x, p + Vector3(0, h * 0.5, r * 0.97), Vector3(0.02, h * 0.6, 0.008), lit(s(4, "glow"), 0.35))
	else:
		_b(k, x, p + Vector3(0, h * 0.5, r * 0.97), Vector3(0.1, 0.09, 0.008), Color(0.96, 0.8, 0.26) if t == 1 else col)


## Cable reels: one reel chocked on the ground; a bigger one on a stand with
## cable pulled off; two on stands with a coil on the ground; a pyramid of
## three in a frame with a glowing fibre run and a sign. Wooden reels of
## extension cord (0), wooden reels on a yellow stand (1), white plastic
## reels with teal cable (2), steel reels (3), brass reels with glowing fibre (4).
static func _reels(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var cc: Array = [[s(0, "cable"), Color(0.3, 0.5, 0.86), Color(0.24, 0.24, 0.26)], [Color(0.14, 0.14, 0.16), Color(0.96, 0.6, 0.3), Color(0.3, 0.5, 0.86)],
		[s(2, "accent"), Color(0.96, 0.6, 0.3), Color(0.3, 0.5, 0.86)], [Color(0.1, 0.1, 0.12), s(3, "accent"), Color(0.3, 0.5, 0.86)], [lit(s(4, "accent2"), 0.45), s(4, "frame"), lit(s(4, "glow"), 0.4)]][t]
	match g:
		0:
			_reel(k, x * MeshKit.at(0, 0.28, 0), 0.28, 0.22, t, cc[0])
			for sx: float in [-1.0, 1.0]:
				_r(k, x, Vector3(sx * 0.2, 0.03, 0), Vector3(0.1, 0.06, 0.2), Vector3(0, 0, sx * -20.0), s(t, "frame") if t != 0 else Pal.BRICK)
			_cable(k, x, [Vector3(0.12, 0.08, 0.1), Vector3(0.22, 0.012, 0.22), Vector3(0.0, 0.012, 0.3)], t, 0.026)
		1:
			_reel_stand(k, x, Vector3(0, 0, -0.04), 0.4, t)
			_reel(k, x * MeshKit.at(0, 0.4, -0.04), 0.34, 0.26, t, cc[0])
			_cable(k, x, [Vector3(0.0, 0.07, 0.06), Vector3(0.06, 0.012, 0.18), Vector3(0.3, 0.012, 0.28), Vector3(0.34, 0.012, 0.36)], t, 0.03)
			if t == 0:
				_u(k, x, Vector3(0.3, 0, 0.3), Vector3(0.1, 0.06, 0.05), Color(0.95, 0.95, 0.92))
		_:
			_u(k, x, Vector3(0, 0, 0), Vector3(0.74, 0.04, 0.6), s(t, "base"))
			var r := 0.17
			var cs := [Vector3(-0.18, 0.04 + r + 0.04, 0.0), Vector3(0.18, 0.04 + r + 0.04, 0.0), Vector3(0.0, 0.04 + r * 3.0 + 0.1, -0.06)]
			var n := 2 if g == 2 else 3
			var fc: Color = [s(0, "frame"), s(1, "accent"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
			for i in n:
				var c: Vector3 = cs[i]
				if i < 2:
					_reel_stand(k, x, Vector3(c.x, 0.04, c.z), c.y - 0.04, t, 0.14)
				_reel(k, x * MeshKit.at(c.x, c.y, c.z), r, 0.22, t, cc[i % 3])
			if g == 3:
				# a frame carrying the top reel
				for sx: float in [-1.0, 1.0]:
					_u(k, x, Vector3(sx * 0.35, 0.04, -0.06), Vector3(0.04, 0.66, 0.04), fc)
				_cx(k, x, Vector3(-0.35, 0.04 + r * 3.0 + 0.1, -0.06), 0.02, 0.7, s(t, "metal"), 6)
				_sign(k, x * MeshKit.xf(Vector3(0.37, 0.35, 0.05), Vector3(0, 90, 0)), Vector3.ZERO, 0.14, t)
			# a coil of cable on the ground
			k.torus(0.1, 0.022, cc[1], x * MeshKit.at(0.2, 0.06, 0.24), 10, 4)
			k.torus(0.07, 0.02, cc[1], x * MeshKit.at(0.2, 0.09, 0.24), 10, 4)
			_cable(k, x, [Vector3(-0.18, 0.11, 0.1), Vector3(-0.2, 0.05, 0.24), Vector3(0.08, 0.05, 0.26)], t, 0.026)
			if t >= 3:
				_b(k, x, Vector3(0, 0.03, 0.302), Vector3(0.7, 0.012, 0.006), lit(s(t, "glow"), 0.35))


## One reel centred on rx with its axle along z: flanges facing front and
## back, the cable wound round the drum, a stencil and bolts on the flange.
static func _reel(k: MeshKit, rx: Transform3D, r: float, w: float, t: int, cable: Color) -> void:
	var fc: Color = [Pal.WOOD_LIGHT, Pal.WOOD, s(2, "shell"), s(3, "metal"), s(4, "frame")][t]
	for sz: float in [-1.0, 1.0]:
		var fz := sz * (w * 0.5 - 0.015)
		k.cyl(r, 0.03, fc, rx * MeshKit.xf(Vector3(0, 0, fz - 0.015), Vector3(90, 0, 0)), 10)
		k.cyl(r * 0.25, 0.034, fc.darkened(0.25), rx * MeshKit.xf(Vector3(0, 0, fz - 0.017), Vector3(90, 0, 0)), 6)
		if sz > 0.0:
			if t <= 1:
				# planks on the wooden flange
				for i in 2:
					k.box(Vector3(0.012, r * 1.8, 0.006), fc.darkened(0.2), rx * MeshKit.at(-r * 0.35 + i * r * 0.7, 0, fz + 0.016))
			k.box(Vector3(r * 0.7, r * 0.22, 0.006), Color(0.96, 0.95, 0.9) if t < 3 else (s(3, "accent") if t == 3 else lit(s(4, "glow"), 0.4)), rx * MeshKit.at(0, -r * 0.55, fz + 0.017))
			k.box(Vector3(r * 0.5, r * 0.1, 0.004), Color(0.14, 0.14, 0.15), rx * MeshKit.at(0, -r * 0.55, fz + 0.021))
	k.cyl(r * 0.8, w - 0.06, cable, rx * MeshKit.xf(Vector3(0, 0, -w * 0.5 + 0.03), Vector3(90, 0, 0)), 10)


## An A-frame stand for a reel (axle along z at height h, standing on p).
static func _reel_stand(k: MeshKit, x: Transform3D, p: Vector3, h: float, t: int, d := 0.16) -> void:
	var fc: Color = [s(0, "frame"), s(1, "accent"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
	for sz: float in [-1.0, 1.0]:
		var z := p.z + sz * d
		_seg(k, x, Vector3(p.x - 0.14, p.y, z), Vector3(p.x, p.y + h, z), 0.03, fc)
		_seg(k, x, Vector3(p.x + 0.14, p.y, z), Vector3(p.x, p.y + h, z), 0.03, fc)
		_u(k, x, Vector3(p.x, p.y, z), Vector3(0.34, 0.025, 0.04), fc)
	_cz(k, x, Vector3(p.x, p.y + h, p.z - d - 0.02), 0.018, d * 2.0 + 0.04, s(t, "metal"), 6)


## Info screens: a board on a post; a screen totem; a taller totem with a
## glowing screen and a hood; a double pylon with a ticker, a halo and a
## planter base. A chalkboard easel (0), a noticeboard on steel posts (1),
## a white totem (2), a dark totem with blue trim (3), a graphite monolith
## with brass and a hologram ring (4).
static func _kiosk(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var scr := Color(0.12, 0.13, 0.16)
	var on := lit(Color(0.5, 0.86, 1.0) if t != 4 else s(4, "accent2"), 0.45)
	if g == 0:
		match t:
			0:
				# a chalkboard A-frame
				for sz: float in [-1.0, 1.0]:
					var fx := x * MeshKit.xf(Vector3(0, 0.36, sz * 0.1), Vector3(-sz * 14.0, 0, 0))
					k.box(Vector3(0.44, 0.7, 0.025), s(0, "frame"), fx)
					k.box(Vector3(0.38, 0.6, 0.01), Color(0.18, 0.22, 0.2), fx * MeshKit.at(0, 0.02, sz * 0.014))
					for i in 3:
						k.box(Vector3(0.24 - i * 0.05, 0.014, 0.004), Color(0.94, 0.94, 0.9), fx * MeshKit.at(-0.02, 0.18 - i * 0.1, sz * 0.02))
					k.box(Vector3(0.08, 0.06, 0.004), col, fx * MeshKit.at(0.1, -0.12, sz * 0.02))
			_:
				var pc: Color = s(t, "frame") if t != 2 else s(t, "shell")
				for sx: float in [-1.0, 1.0]:
					_u(k, x, Vector3(sx * 0.2, 0, 0), Vector3(0.04, 0.9, 0.04), pc if t != 1 else s(t, "metal"))
				_shell(k, x, Vector3(0, 0.42, 0), Vector3(0.46, 0.4, 0.05), t)
				_b(k, x, Vector3(0, 0.62, 0.03), Vector3(0.38, 0.3, 0.008), Color(0.96, 0.95, 0.9) if t < 3 else scr)
				for i in 3:
					_b(k, x, Vector3(-0.1 + i * 0.1, 0.66 - (i % 2) * 0.08, 0.036), Vector3(0.08, 0.1, 0.004), [col, s(t, "accent"), Color(0.96, 0.8, 0.3)][i] if t < 3 else lit(s(t, "glow"), 0.45))
		return
	var h: float = [0.0, 1.1, 1.4, 1.5][g]
	var w := 0.42
	var d := 0.16
	# base
	if g == 3:
		_planter_box(k, x, Vector3(0, 0, 0), 0.72, 0.4, 0.2, t)
		_bush(k, x, Vector3(-0.26, 0.17, 0.06), 0.08, t, 1)
		_bush(k, x, Vector3(0.26, 0.17, 0.06), 0.08, t, 1)
	var y0 := 0.2 if g == 3 else 0.0
	if g < 3:
		_u(k, x, Vector3(0, 0, 0), Vector3(w + 0.08, 0.05, d + 0.1), s(t, "base") if t != 0 else Pal.STONE)
		y0 = 0.05
	_shell(k, x, Vector3(0, y0, 0), Vector3(w, h, d), t)
	var fz := d * 0.5
	# a header with the logo, a card reader and a speaker under the screen
	_b(k, x, Vector3(0, y0 + h - 0.07, fz + 0.006), Vector3(w - 0.06, 0.07, 0.01), s(t, "accent") if t != 1 else s(1, "dark"))
	_b(k, x, Vector3(-w * 0.32, y0 + h - 0.07, fz + 0.013), Vector3(0.05, 0.05, 0.004), col)
	_b(k, x, Vector3(0.04, y0 + h - 0.07, fz + 0.013), Vector3(w * 0.4, 0.02, 0.004), Color(0.97, 0.97, 0.96) if t != 2 else s(2, "shell"))
	_b(k, x, Vector3(w * 0.25, y0 + h * 0.3, fz + 0.012), Vector3(0.09, 0.07, 0.024), s(t, "dark"))
	_b(k, x, Vector3(w * 0.25, y0 + h * 0.3 + 0.012, fz + 0.025), Vector3(0.06, 0.012, 0.004), lit(Color(0.5, 1.0, 0.6), 0.4))
	for i in 3:
		_b(k, x, Vector3(-w * 0.22, y0 + h * 0.27 + i * 0.022, fz + 0.008), Vector3(0.1, 0.008, 0.006), s(t, "dark"))
	if t >= 2:
		for sx: float in [-1.0, 1.0]:
			_b(k, x, Vector3(sx * (w * 0.5 + 0.004), y0 + h * 0.55, 0), Vector3(0.008, h * 0.7, 0.03), lit(s(t, "glow"), 0.35) if g >= 2 else s(t, "accent"))
	elif t == 0:
		_r(k, x, Vector3(-w * 0.38, y0 + h * 0.86, fz + 0.016), Vector3(0.1, 0.03, 0.004), Vector3(0, 0, 35), s(0, "tape"))
		_r(k, x, Vector3(w * 0.36, y0 + h * 0.4, fz + 0.016), Vector3(0.1, 0.03, 0.004), Vector3(0, 0, -35), s(0, "tape"))
		_cable(k, x, [Vector3(w * 0.4, y0 + 0.1, -fz), Vector3(w * 0.5, 0.02, -fz - 0.06), Vector3(0.34, 0.012, -0.2)], 0, 0.014)
	else:
		for sy: float in [0.15, 0.85]:
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(sx * (w * 0.5 - 0.025), y0 + h * sy, fz + 0.008), Vector3(0.016, 0.016, 0.008), s(1, "metal"))
	var sh := h * 0.5
	var sy := y0 + h * 0.62
	_b(k, x, Vector3(0, sy, fz + 0.006), Vector3(w - 0.08, sh, 0.012), scr if g == 1 else on)
	if g >= 2:
		# content on the screen: a header bar and a little chart
		_b(k, x, Vector3(0, sy + sh * 0.4, fz + 0.014), Vector3(w - 0.12, 0.03, 0.004), s(t, "accent") if t != 4 else s(4, "frame"))
		for i in 4:
			var bh := 0.05 + float((i * 37) % 4) * 0.035
			_b(k, x, Vector3(-0.1 + i * 0.065, sy - sh * 0.35 + bh * 0.5, fz + 0.014), Vector3(0.04, bh, 0.004), Color(1.0, 0.86, 0.5, 0.4))
		# a hood over the top
		_u(k, x, Vector3(0, y0 + h, 0.02), Vector3(w + 0.08, 0.04, d + 0.08), s(t, "frame") if t != 2 else s(t, "accent"))
	_b(k, x, Vector3(0, y0 + h * 0.2, fz + 0.006), Vector3(w * 0.5, 0.06, 0.008), col)
	if g >= 2:
		# the back face too (it's double-sided)
		_b(k, x, Vector3(0, sy, -fz - 0.006), Vector3(w - 0.08, sh, 0.012), on)
	if g == 3:
		# a ticker strip and a halo
		_b(k, x, Vector3(0, y0 + h * 0.3, fz + 0.01), Vector3(w - 0.04, 0.04, 0.008), lit(s(t, "glow"), 0.35))
		if t >= 3:
			k.torus(0.3, 0.012, lit(s(t, "glow"), 0.3), x * MeshKit.at(0, y0 + h + 0.18, 0.02), 14, 3)
			_u(k, x, Vector3(0, y0 + h + 0.04, 0.02), Vector3(0.02, 0.14, 0.02), s(t, "frame"))
		elif t == 0:
			k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(0.0, y0 + h + 0.12, 0.08), 6, 4)
			_u(k, x, Vector3(0.0, y0 + h, -0.02), Vector3(0.02, 0.16, 0.02), s(0, "frame"))
			_u(k, x, Vector3(0.0, y0 + h + 0.15, 0.03), Vector3(0.02, 0.02, 0.12), s(0, "frame"))
		else:
			_lamp(k, x, Vector3(w * 0.4, y0 + h + 0.06, fz), t, Color(0, 0, 0, 0), 0.04)


## A token pallet: a pallet with a couple of boxes; a full layer; three
## layers shrink-wrapped with a pallet jack; a tall strapped stack with a
## glowing label and a scanner post.
static func _pallet(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var y := _skid(k, x, Vector3(0, 0, -0.06), 0.72, 0.6, t)
	var layers: int = [1, 1, 2, 3][g]
	for ly in layers:
		var full := g >= 1 or ly > 0
		for i in 2:
			for j in 2:
				if not full and (i + j) % 2 == 1:
					continue
				_crate(k, x, Vector3(-0.17 + i * 0.34, y + ly * 0.24, -0.2 + j * 0.28), Vector3(0.32, 0.24, 0.26), float(((i + j + ly) * 37) % 7 - 3), t, col, j == 0)
	if g == 3:
		_crate(k, x, Vector3(0.05, y + layers * 0.24, -0.1), Vector3(0.4, 0.2, 0.34), 7.0, t, col)
	if g == 0:
		_crate(k, x, Vector3(-0.17, y + 0.24, -0.2), Vector3(0.24, 0.16, 0.2), 12.0, t, col)
	if g >= 2:
		# corner boards, wrap bands and the pallet jack
		var top := y + layers * 0.24
		var wc: Color = Color(0.9, 0.92, 0.94) if t != 4 else s(4, "frame")
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.335, y + 0.02, sz * 0.285 - 0.06), Vector3(0.04, top - y - 0.04, 0.04), s(0, "card").lightened(0.1) if t < 3 else wc)
		for f: float in [0.3, 0.7]:
			_u(k, x, Vector3(0, y + (top - y) * f, -0.06), Vector3(0.69, 0.05, 0.58), wc)
		var jc: Color = [Color(0.82, 0.28, 0.22), s(1, "accent"), s(2, "accent"), s(3, "accent"), s(4, "frame")][t]
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.14, 0.0, 0.12), Vector3(0.08, 0.04, 0.3), jc)
		_u(k, x, Vector3(0, 0.0, 0.3), Vector3(0.38, 0.12, 0.06), jc)
		_seg(k, x, Vector3(0, 0.12, 0.3), Vector3(0, 0.62, 0.36), 0.03, jc.darkened(0.2))
		_b(k, x, Vector3(0, 0.62, 0.36), Vector3(0.16, 0.03, 0.03), Color(0.15, 0.15, 0.16))
	if g == 3:
		var top2 := y + layers * 0.24 + 0.2
		for sx: float in [-0.17, 0.17]:
			_u(k, x, Vector3(sx, y, 0.236), Vector3(0.03, top2 - y - 0.2, 0.006), s(t, "dark") if t != 1 else s(t, "accent"))
		_b(k, x, Vector3(0.0, top2 - 0.34, 0.243), Vector3(0.18, 0.12, 0.006), Color(0.97, 0.97, 0.96))
		_b(k, x, Vector3(0.04, top2 - 0.34, 0.247), Vector3(0.06, 0.06, 0.004), lit(s(t, "glow"), 0.3))
		_b(k, x, Vector3(-0.04, top2 - 0.34, 0.247), Vector3(0.05, 0.08, 0.004), Color(0.1, 0.1, 0.12))


## An antenna mast, taller each grade: a short mast with one antenna; with a
## second antenna, a microwave dish and a cable ladder; a head frame of
## panel antennas and a cabinet at the foot; a platform with a railing and a
## glowing beacon. A guyed wooden pole with TV aerials (0), a red and white
## lattice (1), a white monopole with teal bands (2), a heavy dark lattice
## (3), a graphite monopole with brass rings (4).
static func _mast(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var h: float = [1.3, 1.8, 2.4, 2.8][g]
	var mc: Color = [s(0, "frame"), Color(0.86, 0.3, 0.26), s(2, "shell"), s(3, "frame"), s(4, "shell")][t]
	# the base
	match t:
		0:
			_u(k, x, Vector3(0, 0, 0), Vector3(0.2, 0.08, 0.2), Pal.STONE)
			_u(k, x, Vector3(0, 0, 0), Vector3(0.06, h, 0.06), mc)
			# guy ropes to stakes
			for i in 3:
				var a := TAU * (i + 0.25) / 3.0
				var st := Vector3(cos(a) * 0.34, 0, sin(a) * 0.34)
				_seg(k, x, Vector3(0, h * 0.7, 0), st + Vector3(0, 0.05, 0), 0.008, Color(0.9, 0.86, 0.7))
				_u(k, x, st, Vector3(0.025, 0.08, 0.025), s(0, "frame"))
		1, 3:
			_u(k, x, Vector3(0, 0, 0), Vector3(0.36, 0.06, 0.36), s(t, "base"))
			_lattice(k, x, 0.06, h, 0.26, 0.14, mc, Color(0.94, 0.94, 0.92) if t == 1 else mc.lightened(0.15), t == 1)
		2, 4:
			_cy(k, x, Vector3.ZERO, 0.14, 0.06, s(t, "base"), 8)
			_cy(k, x, Vector3(0, 0.06, 0), 0.05, h - 0.06, mc, 8, 0.035)
			for f: float in [0.25, 0.5, 0.75]:
				_cy(k, x, Vector3(0, h * f, 0), 0.05 - 0.015 * f + 0.006, 0.03, s(t, "accent") if t == 2 else s(4, "frame"), 8)
			if t == 4:
				_u(k, x, Vector3(0, 0.1, 0.045), Vector3(0.015, h * 0.6, 0.012), lit(s(4, "glow"), 0.35))
	# antennas
	if t <= 1:
		_yagi(k, x * MeshKit.at(0, h - 0.05, 0), 0.5, t)
		if g >= 1:
			_yagi(k, x * MeshKit.xf(Vector3(0, h - 0.4, 0), Vector3(0, 70, 0)), 0.38, t)
	else:
		var n := 1 if g == 0 else (2 if g == 1 else 3)
		for i in n:
			var a2 := TAU * i / 3.0
			var ax := x * MeshKit.xf(Vector3(sin(a2) * 0.1, h - 0.3, cos(a2) * 0.1), Vector3(0, rad_to_deg(a2), 0))
			k.box(Vector3(0.1, 0.4, 0.04), s(t, "shell") if t != 4 else s(4, "shell2"), ax * MeshKit.at(0, 0, 0.03))
			k.box(Vector3(0.06, 0.02, 0.08), s(t, "metal"), ax * MeshKit.at(0, 0.12, -0.02))
			if t == 4:
				k.box(Vector3(0.012, 0.32, 0.004), lit(s(4, "accent2"), 0.4), ax * MeshKit.at(0, 0, 0.052))
	# the tip
	_cy(k, x, Vector3(0, h, 0), 0.012, 0.3, s(t, "metal"), 4)
	k.sphere(0.04, lit(Color(1.0, 0.3, 0.25), 0.3), x * MeshKit.at(0, h + 0.3, 0), 6, 4)
	if g >= 1:
		# a microwave dish and the cable ladder
		var dx := x * MeshKit.xf(Vector3(0.06, h * 0.62, 0.06), Vector3(90, 30, 0))
		k.cyl(0.12, 0.08, Color(0.94, 0.94, 0.92) if t != 4 else s(4, "frame"), dx, 10, 0.0, 0.1)
		k.cyl(0.1, 0.01, s(t, "dark") if t != 2 else s(2, "shell2"), dx * MeshKit.at(0, 0.081, 0), 10)
		_u(k, x, Vector3(0.0, 0.06, -0.09), Vector3(0.05, h * 0.9, 0.01), s(t, "cable") if t != 4 else s(4, "frame"))
	if g >= 2:
		# the equipment cabinet at the foot
		_shell(k, x, Vector3(0.0, 0, 0.24), Vector3(0.28, 0.42, 0.18), t)
		_door(k, x, Vector3(0.0, 0.22, 0.33), 0.2, 0.32, t)
		_cable(k, x, [Vector3(0, 0.3, 0.15), Vector3(0, 0.3, 0.02), Vector3(0, 0.6, 0.0)], t, 0.02)
	if g >= 3 and t == 0:
		# a hurricane lantern hung off the pole and a flag on top
		_b(k, x, Vector3(0.08, h - 0.3, 0), Vector3(0.14, 0.025, 0.025), s(0, "frame"))
		_seg(k, x, Vector3(0.14, h - 0.3, 0), Vector3(0.14, h - 0.38, 0), 0.008, Color(0.4, 0.42, 0.44))
		_u(k, x, Vector3(0.14, h - 0.5, 0), Vector3(0.06, 0.1, 0.06), Color(0.64, 0.66, 0.68))
		_u(k, x, Vector3(0.14, h - 0.49, 0), Vector3(0.045, 0.08, 0.045), lit(s(0, "glow"), 0.3))
		_r(k, x, Vector3(-0.1, h + 0.22, 0), Vector3(0.18, 0.11, 0.008), Vector3(0, 0, -4), col)
	elif g >= 3:
		# a platform with a railing and a glowing beacon
		var py := h - 0.55
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.16, py, 0), Vector3(0.12, 0.03, 0.44), s(t, "metal") if t != 4 else s(4, "frame"))
			_u(k, x, Vector3(0, py, sx * 0.16), Vector3(0.2, 0.03, 0.12), s(t, "metal") if t != 4 else s(4, "frame"))
		var rc: Color = s(t, "accent") if t == 1 or t == 3 else (s(t, "metal") if t != 4 else s(4, "frame"))
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.21, py + 0.2, 0), Vector3(0.015, 0.015, 0.44), rc)
			_u(k, x, Vector3(0, py + 0.2, sx * 0.21), Vector3(0.44, 0.015, 0.015), rc)
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.21, py, sz * 0.21), Vector3(0.015, 0.2, 0.015), rc)
		_cy(k, x, Vector3(0, h + 0.26, 0), 0.055, 0.08, lit(s(t, "glow") if t >= 2 else Color(1.0, 0.3, 0.25), 0.3), 8)


## A tapering square lattice from y0 to y1 (legs, rings and diagonals).
static func _lattice(k: MeshKit, x: Transform3D, y0: float, y1: float, w0: float, w1: float, leg: Color, bar: Color, bands: bool) -> void:
	var h := y1 - y0
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_seg(k, x, Vector3(sx * w0 * 0.5, y0, sz * w0 * 0.5), Vector3(sx * w1 * 0.5, y1, sz * w1 * 0.5), 0.025, leg)
	var n := maxi(2, int(h / 0.42))
	for i in n + 1:
		var f := float(i) / n
		var y := y0 + h * f
		var w := lerpf(w0, w1, f) * 0.5
		var c: Color = (leg if i % 2 == 0 else bar) if bands else bar
		_b(k, x, Vector3(0, y, w), Vector3(w * 2.0, 0.018, 0.018), c)
		_b(k, x, Vector3(0, y, -w), Vector3(w * 2.0, 0.018, 0.018), c)
		_b(k, x, Vector3(w, y, 0), Vector3(0.018, 0.018, w * 2.0), c)
		_b(k, x, Vector3(-w, y, 0), Vector3(0.018, 0.018, w * 2.0), c)
		if i < n:
			var y2 := y0 + h * float(i + 1) / n
			var w2 := lerpf(w0, w1, float(i + 1) / n) * 0.5
			var sgn := 1.0 if i % 2 == 0 else -1.0
			_seg(k, x, Vector3(-w * sgn, y, w), Vector3(w2 * sgn, y2, w2), 0.012, bar)
			_seg(k, x, Vector3(-w * sgn, y, -w), Vector3(w2 * sgn, y2, -w2), 0.012, bar)
			_seg(k, x, Vector3(w, y, -w * sgn), Vector3(w2, y2, w2 * sgn), 0.012, bar)
			_seg(k, x, Vector3(-w, y, -w * sgn), Vector3(-w2, y2, w2 * sgn), 0.012, bar)


## A TV yagi aerial: a boom along z with elements across.
static func _yagi(k: MeshKit, ax: Transform3D, len: float, t: int) -> void:
	var c := Color(0.82, 0.84, 0.86)
	k.box(Vector3(0.02, 0.02, len), c, ax * MeshKit.at(0, 0, 0.0))
	k.box(Vector3(0.03, 0.06, 0.03), s(t, "dark"), ax * MeshKit.at(0, -0.03, 0))
	for i in 5:
		k.box(Vector3(0.3 - i * 0.04, 0.01, 0.01), c, ax * MeshKit.at(0, 0, -len * 0.45 + i * len * 0.22))


## A satellite dish: a small dish; a bigger one on a pedestal with its
## receiver box; a big one with an equipment cabinet and a second small
## dish; with a glowing feed, a fence and a sign. On a crate with bricks (0),
## a steel tripod (1), a white pedestal (2), a heavy dark pedestal (3), a
## brass ring mount (4).
static func _dish(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var r: float = [0.24, 0.32, 0.36, 0.36][g]
	var dz := -0.04 if g < 2 else -0.08
	var mh := 0.42 + r * 0.6
	match t:
		0:
			_u(k, x, Vector3(0, 0, dz), Vector3(0.36, 0.3, 0.3), s(0, "card"))
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.12, 0.3, dz + 0.06), Vector3(0.1, 0.06, 0.16), Pal.BRICK)
			_u(k, x, Vector3(0, 0.3, dz), Vector3(0.04, mh - 0.3, 0.04), s(0, "metal"))
		1:
			for i in 3:
				var a := TAU * (i + 0.25) / 3.0
				_seg(k, x, Vector3(cos(a) * 0.24, 0, dz + sin(a) * 0.24), Vector3(0, mh * 0.6, dz), 0.025, s(1, "metal"))
				_u(k, x, Vector3(cos(a) * 0.24, 0, dz + sin(a) * 0.24), Vector3(0.05, 0.02, 0.05), s(1, "accent"))
			_u(k, x, Vector3(0, mh * 0.55, dz), Vector3(0.05, mh * 0.45, 0.05), s(1, "metal"))
		2:
			_cy(k, x, Vector3(0, 0, dz), 0.16, 0.05, s(2, "base"), 8)
			_cy(k, x, Vector3(0, 0.05, dz), 0.06, mh - 0.05, s(2, "shell"), 8)
			_cy(k, x, Vector3(0, mh * 0.5, dz), 0.065, 0.03, s(2, "accent"), 8)
		3:
			_u(k, x, Vector3(0, 0, dz), Vector3(0.4, 0.08, 0.36), s(3, "base"))
			_u(k, x, Vector3(0, 0.08, dz), Vector3(0.2, mh * 0.5, 0.2), s(3, "shell"))
			_b(k, x, Vector3(0, 0.08 + mh * 0.4, dz + 0.101), Vector3(0.12, 0.02, 0.004), lit(s(3, "glow"), 0.4))
			_u(k, x, Vector3(0, 0.08 + mh * 0.5, dz), Vector3(0.08, mh * 0.5 - 0.08, 0.08), s(3, "frame"))
		4:
			_cy(k, x, Vector3(0, 0, dz), 0.2, 0.06, s(4, "shell"), 10)
			k.torus(0.19, 0.012, lit(s(4, "glow"), 0.35), x * MeshKit.at(0, 0.06, dz), 12, 3)
			_cy(k, x, Vector3(0, 0.06, dz), 0.04, mh - 0.06, s(4, "frame"), 6)
	_dish_head(k, x * MeshKit.xf(Vector3(0, mh, dz + 0.02), Vector3(-50, 0, 0)), r, t, g >= 3)
	if g >= 1:
		# the receiver box with a cable to it
		var bx := 0.26
		_shell(k, x, Vector3(bx, 0, 0.24), Vector3(0.16, 0.2, 0.1), t)
		_lamp(k, x, Vector3(bx, 0.15, 0.295), t, Color(0.5, 1.0, 0.6))
		_cable(k, x, [Vector3(0, mh - 0.1, dz), Vector3(0.06, 0.1, dz + 0.08), Vector3(bx - 0.08, 0.06, 0.24)], t, 0.018)
	if g >= 2:
		# a second small dish on a short post
		_u(k, x, Vector3(-0.26, 0, 0.24), Vector3(0.03, 0.34, 0.03), s(t, "metal"))
		_dish_head(k, x * MeshKit.xf(Vector3(-0.26, 0.34, 0.26), Vector3(-45, -25, 0)), 0.12, t, false)
		_u(k, x, Vector3(-0.26, 0, 0.24), Vector3(0.1, 0.03, 0.1), s(t, "base"))
	if g >= 3:
		_sign(k, x, Vector3(0.26, 0.32, 0.29), 0.12, t)
		if t >= 1:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.37, 0, -0.1), Vector3(0.025, 0.4, 0.025), s(t, "frame") if t != 1 else s(1, "metal"))
				_b(k, x, Vector3(sx * 0.37, 0.2, -0.2), Vector3(0.006, 0.36, 0.22), Color(0.5, 0.52, 0.55) if t < 3 else s(t, "frame").lightened(0.1))
			_u(k, x, Vector3(0, 0, -0.33), Vector3(0.74, 0.4, 0.006), Color(0.5, 0.52, 0.55) if t < 3 else s(t, "frame").lightened(0.1))
			_u(k, x, Vector3(0, 0.4, -0.33), Vector3(0.76, 0.02, 0.02), s(t, "frame") if t != 1 else s(1, "metal"))
		else:
			k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(0.0, 0.34, 0.1), 6, 4)


## A dish facing the local +Y of dx: bowl, back frame, struts, feed.
static func _dish_head(k: MeshKit, dx: Transform3D, r: float, t: int, glow: bool) -> void:
	var dc: Color = [Color(0.86, 0.86, 0.84), Color(0.92, 0.93, 0.94), s(2, "shell"), Color(0.6, 0.63, 0.68), s(4, "shell2")][t]
	k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.5, 0.025), Vector2(r, r * 0.3), Vector2(r * 0.96, r * 0.3), Vector2(r * 0.48, 0.045), Vector2(0.0, 0.02)]), dc, dx, 14)
	if t == 4:
		k.torus(r * 0.99, 0.012, s(4, "frame"), dx * MeshKit.at(0, r * 0.3, 0), 14, 3)
	k.box(Vector3(r * 1.2, 0.03, 0.03), s(t, "frame") if t != 2 else s(2, "shell2"), dx * MeshKit.at(0, -0.015, 0))
	k.box(Vector3(0.03, 0.03, r * 1.2), s(t, "frame") if t != 2 else s(2, "shell2"), dx * MeshKit.at(0, -0.015, 0))
	var fy := r * 0.95
	for i in 3:
		var a := TAU * i / 3.0
		_seg(k, dx, Vector3(cos(a) * r * 0.9, r * 0.28, sin(a) * r * 0.9), Vector3(0, fy, 0), 0.01, s(t, "metal"))
	k.box(Vector3(0.05, 0.07, 0.05), s(t, "dark") if not glow else lit(s(t, "glow") if t != 0 else Color(1.0, 0.4, 0.3), 0.35), dx * MeshKit.at(0, fy, 0))
	if t == 0:
		k.box(Vector3(r * 0.4, 0.006, r * 0.3), Color(0.94, 0.94, 0.9), dx * MeshKit.xf(Vector3(r * 0.3, 0.06, 0), Vector3(0, 0, 8)))


## A drone pad: the pad; a drone parked on it; a charging locker with a
## parcel and a windsock; raised on legs with a glowing ring and a second
## drone coming in. Plywood on pallets with a sprayed H (0), a steel plate
## with hazard edges (1), a white disc with a teal ring (2), a dark pad with
## blue lights (3), a graphite hexagon with brass inlay (4).
static func _drone(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var py := 0.0
	if g == 3:
		# raised on legs
		py = 0.3
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.24, 0, sz * 0.24 - 0.02), Vector3(0.04, py, 0.04), s(t, "frame") if t != 2 else s(2, "shell"))
		_seg(k, x, Vector3(-0.24, 0.02, 0.22), Vector3(0.24, py - 0.02, 0.22), 0.02, s(t, "frame") if t != 2 else s(2, "shell"))
	var r := 0.33
	var pz := -0.02
	match t:
		0:
			if py == 0.0:
				_skid(k, x, Vector3(0, 0, pz), 0.66, 0.66, 0)
			_u(k, x, Vector3(0, py + 0.085 if py == 0.0 else py, pz), Vector3(0.66, 0.025, 0.66), s(0, "shell"))
			var hy := (py + 0.085 if py == 0.0 else py) + 0.026
			for sx: float in [-1.0, 1.0]:
				_r(k, x, Vector3(sx * 0.12, hy, pz), Vector3(0.06, 0.004, 0.36), Vector3(0, sx * 3.0, 0), Color(0.96, 0.96, 0.94))
			_b(k, x, Vector3(0, hy, pz), Vector3(0.24, 0.004, 0.06), Color(0.96, 0.96, 0.94))
			py = hy
		1:
			_u(k, x, Vector3(0, py, pz), Vector3(0.68, 0.04, 0.68), s(1, "frame"))
			for i in 4:
				var a := TAU * i / 4.0
				_hazard(k, x * MeshKit.xf(Vector3(cos(a) * 0.3, py + 0.045, pz + sin(a) * 0.3), Vector3(-90, 90 - rad_to_deg(a), 0)), Vector3.ZERO, 0.6, 0.05)
			_b(k, x, Vector3(-0.1, py + 0.044, pz), Vector3(0.05, 0.006, 0.3), s(1, "accent"))
			_b(k, x, Vector3(0.1, py + 0.044, pz), Vector3(0.05, 0.006, 0.3), s(1, "accent"))
			_b(k, x, Vector3(0, py + 0.044, pz), Vector3(0.2, 0.006, 0.05), s(1, "accent"))
			py += 0.044
		2:
			_cy(k, x, Vector3(0, py, pz), r, 0.04, s(2, "shell"), 14)
			k.torus(r * 0.8, 0.014, s(2, "accent"), x * MeshKit.at(0, py + 0.042, pz), 14, 3)
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(sx * 0.08, py + 0.042, pz), Vector3(0.045, 0.006, 0.24), s(2, "accent"))
			_b(k, x, Vector3(0, py + 0.042, pz), Vector3(0.16, 0.006, 0.045), s(2, "accent"))
			py += 0.042
		3:
			_u(k, x, Vector3(0, py, pz), Vector3(0.7, 0.05, 0.7), s(3, "shell2"))
			k.torus(r * 0.75, 0.012, s(3, "accent"), x * MeshKit.at(0, py + 0.052, pz), 14, 3)
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					_b(k, x, Vector3(sx * 0.32, py + 0.06, pz + sz * 0.32), Vector3(0.04, 0.02, 0.04), lit(s(3, "glow"), 0.35))
			_b(k, x, Vector3(-0.08, py + 0.052, pz), Vector3(0.04, 0.006, 0.24), s(3, "accent"))
			_b(k, x, Vector3(0.08, py + 0.052, pz), Vector3(0.04, 0.006, 0.24), s(3, "accent"))
			_b(k, x, Vector3(0, py + 0.052, pz), Vector3(0.16, 0.006, 0.04), s(3, "accent"))
			py += 0.052
		4:
			_cy(k, x, Vector3(0, py, pz), r + 0.02, 0.05, s(4, "shell"), 6)
			_cy(k, x, Vector3(0, py + 0.05, pz), r * 0.85, 0.006, s(4, "frame"), 6)
			_cy(k, x, Vector3(0, py + 0.052, pz), r * 0.75, 0.006, s(4, "shell2"), 6)
			py += 0.058
	if g >= 1:
		_quad(k, x * MeshKit.xf(Vector3(0, py, pz), Vector3(0, 20, 0)), t, col)
	if g >= 2:
		# a charging locker with a parcel, and a windsock
		_shell(k, x, Vector3(0.0, 0, 0.31), Vector3(0.4, 0.2, 0.08) if g == 2 else Vector3(0.4, 0.14, 0.06), t)
		for i in 3:
			_b(k, x, Vector3(-0.13 + i * 0.13, 0.1 if g == 2 else 0.07, 0.364 if g == 2 else 0.354), Vector3(0.1, 0.1 if g == 2 else 0.06, 0.006), s(t, "shell2") if t != 2 else s(2, "shell2"))
		_lamp(k, x, Vector3(0.15, 0.17 if g == 2 else 0.11, 0.366 if g == 2 else 0.356), t, Color(0.5, 1.0, 0.6), 0.025)
		_u(k, x, Vector3(-0.32, 0, -0.32), Vector3(0.025, 0.9, 0.025), s(t, "metal"))
		_seg(k, x, Vector3(-0.32, 0.86, -0.32), Vector3(-0.32 + 0.2, 0.8, -0.32 + 0.04), 0.06, Color(0.96, 0.5, 0.24))
		_b(k, x, Vector3(-0.27, 0.845, -0.31), Vector3(0.03, 0.065, 0.065), Color(0.96, 0.96, 0.94))
	if g >= 3:
		k.torus(r * 0.92, 0.014, lit(s(t, "glow"), 0.3), x * MeshKit.at(0, py + 0.01, pz), 16, 3)
		_quad(k, x * MeshKit.xf(Vector3(0.12, 1.15, -0.1), Vector3(8, -40, 6)), t, col)


## A quadcopter with its parcel (body at the origin, landing skids below).
static func _quad(k: MeshKit, dx: Transform3D, t: int, col: Color) -> void:
	var bc: Color = [Color(0.86, 0.3, 0.24), s(1, "accent"), s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
	k.box(Vector3(0.14, 0.06, 0.18), bc, dx * MeshKit.at(0, 0.08, 0))
	k.box(Vector3(0.1, 0.02, 0.12), s(t, "dark"), dx * MeshKit.at(0, 0.12, 0))
	k.box(Vector3(0.04, 0.02, 0.012), lit(s(t, "glow"), 0.35), dx * MeshKit.at(0, 0.09, 0.096))
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(0.012, 0.05, 0.16), s(t, "dark"), dx * MeshKit.at(sx * 0.05, 0.025, 0))
		for sz: float in [-1.0, 1.0]:
			k.box(Vector3(0.16, 0.015, 0.02), s(t, "dark"), dx * MeshKit.xf(Vector3(sx * 0.1, 0.1, sz * 0.1), Vector3(0, sx * sz * 45.0, 0)))
			k.cyl(0.06, 0.006, Color(0.5, 0.52, 0.56) if t < 4 else s(4, "frame"), dx * MeshKit.at(sx * 0.15, 0.115, sz * 0.15), 8)
			k.cyl(0.012, 0.02, s(t, "dark"), dx * MeshKit.at(sx * 0.15, 0.1, sz * 0.15), 4)
	k.box(Vector3(0.1, 0.06, 0.1), s(0, "card") if t < 2 else col, dx * MeshKit.at(0, 0.02, 0))


## A bench: a seat; with a planter and a bin; with a side table and a lamp;
## under a shelter with a glowing strip and a charging pad. A plank on
## breeze blocks (0), a steel picnic bench (1), slats on a white frame (2),
## dark steel mesh (3), graphite with brass and an underglow (4).
static func _bench(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var bz := 0.06
	_seat(k, x, Vector3(0, 0, bz), t)
	_cy(k, x, Vector3(0.22, 0.32 + (0.012 if t == 4 else 0.0), bz + 0.02), 0.025, 0.06, Color(0.96, 0.96, 0.94) if t != 0 else Color(0.86, 0.3, 0.24), 6)
	_r(k, x, Vector3(-0.12, 0.33 + (0.012 if t == 4 else 0.0), bz + 0.02), Vector3(0.16, 0.012, 0.12), Vector3(0, 14, 0), Color(0.92, 0.91, 0.86))
	if t >= 1:
		_b(k, x, Vector3(0, 0.25, bz - 0.12 + (0.0 if t != 4 else 0.04)), Vector3(0.1, 0.03, 0.006), Pal.BRASS if t != 3 else s(3, "accent"))
	if g >= 1:
		# a planter behind and a bin at the side
		_planter_box(k, x, Vector3(0, 0, -0.27), 0.68, 0.18, 0.18, t)
		for i in 4:
			_bush(k, x, Vector3(-0.24 + i * 0.16, 0.15, -0.27), 0.07, t, 1)
		var bc: Color = [Color(0.36, 0.56, 0.38), s(1, "frame"), s(2, "shell2"), s(3, "frame"), s(4, "shell")][t]
		_cy(k, x, Vector3(0.31, 0, 0.27), 0.06, 0.24, bc, 6)
		_cy(k, x, Vector3(0.31, 0.24, 0.27), 0.065, 0.02, bc.darkened(0.2) if t != 4 else s(4, "frame"), 6)
	if g >= 2:
		# a little table with a cup and a laptop
		var tc: Color = [s(0, "card"), s(1, "metal"), s(2, "shell"), s(3, "shell2"), s(4, "shell2")][t]
		_u(k, x, Vector3(-0.29, 0, 0.27), Vector3(0.025, 0.28, 0.025), s(t, "frame") if t != 2 else s(2, "frame"))
		_u(k, x, Vector3(-0.29, 0.28, 0.27), Vector3(0.15, 0.02, 0.14), tc)
		_cy(k, x, Vector3(-0.32, 0.3, 0.28), 0.02, 0.04, Color(0.96, 0.96, 0.94), 6)
		_u(k, x, Vector3(-0.26, 0.3, 0.26), Vector3(0.08, 0.008, 0.06), s(t, "dark"))
		_r(k, x, Vector3(-0.26, 0.33, 0.235), Vector3(0.08, 0.05, 0.004), Vector3(-15, 0, 0), lit(Color(0.5, 0.86, 1.0), 0.45))
		if g == 2:
			_lamp_head(k, x * MeshKit.at(0.31, 0.64, 0.27), t, false)
			_u(k, x, Vector3(0.31, 0.26, 0.27), Vector3(0.025, 0.36, 0.025), s(t, "frame") if t != 2 else s(2, "shell"))
	if g >= 3:
		_canopy(k, x, Vector3(0, 0, 0), 0.76, 0.66, 1.15, t)
		_b(k, x, Vector3(0, 0.06, bz + 0.17), Vector3(0.62, 0.012, 0.01), lit(s(t, "glow"), 0.3))
		# a charging pad on the arm
		_u(k, x, Vector3(0.27, 0.42, bz + 0.04), Vector3(0.08, 0.012, 0.08), lit(s(t, "accent2") if t >= 2 else s(t, "glow"), 0.4))


## The seat itself (front at +z).
static func _seat(k: MeshKit, x: Transform3D, p: Vector3, t: int) -> void:
	var sh := 0.32
	match t:
		0:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, p + Vector3(sx * 0.26, 0, 0), Vector3(0.14, sh - 0.04, 0.2), Pal.STONE)
				_b(k, x, p + Vector3(sx * 0.26, sh * 0.5, 0.101), Vector3(0.08, 0.08, 0.004), Pal.STONE_DARK)
			_r(k, x, p + Vector3(0, sh - 0.02, 0), Vector3(0.72, 0.04, 0.22), Vector3(0, 2, 0), Pal.WOOD_LIGHT)
			_b(k, x, p + Vector3(0.1, sh + 0.002, 0.05), Vector3(0.12, 0.004, 0.06), s(0, "tape"))
		1:
			for sx: float in [-1.0, 1.0]:
				_seg(k, x, p + Vector3(sx * 0.28, 0, 0.12), p + Vector3(sx * 0.28, sh, -0.06), 0.03, s(1, "frame"))
				_seg(k, x, p + Vector3(sx * 0.28, 0, -0.12), p + Vector3(sx * 0.28, sh, 0.06), 0.03, s(1, "frame"))
			for i in 3:
				_u(k, x, p + Vector3(0, sh - 0.03, -0.07 + i * 0.07), Vector3(0.7, 0.03, 0.06), s(1, "accent") if i != 1 else s(1, "accent").darkened(0.1))
			for i in 2:
				_r(k, x, p + Vector3(0, sh + 0.14 + i * 0.08, -0.13), Vector3(0.7, 0.05, 0.02), Vector3(-10, 0, 0), s(1, "accent"))
			_u(k, x, p + Vector3(0, sh, -0.12), Vector3(0.03, 0.26, 0.03), s(1, "frame"))
		2:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, p + Vector3(sx * 0.3, 0, 0), Vector3(0.04, sh, 0.24), s(2, "shell"))
				_u(k, x, p + Vector3(sx * 0.3, sh, -0.1), Vector3(0.04, 0.26, 0.04), s(2, "shell"))
			for i in 4:
				_u(k, x, p + Vector3(0, sh, -0.09 + i * 0.06), Vector3(0.66, 0.025, 0.045), Pal.WOOD_LIGHT)
			for i in 3:
				_r(k, x, p + Vector3(0, sh + 0.1 + i * 0.07, -0.11), Vector3(0.66, 0.045, 0.02), Vector3(-8, 0, 0), Pal.WOOD_LIGHT)
		3:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, p + Vector3(sx * 0.3, 0, 0), Vector3(0.05, sh + 0.28, 0.06), s(3, "frame"))
				_u(k, x, p + Vector3(sx * 0.3, sh * 0.5, 0.0), Vector3(0.06, 0.04, 0.26), s(3, "frame"))
			_u(k, x, p + Vector3(0, sh - 0.02, 0), Vector3(0.66, 0.03, 0.24), s(3, "shell2"))
			for i in 5:
				_u(k, x, p + Vector3(-0.24 + i * 0.12, sh + 0.01, 0), Vector3(0.012, 0.006, 0.22), s(3, "dark"))
			_r(k, x, p + Vector3(0, sh + 0.16, -0.11), Vector3(0.66, 0.24, 0.025), Vector3(-10, 0, 0), s(3, "shell2"))
			for i in 4:
				_r(k, x, p + Vector3(0, sh + 0.07 + i * 0.06, -0.095), Vector3(0.62, 0.008, 0.008), Vector3(-10, 0, 0), s(3, "dark"))
		4:
			_u(k, x, p + Vector3(0, 0, -0.02), Vector3(0.5, sh - 0.04, 0.16), s(4, "shell"))
			_b(k, x, p + Vector3(0, 0.03, 0.065), Vector3(0.46, 0.012, 0.006), lit(s(4, "glow"), 0.35))
			_u(k, x, p + Vector3(0, sh - 0.04, 0), Vector3(0.7, 0.05, 0.24), s(4, "shell2"))
			_u(k, x, p + Vector3(0, sh + 0.01, 0.115), Vector3(0.7, 0.012, 0.012), s(4, "frame"))
			_r(k, x, p + Vector3(0, sh + 0.16, -0.11), Vector3(0.7, 0.24, 0.04), Vector3(-12, 0, 0), s(4, "shell2"))
			_r(k, x, p + Vector3(0, sh + 0.28, -0.125), Vector3(0.7, 0.015, 0.045), Vector3(-12, 0, 0), s(4, "frame"))


## E-scooters: one; two; three in a dock; the dock with a shelter, glowing
## chargers and a sign. An old bicycle in the garage, then scooters in the
## era's colours: yellow (1), teal and white share-scooters (2), dark (3),
## graphite and brass with glowing decks (4).
static func _bikes(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var n: int = [1, 2, 3, 3][g]
	if g >= 2:
		# the dock: a rail with charging posts
		var dc: Color = [s(0, "frame"), s(1, "frame"), s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
		_u(k, x, Vector3(0, 0, -0.28), Vector3(0.72, 0.04, 0.12), s(t, "base"))
		for i in n:
			var bx := -0.24 + i * 0.24
			_u(k, x, Vector3(bx, 0.04, -0.3), Vector3(0.06, 0.4, 0.06), dc)
			_b(k, x, Vector3(bx, 0.36, -0.268), Vector3(0.04, 0.04, 0.006), lit(s(t, "glow"), 0.35) if g >= 3 else s(t, "dark"))
		_u(k, x, Vector3(0, 0.44, -0.3), Vector3(0.72, 0.04, 0.08), dc)
	for i in n:
		var bx2 := 0.0 if n == 1 else -0.14 + i * (0.28 / (n - 1))
		if t == 0:
			_bicycle(k, x * MeshKit.xf(Vector3(bx2, 0, 0.04), Vector3(0, 58, 4.0 - i * 3.0), Vector3.ONE * 0.8), i)
		else:
			_scooter(k, x * MeshKit.xf(Vector3(bx2 - 0.05, 0, 0.02), Vector3(0, 55, 0)), t, i)
	if g >= 3:
		_canopy(k, x, Vector3(0, 0, 0.0), 0.76, 0.72, 1.1, t)
		_sign(k, x, Vector3(0.0, 0.62, -0.25), 0.16, t)


## One e-scooter facing +z (wheels along z).
static func _scooter(k: MeshKit, x: Transform3D, t: int, i: int) -> void:
	var c: Color = [s(0, "accent2"), s(1, "accent"), s(2, "accent") if i % 2 == 0 else s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
	k.box(Vector3(0.08, 0.04, 0.44), c, x * MeshKit.at(0, 0.08, 0))
	k.box(Vector3(0.07, 0.01, 0.34), s(t, "dark"), x * MeshKit.at(0, 0.105, -0.02))
	for sz: float in [-1.0, 1.0]:
		k.cyl(0.055, 0.03, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(-0.015, 0.055, sz * 0.2), Vector3(0, 0, -90)), 8)
	k.box(Vector3(0.025, 0.66, 0.025), c.darkened(0.15) if t != 4 else s(4, "frame"), x * MeshKit.xf(Vector3(0, 0.42, 0.24), Vector3(-10, 0, 0)))
	k.box(Vector3(0.24, 0.025, 0.025), s(t, "dark"), x * MeshKit.at(0, 0.74, 0.3))
	k.box(Vector3(0.05, 0.03, 0.02), lit(Color(1.0, 0.95, 0.85), 0.4), x * MeshKit.at(0, 0.62, 0.29))
	if t == 4:
		k.box(Vector3(0.09, 0.01, 0.4), lit(s(4, "glow"), 0.35), x * MeshKit.at(0, 0.058, 0))


## An old bicycle facing +z.
static func _bicycle(k: MeshKit, x: Transform3D, i: int) -> void:
	var c: Color = [Color(0.36, 0.5, 0.7), Color(0.7, 0.3, 0.26)][i % 2]
	for sz: float in [-1.0, 1.0]:
		k.torus(0.16, 0.012, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(0, 0.17, sz * 0.25), Vector3(0, 0, 90)), 12, 3)
		k.box(Vector3(0.006, 0.3, 0.006), Color(0.6, 0.62, 0.64), x * MeshKit.at(0, 0.17, sz * 0.25))
	_run(k, x, [Vector3(0, 0.17, -0.25), Vector3(0, 0.42, -0.08), Vector3(0, 0.42, 0.16), Vector3(0, 0.17, 0.25)], 0.02, c)
	_seg(k, x, Vector3(0, 0.17, -0.25), Vector3(0, 0.2, 0.0), 0.02, c)
	_seg(k, x, Vector3(0, 0.2, 0.0), Vector3(0, 0.42, 0.16), 0.02, c)
	_seg(k, x, Vector3(0, 0.2, 0.0), Vector3(0, 0.46, -0.1), 0.02, c)
	k.box(Vector3(0.06, 0.02, 0.1), Color(0.15, 0.15, 0.16), x * MeshKit.at(0, 0.47, -0.1))
	k.box(Vector3(0.26, 0.02, 0.02), Color(0.6, 0.62, 0.64), x * MeshKit.at(0, 0.5, 0.18))
	k.box(Vector3(0.12, 0.08, 0.1), s(0, "card"), x * MeshKit.at(0, 0.38, 0.28))


## Sand sacks: one sack; a heap with a shovel; a pallet of sacks with a
## bucket; a hopper with a chute and a glowing level gauge. Burlap sacks (0),
## a yellow-looped bulk bag (1), white bags with teal print (2), a dark steel
## hopper (3), a graphite silo with brass (4).
static func _sandbags(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var sc: Color = [Color(0.76, 0.64, 0.44), Color(0.92, 0.9, 0.84), s(2, "shell"), Color(0.84, 0.78, 0.62), s(4, "shell2")][t]
	var spots := [Vector3(0, 0, 0.0), Vector3(0.22, 0, 0.04), Vector3(-0.22, 0, 0.02), Vector3(0.0, 0.15, 0.03), Vector3(0.12, 0.3, 0.02), Vector3(-0.12, 0.15, 0.03)]
	if g == 3:
		_hopper(k, x, t, col)
		for i in 2:
			_sack(k, x * MeshKit.xf(Vector3(-0.22 + i * 0.44, 0, 0.25), Vector3(0, 20.0 - i * 40.0, 0)), sc, t, col)
		return
	var y := 0.0
	if g == 2:
		y = _skid(k, x, Vector3(0, 0, -0.02), 0.72, 0.5, t)
	if t == 1 and g >= 1:
		# a bulk bag with lifting loops
		_u(k, x, Vector3(-0.05, y, -0.04), Vector3(0.48, 0.44 + g * 0.06, 0.44), sc)
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_seg(k, x, Vector3(-0.05 + sx * 0.2, y + 0.48 + g * 0.06, -0.04 + sz * 0.2), Vector3(-0.05 + sx * 0.14, y + 0.6 + g * 0.06, -0.04 + sz * 0.14), 0.03, s(1, "accent"))
		_u(k, x, Vector3(-0.05, y + 0.44 + g * 0.06, -0.04), Vector3(0.36, 0.04, 0.36), sc.darkened(0.08))
		_b(k, x, Vector3(-0.05, y + 0.26, 0.181), Vector3(0.22, 0.14, 0.006), Color(0.96, 0.96, 0.94))
		_b(k, x, Vector3(-0.05, y + 0.26, 0.185), Vector3(0.12, 0.04, 0.004), col)
	else:
		var n: int = [1, 3, 6][g]
		for i in n:
			var sp: Vector3 = spots[i]
			_sack(k, x * MeshKit.xf(Vector3(sp.x, y + sp.y, sp.z - 0.04), Vector3(0, float((i * 47) % 30 - 15), 0)), sc.darkened(0.04 * (i % 3)), t, col)
		if g == 0:
			k.cone(0.1, 0.05, Color(0.88, 0.8, 0.6), x * MeshKit.at(0.18, 0, 0.14), 7)
			_r(k, x, Vector3(0.2, 0.04, 0.2), Vector3(0.08, 0.03, 0.12), Vector3(0, -30, 0), s(t, "metal") if t != 0 else Color(0.36, 0.56, 0.38))
			_r(k, x, Vector3(0.24, 0.05, 0.28), Vector3(0.02, 0.02, 0.1), Vector3(0, -30, 0), Pal.WOOD_LIGHT if t < 2 else s(t, "dark"))
	if g >= 1:
		# a shovel (or scoop) leaning on it, a little spilled heap
		var hc: Color = Pal.WOOD_LIGHT if t < 2 else s(t, "frame")
		_seg(k, x, Vector3(0.3, 0.0, 0.2), Vector3(0.3, 0.6, -0.04), 0.025, hc)
		_r(k, x, Vector3(0.3, 0.06, 0.2), Vector3(0.1, 0.13, 0.015), Vector3(-25, 0, 0), s(t, "metal"))
		k.cone(0.12, 0.07, Color(0.88, 0.8, 0.6), x * MeshKit.at(-0.22, 0, 0.24), 8)
	if g == 2:
		var bc: Color = [Color(0.64, 0.66, 0.68), s(1, "accent"), s(2, "accent"), s(3, "frame"), s(4, "frame")][t]
		_cy(k, x, Vector3(0.28, 0, 0.3), 0.07, 0.14, bc, 8, 0.085)
		_cy(k, x, Vector3(0.28, 0.1, 0.3), 0.07, 0.03, Color(0.88, 0.8, 0.6), 8)


## One sack lying on p (along x).
static func _sack(k: MeshKit, x: Transform3D, c: Color, t: int, col: Color) -> void:
	k.ellipsoid(Vector3(0.16, 0.08, 0.11), c, x * MeshKit.at(0, 0.075, 0), 8, 5)
	k.box(Vector3(0.025, 0.05, 0.16), c.darkened(0.2), x * MeshKit.at(0.15, 0.08, 0))
	if t >= 2:
		k.box(Vector3(0.1, 0.006, 0.08), col if t != 4 else lit(s(4, "glow"), 0.4), x * MeshKit.at(0, 0.154, 0))
	elif t == 0:
		k.box(Vector3(0.12, 0.006, 0.02), Color(0.5, 0.4, 0.28), x * MeshKit.at(-0.02, 0.153, 0.0))


## A sand hopper on legs with a chute and a level gauge (fills the back).
static func _hopper(k: MeshKit, x: Transform3D, t: int, _col: Color) -> void:
	var hc: Color = [s(0, "shell"), s(1, "accent"), s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
	var lc: Color = [s(0, "frame"), s(1, "frame"), s(2, "frame"), s(3, "frame"), s(4, "frame")][t]
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.24, 0, -0.08 + sz * 0.18), Vector3(0.04, 0.62, 0.04), lc)
	_seg(k, x, Vector3(-0.24, 0.1, 0.1), Vector3(0.24, 0.5, 0.1), 0.02, lc)
	if t == 4:
		_cy(k, x, Vector3(0, 0.62, -0.08), 0.28, 0.6, hc, 8)
		_cy(k, x, Vector3(0, 0.42, -0.08), 0.06, 0.2, hc, 8, 0.28)
		for f: float in [0.2, 0.5, 0.8]:
			_cy(k, x, Vector3(0, 0.62 + 0.6 * f, -0.08), 0.285, 0.02, s(4, "frame"), 8)
		k.cone(0.29, 0.12, s(4, "shell2"), x * MeshKit.at(0, 1.22, -0.08), 8)
	else:
		_u(k, x, Vector3(0, 0.62, -0.08), Vector3(0.56, 0.5, 0.44), hc)
		_seg(k, x, Vector3(0, 0.62, -0.08), Vector3(0, 0.42, -0.08), 0.12, hc.darkened(0.12))
		_u(k, x, Vector3(0, 1.12, -0.08), Vector3(0.58, 0.03, 0.46), lc)
		if t == 0:
			for i in 2:
				_b(k, x, Vector3(0, 0.78 + i * 0.16, 0.142), Vector3(0.56, 0.012, 0.008), hc.darkened(0.22))
		elif t == 1:
			_hazard(k, x, Vector3(0, 0.66, 0.14), 0.56, 0.05)
		elif t == 2:
			_b(k, x, Vector3(0, 1.0, 0.142), Vector3(0.56, 0.04, 0.006), s(2, "accent"))
	# chute and gauge
	_r(k, x, Vector3(0.0, 0.34, 0.06), Vector3(0.12, 0.03, 0.28), Vector3(-30, 0, 0), s(t, "metal"))
	_b(k, x, Vector3(0.2, 0.86, 0.145 if t != 4 else 0.2), Vector3(0.05, 0.36, 0.01), s(t, "dark"))
	_b(k, x, Vector3(0.2, 0.78, 0.152 if t != 4 else 0.207), Vector3(0.03, 0.18, 0.006), lit(s(t, "glow"), 0.35))
	k.cone(0.12, 0.08, Color(0.88, 0.8, 0.6), x * MeshKit.at(0.0, 0, 0.22), 8)


## Wafer boxes: one box; a stack of two on a trolley; a rack cart of pods;
## a glass-fronted stocker with a glowing wafer on show and a light tower.
## Cardboard boxes (0), grey cases on a steel cart (1), white pods with teal
## doors (2), dark pods (3), graphite pods with brass (4).
static func _wafers(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	match g:
		0:
			var sc: Color = [s(0, "card"), s(1, "metal"), s(2, "shell"), s(3, "shell2"), s(4, "shell")][t]
			if t == 1:
				for sx: float in [-1.0, 1.0]:
					for sz: float in [-1.0, 1.0]:
						_u(k, x, Vector3(sx * 0.15, 0, sz * 0.13), Vector3(0.025, 0.3, 0.025), s(1, "frame"))
				_u(k, x, Vector3(0, 0.3, 0), Vector3(0.36, 0.025, 0.32), sc)
				_u(k, x, Vector3(0, 0.1, 0), Vector3(0.32, 0.015, 0.28), s(1, "frame"))
			else:
				_u(k, x, Vector3(0, 0, 0), Vector3(0.36, 0.3, 0.32), sc)
				_b(k, x, Vector3(0, 0.15, 0.161), Vector3(0.28, 0.2, 0.004), sc.darkened(0.1) if t != 4 else s(4, "frame"))
				if t == 4:
					_b(k, x, Vector3(0, 0.03, 0.162), Vector3(0.3, 0.012, 0.004), lit(s(4, "glow"), 0.35))
				elif t == 2:
					_b(k, x, Vector3(0, 0.28, 0.161), Vector3(0.36, 0.02, 0.004), s(2, "accent"))
			_foup(k, x, Vector3(0, 0.325, 0), t, col)
			# a clipboard leaning on the stand
			_r(k, x, Vector3(0.22, 0.14, 0.12), Vector3(0.14, 0.2, 0.012), Vector3(0, -30, -12), Pal.WOOD_LIGHT if t < 2 else s(t, "dark"))
			_r(k, x, Vector3(0.222, 0.13, 0.128), Vector3(0.11, 0.15, 0.004), Vector3(0, -30, -12), Color(0.97, 0.97, 0.95))
		1:
			_trolley(k, x, 0.0, t)
			_foup(k, x, Vector3(-0.02, 0.14, 0), t, col)
			_foup(k, x, Vector3(0.02, 0.38, 0), t, col)
		2:
			# a two-shelf rack cart
			var fc: Color = [s(0, "frame"), s(1, "metal"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					_u(k, x, Vector3(sx * 0.33, 0.06, sz * 0.2), Vector3(0.03, 0.9, 0.03), fc)
					k.cyl(0.035, 0.03, Color(0.15, 0.15, 0.16), x * MeshKit.xf(Vector3(sx * 0.33 - 0.015, 0.035, sz * 0.2), Vector3(0, 0, -90)), 6)
			for sy: float in [0.12, 0.52, 0.94]:
				_u(k, x, Vector3(0, sy, 0), Vector3(0.7, 0.025, 0.44), fc if sy > 0.9 else fc.darkened(0.1))
			for i in 2:
				_foup(k, x, Vector3(-0.17 + i * 0.34, 0.145, 0), t, col)
				_foup(k, x, Vector3(-0.17 + i * 0.34, 0.545, 0), t, col)
		3:
			# a stocker cabinet with a glass front
			_shell(k, x, Vector3(0, 0, -0.17), Vector3(0.7, 1.1, 0.26), t)
			# an open-fronted case of pods with shelves and posts
			var fz := 0.16
			var fc: Color = s(t, "frame") if t != 2 else s(2, "shell2")
			_u(k, x, Vector3(0, 0, 0.06), Vector3(0.68, 0.16, 0.2), s(t, "shell"))
			_b(k, x, Vector3(0, 0.09, fz + 0.002), Vector3(0.4, 0.05, 0.006), s(t, "accent"))
			for sy: float in [0.58, 0.98]:
				_u(k, x, Vector3(0, sy, 0.06), Vector3(0.66, 0.025, 0.2), fc)
			for r in 2:
				for i in 2:
					_foup(k, x, Vector3(-0.15 + i * 0.3, 0.16 + r * 0.42, 0.05), t, col, 0.7)
			for i in 3:
				_u(k, x, Vector3(-0.32 + i * 0.32, 0.16, fz), Vector3(0.025, 0.84, 0.025), fc)
			_r(k, x, Vector3(-0.2, 0.75, fz + 0.016), Vector3(0.03, 0.26, 0.003), Vector3(0, 0, 30), Color(0.86, 0.94, 0.98))
			_r(k, x, Vector3(0.12, 0.36, fz + 0.016), Vector3(0.03, 0.2, 0.003), Vector3(0, 0, 30), Color(0.86, 0.94, 0.98))
			# the era's air handling on top: box fans (0), a filter unit with fans
			# (1-3), glowing fins (4)
			if t == 4:
				for i in 5:
					_u(k, x, Vector3(-0.28 + i * 0.1, 1.12, -0.2), Vector3(0.025, 0.16, 0.16), s(4, "shell2"))
					_u(k, x, Vector3(-0.28 + i * 0.1, 1.14, -0.115), Vector3(0.008, 0.12, 0.006), lit(s(4, "glow"), 0.4))
			else:
				_cooler(k, x, Vector3(-0.06, 1.12, -0.18), 0.5, 0.2, t)
			# a wafer on show at the front, glowing, and a light tower
			_cy(k, x, Vector3(-0.12, 1.12, 0.06), 0.03, 0.06, s(t, "frame"), 6)
			k.cyl(0.11, 0.012, Color(0.5, 0.56, 0.86), x * MeshKit.xf(Vector3(-0.12, 1.2, 0.08), Vector3(60, 0, 0)), 12)
			for i in 3:
				k.box(Vector3(0.17 - abs(i - 1) * 0.05, 0.004, 0.012), lit(Color(0.7, 0.8, 1.0), 0.4), x * MeshKit.xf(Vector3(-0.12, 1.2, 0.08), Vector3(60, 0, 0)) * MeshKit.at(0, 0.014, -0.05 + i * 0.05))
			_cy(k, x, Vector3(0.26, 1.12, -0.16), 0.02, 0.1, s(t, "dark"), 6)
			for i in 3:
				_cy(k, x, Vector3(0.26, 1.22 + i * 0.05, -0.16), 0.03, 0.045, lit([Color(0.4, 1.0, 0.5), Color(1.0, 0.8, 0.3), Color(1.0, 0.35, 0.3)][i], 0.35 if i == 0 else 0.7), 6)


## One wafer pod standing on p.
static func _foup(k: MeshKit, x: Transform3D, p: Vector3, t: int, col: Color, s_ := 1.0) -> void:
	var w := 0.3 * s_
	var h := 0.22 * s_
	var d := 0.3 * s_
	match t:
		0:
			_u(k, x, p, Vector3(w, h * 0.5, d), s(0, "card"))
			_u(k, x, p + Vector3(0, h * 0.5, 0), Vector3(w + 0.01, 0.015, d + 0.01), s(0, "card").darkened(0.1))
			_b(k, x, p + Vector3(0, h * 0.25, d * 0.5 + 0.002), Vector3(w * 0.6, 0.03, 0.004), Color(0.16, 0.14, 0.13))
			_b(k, x, p + Vector3(w * 0.3, h * 0.25, d * 0.5 + 0.002), Vector3(0.04, 0.04, 0.004), col)
			_b(k, x, p + Vector3(0, h * 0.5 + 0.01, 0), Vector3(w * 0.25, 0.005, d + 0.012), s(0, "tape"))
		_:
			var bc: Color = [Color.BLACK, Color(0.66, 0.68, 0.72), s(2, "shell"), s(3, "shell2"), s(4, "shell")][t]
			_u(k, x, p, Vector3(w, h, d), bc)
			_u(k, x, p + Vector3(0, h, 0), Vector3(w * 0.7, 0.03, d * 0.4), bc.darkened(0.12))
			_u(k, x, p + Vector3(0, h + 0.03, 0), Vector3(w * 0.85, 0.015, d * 0.15), s(t, "frame") if t != 2 else s(2, "accent"))
			_b(k, x, p + Vector3(0, h * 0.5, d * 0.5 + 0.004), Vector3(w - 0.03, h - 0.03, 0.008), s(t, "accent") if t == 2 else (bc.lightened(0.1) if t != 4 else s(4, "shell2")))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(sx * w * 0.3, h * 0.5, d * 0.5 + 0.01), Vector3(0.02, h * 0.5, 0.008), s(t, "dark") if t != 4 else s(4, "frame"))
			_b(k, x, p + Vector3(0, h * 0.75, d * 0.5 + 0.01), Vector3(0.05, 0.02, 0.006), col if t < 3 else lit(s(t, "glow"), 0.4))


## A low trolley (deck at 0.12) centred at x0.
static func _trolley(k: MeshKit, x: Transform3D, x0: float, t: int) -> void:
	var fc: Color = [s(0, "frame"), s(1, "metal"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
	_u(k, x, Vector3(x0, 0.08, 0), Vector3(0.5, 0.04, 0.4), fc)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_cy(k, x, Vector3(x0 + sx * 0.2, 0.0, sz * 0.15), 0.04, 0.08, Color(0.15, 0.15, 0.16), 6)
	_u(k, x, Vector3(x0, 0.12, -0.19), Vector3(0.5, 0.6, 0.025), fc)
	_u(k, x, Vector3(x0, 0.72, -0.19), Vector3(0.54, 0.03, 0.04), Color(0.15, 0.15, 0.16) if t != 4 else s(4, "frame"))


## Paper stacks: a stack of papers and a box; more stacks and a file box; a
## shelf of books; a tall full bookcase with a glowing reading lamp. Crate
## shelves and cardboard (0), steel shelving (1), white shelves (2), dark
## archive racks with blue LEDs (3), graphite and brass (4).
static func _books(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var bk := [Color(0.86, 0.3, 0.26), Color(0.3, 0.5, 0.86), Color(0.96, 0.8, 0.3), Color(0.94, 0.94, 0.9), Color(0.3, 0.66, 0.5), col]
	match g:
		0:
			_stack(k, x, Vector3(-0.1, 0, 0.04), 5, 0, bk)
			_crate(k, x, Vector3(0.18, 0, -0.04), Vector3(0.26, 0.2, 0.3), -8.0, t, col)
		1:
			_stack(k, x, Vector3(-0.22, 0, 0.12), 7, 1, bk)
			_stack(k, x, Vector3(0.02, 0, 0.18), 4, 2, bk)
			_crate(k, x, Vector3(0.18, 0, -0.12), Vector3(0.3, 0.24, 0.32), 6.0, t, col)
			_crate(k, x, Vector3(-0.16, 0, -0.18), Vector3(0.28, 0.22, 0.28), -4.0, t, col)
		_:
			var levels := 3 if g == 2 else 5
			var sh := 0.28 if g == 2 else 0.25
			_shelf(k, x, Vector3(0, 0, -0.18), 0.72, levels, sh, t, bk)
			if g == 2:
				_stack(k, x, Vector3(-0.2, 0, 0.18), 6, 3, bk)
				_crate(k, x, Vector3(0.18, 0, 0.16), Vector3(0.28, 0.2, 0.26), 5.0, t, col)
			else:
				# a reading lamp and a step ladder
				var lx := 0.26
				_cy(k, x, Vector3(lx, 0, 0.2), 0.08, 0.02, s(t, "dark"), 6)
				_cy(k, x, Vector3(lx, 0.02, 0.2), 0.012, 1.0, s(t, "frame") if t != 2 else s(2, "shell"), 4)
				_seg(k, x, Vector3(lx, 1.0, 0.2), Vector3(lx - 0.14, 1.06, 0.24), 0.02, s(t, "frame") if t != 2 else s(2, "shell"))
				k.cone(0.08, 0.08, s(t, "accent") if t != 0 else Color(0.86, 0.3, 0.24), x * MeshKit.xf(Vector3(lx - 0.14, 1.1, 0.24), Vector3(180, 0, 0)), 8)
				k.sphere(0.035, lit(s(t, "glow"), 0.3), x * MeshKit.at(lx - 0.14, 1.0, 0.24), 6, 4)
				for sx: float in [-1.0, 1.0]:
					_seg(k, x, Vector3(-0.2 + sx * 0.1, 0, 0.27), Vector3(-0.2 + sx * 0.1, 0.7, 0.06), 0.02, s(t, "metal") if t != 0 else Pal.WOOD_LIGHT)
				for i in 3:
					_b(k, x, Vector3(-0.2, 0.15 + i * 0.2, 0.22 - i * 0.06), Vector3(0.2, 0.015, 0.05), s(t, "metal") if t != 0 else Pal.WOOD_LIGHT)
				_stack(k, x, Vector3(0.05, 0, 0.24), 4, 4, bk)
				var top := levels * sh + 0.04
				match t:
					0:
						_crate(k, x, Vector3(-0.18, top, -0.18), Vector3(0.26, 0.18, 0.24), 6.0, 0, col)
						_crate(k, x, Vector3(0.16, top, -0.2), Vector3(0.22, 0.14, 0.22), -10.0, 0, col)
					1:
						_u(k, x, Vector3(-0.15, top, -0.18), Vector3(0.3, 0.12, 0.16), Color(0.82, 0.26, 0.22))
						_u(k, x, Vector3(-0.15, top + 0.12, -0.18), Vector3(0.12, 0.03, 0.03), s(1, "dark"))
						_cy(k, x, Vector3(0.2, top, -0.18), 0.05, 0.22, Color(0.82, 0.2, 0.18), 6)
					2:
						_pot(k, x, Vector3(0.18, top, -0.18), 0.08, 0.12, 2)
						_bush(k, x, Vector3(0.18, top + 0.12, -0.18), 0.1, 2, 2)
						_r(k, x, Vector3(-0.15, top + 0.1, -0.2), Vector3(0.16, 0.2, 0.02), Vector3(-10, 0, 0), s(2, "accent"))
					3:
						for i in 3:
							_u(k, x, Vector3(-0.22 + i * 0.22, top, -0.18), Vector3(0.18, 0.14, 0.24), s(3, "shell"))
							_b(k, x, Vector3(-0.22 + i * 0.22, top + 0.07, -0.059), Vector3(0.08, 0.04, 0.004), Color(0.95, 0.95, 0.92))
						k.torus(0.1, 0.012, s(3, "accent"), x * MeshKit.xf(Vector3(0.37, 0.7, -0.18), Vector3(0, 0, 90)), 8, 3)
					4:
						k.sphere(0.09, lit(s(4, "glow"), 0.35), x * MeshKit.at(0.15, top + 0.13, -0.18), 8, 5)
						_cy(k, x, Vector3(0.15, top, -0.18), 0.06, 0.04, s(4, "frame"), 8)
						for sx: float in [-0.24, -0.06]:
							_u(k, x, Vector3(sx, top, -0.18), Vector3(0.03, 0.14, 0.12), s(4, "frame"))
						_u(k, x, Vector3(-0.15, top, -0.18), Vector3(0.14, 0.12, 0.2), Color(0.3, 0.5, 0.86))


## A shelf unit (front +z, back at p.z - 0.15) filled with books.
static func _shelf(k: MeshKit, x: Transform3D, p: Vector3, w: float, levels: int, sh: float, t: int, bk: Array) -> void:
	var fc: Color = [s(0, "frame"), s(1, "accent"), s(2, "shell"), s(3, "frame"), s(4, "shell")][t]
	var bc: Color = [s(0, "base"), s(1, "metal"), s(2, "shell2"), s(3, "shell2"), s(4, "shell2")][t]
	var d := 0.3
	var h := levels * sh + 0.04
	for sx: float in [-1.0, 1.0]:
		if t == 0:
			_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.02), p.y, p.z), Vector3(0.04, h, d), fc)
		else:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.015), p.y, p.z + sz * (d * 0.5 - 0.015)), Vector3(0.03, h, 0.03), fc)
	_u(k, x, Vector3(p.x, p.y, p.z - d * 0.5 + 0.005), Vector3(w - 0.04, h, 0.01), bc.darkened(0.1))
	for l in levels + 1:
		_u(k, x, Vector3(p.x, p.y + l * sh, p.z), Vector3(w, 0.025, d), bc)
		if t == 4:
			_b(k, x, Vector3(p.x, p.y + l * sh + 0.012, p.z + d * 0.5 + 0.003), Vector3(w, 0.008, 0.006), s(4, "frame"))
		elif t == 3 and l > 0:
			_b(k, x, Vector3(p.x, p.y + l * sh - 0.012, p.z + d * 0.5 - 0.01), Vector3(w - 0.06, 0.008, 0.008), lit(s(3, "glow"), 0.4))
	for l in levels:
		var y := p.y + l * sh + 0.025
		var bx := p.x - w * 0.5 + 0.05
		var i := 0
		while bx < p.x + w * 0.5 - 0.08:
			var bw := 0.035 + float((i * 7 + l * 3) % 4) * 0.01
			var bh := sh * (0.62 + float((i * 5 + l) % 4) * 0.08)
			if (i + l) % 6 == 5:
				# a lying stack instead of a book
				_u(k, x, Vector3(bx + 0.05, y, p.z + 0.02), Vector3(0.1, 0.06, 0.2), bk[(i + l) % bk.size()])
				bx += 0.12
			else:
				_u(k, x, Vector3(bx + bw * 0.5, y, p.z + 0.02), Vector3(bw - 0.005, bh, 0.2), bk[(i * 3 + l) % bk.size()])
				bx += bw
			i += 1


## A stack of n papers and books on p (seed varies the colours and twist).
static func _stack(k: MeshKit, x: Transform3D, p: Vector3, n: int, seed: int, bk: Array) -> void:
	for i in n:
		var paper := (i + seed) % 3 == 0
		_r(k, x, p + Vector3(0, 0.025 + i * 0.05, 0), Vector3(0.22, 0.045, 0.3) if not paper else Vector3(0.21, 0.045, 0.29), Vector3(0, float((i * 13 + seed * 7) % 24 - 12), 0), Color(0.96, 0.95, 0.9) if paper else bk[(i + seed) % bk.size()])


## Coolant pumps: a small pump with pipes; a bigger one with a valve wheel;
## two on a manifold with a gauge; a guarded skid with a glowing flow meter,
## insulated pipes and a sign. A pond pump in a tub with garden hoses (0),
## blue pumps with a yellow guard (1), white housings with teal pipes (2),
## dark pumps with blue and red pipes (3), graphite with brass and glowing
## pipes (4).
static func _pumps(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var sup: Color = [Color(0.3, 0.6, 0.36), Color(0.36, 0.6, 0.86), s(2, "accent"), Color(0.36, 0.6, 0.86), s(4, "frame")][t]
	var ret: Color = [Color(0.3, 0.6, 0.36), Color(0.86, 0.42, 0.32), s(2, "shell2"), Color(0.86, 0.42, 0.32), lit(s(4, "accent2"), 0.5)][t]
	if t == 0 and g < 3:
		# a plastic tub with pond pumps and hoses
		var n0 := 1 if g < 2 else 2
		_cy(k, x, Vector3(0, 0, -0.04), 0.3, 0.26, Color(0.26, 0.46, 0.78), 10, 0.33)
		_cy(k, x, Vector3(0, 0.2, -0.04), 0.3, 0.03, Color(0.4, 0.6, 0.66), 10)
		for i in n0:
			var px := 0.0 if n0 == 1 else -0.12 + i * 0.24
			_u(k, x, Vector3(px, 0.23, -0.04), Vector3(0.14 + g * 0.03, 0.1, 0.12), Color(0.18, 0.18, 0.2))
			_run(k, x, [Vector3(px, 0.3, -0.04), Vector3(px + 0.04, 0.4, 0.1), Vector3(px + 0.08, 0.3, 0.28), Vector3(px + 0.2, 0.012, 0.34)], 0.03, sup)
		_cable(k, x, [Vector3(-0.2, 0.28, -0.1), Vector3(-0.34, 0.1, -0.1), Vector3(-0.34, 0.012, 0.2)], 0, 0.016)
		if g >= 1:
			_cy(k, x, Vector3(-0.3, 0, 0.26), 0.07, 0.2, Color(0.64, 0.66, 0.68), 6, 0.08)
		return
	var n := 1 if g < 2 else 2
	var y := _skid(k, x, Vector3(0, 0, 0), 0.74, 0.6, t)
	for i in n:
		var pz := 0.0 if n == 1 else -0.15 + i * 0.32
		var s1 := 0.85 if g == 0 else 1.0
		_pump(k, x * MeshKit.at(0, y, pz), s1, t)
	# pipes: suction from the ground, discharge up and across
	for i in n:
		var pz2 := 0.0 if n == 1 else -0.15 + i * 0.32
		_run(k, x, [Vector3(0.2, y + 0.12, pz2), Vector3(0.34, y + 0.12, pz2), Vector3(0.34, 0.0, pz2)], 0.07, sup)
		_run(k, x, [Vector3(-0.02, y + 0.26, pz2), Vector3(-0.02, y + 0.42, pz2), Vector3(-0.3, y + 0.42, pz2)], 0.06, ret)
	if g >= 1:
		# a valve wheel on the discharge
		k.torus(0.06, 0.01, Color(0.86, 0.3, 0.24) if t < 4 else s(4, "frame"), x * MeshKit.xf(Vector3(-0.16, y + 0.42, 0.0 if n == 1 else 0.17) + Vector3(0, 0.0, 0.05), Vector3(90, 0, 0)), 8, 3)
		_cz(k, x, Vector3(-0.16, y + 0.42, (0.0 if n == 1 else 0.17)), 0.04, 0.05, s(t, "dark"), 6)
	if g >= 2:
		# a header joining them and a gauge
		_seg(k, x, Vector3(-0.3, y + 0.42, -0.3), Vector3(-0.3, y + 0.42, 0.3), 0.08, ret)
		_seg(k, x, Vector3(-0.3, y + 0.42, -0.3), Vector3(-0.3, 0.0, -0.32), 0.07, ret)
		_cz(k, x, Vector3(-0.3, y + 0.52, 0.0), 0.035, 0.02, Color(0.95, 0.95, 0.9) if g < 3 else lit(s(t, "glow"), 0.45), 8)
		_u(k, x, Vector3(-0.3, y + 0.42, 0.0), Vector3(0.015, 0.08, 0.015), s(t, "metal"))
	if g >= 3:
		# a flow meter on a post, a guard rail and a sign
		_u(k, x, Vector3(0.32, 0, 0.3), Vector3(0.03, 0.62, 0.03), s(t, "frame"))
		_shell(k, x, Vector3(0.32, 0.46, 0.3), Vector3(0.14, 0.18, 0.06), t)
		_b(k, x, Vector3(0.32, 0.57, 0.335), Vector3(0.1, 0.06, 0.006), lit(s(t, "glow"), 0.4))
		_sign(k, x, Vector3(0.32, 0.36, 0.316), 0.1, t)
		if t != 0:
			var rc: Color = s(t, "accent") if t != 2 else s(2, "frame")
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(-0.36, y, sz * 0.28), Vector3(0.025, 0.4, 0.025), rc)
			_u(k, x, Vector3(-0.36, y + 0.4, 0), Vector3(0.025, 0.025, 0.58), rc)
			_u(k, x, Vector3(-0.36, y + 0.2, 0), Vector3(0.02, 0.02, 0.58), rc)
		else:
			k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(0.32, 0.7, 0.3), 6, 4)


## One pump at the origin of px: motor along x, volute and flanges.
static func _pump(k: MeshKit, px: Transform3D, sc: float, t: int) -> void:
	var mc: Color = [Color(0.3, 0.5, 0.36), Color(0.26, 0.42, 0.7), s(2, "shell"), Color(0.26, 0.4, 0.34), s(4, "shell")][t]
	var bc: Color = s(t, "frame") if t != 2 else s(2, "shell2")
	k.box(Vector3(0.44, 0.04, 0.2) * sc, bc, px * MeshKit.at(0, 0.02 * sc, 0))
	# motor with cooling fins
	k.cyl(0.09 * sc, 0.26 * sc, mc, px * MeshKit.xf(Vector3(-0.2 * sc, 0.13 * sc, 0), Vector3(0, 0, -90)), 8)
	for i in 4:
		k.box(Vector3(0.012, 0.2, 0.2) * sc, mc.darkened(0.15), px * MeshKit.at((-0.16 + i * 0.05) * sc, 0.13 * sc, 0))
	k.box(Vector3(0.08, 0.06, 0.06) * sc, mc.darkened(0.1), px * MeshKit.at(-0.08 * sc, 0.25 * sc, 0))
	# volute
	k.cyl(0.11 * sc, 0.1 * sc, mc.lightened(0.1) if t != 4 else s(4, "frame"), px * MeshKit.xf(Vector3(0.12 * sc, 0.13 * sc, -0.05 * sc), Vector3(90, 0, 0)), 8)
	k.cyl(0.05 * sc, 0.06 * sc, s(t, "metal"), px * MeshKit.xf(Vector3(0.12 * sc, 0.13 * sc, 0.05 * sc), Vector3(90, 0, 0)), 6)
	if t >= 3:
		k.box(Vector3(0.06, 0.02, 0.006) * sc, lit(s(t, "glow"), 0.4), px * MeshKit.at(-0.08 * sc, 0.25 * sc, 0.031 * sc))


## An ore cart: a heap with a wheelbarrow; a cart on rails; two carts and a
## buffer stop; a chute over the carts and glowing crystals in the ore.
static func _ore(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var oc := col.darkened(0.15)
	var cc: Color = [Color(0.5, 0.38, 0.28), Color(0.42, 0.44, 0.48), s(2, "shell2"), s(3, "shell"), s(4, "shell")][t]
	if g == 0:
		# a heap and a wheelbarrow
		k.cone(0.24, 0.18, oc, x * MeshKit.at(-0.14, 0, -0.12), 7)
		for i in 4:
			_r(k, x, Vector3(-0.3 + i * 0.12, 0.03, 0.02 + (i % 2) * 0.06), Vector3(0.06, 0.05, 0.06), Vector3(i * 20.0, i * 33.0, 0), oc.lightened(0.08 * (i % 2)))
		var wx := x * MeshKit.xf(Vector3(0.14, 0, 0.1), Vector3(0, -25, 0))
		var wc: Color = [Color(0.36, 0.56, 0.38), s(1, "accent"), s(2, "accent"), s(3, "shell"), s(4, "frame")][t]
		k.box(Vector3(0.26, 0.12, 0.34), wc, wx * MeshKit.xf(Vector3(0, 0.2, 0), Vector3(-6, 0, 0)))
		k.ellipsoid(Vector3(0.11, 0.05, 0.14), oc, wx * MeshKit.at(0, 0.27, 0.0), 7, 4)
		k.cyl(0.07, 0.03, Color(0.15, 0.15, 0.16), wx * MeshKit.xf(Vector3(-0.015, 0.07, 0.22), Vector3(0, 0, -90)), 8)
		for sx: float in [-1.0, 1.0]:
			k.box(Vector3(0.02, 0.02, 0.5), s(t, "dark"), wx * MeshKit.at(sx * 0.1, 0.14, -0.06))
			k.box(Vector3(0.02, 0.14, 0.02), s(t, "dark"), wx * MeshKit.at(sx * 0.1, 0.07, -0.14))
		return
	# rails on sleepers
	for i in 5:
		_u(k, x, Vector3(0, 0, -0.32 + i * 0.16), Vector3(0.4, 0.03, 0.06), Pal.WOOD if t < 3 else s(t, "base"))
	for sx: float in [-1.0, 1.0]:
		_u(k, x, Vector3(sx * 0.13, 0.03, 0), Vector3(0.025, 0.03, 0.74), s(t, "metal"))
	var n := 1 if g == 1 else 2
	for i in n:
		var cz := 0.0 if n == 1 else -0.19 + i * 0.38
		_cart(k, x * MeshKit.at(0, 0.06, cz), cc, oc, t, g >= 3)
	if g >= 2:
		# a buffer stop at the end
		_u(k, x, Vector3(0, 0.06, -0.36), Vector3(0.34, 0.16, 0.04), s(t, "accent") if t != 0 else s(0, "frame"))
		_hazard(k, x, Vector3(0, 0.14, -0.34), 0.34, 0.05)
	if g >= 3:
		# a chute coming down from a hopper behind
		var hc: Color = s(t, "frame")
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.3, 0, -0.32), Vector3(0.04, 1.1, 0.04), hc)
		_u(k, x, Vector3(0, 0.92, -0.3), Vector3(0.56, 0.36, 0.14), cc)
		_r(k, x, Vector3(0, 0.78, -0.16), Vector3(0.18, 0.025, 0.3), Vector3(35, 0, 0), s(t, "metal"))
		_b(k, x, Vector3(0, 1.0, -0.229), Vector3(0.3, 0.06, 0.006), lit(s(t, "glow"), 0.35))


## One mine cart on its wheels with a heap of ore (glowing crystals at g3).
static func _cart(k: MeshKit, cx: Transform3D, c: Color, oc: Color, t: int, glow: bool) -> void:
	k.box(Vector3(0.34, 0.2, 0.3), c, cx * MeshKit.at(0, 0.16, 0))
	k.box(Vector3(0.36, 0.03, 0.32), c.darkened(0.2) if t != 4 else s(4, "frame"), cx * MeshKit.at(0, 0.26, 0))
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(0.01, 0.16, 0.02), c.darkened(0.2), cx * MeshKit.at(sx * 0.172, 0.16, 0.0))
		for sz: float in [-1.0, 1.0]:
			k.cyl(0.045, 0.025, Color(0.2, 0.2, 0.22), cx * MeshKit.xf(Vector3(sx * 0.13 - 0.012, 0.045, sz * 0.09), Vector3(0, 0, -90)), 8)
	k.ellipsoid(Vector3(0.15, 0.07, 0.13), oc, cx * MeshKit.at(0, 0.28, 0), 7, 4)
	for i in 3:
		k.box(Vector3(0.06, 0.05, 0.06), oc.lightened(0.1), cx * MeshKit.xf(Vector3(-0.08 + i * 0.08, 0.32, -0.03 + (i % 2) * 0.06), Vector3(i * 30.0, i * 40.0, 0)))
	if glow:
		for i in 3:
			k.cone(0.03, 0.12, lit(oc.lightened(0.4), 0.35), cx * MeshKit.xf(Vector3(-0.06 + i * 0.06, 0.3, 0.0), Vector3(0, 0, -15 + i * 15)), 5)
	if t >= 3:
		k.box(Vector3(0.2, 0.02, 0.006), lit(s(t, "glow"), 0.4), cx * MeshKit.at(0, 0.2, 0.152))


# ================================================================ top parts

## A rooftop condenser: a small unit with a fan; a bigger one with insulated
## pipes into the roof and an isolator; a pair on a rail frame; with a guard
## rail, a glowing panel and a sign. A window unit on bricks (0), then the
## era's casings.
static func _ac(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var cc: Color = Color(0.86, 0.82, 0.72) if t == 0 else (Color(0.88, 0.89, 0.9) if t == 1 else Color(0, 0, 0, 0))
	match g:
		0:
			var y := _rails(k, x, Vector3(0, 0, 0), 0.46, 0.34, t)
			_chill_unit(k, x, Vector3(0, y, 0), Vector3(0.42, 0.28, 0.32), t, 1, cc)
		1:
			var y := _rails(k, x, Vector3(-0.04, 0, 0), 0.56, 0.4, t)
			_chill_unit(k, x, Vector3(-0.04, y, 0), Vector3(0.52, 0.34, 0.36), t, 1, cc)
			_ac_pipes(k, x, Vector3(0.22, y + 0.12, -0.06), t)
		_:
			var y := _rails(k, x, Vector3(0, 0, 0), 0.68, 0.42, t)
			for sx: float in [-1.0, 1.0]:
				_chill_unit(k, x, Vector3(sx * 0.165, y, 0), Vector3(0.3, 0.34, 0.34), t, 1, cc)
			_ac_pipes(k, x, Vector3(0.3, y + 0.12, -0.08), t)
			# a duct between them
			_u(k, x, Vector3(0, y + 0.1, -0.1), Vector3(0.06, 0.12, 0.14), s(t, "metal") if t != 4 else s(4, "frame"))
			if g == 3:
				_shell(k, x, Vector3(-0.3, y, 0.2), Vector3(0.1, 0.16, 0.05), t)
				_b(k, x, Vector3(-0.3, y + 0.1, 0.227), Vector3(0.07, 0.05, 0.004), lit(s(t, "glow"), 0.4))
				_sign(k, x, Vector3(0.18, y + 0.22, 0.17), 0.1, t)
				if t > 0:
					var rc: Color = s(t, "accent") if t != 2 else s(2, "frame")
					for sx: float in [-1.0, 1.0]:
						_u(k, x, Vector3(sx * 0.36, 0, 0.25), Vector3(0.02, 0.5, 0.02), rc)
						_u(k, x, Vector3(sx * 0.36, 0, -0.25), Vector3(0.02, 0.5, 0.02), rc)
						_u(k, x, Vector3(sx * 0.36, 0.48, 0), Vector3(0.02, 0.02, 0.5), rc)
					_u(k, x, Vector3(0, 0.48, -0.25), Vector3(0.72, 0.02, 0.02), rc)
				else:
					k.sphere(0.03, lit(s(0, "glow"), 0.25), x * MeshKit.at(-0.3, y + 0.24, 0.22), 6, 4)


## Bricks (0), or rails / a frame under rooftop gear; returns the height.
static func _rails(k: MeshKit, x: Transform3D, p: Vector3, w: float, d: float, t: int) -> float:
	match t:
		0:
			return _bricks(k, x, p, w, d, 0)
		2:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x, p.y, p.z + sz * (d * 0.5 - 0.04)), Vector3(w, 0.05, 0.05), s(2, "shell2"))
			return 0.05
		4:
			_u(k, x, p, Vector3(w, 0.05, d), s(4, "shell2"))
			_b(k, x, Vector3(p.x, p.y + 0.025, p.z + d * 0.5 + 0.003), Vector3(w - 0.04, 0.01, 0.006), lit(s(4, "glow"), 0.35))
			return 0.05
		_:
			for sz: float in [-1.0, 1.0]:
				_u(k, x, Vector3(p.x, p.y, p.z + sz * (d * 0.5 - 0.04)), Vector3(w, 0.06, 0.04), s(t, "frame"))
				for sx: float in [-1.0, 1.0]:
					_u(k, x, Vector3(p.x + sx * (w * 0.5 - 0.06), p.y, p.z + sz * (d * 0.5 - 0.04)), Vector3(0.08, 0.02, 0.08), Color(0.2, 0.2, 0.22))
			return 0.06


## Insulated refrigerant pipes running from a unit into the roof, and an isolator.
static func _ac_pipes(k: MeshKit, x: Transform3D, a: Vector3, t: int) -> void:
	var pc: Color = [Color(0.2, 0.2, 0.22), Color(0.2, 0.2, 0.22), s(2, "shell2"), Color(0.16, 0.16, 0.18), s(4, "frame")][t]
	for i in 2:
		var pz := a.z + i * 0.06
		_run(k, x, [Vector3(a.x, a.y, pz), Vector3(a.x + 0.05, a.y, pz), Vector3(a.x + 0.05, 0.0, pz)], 0.035 - i * 0.008, pc)
		if t == 0:
			_b(k, x, Vector3(a.x + 0.05, a.y * 0.5, pz), Vector3(0.05, 0.03, 0.05), s(0, "tape"))
	_shell(k, x, Vector3(a.x + 0.02, 0.02, a.z + 0.18), Vector3(0.08, 0.1, 0.05), t)
	_b(k, x, Vector3(a.x + 0.02, 0.08, a.z + 0.21), Vector3(0.02, 0.04, 0.012), s(t, "accent2"))


## A rooftop dish: a small dish on a ballast frame; bigger with its cable; a
## second small dish; a glowing feed, a receiver box and a beacon.
static func _dish_s(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var r: float = [0.18, 0.24, 0.28, 0.28][g]
	var mh := 0.2 + r * 0.6
	var dx0 := -0.06 if g >= 2 else 0.0
	# a non-penetrating mount: a frame weighed down with blocks
	var fc: Color = [s(0, "frame"), s(1, "metal"), s(2, "shell2"), s(3, "frame"), s(4, "frame")][t]
	for sx: float in [-1.0, 1.0]:
		_u(k, x, Vector3(dx0 + sx * 0.14, 0, 0), Vector3(0.04, 0.03, 0.36), fc)
		for sz: float in [-1.0, 1.0]:
			_u(k, x, Vector3(dx0 + sx * 0.14, 0.03, sz * 0.12), Vector3(0.12, 0.06, 0.1), Pal.STONE if t < 4 else s(4, "shell"))
	_u(k, x, Vector3(dx0, 0.03, 0), Vector3(0.32, 0.025, 0.04), fc)
	_seg(k, x, Vector3(dx0, 0.03, -0.1), Vector3(dx0, mh * 0.7, 0), 0.02, fc)
	_u(k, x, Vector3(dx0, 0.03, 0), Vector3(0.04, mh - 0.03, 0.04), s(t, "metal") if t != 4 else s(4, "frame"))
	_dish_head(k, x * MeshKit.xf(Vector3(dx0, mh, 0.02), Vector3(-50, 20, 0)), r, t, g >= 3)
	if g >= 1:
		_cable(k, x, [Vector3(dx0, mh - 0.06, 0.0), Vector3(dx0 + 0.04, 0.04, 0.08), Vector3(0.3, 0.02, 0.12)], t, 0.016)
	if g >= 2:
		_u(k, x, Vector3(0.26, 0, -0.12), Vector3(0.025, 0.24, 0.025), s(t, "metal"))
		_u(k, x, Vector3(0.26, 0, -0.12), Vector3(0.1, 0.04, 0.1), Pal.STONE if t < 4 else s(4, "shell"))
		_dish_head(k, x * MeshKit.xf(Vector3(0.26, 0.24, -0.1), Vector3(-45, -30, 0)), 0.1, t, false)
	if g >= 3:
		_shell(k, x, Vector3(0.24, 0, 0.14), Vector3(0.14, 0.14, 0.08), t)
		_lamp(k, x, Vector3(0.24, 0.1, 0.182), t, Color(0.5, 1.0, 0.6))
		_u(k, x, Vector3(-0.32, 0, -0.18), Vector3(0.02, 0.4, 0.02), s(t, "metal"))
		k.sphere(0.035, lit(Color(1.0, 0.3, 0.25), 0.3), x * MeshKit.at(-0.32, 0.42, -0.18), 6, 4)


## Antennas: a TV aerial (or a whip); two; three on a tripod with guy wires;
## with panel antennas, a cable tray and a glowing beacon.
static func _antenna(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var mc: Color = [s(0, "frame"), s(1, "metal"), s(2, "shell"), s(3, "metal"), s(4, "frame")][t]
	var spots := [Vector3(0.0, 0, 0.0), Vector3(-0.17, 0, 0.08), Vector3(0.17, 0, -0.06)]
	var n := mini(g + 1, 3)
	for i in n:
		var p: Vector3 = spots[i]
		var h: float = [0.8, 0.55, 0.65][i] + g * 0.12
		# a base plate with a ballast block
		_u(k, x, p, Vector3(0.14, 0.03, 0.14), Pal.STONE if t < 4 else s(4, "shell"))
		_u(k, x, p + Vector3(0, 0.03, 0), Vector3(0.06, 0.04, 0.06), s(t, "dark"))
		if t == 0 and i == 0:
			_u(k, x, p, Vector3(0.04, h, 0.04), mc)
			_yagi(k, x * MeshKit.at(p.x, p.y + h - 0.04, p.z), 0.36, t)
		elif t <= 1:
			_cy(k, x, p, 0.015, h, mc, 4)
			_yagi(k, x * MeshKit.xf(p + Vector3(0, h - 0.06, 0), Vector3(0, i * 50.0, 0)), 0.3, t)
		else:
			_cy(k, x, p, 0.02, h, mc, 6)
			if t == 4:
				_cy(k, x, p + Vector3(0, h * 0.5, 0), 0.026, 0.02, s(4, "frame"), 6)
				_u(k, x, p + Vector3(0, 0.07, 0.02), Vector3(0.008, h * 0.6, 0.008), lit(s(4, "glow"), 0.35))
			for j in 2:
				_b(k, x, p + Vector3(0, h * (0.55 + j * 0.25), 0), Vector3(0.14 - j * 0.05, 0.012, 0.012), mc)
		k.sphere(0.025, lit(Color(1.0, 0.3, 0.25), 0.3) if (g >= 3 or i == 0) else mc, x * MeshKit.at(p.x, p.y + h + 0.02, p.z), 6, 4)
	if g >= 2:
		# guy wires on the main mast
		var h0: float = 0.8 + g * 0.12
		for i in 3:
			var a := TAU * (i + 0.25) / 3.0
			_seg(k, x, Vector3(0, h0 * 0.6, 0), Vector3(cos(a) * 0.24, 0.0, sin(a) * 0.22), 0.006, Color(0.8, 0.8, 0.78))
		_cable(k, x, [Vector3(0, 0.07, 0), Vector3(0.0, 0.02, 0.2), Vector3(0.32, 0.02, 0.2)], t, 0.016)
	if g >= 3:
		# two panel antennas on a short frame
		for sx: float in [-1.0, 1.0]:
			var ax := x * MeshKit.xf(Vector3(sx * 0.24, 0.0, 0.18), Vector3(0, sx * 20.0, 0))
			k.box(Vector3(0.03, 0.4, 0.03), mc, ax * MeshKit.at(0, 0.2, -0.04))
			k.box(Vector3(0.1, 0.3, 0.04), s(t, "shell") if t != 4 else s(4, "shell2"), ax * MeshKit.at(0, 0.3, 0.0))
			k.box(Vector3(0.06, 0.008, 0.006), lit(s(t, "glow"), 0.4), ax * MeshKit.at(0, 0.4, 0.022))


## Rooftop solar: one panel on a ballast frame; two; a tidy row of three
## with a combiner; four with a glowing inverter and a walkway.
static func _solar_s(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var n: int = [1, 2, 3, 4][g]
	var w := 0.62 / n if g > 0 else 0.48
	var tilt := 22.0
	for i in n:
		var px := 0.0 if n == 1 else -0.31 + (i + 0.5) * 0.62 / n
		var pz := -0.06
		var fc: Color = [s(0, "frame"), s(1, "metal"), s(2, "shell2"), s(3, "frame"), s(4, "frame")][t]
		if t == 0:
			_u(k, x, Vector3(px, 0, pz - 0.08), Vector3(w * 0.6, 0.14, 0.1), Pal.BRICK)
			_panel(k, x * MeshKit.xf(Vector3(px, 0.08, pz), Vector3(28, 0, 2), Vector3(1, 1, 1)), w - 0.02, 0.32, t, false)
		else:
			for sx: float in [-1.0, 1.0]:
				_seg(k, x, Vector3(px + sx * (w * 0.5 - 0.04), 0.02, pz - 0.12), Vector3(px + sx * (w * 0.5 - 0.04), 0.17, pz - 0.1), 0.02, fc)
				_u(k, x, Vector3(px + sx * (w * 0.5 - 0.04), 0, pz), Vector3(0.03, 0.02, 0.32), fc)
			_u(k, x, Vector3(px, 0.02, pz - 0.12), Vector3(w * 0.7, 0.04, 0.06), Pal.STONE if t < 4 else s(4, "shell"))
			_panel(k, x * MeshKit.xf(Vector3(px, 0.11, pz), Vector3(tilt, 0, 0)), w - 0.02, 0.3, t, g >= 3)
	if g >= 2:
		# a combiner box and the cable run
		_shell(k, x, Vector3(0.28, 0, 0.18), Vector3(0.12, 0.12, 0.06), t)
		_cable(k, x, [Vector3(0.22, 0.04, 0.18), Vector3(-0.3, 0.02, 0.16)], t, 0.016)
	if g >= 3:
		_b(k, x, Vector3(0.28, 0.08, 0.212), Vector3(0.08, 0.03, 0.004), lit(s(t, "glow"), 0.4))
		# a walkway pad along the front
		for i in 4:
			_u(k, x, Vector3(-0.27 + i * 0.13, 0, 0.2), Vector3(0.11, 0.015, 0.1), Pal.STONE if t < 3 else s(t, "base"))


## Vents: a mushroom vent; a turbine vent; three vents and a duct elbow; a
## big exhaust fan housing with glowing louvres.
static func _vent_top(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var vc: Color = [Color(0.64, 0.66, 0.68), s(1, "metal"), s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
	match g:
		0:
			_mush(k, x, Vector3(0, 0, 0), 0.4, vc, t)
		1:
			_mush(k, x, Vector3(-0.18, 0, 0.04), 0.34, vc, t)
			_turbine(k, x, Vector3(0.14, 0, -0.02), vc, t)
		2:
			_mush(k, x, Vector3(-0.24, 0, 0.08), 0.3, vc, t)
			_turbine(k, x, Vector3(0.04, 0, -0.08), vc, t)
			# a duct with an elbow
			_u(k, x, Vector3(0.26, 0, 0.0), Vector3(0.14, 0.32, 0.14), vc.darkened(0.08))
			_u(k, x, Vector3(0.26, 0.32, 0.04), Vector3(0.14, 0.12, 0.22), vc.darkened(0.08))
			_b(k, x, Vector3(0.26, 0.38, 0.152), Vector3(0.12, 0.1, 0.008), s(t, "dark"))
			for i in 3:
				_b(k, x, Vector3(0.26, 0.35 + i * 0.03, 0.157), Vector3(0.12, 0.008, 0.008), vc)
		3:
			# an exhaust fan housing with a hood
			var y := _rails(k, x, Vector3(0, 0, 0), 0.5, 0.42, t)
			_shell(k, x, Vector3(0, y, 0), Vector3(0.44, 0.24, 0.38), t, vc if t == 0 else Color(0, 0, 0, 0))
			_fan(k, x * MeshKit.at(0, y + 0.25, 0), 0.15, t)
			_r(k, x, Vector3(0, y + 0.36, -0.04), Vector3(0.46, 0.02, 0.3), Vector3(-15, 0, 0), vc.darkened(0.1))
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.21, y + 0.24, -0.16), Vector3(0.02, 0.16, 0.02), vc.darkened(0.2))
			for i in 4:
				_b(k, x, Vector3(0, y + 0.05 + i * 0.045, 0.195), Vector3(0.36, 0.015, 0.012), lit(s(t, "glow"), 0.4) if i == 3 else s(t, "dark"))
			_mush(k, x, Vector3(-0.26, 0, 0.15), 0.26, vc, t)


## A mushroom vent standing on p.
static func _mush(k: MeshKit, x: Transform3D, p: Vector3, h: float, c: Color, t: int) -> void:
	_cy(k, x, p, 0.1, 0.03, c.darkened(0.15), 8)
	_cy(k, x, p, 0.06, h, c, 8)
	_cy(k, x, p + Vector3(0, h - 0.08, 0), 0.075, 0.03, c.darkened(0.1), 8)
	k.cone(0.12, 0.1, c.darkened(0.05), x * MeshKit.at(p.x, p.y + h, p.z), 8)
	if t == 0:
		_b(k, x, p + Vector3(0, h * 0.4, 0.062), Vector3(0.08, 0.03, 0.01), s(0, "tape"))
	elif t >= 3:
		_cy(k, x, p + Vector3(0, h * 0.5, 0), 0.063, 0.02, lit(s(t, "glow"), 0.4), 8)


## A whirlybird turbine vent standing on p.
static func _turbine(k: MeshKit, x: Transform3D, p: Vector3, c: Color, t: int) -> void:
	_cy(k, x, p, 0.06, 0.24, c, 8)
	k.sphere(0.12, c.darkened(0.08), x * MeshKit.xf(p + Vector3(0, 0.33, 0), Vector3.ZERO, Vector3(1, 0.9, 1)), 8, 5)
	for i in 6:
		k.box(Vector3(0.012, 0.18, 0.04), c.darkened(0.3), x * MeshKit.xf(p + Vector3(0, 0.33, 0), Vector3(0, i * 30.0, 18)) * MeshKit.at(0.11, 0, 0))
	_cy(k, x, p + Vector3(0, 0.44, 0), 0.02, 0.03, s(t, "dark"), 6)


## A water tank: a barrel (or a small tank); bigger on a stand; with pipes
## and a ladder; with a glowing level gauge.
static func _tank_s(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var tc: Color = [Color(0.26, 0.46, 0.78), s(1, "metal"), s(2, "shell"), s(3, "shell"), s(4, "shell")][t]
	var r: float = [0.15, 0.19, 0.22, 0.22][g]
	var h: float = [0.36, 0.42, 0.48, 0.48][g]
	var sy := 0.0
	if g >= 1:
		sy = 0.14
		var fc: Color = [Pal.BRICK, s(1, "accent"), s(2, "shell2"), s(3, "frame"), s(4, "frame")][t]
		if t == 0:
			for sx: float in [-1.0, 1.0]:
				_u(k, x, Vector3(sx * 0.1, 0, 0), Vector3(0.12, 0.14, 0.26), fc)
		else:
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					_u(k, x, Vector3(sx * r * 0.7, 0, sz * r * 0.7), Vector3(0.03, sy, 0.03), fc)
			_u(k, x, Vector3(0, sy - 0.03, 0), Vector3(r * 1.7, 0.03, r * 1.7), fc)
	if t == 0:
		# a blue plastic barrel with ribs
		_cy(k, x, Vector3(0, sy, 0), r, h, tc, 10)
		for f: float in [0.3, 0.7]:
			k.cyl(r * 1.04, 0.025, tc.darkened(0.15), x * MeshKit.at(0, sy + h * f, 0), 10, 0.0, -1.0, false)
		_cy(k, x, Vector3(0, sy + h, 0), r * 0.9, 0.012, tc.darkened(0.2), 10)
	elif t == 4:
		_cy(k, x, Vector3(0, sy, 0), r, h * 0.7, tc, 10)
		k.sphere(r, tc, x * MeshKit.xf(Vector3(0, sy + h * 0.7, 0), Vector3.ZERO, Vector3(1, 0.7, 1)), 10, 5)
		for f: float in [0.2, 0.5]:
			k.cyl(r * 1.03, 0.02, s(4, "frame"), x * MeshKit.at(0, sy + h * f, 0), 10, 0.0, -1.0, false)
	else:
		_cy(k, x, Vector3(0, sy, 0), r, h, tc, 10)
		k.cone(r + 0.01, 0.08, tc.darkened(0.12), x * MeshKit.at(0, sy + h, 0), 10)
		for f: float in [0.33, 0.66]:
			k.cyl(r * 1.03, 0.02, tc.darkened(0.15) if t != 2 else s(2, "accent"), x * MeshKit.at(0, sy + h * f, 0), 10, 0.0, -1.0, false)
	_cy(k, x, Vector3(0.05, sy + h + (0.04 if t != 0 else 0.0), 0.04), 0.025, 0.04, s(t, "dark"), 6)
	if g >= 2:
		# pipes down to the roof and a ladder
		var pc: Color = [Color(0.6, 0.62, 0.64), s(1, "metal"), s(2, "shell2"), s(3, "metal"), s(4, "frame")][t]
		_run(k, x, [Vector3(r * 0.8, sy + 0.06, 0.06), Vector3(0.3, sy + 0.06, 0.06), Vector3(0.3, 0.0, 0.06)], 0.035, pc)
		_run(k, x, [Vector3(-r * 0.8, sy + 0.1, -0.06), Vector3(-0.3, sy + 0.1, -0.06), Vector3(-0.3, 0.0, -0.06)], 0.03, pc)
		for sx: float in [-1.0, 1.0]:
			_u(k, x, Vector3(sx * 0.06, 0, r + 0.04), Vector3(0.015, sy + h, 0.015), pc)
		for i in 4:
			_u(k, x, Vector3(0, 0.08 + i * (sy + h - 0.1) / 4.0, r + 0.04), Vector3(0.12, 0.012, 0.012), pc)
	if g >= 3:
		# a level gauge
		_b(k, x, Vector3(-r * 0.6, sy + h * 0.5, r * 0.82), Vector3(0.03, h * 0.7, 0.01), s(t, "dark"))
		_b(k, x, Vector3(-r * 0.6, sy + h * 0.4, r * 0.82 + 0.006), Vector3(0.018, h * 0.45, 0.006), lit(s(t, "glow") if t != 0 else Color(0.5, 0.86, 1.0), 0.4))


## A beacon: a short pole with a light; taller on a bracket; a tripod mast
## with two lights; a rotating beacon with a glowing ring, a strobe and a
## lightning rod.
static func _beacon_part(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	var h: float = [0.3, 0.45, 0.6, 0.7][g]
	var pc: Color = [s(0, "frame"), s(1, "metal"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
	var bc: Color = Color(1.0, 0.35, 0.3) if t < 3 else s(t, "glow")
	_u(k, x, Vector3(0, 0, 0), Vector3(0.14, 0.03, 0.14), Pal.STONE if t < 4 else s(4, "shell"))
	if g >= 2:
		for i in 3:
			var a := TAU * (i + 0.25) / 3.0
			_seg(k, x, Vector3(cos(a) * 0.16, 0, sin(a) * 0.16), Vector3(0, h * 0.7, 0), 0.02, pc)
			_u(k, x, Vector3(cos(a) * 0.16, 0, sin(a) * 0.16), Vector3(0.06, 0.03, 0.06), Pal.STONE if t < 4 else s(4, "shell"))
	_cy(k, x, Vector3(0, 0.03, 0), 0.022, h - 0.03, pc, 6)
	if g < 3:
		k.sphere(0.05 + g * 0.012, lit(bc, 0.3), x * MeshKit.at(0, h + 0.04, 0), 8, 5)
		_cy(k, x, Vector3(0, h - 0.01, 0), 0.04, 0.02, s(t, "dark"), 6)
	else:
		# a rotating beacon housing
		_cy(k, x, Vector3(0, h, 0), 0.08, 0.05, s(t, "dark"), 8)
		_cy(k, x, Vector3(0, h + 0.05, 0), 0.07, 0.1, lit(bc, 0.35), 8)
		_cy(k, x, Vector3(0, h + 0.15, 0), 0.08, 0.025, s(t, "dark"), 8)
		k.torus(0.13, 0.01, lit(bc, 0.3), x * MeshKit.at(0, h + 0.1, 0), 12, 3)
		_cy(k, x, Vector3(0, h + 0.175, 0), 0.008, 0.25, s(t, "metal"), 4)
	if g >= 1:
		# a bracket with a second light
		_b(k, x, Vector3(0.07, h * 0.55, 0), Vector3(0.14, 0.02, 0.02), pc)
		_cy(k, x, Vector3(0.14, h * 0.55, 0), 0.025, 0.03, s(t, "dark"), 6)
		k.sphere(0.03, lit(bc, 0.35), x * MeshKit.at(0.14, h * 0.55 + 0.05, 0), 6, 4)
		_cable(k, x, [Vector3(0, 0.05, 0.02), Vector3(0.0, 0.02, 0.16), Vector3(0.24, 0.02, 0.16)], t, 0.012)
	if g >= 2:
		_b(k, x, Vector3(-0.07, h * 0.4, 0), Vector3(0.14, 0.02, 0.02), pc)
		k.sphere(0.03, lit(bc, 0.35), x * MeshKit.at(-0.14, h * 0.4 + 0.03, 0), 6, 4)


## A rooftop sign: a small board; bigger on a frame; big with spotlights;
## lit, with a glowing logo, letters and a catwalk.
static func _sign_top(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var w: float = [0.5, 0.6, 0.68, 0.72][g]
	var h: float = [0.22, 0.28, 0.32, 0.34][g]
	var y := 0.16 + g * 0.04
	var fc: Color = [s(0, "frame"), s(1, "frame"), s(2, "shell2"), s(3, "frame"), s(4, "frame")][t]
	# frame legs and braces behind
	for sx: float in [-1.0, 1.0]:
		_u(k, x, Vector3(sx * w * 0.36, 0, -0.04), Vector3(0.03, y + h, 0.03), fc)
		_seg(k, x, Vector3(sx * w * 0.36, 0, -0.22), Vector3(sx * w * 0.36, y + h * 0.7, -0.05), 0.02, fc)
		_u(k, x, Vector3(sx * w * 0.36, 0, -0.13), Vector3(0.05, 0.03, 0.22), fc)
	var bc: Color = [s(0, "card"), s(1, "accent"), s(2, "shell"), s(3, "dark"), s(4, "dark")][t]
	_u(k, x, Vector3(0, y, 0), Vector3(w, h, 0.04), bc)
	var fz := 0.021
	match t:
		0:
			# hand-painted
			_r(k, x, Vector3(-w * 0.28, y + h * 0.5, fz + 0.002), Vector3(h * 0.6, h * 0.6, 0.004), Vector3(0, 0, 8), col)
			for i in 2:
				_b(k, x, Vector3(w * 0.1, y + h * (0.62 - i * 0.26), fz + 0.002), Vector3(w * (0.45 - i * 0.12), 0.03, 0.004), Color(0.16, 0.14, 0.13))
		1:
			_b(k, x, Vector3(0, y + h * 0.5, fz + 0.002), Vector3(w - 0.04, h - 0.04, 0.004), s(1, "dark"))
			_b(k, x, Vector3(-w * 0.3, y + h * 0.5, fz + 0.005), Vector3(h * 0.5, h * 0.5, 0.004), col)
			_b(k, x, Vector3(w * 0.1, y + h * 0.5, fz + 0.005), Vector3(w * 0.45, 0.04, 0.004), s(1, "accent"))
		2:
			_b(k, x, Vector3(-w * 0.3, y + h * 0.5, fz + 0.002), Vector3(h * 0.6, h * 0.6, 0.004), s(2, "accent") if g < 3 else lit(col, 0.5))
			_b(k, x, Vector3(w * 0.1, y + h * 0.5, fz + 0.002), Vector3(w * 0.45, 0.045, 0.004), s(2, "dark"))
			_b(k, x, Vector3(0, y + 0.012, fz + 0.002), Vector3(w, 0.024, 0.004), s(2, "accent"))
		_:
			_b(k, x, Vector3(-w * 0.3, y + h * 0.5, fz + 0.002), Vector3(h * 0.6, h * 0.6, 0.004), lit(col, 0.5) if g >= 2 else col)
			for i in 4:
				_b(k, x, Vector3(-w * 0.08 + i * w * 0.11, y + h * 0.5, fz + 0.002), Vector3(w * 0.08, h * 0.45, 0.004), lit(s(t, "glow"), 0.4) if g >= 3 else s(t, "shell2"))
			if t == 4:
				_b(k, x, Vector3(0, y + h + 0.01, 0), Vector3(w + 0.02, 0.02, 0.05), s(4, "frame"))
				_b(k, x, Vector3(0, y - 0.01, 0), Vector3(w + 0.02, 0.02, 0.05), s(4, "frame"))
	# era details: planks and drips (0), bolts and a hazard foot (1), a teal
	# top band (2), a cage frame (3), brass end caps (4)
	match t:
		0:
			for i in 2:
				_b(k, x, Vector3(0, y + h * (0.33 + i * 0.33), fz + 0.001), Vector3(w - 0.02, 0.008, 0.004), bc.darkened(0.2))
			_r(k, x, Vector3(-w * 0.1, y + 0.02, fz + 0.003), Vector3(0.012, 0.06, 0.004), Vector3(0, 0, 4), col)
		1:
			for sx: float in [-1.0, 1.0]:
				for sy: float in [0.04, h - 0.04]:
					_b(k, x, Vector3(sx * (w * 0.5 - 0.03), y + sy, fz + 0.005), Vector3(0.018, 0.018, 0.006), s(1, "metal"))
			_hazard(k, x, Vector3(0, y - 0.03, -0.02), w, 0.04)
		2:
			_b(k, x, Vector3(0, y + h + 0.012, 0), Vector3(w + 0.02, 0.024, 0.05), s(2, "accent"))
		3:
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(sx * (w * 0.5 + 0.015), y + h * 0.5, 0), Vector3(0.03, h + 0.04, 0.06), s(3, "frame"))
		4:
			for sx: float in [-1.0, 1.0]:
				_b(k, x, Vector3(sx * (w * 0.5 + 0.01), y + h * 0.5, 0), Vector3(0.02, h + 0.04, 0.05), s(4, "frame"))
	if g >= 1:
		# block letters along the board
		var lc: Color = [Color(0.16, 0.14, 0.13), s(1, "dark"), s(2, "dark"), s(3, "shell2"), s(4, "frame")][t]
		if t >= 3 and g >= 3:
			lc = lit(s(t, "glow"), 0.4)
		for i in 3 + g:
			if t >= 3:
				break
			_b(k, x, Vector3(-w * 0.05 + i * 0.07, y + h * 0.25, fz + 0.004), Vector3(0.05, 0.05, 0.006), lc)
	if g >= 2:
		# spotlights on arms over the top
		for sx: float in [-1.0, 0.0, 1.0]:
			_seg(k, x, Vector3(sx * w * 0.35, y + h, 0.0), Vector3(sx * w * 0.35, y + h + 0.06, 0.12), 0.015, fc)
			_r(k, x, Vector3(sx * w * 0.35, y + h + 0.06, 0.13), Vector3(0.05, 0.04, 0.06), Vector3(-40, 0, 0), s(t, "dark"))
			if g >= 3:
				_r(k, x, Vector3(sx * w * 0.35, y + h + 0.04, 0.145), Vector3(0.035, 0.008, 0.035), Vector3(-40, 0, 0), lit(Color(1.0, 0.96, 0.86), 0.3))
	if g >= 3:
		# a catwalk grating behind
		_u(k, x, Vector3(0, y - 0.03, -0.12), Vector3(w, 0.02, 0.14), s(t, "metal") if t != 4 else s(4, "frame"))
		for i in 4:
			_b(k, x, Vector3(-w * 0.375 + i * w * 0.25, y - 0.015, -0.12), Vector3(0.01, 0.006, 0.13), s(t, "dark"))
		_u(k, x, Vector3(0, y + 0.18, -0.19), Vector3(w, 0.015, 0.015), s(t, "accent") if t == 1 or t == 3 else fc)


# ================================================================ wall parts

## A dashboard: one screen; a wide dashboard with charts; two screens with
## a camera and a sound bar; a 2x2 video wall in a glowing frame. An old TV
## on a shelf (0), a monitor on a steel arm (1), slim white frames (2),
## rugged dark frames (3), graphite with brass (4).
static func _screen(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	if t == 0 and g == 0:
		# an old TV on a shelf bracket with rabbit ears
		_b(k, x, Vector3(0, -0.2, 0.12), Vector3(0.42, 0.025, 0.24), s(0, "base"))
		for sx: float in [-1.0, 1.0]:
			_r(k, x, Vector3(sx * 0.16, -0.26, 0.06), Vector3(0.025, 0.14, 0.025), Vector3(-40, 0, 0), s(0, "frame"))
		_u(k, x, Vector3(0, -0.19, 0.12), Vector3(0.32, 0.26, 0.2), Color(0.42, 0.34, 0.28))
		_b(k, x, Vector3(-0.03, -0.06, 0.222), Vector3(0.22, 0.18, 0.01), Color(0.24, 0.3, 0.3))
		_b(k, x, Vector3(0.12, -0.04, 0.222), Vector3(0.03, 0.03, 0.01), Color(0.7, 0.66, 0.6))
		_b(k, x, Vector3(0.12, -0.1, 0.222), Vector3(0.03, 0.03, 0.01), Color(0.7, 0.66, 0.6))
		for sx: float in [-1.0, 1.0]:
			_seg(k, x, Vector3(0, 0.07, 0.12), Vector3(sx * 0.12, 0.25, 0.1), 0.008, Color(0.7, 0.72, 0.74))
		_cable(k, x, [Vector3(0.14, -0.18, 0.04), Vector3(0.24, -0.3, 0.03), Vector3(0.26, -0.45, 0.03)], 0, 0.014)
		return
	var fc: Color = [s(0, "frame"), s(1, "frame"), s(2, "shell"), s(3, "frame"), s(4, "shell")][t]
	var on := lit(Color(0.36, 0.7, 0.96) if t != 4 else s(4, "accent2"), 0.5)
	match g:
		0:
			if t == 1:
				# a monitor on an arm
				_b(k, x, Vector3(0, 0, 0.01), Vector3(0.08, 0.12, 0.02), s(1, "frame"))
				_b(k, x, Vector3(0, 0, 0.06), Vector3(0.04, 0.04, 0.1), s(1, "metal"))
			var sz := 0.1 if t == 1 else 0.0
			_screen_unit(k, x, Vector3(0, 0, sz), 0.46, 0.3, t, Color(0.2, 0.32, 0.42), false)
			_b(k, x, Vector3(0.2, -0.16, sz + 0.054), Vector3(0.015, 0.008, 0.004), lit(Color(0.5, 1.0, 0.6), 0.35))
			_cable(k, x, [Vector3(0.12, -0.14, 0.01), Vector3(0.14, -0.3, 0.012), Vector3(0.14, -0.5, 0.012)], t, 0.014)
			match t:
				1:
					_r(k, x, Vector3(-0.2, 0.13, sz + 0.056), Vector3(0.06, 0.06, 0.003), Vector3(0, 0, 8), Color(0.98, 0.9, 0.4))
				2:
					_b(k, x, Vector3(0, 0.18, 0.04), Vector3(0.06, 0.025, 0.04), s(2, "shell"))
					_b(k, x, Vector3(0, 0.18, 0.062), Vector3(0.015, 0.015, 0.004), s(2, "dark"))
					_b(k, x, Vector3(0, -0.24, 0.04), Vector3(0.3, 0.015, 0.08), s(2, "shell"))
				3:
					for i in 3:
						_b(k, x, Vector3(-0.15 + i * 0.15, 0, 0.065), Vector3(0.012, 0.34, 0.012), s(3, "frame"))
					_b(k, x, Vector3(0.25, 0.12, 0.03), Vector3(0.04, 0.08, 0.04), s(3, "accent"))
				4:
					for sx: float in [-1.0, 1.0]:
						_b(k, x, Vector3(sx * 0.25, 0, 0.03), Vector3(0.012, 0.36, 0.05), s(4, "frame"))
					_b(k, x, Vector3(0, -0.2, 0.03), Vector3(0.3, 0.008, 0.012), lit(s(4, "glow"), 0.35))
		1:
			_screen_unit(k, x, Vector3(0, 0, 0.0), 0.8, 0.42, t, on, true)
		2:
			for sx: float in [-1.0, 1.0]:
				_screen_unit(k, x, Vector3(sx * 0.235, 0.02, 0.0), 0.43, 0.32, t, on, true)
			# a sound bar and a camera
			_b(k, x, Vector3(0, -0.24, 0.04), Vector3(0.6, 0.06, 0.07), s(t, "dark"))
			for i in 6:
				_b(k, x, Vector3(-0.25 + i * 0.1, -0.24, 0.077), Vector3(0.06, 0.03, 0.004), s(t, "shell2") if t != 2 else s(2, "frame"))
			_b(k, x, Vector3(0, 0.24, 0.03), Vector3(0.08, 0.04, 0.06), s(t, "dark"))
			_b(k, x, Vector3(0, 0.24, 0.062), Vector3(0.025, 0.025, 0.004), Color(0.3, 0.5, 0.9))
		3:
			# a 2x2 video wall in a frame
			_b(k, x, Vector3(0, 0.0, 0.015), Vector3(0.98, 0.66, 0.03), fc)
			for i in 2:
				for j in 2:
					_screen_unit(k, x, Vector3(-0.24 + i * 0.48, -0.16 + j * 0.32, 0.03), 0.46, 0.3, t, on if (i + j) % 2 == 0 else lit(Color(0.4, 0.9, 0.7) if t != 4 else s(4, "glow"), 0.5), true, i + j * 2)
			_b(k, x, Vector3(0, -0.345, 0.05), Vector3(0.98, 0.02, 0.02), lit(s(t, "glow"), 0.35))
			_b(k, x, Vector3(0, 0.345, 0.05), Vector3(0.98, 0.02, 0.02), lit(s(t, "glow"), 0.35))
			_lamp(k, x, Vector3(0.44, 0.38, 0.03), t, Color(0.5, 1.0, 0.6))
			_lamp(k, x, Vector3(0.4, 0.38, 0.03), t, Color(1.0, 0.8, 0.3))


## One screen centred at p (face +z): bezel, picture and its content.
static func _screen_unit(k: MeshKit, x: Transform3D, p: Vector3, w: float, h: float, t: int, pic: Color, content: bool, seed := 0) -> void:
	var fc: Color = [s(0, "frame"), s(1, "dark"), s(2, "shell"), s(3, "frame"), s(4, "shell")][t]
	_b(k, x, p + Vector3(0, 0, 0.025), Vector3(w + 0.04, h + 0.04, 0.05), fc)
	_b(k, x, p + Vector3(0, 0, 0.052), Vector3(w - 0.01, h - 0.01, 0.006), pic)
	match t:
		1:
			for sx: float in [-1.0, 1.0]:
				for sy: float in [-1.0, 1.0]:
					_b(k, x, p + Vector3(sx * (w * 0.5 + 0.005), sy * (h * 0.5 + 0.005), 0.052), Vector3(0.02, 0.02, 0.008), s(1, "metal"))
		2:
			_b(k, x, p + Vector3(0, -h * 0.5 - 0.012, 0.052), Vector3(w * 0.3, 0.012, 0.006), s(2, "accent"))
		3:
			for sy: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(0, sy * (h * 0.5 + 0.03), 0.04), Vector3(w + 0.08, 0.025, 0.08), s(3, "shell"))
		4:
			_b(k, x, p + Vector3(0, h * 0.5 + 0.02, 0.05), Vector3(w + 0.04, 0.012, 0.01), s(4, "frame"))
			_b(k, x, p + Vector3(0, -h * 0.5 - 0.02, 0.05), Vector3(w + 0.04, 0.012, 0.01), s(4, "frame"))
	if content:
		# a header, a bar chart and a line of numbers
		_b(k, x, p + Vector3(0, h * 0.38, 0.057), Vector3(w * 0.85, h * 0.08, 0.004), Color(1, 1, 1, 0.5))
		var n := 5 if w > 0.6 else 4
		for i in n:
			var bh := h * (0.15 + float((i * 37 + seed * 11) % 5) * 0.08)
			_b(k, x, p + Vector3(-w * 0.4 + 0.04 + i * w * 0.1, -h * 0.4 + bh * 0.5, 0.057), Vector3(w * 0.06, bh, 0.004), Color(1.0, 0.86, 0.5, 0.45))
		_b(k, x, p + Vector3(w * 0.25, -h * 0.05, 0.057), Vector3(w * 0.3, h * 0.3, 0.004), Color(0.1, 0.12, 0.16, 0.6))
		_r(k, x, p + Vector3(w * 0.25, -h * 0.05, 0.06), Vector3(w * 0.3, 0.012, 0.003), Vector3(0, 0, 18), Color(0.5, 1.0, 0.6, 0.45))


## LED strips: a short strip; a long one; two rows with a driver box; two
## rows with a glowing marquee frame. Fairy lights on nails (0), a caged
## work-light bar (1), a white channel with a teal diffuser (2), blue LED
## bars on dark rails (3), brass rails with a gold glow (4).
static func _ledbar(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	var w: float = [0.45, 0.75, 0.9, 0.9][g]
	var rows := 1 if g < 2 else 2
	for r in rows:
		var y := 0.0 - r * 0.16
		var lc := lit(s(t, "glow") if r == 0 else (col if t != 4 else s(4, "accent2")), 0.4)
		_strip(k, x, Vector3(0, y, 0), w, t, lc)
	if g == 1:
		_cable(k, x, [Vector3(w * 0.5, 0.0, 0.02), Vector3(w * 0.5 + 0.03, -0.1, 0.02), Vector3(w * 0.5 + 0.03, -0.32, 0.02)], t, 0.012)
		_shell(k, x, Vector3(w * 0.5 + 0.03, -0.42, 0.04), Vector3(0.07, 0.1, 0.04), t)
	if g >= 2:
		# a driver box with a cable
		_shell(k, x, Vector3(w * 0.5 - 0.08, -0.42, 0.05), Vector3(0.12, 0.1, 0.05), t)
		_cable(k, x, [Vector3(w * 0.5 - 0.06, -0.32, 0.025), Vector3(w * 0.5 - 0.06, -0.18, 0.025)], t, 0.014)
	if g >= 3:
		# a marquee frame around the strips
		var fc: Color = [s(0, "frame"), s(1, "frame"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
		_b(k, x, Vector3(0, 0.12, 0.02), Vector3(w + 0.04, 0.04, 0.04), fc)
		_b(k, x, Vector3(0, -0.3, 0.02), Vector3(w + 0.04, 0.04, 0.04), fc)
		for sx: float in [-1.0, 1.0]:
			_b(k, x, Vector3(sx * (w * 0.5 + 0.02), -0.09, 0.02), Vector3(0.04, 0.46, 0.04), fc)
		for i in 9:
			var bx := -w * 0.45 + i * w * 0.9 / 8.0
			_b(k, x, Vector3(bx, 0.12, 0.045), Vector3(0.025, 0.025, 0.012), lit(s(t, "glow"), 0.3))
			_b(k, x, Vector3(bx, -0.3, 0.045), Vector3(0.025, 0.025, 0.012), lit(s(t, "glow"), 0.3))


## One light strip centred at p on the wall.
static func _strip(k: MeshKit, x: Transform3D, p: Vector3, w: float, t: int, lc: Color) -> void:
	match t:
		0:
			# fairy lights sagging between nails
			var n := int(w / 0.07)
			for sx: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(sx * w * 0.5, 0.02, 0.01), Vector3(0.012, 0.012, 0.02), Color(0.4, 0.42, 0.44))
			var pts := []
			for i in n + 1:
				var f := float(i) / n
				pts.append(p + Vector3(-w * 0.5 + w * f, 0.02 - sin(f * PI) * 0.05, 0.015))
			_run(k, x, pts, 0.008, Color(0.16, 0.16, 0.17))
			for i in range(1, n):
				var q: Vector3 = pts[i]
				_b(k, x, q + Vector3(0, -0.02, 0.006), Vector3(0.02, 0.03, 0.02), lit([s(0, "glow"), Color(1.0, 0.5, 0.4), Color(0.5, 0.8, 1.0), Color(0.6, 1.0, 0.6)][i % 4], 0.3))
		1:
			_b(k, x, p + Vector3(0, 0, 0.03), Vector3(w, 0.07, 0.05), s(1, "frame"))
			_b(k, x, p + Vector3(0, 0, 0.057), Vector3(w - 0.06, 0.04, 0.006), lc)
			for i in int(w / 0.12):
				_b(k, x, p + Vector3(-w * 0.5 + 0.06 + i * 0.12, 0, 0.064), Vector3(0.01, 0.07, 0.01), s(1, "metal"))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(sx * w * 0.5, 0, 0.03), Vector3(0.04, 0.09, 0.06), s(1, "accent"))
		2:
			_b(k, x, p + Vector3(0, 0, 0.015), Vector3(w, 0.05, 0.03), s(2, "shell"))
			_b(k, x, p + Vector3(0, 0, 0.032), Vector3(w - 0.02, 0.025, 0.006), lc)
			for sx: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(sx * w * 0.5, 0, 0.016), Vector3(0.012, 0.055, 0.034), s(2, "accent"))
			for i in int(w / 0.15):
				_b(k, x, p + Vector3(-w * 0.5 + 0.1 + i * 0.15, 0, 0.032), Vector3(0.012, 0.06, 0.036), s(2, "shell2"))
		3:
			for i in int(w / 0.3) + 1:
				_b(k, x, p + Vector3(-w * 0.5 + 0.04 + i * (w - 0.08) / maxf(1, int(w / 0.3)), 0, 0.03), Vector3(0.03, 0.1, 0.06), s(3, "frame"))
			_b(k, x, p + Vector3(0, 0, 0.05), Vector3(w, 0.06, 0.04), s(3, "shell2"))
			_b(k, x, p + Vector3(0, -0.012, 0.072), Vector3(w - 0.03, 0.02, 0.006), lc)
			_b(k, x, p + Vector3(0, 0.018, 0.072), Vector3(w - 0.03, 0.008, 0.006), s(3, "dark"))
		4:
			_b(k, x, p + Vector3(0, 0.03, 0.03), Vector3(w, 0.015, 0.06), s(4, "frame"))
			_b(k, x, p + Vector3(0, -0.03, 0.03), Vector3(w, 0.015, 0.06), s(4, "frame"))
			_b(k, x, p + Vector3(0, 0, 0.02), Vector3(w - 0.02, 0.045, 0.03), s(4, "shell"))
			_b(k, x, p + Vector3(0, 0, 0.04), Vector3(w - 0.04, 0.02, 0.006), lc)
			for i in int(w / 0.15):
				_b(k, x, p + Vector3(-w * 0.5 + 0.08 + i * 0.15, 0, 0.045), Vector3(0.012, 0.05, 0.03), s(4, "frame"))


## A sign on the wall: a poster; a framed print with a lamp over it; a neon
## sign; the neon on a backboard in a frame with spotlights. A taped poster
## and hand-painted plywood (0), a bolted enamel sign (1), a white lightbox
## (2), a dark backlit panel (3), a brass frame with a hologram ring (4).
static func _neon(k: MeshKit, g: int, t: int, x: Transform3D, col: Color) -> void:
	match g:
		0:
			match t:
				0:
					_r(k, x, Vector3(0, 0, 0.006), Vector3(0.34, 0.46, 0.008), Vector3(0, 0, 3), Color(0.96, 0.94, 0.88))
					_r(k, x, Vector3(0, 0.06, 0.012), Vector3(0.22, 0.2, 0.004), Vector3(0, 0, 3), col)
					for i in 3:
						_r(k, x, Vector3(0, -0.12 - i * 0.04, 0.012), Vector3(0.24 - i * 0.04, 0.015, 0.004), Vector3(0, 0, 3), Color(0.16, 0.14, 0.13))
					for sx: float in [-1.0, 1.0]:
						_r(k, x, Vector3(sx * 0.16, 0.22, 0.013), Vector3(0.08, 0.025, 0.004), Vector3(0, 0, sx * 40.0), s(0, "tape"))
				_:
					_sign_board(k, x, Vector3.ZERO, 0.4, 0.4, t, col, false)
		1:
			_sign_board(k, x, Vector3.ZERO, 0.6, 0.5, t, col, false)
			# a picture lamp over it
			_b(k, x, Vector3(0, 0.33, 0.02), Vector3(0.04, 0.04, 0.04), s(t, "dark") if t != 4 else s(4, "frame"))
			_seg(k, x, Vector3(0, 0.33, 0.03), Vector3(0, 0.36, 0.14), 0.015, s(t, "dark") if t != 4 else s(4, "frame"))
			_b(k, x, Vector3(0, 0.34, 0.15), Vector3(0.24, 0.035, 0.05), s(t, "dark") if t != 4 else s(4, "frame"))
			_b(k, x, Vector3(0, 0.32, 0.15), Vector3(0.2, 0.008, 0.03), lit(Color(1.0, 0.95, 0.85), 0.3))
		_:
			if g == 3:
				_sign_board(k, x, Vector3.ZERO, 0.8, 0.7, t, col, true)
			if g == 2:
				_neon_mount(k, x, t)
			_neon_tubes(k, x * MeshKit.at(0, 0, 0.06 if g == 3 else 0.03), t, col, g == 3)
			if g == 3:
				for sx: float in [-1.0, 1.0]:
					_seg(k, x, Vector3(sx * 0.3, 0.36, 0.02), Vector3(sx * 0.26, 0.42, 0.16), 0.015, s(t, "dark") if t != 4 else s(4, "frame"))
					_r(k, x, Vector3(sx * 0.26, 0.42, 0.17), Vector3(0.06, 0.05, 0.06), Vector3(-50, 0, 0), s(t, "dark"))


## What a bare neon hangs on: a plywood cut-out on chains (0), a bolted
## steel mesh (1), a clear acrylic panel on standoffs (2), dark rails (3), a
## brass ring and bar (4).
static func _neon_mount(k: MeshKit, x: Transform3D, t: int) -> void:
	match t:
		0:
			_r(k, x, Vector3(0.02, -0.02, 0.012), Vector3(0.62, 0.46, 0.02), Vector3(0, 0, -2), s(0, "shell"))
			for sx: float in [-1.0, 1.0]:
				_seg(k, x, Vector3(sx * 0.26, 0.21, 0.02), Vector3(sx * 0.18, 0.36, 0.01), 0.012, Color(0.5, 0.52, 0.55))
				_b(k, x, Vector3(sx * 0.18, 0.37, 0.01), Vector3(0.02, 0.02, 0.02), Color(0.4, 0.42, 0.44))
			_cable(k, x, [Vector3(0.28, -0.24, 0.02), Vector3(0.3, -0.5, 0.02)], 0, 0.014)
		1:
			_b(k, x, Vector3(0, -0.02, 0.008), Vector3(0.64, 0.48, 0.016), s(1, "frame"))
			for i in 5:
				_b(k, x, Vector3(-0.24 + i * 0.12, -0.02, 0.02), Vector3(0.008, 0.44, 0.008), s(1, "metal"))
			for sx: float in [-1.0, 1.0]:
				for sy: float in [-1.0, 1.0]:
					_b(k, x, Vector3(sx * 0.3, -0.02 + sy * 0.22, 0.02), Vector3(0.025, 0.025, 0.012), s(1, "accent"))
		2:
			_b(k, x, Vector3(0, -0.02, 0.022), Vector3(0.64, 0.46, 0.012), Color(0.84, 0.9, 0.93))
			for sx: float in [-1.0, 1.0]:
				for sy: float in [-1.0, 1.0]:
					_cz(k, x, Vector3(sx * 0.29, -0.02 + sy * 0.2, 0.0), 0.015, 0.035, s(2, "frame"), 6)
		3:
			for sy: float in [-1.0, 1.0]:
				_b(k, x, Vector3(0, -0.02 + sy * 0.18, 0.015), Vector3(0.66, 0.035, 0.03), s(3, "frame"))
			_b(k, x, Vector3(0.3, -0.26, 0.02), Vector3(0.1, 0.08, 0.04), s(3, "shell"))
			_b(k, x, Vector3(0.3, -0.26, 0.042), Vector3(0.04, 0.012, 0.004), lit(s(3, "glow"), 0.4))
		4:
			k.torus(0.22, 0.016, s(4, "frame"), x * MeshKit.xf(Vector3(-0.12, 0.08, 0.02), Vector3(90, 0, 0)), 14, 3)
			_b(k, x, Vector3(0.0, -0.22, 0.02), Vector3(0.62, 0.025, 0.03), s(4, "frame"))
			_b(k, x, Vector3(0.0, -0.22, 0.037), Vector3(0.58, 0.008, 0.004), lit(s(4, "glow"), 0.35))


## A sign board centred at p: the era's plaque with a logo and lines.
static func _sign_board(k: MeshKit, x: Transform3D, p: Vector3, w: float, h: float, t: int, col: Color, dark: bool) -> void:
	match t:
		0:
			_b(k, x, p + Vector3(0, 0, 0.01), Vector3(w, h, 0.02), s(0, "shell"))
			for i in 2:
				_b(k, x, p + Vector3(0, -h * 0.17 + i * h * 0.33, 0.021), Vector3(w - 0.02, 0.008, 0.004), s(0, "shell").darkened(0.22))
			if not dark:
				_b(k, x, p + Vector3(-w * 0.2, h * 0.12, 0.022), Vector3(w * 0.3, w * 0.3, 0.004), col)
				_b(k, x, p + Vector3(w * 0.15, -h * 0.25, 0.022), Vector3(w * 0.5, 0.03, 0.004), Color(0.16, 0.14, 0.13))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(sx * w * 0.42, h * 0.42, 0.024), Vector3(0.015, 0.015, 0.01), Color(0.4, 0.42, 0.44))
		1:
			_b(k, x, p + Vector3(0, 0, 0.01), Vector3(w, h, 0.02), s(1, "accent") if not dark else s(1, "dark"))
			_b(k, x, p + Vector3(0, 0, 0.021), Vector3(w - 0.04, h - 0.04, 0.004), s(1, "dark") if not dark else s(1, "frame"))
			if not dark:
				_b(k, x, p + Vector3(0, h * 0.1, 0.024), Vector3(w * 0.4, w * 0.4, 0.004), col)
				_b(k, x, p + Vector3(0, -h * 0.32, 0.024), Vector3(w * 0.6, 0.04, 0.004), s(1, "accent"))
			for sx: float in [-1.0, 1.0]:
				for sy: float in [-1.0, 1.0]:
					_b(k, x, p + Vector3(sx * (w * 0.5 - 0.03), sy * (h * 0.5 - 0.03), 0.025), Vector3(0.02, 0.02, 0.01), s(1, "metal"))
		2:
			_b(k, x, p + Vector3(0, 0, 0.025), Vector3(w, h, 0.05), s(2, "shell"))
			_b(k, x, p + Vector3(0, 0, 0.051), Vector3(w - 0.04, h - 0.04, 0.004), Color(0.97, 0.98, 0.98) if not dark else s(2, "dark"))
			if not dark:
				_b(k, x, p + Vector3(-w * 0.22, 0, 0.054), Vector3(h * 0.5, h * 0.5, 0.004), s(2, "accent"))
				_b(k, x, p + Vector3(w * 0.15, 0.03, 0.054), Vector3(w * 0.4, 0.04, 0.004), s(2, "dark"))
				_b(k, x, p + Vector3(w * 0.12, -0.04, 0.054), Vector3(w * 0.32, 0.02, 0.004), s(2, "frame"))
		3:
			_b(k, x, p + Vector3(0, 0, 0.025), Vector3(w, h, 0.05), s(3, "dark"))
			_b(k, x, p + Vector3(0, -h * 0.5 + 0.01, 0.052), Vector3(w, 0.02, 0.006), lit(s(3, "glow"), 0.4))
			for sx: float in [-1.0, 1.0]:
				_b(k, x, p + Vector3(sx * w * 0.5, 0, 0.03), Vector3(0.03, h, 0.06), s(3, "frame"))
			if not dark:
				_b(k, x, p + Vector3(0, h * 0.08, 0.052), Vector3(w * 0.36, w * 0.36, 0.004), col)
				_b(k, x, p + Vector3(0, -h * 0.28, 0.052), Vector3(w * 0.6, 0.03, 0.004), s(3, "accent"))
		4:
			_b(k, x, p + Vector3(0, 0, 0.02), Vector3(w, h, 0.04), s(4, "frame"))
			_b(k, x, p + Vector3(0, 0, 0.041), Vector3(w - 0.04, h - 0.04, 0.004), s(4, "dark"))
			if not dark:
				k.torus(w * 0.18, 0.012, lit(s(4, "accent2"), 0.4), x * MeshKit.xf(p + Vector3(0, h * 0.08, 0.05), Vector3(90, 0, 0)), 12, 3)
				_b(k, x, p + Vector3(0, -h * 0.3, 0.045), Vector3(w * 0.5, 0.02, 0.004), s(4, "frame"))


## Neon tubes: a token ring, an inner ring and a word underneath.
static func _neon_tubes(k: MeshKit, nx: Transform3D, t: int, col: Color, big: bool) -> void:
	var c1 := lit(col.lightened(0.2), 0.35)
	var c2 := lit(s(t, "glow") if t != 2 else Color(1.0, 0.5, 0.7), 0.35)
	var r := 0.18 if big else 0.16
	k.torus(r, 0.018, c1, nx * MeshKit.xf(Vector3(-0.12, 0.08, 0.02), Vector3(90, 0, 0)), 14, 3)
	k.torus(r * 0.55, 0.014, c2, nx * MeshKit.xf(Vector3(-0.12, 0.08, 0.02), Vector3(90, 0, 0)), 10, 3)
	# the word: a few tube strokes
	for i in 4:
		k.box(Vector3(0.025, 0.12, 0.02), c2, nx * MeshKit.at(0.12 + i * 0.06, 0.04, 0.02))
		k.box(Vector3(0.05, 0.02, 0.02), c2, nx * MeshKit.at(0.135 + i * 0.06, 0.1 - (i % 2) * 0.12, 0.02))
	k.box(Vector3(0.3, 0.02, 0.02), c1, nx * MeshKit.at(0.0, -0.18, 0.02))
	# brackets and the transformer box
	for sx: float in [-0.2, 0.2]:
		k.box(Vector3(0.01, 0.01, 0.03), Color(0.6, 0.62, 0.64), nx * MeshKit.at(sx, 0.08, 0.0))
	k.box(Vector3(0.1, 0.06, 0.04), s(t, "dark"), nx * MeshKit.at(0.26, -0.24, 0.0))


## A patch panel: one panel (a power strip on plywood in the garage); two
## with a cable loom; a wall rack of panels with cable rings; a full rack
## with glowing switch lights and cable runs down the wall.
static func _panel_part(k: MeshKit, g: int, t: int, x: Transform3D, _col: Color) -> void:
	if t == 0:
		_panel_garage(k, g, x)
		return
	var n: int = [1, 2, 3, 4][g]
	var w := 0.7
	if g >= 2:
		# a wall-mounted rack frame
		var fc: Color = [s(0, "frame"), s(1, "frame"), s(2, "shell"), s(3, "frame"), s(4, "frame")][t]
		var h := n * 0.13 + 0.08
		for sx: float in [-1.0, 1.0]:
			_b(k, x, Vector3(sx * (w * 0.5 + 0.03), 0.08 - h * 0.5, 0.06), Vector3(0.04, h, 0.12), fc)
		_b(k, x, Vector3(0, 0.08, 0.06), Vector3(w + 0.1, 0.03, 0.12), fc)
		_b(k, x, Vector3(0, 0.08 - h, 0.06), Vector3(w + 0.1, 0.03, 0.12), fc)
		if t == 2:
			_b(k, x, Vector3(0, 0.08 + 0.016, 0.06), Vector3(w + 0.1, 0.006, 0.12), s(2, "accent"))
	for r in n:
		var y := -r * 0.13
		var sw := r == 1 or r == 3
		_patch(k, x, Vector3(0, y, 0.0 if g < 2 else 0.04), w, t, r, sw, g >= 3)
		if g >= 2:
			# cable rings at the side
			_b(k, x, Vector3(-w * 0.5 + 0.02, y, 0.12 if g >= 2 else 0.08), Vector3(0.03, 0.06, 0.03), s(t, "dark"))
	# the cable loom down the wall
	var cc := [Color(0.3, 0.6, 1.0), Color(1.0, 0.6, 0.3), Color(0.5, 1.0, 0.6), Color(0.96, 0.9, 0.3)]
	if g >= 1:
		var bot := -n * 0.13 + 0.04
		for i in mini(g + 1, 4):
			var c: Color = cc[i]
			if g >= 3:
				c = lit(c, 0.4)
			elif t == 4:
				c = s(4, "frame") if i % 2 == 0 else s(4, "shell2")
			_run(k, x, [Vector3(w * 0.3 + i * 0.03, bot + 0.06, 0.06), Vector3(w * 0.3 + i * 0.03, bot - 0.06, 0.04), Vector3(w * 0.3 + i * 0.03, -0.75, 0.03)], 0.018, c)
	if g >= 3:
		_b(k, x, Vector3(-0.2, 0.15, 0.03), Vector3(0.16, 0.05, 0.006), Color(0.97, 0.97, 0.96) if t < 3 else s(t, "accent"))
		_lamp(k, x, Vector3(w * 0.5 - 0.02, 0.15, 0.03), t, Color(0.5, 1.0, 0.6))


## One 1U patch panel or switch centred at p.
static func _patch(k: MeshKit, x: Transform3D, p: Vector3, w: float, t: int, r: int, switch_: bool, glow: bool) -> void:
	var bc: Color = [Color.BLACK, s(1, "shell2"), s(2, "shell"), s(3, "dark"), s(4, "shell")][t]
	_b(k, x, p + Vector3(0, 0, 0.025), Vector3(w, 0.11, 0.05), bc)
	for sx: float in [-1.0, 1.0]:
		_b(k, x, p + Vector3(sx * (w * 0.5 - 0.015), 0, 0.052), Vector3(0.03, 0.11, 0.006), s(t, "frame") if t != 2 else s(2, "shell2"))
	var ports := 8
	for i in ports:
		var px := -w * 0.38 + i * w * 0.76 / (ports - 1)
		var on := (i + r) % 3 != 0
		_b(k, x, p + Vector3(px, 0.0, 0.052), Vector3(0.035, 0.03, 0.006), s(t, "dark") if t != 3 else Color(0.05, 0.05, 0.06))
		if switch_:
			_b(k, x, p + Vector3(px, 0.028, 0.054), Vector3(0.012, 0.01, 0.004), lit(s(t, "glow") if on else Color(1.0, 0.7, 0.3), 0.35))
		elif on:
			# a patch lead plugged in, dropping a little
			var lc: Color = [Color(0.3, 0.6, 1.0), Color(1.0, 0.6, 0.3), Color(0.5, 1.0, 0.6), Color(0.96, 0.9, 0.3)][(i + r) % 4]
			_b(k, x, p + Vector3(px, -0.005, 0.062), Vector3(0.02, 0.02, 0.016), lit(lc, 0.45) if glow else lc)
	if t == 2:
		_b(k, x, p + Vector3(w * 0.42, 0.035, 0.052), Vector3(0.06, 0.012, 0.004), s(2, "accent"))
	elif t == 4:
		_b(k, x, p + Vector3(0, -0.05, 0.051), Vector3(w - 0.04, 0.006, 0.004), s(4, "frame"))


## Garage wiring: power strips on a plywood board with tangled cords.
static func _panel_garage(k: MeshKit, g: int, x: Transform3D) -> void:
	var n: int = [1, 2, 3, 4][g]
	var bh := 0.2 + n * 0.12
	_b(k, x, Vector3(0, 0.1 - bh * 0.5, 0.01), Vector3(0.72, bh, 0.02), s(0, "shell"))
	for sx: float in [-1.0, 1.0]:
		for sy: float in [0.0, 1.0]:
			_b(k, x, Vector3(sx * 0.33, 0.06 - sy * (bh - 0.08), 0.024), Vector3(0.015, 0.015, 0.008), Color(0.4, 0.42, 0.44))
	var cords := [s(0, "cable"), Color(0.95, 0.95, 0.92), Color(0.16, 0.16, 0.17), Color(0.3, 0.5, 0.86)]
	for r in n:
		var y := -r * 0.12
		_b(k, x, Vector3(-0.04, y, 0.035), Vector3(0.5, 0.06, 0.04), Color(0.95, 0.95, 0.92))
		_b(k, x, Vector3(0.19, y, 0.058), Vector3(0.03, 0.03, 0.006), Color(0.86, 0.3, 0.24) if g < 3 else lit(Color(1.0, 0.4, 0.3), 0.35))
		for i in 4:
			var px := -0.24 + i * 0.1
			_b(k, x, Vector3(px, y, 0.06), Vector3(0.04, 0.04, 0.03), Color(0.16, 0.16, 0.17) if i % 2 else Color(0.95, 0.95, 0.92))
			if (i + r) % 2 == 0:
				_run(k, x, [Vector3(px, y - 0.02, 0.07), Vector3(px + 0.03, y - 0.1, 0.08), Vector3(px - 0.02 + i * 0.01, -0.75, 0.04)], 0.014, cords[(i + r) % 4])
	if g >= 2:
		# a label and a router taped on
		_b(k, x, Vector3(-0.2, 0.08, 0.022), Vector3(0.2, 0.05, 0.004), Color(0.97, 0.96, 0.9))
		_b(k, x, Vector3(0.24, 0.06, 0.04), Vector3(0.16, 0.06, 0.05), Color(0.94, 0.94, 0.92))
		for i in 3:
			_b(k, x, Vector3(0.2 + i * 0.04, 0.07, 0.066), Vector3(0.012, 0.012, 0.004), lit(Color(0.5, 1.0, 0.6), 0.35))
		_seg(k, x, Vector3(0.3, 0.09, 0.04), Vector3(0.32, 0.22, 0.04), 0.01, Color(0.16, 0.16, 0.17))
	if g >= 3:
		k.sphere(0.035, lit(s(0, "glow"), 0.25), x * MeshKit.at(0.0, 0.3, 0.1), 6, 4)
		_run(k, x, [Vector3(0, 0.33, 0.1), Vector3(0, 0.42, 0.02)], 0.008, Color(0.16, 0.16, 0.17))
