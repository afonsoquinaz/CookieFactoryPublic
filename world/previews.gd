class_name Previews
## The tier-0 look of any building as one mesh, for the placement ghost and
## the build menu. Local frame = building centre, front facing +Z.

static func mesh(kind: String, ing := "", t := 0) -> Mesh:
	return MeshKit.cached("preview_%s_%s_%d" % [kind, ing, t], func(): return _build(kind, ing, t))


static func _build(kind: String, ing: String, t := 0) -> Mesh:
	var k := MeshKit.new()
	var d: Dictionary = Defs.BUILDINGS[kind]
	var tz := LineModule.TUBE_Z
	match d["cat"]:
		"farm":
			var crop: String = d["crop"]
			var w := FarmB.PLOT.size.x
			var dd := FarmB.PLOT.size.y
			var cz := FarmB.PLOT.get_center().y
			k.add_mesh(FarmArt.bed(crop, w, dd, t), MeshKit.at(0, 0, cz))
			k.add_mesh(FarmArt.wall(w + 0.3, dd + 0.3, t), MeshKit.at(0, 0, cz))
			k.add_mesh(FarmArt.extras(crop, w + 0.3, dd + 0.3, t), MeshKit.at(0, 0, cz))
			var cm := MeshKit.cached("crop_" + crop, func(): return Crops.crop(crop))
			for i in 6:
				k.add_mesh(cm, MeshKit.at(-1.8 + (i % 3) * 1.8, 0.07, cz - 0.8 + (i / 3) * 1.4))
			k.add_mesh(MeshKit.cached("crate", FarmB.crate_mesh), MeshKit.at(0, 0, FarmB.CRATE_Z))
		"line":
			var len: float = d["size"].x * Grid.CELL
			if kind != "oven":
				k.add_mesh(LineArt.frame(len), MeshKit.at(0, 0, tz))
			match kind:
				"mixer": k.add_mesh(LineArt.mixer(t))
				"hopper": k.add_mesh(LineArt.silo(ing if ing != "" else "sugar", t), MeshKit.at(0, LineModule.TUBE_Y + 0.47, tz))
				"oven":
					k.add_mesh(LineArt.oven(t))
					k.add_mesh(LineArt.tray(t), MeshKit.at(OvenB.TRAY_POS.x, 0, OvenB.TRAY_POS.z))
		"kitchen":
			k.add_mesh(KitchenArt.machine(kind, t))
			k.add_mesh(KitchenArt.part(kind, t), Transform3D(Basis.IDENTITY, KitchenArt.anim_pivot(kind, t)))
			k.add_mesh(KitchenArt.bench(t), MeshKit.at(MachineB.IN_POS.x, 0, MachineB.IN_POS.z))
			k.add_mesh(KitchenArt.bench(t), MeshKit.at(MachineB.OUT_POS.x, 0, MachineB.OUT_POS.z))
		"pack":
			if kind == "pantry" or kind == "rack":
				k.add_mesh(StorageB.mesh(kind, t))
			else:
				k.add_mesh(KitchenArt.machine(kind, t))
				k.add_mesh(KitchenArt.bench(t), MeshKit.at(MachineB.IN_POS.x, 0, MachineB.IN_POS.z))
				k.add_mesh(KitchenArt.bench(t), MeshKit.at(MachineB.OUT_POS.x, 0, MachineB.OUT_POS.z))
		"sell":
			match kind:
				"dock":
					k.add_mesh(SalesArt.site("dock", t))
					k.add_mesh(SalesArt.van(t), MeshKit.xf(Vector3(0, 0.08, -0.15), Vector3(0, 90, 0)))
				"train":
					k.add_mesh(SalesArt.site("train", t))
					k.add_mesh(SalesArt.train(t), MeshKit.at(0.4, 0.12, -1.4))
				"airship":
					k.add_mesh(SalesArt.site("airship", t))
					k.add_mesh(SalesArt.airship(t), MeshKit.at(0, 5.2, -0.6))
				"shop": k.add_mesh(ShopB.mesh(t))
				"board": k.add_mesh(BoardB.mesh())
		"staff":
			k.add_mesh(CabinB.mesh(t), MeshKit.at(0.3, 0, -0.65))
		"decor":
			if kind == "palace":
				k.add_mesh(PalaceB.mesh(t))
			else:
				k.add_mesh(DecorB.mesh(kind))
	return k.commit()
