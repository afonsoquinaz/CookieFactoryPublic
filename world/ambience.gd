class_name Ambience
extends Node3D
## Life around the base, so the world never stands still: toy cars cruise
## both lanes of the High Street (hatchbacks and vans at first, sleek
## driverless pods in the last era), and soft cloud shadows drift slowly
## across the land.

const CARS := 4
const CLOUDS := 5
const LANES := [[-0.85, -1.0], [0.85, 1.0]]      # [z, direction]

var world
var _cars: Array[Dictionary] = []
var _clouds: Array[MeshInstance3D] = []
var _cloud_mat: StandardMaterial3D


func _ready() -> void:
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud_mat.albedo_texture = _soft_disc()
	_cloud_mat.albedo_color = Color(0.05, 0.08, 0.12, 0.14)
	_cloud_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cloud_mat.render_priority = -1
	for i in CLOUDS:
		var q := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1, 1)
		q.mesh = pm
		q.material_override = _cloud_mat
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)
		_clouds.append(q)
		_place_cloud(q, true)


func _soft_disc() -> Texture2D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n * 0.5, (y + 0.5 - n * 0.5) * 1.3).length() / (n * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 1.6))
	return ImageTexture.create_from_image(img)


func _focus() -> Vector3:
	return world.cam.global_position if world and world.cam else Vector3.ZERO


func _place_cloud(q: MeshInstance3D, anywhere: bool) -> void:
	var f := _focus()
	var s := randf_range(14.0, 26.0)
	q.scale = Vector3(s, 1, s * randf_range(0.6, 0.9))
	q.rotation.y = randf() * TAU
	var x := f.x + (randf_range(-40, 40) if anywhere else -45.0 - randf() * 10.0)
	q.position = Vector3(x, 0.12, f.z + randf_range(-35, 25))


func _process(dt: float) -> void:
	if world == null:
		return
	var f := _focus()
	# clouds drift east, and wrap around the view
	for q in _clouds:
		q.position.x += dt * 1.1
		if q.position.x > f.x + 50.0 or absf(q.position.z - f.z) > 60.0 or q.position.x < f.x - 70.0:
			_place_cloud(q, false)
	# the street stays quiet during the opening story
	if Market.paused:
		for c in _cars:
			c["node"].queue_free()
		_cars.clear()
		return
	while _cars.size() < CARS:
		_cars.append(_new_car(f, _cars.size() % 2, randf_range(-35, 35)))
	for c in _cars.duplicate():
		var n: Node3D = c["node"]
		n.position.x += float(c["dir"]) * float(c["speed"]) * dt
		n.position.y = absf(sin(n.position.x * 3.0)) * 0.015
		if absf(n.position.x - f.x) > 48.0:
			n.queue_free()
			_cars.erase(c)
			var lane := randi() % 2
			_cars.append(_new_car(f, lane, -46.0 * float(LANES[lane][1])))


func _new_car(f: Vector3, lane: int, dx: float) -> Dictionary:
	var dir: float = LANES[lane][1]
	var era := int(round(world.terrain.era)) if world.terrain else 0
	var t: int = 4 if era >= 4 else [0, 1, 2, 3, 0, 2][randi() % 6]
	var col := Color.TRANSPARENT
	if t != 4 and randf() < 0.6:
		col = [Color(0.86, 0.3, 0.28), Color(0.95, 0.75, 0.3), Color(0.3, 0.55, 0.85), Color(0.42, 0.7, 0.5), Color(0.95, 0.95, 0.93)][randi() % 5]
	var key := "car_%d_%s" % [t, col.to_html()]
	var mesh := MeshKit.cached(key, func():
		var k := MeshKit.new()
		ArchKit.vehicle(k, Transform3D.IDENTITY, t, col)
		return k.commit())
	var n := Node3D.new()
	add_child(n)
	Mats.inst(mesh, n)
	n.position = Vector3(f.x + dx, 0, float(LANES[lane][0]))
	# the vehicle mesh faces +z: turn it along the lane
	n.rotation.y = PI * 0.5 if dir > 0.0 else -PI * 0.5
	n.scale = Vector3.ONE * 1.15
	return {"node": n, "dir": dir, "speed": 6.0 if lane == 0 else 5.2}   # one speed per lane: no ghosting through each other
