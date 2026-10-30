extends CharacterBody3D

@onready var head = $CameraHolder
@onready var cam = $CameraHolder/Camera3D
@onready var raycast = $CameraHolder/Camera3D/RayCast3D

var accel = 6
var SPEED = 5.0
var JUMP_VELOCITY = 4.5
var crouched = false 
var input_dir = Vector3(0,0,0) 
var direction = Vector3() 
var sens = 0.005
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Переменные для системы подъема предметов
var hold_object: RigidBody3D = null
var throw_force = 10.0
var hold_position: Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Создаем HoldPosition после инициализации всех @onready переменных
	hold_position = Node3D.new()
	hold_position.name = "HoldPosition"
	cam.add_child(hold_position)
	hold_position.position = Vector3(0, 0, -2) # Позиция перед камерой

func _input(event): 
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * sens)
			cam.rotate_x(-event.relative.y * sens)
			cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Обработка подъема и броска предметов
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: # ЛКМ - поднять/бросить предмет
				if hold_object:
					# Бросаем предмет
					throw_object()
				else:
					# Пытаемся поднять предмет
					pick_up_object()
			
			MOUSE_BUTTON_RIGHT: # ПКМ - бросить с силой
				if hold_object:
					throw_object(true)

func pick_up_object():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is RigidBody3D:
			hold_object = collider
			# Сохраняем оригинальные настройки
			hold_object.set_meta("original_collision_mask", hold_object.collision_mask)
			hold_object.set_meta("original_collision_layer", hold_object.collision_layer)
			hold_object.set_meta("original_gravity", hold_object.gravity_scale)
			
			# Настраиваем для удержания
			hold_object.freeze = true
			hold_object.collision_mask = 0 # Отключаем коллизии
			hold_object.collision_layer = 0
			hold_object.gravity_scale = 0
			
			print("Поднят предмет: ", hold_object.name)

func throw_object(strong_throw: bool = false):
	if hold_object:
		# Восстанавливаем оригинальные настройки
		hold_object.freeze = false
		hold_object.collision_mask = hold_object.get_meta("original_collision_mask", 1)
		hold_object.collision_layer = hold_object.get_meta("original_collision_layer", 1)
		hold_object.gravity_scale = hold_object.get_meta("original_gravity", 1.0)
		
		# Применяем силу броска
		var throw_power = throw_force * 2.0 if strong_throw else throw_force
		hold_object.linear_velocity = cam.global_transform.basis.z * -throw_power
		
		print("Брошен предмет с силой: ", throw_power)
		hold_object = null

func _physics_process(delta):
	if not is_on_floor(): 
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
	
	# Обработка движения
	input_dir = Input.get_vector("+a", "+d", "+w", "+s")
	direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
 
	velocity.x = lerp(velocity.x, direction.x * SPEED, accel * delta)
	velocity.z = lerp(velocity.z, direction.z * SPEED, accel * delta)
	
	# Обновление позиции удерживаемого предмета
	if hold_object:
		hold_object.global_transform.origin = hold_position.global_transform.origin
		# УБРАНА строка, которая перезаписывала вращение предмета
		# Предмет будет сохранять свое исходное вращение
	
	move_and_slide()

# Функция для проверки возможности взаимодействия
func can_interact() -> bool:
	return raycast.is_colliding() and raycast.get_collider() is RigidBody3D

# Функция для получения информации о предмете перед игроком
func get_looking_at_object() -> RigidBody3D:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is RigidBody3D:
			return collider
	return null
