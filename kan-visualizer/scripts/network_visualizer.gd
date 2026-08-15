extends Control

var edge_scene = preload("res://scenes/edge.tscn")
var neuron_scene = preload("res://scenes/neuron.tscn")

@export var selected_edge_panel: Panel

var network_margin = Vector2(50, 50)
var architecture = [2, 2, 1]

var network = []
var edges = []
var selected_edge_index = -1


func _ready() -> void:
	network = create_network(architecture)
	connect_network(network)


func build_network() -> void:
	network = create_network(architecture)
	connect_network(network)


func create_neuron(neuron_position: Vector2):
	var neuron = neuron_scene.instantiate()
	neuron.position = neuron_position
	add_child(neuron)
	return neuron


func create_layer(x_position: float, number_of_neurons: int):
	var layer = []

	var spacing = get_neuron_spacing(number_of_neurons)
	var start_y = get_start_y(number_of_neurons, spacing)

	for neuron_index in range(number_of_neurons):
		var neuron_position = Vector2(
			x_position,
			start_y + neuron_index * spacing
		)

		var neuron = create_neuron(neuron_position)
		layer.append(neuron)

	return layer


func create_network(network_architecture):
	var new_network = []

	for layer_index in range(network_architecture.size()):
		var number_of_neurons = network_architecture[layer_index]

		var x_position = get_layer_x(
			layer_index,
			network_architecture.size()
		)

		var layer = create_layer(
			x_position,
			number_of_neurons
		)

		new_network.append(layer)

	return new_network


func get_layer_x(layer_index: int, number_of_layers: int) -> float:
	var network_area = get_network_area()

	if number_of_layers == 1:
		return network_area.get_center().x

	var spacing = network_area.size.x / float(number_of_layers - 1)

	return network_area.position.x + layer_index * spacing


func get_neuron_spacing(number_of_neurons: int) -> float:
	var network_area = get_network_area()

	if number_of_neurons == 1:
		return 0.0

	return network_area.size.y / float(number_of_neurons - 1)


func get_start_y(number_of_neurons: int, spacing: float) -> float:
	var network_area = get_network_area()

	if number_of_neurons == 1:
		return network_area.get_center().y

	return network_area.position.y


func get_network_area() -> Rect2:
	return Rect2(
		network_margin,
		size - network_margin * 2.0
	)


func create_edge(
	start_neuron,
	end_neuron,
	from_layer: int,
	from_neuron: int,
	to_layer: int,
	to_neuron: int
):
	var edge = edge_scene.instantiate()

	edge.start_neuron = start_neuron
	edge.end_neuron = end_neuron

	edge.edge_index = edges.size()

	edge.from_layer = from_layer
	edge.from_neuron = from_neuron

	edge.to_layer = to_layer
	edge.to_neuron = to_neuron

	edge.edge_selected.connect(_on_edge_selected)

	add_child(edge)
	edges.append(edge)

	return edge


func connect_network(current_network) -> void:
	for layer_index in range(current_network.size() - 1):
		var current_layer = current_network[layer_index]
		var next_layer = current_network[layer_index + 1]

		for current_neuron_index in range(current_layer.size()):
			var current_neuron = current_layer[current_neuron_index]

			for next_neuron_index in range(next_layer.size()):
				var next_neuron = next_layer[next_neuron_index]

				create_edge(
					current_neuron,
					next_neuron,
					layer_index,
					current_neuron_index,
					layer_index + 1,
					next_neuron_index
				)


func _on_edge_selected(index):
	selected_edge_index = index

	for i in range(edges.size()):
		edges[i].set_selected(i == selected_edge_index)

	selected_edge_panel.show_edge(edges[selected_edge_index])
