shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.003;
uniform float aberration_center_falloff : hint_range(0.0, 2.0) = 1.2;

// Vignette settings
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.5;
uniform vec3 vignette_color : source_color = vec3(0.0, 0.0, 0.0);

void fragment() {
	// Distance from center (0,0 at center, 1 at corners)
	vec2 center_offset = SCREEN_UV - vec2(0.5);
	float dist_from_center = length(center_offset) * 2.0;

	// Stronger effect at edges (psychedelic peripheral distortion)
	float falloff = pow(dist_from_center, aberration_center_falloff);
	float offset = aberration_amount * falloff;

	// Direction from center for radial aberration
	vec2 dir = normalize(center_offset + vec2(0.0001)); // avoid div by zero

	// Sample RGB channels with offset
	float r = textureLod(screen_texture, SCREEN_UV + dir * offset, 0.0).r;
	float g = textureLod(screen_texture, SCREEN_UV, 0.0).g;
	float b = textureLod(screen_texture, SCREEN_UV - dir * offset, 0.0).b;

	vec3 color = vec3(r, g, b);

	// Vignette effect - darken edges for tunnel vision
	float vignette = 1.0 - smoothstep(1.0 - vignette_smoothness, 1.0, dist_from_center);
	vignette = mix(1.0, vignette, vignette_intensity);
	color = mix(vignette_color, color, vignette);

	COLOR = vec4(color, 1.0);
}
