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
//
// era (0..4, from the Lab level) turns the village into a datacenter: concrete
// aprons around buildings (road_tex green = a building's lot) and paver paths,
// then concrete slabs over all your land and asphalt roads, then raised-floor
// tiles and LED lane lines, and finally a dark circuit-board floor with light
// pulses running along its traces.
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
uniform float era = 0.0;
uniform vec4 glow_col : source_color = vec4(0.35, 0.9, 1.0, 1.0);

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

// a building stands here or right next to it (its paved lot)
float lot_at(vec2 cell) {
	vec2 t = cell - road_origin;
	if (t.x < 0.0 || t.y < 0.0 || t.x >= road_n || t.y >= road_n) return 0.0;
	return texelFetch(road_tex, ivec2(t), 0).g;
}

// weight of era k (0 before it, 1 once reached, a smooth blend while the era changes)
float era_w(float k) {
	return clamp(era - k + 1.0, 0.0, 1.0);
}

// concrete slabs, 4 m, with joints and stains
vec3 concrete(vec2 p) {
	vec2 q = p / 4.0;
	vec2 f = fract(q);
	float sid = hash12(floor(q));
	vec3 c = mix(vec3(0.7, 0.7, 0.68), vec3(0.76, 0.76, 0.74), sid) * mix(0.93, 1.03, vnoise(p * 0.8));
	float j = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 4.0;
	c = mix(c * 0.72, c, smoothstep(0.02, 0.06, j));
	c *= 1.0 - smoothstep(0.6, 0.85, vnoise(p * 0.25 + 4.0)) * 0.08;
	return c;
}

// small square pavers for campus paths
vec3 pavers(vec2 p) {
	vec2 q = p / 0.6;
	vec2 f = fract(q);
	float sid = hash12(floor(q));
	vec3 c = mix(vec3(0.74, 0.74, 0.72), vec3(0.82, 0.82, 0.8), sid);
	float j = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 0.6;
	return mix(c * 0.7, c, smoothstep(0.01, 0.03, j));
}

// raised datacenter floor: 0.6 m tiles, some perforated, cable cut-outs
vec3 raised(vec2 p) {
	vec2 q = p / 0.6;
	vec2 f = fract(q);
	float sid = hash12(floor(q));
	vec3 c = mix(vec3(0.8, 0.82, 0.84), vec3(0.86, 0.87, 0.89), sid);
	if (sid > 0.82) {
		// a perforated cooling tile
		vec2 h = fract(f * 6.0) - 0.5;
		c = mix(c * 0.62, c * 0.9, smoothstep(0.18, 0.26, length(h)));
	}
	float j = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 0.6;
	return mix(c * 0.66, c, smoothstep(0.008, 0.025, j));
}

// circuit-board floor: graphite with sparse traces, pads and chips.
// rgb = colour, a = glow
vec4 circuit(vec2 p) {
	vec3 c = vec3(0.15, 0.17, 0.21) * mix(0.92, 1.06, vnoise(p * 0.4));
	vec2 q = p / 1.6;
	vec2 i = floor(q);
	vec2 f = fract(q);
	float h = hash12(i);
	float tw = 0.035;
	// a trace through some cells: horizontal runs, vertical runs, a few corners
	float d = 9.0;
	float row = hash12(vec2(0.0, i.y) + 5.3);
	float col = hash12(vec2(i.x, 0.0) + 8.1);
	if (row > 0.62) d = abs(f.y - 0.5);
	if (col > 0.7) d = min(d, abs(f.x - 0.5));
	if (h > 0.9) d = min(d, min(f.x < 0.5 ? abs(f.y - 0.5) : 9.0, f.y > 0.5 ? abs(f.x - 0.5) : 9.0));
	float trace = 1.0 - smoothstep(tw, tw + 0.02, d);
	c = mix(c, vec3(0.22, 0.34, 0.38), trace);
	// pads where traces cross
	float pad = (1.0 - smoothstep(0.07, 0.1, length(f - 0.5))) * step(0.62, row) * step(0.7, col);
	c = mix(c, vec3(0.66, 0.58, 0.36), pad);
	// now and then a chip on the board
	vec2 ci = floor(p / 6.4);
	vec2 cf = fract(p / 6.4);
	float chip = step(0.8, hash12(ci + 2.2)) * step(max(abs(cf.x - 0.5), abs(cf.y - 0.5)), 0.16);
	c = mix(c, vec3(0.08, 0.09, 0.11), chip);
	// light pulses running along the traces
	float along = row > 0.62 && abs(f.y - 0.5) <= d + 0.001 ? p.x : p.y;
	float pulse = smoothstep(0.94, 1.0, fract(along * 0.05 - TIME * 0.4 + h)) * trace;
	float glow = trace * 0.12 + pulse * 1.4 + pad * 0.15;
	return vec4(c, glow);
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
	// the village becomes a datacenter: pave your land, era by era
	vec2 rc = floor(p / cell_m);
	int rm = road_at(rc);
	float glow = 0.0;
	if (own > 0.75 && era > 0.0) {
		float lot = lot_at(rc);
		// era 1: concrete aprons around buildings; era 2: slabs over all your land (a few lawns left)
		float lawn = smoothstep(0.66, 0.74, vnoise(p * 0.07 + 31.0)) * (1.0 - lot);
		float pave = max(lot * era_w(1.0), era_w(2.0) * (1.0 - lawn * (1.0 - era_w(3.0))));
		vec3 floor_c = concrete(p);
		floor_c = mix(floor_c, raised(p), era_w(3.0));
		vec4 board = circuit(p);
		floor_c = mix(floor_c, board.rgb, era_w(4.0));
		c = mix(c, floor_c, pave);
		glow += board.a * era_w(4.0) * pave;
		// era 3: glowing lines along the edges of every lot
		if (era > 2.0) {
			vec2 lf = p / cell_m - rc;
			float e = 9.0;
			if (lot_at(rc + vec2(1.0, 0.0)) < 0.5) e = min(e, 1.0 - lf.x);
			if (lot_at(rc + vec2(-1.0, 0.0)) < 0.5) e = min(e, lf.x);
			if (lot_at(rc + vec2(0.0, 1.0)) < 0.5) e = min(e, 1.0 - lf.y);
			if (lot_at(rc + vec2(0.0, -1.0)) < 0.5) e = min(e, lf.y);
			float edge = (1.0 - smoothstep(0.02, 0.05, e)) * lot * era_w(3.0);
			c = mix(c, glow_col.rgb * 0.8, edge * 0.6);
			glow += edge * 0.8;
		}
	}
	// the High Street
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
		// from the campus era on: smooth asphalt
		vec3 asph = vec3(0.26, 0.27, 0.29) * mix(0.9, 1.06, vnoise(p * 2.3)) * mix(0.95, 1.03, vnoise(p * 0.3));
		st = mix(st, asph, era_w(1.0));
		// dashed centre line (glowing LEDs from the hyperscale era)
		float dash = step(0.42, fract(p.x / 2.4));
		float cl = (1.0 - smoothstep(0.035, 0.05, abs(v - 0.5))) * dash;
		st = mix(st, mix(line_col.rgb, glow_col.rgb, era_w(3.0)), cl * 0.9);
		glow += cl * era_w(3.0) * 0.9;
		// solid white lane edges on asphalt, LED strips later, light streaks at the end
		float le = (1.0 - smoothstep(0.012, 0.022, abs(v - 0.11))) + (1.0 - smoothstep(0.012, 0.022, abs(v - 0.89)));
		st = mix(st, mix(vec3(0.9), glow_col.rgb, era_w(3.0)), le * era_w(2.0) * 0.85);
		glow += le * era_w(3.0) * 0.6;
		float streak = smoothstep(0.85, 1.0, fract(p.x * 0.03 - TIME * (v < 0.5 ? 0.9 : -0.9) + floor(v * 4.0) * 0.37));
		float lane2 = 1.0 - smoothstep(0.02, 0.06, abs(abs(v - 0.5) - 0.25));
		glow += streak * lane2 * era_w(4.0) * 1.2;
		st = mix(st, glow_col.rgb, streak * lane2 * era_w(4.0) * 0.5);
		// kerbs along both edges, open where a side road joins
		float k = 0.0;
		if (v < 0.07 && (road_at(vec2(rc.x, street_y - 1.0)) & 1) == 0) k = 1.0;
		if (v > 0.93 && (road_at(vec2(rc.x, street_y + 2.0)) & 1) == 0) k = 1.0;
		if (v < 0.07 && (road_at(vec2(rc.x, street_y - 1.0)) & 1) == 1 && abs(lx - 0.5) > road_w) k = 1.0;
		if (v > 0.93 && (road_at(vec2(rc.x, street_y + 2.0)) & 1) == 1 && abs(lx - 0.5) > road_w) k = 1.0;
		float kv = min(v, 1.0 - v);
		vec3 kc = mix(street_kerb.rgb, vec3(0.78, 0.79, 0.8), era_w(2.0)) * mix(0.9, 1.0, step(0.5, fract(p.x / 0.9)));
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
		// campus pavers, then asphalt with lane edges, then LED edges
		stone = mix(stone, pavers(p), era_w(1.0));
		vec3 asph = vec3(0.28, 0.29, 0.31) * mix(0.9, 1.06, vnoise(p * 2.3));
		stone = mix(stone, asph, era_w(2.0));
		// a darker kerb along the edge
		float kerb = smoothstep(road_w - 0.075, road_w - 0.045, d);
		vec3 kcol = mix(kerb_col.rgb, mix(vec3(0.86), glow_col.rgb, era_w(3.0)), era_w(2.0));
		stone = mix(stone, kcol, kerb * 0.8);
		glow += kerb * edge * era_w(3.0) * 0.7;
		// data pulses down the middle of every road at the end
		float mid = 1.0 - smoothstep(0.02, 0.05, d);
		float run = smoothstep(0.9, 1.0, fract((p.x + p.y) * 0.12 - TIME * 0.6));
		glow += mid * run * era_w(4.0) * 1.4;
		stone = mix(stone, glow_col.rgb, mid * run * era_w(4.0) * 0.6);
		c = mix(c, stone, edge);
	}
	// slow drifting cloud shadows
	float cl = vnoise(p * 0.045 + vec2(TIME * 0.035, TIME * 0.012)) * 0.65 + vnoise(p * 0.11 - vec2(TIME * 0.05, 0.0)) * 0.35;
	c *= 1.0 - smoothstep(0.55, 0.75, cl) * 0.16;
	// biome_tex is a source_color texture, so c is already linear
	ALBEDO = c * 0.82;
	EMISSION = c * 0.07 + glow_col.rgb * glow * 0.9;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}

void light() {
	toon_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, 0.0, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}
