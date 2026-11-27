extends SceneTree
## Cria um save de TESTE para a Ronda 2a2 (o chefe Apagão) em user:// (pasta do APPDATA de teste).
## Academia, campanha 9, Boxe, linhagem com o Cinturão do Vale, lenda 64 (nível 5) e os 3 bandidos do beco já vencidos:
## o Apagão está liberado. O capuz aparece poucos segundos depois de abrir a sala.
## "-- --forte": atributos bem maiores, para ver a vitória, o prêmio e tentar o desafio ANTES DO APAGÃO.
## Só roda se o APPDATA for o de teste (nunca toca o save real do dono). Use pelo jogar_teste_2a2.ps1.
const GS := preload("res://scripts/game_state.gd")


func _initialize() -> void:
	await process_frame
	var appdata := OS.get_environment("APPDATA")
	if not appdata.contains("FightclickerTeste"):
		print("ERRO: APPDATA nao e o de teste (%s). Abortando." % appdata)
		quit(1)
		return
	var forte := "--forte" in OS.get_cmdline_user_args()
	var gs: Node = GS.new()
	gs.inicializar("user://", "res://data/config.json")
	gs.autosave_ativo = false
	gs._gravar_marco("prologue_seen", {}, false)
	gs._gravar_marco(str(gs.escola_cfg.gym_arrival.milestone), {}, false)
	for id in ["cl_primeira_academia", "cl_liga_regional", "cl_cinturao_regional"]:
		gs.escola["lines_seen"][id] = 1
	gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.arte_id = ""
	gs.passiva_carreira = 1
	gs.escolher_arte("boxing", 1)
	gs.pular_abertura()
	# linhagem: 9ª campanha, Cinturão do Vale já conquistado numa campanha anterior
	gs.permanente["career_number"] = 9
	gs.permanente["regional_belts"] = 1
	gs.permanente["first_regional_belt_campaign"] = 6
	gs._gravar_marco("regional_league_opened", {}, false)
	gs._gravar_marco("regional_belt_first", {}, false)
	gs._gravar_marco("black_cat_rumor_heard", {}, false)
	# Gato Preto: lenda 64 (nível 5) e os 3 bandidos vencidos nas campanhas 5, 6 e 7
	var lenda := int(RondaData.carregar().niveis[4])
	var alley := {}
	var ids: Array = ["tire", "bike", "gate"]
	for i in ids.size():
		alley[ids[i]] = {"won": 1, "lost": 0, "first_win_campaign": 5 + i, "challenge": false}
	gs.permanente["black_cat"] = {"legend": lenda, "rounds": 14, "scares": 9, "shown_level": gs.ronda_cfg.nivel_de(lenda),
		"open_campaign": 3, "alley": alley}
	# campanha atual: academia, a meio caminho, sem luta marcada para hoje
	gs.indice_escada = 3
	gs.fama = 400
	gs.dinheiro = 50000.0
	var base := 3.0e9 if forte else 7.9e8  # 7,9e8: chance perto de 50% na prévia; 3e9: 100%
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--base="):
			base = float(str(a).trim_prefix("--base="))
	gs.atributos = {"strength": base, "agility": base, "endurance": base}
	gs.fight_day = -1
	gs.capuz = {"hood_s": 0.0, "next_at": 5.0, "open": ""}  # o capuz aparece ~5 s depois de abrir a sala
	var ok: bool = gs.salvar()
	print("save de teste 2a2 salvo: %s (campanha %d, lenda %d, chefe aberto: %s, falta: '%s', atributos %s)" % [str(ok),
		gs.numero_carreira(), int(gs.permanente.black_cat.legend), str(gs.chefe_aberto()), gs.chefe_falta(), str(base)])
	gs.free()
	quit(0 if ok else 1)
