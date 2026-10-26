class_name TerrainDefinition
extends Resource
## A terrain or feature type that cells refer to by [member id].
## Sprite data lives here, never in the cells. [member color] is the placeholder used when
## there are no sprites or a sprite is missing.

## Unique ID stored in map cells and project files, e.g. &"grassland".
@export var id: StringName
## Name shown in the palette.
@export var display_name: String
## Palette category, e.g. "Grassland" or "Water".
@export var category: String
## Placeholder fill colour when no sprite is available.
@export var color: Color = Color.MAGENTA
## Visual variants; a cell's variant index picks one. May be empty.
@export var variants: Array[Texture2D] = []


## Returns the texture for [param variant], or null if there is none.
## Out-of-range variants wrap, so a cell keeps rendering if a pack has fewer variants.
func get_variant_texture(variant: int) -> Texture2D:
	if variants.is_empty():
		return null
	return variants[posmod(variant, variants.size())]
