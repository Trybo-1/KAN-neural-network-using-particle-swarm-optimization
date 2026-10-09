extends Object

class_name CarData

var car_name: String
var car_number: int
var lap_time: float
var reward: float


func _init(_car_name: String,_car_number: int,_reward: float, _lap_time: float) -> void:
	car_name = _car_name
	car_number = _car_number
	reward = _reward
	lap_time = _lap_time


func update(rwd:float,lap:float):
	reward = rwd
	lap_time = lap

func get_car_info():
	return [car_number,reward,lap_time]
