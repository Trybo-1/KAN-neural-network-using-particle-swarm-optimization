extends Control

var control_points = [
		Vector2(-4, 2),
		Vector2(-2, 4),
		Vector2(0, 1),
		Vector2(2, 4),
		Vector2(4, 2)
	]
var degree = 3
var knots

var selected_point = -1
var dragging = false
var offset = Vector2.ZERO

var graph_margin = 35.0

var axis_padding = 2

var hover_t = 0.0
var hover_curve_point = Vector2.ZERO
var show_t_marker = false

signal control_point_changed(index, point)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	degree = 2
	knots = create_knot_vector(control_points.size(), degree)
	queue_redraw()

func set_control_points(points):
	control_points = points
	knots = create_knot_vector(control_points.size(), degree)
	queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_knot_vector(num_control_points, degree):
	var num_knots = num_control_points + degree + 1
	var knots = []
	var internal_knots = num_knots - 2 * (degree + 1)
	
	for i in range(degree + 1):
		knots.append(0.0)
		
	if internal_knots > 0:
		for i in range(internal_knots):
			knots.append(float(i + 1) / float(internal_knots + 1))
	
	for i in range(degree + 1):
		knots.append(1.0)
	
	return knots

func basis_function(i, degree, t, knots):
	# Base case
	if degree == 0:
		if knots[i] <= t and t < knots[i + 1]:
			return 1.0
		if t == 1.0 and knots[i + 1] == 1.0:
			return 1.0
		return 0.0
	
	var left = 0.0
	var right = 0.0
	
	var left_denom = knots[i + degree] - knots[i]
	var right_denom = knots[i + degree + 1] - knots[i + 1]
	
	if left_denom != 0:
		left = (t-knots[i]) / left_denom * basis_function(i, degree - 1, t, knots)#left influnce
	
	if right_denom != 0:
		right = (knots[i + degree + 1] - t) / right_denom * basis_function(i + 1, degree - 1, t, knots)#right influence
	
	return left + right
	
func linspace(start, end, number_of_points):
	var result = []
	var gap = end - start
	result.append(start)
	for i in range(number_of_points-2):
		result.append((float(gap*(i+1))/float(number_of_points-1))+start)
	result.append(end)
	return result
	
func create_curve(resolution=500):
	var curve_points = []

	var t_values = linspace(self.knots[self.degree], self.knots[-self.degree - 1], resolution)

	for t in t_values:
		var point = evaluate(t)
		curve_points.append(point)
	return curve_points
	
func evaluate(t: float) -> Vector2:
	var curve_point := Vector2.ZERO
	
	for i in range(control_points.size()):
		var influence = basis_function(i, degree, t, knots)
		curve_point += influence * control_points[i]
	
	return curve_point

func _draw():
	# Axes
	draw_axes()

	# Control polygon
	for i in range(control_points.size() - 1):
		draw_line(
			math_to_screen(control_points[i]),
			math_to_screen(control_points[i + 1]),
			Color.GRAY,
			1.0
		)

	# Control points
	for i in range(control_points.size()):
		var colour = Color.WHITE

		if i == selected_point:
			colour = Color.RED

		draw_circle(
			math_to_screen(control_points[i]),
			8.0,
			colour
		)

	# B-spline
	var curve_points = create_curve()

	for i in range(curve_points.size() - 1):
		draw_line(
			math_to_screen(curve_points[i]),
			math_to_screen(curve_points[i + 1]),
			Color.WHITE,
			3.0
		)
		
	if show_t_marker:
		var screen_point = math_to_screen(hover_curve_point)

		draw_circle(
			screen_point,
			7.0,
			Color.RED
		)

		draw_string(
			ThemeDB.fallback_font,
			screen_point + Vector2(10, -10),
			"t = %.2f" % hover_t,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16
		)


func math_to_screen(point: Vector2) -> Vector2:
	var bounds = get_axis_bounds()
	var scaler = get_scaler()

	var bounds_center = bounds.position + bounds.size / 2.0
	var screen_center = size / 2.0

	return Vector2(
		screen_center.x + (point.x - bounds_center.x) * scaler,
		screen_center.y - (point.y - bounds_center.y) * scaler
	)

func screen_to_math(point: Vector2) -> Vector2:
	var bounds = get_axis_bounds()
	var scaler = get_scaler()
	var bounds_center = bounds.position + bounds.size / 2.0
	var screen_center = size / 2.0

	return Vector2(
		bounds_center.x + (point.x - screen_center.x) / scaler,
		bounds_center.y - (point.y - screen_center.y) / scaler
	)
	
func get_axis_bounds():
	var min_x = control_points[0].x
	var max_x = control_points[0].x
	var min_y = control_points[0].y
	var max_y = control_points[0].y
	
	for point in control_points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	min_x = floor(min_x) - axis_padding
	max_x = ceil(max_x) + axis_padding
	min_y = floor(min_y) - axis_padding
	max_y = ceil(max_y) + axis_padding
	
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	
func draw_axes():
	var bounds = get_axis_bounds()
	var min_x = int(bounds.position.x)
	var max_x = int(bounds.end.x)
	var min_y = int(bounds.position.y)
	var max_y = int(bounds.end.y)
	
	# X axis
	if min_y <= 0 and max_y >= 0:
		var x_start = math_to_screen(Vector2(min_x, 0))
		var x_end = math_to_screen(Vector2(max_x, 0))
		
		draw_line(
			x_start,
			x_end,
			Color.WHITE,
			1.0
		)
		
	# Y axis
	if min_x <= 0 and max_x >= 0:
		var y_start = math_to_screen(Vector2(0, min_y))
		var y_end = math_to_screen(Vector2(0, max_y))
		
		draw_line(
			y_start,
			y_end,
			Color.WHITE,
			1.0
		)
	
	# X ticks
	for x in range(min_x, max_x + 1):
		var position = math_to_screen(Vector2(x, 0))
		
		draw_line(
			position + Vector2(0, -5),
			position + Vector2(0, 5),
			Color.WHITE,
			1.0
		)
		
		if x != 0:
			draw_string(
				ThemeDB.fallback_font,
				position + Vector2(-5, 20),
				str(x),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14
			)
	
	# Y ticks
	for y in range(min_y, max_y + 1):
		var position = math_to_screen(Vector2(0, y))
		
		draw_line(
			position + Vector2(-5, 0),
			position + Vector2(5, 0),
			Color.WHITE,
			1.0
		)
		
		if y != 0:
			draw_string(
				ThemeDB.fallback_font,
				position + Vector2(-25, 5),
				str(y),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14
			)
			
func find_nearest_curve_point(mouse_position: Vector2):
	var curve_points = create_curve()
	var closest_distance = INF
	var closest_index = -1

	for i in range(curve_points.size()):
		var screen_point = math_to_screen(curve_points[i])
		var distance = screen_point.distance_squared_to(mouse_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_index = i

	if closest_index != -1:
		var resolution = curve_points.size()
		hover_t = float(closest_index) / float(resolution - 1)
		hover_curve_point = curve_points[closest_index]
		show_t_marker = true

	queue_redraw()

func get_scaler() -> float:
	var bounds = get_axis_bounds()

	var available_width = size.x - graph_margin * 2.0
	var available_height = size.y - graph_margin * 2.0

	var scale_x = available_width / bounds.size.x
	var scale_y = available_height / bounds.size.y

	return min(scale_x, scale_y)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_position = event.position

				for i in range(control_points.size()):
					if math_to_screen(control_points[i]).distance_to(mouse_position) < 15:
						selected_point = i
						dragging = true
						break
			else:
				dragging = false
				selected_point = -1

	if event is InputEventMouseMotion:
		if dragging and selected_point != -1:
			control_points[selected_point] = screen_to_math(event.position)
			control_point_changed.emit(selected_point, control_points[selected_point])
			queue_redraw()

		find_nearest_curve_point(event.position)
