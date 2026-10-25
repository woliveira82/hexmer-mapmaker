extends GutTest

const StatusBarScene: PackedScene = preload("res://scenes/editor/status_bar.tscn")


func test_format_helpers() -> void:
	assert_eq(StatusBar.format_hex(Vector2i(0, 1)), "(0, 1)  [col 1, row 1]")
	assert_eq(StatusBar.format_orientation(HexLayout.HexOrientation.POINTY_TOP), "pointy-top")
	assert_eq(StatusBar.format_orientation(HexLayout.HexOrientation.FLAT_TOP), "flat-top")
	assert_eq(StatusBar.format_zoom(0.254), "25%")
	assert_eq(StatusBar.format_zoom(2.0), "200%")


func test_fields_update() -> void:
	var bar: StatusBar = StatusBarScene.instantiate()
	add_child_autofree(bar)
	bar.set_hover(Vector2i(3, -1), true)
	bar.set_selected(Vector2i.ZERO, false)
	bar.set_map_info(100, 80, HexLayout.HexOrientation.FLAT_TOP)
	bar.set_zoom(0.5)
	var texts: PackedStringArray = bar.get_texts()
	assert_string_contains(texts[0], "(3, -1)")
	assert_string_contains(texts[1], StatusBar.NO_HEX_TEXT)
	assert_string_contains(texts[2], "100 × 80 flat-top")
	assert_string_contains(texts[3], "50%")
	bar.set_hover(Vector2i.ZERO, false)
	assert_string_contains(bar.get_texts()[0], StatusBar.NO_HEX_TEXT)
