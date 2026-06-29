class_name HazardStats
extends Resource
## Tunable configuration for a [HazardComponent].
##
## Holds the [i]logic[/i] of a hazard — how much it hurts, how it decides when it
## is dangerous, and its timing. Geometry (hitbox size, proximity radius) lives on
## the scene's collision shapes, and visuals/animation names live on the [Hazard]
## entity; only behaviour belongs here.[br][br]
## Save presets as [code].tres[/code] files (e.g. [code]constantSpike.tres[/code],
## [code]proximitySpike.tres[/code]) and assign different ones to instances of the
## same hazard scene to get different hazard types in a single level. Runtime state
## stays on the component, so one preset can be shared across many instances.

## How a hazard decides when it is dangerous.
enum Mode {
	## Dangerous whenever the hazard is active. Used by the lasers.
	CONTACT,
	## Auto-cycles safe -> (telegraph) -> dangerous on a timer.
	PERIODIC,
	## Safe until the player enters the proximity area, then arms.
	PROXIMITY,
}

@export_category("Damage")
## Hit points removed per hit. Ignored when [member lethal] is true.
@export var damage: int = 10
## When true, any hit instantly kills the player regardless of [member damage].
@export var lethal: bool = false
## Seconds between damage ticks while overlapping. [code]0[/code] = a single hit
## per arming (re-enter to be hit again); [code]> 0[/code] = repeating DOT.
@export var damage_interval: float = 0.0

@export_category("Activation")
## Which [enum Mode] decides when the hazard is dangerous.
@export var mode: Mode = Mode.CONTACT

@export_subgroup("Periodic")
## Safe window before each activation.
@export var idle_time: float = 1.0
## Optional warning window between idle and arming. [code]0[/code] = no telegraph.
@export var telegraph_time: float = 0.0
## How long the hazard stays dangerous each cycle.
@export var active_time: float = 1.0

@export_subgroup("Proximity")
## Delay between the player entering the proximity area and arming.
@export var proximity_charge: float = 0.0
