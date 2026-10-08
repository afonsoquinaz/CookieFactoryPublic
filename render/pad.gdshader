shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix;
// Floor interaction pad: rounded-rectangle with a thick border, soft fill,
// marching chevrons pointing in/out, an icon in the middle and a fill that
// rises for build pads. Drawn on a flat quad (UV 0..1).
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 0.18);
uniform vec2 size = vec2(1.6, 1.6);         // metres, for corner radius + border
uniform float radius = 0.28;
uniform float border = 0.09;
uniform float active = 0.0;                 // 0..1 someone is standing here
uniform float progress = -1.0;              // >= 0: build pad fill
uniform float direction = 0.0;              // 1 = arrows in (give), -1 = out (take)
uniform sampler2D icon : source_color, filter_linear_mipmap;
uniform float icon_size = 0.62;             // fraction of the short side
uniform float has_icon = 1.0;
uniform float dim = 0.0;                    // locked / inactive look

float rbox(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float d = rbox(p, size * 0.5 - 0.02, radius);
	float aa = fwidth(d) * 1.2;
	float inside = 1.0 - smoothstep(-aa, aa, d);
	float ring = inside * smoothstep(-border - aa, -border + aa, d);
	float pulse = 0.5 + 0.5 * sin(TIME * 6.0);
	vec4 fc = fill_color;
	fc.a *= 1.0 + active * (0.8 + pulse * 0.6);
	vec3 col = fc.rgb;
	float a = fc.a * inside;
	// rising fill (build pads)
	if (progress >= 0.0) {
		float h = (UV.y - 0.0);
		float filled = step(1.0 - progress, UV.y);
		col = mix(col, color.rgb, filled * 0.55);
		a = max(a, filled * 0.55 * inside);
	}
	// chevrons along the border band
	if (direction != 0.0) {
		float s = fract((UV.x + UV.y) * 3.0 - TIME * 0.8 * direction);
		float chev = smoothstep(0.0, 0.08, s) * (1.0 - smoothstep(0.25, 0.33, s));
		float band = inside * (1.0 - smoothstep(-border * 2.6, -border * 2.4, d)) * smoothstep(-border * 3.4, -border * 3.2, d);
		a = max(a, band * chev * 0.5 * (0.6 + active * 0.4));
	}
	col = mix(col, color.rgb, ring);
	a = max(a, ring * color.a * (0.85 + active * 0.15));
	// icon
	vec2 iuv = (UV - 0.5) * size / (min(size.x, size.y) * icon_size) + 0.5;
	if (has_icon > 0.5 && iuv.x > 0.0 && iuv.x < 1.0 && iuv.y > 0.0 && iuv.y < 1.0) {
		vec4 ic = texture(icon, iuv);
		col = mix(col, ic.rgb, ic.a);
		a = max(a, ic.a * (0.95 - dim * 0.4));
	}
	col = mix(col, vec3(dot(col, vec3(0.33))), dim * 0.7);
	ALBEDO = col;
	ALPHA = a;
}
