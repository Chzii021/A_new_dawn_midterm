extends RefCounted
## Shared code-native pixel palette. No rounded corners or fractional UI scaling.
static func box(fill: Color, edge: Color, border: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_content_margin_all(4)
	return style

static func create_theme() -> Theme:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	theme.default_font = font
	theme.default_font_size = 8
	theme.set_color("font_color", "Label", Color("e8d9aa"))
	theme.set_color("font_shadow_color", "Label", Color("101b17"))
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_stylebox("panel", "PanelContainer", box(Color("172d25"), Color("947344"), 2))
	theme.set_stylebox("normal", "Button", box(Color("354f32"), Color("a28950")))
	theme.set_stylebox("hover", "Button", box(Color("526b3f"), Color("ebcc83")))
	theme.set_stylebox("pressed", "Button", box(Color("223c2b"), Color("bf9b50")))
	theme.set_stylebox("disabled", "Button", box(Color("29362b"), Color("4b5840")))
	var focus := box(Color.TRANSPARENT, Color("f1d486"))
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(key, "Button", Color("f1dc9d"))
	theme.set_color("font_disabled_color", "Button", Color("829077"))
	theme.set_stylebox("scroll", "VScrollBar", box(Color("101d18"), Color("354a32")))
	for key in ["grabber", "grabber_highlight", "grabber_pressed"]:
		theme.set_stylebox(key, "VScrollBar", box(Color("8b784b"), Color("c4ae6c")))
	return theme

static func margins(node: MarginContainer, value: int) -> void:
	for side in ["left", "top", "right", "bottom"]:
		node.add_theme_constant_override("margin_" + side, value)
