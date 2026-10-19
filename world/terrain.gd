class_name Terrain
extends Node3D
## The endless land around your empire. The ground is one big plane that
## follows the camera; its shader colours every 16 m land chunk by biome and
## shades land you don't own. Trees, shrubs, rocks and flowers are streamed
## in around the camera from per-chunk seeds (MultiMeshes, a handful of draw
## calls). Chunks next to your land show a "For sale" sign you can tap.
##
## Eras (Defs.ERAS, from the Lab level) turn the village into a datacenter:
## the shader paves your land and roads, the streamed decor swaps lawns for
## LED bollards and floor vents, smart lamps then power poles with cables
## line the High Street, and datacenter halls with cooling towers rise on the
## horizon (wild land at least one plot away from yours).

signal era_changed(era: int)

const TEX_N := 128
const ROAD_N := 256                     # road texture: one texel per grid cell
const RADIUS := 2                       # decor chunks around the focus
const CHUNK_M := Bal.CHUNK * Grid.CELL  # 16 m

var world: World
var focus := Vector3.ZERO
var _ground: MeshInstance3D
var _mat: ShaderMaterial
var _own_img: Image
var _own_tex: ImageTexture
var _biome_tex: ImageTexture
var _road_img: Image
var _road_tex: ImageTexture
var _origin := Vector2i(-TEX_N / 2, -TEX_N / 2)
var _focus_chunk := Vector2i(99999, 99999)
var _mmis := {}                         # decor kind -> MultiMeshInstance3D
var _signs := {}                        # chunk key -> Node3D
var _dirty := true
var era := 0.0                          # shown era (eases toward Game's era)
var _era_target := 0
static var _noise: FastNoiseLite
static var _noise2: FastNoiseLite


static func biome(chunk: Vector2i) -> String:
	if chunk.length_squared() <= 2:
		return "valley"
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.seed = 1717
		_noise.frequency = 0.11
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise2 = FastNoiseLite.new()
		_noise2.seed = 4242
		_noise2.frequency = 0.09
		_noise2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var a := _noise.get_noise_2d(chunk.x, chunk.y)
	var b := _noise2.get_noise_2d(chunk.x, chunk.y)
	if absf(a) < 0.12 and absf(b) < 0.25:
		return "valley"
	if a >= 0.0:
		return "desert" if b >= 0.0 else "tundra"
	return "highland" if b >= 0.0 else "valley"


static func biome_at(p: Vector3) -> String:
	return biome(Grid.chunk_of(Grid.cell_of(p)))


func _ready() -> void:
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(320, 320)
	_ground.mesh = pm
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://render/ground.gdshader")
	_ground.material_override = _mat
	_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ground)
	var bimg := Image.create(TEX_N, TEX_N, false, Image.FORMAT_RGB8)
	for x in TEX_N:
		for y in TEX_N:
			var b := biome(_origin + Vector2i(x, y))
			bimg.set_pixel(x, y, Defs.BIOMES[b]["grass"])
	_biome_tex = ImageTexture.create_from_image(bimg)
	_own_img = Image.create(TEX_N, TEX_N, false, Image.FORMAT_R8)
	_own_tex = ImageTexture.create_from_image(_own_img)
	_mat.set_shader_parameter("biome_tex", _biome_tex)
	_mat.set_shader_parameter("own_tex", _own_tex)
	_mat.set_shader_parameter("tex_origin", Vector2(_origin))
	_mat.set_shader_parameter("tex_n", float(TEX_N))
	_mat.set_shader_parameter("chunk_m", CHUNK_M)
	_road_img = Image.create(ROAD_N, ROAD_N, false, Image.FORMAT_RG8)
	_road_tex = ImageTexture.create_from_image(_road_img)
	_mat.set_shader_parameter("road_tex", _road_tex)
	_mat.set_shader_parameter("road_origin", Vector2(-ROAD_N / 2, -ROAD_N / 2))
	_mat.set_shader_parameter("road_n", float(ROAD_N))
	_mat.set_shader_parameter("street_y", float(Roads.STREET_Y))
	_era_target = Defs.era_for(Game.level)
	era = float(_era_target)
	_mat.set_shader_parameter("era", era)
	Game.level_up.connect(func(_l, _g): _check_era())
	refresh_land()
	# a big flat collider so taps and the player always find the ground
	var body := StaticBody3D.new()
	body.collision_layer = 4
	var cs := CollisionShape3D.new()
	var sh := WorldBoundaryShape3D.new()
	cs.shape = sh
	body.add_child(cs)
	add_child(body)


## Land ownership changed: update the overlay and the sale signs.
func refresh_land() -> void:
	_own_img.fill(Color(0, 0, 0))
	for c in Game.owned_chunks():
		var t := c - _origin
		if t.x >= 0 and t.y >= 0 and t.x < TEX_N and t.y < TEX_N:
			_own_img.set_pixel(t.x, t.y, Color(1, 0, 0))
	_own_tex.update(_own_img)
	_dirty = true


## Paints the road network into the ground (red = cell -> bits, see Roads)
## and each building's lot (green: its cells and a ring around them, on your
## land), which the later eras pave.
func set_roads(cells: Dictionary) -> void:
	if _road_img == null:
		return
	_road_img.fill(Color(0, 0, 0))
	var o := Vector2i(-ROAD_N / 2, -ROAD_N / 2)
	var lots := {}
	if world:
		for c in world.grid.occ:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var q: Vector2i = c + Vector2i(dx, dy)
					if Game.owns_cell(q):
						lots[q] = true
	for c in lots:
		var t: Vector2i = c - o
		if t.x >= 0 and t.y >= 0 and t.x < ROAD_N and t.y < ROAD_N:
			_road_img.set_pixel(t.x, t.y, Color(0, 1, 0))
	for c in cells:
		var t: Vector2i = c - o
		if t.x >= 0 and t.y >= 0 and t.x < ROAD_N and t.y < ROAD_N:
			_road_img.set_pixel(t.x, t.y, Color(float(int(cells[c])) / 255.0, 1.0 if lots.has(c) else 0.0, 0))
	_road_tex.update(_road_img)
	_dirty = true


## The Lab level went up: a new era eases in over a couple of seconds.
func _check_era() -> void:
	var e := Defs.era_for(Game.level)
	if e != _era_target:
		_era_target = e
		_dirty = true
		era_changed.emit(e)


## Jumps straight to the current era (loading, tests, screenshots).
func snap_era() -> void:
	_era_target = Defs.era_for(Game.level)
	era = float(_era_target)
	if _mat:
		_mat.set_shader_parameter("era", era)
	_dirty = true


func mark_dirty() -> void:
	_dirty = true


func _process(dt: float) -> void:
	if absf(era - float(_era_target)) > 0.001:
		era = move_toward(era, float(_era_target), dt * 0.4)
		_mat.set_shader_parameter("era", era)
	var cam := get_viewport().get_camera_3d()
	if cam:
		# where the camera looks at the ground
		var o := cam.global_position
		var d := -cam.global_transform.basis.z
		if d.y < -0.05:
			focus = o + d * (-o.y / d.y)
	_ground.global_position = Vector3(snappedf(focus.x, 8.0), 0, snappedf(focus.z, 8.0))
	var fc := Grid.chunk_of(Grid.cell_of(focus))
	if fc != _focus_chunk or _dirty:
		_focus_chunk = fc
		_dirty = false
		_rebuild_decor()
		_rebuild_signs()


# ---------------------------------------------------------------- decor

const DECOR := ["tuft", "drytuft", "daisy", "pebble", "lavender", "oak", "cypress", "pine", "snowpine", "cactus", "dune", "shrub", "rock", "snowrock",
	"bollard", "vent", "lamp_smart", "pole", "cable", "pylon", "dc_hall", "dc_tower", "dc_chiller", "dc_tank"]
const BIG_DECOR := ["oak", "cypress", "pine", "snowpine", "cactus", "lamp_smart", "pole", "pylon", "dc_hall", "dc_tower", "dc_chiller", "dc_tank"]
const POLE_GAP := 6                    # cells between High Street poles


func _rebuild_decor() -> void:
	var per := {}
	for k in DECOR:
		per[k] = []
	for cx in range(_focus_chunk.x - RADIUS, _focus_chunk.x + RADIUS + 1):
		for cy in range(_focus_chunk.y - RADIUS, _focus_chunk.y + RADIUS + 1):
			_chunk_decor(Vector2i(cx, cy), per)
	for k in DECOR:
		var xs: Array = per[k]
		var mmi: MultiMeshInstance3D = _mmis.get(k)
		if mmi == null:
			mmi = MultiMeshInstance3D.new()
			mmi.material_override = Mats.toon()
			var big: bool = k in BIG_DECOR
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if big else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = MeshKit.cached("decor_" + k, Terrain.decor_mesh.bind(k))
			mmi.multimesh = mm
			add_child(mmi)
			_mmis[k] = mmi
		var m: MultiMesh = mmi.multimesh
		if m.instance_count < xs.size() or m.instance_count > xs.size() + 400:
			m.instance_count = xs.size() + 64
		m.visible_instance_count = xs.size()
		for i in xs.size():
			m.set_instance_transform(i, xs[i])


func _chunk_decor(c: Vector2i, per: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c * 7919 + Vector2i(13, 71))
	var owned := Game.owns_chunk(c)
	var b := biome(c)
	var x0 := c.x * CHUNK_M
	var z0 := c.y * CHUNK_M
	var add := func(kind: String, n: int, smin: float, smax: float) -> void:
		for i in n:
			var p := Vector3(x0 + rng.randf() * CHUNK_M, 0, z0 + rng.randf() * CHUNK_M)
			var s := rng.randf_range(smin, smax)
			var rot := rng.randf() * TAU
			var pc := Grid.cell_of(p)
			if Roads.is_street(pc) or Roads.is_street(pc + Vector2i(0, 1)) or Roads.is_street(pc - Vector2i(0, 1)):
				continue
			if world and (world.grid.blocked(pc) or world.roads.is_road(pc)):
				continue
			per[kind].append(Transform3D(Basis(Vector3.UP, rot).scaled(Vector3(s, s, s)), p))
	if c.y == 0:
		_street_props(c, per)
	if owned and _era_target >= 2:
		# paved land: a few lawns, LED bollards, floor vents later
		add.call("tuft", 6 if _era_target == 2 else 0, 0.8, 1.2)
		add.call("bollard", 3, 0.9, 1.1)
		add.call("vent", 4 if _era_target >= 3 else 0, 0.9, 1.1)
		return
	add.call("drytuft" if b == "desert" else "tuft", 40 if b != "desert" else 14, 0.8, 1.4)
	add.call("daisy", {"valley": 9, "desert": 0, "tundra": 4, "highland": 3}[b], 0.8, 1.3)
	add.call("pebble", 4 if b != "highland" else 9, 0.8, 1.5)
	if owned:
		# cleared land: only grass and flowers
		add.call("lavender", 2 if b == "valley" else (0 if b == "desert" else 1), 0.8, 1.1)
		if _era_target >= 1:
			add.call("bollard", 2, 0.9, 1.1)
		return
	if _era_target >= 3 and _sprawl(c, per, rng):
		return
	match b:
		"valley":
			add.call("oak", 3, 0.85, 1.25)
			add.call("cypress", 1, 0.85, 1.15)
			add.call("shrub", 4, 0.8, 1.3)
			add.call("lavender", 3, 0.8, 1.2)
			add.call("rock", 1, 0.7, 1.2)
		"desert":
			add.call("cactus", 5, 1.3, 1.9)
			add.call("dune", 3, 0.8, 1.5)
			add.call("rock", 2, 0.7, 1.3)
		"tundra":
			add.call("snowpine", 6, 0.85, 1.35)
			add.call("snowrock", 4, 0.7, 1.5)
			add.call("shrub", 1, 0.8, 1.1)
		"highland":
			add.call("pine", 5, 0.85, 1.3)
			add.call("rock", 5, 0.7, 1.6)
			add.call("shrub", 2, 0.8, 1.1)


## Smart lamps (campus), then power poles with cables (data park on) along
## both edges of the High Street, stepping aside where a side road joins.
func _street_props(c: Vector2i, per: Dictionary) -> void:
	if _era_target < 1:
		return
	var x0 := c.x * Bal.CHUNK
	var k0 := ceili(float(x0) / POLE_GAP)
	var k1 := floori(float(x0 + Bal.CHUNK - 1) / POLE_GAP)
	for side in [0, 1]:
		var z := float(Roads.STREET_Y) * Grid.CELL + 0.18 if side == 0 else float(Roads.STREET_Y + 2) * Grid.CELL - 0.18
		var yaw := 0.0 if side == 0 else PI
		for k in range(k0, k1 + 1):
			var x := _pole_x(k, side)
			var p := Vector3(x, 0, z)
			if _era_target == 1:
				per["lamp_smart"].append(Transform3D(Basis(Vector3.UP, yaw), p))
				continue
			per["pole"].append(Transform3D(Basis(Vector3.UP, yaw), p))
			# two cables to the next pole
			var q := Vector3(_pole_x(k + 1, side), 0, z)
			var len := q.x - p.x
			per["cable"].append(Transform3D(Basis.from_scale(Vector3(len, 1, 1)), p + Vector3(0, 3.55, 0)))


## Where High Street pole k stands (world x) on a side, off any side road.
func _pole_x(k: int, side: int) -> float:
	var row := Roads.STREET_Y - 1 if side == 0 else Roads.STREET_Y + 2
	var cx := k * POLE_GAP
	for t in 3:
		if world == null or not world.roads.is_road(Vector2i(cx + t, row)):
			return (cx + t) * Grid.CELL + Grid.CELL * 0.5
	return cx * Grid.CELL + Grid.CELL * 0.5


## Hyperscale on: wild land at least a plot away from yours fills with
## datacenter halls, cooling towers, chillers, tanks and power pylons.
## Returns true when this chunk became sprawl.
func _sprawl(c: Vector2i, per: Dictionary, rng: RandomNumberGenerator) -> bool:
	if c.y == 0 or c.y == -1:
		return false
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if Game.owns_chunk(c + Vector2i(dx, dy)):
				return false
	if rng.randf() < (0.45 if _era_target == 3 else 0.3):
		return false
	var o := Vector3(c.x * CHUNK_M, 0, c.y * CHUNK_M)
	var flip := rng.randf() < 0.5
	var hall := o + Vector3(8.0, 0, 6.0 if flip else 10.0)
	per["dc_hall"].append(Transform3D(Basis(Vector3.UP, PI * 0.5 * rng.randi_range(0, 1) * 2.0), hall))
	if _era_target >= 4 and rng.randf() < 0.3:
		per["dc_hall"].append(Transform3D(Basis.IDENTITY, o + Vector3(8.0, 0, 13.5 if flip else 2.5)))
	else:
		for i in 3:
			per["dc_chiller"].append(Transform3D(Basis.IDENTITY, o + Vector3(3.5 + i * 4.5, 0, 13.0 if flip else 3.0)))
	var tz := 1.8 if flip else 14.2
	per["dc_tower"].append(Transform3D(Basis.IDENTITY, o + Vector3(2.6, 0, tz)))
	per["dc_tank"].append(Transform3D(Basis.IDENTITY, o + Vector3(13.6, 0, tz)))
	# a power line along the chunk row, joining the neighbours that are sprawl too
	var py := o + Vector3(0.6, 0, 8.0)
	per["pylon"].append(Transform3D(Basis.IDENTITY, py))
	for h in [8.6, 7.4]:
		per["cable"].append(Transform3D(Basis.from_scale(Vector3(CHUNK_M, 1, 1)), py + Vector3(0, h, 0)))
	return true


static func decor_mesh(kind: String) -> Mesh:
	var k := MeshKit.new()
	match kind:
		"tuft":
			for i in 4:
				var a := TAU * i / 4.0 + 0.3
				k.cone(0.045, 0.22 + (i % 2) * 0.08, Color(0.4, 0.5, 0.3) if i % 2 == 0 else Color(0.5, 0.58, 0.36),
					MeshKit.xf(Vector3(cos(a) * 0.05, 0, sin(a) * 0.05), Vector3(sin(a) * 18, 0, cos(a) * 18)), 5)
		"daisy":
			k.cyl(0.012, 0.14, Pal.LEAF_DARK, MeshKit.at(0, 0, 0), 4)
			for i in 5:
				var a := TAU * i / 5.0
				k.ellipsoid(Vector3(0.045, 0.012, 0.025), Color(1, 1, 1), MeshKit.xf(Vector3(cos(a) * 0.04, 0.15, sin(a) * 0.04), Vector3(0, -rad_to_deg(a), 0)), 5, 3)
			k.sphere(0.025, Color(1.0, 0.82, 0.25), MeshKit.at(0, 0.16, 0), 5, 3)
		"pebble":
			k.ellipsoid(Vector3(0.12, 0.05, 0.09), Color(0.62, 0.6, 0.57), MeshKit.at(0, 0.0, 0), 6, 4)
			k.ellipsoid(Vector3(0.07, 0.035, 0.06), Color(0.55, 0.53, 0.5), MeshKit.at(0.13, 0.0, 0.05), 6, 3)
		"lavender":
			return Stations.tree(4)
		"oak":
			k.cyl(0.12, 1.1, Pal.WOOD_DARK, MeshKit.xf(Vector3.ZERO, Vector3(0, 0, 4)), 7, 0.02, 0.08)
			k.ellipsoid(Vector3(1.0, 0.75, 0.95), Color(0.4, 0.52, 0.32), MeshKit.at(0.05, 1.65, 0), 12, 8)
			k.ellipsoid(Vector3(0.7, 0.55, 0.7), Color(0.47, 0.58, 0.36), MeshKit.at(-0.45, 1.95, 0.2), 10, 6)
			k.ellipsoid(Vector3(0.6, 0.45, 0.6), Color(0.35, 0.46, 0.29), MeshKit.at(0.5, 1.35, -0.25), 10, 6)
		"cypress":
			return Stations.tree(1)
		"pine":
			k.cyl(0.11, 0.6, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 7, 0.02)
			for i in 4:
				var y := 0.45 + i * 0.55
				var r := 0.95 - i * 0.2
				k.cone(r, 0.9, Color(0.24, 0.38, 0.3).lerp(Color(0.32, 0.46, 0.36), i / 4.0), MeshKit.at(0, y, 0), 10)
		"snowpine":
			k.cyl(0.11, 0.6, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 7, 0.02)
			for i in 4:
				var y := 0.45 + i * 0.55
				var r := 0.95 - i * 0.2
				k.cone(r, 0.9, Color(0.22, 0.36, 0.32).lerp(Color(0.3, 0.44, 0.4), i / 4.0), MeshKit.at(0, y, 0), 10)
				k.cone(r * 0.72, 0.42, Color(0.95, 0.97, 0.98), MeshKit.at(0, y + 0.5, 0), 10)
		"snowrock":
			k.ellipsoid(Vector3(0.5, 0.32, 0.42), Color(0.6, 0.62, 0.64), MeshKit.xf(Vector3(0, 0.15, 0), Vector3(0, 20, 8)), 8, 5)
			k.ellipsoid(Vector3(0.44, 0.14, 0.36), Color(0.95, 0.97, 0.98), MeshKit.xf(Vector3(0, 0.36, 0), Vector3(0, 20, 8)), 8, 4)
			k.ellipsoid(Vector3(0.28, 0.2, 0.26), Color(0.54, 0.56, 0.58), MeshKit.at(0.42, 0.08, 0.15), 7, 4)
		"cactus":
			var g := Color(0.42, 0.58, 0.38)
			k.capsule(0.16, 1.5, g, MeshKit.at(0, 0, 0), 10, 4)
			k.capsule(0.1, 0.55, g.lightened(0.06), MeshKit.at(0.26, 0.55, 0), 8, 3)
			k.cyl(0.1, 0.18, g.lightened(0.06), MeshKit.xf(Vector3(0.12, 0.62, 0), Vector3(0, 0, 90)), 8)
			k.capsule(0.09, 0.45, g.darkened(0.06), MeshKit.at(-0.24, 0.8, 0), 8, 3)
			k.cyl(0.09, 0.16, g.darkened(0.06), MeshKit.xf(Vector3(-0.08, 0.86, 0), Vector3(0, 0, -90)), 8)
			k.sphere(0.06, Color(0.95, 0.55, 0.62), MeshKit.at(0, 1.5, 0), 6, 4)
		"dune":
			k.ellipsoid(Vector3(1.2, 0.22, 0.7), Color(0.86, 0.74, 0.52), MeshKit.at(0, 0, 0), 12, 5)
			k.ellipsoid(Vector3(0.7, 0.16, 0.45), Color(0.9, 0.8, 0.58), MeshKit.at(0.5, 0.05, 0.2), 10, 4)
		"bollard":
			# a little LED bollard
			k.cyl(0.08, 0.55, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0, 0), 8, 0.02)
			k.cyl(0.085, 0.08, Color(0.45, 0.92, 1.0, 0.4), MeshKit.at(0, 0.42, 0), 8)
		"vent":
			# a floor grille breathing cold air
			k.rbox(Vector3(0.9, 0.05, 0.9), 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.02, 0))
			for i in 6:
				k.rbox(Vector3(0.78, 0.02, 0.05), 0.01, Color(0.6, 0.64, 0.7), MeshKit.at(0, 0.055, -0.3 + i * 0.12))
		"lamp_smart":
			# a slim street lamp leaning over the street (front = +z)
			k.cyl(0.2, 0.12, Color(0.5, 0.52, 0.56), MeshKit.at(0, 0, 0), 10, 0.02)
			k.cyl(0.06, 3.4, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.1, 0), 8, 0.0, 0.045)
			k.rbox(Vector3(0.1, 0.08, 1.0), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0, 3.45, 0.42))
			k.rbox(Vector3(0.18, 0.04, 0.5), 0.02, Color(0.9, 0.97, 1.0, 0.4), MeshKit.at(0, 3.4, 0.62))
			k.rbox(Vector3(0.1, 0.4, 0.02), 0.02, Color(0.4, 0.9, 1.0, 0.45), MeshKit.at(0, 1.4, 0.06))
		"pole":
			# a power pole with a crossarm, insulators and a little light
			k.cyl(0.12, 3.9, Color(0.66, 0.66, 0.64), MeshKit.at(0, 0, 0), 8, 0.0, 0.08)
			k.rbox(Vector3(0.12, 0.12, 1.3), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0, 3.6, 0))
			for z in [-0.55, 0.55]:
				for h in [3.25, 3.55]:
					k.cyl(0.035, 0.12, Color(0.82, 0.5, 0.3), MeshKit.at(0, h - 0.06, z), 6)
			k.rbox(Vector3(0.1, 0.08, 0.7), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0, 3.0, 0.42))
			k.rbox(Vector3(0.16, 0.04, 0.36), 0.02, Color(0.9, 0.97, 1.0, 0.4), MeshKit.at(0, 2.95, 0.62))
			k.torus(0.14, 0.025, Color(0.4, 0.9, 1.0, 0.45), MeshKit.at(0, 1.6, 0), 10, 4)
		"cable":
			# a pair of cables from x = 0 to x = 1 (scaled to the span)
			for z in [-0.55, 0.55]:
				k.rbox(Vector3(1.0, 0.022, 0.022), 0.005, Color(0.16, 0.16, 0.18), MeshKit.at(0.5, -0.08, z))
		"pylon":
			# a lattice transmission tower
			var st := Color(0.62, 0.64, 0.66)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.cyl(0.06, 9.0, st, MeshKit.xf(Vector3(sx * 0.9, 0, sz * 0.9), Vector3(-sz * 5.5, 0, sx * 5.5)), 5)
			for i in 7:
				var y := 0.8 + i * 1.2
				var w := 0.9 * (1.0 - y / 11.0)
				for sz in [-1.0, 1.0]:
					k.rbox(Vector3(w * 2.0, 0.05, 0.05), 0.01, st, MeshKit.at(0, y, sz * w))
					k.rbox(Vector3(0.05, 0.05, w * 2.0), 0.01, st, MeshKit.at(sz * w, y, 0))
			for h in [8.6, 7.4]:
				k.rbox(Vector3(0.12, 0.12, 3.2), 0.02, st, MeshKit.at(0, h + 0.1, 0))
			k.cone(0.3, 1.0, st, MeshKit.at(0, 9.0, 0), 6)
		"dc_hall":
			# a datacenter hall: long white box, roof chillers, louvres, a glowing band
			var wall := Color(0.92, 0.93, 0.94)
			k.rbox(Vector3(13.0, 0.3, 7.4), 0.05, Color(0.56, 0.57, 0.58), MeshKit.at(0, 0.15, 0))
			k.rbox(Vector3(12.0, 4.2, 6.4), 0.12, wall, MeshKit.at(0, 2.4, 0))
			for i in 12:
				k.rbox(Vector3(0.06, 3.9, 6.44), 0.01, wall.darkened(0.06), MeshKit.at(-5.5 + i * 1.0, 2.4, 0))
			k.rbox(Vector3(12.04, 0.22, 6.44), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(0, 3.5, 0))
			k.rbox(Vector3(11.6, 0.06, 0.04), 0.02, Color(0.45, 0.92, 1.0, 0.4), MeshKit.at(0, 1.2, 3.22))
			for i in 5:
				k.rbox(Vector3(1.4, 0.8, 0.05), 0.03, Color(0.4, 0.44, 0.5), MeshKit.at(-4.4 + i * 2.2, 2.4, 3.22))
			k.rbox(Vector3(1.4, 2.0, 0.06), 0.04, Color(0.24, 0.25, 0.28), MeshKit.at(4.8, 1.3, 3.22))
			for i in 4:
				var rx := -4.2 + i * 2.8
				k.rbox(Vector3(2.2, 0.7, 1.6), 0.06, Color(0.82, 0.84, 0.86), MeshKit.at(rx, 4.85, -1.2))
				for j in 2:
					k.cyl(0.45, 0.06, Color(0.3, 0.32, 0.36), MeshKit.at(rx - 0.5 + j * 1.0, 5.2, -1.2), 14)
			k.rbox(Vector3(3.0, 0.9, 1.4), 0.06, Color(0.82, 0.84, 0.86), MeshKit.at(3.5, 4.95, 1.6))
		"dc_tower":
			k.lathe(PackedVector2Array([Vector2(1.6, 0), Vector2(1.15, 2.6), Vector2(1.0, 3.8), Vector2(1.2, 5.2), Vector2(1.08, 5.2), Vector2(0.86, 3.8), Vector2(1.0, 2.6), Vector2(1.45, 0.02)]), Color(0.86, 0.86, 0.84), Transform3D.IDENTITY, 18)
			k.torus(1.15, 0.06, Color(0.36, 0.6, 0.86), MeshKit.at(0, 1.6, 0), 18, 4)
		"dc_chiller":
			k.rbox(Vector3(3.6, 1.6, 2.0), 0.08, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0.8, 0))
			for i in 3:
				k.cyl(0.5, 0.08, Color(0.3, 0.32, 0.36), MeshKit.at(-1.15 + i * 1.15, 1.6, 0), 14)
				k.cyl(0.12, 0.1, Color(0.6, 0.62, 0.66), MeshKit.at(-1.15 + i * 1.15, 1.62, 0), 8)
			for i in 6:
				k.rbox(Vector3(3.4, 0.04, 0.02), 0.01, Color(0.66, 0.7, 0.76), MeshKit.at(0, 0.3 + i * 0.18, 1.01))
		"dc_tank":
			k.cyl(1.3, 3.2, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0, 0), 18, 0.08)
			k.cyl(1.32, 0.12, Color(0.36, 0.6, 0.86), MeshKit.at(0, 2.2, 0), 18)
			k.cone(1.35, 0.5, Color(0.7, 0.72, 0.74), MeshKit.at(0, 3.2, 0), 18)
		"drytuft":
			for i in 4:
				var a := TAU * i / 4.0 + 0.3
				k.cone(0.04, 0.2 + (i % 2) * 0.08, Color(0.7, 0.62, 0.4) if i % 2 == 0 else Color(0.62, 0.6, 0.38),
					MeshKit.xf(Vector3(cos(a) * 0.05, 0, sin(a) * 0.05), Vector3(sin(a) * 22, 0, cos(a) * 22)), 5)
		"shrub":
			return Stations.tree(2)
		"rock":
			return Stations.tree(3)
	return k.commit()


# ---------------------------------------------------------------- land signs

func _rebuild_signs() -> void:
	var want := {}
	for cx in range(_focus_chunk.x - RADIUS, _focus_chunk.x + RADIUS + 1):
		for cy in range(_focus_chunk.y - RADIUS, _focus_chunk.y + RADIUS + 1):
			var c := Vector2i(cx, cy)
			if Game.can_buy_chunk(c):
				want[Game.chunk_key(c)] = c
	for k in _signs.keys():
		if not want.has(k):
			_signs[k].queue_free()
			_signs.erase(k)
	for k in want:
		if not _signs.has(k):
			_signs[k] = _make_sign(want[k])
		_update_sign(_signs[k])


func _make_sign(c: Vector2i) -> Node3D:
	var n := Node3D.new()
	n.set_meta("chunk", c)
	n.position = Vector3((c.x + 0.5) * CHUNK_M, 0, (c.y + 0.5) * CHUNK_M)
	add_child(n)
	Mats.inst(MeshKit.cached("land_sign", func():
		var k := MeshKit.new()
		k.cyl(0.07, 1.5, Pal.WOOD_DARK, MeshKit.at(-0.55, 0, 0), 6, 0.02)
		k.cyl(0.07, 1.5, Pal.WOOD_DARK, MeshKit.at(0.55, 0, 0), 6, 0.02)
		k.rbox(Vector3(1.5, 0.75, 0.08), 0.04, Pal.CREAM, MeshKit.at(0, 1.25, 0.04))
		k.rbox(Vector3(1.56, 0.08, 0.12), 0.02, Pal.TERRACOTTA, MeshKit.at(0, 1.66, 0.04))
		k.rbox(Vector3(0.6, 0.06, 0.6), 0.03, Pal.STONE_DARK, MeshKit.at(-0.55, 0.03, 0))
		k.rbox(Vector3(0.6, 0.06, 0.6), 0.03, Pal.STONE_DARK, MeshKit.at(0.55, 0.03, 0))
		return k.commit()), n)
	var b := biome(c)
	var t := UI3D.label(Defs.BIOMES[b]["name"], 30, Color(1, 1, 1), 8)
	t.position = Vector3(0, 2.45, 0)
	n.add_child(t)
	var price := UI3D.label("", 44, Color(1.0, 0.86, 0.4), 10)
	price.position = Vector3(0, 2.05, 0)
	price.name = "Price"
	n.add_child(price)
	var bonus: Array = Defs.BIOMES[b]["bonus"]
	for i in bonus.size():
		var ic := UI3D.icon(bonus[i], 0.0022)
		ic.position = Vector3((i - (bonus.size() - 1) * 0.5) * 0.42, 1.25, 0.12)
		n.add_child(ic)
	return n


func _update_sign(n: Node3D) -> void:
	var l: Label3D = n.get_node("Price")
	l.text = "$" + Fmt.num(Game.land_price())
	l.modulate = Color(1, 1, 1) if Game.can_afford(Game.land_price()) else Color(1, 0.7, 0.6)


## The sale sign chunk nearest to a world point (within r metres), or null.
func sign_near(p: Vector3, r := 2.5) -> Variant:
	for k in _signs:
		var n: Node3D = _signs[k]
		if Vector2(n.global_position.x - p.x, n.global_position.z - p.z).length() < r:
			return n.get_meta("chunk")
	return null


func refresh_prices() -> void:
	for k in _signs:
		_update_sign(_signs[k])
