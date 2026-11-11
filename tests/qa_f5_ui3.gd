extends SceneTree
## QA Fase 5 (rodada 2): luta na academia gravada em capturas a cada 1,5 s (rounds, barra de especial, banners).
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa5c/"
var gs: Node
var cena: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	gs = root.get_node("GameState")
	await process_frame
	for caso in [["a", 4, "boxing", 0.85, 7], ["b", 5, "bjj", 0.6, 9]]:
		gs.inicializar("user://test/qa_f5_ui3/", "res://data/config.json")
		gs.autosave_ativo = false
		gs.apagar_save()
		gs.indice_escada = caso[1]
		gs.cinturao = true
		gs.fama = 300
		gs.dinheiro = 1000.0
		gs.mudar()
		gs.escolher_arte(caso[2])
		var opp: Dictionary = gs.proximo_adversario()
		var f: float = caso[3]
		gs.atributos = {"strength": opp.strength * f, "agility": opp.agility * f, "endurance": opp.endurance * f}
		gs.rng.seed = caso[4]
		cena = load("res://scenes/main.tscn").instantiate()
		root.add_child(cena)
		await create_timer(0.6, true, false, true).timeout
		gs.lutar()
		var t := 0.0
		var fluxo: Node = cena.get_node("Fluxo")
		var n := 0
		while t < 30.0:
			await create_timer(1.5, true, false, true).timeout
			t += 1.5
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s%s_%02d.png" % [OUT, caso[0], n])
			n += 1
			if fluxo.janela != null and not fluxo.tela.visible:
				break
		print("caso %s: %d capturas, janela=%s" % [caso[0], n, fluxo.janela])
		cena.queue_free()
		await process_frame
		await process_frame
	quit(0)
