extends Control

const SCENE_PATH = "res://scenes/main_tunnel.tscn"

enum LoadingState {
	IDLE,           # Initial state, waiting for button press
	FADING_IN,      # Overlay fade animation (0.33s)
	LOADING,        # Threaded loading in progress
	LOADED,         # Resource ready, preparing transition
	TRANSITIONING   # Scene change in progress
}

@onready var start_button: Button = $UI/CenterContainer/VBoxContainer/StartButton
@onready var loading_overlay: ColorRect = $LoadingOverlay
@onready var loading_label: Label = $LoadingOverlay/CenterContainer/LoadingLabel

var loading_state: LoadingState = LoadingState.IDLE
var loading_time: float = 0.0
var loading_progress: Array[float] = [0.0]
var loaded_scene: PackedScene = null
var loading_error: bool = false
var loaded_time: float = 0.0

func _ready() -> void:
	start_button.grab_focus()
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	if loading_state != LoadingState.IDLE:
		return  # Prevent multiple clicks

	loading_state = LoadingState.FADING_IN
	loading_time = 0.0
	loading_error = false
	loaded_scene = null
	loaded_time = 0.0

	# Show loading overlay
	loading_overlay.visible = true
	loading_overlay.modulate.a = 0.0

func _process(delta: float) -> void:
	match loading_state:
		LoadingState.IDLE:
			return
		LoadingState.FADING_IN:
			_process_fade_in(delta)
		LoadingState.LOADING:
			_process_loading(delta)
		LoadingState.LOADED:
			_process_loaded(delta)
		LoadingState.TRANSITIONING:
			return

func _process_fade_in(delta: float) -> void:
	loading_time += delta

	# Fade in overlay
	if loading_overlay.modulate.a < 1.0:
		loading_overlay.modulate.a = minf(loading_overlay.modulate.a + delta * 3.0, 1.0)
	else:
		# Fade complete, start threaded loading
		_start_threaded_load()
		loading_state = LoadingState.LOADING

func _start_threaded_load() -> void:
	var error = ResourceLoader.load_threaded_request(
		SCENE_PATH,
		"",   # type_hint (empty = auto-detect)
		true  # use_sub_threads for parallel loading
	)

	if error != OK:
		_handle_loading_error("Failed to request threaded load: " + error_string(error))

func _process_loading(delta: float) -> void:
	loading_time += delta

	var status = ResourceLoader.load_threaded_get_status(SCENE_PATH, loading_progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_update_loading_ui(delta)

		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_scene = ResourceLoader.load_threaded_get(SCENE_PATH)
			loading_state = LoadingState.LOADED

		ResourceLoader.THREAD_LOAD_FAILED:
			_handle_loading_error("Failed to load scene")

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_handle_loading_error("Invalid resource")

func _update_loading_ui(_delta: float) -> void:
	# Keep existing golden pulsing effect
	var pulse = (sin(loading_time * 2.5) * 0.5 + 0.5) * 0.4 + 0.6

	# Get current progress (0.0 to 1.0)
	var progress = loading_progress[0] if loading_progress.size() > 0 else 0.0
	var percentage = int(progress * 100.0)

	# Update text with percentage
	loading_label.text = "Entering... %d%%" % percentage

	# Apply golden pulsing color (existing effect)
	loading_label.modulate = Color(1.0, pulse, pulse * 0.7, 1.0)

func _process_loaded(delta: float) -> void:
	loading_time += delta

	if loaded_time == 0.0:
		loaded_time = loading_time

	# Show 100% briefly for polish (0.2s pause)
	if loading_time - loaded_time < 0.2:
		_update_loading_ui(delta)
		return

	# Transition to new scene
	loading_state = LoadingState.TRANSITIONING
	get_tree().change_scene_to_packed(loaded_scene)

func _handle_loading_error(error_message: String) -> void:
	loading_error = true
	loading_state = LoadingState.IDLE

	# Show error in red (keep golden outline from label settings)
	loading_label.text = "Error: " + error_message
	loading_label.modulate = Color(1.0, 0.3, 0.3, 1.0)

	# Log to console
	push_error("Loading failed: " + error_message)

	# Auto-hide overlay after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if loading_error:
		loading_overlay.visible = false
		start_button.grab_focus()
