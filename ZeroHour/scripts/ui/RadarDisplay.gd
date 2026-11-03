extends Control
signal contact_swept
const GREEN := Color("#a8d8a0")
const AMBER := Color("#edb56a")
const RED := Color("#ec7971")
const CRITICAL := Color("#d65d60")
const REDRAW_INTERVAL := 1.0 / 24.0

class RadarGrid extends Control:
	var active := GREEN
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		draw_circle(c, r, Color("#1b211c"))
		for n in range(1, 5):
			draw_arc(c, r * float(n) / 4.0, 0.0, TAU, 48, Color(active, 0.22 if n < 4 else 0.42), 1.0)
		draw_line(Vector2(c.x-r,c.y),Vector2(c.x+r,c.y),Color(active,0.24),1.0)
		draw_line(Vector2(c.x,c.y-r),Vector2(c.x,c.y+r),Color(active,0.24),1.0)
		for spoke in range(8):
			var angle := TAU * float(spoke) / 8.0
			draw_line(c+Vector2(cos(angle),sin(angle))*r*0.78,c+Vector2(cos(angle),sin(angle))*r,Color(active,0.18),1.0)

var sweep := 0.0
var redraw_elapsed := 0.0
var active := GREEN
var center := Vector2.ZERO
var radius := 0.0
var contact_one := Vector2.ZERO
var contact_two := Vector2.ZERO
var grid: RadarGrid

func _ready() -> void:
	grid = RadarGrid.new()
	grid.active = active
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.show_behind_parent = true
	add_child(grid)
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_cache_geometry)
	_cache_geometry()

func _cache_geometry() -> void:
	center = size * 0.5
	radius = minf(size.x, size.y) * 0.44
	contact_one = center + Vector2(radius*0.38,-radius*0.20)
	contact_two = center + Vector2(-radius*0.47,radius*0.28)
	queue_redraw()

func _process(delta: float) -> void:
	redraw_elapsed += delta
	if redraw_elapsed < REDRAW_INTERVAL:
		return
	var step := redraw_elapsed
	redraw_elapsed = 0.0
	var previous_sweep := sweep
	sweep = fposmod(sweep + step * 1.15, TAU)
	if previous_sweep > sweep or (previous_sweep < 5.05 and sweep >= 5.05):
		contact_swept.emit()
	queue_redraw()

func set_exposure(value: float) -> void:
	var next_active := CRITICAL if value >= 95.0 else RED if value >= 80.0 else AMBER if value >= 65.0 else GREEN
	if active != next_active:
		active = next_active
		if is_instance_valid(grid):
			grid.active = active
			grid.queue_redraw()
		queue_redraw()

func _draw() -> void:
	var end := center + Vector2(cos(sweep), sin(sweep)) * radius
	for tail in range(1, 7):
		var angle := sweep - float(tail) * 0.045
		var strength := 1.0 - float(tail) / 7.0
		draw_line(center + Vector2(cos(angle), sin(angle)) * radius * 0.08, center + Vector2(cos(angle), sin(angle)) * radius, Color(GREEN, strength * 0.22), 1.0)
	draw_line(center, end, GREEN, 2.0)
	draw_circle(contact_one, 3.5, active)
	draw_circle(contact_two, 2.7, Color("#aeb8a7"))
	draw_circle(center, 2.7, Color("#f3f0df"))

