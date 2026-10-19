class_name DeskB
extends Building
## The Enterprise Desk: contracts up on a big screen ("serve 4.5M tokens of
## Code 13B"). Enterprise customers' calls come in through the API on top of
## everyone else's (paying x1.2) and the whole contract pays a bonus in cash
## and sparks when it's served.

var _rows: Array[Node3D] = []
var _bars: Array[MeshInstance3D] = []
var _labels: Array[Label3D] = []


func _build() -> void:
	Game.orders_changed.connect(_refresh_rows)
	Game.refill_orders()
	_refresh_rows.call_deferred()


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -1.0, 4.0, 0.75)]


func _visual(root: Node3D, _t: int) -> void:
	Mats.inst(MeshKit.cached("desk", DeskB.mesh), root)


func _refresh_rows() -> void:
	for r in _rows:
		r.queue_free()
	_rows.clear()
	_bars.clear()
	_labels.clear()
	var i := 0
	for o in Game.orders:
		var n := Node3D.new()
		n.position = Vector3(-0.85 + (i % 2) * 1.7, 2.35 - (i / 2) * 0.62, -0.5)
		add_child(n)
		var ic := UI3D.icon("tk_" + str(o["model"]), 0.0017)
		ic.position = Vector3(-0.38, 0.04, 0)
		n.add_child(ic)
		var l := UI3D.label("", 22)
		l.position = Vector3(0.18, 0.08, 0)
		n.add_child(l)
		var bar := Mats.inst(MeshKit.cached("desk_bar", func():
			var k := MeshKit.new()
			k.rbox(Vector3(1.0, 0.06, 0.01), 0.01, Items.lit(Color(0.45, 1.0, 0.7), 0.45), MeshKit.at(0.5, 0, 0))
			return k.commit()), n)
		bar.position = Vector3(-0.5, -0.17, 0.02)
		_rows.append(n)
		_bars.append(bar)
		_labels.append(l)
		i += 1
	_update_rows()


func _process(dt: float) -> void:
	super(dt)
	if int(_t * 2.0) != int((_t - dt) * 2.0):
		_update_rows()


func _update_rows() -> void:
	for i in mini(_rows.size(), Game.orders.size()):
		var o: Dictionary = Game.orders[i]
		var f := clampf(float(o["got"]) / maxf(0.001, float(o["count"])), 0.0, 1.0)
		_labels[i].text = "%s / %s" % [Fmt.tokens(o["got"]), Fmt.tokens(o["count"])]
		_bars[i].scale = Vector3(maxf(0.01, f), 1, 1)


func status() -> String:
	if Game.orders.is_empty():
		return "Contracts arrive for models you can serve."
	return "Serve these tokens through the API for a bonus in cash and sparks."


func info() -> Array:
	var out := []
	for o in Game.orders:
		var rid: String = o["model"]
		var note := "" if Market.cap.has(rid) else "  (no server runs it!)"
		out.append(["tk_" + rid, "%s  %s / %s  ->  $%s + %d sparks%s" % [Defs.model_name(rid), Fmt.tokens(o["got"]), Fmt.tokens(o["count"]), Fmt.num(o["reward"]), int(o["gems"]), note]])
	return out


static func mesh() -> Mesh:
	var k := MeshKit.new()
	# a reception desk in front of a big contracts screen on two posts
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.14, 2.9, 0.14), 0.03, Pal.STEEL_DARK, MeshKit.at(sx * 1.55, 1.45, -0.55))
	k.rbox(Vector3(3.2, 1.5, 0.12), 0.05, Color(0.16, 0.17, 0.2), MeshKit.at(0, 2.1, -0.6))
	k.rbox(Vector3(3.0, 1.32, 0.13), 0.04, Color(0.2, 0.26, 0.34, 0.85), MeshKit.at(0, 2.1, -0.6))
	k.rbox(Vector3(3.5, 0.12, 0.4), 0.03, Color(0.3, 0.66, 0.68), MeshKit.at(0, 2.95, -0.6))
	for i in 4:
		k.rbox(Vector3(1.2, 0.5, 0.02), 0.03, Color(0.24, 0.32, 0.42, 0.7), MeshKit.at(-0.85 + (i % 2) * 1.7, 2.35 - (i / 2) * 0.62, -0.53))
		k.rbox(Vector3(1.2, 0.04, 0.02), 0.01, Color(0.4, 0.9, 0.9, 0.45), MeshKit.at(-0.85 + (i % 2) * 1.7, 2.58 - (i / 2) * 0.62, -0.52))
	k.rbox(Vector3(2.4, 0.8, 0.5), 0.08, Color(0.95, 0.95, 0.96), MeshKit.at(0, 0.4, -0.65))
	k.rbox(Vector3(2.5, 0.06, 0.6), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(0, 0.82, -0.65))
	k.rbox(Vector3(0.3, 0.2, 0.02), 0.02, Color(0.14, 0.15, 0.18), MeshKit.xf(Vector3(0.6, 0.95, -0.7), Vector3(-15, 0, 0)))
	return k.commit()
