extends Node2D

signal edge_selected(index)

var start_neuron
var end_neuron

var edge_index = -1
var selected = false

func _ready():
	z_index = -1

func _process(_delta):
	if start_neuron == null or end_neuron == null:
		return

	queue_redraw()

func _draw():
	if start_neuron == null or end_neuron == null:
		return

	var colour = Color(0.4, 0.4, 0.4)

	if selected:
		colour = Color(1.0, 0.8, 0.2)

	draw_line(
		start_neuron.position,
		end_neuron.position,
		colour,
		3.0
	)

func is_mouse_over_edge(mouse_position: Vector2) -> bool:
	var start = start_neuron.position
	var end = end_neuron.position
	var closest_point = Geometry2D.get_closest_point_to_segment(mouse_position, start, end)
	return closest_point.distance_to(mouse_position) < 10.0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_mouse_over_edge(event.position):
				edge_selected.emit(edge_index)

func set_selected(value):
	selected = value
	queue_redraw()
