extends Node3D
## Visual test bench: renders props in a row so they can be screenshotted.
##   tools/shot.sh res://dev/look.tscn /tmp/look.png -- --set=prims

func _ready() -> void:
	Env.build(self)
	var a := Shot.args()
	var cam := Camera3D.new()
	cam.fov = 35
	add_child(cam)
	cam.position = Vector3(0, 7, 9)
	cam.look_at(Vector3(0, 0.6, 0))
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	g.mesh = pm
	g.material_override = Mats.ground() if not a.has("std") else StandardMaterial3D.new()
	add_child(g)
	match a.get("set", "prims"):
		"prims":
			var k := MeshKit.new()
			k.rbox(Vector3(1.2, 0.8, 1.2), 0.18, Pal.RED, MeshKit.at(-3, 0.4, 0))
			k.sphere(0.6, Pal.YELLOW, MeshKit.at(-1.5, 0.6, 0))
			k.cyl(0.55, 1.0, Pal.BLUE, MeshKit.at(0, 0, 0), 20, 0.12)
			k.capsule(0.4, 1.4, Pal.MINT, MeshKit.at(1.5, 0, 0))
			k.torus(0.5, 0.18, Pal.PINK, MeshKit.at(3, 0.2, 0))
			k.cone(0.5, 1.2, Pal.ORANGE, MeshKit.at(0, 0, 2))
			k.ellipsoid(Vector3(0.7, 0.3, 0.5), Pal.PURPLE, MeshKit.at(-2, 0.3, 2))
			k.star(0.6, 0.3, 5, 0.2, Pal.GOLD, MeshKit.at(2, 0.05, 2))
			Mats.inst(k.commit(), self)
		"items":
			cam.position = Vector3(0, 1.6, 2.2)
			cam.look_at(Vector3(0, 0.15, 0))
			var x := -1.0
			for t in ["wheat", "sugar", "cocoa", "egg", "milk", "cookie", "dough", "coin"]:
				var mi := Items.node(t)
				add_child(mi)
				mi.position = Vector3(x, 0, 0)
				# a little stack of three
				for j in range(1, 3):
					var m2 := Items.node(t)
					add_child(m2)
					m2.position = Vector3(x, Items.height(t) * j, 0.6)
				x += 0.5 if x < 0.4 else 0.5
		"chars":
			cam.position = Vector3(0, 1.9, 5.2)
			cam.look_at(Vector3(0, 0.55, 0))
			var looks := ["player", "farmer", "gatherer", "feeder", "collector", "loader", "idle"]
			var works := ["", "", "", "", "", "", ""]
			if a.has("work"):
				works = ["cheer", "hoe", "pick", "scoop", "", "push", "sit"]
			for i in looks.size():
				var ch := Character.new()
				add_child(ch)
				ch.setup(looks[i], i)
				ch.position = Vector3(-3.0 + i * 1.0, 0, 0)
				ch.rotation.y = 0.25
				ch.work = works[i]
				if a.has("carry") and i == 0:
					ch.carrying = true
		"oven":
			cam.position = Vector3(2.5, 4.5, 7.5)
			cam.look_at(Vector3(0, 1.3, 0))
			var l := Line.new()
			add_child(l)
			l.setup(0)
			l.position = Vector3(-Lay.OVEN_X, 0, 0)
		"tiers":
			cam.position = Vector3(0, 6.5, 7.5)
			cam.look_at(Vector3(0, 0.6, 0))
			for t in 3:
				Mats.inst(Dock.truck_mesh(t), self, MeshKit.xf(Vector3(-4 + t * 4, 0.1, -1), Vector3(0, -25, 0)))
				for j in 6:
					Mats.inst(Items._cookie_mesh(t), self, MeshKit.at(-4 + t * 4, j * 0.085, 2.2))
	Shot.attach(self)
