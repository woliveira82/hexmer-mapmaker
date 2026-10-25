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
- [ ] Step 2: chunked grid renderer (`scripts/rendering/hex_map_renderer.gd`), no Node per hex.
- [ ] Step 3: main scene + viewport camera: zoom to cursor, middle/space-drag pan (InputMap).
- [ ] Step 4: hover/click picking, status bar (axial coords, map size, zoom %),
      grid size/orientation settings. Acceptance: navigate 100 × 100, click identifies a hex.

## Known issues
- Bounds are always even-r. Flat-top maps therefore come out slanted, not rectangular,
  until even-q is added.
- The layout enum is `HexLayout.HexOrientation`; plain `Orientation` clashes with Godot's
  global `Orientation` enum.
