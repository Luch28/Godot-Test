extends CharacterBody3D

@onready var head = $head
@onready var cam = $head/Camera3D
 
 
var accel = 6
var SPEED = 5.0
var JUMP_VELOCITY = 4.5
var crouched = false 
var input_dir = Vector3(0,0,0) 
var direction = Vector3() 
var sens = 0.005
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
 
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
 
func _input(event: InputEvent): 
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * sens)
			cam.rotate_x(-event.relative.y * sens)
			cam.rotation.x = clamp(cam.rotation.x,deg_to_rad(-89),deg_to_rad(89))
			
func _physics_process(delta):
	if not is_on_floor(): 
		velocity.y -= gravity * delta
	################################################
	input_dir = Input.get_vector("+a", "+d", "+w", "+s")
	direction = ($head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
 
	velocity.x = lerp(velocity.x ,direction.x * SPEED, accel * delta)
	velocity.z = lerp(velocity.z ,direction.z * SPEED, accel * delta)
	move_and_slide()
	###################################################-- 
	
