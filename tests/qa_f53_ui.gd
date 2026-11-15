extends SceneTree
## QA 5.3: tabela da secao 2 do design no nivel da UI real (cena da garagem), dia da luta, VOLTAR, reabrir no dia.
## Roda headless: godot --headless --path . --script res://tests/qa_f53_ui.gd
## Salva so em user://test/autoload/ (nunca no save real).

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


func nj(j) -> String:
	if j == null:
		return ""
	var sc = j.get_script()
	return str(sc.get_global_name()) if sc != null else ""


func frames(n: int) -> void:
	for i in n:
		await process_frame


func snap() -> Array:
	return [gs.segundos_campanha, gs.treino, gs.atributos.duplicate(), gs._acc_metronomo, gs.frenesi_restante,
		gs.arte_segundos, gs.evento_dourado_restante]


func equipar() -> void:
	gs.geradores[gs.dados.geradores[0].id] = 10
	gs.nivel_metronomo = 1
	gs.frenesi_restante = 5.0
	gs.evento_dourado_restante = 3.0


# gs.tick manual com a UI aberta: a cena tambem ticka por _process, entao medimos so a diferenca congelada.
func parado(nome: String) -> void:
	chk(not gs.sala_ativa(), nome + ": sala_ativa falso")
	var a := snap()
	gs.tick(10.0)
	var b := snap()
	chk(a == b, nome + ": relogio/equipe/Metronomo/FRENESI/arte/ouro parados em 10 s")
	chk(gs.clicar().is_empty(), nome + ": clique recusado")


func andando(nome: String) -> void:
	chk(gs.sala_ativa(), nome + ": sala_ativa verdadeiro")
	var c0: float = gs.segundos_campanha
	var t0: float = gs.treino
	var prod: float = gs.producao_total()
	gs.tick(10.0)
	chk(absf((gs.segundos_campanha - c0) - 10.0) < 0.2, nome + ": relogio andou ~10 s (%.2f)" % (gs.segundos_campanha - c0))
	chk(gs.treino - t0 >= prod * 9.5, nome + ": equipe treinou junto")


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	fluxo = cena.get_node("Fluxo")
	await frames(10)
	gs.apagar_save()
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	await frames(3)
	print("pasta de save do teste: ", gs.store.pasta if "pasta" in gs.store else "?")
	equipar()
	# ---------- ANDAM ----------
	andando("sala livre")
	cena.get_node("PainelLoja")._trocar_aba("loja")
	await frames(3)
	andando("aba LOJA aberta")
	cena.get_node("PainelLoja")._trocar_aba("treino")
	await frames(3)
	gs._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	andando("janela sem foco")
	gs.definir_assistido(false)
	# caixa de equipamento pendente na sala (mao na caixa): a equipe segue
	gs.caixas_lista.append({"item": "treadmill", "kind": "apparatus", "hits": 1})
	await frames(3)
	andando("caixa de equipamento aberta (hits=1)")
	gs.caixas_lista.clear()
	# ---------- PARAM: previa pelo LUTAR ----------
	gs.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	fluxo.abrir_previa()
	await frames(5)
	chk(fluxo.janela != null, "previa abriu")
	parado("previa aberta pelo LUTAR")
	fluxo._voltar_da_previa()
	await frames(3)
	andando("depois de VOLTAR A TREINAR")
	# ---------- PARAM: confirmacao de passar o posto, fora do dia ----------
	gs.fama = 100
	fluxo.abrir_aposentar()
	await frames(5)
	chk(fluxo.janela != null, "confirmacao abriu fora do dia")
	parado("confirmacao de passar o posto")
	fluxo.janela.cancelou.emit()
	await frames(5)
	chk(fluxo.janela == null and gs.sala_ativa(), "VOLTAR fora do dia volta para a SALA (nao para a previa)")
	# ---------- PARAM: luta + vitoria ----------
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	var dia_antes: int = gs.dia_campanha()
	fluxo.abrir_previa()
	await frames(3)
	fluxo._lutar()
	await frames(3)
	parado("luta (arena)")
	Engine.time_scale = 30.0
	var t0 := Time.get_ticks_msec()
	while not ((nj(fluxo.janela) == "JanelaVitoria")) and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	Engine.time_scale = 1.0
	chk((nj(fluxo.janela) == "JanelaVitoria"), "janela de vitoria abriu")
	parado("vitoria")
	chk(gs.fight_day == dia_antes + 13 or gs.fight_day == gs.dia_campanha() + 13, "data do Brutao = dia da luta + 13 (fight_day=%d, dia=%d)" % [gs.fight_day, gs.dia_campanha()])
	fluxo._fechar_vitoria({"belt": false})
	await frames(3)
	andando("depois da vitoria")
	# ---------- PARAM: fim de campanha + arvore + cartao de inicio ----------
	gs.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	equipar()
	gs.aposentar()
	await frames(5)
	chk((nj(fluxo.janela) == "JanelaFim"), "tela de fim abriu")
	parado("fim de campanha")
	fluxo.abrir_arvore()
	await frames(5)
	parado("arvore")
	fluxo._fechar()
	gs.nova_carreira()
	await frames(5)
	# ---------- PARAM: escolha da arte ----------
	# ---------- PARAM: escolha da arte e cartao ----------
	gs.aposentar()
	await frames(3)
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.permanente["last_art"] = ""
	gs.nova_carreira()
	await frames(8)
	print("DIAG janela=", nj(fluxo.janela), " fim=", gs.fim.is_empty(), " arte=", gs.arte_id, " tela=", fluxo.tela.visible, " desbl=", gs.permanente.get("arts_unlocked"))
	chk(gs.escolha_arte_pendente(), "escolha da arte pendente")
	chk((nj(fluxo.janela) == "JanelaArte"), "janela da arte abriu")
	equipar()
	parado("escolha da arte")
	gs.escolher_arte("boxing")
	fluxo.janela.escolheu.emit("boxing")
	await frames(10)
	chk(fluxo.cartao != null, "cartao de inicio abriu depois da arte")
	if fluxo.cartao != null:
		equipar()
		parado("cartao depois da arte")
		chk(fluxo.fechar_cartao_aberto(), "cartao fecha com 1 acao")
		await frames(10)
	andando("depois da arte")
	# ---------- DIA DA LUTA ----------
	gs.risco_hud_ativo = true
	gs.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	equipar()
	gs.fama = 300
	var alvo: float = float(gs.fight_day - 1) * 30.0
	gs.segundos_campanha = alvo - 2.0
	for i in 5:
		gs.tick(1.0)
	await frames(8)
	chk(gs.no_dia_da_luta(), "chegou o dia")
	chk(gs.segundos_campanha == alvo, "relogio exatamente em (data-1)*30 = %.1f" % alvo)
	chk((nj(fluxo.janela) == "JanelaPrevia") and fluxo.janela.dia_da_luta, "previa do dia abriu sozinha")
	parado("previa do dia")
	# a previa nao fecha: botao voltar escondido, Esc nao fecha
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	fluxo._unhandled_key_input(esc)
	await frames(3)
	chk((nj(fluxo.janela) == "JanelaPrevia"), "Esc nao fecha a previa do dia")
	var achou_voltar := false
	for b in fluxo.janela.find_children("*", "Button", true, false):
		var tx := str(b.text)
		for c in b.get_children():
			if c is Label:
				tx += str(c.text)
		if b.visible and ("VOLTAR A TREINAR" in tx):
			achou_voltar = true
	chk(not achou_voltar, "previa do dia sem VOLTAR A TREINAR")
	# tentativa de LUTAR pela barra e abrir 2a previa
	var n_janelas_antes := cena.get_node("Fluxo").get_child_count()
	fluxo.abrir_previa()
	chk(cena.get_node("Fluxo").get_child_count() == n_janelas_antes, "nao abre 2a previa por cima")
	# LOJA fechada
	var loja = cena.get_node("PainelLoja")
	chk(loja._tab["loja"].botao.disabled and loja._aba == "treino", "LOJA fechada no dia")
	gs.dinheiro = 1.0e9
	chk(not gs.comprar_luva() and not gs.comprar_melhoria(gs.foco), "compras recusadas no dia")
	pass
	# 10 minutos
	var e0 := [gs.segundos_campanha, gs.treino, gs.indice_escada, gs.luta.is_empty(), gs.dinheiro]
	for i in 600:
		gs.tick(1.0)
	await frames(5)
	chk([gs.segundos_campanha, gs.treino, gs.indice_escada, gs.luta.is_empty(), gs.dinheiro] == e0, "10 min parado no dia: nada muda, nenhuma luta comeca")
	chk((nj(fluxo.janela) == "JanelaPrevia"), "previa do dia continua aberta")
	# PASSAR O POSTO -> confirmacao -> VOLTAR -> previa do dia
	fluxo.janela.passar_pedido.emit()
	await frames(8)
	chk((nj(fluxo.janela) == "JanelaAposentar"), "PASSAR O POSTO abre a confirmacao")
	parado("confirmacao no dia")
	fluxo.janela.cancelou.emit()
	await frames(8)
	chk((nj(fluxo.janela) == "JanelaPrevia") and fluxo.janela.dia_da_luta, "VOLTAR no dia devolve a previa do dia")
	# reabrir o jogo no dia
	gs.salvar()
	gs.carregar_save()
	fluxo._fechar()
	await frames(5)
	fluxo._checar_pendencias()
	await frames(8)
	chk(gs.no_dia_da_luta() and (nj(fluxo.janela) == "JanelaPrevia"), "reabrir o save no dia abre direto na previa do dia")
	# passar o posto = 100% do legado
	var esperado: int = int(gs.previa_aposentar().total)
	var leg0: int = int(gs.permanente.legacy_total)
	fluxo.janela.passar_pedido.emit()
	await frames(8)
	fluxo.janela.confirmou.emit()
	await frames(8)
	chk(gs.tem_fim_pendente() and gs.fim.kind == "retire" and int(gs.permanente.legacy_total) == leg0 + esperado and esperado > 0,
		"PASSAR no dia: kind=retire, Legado +%d (100%%)" % esperado)
	print("RESULTADO: ", ok_n, " PASS, ", falhas.size(), " FAIL")
	for f in falhas:
		print("  FALHOU: ", f)
	quit(1 if falhas.size() > 0 else 0)
