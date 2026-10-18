class_name ActionBar
extends Control
## What you can do with the selected thing, base-builder style: its name and
## level on a ribbon, and a row of big round buttons underneath (Info,
## Upgrade with its price, Model for a server, Staff, Move, Finish now with
## gems while a builder is busy on it, Clear for an obstacle...).

signal action(id: String)

var _title: Label
var _sub: Label
var _row: HBoxContainer
var _box: VBoxContainer
var _buttons := {}
var _sig := ""
var _target := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = Kit.vbox(6)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", Kit.skin("card_dark", 30, Vector4(22, 8, 22, 12)))
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(head)
	var hv := Kit.vbox(-2)
	head.add_child(hv)
	_title = Kit.game("", 28, Kit.WHITE, 6)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(_title)
	_sub = Kit.game("", 17, Color(1.0, 0.88, 0.6), 4)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.custom_minimum_size.x = 360
	hv.add_child(_sub)
	_row = Kit.hbox(10)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(_row)


func set_title(t: String, sub: String) -> void:
	_title.text = t
	_sub.text = sub
	_sub.visible = sub != ""


## buttons: [[id, icon, label, face(Color), enabled(bool)], ...]
func set_buttons(buttons: Array, target := "") -> void:
	var sig := str(buttons)
	if sig == _sig and target == _target:
		return
	var fresh := target != _target
	_sig = sig
	_target = target
	for c in _row.get_children():
		c.queue_free()
	_buttons.clear()
	for b in buttons:
		var btn := _button(b[0], b[1], b[2], b[3], b[4] if b.size() > 4 else true)
		_buttons[b[0]] = btn
		_row.add_child(btn)
	if fresh:
		Kit.pop_in.call_deferred(_box, 0.0, 0.25)


func _button(id: String, icon: String, label: String, face: Color, enabled: bool) -> Control:
	var w := 112.0 if _row.get_child_count() < 6 else 96.0
	var b := Kit.juicy("", face if enabled else Kit.GREY, Kit.SAGE_EDGE, 16, Vector2(w, 112))
	b.row.queue_free()
	var v := Kit.vbox(-4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_bottom = -10
	b.add_child(v)
	var ic := Kit.icon(icon, 54)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := Kit.game(label, 16, Kit.WHITE, 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	b.row = Kit.hbox()
	b.pressed.connect(func(): action.emit(id))
	return b


## The button for an action (null if not shown).
func find(id: String) -> Control:
	var b: Control = _buttons.get(id)
	return b if is_instance_valid(b) and is_visible_in_tree() else null


func layout(vs: Vector2) -> void:
	_box.size = Vector2(vs.x, 0)
	_box.size = Vector2(vs.x, _box.get_combined_minimum_size().y)
	_box.position = Vector2(0, vs.y - _box.size.y - 28)
