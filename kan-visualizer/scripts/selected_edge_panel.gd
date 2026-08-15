extends Panel

@onready var title_label = $MarginContainer/VBoxContainer/Title
@onready var from_label = $MarginContainer/VBoxContainer/FromLabel
@onready var to_label = $MarginContainer/VBoxContainer/ToLabel
@onready var layer_label = $MarginContainer/VBoxContainer/LayerLabel

@onready var bspline = $MarginContainer/VBoxContainer/BSpline
@onready var control_points_container = $MarginContainer/VBoxContainer/ControlPointsContainer

var selected_edge = null
var x_inputs = []
var y_inputs = []

func _ready():
	visible = false
	bspline.control_point_changed.connect(_on_control_point_changed)
	
func show_edge(edge):
	selected_edge = edge
	visible = true

	from_label.text = "From: Layer %d, Neuron %d" % [edge.from_layer, edge.from_neuron]
	to_label.text = "To: Layer %d, Neuron %d" % [edge.to_layer, edge.to_neuron]
	layer_label.text = "Layer: %d → %d" % [edge.from_layer, edge.to_layer]
	update_control_points(edge.control_points)
	bspline.set_control_points(edge.control_points)
	
func update_control_points(points):
	x_inputs.clear()
	y_inputs.clear()
	
	for child in control_points_container.get_children():
		child.queue_free()

	for i in range(points.size()):
		var row = HBoxContainer.new()

		var point_label = Label.new()
		point_label.text = "P%d" % i

		var x_input = LineEdit.new()
		x_input.text = "%.2f" % points[i].x
		x_input.custom_minimum_size.x = 70

		var y_input = LineEdit.new()
		y_input.text = "%.2f" % points[i].y
		y_input.custom_minimum_size.x = 70

		x_inputs.append(x_input)
		y_inputs.append(y_input)

		x_input.text_submitted.connect(_on_x_changed.bind(i))
		y_input.text_submitted.connect(_on_y_changed.bind(i))

		row.add_child(point_label)
		row.add_child(x_input)
		row.add_child(y_input)

		control_points_container.add_child(row)
		
func _on_x_changed(value: String, index: int):
	if selected_edge == null:
		return

	var point = selected_edge.control_points[index]
	point.x = value.to_float()
	selected_edge.control_points[index] = point

	bspline.set_control_points(selected_edge.control_points)
	
func _on_y_changed(value: String, index: int):
	if selected_edge == null:
		return

	var point = selected_edge.control_points[index]
	point.y = value.to_float()
	selected_edge.control_points[index] = point

	bspline.set_control_points(selected_edge.control_points)
	
func _on_control_point_changed(index, point):
	if selected_edge == null:
		return

	selected_edge.control_points[index] = point

	if index < x_inputs.size():
		x_inputs[index].text = "%.2f" % point.x
		y_inputs[index].text = "%.2f" % point.y
