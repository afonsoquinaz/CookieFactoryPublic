class_name LevelArt
## Small things a building gains as it levels up, so every upgrade shows:
## crates, planters, lamps, barrels, flags, a bench, topiaries, golden
## lamps... Each building kind lists anchor spots (local metres, front +Z)
## where they stand; the first levels add one almost every level, later
## ones less often.

## Level at which prop i (of n anchors) appears, for a building that tops
## out at max_level: quick at first, then spreading out.
static func level_of(i: int, n: int, max_level: int) -> int:
	var f := float(i + 1) / float(n)
	return 2 + int(round(pow(f, 1.6) * float(maxi(1, max_level - 2))))


## How many props a building of max_level shows at level l.
static func count(n: int, l: int, max_level: int) -> int:
	var c := 0
	for i in n:
		if l >= level_of(i, n, max_level):
			c += 1
	return c


## The props for the first `c` anchors: [[pos: Vector3, yaw_deg: float], ...]
static func props(anchors: Array, c: int, style := 0) -> Mesh:
	var k := MeshKit.new()
	for i in mini(c, anchors.size()):
		var a: Array = anchors[i]
		_prop(k, i, a[0], float(a[1]), style)
	return k.commit()


static func _prop(k: MeshKit, i: int, p: Vector3, yaw: float, style: int) -> void:
	var t := MeshKit.xf(p, Vector3(0, yaw, 0))
	var gold := style >= 3
	match i % 10:
		0:
			TownArt.crate(k, p, 0.5, yaw)
			TownArt.crate(k, p + Vector3(0, 0.5, 0), 0.4, yaw + 20.0)
		1:
			# a planter of flowers
			k.rbox(Vector3(0.8, 0.32, 0.36), 0.05, Pal.WOOD if not gold else Pal.STONE, t * MeshKit.at(0, 0.16, 0))
			for j in 5:
				var c: Color = [Color(0.86, 0.5, 0.52), Color(0.96, 0.92, 0.84), Color(0.9, 0.68, 0.36), Color(0.6, 0.52, 0.72), Color(0.86, 0.5, 0.52)][j]
				k.sphere(0.09, Pal.LEAF, t * MeshKit.at(-0.3 + j * 0.15, 0.38, 0), 6, 4)
				k.sphere(0.06, c, t * MeshKit.at(-0.3 + j * 0.15, 0.46, 0.04), 6, 4)
		2:
			TownArt.lamp_post(k, p, 1.9)
		3:
			# barrels
			for j in 2:
				var q := t * Vector3(-0.2 + j * 0.42, 0, 0)
				k.cyl(0.2, 0.55, Pal.WOOD, MeshKit.at(q.x, q.y, q.z), 10, 0.04, 0.17)
				k.torus(0.2, 0.025, Pal.STEEL_DARK, MeshKit.at(q.x, q.y + 0.14, q.z), 10, 3)
				k.torus(0.2, 0.025, Pal.STEEL_DARK, MeshKit.at(q.x, q.y + 0.42, q.z), 10, 3)
		4:
			# a topiary ball in a pot
			k.cyl(0.2, 0.32, Pal.TERRACOTTA if not gold else Pal.CREAM, t * MeshKit.at(0, 0, 0), 10, 0.03, 0.15)
			k.sphere(0.3, Pal.LEAF_DARK, t * MeshKit.at(0, 0.6, 0), 10, 7)
		5:
			TownArt.flag(k, p, 2.4, [Pal.TERRACOTTA, Pal.SAGE, Pal.SLATE, Pal.BRASS, Pal.GOLD][clampi(style, 0, 4)])
		6:
			TownArt.bench(k, p, 1.1, yaw)
		7:
			TownArt.sacks(k, p, 3)
		8:
			# a little golden cookie on a plinth
			k.rbox(Vector3(0.44, 0.5, 0.44), 0.04, Pal.STONE, t * MeshKit.at(0, 0.25, 0))
			Items.cookie_into(k, "choc", 0.18, 0.05, t * MeshKit.xf(Vector3(0, 0.72, 0), Vector3(80, 0, 0)))
		9:
			# a brass lamp with a warm glow
			k.cyl(0.05, 1.7, Pal.BRASS, MeshKit.at(p.x, 0, p.z), 8)
			k.sphere(0.17, Color(1.0, 0.88, 0.6, 0.4), MeshKit.at(p.x, 1.85, p.z), 10, 6)
			k.cone(0.16, 0.18, Pal.BRASS, MeshKit.at(p.x, 1.98, p.z), 8)
