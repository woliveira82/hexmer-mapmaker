class_name TerrainChunk
extends Node2D
## Draws the terrain of one block of hexes across all visible layers.
## Layers are drawn bottom first; within a layer, hexes sharing a texture are sent as one
## triangle array, and textureless hexes as one coloured array.
## In [member low_detail] mode (zoomed far out) it instead draws one pixel per hex in the
## terrain's colour, which is far cheaper to build.


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

## Map-space bounding box of the hexes this chunk covers.
var bounds: Rect2

## When true, draws one flat-coloured pixel per hex instead of sprites.
var low_detail: bool = false:
	set(value):
		if value != low_detail:
			low_detail = value
			queue_redraw()

## Placeholder colour for terrain IDs the registry doesn't know.
var missing_color: Color = Color(1.0, 0.0, 1.0)

var _map: MapData
var _registry: TerrainRegistry
var _hexes: Array[Vector2i] = []
var _offset_rect: Rect2i


## Sets what to draw: the hexes of [param map] whose even-r offset lies in
## [param offset_rect] (clipped to the map), resolved through [param registry].
func setup(map: MapData, registry: TerrainRegistry, offset_rect: Rect2i) -> void:
	_map = map
	_registry = registry
	_offset_rect = offset_rect.intersection(Rect2i(0, 0, map.grid.width, map.grid.height))
	_hexes = map.grid.cells_in_offset_rect(_offset_rect)
	bounds = map.layout.hexes_bounds(_hexes)
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
		if not layer.visible or layer.cell_count() == 0:
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


## Builds the low-detail image: one pixel per hex in offset order (col, row from the chunk's
## corner), coloured by the topmost visible layer's terrain; transparent where all are empty.
func build_low_detail_image() -> Image:
	var image := Image.create_empty(maxi(_offset_rect.size.x, 1), maxi(_offset_rect.size.y, 1), false, Image.FORMAT_RGBA8)
	if _map == null:
		return image
	var colors: Dictionary[MapCell, Color] = {}
	for layer: MapLayer in _map.get_layers():
		if not layer.visible or layer.cell_count() == 0:
			continue
		# _hexes runs row by row over _offset_rect, so pixels follow the same order.
		var pixel := Vector2i.ZERO
		for hex: Vector2i in _hexes:
			var cell: MapCell = layer.get_cell(hex)
			if cell != null:
				if not colors.has(cell):
					colors[cell] = _cell_color(cell)
				image.set_pixelv(pixel, colors[cell])
			pixel.x += 1
			if pixel.x == _offset_rect.size.x:
				pixel = Vector2i(0, pixel.y + 1)
	return image


## Returns the transform from low-detail image pixels to map space: pixel centres land within
## a quarter hex of their hex centres (even-r rows alternate a half-hex shift, which an
## image can't follow; invisible at low-detail zoom).
func get_low_detail_transform() -> Transform2D:
	var layout: HexLayout = _map.layout
	var corner: Vector2i = _offset_rect.position
	var origin: Vector2 = layout.hex_to_pixel(HexCoordinates.even_r_to_axial(corner))
	var x_axis: Vector2 = layout.hex_to_pixel(HexCoordinates.even_r_to_axial(corner + Vector2i(1, 0))) - origin
	# Two rows down skips the alternating shift; then split the odd-row shift between both rows.
	var y_axis: Vector2 = (layout.hex_to_pixel(HexCoordinates.even_r_to_axial(corner + Vector2i(0, 2))) - origin) / 2.0
	var odd_row_shift: Vector2 = layout.hex_to_pixel(HexCoordinates.even_r_to_axial(corner + Vector2i(0, 1))) - origin - y_axis
	return Transform2D(x_axis, y_axis, origin + odd_row_shift * 0.5 - (x_axis + y_axis) * 0.5)


func _draw() -> void:
	if low_detail:
		_draw_low_detail()
	else:
		_draw_batches()


func _draw_low_detail() -> void:
	if _hexes.is_empty():
		return
	draw_set_transform_matrix(get_low_detail_transform())
	draw_texture(ImageTexture.create_from_image(build_low_detail_image()), Vector2.ZERO)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _cell_color(cell: MapCell) -> Color:
	var definition: TerrainDefinition = _registry.get_definition(cell.terrain_id)
	return definition.color if definition != null else missing_color


func _draw_batches() -> void:
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
