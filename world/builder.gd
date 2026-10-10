class_name Builder
extends Node3D
## A builder from a Builder's Hut. When the World hands them a job they walk
## to the site (across the grass if they must: builders go where the work
## is), hammer away beside it until it's done, then walk home and rest.

var world: World
var hut_uid := 0
var job := {}                  # the Game job being worked on ({} = none)
var ch: Character
var _path := PackedVector3Array()
var _pi := 0
var _goal := Vector3.INF
var _dust_t := 0.0


func _ready() -> void:
	ch = Character.new()
	add_child(ch)
	ch.setup("builder", hut_uid * 31 + 7)
	ch.scale = Vector3.ONE * 0.95


func _process(dt: float) -> void:
	var target := _home()
	var working := false
	if not job.is_empty() and Game.jobs.has(job):
		target = world.job_spot(job, hut_uid)
		working = true
	if global_position.distance_to(target) > 0.25:
		_walk(target, dt)
		return
	ch.move_speed = 0.0
	if working:
		ch.work = "hoe"
		ch.face(world.job_center(job) - global_position, dt, 6.0)
		_dust_t -= dt
		if _dust_t <= 0.0:
			_dust_t = 0.55
			Fx.puff(get_tree().current_scene, global_position + ch.global_transform.basis.z * 0.6 + Vector3(0, 0.3, 0), Color(0.86, 0.8, 0.7), 2)
			if _near_camera():
				Sfx.play("hammer", 0.0, 1.0, 0.08)
	else:
		ch.work = "sit"
		ch.face(Vector3(0, 0, 1), dt, 4.0)


func _near_camera() -> bool:
	return world.cam and global_position.distance_to(world.cam.global_position) < 26.0 * world.cam.zoom


func _home() -> Vector3:
	var h: Building = world.building(hut_uid)
	if h is HutB:
		return (h as HutB).rest_spot()
	return global_position


func _walk(target: Vector3, dt: float) -> void:
	if _goal.distance_to(target) > 0.3:
		_goal = target
		_path = world.grid.path(global_position, target)
		_pi = 0
	while _pi < _path.size() and Vector2(_path[_pi].x - global_position.x, _path[_pi].z - global_position.z).length() < 0.15:
		_pi += 1
	if _pi >= _path.size():
		global_position = global_position.move_toward(target, dt * 3.0)
		return
	var to := _path[_pi] - global_position
	to.y = 0
	var spd := 3.4 * Game.speed_mult()
	if to.length() > 0.001:
		global_position += to.normalized() * minf(to.length(), spd * dt)
		ch.face(to, dt, 10.0)
	global_position.y = 0.0
	ch.work = ""
	ch.move_speed = 0.9
