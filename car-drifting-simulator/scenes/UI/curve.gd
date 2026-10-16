
extends Control

const Dataset = TauPlot.Dataset
const AxisId = TauPlot.AxisId
const PaneOverlayType = TauPlot.PaneOverlayType

const SAVE_PATH: String = "user://training_loss.csv"

@onready var plot: TauPlot = $plot

var iterations := PackedFloat64Array()
var bspline_fitness := PackedFloat64Array()
var polynomial_fitness := PackedFloat64Array()


func _ready() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file != null:
		file.store_line(
            "iteration,bspline_fitness,polynomial_fitness"
		)
		file.close()

	plot.title = "KAN Training Loss"
	plot.legend_enabled = true
	plot.hover_enabled = true


func add_training_point(
	iteration: int,
	global_loss: float,
	generation_loss: float = NAN
) -> void:
	iterations.append(float(iteration))
	bspline_fitness.append(global_loss)
	polynomial_fitness.append(generation_loss)

	save_point(iteration, global_loss, generation_loss)
	update_plot()


func save_point(
	iteration: int,
	global_loss: float,
	generation_loss: float
) -> void:
	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ_WRITE
	)

	if file == null:
		push_error("Could not open training loss CSV.")
		return

	file.seek_end()

	var generation_text: String = ""

	if is_finite(generation_loss):
		generation_text = "%.9f" % generation_loss

	file.store_line(
        "%d,%.9f,%s"
		% [iteration, global_loss, generation_text]
	)

	file.close()


func update_plot() -> void:
	if iterations.is_empty():
		return

	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray([
			"bspline_fitness",
            "polynomial_fitness"
		]),
		iterations,
		[bspline_fitness, polynomial_fitness]
			as Array[PackedFloat64Array]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "Iteration"
	x_axis.include_zero_in_domain = true
	x_axis.tick_count_preferred = 6

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "Loss"
	y_axis.include_zero_in_domain = true
	y_axis.tick_count_preferred = 5

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.SKIP

	var grid := TauGridLineConfig.new()
	grid.x_major_enabled = true
	grid.y_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []

	for i in range(2):
		var binding := TauXYSeriesBinding.new()
		binding.series_id = dataset.get_series_id_by_index(i)
		binding.pane_index = 0
		binding.overlay_type = PaneOverlayType.LINE
		binding.y_axis_id = AxisId.LEFT
		bindings.append(binding)

	plot.plot_xy(dataset, xy, bindings)
