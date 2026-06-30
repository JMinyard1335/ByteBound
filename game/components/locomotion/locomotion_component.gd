class_name LocomotionComponent extends Node
## Owns a body's motion loop and is the single public face of its movement.
##
## Runs each child [MovementComponent] in tree order every physics frame, then
## calls move_and_slide exactly once — the [b]sole[/b] caller of move_and_slide
## for its body. Controllers (FSM states, AI) set movement intent through this
## component's API ([method move], [method jump], [method dash], …); the child
## movers stay private and no controller slides the body itself.

## The body to move. Defaults to the parent if left unset.
@export var body: CharacterBody2D

## When true the body is pinned in place: velocity is zeroed and neither the
## movers nor move_and_slide run, so gravity and movement intent are ignored.
var frozen: bool = false

var _movers: Array[MovementComponent] = []

# Child movers — private. Only this component drives them; controllers reach
# them through the intent API below, never directly. Each is optional: a body
# can carry any subset (e.g. a flyer with none, just sliding its own velocity).
@onready var _gravity: GravityComponent = get_node_or_null("%Gravity")
@onready var _walk: WalkComponent = get_node_or_null("%Walk")
@onready var _fly: FlyComponent = get_node_or_null("%Fly")
@onready var _jump: JumpComponent = get_node_or_null("%Jump")
@onready var _dash: DashComponent = get_node_or_null("%Dash")

#region Engine Methods
func _ready() -> void:
	if not body:
		body = get_parent() as CharacterBody2D
	assert(body, "LocomotionComponent: body (CharacterBody2D) not set")
	# Collect the child movers to run each frame, in tree order.
	for child in get_children():
		if child is MovementComponent:
			_movers.append(child)
	# Run after controllers (FSM/AI) have set this frame's movement intent.
	process_physics_priority = 100


func _physics_process(delta: float) -> void:
	if frozen:
		body.velocity = Vector2.ZERO
		return
	for mover in _movers:
		mover.apply(body, delta)
	body.move_and_slide()
#endregion

#region Public API
## Sets horizontal movement intent for this frame. -1 left, 1 right, 0 stop.
func move(direction: float) -> void:
	if _walk:
		_walk.direction = direction


## Steers the body with a desired world velocity (from a [Pathfinder] or other AI).[br]
## Walkers consume only the x-direction (gravity owns y); flyers apply the full vector. The
## body type is inferred from which movers are present, so the caller stays type-agnostic.
func steer(velocity: Vector2) -> void:
	if _walk:
		_walk.direction = signf(velocity.x)
	if _fly:
		_fly.velocity = velocity


## Stops horizontal movement now: clears intent and zeroes current x velocity.
func stop() -> void:
	if _walk:
		_walk.direction = 0.0
	if _fly:
		_fly.velocity = Vector2.ZERO
	body.velocity.x = 0.0


## Sets whether the body should fast-fall (stronger gravity) this frame.
func set_fast_fall(enabled: bool) -> void:
	if _gravity:
		_gravity.fast_fall = enabled


## True if the body may start a jump right now.
func can_jump() -> bool:
	return _jump != null and _jump.can_jump()


## Applies a jump impulse to the body (scaled for air jumps).
func jump() -> void:
	if _jump:
		_jump.jump(body)


## True if the body may start a dash right now.
func can_dash() -> bool:
	return _dash != null and _dash.can_dash()


## True while a dash is in progress.
func is_dashing() -> bool:
	return _dash != null and _dash.is_dashing


## Starts a dash in [param direction] if one is available.
func dash(direction: float) -> void:
	if _dash:
		_dash.dash(direction)
#endregion
