shader_type canvas_item;
// Title menu backdrop: darkens the top (behind the crest) and the bottom
// (behind PLAY) so the live island in the middle stays visible.

void fragment() {
	float y = UV.y;
	float top = smoothstep(0.62, 0.0, y) * 0.62;
	float bot = smoothstep(0.62, 1.0, y) * 0.5;
	vec2 d = (UV - 0.5) * vec2(1.4, 1.0);
	float vig = smoothstep(0.35, 0.85, length(d)) * 0.35;
	COLOR = vec4(0.09, 0.055, 0.035, clamp(top + bot + vig, 0.0, 0.85));
}
