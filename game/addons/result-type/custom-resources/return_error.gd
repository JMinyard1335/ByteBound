class_name ResultError
extends Resource
## represents an error held by the [Result] type

## The error value
@export var err: int
## The readable human error message
@export var msg: String
## Flag that says if the error is considered fatal and should crash the program
@export var fatal: bool

func _init(code: int = 1, m: String = "", f: bool = false) -> void:
	err = code
	msg = m
	fatal = f

func report() -> void:
	if fatal: push_error(msg)
	print("[ERROR]: (%d) - %s" % [err, msg])
