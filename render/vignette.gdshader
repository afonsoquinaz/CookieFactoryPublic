shader_type canvas_item;
// Soft pulsing coloured edge glow (Cookie Rush).
uniform vec4 color : source_color = vec4(1.0, 0.45, 0.7, 1.0);
uniform float strength = 0.0;

void fragment() {
	vec2 d = abs(UV - 0.5) * 2.0;
	float e = max(d.x * 0.85, d.y);
	float v = smoothstep(0.62, 1.0, e) * (0.75 + 0.25 * sin(TIME * 5.0));
	COLOR = vec4(color.rgb, v * strength * 0.55);
}
