shader_type spatial;
render_mode cull_back, shadows_disabled;
// Stylised sea: turquoise shallows hugging the island, deeper blue further
// out, a soft animated foam band at the shore and drifting sparkle streaks.
uniform vec2 island_min = vec2(-18.0, -18.0);
uniform vec2 island_max = vec2(18.0, 18.0);
uniform vec4 shallow : source_color = vec4(0.38, 0.86, 0.9, 1.0);
uniform vec4 deep : source_color = vec4(0.2, 0.55, 0.9, 1.0);
uniform vec4 foam : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec3 v_wpos;

float rbox(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = (island_min + island_max) * 0.5;
	vec2 h = (island_max - island_min) * 0.5;
	float d = rbox(v_wpos.xz - c, h, 2.0);
	float t = TIME;
	vec3 col = mix(shallow.rgb, deep.rgb, smoothstep(0.5, 14.0, d));
	// shore foam: two bands that breathe in and out
	float wob = noise(v_wpos.xz * 0.6 + t * 0.2) * 0.6;
	float band1 = 1.0 - smoothstep(0.0, 0.35, abs(d - (0.4 + sin(t * 1.2) * 0.25 + wob)));
	float band2 = 1.0 - smoothstep(0.0, 0.18, abs(d - (1.6 + sin(t * 1.2 + 1.5) * 0.4 + wob)));
	col = mix(col, foam.rgb, clamp(band1 * 0.9 + band2 * 0.45, 0.0, 1.0));
	// sparkle streaks
	float n = noise(vec2(v_wpos.x * 0.35 + t * 0.15, v_wpos.z * 1.6 - t * 0.05));
	col += vec3(0.9) * smoothstep(0.82, 0.9, n) * 0.25 * smoothstep(1.5, 4.0, d);
	ALBEDO = col;
	EMISSION = col * 0.25;
	ROUGHNESS = 0.3;
	SPECULAR = 0.4;
}
