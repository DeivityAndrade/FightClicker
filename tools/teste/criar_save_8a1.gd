extends SceneTree
## Cria um save de TESTE para a fase 8a1 (liga regional) em user:// (pasta do APPDATA de teste).
## Estado: academia, a 2 dias da luta contra o Kid, Boxe com a Mao rapida, atributos de sobra para vencer o Kid e entrar na liga.
## Com "-- --contragolpista": o mesmo save, mas com a 2a passiva do Boxe (Contragolpista) liberada e escolhida.
## So roda se o APPDATA for o de teste (nunca toca o save real do dono). Use pelo jogar_teste_8a1.ps1.
const GS := preload("res://scripts/game_state.gd")

func _initialize() -> void:
	await process_frame
	var appdata := OS.get_environment("APPDATA")
	if not appdata.contains("FightclickerTeste"):
		print("ERRO: APPDATA nao e o de teste (%s). Abortando." % appdata)
		quit(1)
		return
	var contra := "--contragolpista" in OS.get_cmdline_user_args()
	var gs: Node = GS.new()
	gs.inicializar("user://", "res://data/config.json")
	gs.autosave_ativo = false
	# Prologo e cena da 1a chegada ja vistos; falas do Osmar ja passadas
	gs._gravar_marco("prologue_seen", {}, false)
	gs._gravar_marco(str(gs.escola_cfg.gym_arrival.milestone), {}, false)
	gs.escola["lines_seen"]["cl_primeira_academia"] = 1
	# Chegou a academia com Boxe e Jiu-jitsu (o Muay Thai abre ao vencer o Kid)
	gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	if contra:
		gs.permanente["passive_wins"] = {"boxing": 3}
		gs.permanente["passives_unlocked"] = ["boxing"]
		gs._gravar_marco("passive2_boxing_unlocked", {}, false)
		gs.escola["lines_seen"]["cl_passive2_boxing"] = 1
	gs.arte_id = ""  # recriar sobre um save de teste antigo: a escolha volta a ficar aberta
	gs.passiva_carreira = 1
	var escolheu: bool = gs.escolher_arte("boxing", 2 if contra else 1)
	# Escada: 5 vitorias (o Kid e o proximo), a 2 dias da luta
	gs.indice_escada = 5
	gs.cinturao = true
	gs.fama = 600
	var spd := float(gs.lutas.calendario.get("seconds_per_day", 30.0))
	gs.segundos_campanha = 20.0 * spd
	gs.fight_day = gs.dia_campanha() + 2
	# Atributos folgados para o Kid (6,9M / 12,1M / 31,1M) e dinheiro para a loja
	gs.atributos = {"strength": 3.0e7, "agility": 4.0e7, "endurance": 6.0e7}
	gs.dinheiro = 1.0e6
	var ok: bool = gs.salvar()
	var chances: Dictionary = gs.previa().get("risks", {}) if gs.proximo_adversario().get("id", "") == "opp_gym_2" else {}
	print("save de teste 8a1 salvo: %s (arte escolhida: %s, passiva %d, Kid em %d dias, risco: %s)" % [str(ok), str(escolheu), gs.passiva_carreira, gs.dias_para_luta(), str(chances.keys())])
	gs.free()
	quit(0 if ok else 1)
