extends Node

var socket := WebSocketPeer.new()

var connected := false
var hello_sent := false
var python_ready := false

var waiting_for_action := false
var current_step := 0
var current_action := { "throttle": [0.0], "steering": [0.0]}

@onready var cars: Array = get_parent().get_node("Track/car holder").get_children()
@onready var track: Track = $"../Track"
@onready var plot: Control = $"../../../../../Graph/Control"
#@onready var kan_visualizer: KANVisualizer = $"../../../../../../VBoxContainer/kan_bspline/Control"
@onready var kan_visualizer_bspline: KANConnectionMatrix = $"../../../../../../VBoxContainer/kan_bspline/ScrollContainer/Control"
@onready var kan_visualizer_polynomial: KANConnectionMatrix = $"../../../../../../VBoxContainer/kan_polynomial/ScrollContainer/Control"





var cars_done = 0
var number_of_cars_on_track

func _ready():
	print("SOCKET: _ready() called")

	EventHub.on_lap_completed.connect(on_lap_completed)

	refresh_track_references()

	print("SOCKET: Cars found: ", cars.size())
	print("SOCKET: Track found: ", track)
	print("SOCKET: Connecting to Python")
	
	number_of_cars_on_track = track.number_of_car_on_track

	python_ready = false
	connect_to_python()

func connect_to_python():
	var error := socket.connect_to_url("ws://127.0.0.1:5000")

	if error != OK:
		print("Connection failed: ", error)
		return

	print("Connecting to Python...")

func on_lap_completed(info: LapCompleteData) -> void:
	cars_done += 1
	if cars_done < number_of_cars_on_track or not track.training_track: return
	waiting_for_action = true
	cars_done = 0
	send_evaluation(info)


func _process(_delta):
	socket.poll()

	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:

		if not connected:
			connected = true
			print("Connected to Python!")

		if not hello_sent:
			send_hello()
			hello_sent = true

		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()

			if socket.was_string_packet():
				var message := packet.get_string_from_utf8()
				handle_message(message)


	elif state == WebSocketPeer.STATE_CLOSED:

		if connected:
			connected = false
			python_ready = false
			hello_sent = false
			waiting_for_action = false

			print("Disconnected from Python")


func _physics_process(_delta):
	# Do not advance the simulation while waiting for Python.
	if waiting_for_action:
		return

	# Python must complete the handshake first.
	if not python_ready:
		return

	# Apply the action received from Python.
	for action in len(current_action.get("throttle")):
		if action < number_of_cars_on_track:
			apply_action(cars[action],current_action.get("throttle")[action], current_action.get("steering")[action])

	# Advance the game by exactly one physics step.
	advance_simulation()


func send_hello():
	var message := {
		"type": "hello"
	}

	socket.send_text(JSON.stringify(message))


func send_state():
	var car_states := []
	for car in cars:
		car_states.append(car.get_car_info_for_kan())
	var message := {
		"type": "state",
		"training": track.training_track,
		"step": current_step,
		"states": car_states
	}

	socket.send_text(JSON.stringify(message))

	waiting_for_action = true

	#print("Sent state: ", current_step)
	#print("Car state: ", car_states)


func handle_message(message: String):
	var data = JSON.parse_string(message)

	if data == null:
		print("Invalid JSON received")
		return
	#if data != null:
		#print("data is ok")

	#print("Received: ", data["type"])

	var message_type = data.get("type")

	if message_type == "ready":
		python_ready = true
		print("Python is ready!")
		kan_visualizer_bspline.set_kan_architecture(data["layer_sizes_bspline"])
		kan_visualizer_polynomial.set_kan_architecture(data["layer_sizes_polynomial"])
		

	elif message_type == "action":
		handle_action(data)

	elif message_type == "curve_bspline":
		kan_visualizer_bspline.update_functions([data])
	
	elif message_type == "curve_polynomial":
		kan_visualizer_polynomial.update_functions([data])

	elif message_type == "restart epoch":
		plot.add_training_point("bspline",int(data["iteration"]),float(data["global_best_reward_bspline"]))
		plot.add_training_point("polynomial",int(data["iteration"]), float(data["global_best_reward_polynomial"]))

		start_race()

	elif message_type == "best_cars_response":
		save_car(data)
		


func handle_action(data):
	var received_step = data.get("step")

	# Ignore actions belonging to an old/different simulation step.
	if received_step != current_step:
		print(
			"Step error. Expected ",
			current_step,
			" but received ",
			received_step
		)
		return

	current_action = data.get("action")

	waiting_for_action = false

	#print("Action received for step ", current_step)
	#print("Action: ", current_action)


func apply_action(car:Car,throttle, steering):
	car.set_steering(steering)
	car.set_throttle(throttle)


func advance_simulation():
	for car in cars:
		car.training_paused = false


func _on_physics_step_completed():
	current_step += 1
	send_state()

func send_evaluation(info: LapCompleteData):
	var data = track.race_controller.get_car_data()

	var message := {
		"type": "evaluation",
		"car_data": data
	}
	print("sending info")
	
	socket.send_text(JSON.stringify(message))
	
	waiting_for_action = true
	
	print("evaluation sent")

func start_race():
	track.restart_race()
	current_step = 0
	send_state()

func cars_lap_completed():
	pass

func request_best_car_info():
	var message := {
		"type": "best_cars_request",
	}
	
	socket.send_text(JSON.stringify(message))

func save_car(data: Dictionary):
	var metadata = {
		"architecture": data["architecture"],
		"edge_function_type": data["edge_function_type"],
		"degree": data["degree"],
		"number_of_control_points": data["number_of_control_points"],
		"fitness": data["fitness"]
	}
	var curve = {
		"points": plot.get_curve(data["edge_function_type"])
	}
	var network = {
		"parameters": data["parameters"]
	}
	
	SavedCarStorage.save_best_car(metadata, network, curve)


func refresh_track_references() -> void:
	current_action = { "throttle": [0.0], "steering": [0.0]}
	var track_node := get_parent().get_node_or_null("Track")

	if track_node == null:
		push_error("Socket could not find the Track node.")
		return

	track = track_node as Track

	var car_holder := track.get_node_or_null("car holder")

	if car_holder == null:
		push_error("Track is missing its car holder.")
		return

	cars = car_holder.get_children()

	if cars.is_empty():
		push_error("No cars found on the selected track.")
		return

	var last_car = cars[-1]

	if not last_car.physics_step_completed.is_connected(
		_on_physics_step_completed
	):
		last_car.physics_step_completed.connect(
			_on_physics_step_completed
		)

	number_of_cars_on_track = cars.size()

	print("Socket references refreshed.")
	print("Cars found: ", cars.size())

func disconnect_old_track() -> void:
	for car in cars:
		if is_instance_valid(car):
			if car.physics_step_completed.is_connected(_on_physics_step_completed):
				car.physics_step_completed.disconnect(_on_physics_step_completed)

	cars.clear()
	track = null


func _on_load_car_container_car_selected(car_data: Dictionary) -> void:
	print(car_data)
	if track.training_track:
		return
	var all_data = car_data["car_data"]
	var metadata = car_data["car_data"]["metadata"]
	
	if metadata["edge_function_type"] == "bspline":
		kan_visualizer_bspline.set_kan_architecture(metadata["architecture"])
	else:
		kan_visualizer_polynomial.set_kan_architecture(metadata["architecture"])

	var network_path = all_data["car_path"].path_join("network.json")
	

	if not FileAccess.file_exists(network_path):
		push_error("Network file not found: " + network_path)
		return

	var file = FileAccess.open(network_path, FileAccess.READ)

	if file == null:
		push_error("Failed to open network.json")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("JSON parsing failed: " + json.get_error_message())
		return

	var parameters = json.data

	var message = {
		"type": "load_inference_network",
		"architecture": metadata["architecture"],
		"edge_function_type": metadata["edge_function_type"],
		"degree": metadata["degree"],
		"number_of_control_points": metadata["number_of_control_points"],
		"parameters": parameters["parameters"]
	}
	
	load_graph(all_data["car_path"].path_join("training_curve.json"), metadata["edge_function_type"])

	socket.send_text(JSON.stringify(message))

func load_graph(path: String, type: String):
	
	if not FileAccess.file_exists(path):
		push_error("Network file not found: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Failed to open network.json")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("JSON parsing failed: " + json.get_error_message())
		return

	var points = json.data["points"]

	var count = 0
	var mapped_points = []

	for point in points:
		mapped_points.append([count,point])
		count+=1

	plot.set_curve_points(type,mapped_points)

	plot.update_plot()
