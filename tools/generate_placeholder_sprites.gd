extends SceneTree
## Dev tool: writes the placeholder terrain sprites to [constant OUTPUT_DIR].
## Deterministic (fixed seeds), so re-running reproduces the same files.
## Run: godot --headless --path . -s res://tools/generate_placeholder_sprites.gd

const OUTPUT_DIR: String = "res://resources/sprite_packs/placeholder"
const SIZE: int = 64
const VARIANTS: int = 2
const TERRAINS: Array[String] = ["grassland", "forest", "mountains", "water", "desert", "snow"]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for t: int in TERRAINS.size():
		for v: int in VARIANTS:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 * (t + 1) + v
			var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
			call("_draw_" + TERRAINS[t], image, rng)
			var path: String = OUTPUT_DIR.path_join("%s_%d.png" % [TERRAINS[t], v])
			var error: Error = image.save_png(ProjectSettings.globalize_path(path))
			print("%s: %s" % [path, error_string(error)])
	quit()


# --- Terrains -------------------------------------------------------------------------------

func _draw_grassland(image: Image, rng: RandomNumberGenerator) -> void:
	_fill_speckled(image, rng, Color(0.50, 0.72, 0.33), 0.06)
	for i: int in 26:
		var p := _random_point(rng, 4)
		var tuft: Color = Color(0.36, 0.58, 0.22) if rng.randf() < 0.6 else Color(0.66, 0.84, 0.42)
		_line(image, p, p + Vector2i(-1, -3), tuft)
		_line(image, p, p + Vector2i(1, -3), tuft)
	for i: int in 3:
		_disc(image, _random_point(rng, 10), 1, Color(0.97, 0.90, 0.45))


func _draw_forest(image: Image, rng: RandomNumberGenerator) -> void:
	_fill_speckled(image, rng, Color(0.20, 0.42, 0.20), 0.05)
	var trees: Array[Vector2i] = []
	for i: int in 7:
		trees.append(_random_point(rng, 12))
	trees.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
	for p: Vector2i in trees:
		var radius: int = rng.randi_range(6, 9)
		_rect(image, Rect2i(p.x - 1, p.y + radius - 3, 3, 5), Color(0.36, 0.24, 0.14))
		_disc(image, p, radius, Color(0.10, 0.28, 0.12))
		_disc(image, p, radius - 1, Color(0.16, 0.48, 0.20))
		_disc(image, p + Vector2i(-radius / 3, -radius / 3), radius / 3, Color(0.30, 0.62, 0.30))


func _draw_mountains(image: Image, rng: RandomNumberGenerator) -> void:
	_fill_speckled(image, rng, Color(0.56, 0.52, 0.45), 0.06)
	var peaks: int = rng.randi_range(1, 2)
	for i: int in peaks:
		var base_y: int = rng.randi_range(44, 54)
		var half: int = rng.randi_range(14, 20)
		var peak := Vector2i(rng.randi_range(18, 46) if peaks > 1 else 32, base_y - half * 2 + rng.randi_range(0, 6))
		var left := Vector2i(peak.x - half, base_y)
		var right := Vector2i(peak.x + half, base_y)
		var foot := Vector2i(peak.x + rng.randi_range(-3, 3), base_y)
		_triangle(image, peak, left, foot, Color(0.70, 0.66, 0.60))
		_triangle(image, peak, foot, right, Color(0.42, 0.38, 0.34))
		var cap: float = 0.3
		var cap_left := Vector2i(Vector2(peak).lerp(Vector2(left), cap).round())
		var cap_right := Vector2i(Vector2(peak).lerp(Vector2(right), cap).round())
		_triangle(image, peak, cap_left, cap_right, Color(0.95, 0.96, 0.98))


func _draw_water(image: Image, rng: RandomNumberGenerator) -> void:
	_fill_speckled(image, rng, Color(0.20, 0.45, 0.76), 0.04)
	for i: int in 9:
		var p := _random_point(rng, 6)
		var length: int = rng.randi_range(6, 12)
		var crest: Color = Color(0.55, 0.75, 0.95) if rng.randf() < 0.7 else Color(0.14, 0.36, 0.64)
		for x: int in length:
			var y: int = p.y + roundi(sin(TAU * float(x) / length) * 1.5)
			_plot(image, Vector2i(p.x + x, y), crest)


func _draw_desert(image: Image, rng: RandomNumberGenerator) -> void:
	_fill_speckled(image, rng, Color(0.88, 0.78, 0.50), 0.05)
	for i: int in 4:
		var y0: int = rng.randi_range(10, 54)
		var phase: float = rng.randf() * TAU
		for x: int in SIZE:
			var y: int = y0 + roundi(sin(phase + x * 0.12) * 3.0)
			_plot(image, Vector2i(x, y), Color(0.76, 0.63, 0.36))
			_plot(image, Vector2i(x, y - 1), Color(0.95, 0.88, 0.64))
	for i: int in 2:
		_disc(image, _random_point(rng, 10), 1, Color(0.55, 0.45, 0.30))


func _draw_snow(image: Image, rng: RandomNumberGenerator) -> void:
	_fill_speckled(image, rng, Color(0.90, 0.94, 0.98), 0.03)
	for i: int in 5:
		var p := _random_point(rng, 8)
		_disc(image, p, rng.randi_range(3, 6), Color(0.80, 0.87, 0.95))
	for i: int in 6:
		var p := _random_point(rng, 6)
		var flake: Color = Color(1.0, 1.0, 1.0)
		_line(image, p + Vector2i(-2, 0), p + Vector2i(2, 0), flake)
		_line(image, p + Vector2i(0, -2), p + Vector2i(0, 2), flake)


# --- Drawing helpers ------------------------------------------------------------------------

func _fill_speckled(image: Image, rng: RandomNumberGenerator, color: Color, amount: float) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			var shade: float = rng.randf_range(-amount, amount)
			image.set_pixel(x, y, Color(color.r + shade, color.g + shade, color.b + shade))


func _random_point(rng: RandomNumberGenerator, margin: int) -> Vector2i:
	return Vector2i(rng.randi_range(margin, SIZE - 1 - margin), rng.randi_range(margin, SIZE - 1 - margin))


func _plot(image: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.x < SIZE and p.y >= 0 and p.y < SIZE:
		image.set_pixelv(p, color)


func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect.intersection(Rect2i(0, 0, SIZE, SIZE)), color)


func _line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var steps: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i: int in steps + 1:
		var t: float = float(i) / maxi(steps, 1)
		_plot(image, Vector2i(Vector2(from).lerp(Vector2(to), t).round()), color)


func _disc(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y: int in range(-radius, radius + 1):
		for x: int in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				_plot(image, center + Vector2i(x, y), color)


func _triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var polygon := PackedVector2Array([Vector2(a), Vector2(b), Vector2(c)])
	var bounds := Rect2i(a, Vector2i.ZERO).expand(b).expand(c)
	for y: int in range(bounds.position.y, bounds.end.y + 1):
		for x: int in range(bounds.position.x, bounds.end.x + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				_plot(image, Vector2i(x, y), color)
