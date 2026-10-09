
extends Control

const MAX_POINTS: int = 300
const GRAPH_MARGIN_LEFT: float = 48.0
const GRAPH_MARGIN_RIGHT: float = 16.0
const GRAPH_MARGIN_TOP: float = 24.0
const GRAPH_MARGIN_BOTTOM: float = 36.0
const SAVE_PATH: String = "user://training_loss.csv"

var losses: Array[float] = []
var iterations: Array[int] = []

var grid_color := Color(0.35, 0.38, 0.43, 0.45)
var axis_color := Color(0.75, 0.78, 0.82)
var curve_color := Color(0.2, 0.85, 1.0)
var point_color := Color(1.0, 0.75, 0.25)


func _ready() -> void:
	# Start a fresh CSV for each application session.
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file != null:
		file.store_line("iteration,global_best_loss")
		file.close()

	queue_redraw()


func add_loss(value: float) -> void:
	var iteration: int = iterations.size()

	iterations.append(iteration)
	losses.append(value)

	if losses.size() > MAX_POINTS:
		losses.pop_front()
		iterations.pop_front()

	save_point(iteration, value)
	queue_redraw()


func save_point(iteration: int, value: float) -> void:
	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ_WRITE
	)

	if file == null:
		push_error("Could not open loss CSV: " + SAVE_PATH)
		return

	file.seek_end()
	file.store_line("%d,%.9f" % [iteration, value])
	file.close()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12

	var graph_rect := Rect2(
		GRAPH_MARGIN_LEFT,
		GRAPH_MARGIN_TOP,
		maxf(1.0, size.x - GRAPH_MARGIN_LEFT - GRAPH_MARGIN_RIGHT),
		maxf(1.0,size.y - GRAPH_MARGIN_TOP - GRAPH_MARGIN_BOTTOM)
	)

	# Graph title.
	draw_string(
		font,
		Vector2(GRAPH_MARGIN_LEFT, 16.0),
		"Global Best Loss",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size + 2,
		axis_color
	)

	# Draw the graph frame.
	draw_rect(graph_rect, axis_color, false, 1.0)

	if losses.is_empty():
		draw_string(
			font,
			graph_rect.get_center() + Vector2(-65.0, 4.0),
			"Waiting for data...",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			axis_color
		)
		return

	var min_loss: float = losses.min()
	var max_loss: float = losses.max()

	# Add vertical padding so constant or near-constant losses remain visible.
	var loss_range: float = max_loss - min_loss
	var padding: float = maxf(loss_range * 0.1, 0.001)

	min_loss -= padding
	max_loss += padding

	var first_iteration: float = float(iterations[0])
	var last_iteration: float = float(iterations[-1])
	var iteration_range: float = last_iteration - first_iteration

	if iteration_range <= 0.0:
		iteration_range = 1.0

	# Horizontal grid lines and Y-axis labels.
	for i in range(5):
		var fraction: float = float(i) / 4.0
		var y: float = graph_rect.position.y + graph_rect.size.y * fraction
		var label_value: float = max_loss - (
			fraction * (max_loss - min_loss)
		)

		draw_line(
			Vector2(graph_rect.position.x, y),
			Vector2(graph_rect.end.x, y),
			grid_color,
			1.0
		)

		draw_string(
			font,
			Vector2(0.0, y + 4.0),
			"%.3f" % label_value,
			HORIZONTAL_ALIGNMENT_LEFT,
			GRAPH_MARGIN_LEFT - 6.0,
			font_size,
			axis_color
		)

	# X-axis labels.

	# X-axis labels.
	var x_label_count: int = 5

	for i in range(x_label_count):
		var fraction: float = float(i) / float(x_label_count - 1)

		var iteration_value: int = roundi(first_iteration + fraction * iteration_range)

		var x: float = (graph_rect.position.x + fraction * graph_rect.size.x)

		draw_string(
			font,
			Vector2(x - 20.0, graph_rect.end.y + 20.0),
			str(iteration_value),
			HORIZONTAL_ALIGNMENT_CENTER,
			40.0,
			font_size,
			axis_color
		)


	# Axis title.
	draw_string(
		font,
		Vector2(graph_rect.get_center().x - 35.0, size.y - 3.0),
		"Iteration",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		axis_color
	)

	# Convert data values into graph coordinates.
	for i in range(losses.size()):
		var x_fraction: float = (float(iterations[i]) - first_iteration) / iteration_range

		var y_fraction: float = (losses[i] - min_loss) / (max_loss - min_loss)

		var point := Vector2(
			graph_rect.position.x + x_fraction * graph_rect.size.x,
			graph_rect.end.y - y_fraction * graph_rect.size.y
		)

		# Draw a line between consecutive points.
		if i > 0:
			var previous_x: float = (
				float(iterations[i - 1]) - first_iteration
			) / iteration_range

			var previous_y: float = (
				losses[i - 1] - min_loss
			) / (max_loss - min_loss)

			var previous_point := Vector2(
				graph_rect.position.x + previous_x * graph_rect.size.x,
				graph_rect.end.y - previous_y * graph_rect.size.y
			)

			draw_line(
				previous_point,
				point,
				curve_color,
				2.0,
				true
			)

		# Draw a marker even when there is only one point.
		draw_circle(point, 3.5, point_color)
