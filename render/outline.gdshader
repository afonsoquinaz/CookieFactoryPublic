shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, fog_disabled;
// Inverted-hull ink outline (DEADGRID style), used as next_pass of the
// character material. Width is in world units at scale 1.
uniform vec3 ink : source_color = vec3(0.137, 0.157, 0.184);
uniform float width = 0.014;

void vertex() {
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 vn = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float s = length(MODEL_MATRIX[0].xyz);
	vp.xyz += vn * width * s * clamp(-vp.z * 0.12, 0.6, 2.5);
	POSITION = PROJECTION_MATRIX * vp;
}

void fragment() {
	ALBEDO = ink;
}
