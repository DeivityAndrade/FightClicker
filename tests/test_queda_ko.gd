extends "res://tests/test_base.gd"
## Quedas de K.O. por golpe (ko_back / ko_knees) e barra de especial, com a tela de luta de verdade rodando a animação inteira
## contra TODOS os adversários: a arte existe (jogador com as 4 luvas e os 6 adversários), a queda escolhida combina com o golpe
## final, o corpo bate no chão num quadro válido, nada quebra e o time_scale volta ao normal.

const ADVERSARIOS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
const QUEDAS := ["ko_back", "ko_knees"]

var gs: Node
var U: GDScript  # UiTema, carregado em tempo de execução (os autoloads só existem depois do início)


func rodar_testes() -> void:
	gs = root.get_node("GameState")
	U = load("res://ui/ui_tema.gd")
	_teste_arte()
	await _teste_animacao()


func _teste_arte() -> void:
	for q in QUEDAS:
		for suf in ["", "_glove_l1", "_glove_l2", "_glove_l3"]:
			var s: Dictionary = U.sprite("fight_player_%s%s" % [q, suf])
			checar(not s.is_empty(), "jogador tem %s%s" % [q, suf])
			if not s.is_empty():
				checar(int(s.get("ground_frame", -1)) >= 0 and int(s.get("ground_frame", -1)) < int(s.frames), "jogador %s%s: ground_frame dentro dos quadros" % [q, suf])
		for oid in ADVERSARIOS:
			var s: Dictionary = U.sprite("%s_%s" % [oid, q])
			checar(not s.is_empty(), "%s tem %s" % [oid, q])
			if not s.is_empty():
				checar(int(s.get("ground_frame", -1)) >= 0 and int(s.get("ground_frame", -1)) < int(s.frames), "%s %s: ground_frame dentro dos quadros" % [oid, q])
				checar(ResourceLoader.exists(str(s.file)), "%s %s: a imagem existe e foi importada" % [oid, q])


func _luta_com_ko(forca_alta: bool) -> Dictionary:
	gs.inicializar(pasta_limpa("queda_ko"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.atributos = {"strength": 1000.0 if forca_alta else 5.0, "agility": 100.0, "endurance": 700.0 if forca_alta else 5.0}
	for semente in range(1, 200):
		gs.rng.seed = semente
		var info: Dictionary = gs.lutar()
		if info.is_empty():
			return {}
		if bool(info.result.ko):
			return gs.luta_atual()
		gs.aguardar_motivo()
		gs.luta = {}
	return {}


func _teste_animacao() -> void:
	var tela_script: GDScript = load("res://ui/tela_luta.gd")
	for forcar in ["", "ko_back", "ko_knees"]:
		for ganha in [true, false]:
			var info := _luta_com_ko(ganha)
			checar(not info.is_empty(), "achou luta com K.O. (forcar=%s, ganha=%s)" % [forcar, ganha])
			if info.is_empty():
				continue
			for oid in ADVERSARIOS:
				tela_script.set("forcar_ko", forcar)
				var d: Dictionary = info.duplicate(true)
				d["opponent"] = oid  # a arte muda por adversário; os eventos (golpes) são os mesmos
				var tela: Control = tela_script.new()
				root.add_child(tela)
				await process_frame
				tela.iniciar(d)
				var passos := 0
				while not tela.finalizada and passos < 3000:
					tela._process(0.05)
					passos += 1
				var ctx := "%s forcar=%s ganha=%s" % [oid, forcar, ganha]
				checar(tela.finalizada, ctx + ": a luta animada chegou ao fim")
				var ko: String = tela._ko_nome
				checar(ko in ["ko", "ko_back", "ko_knees"], ctx + ": queda válida (" + ko + ")")
				if forcar != "":
					checar_igual(ko, forcar, ctx + ": a queda forçada vale")
				var perdedor: int = int(d.loser)
				if perdedor >= 0:
					var nome_spr: String = tela._l[perdedor].spr.nome_sprite
					checar(nome_spr.contains(ko if ko != "ko" else "_ko"), ctx + ": o perdedor caiu com a arte certa (" + nome_spr + ")")
				tela.encerrar()
				checar_igual(Engine.time_scale, 1.0, ctx + ": time_scale voltou ao normal")
				tela.queue_free()
				await process_frame
				gs.luta = d  # concluir_luta() consome a luta: devolve para a próxima rodada
	tela_script.set("forcar_ko", "")
	# Limpeza: sem isso o Godot acusa recursos/objetos vazados na saída e o executor de testes reprova.
	gs.luta = {}
	U = null
	tela_script = null
	await create_timer(1.6, true, false, true).timeout  # deixa terminar os congelamentos (_congelar) ainda pendentes
	await process_frame
