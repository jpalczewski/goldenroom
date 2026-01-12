extends Node3D

@export var amplitude: float = 0.5
@export var speed_min: float = 0.8
@export var speed_max: float = 1.6
@export var rynna_count: int = 300
@export var rynna_spacing: float = 0.5
@export var start_position: Vector3 = Vector3(-4, 0, 14)

## Player reference for proximity effect
@export var player_path: NodePath

var multi_mesh_instance: MultiMeshInstance3D
var block_count: int = 0
var shader_material: ShaderMaterial
var player: Node3D

# Struktura rynny
const LAYER_COUNTS = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
const TAIL_DEPTH = 3  # Glowny + 2 ogon

func _ready():
	# Get player reference
	if player_path:
		player = get_node(player_path)
	else:
		# Try to find player automatically
		player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_parent().get_node_or_null("Player")

	_create_multi_mesh()
	_create_collision()

func _create_multi_mesh():
	# Oblicz calkowita liczbe klockow
	var blocks_per_rynna = 0
	for count in LAYER_COUNTS:
		blocks_per_rynna += count * TAIL_DEPTH
	block_count = blocks_per_rynna * rynna_count

	# Stworz MultiMesh z custom data enabled
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_custom_data = true  # Enable for shader instance data
	multi_mesh.instance_count = block_count
	multi_mesh.mesh = _create_box_mesh()

	# Stworz MultiMeshInstance3D
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	multi_mesh_instance.layers = 2  # Warstwa 2 - nie oswietlana przez ambient light gracza
	add_child(multi_mesh_instance)

	# Wypelnij pozycje i custom data
	var idx = 0
	for rynna_idx in range(rynna_count):
		var rynna_z = start_position.z - rynna_idx * rynna_spacing

		for layer in range(1, 11):
			var count = LAYER_COUNTS[layer - 1]
			var y = start_position.y + (layer - 1) * 0.5 + 0.25

			for i in range(count):
				var x = start_position.x + i * 0.5 + 0.25
				var base_name = "W%d_%d" % [layer, i]
				var is_anchor = (base_name == "W1_0" or base_name == "W10_0")

				# Kierunek od srodka rynny
				var center_x = start_position.x + 2.5
				var direction = sign(x - center_x)
				if direction == 0:
					direction = 1.0
				if is_anchor:
					direction = 0.0  # Kotwice nie animuja

				# Losowe parametry dla tego "weza"
				var phase = randf() * TAU * 10.0
				var spd = randf_range(speed_min, speed_max)

				# Dodaj 3 klocki (glowny + ogon)
				for tail_idx in range(TAIL_DEPTH):
					var z = rynna_z + tail_idx * 0.5

					# Ustaw transform (static position - animation in shader)
					var block_transform = Transform3D()
					block_transform.origin = Vector3(x, y, z)
					multi_mesh.set_instance_transform(idx, block_transform)

					# Set custom data for shader: direction, phase, speed
					# Packed into Color (r, g, b, a)
					var custom_data = Color(direction, phase, spd, 0.0)
					multi_mesh.set_instance_custom_data(idx, custom_data)

					idx += 1

	# Set shader parameters
	_update_shader_parameters()

func _create_box_mesh() -> BoxMesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.47, 0.47, 0.47)

	# Load and setup shader material
	var shader = load("res://shaders/environment/block_shader.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	# Set initial shader parameters
	shader_material.set_shader_parameter("breath_amplitude", amplitude)
	shader_material.set_shader_parameter("tunnel_start_z", start_position.z)
	shader_material.set_shader_parameter("tunnel_end_z", start_position.z - rynna_count * rynna_spacing)

	mesh.surface_set_material(0, shader_material)
	return mesh

func _update_shader_parameters():
	if shader_material:
		shader_material.set_shader_parameter("breath_amplitude", amplitude)

func _create_collision():
	var static_body = StaticBody3D.new()
	add_child(static_body)

	# Glebokosc calej rynny
	var total_depth = rynna_count * rynna_spacing + TAIL_DEPTH * 0.5
	var z_center = start_position.z - total_depth / 2 + 0.75

	# Stworz kolizje dla kazdej warstwy (schodki)
	for layer in range(10):
		var count = LAYER_COUNTS[layer]
		var width = count * 0.5
		var y = start_position.y + layer * 0.5 + 0.25
		var x = start_position.x + width / 2

		var shape = BoxShape3D.new()
		shape.size = Vector3(width, 0.5, total_depth)

		var collision = CollisionShape3D.new()
		collision.shape = shape
		collision.position = Vector3(x, y, z_center)
		static_body.add_child(collision)

func _process(_delta):
	# Only update player position - all animation is in GPU shader!
	if player and shader_material:
		shader_material.set_shader_parameter("player_position", player.global_position)
