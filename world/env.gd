class_name Env
## Sun, sky colour, ambient and tonemapping: bright, warm, soft shadows.

static func build(parent: Node3D) -> DirectionalLight3D:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.26, 0.29)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.84, 1.0)
	e.ambient_light_energy = 0.32
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.92
	e.tonemap_white = 6.0
	e.glow_enabled = true
	e.glow_intensity = 0.2
	e.glow_strength = 0.8
	e.glow_bloom = 0.02
	e.glow_hdr_threshold = 1.1
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.96
	e.adjustment_contrast = 1.06
	we.environment = e
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.6
	sun.shadow_opacity = 0.78
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	parent.add_child(sun)
	return sun
