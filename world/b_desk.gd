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
		n.position = Vector3(-0.85 + (i % 2) * 1.7, 2.35 - (i / 2) * 0.62, -0.42)
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


## A reception lobby in front of a big contracts screen: the screen hangs in
## a truss gantry with a lit header and spotlights; a curved reception desk
## with monitors, a bell and papers; a waiting corner, a queue rope, plants.
## The four row panels stay where _refresh_rows puts the icons and bars.
static func mesh() -> Mesh:
	var k := MeshKit.new()
	var teal := Color(0.3, 0.66, 0.68)
	var white := Color(0.95, 0.95, 0.96)
	var dark := Color(0.16, 0.17, 0.2)
	var steel := Pal.STEEL_DARK
	var glow := Color(0.5, 0.95, 1.0, 0.4)
	# lobby floor: pale tiles with seams, a teal rug, a kerb
	k.box(Vector3(3.8, 0.03, 1.8), Color(0.86, 0.86, 0.85), MeshKit.at(0, 0.015, 0))
	for i in 10:
		k.box(Vector3(0.012, 0.006, 1.8), Color(0.78, 0.78, 0.77), MeshKit.at(-1.71 + i * 0.38, 0.032, 0))
	for j in 4:
		k.box(Vector3(3.8, 0.006, 0.012), Color(0.78, 0.78, 0.77), MeshKit.at(0, 0.032, -0.675 + j * 0.45))
	k.box(Vector3(2.2, 0.012, 0.7), teal.darkened(0.15), MeshKit.at(0, 0.036, 0.35))
	k.box(Vector3(2.0, 0.004, 0.5), teal, MeshKit.at(0, 0.044, 0.35))
	k.box(Vector3(3.8, 0.06, 0.06), Color(0.7, 0.71, 0.72), MeshKit.at(0, 0.03, 0.87))
	# ---- the gantry: two lattice towers and a header truss with a sign
	for sx in [-1.0, 1.0]:
		var px: float = sx * 1.72
		k.box(Vector3(0.42, 0.06, 0.42), steel, MeshKit.at(px, 0.06, -0.6))
		TownArt.lattice(k, Vector3(px, 0.09, -0.6), Vector3(px, 3.05, -0.6), 0.26, Color(0.3, 0.32, 0.36), true)
		# a speaker stack on each tower
		k.box(Vector3(0.3, 0.42, 0.26), dark, MeshKit.at(px, 0.32, -0.6))
		k.cyl(0.08, 0.02, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(px, 0.38, -0.46), Vector3(90, 0, 0)), 8)
		k.cyl(0.04, 0.02, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(px, 0.2, -0.46), Vector3(90, 0, 0)), 6)
		# a vertical light bar
		k.box(Vector3(0.05, 1.5, 0.03), glow, MeshKit.at(px - sx * 0.16, 1.9, -0.45))
	TownArt.lattice(k, Vector3(-1.95, 3.05, -0.6), Vector3(1.95, 3.05, -0.6), 0.26, Color(0.3, 0.32, 0.36))
	k.box(Vector3(2.4, 0.3, 0.06), white, MeshKit.at(0, 3.05, -0.44))
	k.box(Vector3(0.24, 0.24, 0.02), teal, MeshKit.at(-0.95, 3.05, -0.405))
	for i in 3:
		k.sphere(0.025, white, MeshKit.at(-1.01 + i * 0.06, 3.05, -0.39), 5, 3)
	for i in 10:
		k.box(Vector3(0.1, 0.13, 0.015), dark, MeshKit.at(-0.6 + i * 0.15, 3.06, -0.405))
	k.box(Vector3(2.44, 0.025, 0.07), glow, MeshKit.at(0, 2.885, -0.44))
	# spotlights on the header aimed down at the desk
	for i in 4:
		var lx := -1.35 + i * 0.9
		k.box(Vector3(0.04, 0.12, 0.04), steel, MeshKit.at(lx, 3.24, -0.5))
		k.cyl(0.07, 0.18, dark, MeshKit.xf(Vector3(lx, 3.3, -0.52), Vector3(110, 0, 0)), 8)
		k.cyl(0.055, 0.02, Color(1.0, 0.95, 0.8, 0.35), MeshKit.xf(Vector3(lx, 3.24, -0.35), Vector3(110, 0, 0)), 8)
	# ---- the screen (bezel, glass, the four row panels, chrome)
	k.rbox(Vector3(3.2, 1.5, 0.12), 0.05, dark, MeshKit.at(0, 2.1, -0.6))
	k.box(Vector3(3.0, 1.32, 0.13), Color(0.2, 0.26, 0.34, 0.85), MeshKit.at(0, 2.1, -0.6))
	for i in 4:
		var rx := -0.85 + (i % 2) * 1.7
		var ry := 2.35 - (i / 2) * 0.62
		k.box(Vector3(1.2, 0.5, 0.02), Color(0.24, 0.32, 0.42, 0.7), MeshKit.at(rx, ry, -0.53))
		k.box(Vector3(1.2, 0.04, 0.02), Color(0.4, 0.9, 0.9, 0.45), MeshKit.at(rx, ry + 0.23, -0.52))
		k.box(Vector3(0.02, 0.5, 0.02), Color(0.4, 0.9, 0.9, 0.45), MeshKit.at(rx - 0.59, ry, -0.52))
	# a column divider, a status bar on top, a ticker along the bottom
	k.box(Vector3(0.02, 1.2, 0.02), Color(0.32, 0.42, 0.52, 0.7), MeshKit.at(0, 2.08, -0.528))
	k.box(Vector3(2.9, 0.06, 0.02), Color(0.16, 0.22, 0.3, 0.8), MeshKit.at(0, 2.71, -0.528))
	for i in 3:
		var dot: Color = [Color(1.0, 0.4, 0.35), Color(1.0, 0.8, 0.3), Color(0.45, 1.0, 0.6)][i]
		k.box(Vector3(0.04, 0.04, 0.01), Color(dot.r, dot.g, dot.b, 0.4), MeshKit.at(-1.38 + i * 0.07, 2.71, -0.518))
	k.box(Vector3(0.5, 0.025, 0.01), Color(0.6, 0.9, 1.0, 0.45), MeshKit.at(1.1, 2.71, -0.518))
	k.box(Vector3(2.9, 0.07, 0.02), Color(0.12, 0.16, 0.22, 0.8), MeshKit.at(0, 1.47, -0.528))
	for i in 12:
		k.box(Vector3(0.12 + (i * 37 % 5) * 0.03, 0.03, 0.01), Color(0.45, 1.0, 0.7, 0.45) if i % 3 else Color(1.0, 0.8, 0.4, 0.45), MeshKit.at(-1.32 + i * 0.235, 1.47, -0.518))
	# the screen's back: ribs, a cable tray
	for i in 6:
		k.box(Vector3(0.05, 1.3, 0.05), Color(0.26, 0.27, 0.3), MeshKit.at(-1.25 + i * 0.5, 2.1, -0.685))
	k.box(Vector3(2.8, 0.2, 0.04), Color(0.3, 0.32, 0.36), MeshKit.at(0, 1.55, -0.71))
	# ---- the reception desk: a gentle arc of panels
	var arc := 7
	for i in arc:
		var f := (i + 0.5) / arc - 0.5
		var a := f * 34.0
		var x := sin(deg_to_rad(a)) * 3.2
		var z := -0.3 - (1.0 - cos(deg_to_rad(a))) * 3.2
		var seg := MeshKit.xf(Vector3(x, 0, z), Vector3(0, a, 0))
		k.box(Vector3(0.4, 0.92, 0.08), white, seg * MeshKit.at(0, 0.5, 0))
		k.box(Vector3(0.4, 0.1, 0.09), teal, seg * MeshKit.at(0, 0.1, 0.005))
		k.box(Vector3(0.41, 0.025, 0.1), glow, seg * MeshKit.at(0, 0.18, 0.01))
		k.box(Vector3(0.42, 0.04, 0.32), Color(0.62, 0.48, 0.34), seg * MeshKit.at(0, 0.98, -0.1))
		k.box(Vector3(0.4, 0.04, 0.34), Color(0.92, 0.92, 0.93), seg * MeshKit.at(0, 0.74, -0.24))
		k.box(Vector3(0.02, 0.88, 0.06), Color(0.86, 0.87, 0.88), seg * MeshKit.at(0.2, 0.5, 0.01))
	# a logo plate on the front
	k.box(Vector3(0.6, 0.3, 0.02), dark, MeshKit.at(0, 0.6, -0.25))
	k.box(Vector3(0.18, 0.18, 0.01), glow, MeshKit.at(-0.16, 0.6, -0.235))
	k.box(Vector3(0.26, 0.04, 0.01), white, MeshKit.at(0.1, 0.64, -0.235))
	k.box(Vector3(0.2, 0.03, 0.01), Color(0.6, 0.62, 0.66), MeshKit.at(0.07, 0.57, -0.235))
	# on the counter: a bell, a tablet stand, brochures, a nameplate, a plant
	k.cyl(0.06, 0.02, Pal.BRASS, MeshKit.at(0.55, 1.0, -0.42), 8)
	k.sphere(0.05, Pal.BRASS, MeshKit.xf(Vector3(0.55, 1.02, -0.42), Vector3.ZERO, Vector3(1, 0.7, 1)), 8, 3)
	k.box(Vector3(0.2, 0.14, 0.02), dark, MeshKit.xf(Vector3(-0.45, 1.08, -0.4), Vector3(-20, 0, 0)))
	k.box(Vector3(0.17, 0.11, 0.01), Color(0.6, 0.9, 1.0, 0.45), MeshKit.xf(Vector3(-0.45, 1.08, -0.388), Vector3(-20, 0, 0)))
	for i in 3:
		k.box(Vector3(0.1, 0.012, 0.14), [Color(0.96, 0.96, 0.94), teal, Color(0.98, 0.7, 0.3)][i], MeshKit.xf(Vector3(-0.95 + i * 0.12, 1.008 + i * 0.012, -0.44), Vector3(0, 10 - i * 8, 0)))
	k.box(Vector3(0.2, 0.06, 0.03), Pal.BRASS, MeshKit.xf(Vector3(0.12, 1.03, -0.38), Vector3(-30, 0, 0)))
	k.cyl(0.07, 0.12, white, MeshKit.at(1.05, 1.0, -0.47), 8)
	k.sphere(0.1, Pal.LEAF, MeshKit.at(1.05, 1.18, -0.47), 7, 4)
	# behind the counter: two monitors, keyboards, a phone, papers, a chair
	for sx in [-0.4, 0.35]:
		k.box(Vector3(0.04, 0.12, 0.04), dark, MeshKit.at(sx, 0.82, -0.62))
		k.box(Vector3(0.36, 0.22, 0.03), dark, MeshKit.at(sx, 0.98, -0.62))
		k.box(Vector3(0.32, 0.18, 0.01), Color(0.5, 0.8, 1.0, 0.5), MeshKit.at(sx, 0.98, -0.604))
		k.box(Vector3(0.28, 0.015, 0.1), Color(0.3, 0.32, 0.36), MeshKit.at(sx, 0.77, -0.5))
	k.box(Vector3(0.14, 0.05, 0.12), dark, MeshKit.at(0.85, 0.79, -0.5))
	for i in 4:
		k.box(Vector3(0.2, 0.01, 0.28), Color(0.96, 0.96, 0.94).darkened(0.03 * i), MeshKit.xf(Vector3(-0.95, 0.765 + i * 0.012, -0.52), Vector3(0, i * 6, 0)))
	k.cyl(0.18, 0.06, dark, MeshKit.at(0.0, 0.45, -0.82), 8)
	k.box(Vector3(0.4, 0.4, 0.06), dark, MeshKit.at(0.0, 0.75, -0.86))
	k.cyl(0.025, 0.4, steel, MeshKit.at(0.0, 0.05, -0.82), 5)
	for i in 5:
		var a2 := TAU * i / 5.0
		k.box(Vector3(0.22, 0.03, 0.03), steel, MeshKit.xf(Vector3(cos(a2) * 0.11, 0.05, -0.82 + sin(a2) * 0.05), Vector3(0, -rad_to_deg(a2), 0)))
	# ---- the waiting corner (left): two lounge chairs, a low table
	for i in 2:
		var ch := MeshKit.xf(Vector3(-1.55, 0, 0.05 + i * 0.55), Vector3(0, 90, 0))
		k.rbox(Vector3(0.5, 0.2, 0.46), 0.06, teal.darkened(0.25), ch * MeshKit.at(0, 0.3, 0), 1)
		k.box(Vector3(0.5, 0.36, 0.1), teal.darkened(0.3), ch * MeshKit.at(0, 0.52, -0.2))
		for sx in [-0.26, 0.26]:
			k.box(Vector3(0.06, 0.26, 0.46), teal.darkened(0.35), ch * MeshKit.at(sx, 0.4, 0))
		for sx in [-0.2, 0.2]:
			for sz in [-0.18, 0.18]:
				k.box(Vector3(0.03, 0.2, 0.03), steel, ch * MeshKit.at(sx, 0.1, sz))
	k.cyl(0.2, 0.03, white, MeshKit.at(-1.05, 0.38, 0.33), 10)
	k.cyl(0.03, 0.36, steel, MeshKit.at(-1.05, 0.02, 0.33), 5)
	k.cyl(0.12, 0.02, steel, MeshKit.at(-1.05, 0.02, 0.33), 8)
	k.box(Vector3(0.16, 0.01, 0.22), Color(0.98, 0.7, 0.3), MeshKit.xf(Vector3(-1.08, 0.415, 0.3), Vector3(0, 20, 0)))
	k.cyl(0.03, 0.07, white, MeshKit.at(-0.98, 0.41, 0.4), 6)
	# a tall plant in the corner, a water cooler
	k.cyl(0.16, 0.42, Color(0.3, 0.32, 0.36), MeshKit.at(-1.7, 0.03, -0.25), 8, 0.02, 0.13)
	TownArt.tree(k, Vector3(-1.7, 0.4, -0.25), 1.3, Pal.LEAF_DARK, 3)
	k.box(Vector3(0.26, 0.8, 0.26), white, MeshKit.at(1.2, 0.43, -0.12))
	k.cyl(0.11, 0.3, Color(0.5, 0.75, 0.95, 0.7), MeshKit.at(1.2, 0.83, -0.12), 8, 0.03)
	k.box(Vector3(0.06, 0.04, 0.04), Color(0.3, 0.5, 0.86), MeshKit.at(1.17, 0.6, 0.02))
	# ---- the queue (right): stanchions with a rope, a sign
	var posts := [Vector3(0.7, 0, 0.75), Vector3(1.25, 0, 0.75), Vector3(1.75, 0, 0.75), Vector3(1.75, 0, 0.25)]
	for p in posts:
		k.cyl(0.08, 0.02, Pal.BRASS, MeshKit.at(p.x, 0.03, p.z), 8)
		k.cyl(0.02, 0.9, Pal.BRASS, MeshKit.at(p.x, 0.03, p.z), 5)
		k.sphere(0.03, Pal.BRASS, MeshKit.at(p.x, 0.95, p.z), 5, 3)
	for i in posts.size() - 1:
		var a3: Vector3 = posts[i] + Vector3(0, 0.86, 0)
		var b3: Vector3 = posts[i + 1] + Vector3(0, 0.86, 0)
		var m3 := (a3 + b3) * 0.5 - Vector3(0, 0.12, 0)
		TownArt.beam(k, a3, m3, 0.025, Color(0.62, 0.16, 0.2))
		TownArt.beam(k, m3, b3, 0.025, Color(0.62, 0.16, 0.2))
	k.box(Vector3(0.04, 1.1, 0.04), steel, MeshKit.at(1.75, 0.58, -0.2))
	k.box(Vector3(0.36, 0.5, 0.03), white, MeshKit.at(1.75, 1.3, -0.18))
	k.box(Vector3(0.28, 0.06, 0.01), teal, MeshKit.at(1.75, 1.45, -0.163))
	for i in 3:
		k.box(Vector3(0.24 - i * 0.04, 0.025, 0.01), Color(0.4, 0.42, 0.46), MeshKit.at(1.75, 1.32 - i * 0.07, -0.163))
	return k.commit()
