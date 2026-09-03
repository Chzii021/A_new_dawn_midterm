extends Control

const WORLD_SCENE := "res://scenes/world.tscn"
const SLIDE_TIME := 6.5

const SLIDES: Array[Dictionary] = [
	{"image": "res://art/opening_story/01_bangkok_call.png", "text": "วิกรมใช้ชีวิตทำงานอยู่ในกรุงเทพฯ จนกระทั่งได้รับสายจากคุณยาย", "tone": 440.0},
	{"image": "res://art/opening_story/02_grandmother_warning.png", "text": "คุณยายขอให้เขากลับบ้าน เพราะหมู่บ้านกำลังถูกภัยลึกลับคุกคาม", "tone": 350.0},
	{"image": "res://art/opening_story/03_abandoned_village.png", "text": "เมื่อกลับมาถึง วิกรมพบว่าหมู่บ้านที่เคยคึกคักแทบกลายเป็นหมู่บ้านร้าง", "tone": 280.0},
	{"image": "res://art/opening_story/04_haunted_khaen.png", "text": "ต้นเหตุเกิดจากภูติผีที่เข้าสิงแคนเก่าแก่ของคุณยาย", "tone": 190.0},
	{"image": "res://art/opening_story/05_village_attack.png", "text": "แคนผีสิงออกอาละวาด จนชาวบ้านหวาดกลัวและพากันหลบหนี", "tone": 150.0},
	{"image": "res://art/opening_story/06_wikrom_resolves.png", "text": "วิกรมจึงตัดสินใจเผชิญหน้ากับภูติผี เพื่อช่วยคุณยายและฟื้นฟูหมู่บ้านอีกครั้ง", "tone": 520.0}
]

@onready var picture: TextureRect = $Picture
@onready var caption: Label = $CaptionPanel/Margin/Caption
@onready var fade: ColorRect = $Fade
@onready var cue_player: AudioStreamPlayer = $CueSound
@onready var timer: Timer = $AdvanceTimer

var slide_index := 0
var changing := false
var movement_tween: Tween


func _ready() -> void:
	$StoryMusic.bus = &"Music"
	cue_player.bus = &"SFX"
	$StoryMusic.play()
	timer.timeout.connect(_advance)
	resized.connect(_restart_pan)
	_show_slide(0, true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right"):
		_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _show_slide(index: int, first: bool = false) -> void:
	changing = true
	timer.stop()
	if not first:
		var cover: Tween = create_tween()
		cover.tween_property(fade, "color:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
		await cover.finished
	picture.texture = load(str(SLIDES[index]["image"])) as Texture2D
	caption.text = str(SLIDES[index]["text"])
	caption.modulate.a = 0.0
	await get_tree().process_frame
	_restart_pan()
	_play_cue(float(SLIDES[index]["tone"]), index >= 3)
	var reveal: Tween = create_tween().set_parallel(true)
	reveal.tween_property(fade, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	reveal.tween_property(caption, "modulate:a", 1.0, 0.8).set_delay(0.25)
	await reveal.finished
	changing = false
	timer.start(SLIDE_TIME)


func _restart_pan() -> void:
	if not is_instance_valid(picture):
		return
	if movement_tween and movement_tween.is_valid():
		movement_tween.kill()
	picture.pivot_offset = picture.size * 0.5
	var move_left: bool = slide_index % 2 == 0
	picture.scale = Vector2(1.1, 1.1)
	picture.position = Vector2(-10.0 if move_left else 10.0, -5.0)
	movement_tween = create_tween().set_parallel(true)
	movement_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement_tween.tween_property(picture, "scale", Vector2(1.035, 1.035), SLIDE_TIME + 1.8)
	movement_tween.tween_property(picture, "position", Vector2(10.0 if move_left else -10.0, 5.0), SLIDE_TIME + 1.8)


func _advance() -> void:
	if changing:
		return
	slide_index += 1
	if slide_index >= SLIDES.size():
		_finish_story()
		return
	_show_slide(slide_index)


func _finish_story() -> void:
	changing = true
	timer.stop()
	var ending: Tween = create_tween().set_parallel(true)
	ending.tween_property(fade, "color:a", 1.0, 0.75)
	ending.tween_property($StoryMusic, "volume_db", -45.0, 0.75)
	await ending.finished
	get_tree().change_scene_to_file(WORLD_SCENE)


func _play_cue(frequency: float, ominous: bool) -> void:
	var rate := 22050
	var duration := 0.7 if ominous else 0.35
	var samples := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for i in samples:
		var envelope: float = sin(PI * float(i) / float(samples))
		var wave: float = sin(TAU * frequency * float(i) / float(rate))
		if ominous:
			wave = wave * 0.65 + sin(TAU * frequency * 0.5 * float(i) / float(rate)) * 0.35
		bytes.encode_s16(i * 2, int(wave * envelope * 5000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = bytes
	cue_player.stream = sound
	cue_player.play()


func _on_skip_pressed() -> void:
	if not changing:
		_finish_story()

