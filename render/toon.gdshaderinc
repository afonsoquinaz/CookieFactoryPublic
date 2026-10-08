// Soft "painted toy" lighting shared by every lit surface: wrapped-lambert soft
// terminator, warm-to-cool shadow tint, rim light, gentle plastic sheen and a
// sky/ground bounce fill. Colours come in as sRGB (vertex colour x tint).
uniform float rim_strength = 0.32;
uniform float sky_rim = 0.10;
uniform float sheen = 0.16;
uniform float sheen_pow = 18.0;
uniform vec3 shade_tint = vec3(0.72, 0.70, 0.94);
uniform float top_light = 0.10;
uniform float fill = 0.26;
uniform vec3 fill_sky = vec3(0.90, 0.95, 1.0);
uniform vec3 fill_ground = vec3(0.95, 0.80, 0.62);

vec3 toon_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

float toon_rim(vec3 n, vec3 v) {
	float f = 1.0 - clamp(dot(n, v), 0.0, 1.0);
	return f * f * f;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

void toon_light(vec3 n, vec3 l, vec3 v, vec3 lc, float att, float sheen_amt, inout vec3 diffuse, inout vec3 spec) {
	float ndl = dot(n, l);
	float w = clamp((ndl + 0.35) / 1.35, 0.0, 1.0);
	float ramp = smoothstep(0.05, 0.95, w);
	float sh = ramp * att;
	vec3 tinted = mix(shade_tint, vec3(1.0), sh);
	diffuse += lc * tinted * sh / PI + lc * shade_tint * 0.14 * (1.0 - sh) / PI;
	float rim = toon_rim(n, v) * smoothstep(-0.1, 0.5, ndl);
	diffuse += lc * att * rim * rim_strength / PI;
	vec3 h = normalize(l + v);
	spec += lc * att * smoothstep(0.55, 0.75, pow(max(dot(n, h), 0.0), sheen_pow)) * sheen_amt / PI;
}
