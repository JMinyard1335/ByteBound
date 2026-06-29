extends PortalState

@export var spawn_state: PortalState
@export var hidden_state: PortalState


func process_frame(_delta: float) -> FSMState:
	if portal.locked: return self # if portal is locked do nothing
	# if there is a player in the trigger area spawn the portal
	if portal.trigger_area.player: return spawn_state
	# if there is no player and this is a secret portal, collapse to hidden
	if not portal.trigger_area.player and portal.secret:
		return hidden_state
	# Stay in volitile if nothing has happend
	return self
