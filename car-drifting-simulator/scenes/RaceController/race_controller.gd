extends Node


class_name RaceController

var cars: Array[Car] = []
var car_data : Dictionary[Car, CarData] = {}

func setup(carss: Array[Car]) -> void:
	cars = carss
	for car in carss:
		car_data[car] = CarData.new(car.car_name,car.car_number,car.reward, car.lap_time)

func _enter_tree() -> void:
	EventHub.on_lap_completed.connect(on_lap_completed)
	EventHub.cars_lap_completed.connect(cars_lap_completed)

func on_lap_completed(info: LapCompleteData) -> void:
	print("racecontroller:",info)
	
	var car: Car = info.car
	var cd: CarData = car_data[car]
	
	cd.update(car.reward,car.lap_time)

func get_car_data():
	var output = []

	for entry in car_data:
		var data = car_data[entry].get_car_info()
		var message := {
			"car": data[0],
			"reward": data[1],
			"lap time": data[2]
		}
		output.append(message)
	return output


func cars_lap_completed():
	
	pass
