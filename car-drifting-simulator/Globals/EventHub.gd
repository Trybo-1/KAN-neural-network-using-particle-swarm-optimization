extends Node

var lap_data = []
signal on_lap_completed(info: LapCompleteData)
signal cars_lap_completed()


func emit_on_lap_completed(info: LapCompleteData) -> void:
	on_lap_completed.emit(info)
	lap_data.append(info)
