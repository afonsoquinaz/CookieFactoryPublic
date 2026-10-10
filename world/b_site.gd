class_name SiteB
extends Building
## A building under construction: a dirt pad, scaffolding, and the building
## itself rising inside it as the builder works. When the job is done the
## World swaps it for the real building.

var _rise: MeshInstance3D
var _frame: Node3D
var _dust_t := 0.0


func _visual(root: Node3D, _t: int) -> void:
	var s := size_m()
	Mats.inst(MeshKit.cached("site_ground_%d_%d" % [size().x, size().y], func(): return TownArt.site_ground(s.x, s.y)), root)
	var h := clampf(maxf(s.x, s.y) * 0.45, 2.4, 6.0)
	_frame = Mats.inst(MeshKit.cached("scaffold_%d_%d" % [size().x, size().y], func(): return TownArt.scaffold(s.x, s.y, h)), root, Transform3D.IDENTITY, false)
	_rise = Mats.inst(Previews.mesh(kind, "", 0), root)
	_rise.scale = Vector3(0.96, 0.1, 0.96)
	_update(0.0)


func solid_rects() -> Array[Rect2]:
	var s := size_m()
	return [Rect2(-s.x * 0.5 + 0.1, -s.y * 0.5 + 0.1, s.x - 0.2, s.y - 0.2)]


func progress() -> float:
	var j := Game.job_of(uid)
	return Game.job_progress(j) if not j.is_empty() else 1.0


func _update(dt: float) -> void:
	var p := progress()
	if _rise:
		var target := 0.08 + 0.92 * p
		_rise.scale.y = lerpf(_rise.scale.y, target, clampf(dt * 3.0, 0.0, 1.0)) if dt > 0.0 else target


func _process(dt: float) -> void:
	super(dt)
	_update(dt)
	_dust_t -= dt
	if _dust_t <= 0.0 and is_inside_tree():
		_dust_t = randf_range(0.5, 1.2)
		var s := size_m()
		Fx.puff(get_tree().current_scene, to_world(randf_range(-s.x, s.x) * 0.35, randf_range(-s.y, s.y) * 0.35, 0.3), Color(0.86, 0.8, 0.7), 2)


func status() -> String:
	var j := Game.job_of(uid)
	if j.is_empty():
		return "Almost done..."
	return "Under construction: %s left" % Fmt.time(Game.job_left(j))


func info() -> Array:
	return [["hammer", "A builder is building it"], ["clock", status()]]
