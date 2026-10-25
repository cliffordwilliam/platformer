class_name TestLevel
extends Level
## A level built in code by a test: layout() calls `configure`, which the
## test sets first, so each test writes only the fields it needs.

static var configure: Callable


func layout() -> void:
	configure.call(self)
