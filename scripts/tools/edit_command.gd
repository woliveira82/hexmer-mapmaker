class_name EditCommand
## Base class for reversible map edits. Subclasses store only what they change, so
## [method undo] restores exactly the state before [method do].


## Applies the edit.
func do() -> void:
	pass


## Reverts the edit. Only valid right after [method do] (or a [method undo]/[method do] pair).
func undo() -> void:
	pass


## Returns true if the command would change nothing; the undo stack drops these.
func is_empty() -> bool:
	return false


## Short label for menus and tooltips, e.g. "Paint 12 hexes".
func get_description() -> String:
	return "Edit"
