extends Node3D

## Pulsating light effect - creates breathing/dreamy atmosphere
## Attach to SwiatloPunktowe scene

@export var pulse_speed: float = 0.12  ## Speed of pulsation (cycles per second) - slower, dreamier
@export var energy_min: float = 3.5   ## Minimum light energy
@export var energy_max: float = 5.0   ## Maximum light energy
@export var emission_min: float = 5.0 ## Minimum emission energy
@export var emission_max: float = 8.0 ## Maximum emission energy
@export var phase_offset: float = 0.0 ## Phase offset for desynchronization

## Flickering settings (old bulb effect)
@export var flicker_enabled: bool = true
@export var flicker_intensity: float = 0.08  ## Max flicker variation (0-1)
@export var flicker_speed: float = 8.0  ## Base flicker speed

@onready var light: OmniLight3D = $OmniLight3D
@onready var bulb: CSGSphere3D = $Zarowka

var time: float = 0.0
var bulb_material: StandardMaterial3D
var flicker_offset: float = 0.0  ## Random offset for each light

func _ready() -> void:
	# Get material from bulb
	if bulb and bulb.material:
		bulb_material = bulb.material as StandardMaterial3D

	# Randomize phase offset if not set (for organic feel)
	if phase_offset == 0.0:
		phase_offset = randf() * TAU

	# Random flicker offset for each light
	flicker_offset = randf() * 100.0

func _process(delta: float) -> void:
	time += delta

	# Sinusoidal pulse with phase offset
	var pulse = (sin((time * pulse_speed * TAU) + phase_offset) + 1.0) / 2.0

	# Flickering - layered sine waves for organic randomness (like old bulb)
	var flicker = 1.0
	if flicker_enabled:
		var t = time * flicker_speed + flicker_offset
		# Multiple overlapping frequencies for pseudo-random feel
		flicker = 1.0 - flicker_intensity * (
			sin(t * 1.0) * 0.3 +
			sin(t * 2.3 + 1.2) * 0.25 +
			sin(t * 5.7 + 0.8) * 0.25 +
			sin(t * 13.1 + 2.1) * 0.2  # High frequency micro-flicker
		)

	# Apply to light energy
	if light:
		var energy = lerp(energy_min, energy_max, pulse) * flicker
		light.light_energy = energy
		light.light_volumetric_fog_energy = lerp(4.0, 6.0, pulse) * flicker

	# Apply to bulb emission
	if bulb_material:
		var emission = lerp(emission_min, emission_max, pulse) * flicker
		bulb_material.emission_energy_multiplier = emission
