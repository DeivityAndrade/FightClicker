extends SceneTree
## QA 6d3: numeros flutuantes com nome inteiro; extremos (ganho 1 a 1e15), cliques nas bordas, critico, 3 atributos.
## godot --headless --path . --script res://tests/qa_f6d3_numeros.gd   (APPDATA temporario!)
var gs: Node
var cena: Node
var falhas := 0
func ok(c: bool, n: String) -> void:
	if not c: falhas += 1
	if not c: print("FAIL  ", n)
func esperar(s: float) -> void:
	await create_timer(s).timeout
func _initialize() -> void:
	gs = root.get_node("GameState")
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar("user://test/qa6d3num/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.indice_escada = 4; gs.cinturao = true; gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]; gs.permanente["last_art"] = "bjj"; gs.arte_id = "bjj"
	gs._atualizar_traco()
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill", "jump_rope", "grappling_dummy", "speed_bag"]
	gs.treino = 1.0e18
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.8)
	var sala: Node = cena.get_node("Sala")
	var dados = gs.dados
	var rx := RegEx.create_from_string(" (FOR|AGI|RES)!?$")
	var total := 0
	var maxw := 0.0
	for foco in ["grappling_dummy", "speed_bag", "punching_bag", "treadmill", "jump_rope"]:
		gs.foco = foco
		for base in [0.001, 1.0, 100.0, 12345.0, 1.0e6, 9.99e9, 1.0e15, 1.0e30]:
			for crit in [false, true]:
				for ponto in [Vector2(2, 100), Vector2(638, 100), Vector2(336, 222), Vector2(320, 5), Vector2(638, 350), Vector2(2, 350)]:
					dados.base_training = base
					dados.crit_chance = 1.0 if crit else 0.0
					sala._pos_clique = ponto
					var antes := {}
					for n in sala._numeros:
						if n.ativo: antes[n] = true
					gs.clicar()
					await process_frame
					var novos := 0
					for n in sala._numeros:
						if not n.ativo or antes.has(n): continue
						novos += 1
						var t := str(n._principal.text)
						total += 1
						ok(not rx.search(t), "sigla em '%s'" % t)
						var r: Rect2 = n.retangulo()
						if r.position.x < 0.0 or r.end.x > 640.0:
							ok(false, "fora da sala foco=%s base=%s crit=%s ponto=%s texto='%s' ret=%s" % [foco, base, crit, ponto, t, r])
						maxw = maxf(maxw, r.size.x)
					ok(novos <= 3, "mais de 3 novos: %d (foco %s base %s)" % [novos, foco, base])
					await esperar(0.1)
	print("numeros vistos: ", total, " maior largura ", maxw, " FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)
