shader_type spatial;
render_mode cull_back;
// The one material most props use: vertex colours (baked by MeshKit) times a
// tint, painted toon lighting, optional per-instance flash for "hit"/pulse.
#include "res://render/toon.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);
uniform float gloss = 1.0;
uniform float emit = 0.0;          // glow (windows, oven light)

varying vec3 v_nw;

void vertex() {
	v_nw = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// vertex colours are sRGB; tint (source_color) already arrives linear
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// the Compatibility renderer already hands vertex colours over linearised
	vec3 lin = clamp(COLOR.rgb, 0.0, 1.0) * tint.rgb;
#else
	vec3 lin = toon_to_linear(clamp(COLOR.rgb, 0.0, 1.0)) * tint.rgb;
#endif
	vec3 n = normalize(v_nw);
	float up = max(n.y, 0.0);
	ALBEDO = lin * (1.0 + top_light * up * up);
	// vertex alpha < 1 marks "glow" parts (lamps, oven window) inside a mesh
	float glow = emit + (1.0 - COLOR.a) * 2.2;
	EMISSION = ALBEDO * toon_rim(NORMAL, VIEW) * sky_rim
		+ ALBEDO * fill * mix(fill_ground, fill_sky, n.y * 0.5 + 0.5)
		+ lin * glow;
	ROUGHNESS = 0.8;
	SPECULAR = 0.25;
}

void light() {
	toon_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, sheen * gloss, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
