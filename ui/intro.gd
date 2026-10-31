class_name Intro
extends Control
## The opening story of a new game (about 20 seconds, skippable): you on an
## empty plot with a big idea; a delivery van pulls up; the courier carries
## a second-hand solar panel to one side, you carry the server to the
## other; they're unboxed and plugged in; you type at a terminal and your
## first LLM (Pico 1B) comes online; the home internet line beams up to the
## sky, the first request comes down, the first tokens go back up and are
## paid. Then the HUD and the tutorial take over.

signal finished

const SCRIPT := [
	# [time, caption]
	[0.3, "A patch of land. One power socket. A big idea."],
	[3.2, "Delivery for you!"],
	[6.9, "A second-hand solar panel..."],
	[8.7, "...and a server with one serious GPU."],
	[11.2, "Plug it in."],
	[12.8, ""],
	[17.4, "Somewhere out there, someone asks a question..."],
	[20.2, "Your first tokens. Welcome to the token business."],
]
const TERMINAL := [
	"$ pull pico-1b",
	"  downloading weights   ████████████  100%",
	"$ serve pico-1b --public",
	"  model loaded on GPU  ·  15 ms per token",
	"  online  ·  waiting for the first request...",
]
const END := 23.0

var world: World
var _t := 0.0
var _step := -1
var _done := false
var _caption: Label
var _top_bar: ColorRect
var _bot_bar: ColorRect
var _term: PanelContainer
var _term_label: Label
var _skip: JuicyButton
var _van: Node3D
var _boxes: Array[Node3D] = []
var _farm: Building
var _server: Building
var _net: Node3D
var _farm_shown := false
var _server_shown := false
var _plugged := false
var _online := false
var _first_token := false
var _tokens0 := 0.0
var _money0 := 0.0
var _mid := Vector3(-4, 0, -7)       # between the panel and the server
var _you: Character                  # the founder
var _courier: Character
var _walks := {}                     # Character -> [[t0, t1, from, to], ...]


## A brand-new game opens with the story; a saved one never does.
static func needed() -> bool:
	return not bool(Game.settings.get("intro_done", false)) and Game.tutorial_step == 0 \
		and float(Game.stats["tokens"]) <= 0.0 and Game.count_of("server") == 1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# cinema bars
	_top_bar = ColorRect.new()
	_top_bar.color = Color(0.03, 0.04, 0.06, 0.92)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_bar)
	_bot_bar = ColorRect.new()
	_bot_bar.color = Color(0.03, 0.04, 0.06, 0.92)
	_bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bot_bar)
	_caption = Kit.game("", 30, Kit.WHITE, 8)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_term = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.08, 0.9)
	sb.border_color = Color(0.3, 0.9, 0.7, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_term.add_theme_stylebox_override("panel", sb)
	_term.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_term.visible = false
	add_child(_term)
	_term_label = Label.new()
	_term_label.add_theme_font_size_override("font_size", 20)
	_term_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.75))
	_term.add_child(_term_label)
	_skip = Kit.juicy("Skip", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 18, Vector2(110, 52))
	_skip.pressed.connect(_finish)
	add_child(_skip)
	# the stage: what came in the boxes is hidden until it's unboxed
	for n in world.bnodes.values():
		if n.kind == "src_power" and _farm == null:
			_farm = n
		elif n.kind == "server" and _server == null:
			_server = n
	for b in [_farm, _server]:
		if b:
			b.visible = false
	for c in world.get_children():
		if c is NetworkView:
			_net = c
			_net.visible = false
	Market.paused = true
	_tokens0 = float(Game.stats["tokens"])
	_money0 = Game.money
	if _farm and _server:
		_mid = (_farm.global_position + _server.global_position) * 0.5
	# you, on the empty plot, looking at the street
	_you = _person("player", _mid + Vector3(1.0, 0, 3.4))
	_you.rotation.y = 0.0
	var van_back := Vector3(_mid.x + 0.9, 0, -0.4)
	_walks[_you] = [
		[5.0, 6.3, _you.position, van_back],
		[6.55, 8.35, van_back, _front(_server) + Vector3(-1.2, 0, 0.9)],
	]
	# the camera starts down the street and settles over the garage plot
	world.cam.free_focus = false
	world.cam.global_position = Vector3(_mid.x - 6.0, 0, 1.0)
	world.cam.zoom = 1.9
	world.cam.snap()
	world.cam.fly_to(Vector3(_mid.x, 0, _mid.z + 4.5), 1.3, 3.5)
	Sfx.play("open", -8.0, 0.8)


func _process(dt: float) -> void:
	if _done:
		return
	_t += dt
	_layout()
	while _step + 1 < SCRIPT.size() and _t >= float(SCRIPT[_step + 1][0]):
		_step += 1
		_show_caption(str(SCRIPT[_step][1]))
	# the delivery van
	if _t >= 3.0 and _van == null:
		_van = _make_van()
	if _van:
		var arrive := clampf((_t - 3.0) / 2.6, 0.0, 1.0)
		var leave := clampf((_t - 9.6) / 2.5, 0.0, 1.0)
		var x := lerpf(_mid.x - 42.0, _mid.x, 1.0 - pow(1.0 - arrive, 3.0)) + leave * leave * 45.0
		_van.global_position = Vector3(x, 0.06, 0.9)
		_van.rotation.z = sin(_t * 18.0) * 0.006 * (1.0 if arrive < 1.0 or leave > 0.0 else 0.0)
	_move_people(dt)
	if _t >= 5.6 and _courier == null:
		_courier_out()
	if _t >= 6.75 and _boxes.is_empty() and _courier:
		_put_down(_courier, _front(_farm))
	if _t >= 8.45 and _boxes.size() == 1:
		_put_down(_you, _front(_server))
	if _t >= 8.6 and _courier and _courier.visible:
		_courier.visible = false
	if _t >= 7.1 and not _farm_shown:
		_farm_shown = true
		_unbox(0, _farm)
	if _t >= 9.2 and not _server_shown:
		_server_shown = true
		_unbox(1, _server)
		world.cam.fly_to(Vector3(_mid.x + 1.0, 0, _mid.z + 3.0), 1.45, 1.6)
	if _t >= 11.6 and not _plugged:
		_plugged = true
		if _net:
			_net.visible = true
		if _farm and _server:
			_sparks_along(_farm.global_position, _server.global_position + Vector3(-2.5, 0, 0))
		Sfx.play("upgrade", -4.0, 1.2)
	# the deploy terminal
	if _you:
		_you.work = "type" if _t >= 12.6 and _t < 17.2 else ("cheer" if _t >= 20.0 and _t < 21.8 or _t >= 3.4 and _t < 4.6 else "")
	if _t >= 12.8 and _t < 17.4:
		_term.visible = true
		_type_terminal(_t - 12.8)
	elif _t >= 17.4 and _term.visible:
		var tw := create_tween()
		tw.tween_property(_term, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): _term.visible = false)
	if _t >= 17.4 and not _online:
		_online = true
		Market.paused = false
		world.cam.fly_to(Vector3(_mid.x + 1.0, 0, _mid.z + 2.5), 1.75, 2.4)
		Sfx.play("levelup", -8.0, 1.4)
	if _online and not _first_token and _t >= 19.9 and float(Game.stats["tokens"]) > _tokens0:
		_first_token = true
		if _server and is_inside_tree():
			Fx.burst(get_tree().current_scene, _server.to_world(ServerB.CORE_X, ServerB.BUS_Z, 4.0), Pal.GOLD, 24)
			_token_pop()
		Sfx.play("cash", -2.0)
	if _t >= END:
		_finish()


## "+1 token" rises from the server in big gold letters, with its price.
func _token_pop() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var big := Kit.game("+%s tokens" % Fmt.tokens(float(Game.stats["tokens"]) - _tokens0), 54, Color(1.0, 0.86, 0.32), 10)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var paid := Kit.game("+$%s, paid on the spot" % Fmt.num(maxf(1.0, Game.money - _money0)), 26, Kit.WHITE, 7)
	paid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(paid)
	add_child(box)
	box.size = Vector2(420, 110)
	var sp := cam.unproject_position(_server.to_world(ServerB.CORE_X, ServerB.BUS_Z, 3.0))
	var vw := get_viewport_rect().size.x
	box.position = Vector2(clampf(sp.x - 210.0, 10.0, vw - 430.0), sp.y - 110.0)
	box.pivot_offset = Vector2(210, 55)
	box.scale = Vector2(0.3, 0.3)
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(box, "position:y", box.position.y - 90.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(box, "modulate:a", 0.0, 0.5)


func _layout() -> void:
	var vs := get_viewport_rect().size
	var bar := vs.y * 0.11
	var k := clampf(minf(_t / 0.6, (END - _t) / 0.6), 0.0, 1.0)
	_top_bar.position = Vector2(0, -bar * (1.0 - k))
	_top_bar.size = Vector2(vs.x, bar)
	_bot_bar.position = Vector2(0, vs.y - bar * k)
	_bot_bar.size = Vector2(vs.x, bar)
	_caption.size = Vector2(vs.x - 60, bar)
	_caption.position = Vector2(30, vs.y - bar * k + (bar - 70) * 0.5)
	_term.custom_minimum_size = Vector2(minf(600.0, vs.x - 40.0), 0)
	_term.position = Vector2((vs.x - _term.size.x) * 0.5, vs.y * 0.56)
	_skip.size = _skip.custom_minimum_size
	_skip.position = Vector2(vs.x - _skip.size.x - 18, bar * k - _skip.size.y - 10 if bar * k > _skip.size.y + 20 else 14)


func _show_caption(text: String) -> void:
	_caption.text = text
	if text != "":
		_caption.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_caption, "modulate:a", 1.0, 0.35)


func _type_terminal(t: float) -> void:
	var shown := ""
	var budget := t * 34.0          # characters per second
	for line in TERMINAL:
		if budget <= 0.0:
			break
		var take := mini(line.length(), int(budget))
		shown += line.substr(0, take) + "\n"
		budget -= line.length() + 6.0
	if int(t * 2.5) % 2 == 0:
		shown = shown.strip_edges(false, true) + " _"
	_term_label.text = shown


# ---------------------------------------------------------------- props

func _make_van() -> Node3D:
	var n := Node3D.new()
	world.add_child(n)
	var k := MeshKit.new()
	# a white parcel van facing +x: a tall cargo box, a short cab with a
	# wide windscreen, a teal stripe with a parcel badge, lights and wheels
	var white := Color(0.95, 0.95, 0.93)
	var teal := Color(0.22, 0.62, 0.62)
	var glass := Color(0.32, 0.44, 0.56)
	k.rbox(Vector3(2.3, 1.25, 1.1), 0.08, white, MeshKit.at(-0.35, 0.95, 0), 1)            # cargo box
	k.rbox(Vector3(0.95, 0.75, 1.06), 0.1, white, MeshKit.at(1.15, 0.72, 0), 1)           # cab
	k.box(Vector3(0.5, 0.42, 1.0), white, MeshKit.xf(Vector3(1.05, 1.18, 0), Vector3(0, 0, 25)))
	k.box(Vector3(0.04, 0.36, 0.96), glass, MeshKit.xf(Vector3(1.4, 1.16, 0), Vector3(0, 0, 24)))   # windscreen
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.5, 0.3, 0.02), glass, MeshKit.at(1.08, 1.0, sz * 0.54))           # side windows
		k.box(Vector3(2.3, 0.14, 0.02), teal, MeshKit.at(-0.35, 0.62, sz * 0.556))          # stripe
		k.box(Vector3(0.46, 0.4, 0.02), Color(0.78, 0.6, 0.38), MeshKit.at(-0.3, 1.08, sz * 0.556))   # parcel badge
		k.box(Vector3(0.48, 0.05, 0.022), Color(0.92, 0.86, 0.7), MeshKit.at(-0.3, 1.2, sz * 0.556))
		for wx in [-1.05, 1.15]:
			k.cyl(0.22, 0.16, Color(0.12, 0.12, 0.13), MeshKit.xf(Vector3(wx, 0.22, sz * 0.5), Vector3(90, 0, 0)), 12)
			k.cyl(0.11, 0.17, Color(0.7, 0.7, 0.72), MeshKit.xf(Vector3(wx, 0.22, sz * 0.5), Vector3(90, 0, 0)), 8)
		k.box(Vector3(0.04, 0.1, 0.18), Color(1.0, 0.95, 0.75, 0.4), MeshKit.at(1.63, 0.62, sz * 0.36))   # headlights
		k.box(Vector3(0.04, 0.16, 0.1), Color(0.95, 0.25, 0.2, 0.5), MeshKit.at(-1.51, 0.75, sz * 0.46))  # tail lights
	k.box(Vector3(0.1, 0.14, 1.12), Color(0.25, 0.26, 0.28), MeshKit.at(1.62, 0.36, 0))    # bumper
	k.box(Vector3(0.1, 0.14, 1.12), Color(0.25, 0.26, 0.28), MeshKit.at(-1.52, 0.36, 0))
	Mats.inst(k.commit(), n)
	n.scale = Vector3.ONE * 1.25
	return n


func _person(look: String, at: Vector3) -> Character:
	var ch := Character.new()
	world.add_child(ch)
	ch.setup(look, 7)
	ch.position = at
	ch.scale = Vector3.ONE * 1.25
	return ch


## Where a box goes: in front of the building, on the street side.
func _front(b: Building) -> Vector3:
	if b == null:
		return _mid
	return b.global_position + Vector3(0, 0, maxf(b.size_m().y * 0.5 - 0.6, 1.0))


func _box_mesh(s: float, tag: Color) -> ArrayMesh:
	var k := MeshKit.new()
	k.box(Vector3(s, s * 0.8, s), Color(0.76, 0.6, 0.4), MeshKit.at(0, s * 0.4, 0))
	k.box(Vector3(s * 1.02, 0.06, s * 0.16), Color(0.9, 0.85, 0.7), MeshKit.at(0, s * 0.8, 0))
	k.box(Vector3(s * 0.34, s * 0.18, 0.01), tag, MeshKit.at(0, s * 0.45, s * 0.505))
	return k.commit()


func _carry(ch: Character, tag: Color) -> void:
	var holder := Node3D.new()
	ch.carry_mount.add_child(holder)
	Mats.inst(_box_mesh(0.62, tag), holder, MeshKit.at(0, 0.05, 0.1))
	ch.carrying = true


## The courier hops out of the van with the solar panel's box.
func _courier_out() -> void:
	var door := Vector3(_mid.x - 0.7, 0, -0.4)
	_courier = _person("courier", door)
	_carry(_courier, Color(0.46, 0.82, 0.52))
	var spot := _front(_farm) + Vector3(0.9, 0, 0.9)
	_walks[_courier] = [[5.65, 6.7, door, spot], [7.0, 8.5, spot, door]]
	Sfx.play("pop", -4.0)


func _put_down(ch: Character, at: Vector3) -> void:
	for c in ch.carry_mount.get_children():
		c.queue_free()
	ch.carrying = false
	var b := Node3D.new()
	world.add_child(b)
	var big := _boxes.size() == 1
	Mats.inst(_box_mesh(1.5 if big else 1.2, Color(0.3, 0.62, 0.42) if big else Color(0.46, 0.82, 0.52)), b)
	b.global_position = at
	b.scale = Vector3(0.5, 0.5, 0.5)
	b.create_tween().tween_property(b, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_boxes.append(b)
	Fx.puff(get_tree().current_scene, at, Pal.CREAM, 6)
	Sfx.play("drop", -4.0)
	if ch == _you:
		_you.carrying = false


## People walk their scheduled legs (arms out while carrying).
func _move_people(dt: float) -> void:
	for ch in _walks:
		if not is_instance_valid(ch):
			continue
		var moving := false
		for leg in _walks[ch]:
			if _t >= float(leg[0]) and _t < float(leg[1]):
				var f := (_t - float(leg[0])) / (float(leg[1]) - float(leg[0]))
				var from: Vector3 = leg[2]
				var to: Vector3 = leg[3]
				ch.position = from.lerp(to, smoothstep(0.0, 1.0, f) * 0.3 + f * 0.7)
				ch.face(to - from, dt, 10.0)
				moving = true
		ch.move_speed = 0.75 if moving else 0.0
		if not moving and ch == _you and _t >= 5.0:
			# face the camera-ish (the street) while standing
			ch.face(Vector3(0, 0, 1), dt, 4.0)
	# you pick up the server's box at the van
	if _you and _t >= 6.35 and _t < 6.5 and not _you.carrying and _boxes.size() <= 1:
		_carry(_you, Color(0.3, 0.62, 0.42))


func _unbox(i: int, b: Building) -> void:
	if i < _boxes.size():
		var box := _boxes[i]
		Fx.burst(get_tree().current_scene, box.global_position + Vector3(0, 1, 0), Pal.CREAM, 18)
		var tw := box.create_tween()
		tw.tween_property(box, "scale", Vector3(1.3, 0.1, 1.3), 0.25)
		tw.tween_callback(box.queue_free)
	if b == null:
		return
	b.visible = true
	b.scale = Vector3(0.05, 0.05, 0.05)
	var tw2 := b.create_tween()
	tw2.tween_property(b, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sfx.play("upgrade", -2.0, 0.9 + i * 0.2)


func _sparks_along(a: Vector3, b: Vector3) -> void:
	for i in 8:
		var p := a.lerp(b, i / 7.0) + Vector3(0, 2.2 - sin(i / 7.0 * PI) * 0.6, 0)
		get_tree().create_timer(i * 0.07).timeout.connect(func():
			Fx.burst(get_tree().current_scene, p, Color(1.0, 0.95, 0.55), 5, false))


func _finish() -> void:
	if _done:
		return
	_done = true
	for b in [_farm, _server]:
		if b:
			b.visible = true
			b.scale = Vector3.ONE
	if _net:
		_net.visible = true
	if _van:
		_van.queue_free()
	for ch in [_you, _courier]:
		if ch and is_instance_valid(ch):
			ch.queue_free()
	for bx in _boxes:
		if is_instance_valid(bx):
			bx.queue_free()
	Market.paused = false
	Game.settings["intro_done"] = true
	Game.save_game()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		finished.emit()
		queue_free())
