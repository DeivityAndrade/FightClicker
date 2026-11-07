extends SceneTree
func achar(n: Node, tipo: String, texto: String) -> Node:
	if n.get_class() == tipo and ("text" in n) and str(n.text).begins_with(texto): return n
	for c in n.get_children():
		var r = achar(c, tipo, texto)
		if r: return r
	return null
func _initialize() -> void:
	var gs = root.get_node("GameState")
	var cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	var d = "user://test/qa_ui/"
	var t0 = gs.treino
	achar(cena, "Button", "+1").emit_signal("pressed")
	print("QA +1: ", t0, " -> ", gs.treino)
	for i in 8: achar(cena, "Button", "x1").emit_signal("pressed")
	await create_timer(0.3).timeout
	print("QA apos 8x x1000: ", gs.treino, " label=", achar(cena, "Label", "Treino:").text)
	for i in 4: achar(cena, "Button", "x1").emit_signal("pressed")
	print("QA total 12x: ", gs.treino, " finito=", is_finite(gs.treino))
	achar(cena, "Button", "Salvar").emit_signal("pressed")
	print("QA save existe: ", FileAccess.file_exists(d + "save.json"))
	achar(cena, "Button", "Apagar").emit_signal("pressed")
	await process_frame
	var dlg = achar(cena, "ConfirmationDialog", "") 
	var dialogs = cena.find_children("*", "ConfirmationDialog", true, false)
	print("QA dialogo visivel: ", dialogs[0].visible, " save ainda existe: ", FileAccess.file_exists(d + "save.json"), " treino=", gs.treino)
	dialogs[0].get_cancel_button().emit_signal("pressed")
	await process_frame
	print("QA apos cancelar: existe=", FileAccess.file_exists(d + "save.json"), " treino=", gs.treino)
	dialogs[0].emit_signal("confirmed")
	await process_frame
	print("QA apos confirmar: existe=", FileAccess.file_exists(d + "save.json"), " treino=", gs.treino)
	quit(0)
