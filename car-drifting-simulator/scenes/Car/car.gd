extends Area2D

class_name Car

var car_number: int = 0
var car_name: String = "car"

var throttle : float = 0.0
var velocity = 0.0
@export var max_speed = 380

var steer: float = 4
var steer_strength = 6
var min_steer_factor = 0.5

var bounce_force = 30.0
var bounce_time = 0.8
var bounce_tween : Tween
var bounce_target : Vector2 = Vector2.ZERO

var checkpoint_count: int = 3
var checkpoints_passed: Array[int] = []

var lap_time: float = 0.0

var training_paused : bool = true
signal physics_step_completed

var reward : float = 0.0
var time_exceded: bool = false

@onready var ray_cast_2d1: RayCast2D = $RayCast2D1
@onready var ray_cast_2d_4: RayCast2D = $RayCast2D4
@onready var ray_cast_2d_2: RayCast2D = $RayCast2D2
@onready var ray_cast_2d_5: RayCast2D = $RayCast2D5
@onready var ray_cast_2d_3: RayCast2D = $RayCast2D3

@onready var rays : Array[RayCast2D] = [$RayCast2D1, $RayCast2D4, $RayCast2D2, $RayCast2D5, $RayCast2D3]

func _ready() -> void:
	pass

func setup(cc: int) -> void:
	checkpoint_count = cc

func _process(delta: float) -> void:
	lap_time += delta
	reward -= delta
	if velocity < 25:
		reward -= 0.05
	else:
		reward += velocity/90
	#throttle = Input.is_action_pressed("accelerate")
	#steer = Input.get_axis("steer_left","steer_right")


func _physics_process(delta: float) -> void:
	if training_paused:
		return
	
	if lap_time > 60.0 and not time_exceded:
		time_exceded = true
		training_paused = true
		print("time exceded")
		EventHub.emit_on_lap_completed(LapCompleteData.new(self,lap_time,reward))
		velocity = 0.0
		return
	
	training_paused = true
	apply_throttle(delta)
	apply_rotation(delta)
	position += transform.x * velocity * delta
	if not time_exceded:
		physics_step_completed.emit()


func apply_throttle(delta: float) -> void:
	if throttle > 0.0:
		velocity += delta * 100.0
	else: 
		velocity -= delta * 150.0 * 0
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
	reward -= 80

func lap_completed() -> void:
	if checkpoint_count == checkpoints_passed.size():
		var lcd : LapCompleteData = LapCompleteData.new(self,lap_time,reward)
		print(lcd)
		reward += 30000
		EventHub.emit_on_lap_completed(lcd)
	checkpoints_passed.clear()
	#lap_time = 0.0

func hit_checkpoint(checkpoint_id: int) -> void:
	if checkpoint_id not in checkpoints_passed:
		checkpoints_passed.append(checkpoint_id)
		reward += 100

func get_distances() -> Array[float]:
	var output : Array[float] = []
	for ray in rays:
		if ray.is_colliding():
			output.append(global_position.distance_to(ray.get_collision_point()))
		else :
			output.append(9999.0)
	return output

func get_car_info_for_kan() -> Array[float]:
	var output: Array[float] = []
	output.append(velocity) 
	output.append_array(get_distances())
	return output

func set_steering(steering):
	steer = steering
func set_throttle(throtle):
	self.throttle = throtle

func reset():
	throttle= 0.0
	velocity = 0.0
	checkpoints_passed.clear()
	lap_time= 0.0
	training_paused = true
	reward= 0.0
	time_exceded = false
