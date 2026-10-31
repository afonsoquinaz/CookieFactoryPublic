class_name Bubbles
extends Node3D
## Coin bubbles: now and then a busy server or a customer channel (API
## Gateway, Chat Café, Desk, Edge PoP, Agent Hub) floats a gold coin bubble
## over its roof: a tip from happy customers. Tap it to collect a bonus
## worth a few seconds of your whole income; the coins fly to your money.
## A few at a time, they wait for you (nothing is lost if you don't tap),
## and they're only a bonus: the API keeps paying either way.

const MAX_SHOWN := 3
const HIT_PX := 70.0

var world
var _next := {}          # uid -> seconds until its next bubble
var _shown := {}         # uid -> Node3D bubble
var _t := 0.0


static func eligible(n: Building) -> bool:
	if n == null or n is SiteB:
		return false
	if n is ServerB:
		return (n as ServerB).load_now > 0.05
	return n is ChannelB or n is CafeB or n is DeskB


## What a bubble pays right now.
static func value() -> float:
	return maxf(Bal.BUBBLE_MIN, Market.income * Bal.BUBBLE_SECONDS)


func _process(dt: float) -> void:
	_t += dt
	if Market.paused:
		return
	# bob and drop stale ones
	for uid in _shown.keys():
		var b: Node3D = _shown[uid]
		var n: Building = world.bnodes.get(uid)
		if n == null or not is_instance_valid(b) or n is SiteB:
			_drop(uid)
			continue
		b.position = _anchor(n) + Vector3(0, sin(_t * 2.6 + uid) * 0.18, 0)
		b.rotation.y = 0.0
	# count down; new bubbles while there's room
	for n2 in world.bnodes.values():
		if not eligible(n2) or _shown.has(n2.uid):
			continue
		var left := float(_next.get(n2.uid, randf_range(Bal.BUBBLE_FIRST, Bal.BUBBLE_EVERY.y))) - dt
		_next[n2.uid] = left
		if left <= 0.0 and _shown.size() < MAX_SHOWN:
			_spawn(n2)


func _anchor(n: Building) -> Vector3:
	var top := clampf(maxf(n.size_m().x, n.size_m().y) * 0.55, 2.6, 6.0)
	return n.global_position + Vector3(0, top, 0)


func _spawn(n: Building) -> void:
	var b := UI3D.badge("coin", Color(0.95, 0.72, 0.2), 1.25)
	add_child(b)
	b.position = _anchor(n)
	b.scale = Vector3(0.1, 0.1, 0.1)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_shown[n.uid] = b
	Sfx.play("pop", -10.0, 1.4)


func _drop(uid: int) -> void:
	var b: Node3D = _shown.get(uid)
	if b and is_instance_valid(b):
		b.queue_free()
	_shown.erase(uid)
	_next[uid] = randf_range(Bal.BUBBLE_EVERY.x, Bal.BUBBLE_EVERY.y)


func count() -> int:
	return _shown.size()


## The bubble under a screen tap, or -1.
func hit(screen: Vector2, cam: Camera3D) -> int:
	var best := -1
	var best_d := HIT_PX
	for uid in _shown:
		var b: Node3D = _shown[uid]
		if not is_instance_valid(b) or cam.is_position_behind(b.global_position):
			continue
		var d := cam.unproject_position(b.global_position).distance_to(screen)
		if d < best_d:
			best_d = d
			best = uid
	return best


## Pops a bubble: returns {"money", "pos"} (pos is where it was).
func collect(uid: int) -> Dictionary:
	var b: Node3D = _shown.get(uid)
	if b == null or not is_instance_valid(b):
		return {}
	var pos := b.global_position
	var money := value()
	Fx.burst(get_tree().current_scene, pos, Color(1.0, 0.82, 0.3), 16)
	UI3D.pop_text(get_tree().current_scene, pos + Vector3(0, 0.6, 0), "+$%s" % Fmt.num(money), Color(1.0, 0.88, 0.35), 84)
	_drop(uid)
	return {"money": money, "pos": pos}


## Where the first bubble floats (for the hint), or null.
func first_pos() -> Variant:
	for uid in _shown:
		var b: Node3D = _shown[uid]
		if is_instance_valid(b):
			return b.global_position
	return null


## A bubble right away (tests, the tutorial hint).
func force(n: Building) -> void:
	if not _shown.has(n.uid):
		_spawn(n)
