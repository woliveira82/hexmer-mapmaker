# Hexmer - Map Maker — Godot 4.x Hexagonal Map Creator

Product definition and implementation brief for an AI coding agent.

A desktop-first 2D hex map editor for manually painting terrain, arranging sprite layers, generating procedural worlds, and exporting high-resolution maps. Designed as an alternative to tools such as Hexton, Hexer, Hexml, and Hexroll.

| | |
|---|---|
| **Engine** | Godot 4.x |
| **Language** | GDScript |
| **Platforms** | Windows, Linux, macOS |
| **Core workflows** | Manual editing + seeded procedural generation |
| **Primary output** | Editable project, PNG export, JSON map data |

> **PRODUCT GOAL**
> Build a real, runnable editor — not only a mockup. Prioritize correct hex coordinates, reliable painting, robust save/load, and editable procedural output before adding advanced features.

*Application name: Hexmer - Map Maker. The visual direction may be changed by the project owner.*

---

## Document overview

1. Product vision and user experience
2. Main application layout
3. Functional requirements
4. Map data and project structure
5. Saving, loading, and export
6. Architecture and implementation rules
7. Milestones and acceptance criteria
8. MVP scope and future features
9. Definition of done and agent instructions

---

## 1. Product vision

- **Application name:** Hexmer - Map Maker
- **Engine:** Godot 4.x
- **Language:** GDScript
- **Primary platform:** Windows, Linux, and macOS desktop
- **Map type:** 2D hexagonal maps with configurable orientation, dimensions, terrain, and sprite layers.

The application should let users create attractive, large-scale hex maps without manually drawing every tile. It combines a visual map editor with procedural world generation. Maps remain editable after generation; generation is a starting point rather than a locked, one-click output.

### Core workflows

- **Manual map creation:** paint, erase, replace, and customize individual hexes with a mouse.
- **Procedural generation:** generate maps or selected regions from a seed, biome rules, terrain distributions, and generation parameters.
- **Sprite composition:** combine terrain, objects, roads, rivers, settlements, and annotations on separate layers.
- **Export:** save an editable project and render a high-resolution image for tabletop RPGs, campaign planning, worldbuilding, or game development.

---

## 2. Main application layout

Build a professional desktop interface inspired by 2D game engines and digital painting applications. The map viewport should be the dominant workspace.

| Area | Responsibilities |
|---|---|
| Top menu and toolbar | Project management, undo/redo, generation, view settings, export. |
| Left tool panel | Paint, erase, fill, selection, terrain sampling, object placement, region tools. |
| Central map viewport | Interactive hex grid, zoom, pan, hover feedback, tile selection. |
| Right inspector | Properties for selected tile, terrain, object, layer, or generation settings. |
| Bottom status panel | Coordinates, map dimensions, active layer, zoom percentage, diagnostics. |

Panels should be resizable and dockable if practical. Provide clear hover and selection states, keyboard shortcuts, and predictable mouse behavior.

### Recommended interaction defaults

- Left-click paints with the active tool; click-and-drag paints continuously.
- Middle-click or space-drag pans the map.
- Mouse wheel zooms toward the cursor position.
- Hovering a tile displays its axial coordinates and relevant properties.
- Shortcuts should be configurable rather than hard-coded into UI logic.

---

## 3. Functional requirements

### 3.1 Hexagonal grid engine

Implement a proper hex-coordinate system rather than treating hexes as square tiles with decorative borders.

- Support pointy-top and flat-top hexagons.
- Use axial coordinates `(q, r)` as the primary logical coordinate system.
- Implement conversions between axial coordinates, cube coordinates, screen positions, and offset coordinates where needed.
- Provide accurate mouse-to-hex picking and coordinate display.
- Render grid outlines independently of terrain sprites.
- Support configurable hex dimensions, zoom, camera panning, and finite map dimensions.
- Keep map data independent of camera position and zoom.
- Use cube coordinates internally for distance calculations and hex-line algorithms where useful.

> **Implementation note:** Do not depend on square-grid `TileMapLayer` behavior to define the map logic. Use a dedicated hex-grid abstraction, using Godot rendering nodes, custom drawing, or a suitable tile-rendering layer.

### 3.2 Terrain and sprite library

The map should be built from reusable sprites representing terrain types and environmental features. Support original, user-supplied, or appropriately licensed art; do not lock the application to one visual style or bundled pack.

- Support PNG and WebP assets, including transparent backgrounds where appropriate.
- Organize sprite collections into named categories.
- Allow multiple visual variants for a single terrain type.
- Support optional terrain transitions and edge sprites.
- Allow random rotation, mirroring, variant selection, per-sprite offsets, and scale.
- Show sprite previews and terrain names in the palette.
- Allow users to import asset folders.
- Provide missing-asset warnings without losing logical terrain data.

#### Suggested starter terrain categories

| Category | Example content |
|---|---|
| Grassland | Plains, meadows, hills, fields. |
| Forest | Deciduous forest, pine forest, dense woodland. |
| Mountains | Hills, peaks, cliffs, rocky terrain. |
| Water | Oceans, lakes, rivers, marshes. |
| Desert | Sand, dunes, badlands, dry terrain. |
| Snow and tundra | Ice, snowfields, frozen mountains. |

### 3.3 Layer system

| Layer | Purpose |
|---|---|
| Base terrain | Grass, water, desert, snow, and similar ground. |
| Terrain details | Ground textures, terrain variants, transitions. |
| Natural objects | Trees, rocks, vegetation, resource nodes. |
| Infrastructure | Roads, bridges, rivers, paths. |
| Settlements | Houses, towns, castles, ruins. |
| Annotations | Labels, markers, text, symbols. |
| Grid overlay | Hex boundaries, coordinates, selection highlights. |

Users must be able to create, rename, hide, lock, reorder, and delete layers. Every layer is saved with the project. Hiding the grid must not change the underlying terrain data.

### 3.4 Editing tools

- **Paint:** apply selected terrain or objects to individual hexes.
- **Brush:** paint multiple adjacent hexes with configurable radius.
- **Erase:** remove content from the active layer without affecting other layers.
- **Fill:** fill a connected region with selected terrain.
- **Replace:** replace matching terrain globally or within a selection.
- **Picker:** sample terrain or a sprite from an existing hex.
- **Selection:** select one hex, a group of hexes, or a rectangular region.
- **Move and copy:** duplicate or relocate selected content.
- **Randomize:** apply sprite variants or terrain changes to a selected area.
- **Undo and redo:** reverse edits without corrupting project state.

### 3.5 Procedural map generation

Provide a generation panel with controls for:

- random seed
- map dimensions
- land-to-water ratio
- continent count and size
- mountain density
- forest density
- river and lake frequency
- terrain smoothness
- biome distribution
- optional temperature and moisture
- random variation intensity

#### Recommended generation pipeline

| Step | Operation |
|---|---|
| 1 | Configure seed and map size |
| 2 | Generate elevation field |
| 3 | Classify land and water |
| 4 | Generate temperature and moisture |
| 5 | Assign biomes |
| 6 | Generate mountains and hills |
| 7 | Generate rivers and lakes |
| 8 | Place forests and terrain details |
| 9 | Apply sprite variants |
| 10 | Preview, then commit to editable map |

Use separate generation passes rather than assigning a completely random terrain type to every hex. For the first version, use seeded noise fields, elevation thresholds, neighborhood rules, and biome lookup tables. More advanced algorithms can be added later.

> **Non-destructive by default:** preview generated results before committing them. Preserve existing manual edits unless the user explicitly chooses to replace them.

### 3.6 Biome system

Allow users to define custom biomes with rules for terrain and object placement. Each biome definition should specify allowed terrain types, terrain probabilities, elevation ranges, temperature and moisture ranges, and permitted environmental objects.

- **Temperate forest:** grassland, trees, hills, rivers.
- **Desert:** sand, dunes, rock, sparse vegetation.
- **Tundra:** snow, ice, rock, sparse trees.
- **Tropical jungle:** dense vegetation, wetlands, rivers.
- **Volcanic region:** dark rock, lava, ash, volcanic peaks.

The same generator should support fantasy, historical, science-fiction, and modern settings.

---

## 4. Map data and project structure

Keep project data separate from rendering and UI code. A map stores dimensions, grid orientation, coordinate settings, random seed, layers, and metadata. Each cell stores its terrain identifier and any additional data required by the layer system.

### Recommended initial folder structure

```
hexmer-mapmaker/
├── project.godot
├── scenes/
│   ├── main/main.tscn
│   ├── editor/
│   │   ├── map_editor.tscn
│   │   ├── map_viewport.tscn
│   │   ├── terrain_palette.tscn
│   │   ├── layer_panel.tscn
│   │   └── inspector_panel.tscn
│   └── dialogs/
├── scripts/
│   ├── core/
│   │   ├── hex_coordinates.gd
│   │   ├── hex_grid.gd
│   │   ├── map_data.gd
│   │   └── map_serializer.gd
│   ├── rendering/
│   │   ├── hex_map_renderer.gd
│   │   └── sprite_resolver.gd
│   ├── tools/
│   │   ├── paint_tool.gd
│   │   ├── erase_tool.gd
│   │   ├── fill_tool.gd
│   │   └── selection_tool.gd
│   ├── generation/
│   │   ├── map_generator.gd
│   │   ├── elevation_generator.gd
│   │   ├── biome_generator.gd
│   │   └── river_generator.gd
│   └── ui/
├── resources/
│   ├── terrain/
│   ├── biomes/
│   └── sprite_packs/
├── tests/
└── docs/
```

### Illustrative logical tile record

```json
{
  "q": 12,
  "r": 8,
  "terrain_id": "grassland",
  "variant": 2,
  "elevation": 0.62,
  "moisture": 0.71,
  "temperature": 0.54
}
```

This is an example, not a requirement that every tile store every field. Generation fields can be stored separately if they are not needed for manual editing. Store terrain and sprite definitions as reusable Godot Resources or equivalent data assets; avoid duplicating sprite data in every cell.

### Recommended core modules

| Module | Responsibility |
|---|---|
| `HexCoordinates` | Coordinate mathematics and conversions. |
| `MapData` | Logical map, cells, and layer content. |
| `HexMapRenderer` | Terrain, sprites, and overlays. |
| `MapGenerator` | Generate map data without UI dependencies. |
| `EditorController` | Coordinate tools, selection, and user actions. |
| `MapSerializer` | Load and save project files. |
| `TerrainRegistry` | Resolve terrain IDs to resource definitions. |

---

## 5. Saving, loading, and export

### 5.1 Native project format

Use a versioned, human-readable project format, preferably JSON for the first version. Save:

- Map dimensions and hex orientation.
- Terrain and object layers, cell data, and layer visibility.
- Sprite pack references.
- Biome and generator settings, seed, and reproducibility settings.
- Annotations and map metadata.
- Camera and editor preferences where appropriate.

Support New, Open, Save, Save As, and recovery from invalid or incompatible project files. When an external sprite is missing, preserve logical terrain data and display a placeholder rather than silently deleting tiles.

### 5.2 Export formats

| Priority | Format | Requirements |
|---|---|---|
| 1 | PNG | Full-resolution map image. |
| 2 | Transparent PNG | Optional transparent background where appropriate. |
| 3 | JSON | Map data for external tools and scripts. |
| 4 | SVG (optional) | Vector-style export for grid lines, labels, and supported flat-color maps. |
| 5 | Godot scene/resource (later) | Use a map inside another Godot game. |

Export settings should include scale, visible layers, grid visibility, background color, labels, and output dimensions. For large maps, render off-screen or in chunks instead of relying on the visible viewport resolution.

---

## 6. Architecture and implementation rules

- **Separation of concerns:** coordinate math, map data, rendering, generation, serialization, and UI must be distinct modules.
- **Signals and interfaces:** prefer signals and explicit method calls over tight coupling between UI nodes.
- **Performance:** avoid one independent scene node per hex on large maps; use batched drawing, custom rendering, or chunk-based rendering where appropriate.
- **Sprite objects:** use separate render batches or scene nodes where they make sense.
- **Determinism:** use seeded random number generation for procedural content. UI operations such as zooming or selecting a tile must not alter generation results.
- **Undo/redo:** use reversible commands or compact snapshots of affected map data. Do not copy an entire large map for every brush stroke.
- **Maintainability:** use typed GDScript where practical, clear naming, small testable methods, and documented data formats.

Keep the generator independent of UI nodes. Terrain definitions should be data-driven, and map rendering should consume logical map data rather than own it.

---

## 7. Implementation milestones

### Milestone 1 — Hex grid foundation
- Implement coordinate math, rendering, mouse picking, zoom, pan, and configurable grid dimensions.
- **Acceptance:** navigate a map of at least 100 × 100 hexes and reliably identify a hex by clicking it.

### Milestone 2 — Sprite painting and layers
- Add terrain resources, palette, painting, erasing, selection, and layer management.
- **Acceptance:** create a multi-sprite map, edit separate layers, and undo/redo changes.

### Milestone 3 — Project persistence
- Implement save/load, resource references, error handling, and PNG export.
- **Acceptance:** saving and reopening preserves terrain, sprites, layers, and settings.

### Milestone 4 — Procedural generation
- Add seeded elevation, water, biomes, mountains, rivers, and forest generation.
- **Acceptance:** the same seed and settings reproduce the same map, and the result remains editable.

### Milestone 5 — Polish and extensibility
- Add sprite pack importing, terrain variants, object placement, performance optimization, shortcuts, and advanced export.
- **Acceptance:** users can work with large maps, reuse custom asset packs, and export high-resolution images.

---

## 8. MVP scope versus future features

| Feature | MVP | Later |
|---|---|---|
| Hex grid and coordinates | Required | Advanced coordinate overlays |
| Terrain sprite palette | Required | Asset pack manager |
| Paint, erase, fill | Required | Advanced selection tools |
| Layers | Basic | Groups and blend modes |
| Seeded generation | Basic elevation and biomes | Climate, plate tectonics, advanced rivers |
| Save and load | Required | Autosave and version migration |
| PNG export | Required | SVG, tiled exports, animation |
| Sprite variants | Basic | Automatic edge transitions |
| Labels and markers | Basic | Rich annotation system |
| External integration | JSON | Game-engine and campaign integrations |

Keep the first version small enough to complete while making architectural choices that support expansion. Do not implement every advanced feature before the core editor works.

---

## 9. Definition of done

The first usable release is complete when a user can:

- Create a new hex map with configurable dimensions and orientation.
- Import and organize different terrain sprites.
- Paint, erase, fill, select, and replace hexes.
- Create and manage separate terrain and object layers.
- Generate terrain using a seed and biome settings.
- Edit generated maps manually.
- Undo and redo editing operations.
- Save and reopen the native project without losing content.
- Export a clean, high-resolution PNG.
- Work with large maps without severe interaction or rendering slowdowns.

> The project must launch and run in Godot 4.x without missing scripts, unresolved resource references, or placeholder buttons presented as finished functionality.

---

## Final instruction for the coding agent

Build a complete, modular 2D hex map editor in Godot 4.x using GDScript. Treat this specification as the product requirements.

Begin with a working hex-grid engine, coordinate conversion, map renderer, and mouse interaction. Then implement sprite-based terrain painting, layers, saving/loading, and procedural generation in the milestone order above.

Use a data-driven architecture, reusable terrain resources, deterministic generation, and an undoable editing system. Build an attractive desktop interface with a central map viewport, terrain palette, editing tools, layer panel, and inspector.

Deliver actual runnable Godot scenes and scripts, not just a design document or a visual prototype. Include sample terrain assets or clearly documented asset-import instructions, a sample project, and basic tests for coordinate conversion, tile picking, serialization, and deterministic generation.

Prioritize correctness and usability over feature count. Every visible tool must either work or be explicitly marked as not yet implemented.

> **Recommended starting point:** complete Milestones 1–3 first. Once users can reliably paint, save, reopen, and export a hex map, procedural generation can be added without destabilizing the core editor.
