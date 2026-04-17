extends CharacterBody3D
#walkspeed and jump height
const SPEED = 4
const JUMP_VELOCITY = 7.5
#coyote time shi
@export var coyote_time := 0.1
var coyote_timer := 0.0
# health shit idk
@export var MaxHealth := 100.0
var Health := 100.0
var kills := 5
var ouch := 20
var instakills := MaxHealth
@export var regen_rate := 1.0  # HP per second
@export var regen_delay := 2.0  # seconds after taking damage
var regen_timer := 0.0
var took_damage := false
# camera and trusses etc
@export var sensitivity := 0.005
@export var climb_speed := 3.0
@export var stick_force := 2.0
@export var jump_off_force := 40
@export var jump_up_force := 5.0
var just_jumped_off := false

@onready var cam = $Camera3D
@onready var ray = $RayCast3D
@onready var brickCollision = $Area3D
@export var HealthBar: ProgressBar
@export var spawn: Node3D


# how far u can fall into the void xd
@export var voidDepth := 50.0
@export var shiftlock := false

var is_climbing := false
var climb_normal := Vector3.ZERO


func _ready() -> void:
	reset()




func update_health_bar():
	if HealthBar:
		HealthBar.value = (Health / MaxHealth) * 100


func remove_Health(amount: float):
	if Health > 0:
		Health = max(0, Health - amount)
		update_health_bar()
		regen_timer = 0.0
		took_damage = true

func add_Health(amount: float):
	if Health < MaxHealth:
		Health = min(MaxHealth, Health + amount)
		update_health_bar()


func reset():
	position = spawn.position
	Health = MaxHealth
	update_health_bar()




func _physics_process(delta: float) -> void:
	# passive regen system
	if Health < MaxHealth:
		if took_damage:
			regen_timer += delta
			if regen_timer >= regen_delay:
				took_damage = false
		else:
			Health += regen_rate * delta
			Health = min(Health, MaxHealth)
			update_health_bar()
	if ray.is_colliding() and not is_on_floor():
		var collider = ray.get_collider()

		if collider.is_in_group("climbable"):
			is_climbing = true
			climb_normal = ray.get_collision_normal()
			ray.target_position.y = -0.2
		else:
			is_climbing = false
			climb_normal = Vector3.ZERO
			ray.target_position.y = -0.1
	else:
		is_climbing = false
		climb_normal = Vector3.ZERO
	
	if not is_on_floor() and not is_climbing:
		velocity += get_gravity() * delta

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("ui_accept"):
		if coyote_timer > 0 and not is_climbing:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0

		elif is_climbing:
			velocity += climb_normal * jump_off_force + Vector3.UP * jump_up_force
			is_climbing = false
			just_jumped_off = true

	if position.y <= -voidDepth:
		reset()

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var cam_basis = cam.global_transform.basis
	var forward = -cam_basis.z
	var right = cam_basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction = (right * input_dir.x + forward * input_dir.y).normalized()

	if is_climbing:
		velocity.x = 0
		velocity.z = 0

		if Input.is_action_pressed("ui_up"):
			velocity.y = -climb_speed
		elif Input.is_action_pressed("ui_down"):
			velocity.y = climb_speed
		else:
			velocity.y = 0


	elif not just_jumped_off:
		if direction != Vector3.ZERO:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0
			velocity.z = 0

	# ROTATION
	if is_climbing:
		if shiftlock:
			# allow rotation with camera
			var cam_forward = -cam.global_transform.basis.z
			cam_forward.y = 0
			cam_forward = cam_forward.normalized()

			if cam_forward.length() > 0.001:
				rotation.y = atan2(cam_forward.x, cam_forward.z)
		else:
			# DO NOTHING → rotation stays locked
			pass

	else:
		if shiftlock:
			var cam_forward = -cam.global_transform.basis.z
			cam_forward.y = 0
			cam_forward = cam_forward.normalized()

			if cam_forward.length() > 0.001:
				rotation.y = atan2(cam_forward.x, cam_forward.z)
		else:
			if direction.length() > 0.001:
				var target_angle = atan2(direction.x, direction.z)
				rotation.y = lerp_angle(rotation.y, target_angle, 10 * delta)
	move_and_slide()
	just_jumped_off = false


func _process(delta: float) -> void:
	if Health <= 0:
		reset()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("kills"):
		remove_Health(kills)
	elif body.is_in_group("ouch"):
		remove_Health(ouch)
	elif body.is_in_group("instakills"):
		remove_Health(instakills)
