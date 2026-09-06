extends Area2D

class_name Car

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


func _ready() -> void:
	pass

func _process(delta: float) -> void:
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
