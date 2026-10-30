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


func test_set_view_hides_chunks_outside_and_far_zoom_hides_grid() -> void:
	var renderer := _make_renderer(64, 64, 16)
	var first: HexGridChunk = renderer.get_chunks()[0]
	renderer.set_view(first.bounds.grow(-1.0), 1.0)
	var shown: Array[HexGridChunk] = []
	for chunk: HexGridChunk in renderer.get_chunks():
		if chunk.visible:
			shown.append(chunk)
	assert_true(shown.has(first))
	assert_lt(shown.size(), 16, "most chunks hidden")
	assert_true(renderer.visible)
	renderer.set_map(HexGrid.new(64, 64), HexLayout.new())
	assert_true(renderer.get_chunks()[0].visible, "view kept after set_map")
	assert_false(renderer.get_chunks()[15].visible, "view kept after set_map")
	renderer.set_view(renderer.get_map_rect(), 0.05)
	assert_false(renderer.visible, "32 px hexes at 5 % are under min_hex_pixels")


func test_outlines_are_built_only_when_drawn() -> void:
	var renderer := _make_renderer(64, 64, 16)
	var first: HexGridChunk = renderer.get_chunks()[0]
	var last: HexGridChunk = renderer.get_chunks()[15]
	renderer.set_view(first.bounds.grow(-1.0), 1.0)
	assert_false(first.is_built())
	await wait_process_frames(2)
	assert_true(first.is_built(), "visible chunk drawn")
	assert_false(last.is_built(), "hidden chunk never built")
