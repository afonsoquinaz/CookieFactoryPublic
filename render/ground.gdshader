shader_type spatial;
render_mode cull_back;
// Endless meadow. The grass colour comes from the biome of each land chunk
// (smoothly blended between chunk centres); land you don't own is a little
// darker and hazier; a cream dashed line marks the edge of your land.
// Roads are cobbled paths drawn per 2 m grid cell from road_tex: each road
// cell links its centre to its road neighbours (and a doorstep stub toward
// its building), and the path is everything near those links. The High
// Street (two cell rows from street_y) runs from horizon to horizon: paved
// setts, kerbs with gaps where side roads join, a dashed centre line.
#include "res://render/toon.gdshaderinc"

uniform sampler2D biome_tex : source_color, filter_linear, repeat_disable;
uniform sampler2D own_tex : filter_nearest, repeat_disable;
uniform vec2 tex_origin = vec2(-64.0, -64.0);   // chunk coords of texel 0
uniform float tex_n = 128.0;
uniform float chunk_m = 16.0;
uniform vec4 border_col : source_color = vec4(0.98, 0.94, 0.84, 1.0);
uniform sampler2D road_tex : filter_nearest, repeat_disable;
uniform vec2 road_origin = vec2(-128.0, -128.0);
uniform float road_n = 256.0;
uniform float cell_m = 2.0;
uniform float road_w = 0.37;   // half width, in cells
uniform vec4 stone_a : source_color = vec4(0.79, 0.74, 0.65, 1.0);
uniform vec4 stone_b : source_color = vec4(0.86, 0.82, 0.74, 1.0);
uniform vec4 stone_c : source_color = vec4(0.72, 0.68, 0.6, 1.0);
uniform vec4 grout_col : source_color = vec4(0.55, 0.51, 0.45, 1.0);
uniform vec4 kerb_col : source_color = vec4(0.6, 0.57, 0.52, 1.0);
uniform float street_y = -1.0;  // first row (cells) of the High Street
uniform vec4 sett_a : source_color = vec4(0.55, 0.52, 0.49, 1.0);
uniform vec4 sett_b : source_color = vec4(0.62, 0.59, 0.55, 1.0);
uniform vec4 street_kerb : source_color = vec4(0.88, 0.85, 0.78, 1.0);
uniform vec4 line_col : source_color = vec4(0.97, 0.93, 0.8, 1.0);

varying vec3 v_wpos;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float owned_at(vec2 chunk) {
	vec2 t = chunk - tex_origin;
	if (t.x < 0.0 || t.y < 0.0 || t.x >= tex_n || t.y >= tex_n) return 0.0;
	return texelFetch(own_tex, ivec2(t), 0).r;
}

bool is_street(vec2 cell) {
	return cell.y >= street_y && cell.y < street_y + 2.0;
}

int road_at(vec2 cell) {
	if (is_street(cell)) return 1;
	vec2 t = cell - road_origin;
	if (t.x < 0.0 || t.y < 0.0 || t.x >= road_n || t.y >= road_n) return 0;
	return int(texelFetch(road_tex, ivec2(t), 0).r * 255.0 + 0.5);
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// distance (cells) from a point in road cell rc (local l in 0..1) to the path skeleton
float road_dist(vec2 rc, vec2 l, int m) {
	vec2 c = vec2(0.5);
	float d = length(l - c);
	vec2 dirs[4] = vec2[4](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0));
	for (int k = 0; k < 4; k++) {
		bool link = (road_at(rc + dirs[k]) & 1) == 1 || ((m >> (k + 1)) & 1) == 1;
		if (link) d = min(d, seg_dist(l, c, c + dirs[k] * 0.5));
	}
	return d;
}

// cobblestones: x = distance to the stone edge, y = stone id
vec2 cobble(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash12(i + g), hash12(i + g + 17.3)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; id = hash12(i + g + 3.7); }
			else if (d < d2) { d2 = d; }
		}
	}
	return vec2(d2 - d1, id);
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
	// the High Street
	vec2 rc = floor(p / cell_m);
	int rm = road_at(rc);
	if (is_street(rc)) {
		float v = (p.y / cell_m - street_y) * 0.5;      // 0..1 across the street
		float lx = p.x / cell_m - rc.x;                  // 0..1 along this cell
		// setts: staggered rectangles
		vec2 q = vec2(p.x / 0.62, p.y / 0.36);
		q.x += step(1.0, mod(floor(q.y), 2.0)) * 0.5;
		vec2 f = fract(q);
		float sid = hash12(floor(q));
		float gap = min(min(f.x, 1.0 - f.x) * 0.62, min(f.y, 1.0 - f.y) * 0.36);
		vec3 st = mix(sett_a.rgb, sett_b.rgb, sid) * mix(0.92, 1.04, vnoise(p * 0.9));
		st = mix(grout_col.rgb * 0.8, st, smoothstep(0.012, 0.04, gap));
		// worn wheel tracks
		float lane = abs(fract(v * 2.0) - 0.5);
		st *= 1.0 - (1.0 - smoothstep(0.08, 0.2, abs(lane - 0.22))) * 0.05;
		// dashed centre line
		float dash = step(0.42, fract(p.x / 2.4));
		st = mix(st, line_col.rgb, (1.0 - smoothstep(0.035, 0.05, abs(v - 0.5))) * dash * 0.9);
		// kerbs along both edges, open where a side road joins
		float k = 0.0;
		if (v < 0.07 && (road_at(vec2(rc.x, street_y - 1.0)) & 1) == 0) k = 1.0;
		if (v > 0.93 && (road_at(vec2(rc.x, street_y + 2.0)) & 1) == 0) k = 1.0;
		if (v < 0.07 && (road_at(vec2(rc.x, street_y - 1.0)) & 1) == 1 && abs(lx - 0.5) > road_w) k = 1.0;
		if (v > 0.93 && (road_at(vec2(rc.x, street_y + 2.0)) & 1) == 1 && abs(lx - 0.5) > road_w) k = 1.0;
		float kv = min(v, 1.0 - v);
		vec3 kc = street_kerb.rgb * mix(0.9, 1.0, step(0.5, fract(p.x / 0.9)));
		kc = mix(kc * 0.82, kc, smoothstep(0.0, 0.02, kv));
		st = mix(st, kc, k);
		// a soft gutter shadow inside the kerb
		st *= 1.0 - (1.0 - smoothstep(0.07, 0.12, kv)) * (1.0 - k) * 0.12;
		c = st;
	} else if ((rm & 1) == 1) {
		vec2 l = p / cell_m - rc;
		float d = road_dist(rc, l, rm);
		float edge = smoothstep(road_w + 0.015, road_w - 0.015, d);
		// worn grass right beside the path
		c *= 1.0 - (1.0 - smoothstep(road_w, road_w + 0.12, d)) * (1.0 - edge) * 0.18;
		vec2 cb = cobble(p * 2.3);
		vec3 stone = mix(stone_a.rgb, stone_b.rgb, cb.y);
		stone = mix(stone, stone_c.rgb, step(0.82, cb.y) * 0.6);
		stone *= mix(0.9, 1.03, vnoise(p * 1.7));
		float grout = 1.0 - smoothstep(0.03, 0.09, cb.x);
		stone = mix(stone, grout_col.rgb, grout * 0.75);
		// a darker kerb along the edge
		float kerb = smoothstep(road_w - 0.075, road_w - 0.045, d);
		stone = mix(stone, kerb_col.rgb, kerb * 0.8);
		c = mix(c, stone, edge);
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
