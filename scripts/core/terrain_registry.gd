class_name TerrainRegistry
## Resolves terrain IDs to [TerrainDefinition]s. Unknown IDs resolve to null so callers can
## keep the cell's logical data and draw a placeholder.

const STARTER_TERRAIN_DIR: String = "res://resources/terrain"

var _definitions: Dictionary[StringName, TerrainDefinition] = {}
var _order: Array[StringName] = []


## Adds [param definition]. Returns false (and adds nothing) if its ID is empty or taken.
func register(definition: TerrainDefinition) -> bool:
	if definition == null or definition.id.is_empty() or _definitions.has(definition.id):
		return false
	_definitions[definition.id] = definition
	_order.append(definition.id)
	return true


## Returns the definition for [param id], or null if it is not registered.
func get_definition(id: StringName) -> TerrainDefinition:
	return _definitions.get(id)


## Returns true if [param id] is registered.
func has(id: StringName) -> bool:
	return _definitions.has(id)


## Returns all registered IDs in registration order.
func ids() -> Array[StringName]:
	return _order.duplicate()


## Returns the distinct categories in registration order.
func categories() -> PackedStringArray:
	var result := PackedStringArray()
	for id: StringName in _order:
		var category: String = _definitions[id].category
		if not result.has(category):
			result.append(category)
	return result


## Returns the IDs in [param category], in registration order.
func ids_in_category(category: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in _order:
		if _definitions[id].category == category:
			result.append(id)
	return result


## Registers every [TerrainDefinition] .tres file in [param dir_path], sorted by file name.
## Returns the number added. Files that fail to load or have duplicate IDs are skipped
## with a warning.
func load_directory(dir_path: String) -> int:
	var files: PackedStringArray = ResourceLoader.list_directory(dir_path)
	files.sort()
	var added: int = 0
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var path: String = dir_path.path_join(file)
		var definition := ResourceLoader.load(path) as TerrainDefinition
		if definition == null:
			push_warning("Not a TerrainDefinition: %s" % path)
		elif not register(definition):
			push_warning("Skipped terrain with empty or duplicate ID: %s" % path)
		else:
			added += 1
	return added


## Returns a registry loaded with the starter terrains.
static func create_starter() -> TerrainRegistry:
	var registry := TerrainRegistry.new()
	registry.load_directory(STARTER_TERRAIN_DIR)
	return registry
