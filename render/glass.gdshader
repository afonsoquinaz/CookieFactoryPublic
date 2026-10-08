shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never, shadows_disabled;
// Clean candy-glass for the assembly tube and windows: fresnel edges, a soft
// moving highlight band, lets the inside read clearly.
uniform vec4 color : source_color = vec4(0.75, 0.92, 1.0, 0.16);
uniform float edge = 0.55;

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	f = f * f;
	float band = smoothstep(0.92, 1.0, sin((v_wpos.x + v_wpos.y * 0.6) * 1.3 - TIME * 0.9) * 0.5 + 0.5);
	ALBEDO = color.rgb;
	EMISSION = vec3(1.0) * (band * 0.35 + f * 0.25);
	ALPHA = clamp(color.a + f * edge + band * 0.18, 0.0, 0.85);
	ROUGHNESS = 0.1;
	SPECULAR = 0.8;
}
