extends Camera3D

@export var target: Node3D
@export var distance := 10.0
@export var min_distance := 2
@export var max_distance := 20.0

@export var zoom_speed := .4
@export var smooth_speed := 5

var yaw := 0.0
var pitch := 0.0
var rotating := false


var target_distance := 10.0

func _ready():
	target_distance = distance

func _input(event):
	if Input.is_action_just_pressed("shift_lock"):
		target.shiftlock = !target.shiftlock

		if target.shiftlock:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			rotating = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not target.shiftlock:
			rotating = event.pressed
			Input.set_mouse_mode(
				Input.MOUSE_MODE_CAPTURED if rotating else Input.MOUSE_MODE_VISIBLE
			)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance += zoom_speed

		target_distance = clamp(target_distance, min_distance, max_distance)

	if event is InputEventMouseMotion:
		if rotating or target.shiftlock:
			yaw -= event.relative.x * target.sensitivity
			pitch -= event.relative.y * target.sensitivity
			pitch = clamp(pitch, -1.5, 1.5)

func _process(delta):
	if target == null:
		return
	
	distance = lerp(distance, target_distance, smooth_speed * delta)
	
	var rotation = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	
	var offset = rotation * Vector3(0, 0, distance)
	var desired_pos = target.global_position + offset
	
	global_position = desired_pos
	
	var focus_point = target.global_position + Vector3(0, 1, 0)
	look_at(focus_point, Vector3.UP)
