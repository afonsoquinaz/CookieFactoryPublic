class_name Player
extends CharacterBody3D
## You: a tiny baker in a pink apron. Move with the joystick (or WASD/arrows);
## stand on pads to pick up, drop off and pay. Your stack wobbles as you run.

static var joy := Vector2.ZERO      # set by the on-screen joystick (-1..1)

var ch: Character
var carry: Holder
var _max_label: Label3D
var _step_t := 0.0
var _dust_t := 0.0
var _was_full := false
var input_enabled := true


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.4
	sh.height = 1.2
	cs.shape = sh
	cs.position.y = 0.6
	add_child(cs)
	ch = Character.new()
	add_child(ch)
	ch.setup("player")
	ch.scale = Vector3.ONE * 1.0
	carry = Holder.new().setup(Bal.carry(Game.lvl("carry")), [], Holder.Layout.COLUMN)
	carry.sway = 0.06
	carry.max_visible = 80
	ch.carry_mount.add_child(carry)
	carry.changed.connect(_on_carry_changed)
	_max_label = UI3D.label("FULL", 34, Color(1.0, 0.8, 0.62))
	_max_label.position = Vector3(0, 2.0, 0)
	_max_label.visible = false
	add_child(_max_label)
	# soft blob shadow ring to read position on any surface
	var ring := MeshInstance3D.new()
	var k := MeshKit.new()
	k.torus(0.42, 0.035, Color(1, 1, 1), Transform3D.IDENTITY, 28, 4)
	ring.mesh = k.commit()
	ring.material_override = Mats.flat(Color(0.86, 0.72, 0.46, 0.9))
	ring.position.y = 0.05
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	Game.upgraded.connect(func(_id, _l): refresh())


func refresh() -> void:
	carry.capacity = Bal.carry(Game.lvl("carry"))
	_on_carry_changed()


func _on_carry_changed() -> void:
	var full := carry.space() <= 0
	_max_label.visible = full
	var h := 0.0
	for t in carry.items:
		h += Items.height(t)
	_max_label.position.y = 1.35 + h
	ch.carrying = carry.count() > 0 or carry.incoming > 0
	if full and not _was_full:
		Sfx.play("deny", -8.0, 1.3)
	_was_full = full
	ch.squash(0.6)


func _physics_process(dt: float) -> void:
	var dir := Vector2.ZERO
	if input_enabled:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var kb := Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		if kb != Vector2.ZERO:
			dir = kb.normalized()
		if joy.length() > 0.08:
			dir = joy
	var speed := Bal.player_speed(Game.lvl("speed"))
	var target := Vector3(dir.x, 0, dir.y) * speed
	velocity.x = move_toward(velocity.x, target.x, dt * 60.0)
	velocity.z = move_toward(velocity.z, target.z, dt * 60.0)
	velocity.y = 0.0
	move_and_slide()
	position.y = 0.0
	var spd := Vector2(velocity.x, velocity.z).length()
	ch.move_speed = clampf(spd / speed, 0.0, 1.0)
	if spd > 0.3:
		ch.face(velocity, dt, 14.0)
		_step_t -= dt * spd
		if _step_t <= 0.0:
			_step_t = 1.6
			Sfx.play("step", 0.0, 1.0, 0.15)
		_dust_t -= dt
		if _dust_t <= 0.0 and spd > speed * 0.7:
			_dust_t = 0.22
			Fx.puff(get_tree().current_scene, global_position + Vector3(0, 0.08, 0), Color(1.0, 0.95, 0.85), 1)
	_interact(dt)


func _interact(dt: float) -> void:
	for z in get_tree().get_nodes_in_group("zones"):
		var zone := z as Zone
		if zone.is_visible_in_tree() and zone.contains(global_position, 0.1):
			zone.tick(self, carry, dt, 0.06)
