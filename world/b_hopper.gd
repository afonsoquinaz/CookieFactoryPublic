class_name HopperB
extends LineModule
## A silo over the tube holding one ingredient. Every dough ball that needs
## it stops underneath for a dose. A hopper whose ingredient the line's
## recipe doesn't use shows a grey "unused" tag.

var ing := "sugar"
var store: Holder
var _fill: Node3D
var _label: Label3D
var _bang: Label3D
var _unused: Label3D
var _silo: Node3D
var waiting := false


func _build() -> void:
	ing = str(data.get("ing", "sugar"))
	store = Holder.new().setup(10, [ing], Holder.Layout.NONE)
	store.position = Vector3(0, TUBE_Y + 1.4, TUBE_Z)
	add_child(store)
	var z := add_zone(Zone.Kind.GIVE, [store], Vector2(0, PAD_Z), Vector2(1.6, 1.3), Defs.ITEMS[ing]["color"])
	add_port(store, z, "in")
	_label = UI3D.label("0/10", 26)
	_label.position = Vector3(0.7, 1.4, 0.2)
	add_child(_label)
	_bang = UI3D.label("!", 70, Color(1.0, 0.62, 0.5), 10)
	_bang.position = Vector3(0.55, 3.9, TUBE_Z)
	_bang.visible = false
	add_child(_bang)
	_unused = UI3D.label("not in recipe", 22, Color(0.85, 0.85, 0.85))
	_unused.position = Vector3(0, 0.45, 0.6)
	_unused.visible = false
	add_child(_unused)
	store.changed.connect(_update)
	store.landed.connect(func(_t): bump(0.04))


func _visual(root: Node3D, t: int) -> void:
	_tube(root, size_m().x)
	_silo = Node3D.new()
	_silo.position = Vector3(0, TUBE_Y + 0.47, TUBE_Z)
	root.add_child(_silo)
	Mats.inst(MeshKit.cached("silo_%s_%d" % [ing, t], func(): return LineArt.silo(ing, t)), _silo)
	var b := UI3D.badge(ing, Pal.STEEL_DARK, 0.55)
	b.position = Vector3(0, [1.7, 2.0, 2.6, 2.6, 2.6][t], 0)
	_silo.add_child(b)
	_fill = Node3D.new()
	_fill.position = Vector3(0, [0.62, 0.7, 0.85, 0.85, 0.85][t], [0.46, 0.45, 0.51, 0.51, 0.51][t])
	_silo.add_child(_fill)
	var fk := MeshKit.new()
	fk.rbox(Vector3(0.08, 0.56 if t < 2 else 0.74, 0.02), 0.01, Defs.ITEMS[ing]["color"].lightened(0.15), MeshKit.at(0, 0.28 if t < 2 else 0.37, 0))
	var fm := Mats.inst(fk.commit(), _fill, Transform3D.IDENTITY, false)
	fm.material_override = Mats.glow()
	_bang.position.y = TUBE_Y + [2.0, 2.4, 3.0, 3.0, 3.0][t]
	_update()


func _on_level() -> void:
	store.capacity = Bal.hopper_cap(level)
	_update()


func _on_links() -> void:
	if _unused:
		_unused.visible = line != null and not line.uses(ing)


func _update() -> void:
	_label.text = "%d/%d" % [store.count(), store.capacity]
	_label.modulate = Color(1.0, 0.72, 0.62) if store.count() == 0 else Color(1, 1, 1)
	if _fill:
		var f := float(store.count()) / maxf(1.0, store.capacity)
		_fill.scale = Vector3(1, maxf(0.02, f), 1)
		_fill.visible = store.count() > 0


func dose() -> void:
	if _silo:
		var tw := _silo.create_tween()
		tw.tween_property(_silo, "scale", Vector3(1.06, 0.92, 1.06), 0.08)
		tw.tween_property(_silo, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(dt: float) -> void:
	super(dt)
	_bang.visible = waiting and store.count() == 0
	if _bang.visible:
		_bang.position.y = TUBE_Y + 2.4 + absf(sin(_t * 6.0)) * 0.25


func need(t: String) -> float:
	if line == null or not line.uses(ing):
		return 0.0
	return super(t) * (2.0 if waiting else 1.0)


func save_contents() -> Dictionary:
	return {"store": store.items.duplicate()}


func load_contents(d: Dictionary) -> void:
	Building.fill(store, d.get("store", []))


func status() -> String:
	if line == null:
		return "Not connected to a line"
	if not line.uses(ing):
		return "The line's recipe doesn't use %s" % Defs.item_name(ing).to_lower()
	return "Adds %s to %s" % [Defs.item_name(ing).to_lower(), Defs.recipe(line.product)["name"]]


func info() -> Array:
	return [[ing, "%s %d / %d" % [Defs.item_name(ing), store.count(), store.capacity]]]


func upgrade_info() -> Array:
	return [["Holds", str(Bal.hopper_cap(level)), str(Bal.hopper_cap(level + 1))]]
