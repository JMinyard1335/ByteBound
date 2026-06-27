class_name Enemy extends BaseCharacter
## AI-controlled hazard that patrols, idles, and chases the player on sight.
##
## Movement and decisions are driven by the child [BeehaveTree]. This node wires
## its components and exposes shared sensory state for behavior leaves.

@export var hitbox: Hitbox
@export var locomotion: LocomotionComponent
@export var behavior_tree: BeehaveTree
@export var walk: WalkComponent
@export var jump: JumpComponent

@export_category("Field of View")
@export var fov: FoV
@export var num_segments: int
@export var sight_distance: float
@export var sight_angle: float

var player_in_sight: bool
var should_search: bool
var home_position: Vector2
var original_color: Color = Color(1, 0.270588, 0, 1)
var player: CharacterBody2D

func _ready() -> void:
	super._ready()
	home_position = global_position
	assert(walk, "Enemy: walk component not set")
	assert(jump, "Enemy: jump component not set")
	assert(fov, "Enemy: FoV component not set")
	assert(hitbox, "Enemy: hitbox component not set")
	assert(locomotion, "Enemy: locomotion component not set")
	assert(behavior_tree, "Enemy: behavior_tree not set")
	fov.init(num_segments, sight_angle, sight_distance)
	fov.sighted.connect(_on_sighted)
	fov.lost.connect(_on_lost)
	hitbox.init()
	SignalHub.actors_freeze_requested.connect(_on_freeze_requested)
	dir = movement_stats.starting_dir
	return

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	fov.update(dir)
	return

## Freezes ([param frozen] true) or resumes the enemy. While frozen the body is pinned
## in place and the [BeehaveTree] is disabled so the AI can neither move, see, nor kill.
func set_movement_frozen(frozen: bool) -> void:
	locomotion.frozen = frozen
	behavior_tree.enabled = not frozen
	if frozen:
		velocity = Vector2.ZERO
		walk.direction = 0.0
	return

func can_see_player() -> bool:
	return player_in_sight and is_instance_valid(player)

func is_home_reached(distance: float) -> bool:
	return global_position.distance_to(home_position) <= distance

func request_search() -> void:
	should_search = true
	return

func clear_search() -> void:
	should_search = false
	return

func _on_freeze_requested(frozen: bool) -> void:
	set_movement_frozen(frozen)
	return

func _on_sighted(body: Node2D) -> void:
	player_in_sight = true
	player = body as CharacterBody2D
	should_search = false
	return

func _on_lost(body: Node2D) -> void:
	if body != player:
		return
	player_in_sight = false
	request_search()
	return
