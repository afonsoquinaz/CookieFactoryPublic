class_name DeskB
extends Building
## The Enterprise Desk: contracts up on a big screen ("40 Chat 7B
## Tokens"). Deliver them on its pad for a big cash reward and sparks.

var inbox: Holder
var _rows: Array[Node3D] = []


func _build() -> void:
	inbox = Holder.new().setup(999, [], Holder.Layout.NONE)
	inbox.accept_fn = func(t): return Game.wanted_items().has(t)
	inbox.position = Vector3(0, 1.2, -0.5)
	add_child(inbox)
	inbox.landed.connect(_on_landed)
	add_port(inbox, null, "in")
	Game.orders_changed.connect(_refresh_rows)
	Game.refill_orders()
	_refresh_rows.call_deferred()


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -1.0, 4.0, 0.75)]


func _visual(root: Node3D, _t: int) -> void:
	Mats.inst(MeshKit.cached("desk", DeskB.mesh), root)


func _on_landed(t: String) -> void:
	inbox.take(t)
	Game.deliver(t)
	bump(0.03)


func need(t: String) -> float:
	return 0.55 if Game.wanted_items().has(t) else 0.0


func _refresh_rows() -> void:
	for r in _rows:
		r.queue_free()
	_rows.clear()
	var i := 0
	for o in Game.orders:
		var n := Node3D.new()
		n.position = Vector3(-1.1 + (i % 2) * 2.2 * 0.5 + 0.55 * 0, 2.3 - (i / 2) * 0.62, -0.55)
		n.position = Vector3(-0.85 + (i % 2) * 1.7, 2.35 - (i / 2) * 0.62, -0.5)
		add_child(n)
		var ic := UI3D.icon(Defs.item_icon(o["item"]), 0.0017)
		ic.position = Vector3(-0.35, 0, 0)
		n.add_child(ic)
		var l := UI3D.label("%d/%d" % [int(o["got"]), int(o["count"])], 26)
		l.position = Vector3(0.2, 0, 0)
		n.add_child(l)
		_rows.append(n)
		i += 1


func status() -> String:
	return "Deliver contracts here for cash and sparks."


func info() -> Array:
	var out := []
	for o in Game.orders:
		out.append([Defs.item_icon(o["item"]), "%s  %d/%d  ->  $%s + %d sparks" % [Defs.item_name(o["item"]), int(o["got"]), int(o["count"]), Fmt.num(o["reward"]), int(o["gems"])]])
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
