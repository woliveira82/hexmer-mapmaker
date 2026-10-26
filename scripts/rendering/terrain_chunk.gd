class_name TerrainChunk
extends Node2D
## Draws the terrain of one block of hexes across all visible layers.
## Layers are drawn bottom first; within a layer, hexes sharing a texture are sent as one
## triangle array, and textureless hexes as one coloured array.


## Triangles for one texture (or none) on one layer.
class Batch:
	var layer_id: int
	## Null for flat placeholder colours.
	var texture: Texture2D
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	## Number of hexes in the batch.
	@warning_ignore("integer_division")
	func hex_count() -> int:
		return points.size() / HEX_CORNERS


const HEX_CORNERS: int = 6

## Placeholder colour for terrain IDs the registry doesn't know.
var missing_color: Color = Color(1.0, 0.0, 1.0)

var _map: MapData
var _registry: TerrainRegistry
var _hexes: Array[Vector2i] = []


## Sets what to draw: [param hexes] of [param map], resolved through [param registry].
func setup(map: MapData, registry: TerrainRegistry, hexes: Array[Vector2i]) -> void:
	_map = map
	_registry = registry
	_hexes = hexes
	queue_redraw()


## Returns the hexes this chunk covers.
func get_hexes() -> Array[Vector2i]:
	return _hexes


## Builds the draw batches from the current map content, bottom layer first.
func build_batches() -> Array[Batch]:
	var result: Array[Batch] = []
	if _map == null:
		return result
	var layout: HexLayout = _map.layout
	var corner_offsets: PackedVector2Array = []
	var corner_uvs: PackedVector2Array = []
	for i: int in HEX_CORNERS:
		var offset: Vector2 = layout.corner_offset(i)
		corner_offsets.append(offset)
		# The square texture spans the hex's 2·size bounding square, whatever the orientation.
		corner_uvs.append(offset / (layout.hex_size * 2.0) + Vector2(0.5, 0.5))
	for layer: MapLayer in _map.get_layers():
		if not layer.visible:
			continue
		var by_texture: Dictionary[Texture2D, Batch] = {}
		var flat: Batch = null
		for hex: Vector2i in _hexes:
			var cell: MapCell = layer.get_cell(hex)
			if cell == null:
				continue
			var definition: TerrainDefinition = _registry.get_definition(cell.terrain_id)
			var texture: Texture2D = definition.get_variant_texture(cell.variant) if definition != null else null
			var batch: Batch
			var color: Color = Color.WHITE
			if texture != null:
				batch = by_texture.get(texture)
				if batch == null:
					batch = _new_batch(layer.id, texture)
					by_texture[texture] = batch
					result.append(batch)
			else:
				if flat == null:
					flat = _new_batch(layer.id, null)
					result.append(flat)
				batch = flat
				color = definition.color if definition != null else missing_color
			_append_hex(batch, layout.hex_to_pixel(hex), corner_offsets, corner_uvs, color)
	return result


func _draw() -> void:
	var canvas_item: RID = get_canvas_item()
	for batch: Batch in build_batches():
		var texture_rid: RID = batch.texture.get_rid() if batch.texture != null else RID()
		RenderingServer.canvas_item_add_triangle_array(
			canvas_item, batch.indices, batch.points, batch.colors, batch.uvs,
			PackedInt32Array(), PackedFloat32Array(), texture_rid)


func _new_batch(layer_id: int, texture: Texture2D) -> Batch:
	var batch := Batch.new()
	batch.layer_id = layer_id
	batch.texture = texture
	return batch


func _append_hex(
	batch: Batch, center: Vector2, corner_offsets: PackedVector2Array,
	corner_uvs: PackedVector2Array, color: Color
) -> void:
	var first: int = batch.points.size()
	for i: int in HEX_CORNERS:
		batch.points.append(center + corner_offsets[i])
		batch.uvs.append(corner_uvs[i])
		batch.colors.append(color)
	# Triangle fan from corner 0: (0,1,2) (0,2,3) (0,3,4) (0,4,5).
	for i: int in range(1, HEX_CORNERS - 1):
		batch.indices.append(first)
		batch.indices.append(first + i)
		batch.indices.append(first + i + 1)
