class_name FarmWorker
extends Node3D
## A farmer working one farm (positions are in the farm's local space):
## walk to a ripe crop, work it, carry the harvest to the crate, repeat.

enum S { SEEK, TO_SPOT, WORK, TO_CRATE, DROP, WAIT }

var farm: Farm
var index := 0
var ch: Character
var carry: Holder
var state := S.SEEK
var _spot := {}
var _timer := 0.0
var _goal := Vector3.ZERO
var _bubble: Label3D


func _ready() -> void:
	ch = Character.new()
	add_child(ch)
	ch.setup("farmer", hash(farm.ing) + index * 31)
	ch.scale = Vector3.ONE * 1.25
	carry = Holder.new().setup(6, [], Holder.Layout.COLUMN)
	ch.carry_mount.add_child(carry)
	_bubble = UI3D.label("...", 40, Color(1, 1, 1))
	_bubble.position = Vector3(0, 1.75, 0)
	_bubble.visible = false
	add_child(_bubble)


func release() -> void:
	if not _spot.is_empty():
		_spot["busy"] = false
		_spot = {}


func _work_anim() -> String:
	match farm.ing:
		"wheat", "sugar": return "hoe"
		"cocoa": return "pick"
		_: return "milk"


func _process(dt: float) -> void:
	var lvl := farm.level
	var speed := Bal.farm_walk_speed(lvl) * Game.speed_mult()
	_bubble.visible = state == S.WAIT
	match state:
		S.SEEK:
			ch.work = ""
			_spot = farm.claim_spot()
			if _spot.is_empty():
				_timer -= dt
				ch.move_speed = 0.0
				if _timer <= 0.0:
					_timer = 0.5
				return
			# stand beside the crop, on its gate side
			_goal = _spot["pos"] + Vector3(0.0, 0, 0.42)
			_goal.y = 0.07
			state = S.TO_SPOT
		S.TO_SPOT:
			if _walk(_goal, speed, dt):
				state = S.WORK
				_timer = Bal.farm_work_time(lvl)
				ch.face((_spot["pos"] - position) * Vector3(1, 0, 1) + Vector3(0, 0, -0.01), 1.0, 1.0)
		S.WORK:
			ch.move_speed = 0.0
			ch.work = _work_anim()
			ch.face(Vector3(0, 0, -1), dt, 6.0)
			_timer -= dt * Game.speed_mult()
			if _timer <= 0.0:
				ch.work = ""
				farm.harvest(_spot)
				_spot = {}
				var y := Bal.farm_yield(lvl)
				for i in y:
					carry.add(farm.ing)
				ch.squash(1.0)
				ch.carrying = true
				Fx.puff(farm.get_tree().current_scene, global_position + Vector3(0, 0.5, -0.4), Defs.ITEMS[farm.ing]["color"], 5)
				_goal = farm.crate_drop_point() + Vector3(-0.6 + (index % 3) * 0.6, 0.07, 0)
				state = S.TO_CRATE
		S.TO_CRATE:
			if _walk(_goal, speed, dt):
				ch.face(Vector3(0, 0, 1), 1.0, 1.0)
				state = S.DROP
				_timer = 0.0
		S.DROP, S.WAIT:
			ch.move_speed = 0.0
			_timer -= dt
			if _timer > 0.0:
				return
			if carry.count() == 0:
				ch.carrying = false
				state = S.SEEK
				return
			if Holder.fly(carry, farm.crate, "", 0.3):
				Sfx.play("drop", -6.0)
				state = S.DROP
				_timer = 0.12
			else:
				state = S.WAIT
				_timer = 0.4


## Moves toward local point p. Returns true on arrival.
func _walk(p: Vector3, speed: float, dt: float) -> bool:
	var to := p - position
	to.y = 0
	var d := to.length()
	if d < 0.06:
		ch.move_speed = 0.0
		return true
	var step := minf(d, speed * dt)
	position += to / d * step
	ch.move_speed = clampf(speed / 3.0, 0.4, 1.0)
	ch.face(to, dt)
	return false
