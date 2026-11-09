extends SceneTree
## Joga um trecho do jogo sozinho para GRAVAR EM VÍDEO (modo de filmagem do Godot). Serve para mostrar mudanças
## (animações, cenário) sem ninguém precisar jogar. Save de teste isolado (user://demo/), nunca o save real.
##
## Uso (um trecho por vez; precisa de janela, sem --headless). A janela pode ficar fora da tela:
##   Godot_console.exe --path <projeto> --resolution 1280x720 --position -3000,-3000 --fixed-fps 30 \
##       --write-movie <saida>.avi --script res://tools/ui/gravar_demo.gd -- <trecho>
## Trechos: treino (clica no saco: jab das duas mãos, uppercut e golpe lateral) | corda (pula corda) |
##          chegada_corda (marca na parede, compra e a corda sendo pendurada) | luta (luta com golpes variados)
## Para a luta, um 2º argumento fixa a semente (a mesma luta em duas versões do jogo): ... -- luta 123
## Converter: ffmpeg -i saida.avi -c:v libx264 -pix_fmt yuv420p saida.mp4

const PASTA_SAVE := "user://demo/"
const CONFIG := "res://data/config.json"

var gs: Node
var cena: Node
var semente_fixa := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var trecho: String = args[0] if args.size() > 0 else "treino"
	semente_fixa = int(args[1]) if args.size() > 1 else 0
	gs = root.get_node("GameState")
	await process_frame
	match trecho:
		"treino":
			await _treino()
		"corda":
			await _corda()
		"chegada_corda":
			await _chegada_corda()
		"luta":
			await _luta()
		_:
			printerr("trecho desconhecido: %s" % trecho)
	await _esperar(0.5)
	quit()


# --- trechos ---

func _treino() -> void:
	_novo()
	await _abrir()
	await _esperar(1.0)
	await _clicar(34, 0.30)
	await _esperar(0.8)


func _corda() -> void:
	_novo()
	_com_aparelhos(["treadmill", "jump_rope"], 6000.0, "jump_rope")
	await _abrir()
	await _esperar(1.0)
	await _clicar(30, 0.30)
	await _esperar(0.8)


func _chegada_corda() -> void:
	_novo()
	_com_aparelhos(["treadmill"], 2500.0, "punching_bag")
	await _abrir()
	await _esperar(2.5)  # marca e plaquinha na parede
	gs.comprar_aparelho("jump_rope")
	await _esperar(2.2)  # a corda é pendurada
	await _clicar(12, 0.30)
	await _esperar(0.5)


func _luta() -> void:
	var k := semente_fixa if semente_fixa > 0 else _melhor_semente()
	_novo()
	gs.atributos = {"strength": 1000.0, "agility": 100.0, "endurance": 700.0}
	await _abrir()
	gs.rng.seed = k
	var fluxo: Node = cena.get_node("Fluxo")
	fluxo.abrir_previa()
	await _esperar(1.2)
	fluxo.janela.lutar_pedido.emit()
	await _esperar(float(gs.luta_atual().screen_seconds) + 1.5)


## Procura uma semente cuja luta mostre o máximo de golpes diferentes do jogador (uppercut, gancho e soco baixo)
## e dure pouco (bom para vídeo). A luta é sempre a mesma para a mesma semente.
func _melhor_semente() -> int:
	_novo()
	gs.atributos = {"strength": 1000.0, "agility": 100.0, "endurance": 700.0}
	var snap: Dictionary = gs.para_save()
	var melhor := 1
	var pontos := -1.0
	for k in range(1, 500):
		gs.rng.seed = k
		var info: Dictionary = gs.lutar()
		var vistos := {}
		for e in info.events:
			if int(e.who) == 0 and str(e.get("move", "")) in ["uppercut", "hook", "body_shot"]:
				vistos[str(e.get("move", ""))] = true
		var dur: float = float(info.result.t_end)
		var p := float(vistos.size()) * 100.0 - absf(dur - 10.0)
		gs.aguardar_motivo()
		gs.aplicar_save(snap.duplicate(true))
		if p > pontos:
			pontos = p
			melhor = k
	print("semente escolhida: %d (pontos %.1f)" % [melhor, pontos])
	return melhor


# --- ajudantes ---

func _novo() -> void:
	_fechar_cena()
	gs.definir_assistido(false)
	gs.inicializar(PASTA_SAVE, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 1
	gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	gs.treino = 1234.0
	gs.dinheiro = 0.0
	gs.fama = 0
	gs.indice_escada = 0
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0}
	gs.nivel_metronomo = 0
	gs.modal_aberto = false
	gs._recalcular_bonus()
	for g in gs.dados.geradores:
		gs.geradores[g.id] = 3


func _com_aparelhos(ids: Array, treino: float, foco: String) -> void:
	gs.aparelhos_montados_ids = ["punching_bag"] + ids
	gs.foco = foco
	gs.treino = treino


func _abrir() -> void:
	_fechar_cena()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await _esperar(0.5)


func _fechar_cena() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null


func _clicar(vezes: int, intervalo: float) -> void:
	for i in vezes:
		gs.clicar()
		await _esperar(intervalo)


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout
