extends Control

const SCENE_PATH = "res://scenes/main_tunnel.tscn"

@onready var start_button: Button = $UI/CenterContainer/VBoxContainer/StartButton
@onready var loading_overlay: ColorRect = $LoadingOverlay
@onready var loading_label: Label = $LoadingOverlay/CenterContainer/LoadingLabel

var is_loading: bool = false
var loading_time: float = 0.0
var fade_complete: bool = false

func _ready() -> void:
	start_button.grab_focus()
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	if is_loading:
		return

	is_loading = true
	loading_time = 0.0
	fade_complete = false

	# Show loading overlay
	loading_overlay.visible = true
	loading_overlay.modulate.a = 0.0

func _process(delta: float) -> void:
	if not is_loading:
		return

	loading_time += delta

	# Fade in overlay
	if loading_overlay.modulate.a < 1.0:
		loading_overlay.modulate.a = minf(loading_overlay.modulate.a + delta * 3.0, 1.0)
	elif not fade_complete:
		# Fade complete, wait one more frame for render, then load
		fade_complete = true
		_load_scene.call_deferred()

	# Pulse the loading text (gentle golden glow)
	var pulse = (sin(loading_time * 2.5) * 0.5 + 0.5) * 0.4 + 0.6
	loading_label.modulate = Color(1.0, pulse, pulse * 0.7, 1.0)

func _load_scene() -> void:
	# This runs after the frame renders, so loading screen is visible
	var scene = load(SCENE_PATH)
	get_tree().change_scene_to_packed(scene)
