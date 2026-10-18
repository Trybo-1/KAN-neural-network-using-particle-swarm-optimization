
class_name SavedCarStorage
extends RefCounted

const SAVE_DIR := "user://saved_cars"



static func save_best_car(
	metadata: Dictionary,
	network: Dictionary,
	training_curve: Dictionary
) -> Dictionary:

	var root := DirAccess.open("user://")

	if root == null:
		return {
			"ok": false,
			"saved": false,
			"message": "Could not access the user data directory."
		}

	var error := root.make_dir_recursive("saved_cars")

	if error != OK and error != ERR_ALREADY_EXISTS:
		return {
			"ok": false,
			"saved": false,
			"message": "Could not create the saved cars directory."
		}

	# Read the configuration.

	var edge_function_type := str(
		metadata.get("edge_function_type")
	).to_lower()

	# Only allow explicitly supported edge-function types.
	if edge_function_type not in ["polynomial", "bspline"]:
		return {
			"ok": false,
			"saved": false,
			"message": "Invalid edge function type: " + edge_function_type
		}

	var architecture: Array = metadata.get("architecture", [])
	var degree := int(metadata.get("degree", 2))
	var control_points := int(metadata.get("number_of_control_points", 4))

	# Build the architecture key, e.g. 6-16-4-2.
	var architecture_key := ""

	for layer_size in architecture:
		if not architecture_key.is_empty():
			architecture_key += "-"
		architecture_key += str(layer_size)

	# Build the configuration key.
	var configuration_key := "%s_degree%d_cp%d" % [
		architecture_key,
		degree,
		control_points
	]

	configuration_key = configuration_key.validate_filename()

	# Separate parent folder for each edge-function type.
	var type_directory := SAVE_DIR.path_join(edge_function_type)
	var folder_path := type_directory.path_join(configuration_key)
	var metadata_path := folder_path.path_join("metadata.json")

	# Create the edge-function-specific directory.
	var saved_cars_dir := DirAccess.open(SAVE_DIR)
	if saved_cars_dir == null:
		return {
			"ok": false,
			"saved": false,
			"message": "Could not open the saved cars directory."
		}

	error = saved_cars_dir.make_dir_recursive(edge_function_type)

	if error != OK and error != ERR_ALREADY_EXISTS:
		return {
			"ok": false,
			"saved": false,
			"message": "Could not create the edge-function directory."
		}

	# Compare fitness only against the same edge-function type
	# and the same model configuration.
	if FileAccess.file_exists(metadata_path):
		var existing_text := FileAccess.get_file_as_string(
			metadata_path
		)
		var existing_data = JSON.parse_string(existing_text)

		if existing_data is Dictionary:
			var old_fitness := float(
				existing_data.get("fitness", -INF)
			)
			var new_fitness := float(
				metadata.get("fitness", -INF)
			)

			# Assumes higher fitness is better.
			if new_fitness <= old_fitness:
				return {
					"ok": true,
					"saved": false,
					"message": "An equal or better car is already saved.",
					"configuration_key": configuration_key
				}

	# Create the configuration directory.
	var type_dir := DirAccess.open(type_directory)

	if type_dir == null:
		return {
			"ok": false,
			"saved": false,
			"message": "Could not open the edge-function directory."
		}

	error = type_dir.make_dir_recursive(configuration_key)

	if error != OK and error != ERR_ALREADY_EXISTS:
		return {
			"ok": false,
			"saved": false,
			"message": "Could not create the configuration directory."
		}

	# Store metadata, including the type and complete configuration.
	metadata["configuration_key"] = configuration_key
	metadata["edge_function_type"] = edge_function_type
	metadata["architecture"] = architecture
	metadata["degree"] = degree
	metadata["number_of_control_points"] = control_points

	# Save metadata, network parameters, and training curve.
	if not _write_json(metadata_path, metadata):
		return {
			"ok": false,
			"saved": false,
			"message": "Failed to save metadata."
		}

	if not _write_json(
		folder_path.path_join("network.json"),
		network
	):
		return {
			"ok": false,
			"saved": false,
			"message": "Failed to save network parameters."
		}

	if not _write_json(
		folder_path.path_join("training_curve.json"),
		training_curve
	):
		return {
			"ok": false,
			"saved": false,
			"message": "Failed to save training curve."
		}

	return {
		"ok": true,
		"saved": true,
		"message": "The best car for this configuration was saved.",
		"configuration_key": configuration_key
	}

static func _write_json(path: String, data: Variant) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		push_error("Could not open file for writing: " + path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true
