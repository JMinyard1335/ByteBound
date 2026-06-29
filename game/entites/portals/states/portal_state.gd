class_name PortalState
extends FSMState2D


@export var animation_name: String

var portal: Portal:
	get: return body as Portal


func enter() -> void:
	super()
	if animation_name and has_anim(animation_name):
		portal.portal_sprite.play(animation_name)


func has_anim(anim: String) -> bool:
	if not portal.portal_sprite: return false
	return portal.portal_sprite.sprite_frames.has_animation(anim)
