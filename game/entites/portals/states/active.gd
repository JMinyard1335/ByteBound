extends PortalState

@export var despawn_state: PortalState
@export var teleport_state: PortalState

func process_input(_event: InputEvent) -> FSMState:
	if portal.locked: return # dont teleport if locked
	if portal.trigger_area.player and _event.is_action_pressed("interact"):
		return teleport_state
	return

func process_frame(_delta: float) -> FSMState:
	if portal.locked:  return null
	if not portal.trigger_area.player:
		return despawn_state
	return null
