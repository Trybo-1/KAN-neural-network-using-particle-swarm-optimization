extends Area2D

class_name Car

var car_number: int = 0
var car_name: String = "car"

var throttle = 0.0
var velocity = 0.0
@export var max_speed = 380

var steer = 4
var steer_strength = 6
var min_steer_factor = 0.5

var bounce_force = 30.0
var bounce_time = 0.8
var bounce_tween : Tween
var bounce_target : Vector2 = Vector2.ZERO

var checkpoint_count: int = 3
var checkpoints_passed: Array[int] = []

var lap_time: float = 0.0

func _ready() -> void:
	pass

func setup(cc: int) -> void:
	checkpoint_count = cc

func _process(delta: float) -> void:
	lap_time += delta
	throttle = Input.get_action_strength("accelerate")
	steer = Input.get_axis("steer_left","steer_right")


func _physics_process(delta: float) -> void:
	apply_throttle(delta)
	apply_rotation(delta)
	position += transform.x * velocity * delta


func apply_throttle(delta: float) -> void:
	if throttle > 0.0:
		velocity += delta * 100.0
	else: 
		velocity -= delta * 150.0
	velocity = clampf(velocity,0.0,max_speed)

func get_steer_factor() -> float:
	return clampf(
		1.0 - pow(velocity/max_speed,2),
		min_steer_factor,
		1.0
	) * steer_strength

func apply_rotation(delta: float) -> void:
	if velocity > 0.0:
		rotate(get_steer_factor() * delta * steer)


func bounce(pos: Vector2) -> void:
	set_physics_process(false)
	velocity = 0.0
	position = pos
	await get_tree().create_timer(bounce_time).timeout
	set_physics_process(true)

func hit_boundary(pos: Vector2) -> void:
	bounce(pos)

func lap_completed() -> void:
	if checkpoint_count == checkpoints_passed.size():
		var lcd : LapCompleteData = LapCompleteData.new(self,lap_time)
		print(lcd)
		EventHub.emit_on_lap_completed(lcd)
	checkpoints_passed.clear()
	lap_time = 0.0

func hit_checkpoint(checkpoint_id: int) -> void:
	if checkpoint_id not in checkpoints_passed:
		checkpoints_passed.append(checkpoint_id)
