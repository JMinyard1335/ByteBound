class_name GroundedEnemy extends Enemy
## An enemy bound to the ground — it walks and jumps under gravity.
##
## Its [LocomotionComponent] carries Walk + Gravity + Jump movers. Free [NavigationAgent2D] pathing
## doesn't suit a gravity-bound body (it throws away the vertical and never jumps), so a grounded
## enemy is steered through [member walk] and [member jump] by its behavior tree rather than a
## [Pathfinder].

## Drives horizontal movement. The behavior tree sets [member WalkComponent.direction].
@export var walk: WalkComponent
## Provides jumps the behavior tree triggers to clear walls, gaps, and ledges.
@export var jump: JumpComponent

func _ready() -> void:
	super._ready()
	assert(walk, "GroundedEnemy: walk (WalkComponent) is not set")
	assert(jump, "GroundedEnemy: jump (JumpComponent) is not set")
