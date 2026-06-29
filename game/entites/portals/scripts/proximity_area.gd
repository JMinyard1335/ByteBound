@tool
class_name ProximityArea
extends Area2D
## An [Area2D] That reacts to the players presence.
##
## callbacks can be provided that have one parameter that
## is the player [Player]. Set the collison mask to search
## for the players collision layer
##
## *WARNING* This area does not react to anything that is
## not the [Player] class

## The "Player" physics layer index from project.godot (1-based).
const PLAYER_PHYSICS_LAYER: int = 2

var entered_cb: Callable
var exited_cb: Callable

## ref to the player set when the player enters the area
## set to null when the player leaves
var player: Player = null


func _ready() -> void:
	if Engine.is_editor_hint():
		# Refresh the warning as a shape child is added/removed in the editor.
		child_order_changed.connect(update_configuration_warnings)
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not _has_shape():
		warnings.append("Add a CollisionShape2D or CollisionPolygon2D child to give this area a detection region.")
	if (collision_mask & (1 << (PLAYER_PHYSICS_LAYER - 1))) == 0:
		warnings.append("collision_mask does not include the Player layer (%d), so it won't detect the player." % PLAYER_PHYSICS_LAYER)
	return warnings


## Provides a callable that will be executed when the
## player enters the proximity area. This callable can 
## take a single paramater that is (player [Player])
func set_entered_cb(cb: Callable) -> void:
	entered_cb = cb


## Provides a callable that will be executed when the
## player exits the proximity area. This callable can 
## take a single paramater that is (player [Player])
func set_exited_cb(cb: Callable) -> void:
	exited_cb = cb


func _on_body_entered(body: Node2D) -> void:
	if not body is Player: return
	player = body
	if entered_cb: entered_cb.call(body as Player)


func _on_body_exited(body: Node2D) -> void:
	if not body is Player: return
	player = null
	if exited_cb: exited_cb.call(body as Player)


# True if the area has a collision shape child to define its region.
func _has_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return true
	return false
