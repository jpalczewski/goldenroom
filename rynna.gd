extends Node3D

@export var amplitude: float = 0.5
@export var speed_min: float = 0.8
@export var speed_max: float = 1.6

var blocks_data: Array = []  # [nodes_array, original_x, direction, phase, speed]
var time: float = 0.0

func _ready():
	var layer_counts = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
	var center_x = 2.5

	for layer in range(1, 11):
		var count = layer_counts[layer - 1]

		for i in range(count):
			var base_name = "W%d_%d" % [layer, i]

			# Pomiń kotwice (W1_0 i W10_0)
			if base_name == "W1_0" or base_name == "W10_0":
				continue

			var main_node = get_node_or_null(base_name)
			if main_node:
				# Zbierz główny klocek i jego ogon
				var nodes: Array[Node3D] = [main_node]
				var t1 = get_node_or_null(base_name + "_t1")
				var t2 = get_node_or_null(base_name + "_t2")
				if t1:
					nodes.append(t1)
				if t2:
					nodes.append(t2)

				var direction = sign(main_node.position.x - center_x)
				if direction == 0:
					direction = 1.0

				var phase = randf() * TAU * 10.0
				var spd = randf_range(speed_min, speed_max)

				# Zapisz oryginalne pozycje X dla każdego klocka w wężu
				var original_positions: Array[float] = []
				for node in nodes:
					original_positions.append(node.position.x)

				blocks_data.append([nodes, original_positions, direction, phase, spd])

func _process(delta):
	time += delta

	for data in blocks_data:
		var nodes = data[0]
		var original_positions = data[1]
		var direction = data[2]
		var phase = data[3]
		var spd = data[4]

		var offset = sin(time * spd + phase) * amplitude * direction

		# Animuj wszystkie klocki w wężu razem
		for idx in range(nodes.size()):
			nodes[idx].position.x = original_positions[idx] + offset
