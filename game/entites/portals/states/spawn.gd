extends PortalState

@export var volitile_state: PortalState
@export var active_state: PortalState

var _safe_exit: bool = false


func enter() -> void:
	_safe_exit = false
	if animation_name and has_anim(animation_name):
		portal.portal_sprite.play(animation_name)
		await portal.portal_sprite.animation_finished
		_safe_exit = true
	else:
		_safe_exit = true


func process_frame(_delta: float) -> FSMState:
	# Player walked away mid-spawn, fall back to volitile
	if not portal.trigger_area.player:
		return volitile_state
	# Let the spawn animation finish before going active
	if not _safe_exit:
		return self
	return active_state


func exit() -> void:
	super()
	_safe_exit = false
