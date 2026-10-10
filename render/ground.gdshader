shader_type spatial;
render_mode cull_back;
// Endless meadow. The grass colour comes from the biome of each land chunk
// (smoothly blended between chunk centres); land you don't own is a little
// darker and hazier; a cream dashed line marks the edge of your land.
#include "res://render/toon.gdshaderinc"

uniform sampler2D biome_tex : source_color, filter_linear, repeat_disable;
uniform sampler2D own_tex : filter_nearest, repeat_disable;
uniform vec2 tex_origin = vec2(-64.0, -64.0);   // chunk coords of texel 0
uniform float tex_n = 128.0;
uniform float chunk_m = 16.0;
uniform vec4 border_col : source_color = vec4(0.98, 0.94, 0.84, 1.0);

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float owned_at(vec2 chunk) {
	vec2 t = chunk - tex_origin;
	if (t.x < 0.0 || t.y < 0.0 || t.x >= tex_n || t.y >= tex_n) return 0.0;
	return texelFetch(own_tex, ivec2(t), 0).r;
}

void fragment() {
	vec2 p = v_wpos.xz;
	vec2 cf = p / chunk_m;
	vec2 cc = floor(cf);
	vec3 base = texture(biome_tex, (cf - tex_origin) / tex_n).rgb;
	float n1 = vnoise(p * 0.18);
	float n2 = vnoise(p * 0.55 + 13.0);
	vec3 c = base * mix(0.92, 1.07, smoothstep(0.3, 0.7, n1));
	c = mix(c, c * vec3(0.84, 0.9, 0.84), smoothstep(0.62, 0.8, n2) * 0.5);
	float speck = step(0.985, hash12(floor(p * 7.0)));
	c = mix(c, c * 1.08 + vec3(0.02, 0.02, 0.0), speck * 0.4);
	// land you don't own: a touch darker and greyer
	float own = owned_at(cc);
	float wild = 1.0 - step(0.75, own);
	float g = dot(c, vec3(0.3, 0.55, 0.15));
	c = mix(c, mix(vec3(g), c, 0.75) * 0.86, wild);
	// dashed border on owned chunk edges that face land you don't own
	if (own > 0.75) {
		vec2 fr = cf - cc;
		float d = 1.0;
		float along = 0.0;
		if (owned_at(cc + vec2(-1.0, 0.0)) < 0.75 && fr.x * chunk_m < d) { d = fr.x * chunk_m; along = p.y; }
		if (owned_at(cc + vec2(1.0, 0.0)) < 0.75 && (1.0 - fr.x) * chunk_m < d) { d = (1.0 - fr.x) * chunk_m; along = p.y; }
		if (owned_at(cc + vec2(0.0, -1.0)) < 0.75 && fr.y * chunk_m < d) { d = fr.y * chunk_m; along = p.x; }
		if (owned_at(cc + vec2(0.0, 1.0)) < 0.75 && (1.0 - fr.y) * chunk_m < d) { d = (1.0 - fr.y) * chunk_m; along = p.x; }
		float dash = step(0.45, fract(along * 0.7));
		float line = (1.0 - smoothstep(0.18, 0.3, d)) * smoothstep(0.02, 0.08, d) * dash;
		c = mix(c, border_col.rgb, line * 0.85);
	}
	// slow drifting cloud shadows
	float cl = vnoise(p * 0.045 + vec2(TIME * 0.035, TIME * 0.012)) * 0.65 + vnoise(p * 0.11 - vec2(TIME * 0.05, 0.0)) * 0.35;
	c *= 1.0 - smoothstep(0.55, 0.75, cl) * 0.16;
	// biome_tex is a source_color texture, so c is already linear
	ALBEDO = c * 0.82;
	EMISSION = c * 0.07;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}

void light() {
	toon_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, 0.0, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
