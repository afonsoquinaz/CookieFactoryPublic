class_name Previews
## The tier-0 look of any building as one mesh, for the placement ghost and
## the build menu. Local frame = building centre, front facing +Z.

## lvl: the level to show (sources lay out more stations as they level);
## -1 = the first level of tier t.
static func mesh(kind: String, ing := "", t := 0, lvl := -1) -> Mesh:
	if lvl < 0:
		lvl = Bal._tiers(kind)[clampi(t, 0, 4)]
	var key := "preview_%s_%s_%d" % [kind, ing, t]
	if Defs.BUILDINGS[kind]["cat"] == "source":
		key += "_%d" % SourceArt.station_count(Defs.BUILDINGS[kind]["res"], lvl)
	return MeshKit.cached(key, func(): return _build(kind, ing, t, lvl))


static func _build(kind: String, ing: String, t := 0, lvl := 1) -> Mesh:
	var k := MeshKit.new()
	var d: Dictionary = Defs.BUILDINGS[kind]
	match d["cat"]:
		"source":
			var res: String = d["res"]
			var w := SourceB.PLOT.size.x
			var dd := SourceB.PLOT.size.y
			var cz := SourceB.PLOT.get_center().y
			k.add_mesh(SourceArt.bed(res, w, dd, t), MeshKit.at(0, 0, cz))
			k.add_mesh(SourceArt.wall(w + 0.3, dd + 0.3, t), MeshKit.at(0, 0, cz))
			k.add_mesh(SourceArt.extras(res, w + 0.3, dd + 0.3, t), MeshKit.at(0, 0, cz))
			var cm := MeshKit.cached("station_" + res, func(): return Stations.station(res))
			for p in SourceArt.station_spots(res, lvl, w, dd, cz):
				k.add_mesh(cm, MeshKit.xf(p, Vector3.ZERO, Vector3.ONE * 1.22))
			k.add_mesh(MeshKit.cached("crate", SourceB.crate_mesh), MeshKit.at(0, 0, SourceB.CRATE_Z))
		"server":
			var bz := ServerB.BUS_Z - ServerArt.TZ
			k.add_mesh(ServerArt.house(t, ServerB.W, ServerB.D))
			var len := ServerB.BUS_X1 - ServerB.BUS_X0
			k.add_mesh(ServerArt.frame(len), MeshKit.at((ServerB.BUS_X0 + ServerB.BUS_X1) * 0.5, 0, ServerB.BUS_Z))
			k.add_mesh(ServerArt.router(t), MeshKit.at(ServerB.ROUTER_X, 0, bz))
			k.add_mesh(ServerArt.core(t), MeshKit.at(ServerB.CORE_X, 0, bz))
			k.add_mesh(ServerArt.bench(t), MeshKit.at(ServerB.BENCH_POS.x, 0, ServerB.BENCH_POS.z))
			k.add_mesh(ServerArt.power_dock(t), MeshKit.at(ServerB.DOCK_POS.x, 0, ServerB.DOCK_POS.z))
			k.add_mesh(ServerArt.gpu_tray(1 + t, 0, t), MeshKit.at(-0.7, ServerArt.Y + 0.47, ServerB.BUS_Z))
		"staff":
			if kind == "hut":
				k.add_mesh(TownArt.hut())
			else:
				k.add_mesh(DormB.mesh(t), MeshKit.at(0.3, 0, -0.65))
		"wonder":
			k.add_mesh(MegaB.mesh(t))
		"lab":
			k.add_mesh(LabArt.machine(kind, t))
			k.add_mesh(LabArt.part(kind, t), Transform3D(Basis.IDENTITY, LabArt.anim_pivot(kind, t)))
			k.add_mesh(LabArt.bench(t), MeshKit.at(MachineB.IN_POS.x, 0, MachineB.IN_POS.z))
			k.add_mesh(LabArt.bench(t), MeshKit.at(MachineB.OUT_POS.x, 0, MachineB.OUT_POS.z))
		"pack":
			k.add_mesh(StorageB.mesh(kind, t))
		"train":
			k.add_mesh(InfraArt.trainer(t))
		"space":
			if kind == "launchpad":
				k.add_mesh(InfraArt.launchpad(t))
				k.add_mesh(InfraArt.rocket(), MeshKit.at(LaunchB.PAD.x, LaunchB.PAD.y, LaunchB.PAD.z))
			else:
				k.add_mesh(InfraArt.groundstation(t))
		"sell":
			match kind:
				"gateway": k.add_mesh(InfraArt.gateway(t))
				"edge": k.add_mesh(InfraArt.edge(t))
				"agent_hub":
					k.add_mesh(InfraArt.agent_hub(t))
					for i in 3:
						k.add_mesh(InfraArt.agent_bot([Color(0.5, 0.86, 1.0), Color(0.6, 1.0, 0.7), Color(1.0, 0.8, 0.5)][i]), MeshKit.at(-1.2 + i * 1.2, 0.17, 2.0))
				"cafe":
					k.add_mesh(CafeB.mesh(t))
					k.add_mesh(CafeB.seats_mesh(4, t))
				"desk": k.add_mesh(DeskB.mesh())
		"decor":
			k.add_mesh(DecorB.mesh(kind))
	return k.commit()
