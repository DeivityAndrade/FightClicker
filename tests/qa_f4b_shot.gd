extends SceneTree
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa4b/"
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = root.get_node("GameState")
	gs.autosave_ativo = false
	var cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	for i in 20: await process_frame
	gs.apagar_save()
	for i in 5: await process_frame
	gs.dinheiro = 100.0
	var dir = cena.get_node("PainelLoja")
	dir._hover = "m"
	dir._emitir_info()
	for i in 10: await process_frame
	root.get_texture().get_image().save_png(OUT + "metro_hover.png")
	# hover em atributo trancado
	var esq = cena.get_node("PainelAtributos")
	var inf = gs.dados.atributo_info("endurance")
	esq.mostrar_info({"titulo": str(inf.get("name", "")), "texto": str(inf.get("hint", "")), "extra": esq._aviso_trancado("endurance")})
	for i in 10: await process_frame
	root.get_texture().get_image().save_png(OUT + "attr_hover.png")
	quit(0)
