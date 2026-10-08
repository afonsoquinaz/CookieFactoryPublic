class_name Zone
extends Node3D
## A floor pad you stand on to interact: take items from a holder, give items
## into holders, or pay money into a build pad. Players and workers both use
## zones through tick().

signal paid_off

enum Kind { TAKE, GIVE, PAY }

const PAD_SHADER := preload("res://render/pad.gdshader")

var kind := Kind.TAKE
var holders: Array[Holder] = []     # TAKE: sources (first with items wins); GIVE: targets
var size := Vector2(1.7, 1.7)
var enabled := true
var color := Color(1, 1, 1)
var icon_name := ""
## PAY pads
var price := 0
var paid := 0
var required_level := 1
var pad_id := ""
## while someone is standing here
var occupied := 0.0

var _mat: ShaderMaterial
var _quad: MeshInstance3D
var _timers := {}


static func make(p_kind: Kind, p_holders: Array, p_size := Vector2(1.7, 1.7), p_icon := "", p_color := Color(1, 1, 1)) -> Zone:
	var z := Zone.new()
	z.kind = p_kind
	for h in p_holders:
		z.holders.append(h)
	z.size = p_size
	z.icon_name = p_icon
	z.color = p_color
	return z


func _ready() -> void:
	add_to_group("zones")
	_quad = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	_quad.mesh = pm
	_quad.position.y = 0.03
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = ShaderMaterial.new()
	_mat.shader = PAD_SHADER
	_mat.render_priority = -1
	_mat.set_shader_parameter("size", size)
	_mat.set_shader_parameter("color", color)
	_mat.set_shader_parameter("fill_color", Color(color.r, color.g, color.b, 0.2))
	_mat.set_shader_parameter("direction", 1.0 if kind == Kind.GIVE else (-1.0 if kind == Kind.TAKE else 0.0))
	var t := Icons.tex(icon_name) if icon_name != "" else null
	_mat.set_shader_parameter("has_icon", 1.0 if t else 0.0)
	if t:
		_mat.set_shader_parameter("icon", t)
	_quad.material_override = _mat
	add_child(_quad)
	if kind == Kind.PAY:
		_mat.set_shader_parameter("progress", 0.0)


func set_icon(n: String) -> void:
	icon_name = n
	var t := Icons.tex(n)
	_mat.set_shader_parameter("has_icon", 1.0 if t else 0.0)
	if t:
		_mat.set_shader_parameter("icon", t)


func contains(p: Vector3, margin := 0.0) -> bool:
	var l := to_local(p)
	return absf(l.x) <= size.x * 0.5 + margin and absf(l.z) <= size.y * 0.5 + margin


func _process(dt: float) -> void:
	occupied = move_toward(occupied, 0.0, dt * 3.0)
	_mat.set_shader_parameter("active", occupied)
	_mat.set_shader_parameter("dim", 0.0 if enabled else 1.0)
	if kind == Kind.PAY:
		_mat.set_shader_parameter("progress", float(paid) / maxf(1.0, price))


## Called every frame by whoever stands here. carrier = their carry stack.
## Returns true if something happened this frame.
func tick(who: Object, carrier: Holder, dt: float, rate := 0.07, filter := "") -> bool:
	occupied = 1.0
	if not enabled:
		return false
	var key := who.get_instance_id()
	var tm := float(_timers.get(key, 0.0)) - dt
	if tm > 0.0:
		_timers[key] = tm
		return false
	_timers[key] = rate
	match kind:
		Kind.TAKE:
			if carrier == null:
				return false
			# take from the fullest source (keeps a mixed pantry balanced)
			var best: Holder = null
			for h in holders:
				if h.count() == 0 or (filter != "" and not h.has(filter)):
					continue
				if best == null or h.count() > best.count():
					best = h
			if best:
				var t := filter if filter != "" else best.items[best.items.size() - 1]
				if carrier.can_accept(t) and Holder.fly(best, carrier, t, 0.28):
					Sfx.play("pop", 0.0, 1.0 + minf(carrier.count(), 20) * 0.025)
					return true
		Kind.GIVE:
			if carrier == null:
				return false
			# give the top-most item that some holder here accepts
			for i in range(carrier.items.size() - 1, -1, -1):
				var t2 := carrier.items[i]
				if filter != "" and t2 != filter:
					continue
				for h in holders:
					if h.can_accept(t2) and Holder.fly(carrier, h, t2, 0.3):
						Sfx.play("drop")
						return true
		Kind.PAY:
			return _pay(dt)
	return false


func _pay(_dt: float) -> bool:
	if paid >= price or Game.level < required_level:
		return false
	# pay faster the bigger the price: ~1.6 s for a full pad
	var step := maxi(1, int(ceil(price / 26.0)))
	step = mini(step, mini(price - paid, Game.money))
	if step <= 0:
		return false
	Game.spend(step)
	paid += step
	Game.pad_paid[pad_id] = paid
	Sfx.play("pay_tick", 0.0, 0.8 + float(paid) / price * 0.8, 0.0)
	if paid >= price:
		paid_off.emit()
	return true
