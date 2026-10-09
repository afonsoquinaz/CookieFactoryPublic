class_name BuildPad
extends Node3D
## A pad in the world where you pay to unlock a building. Stand on it and
## coins fly in until it's paid; then the building pops up. Locked pads show
## the empire level they need.

signal completed(id: String)

var id := ""
var zone: Zone
var _title: Label3D
var _price: Label3D
var _lock: Label3D
var _ghost: Node3D
var _t := 0.0
var _coin_cd := 0.0


func setup(p_id: String) -> void:
	id = p_id
	name = "Pad_" + id
	var d: Dictionary = Defs.BUILDINGS[id]
	position = Lay.pad_pos(id)
	var sz := Vector2(2.2, 2.2) if not id.begins_with("line") else Vector2(3.0, 2.2)
	zone = Zone.make(Zone.Kind.PAY, [], sz, d["icon"], Pal.BRASS)
	var badge := UI3D.badge(d["icon"], Pal.BRASS.darkened(0.2), 0.7)
	badge.position = Vector3(0, 1.95, 0)
	add_child(badge)
	zone.price = int(d["cost"])
	zone.paid = int(Game.pad_paid.get(id, 0))
	zone.required_level = int(d["lvl"])
	zone.pad_id = id
	add_child(zone)
	zone.paid_off.connect(_done)
	_title = UI3D.label(d["name"], 30, Color(1, 1, 1))
	_title.position = Vector3(0, 1.35, 0)
	add_child(_title)
	_price = UI3D.label("", 44, Color(0.95, 0.84, 0.6))
	_price.position = Vector3(0, 0.85, 0)
	add_child(_price)
	_lock = UI3D.label("", 40, Color(0.75, 0.85, 1.0))
	_lock.position = Vector3(0, 0.3, 0.5)
	add_child(_lock)
	# a faint wireframe-ish hint of what will be built
	_ghost = Node3D.new()
	add_child(_ghost)
	var gk := MeshKit.new()
	gk.rbox(Vector3(sz.x - 0.4, 0.06, sz.y - 0.4), 0.03, Color(1, 1, 1))
	var gm := MeshInstance3D.new()
	gm.mesh = gk.commit()
	gm.material_override = Mats.flat(Color(1, 1, 1, 0.12))
	gm.position.y = 0.04
	_ghost.add_child(gm)
	_refresh()


func _refresh() -> void:
	var left := zone.price - zone.paid
	_price.text = "$" + Fmt.num(left)
	var locked := Game.level < zone.required_level
	_lock.visible = locked
	_lock.text = "Reach Level %d" % zone.required_level
	zone.enabled = not locked
	_price.modulate = Color(0.75, 0.74, 0.72) if locked else (Color(0.95, 0.84, 0.6) if Game.money >= zone.price - zone.paid else Color(0.92, 0.9, 0.86))


func _process(dt: float) -> void:
	_t += dt
	_refresh()
	_price.position.y = 0.85 + sin(_t * 2.0) * 0.03
	if zone.occupied > 0.9 and zone.enabled and Game.money > 0:
		_coin_cd -= dt
		if _coin_cd <= 0.0:
			_coin_cd = 0.07
			_spawn_coin()


func _spawn_coin() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	var c := Items.node("coin")
	get_tree().current_scene.add_child(c)
	var from := p.global_position + Vector3(0, 1.2, 0)
	c.global_position = from
	var to := global_position + Vector3(randf_range(-0.4, 0.4), 0.1, randf_range(-0.4, 0.4))
	var step := func(f: float) -> void:
		if not is_instance_valid(c):
			return
		var q := from.lerp(to, f)
		q.y += sin(f * PI) * 1.2
		c.global_position = q
		c.rotation.y = f * 8.0
	var tw := c.create_tween()
	tw.tween_method(step, 0.0, 1.0, 0.3)
	tw.tween_callback(c.queue_free)


func _done() -> void:
	Sfx.play("build")
	Fx.burst(get_tree().current_scene, global_position + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.3), 30)
	Fx.ring(get_tree().current_scene, global_position, Color(1, 0.9, 0.4), 3.0)
	Game.build(id)
	completed.emit(id)
	queue_free()
