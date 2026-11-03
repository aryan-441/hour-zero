extends Control
const Flow = preload("res://scripts/system/ChallengeFlow.gd")
const Radar = preload("res://scripts/ui/RadarDisplay.gd")
const Sounds = preload("res://scripts/ui/SoundManager.gd")
const BG=Color("#1b1c2a")
const PANEL=Color("#2b2b40")
const LINE=Color("#494353")
const TEXT=Color("#f3f0df")
const MUTED=Color("#c8c1cd")
const CYAN=Color("#ffc28c")
const AMBER=Color("#edb56a")
const RED=Color("#ec7971")
const GRACE_SECONDS=6.0

class PerkBadge extends Control:
	var perk_id := ""
	func set_perk(value: String) -> void:
		perk_id = value
		queue_redraw()
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.43
		var accent := Color("#6af0d0")
		if perk_id == "time_buffer":
			accent = Color("#ffbb62")
		elif perk_id == "signal_scrubber":
			accent = Color("#ff5d72")
		elif perk_id == "ghost_protocol":
			accent = Color("#8ba2b5")
		elif perk_id == "cache_spike":
			accent = Color("#ffbb62")
		draw_circle(center, radius, PANEL)
		draw_arc(center, radius, 0.0, TAU, 48, accent, 2.0, true)
		draw_arc(center, radius * 0.72, 0.0, TAU, 36, accent * 0.28, 1.0, true)
		match perk_id:
			"intel_ping":
				draw_arc(center, radius * 0.42, 0.0, TAU, 24, accent, 1.8, true)
				draw_line(center + Vector2(0, -radius * 0.66), center + Vector2(0, radius * 0.66), accent, 1.5, true)
				draw_line(center + Vector2(-radius * 0.66, 0), center + Vector2(radius * 0.66, 0), accent, 1.5, true)
			"time_buffer":
				draw_line(center + Vector2(-radius * 0.34, -radius * 0.58), center + Vector2(radius * 0.34, -radius * 0.58), accent, 2.0, true)
				draw_line(center + Vector2(-radius * 0.34, radius * 0.58), center + Vector2(radius * 0.34, radius * 0.58), accent, 2.0, true)
				draw_line(center + Vector2(-radius * 0.30, -radius * 0.50), center + Vector2(radius * 0.26, 0), accent, 1.8, true)
				draw_line(center + Vector2(radius * 0.26, 0), center + Vector2(-radius * 0.30, radius * 0.50), accent, 1.8, true)
				draw_line(center + Vector2(radius * 0.30, -radius * 0.50), center + Vector2(-radius * 0.26, 0), accent, 1.8, true)
				draw_line(center + Vector2(-radius * 0.26, 0), center + Vector2(radius * 0.30, radius * 0.50), accent, 1.8, true)
			"signal_scrubber":
				for row in range(3):
					var y := center.y + float(row - 1) * radius * 0.32
					draw_line(Vector2(center.x - radius * 0.58, y), Vector2(center.x - radius * 0.20, y), accent, 1.8, true)
					draw_line(Vector2(center.x - radius * 0.20, y), Vector2(center.x, y - radius * 0.16), accent, 1.8, true)
					draw_line(Vector2(center.x, y - radius * 0.16), Vector2(center.x + radius * 0.20, y + radius * 0.16), accent, 1.8, true)
					draw_line(Vector2(center.x + radius * 0.20, y + radius * 0.16), Vector2(center.x + radius * 0.58, y), accent, 1.8, true)
			"ghost_protocol":
				draw_arc(center, radius * 0.48, -PI * 0.82, PI * 0.82, 28, accent, 2.0, true)
				draw_line(center + Vector2(0, -radius * 0.45), center + Vector2(0, radius * 0.45), accent, 2.0, true)
			"cache_spike":
				var spike := PackedVector2Array([center + Vector2(0, -radius * 0.58), center + Vector2(radius * 0.14, -radius * 0.12), center + Vector2(radius * 0.50, -radius * 0.12), center + Vector2(radius * 0.20, radius * 0.12), center + Vector2(radius * 0.30, radius * 0.50), center, center + Vector2(-radius * 0.30, radius * 0.50), center + Vector2(-radius * 0.20, radius * 0.12), center + Vector2(-radius * 0.50, -radius * 0.12), center + Vector2(-radius * 0.14, -radius * 0.12)])
				draw_colored_polygon(spike, accent)
var flow=Flow.new()
var timer:Timer
var meter:ProgressBar
var risk_value:Label
var risk_band_label:Label
var risk_odds:Label
var hud_depth:Label
var hud_score:Label
var hud_credits:Label
var screen_root:Control
var intro:VBoxContainer
var instructions:VBoxContainer
var stats_screen:VBoxContainer
var about:VBoxContainer
var armory:VBoxContainer
var boss_briefing:VBoxContainer
var challenge:VBoxContainer
var decision:VBoxContainer
var results:VBoxContainer
var challenge_header:Label
var prompt:Label
var challenge_scroll:ScrollContainer
var answer:LineEdit
var clock_label:Label
var challenge_status:Label
var decision_text:Label
var decision_outcome:Label
var decision_status:Label
var decision_banner:PanelContainer
var results_text:Label
var radar:Control
var memory_phase=false
var memory_response_prompt=""
var base_limit=12.0
var timer_exposure_band := ""
var challenge_resolved=false
var displayed_risk_band=""
var screen_panels:Array[Control]=[]
var screen_title:Label
var risk_ui_elapsed := 0.0
var sounds:Node
var sound_toggle:Button
var backdrop:Control
var displayed_risk=-1.0
var displayed_risk_integer=-1
var displayed_depth=-1
var displayed_score=-1
var displayed_credits=-1
var displayed_clock_seconds=-1
var displayed_clock_text=""
var displayed_clock_phase=-1
var boss_is_active := false
var armory_balance:Label
var purchase_feedback:Label
var purchase_labels:Dictionary={}
var armory_stock_labels:Dictionary={}
var armory_buy_buttons:Dictionary={}
var perk_bar:HFlowContainer
var perk_feedback:Label
var perk_use_buttons:Dictionary={}
var perk_count_labels:Dictionary={}
var perk_badges:Dictionary={}
var used_perks_this_challenge:Dictionary={}
var web_visibility_callback:JavaScriptObject
var web_pause_started_msec := -1
var outer:MarginContainer
var shell:VBoxContainer
var cols:HBoxContainer
var rail:VBoxContainer
var mobile_risk:Label
var footer_right:Label
var mobile_copyright:Label
var mobile_meter:ProgressBar
var mobile_details:Label
var mobile_layout := false
var stat_values:Dictionary={}
var navigation:MenuButton
var current_panel:VBoxContainer

var reduced_motion := false
var veil := ColorRect.new()
var page_fade: Tween
var display_face := SystemFont.new()

func _ready():
	display_face.font_names = PackedStringArray(["Georgia", "Noto Serif", "serif"])
	if OS.has_feature("web"):
		reduced_motion = bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))

	_setup_audio()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_configure_display_scale()
	_build_ui()
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glass := ShaderMaterial.new()
	glass.shader = Shader.new()
	glass.shader.code = "shader_type canvas_item; uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear_mipmap; void fragment(){vec3 c=textureLod(scene,SCREEN_UV,2.0).rgb; COLOR=vec4(mix(c,vec3(0.07,0.055,0.10),0.38),1.0);}"
	veil.color = Color(0.04,0.03,0.07,0.55)
	if not OS.has_feature("web"):
		veil.material = glass
	veil.hide()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	add_child(flow)
	timer=Timer.new()
	timer.one_shot=true
	add_child(timer)
	timer.timeout.connect(_timeout)
	GameManager.state_changed.connect(_refresh)
	_show_panel(intro)
	_update_risk()
	if OS.has_feature("web"):
		web_visibility_callback=JavaScriptBridge.create_callback(_on_web_visibility_changed)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange",web_visibility_callback)
		_on_web_visibility_changed([])

func _physical_width() -> float:
	if OS.has_feature("web"):
		return float(JavaScriptBridge.get_interface("window").innerWidth)
	return float(DisplayServer.window_get_size().x)

func _configure_display_scale() -> void:
	if OS.has_feature("web"):
		var browser_window=JavaScriptBridge.get_interface("window")
		var rect=JavaScriptBridge.eval("JSON.stringify([document.querySelector('#canvas').clientWidth,document.querySelector('#canvas').clientHeight])")
		var dimensions=JSON.parse_string(rect)
		var logical_size=Vector2i(int(dimensions[0]),int(dimensions[1]))
		if logical_size.x>0 and logical_size.y>0 and get_window().content_scale_size!=logical_size:
			get_window().content_scale_size=logical_size
		return
	var width := _physical_width()
	var small := width < 700.0
	get_window().content_scale_size = Vector2i(390, 844) if small else Vector2i(820, 1180) if width < 1000.0 else Vector2i(1152, 648)
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

func _apply_responsive_layout() -> void:
	if not is_instance_valid(outer) or not is_instance_valid(screen_root):
		return
	_configure_display_scale()
	var narrow := _physical_width() < 1000.0
	mobile_layout=narrow
	var in_run=current_panel in [challenge,decision,boss_briefing]
	var show_instruments=in_run and not narrow
	for item in range(5):
		navigation.get_popup().set_item_disabled(item,false)
	rail.visible=show_instruments
	hud_depth.visible=show_instruments
	hud_score.visible=show_instruments
	hud_credits.visible=show_instruments
	footer_right.visible=false
	mobile_copyright.visible=true
	shell.get_node("HeaderRow").get_node("SignalLabel").visible=show_instruments
	mobile_risk.visible=in_run
	mobile_meter.visible=in_run
	mobile_details.visible=in_run
	brand_resize()
	var margin := 12 if _physical_width() < 370 else 16 if narrow else 28
	var inset = [0,0,0,0]
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("JSON.stringify(['top','right','bottom','left'].map(k=>parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--safe-'+k))||0))")
		if raw:
			inset = JSON.parse_string(raw)
	outer.add_theme_constant_override("margin_left",maxi(margin,int(inset[3])))
	outer.add_theme_constant_override("margin_right",maxi(margin,int(inset[1])))
	outer.add_theme_constant_override("margin_top",maxi(18 if narrow else 20,int(inset[0])))
	outer.add_theme_constant_override("margin_bottom",maxi(24 if narrow else 18,int(inset[2])))
	screen_root.custom_minimum_size.y=0

func brand_resize() -> void:
	var brand := shell.get_node("HeaderRow").get_child(0)
	brand.custom_minimum_size.x=175 if mobile_layout else 190

func _on_web_visibility_changed(_arguments: Array) -> void:
	var hidden: bool=JavaScriptBridge.get_interface("document").hidden
	if hidden and web_pause_started_msec < 0:
		web_pause_started_msec=Time.get_ticks_msec()
		get_tree().paused=true
	elif not hidden and web_pause_started_msec >= 0:
		# Browser time continues while scene timers stop. Keep both clocks aligned.
		if GameManager.game_state=="playing" and not memory_phase:
			flow.question_start_time+=Time.get_ticks_msec()-web_pause_started_msec
		web_pause_started_msec=-1
		get_tree().paused=false

func _exit_tree() -> void:
	if OS.has_feature("web") and web_visibility_callback != null:
		JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange",web_visibility_callback)

func _process(delta):
	if GameManager.game_state=="playing" and timer:
		# Keep gameplay timing precise while limiting display work to 10 Hz.
		GameManager.advance_risk(delta)
		if GameManager.game_state != "playing":
			return
		risk_ui_elapsed+=delta
		if risk_ui_elapsed<0.1:
			return
		risk_ui_elapsed=fposmod(risk_ui_elapsed,0.1)
		_update_risk()
		var current_band := str(GameManager.get_detection_profile().get("band", "GREEN"))
		if not memory_phase and current_band != timer_exposure_band and not challenge_resolved:
			timer_exposure_band = current_band
			base_limit = flow.sync_time_to_exposure()
			var elapsed := float(Time.get_ticks_msec() - flow.question_start_time) / 1000.0
			var remaining := maxf(base_limit + GRACE_SECONDS - elapsed, 0.01)
			timer.start(remaining)
			challenge_status.text="Exposure is %s. Timer adjusted to %d sec." % [current_band.to_lower(), int(base_limit)]
		if not memory_phase:
			var rem=timer.time_left
			if rem>GRACE_SECONDS:
				var seconds=int(ceil(rem-GRACE_SECONDS))
				if displayed_clock_phase!=0 or displayed_clock_seconds!=seconds:
					displayed_clock_seconds=seconds
					displayed_clock_text="%02d" % seconds
					clock_label.text=displayed_clock_text
				if displayed_clock_phase!=0:
					clock_label.add_theme_color_override("font_color",CYAN)
					displayed_clock_phase=0
			else:
				var clock_text="+%.1f" % (GRACE_SECONDS-rem)
				if displayed_clock_text!=clock_text:
					displayed_clock_text=clock_text
					clock_label.text=clock_text
				if displayed_clock_phase!=1:
					clock_label.add_theme_color_override("font_color",RED)
					challenge_status.text="Overtime: signal exposure is rising."
					displayed_clock_phase=1
func _build_ui():
	var bg=preload("res://scripts/ui/DynamicBackdrop.gd").new()
	backdrop=bg
	bg.name="DynamicBackdrop"
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	outer=MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	var page_scroll=ScrollContainer.new()
	page_scroll.name="PageScroll"
	page_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	page_scroll.scroll_deadzone=12
	page_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	outer.add_child(page_scroll)
	shell=VBoxContainer.new()
	shell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	shell.add_theme_constant_override("separation",12)
	page_scroll.add_child(shell)
	_build_header(shell)
	var div=ColorRect.new()
	div.color=LINE
	div.custom_minimum_size.y=1
	shell.add_child(div)
	cols=HBoxContainer.new()
	cols.size_flags_vertical=Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation",14)
	shell.add_child(cols)
	var main=VBoxContainer.new()
	main.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	main.size_flags_vertical=Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation",10)
	cols.add_child(main)
	_build_stage(main)
	_build_sidebar(cols)
	_build_footer(shell)
	_flatten_scrolls(screen_root)
	_remove_spacers(screen_root)

func _flatten_scrolls(node: Node):
	for child in node.get_children():
		if child is ScrollContainer:
			child.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
			child.custom_minimum_size.y=0
			child.mouse_filter=Control.MOUSE_FILTER_PASS
		_flatten_scrolls(child)

func _remove_spacers(node: Node):
	for child in node.get_children():
		if child.get_class()=="Control" and child.size_flags_vertical==Control.SIZE_EXPAND_FILL:
			child.hide()
		_remove_spacers(child)

func _build_header(parent):
	var row=HBoxContainer.new()
	row.name="HeaderRow"
	row.add_theme_constant_override("separation",14)
	parent.add_child(row)
	var brand=VBoxContainer.new()
	brand.add_theme_constant_override("separation",0)
	row.add_child(brand)
	brand.custom_minimum_size.x=190
	var wordmark=_label("Hour Zero",27,TEXT)
	wordmark.autowrap_mode=TextServer.AUTOWRAP_OFF
	brand.add_child(wordmark)
	var gap=Control.new()
	gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	hud_depth=_label("DEPTH  --",11,TEXT)
	hud_depth.custom_minimum_size.x=88
	hud_score=_label("SCORE  000000",11,TEXT)
	hud_score.custom_minimum_size.x=112
	hud_credits=_label("CREDITS  000",11,TEXT)
	hud_credits.custom_minimum_size.x=112
	row.add_child(hud_depth)
	row.add_child(hud_score)
	row.add_child(hud_credits)
	var signal_label=_label("SIGNAL ACTIVE",10,CYAN)
	signal_label.name="SignalLabel"
	signal_label.custom_minimum_size.x=112
	signal_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	row.add_child(signal_label)
	navigation=MenuButton.new()
	navigation.text="Menu"
	var menu_image=Image.new()
	menu_image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><path d="M2 4h16M2 10h16M2 16h16" stroke="#fff3df" stroke-width="2" stroke-linecap="round"/></svg>')
	navigation.icon=ImageTexture.create_from_image(menu_image)
	navigation.flat=false
	navigation.custom_minimum_size=Vector2(92,46)
	navigation.tooltip_text="Open navigation"
	row.add_child(navigation)
	var popup=navigation.get_popup()
	popup.add_theme_constant_override("v_separation",18)
	popup.add_theme_font_size_override("font_size",16)
	popup.add_theme_color_override("font_color",TEXT)
	popup.add_theme_color_override("font_hover_color",TEXT)
	popup.add_theme_color_override("font_disabled_color",MUTED.darkened(0.3))
	var surface=StyleBoxFlat.new()
	surface.bg_color=Color("#302d42")
	surface.border_color=Color("#575064")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(14)
	surface.set_content_margin_all(18)
	surface.shadow_color=Color(0,0,0,0.3)
	surface.shadow_size=12
	popup.add_theme_stylebox_override("panel",surface)
	var selection=StyleBoxFlat.new()
	selection.bg_color=Color("#4b4059")
	selection.set_corner_radius_all(7)
	popup.add_theme_stylebox_override("hover",selection)
	var menu_style=StyleBoxFlat.new()
	menu_style.bg_color=Color("#353044")
	menu_style.set_corner_radius_all(12)
	menu_style.set_content_margin_all(12)
	navigation.add_theme_stylebox_override("normal",menu_style)
	navigation.add_theme_stylebox_override("hover",selection)
	navigation.add_theme_stylebox_override("pressed",selection)
	navigation.add_theme_font_size_override("font_size",15)
	navigation.add_theme_color_override("font_color",TEXT)
	navigation.about_to_popup.connect(func():
		sounds.play_cue("menu")
		veil.show()
		popup.set_item_text(6,"Sound on" if GameManager.is_sound_enabled() else "Sound off")
		if get_viewport_rect().size.x < 600:
			popup.size.x = int(get_viewport_rect().size.x)-24
			_place_menu_sheet.call_deferred(popup)
		else:
			popup.size.x = 242
	)
	popup.popup_hide.connect(func(): veil.hide())

	for item in ["Home","How to play","Perk shop","Stats","About Hour Zero","Toggle sound"]:
		if popup.item_count == 5:
			popup.add_separator()
		var paths=["M3 10L10 4l7 6v7H4v-7","M3 4q4-1 7 2 3-3 7-2v12q-4-1-7 1-3-2-7-1z","M3 8h14l-1 9H4z M7 8V6a3 3 0 016 0v2","M4 16V9m6 7V4m6 12v-6","M10 9v6m0-10v1","M3 8h3l5-4v12l-5-4H3z M14 7q4 3 0 6"]
		var id=5 if popup.item_count==6 else popup.item_count
		var glyph=Image.new()
		glyph.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><path d="%s" fill="none" stroke="#ffc28c" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round"/></svg>' % paths[id])
		popup.add_icon_item(ImageTexture.create_from_image(glyph),item, id if id<5 else 6)
	popup.id_pressed.connect(_navigate)
	mobile_risk=_label("EXPOSURE 00%",13,CYAN)
	mobile_risk.visible=false
	mobile_risk.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	mobile_risk.add_theme_font_size_override("font_size",20)
	var risk_surface=StyleBoxFlat.new()
	risk_surface.bg_color=Color("#292635")
	risk_surface.border_color=CYAN
	risk_surface.set_border_width_all(1)
	risk_surface.set_corner_radius_all(12)
	risk_surface.set_content_margin_all(12)
	mobile_risk.add_theme_stylebox_override("normal",risk_surface)
	parent.add_child(mobile_risk)
	mobile_details=_label("",14,MUTED)
	parent.add_child(mobile_details)
	mobile_meter=ProgressBar.new()
	mobile_meter.custom_minimum_size.y=7
	mobile_meter.show_percentage=false
	mobile_meter.visible=false
	parent.add_child(mobile_meter)
	popup.add_separator()
	popup.add_item("Privacy policy",7)
	popup.add_item("Terms of service",8)
	popup.add_item("Contact support",9)
func _place_menu_sheet(popup: PopupMenu):
	if popup.visible:
		popup.max_size=Vector2i(maxi(240,int(get_viewport_rect().size.x)-24),maxi(160,int(get_viewport_rect().size.y)-24))
		popup.position = Vector2i(12,12)

func _navigate(id:int) -> void:
	if id<5 and GameManager.game_state in ["playing","decision","boss_briefing"]:
		var confirmation=ConfirmationDialog.new()
		confirmation.dialog_text="Leave this run? Your unbanked credits will be lost."
		confirmation.title="Leave run"
		add_child(confirmation)
		confirmation.confirmed.connect(func():
			timer.stop()
			GameManager.return_to_start()
			_navigate(id)
			confirmation.queue_free())
		confirmation.canceled.connect(confirmation.queue_free)
		confirmation.popup_centered(Vector2i(280,160))
		return
	sounds.play_cue("navigate")
	match id:
		0: _back_to_intro()
		1: _open_instructions()
		2: _open_armory()
		3: _open_stats()
		4: _open_about()
		6: _toggle_sound()
		7: OS.shell_open("https://hourzero.web.app/privacy.html")
		8: OS.shell_open("https://hourzero.web.app/terms.html")
		9: OS.shell_open("mailto:hourzerosupport@gmail.com")

func _build_stage(parent):
	parent.add_child(_rule())
	screen_root=VBoxContainer.new()
	screen_root.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	screen_root.size_flags_vertical=Control.SIZE_EXPAND_FILL
	parent.add_child(screen_root)
	intro=_new_panel()
	instructions=_new_panel()
	stats_screen=_new_panel()
	about=_new_panel()
	armory=_new_panel()
	boss_briefing=_new_panel()
	challenge=_new_panel()
	decision=_new_panel()
	results=_new_panel()
	screen_panels=[intro,instructions,stats_screen,about,armory,boss_briefing,challenge,decision,results]
	for p in screen_panels:
		p.visible=false
	_build_intro()
	_build_instructions()
	_build_stats()
	_build_about()
	_build_armory()
	_build_boss_briefing()
	_build_challenge()
	_build_decision()
	_build_results()

func _make_content_scrollable(panel: VBoxContainer, fixed_rows: int = 1) -> void:
	var content_nodes=panel.get_children()
	for index in range(fixed_rows):
		content_nodes.pop_back() # Keep the final action rows outside the scrolling body.
	var scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	panel.move_child(scroll,0)
	var body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",11)
	scroll.add_child(body)
	for child in content_nodes:
		child.reparent(body)

func _build_sidebar(parent):
	rail=VBoxContainer.new()
	rail.custom_minimum_size.x=244
	rail.add_theme_constant_override("separation",12)
	parent.add_child(rail)
	var row=HBoxContainer.new()
	var exposure_label=_label("EXPOSURE",10,MUTED)
	exposure_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(exposure_label)
	risk_band_label=_label("GREEN",11,CYAN)
	risk_band_label.custom_minimum_size.x=80
	risk_band_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	risk_band_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	row.add_child(risk_band_label)
	rail.add_child(row)
	risk_value=_label("00%",58,CYAN)
	rail.add_child(risk_value)
	meter=ProgressBar.new()
	meter.custom_minimum_size.y=8
	meter.max_value=100
	meter.show_percentage=false
	var back=StyleBoxFlat.new()
	back.bg_color=Color("#29332b")
	back.set_corner_radius_all(0)
	meter.add_theme_stylebox_override("background",back)
	var fill=StyleBoxFlat.new()
	fill.bg_color=CYAN
	fill.set_corner_radius_all(0)
	meter.add_theme_stylebox_override("fill",fill)
	rail.add_child(meter)
	risk_odds=_label("DETECTION CHANCE: 0%",11,MUTED)
	rail.add_child(risk_odds)
	rail.add_child(_rule())
	rail.add_child(_label("SIGNAL MAP",10,MUTED))
	radar=Radar.new()
	radar.custom_minimum_size=Vector2(220,190)
	radar.size_flags_vertical=Control.SIZE_EXPAND_FILL
	rail.add_child(radar)
	radar.contact_swept.connect(_play_ping)
	rail.add_child(_rule())
	var note=_label("Correct answers build your cache. Extract to keep it.",12,TEXT)
	note.custom_minimum_size.y=44
	rail.add_child(note)
func _build_footer(parent):
	var footer_box=VBoxContainer.new()
	parent.add_child(footer_box)
	footer_box.visible=not OS.has_feature("web")
	parent=footer_box
	var row=HBoxContainer.new()
	parent.add_child(row)
	var left=_label("Saved on this device",9,MUTED)
	left.custom_minimum_size.x=180
	left.autowrap_mode=TextServer.AUTOWRAP_OFF
	left.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(left)
	var gap=Control.new()
	gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	sound_toggle=Button.new()
	sound_toggle.text="Sound: on" if GameManager.is_sound_enabled() else "Sound: off"
	sound_toggle.tooltip_text="Toggle all game sounds"
	sound_toggle.pressed.connect(_toggle_sound)
	row.add_child(sound_toggle)
	footer_right=_label("© Aryan Arora 2026",9,MUTED)
	var right=footer_right
	right.custom_minimum_size.x=164
	right.autowrap_mode=TextServer.AUTOWRAP_OFF
	right.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(right)
	mobile_copyright=_label("© Aryan Arora 2026",11,MUTED)
	mobile_copyright.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(mobile_copyright)
	var links=HFlowContainer.new()
	links.add_theme_constant_override("h_separation",16)
	parent.add_child(links)
	for entry in [["Privacy policy","https://hourzero.web.app/privacy.html"],["Terms of service","https://hourzero.web.app/terms.html"],["hourzerosupport@gmail.com","mailto:hourzerosupport@gmail.com"]]:
		var link=LinkButton.new()
		link.text=entry[0]
		link.uri=entry[1]
		link.custom_minimum_size.y=44
		link.add_theme_font_size_override("font_size",13)
		links.add_child(link)
func _new_panel():
	var p=VBoxContainer.new()
	p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("separation",11)
	screen_root.add_child(p)
	return p

func _chapter(parent: Control, caption: String, title: String, accent: Color):
	var band = _panel(Color("#322c3d"),Color("#524758"),14)
	parent.add_child(band)
	var line = HBoxContainer.new()
	line.add_theme_constant_override("separation",16)
	band.add_child(line)
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(copy)
	copy.add_child(_label(caption,12,accent))
	copy.add_child(_label(title,32,TEXT))
	var art = TextureRect.new()
	art.texture = preload("res://assets/harbor.svg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size.x = 70
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(art)

func _build_intro():
	intro.add_theme_constant_override("separation",14)
	var harbor=TextureRect.new()
	harbor.texture=preload("res://assets/harbor.svg")
	harbor.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	harbor.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	harbor.custom_minimum_size.y=160
	harbor.size_flags_vertical=Control.SIZE_FILL
	harbor.mouse_filter=Control.MOUSE_FILTER_IGNORE
	intro.add_child(harbor)
	intro.add_child(_label("NIGHT SHIFT",13,AMBER))
	intro.add_child(_label("One more signal?",32,TEXT))
	intro.add_child(_label("Each puzzle earns credits. Extract to keep them, or stay on the air and risk getting caught.",17,MUTED))
	var actions=HFlowContainer.new()
	actions.add_theme_constant_override("h_separation",10)
	intro.add_child(actions)
	var start=_button(actions,"Start a run",_begin_mission,true)
	start.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var guide=_button(actions,"How to play",_open_instructions,false)
	guide.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var shop=_button(actions,"Perk shop",_open_armory,false)
	shop.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN

func _build_instructions():
	_chapter(instructions,"Field guide","How to play",AMBER)
	instructions.add_child(_label("Solve challenges to move deeper into the network. Every correct answer adds credits to your exposed cache. Choose when to leave and secure them.",14,MUTED))
	var gap=Control.new()
	gap.size_flags_vertical=Control.SIZE_EXPAND_FILL
	instructions.add_child(gap)
	var row=VBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	instructions.add_child(row)
	_tile(row,"Solve","Beat the clock. You get 6 seconds of overtime grace, but exposure rises faster during it.",CYAN)
	_tile(row,"02: MANAGE EXPOSURE","Exposure rises while you play. Wrong answers add risk; quick correct answers can reduce it.",AMBER)
	var row2=VBoxContainer.new()
	row2.add_theme_constant_override("separation",10)
	instructions.add_child(row2)
	_tile(row2,"03: CHOOSE YOUR EXIT","PUSH DEEPER for more rewards or EXTRACT & BANK to keep your cache.",CYAN)
	_tile(row2,"04: KNOW THE STAKES","Detection permanently wipes unbanked credits. Already banked credits are safe.",RED)
	instructions.add_child(_label("Detection risk",11,CYAN))
	var bands=VBoxContainer.new()
	bands.add_theme_constant_override("separation",7)
	instructions.add_child(bands)
	_tile(bands,"GREEN: 0-49%","0% detection chance",CYAN)
	_tile(bands,"YELLOW: 50-64%","1% detection chance",Color("#f4dc61"))
	_tile(bands,"ORANGE: 65-79%","5% detection chance",AMBER)
	_tile(bands,"RED: 80-94%","25% detection chance",RED)
	_tile(bands,"CRITICAL: 95-99%","65% detection chance",Color("#ff2f59"))
	instructions.add_child(_label("100% EXPOSURE: immediate capture. Ghost Protocol cannot block full exposure.",12,RED))
	var actions=HFlowContainer.new()
	actions.add_theme_constant_override("separation",10)
	instructions.add_child(actions)
	_button(actions,"Start a run",_begin_mission,true)
	_button(actions,"Perk shop",_open_armory,false)
	_button(actions,"Back to start",_back_to_intro,false)

func _build_stats():
	_chapter(stats_screen,"Run history","Your progress",CYAN)
	stats_screen.add_child(_label("Your records across all runs.",15,MUTED))
	var scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	stats_screen.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=1 if _physical_width()<350 else 2
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	var metrics=[
		["credits_wallet","Available credits"],
		["best_score","Best score"],
		["accuracy","Accuracy"],
		["average","Average response"],
		["best_depth","Deepest node"],
		["games_played","Completed runs"],
		["questions_answered","Challenges answered"],
		["extracted_runs","Clean extractions"],
		["detected_runs","Detected runs"],
		["banked_credits_total","Lifetime banked"],
		["lost_unbanked_credits_total","Credits lost"]
	]
	for metric in metrics:
		var featured = metric[0] in ["credits_wallet","best_score"]
		var card=_panel(Color("#453541") if featured else Color("#262535"),Color("#745462") if featured else Color("#3d3948"),14)
		card.custom_minimum_size=Vector2(140,106)
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var stack=VBoxContainer.new()
		stack.add_theme_constant_override("separation",8)
		card.add_child(stack)
		var value=_label("0",30,CYAN if stat_values.size()<2 else TEXT)
		stat_values[metric[0]]=value
		stack.add_child(value)
		stack.add_child(_label(metric[1],13,MUTED))
	stats_screen.add_child(_label("Saved on this device",12,MUTED))
	var actions=HFlowContainer.new()
	stats_screen.add_child(actions)
	_button(actions,"Back to start",_back_to_intro,false)

func _build_about():
	_chapter(about,"Behind the game","Hour Zero",CYAN)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	about.add_child(scroll)
	var content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	scroll.add_child(content)
	content.add_child(_label("Hour Zero is a high-risk, high-reward game that puts your mental capabilities to the test.",16,TEXT))
	for paragraph in [
		"Infiltrate a secure digital network by solving timed math, pattern, logic, memory, and attention challenges.",
		"Each cleared challenge earns points and adds credits to your unbanked haul. As your exposure rises, the network becomes more likely to detect you.",
		"Choose whether to continue deeper for greater rewards or extract to secure your credits. If you are detected, the run ends and you lose any credits you have not banked.",
		"Boss challenges and tactical perks add extra ways to manage risk and push your run further.",
		"Detailed instructions are available in Mission Briefing."
	]:
		content.add_child(_label(paragraph,14,MUTED))
	content.add_child(_rule())
	content.add_child(_label("TEAM FileNotFoundError",18,CYAN))
	content.add_child(_label("Aryan Arora (Leader)\nAarush Sahai\nDhyann Jhunjhunwala",15,TEXT))
	var actions=HFlowContainer.new()
	actions.add_theme_constant_override("separation",10)
	about.add_child(actions)
	_button(actions,"How to play",_open_instructions,false)
	_button(actions,"Back to start",_back_to_intro,true)

func _build_armory():
	_chapter(armory,"Equipment","Perk shop",CYAN)
	armory.add_child(_label("Buy single-use perks with secured credits. They stay in your inventory until activated.",13,MUTED))
	purchase_feedback=_label("",12,CYAN)
	purchase_feedback.visible=false
	armory.add_child(purchase_feedback)
	armory_balance=_label("",13,AMBER)
	armory.add_child(armory_balance)
	var cards_scroll=ScrollContainer.new()
	cards_scroll.custom_minimum_size.y=185
	cards_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	cards_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	armory.add_child(cards_scroll)
	var card_list=VBoxContainer.new()
	card_list.add_theme_constant_override("separation",8)
	card_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	cards_scroll.add_child(card_list)
	var cards=HFlowContainer.new()
	cards.add_theme_constant_override("separation",8)
	card_list.add_child(cards)
	_add_armory_card(cards,"intel_ping","INTEL PING","Reveal a tailored hint for a challenge.","225 CREDITS",CYAN)
	_add_armory_card(cards,"time_buffer","TIME BUFFER","Add 5 seconds to a challenge.","300 CREDITS",AMBER)
	_add_armory_card(cards,"signal_scrubber","SIGNAL SCRUBBER","Cut current exposure by 8 points.","450 CREDITS",RED)
	var cards2=HFlowContainer.new()
	cards2.add_theme_constant_override("separation",8)
	card_list.add_child(cards2)
	_add_armory_card(cards2,"ghost_protocol","GHOST PROTOCOL","Block one detection below 100% exposure.","750 CREDITS",Color("#8ba2b5"))
	_add_armory_card(cards2,"cache_spike","CACHE SPIKE","Add 50 credits after your next correct answer.","525 CREDITS",Color("#ffbb62"))
	var actions=HFlowContainer.new()
	actions.add_theme_constant_override("separation",10)
	armory.add_child(actions)
	_button(actions,"DEPLOY WITH LOADOUT",_begin_mission,true)
	_button(actions,"Back to start",_back_to_intro,false)

func _build_boss_briefing() -> void:
	_chapter(boss_briefing,"High-security node","Black Ice",RED)
	boss_briefing.add_child(_label("Every eight regular challenges, the network deploys a multi-step arithmetic or layered pattern problem. Perks are disabled during boss questions. Engage or bypass.",14,MUTED))
	var row=HFlowContainer.new()
	row.add_theme_constant_override("separation",10)
	boss_briefing.add_child(row)
	_tile(row,"ENGAGE: DYNAMIC TIMER","A multi-step boss problem gets up to 48 seconds at low exposure or 28 at critical, plus 6 seconds of grace. The timer updates if your exposure band changes.",CYAN)
	_tile(row,"CORRECT: +150 CREDITS","Earn 150 bonus unbanked credits, plus the question's normal reward, and reduce exposure by 10 percentage points.",Color("#ffbb62"))
	var row2=HFlowContainer.new()
	row2.add_theme_constant_override("separation",10)
	boss_briefing.add_child(row2)
	_tile(row2,"WRONG: +15 EXPOSURE","Exposure rises by 15 percentage points and there is no boss bonus.",RED)
	_tile(row2,"BYPASS: +5 EXPOSURE","Skip the boss question and exposure rises by 5 percentage points.",AMBER)
	boss_briefing.add_child(_label("A detection chance happens after an engaged boss answer using your resulting exposure. Detection can still wipe your unbanked cache; secured wallet credits remain safe. Boss questions do not count toward the next set of eight.",12,TEXT))
	var gap=Control.new()
	gap.size_flags_vertical=Control.SIZE_EXPAND_FILL
	boss_briefing.add_child(gap)
	var actions=HFlowContainer.new()
	actions.add_theme_constant_override("separation",10)
	boss_briefing.add_child(actions)
	_button(actions,"ENGAGE BOSS NODE",_engage_boss,true)
	_button(actions,"BYPASS NODE: +5 EXPOSURE",_skip_boss,false)

func _add_armory_card(parent: Control, perk_id: String, title: String, description: String, cost_text: String, accent: Color) -> void:
	var card=_panel(PANEL,LINE,6)
	card.custom_minimum_size.x=210
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var stack=VBoxContainer.new()
	stack.add_theme_constant_override("separation",7)
	card.add_child(stack)
	var badge=PerkBadge.new()
	badge.custom_minimum_size=Vector2(72,72)
	badge.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	badge.set_perk(perk_id)
	stack.add_child(badge)
	stack.add_child(_label(title.capitalize(),18,accent))
	var desc=_label(description,10,TEXT)
	desc.custom_minimum_size.y=44
	stack.add_child(desc)
	var stock=_label("OWNED: 0",10,MUTED)
	armory_stock_labels[perk_id]=stock
	stack.add_child(stock)
	var confirmation=_label("",10,CYAN)
	confirmation.name="PurchaseConfirmation"
	confirmation.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	purchase_labels[perk_id]=confirmation
	stack.add_child(confirmation)
	var buy_button=_button(stack,"Buy · "+cost_text,Callable(self,"_buy_perk").bind(perk_id),false)
	armory_buy_buttons[perk_id]=buy_button

func _build_challenge():
	challenge_header=_label("",11,CYAN)
	challenge_header.custom_minimum_size.y=22
	challenge_header.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var row=HBoxContainer.new()
	challenge_header.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(challenge_header)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.alignment=BoxContainer.ALIGNMENT_END
	clock_label=_label("12",24,CYAN)
	clock_label.custom_minimum_size.x=82
	clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(clock_label)
	challenge.add_child(row)
	challenge.add_child(_rule())
	challenge_scroll=ScrollContainer.new()
	challenge_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	challenge_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	challenge_scroll.custom_minimum_size.y=100
	challenge.add_child(challenge_scroll)
	var content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.alignment=BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation",11)
	challenge_scroll.add_child(content)
	prompt=_label("",22,TEXT)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(prompt)
	challenge_status=_label("Solve the challenge.",11,MUTED)
	challenge_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(challenge_status)
	perk_feedback=_label("",11,CYAN)
	perk_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	perk_feedback.visible=false
	content.add_child(perk_feedback)
	perk_bar=HFlowContainer.new()
	perk_bar.alignment=FlowContainer.ALIGNMENT_CENTER
	perk_bar.add_theme_constant_override("separation",6)
	for perk_id in ["intel_ping","time_buffer","signal_scrubber","ghost_protocol","cache_spike"]:
		var slot=VBoxContainer.new()
		slot.custom_minimum_size.x=132
		slot.add_theme_constant_override("separation",2)
		var badge=PerkBadge.new()
		badge.custom_minimum_size=Vector2(38,38)
		badge.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		badge.set_perk(perk_id)
		perk_badges[perk_id]=badge
		slot.add_child(badge)
		var titles={"intel_ping":"INTEL","time_buffer":"TIME +5","signal_scrubber":"SCRUBBER","ghost_protocol":"GHOST","cache_spike":"CACHE +50"}
		var title=titles[perk_id]
		var action_button=_button(slot,"USE "+title,Callable(self,"_activate_perk").bind(perk_id),false)
		action_button.custom_minimum_size.x=126
		action_button.add_theme_font_size_override("font_size",9)
		perk_use_buttons[perk_id]=action_button
		var count_label=_label("x0",9,MUTED)
		count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		perk_count_labels[perk_id]=count_label
		slot.add_child(count_label)
		perk_bar.add_child(slot)
	perk_bar.visible=false
	content.add_child(perk_bar)
	answer=LineEdit.new()
	answer.custom_minimum_size.y=50
	answer.placeholder_text="Your answer"
	answer.alignment=HORIZONTAL_ALIGNMENT_CENTER
	answer.add_theme_font_size_override("font_size",16)
	answer.add_theme_color_override("font_color",TEXT)
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#050a12")
	style.border_color=Color("#2d5161")
	style.set_border_width_all(1)
	_round(style,7)
	answer.add_theme_stylebox_override("normal",style)
	answer.add_theme_stylebox_override("focus",style)
	answer.text_submitted.connect(_submit_text)
	challenge.add_child(answer)
	var buttons=HBoxContainer.new()
	buttons.alignment=BoxContainer.ALIGNMENT_CENTER
	challenge.add_child(buttons)
	_button(buttons,"Submit answer",_submit,true)

func _build_decision():
	decision.add_child(_label("Challenge result",10,CYAN))
	decision_banner=_panel(Color("#342325"),RED,8)
	decision.add_child(decision_banner)
	var banner_pad=_pad(decision_banner,14,10)
	decision_outcome=_label("No reward this time",23,RED)
	banner_pad.add_child(decision_outcome)
	decision_status=_label("You are still in. Choose what happens next.",16,TEXT)
	decision.add_child(decision_status)
	decision_text=_label("",14,MUTED)
	decision.add_child(decision_text)
	var gap=Control.new()
	gap.size_flags_vertical=Control.SIZE_EXPAND_FILL
	decision.add_child(gap)
	var row=HFlowContainer.new()
	row.add_theme_constant_override("separation",9)
	decision.add_child(row)
	_button(row,"Keep going",_continue,true)
	_button(row,"Extract and bank",_extract,false)
	decision.add_child(_label("Choose when ready. This decision will not time out.",10,MUTED))

func _build_results():
	results.add_child(_label("Run complete",10,AMBER))
	var title=_label("Run complete",33,TEXT)
	title.name="ResultTitle"
	results.add_child(title)
	results_text=_label("",15,MUTED)
	results.add_child(results_text)
	var gap=Control.new()
	gap.size_flags_vertical=Control.SIZE_EXPAND_FILL
	results.add_child(gap)
	var row=HFlowContainer.new()
	results.add_child(row)
	_button(row,"Play again",_open_instructions,true)
	_button(row,"Stats",_open_stats,false)
	_button(row,"Back to start",_back_to_intro,false)

func _label(value,size,color):
	var l=Label.new()
	l.text=value
	if size >= 26:
		l.add_theme_font_override("font",display_face)

	l.add_theme_font_size_override("font_size",maxi(size,12) if _physical_width() < 1000.0 else size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l

func _panel(color,border,radius):
	var p=PanelContainer.new()
	var s=StyleBoxFlat.new()
	s.bg_color=color
	s.border_color=border
	s.set_border_width_all(1)
	_round(s,radius)
	s.content_margin_left=11
	s.content_margin_right=11
	s.content_margin_top=11
	s.content_margin_bottom=11
	p.add_theme_stylebox_override("panel",s)
	return p

func _round(s,r):
	s.corner_radius_top_left=r
	s.corner_radius_top_right=r
	s.corner_radius_bottom_left=r
	s.corner_radius_bottom_right=r

func _pad(parent,h,v):
	var m=MarginContainer.new()
	m.add_theme_constant_override("margin_left",h)
	m.add_theme_constant_override("margin_right",h)
	m.add_theme_constant_override("margin_top",v)
	m.add_theme_constant_override("margin_bottom",v)
	parent.add_child(m)
	return m

func _chip(label):
	var p=_panel(PANEL,LINE,5)
	_pad(p,9,6).add_child(label)
	return p

func _tile(parent,title,body,accent):
	var group=HBoxContainer.new()
	group.add_theme_constant_override("separation",9)
	group.custom_minimum_size.x=0
	group.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(group)
	var marker=ColorRect.new()
	marker.color=accent
	marker.custom_minimum_size=Vector2(2,1)
	marker.size_flags_vertical=Control.SIZE_EXPAND_FILL
	group.add_child(marker)
	var copy=VBoxContainer.new()
	copy.add_theme_constant_override("separation",4)
	copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	group.add_child(copy)
	copy.add_child(_label(title,13,accent))
	copy.add_child(_label(body,11,TEXT))
func _button(parent,text,action,primary):
	var b=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(158 if _physical_width() < 1000.0 else 170,54 if _physical_width() < 1000.0 else 48)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",14 if _physical_width() < 1000.0 else 13)
	var n=StyleBoxFlat.new()
	n.bg_color=CYAN if primary else Color("#343143")
	n.border_color=CYAN if primary else LINE
	n.set_border_width_all(1)
	_round(n,12)
	var h=n.duplicate()
	h.bg_color=Color("#ffdab2") if primary else Color("#463f54")
	b.add_theme_stylebox_override("normal",n)
	b.add_theme_stylebox_override("hover",h)
	b.add_theme_stylebox_override("pressed",h)
	var focus=StyleBoxFlat.new()
	focus.bg_color=Color(0,0,0,0)
	focus.set_border_width_all(2)
	focus.border_color=AMBER
	_round(focus,12)
	b.add_theme_stylebox_override("focus",focus)
	b.add_theme_color_override("font_color",BG if primary else TEXT)
	for state in ["font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state,BG if primary else TEXT)
	b.button_down.connect(func(): _press_feedback(b,0.97))
	b.button_up.connect(func(): _press_feedback(b,1.0))
	b.pressed.connect(func():
		sounds.play_cue("click")
		action.call()
	)
	parent.add_child(b)
	return b
func _press_feedback(button: Button, factor: float):
	if reduced_motion:
		return
	var prior = button.get_meta("press_motion",null) if button.has_meta("press_motion") else null
	if prior:
		prior.kill()
	button.pivot_offset = button.size * 0.5
	var motion = button.create_tween()
	button.set_meta("press_motion",motion)
	motion.tween_property(button,"scale",Vector2.ONE * factor,0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _rule():
	var r=ColorRect.new()
	r.color=LINE
	r.custom_minimum_size.y=1
	return r

func _show_panel(panel):
	for p in screen_panels:
		p.visible=p==panel
	current_panel=panel
	_apply_responsive_layout()
	if page_fade:
		page_fade.kill()
	outer.get_node("PageScroll").set_deferred("scroll_vertical",0)
	panel.modulate.a=1.0
	if not reduced_motion:
		panel.modulate.a=0.35
		page_fade=create_tween()
		page_fade.tween_property(panel,"modulate:a",1.0,0.16)
func _open_instructions():
	GameManager.return_to_start()
	_show_panel(instructions)

func _open_about():
	GameManager.return_to_start()
	_show_panel(about)

func _toggle_sound():
	GameManager.set_sound_enabled(not GameManager.is_sound_enabled())
	sounds.set_enabled(GameManager.is_sound_enabled())
	sound_toggle.text="Sound: on" if GameManager.is_sound_enabled() else "Sound: off"

func _open_armory():
	GameManager.return_to_start()
	_refresh_armory()
	_show_panel(armory)

func _buy_perk(perk_id: String) -> void:
	if GameManager.buy_perk(perk_id):
		sounds.play_cue("purchase")
		purchase_feedback.text="PURCHASE CONFIRMED: %s added to your loadout" % perk_id.replace("_", " ").to_upper()
		purchase_feedback.visible=true
		purchase_labels[perk_id].text="ACQUIRED: +1 STOCK"
		purchase_labels[perk_id].add_theme_color_override("font_color",CYAN)
		var badge:Control=armory_stock_labels[perk_id].get_parent().get_node("PurchaseConfirmation").get_parent().get_child(0)
		badge.scale=Vector2(0.75,0.75)
		var pulse=create_tween()
		pulse.tween_property(badge,"scale",Vector2.ONE,0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_refresh_armory()
		_update_risk()

func _refresh_armory() -> void:
	if not is_instance_valid(armory_balance):
		return
	armory_balance.text="SECURED CREDITS: %d" % GameManager.get_credit_wallet()
	for perk_id in armory_stock_labels:
		armory_stock_labels[perk_id].text="OWNED: %d" % GameManager.get_perk_count(perk_id)
		armory_buy_buttons[perk_id].disabled=GameManager.get_credit_wallet() < int(GameManager.PERK_COSTS[perk_id])

func _refresh_perk_controls() -> void:
	if not is_instance_valid(perk_bar):
		return
	var any_available := false
	for perk_id in perk_use_buttons:
		var count := GameManager.get_perk_count(perk_id)
		var carries_into_boss: bool = GameManager.normal_questions_since_boss >= 7 and (perk_id == "ghost_protocol" or perk_id == "cache_spike")
		var available: bool = count > 0 and not boss_is_active and not carries_into_boss and not used_perks_this_challenge.has(perk_id) and not memory_phase and not challenge_resolved
		perk_use_buttons[perk_id].visible=count > 0
		perk_use_buttons[perk_id].get_parent().visible=count > 0
		perk_use_buttons[perk_id].disabled=not available
		perk_use_buttons[perk_id].tooltip_text="This perk affects the next question, which is a boss question." if carries_into_boss else ""
		perk_count_labels[perk_id].text="x%d" % count
		any_available = any_available or available
	perk_bar.visible=any_available and not boss_is_active and GameManager.game_state=="playing"

func _activate_perk(perk_id: String) -> void:
	if GameManager.game_state!="playing" or boss_is_active or GameManager.current_challenge_is_boss or challenge_resolved or memory_phase or used_perks_this_challenge.has(perk_id):
		return
	if not GameManager.consume_perk(perk_id):
		return
	used_perks_this_challenge[perk_id]=true
	match perk_id:
		"intel_ping":
			var hint := flow.get_current_hint()
			perk_feedback.text="INTEL PING: "+hint
			perk_feedback.visible=true
			challenge_status.text="FIELD INTEL DECRYPTED"
		"time_buffer":
			flow.add_time_buffer(5.0)
			base_limit+=5.0
			timer.start(timer.time_left+5.0)
			challenge_status.text="TIME BUFFER ACTIVE: +5 SECONDS"
		"signal_scrubber":
			GameManager.risk=maxf(GameManager.risk-8.0,0.0)
			challenge_status.text="SIGNAL SCRUBBED: EXPOSURE REDUCED BY 8"
		"ghost_protocol":
			GameManager.arm_ghost_protocol()
			challenge_status.text="GHOST PROTOCOL ARMED: BLOCKS ONE DETECTION BELOW 100%"
		"cache_spike":
			GameManager.arm_cache_spike()
			challenge_status.text="CACHE SPIKE ARMED: +50 ON NEXT CORRECT ANSWER"
	_play_perk_vfx(perk_id)
	sounds.play_cue("perk")
	_refresh_perk_controls()
	_update_risk()

func _play_perk_vfx(perk_id: String) -> void:
	var accent := CYAN
	if perk_id=="time_buffer":
		accent=AMBER
	elif perk_id=="signal_scrubber":
		accent=RED
	elif perk_id=="ghost_protocol":
		accent=Color("#8ba2b5")
	elif perk_id=="cache_spike":
		accent=Color("#ffbb62")
	var badge=perk_badges.get(perk_id)
	if is_instance_valid(badge):
		badge.scale=Vector2(0.72,0.72)
		var badge_tween=create_tween()
		badge_tween.tween_property(badge,"scale",Vector2.ONE,0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if perk_id=="intel_ping":
		var sweep=ColorRect.new()
		sweep.color=accent
		sweep.modulate.a=0.88
		sweep.size=Vector2(90.0,3.0)
		sweep.position=Vector2(-100.0,size.y*0.46)
		sweep.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(sweep)
		var scan=create_tween()
		scan.tween_property(sweep,"position:x",size.x+100.0,0.48)
		scan.parallel().tween_property(sweep,"modulate:a",0.0,0.48)
		scan.finished.connect(sweep.queue_free)
	else:
		var flash=ColorRect.new()
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.color=accent
		flash.modulate.a=0.0
		flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(flash)
		var flash_tween=create_tween()
		flash_tween.tween_property(flash,"modulate:a",0.17,0.08)
		flash_tween.tween_property(flash,"modulate:a",0.0,0.30)
		flash_tween.finished.connect(flash.queue_free)

func _begin_mission():
	sounds.play_cue("deploy")
	memory_phase=false
	flow.reset_run()
	GameManager.start_mission()
	_begin_challenge()

func _begin_challenge(is_boss: bool = false):
	challenge_scroll.scroll_vertical=0
	challenge_resolved=false
	boss_is_active=is_boss
	displayed_clock_phase=-1
	used_perks_this_challenge.clear()
	perk_feedback.text=""
	perk_feedback.visible=false
	var q=flow.start_challenge(is_boss)
	if q.is_empty():
		timer.stop()
		memory_phase=false
		challenge_resolved=true
		if is_boss and flow.challenge_manager.remaining_count() > 0:
			GameManager.current_challenge_is_boss=false
			_begin_challenge(false)
			return
		GameManager.finish_exhausted_run()
		results_text.text+="\n\nChallenge pool complete. Your cache has been secured."
		return
	challenge_header.text="%s: DEPTH %02d: %s: TIER %d" % ["BOSS NODE" if is_boss else "CHALLENGE",GameManager.mission_depth,str(q.get("category","CHALLENGE")).to_upper(),int(q.get("difficulty",1))]
	answer.clear()
	base_limit=float(q.get("time_limit_seconds",12.0))
	timer_exposure_band=str(GameManager.get_detection_profile().get("band","GREEN"))
	memory_phase=q.has("stimulus")
	answer.editable=not memory_phase
	memory_response_prompt=str(q.get("response_prompt",q.get("prompt","")))
	if memory_phase:
		prompt.text=str(q["stimulus"])
		prompt.add_theme_font_size_override("font_size",26)
		challenge_status.text="MEMORIZE THE SEQUENCE"
		perk_bar.visible=false
		timer.start(float(q.get("display_duration_seconds",2.0)))
	else:
		prompt.text=str(q["prompt"])
		prompt.add_theme_font_size_override("font_size",20 if prompt.text.length()>180 else 26)
		challenge_status.text="BOSS: PERKS DISABLED: %d SEC AT %s EXPOSURE: +6 SEC GRACE" % [int(base_limit), timer_exposure_band] if is_boss else "%d sec at %s exposure, plus 6 sec grace." % [int(base_limit), timer_exposure_band]
		timer.start(base_limit+GRACE_SECONDS)
		_refresh_perk_controls()
	_show_panel(challenge)
	_update_risk()
	if not memory_phase:
		answer.grab_focus()

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo and not memory_phase and GameManager.game_state=="playing" and answer.has_focus() and (event.keycode==KEY_ENTER or event.keycode==KEY_KP_ENTER):
		get_viewport().set_input_as_handled()
		_submit()

func _submit():
	if not memory_phase and not challenge_resolved:
		_resolve(answer.text)

func _submit_text(value):
	sounds.play_cue("submit")
	if not memory_phase and not challenge_resolved:
		_resolve(value)

func _timeout():
	if memory_phase:
		memory_phase=false
		challenge_scroll.scroll_vertical=0
		prompt.text=memory_response_prompt
		prompt.add_theme_font_size_override("font_size",20 if prompt.text.length()>180 else 26)
		answer.editable=true
		base_limit=flow.sync_time_to_exposure()
		timer_exposure_band=str(GameManager.get_detection_profile().get("band","GREEN"))
		challenge_status.text="Memory challenge. %d sec at %s exposure, plus 6 sec grace." % [int(base_limit), timer_exposure_band]
		flow.begin_response_phase()
		timer.start(base_limit+GRACE_SECONDS)
		_refresh_perk_controls()
		answer.grab_focus()
		return
	_resolve("",true)

func _resolve(value,timed_out=false):
	if GameManager.game_state!="playing" or challenge_resolved:
		return
	challenge_resolved=true
	timer.stop()
	memory_phase=false
	perk_bar.visible=false
	var result=flow.submit_answer(value,timed_out)
	if not result.get("resolved",false):
		challenge_resolved=false
		return
	if GameManager.game_state=="decision":
		sounds.play_cue("correct" if result.get("correct",false) else "incorrect")
	_refresh()
	_show_panel(decision if GameManager.game_state=="decision" else results)

func _continue():
	GameManager.continue_mission()
	if GameManager.game_state=="boss_briefing":
		sounds.play_cue("boss")
		_show_panel(boss_briefing)
	else:
		_begin_challenge()

func _engage_boss() -> void:
	GameManager.begin_boss_challenge()
	_begin_challenge(true)

func _skip_boss() -> void:
	GameManager.skip_boss()
	if GameManager.game_state != "playing":
		return
	boss_is_active=false
	_begin_challenge(false)

func _extract():
	GameManager.extract()
	_refresh()
	_show_panel(results)

func _open_stats():
	GameManager.return_to_start()
	_refresh_stats()
	_show_panel(stats_screen)

func _back_to_intro():
	GameManager.return_to_start()
	_show_panel(intro)

func _refresh_stats():
	var s=GameManager.get_stats()
	var total=int(s["questions_answered"])
	var accuracy=100.0*float(s["correct_answers"])/maxf(float(total),1.0)
	var average=float(s["total_answer_seconds"])/maxf(float(total),1.0)
	for key in stat_values:
		var value=stat_values[key]
		match key:
			"accuracy": value.text="%.1f%%" % accuracy
			"average": value.text="%.1f s" % average
			_: value.text=str(int(s.get(key,0)))

func _update_risk():
	if not is_instance_valid(meter):
		return
	var depth=maxi(GameManager.mission_depth,0)
	if displayed_depth!=depth:
		displayed_depth=depth
		hud_depth.text="DEPTH  %02d" % depth if depth>0 else "DEPTH  --"
	if displayed_score!=GameManager.score:
		displayed_score=GameManager.score
		hud_score.text="SCORE  %06d" % displayed_score
	var credits=GameManager.get_credit_wallet()+GameManager.unbanked_rewards
	if displayed_credits!=credits:
		displayed_credits=credits
		hud_credits.text="CREDITS  %03d" % credits
	var profile=GameManager.get_detection_profile()
	var band_name="Stable" if profile["band"]=="GREEN" else str(profile["band"]).capitalize()
	var status_color=Color("#a8d8a0")
	match profile["band"]:
		"YELLOW": status_color=Color("#f4dc61")
		"ORANGE": status_color=AMBER
		"RED": status_color=RED
		"CRITICAL": status_color=Color("#ff2f59")
	mobile_risk.text="Exposure  %d%% · %s" % [int(GameManager.risk),band_name]
	mobile_details.text="Detection  %.0f%%   ·   Unbanked  %d credits" % [float(profile["chance"]),GameManager.unbanked_rewards]
	mobile_risk.add_theme_color_override("font_color",status_color)
	mobile_meter.value=GameManager.risk
	if band_name!=str(mobile_meter.get_meta("band","")):
		var mobile_fill=StyleBoxFlat.new()
		mobile_fill.bg_color=status_color
		mobile_fill.set_corner_radius_all(3)
		mobile_meter.add_theme_stylebox_override("fill",mobile_fill)
		mobile_meter.set_meta("band",band_name)
	var current_risk: float=GameManager.risk
	var risk_integer=int(current_risk)
	# Redraw the instrument once per visible percentage point.
	if displayed_risk_integer==risk_integer:
		return
	displayed_risk=current_risk
	displayed_risk_integer=risk_integer
	meter.value=current_risk
	radar.set_exposure(current_risk)
	backdrop.set_exposure(current_risk)
	var info=GameManager.get_detection_profile()
	var band=str(info["band"])
	# 95-99% and 100% share a colour but have different detection probabilities.
	risk_odds.text="DETECTION CHANCE: %.0f%%" % float(info["chance"])

	if band==displayed_risk_band:
		return
	if GameManager.game_state=="playing" and band in ["RED","CRITICAL"] and displayed_risk_band!="":
		sounds.play_cue("warning")
	displayed_risk_band=band
	risk_band_label.text="Stable" if band=="GREEN" else band.capitalize()
	var accent=CYAN
	match band:
		"YELLOW":accent=Color("#f4dc61")
		"ORANGE":accent=AMBER
		"RED":accent=RED
		"CRITICAL":accent=Color("#ff2f59")
	risk_value.add_theme_color_override("font_color",accent)
	risk_band_label.add_theme_color_override("font_color",accent)
	var fill:StyleBoxFlat=meter.get_theme_stylebox("fill")
	fill.bg_color=accent

func _refresh():
	_update_risk()
	_refresh_armory()
	_refresh_perk_controls()
	if not is_instance_valid(decision_text):
		return
	if GameManager.game_state=="decision":
		var r=GameManager.last_resolution
		var correct=bool(r.get("correct",false))
		var accent=CYAN if correct else RED
		decision_outcome.text="Correct · Cache rewarded" if correct else "No reward this time"
		decision_outcome.add_theme_color_override("font_color",accent)
		var banner_style:StyleBoxFlat=decision_banner.get_theme_stylebox("panel")
		banner_style.border_color=accent
		banner_style.bg_color=Color("#263527") if correct else Color("#342325")
		decision_status.text="You are still in. Choose what happens next."
		decision_status.add_theme_color_override("font_color",TEXT)
		var late="Overtime  %.1f s · Exposure +%.1f" % [r.get("overtime_seconds",0.0),float(r.get("overtime_seconds",0.0))*1.0] if float(r.get("overtime_seconds",0.0))>0.0 else "On time · No overtime exposure"
		var boss_summary=""
		if bool(r.get("is_boss",false)):
			boss_summary="BOSS NODE: "+("SUCCESS: +150 BONUS CREDITS: EXPOSURE -10 POINTS" if correct else "FAILED: EXPOSURE +15 POINTS")+"\n"
		if bool(r.get("blocked_by_ghost_protocol",false)):
			boss_summary+="GHOST PROTOCOL: DETECTION EVENT BLOCKED\n"
		if int(r.get("cache_spike_bonus",0))>0:
			boss_summary+="CACHE SPIKE: +%d CREDITS\n" % int(r["cache_spike_bonus"])
		decision_text.text=boss_summary+late+"\n\n"+str(r.get("explanation",""))

	if GameManager.game_state=="results":
		var just_finished=not results.visible
		timer.stop()
		memory_phase=false
		challenge_resolved=true
		perk_bar.visible=false
		if just_finished:
			sounds.play_cue("detected" if GameManager.run_result=="detected" else "extracted")
			_show_panel(results)
		var summary=GameManager.run_summary
		var title:Label=results.get_node("ResultTitle")
		if GameManager.run_result=="detected":
			title.text="Your signal was found."
			title.add_theme_color_override("font_color",RED)
			results_text.text="OPERATION COMPROMISED\n\nScore: %d\nUnbanked cache lost: %d\nLifetime banked credits: %d\nReached depth: %d\nFinal exposure: %d%%" % [summary.get("score",0),GameManager.run_credits_lost,GameManager.banked_rewards,summary.get("depth",0),int(summary.get("exposure",0))]
		else:
			title.text="Clean extraction."
			title.add_theme_color_override("font_color",CYAN)
			results_text.text="CACHE SECURED\n\nScore: %d\nBanked this run: %d\nLifetime banked credits: %d\nReached depth: %d\nFinal exposure: %d%%" % [summary.get("score",0),GameManager.run_credits_banked,GameManager.banked_rewards,summary.get("depth",0),int(summary.get("exposure",0))]
func _setup_audio():
	sounds=Sounds.new()
	add_child(sounds)
	sounds.set_enabled(GameManager.is_sound_enabled())

func _play_ping():
	sounds.play_cue("radar")











