shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Player position for proximity effect
uniform vec3 player_position = vec3(0.0, 0.0, 0.0);

// Tunnel parameters for zone effect
uniform float tunnel_start_z = 14.0;
uniform float tunnel_end_z = -136.0;

// Breathing animation parameters
uniform float breath_amplitude = 0.5;

// Material properties
uniform float metallic : hint_range(0.0, 1.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;

// Proximity settings
uniform float proximity_radius = 6.0;
uniform float proximity_boost = 0.5;

// Zone color settings (start = warm gold, end = cool amber)
uniform vec3 zone_start_color = vec3(0.75, 0.55, 0.12);
uniform vec3 zone_end_color = vec3(0.5, 0.3, 0.08);

// Base emission
uniform float base_emission_energy = 0.08;

// Color shift (subtle hue variation over time)
uniform float color_shift_speed = 0.05;

// Instance data passed via INSTANCE_CUSTOM:
// r = direction (-1, 0, or 1)
// g = phase (random 0-TAU*10)
// b = speed (0.8-1.6)
// a = unused (reserved)

varying vec3 world_position;
varying float proximity_factor;
varying float zone_factor;

void vertex() {
	// Get instance animation data
	float direction = INSTANCE_CUSTOM.r;
	float phase = INSTANCE_CUSTOM.g;
	float speed = INSTANCE_CUSTOM.b;

	// Breathing animation - offset X position
	if (direction != 0.0) {
		float offset = sin(TIME * speed + phase) * breath_amplitude * direction;
		VERTEX.x += offset;
	}

	// Calculate world position for fragment shader
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Calculate proximity to player (0 = far, 1 = close)
	float dist = distance(world_position, player_position);
	proximity_factor = 1.0 - smoothstep(0.0, proximity_radius, dist);

	// Calculate zone factor (0 = start of tunnel, 1 = end)
	float tunnel_length = tunnel_start_z - tunnel_end_z;
	zone_factor = clamp((tunnel_start_z - world_position.z) / tunnel_length, 0.0, 1.0);
}

void fragment() {
	// Time-based color shift (very subtle)
	float shift = sin(TIME * color_shift_speed * 6.28318) * 0.5 + 0.5;
	float hue_offset = shift * 0.04;

	// Zone-based color interpolation
	vec3 zone_color = mix(zone_start_color, zone_end_color, zone_factor);

	// Apply subtle hue shift
	vec3 base_color = zone_color * (1.0 + hue_offset * 0.3);

	// Proximity boost - blocks near player glow more
	float emission_boost = 1.0 + proximity_factor * proximity_boost;

	// Also subtle color warmth boost when close (very gentle)
	vec3 proximity_tint = mix(vec3(1.0), vec3(1.08, 1.04, 0.96), proximity_factor * 0.3);

	ALBEDO = base_color * proximity_tint;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	// Emission with proximity boost
	EMISSION = base_color * base_emission_energy * emission_boost * proximity_tint;
}
