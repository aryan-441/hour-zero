extends Control

# A quiet, static plotting field. It is redrawn only on resize or risk-band change.
const FIELD := Color("#050a12")
const GRID := Color(0.12, 0.21, 0.30, 0.28)
const GRID_BOLD := Color(0.18, 0.30, 0.40, 0.34)
const SIGNAL := Color("#6af0d0")
const WARNING := Color("#ffbb62")
const ALERT := Color("#ff5d72")
const SPACING := 72.0

var exposure_band := -1
var center := Vector2.ZERO
var radius := 0.0
var grid_columns := 0
var grid_rows := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_cache_geometry)
	_cache_geometry()

func _cache_geometry() -> void:
	center = Vector2(size.x * 0.83, size.y * 0.72)
	radius = minf(size.x * 0.34, size.y * 0.44)
	grid_columns = int(size.x / SPACING) + 1
	grid_rows = int(size.y / SPACING) + 1
	queue_redraw()

func set_exposure(value: float) -> void:
	var next_band := 0 if value < 50.0 else 1 if value < 65.0 else 2 if value < 80.0 else 3 if value < 95.0 else 4
	if next_band != exposure_band:
		exposure_band = next_band
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FIELD)
	for column in range(grid_columns + 1):
		var x := float(column) * SPACING
		var color := GRID_BOLD if column % 4 == 0 else GRID
		draw_line(Vector2(x, 0), Vector2(x, size.y), color, 1.0)
	for row in range(grid_rows + 1):
		var y := float(row) * SPACING
		var color := GRID_BOLD if row % 4 == 0 else GRID
		draw_line(Vector2(0, y), Vector2(size.x, y), color, 1.0)
	var accent := SIGNAL if exposure_band <= 0 else WARNING if exposure_band <= 2 else ALERT
	for ring in range(1, 5):
		draw_arc(center, radius * float(ring) / 4.0, 0.0, TAU, 64, Color(accent, 0.15 + float(ring) * 0.025), 1.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(accent, 0.28), 1.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(accent, 0.28), 1.0)
	draw_circle(center, 3.0, accent)
