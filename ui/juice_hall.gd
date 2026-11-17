extends Node
## Juice helper for Fase 6c2 (Hall tree, mural, honor).
## Provides tween-based punch, float number, and screen shake.
## Wire signals from GameState when API is ready.

@export var punch_scale := Vector2(1.15, 1.15)
@export var punch_duration := 0.08
@export var float_duration := 0.7
@export var float_rise := 24.0
@export var shake_strength := 3.0
@export var shake_duration := 0.12


func punch(control: Control) -> void:
	if control == null:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(control, "scale", punch_scale, punch_duration)
	tw.tween_property(control, "scale", Vector2.ONE, punch_duration)


func float_number(text: String, pos: Vector2, parent: Control, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lbl.set_meta("ui_align", "ignore")
	parent.add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - float_rise, float_duration).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, float_duration).set_delay(float_duration * 0.6)
	tw.chain().tween_callback(lbl.queue_free)


func shake(camera: Camera2D) -> void:
	if camera == null:
		return
	var original := camera.offset
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	var steps := 4
	var step_time := shake_duration / float(steps)
	for i in steps:
		var offset := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tw.tween_property(camera, "offset", original + offset, step_time)
	tw.tween_property(camera, "offset", original, step_time)