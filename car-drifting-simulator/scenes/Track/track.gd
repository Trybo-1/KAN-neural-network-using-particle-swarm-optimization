extends Node

class_name Track

@onready var curve_path: Path2D = $centre_Line
@onready var checkpoint_holder: Node = $"checkpoint holder"
@onready var car_holder: Node = $"car holder"
@onready var race_controller: RaceController = $RaceController

var curve : Curve2D

func _ready() -> void:
	curve = curve_path.curve
	var cars: Array[Car] = []
	
	for car in car_holder.get_children():
		if car is Car:
			car.setup(checkpoint_holder.get_children().size())
			cars.append(car)
	race_controller.setup(cars)
	pass

func _on_track_collision_area_entered(area: Area2D) -> void:
	if area is Car:area.hit_boundary(get_direction_to_path(area.position))


func get_direction_to_path(from_position: Vector2) -> Vector2:
	return curve.get_closest_point(from_position)


func _on_startline_area_entered(area: Area2D) -> void:
	if area is Car:
		area.lap_completed()

func restart_race() -> void:
	for car in car_holder.get_children():
		if car is Car:
			car.reset()
			car.position = Vector2(481,91)
			car.rotation = 0
