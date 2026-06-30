class_name Result
extends RefCounted
## A generic result type that holds a success flag, error, value
##
## It will default to a failed generic error state. This means you can return a
## brand new result in error checks without having to define additional data.
## This does give generic error messages but its a `quick cut` for proto-typing.

const DEFAULT_ERROR = preload("uid://bp5p7yla20shs")

## Success flag if false there was an error in fetching the result
var ok: bool
## only set if [member Result.ok] is false. Message describing the error
var err: ResultError
## only set if [member Result.ok] is true. Can hold any type
var value: Variant 


func _init(
	flag: bool = false, 
	error: ResultError = DEFAULT_ERROR , 
	result: Variant = null
) -> void:
	ok = flag
	err = error
	value = result
