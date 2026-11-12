extends SceneTree
## QA 5.1: captura corda+boneco+luva em caixa na garagem e na academia.
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa51/"
func frames(n: int) -> void:
	for i in n:
		await process_frame
func shot(n: String) -> void:
	root.get_texture().get_image().save_png(OUT + n + ".png")
func _initialize() -> void:
	var gs = root.get_node("GameState")
	gs.autosave_ativo = false
	var cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	await frames(20)
	gs.apagar_save()
	await frames(3)
	gs.treino = 1e7; gs.dinheiro = 1e6
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.arte_id = "bjj"
	gs.aplicar_save(gs.estado_para_salvar() if gs.has_method("estado_para_salvar") else {}) if false else null
	gs.comprar_aparelho("treadmill"); gs.abrir_caixa("treadmill")
	gs.comprar_aparelho("jump_rope"); gs.comprar_aparelho("grappling_dummy"); gs.comprar_luva()
	gs.caixas_mudaram.emit()
	await frames(40)
	print("QA| caixas=", gs.caixas())
	shot("bjj_3caixas")
	gs.abrir_caixa("jump_rope")
	gs.definir_foco("grappling_dummy") if gs.aparelho_montado("grappling_dummy") else null
	await frames(30)
	shot("bjj_2caixas")
	quit(0)
