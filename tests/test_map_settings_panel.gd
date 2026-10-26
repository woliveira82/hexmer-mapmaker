extends GutTest

const PanelScene: PackedScene = preload("res://scenes/editor/map_settings_panel.tscn")


func _make_panel() -> MapSettingsPanel:
	var panel: MapSettingsPanel = PanelScene.instantiate()
	add_child_autofree(panel)
	return panel


func test_apply_emits_shown_settings() -> void:
	var panel := _make_panel()
	panel.set_settings(40, 30, HexLayout.HexOrientation.FLAT_TOP, 24.0)
	watch_signals(panel)
	panel.apply()
	assert_signal_emitted_with_parameters(
		panel, "settings_applied", [40, 30, HexLayout.HexOrientation.FLAT_TOP, 24.0]
	)


func test_values_are_clamped_to_limits() -> void:
	var panel := _make_panel()
	panel.set_settings(0, 5000, HexLayout.HexOrientation.POINTY_TOP, 1000.0)
	watch_signals(panel)
	panel.apply()
	assert_signal_emitted_with_parameters(panel, "settings_applied", [
		MapSettingsPanel.MIN_DIMENSION, MapSettingsPanel.MAX_DIMENSION,
		HexLayout.HexOrientation.POINTY_TOP, MapSettingsPanel.MAX_HEX_SIZE,
	])
