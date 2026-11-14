extends "res://tests/test_base.gd"
## Fase 6a: falas (dados e limites), fila de comentários, abertura, marcos da escola, gesto e save v11.
## Tudo em pastas de user://test/, nunca o save real. Números lidos de data/dialogos.json.

const GameStateScript := preload("res://scripts/game_state.gd")


# Jogo novo de teste: calendário desligado (a sala nunca para no dia da luta), sem crítico, sem autosave.
func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.lutas.calendario["seconds_per_day"] = 0.0
	return gs


# Jogo com a abertura já vista e a sala calma há tempo suficiente; intervalo de comentário livre.
func _pronto(nome: String) -> Node:
	var gs := _novo(nome)
	gs.pular_abertura()
	_tickar(gs, 3.0)
	gs._ultimo_comentario = -1.0e9
	return gs


func _tickar(gs: Node, segundos: float, passo: float = 0.1) -> void:
	var n := int(round(segundos / passo))
	for i in n:
		gs.tick(passo)


func _esperar(gs: Node, segundos: float) -> void:
	# Espera sem deixar a sala "parada" (um clique de mentira a cada 5 s), para o comentário de treino parado não atrapalhar
	var n := int(segundos / 0.5)
	for i in n:
		gs.tick(0.5)
		if i % 10 == 9:
			gs.registrar_clique()


func _num_igual(a: Variant, b: Variant) -> bool:
	if (typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT) and (typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT):
		return float(a) == float(b)
	return a == b


func _dic_igual(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in b:
		if not a.has(k) or not _num_igual(a[k], b[k]):
			return false
	return true


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _vencer(gs: Node) -> Dictionary:
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	return gs.concluir_luta()


func rodar_testes() -> void:
	_teste_dados()
	_teste_validador()
	_teste_escolha_pura()
	_teste_save_v11()
	_teste_lutador_atual()
	_teste_abertura()
	_teste_abertura_pular_e_janela()
	_teste_comentarios_espacamento()
	_teste_comentarios_calma_e_vaga()
	_teste_gesto()
	_teste_marcos()
	_teste_derrota_e_academia()
	_teste_gatilhos_dos_sinais()
	_teste_baloes_escondidos()
	_teste_fala_unica_nunca_se_perde()
	_teste_correcoes_qa()
	_teste_sons()


# --- Dados ---

func _teste_dados() -> void:
	var d := DialogosData.carregar()
	checar_igual(d.erros, [], "dialogos.json carrega sem erros do validador")
	checar_igual([d.personagem("first").name, d.personagem("coach").name, d.school_name], ["John Bullet", "Osmar Brandão", "Raízes Fight Club"], "elenco e escola do dono")
	var ids := {}
	var ruins: Array = []
	var ligadas := 0
	for l in d.linhas:
		ids[l.id] = true
		var texto: String = d.texto_balao(l)
		var partes := texto.split("\n")
		if "—" in l.text or partes.size() > 2 or texto != texto.to_lower():
			ruins.append(l.id)
		for p in partes:
			if p.length() > 26:
				ruins.append(l.id)
		if l.enabled:
			ligadas += 1
	checar_igual(ruins, [], "toda fala: até 2 linhas, até 26 caracteres, minúscula, sem travessão")
	checar_igual(ids.size(), d.linhas.size(), "ids de fala únicos")
	var desligadas: Array = []
	for l in d.linhas:
		if not l.enabled:
			desligadas.append(l.id)
	checar_igual(desligadas, ["cl_passar_posto", "cl_arte_1", "cl_arte_2", "cl_arte_3"], "só passar_posto (6b) e arte (6c) desligadas")
	var derrota := 0
	for l in d.linhas:
		if l.trigger == "after_defeat" and l.repeat == "rest":
			derrota += 1
	checar_igual(derrota, 6, "derrota e derrota_recall juntas: 6 variantes no mesmo grupo")
	checar_igual(d.linha("cl_primeira_derrota").repeat, "once", "primeira derrota é única")
	for t in ["garage_saved_return", "after_defeat", "glove_new", "fight_won", "gym_arrival", "fight_near", "big_purchase", "box_opened", "idle"]:
		checar(d.triggers.has(t), "gatilho %s existe" % t)
	checar_igual([float(d.comments.gap_min_seconds), float(d.comments.gap_filler_seconds), float(d.comments.defer_max_seconds)], [60.0, 120.0, 15.0], "intervalos 60/120 s e espera de 15 s")
	checar_igual(d.typing.space_completes_passive, false, "ESPAÇO só treina no passivo")
	# Abertura
	checar_igual(d.opening.lines, ["open_1", "open_2", "open_3", "open_4"], "abertura: 4 falas na ordem")
	checar_igual(d.texto_balao(d.linha("open_1")), "chegou outro aviso, john.", "placeholder {first} vira o apelido no balão")
	checar_igual(d.texto_balao(d.linha("open_3")), "o muralha riu da ficha:\nescola: nenhuma.", "open_3 com quebra de linha")
	checar(d.letras_abertura() <= 140, "abertura até 140 letras (%d)" % d.letras_abertura())
	checar(d.duracao_abertura() <= 20.0, "abertura até 20 s (prevista %.1f s)" % d.duracao_abertura())
	print("  abertura: %d letras, %.1f s previstos" % [d.letras_abertura(), d.duracao_abertura()])
	# Objetos
	checar_igual(d.texto_objeto("entry_form_before"), "ESCOLA: NENHUMA", "ficha antes")
	checar_igual(d.texto_objeto("entry_form_after"), "ESCOLA: RAÍZES FIGHT CLUB", "ficha depois")
	checar_igual(d.texto_objeto("starter_glove_desc"), "O par do John. Velha, mas fecha direito.", "luva inicial: o par do John")
	checar_igual(d.texto_objeto("clipping", "footer"), "Errata: o nome é Raízes Fight Club.", "{school} nos objetos vira o nome completo")
	for k in ["debt_notice", "old_photo", "entry_form_before", "entry_form_after", "clipping", "team_photo", "garage_saved_seal", "starter_glove_desc"]:
		checar(d.objects.has(k), "objeto %s existe" % k)
	# Tempo de fala: n/cps + pausas + leitura
	var t := d.tempo_fala("tá chegando a luta.", "coach")
	checar(absf(float(t.write) - 19.0 / 22.0) < 1.0e-6 and absf(float(t.hold) - 1.2) < 1.0e-6, "tempo de fala: 19 letras a 22 c/s, leitura mínima 1,2 s")
	var t2 := d.tempo_fala("a, b. c", "first")
	checar(absf(float(t2.write) - (7.0 / 28.0 + 0.12 + 0.28)) < 1.0e-6, "pausas: vírgula 0,12 e ponto 0,28")


func _teste_validador() -> void:
	var pasta := pasta_limpa("f6a_validador")
	var ruim := {"version": 1, "cast": {"first": {"name": "A", "short": "a", "color": "r2", "voice": "first"}}, "school_name": "E",
		"voices": {"first": {"cps": 28}}, "typing": {}, "comments": {}, "gesture": {}, "opening": {},
		"triggers": {"idle": {"priority": 1}},
		"lines": [
			{"id": "ok", "speaker": "first", "text": "tudo certo.", "trigger": "idle", "repeat": "rest"},
			{"id": "ok", "speaker": "first", "text": "id repetido.", "trigger": "idle", "repeat": "rest"},
			{"id": "larga", "speaker": "first", "text": "uma linha com mais de vinte e seis letras", "trigger": "idle", "repeat": "rest"},
			{"id": "tres", "speaker": "first", "text": "a\nb\nc", "trigger": "idle", "repeat": "rest"},
			{"id": "traco", "speaker": "first", "text": "pera — olha", "trigger": "idle", "repeat": "rest"},
			{"id": "caps", "speaker": "first", "text": "Á maiúscula acentuada", "trigger": "idle", "repeat": "rest"},
			{"id": "quem", "speaker": "ninguem", "text": "oi.", "trigger": "idle", "repeat": "rest"},
			{"id": "gat", "speaker": "first", "text": "oi.", "trigger": "nao_existe", "repeat": "rest"},
			{"id": "cond", "speaker": "first", "text": "oi.", "trigger": "idle", "repeat": "rest", "conditions": {"xis": 1}},
			{"id": "rep", "speaker": "first", "text": "oi.", "trigger": "idle", "repeat": "talvez"},
		]}
	escrever(pasta + "d.json", JSON.stringify(ruim))
	var d := DialogosData.carregar(pasta + "d.json")
	var ligadas: Array = []
	for l in d.linhas:
		if l.enabled:
			ligadas.append(l.id)
	checar_igual(ligadas, ["ok"], "validador desliga: repetida, larga, 3 linhas, travessão, maiúscula, speaker, gatilho, condição, repeat")
	checar_igual(d.erros.size(), 9, "um erro para cada fala ruim (9)")
	var vazio := DialogosData.carregar(pasta + "nao_existe.json")
	checar(vazio.linhas.is_empty() and vazio.candidatas("idle", {}).is_empty(), "arquivo ausente: sem falas, sem travar")


# Regras puras de escolha: once, descanso, teto por campanha, condições, prioridade.
func _teste_escolha_pura() -> void:
	var d := DialogosData.carregar()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ctx := {"campaign": 1, "first_campaign": 1, "lutador": "first", "location": "garage", "milestones": {}, "lines_seen": {}, "params": {}}
	var c := d.candidatas("big_purchase", ctx)
	checar_igual(c.size(), 4, "compra: 1 única + 3 repetíveis disponíveis")
	checar_igual(d.melhor(c, ctx, rng).id, "cl_primeira_compra", "empate de prioridade: a única vem primeiro")
	ctx.lines_seen = {"cl_primeira_compra": 1}
	checar_igual(d.candidatas("big_purchase", ctx).size(), 3, "única já vista nunca volta")
	ctx.campaign = 5
	checar_igual(d.candidatas("big_purchase", ctx).size(), 3, "única nunca volta, em campanha nenhuma")
	# Descanso: tocou na campanha 1 -> volta na 3 (N + 1 + rest_campaigns)
	ctx = {"campaign": 1, "location": "garage", "lines_seen": {"cl_compra_1": 1}, "params": {}}
	checar(not _tem(d.candidatas("big_purchase", ctx), "cl_compra_1"), "repetível não volta na mesma campanha")
	ctx.campaign = 2
	checar(not _tem(d.candidatas("big_purchase", ctx), "cl_compra_1"), "repetível não volta na campanha seguinte")
	ctx.campaign = 3
	checar(_tem(d.candidatas("big_purchase", ctx), "cl_compra_1"), "repetível volta duas campanhas depois")
	# Teto: 1 repetível por gatilho por campanha (única não conta nem é barrada)
	ctx = {"campaign": 2, "location": "garage", "lines_seen": {"cl_compra_2": 2}, "params": {}}
	var so_unica := d.candidatas("big_purchase", ctx)
	checar_igual(so_unica.size(), 1, "teto 1: depois de uma repetível sobra só a única")
	checar_igual(so_unica[0].id, "cl_primeira_compra", "...e é a única")
	# Condições
	ctx = {"campaign": 2, "location": "garage", "lines_seen": {}, "params": {"revenge": false, "record": false}}
	checar(d.candidatas("fight_won", ctx).is_empty(), "vitória comum: sem revanche e sem recorde, sem fala")
	ctx.params = {"revenge": true}
	checar_igual(d.candidatas("fight_won", ctx).size(), 3, "revanche: 3 variantes")
	ctx.params = {"record": true}
	checar_igual(d.candidatas("fight_won", ctx).size(), 3, "recorde: 3 variantes")
	ctx = {"campaign": 2, "location": "garage", "lines_seen": {}, "params": {}}
	checar(d.candidatas("gym_arrival", ctx).size() == 1 and d.candidatas("gym_arrival", ctx)[0].id == "cl_primeira_academia", "1ª academia: só a única")
	ctx.lines_seen = {"cl_primeira_academia": 1}
	checar_igual(d.candidatas("gym_arrival", ctx).size(), 3, "academia nas campanhas seguintes: academia_volta (after_line)")
	ctx.campaign = 1
	checar(d.candidatas("gym_arrival", ctx).is_empty(), "academia_volta não toca na mesma campanha da primeira")
	# Prioridade: derrota única (9) ganha das repetíveis (5)
	ctx = {"campaign": 1, "location": "garage", "lines_seen": {}, "params": {}}
	checar_igual(d.melhor(d.candidatas("after_defeat", ctx), ctx, rng).id, "cl_primeira_derrota", "primeira derrota ganha das 6 variantes")
	# Desligadas nunca entram
	checar(d.candidatas("retire", ctx).is_empty() and d.candidatas("art_choice", ctx).is_empty(), "falas de 6b e 6c desligadas")


func _tem(lista: Array, id: String) -> bool:
	for l in lista:
		if l.id == id:
			return true
	return false


# --- Save v11 ---

func _teste_save_v11() -> void:
	checar_igual(SaveStore.VERSAO_ATUAL, 11, "save v11")
	var pasta := pasta_limpa("f6a_v10")
	var career := {"training": 500.0, "money": 20.0, "fame": 5, "ladder_index": 2, "glove_level": 1, "belt": true,
		"campaign_seconds": 40.0, "fight_day": 9, "active_nodes": [], "metronome_level": 0}
	var perm := {"legacy_total": 120, "career_number": 3, "careers_finished": 2, "best_wins": 4, "belts_won": 2,
		"skill_nodes": [], "revenge_opponent": "opp_fast", "tree_last_node": ""}
	var doc := {"version": 10, "saved_at_unix": 1730000000, "state": {"career": career, "permanent": perm, "ending": null}}
	escrever(pasta + "save.json", JSON.stringify(doc))
	var store := SaveStore.new(pasta)
	var r: Dictionary = store.carregar()
	var e: Dictionary = r.estado
	checar_igual(e.school.first_fighter_campaign, 3, "v10 -> v11: a campanha atual vira a do John")
	checar_igual([e.school.milestones, e.school.lines_seen, e.school.last_end], [{}, {}, null], "school nasce vazio")
	checar_igual(e.career.gestured_gloves, [], "career.gestured_gloves nasce vazio")
	var c_igual := true
	for k in career:
		if not _num_igual(e.career[k], career[k]):
			c_igual = false
	checar(c_igual and _dic_igual(e.permanent, perm), "career e permanent idênticos antes e depois")
	# Com tela de fim pendente: a PRÓXIMA campanha
	var pend := doc.duplicate(true)
	pend.state.ending = {"kind": "defeat", "career_number": 3}
	escrever(pasta + "save.json", JSON.stringify(pend))
	var e2: Dictionary = SaveStore.new(pasta).carregar().estado
	checar_igual(e2.school.first_fighter_campaign, 4, "fim pendente: o John é da campanha seguinte")
	checar_igual(e2.school.last_end, {"kind": "defeat", "campaign": 3}, "fim pendente vira last_end")
	# No jogo: sem marco por causa de belts_won ou do cinturão em andamento; a abertura toca uma vez
	escrever(pasta + "save.json", JSON.stringify(doc))
	var gs := _novo("f6a_v10", pasta)
	checar(not gs.marco("garage_saved") and not gs.marco("garage_saved_seen") and not gs.marco("first_school_win"), "migração nunca cria garage_saved (belts_won e cinturão não contam)")
	checar_igual([gs.lutador_atual(), gs.abertura_estado()], ["first", "pending"], "save antigo: campanha atual é do John e a abertura ainda não tocou")
	_tickar(gs, 30.0)
	checar(not gs.marco("garage_saved"), "...nem depois de jogar")
	checar_igual(int(JSON.parse_string(ler(pasta + "save.json")).version), 11, "regravado como v11")
	_liberar(gs)
	# Ida e volta no disco, e bloco inválido
	var g2 := _novo("f6a_volta")
	g2.escola["lines_seen"]["cl_caixa_2"] = 3
	g2._gravar_marco("first_school_win")
	g2.gestos_calcados = [1, 2]
	g2.salvar()
	var g3 := _novo("f6a_volta", g2.store.pasta)
	checar_igual([g3.escola.lines_seen, g3.marco("first_school_win"), g3.gestos_calcados], [{"cl_caixa_2": 3}, true, [1, 2]], "school e gestured_gloves voltam do disco")
	_liberar(g2)
	_liberar(g3)
	var pb := pasta_limpa("f6a_bloco_ruim")
	escrever(pb + "save.json", JSON.stringify({"version": 11, "saved_at_unix": 1, "state": {"career": {}, "permanent": {"career_number": 2},
		"school": {"first_fighter_campaign": "x", "milestones": 5, "lines_seen": {"a": "b", "cl_x": 2}, "last_end": {"kind": "lixo"}}}}))
	var g4 := _novo("f6a_bloco_ruim", pb)
	checar_igual([g4.escola.first_fighter_campaign, g4.escola.milestones, g4.escola.lines_seen, g4.escola.last_end], [2, {}, {"cl_x": 2}, null], "bloco inválido: padrão da migração, com aviso")
	_liberar(g4)


func _teste_lutador_atual() -> void:
	var gs := _novo("f6a_lutador")
	checar_igual([gs.lutador_atual(), gs.escola.first_fighter_campaign], ["first", 1], "jogo novo: John na campanha 1")
	gs.aposentar()
	gs.nova_carreira()
	checar_igual([gs.numero_carreira(), gs.lutador_atual()], [2, "disciple"], "campanha 2: discípulo padrão")
	checar_igual(gs.escola.first_fighter_campaign, 1, "NOVA CAMPANHA não mexe no bloco da escola")
	checar_igual(gs.descricao_luva_inicial(), gs.lutas.luva_base.description, "discípulo: descrição de luva padrão")
	_liberar(gs)
	var g2 := _novo("f6a_lutador2")
	checar_igual(g2.descricao_luva_inicial(), "O par do John. Velha, mas fecha direito.", "John: luva inicial é o par dele")
	_liberar(g2)


# --- Abertura ---

func _teste_abertura() -> void:
	var pasta := pasta_limpa("f6a_abertura")
	var gs := _novo("f6a_abertura", pasta)
	var falas: Array = []
	var gestos: Array = []
	var estados: Array = []
	var cancelamentos := [0]
	gs.fala_pedida.connect(func(quem: String, texto: String, id: String) -> void: falas.append([quem, texto, id]))
	gs.gesto_pedido.connect(func(p: Dictionary) -> void: gestos.append(p))
	gs.abertura_mudou.connect(func(e: String) -> void: estados.append(e))
	gs.fala_cancelada.connect(func(_id: String) -> void: cancelamentos[0] += 1)
	checar_igual(gs.abertura_estado(), "pending", "save novo: abertura pendente")
	gs.tick(0.016)
	checar_igual(gs.abertura_estado(), "playing", "primeiro quadro da sala: a abertura começa")
	var doc: Dictionary = JSON.parse_string(ler(pasta + "save.json"))
	checar(doc.state.school.milestones.has("prologue_seen"), "prologue_seen gravado em t = 0, antes de qualquer balão")
	checar(falas.is_empty() and gestos.size() == 1 and gestos[0].momento == "opening", "em t = 0 só o gesto completo foi pedido")
	checar(absf(float(gestos[0].start) - 0.30) < 1.0e-6 and gestos[0].version == "full" and absf(float(gestos[0].duration) - 0.89) < 1.0e-6, "gesto da abertura: completo, de 0,30 a 1,19 s")
	checar(absf(float(gestos[0].taps[1]) - float(gestos[0].taps[0]) - 0.22) < 1.0e-6 and absf(float(gestos[0].rip_at) - 0.11) < 1.0e-6, "toques com 0,22 s e rip em 0,11 s")
	# O saco vale desde o primeiro quadro
	checar(not gs.clicar().is_empty(), "o saco vale durante a abertura")
	var t := 0.016
	while gs.abertura_estado() != "over" and t < 30.0:
		gs.tick(0.05)
		t += 0.05
	checar_igual(estados, ["playing", "over"], "estados playing -> over (pending era o inicial)")
	checar_igual(falas.map(func(f: Array) -> String: return f[2]), ["open_1", "open_2", "open_3", "open_4"], "as 4 falas na ordem")
	checar_igual(falas.map(func(f: Array) -> String: return f[0]), ["coach", "coach", "first", "first"], "Osmar, Osmar, John, John")
	checar(t <= 20.0, "abertura acabou em %.1f s (teto 20 s)" % t)
	print("  abertura real: %.1f s" % t)
	checar_igual(cancelamentos[0], 0, "nenhum balão cancelado no caminho feliz")
	checar(gs.marco("prologue_seen") and not gs.tem_balao(), "estado final: marco gravado e nenhum balão")
	# O clique no alvo cancelou o gesto: o 2º gesto de abertura não existe
	checar_igual(gestos.size(), 1, "o gesto da abertura toca uma vez só")
	# Outro processo: abertura não repete
	var g2 := _novo("f6a_abertura", pasta)
	var outras: Array = []
	g2.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: outras.append(id))
	checar_igual(g2.abertura_estado(), "over", "save com prologue_seen: abertura nunca mais toca")
	_tickar(g2, 25.0)
	checar(outras.is_empty(), "nenhuma fala de abertura ao reabrir")
	_liberar(gs)
	_liberar(g2)
	# Reset de campanha e derrota não repetem a abertura
	var g3 := _novo("f6a_abertura3")
	_tickar(g3, 22.0)
	g3.aposentar()
	g3.nova_carreira()
	checar_igual(g3.abertura_estado(), "over", "NOVA CAMPANHA não repete a abertura")
	_liberar(g3)


func _teste_abertura_pular_e_janela() -> void:
	# Pular no meio (ESC 0,5 s): mesmo estado final, balão cancelado, nada repete
	var gs := _novo("f6a_pular")
	var falas: Array = []
	var cancelados: Array = []
	gs.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: falas.append(id))
	gs.fala_cancelada.connect(func(id: String) -> void: cancelados.append(id))
	_tickar(gs, 2.0)
	checar_igual(falas, ["open_1"], "aos 2 s o 1º balão está na tela")
	gs.pular_abertura()
	checar_igual([gs.abertura_estado(), cancelados], ["over", ["open_1"]], "pular: over e o balão fecha")
	_tickar(gs, 25.0)
	checar_igual(falas, ["open_1"], "depois de pular nenhuma fala da abertura volta")
	_liberar(gs)
	# Janela no meio: o balão fecha, os seguintes esperam a sala calma, o teto de 20 s continua contando
	var g2 := _novo("f6a_janela")
	var f2: Array = []
	var c2: Array = []
	g2.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: f2.append(id))
	g2.fala_cancelada.connect(func(id: String) -> void: c2.append(id))
	_tickar(g2, 2.0)
	g2.definir_modal(true)
	checar_igual(c2, ["open_1"], "janela abriu: o balão fecha na hora")
	_tickar(g2, 6.0)
	checar_igual(f2, ["open_1"], "com a janela aberta nenhum balão novo entra")
	g2.definir_modal(false)
	_tickar(g2, 1.0)
	checar_igual(f2.size(), 2, "janela fechou: a abertura segue com a fala seguinte")
	g2.definir_modal(true)
	_tickar(g2, 20.0)
	g2.definir_modal(false)
	_tickar(g2, 0.2)
	checar_igual(g2.abertura_estado(), "over", "passou de 20 s: vai para over mesmo com falas que faltam")
	checar(f2.size() < 4, "as falas que faltavam não entram depois do teto")
	_liberar(g2)
	# Luta pendente ao abrir: espera a sala voltar
	var g3 := _novo("f6a_luta_pendente")
	g3.luta = {"opponent": "opp_warmup"}
	g3.tick(1.0)
	checar_igual(g3.abertura_estado(), "pending", "sala parada (luta pendente): a abertura espera")
	g3.luta = {}
	g3.tick(0.1)
	checar_igual(g3.abertura_estado(), "playing", "sala voltou: a abertura começa")
	_liberar(g3)


# --- Comentários ---

func _teste_comentarios_espacamento() -> void:
	var gs := _pronto("f6a_gap")
	var vistos: Array = []
	gs.comentario.connect(func(id: String) -> void: vistos.append(id))
	var falas: Array = []
	gs.fala_pedida.connect(func(q: String, t: String, id: String) -> void: falas.append([q, t, id]))
	gs.disparar_gatilho("big_purchase", {"what": "apparatus", "item": "treadmill"})
	gs.tick(0.1)
	checar_igual(vistos, ["cl_primeira_compra"], "1ª compra: a fala única")
	checar_igual([falas[0][0], falas[0][1]], ["coach", "isso, enche a sala."], "fala_pedida: quem e o texto do balão")
	checar(gs.escola.lines_seen.has("cl_primeira_compra"), "lines_seen gravado")
	# única salva na hora
	var salvo: Dictionary = JSON.parse_string(ler(gs.store.caminho()))
	checar(salvo.state.school.lines_seen.has("cl_primeira_compra"), "fala única salva na hora")
	# Dentro do intervalo de 120 s (enchimento) e com balão na tela: nada
	_tickar(gs, 30.0)
	gs.disparar_gatilho("big_purchase", {"what": "glove"})
	gs.tick(0.1)
	checar_igual(vistos.size(), 1, "30 s depois: enchimento (compra) espera 120 s")
	_tickar(gs, 60.0)
	gs.disparar_gatilho("glove_new", {"item": "glove_l1"})
	gs.tick(0.1)
	checar_igual(vistos.size(), 2, "90 s depois: prioridade alta (luva, 8) só precisa de 60 s")
	checar_igual(vistos[1], "cl_luva_par", "a luva toca a fala da luva")
	checar_igual(falas[1][1], "a velha é o par do john.\npassa de mão em mão.", "placeholder {first} trocado no balão")
	gs._ultimo_comentario = gs._t_real - 50.0
	gs.disparar_gatilho("glove_new", {"item": "x"})
	gs.tick(0.1)
	checar_igual(vistos.size(), 2, "menos de 60 s desde o último: nunca dois")
	_tickar(gs, 8.0)
	# Teto por campanha: 1 repetível por gatilho
	gs._ultimo_comentario = -1.0e9
	gs.disparar_gatilho("big_purchase", {})
	gs.tick(0.1)
	checar_igual(vistos.size(), 3, "3ª fala: repetível de compra")
	checar(vistos[2].begins_with("cl_compra_"), "...uma repetível")
	_tickar(gs, 12.0)
	gs._ultimo_comentario = -1.0e9
	gs.disparar_gatilho("big_purchase", {})
	gs.tick(0.1)
	checar_igual(vistos.size(), 3, "teto: no máximo 1 repetível de compra por campanha")
	# Balão na tela bloqueia
	gs._ultimo_comentario = -1.0e9
	gs.disparar_gatilho("box_opened", {"kind": "apparatus", "item": "x"})
	gs.tick(0.1)
	checar_igual(vistos.size(), 4, "caixa: toca (a única da 1ª caixa)")
	gs._ultimo_comentario = -1.0e9
	gs.disparar_gatilho("fight_near", {})
	gs.tick(0.1)
	checar_igual(vistos.size(), 4, "com balão na tela nada entra")
	# Dois gatilhos no mesmo quadro: só a melhor, o resto é descartado
	var g2 := _pronto("f6a_dois")
	var v2: Array = []
	g2.comentario.connect(func(id: String) -> void: v2.append(id))
	g2.disparar_gatilho("box_opened", {"kind": "glove", "item": "glove_l1"})
	g2.disparar_gatilho("glove_new", {"item": "glove_l1"})
	g2.tick(0.1)
	checar_igual(v2, ["cl_luva_par"], "luva aberta: glove_new e box_opened no mesmo quadro tocam uma fala só, a melhor")
	_tickar(g2, 70.0)
	checar_igual(v2, ["cl_luva_par"], "a outra não ficou guardada")
	_liberar(gs)
	_liberar(g2)


func _teste_comentarios_calma_e_vaga() -> void:
	# Sem sala calma: gatilho comum é descartado
	var gs := _pronto("f6a_calma")
	var vistos: Array = []
	gs.comentario.connect(func(id: String) -> void: vistos.append(id))
	gs.definir_modal(true)
	gs.disparar_gatilho("box_opened", {})
	_tickar(gs, 1.0)
	gs.definir_modal(false)
	_tickar(gs, 5.0)
	checar(vistos.is_empty(), "gatilho comum com janela aberta: descartado, não volta depois")
	# Assentar 2 s depois da sala voltar
	gs.definir_modal(true)
	gs.tick(0.1)
	gs.definir_modal(false)
	gs.disparar_gatilho("glove_new", {})
	gs.tick(0.1)
	checar(vistos.is_empty(), "sala acabou de voltar: ainda não está calma (2 s)")
	# Vaga (defer): vitória com revanche guarda e toca no 1º momento calmo
	gs.definir_modal(true)
	gs.disparar_gatilho("fight_won", {"revenge": true})
	_tickar(gs, 3.0)
	checar(vistos.is_empty(), "vitória com janela aberta: fica na vaga")
	gs.definir_modal(false)
	_tickar(gs, 1.5)
	checar(vistos.is_empty(), "vaga espera o assentamento de 2 s")
	_tickar(gs, 1.0)
	checar_igual(vistos.size(), 1, "vaga toca no 1º momento calmo")
	checar(vistos[0].begins_with("cl_revanche_"), "...a fala da revanche")
	# Vaga expira depois de 15 s de sala ativa sem intervalo livre
	var g2 := _pronto("f6a_vaga_expira")
	var v2: Array = []
	g2.comentario.connect(func(id: String) -> void: v2.append(id))
	g2.disparar_gatilho("glove_new", {})
	g2.tick(0.1)  # um comentário agora: o intervalo de 60 s começa
	g2.definir_modal(true)
	g2.disparar_gatilho("fight_won", {"revenge": true})
	g2.tick(0.1)
	g2.definir_modal(false)
	_tickar(g2, 20.0)
	checar_igual(v2, ["cl_luva_par"], "sem intervalo livre a vaga some depois de 15 s e não volta")
	_tickar(g2, 70.0)
	checar_igual(v2.size(), 1, "...nem depois")
	# Vaga única: a de maior prioridade vence
	var g3 := _pronto("f6a_vaga_unica")
	var v3: Array = []
	g3.comentario.connect(func(id: String) -> void: v3.append(id))
	g3.definir_modal(true)
	g3.disparar_gatilho("gym_arrival", {})
	g3.tick(0.1)
	g3.disparar_gatilho("garage_saved_return", {})
	g3.tick(0.1)
	g3.definir_modal(false)
	_tickar(g3, 3.0)
	checar_igual(v3, ["cl_garagem_salva"], "vaga única: a de maior prioridade (10) substitui a menor (6)")
	_liberar(gs)
	_liberar(g2)
	_liberar(g3)
	# Com a sala parada por luta: sala_ativa false
	var g4 := _pronto("f6a_luta")
	var v4: Array = []
	var c4: Array = []
	g4.comentario.connect(func(id: String) -> void: v4.append(id))
	g4.fala_cancelada.connect(func(id: String) -> void: c4.append(id))
	g4.disparar_gatilho("glove_new", {})
	g4.tick(0.1)
	checar(g4.tem_balao(), "balão na tela")
	g4.luta = {"opponent": "opp_warmup"}
	g4.tick(0.1)
	checar(not g4.tem_balao() and c4.size() == 1, "luta começou: balão fecha na hora")
	_liberar(g4)


# --- Gesto ---

func _teste_gesto() -> void:
	var gs := _pronto("f6a_gesto")
	var plano: Dictionary = gs.pedir_gesto("fight_intro")
	checar(plano.version == "full" and absf(float(plano.start) - 0.30) < 1e-6 and absf(float(plano.start) + float(plano.duration) - 1.19) < 1e-6, "entrada de luta: completo, 0,30 a 1,19 s (cabe nos 1,5 s)")
	var v: Dictionary = gs.pedir_gesto("victory")
	checar(v.version == "short" and absf(float(v.start) - 0.15) < 1e-6 and float(v.start) + float(v.duration) < float(v.pose_at) and absf(float(v.pose_at) - 0.60) < 1e-6, "vitória: curto, 0,15 a 0,59 s, antes da pose de 0,60 s")
	checar(absf(float(v.taps[0]) - 0.11) < 1e-6 and absf(float(v.taps[1]) - 0.33) < 1e-6 and float(v.rip_at) < 0.0, "curto: toques em 0,11 e 0,33, sem fecho")
	checar(gs.pedir_gesto("nao_existe").is_empty(), "momento desconhecido: nada")
	# Luva: uma vez por nível; cancelado pelo clique conta como feito
	gs.cancelar_gesto()
	gs.nivel_luva = 1
	var g1: Dictionary = gs.pedir_gesto("glove", 1)
	checar(not g1.is_empty() and absf(float(g1.start) - 0.30) < 1e-6 and g1.version == "full", "luva nova: completo")
	gs.clicar()
	checar(gs.pedir_gesto("glove", 1).is_empty(), "o mesmo nível não repete (cancelado conta como feito)")
	checar(not gs.pedir_gesto("glove", 2).is_empty(), "outro nível faz")
	checar_igual(gs.gestos_calcados, [1, 2], "career.gestured_gloves")
	# Clique cancela no mesmo quadro
	var cancelados := [0]
	gs.gesto_cancelado.connect(func() -> void: cancelados[0] += 1)
	gs.pedir_gesto("victory")
	gs.clicar()
	checar_igual(cancelados[0], 1, "clicar() cancela o gesto")
	gs.pedir_gesto("victory")
	gs.registrar_clique()
	checar_igual(cancelados[0], 2, "clique fora do alvo (registrar_clique) também cancela")
	# Janela cancela o gesto da sala
	gs._ultimo_comentario = gs._t_real
	gs.nivel_luva = 3
	gs.pedir_gesto("glove", 3)
	gs.definir_modal(true)
	checar_igual(cancelados[0], 3, "janela abriu: o gesto da sala para")
	gs.definir_modal(false)
	# Sala parada: aos 20 s, depois a cada 30-60 s, no máximo 3 por parada
	var g2 := _pronto("f6a_parado")
	var idle: Array = []
	g2.gesto_pedido.connect(func(p: Dictionary) -> void:
		if p.momento == "idle":
			idle.append(g2._parado))
	_tickar(g2, 16.0, 0.5)
	checar(idle.is_empty(), "antes dos 20 s sem clique: nada")
	_tickar(g2, 2.0, 0.5)
	checar_igual(idle.size(), 1, "aos 20 s: o 1º gesto curto")
	_tickar(g2, 400.0, 0.5)
	checar_igual(idle.size(), 3, "no máximo 3 gestos por parada")
	checar(idle[1] - idle[0] >= 30.0 - 0.51 and idle[1] - idle[0] <= 60.5 and idle[2] - idle[1] >= 29.4, "intervalo de 30 a 60 s entre eles")
	g2.clicar()
	_tickar(g2, 21.0, 0.5)
	checar_igual(idle.size(), 4, "o clique zera a parada: volta a fazer aos 20 s")
	# Não com balão: o comentário parado e o gesto não se atropelam
	# Discípulo nunca faz
	g2.aposentar()
	g2.nova_carreira()
	checar(g2.pedir_gesto("victory").is_empty() and g2.pedir_gesto("fight_intro").is_empty(), "discípulo padrão não faz o gesto")
	var antes: int = idle.size()
	g2.gestos_calcados = []
	g2.nivel_luva = 1
	checar(g2.pedir_gesto("glove", 1).is_empty(), "discípulo: nem o de luva")
	_tickar(g2, 100.0, 0.5)
	checar_igual(idle.size(), antes, "discípulo: nada de gesto de sala parada")
	_liberar(gs)
	_liberar(g2)
	# O gesto vem antes da fala
	var g3 := _pronto("f6a_antes_da_fala")
	var ordem: Array = []
	g3.gesto_pedido.connect(func(p: Dictionary) -> void: ordem.append("gesto:" + str(p.momento)))
	g3.comentario.connect(func(id: String) -> void: ordem.append("fala:" + id))
	g3.nivel_luva = 1
	g3.caixas_lista = []
	g3.caixa_aberta.emit("glove_l1", "glove")
	_tickar(g3, 0.1)
	checar_igual(ordem, ["gesto:glove"], "luva aberta: o gesto começa e o comentário espera")
	_tickar(g3, 2.0)
	checar_igual(ordem, ["gesto:glove", "fala:cl_luva_par"], "...e a fala vem depois do gesto")
	# Gesto cancelado: a fala espera menos
	var g4 := _pronto("f6a_cancela_gesto")
	var o4: Array = []
	g4.comentario.connect(func(id: String) -> void: o4.append(id))
	g4.nivel_luva = 1
	g4.caixa_aberta.emit("glove_l1", "glove")
	g4.tick(0.1)
	checar(o4.is_empty(), "gesto em andamento: a fala espera")
	g4.clicar()
	g4.tick(0.1)
	checar_igual(o4, ["cl_luva_par"], "gesto cancelado pelo clique: a fala vem")
	_liberar(g3)
	_liberar(g4)


# --- Marcos da escola ---

func _teste_marcos() -> void:
	var gs := _pronto("f6a_marcos")
	var marcos: Array = []
	gs.marco_gravado.connect(func(id: String) -> void: marcos.append(id))
	var r1: Dictionary = _vencer(gs)
	checar(r1.win and r1.first_school_win and not r1.garage_saved, "1ª vitória: first_school_win, sem selo")
	checar(gs.marco("first_school_win") and not gs.marco("garage_saved"), "marco first_school_win gravado")
	checar(JSON.parse_string(ler(gs.store.caminho())).state.school.milestones.has("first_school_win"), "...no mesmo save do prêmio")
	var r2: Dictionary = _vencer(gs)
	checar(not r2.first_school_win, "2ª vitória não repete o marco")
	_vencer(gs)
	var antes_do_muralha: Array = marcos.duplicate()
	checar(not gs.marco("garage_saved"), "antes do Muralha: garagem não salva")
	var r4: Dictionary = _vencer(gs)
	checar(r4.belt and r4.garage_saved, "vitória ao vivo sobre o adversário do cinturão: garage_saved no resumo")
	checar_igual(gs.dados_marco("garage_saved").opponent, "opp_tank", "marco guarda o adversário")
	checar_igual(gs.dados_marco("garage_saved").by_first, true, "...e que foi o John")
	checar(not gs.marco("garage_saved_seen"), "garage_saved_seen só quando a garagem for desenhada de novo")
	checar_igual(marcos, ["first_school_win", "garage_saved"], "marco_gravado na ordem")
	var vistos: Array = []
	gs.comentario.connect(func(id: String) -> void: vistos.append(id))
	_tickar(gs, 0.2)
	checar(gs.marco("garage_saved_seen"), "sala ativa na garagem: garage_saved_seen gravado")
	_tickar(gs, 3.0)
	checar(vistos.has("cl_garagem_salva"), "volta à garagem: o Osmar fala (única, prioridade 10)")
	checar(JSON.parse_string(ler(gs.store.caminho())).state.school.milestones.has("garage_saved_seen"), "garage_saved_seen salvo na hora")
	checar(not gs._gravar_marco("garage_saved") and not gs._gravar_marco("first_school_win"), "marcos de uma vez só")
	_liberar(gs)
	# Discípulo na campanha 2 pega o cinturão: o marco é de qualquer lutador da escola
	var g2 := _pronto("f6a_marcos_disc")
	g2.aposentar()
	g2.nova_carreira()
	for i in 3:
		_vencer(g2)
	var rd: Dictionary = _vencer(g2)
	checar(rd.garage_saved and g2.dados_marco("garage_saved").by_first == false, "discípulo ganha o cinturão: garagem salva (by_first = false)")
	checar(g2.marco("first_school_win"), "first_school_win também vale para qualquer lutador")
	_liberar(g2)
	# Na academia: a parede só muda quando voltar à garagem (sala ativa em garage)
	var g3 := _pronto("f6a_marcos_gym")
	for i in 4:
		_vencer(g3)
	g3.marco_gravado.connect(func(_id: String) -> void: pass)
	checar(g3.marco("garage_saved"), "garagem salva (4ª vitória)")
	_liberar(g3)
	var g4 := _pronto("f6a_marcos_gym2")
	for i in 3:
		_vencer(g4)
	g4.local_id = "gym"
	_vencer(g4)  # Muralha vencido com o jogador na academia (cenário do save antigo)
	_tickar(g4, 3.0)
	checar(g4.marco("garage_saved") and not g4.marco("garage_saved_seen"), "na academia: garage_saved gravado, garage_saved_seen espera a garagem")
	g4.local_id = "garage"
	_tickar(g4, 0.2)
	checar(g4.marco("garage_saved_seen"), "voltou à garagem: garage_saved_seen")
	_liberar(g4)


func _teste_derrota_e_academia() -> void:
	# Derrota: last_end e o comentário no começo da campanha seguinte
	var gs := _pronto("f6a_derrota")
	var vistos: Array = []
	gs.comentario.connect(func(id: String) -> void: vistos.append(id))
	_esperar(gs, 70.0)
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs.lutar()
	var r: Dictionary = gs.concluir_luta()
	checar(not r.win, "derrota forçada")
	checar(gs.escola.last_end.kind == "defeat" and int(gs.escola.last_end.campaign) == 1, "derrota grava school.last_end")
	var le_disco: Dictionary = JSON.parse_string(ler(gs.store.caminho())).state.school.last_end
	checar(le_disco.kind == "defeat" and int(le_disco.campaign) == 1, "...no mesmo save da tela de fim")
	_tickar(gs, 5.0)
	checar(vistos.is_empty(), "com a tela de fim: nenhum comentário")
	gs.nova_carreira()
	_tickar(gs, 1.0)
	checar(vistos.is_empty(), "campanha nova: espera o assentamento")
	_tickar(gs, 2.0)
	checar_igual(vistos, ["cl_primeira_derrota"], "1º momento calmo da campanha seguinte: a 1ª derrota")
	_liberar(gs)
	# Aposentar não comenta como derrota
	var g2 := _pronto("f6a_aposenta")
	var v2: Array = []
	g2.comentario.connect(func(id: String) -> void: v2.append(id))
	_esperar(g2, 70.0)
	g2.aposentar()
	g2.nova_carreira()
	_tickar(g2, 5.0)
	checar(v2.is_empty(), "aposentadoria: sem comentário de derrota")
	_liberar(g2)
	# Academia pelo MUDAR
	var g3 := _pronto("f6a_academia")
	var v3: Array = []
	g3.comentario.connect(func(id: String) -> void: v3.append(id))
	_esperar(g3, 70.0)
	g3.cinturao = true
	g3.dinheiro = 1.0e9
	checar(g3.mudar(), "MUDAR para a academia")
	_tickar(g3, 3.0)
	checar(v3.is_empty(), "a escolha da arte está aberta: sem comentário")
	g3.escolher_arte(g3.academia.ids_artes()[0])
	_tickar(g3, 2.5)
	checar(v3.is_empty() and not g3.escola.lines_seen.has("cl_primeira_academia"), "chegada à academia: o Osmar não está lá, nada toca e a única não é gasta (B1)")
	_liberar(g3)
	# Carregar já na academia não comenta
	var g4 := _pronto("f6a_academia_carga")
	g4.cinturao = true
	g4.dinheiro = 1.0e9
	g4.mudar()
	g4.escolher_arte(g4.academia.ids_artes()[0])
	g4.salvar()
	var g5 := _novo("f6a_academia_carga", g4.store.pasta)
	var v5: Array = []
	g5.comentario.connect(func(id: String) -> void: v5.append(id))
	_esperar(g5, 100.0)
	checar(v5.is_empty(), "carregar o save na academia não é chegada")
	_liberar(g4)
	_liberar(g5)


func _teste_gatilhos_dos_sinais() -> void:
	var gs := _pronto("f6a_sinais")
	# Confere só a fila de gatilhos que os sinais que já existem alimentam
	gs._gatilhos_quadro = []
	gs.caixa_criada.emit("treadmill", "apparatus")
	checar_igual(gs._gatilhos_quadro.size(), 1, "caixa_criada -> big_purchase")
	gs._gatilhos_quadro = []
	gs.melhoria_comprada.emit("punching_bag", "x", 1)
	checar(gs._gatilhos_quadro.is_empty(), "melhoria que não é a última: sem gatilho")
	var total: int = gs.dados.aparelho("punching_bag").upgrades.size()
	gs.melhoria_comprada.emit("punching_bag", "x", total)
	checar_igual(gs._gatilhos_quadro.size(), 1, "melhoria no último nível -> big_purchase")
	gs._gatilhos_quadro = []
	gs.metronomo_mudou.emit(1)
	checar_igual(gs._gatilhos_quadro.size(), 1, "Metrônomo 0 -> 1 -> big_purchase")
	gs._gatilhos_quadro = []
	gs.metronomo_mudou.emit(2)
	checar(gs._gatilhos_quadro.is_empty(), "Metrônomo 1 -> 2: sem gatilho")
	gs.crew_click_mudou.emit(true)
	checar_igual(gs._gatilhos_quadro.size(), 1, "Grito da equipe comprado -> big_purchase")
	gs._gatilhos_quadro = []
	gs.crew_click_mudou.emit(true)
	checar(gs._gatilhos_quadro.is_empty(), "o sinal repetido (carga) não conta")
	gs.caixa_aberta.emit("treadmill", "apparatus")
	checar_igual(gs._gatilhos_quadro.size(), 1, "caixa de aparelho aberta -> só box_opened")
	gs._gatilhos_quadro = []
	gs.aviso_data.emit(1)
	checar(gs._gatilhos_quadro.is_empty(), "aviso de 1 dia: sem gatilho")
	gs.aviso_data.emit(int(gs.lutas.calendario.warn_days))
	checar_igual(gs._gatilhos_quadro.size(), 1, "aviso de 3 dias -> fight_near")
	gs._gatilhos_quadro = []
	gs.luta_resolvida.emit({"win": true, "retire": true})
	checar(gs._gatilhos_quadro.is_empty(), "aposentar não é vitória")
	gs.luta_resolvida.emit({"win": false})
	checar(gs._gatilhos_quadro.is_empty(), "derrota não é fight_won")
	gs.luta_resolvida.emit({"win": true, "revenge": true, "record": false, "opponent": "opp_fast"})
	checar_igual(gs._gatilhos_quadro[0].params.revenge, true, "vitória -> fight_won com os dados da luta")
	_liberar(gs)
	# Carga e NOVA CAMPANHA não contam como compra
	var g2 := _pronto("f6a_sinais2")
	g2.nivel_metronomo = 1
	g2.crew_click_comprado = true
	g2.salvar()
	var g3 := _novo("f6a_sinais2", g2.store.pasta)
	checar(g3._gatilhos_quadro.is_empty(), "carregar com Metrônomo e Grito já comprados: sem gatilho")
	g3.aposentar()
	g3.nova_carreira()
	checar(g3._gatilhos_quadro.is_empty(), "NOVA CAMPANHA: sem gatilho de compra")
	_liberar(g2)
	_liberar(g3)
	# Recorde: passou da marca anterior (e havia marca)
	var g4 := _pronto("f6a_recorde")
	g4.permanente["best_wins"] = 1
	var rr: Dictionary = _vencer(g4)
	checar_igual(rr.record, false, "1 vitória não passa a marca de 1")
	rr = _vencer(g4)
	checar_igual(rr.record, true, "2 vitórias passam a marca de 1")
	g4.permanente["best_wins"] = 0
	checar_igual(_vencer(g4).record, false, "sem marca anterior não há recorde")
	_liberar(g4)
	# Idle: aos 45 s de sala parada
	var g5 := _pronto("f6a_idle")
	var v5: Array = []
	g5.comentario.connect(func(id: String) -> void: v5.append(id))
	_tickar(g5, 40.0, 0.5)
	checar(v5.is_empty(), "antes dos 45 s: nada")
	_tickar(g5, 4.0, 0.5)
	checar_igual(v5.size(), 1, "aos 45 s parado: o comentário de treino parado")
	checar(v5[0].begins_with("cl_parado_"), "...do grupo parado")
	_tickar(g5, 200.0, 0.5)
	checar_igual(v5.size(), 1, "uma vez por parada")
	g5.baloes_escondidos = true
	_liberar(g5)


func _teste_baloes_escondidos() -> void:
	var gs := _pronto("f6a_escondido")
	gs.baloes_escondidos = true
	var falas := [0]
	var vistos: Array = []
	gs.fala_pedida.connect(func(_q: String, _t: String, _id: String) -> void: falas[0] += 1)
	gs.comentario.connect(func(id: String) -> void: vistos.append(id))
	gs.disparar_gatilho("glove_new", {})
	gs.tick(0.1)
	checar_igual([falas[0], vistos], [0, ["cl_luva_par"]], "balões escondidos: nenhum balão, mas o comentário e o lines_seen valem")
	checar(gs.escola.lines_seen.has("cl_luva_par"), "lines_seen funciona igual")
	_liberar(gs)


func _teste_sons() -> void:
	for nome in ["first", "coach", "disciple"]:
		for v in ["u", "o", "a", "e", "i"]:
			checar(FileAccess.file_exists("res://assets/sfx/voice_%s_%s.wav" % [nome, v]), "voice_%s_%s.wav existe" % [nome, v])
	checar(FileAccess.file_exists("res://assets/sfx/strap_rip.wav") and FileAccess.file_exists("res://assets/sfx/tap_glove.wav"), "strap_rip e tap_glove existem")


# Fala única de prioridade 9+ não depende do intervalo de 60 s e nunca é perdida.
func _teste_fala_unica_nunca_se_perde() -> void:
	var gs := _pronto("f6a_unica")
	var v: Array = []
	gs.comentario.connect(func(id: String) -> void: v.append(id))
	gs.disparar_gatilho("glove_new", {})
	gs.tick(0.1)
	_tickar(gs, 8.0)
	gs.disparar_gatilho("garage_saved_return", {})
	gs.tick(0.1)
	checar_igual(v, ["cl_luva_par", "cl_garagem_salva"], "prioridade 10: toca 8 s depois de outro comentário (sem o intervalo de 60 s)")
	# Vaga que passa de 15 s sem espaço livre: a única continua pendente e toca no próximo espaço
	var g2 := _pronto("f6a_unica_vaga")
	var v2: Array = []
	g2.comentario.connect(func(id: String) -> void: v2.append(id))
	g2.definir_modal(true)
	g2.disparar_gatilho("after_defeat", {})
	g2.tick(0.1)
	g2.definir_modal(false)
	g2._balao = {"id": "bloqueio", "ate": g2._t_real + 40.0}
	_esperar(g2, 25.0)
	checar(v2.is_empty() and not g2._vaga.is_empty(), "passou de 15 s sem espaço livre: a única segue pendente")
	g2._balao = {}
	_tickar(g2, 0.5)
	checar_igual(v2, ["cl_primeira_derrota"], "...e toca no próximo espaço livre")
	# Fechou o jogo antes da fala da garagem: ela volta na próxima sessão
	var g3 := _pronto("f6a_unica_reabre")
	g3._gravar_marco("garage_saved")
	g3._gravar_marco("garage_saved_seen")
	g3.salvar()
	var g4 := _novo("f6a_unica_reabre", g3.store.pasta)
	var v4: Array = []
	g4.comentario.connect(func(id: String) -> void: v4.append(id))
	_esperar(g4, 4.0)
	checar_igual(v4, ["cl_garagem_salva"], "save com a garagem salva e a fala ainda não dita: ela toca ao reabrir")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


# --- Correções do QA (B1, B2, B3) ---

func _teste_correcoes_qa() -> void:
	# B1: nenhuma fala do Osmar fora da garagem; a única não é gasta e toca na volta
	var d := DialogosData.carregar()
	var sem_local: Array = []
	for l in d.linhas:
		if l.speaker == "coach" and l.trigger != "opening" and str(l.get("conditions", {}).get("location", "")) != "garage":
			sem_local.append(l.id)
	checar_igual(sem_local, [], "B1: toda fala do Osmar (fora da abertura) exige location garage")
	var g := _pronto("f6a_b1")
	var falas: Array = []
	g.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: falas.append(id))
	g.cinturao = true
	g.dinheiro = 1.0e9
	g.mudar()
	g.escolher_arte(g.academia.ids_artes()[0])
	_tickar(g, 6.0)
	checar(falas.is_empty() and not g.escola.lines_seen.has("cl_primeira_academia"), "B1: academia sem balão e a única não foi gasta")
	g.disparar_gatilho("gym_arrival", {})
	_tickar(g, 20.0)
	checar(falas.is_empty() and g._vaga.is_empty(), "B1: nem a vaga guarda a fala da academia")
	_liberar(g)
	# B1: abertura num save que começa na academia não faz balão do Osmar
	var g1b := _novo("f6a_b1_abertura")
	g1b.local_id = "gym"
	var f1b: Array = []
	g1b.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: f1b.append(id))
	_tickar(g1b, 25.0)
	checar(f1b.is_empty() and g1b.abertura_estado() == "pending", "B1: abertura só começa na garagem (nenhum balão na academia)")
	g1b.local_id = "garage"
	_tickar(g1b, 5.0)
	checar(g1b.abertura_estado() == "playing" and f1b.size() >= 1 and f1b[0] == "open_1", "B1: ...e começa quando volta à garagem")
	_liberar(g1b)

	# B2: derrota -> NOVA CAMPANHA -> fecha antes dos 2 s -> reabre: a 1ª derrota volta
	var gs := _pronto("f6a_b2")
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs.lutar()
	checar(not gs.concluir_luta().win, "B2: derrota forçada")
	_tickar(gs, 0.5)  # tela de fim: a sala não está calma
	gs.nova_carreira()
	_tickar(gs, 0.5)
	gs.salvar()
	var g2 := _novo("f6a_b2", gs.store.pasta)
	g2.pular_abertura()
	var v2: Array = []
	g2.comentario.connect(func(id: String) -> void: v2.append(id))
	_tickar(g2, 6.0)
	checar_igual(v2, ["cl_primeira_derrota"], "B2: reabrir após a derrota e NOVA CAMPANHA: a 1ª derrota toca")
	var g3 := _novo("f6a_b2", g2.store.pasta)  # ela já foi dita (e salva): não volta
	g3.pular_abertura()
	var v3: Array = []
	g3.comentario.connect(func(id: String) -> void: v3.append(id))
	_tickar(g3, 30.0)
	checar(not v3.has("cl_primeira_derrota"), "B2: depois de dita, não volta")
	for x in [gs, g2, g3]:
		_liberar(x)

	# B3: a UI recusa o balão -> a única não conta como vista e fica pendente
	var g4 := _pronto("f6a_b3")
	var recusar := [true]
	var pedidos: Array = []
	var c4: Array = []
	g4.comentario.connect(func(id: String) -> void: c4.append(id))
	g4.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void:
		pedidos.append(id)
		if recusar[0]:
			g4.fala_recusada(id))
	g4.disparar_gatilho("big_purchase", {})
	_tickar(g4, 0.5)
	checar(pedidos == ["cl_primeira_compra"] and c4.is_empty() and not g4.escola.lines_seen.has("cl_primeira_compra"), "B3: balão recusado: não foi vista nem comentada")
	checar(not g4.tem_balao() and not g4._vaga.is_empty(), "B3: ...sem balão preso e a única fica pendente")
	var salvo: Dictionary = JSON.parse_string(ler(g4.store.caminho()))
	checar(not salvo.get("state", {}).get("school", {}).get("lines_seen", {}).has("cl_primeira_compra"), "B3: ...e não foi salva como vista")
	recusar[0] = false
	_tickar(g4, 3.0)
	checar(c4 == ["cl_primeira_compra"] and g4.escola.lines_seen.has("cl_primeira_compra"), "B3: UI aceita depois: toca e vira vista")
	_liberar(g4)
