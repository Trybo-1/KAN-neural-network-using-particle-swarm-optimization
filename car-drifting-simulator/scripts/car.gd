extends RigidBody2D


@export var engine_force: float = 10000.0
@export var drag: float = 1000.0


func _physics_process(_delta):
	var forward = Vector2.UP.rotated(rotation)

	if Input.is_action_pressed("accelerate"):
		apply_central_force(forward * engine_force)

	apply_central_force(-linear_velocity * drag)
