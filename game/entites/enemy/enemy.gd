@tool
class_name Enemy
extends BaseCharacter
## Shared base for every AI enemy.
##
## Patrol is driven by a [Pathfinder] added as a direct child [b]per level[/b] — so its
## [member Pathfinder.region] can be set in the editor without toggling "editable children" on the
## enemy instance. The enemy warns until one is present, resolves it at runtime, and wires its
## steering into the [LocomotionComponent].

## Owns the body's movement and is its sole mover/slider. Controllers (the
## behavior tree) set intent through this component, never sliding the body.
@export var locomotion: LocomotionComponent

## This enemy's patrol agent; resolved from a child [Pathfinder] at runtime.
var pather: Pathfinder

#region Engine Methods
func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_warnings_on_child_changes()
		return
	super._ready()
	assert(locomotion, "Enemy: locomotion (LocomotionComponent) is not set")
	pather = _find_pather()
	assert(pather, "Enemy: add a Pathfinder child node so this enemy can patrol")
	pather.steering.connect(locomotion.steer)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if _find_pather() == null:
		warnings.append("Add a Pathfinder child node (and set its Region) so this enemy can patrol.")
	return warnings
#endregion

#region Private Helpers
## The first child [Pathfinder], or [code]null[/code] when none is present.
func _find_pather() -> Pathfinder:
	for child: Node in get_children():
		if child is Pathfinder:
			return child as Pathfinder
	return null


## Editor-only: keep the missing-Pathfinder warning live as children are added/removed.
func _refresh_warnings_on_child_changes() -> void:
	var refresh: Callable = func(_node: Node) -> void: update_configuration_warnings()
	child_entered_tree.connect(refresh)
	child_exiting_tree.connect(refresh)
#endregion
