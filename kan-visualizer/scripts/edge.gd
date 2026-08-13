extends Node2D

var start_neuron
var end_neuron

@export var degree = 3
@export var control_points = [
	Vector2(0, 0),
	Vector2(0.5, 1),
	Vector2(1, 0)
]


func _ready():
	z_index = -1


func _process(_delta):
	if start_neuron == null or end_neuron == null:
		return

	queue_redraw()


func _draw():
	draw_line(
		start_neuron.position,
		end_neuron.position,
		Color(0.4, 0.4, 0.4),
		3.0
	)
