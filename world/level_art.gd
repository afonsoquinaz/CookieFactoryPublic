class_name LevelArt
## Small things a building gains as it levels up, so every upgrade shows:
## crates, planters, lamps, server cabinets, flags, a bench, topiaries,
## cable reels, a token on a plinth, brass lamps... Each building kind lists anchor spots (local metres, front +Z)
## where they stand; the first levels add one almost every level, later
## ones less often.

## Spots where a kind of building shows its props (local, front +Z):
## [[pos, yaw_deg], ...], kept clear of where people walk and work.
static func anchors_for(kind: String) -> Array:
	var d: Dictionary = Defs.BUILDINGS[kind]
	match d["cat"]:
		"source":
			return [[Vector3(-2.35, 0, 2.4), 0.0], [Vector3(2.35, 0, 2.4), 0.0], [Vector3(-1.5, 0, 2.55), 0.0],
				[Vector3(1.5, 0, 2.55), 0.0], [Vector3(-2.55, 0, 1.55), 90.0], [Vector3(2.55, 0, 1.55), -90.0]]
		"server":
			return [[Vector3(-4.55, 0.12, 2.55), 0.0], [Vector3(4.55, 0.12, 2.55), 0.0], [Vector3(-2.4, 0.12, 2.6), 0.0],
				[Vector3(1.6, 0.12, 2.6), 0.0], [Vector3(-4.6, 0.12, 0.4), 90.0], [Vector3(4.6, 0.12, 0.2), -90.0],
				[Vector3(-0.6, 0.12, 2.65), 0.0], [Vector3(4.55, 0.12, 1.75), 0.0]]
		"lab":
			return [[Vector3(-1.7, 0, 1.6), 0.0], [Vector3(1.7, 0, 1.6), 0.0], [Vector3(-1.75, 0, 0.95), 90.0], [Vector3(1.75, 0, 0.95), -90.0]]
		"pack":
			return [[Vector3(-1.7, 0, 1.55), 0.0], [Vector3(1.7, 0, 1.55), 0.0], [Vector3(-1.75, 0, 1.0), 90.0], [Vector3(1.75, 0, 1.0), -90.0]]
		"sell":
			match kind:
				"van": return SalesArt.DOCK_PROPS
				"cafe": return [[Vector3(2.55, 0, 1.5), 0.0], [Vector3(-2.65, 0, 1.55), 0.0], [Vector3(2.6, 0, 0.55), -90.0], [Vector3(1.6, 0, 1.6), 0.0]]
				"hyperloop", "droneport": return [[Vector3(-2.55, 0, 2.55), 0.0], [Vector3(2.55, 0, 2.55), 0.0], [Vector3(-2.6, 0, 1.6), 90.0], [Vector3(2.6, 0, 1.6), -90.0]]
	return []


## Level at which prop i (of n anchors) appears, for a building that tops
## out at max_level: the first half one per level from level 2 (early
## upgrades always show), the rest spread out toward the top.
static func level_of(i: int, n: int, max_level: int) -> int:
	var early := (n + 1) / 2
	if i < early:
		return 2 + i
	var f := float(i - early + 1) / float(n - early)
	var lo := 2 + early
	return lo + int(round(pow(f, 1.5) * float(maxi(0, max_level - lo))))


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
			var lk := MeshKit.new()
			TownArt.lamp_post(lk, Vector3.ZERO, 1.9)
			k.merge(lk, MeshKit.at(p.x, p.y, p.z))
		3:
			# an outdoor server cabinet with status lights
			k.rbox(Vector3(0.6, 0.9, 0.44), 0.04, Color(0.86, 0.88, 0.9) if not gold else Color(0.2, 0.21, 0.24), t * MeshKit.at(0, 0.45, 0))
			for j in 3:
				k.rbox(Vector3(0.06, 0.04, 0.01), 0.01, Color(0.5, 1.0, 0.6, 0.4) if j < 2 else Color(0.4, 0.9, 1.0, 0.4), t * MeshKit.at(-0.15 + j * 0.1, 0.75, 0.225))
		4:
			# a topiary ball in a pot
			k.cyl(0.2, 0.32, Pal.TERRACOTTA if not gold else Pal.CREAM, t * MeshKit.at(0, 0, 0), 10, 0.03, 0.15)
			k.sphere(0.3, Pal.LEAF_DARK, t * MeshKit.at(0, 0.6, 0), 10, 7)
		5:
			TownArt.flag(k, p, 2.4, [Pal.TERRACOTTA, Pal.SAGE, Pal.SLATE, Pal.BRASS, Pal.GOLD][clampi(style, 0, 4)])
		6:
			TownArt.bench(k, p, 1.1, yaw)
		7:
			# a cable reel lying on its side
			k.cyl(0.36, 0.08, Pal.WOOD, t * MeshKit.xf(Vector3(-0.2, 0.36, 0), Vector3(0, 0, 90)), 14)
			k.cyl(0.36, 0.08, Pal.WOOD, t * MeshKit.xf(Vector3(0.2, 0.36, 0), Vector3(0, 0, 90)), 14)
			k.cyl(0.26, 0.34, [Color(0.3, 0.5, 0.86), Color(0.96, 0.6, 0.3), Color(0.24, 0.24, 0.28)][i % 3], t * MeshKit.xf(Vector3(-0.17, 0.36, 0), Vector3(0, 0, -90)), 14)
		8:
			# a glowing token on a plinth
			k.rbox(Vector3(0.44, 0.5, 0.44), 0.04, Color(0.86, 0.87, 0.88) if not gold else Color(0.2, 0.21, 0.24), t * MeshKit.at(0, 0.25, 0))
			Items.token_into(k, ["chat7", "code13", "assist70", "reason200", "frontier"][clampi(style, 0, 4)], 0.18, 0.05, t * MeshKit.xf(Vector3(0, 0.72, 0), Vector3(80, 0, 0)))
		9:
			# a brass lamp with a cool glow
			k.cyl(0.05, 1.7, Pal.BRASS, MeshKit.at(p.x, p.y, p.z), 8)
			k.sphere(0.17, Color(0.7, 0.95, 1.0, 0.4), MeshKit.at(p.x, p.y + 1.85, p.z), 10, 6)
			k.cone(0.16, 0.18, Pal.BRASS, MeshKit.at(p.x, p.y + 1.98, p.z), 8)
