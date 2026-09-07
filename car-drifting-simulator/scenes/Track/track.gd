extends Node

class_name Track

@onready var curve_path: Path2D = $centre_Line

var curve : Curve2D

func _ready() -> void:
	curve = curve_path.curve

func _on_track_collision_area_entered(area: Area2D) -> void:
	if area is Car:area.hit_boundary(get_direction_to_path(area.position))


func get_direction_to_path(from_position: Vector2) -> Vector2:
	return curve.get_closest_point(from_position)
