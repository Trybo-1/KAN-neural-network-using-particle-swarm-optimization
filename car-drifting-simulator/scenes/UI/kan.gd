extends Control
class_name KANVisualizer

## Configure the architecture once:
## set_kan_architecture([6, 16, 4, 2], "bspline")
##
## Then update the sampled function curves whenever needed:
## update_functions([
##   {
##     "from_layer": 0,
##     "from_neuron": 0,
##     "to_layer": 1,
##     "to_neuron": 0,
##     "points": [[-2.0, 0.1], [-1.0, 0.5], [0.0, 0.8], [1.0, 0.4], [2.0, 0.2]]
##   }
## ])
##
## Each points list contains sampled [x, y] coordinates for that edge.
## Send one entry per edge to update the entire network.

@export var neuron_radius: float = 5.0
@export_range(0.0, 1.0, 0.01) var edge_opacity: float = 0.34
@export var min_function_width: float = 24.0
@export var max_function_width: float = 62.0
@export var function_height: float = 18.0
@export var outer_margin: float = 12.0
@export var layer_label_height: float = 20.0

var layers: Array[int] = []
var function_type := "bspline"
var selected_edge_id := ""

# Keyed by "from_layer:from_neuron:to_layer:to_neuron".
var _functions: Dictionary = {}
var _layer_positions: Array[PackedVector2Array] = []
var _edge_layouts: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	resized.connect(_on_resized)


## Function 1: set architecture and calculate neuron/layout positions.
## Call once per visualizer, or again if the architecture changes.
func set_kan_architecture(
	layer_sizes: Array,
	edge_function_type: String = "bspline"
) -> void:
	var parsed_layers: Array[int] = []

	for value in layer_sizes:
		var count := int(value)
		if count < 1:
			push_warning("KANVisualizer: layer sizes must be positive.")
			return
		parsed_layers.append(count)

	if parsed_layers.size() < 2:
		push_warning("KANVisualizer: architecture needs at least two layers.")
		return

	layers = parsed_layers
	function_type = edge_function_type.to_lower()
	_functions.clear()
	selected_edge_id = ""

	_rebuild_layout()
	queue_redraw()


## Function 2: update sampled curves for edges.
## Each dictionary must contain from_layer, from_neuron, to_layer,
## to_neuron and points (an Array of [x, y] pairs).
## Existing edges not included in this update remain unchanged.
func update_functions(function_data: Array) -> void:
	for raw_edge in function_data:
		if not raw_edge is Dictionary:
			continue

		var from_layer := int(raw_edge.get("from_layer", -1))
		var to_layer := int(raw_edge.get("to_layer", -1))
		var from_neuron := int(raw_edge.get("from_neuron", -1))
		var to_neuron := int(raw_edge.get("to_neuron", -1))

		if not _valid_edge_indices(
			from_layer, from_neuron, to_layer, to_neuron
		):
			continue

		var raw_points: Variant = raw_edge.get("points", [])
		if not raw_points is Array:
			continue

		var points: Array[Vector2] = []
		for raw_point in raw_points:
			if raw_point is Array and raw_point.size() >= 2:
				points.append(Vector2(
					float(raw_point[0]),
					float(raw_point[1])
				))
			elif raw_point is Vector2:
				points.append(raw_point)

		if points.size() < 2:
			continue

		var id := _make_edge_id(
			from_layer, from_neuron, to_layer, to_neuron
		)
		_functions[id] = {
			"id": id,
			"from_layer": from_layer,
			"from_neuron": from_neuron,
			"to_layer": to_layer,
			"to_neuron": to_neuron,
			"points": points
		}

	_rebuild_edge_layouts()
	queue_redraw()


func _valid_edge_indices(
	from_layer: int,
	from_neuron: int,
	to_layer: int,
	to_neuron: int
) -> bool:
	if layers.size() < 2:
		return false
	if from_layer < 0 or from_layer >= layers.size():
		return false
	if to_layer != from_layer + 1 or to_layer >= layers.size():
		return false
	if from_neuron < 0 or from_neuron >= layers[from_layer]:
		return false
	if to_neuron < 0 or to_neuron >= layers[to_layer]:
		return false
	return true


func _make_edge_id(
	from_layer: int,
	from_neuron: int,
	to_layer: int,
	to_neuron: int
) -> String:
	return "%d:%d:%d:%d" % [
		from_layer, from_neuron, to_layer, to_neuron
	]


func _on_resized() -> void:
	_rebuild_layout()
	queue_redraw()


func _rebuild_layout() -> void:
	_layer_positions.clear()

	if layers.is_empty() or size.x <= 1.0 or size.y <= 1.0:
		_edge_layouts.clear()
		return

	var left := outer_margin
	var right := maxf(left + 1.0, size.x - outer_margin)
	var top := outer_margin 
	var bottom := maxf(top + 1.0, size.y - outer_margin)

	var x_step := 0.0
	if layers.size() > 1:
		x_step = (right - left) / float(layers.size() - 1)

	for layer_index in range(layers.size()):
		var positions := PackedVector2Array()
		var count: int = layers[layer_index]
		var y_step := (bottom - top) / float(count + 1)
		var x := left + x_step * layer_index

		for neuron_index in range(count):
			positions.append(Vector2(
				x, top + y_step * float(neuron_index + 1)
			))

		_layer_positions.append(positions)

	_rebuild_edge_layouts()


func _rebuild_edge_layouts() -> void:
	_edge_layouts.clear()

	if layers.is_empty() or _layer_positions.size() != layers.size():
		return

	for edge in _functions.values():
		var start: Vector2 = _layer_positions[
			edge["from_layer"]
		][edge["from_neuron"]]

		var finish: Vector2 = _layer_positions[
			edge["to_layer"]
		][edge["to_neuron"]]

		var distance := start.distance_to(finish)
		var graph_width := clampf(
			distance * 0.30,
			min_function_width,
			max_function_width
		)
		graph_width = minf(
			graph_width,
			maxf(12.0, absf(finish.x - start.x) * 0.72)
		)

		_edge_layouts.append({
			"edge": edge,
			"start": start,
			"finish": finish,
			"center": start.lerp(finish, 0.5),
			"graph_width": graph_width/2.5,
			"graph_height": minf(
				function_height, maxf(8.0, distance * 0.20)
			)/2.5
		})


func _draw() -> void:
	if layers.is_empty() or _layer_positions.size() != layers.size():
		return

	_draw_edges()
	#_draw_layer_labels()
	_draw_neurons()


func _draw_edges() -> void:
	for layout in _edge_layouts:
		var edge: Dictionary = layout["edge"]
		var start: Vector2 = layout["start"]
		var finish: Vector2 = layout["finish"]
		var center: Vector2 = layout["center"]
		var graph_width: float = layout["graph_width"]
		var graph_height: float = layout["graph_height"]

		var edge_id: String = edge["id"]
		var selected := edge_id == selected_edge_id
		var color := _edge_color(selected)
		var line_color := Color(
			color.r, color.g, color.b,
			1.0 if selected else edge_opacity
		)

		var direction := (finish - start).normalized()
		var half_width := graph_width * 0.5
		var graph_start := center - direction * half_width
		var graph_end := center + direction * half_width

		draw_line(
			start, graph_start, line_color,
			1.5 if selected else 1.0, true
		)
		draw_line(
			graph_end, finish, line_color,
			1.5 if selected else 1.0, true
		)

		_draw_function_graph(
			edge["points"], center, graph_width,
			graph_height, color, selected
		)


func _draw_function_graph(
	points: Array,
	center: Vector2,
	graph_width: float,
	graph_height: float,
	color: Color,
	selected: bool
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

	if is_equal_approx(min_x, max_x):
		max_x = min_x + 1.0
	if is_equal_approx(min_y, max_y):
		max_y = min_y + 1.0

	var rect := Rect2(
		center.x - graph_width * 0.5,
		center.y - graph_height * 0.5,
		graph_width,
		graph_height
	)

	draw_rect(rect, Color(0.015, 0.045, 0.08, 0.92), true)
	draw_rect(rect, color, false, 1.0)

	var curve := PackedVector2Array()
	for point in points:
		var px := remap(
			point.x, min_x, max_x,
			rect.position.x + 2.0, rect.end.x - 2.0
		)
		var py := remap(
			point.y, min_y, max_y,
			rect.end.y - 2.0, rect.position.y + 2.0
		)
		curve.append(Vector2(px, py))

	draw_polyline(curve, color, 1.7 if selected else 1.1, true)


func _draw_layer_labels() -> void:
	if _font == null:
		return

	for i in range(layers.size()):
		var label := "Layer %d\n(%d)" % [i, layers[i]]
		if i == 0:
			label = "Input\n(%d)" % layers[i]
		elif i == layers.size() - 1:
			label = "Output\n(%d)" % layers[i]

		var x: float = _layer_positions[i][0].x
		draw_multiline_string(
			_font,
			Vector2(x - 35.0, outer_margin + 10.0),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			70.0,
			12,
			-1,
			Color(0.76, 0.84, 0.94)
		)


func _draw_neurons() -> void:
	for layer_index in range(_layer_positions.size()):
		for position in _layer_positions[layer_index]:
			draw_circle(
				position, neuron_radius + 1.5,
				Color(0.02, 0.05, 0.09)
			)
			draw_circle(position, neuron_radius, _neuron_color(layer_index))


func _neuron_color(layer_index: int) -> Color:
	if layer_index == 0:
		return Color(0.15, 0.62, 1.0)
	if layer_index == layers.size() - 1:
		return Color(1.0, 0.76, 0.18)
	if layer_index % 2 == 1:
		return Color(0.67, 0.52, 1.0)
	return Color(0.12, 0.82, 0.68)


func _edge_color(selected: bool) -> Color:
	if selected:
		return Color(1.0, 0.86, 0.22)
	if function_type == "polynomial":
		return Color(0.72, 0.38, 1.0)
	return Color(0.12, 0.72, 1.0)


## Optional helper for highlighting an edge by its stable ID.
func select_edge(
	from_layer: int,
	from_neuron: int,
	to_layer: int,
	to_neuron: int
) -> void:
	selected_edge_id = _make_edge_id(
		from_layer, from_neuron, to_layer, to_neuron
	)
	queue_redraw()
