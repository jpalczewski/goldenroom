extends CharacterBody3D

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var gravity: float = 20.0

## Camera sway settings (dreamy floating effect)
@export var sway_enabled: bool = true
@export var sway_amount: float = 0.008  ## Maximum rotation in radians
@export var sway_speed_x: float = 0.15  ## Speed of vertical sway
@export var sway_speed_z: float = 0.12  ## Speed of roll sway

var camera: Camera3D
var flashlight: SpotLight3D
var sway_time: float = 0.0
var base_camera_rotation: Vector3

func _ready():
	add_to_group("player")
	camera = $Camera3D
	flashlight = $Camera3D/Flashlight
	flashlight.visible = false

func _input(event):
	# Kliknięcie żeby przechwycić mysz (wymagane w web)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Obrót w poziomie (yaw) - cały gracz
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Obrót w pionie (pitch) - tylko kamera
		base_camera_rotation.x -= event.relative.y * mouse_sensitivity
		base_camera_rotation.x = clamp(base_camera_rotation.x, -PI/2, PI/2)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Latarka na F
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		flashlight.visible = not flashlight.visible

func _physics_process(delta):
	# Grawitacja
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Vector3.ZERO

	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	# Przekształć kierunek względem obrotu gracza
	var direction = (transform.basis * input_dir).normalized()

	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

func _process(delta: float) -> void:
	if not sway_enabled:
		camera.rotation = base_camera_rotation
		return

	sway_time += delta

	# Sinusoidal sway with different frequencies for organic feel
	var sway_x = sin(sway_time * sway_speed_x * TAU) * sway_amount
	var sway_z = sin(sway_time * sway_speed_z * TAU + 1.5) * sway_amount * 0.7  # Roll is subtler

	# Apply base rotation + sway
	camera.rotation.x = base_camera_rotation.x + sway_x
	camera.rotation.z = base_camera_rotation.z + sway_z
