class_name ClimbComponent
extends Node
## Lets a [CharacterBody2D] opt into climbable stair collision.
##
## Stairs live on their own physics layer the body normally ignores, so the body
## walks straight past them — the [i]bottom path[/i]. While the body stands inside
## a stair zone (any [Area2D] overlapped by [member sensor]) and presses up or
## down, this adds [member climb_mask] to the body's collision mask, so
## move_and_slide treats the ramp as solid and the body walks up or down it — the
## [i]top path[/i].[br][br]
## The opt-in [b]latches[/b]: once climbing, the body stays opted in until it
## leaves every stair zone, by which point it is standing back on ordinary
## [code]Terrain[/code]. That is why the stair zone must cover the whole ramp and
## reach slightly onto the flat ground at each end — so releasing the body never
## drops it mid-ramp.

## Emitted when the body opts into stair collision (sfx / "climbing" visuals).
signal engaged
## Emitted when the body opts back out (left every zone / forced off).
signal disengaged

## The body whose collision mask is toggled. Defaults to the parent if unset.
@export var body: CharacterBody2D
## Detects stair zones; overlap any of them to allow climbing.
@export var sensor: Area2D
## Supplies the climb intent: up to ascend, down (fast-fall) to descend.
@export var input: InputComponent
## Physics layer(s) the climbable ramps occupy. Added to [member body]'s mask
## while climbing, removed otherwise. Must match the stair ramp body's layer.
@export_flags_2d_physics var climb_mask: int = 256

## True while the body is opted into stair collision. Read-only.
var climbing: bool = false


#region Engine Methods
func _ready() -> void:
	if not body:
		body = get_parent() as CharacterBody2D
	assert(body, "ClimbComponent: body (CharacterBody2D) not set")
	assert(sensor, "ClimbComponent: sensor (Area2D) not set")
	assert(input, "ClimbComponent: input (InputComponent) not set")
	assert(climb_mask != 0, "ClimbComponent: climb_mask not set")
	# Toggle the mask before the locomotion's move_and_slide (priority 100) runs.
	process_physics_priority = 50


func _physics_process(_delta: float) -> void:
	if not _in_zone():
		_set_climbing(false)
		return
	# Latch: stay opted in until the body leaves the zone (back on solid Terrain),
	# so releasing the up/down key part-way up never drops the body through.
	if climbing:
		return
	# Only opt in from solid ground, so passing through a zone in mid-air (a jump
	# or a fall down the shaft) never snaps the body onto the ramp.
	if body.is_on_floor() and _wants_climb():
		_set_climbing(true)
#endregion


#region Private Helpers
func _in_zone() -> bool:
	return not sensor.get_overlapping_areas().is_empty()


func _wants_climb() -> bool:
	return input.get_up() or input.get_fast_fall()


func _set_climbing(on: bool) -> void:
	if on == climbing:
		return
	climbing = on
	if on:
		body.collision_mask |= climb_mask
		engaged.emit()
		return
	body.collision_mask &= ~climb_mask
	disengaged.emit()
#endregion
