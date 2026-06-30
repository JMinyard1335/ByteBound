@abstract
class_name Enemy 
extends BaseCharacter
## Abstract base for every AI-controlled enemy.
##
## Holds only what every enemy shares: a [LocomotionComponent] (the sole driver of the body's
## movement) and a child behavior tree that makes its decisions. What differs between enemies is
## [i]how they get around[/i] — so concrete enemies extend [FlyingEnemy] (free [Pathfinder]
## navigation) or [GroundedEnemy] (gravity-bound walking and jumping), never [Enemy] directly.

## Owns the body's movement and is its sole mover/slider. Controllers (the behavior tree) set
## intent through this component; nothing slides the body itself.
@export var locomotion: LocomotionComponent

func _ready() -> void:
	super._ready()
	assert(locomotion, "Enemy: locomotion (LocomotionComponent) is not set")
