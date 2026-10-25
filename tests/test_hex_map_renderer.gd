extends GutTest


func _make_renderer(width: int, height: int, chunk_size: int) -> HexMapRenderer:
	var renderer := HexMapRenderer.new()
	renderer.chunk_size = chunk_size
	add_child_autofree(renderer)
	renderer.set_map(HexGrid.new(width, height), HexLayout.new())
	return renderer


func test_chunks_cover_every_hex_once() -> void:
	var renderer := _make_renderer(100, 100, 16)
	var chunks: Array[HexGridChunk] = renderer.get_chunks()
	assert_eq(chunks.size(), 49, "ceil(100/16)^2 chunks, not one node per hex")
	var total: int = 0
	for chunk: HexGridChunk in chunks:
		total += chunk.hex_count()
	assert_eq(total, 10000)


func test_map_rect_contains_all_hex_centres() -> void:
	var renderer := _make_renderer(9, 7, 4)
	var layout := HexLayout.new()
	var rect: Rect2 = renderer.get_map_rect()
	for hex: Vector2i in HexGrid.new(9, 7).cells():
		assert_true(rect.has_point(layout.hex_to_pixel(hex)), "rect contains %s" % hex)


func test_set_map_again_replaces_chunks() -> void:
	var renderer := _make_renderer(40, 40, 16)
	renderer.set_map(HexGrid.new(10, 10), HexLayout.new())
	assert_eq(renderer.get_chunks().size(), 1)
