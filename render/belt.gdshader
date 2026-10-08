shader_type spatial;
render_mode cull_back;
// Rubber conveyor belt with moving ridges.
uniform float speed = 1.0;
uniform vec4 base : source_color = vec4(0.32, 0.3, 0.4, 1.0);
uniform vec4 ridge : source_color = vec4(0.45, 0.43, 0.55, 1.0);
varying vec3 v_local;
uniform float offset = 0.0;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float s = fract(v_local.x * 2.5 - TIME * speed * 2.5);
	float r = smoothstep(0.0, 0.1, s) * (1.0 - smoothstep(0.25, 0.35, s));
	ALBEDO = mix(base.rgb, ridge.rgb, r);
	ROUGHNESS = 0.9;
}
