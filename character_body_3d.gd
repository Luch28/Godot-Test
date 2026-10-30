extends CharacterBody3D



var walk_speed := 8.0
var jump_speed := 5.0
var acceleration_speed := 10.0
var gravity := -10.0

var hold_object: Object

var _dir := Vector3.ZERO
var _vel := Vector3.ZERO

@onready var _camera := $CameraHolder
@onready var _raycast := _camera.get_node("Camera3D/RayCast3D")
@onready var _hold_position := _camera.get_node("Camera3D/HoldPosition")

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_action_pressed("up"):
		input.y += 1
	if Input.is_action_pressed("down"):
		input.y -= 1
	if Input.is_action_pressed("right"):
		input.x += 1
	if Input.is_action_pressed("left"):
		input.x -= 1
		
	input = input.normalized()
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			_vel.y = jump_speed

	_vel.y += gravity * delta
	
	if Input.is_action_just_pressed("left_click"):
		if _raycast.get_collider():
			hold_object = _raycast.get_collider()
			hold_object.mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			hold_object.collision_mask = 0
	
	if hold_object:
		hold_object.global_transform.origin = _hold_position.global_transform.origin
	
	var camera_basis: Basis = _camera.global_transform.basis
	_dir = Vector3.ZERO
	_dir += -camera_basis.z * input.y  # Теперь используем camera_basis вместо basis
	_dir += camera_basis.x * input.x   # И здесь тоже
	_dir = _dir.normalized()

	var acc := _vel.lerp(_dir * walk_speed, acceleration_speed * delta)
	velocity = Vector3(acc.x, _vel.y, acc.z)
	move_and_slide()
