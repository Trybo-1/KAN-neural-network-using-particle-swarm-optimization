extends PanelContainer

signal car_selected(car_data: Dictionary)
signal cancelled

const SAVE_DIRECTORY := "user://saved_cars"

@onready var car_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/car_list
@onready var status_label: Label = $MarginContainer/VBoxContainer/status_label
@onready var load_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/load_button
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/cancel_button


var saved_cars: Array[Dictionary] = []
var selected_car: Dictionary = {}


func _ready() -> void:

	hide()

	load_button.disabled = true

	load_button.pressed.connect(_on_load_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	scan_saved_cars()


func scan_saved_cars() -> void:
	saved_cars.clear()
	selected_car.clear()

	for child in car_list.get_children():
		child.queue_free()

	var root_dir := DirAccess.open(SAVE_DIRECTORY)

	if root_dir == null:
		status_label.text = "No saved cars found."
		return

	root_dir.list_dir_begin()

	var edge_type := root_dir.get_next()

	while edge_type != "":
		if root_dir.current_is_dir() and not edge_type.begins_with("."):
			scan_edge_type(edge_type)

		edge_type = root_dir.get_next()

	root_dir.list_dir_end()

	if saved_cars.is_empty():
		status_label.text = "No saved cars found."
	else:
		status_label.text = "%d saved car(s) found." % saved_cars.size()


func scan_edge_type(edge_type: String) -> void:
	var edge_path := SAVE_DIRECTORY.path_join(edge_type)
	var edge_dir := DirAccess.open(edge_path)

	if edge_dir == null:
		return

	edge_dir.list_dir_begin()

	var configuration_key := edge_dir.get_next()

	while configuration_key != "":
		if edge_dir.current_is_dir() and not configuration_key.begins_with("."):
			var car_path := edge_path.path_join(configuration_key)
			var metadata_path := car_path.path_join("metadata.json")

			if FileAccess.file_exists(metadata_path):
				read_car_metadata(
					metadata_path,
					car_path,
					edge_type,
					configuration_key
				)

		configuration_key = edge_dir.get_next()

	edge_dir.list_dir_end()


func read_car_metadata(
	metadata_path: String,
	car_path: String,
	edge_type: String,
	configuration_key: String
) -> void:
	var file := FileAccess.open(metadata_path, FileAccess.READ)

	if file == null:
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK or not json.data is Dictionary:
		push_warning("Invalid car metadata: " + metadata_path)
		return

	var metadata: Dictionary = json.data

	var car_data := {
		"metadata": metadata,
		"car_path": car_path,
		"metadata_path": metadata_path,
		"edge_type": edge_type,
		"configuration_key": configuration_key
	}

	saved_cars.append(car_data)
	create_car_entry(car_data)



func create_car_entry(car_data: Dictionary) -> void:
	var metadata: Dictionary = car_data["metadata"]

	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	

	button.text = "%s\nArchitecture: %s | Degree: %d | Control points: %d\nFitness: %.2f" % [
		str(metadata.get("edge_function_type", "unknown")).capitalize(),
		str(metadata.get("architecture", [])),
		int(metadata.get("degree", 0)),
		int(metadata.get("number_of_control_points", 0)),
		float(metadata.get("fitness", 0.0))
	]

	button.pressed.connect(
		_on_car_entry_pressed.bind(car_data, button)
	)

	car_list.add_child(button)




func _on_car_entry_pressed(
	car_data: Dictionary,
	button: Button
) -> void:
	selected_car = car_data

	for child in car_list.get_children():
		if child is Button:
			child.button_pressed = (child == button)

	load_button.disabled = false

	status_label.text = "Selected: " + str(
		car_data["configuration_key"]
	)



func _on_load_pressed() -> void:
	if selected_car.is_empty():
		return

	car_selected.emit({
		"car_data": selected_car
	})


func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()
