# Progress

## Setup — done
- Godot 4.7.2 stable (app launched from the Windows editor; headless tests run from WSL).
- GUT 9.7.1 installed and enabled; headless runner works.
- Renderer: GL Compatibility (2D-only app; no 3D physics engine configured).
- Name: "Hexmer - Map Maker".
- Offset layout decision: even-r (pointy-top); even-q (flat-top) planned.

## Milestone 1 — Hex grid foundation (in progress)
- [x] Step 1: core hex math (`scripts/core/`), 22 tests green
  - `HexCoordinates`: axial↔cube, cube rounding, distance, neighbours, lines, even-r offset.
  - `HexLayout`: pointy/flat orientation, hex size, origin; hex↔pixel, corners.
  - `HexGrid`: finite width × height bounds in even-r offset space.
- [x] Step 2: chunked grid renderer + main scene, 28 tests green
  - `HexMapRenderer` splits the map into 16 × 16 offset-cell `HexGridChunk`s (49 nodes for
    100 × 100); each chunk draws its outlines with one `draw_multiline` call.
  - `HexGrid.cells_in_offset_rect()` for chunk queries.
  - `scenes/main/main.tscn` (set as main scene): 100 × 100 pointy-top grid, camera fitted
    to the map. Map size/orientation/hex size are exports on the Main node.
- [x] Step 3: viewport camera, 37 tests green
  - `MapCamera` (`scripts/ui/map_camera.gd`): wheel zoom toward cursor (clamped 1 %–800 %),
    middle-drag or Space + left-drag pan, Home fits the map.
  - InputMap actions in project.godot: `camera_zoom_in/out`, `camera_pan`,
    `camera_pan_hold`, `camera_fit`, `editor_primary` (left click, for tools).
- [x] Step 4a: hover/click picking + status bar, 48 tests green
  - `EditorController` (`scripts/tools/`): hovered/selected hex from map-space positions,
    `hovered_changed` / `selected_changed` signals. Clicking off the map clears the selection.
  - `HexHighlight` (`scripts/rendering/`): hover (white) and selection (amber) outlines,
    constant on-screen width at any zoom.
  - `StatusBar` (`scenes/editor/status_bar.tscn`): hovered hex, selected hex (axial +
    even-r offset), map size/orientation, zoom %.
  - `test_main_scene.gd` checks the acceptance criteria headless: 100 × 100 map loads, and
    clicking identifies hexes (corners included) in both orientations.
- [x] Step 4b: map settings panel, 52 tests green
  - `MapSettingsPanel` (`scenes/editor/map_settings_panel.tscn`, top-right): width/height
    (1–1000), orientation, hex size (4–256 px), Apply → `settings_applied` signal.
  - `Main.rebuild_map()` swaps in a new grid/layout, redraws, refits the camera and
    updates the status bar. `EditorController.set_map()` clears hover and selection.
  - Renderer frees old chunks immediately (no orphan nodes after a rebuild).
- [ ] Manual acceptance check in the Windows editor (navigate 100 × 100, click-identify
      hexes, change map settings) → Milestone 1 done. Next: Milestone 2.

## Known issues
- Bounds are always even-r. Flat-top maps therefore come out slanted, not rectangular,
  until even-q is added.
- Touchpad pinch/pan gestures (`InputEventMagnifyGesture` / `InputEventPanGesture`) are not
  handled yet; touchpad scrolling works as wheel zoom.
- The layout enum is `HexLayout.HexOrientation`; plain `Orientation` clashes with Godot's
  global `Orientation` enum.
