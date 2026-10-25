# Progress

## Setup — done
- Godot 4.7.2 stable (app launched from the Windows editor; headless tests run from WSL).
- GUT 9.7.1 installed and enabled; headless runner works.
- Renderer: GL Compatibility (2D-only app; no 3D physics engine configured).
- Name: "Hexmer - Map Maker".
- Offset layout decision: even-r (pointy-top); even-q (flat-top) planned.

## Next
- Milestone 1 — Hex grid foundation (coordinate math, rendering, picking, zoom, pan).

## Known issues
- GUT exits 0 when no tests exist ("Nothing was run"); `tests/` arrives with Milestone 1.
