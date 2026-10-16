
extends Control
class_name KANConnectionMatrix

signal edge_selected(from_layer: int, from_neuron: int, to_layer: int, to_neuron: int)

@export var min_cell_width: float = 54.0
@export var min_cell_height: float = 42.0
@export var label_width: float = 28.0
@export var label_height: float = 22.0
@export var layer_column_width: float = 76.0
@export var layer_option_height: float = 34.0
@export var curve_color:Color = Color(0.35, 0.75, 1.0, 1.0)
var original_color = curve_color

var function_count: int = 0

var layers: Array[int] = []
var selected_layer: int = 0
var selected_edge_id: String = ""

# Key: "from_layer:from_neuron:to_layer:to_neuron"
var functions: Dictionary = {}


func set_kan_architecture(layer_sizes: Array) -> void:
	layers.clear()

	for layer_size in layer_sizes:
		layers.append(int(layer_size))

	selected_layer = clampi(selected_layer, 0, max(0, layers.size() - 2))
	_update_minimum_size()
	queue_redraw()


func set_layer_transition(layer_index: int) -> void:
	if layer_index < 0 or layer_index >= layers.size() - 1:
		return

	selected_layer = layer_index
	_update_minimum_size()
	queue_redraw()




func update_functions(function_data: Array) -> void:
	for function in function_data:
		if not function is Dictionary:
			continue

		if not function.has_all([
			"from_layer", "from_neuron",
			"to_layer", "to_neuron", "points"
		]):
			continue

		var from_layer := int(function["from_layer"])
		var from_neuron := int(function["from_neuron"])
		var to_layer := int(function["to_layer"])
		var to_neuron := int(function["to_neuron"])

		if from_layer < 0 or from_layer >= layers.size() - 1:
			continue
		if to_layer != from_layer + 1:
			continue
		if from_neuron < 0 or from_neuron >= layers[from_layer]:
			continue
		if to_neuron < 0 or to_neuron >= layers[to_layer]:
			continue

		var sampled_points := PackedVector2Array()

		for point in function["points"]:
			if point is Vector2:
				sampled_points.append(point)
			elif point is Array and point.size() >= 2:
				sampled_points.append(Vector2(
					float(point[0]), float(point[1])
				))
			elif point is Dictionary and point.has("x") and point.has("y"):
				sampled_points.append(Vector2(
					float(point["x"]), float(point["y"])
				))

		if sampled_points.size() < 2:
			continue


		var edge_id := _make_edge_id(
			from_layer, from_neuron, to_layer, to_neuron
		)

		functions[edge_id] = sampled_points


	_update_minimum_size()
	queue_redraw()



func _make_edge_id(
	from_layer: int,
	from_neuron: int,
	to_layer: int,
	to_neuron: int
) -> String:
	return "%d:%d:%d:%d" % [
		from_layer, from_neuron, to_layer, to_neuron
	]



func _update_minimum_size() -> void:
	if layers.size() < 2:
		custom_minimum_size = Vector2.ZERO
		return

	var rows: int = layers[selected_layer]
	var columns: int = layers[selected_layer + 1]

	var selector_height := (layers.size() - 1) * layer_option_height

	custom_minimum_size = Vector2(
		layer_column_width + label_width + columns * min_cell_width,
		max(
			selector_height,
			label_height + rows * min_cell_height
		)
	)



func _draw() -> void:
	if layers.size() < 2:
		return

	var rows: int = layers[selected_layer]
	var columns: int = layers[selected_layer + 1]

	var selector_height := (layers.size() - 1) * layer_option_height
	var matrix_x := layer_column_width + label_width
	var matrix_width := float(max(
		size.x - matrix_x,
		columns * min_cell_width
	))
	var matrix_height := float(max(
		size.y,
		label_height + rows * min_cell_height
	))

	var cell_width := matrix_width / columns
	var cell_height := (matrix_height - label_height) / rows
	var font := ThemeDB.fallback_font
	var font_size := 12

	# Layer-transition selector column.
	draw_string(
		font, Vector2(4, 15), "LAYERS",
		HORIZONTAL_ALIGNMENT_LEFT, layer_column_width - 8, font_size
	)

	for layer_index in range(layers.size() - 1):
		var option_rect := Rect2(
			2,
			label_height + layer_index * layer_option_height,
			layer_column_width - 4,
			layer_option_height - 2
		)

		var selected := layer_index == selected_layer

		draw_rect(
			option_rect,
			Color(0.32, 0.25, 0.14, 1.0) if selected
			else Color(0.15, 0.17, 0.21, 1.0),
			true
		)
		draw_rect(
			option_rect,
			Color(1.0, 0.65, 0.2, 1.0) if selected
			else Color(0.35, 0.38, 0.43, 1.0),
			false
		)

		draw_string(
			font,
			Vector2(option_rect.position.x + 4,
				option_rect.position.y + 20),
			"%d → %d" % [layer_index, layer_index + 1],
			HORIZONTAL_ALIGNMENT_LEFT,
			option_rect.size.x - 8,
			font_size
		)

	# Matrix title and destination neuron labels.
	draw_string(
		font,
		Vector2(matrix_x, 15),
		"Connection functions: %d" % function_count,
		HORIZONTAL_ALIGNMENT_LEFT,
		matrix_width,
		font_size
	)

	for column in range(columns):
		var x := matrix_x + column * cell_width

		draw_string(
			font,
			Vector2(x, label_height - 5),
			str(column),
			HORIZONTAL_ALIGNMENT_CENTER,
			cell_width,
			font_size
		)

	# Matrix cells.
	for row in range(rows):
		var y := label_height + row * cell_height

		draw_string(
			font,
			Vector2(layer_column_width, y + cell_height * 0.65),
			str(row),
			HORIZONTAL_ALIGNMENT_LEFT,
			label_width - 4,
			font_size
		)

		for column in range(columns):
			var x := matrix_x + column * cell_width
			var cell_rect := Rect2(
				x, y, cell_width, cell_height
			).grow(-1.0)

			var edge_id := _make_edge_id(
				selected_layer, row,
				selected_layer + 1, column
			)

			var is_selected := edge_id == selected_edge_id

			draw_rect(
				cell_rect,
				Color(0.28, 0.22, 0.12, 1.0) if is_selected
				else Color(0.12, 0.14, 0.17, 1.0),
				true
			)
			draw_rect(
				cell_rect,
				Color(1.0, 0.65, 0.2, 1.0) if is_selected
				else Color(0.35, 0.38, 0.43, 1.0),
				false
			)

			if functions.has(edge_id):
				_draw_function(
					functions[edge_id], cell_rect, is_selected
				)
			else:
				# Makes missing connections visibly different from curves.
				draw_line(
					cell_rect.position + Vector2(4, cell_rect.size.y / 2),
					cell_rect.position + Vector2(
						cell_rect.size.x - 4, cell_rect.size.y / 2
					),
					Color(0.3, 0.32, 0.36, 0.8),
					1.0
				)


func _draw_function(
	points: PackedVector2Array,
	rect: Rect2,
	is_selected: bool
) -> void:
	if points.size() < 2:
		return

	var min_x: float = points[0].x
	var max_x: float = points[0].x
	var min_y: float = points[0].y
	var max_y: float = points[0].y

	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)

	var x_range: float = maxf(max_x - min_x, 0.0001)
	var y_range: float = maxf(max_y - min_y, 0.0001)

	var padding := 4.0
	var plot_rect := rect.grow(-padding)

	var curve := PackedVector2Array()

	for point in points:
		var normalized_x := (point.x - min_x) / x_range
		var normalized_y := (point.y - min_y) / y_range

		curve.append(Vector2(
			plot_rect.position.x + normalized_x * plot_rect.size.x,
			plot_rect.position.y + (1.0 - normalized_y) * plot_rect.size.y
		))


	draw_polyline(curve, curve_color, 1.5, true)



func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	if layers.size() < 2:
		return

	var selector_y := float(event.position.y - label_height)

	# Click in the layer-selector column.
	if event.position.x < layer_column_width:
		if selector_y >= 0:
			var layer_index := int(selector_y / layer_option_height)

			if layer_index >= 0 and layer_index < layers.size() - 1:
				selected_layer = layer_index
				selected_edge_id = ""
				_update_minimum_size()
				queue_redraw()
				accept_event()
		return

	var rows: int = layers[selected_layer]
	var columns: int = layers[selected_layer + 1]

	var matrix_x := layer_column_width + label_width
	var matrix_width := float(max(
		size.x - matrix_x,
		columns * min_cell_width
	))
	var matrix_height := float(max(
		size.y,
		label_height + rows * min_cell_height
	))

	var cell_width := matrix_width / columns
	var cell_height := (matrix_height - label_height) / rows

	var local_x := float(event.position.x - matrix_x)
	var local_y := float(event.position.y - label_height)

	if local_x < 0 or local_y < 0:
		return

	var column := int(local_x / cell_width)
	var row := int(local_y / cell_height)

	if row >= rows or column >= columns:
		return

	selected_edge_id = _make_edge_id(
		selected_layer, row,
		selected_layer + 1, column
	)

	edge_selected.emit(
		selected_layer, row, selected_layer + 1, column
	)

	queue_redraw()
	accept_event()
