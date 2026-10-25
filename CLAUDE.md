# Hexmer - Map Maker — instructions for Claude

Hexmer - Map Maker is a desktop 2D hex map editor built with **Godot 4.x** and **typed GDScript**.
The full product spec lives in `docs/SPEC.md` (the original spec PDF converted to Markdown).
Read it before starting any milestone. Current progress lives in `docs/PROGRESS.md`.

## Golden rules
- Build a runnable app, not a mockup. Every visible button/tool either works or is
  clearly disabled and labelled "Not yet implemented".
- Work milestone by milestone (see `docs/SPEC.md` §7). Do not start a milestone until
  the previous one passes its acceptance criteria and its tests are green.
- Small, reviewable steps: one feature per task, run tests, then stop and summarise.
- Never invent Godot APIs. If unsure whether a method exists in Godot 4.x, check the
  official docs or ask. Godot 3 syntax (`export var`, `onready var`, `yield`,
  `KinematicBody2D`, etc.) is forbidden.

## Architecture (strict separation of concerns)
- `scripts/core/` — pure data + math. No Node, no UI. `HexCoordinates`, `HexGrid`,
  `MapData`, `MapSerializer`, `TerrainRegistry`. Must be fully unit-testable.
- `scripts/rendering/` — consumes `MapData`, never owns it. Batched/chunked drawing;
  **never one Node per hex**.
- `scripts/tools/` — editor tools. Each edit goes through a reversible command
  (`EditCommand` with `do()` / `undo()`) that stores only the affected cells.
- `scripts/generation/` — no UI dependencies. Deterministic: all randomness from a
  seeded `RandomNumberGenerator` / `FastNoiseLite` created from the map seed.
- `scripts/ui/` + `scenes/` — UI talks to the controller via signals and explicit calls.
- Terrain, biome and sprite definitions are data-driven `Resource`s in `resources/`.
  Cells store IDs, not sprite data.

## Hex conventions (do not change without updating tests)
- Primary logical coordinates: **axial (q, r)**. Cube (q, r, s=-q-r) for distance/lines.
- Support pointy-top and flat-top orientations via a layout object.
- Cell keys: `Vector2i(q, r)`.
- Rectangular map bounds use offset coordinates: **even-r** (pointy-top) for now; even-q
  (flat-top) is planned. Keep offset conversion behind the layout object so it can be added.
- Do not use TileMapLayer's square-grid logic to define map logic.

## Code style
- Typed GDScript everywhere practical: `var x: int`, `func f(a: float) -> Vector2i:`.
- `class_name` for reusable classes; snake_case files; PascalCase classes.
- Small methods; doc comments (`##`) on public methods.
- No magic numbers in UI code; shortcuts go through the InputMap, not hard-coded keys.

## Commands
- Import / check project loads: `godot --headless --path . --import`
- Run all tests (GUT): `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- Run the app: launched by the user from the **Windows** Godot editor. Claude runs only the
  headless import/tests from WSL. If the Windows and Linux builds disagree over the
  `.godot/` cache, re-run the import.
Always run the tests after changing anything in `scripts/core/` or `scripts/generation/`,
and fix failures before reporting a task as done.

## Tests (required)
Located in `tests/`, prefixed `test_`. Must cover at minimum:
coordinate conversions & round-trips, pixel→hex picking (both orientations),
neighbours/distance, serialization round-trip, undo/redo, deterministic generation
(same seed + settings ⇒ identical MapData).

## Project file format
Versioned JSON (`"format_version"`). Missing sprites must keep logical terrain data and
render a placeholder. Loading an invalid file shows an error; it never crashes or
silently drops data. Document the format in `docs/FILE_FORMAT.md` when it changes.

## When finishing a task
1. Tests green, project imports with no errors or missing resources.
2. Update `docs/PROGRESS.md` (what's done, what's next, known issues).
3. Give a short summary and suggest a commit message. Do not commit unless asked.
