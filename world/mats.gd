class_name Mats
## Shared materials. Most meshes use toon() with baked vertex colours.

static var _toon: ShaderMaterial
static var _glass: ShaderMaterial
static var _ground: ShaderMaterial
static var _glow: ShaderMaterial
static var _flat := {}
static var _ink: ShaderMaterial
static var _ghost: StandardMaterial3D
static var _tiles: StandardMaterial3D


## Toon material with an inverted-hull ink outline (characters only).
static func inked() -> ShaderMaterial:
	if _ink == null:
		_ink = toon().duplicate() as ShaderMaterial
		var o := ShaderMaterial.new()
		o.shader = preload("res://render/outline.gdshader")
		o.set_shader_parameter("width", 0.014)
		o.set_shader_parameter("ink", Color(0.2, 0.13, 0.1))
		_ink.next_pass = o
	return _ink


static func toon() -> ShaderMaterial:
	if _toon == null:
		_toon = ShaderMaterial.new()
		_toon.shader = preload("res://render/toon.gdshader")
	return _toon


## Toon material that glows a bit (oven windows, lamps, highlights).
static func glow() -> ShaderMaterial:
	if _glow == null:
		_glow = ShaderMaterial.new()
		_glow.shader = preload("res://render/toon.gdshader")
		_glow.set_shader_parameter("emit", 0.9)
	return _glow


static func glass() -> ShaderMaterial:
	if _glass == null:
		_glass = ShaderMaterial.new()
		_glass.shader = preload("res://render/glass.gdshader")
		_glass.render_priority = 1
	return _glass


static func ground() -> ShaderMaterial:
	if _ground == null:
		_ground = ShaderMaterial.new()
		_ground.shader = preload("res://render/ground.gdshader")
	return _ground


## Unshaded flat colour (UI-in-world: zone rings, arrows, progress).
static func flat(c: Color, no_depth := false) -> StandardMaterial3D:
	var key := "%s%s" % [c.to_html(), no_depth]
	if not _flat.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = c
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = no_depth
		m.disable_receive_shadows = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_flat[key] = m
	return _flat[key]


## The see-through placement ghost (vertex colours, a little glow). Shared:
## placement tints it red when the spot doesn't work.
static func ghost() -> StandardMaterial3D:
	if _ghost == null:
		_ghost = StandardMaterial3D.new()
		_ghost.vertex_color_use_as_albedo = true
		_ghost.vertex_color_is_srgb = true
		_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost.albedo_color = Color(1, 1, 1, 0.88)
		_ghost.emission_enabled = true
		_ghost.emission = Color(0.25, 0.22, 0.15)
	return _ghost


## Unshaded see-through vertex colours on top (placement tiles, arrows).
static func tiles() -> StandardMaterial3D:
	if _tiles == null:
		_tiles = StandardMaterial3D.new()
		_tiles.vertex_color_use_as_albedo = true
		_tiles.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_tiles.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_tiles.render_priority = 1
	return _tiles


## MeshInstance3D with the toon material.
static func inst(mesh: Mesh, parent: Node3D = null, t := Transform3D.IDENTITY, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = toon()
	mi.transform = t
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent:
		parent.add_child(mi)
	return mi
