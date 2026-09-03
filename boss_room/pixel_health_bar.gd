extends ProgressBar
## Code-native pixel UI; keeps the existing Range health contract intact.
@export var boss_style: bool = false
@export var caption: String = "PLAYER"

const INK := Color("101a18")
const WOOD := Color("65472e")
const GOLD := Color("bb9450")
const LIGHT := Color("efdaa0")
const GLYPHS: Dictionary = {
	"A":"010101111101101", "B":"110101110101110", "C":"011100100100011",
	"D":"110101101101110", "E":"111100110100111", "F":"111100110100100",
	"G":"011100101101011", "H":"101101111101101", "I":"111010010010111",
	"J":"001001001101010", "K":"101101110101101", "L":"100100100100111",
	"M":"101111111101101", "N":"101111111111101", "O":"010101101101010",
	"P":"110101110100100", "Q":"010101101111011", "R":"110101110101101",
	"S":"011100010001110", "T":"111010010010010", "U":"101101101101111",
	"V":"101101101101010", "W":"101101111111101", "X":"101101010101101",
	"Y":"101101010010010", "Z":"111001010100111",
	"0":"111101101101111", "1":"010110010010111", "2":"110001111100111",
	"3":"110001010001110", "4":"101101111001001", "5":"111100110001110",
	"6":"011100111101111", "7":"111001010010010", "8":"111101111101111",
	"9":"111101111001110", "/":"001001010100100", "-":"000000111000000",
	" ":"000000000000000"
}

var _trail: float = 1.0
var _last_ratio: float = 1.0
var _hold: float = 0.0
var _initialized: bool = false
var _last_status: String = ""

func _ready() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("background", StyleBoxEmpty.new())
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	value_changed.connect(_on_value_changed)
	changed.connect(queue_redraw)
	resized.connect(queue_redraw)
	visibility_changed.connect(_sync_on_show)
	_sync_on_show()

func _sync_on_show() -> void:
	_trail = _health_ratio()
	_last_ratio = _trail
	_hold = 0.0
	_initialized = true
	queue_redraw()

func _health_ratio() -> float:
	return clampf((value - min_value) / maxf(max_value - min_value, 1.0), 0.0, 1.0)

func _on_value_changed(_value: float) -> void:
	var current: float = _health_ratio()
	if not _initialized or current >= _last_ratio:
		_trail = current
		_hold = 0.0
	else:
		_hold = 0.22
	_last_ratio = current
	_initialized = true
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var current: float = _health_ratio()
	if _trail < current:
		_trail = current
	if _hold > 0.0:
		_hold = maxf(0.0, _hold - delta)
	elif _trail > current:
		_trail = move_toward(_trail, current, delta * 0.8)
		queue_redraw()
	var status: String = _status()
	if status != _last_status:
		_last_status = status
		queue_redraw()

func _status() -> String:
	if boss_style:
		var title: Label = get_node_or_null("../Title")
		if title != null and title.text.contains("DEFEATED"):
			return "DEFEATED"
		if title != null and title.text.contains("ENRAGED"):
			return "ENRAGED"
	return "LOW HP" if not boss_style and _health_ratio() <= 0.25 else ""

func _draw() -> void:
	var width: int = int(size.x)
	if width < 64:
		return
	var bar_x: int = 24 if not boss_style else 14
	var bar_y: int = 12
	var bar_width: int = width - bar_x - (14 if boss_style else 2)
	var hp_text: String = "%d/%d" % [int(value), int(max_value)]
	if boss_style:
		# A carved name plaque, separated from combat space by a dark outline.
		var plaque_width: int = caption.length() * 4 + 12
		var plaque_x: int = int((width - plaque_width) / 2.0)
		_rect(plaque_x, 0, plaque_width, 10, INK)
		_rect(plaque_x + 1, 1, plaque_width - 2, 8, WOOD)
		_rect(plaque_x + 2, 2, plaque_width - 4, 6, Color("283329"))
		_text(caption, Vector2(plaque_x + 6, 3), LIGHT)
	else:
		_text(caption, Vector2(26, 3), LIGHT)
		_text(hp_text, Vector2(width - 3 - hp_text.length() * 4, 3), Color("eff0cf"))
	# Stepped wood outline, gold bevel and inset shadow. No rounded/vector edges.
	_rect(bar_x + 2, bar_y + 2, bar_width, 13, Color(0, 0, 0, 0.45))
	_rect(bar_x + 1, bar_y, bar_width - 2, 13, INK)
	_rect(bar_x, bar_y + 2, bar_width, 9, INK)
	_rect(bar_x + 1, bar_y + 2, bar_width - 2, 9, WOOD)
	_rect(bar_x + 2, bar_y + 1, bar_width - 4, 1, GOLD)
	_rect(bar_x + 2, bar_y + 11, bar_width - 4, 1, Color("352b23"))
	_rect(bar_x + 3, bar_y + 3, bar_width - 6, 7, Color("1b2421"))
	_rect(bar_x + 3, bar_y + 3, bar_width - 6, 1, Color("080f10"))
	var fill_width: int = bar_width - 8
	var fill: int = int(round(fill_width * _health_ratio()))
	var trail: int = int(round(fill_width * _trail))
	_rect(bar_x + 4, bar_y + 4, trail, 5, Color("d6ad66"))
	var body := Color("b84132") if boss_style else Color("549663")
	var shine := Color("f1834c") if boss_style else Color("a4ca7b")
	var shade := Color("742c32") if boss_style else Color("2d5748")
	if not boss_style and _health_ratio() <= 0.25:
		body = Color("be553c")
		shine = Color("f59b63")
		shade = Color("733b32")
	_rect(bar_x + 4, bar_y + 4, fill, 5, body)
	_rect(bar_x + 4, bar_y + 4, fill, 1, shine)
	_rect(bar_x + 4, bar_y + 8, fill, 1, shade)
	for i in range(1, 5):
		var tick: int = int(round(fill_width * i / 5.0))
		_rect(bar_x + 4 + tick, bar_y + 4, 1, 5, Color(0.04, 0.1, 0.08, 0.28))
	for edge in [bar_x + 1, bar_x + bar_width - 3]:
		_rect(edge, bar_y + 5, 2, 3, INK)
		_rect(edge, bar_y + 5, 1, 1, LIGHT)
	# Small moss shoots tie the carved frame to the forest arena.
	for edge in [bar_x + 5, bar_x + bar_width - 8]:
		_rect(edge, bar_y - 1, 3, 2, Color("45633a"))
		_rect(edge + 1, bar_y - 2, 2, 1, Color("90a65d"))
	if boss_style:
		_helmet(Vector2(0, 8))
		_helmet(Vector2(width - 13, 8))
		_text(hp_text, Vector2(int((width - hp_text.length() * 4) / 2.0), 27), LIGHT)
		var status: String = _status()
		if not status.is_empty():
			_text(status, Vector2(width - 15 - status.length() * 4, 27), Color("f5a15e"))
	else:
		_heart(Vector2(0, 7))
		if _health_ratio() <= 0.25:
			_text("LOW HP", Vector2(26, 27), Color("f5a15e"))

func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	if w > 0 and h > 0:
		draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), color)

func _text(text: String, at: Vector2, color: Color) -> void:
	# Tiny hand-authored 3x5 bitmap alphabet stays crisp at the game's 3x scale.
	for i in range(text.length()):
		var bits: String = GLYPHS.get(text[i].to_upper(), GLYPHS[" "])
		for p in range(15):
			if bits[p] == "1":
				_rect(at.x + i * 4 + p % 3 + 1, at.y + int(p / 3) + 1, 1, 1, INK)
		for p in range(15):
			if bits[p] == "1":
				_rect(at.x + i * 4 + p % 3, at.y + int(p / 3), 1, 1, color)

func _heart(at: Vector2) -> void:
	_rect(at.x + 2, at.y, 18, 18, INK)
	_rect(at.x + 1, at.y + 2, 20, 14, INK)
	_rect(at.x + 3, at.y + 1, 16, 16, GOLD)
	_rect(at.x + 4, at.y + 2, 14, 14, Color("29392b"))
	var rows: Array[String] = ["01100110", "11111111", "11111111", "11111111", "01111110", "00111100", "00011000"]
	for y in range(rows.size()):
		for x in range(8):
			if rows[y][x] == "1":
				_rect(at.x + 7 + x, at.y + 5 + y, 1, 1, Color("df654d") if y < 4 else Color("983c39"))
	_rect(at.x + 8, at.y + 6, 2, 1, Color("ffba85"))

func _helmet(at: Vector2) -> void:
	_rect(at.x + 2, at.y, 9, 18, INK)
	_rect(at.x, at.y + 4, 13, 10, INK)
	_rect(at.x + 2, at.y + 2, 9, 13, WOOD)
	_rect(at.x + 3, at.y + 1, 7, 13, GOLD)
	_rect(at.x + 4, at.y + 2, 5, 2, LIGHT)
	_rect(at.x + 3, at.y + 6, 7, 3, INK)
	_rect(at.x + 5, at.y + 9, 1, 4, Color("e4b665"))
	_rect(at.x + 3, at.y + 14, 7, 2, Color("a84b35"))
