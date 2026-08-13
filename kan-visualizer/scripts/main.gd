extends Node2D

var edge_scene = preload("res://scenes/edge.tscn")
var neuron_scene = preload("res://scenes/neuron.tscn")

var network_margin = Vector2(100, 100)
var network

var architecture = [2,2,1]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	network = create_network(architecture)
	connect_network(network)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_neuron(neuron_position):
	var neuron = neuron_scene.instantiate()
	neuron.position = neuron_position
	add_child(neuron)
	return neuron
	
func create_layer(x_position, number_of_neurons):
	var layer = []
	var spacing = get_neuron_spacing(number_of_neurons)
	var start_y = get_start_y(number_of_neurons, spacing)

	for neuron_index in range(number_of_neurons):
		var neuron_position = Vector2(x_position, start_y + neuron_index * spacing)
		var neuron = create_neuron(neuron_position)
		layer.append(neuron)
	return layer

func create_network(network_architecture):
	var network = []

	for layer_index in range(network_architecture.size()):
		var number_of_neurons = network_architecture[layer_index]
		var x_position = get_layer_x(layer_index, network_architecture.size())
		var layer = create_layer(x_position, number_of_neurons)
		network.append(layer)
	return network
	

func get_layer_x(layer_index, number_of_layers):
	var network_area = get_network_area()
	if number_of_layers == 1:
		return network_area.get_center().x
	
	var spacing = network_area.size.x / (number_of_layers - 1)
	return network_area.position.x + layer_index * spacing

func get_neuron_spacing(number_of_neurons):
	var network_area = get_network_area()
	if number_of_neurons == 1:
		return 0.0
	return network_area.size.y / (number_of_neurons - 1)
	
func get_start_y(number_of_neurons, spacing):
	var network_area = get_network_area()
	if number_of_neurons == 1:
		return network_area.get_center().y
	return network_area.position.y
	

func get_network_area():
	var viewport_size = get_viewport_rect().size
	return Rect2(network_margin, viewport_size - network_margin * 2.0)
	
func _draw():
	if network == null:
		return

	for layer_index in range(network.size() - 1):
		var current_layer = network[layer_index]
		var next_layer = network[layer_index + 1]

		for current_neuron in current_layer:
			for next_neuron in next_layer:
				draw_line(
					current_neuron.position,
					next_neuron.position,
					Color(0.4, 0.4, 0.4),
					3.0
				)

func create_edge(start_neuron, end_neuron):
	var edge = edge_scene.instantiate()
	edge.start_neuron = start_neuron
	edge.end_neuron = end_neuron
	edge.coefficients = [
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	]
	add_child(edge)
	return edge

func connect_network(network):
	for layer_index in range(network.size() - 1):
		var current_layer = network[layer_index]
		var next_layer = network[layer_index + 1]

		for current_neuron in current_layer:
			for next_neuron in next_layer:
				create_edge(
					current_neuron,
					next_neuron
				)
