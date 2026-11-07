extends SceneTree
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/d03e7314839aa25e/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/final2/"
var gs: Node


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(nome: String) -> void:
	root.get_texture().get_image().save_png(OUT + nome + ".png")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	var cena: Node = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	await frames(10)
	gs.aplicar_save({})
	await frames(40)
	shot("a_inicio")
	gs.treino = 1e6
	gs.comprar_gerador("neighbor_kid")
	gs.comprar_gerador("neighbor_kid")
	gs.comprar_gerador("retired_uncle")
	gs.comprar_melhoria("punching_bag")
	gs.definir_foco("punching_bag")
	await frames(30)
	for i in 6:
		gs.clicar()
		await frames(4)
	await frames(6)
	shot("b_meio")
	await frames(60)
	var ok := false
	for i in 400:
		if gs.clicar().critico:
			ok = true
			break
	await frames(8)
	shot("c_critico")
	print("critico=", ok)
	await frames(60)
	gs.definir_foco("jump_rope")
	await frames(40)
	shot("d_corda")
	quit(0)
