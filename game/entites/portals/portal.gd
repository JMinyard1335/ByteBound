@tool
class_name Portal
extends Node2D
## Connects two points in the game space.
##
## when interacting with a portal the player will be teleported to the connected
## point on the map. Portals should be able to be locked or unlocked there by
## locking travel till unlocked either by mechanic or progression.
##
## The portal can be in a few states. [Hidden, Volitile, Spawning, Desapwning, Active]
## The main state flow is Volitile -> Spawning -> Active -> Despawning -> Volitile
## The Hidden State is for seceret or hidden portals that are not revealed till the player 
## is with in range of them.

#region Exports
## The name the portal will have
@export var portal_id: StringName = &""
@export var to_portal: StringName = &""

@export_category("State")
@export_enum("HIDDEN", "VOLITILE", "ACTIVE") var starting_state: String = "VOLITILE"
## If true the portal can leave its starting state. 
@export var locked: bool = false
## If true the portal will collapse to the hidden state instead of the volitile state.
## A hidden portal can not be seen at all and makes no noise till the player comes
## in range of it
@export var secret: bool = false

@export_category("Style")
## The main portal color. This color will be the center color with the color shading
## to create the portal shading.
@export var portal_color: Color = Color.CYAN:
	set(value):
		portal_color = value
		if is_node_ready():
			_apply_portal_color()
## The effect applied to the screen when the player interacts with the portal to >
## teleport to a different area
@export var portal_entered_vfx: ShaderMaterial
@export_group("audio")
## The sound played while the portal is active
@export var active_sfx: AudioPoolStream
## The sound played while the portal is volitile
@export var volitile_sfx: AudioPoolStream
## The stream applied to the audio while transition from volitile to active
## and vice versa
@export var transition_sfx: AudioPoolStream
#endregion Exports

var active_handle: AudioHandle
var volitile_handle: AudioHandle
# When true, the next Spawn/Despawn skips its transition_sfx. Set by teleport so
# arriving at a destination doesn't replay its spawn whoosh.
var _suppress_next_transition_sfx: bool = false

#region OnReady
# Ships inside Portal.tscn.
@onready var portal_sprite: PortalSprite = get_node_or_null("PortalSprite")
# Ships inside Portal.tscn.
@onready var transition_area: ProximityArea = get_node_or_null("TransitionArea")
## The outer activation ring. Added per-instance in the level scene so each portal
## can size its own range; flagged by [method _get_configuration_warnings] if absent.
@onready var trigger_area: ProximityArea = get_node_or_null("TriggerArea")
# Ships inside Portal.tscn.
@onready var portal_state: FSMachine2D = get_node_or_null("PortalState")
#endregion OnReady


func _ready() -> void:
	_apply_portal_color()
	if Engine.is_editor_hint():
		# Keep the warning live as the designer adds/removes the TriggerArea child.
		child_order_changed.connect(update_configuration_warnings)
		return
	_assert_nodes()
	# React to transitions for per-state audio; connect before the starting state is
	# set so that state's sound starts too.
	portal_state.state_changed.connect(_handle_audio)
	_set_starting_state()


func _input(event: InputEvent) -> void:
	if not transition_area.player: return
	if event.is_action_pressed("interact"):
		# TODO: implement teleport
		pass


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not (get_node_or_null("TriggerArea") is ProximityArea):
		warnings.append(
			"Add a ProximityArea named \"TriggerArea\" as a child to set this "
			+ "portal's activation range. Each portal carries its own so ranges "
			+ "can differ per level."
		)
	# The rest ship inside Portal.tscn; flagged only if the scene was edited down.
	if not (get_node_or_null("PortalSprite") is PortalSprite):
		warnings.append("Missing a PortalSprite named \"PortalSprite\".")
	if not (get_node_or_null("TransitionArea") is ProximityArea):
		warnings.append("Missing a ProximityArea named \"TransitionArea\".")
	if not (get_node_or_null("PortalState") is FSMachine2D):
		warnings.append("Missing an FSMachine2D named \"PortalState\".")
	return warnings


# Pushes portal_color into the sprite's recolor shader. Null-safe so it can run in
# the editor and during load before the sprite child is guaranteed present.
func _apply_portal_color() -> void:
	if portal_sprite:
		portal_sprite.set_color(portal_color)


# Required nodes for the portal to run. trigger_area is added per-instance in the
# level scene; the rest ship with Portal.tscn.
func _assert_nodes() -> void:
	assert(portal_sprite, "Portal is missing its PortalSprite child.")
	assert(transition_area, "Portal is missing its TransitionArea child.")
	assert(trigger_area, "Portal needs a TriggerArea (ProximityArea) child; add one in the level scene.")
	assert(portal_state, "Portal is missing its PortalState child.")


# Sets the starting state of the FSM based off the portal's editor export
func _set_starting_state() -> void:
	match starting_state:
		"HIDDEN":
			portal_state.change_state(portal_state.state_list.get("Hidden"))
		"VOLITILE":
			portal_state.change_state(portal_state.state_list.get("Volitile"))
		"ACTIVE":
			portal_state.change_state(portal_state.state_list.get("Active"))
		_:
			push_warning("Unknown portal start state setting default volitile")
			portal_state.change_state(portal_state.state_list.get("Volitile"))


## Skips the transition_sfx on this portal's next Spawn/Despawn. Used by teleport so
## a destination that spawns as the player arrives doesn't replay its whoosh.
func suppress_next_transition_sfx() -> void:
	_suppress_next_transition_sfx = true


# Starts the loop for the state we just entered, stops the others, and fires the
# one-shot transition whoosh when entering a transition state. Driven by
# FSMachine.state_changed, so it runs once per transition.
func _handle_audio(_to: FSMState) -> void:
	var states: Dictionary[String, FSMState] = portal_state.state_list
	var current: FSMState = portal_state.current_state
	# Teleport is a brief sub-phase of being at an active portal; keep the loop alive
	# across it so a bounced/locked teleport doesn't restart the sound.
	var at_active_portal: bool = current == states.get("Active") or current == states.get("Teleport")
	active_handle = _sfx_for_state(at_active_portal, active_sfx, active_handle)
	volitile_handle = _sfx_for_state(current == states.get("Volitile"), volitile_sfx, volitile_handle)
	# Volitile <-> Active passes through Spawn / Despawn; play the whoosh there,
	# unless a teleport asked us to skip the next one.
	if current == states.get("Spawn") or current == states.get("Despawn"):
		if _suppress_next_transition_sfx:
			_suppress_next_transition_sfx = false
		elif transition_sfx:
			AudioPool.play(transition_sfx, global_position)
	elif current == states.get("Volitile"):
		# Drop an unused suppression so it can't mute a later, genuine transition.
		_suppress_next_transition_sfx = false


# Starts [param sfx] (looping) when [param should_play] and it isn't already going;
# stops it otherwise. Returns the current handle.
func _sfx_for_state(should_play: bool, sfx: AudioPoolStream, handle: AudioHandle) -> AudioHandle:
	if should_play:
		if sfx and (handle == null or not handle.is_playing()):
			return AudioPool.play(sfx, global_position)
		return handle
	if handle and handle.is_valid():
		handle.stop()
	return handle
