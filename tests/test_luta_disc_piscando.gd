extends "res://tests/test_base.gd"
## Regressão 6d3: o discípulo "piscava" na luta. Cada troca de pose (`AnimSprite.definir`) devolvia a folha PADRÃO
## (`fight_player_*_disc`, boneco de outra aparência) e o visual escolhido só voltava no quadro seguinte.
## Aqui, depois de CADA passo da animação (golpes, reações, queda, vitória), o sprite do jogador tem que mostrar a folha
## em camadas com o visual do discípulo, nunca a padrão, e a luta inteira (ganha e perdida) é conferida.

const PASTA := "disc_piscando"
const LOOK := {"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "purple", "top": "tank",
	"top_color": "yellow", "headband": "band", "headband_color": "red", "socks": "on"}

var gs: Node
var U: GDScript
var DV: GDScript


func rodar_testes() -> void:
	gs = root.get_node("GameState")
	U = load("res://ui/ui_tema.gd")
	DV = load("res://ui/disc_visual.gd")
	gs.inicializar(pasta_limpa(PASTA), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	while gs.numero_carreira() < 2:
		gs.aposentar()
		gs.receber_discipulo()
		gs.sucessao_tela_aberta()
		gs.confirmar_discipulo()
		gs.sucessao_terminou()
	gs.treino = 500.0
	gs.discipulo = {"name": "T", "look": LOOK.duplicate(), "campaign": 2}
	checar_igual(gs.lutador_atual(), "disciple", "o lutador atual é o discípulo")
	gs.luta = {}
	await _teste_troca_de_pose()
	for ganha in [true, false]:
		await _teste_luta(ganha)
	gs.luta = {}
	U = null
	DV = null
	await create_timer(1.6, true, false, true).timeout  # deixa terminar os congelamentos pendentes
	await process_frame


## A textura que o jogo QUER ver no jogador (folha em camadas com o visual do discípulo), ou null se a pose não tem.
func _esperada(spr) -> Texture2D:
	var cam: String = DV.nome_em_camadas(spr.nome_sprite)
	if cam == "":
		return null
	return DV.textura(cam, gs.visual_lutador(), gs.simbolo_no_lutador())


func _teste_troca_de_pose() -> void:
	var tela: Control = load("res://ui/tela_luta.gd").new()
	root.add_child(tela)
	await process_frame
	var d := _luta(true)
	tela.iniciar(d)
	var spr = tela._l[0].spr
	for acao in ["idle", "jab", "heavy", "hook", "uppercut", "body_shot", "dodge", "block", "tired", "victory", "hit", "hit_head",
			"hit_up", "hit_body", "ko", "ko_back", "ko_knees"]:
		spr.definir("")  # força a troca (definir ignora o mesmo nome)
		spr.definir(tela._nome(0, acao))
		var esp := _esperada(spr)
		if esp != null:
			checar(spr.texture == esp, "%s: logo após definir() o jogador já tem o visual do discípulo" % acao)
	tela.encerrar()
	tela.queue_free()
	await process_frame
	gs.luta = {}


func _luta(ganha: bool) -> Dictionary:
	gs.treino = 500.0
	gs.atributos = {"strength": 1000.0 if ganha else 0.0, "agility": 0.0 if not ganha else 100.0, "endurance": 700.0 if ganha else 0.0}
	for semente in range(1, 300):
		gs.rng.seed = semente
		var info: Dictionary = gs.lutar()
		if info.is_empty():
			return {}
		if bool(info.result.win) == ganha and (bool(info.result.ko) or not ganha):
			return gs.luta_atual()
		gs.aguardar_motivo()
		gs.luta = {}
	return {}


func _teste_luta(ganha: bool) -> void:
	var d := _luta(ganha)
	checar(not d.is_empty(), "achou luta (ganha=%s)" % ganha)
	if d.is_empty():
		return
	var tela: Control = load("res://ui/tela_luta.gd").new()
	root.add_child(tela)
	await process_frame
	tela.iniciar(d)
	var spr = tela._l[0].spr
	var passos := 0
	var errados := 0
	var vistos := {}
	while not tela.finalizada and passos < 3000:
		tela._process(0.02)
		spr._process(0.02) if spr.is_processing() else null  # o quadro do AnimSprite (callbacks de fim de pose)
		var esp := _esperada(spr)
		if esp != null:
			vistos[spr.nome_sprite] = true
			if spr.texture != esp:
				errados += 1
		passos += 1
	checar(tela.finalizada, "ganha=%s: a luta animada chegou ao fim" % ganha)
	checar(vistos.size() >= 4, "ganha=%s: o jogador mostrou várias poses (%d)" % [ganha, vistos.size()])
	checar_igual(errados, 0, "ganha=%s: nenhum quadro mostrou o boneco padrão em vez do discípulo" % ganha)
	tela.encerrar()
	tela.queue_free()
	await process_frame
	gs.luta = {}
