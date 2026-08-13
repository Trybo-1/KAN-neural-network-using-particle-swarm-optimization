extends Node2D

var control_points
var degree = 3
var knots

var selected_point = -1
var dragging = false
var offset = Vector2.ZERO

var origin = Vector2(575, 350)
var scaler = 50.0
var axis_length = 400

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	control_points = [
	Vector2(-4, 2),
	Vector2(-2, 4),
	Vector2(0, 1),
	Vector2(2, 4),
	Vector2(4, 2)
]
	self.degree = 2
	self.knots = create_knot_vector(control_points.size(), degree)
	
	print("Degree: ", degree)
	print("Knots: ", knots)
	
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
	draw_line(
		origin - Vector2(500,0),
		origin + Vector2(500, 0),
		Color.WHITE,
		2.0
	)

	draw_line(
		origin - Vector2(0,-500),
		origin + Vector2(0, -500),
		Color.WHITE,
		2.0
	)

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
		
	var tick_range = 10

	# X-axis ticks
	for x in range(-tick_range, tick_range + 1):
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

	# Y-axis ticks
	for y in range(-tick_range, tick_range + 1):
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
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				for i in range(control_points.size()):
					if math_to_screen(control_points[i]).distance_to(event.position) < 15:
						selected_point = i
						offset = get_global_mouse_position() - event.position
						dragging = true
						break
			else:
				dragging = false
				selected_point = -1
		
	if event is InputEventMouseMotion:
		if dragging and selected_point != -1:
			control_points[selected_point] = screen_to_math(event.position) + offset
			queue_redraw()
			
func math_to_screen(point: Vector2) -> Vector2:
	return Vector2(origin.x + point.x * scaler, origin.y - point.y * scaler)
	
func screen_to_math(point: Vector2) -> Vector2:
	return Vector2((point.x - origin.x) / scaler, (origin.y - point.y) / scaler)
