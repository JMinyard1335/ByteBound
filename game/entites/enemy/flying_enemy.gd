@tool
class_name FlyingEnemy extends Enemy
## An enemy that flies, navigating freely with a [Pathfinder].
##
## Its [LocomotionComponent] carries a [FlyComponent], so the full 2D velocity the pather steers
## with is applied directly — there is no gravity to fight and free navigation suits it. Add a
## [Pathfinder] as a direct child (so its region can be set per level); this resolves it at runtime
## and feeds its steering into the locomotion.

## This enemy's patrol agent; resolved from a child [Pathfinder] at runtime.
var pather: Pathfinder

func _ready() -> void:
	# Runs all editor only updates and then returns to avoid running game code.
	if _update_editor(): return
	super._ready()
	
	# Get the pathfinder node for the flying enemy at runtime
	var rv: Result = _find_pather().value
	if not rv.ok: 
		push_error("FlyingEnemy: add a Pathfinder child node so this enemy can patrol")
		
	pather.steering.connect(locomotion.steer)


#region Editor Tooling
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if not _find_pather().ok:
		warnings.append("Add a Pathfinder child node (and set its Region) so this enemy can patrol.")
	return warnings


# finds the first pathfinder that is a child of the Flyer. Returns a result whos
# value is a Patfinder node only of [member Result.ok] is true
func _find_pather() -> Result:
	for child: Node in get_children():
		if not child is Pathfinder:
			continue
		
		return Result.new(true, null, child as Pathfinder)
	return Result.new(false,  ResultError.new(1, "No Pathfinder node found"))

# Runs all editor only logic and returns true if the editor logic ran
# returning true allows for early returns in the _ready
func _update_editor() -> bool:
	if Engine.is_editor_hint(): 
		_refresh_warnings_on_child_changes()
		return true
	return false

# Editor-only: connects child enters/exit tree to update_configuration_warnings
# this is used to recheck for a [Pather] node whenever a child is added or removed
func _refresh_warnings_on_child_changes() -> void:
	child_entered_tree.connect(update_configuration_warnings.unbind(1))
	child_exiting_tree.connect(update_configuration_warnings.unbind(1))

#endregion Editor Tooling
