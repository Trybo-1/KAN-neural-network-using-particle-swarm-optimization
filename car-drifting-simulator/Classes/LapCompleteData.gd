extends Object

class_name LapCompleteData

var lap_time: float
var car: Car
var reward: float

func _init(p_car: Car, lt: float, rwd:float) -> void:
	car = p_car
	lap_time = lt
	reward = rwd

func _to_string() -> String:
	return "LapCompleteData %s (%d) lap: %.2f reward: %.2f" % [
		car.car_name, car.car_number, lap_time, reward
	]
