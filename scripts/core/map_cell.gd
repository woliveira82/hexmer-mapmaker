class_name MapCell
## Content of one hex on one layer: a terrain ID plus a variant index.
## Treat as immutable: change a cell by replacing it, so undo commands can keep references.

var terrain_id: StringName
var variant: int


func _init(p_terrain_id: StringName, p_variant: int = 0) -> void:
	terrain_id = p_terrain_id
	variant = p_variant


## Returns true if [param other] has the same content.
func equals(other: MapCell) -> bool:
	return other != null and other.terrain_id == terrain_id and other.variant == variant
