extends SceneTree
## Verificacao da UI da 6c1 (Casa nova) na cena principal real, com janela: cena da 1a chegada a academia, academia cheia
## (Osmar, foto reta, caixote, John, ultimo em pe, equipe) e saida do John (natural e interrompida). Gera capturas.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6c1_ui.gd
## Save SEMPRE em user://test/qa6c1_ui/ (defina APPDATA para uma pasta temporaria; nunca o save real).

const PASTA := "user://test/qa6c1_ui/"
const CONFIG := "res://data/config.json"

var gs: Node
var cena: Node
var falhas := 0
var total := 0
var out := ""


func ok(c: bool, nome: String) -> void:
	total += 1
	if c:
		print("PASS  ", nome)
	else:
		falhas += 1
		print("FAIL  ", nome)


func esperar(s: float) -> void:
	await create_timer(s).timeout


func shot(nome: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out + "fase6c1_ui_" + nome + ".png")


func fechar() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null
		await process_frame


func novo_jogo(carreira: int) -> void:
	await fechar()
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 7
	gs.pular_abertura()
	gs.treino = 500.0
	while gs.numero_carreira() < carreira:
		gs.aposentar()
		gs.receber_discipulo()
		gs.sucessao_tela_aberta()
		gs.confirmar_discipulo()
		gs.sucessao_terminou()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.6)


func sala() -> Node:
	return cena.get_node("Sala")


func ir_para_academia() -> void:
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()


func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/")
	await process_frame
	await cenario_chegada()
	await cenario_saida()
	await cenario_saida_interrompida()
	await fechar()
	print("TOTAL %d FALHAS %d" % [total, falhas])
	quit(1 if falhas > 0 else 0)


func cenario_chegada() -> void:
	await novo_jogo(3)  # John sentado e o ultimo em pe na garagem
	ok(sala().mentor_visivel() and sala().mentor2_visivel(), "garagem: John sentado e o ultimo em pe")
	ir_para_academia()
	ok(gs.cena_sala == "primeira_academia", "a cena da chegada foi pedida")
	await esperar(0.7)
	ok(not sala().mentor_visivel(), "cena: mentores escondidos")
	await shot("chegada_A1")
	await esperar(2.6)
	await shot("chegada_A3")
	await esperar(2.7)
	await shot("chegada_A4_2x")
	await esperar(2.6)
	await shot("chegada_A6")
	await esperar(2.4)
	await shot("chegada_A7")
	await esperar(3.0)
	ok(gs.cena_sala == "", "a cena terminou sozinha e soltou o relogio")
	ok(sala().mentor_visivel() and sala().mentor2_visivel(), "academia: John sentado e o ultimo em pe depois da cena")
	ok(sala()._osmar.visible, "academia: Osmar desenhado")
	ok(sala()._parede["photo_old_gym"].sprite.visible and sala()._parede["photo_old_gym"].sprite.frame == 0, "academia: foto reta (o Osmar desentorta)")
	ok(sala()._caixote.visible, "academia: caixote")
	var fl0: Node = cena.get_node("Fluxo")
	if fl0.janela != null and fl0.janela.has_method("_escolher"):
		await shot("chegada_escolha_da_arte")
		fl0.janela._escolher(gs.academia.ids_artes()[0])
	await esperar(3.0)
	await shot("academia_cheia")
	# PULAR: nova campanha igual, apertando o botao
	await novo_jogo(3)
	ir_para_academia()
	await esperar(1.5)
	var cu: Node = null
	for c in cena.get_children():
		if c.get_script() != null and str(c.get_script().get_global_name()) == "CenaUi":
			cu = c
	ok(cu != null and cu.player.pode_pular(), "PULAR disponivel na chegada")
	cu.player.pular()
	await esperar(0.5)
	ok(gs.cena_sala == "", "PULAR soltou o relogio")
	ok(sala()._osmar.visible and sala().mentor_visivel(), "PULAR: academia montada")
	await shot("chegada_pulada")


func cenario_saida() -> void:
	await novo_jogo(3)
	ir_para_academia()
	await esperar(0.5)
	await pular_e_escolher()
	gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	var visto := {"pedida": false}
	gs.saida_mentor_pedida.connect(func() -> void: visto.pedida = true)
	var t := 0.0
	while not visto.pedida and t < 25.0:
		await esperar(0.25)
		t += 0.25
	print("DBG devida=", gs.saida_devida(), " ativa=", gs.sala_ativa(), " sentado=", gs.mentor_sentado(), " calma=", gs._calma, " balao=", gs._balao, " ab=", gs._abertura, " tv=", gs._toque_vitoria, " toques=", gs._toques, " gesto=", gs._gesto, " cena=", gs.cena_sala, " modal=", gs.modal_aberto, " arte=", gs.escolha_arte_pendente(), " luta=", gs.luta.size(), " dia=", gs.no_dia_da_luta())
	ok(visto.pedida, "a saida foi pedida no momento calmo")
	await esperar(1.0)
	await shot("saida_J1")
	await esperar(3.0)
	await shot("saida_J2")
	await esperar(3.5)
	await shot("saida_J4")
	await esperar(5.0)
	await shot("saida_J6")
	t = 0.0
	while gs.saida_tocando() and t < 12.0:
		await esperar(0.25)
		t += 0.25
	ok(not gs.saida_tocando(), "a saida terminou")
	await esperar(0.3)
	ok(sala().mentor_visivel() and sala()._mentor_quem == "last", "depois da saida o ultimo esta no caixote")
	ok(not sala().mentor2_visivel(), "depois da saida o ponto em pe esta vazio")
	await shot("saida_fim")


func cenario_saida_interrompida() -> void:
	await novo_jogo(2)  # Carreira 2: sem ultimo, o caixote fica vazio
	ir_para_academia()
	await esperar(0.5)
	await pular_e_escolher()
	gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	var t := 0.0
	while not gs.saida_tocando() and t < 25.0:
		await esperar(0.25)
		t += 0.25
	await esperar(2.0)
	ok(gs.saida_tocando(), "saida tocando")
	gs._interromper_saida()
	await esperar(0.3)
	ok(not sala().mentor_visivel() and not sala().mentor2_visivel(), "interrompida: ninguem no caixote na Carreira 2")
	ok(sala()._caixote.visible, "interrompida: caixote vazio visivel")
	ok(sala()._osmar.visible, "interrompida: Osmar de volta")
	await shot("saida_interrompida_c2")

func pular_e_escolher() -> void:
	for c in cena.get_children():
		if c.get_script() != null and str(c.get_script().get_global_name()) == "CenaUi":
			c.player.pular()
	await esperar(0.8)
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.has_method("_escolher"):
		fl.janela._escolher(gs.academia.ids_artes()[0])
	await esperar(1.0)