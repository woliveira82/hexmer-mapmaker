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
- [x] Step 2: undo/redo, 75 tests green
  - `EditCommand` (`scripts/tools/`): `do()` / `undo()` / `is_empty()` / `get_description()`.
  - `SetCellsCommand`: before/after of only the affected hexes on one layer.
    `paint()` / `erase()` factories skip out-of-bounds and unchanged hexes and return an
    empty command on locked or missing layers. `merge()` folds a drag stroke into one step.
  - `UndoStack`: `execute()`, `push_done()` (for strokes applied live), undo/redo,
    redo cleared on new edits, `max_size` (200), `changed` signal, descriptions.
  - Tests: round trips, layer isolation, locked layers, merged strokes, 40 random edits
    undone/redone back to identical snapshots.
- [x] Step 3: chunked terrain renderer, 87 tests green
  - `TerrainRenderer` + `TerrainChunk` (`scripts/rendering/`): 16 × 16 offset-cell chunks
    under the grid. Each chunk draws visible layers bottom first; per layer, one
    `RenderingServer.canvas_item_add_triangle_array` call per texture plus one for
    textureless hexes. Sprites are UV-mapped onto the hex (works for both orientations).
  - Placeholders: definition colour when a terrain has no sprites; magenta for unknown IDs
    (cell data kept).
  - `cells_changed` redraws only the touched chunks; `layers_changed` redraws all.
  - `MapData.fill_layer()`. `Main` owns `MapData` + `TerrainRegistry`; new maps (and
    Map settings → Apply) fill the base layer with `default_terrain` (grassland).
- [ ] **Manual check in the Windows editor:** grassland sprites under the grid outlines,
      both orientations, after Apply. (Step 3; not yet reported.)
- [x] Step 4: palette, paint/erase, undo/redo, 107 tests green
  - `EditorController` now takes `MapData` + `TerrainRegistry` (`grid`/`layout` are
    getters). Owns the `UndoStack`, `active_tool` (SELECT/PAINT/ERASE), `active_terrain`,
    `active_layer_id` (bottom layer until the layer panel exists).
  - Strokes: `primary_pressed/dragged/released`; drags fill gaps with `HexCoordinates.line`;
    each hex is painted once per stroke; a stroke is one undo step. Painting a hex that
    already has the active terrain keeps its variant. New hexes get a random sprite variant.
    Undo/redo or switching tool mid-stroke ends the stroke first. `set_map` clears history.
  - `TerrainPalette` (`scenes/editor/terrain_palette.tscn`, top-left): Select/Paint/Erase,
    Undo/Redo (disabled when unavailable, tooltips name the edit + shortcut), terrain list
    with sprite icons (colour swatch if no sprite). Picking a terrain switches to Paint.
    Palette controls take no keyboard focus (Space would press them; list search would eat
    B/E/S). Clicking the map releases focus from panel fields.
  - InputMap: `edit_undo` Ctrl+Z, `edit_redo` Ctrl+Y / Ctrl+Shift+Z, `tool_select` S,
    `tool_paint` B, `tool_erase` E (logical keys, matched exactly).
  - Mouse release is caught in `_input`, so a stroke ends even if released over a panel.
- [ ] **Manual check in the Windows editor:** paint/erase strokes, fast drags, undo/redo
      buttons + shortcuts, palette layout at the default 1152 × 648 window.
- [ ] Step 5: layer panel (create, rename, hide, lock, reorder, delete).
- [ ] Step 6: selection tool (single, group, rectangle), then fill.
- [x] Placeholder sprites: 64 × 64 PNGs, two variants per starter terrain, in
  `resources/sprite_packs/placeholder/`, linked as `variants` in each terrain `.tres`.
  Generated deterministically by `tools/generate_placeholder_sprites.gd`
  (`godot --headless --path . -s res://tools/generate_placeholder_sprites.gd`, then `--import`).
  Square, orientation-agnostic textures: the renderer should UV-map them onto the hex polygon.

## Known issues
- Bounds are always even-r. Flat-top maps therefore come out slanted, not rectangular,
  until even-q is added.
- Touchpad pinch/pan gestures (`InputEventMagnifyGesture` / `InputEventPanGesture`) are not
  handled yet; touchpad scrolling works as wheel zoom.
- Dragging across a panel pauses the stroke; re-entering the map joins the two points with
  a line, which can paint hexes hidden under the panel.
- Hover does not show the hex's terrain in the status bar yet.
- Large maps are slow: create + first draw takes ~0.1 s at 100 × 100, ~1 s at 300 × 300,
  ~12 s and ~140 MB at 1000 × 1000 (headless timing). Layer visibility/order changes redraw
  every chunk (~9 s at 1000 × 1000). Options: build batches only for on-screen chunks,
  cache batches per layer, or a lower size limit.
- GDScript consts can't use `PackedStringArray(...)` constructors; use typed `Array[String]`.
- The layout enum is `HexLayout.HexOrientation`; plain `Orientation` clashes with Godot's
  global `Orientation` enum.
