class_name MixerB
extends LineModule
## Start of a production line: drop wheat on its pad; it mixes a dough ball
## and pushes it into the tube whenever the line has room.

var wheat: Holder
var _hook: Node3D
var _label: Label3D
var _warn: Label3D
var _spin := 0.0


func _build() -> void:
	wheat = Holder.new().setup(12, ["wheat"], Holder.Layout.NONE)
	wheat.position = Vector3(0, 1.5, TUBE_Z)
	add_child(wheat)
	var z := add_zone(Zone.Kind.GIVE, [wheat], Vector2(0, PAD_Z), Vector2(1.6, 1.3), Defs.ITEMS["wheat"]["color"])
	add_port(wheat, z, "in")
	var b := UI3D.badge("wheat", Pal.STEEL_DARK, 0.55)
	b.position = Vector3(0, 3.0, TUBE_Z)
	add_child(b)
	_label = UI3D.label("0/12", 26)
	_label.position = Vector3(0.7, 1.4, 0.2)
	add_child(_label)
	_warn = UI3D.label("Needs an Oven at the end", 32, Color(1.0, 0.75, 0.6))
	_warn.position = Vector3(0.6, 3.6, TUBE_Z)
	_warn.visible = false
	add_child(_warn)
	wheat.changed.connect(_update)


func _visual(root: Node3D, t: int) -> void:
	_tube(root, size_m().x)
	Mats.inst(MeshKit.cached("mixer_%d" % t, func(): return LineArt.mixer(t)), root)
	_hook = Node3D.new()
	var s := 1.0 + t * 0.06
	_hook.position = Vector3(0.0, 1.85 * s, TUBE_Z)
	root.add_child(_hook)
	Mats.inst(MeshKit.cached("mixer_hook", LineArt.hook), _hook, Transform3D.IDENTITY, false)


func _on_level() -> void:
	wheat.capacity = Bal.mixer_cap(level)
	_update()


func _on_links() -> void:
	if _warn:
		_warn.visible = line == null


func _update() -> void:
	_label.text = "%d/%d" % [wheat.count(), wheat.capacity]
	_label.modulate = Color(1.0, 0.72, 0.62) if wheat.count() == 0 else Color(1, 1, 1)


## Called by the line when it mixes a ball.
func mixed() -> void:
	_spin = 1.0
	bump(0.03)


func _process(dt: float) -> void:
	super(dt)
	_spin = maxf(0.0, _spin - dt * 0.8)
	if _hook:
		_hook.rotation.y += dt * (1.0 + _spin * 12.0)
	if _warn.visible:
		_warn.position.y = 3.6 + sin(_t * 3.0) * 0.06


func save_contents() -> Dictionary:
	return {"wheat": wheat.items.duplicate()}


func load_contents(d: Dictionary) -> void:
	Building.fill(wheat, d.get("wheat", []))


func status() -> String:
	if line == null:
		return "Not connected: place tubes or hoppers and an Oven to its right"
	return "Line makes: %s" % Defs.recipe(line.product)["name"]


func info() -> Array:
	return [
		["dough", "A dough ball every %.1fs" % Bal.mixer_interval(level)],
		["conveyor", "Belt %.1f m/s" % Bal.belt_speed(level)],
		["wheat", "Wheat %d / %d" % [wheat.count(), wheat.capacity]],
	]


func upgrade_info() -> Array:
	var n := level + 1
	return [
		["Dough every", "%.2fs" % Bal.mixer_interval(level), "%.2fs" % Bal.mixer_interval(n)],
		["Belt speed", "%.1f" % Bal.belt_speed(level), "%.1f" % Bal.belt_speed(n)],
		["Holds", str(Bal.mixer_cap(level)), str(Bal.mixer_cap(n))],
	]


func need(t: String) -> float:
	if line == null:
		return 0.0
	return super(t) * 1.5
