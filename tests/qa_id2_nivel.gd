extends SceneTree
## QA ID2: mede o contador "0/4" das MELHORIAS (borda do cartão) e confere as regras do verificador.
func _initialize() -> void:
	var gs: Node = root.get_node("GameState")
	gs.inicializar("user://test/qa_id2/", "user://test/qa_id2_cfg.cfg")
	gs.autosave_ativo = false
	gs.pular_abertura()
	gs.treino = 1234.0
	var cena: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	await create_timer(0.6).timeout
	var achou := 0
	for l in cena.find_children("*", "Label", true, false):
		var t: String = l.text
		if t.length() == 3 and t[1] == "/":
			var card: Control = l.get_parent()
			var f: Font = l.get_theme_font("font")
			var fs: int = l.get_theme_font_size("font_size")
			var w: float = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var off: float = (l.size.x - w) / 2.0
			print("NIVEL '%s' label x=%.1f size=%s autowrap=%d texto_w=%.1f -> texto comeca em x_cartao=%.1f (borda do cartao=0) align=%d ui_align=%s" % [t, l.position.x, l.size, l.autowrap_mode, w, l.position.x + off, l.horizontal_alignment, str(l.get_meta("ui_align", "-"))])
			print("   card meta ui_indent=%s card size=%s" % [str(card.get_meta("ui_indent", "-")), card.size])
			achou += 1
	print("ACHADOS ", achou)
	quit(0)
