extends Node

class_name Track

@onready var curve_path: Path2D = $centre_Line
@onready var checkpoint_holder: Node = $"checkpoint holder"
@onready var car_holder: Node = $"car holder"

var curve : Curve2D

func _ready() -> void:
	curve = curve_path.curve
	
	for car in car_holder.get_children():
		if car is Car:
			car.setup(checkpoint_holder.get_children().size())

func _on_track_collision_area_entered(area: Area2D) -> void:
	if area is Car:area.hit_boundary(get_direction_to_path(area.position))


func get_direction_to_path(from_position: Vector2) -> Vector2:
	return curve.get_closest_point(from_position)


func _on_startline_area_entered(area: Area2D) -> void:
	if area is Car:
		area.lap_completed()
