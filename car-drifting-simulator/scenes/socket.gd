extends Node

var socket := WebSocketPeer.new()

var connected := false
var hello_sent := false
var python_ready := false

var waiting_for_action := false
var current_step := 0
var current_action := { "throttle": 1.0, "steering": -0.57623024322664 }

@onready var car: Car = get_parent().get_node("Track/car holder/car")

func _ready():
	EventHub.on_lap_completed.connect(on_lap_completed)
	car.physics_step_completed.connect(_on_physics_step_completed)
	python_ready = false
	var error := socket.connect_to_url("ws://127.0.0.1:5000")

	if error != OK:
		print("Connection failed: ", error)
		return

	print("Connecting to Python...")


func on_lap_completed(info: LapCompleteData) -> void:
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
	apply_action(current_action.get("throttle"), current_action.get("steering"))

	# Advance the game by exactly one physics step.
	advance_simulation()



func send_hello():
	var message := {
		"type": "hello"
	}

	socket.send_text(JSON.stringify(message))


func send_state():
	var car_state := car.get_car_info_for_kan()
	var message := {
		"type": "state",
		"step": current_step,
		"state": car_state
	}
	socket.send_text(JSON.stringify(message))

	waiting_for_action = true

	print("Sent state: ", current_step)
	print("Car state: ", car_state)


func handle_message(message: String):
	var data = JSON.parse_string(message)

	if data == null:
		print("Invalid JSON received")
		return
	if data != null:
		print(data)

	print("Received: ", data)

	var message_type = data.get("type")

	if message_type == "ready":
		python_ready = true
		print("Python is ready!")

	elif message_type == "action":
		handle_action(data)


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

	current_action = data.get("action", {})

	waiting_for_action = false

	print("Action received for step ", current_step)
	print("Action: ", current_action)


func apply_action(throttle, steering):
	# This will eventually send the action to the Car node.
	car.set_steering(steering)
	car.set_throttle(throttle)



func advance_simulation():
	car.training_paused = false


func _on_physics_step_completed():
	current_step += 1
	send_state()

func send_evaluation(info: LapCompleteData):
	var time = info.lap_time
	var reward = info.reward
	var message := {
		"type": "evaluation",
		"time": time,
		"reward": reward
	}
	
	socket.send_text(JSON.stringify(message))
	
	waiting_for_action = true
	
	print("evaluation sent")
