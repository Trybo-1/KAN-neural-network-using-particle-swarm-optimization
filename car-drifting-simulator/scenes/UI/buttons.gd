extends ColorRect

@onready var options: MenuButton = $HBoxContainer/options
@onready var track: Track = $"../../../content/visuals/track/Panel/SubViewportContainer/SubViewport/Track"
@onready var socket: Node = $"../../../content/visuals/track/Panel/SubViewportContainer/SubViewport/socket"
@onready var load_car_container: PanelContainer = $"../../../../../LoadCarContainer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	options.get_popup().id_pressed.connect(_on_menu_option_selected)
	
func _on_menu_option_selected(id: int) -> void:
	match id:
		0:
			save_car()
		1:
			open_load_car_dialog()
		2:
			reset_cars()
		3:
			#WebSocketPeer.new().close(0)
			socket.connect_to_python()
			socket._process(0)


func save_car():
	if socket.python_ready:
		socket.request_best_car_info()
	else: print("python not ready")
	
	

func open_load_car_dialog():
	load_car_container.show()

func reset_cars():
	track.restart_race()

func refresh_track_references() -> void:
	var sub_viewport: SubViewport = $"../../../content/visuals/track/Panel/SubViewportContainer/SubViewport"
	var track_node := sub_viewport.get_node_or_null("Track")
	
	if track_node == null:
		push_error("Socket could not find the Track node.")
		return

	track = track_node as Track

func disconnect_old_track() -> void:
	track = null
