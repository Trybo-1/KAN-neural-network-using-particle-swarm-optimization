
extends Control

const Dataset = TauPlot.Dataset
const AxisId = TauPlot.AxisId
const PaneOverlayType = TauPlot.PaneOverlayType

const SAVE_PATH := "user://training_loss.csv"

@onready var plot: TauPlot = $plot

# B-spline data
var bspline_iterations := PackedFloat64Array()
var bspline_fitness := PackedFloat64Array()

# Polynomial data
var polynomial_iterations := PackedFloat64Array()
var polynomial_fitness := PackedFloat64Array()


func _ready() -> void:
	plot.title = "KAN Training Fitness"
	plot.legend_enabled = true
	plot.hover_enabled = true

func set_curve_points(type: String, points: Array) -> void:
	var x_values := PackedFloat64Array()
	var y_values := PackedFloat64Array()

	for point in points:
		if point.size() < 2:
			push_warning("Skipping invalid point in curve: " + type)
			continue

		x_values.append(float(point[0]))
		y_values.append(float(point[1]))

	match type.to_lower():
		"bspline":
			bspline_iterations = x_values
			bspline_fitness = y_values

		"polynomial":
			polynomial_iterations = x_values
			polynomial_fitness = y_values

		_:
			push_error("Unknown curve type: " + type)
			return

	update_plot()


# Add one point to a curve.
func add_training_point(
	type: String,
	iteration: float,
	loss: float
) -> void:
	match type.to_lower():
		"bspline":
			bspline_iterations.append(iteration)
			bspline_fitness.append(loss)

		"polynomial":
			polynomial_iterations.append(iteration)
			polynomial_fitness.append(loss)

		_:
			push_error("Unknown curve type: " + type)
			return

	update_plot()


# Return the stored X and Y arrays for a curve.
func get_curve(type: String) -> Dictionary:
	match type.to_lower():
		"bspline":
			return {
				"x": bspline_iterations,
				"y": bspline_fitness
			}

		"polynomial":
			return {
				"x": polynomial_iterations,
				"y": polynomial_fitness
			}

		_:
			push_error("Unknown curve type: " + type)
			return {}


# Clear one curve or both curves.
func clear_curve(type: String = "all") -> void:
	match type.to_lower():
		"bspline":
			bspline_iterations.clear()
			bspline_fitness.clear()

		"polynomial":
			polynomial_iterations.clear()
			polynomial_fitness.clear()

		"all":
			bspline_iterations.clear()
			bspline_fitness.clear()
			polynomial_iterations.clear()
			polynomial_fitness.clear()

		_:
			push_error("Unknown curve type: " + type)
			return

	update_plot()


func update_plot() -> void:
	var dataset := Dataset.make_per_series_x_continuous(
		PackedStringArray([
			"B-spline",
			"Polynomial"
		]),
		[
			bspline_iterations,
			polynomial_iterations
		],
		[
			bspline_fitness,
			polynomial_fitness
		]
	)

	# X-axis configuration.
	var x_axis := TauAxisConfig.new()
	x_axis.title = "Iteration"
	x_axis.include_zero_in_domain = true
	x_axis.tick_count_preferred = 6

	# Y-axis configuration.
	var y_axis := TauAxisConfig.new()
	y_axis.title = "Loss"
	y_axis.include_zero_in_domain = true
	y_axis.tick_count_preferred = 5

	# Grid configuration.
	var grid := TauGridLineConfig.new()
	grid.x_major_enabled = true
	grid.y_major_enabled = true

	# Pane configuration.
	var pane := TauPaneConfig.new()

	# Assign the Y-axis and grid to the pane.
	pane.y_left_axis = y_axis
	pane.grid_line = grid

	# Configure the XY plot.
	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	# Configure the line overlay on the pane.
	var line := TauLineConfig.new()
	line.gap_policy = TauLineConfig.GapPolicy.SKIP
	pane.overlays = [line]

	# Bind both series to the same pane.
	var bindings: Array[TauXYSeriesBinding] = []

	for i in range(2):
		var binding := TauXYSeriesBinding.new()
		binding.series_id = dataset.get_series_id_by_index(i)
		binding.pane_index = 0
		binding.overlay_type = PaneOverlayType.LINE
		binding.y_axis_id = AxisId.LEFT

		bindings.append(binding)

	plot.plot_xy(dataset, xy, bindings)


# Save all stored points to a CSV file.
# Each curve retains its own iteration values.
func save_point() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Could not open CSV file: " + SAVE_PATH)
		return

	file.store_line("type,iteration,loss")

	for i in range(bspline_iterations.size()):
		file.store_line(
			"bspline,%s,%s" % [
				bspline_iterations[i],
				bspline_fitness[i]
			]
		)

	for i in range(polynomial_iterations.size()):
		file.store_line(
			"polynomial,%s,%s" % [
				polynomial_iterations[i],
				polynomial_fitness[i]
			]
		)

	file.close()
