class_name KitchenArt
## Kitchen machines, packer and wrapper, five tiers each:
##   0 rustic wood + clay   1 copper   2 copper on a brick hearth
##   3 stainless steel with dials   4 royal: copper, brass and gold
## Each has a moving part (plunger, paddle, drum, spool, conveyor box).

const Z := -0.85


static func _metal(t: int) -> Color:
	return [Pal.WOOD, Color(0.78, 0.5, 0.34), Color(0.78, 0.5, 0.34), Pal.STEEL, Color(0.82, 0.55, 0.36)][t]


static func _trim(t: int) -> Color:
	return [Pal.WOOD_DARK, Pal.STEEL_DARK, Pal.BRASS, Pal.STEEL_DARK, Pal.GOLD][t]


static func bench(t: int) -> Mesh:
	var k := MeshKit.new()
	var top: Color = [Pal.WOOD_LIGHT, Pal.WOOD_LIGHT, Pal.STONE, Pal.STEEL, Color(0.95, 0.93, 0.88)][t]
	var leg: Color = [Pal.WOOD_DARK, Pal.WOOD_DARK, Pal.STONE_DARK, Pal.STEEL_DARK, Pal.BRASS][t]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.72, 0.08), 0.02, leg, MeshKit.at(sx * 0.62, 0.36, sz * 0.36))
	k.rbox(Vector3(1.4, 0.06, 0.86), 0.02, top, MeshKit.at(0, 0.74, 0))
	return k.commit()


## Hearth / base under every machine, then the machine itself.
static func machine(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var m := _metal(t)
	var trim := _trim(t)
	# base
	match t:
		0, 1:
			k.rbox(Vector3(2.4, 0.3, 1.6), 0.06, Pal.STONE, MeshKit.at(0, 0.15, Z))
		2:
			for i in 3:
				k.rbox(Vector3(2.4, 0.2, 1.6), 0.03, Pal.BRICK if i % 2 == 0 else Pal.BRICK_DARK, MeshKit.at(0, 0.1 + i * 0.2, Z))
		3:
			k.rbox(Vector3(2.5, 0.5, 1.7), 0.05, Pal.STEEL_DARK, MeshKit.at(0, 0.25, Z))
		4:
			k.rbox(Vector3(2.5, 0.45, 1.7), 0.08, Color(0.3, 0.2, 0.16), MeshKit.at(0, 0.22, Z))
			k.rbox(Vector3(2.54, 0.06, 1.74), 0.02, Pal.GOLD, MeshKit.at(0, 0.45, Z))
	var by: float = [0.3, 0.3, 0.6, 0.5, 0.48][t]
	match kind:
		"churn":
			var s := 1.0 + t * 0.08
			k.cyl(0.42 * s, 1.1 * s, m, MeshKit.at(0, by, Z), 14, 0.04, 0.34 * s)
			for y in [0.25, 0.75]:
				k.torus(0.42 * s - y * 0.07, 0.03, trim, MeshKit.at(0, by + y * s, Z), 14, 3)
			k.cyl(0.36 * s, 0.06, m.darkened(0.1), MeshKit.at(0, by + 1.1 * s, Z), 12)
			if t >= 3:
				k.rbox(Vector3(0.9, 1.2, 0.3), 0.05, Pal.STEEL, MeshKit.at(0.85, by + 0.6, Z - 0.3))
				k.cyl(0.08, 0.04, Color(0.95, 0.94, 0.9), MeshKit.xf(Vector3(0.85, by + 0.9, Z - 0.14), Vector3(90, 0, 0)), 10)
		"chocolatier", "kettle", "caramel_pot", "candy":
			var col: Color = {"chocolatier": Color(0.36, 0.22, 0.15), "kettle": Color(0.72, 0.14, 0.2), "caramel_pot": Color(0.86, 0.56, 0.24), "candy": Color(0.95, 0.6, 0.25)}[kind]
			var r := 0.62 + t * 0.06
			# a pot on a stove
			k.rbox(Vector3(1.6, 0.5, 1.3), 0.06, Pal.STEEL_DARK if t < 4 else Color(0.3, 0.2, 0.16), MeshKit.at(0, by + 0.25, Z))
			k.rbox(Vector3(0.4, 0.2, 0.05), 0.04, Color(1.0, 0.5, 0.2, 0.4), MeshKit.at(0, by + 0.2, Z + 0.66))
			var prof := PackedVector2Array([Vector2(0, 0), Vector2(r * 0.8, 0), Vector2(r, 0.2), Vector2(r, 0.62), Vector2(r * 1.05, 0.66), Vector2(r * 0.95, 0.66), Vector2(r * 0.9, 0.55), Vector2(0, 0.55)])
			k.lathe(prof, m, MeshKit.at(0, by + 0.5, Z), 20)
			k.cyl(r * 0.88, 0.04, col, MeshKit.at(0, by + 1.06, Z), 18)
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.24, 0.06, 0.08), 0.03, trim, MeshKit.at(sx * (r + 0.1), by + 1.0, Z))
			if kind == "candy":
				k.rbox(Vector3(0.9, 0.06, 0.6), 0.03, Color(0.95, 0.94, 0.9), MeshKit.at(0.0, by + 0.53, Z + 0.4))
			if t >= 2:
				# extractor hood
				k.cyl(0.18, 1.1, trim if t != 2 else Pal.STEEL_DARK, MeshKit.at(0, by + 1.7, Z - 0.1), 10, 0.02, 0.14)
				k.cone(0.7, 0.4, Pal.STEEL_DARK if t < 4 else Pal.GOLD, MeshKit.xf(Vector3(0, by + 1.6, Z), Vector3(180, 0, 0)), 14)
		"roaster":
			var s2 := 1.0 + t * 0.06
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.12, 1.0 * s2, 0.12), 0.03, Pal.STEEL_DARK, MeshKit.at(sx * 0.75 * s2, by + 0.5 * s2, Z))
			k.rbox(Vector3(1.4, 0.3, 0.8), 0.05, Pal.STEEL_DARK, MeshKit.at(0, by + 0.15, Z))
			k.rbox(Vector3(0.5, 0.18, 0.06), 0.04, Color(1.0, 0.45, 0.15, 0.4), MeshKit.at(0, by + 0.17, Z + 0.41))
			k.cone(0.3, 0.4, trim, MeshKit.xf(Vector3(0, by + 1.65 * s2, Z), Vector3(180, 0, 0)), 10)
		"packer":
			var c2: Color = [Color(0.93, 0.9, 0.82), Color(0.93, 0.9, 0.82), Color(0.55, 0.62, 0.52), Pal.STEEL, Color(0.82, 0.55, 0.36)][t]
			k.rbox(Vector3(1.0, 1.4, 1.1), 0.1, c2, MeshKit.at(-0.55, by + 0.7, Z))
			k.rbox(Vector3(0.5, 0.35, 0.05), 0.05, Color(0.75, 0.86, 0.9, 0.5), MeshKit.at(-0.55, by + 0.95, Z + 0.56))
			k.rbox(Vector3(1.6, 0.08, 0.5), 0.02, Pal.STEEL_DARK, MeshKit.at(0.45, by + 0.5, Z + 0.1))
			for i in 5:
				k.cyl(0.05, 0.5, Pal.STEEL, MeshKit.xf(Vector3(-0.2 + i * 0.32, by + 0.56, Z + 0.1), Vector3(90, 0, 0)), 8)
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 0.5, 0.06), 0.02, Pal.STEEL_DARK, MeshKit.at(0.45 + sx * 0.7, by + 0.25, Z + 0.1))
			k.rbox(Vector3(0.4, 0.3, 0.3), 0.03, Color(0.78, 0.62, 0.44), MeshKit.at(-0.55, by + 1.55, Z))
			if t >= 3:
				k.sphere(0.09, Color(0.5, 0.85, 0.5, 0.4), MeshKit.at(-0.25, by + 1.3, Z + 0.56), 8, 5)
		"wrapper":
			k.rbox(Vector3(2.0, 0.9, 1.1), 0.08, [Pal.WOOD, Pal.WOOD, Pal.WOOD_DARK, Pal.STEEL, Color(0.3, 0.2, 0.16)][t], MeshKit.at(0, by + 0.45, Z))
			k.rbox(Vector3(2.04, 0.05, 1.14), 0.02, trim, MeshKit.at(0, by + 0.92, Z))
			for i in 3:
				k.rbox(Vector3(0.3, 0.24, 0.3), 0.04, Color(0.95, 0.92, 0.86), MeshKit.at(0.3 + i * 0.32, by + 1.07, Z + 0.1))
				k.rbox(Vector3(0.31, 0.25, 0.06), 0.01, Pal.TERRACOTTA, MeshKit.at(0.3 + i * 0.32, by + 1.07, Z + 0.1))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 0.6, 0.06), 0.02, trim, MeshKit.at(-0.55 + sx * 0.3, by + 1.2, Z))
	return k.commit()


## Where the moving part pivots (local).
static func anim_pivot(kind: String, t: int) -> Vector3:
	var by: float = [0.3, 0.3, 0.6, 0.5, 0.48][t]
	match kind:
		"churn": return Vector3(0, by + 1.1 * (1.0 + t * 0.08), Z)
		"chocolatier", "kettle", "caramel_pot", "candy": return Vector3(0, by + 1.06, Z)
		"roaster": return Vector3(0, by + 0.95 * (1.0 + t * 0.06), Z)
		"packer": return Vector3(-0.1, by + 0.62, Z + 0.1)
		"wrapper": return Vector3(-0.55, by + 1.45, Z)
	return Vector3(0, 1, Z)


static func part(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var m := _metal(t)
	match kind:
		"churn":
			k.cyl(0.035, 0.7, Pal.WOOD_DARK, MeshKit.at(0, -0.3, 0), 6)
			k.sphere(0.07, Pal.WOOD, MeshKit.at(0, 0.42, 0), 8, 5)
		"chocolatier", "kettle", "caramel_pot", "candy":
			k.cyl(0.03, 0.9, Pal.WOOD, MeshKit.xf(Vector3(0.15, 0.1, 0), Vector3(0, 0, 20)), 6)
			k.rbox(Vector3(0.12, 0.25, 0.03), 0.02, Pal.WOOD, MeshKit.xf(Vector3(0.0, -0.3, 0), Vector3(0, 0, 20)))
			for i in 3:
				k.sphere(0.04, Color(1, 1, 1, 0.6), MeshKit.at(-0.2 + i * 0.2, 0.01, 0.1 * (i - 1)), 6, 4)
		"roaster":
			var s := 1.0 + t * 0.06
			k.cyl(0.42 * s, 1.2 * s, m, MeshKit.xf(Vector3(-0.6 * s, 0, 0), Vector3(0, 0, -90)), 14, 0.03)
			for i in 6:
				k.rbox(Vector3(1.2 * s, 0.04, 0.06), 0.01, _trim(t), MeshKit.xf(Vector3(0, 0, 0), Vector3(i * 30, 0, 0)) * MeshKit.at(0, 0.43 * s, 0))
		"packer":
			# a kraft box riding the conveyor
			k.rbox(Vector3(0.3, 0.2, 0.26), 0.03, Color(0.78, 0.62, 0.44), MeshKit.at(0, 0.12, 0))
			k.rbox(Vector3(0.31, 0.02, 0.04), 0.01, Pal.CREAM, MeshKit.at(0, 0.22, 0))
		"wrapper":
			k.cyl(0.18, 0.5, Pal.TERRACOTTA, MeshKit.xf(Vector3(0, 0, -0.25), Vector3(90, 0, 0)), 14, 0.03)
			k.cyl(0.06, 0.55, Pal.WOOD_DARK, MeshKit.xf(Vector3(0, 0, -0.27), Vector3(90, 0, 0)), 8)
	return k.commit()


static func animate(kind: String, n: Node3D, t: float, busy: bool) -> void:
	var sp := 1.0 if busy else 0.0
	match kind:
		"churn":
			if not n.has_meta("y0"):
				n.set_meta("y0", n.position.y)
			n.position.y = float(n.get_meta("y0")) + sin(t * 7.0) * 0.12 * sp
		"chocolatier", "kettle", "caramel_pot", "candy":
			n.rotation.y += 0.04 * (0.3 + sp * 2.0)
		"roaster":
			n.rotation.x += 0.05 * sp
		"packer":
			if not n.has_meta("x0"):
				n.set_meta("x0", n.position.x)
			n.position.x = float(n.get_meta("x0")) + (fmod(t * 0.6, 1.0) * 1.2 if busy else 0.0)
			n.visible = busy
		"wrapper":
			n.rotation.z += 0.08 * sp
