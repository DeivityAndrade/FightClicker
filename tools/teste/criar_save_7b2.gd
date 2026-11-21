extends SceneTree
## Cria um save de TESTE para a fase 7b2 (passiva 2 das 3 artes) em user:// (pasta do APPDATA de teste).
## Só roda se o APPDATA for o de teste (nunca toca o save real do dono). Use pelo jogar_teste_7b2.ps1.
const GS := preload("res://scripts/game_state.gd")

func _initialize() -> void:
	await process_frame
	var appdata := OS.get_environment("APPDATA")
	if not appdata.contains("FightclickerTeste"):
		print("ERRO: APPDATA nao e o de teste (%s). Abortando." % appdata)
		quit(1)
		return
	var gs: Node = GS.new()
	gs.inicializar("user://", "res://data/config.json")
	gs.autosave_ativo = false
	# Prólogo e cena da 1ª chegada já vistos (o dono cai direto na escolha da arte)
	gs._gravar_marco("prologue_seen", {}, false)
	gs._gravar_marco(str(gs.escola_cfg.gym_arrival.milestone), {}, false)
	# Chegou à academia com as 3 artes liberadas (Muay Thai incluída)
	gs.local_id = "gym"
	var ids: Array = []
	for a in gs.academia.artes:
		ids.append(a.id)
	gs.permanente["arts_unlocked"] = ids
	gs._gravar_marco("muay_thai_unlocked", {}, false)
	gs.escola["lines_seen"]["cl_muay_thai"] = 1  # a fala do Osmar da liberação já passou
	# 2/3 em cada arte, 2ª passiva ainda travada
	var vit := {}
	for id in ids:
		vit[id] = 2
	gs.permanente["passive_wins"] = vit
	gs.permanente["passives_unlocked"] = []
	gs.permanente["last_passive"] = {}
	# Começo de carreira, sem arte (escolha aberta), atributos grandes e dinheiro
	gs.arte_id = ""
	gs.passiva_carreira = 1
	gs.indice_escada = 0
	gs.atributos = {"strength": 3.0e6, "agility": 2.5e6, "endurance": 2.0e6}
	gs.dinheiro = 1.0e6
	var ok: bool = gs.salvar()
	print("save de teste 7b2 salvo: %s (escolha pendente: %s)" % [str(ok), str(gs.escolha_arte_pendente())])
	gs.free()
	quit(0 if ok else 1)
