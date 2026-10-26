class_name UndoStack
## Linear undo/redo history of [EditCommand]s. Recording a new command clears the redo branch.

## Emitted whenever undo/redo availability or the history changes.
signal changed

const DEFAULT_MAX_SIZE: int = 200

## Oldest commands are dropped beyond this many.
var max_size: int = DEFAULT_MAX_SIZE

var _undo: Array[EditCommand] = []
var _redo: Array[EditCommand] = []


## Runs [param command] and records it. Empty commands are ignored. Returns true if recorded.
func execute(command: EditCommand) -> bool:
	if command == null or command.is_empty():
		return false
	command.do()
	_record(command)
	return true


## Records a [param command] that has already been applied (e.g. a stroke painted live
## during a drag). Empty commands are ignored. Returns true if recorded.
func push_done(command: EditCommand) -> bool:
	if command == null or command.is_empty():
		return false
	_record(command)
	return true


## Reverts the latest command. Returns false if there is nothing to undo.
func undo() -> bool:
	if _undo.is_empty():
		return false
	var command: EditCommand = _undo.pop_back()
	command.undo()
	_redo.push_back(command)
	changed.emit()
	return true


## Re-applies the latest undone command. Returns false if there is nothing to redo.
func redo() -> bool:
	if _redo.is_empty():
		return false
	var command: EditCommand = _redo.pop_back()
	command.do()
	_undo.push_back(command)
	changed.emit()
	return true


## Returns true if there is something to undo.
func can_undo() -> bool:
	return not _undo.is_empty()


## Returns true if there is something to redo.
func can_redo() -> bool:
	return not _redo.is_empty()


## Description of the command [method undo] would revert, or "" if none.
func undo_description() -> String:
	return _undo.back().get_description() if can_undo() else ""


## Description of the command [method redo] would re-apply, or "" if none.
func redo_description() -> String:
	return _redo.back().get_description() if can_redo() else ""


## Forgets all history, e.g. after loading or replacing the map.
func clear() -> void:
	_undo.clear()
	_redo.clear()
	changed.emit()


func _record(command: EditCommand) -> void:
	_undo.push_back(command)
	_redo.clear()
	while _undo.size() > maxi(max_size, 1):
		_undo.pop_front()
	changed.emit()
