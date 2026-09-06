extends Node

var socket = StreamPeerTCP.new()

const HOST = "127.0.0.1"
const PORT = 5000

var connected = false
var received_data = ""


func _ready():
	connect_to_python()


func connect_to_python():
	var error = socket.connect_to_host(HOST, PORT)

	if error == OK:
		print("Connecting to Python...")
	else:
		print("Failed to connect to Python: ", error)


func _process(_delta):
	socket.poll()

	var status = socket.get_status()

	if status == StreamPeerTCP.STATUS_CONNECTED:

		if not connected:
			connected = true
			print("Connected to Python!")

		receive_data()

	elif status == StreamPeerTCP.STATUS_ERROR:
		print("Connection error")

	elif status == StreamPeerTCP.STATUS_NONE and connected:
		print("Disconnected from Python")
		connected = false


func receive_data():
	var available_bytes = socket.get_available_bytes()

	if available_bytes <= 0:
		return

	var result = socket.get_data(available_bytes)

	if result[0] != OK:
		print("Failed to receive data")
		return

	var text = result[1].get_string_from_utf8()

	received_data += text

	process_messages()


func process_messages():

	while "\n" in received_data:

		var message_end = received_data.find("\n")

		var json_message = received_data.substr(
			0,
			message_end
		)

		received_data = received_data.substr(
			message_end + 1
		)

		parse_message(json_message)


func parse_message(message: String):

	var json = JSON.new()

	var error = json.parse(message)

	if error != OK:
		print("JSON parse error")
		return

	var data = json.data

	print("Received from Python:")
	print(data)

	print("Message: ", data.get("message", "No message"))

	print("Architecture: ", data.get("architecture", []))

	print("Layer values: ", data.get("layer_values", []))
