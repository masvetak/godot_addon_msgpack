@tool extends EditorPlugin

const AUTOLOAD_NAME = "Msgpack"

# ------------------------------------------------------------------------------
# Build-in methods
# ------------------------------------------------------------------------------

func _enter_tree() -> void:
	self.add_autoload_singleton(AUTOLOAD_NAME, "msgpack.gd")

func _exit_tree() -> void:
	self.remove_autoload_singleton(AUTOLOAD_NAME)
