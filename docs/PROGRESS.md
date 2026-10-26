# Progress

## Setup — done
- Godot 4.7.2 stable (app launched from the Windows editor; headless tests run from WSL).
- GUT 9.7.1 installed and enabled; headless runner works.
- Renderer: GL Compatibility (2D-only app; no 3D physics engine configured).
- Name: "Hexmer - Map Maker".
- Offset layout decision: even-r (pointy-top); even-q (flat-top) planned.

## Milestone 1 — Hex grid foundation — done (manual acceptance passed)
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
- [x] Manual acceptance check in the Windows editor.

## Milestone 2 — Sprite painting and layers (in progress)
- [x] Step 1: core map data + terrain library, 65 tests green
  - `TerrainDefinition` (Resource): id, display name, category, placeholder colour, sprite
    variants (wrap on out-of-range index; none → placeholder).
  - `TerrainRegistry`: id → definition, categories, loads `.tres` folders; unknown IDs
    resolve to null so cells keep their logical data.
  - Starter terrains in `resources/terrain/` (grassland, forest, mountains, water, desert,
    snow): colours only, no sprite art yet.
  - `MapData`: grid, layout, `map_seed`, ordered layers (index 0 = bottom) with
    add/insert/remove/move/rename/visible/locked; per-layer sparse cells; `set_cells()`
    batches edits into one `cells_changed` signal. `MapData.create_default()` adds the six
    spec layers. `MapCell` (terrain_id + variant) is immutable by convention.
- [ ] Step 2: `EditCommand` + undo stack; paint/erase commands storing only affected cells.
- [ ] Step 3: chunked terrain renderer (sprite or placeholder colour, per visible layer).
- [ ] Step 4: terrain palette, paint/erase tools (drag = one undo step), undo/redo shortcuts.
- [ ] Step 5: layer panel (create, rename, hide, lock, reorder, delete).
- [ ] Step 6: selection tool (single, group, rectangle), then fill.
- Open question: sprite art for the "multi-sprite map" acceptance (user-supplied pack vs.
  generated placeholder PNGs).

## Known issues
- Bounds are always even-r. Flat-top maps therefore come out slanted, not rectangular,
  until even-q is added.
- Touchpad pinch/pan gestures (`InputEventMagnifyGesture` / `InputEventPanGesture`) are not
  handled yet; touchpad scrolling works as wheel zoom.
- `MapData` is not wired into the main scene yet (step 3/4).
- GDScript consts can't use `PackedStringArray(...)` constructors; use typed `Array[String]`.
- The layout enum is `HexLayout.HexOrientation`; plain `Orientation` clashes with Godot's
  global `Orientation` enum.
