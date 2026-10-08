shader_type spatial;
render_mode cull_back;
// Grass: two greens blended by soft noise blotches, tiny clover speckle,
// darker toward the far edge of the island, painted lighting.
#include "res://render/toon.gdshaderinc"

uniform vec4 grass_a : source_color = vec4(0.45, 0.76, 0.3, 1.0);
uniform vec4 grass_b : source_color = vec4(0.52, 0.8, 0.33, 1.0);
uniform vec4 grass_c : source_color = vec4(0.38, 0.68, 0.27, 1.0);

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_wpos.xz;
	float n1 = vnoise(p * 0.18);
	float n2 = vnoise(p * 0.55 + 13.0);
	vec3 c = mix(grass_a.rgb, grass_b.rgb, smoothstep(0.35, 0.65, n1));
	c = mix(c, grass_c.rgb, smoothstep(0.62, 0.8, n2) * 0.55);
	float speck = step(0.985, hash12(floor(p * 7.0)));
	c = mix(c, c * 1.12 + vec3(0.03, 0.04, 0.0), speck * 0.6);
	vec3 lin = c * COLOR.rgb;  // source_color uniforms arrive linear
	ALBEDO = lin;
	EMISSION = lin * fill * mix(fill_ground, fill_sky, 0.9);
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}

void light() {
	toon_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, 0.0, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
