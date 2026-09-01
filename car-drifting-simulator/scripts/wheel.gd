extends Node2D


@export var lateral_stiffness: float = 500.0
@export var max_lateral_force: float = 1000.0
@export var steering_angle: float = 0.0
@export var max_steering_angle: float = 30.0

var car: RigidBody2D


func _ready():
	car = get_parent()


func _physics_process(_delta):
	get_steering()
	apply_lateral_force()


func get_steering():
	steering_angle = Input.get_axis("steer_left", "steer_right")
	steering_angle *= deg_to_rad(max_steering_angle)
	queue_redraw()


func apply_lateral_force():
	var wheel_position = position

	var rotational_velocity = Vector2(
		-car.angular_velocity * wheel_position.y,
		car.angular_velocity * wheel_position.x
	)

	var wheel_velocity = car.linear_velocity + rotational_velocity

	var wheel_rotation = car.rotation + steering_angle
	var wheel_right = Vector2.RIGHT.rotated(wheel_rotation)

	var lateral_velocity = wheel_velocity.dot(wheel_right)

	var lateral_force = -lateral_velocity * lateral_stiffness

	lateral_force = clamp(
		lateral_force,
		-max_lateral_force,
		max_lateral_force
	)

	car.apply_force(
		wheel_right * lateral_force,
		wheel_position
	)


func _draw():
	var wheel_length = 12.0

	var direction = Vector2.UP.rotated(steering_angle)

	draw_line(
		-direction * wheel_length / 2.0,
		direction * wheel_length / 2.0,
		Color.AQUA,
		3.0
	)
