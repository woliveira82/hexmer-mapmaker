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
- [ ] Step 3: viewport camera: zoom to cursor, middle/space-drag pan (InputMap).
- [ ] Step 4: hover/click picking, status bar (axial coords, map size, zoom %),
      grid size/orientation settings. Acceptance: navigate 100 × 100, click identifies a hex.

## Known issues
- Bounds are always even-r. Flat-top maps therefore come out slanted, not rectangular,
  until even-q is added.
- The layout enum is `HexLayout.HexOrientation`; plain `Orientation` clashes with Godot's
  global `Orientation` enum.
