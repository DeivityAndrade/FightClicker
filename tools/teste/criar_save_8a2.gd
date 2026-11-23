extends SceneTree
## Cria um save de TESTE para a fase 8a2 (centro de treinamento) em user:// (pasta do APPDATA de teste).
## "-- --vale": academia, James ja vencido NESTA campanha (Cinturao do Vale), dinheiro de sobra: basta clicar MUDAR.
## "-- --patrocinio": campanha 2 (discipulo), linhagem com o Cinturao do Vale e ja com a chegada ao centro feita, 22.000 de Legado
##   guardado (regiao CENTRO da arvore), a 2 dias do Tonhao com fama perto de 200 (a proposta do patrocinador sai nesta vitoria).
## So roda se o APPDATA for o de teste (nunca toca o save real do dono). Use pelo jogar_teste_8a2.ps1.
const GS := preload("res://scripts/game_state.gd")


func _initialize() -> void:
	await process_frame
	var appdata := OS.get_environment("APPDATA")
	if not appdata.contains("FightclickerTeste"):
		print("ERRO: APPDATA nao e o de teste (%s). Abortando." % appdata)
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var patro := "--patrocinio" in args
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
	# campanha 1: Cinturao do Vale conquistado (James vencido), campanha completa na academia
	gs.indice_escada = gs.lutas.adversarios.size()
	gs.cinturao = true
	gs.fama = 1500
	gs.permanente["regional_belts"] = 1
	gs.permanente["first_regional_belt_campaign"] = gs.numero_carreira()
	gs._gravar_marco("regional_league_opened", {}, false)
	gs._gravar_marco("regional_belt_first", {}, false)
	gs.fight_day = -1
	gs.atributos = {"strength": 3.0e8, "agility": 3.0e8, "endurance": 3.0e8}
	gs.dinheiro = 120000.0
	if not patro:
		var ok: bool = gs.salvar()
		print("save de teste 8a2 (vale) salvo: %s (MUDAR: %s, custo %s)" % [str(ok), gs.estado_mudanca(), str(gs.mudanca().get("cost", 0))])
		gs.free()
		quit(0 if ok else 1)
		return
	# vai ao centro, passa o posto e comeca a campanha 2 (o discipulo)
	gs.mudar()
	gs.aposentar()
	gs.nova_carreira()
	gs.escolher_arte("boxing", 1)
	gs.escola["lines_seen"]["cl_primeiro_centro"] = 1
	gs.permanente["legacy_total"] = 22000
	gs.permanente["career_number"] = int(gs.permanente.career_number)
	gs.pular_abertura()
	gs.indice_escada = 3  # o Tonhao e o proximo (garagem)
	gs.cinturao = false
	gs.fama = 150
	gs.dinheiro = 500.0
	gs.atributos = {"strength": 2.0e6, "agility": 2.0e6, "endurance": 2.0e6}
	var spd := float(gs.lutas.calendario.get("seconds_per_day", 30.0))
	gs.segundos_campanha = 10.0 * spd
	gs.fight_day = gs.dia_campanha() + 2
	var ok2: bool = gs.salvar()
	print("save de teste 8a2 (patrocinio) salvo: %s (campanha %d, centro alcancado: %s, Legado %d, fama %d, Tonhao em %d dias)" % [str(ok2),
		gs.numero_carreira(), str(gs.permanente.get("center_reached", false)), int(gs.permanente.legacy_total), gs.fama, gs.dias_para_luta()])
	gs.free()
	quit(0 if ok2 else 1)
