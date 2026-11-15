extends SceneTree
## QA 5.4: JanelaMapa.diagnostico() roda e acusa sobreposicao (injeta defeitos), e abre/fecha com Esc, relogio parado.
## Roda: godot --headless --path . --script res://tests/qa_f54_diag.gd   (save so em user://test/autoload/)

var gs: Node
var cena: Control
var fluxo
var ok_n := 0
var falhas: Array = []


func chk(c: bool, nome: String) -> void:
	if c:
		ok_n += 1
		print("PASS  ", nome)
	else:
		falhas.append(nome)
		print("FAIL  ", nome)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func nj(j) -> String:
	if j == null:
		return ""
	var sc = j.get_script()
	return str(sc.get_global_name()) if sc != null else ""


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	fluxo = cena.get_node("Fluxo")
	await frames(10)
	gs.apagar_save()
	gs.risco_hud_ativo = false
	await frames(3)
	var bm = cena.find_child("BotaoMapa", true, false)
	chk(bm != null, "BotaoMapa existe na sala")
	# sem Legado: sem brilho
	gs.permanente["legacy_total"] = 5
	gs.permanente_mudou.emit()
	await frames(20)
	chk(not bm.brilhando(), "Legado 5: botao sem brilho")
	gs.permanente["legacy_total"] = 10
	gs.permanente_mudou.emit()
	await frames(20)
	chk(bm.brilhando(), "Legado 10: botao brilha")
	gs.permanente["legacy_total"] = 9
	gs.permanente_mudou.emit()
	await frames(20)
	chk(not bm.brilhando(), "Legado 9: apaga de novo")
	gs.permanente["legacy_total"] = 400
	gs.permanente_mudou.emit()
	# abrir pelo botao
	bm.pressed.emit()
	await frames(10)
	chk(nj(fluxo.janela) == "JanelaMapa", "botao abre o mapa")
	var m = fluxo.janela
	chk(not gs.sala_ativa(), "mapa aberto: sala_ativa falso")
	var c0: float = gs.segundos_campanha
	gs.tick(5.0)
	chk(gs.segundos_campanha == c0, "mapa aberto: relogio parado em tick(5)")
	chk(gs.clicar().is_empty(), "mapa aberto: clique recusado")
	var d: Array = m.diagnostico()
	print("  diagnostico real: ", d)
	chk(d.is_empty(), "diagnostico do mapa real: 0 problemas")
	# injeta defeitos
	var vis: Dictionary = m._vis
	var ids := vis.keys()
	print("  nos desenhados: ", ids.size())
	chk(ids.size() >= 2, "ha nos desenhados")
	if ids.size() >= 2:
		var a: Dictionary = vis[ids[0]]
		var b: Dictionary = vis[ids[1]]
		var rb: Rect2 = b.rect
		b.rect = Rect2(a.rect.position + Vector2(3, 3), rb.size)
		var d2: Array = m.diagnostico()
		print("  diagnostico com no sobre no: ", d2)
		chk(d2.size() > 0 and str(d2).contains("cobre"), "diagnostico acusa no sobre no")
		b.rect = rb
		a.rect = Rect2(Vector2(-500, -500), a.rect.size)
		var d3: Array = m.diagnostico()
		print("  diagnostico com no fora do mundo: ", d3)
		chk(d3.size() > 0 and str(d3).contains("fora do mundo"), "diagnostico acusa no fora do mundo")
	# fecha com Esc
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(5)
	chk(fluxo.janela == null, "Esc fecha o mapa")
	chk(gs.sala_ativa(), "depois de fechar: sala ativa")
	# cartao/plaquinha
	# nao abre em luta
	gs.luta = {"opponent": "x"}
	chk(not gs.pode_abrir_arvore(), "luta: nao abre")
	bm.pressed.emit()
	await frames(5)
	chk(fluxo.janela == null or nj(fluxo.janela) != "JanelaMapa", "botao na luta nao abre o mapa")
	gs.luta = {}
	# dia da luta
	gs.segundos_campanha = gs._alvo_relogio()
	await frames(3)
	var antes := nj(fluxo.janela)
	fluxo.abrir_arvore()
	await frames(3)
	chk(nj(fluxo.janela) != "JanelaMapa", "dia da luta: mapa nao abre (janela=%s)" % nj(fluxo.janela))
	# --- derrota real: a tela de fim abre por cima da arena; ARVORE deve abrir o mapa ---
	gs.segundos_campanha = 0.0
	gs.permanente["legacy_total"] = 400
	gs.fama = 200
	gs.atributos["strength"] = 1.0
	gs.atributos["agility"] = 1.0
	gs.atributos["endurance"] = 1.0
	gs.lutar()
	await frames(5)
	chk(fluxo.tela.visible, "arena visivel durante a luta")
	gs.concluir_luta()
	await frames(10)
	print("  apos derrota: janela=", nj(fluxo.janela), " tela.visible=", fluxo.tela.visible, " fim pendente=", gs.tem_fim_pendente())
	chk(nj(fluxo.janela) == "JanelaFim", "derrota abre a tela de fim")
	chk(gs.pode_abrir_arvore(), "pode_abrir_arvore na tela de fim da derrota")
	fluxo.abrir_arvore()
	await frames(10)
	chk(nj(fluxo.janela) == "JanelaMapa", "BUG? ARVORE na tela de fim DEPOIS DE DERROTA abre o mapa (janela=%s, tela.visible=%s)" % [nj(fluxo.janela), str(fluxo.tela.visible)])
	# --- fechar o mapa do fim volta ao fim; e fim por aposentadoria abre o mapa ---
	if nj(fluxo.janela) == "JanelaMapa":
		var ev3 := InputEventKey.new()
		ev3.keycode = KEY_ESCAPE
		ev3.pressed = true
		Input.parse_input_event(ev3)
		await frames(6)
		chk(nj(fluxo.janela) == "JanelaFim", "Esc no mapa do fim volta para a tela de fim")
	gs.nova_carreira()
	await frames(10)
	if fluxo.cartao != null:
		fluxo.fechar_cartao_aberto()
		await frames(5)
	gs.fama = 100
	gs.permanente["legacy_total"] = 500
	gs.aposentar()
	await frames(10)
	print("  apos aposentar: janela=", nj(fluxo.janela), " tela.visible=", fluxo.tela.visible)
	fluxo.abrir_arvore()
	await frames(10)
	chk(nj(fluxo.janela) == "JanelaMapa", "ARVORE na tela de fim de APOSENTADORIA abre o mapa (janela=%s)" % nj(fluxo.janela))
	print("RESULTADO: %d ok, %d falhas" % [ok_n, falhas.size()])
	for f in falhas:
		print("  FALHOU: ", f)
	gs.apagar_save()
	quit(1 if falhas.size() > 0 else 0)
