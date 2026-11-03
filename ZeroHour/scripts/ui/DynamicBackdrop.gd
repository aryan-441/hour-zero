extends Control

# A quiet, static plotting field. It is redrawn only on resize or risk-band change.
const FIELD := Color("#10120f")
const GRID := Color(0.30, 0.39, 0.30, 0.17)
const GRID_BOLD := Color(0.42, 0.48, 0.37, 0.24)
const SIGNAL := Color("#a8d8a0")
const WARNING := Color("#edb56a")
const ALERT := Color("#ec7971")
const SPACING := 96.0

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
	center = Vector2(size.x * 0.86, size.y * 0.73)
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
	draw_rect(Rect2(Vector2.ZERO,size),Color("#1b1c2a"))
