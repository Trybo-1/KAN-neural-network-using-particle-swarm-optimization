extends OptionButton

@export var track_scenes: Array[PackedScene] = []

@onready var track_select: OptionButton = $"."
@onready var track_viewport: SubViewport = $"../../../../../content/visuals/track/Panel/SubViewportContainer/SubViewport"
#@onready var socket: Node = $"../../../../../content/visuals/track/Panel/SubViewportContainer/SubViewport/socket"

var current_track: Node2D


func _ready() -> void:
	track_select.clear()

	for i in range(track_scenes.size()):
		var scene := track_scenes[i]
		if scene == null:
			continue

		var track_name := scene.resource_path.get_file().get_basename()
		track_select.add_item(track_name.replace("_", " ").capitalize(), i)

	track_select.item_selected.connect(_on_track_selected)

	if track_select.item_count > 0:
		track_select.select(0)
		_on_track_selected(0)
		


func _on_track_selected(option_index: int) -> void:
	var scene_index := track_select.get_item_id(option_index)

	if scene_index < 0 or scene_index >= track_scenes.size():
		return

	var scene := track_scenes[scene_index]
	if scene == null:
		return

	# Remove the old track.
	if is_instance_valid(current_track):
		track_viewport.remove_child(current_track)
		current_track.queue_free()

	# Instance the replacement.
	current_track = scene.instantiate() as Node2D

	if current_track == null:
		push_error("Track root must inherit from Node2D.")
		return

	var socket_node = track_viewport.get_node_or_null("socket")

	if socket_node:
		socket_node.disconnect_old_track()

	var buttons: ColorRect = $"../.."

	buttons.disconnect_old_track()

	if is_instance_valid(current_track):
		track_viewport.remove_child(current_track)
		current_track.queue_free()
		current_track = null

	current_track = scene.instantiate() as Node2D
	if current_track == null:
		return

	current_track.name = "Track"
	track_viewport.add_child(current_track)

	if socket_node:
		socket_node.refresh_track_references()

	buttons.refresh_track_references()
