class_name Player extends BaseCharacter
## The player-controlled character.
##
## Extends [BaseCharacter] (sprite, movement stats, facing) and wires the
## player's components: a [HealthComponent], the [LocomotionComponent] that owns
## all movement, and the [InputComponent]. The child FSM ([FSMachine2D]) reads
## input and drives the body through [member motion]'s intent API.


@export_category("Components")
## Tracks damage and announces death when health is depleted.
@export var health: HealthComponent
## Owns the body's movement; the sole mover/slider. States drive it via its API.
@export var motion: LocomotionComponent
## Polls and exposes the player's input each frame.
@export var input: InputComponent
## Handles the players animations
@export var anim: AnimationComponent
## The finite State machine that controlls the players state
@export var fsm: FSMachine2D



#region Engine Methods
func _ready() -> void:
	super._ready()
	assert(health, "Player: health component not set")
	assert(motion, "Player: motion (LocomotionComponent) not set")
	assert(input, "Player: input component not set")
	assert(anim, "Player: animation component not set")
	assert(fsm, "Player: fsm not set")
	
	health.health_depleated.connect(_on_death)
	fsm.init(self)


func _process(_delta: float) -> void:
	# Single owner of the player's facing: flip toward actual horizontal motion.
	# The dash's locked velocity carries through here too, so the states never
	# touch the sprite. At velocity.x == 0 the flip is held (last facing kept).
	anim.handle_horizontal_flip(velocity.x)
#endregion


#region Public API
## Deals [param amount] of damage to the player. Death is handled automatically
## when [member health] is depleted (via [signal HealthComponent.health_depleated]).
func hurt(amount: int) -> void:
	health.take_damage(amount)


## Instantly kills the player, routing through the normal death flow so listeners
## of [signal HealthComponent.health_depleated] still fire.
func kill() -> void:
	health.take_damage(health.health)
#endregion


func _on_death() -> void:
	if not fsm.state_list.has("Death"):
		return
	
	# Change to the death state if it exists
	fsm.change_state(fsm.state_list.get("Death"))
	
	
