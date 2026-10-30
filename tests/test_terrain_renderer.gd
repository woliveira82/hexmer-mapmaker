extends GutTest
## Terrain chunks: coverage, batching per layer and texture, placeholders, partial redraws.

const ORIENTATIONS: Array[HexLayout.HexOrientation] = [
	HexLayout.HexOrientation.POINTY_TOP, HexLayout.HexOrientation.FLAT_TOP,
]

var _registry: TerrainRegistry


func before_each() -> void:
	_registry = TerrainRegistry.create_starter()
	var flat := TerrainDefinition.new()
	flat.id = &"flat"
	flat.color = Color(0.1, 0.2, 0.3)
	_registry.register(flat)


func _make_renderer(map: MapData, chunk_size: int = 16) -> TerrainRenderer:
	var renderer := TerrainRenderer.new()
	renderer.chunk_size = chunk_size
	add_child_autofree(renderer)
	renderer.set_map(map, _registry)
	return renderer


func _make_map(width: int, height: int, orientation := HexLayout.HexOrientation.POINTY_TOP) -> MapData:
	return MapData.create_default(HexGrid.new(width, height), HexLayout.new(orientation))


func _layer_id(map: MapData, index: int) -> int:
	return map.get_layers()[index].id


## True if colours match to 8-bit image precision.
func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01 and absf(a.a - b.a) < 0.01


func _total_hexes(batches: Array[TerrainChunk.Batch]) -> int:
	var total: int = 0
	for batch: TerrainChunk.Batch in batches:
		total += batch.hex_count()
	return total


func test_chunks_cover_every_hex_once() -> void:
	var renderer := _make_renderer(_make_map(100, 100))
	assert_eq(renderer.get_chunks().size(), 49, "ceil(100/16)^2 chunks, not one node per hex")
	var seen: Dictionary[Vector2i, bool] = {}
	for chunk: TerrainChunk in renderer.get_chunks():
		for hex: Vector2i in chunk.get_hexes():
			assert_false(seen.has(hex), "hex %s in one chunk only" % hex)
			seen[hex] = true
	assert_eq(seen.size(), 10000)


func test_empty_map_draws_nothing() -> void:
	var renderer := _make_renderer(_make_map(8, 8))
	assert_eq(renderer.get_chunks()[0].build_batches().size(), 0)


func test_one_batch_per_texture_per_layer_bottom_first() -> void:
	var map := _make_map(8, 8)
	var base: int = _layer_id(map, 0)
	var details: int = _layer_id(map, 1)
	map.fill_layer(base, MapCell.new(&"grassland", 0))
	map.set_cell(base, Vector2i(1, 1), MapCell.new(&"grassland", 1))
	map.set_cell(details, Vector2i(2, 2), MapCell.new(&"forest", 0))
	map.set_cell(details, Vector2i(3, 2), MapCell.new(&"forest", 0))
	var batches := _make_renderer(map).get_chunks()[0].build_batches()
	assert_eq(batches.size(), 3, "grass v0, grass v1, forest v0")
	assert_eq(batches[0].layer_id, base)
	assert_eq(batches[1].layer_id, base)
	assert_eq(batches[2].layer_id, details, "upper layer drawn last")
	var grass: TerrainDefinition = _registry.get_definition(&"grassland")
	assert_eq(batches[0].texture, grass.get_variant_texture(0))
	assert_eq(batches[0].hex_count(), 63)
	assert_eq(batches[1].texture, grass.get_variant_texture(1))
	assert_eq(batches[2].hex_count(), 2)
	assert_eq(batches[2].indices.size(), 2 * 12, "4 triangles per hex")


func test_hidden_layers_are_skipped() -> void:
	var map := _make_map(8, 8)
	map.fill_layer(_layer_id(map, 0), MapCell.new(&"water"))
	map.set_cell(_layer_id(map, 1), Vector2i(0, 0), MapCell.new(&"desert"))
	var chunk: TerrainChunk = _make_renderer(map).get_chunks()[0]
	map.set_layer_visible(_layer_id(map, 0), false)
	var batches := chunk.build_batches()
	assert_eq(_total_hexes(batches), 1)
	assert_eq(batches[0].layer_id, _layer_id(map, 1))


func test_placeholder_colours_for_missing_sprites_and_unknown_ids() -> void:
	var map := _make_map(8, 8)
	var base: int = _layer_id(map, 0)
	map.set_cell(base, Vector2i(0, 0), MapCell.new(&"flat"))
	map.set_cell(base, Vector2i(1, 0), MapCell.new(&"not_in_registry", 3))
	var chunk: TerrainChunk = _make_renderer(map).get_chunks()[0]
	var batches := chunk.build_batches()
	assert_eq(batches.size(), 1, "both go in the untextured batch")
	assert_null(batches[0].texture)
	assert_eq(batches[0].hex_count(), 2)
	var colors: Array[Color] = []
	colors.assign(batches[0].colors)
	assert_true(colors.has(Color(0.1, 0.2, 0.3)), "definition colour when it has no sprites")
	assert_true(colors.has(chunk.missing_color), "missing colour for unknown IDs")
	assert_eq(map.get_cell(base, Vector2i(1, 0)).terrain_id, &"not_in_registry", "data kept")


func test_geometry_matches_hex_corners_and_uvs_stay_in_texture() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var map := _make_map(4, 4, orientation)
		map.set_cell(_layer_id(map, 0), Vector2i(1, 1), MapCell.new(&"snow"))
		var batch: TerrainChunk.Batch = _make_renderer(map).get_chunks()[0].build_batches()[0]
		assert_eq(batch.points, map.layout.polygon_corners(Vector2i(1, 1)))
		for uv: Vector2 in batch.uvs:
			assert_true(Rect2(0, 0, 1, 1).grow(0.0001).has_point(uv), "uv %s in texture" % uv)


func test_cell_edits_touch_only_their_chunks() -> void:
	var map := _make_map(40, 40)
	var renderer := _make_renderer(map)
	var hexes: Array[Vector2i] = [
		HexCoordinates.even_r_to_axial(Vector2i(0, 0)),
		HexCoordinates.even_r_to_axial(Vector2i(15, 15)),
		HexCoordinates.even_r_to_axial(Vector2i(16, 0)),
		HexCoordinates.even_r_to_axial(Vector2i(-1, 0)),
	]
	var chunks := renderer.get_chunks_for(hexes)
	assert_eq(chunks.size(), 2, "two chunks; the off-map hex has none")
	assert_true(chunks.has(renderer.get_chunk_for(hexes[0])))
	assert_true(chunks.has(renderer.get_chunk_for(hexes[2])))
	assert_null(renderer.get_chunk_for(hexes[3]))


func test_set_map_again_switches_signals() -> void:
	var old_map := _make_map(8, 8)
	var renderer := _make_renderer(old_map)
	var new_map := _make_map(20, 20)
	renderer.set_map(new_map, _registry)
	assert_eq(old_map.cells_changed.get_connections().size(), 0)
	assert_eq(old_map.layers_changed.get_connections().size(), 0)
	assert_eq(new_map.cells_changed.get_connections().size(), 1)
	assert_eq(old_map.layer_content_changed.get_connections().size(), 0)
	assert_eq(new_map.layer_content_changed.get_connections().size(), 1)
	assert_eq(renderer.get_chunks().size(), 4)


func test_set_view_culls_and_switches_detail() -> void:
	var map := _make_map(64, 64)
	map.fill_layer(_layer_id(map, 0), MapCell.new(&"water"))
	var renderer := _make_renderer(map)
	var first: TerrainChunk = renderer.get_chunks()[0]
	renderer.set_view(first.bounds.grow(-1.0), 1.0)
	assert_true(first.visible)
	var hidden: int = 0
	for chunk: TerrainChunk in renderer.get_chunks():
		if not chunk.visible:
			hidden += 1
	assert_gt(hidden, 10)
	assert_false(renderer.is_low_detail())
	assert_false(first.low_detail)
	renderer.set_view(Rect2(-1e6, -1e6, 2e6, 2e6), 0.05)
	assert_true(renderer.is_low_detail(), "32 px hexes at 5 % are under 4 px")
	for chunk: TerrainChunk in renderer.get_chunks():
		assert_true(chunk.visible and chunk.low_detail)
	renderer.set_map(_make_map(20, 20), _registry)
	assert_true(renderer.get_chunks()[0].low_detail, "new chunks get the current detail level")


func test_low_detail_image_uses_top_visible_layer() -> void:
	var map := _make_map(16, 16)
	var base: int = _layer_id(map, 0)
	var details: int = _layer_id(map, 1)
	map.fill_layer(base, MapCell.new(&"water"))
	var hex: Vector2i = HexCoordinates.even_r_to_axial(Vector2i(3, 2))
	map.set_cell(details, hex, MapCell.new(&"desert"))
	map.set_layer_visible(_layer_id(map, 2), false)
	var chunk: TerrainChunk = _make_renderer(map).get_chunks()[0]
	var image: Image = chunk.build_low_detail_image()
	assert_eq(image.get_size(), Vector2i(16, 16))
	var water: Color = _registry.get_definition(&"water").color
	var desert: Color = _registry.get_definition(&"desert").color
	assert_true(_close(image.get_pixel(3, 2), desert), "upper layer wins")
	assert_true(_close(image.get_pixel(4, 2), water))
	map.set_layer_visible(details, false)
	assert_true(_close(chunk.build_low_detail_image().get_pixel(3, 2), water), "hidden layer ignored")


func test_low_detail_image_is_transparent_where_empty_and_clipped_at_map_edge() -> void:
	var map := _make_map(20, 18)
	var renderer := _make_renderer(map)
	var corner: TerrainChunk = renderer.get_chunk_for(HexCoordinates.even_r_to_axial(Vector2i(17, 17)))
	var image: Image = corner.build_low_detail_image()
	assert_eq(image.get_size(), Vector2i(4, 2), "chunk clipped to the 20 × 18 map")
	assert_eq(image.get_pixel(0, 0).a, 0.0)


func test_low_detail_transform_puts_pixels_on_hexes() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var map := _make_map(40, 40, orientation)
		var renderer := _make_renderer(map)
		for offset: Vector2i in [Vector2i(16, 16), Vector2i(20, 18), Vector2i(23, 21), Vector2i(31, 31)]:
			var hex: Vector2i = HexCoordinates.even_r_to_axial(offset)
			var chunk: TerrainChunk = renderer.get_chunk_for(hex)
			var pixel_center := Vector2(offset - Vector2i(16, 16)) + Vector2(0.5, 0.5)
			var placed: Vector2 = chunk.get_low_detail_transform() * pixel_center
			var error: float = placed.distance_to(map.layout.hex_to_pixel(hex))
			assert_lt(error, map.layout.hex_size.x * 0.5, "%s offset %s within a quarter hex width" % [orientation, offset])
