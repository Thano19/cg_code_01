extends CharacterBody3D

@export var SPEED = 5.0
@export var ACCELERATION = 10.0
@export var DECELERATION = 8.0
@export var JUMP_VELOCITY = 4.5
@export var camera_pan_speed = 1
const PAN_SPEED_FACTOR = 0.0001

const KICK_RADIUS = 1.5
const KICK_FORCE = 10.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Schwerkraft
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Springen
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Richtungsinput (relativ zur Rotation des Spielers)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var forward = -transform.basis.z
		var right = transform.basis.x
		direction = (right * input_dir.x + forward * input_dir.y).normalized()

	# Bewegung mit Beschleunigung / Dämpfung
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)

	# Maussteuerung für Kamera und Drehung
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_vel = Input.get_last_mouse_velocity()
		rotation.y -= mouse_vel.x * camera_pan_speed * PAN_SPEED_FACTOR
		var cam_rig_rot = $CameraRig.rotation.x + mouse_vel.y * camera_pan_speed * PAN_SPEED_FACTOR
		cam_rig_rot = clamp(cam_rig_rot, -PI/2, -PI/8)
		$CameraRig.rotation.x = cam_rig_rot

		if Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Ball kicken
	if Input.is_action_just_pressed("kick"):
		try_kick_ball()

	# Bewegung ausführen
	move_and_slide()

func try_kick_ball():
	var space_state = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = KICK_RADIUS

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_transform.origin + transform.basis.z.normalized() * 1.0)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query, 10)
	for hit in result:
		var body = hit.get("collider")
		if body is RigidBody3D:
			var kick_dir = (body.global_transform.origin - global_transform.origin).normalized()
			body.apply_impulse(kick_dir * KICK_FORCE)
