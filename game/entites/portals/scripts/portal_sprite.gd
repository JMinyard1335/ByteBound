@tool
class_name PortalSprite
extends AnimatedSprite2D
## The animated sprite for a [Portal].
##
## Plays the portal's state animations and recolors itself at runtime through the
## color-replace shader on its [member CanvasItem.material].
## See [code]res://Assets/shaders/color_replace.gdshader[/code].

## Name of the shader uniform that the recolor is stamped onto.
const RECOLOR_PARAM: StringName = &"recolor"


## Recolors the portal by writing [param color] into the shader's recolor ramp.
## Warns and does nothing if the sprite has no [ShaderMaterial].
func set_color(color: Color) -> void:
	var mat: ShaderMaterial = material as ShaderMaterial
	if not mat:
		push_warning("PortalSprite has no ShaderMaterial; cannot set color")
		return
	mat.set_shader_parameter(RECOLOR_PARAM, color)


func has_animation(anim: String) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(anim)
