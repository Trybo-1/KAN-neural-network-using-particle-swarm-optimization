extends Node

var socket := WebSocketPeer.new()
var connected := false
var hello_sent := false


func _ready():
	var error := socket.connect_to_url("ws://127.0.0.1:5000")

	if error != OK:
		print("Connection failed: ", error)
		return

	print("Connecting to Python...")


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
			print("Disconnected from Python")


func send_hello():
	var message := {
		"type": "hello"
	}

	socket.send_text(JSON.stringify(message))


func handle_message(message: String):
	var data = JSON.parse_string(message)

	if data == null:
		print("Invalid JSON received")
		return

	print("Received:", data)

	if data.get("type") == "ready":
		print("Python is ready!")
