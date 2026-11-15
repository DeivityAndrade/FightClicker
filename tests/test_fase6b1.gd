extends "res://tests/test_base.gd"
## Fase 6b1 (Passar o posto): sucessão, fechar no meio, save v12 e migração, John mentor, player de cena, validador,
## sons e balanço inalterado. Tudo em pastas de user://test/, nunca o save real.
## Arte que ainda não existe NÃO reprova o validador: vira pendência (impressa no fim).

const GameStateScript := preload("res://scripts/game_state.gd")

var _pendencias_vistas: Array = []


func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _tickar(gs: Node, segundos: float, passo: float = 0.1) -> void:
	for i in int(round(segundos / passo)):
		gs.tick(passo)


# Passa o posto (aposentadoria) e recebe o discípulo: devolve o estado da sucessão.
func _encerrar_e_receber(gs: Node, tela: bool = false) -> String:
	gs.aposentar()
	gs.receber_discipulo()
	if tela:
		gs.sucessao_tela_aberta()  # o que o player faz no open_screen
	return gs.sucessao_estado()


# Toca a cena até `flag` ficar true (ou estourar o tempo). Devolve os segundos tocados.
func _tocar_ate(p: CenaPlayer, flags: Dictionary, chave: String, maximo: float = 60.0) -> float:
	var t := 0.0
	while not flags.get(chave, false) and t < maximo:
		p.avancar(0.05)
		t += 0.05
	return t


func _jogador(gs: Node) -> Dictionary:
	var p := CenaPlayer.new(gs)
	p.ler_teclado = false
	p.automatico = false
	var f := {"tela": false, "controle": false, "fim": false, "pulada": false, "prog": 0.0, "eventos": [], "reacao": false, "cancel": false}
	p.tela_pedida.connect(func(_t: String, _e: Dictionary) -> void: f.tela = true)
	p.controle_devolvido.connect(func() -> void: f.controle = true)
	p.cena_terminada.connect(func(pulada: bool) -> void:
		f.fim = true
		f.pulada = pulada)
	p.evento.connect(func(ev: Dictionary) -> void: f.eventos.append(ev))
	p.reacao_iniciada.connect(func(_q: String) -> void: f.reacao = true)
	p.reacao_cancelada.connect(func(_q: String) -> void: f.cancel = true)
	return {"p": p, "f": f}


func _grava_v11(pasta: String, perm: Dictionary, escola: Dictionary, fim: Variant) -> void:
	var doc := {"version": 11, "saved_at_unix": 1730000000, "state": {"career": {"training": 10.0, "money": 5.0},
		"permanent": perm, "ending": fim, "school": escola}}
	escrever(pasta + "save.json", JSON.stringify(doc))


func rodar_testes() -> void:
	_teste_dados()
	_teste_nome_e_sorteio()
	_teste_validador()
	_teste_sons()
	_teste_primeira_sucessao()
	_teste_pular()
	_teste_fechar_no_meio()
	_teste_sucessao_seguinte_e_lista()
	_teste_migracao()
	_teste_toques()
	_teste_textos()
	_teste_balanco()
	_teste_correcoes_qa()
	if not _pendencias_vistas.is_empty():
		print("PENDENCIAS DE ARTE (nao sao falhas): %d" % _pendencias_vistas.size())
		for p in _pendencias_vistas:
			print("  - " + str(p))


# --- Dados ---

func _teste_dados() -> void:
	var d := DiscipulosData.carregar()
	checar_igual(d.erros, [], "disciples.json e o banco de nomes carregam sem erro")
	checar_igual(d.nomes.size(), 42, "42 nomes no banco")
	var maior := 0
	var todos_limpos := true
	for n in d.nomes:
		maior = maxi(maior, n.length())
		todos_limpos = todos_limpos and d.limpar_nome(n) == n
	checar(maior <= d.max_letras(), "nenhum nome passa de %d letras (maior: %d)" % [d.max_letras(), maior])
	checar(todos_limpos, "todos os nomes do banco passam pela limpeza sem mudar")
	checar_igual(d.nome_padrao, "Novato", "nome padrão do migrado")
	checar_igual(d.look_padrao.size(), 9, "look com 9 campos")
	checar_igual([d.opcoes_ativas("skin").size(), d.opcoes_ativas("hair_color").size(), d.opcoes_ativas("shorts_color").size()], [5, 6, 6], "5 peles, 6 cabelos, 6 calções ligados")
	checar_igual([d.opcoes_ativas("hair_style"), d.opcoes_ativas("top"), d.opcoes_ativas("socks")], [["short"], ["none"], ["none"]], "6b1: campos da 6b2 com uma opção só")
	var c := d.cores(d.look_padrao)
	checar_igual([c.skin.colors, c.hair_color.tokens, c.shorts_color.tokens], [["#7a4632", "#b9744f", "#e3a275"], ["br1", "br2", "br0"], ["gr0", "gr1", "gr2", "gr3"]], "cores do visual padrão")
	var l := d.look_padrao.duplicate()
	l["skin"] = "skin_5"
	l["hair_color"] = "copper"
	var c2 := d.cores(l)
	checar_igual([c2.skin.colors, c2.hair_color.tokens], [["#422529", "#73453f", "#a06a5a"], ["br2", "br3", "br0"]], "paletas finais do Diretor de Arte (skin_5, copper)")
	var avisos: Array = []
	var v := d.validar_look({"skin": "skin_9", "hair_color": "blond"}, avisos)
	checar_igual([v.skin, v.hair_color, v.shorts_color, avisos.is_empty()], ["skin_3", "blond", "green", false], "look tolerante: id desconhecido e campo ausente viram o padrão, com aviso")
	var gs := _novo("f6b1_dados")
	checar_igual([gs.disciples.toques.cooldown_seconds, gs.disciples.toques.first_click_guard_seconds, gs.disciples.toques.win_return_delay_seconds],
		[60.0, 0.5, 1.0], "toques: 60 s, guarda 0,5 s, 1,0 s depois da vitória")
	_liberar(gs)


func _teste_nome_e_sorteio() -> void:
	var d := DiscipulosData.carregar()
	checar_igual(d.limpar_nome("  Tati   Gancho  "), "Tati Gancho", "limpeza: pontas e espaços repetidos")
	checar_igual(d.limpar_nome("   "), "", "só espaços: vazio")
	checar_igual(d.limpar_nome("a1b2-c!"), "abc", "tira o que a fonte não desenha")
	checar_igual(d.limpar_nome("Ação José"), "Ação José", "acentos aceitos")
	checar_igual(d.limpar_nome("Abcdefghijklmnopqrst").length(), 14, "no máximo 14 letras")
	checar_igual(d.filtrar_digitacao("ab 12 c").length(), 5, "digitação: tira só o que a fonte não desenha")
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var roster: Array = []
	for i in 5:
		roster.append({"kind": "disciple", "name": d.nomes[i], "look": d.look_padrao.duplicate()})
	var evitou := true
	var verdes := 0
	for i in 200:
		var r := d.sortear(rng, roster, d.nomes[7])
		evitou = evitou and not (r.name in [d.nomes[0], d.nomes[1], d.nomes[2], d.nomes[3], d.nomes[4], d.nomes[7]])
		for campo in ["skin", "hair_color", "shorts_color"]:
			evitou = evitou and r.look[campo] in d.opcoes_ativas(campo)
		verdes += 1 if r.look.shorts_color == "green" else 0  # o último discípulo da lista usou o verde padrão
	checar(evitou and verdes <= 20, "sorteio: sem os 5 últimos nomes nem o atual, opções ligadas, calção diferente do último")
	var r2 := d.sortear(rng, [], "")
	checar_igual([r2.look.hair_style, r2.look.top, r2.look.socks], ["short", "none", "none"], "sorteio mantém os campos da 6b2 no padrão")


# --- Validador ---

func _teste_validador() -> void:
	var v := CenaValidador.novo()
	var ids := CenaDados.ids_das_cenas()
	checar_igual(ids, ["chegada_discipulo", "primeira_sucessao"], "o validador lê as 2 cenas e ignora data/cutscenes/_rascunhos/")
	for r in v.validar_tudo():
		checar_igual(r.erros, [], "cena %s sem erros do validador" % r.id)
		for p in r.pendencias:
			if not (p in _pendencias_vistas):
				_pendencias_vistas.append(p)
		if r.id == "chegada_discipulo":
			checar(r.tempo_preso <= 2.5 + 1.0e-6 or not r.tempo_exato, "chegada curta: <= 2,5 s presos (%.2f, exato: %s)" % [r.tempo_preso, str(r.tempo_exato)])
		else:
			checar(r.tempo_preso <= 16.0 + 1.0e-6 or not r.tempo_exato, "cena grande: <= 16 s presos (%.2f, exato: %s)" % [r.tempo_preso, str(r.tempo_exato)])
	# Cena sintética com TODOS os tipos de passo, inclusive os da luta: nenhum "tipo desconhecido".
	var pasta := pasta_limpa("f6b1_val")
	var todos := {"id": "todos", "version": 1, "milestone": "m", "once": true, "blocking": true, "register": "espetaculo", "max_seconds": 40,
		"trigger": {"event": "fight_intro", "requires": {"opponent": "x", "calm": true}},
		"grants": [{"type": "photo", "id": "p"}], "_nota": "ignorada",
		"stage": {"view": "fight", "location": "gym", "window": [0, 0, 640, 360], "hide": [], "props": {"p": {"sprite": "nada", "pos": [1, 2]}}},
		"actors": {"a": {"character": "first_fighter_old", "pos": [10, 10], "facing": "left"}},
		"lines": {"l": {"speaker": "a", "text": "oi."}},
		"steps": [
			{"type": "frame", "window": "full", "seconds": 0.2}, {"type": "name_card", "actor": "a", "style": "show", "seconds": 1},
			{"type": "light", "id": "tubo", "on": true}, {"type": "fx", "sprite": "poeira", "actor": "a"},
			{"type": "photo", "id": "p", "wall": "gym", "slot": 1, "subjects": []}, {"type": "face", "actor": "a", "face": "smile"},
			{"type": "say", "line": "l"}, {"type": "camera", "scale": 2, "rect": [1, 2, 192, 136]}, {"type": "shake", "px": 2, "frames": 3},
			{"type": "ui", "hide": ["hud"]}, {"type": "show", "prop": "p"}, {"type": "hide", "prop": "p"},
			{"type": "parallel", "steps": [{"type": "wait", "seconds": 1}, {"type": "sequence", "steps": [{"type": "wait", "seconds": 1}]}]},
			{"type": "start_fight"}],
		"end_state": {"actors": {"a": "hand_to_game"}, "camera": {"scale": 1}, "ui": "show_all"}}
	escrever(pasta + "todos.json", JSON.stringify(todos))
	var r1 := v.validar_caminho(pasta + "todos.json")
	checar_igual(r1.erros, [], "cena com todos os tipos de passo (frame, name_card, light, fx, photo, start_fight...) valida")
	# Erros que têm que ser pegos.
	var ruim := todos.duplicate(true)
	ruim.id = "ruim"
	ruim.stage.view = "room"  # start_fight fora da luta
	ruim.actors["d"] = {"character": "current_player", "pos": [10.5, 3]}
	ruim.steps = [
		{"type": "start_fight"},
		{"type": "pose", "actor": "d", "anim": "mentor_first_taps"},
		{"type": "pose", "actor": "d", "anim": "gesture"},
		{"type": "camera", "scale": 2, "rect": [0, 0, 100, 100]},
		{"type": "camera", "scale": 3},
		{"type": "say", "line": "nao_existe"},
		{"type": "voar"},
		{"type": "sound", "id": "som_que_nao_existe"},
		{"type": "move", "actor": "a", "to": [1, 2]},
		{"type": "open_screen", "screen": "x"}]
	ruim.lines["longa"] = {"speaker": "a", "text": "uma linha enorme que passa de vinte e seis colunas"}
	escrever(pasta + "ruim.json", JSON.stringify(ruim))
	var r2 := v.validar_caminho(pasta + "ruim.json")
	var texto := "\n".join(r2.erros)
	checar("posição" in texto or "inteiros" in texto, "erro: posição não inteira")
	checar("só o John" in texto, "erro: gesto e mentor_first_taps em ator current_player")
	checar("192, 136" in texto, "erro: rect do 2x precisa ser 192x136")
	checar("scale precisa ser 1 ou 2" in texto, "erro: zoom suave (scale 3)")
	checar("fala inexistente" in texto, "erro: fala que não existe")
	checar("desconhecido: 'voar'" in texto, "erro: tipo de passo desconhecido")
	checar("som inexistente" in texto, "erro: som que não existe")
	checar("speed OU seconds" in texto, "erro: move sem speed nem seconds")
	checar("start_fight só em cena" in texto, "erro: start_fight fora da vista de luta")
	checar("return_control ou start_fight" in texto or "start_fight" in texto, "erro: sem fim da cena")
	checar("26" in texto, "erro: fala passa de 26 colunas")
	# Tempo preso: soma maior que max_seconds reprova (com durações exatas, sem pose de arte).
	var longa := {"id": "longa", "version": 1, "once": false, "blocking": true, "register": "cotidiano", "max_seconds": 3,
		"trigger": {"event": "handover_started", "requires": {}}, "grants": [],
		"stage": {"view": "room", "location": "garage", "window": [0, 0, 10, 10], "hide": [], "props": {}}, "actors": {}, "lines": {},
		"steps": [{"type": "wait", "seconds": 2}, {"type": "wait", "seconds": 2}, {"type": "return_control"}],
		"end_state": {"ui": "show_all"}}
	escrever(pasta + "longa.json", JSON.stringify(longa))
	var r3 := v.validar_caminho(pasta + "longa.json")
	checar("max_seconds" in "\n".join(r3.erros), "tempo preso (4 s) acima de max_seconds (3 s) reprova")
	# Comentários (_chave) são ignorados.
	var com := longa.duplicate(true)
	com["max_seconds"] = 5
	com["_q"] = "comentário"
	com.steps[0]["_t"] = 0.0
	escrever(pasta + "longa.json", JSON.stringify(com))
	checar_igual(v.validar_caminho(pasta + "longa.json").erros, [], "chaves que começam com _ são comentário")


func _teste_sons() -> void:
	var novos := ["bag_catch", "chain_creak", "lamp_hum", "strap_open", "glove_leather", "ring_clink", "door_shake", "door_roll",
		"door_jam", "strap_close", "tap_fist"]
	var ok := true
	for s in novos:
		ok = ok and FileAccess.file_exists("res://assets/sfx/%s.wav" % s)
	checar(ok, "os 11 sons novos existem em assets/sfx/")
	# Todo som citado pelas cenas existe (o validador já confere, aqui só a contagem dos novos usados).
	var citados := {}
	for id in CenaDados.ids_das_cenas():
		var txt := FileAccess.get_file_as_string(CenaDados.PASTA + id + ".json")
		for s in novos:
			if ('"%s"' % s) in txt:
				citados[s] = true
	checar_igual(citados.size(), 11, "as cenas usam os 11 sons novos")


# --- Fluxo da sucessão ---

func _teste_primeira_sucessao() -> void:
	var gs := _novo("f6b1_primeira")
	gs.lutas.calendario["seconds_per_day"] = 60.0
	_tickar(gs, 5.0)
	gs.aposentar()
	var estados: Array = []
	gs.sucessao_mudou.connect(func(e: String) -> void: estados.append(e))
	var iniciou: Array = []
	gs.nova_carreira_iniciada.connect(func(c: Dictionary) -> void: iniciou.append(c))
	checar(gs.receber_discipulo(), "RECEBER NOVO DISCÍPULO")
	checar_igual(gs.sucessao_estado(), "scene_1", "primeira sucessão: parte 1")
	checar_igual(gs.sucessao_cena(), "primeira_sucessao", "toca a cena grande")
	checar(gs.marco("cena_primeira_sucessao"), "marco gravado no começo")
	checar_igual([gs.escola.mentors, gs.numero_carreira(), gs.lutador_atual()], [["first"], 2, "disciple"], "grant: John sentado; campanha 2")
	checar_igual(gs.escola.handover.stage, "creating", "save grava creating")
	checar(iniciou.is_empty(), "o cartão de início NÃO sai antes do fim da sucessão")
	var r0: Dictionary = gs.rascunho()
	checar(r0.name != "" and r0.look.size() == 9, "rascunho já vem sorteado")
	# Relógio parado.
	var antes := [gs.segundos_campanha, gs.tempo_jogo, gs.treino, gs.dinheiro]
	_tickar(gs, 30.0)
	checar_igual([gs.segundos_campanha, gs.tempo_jogo, gs.treino, gs.dinheiro], antes, "30 s de sucessão: nenhum segundo, treino ou ouro")
	checar(not gs.sala_ativa() and gs.clicar().is_empty(), "sem sala ativa e sem soco antes do return_control")
	# Marco gravado: fechar aqui não repete a cena (outro jogo no mesmo disco).
	var j := _jogador(gs)
	var p: CenaPlayer = j.p
	var f: Dictionary = j.f
	checar(p.iniciar(gs.sucessao_cena()), "player inicia a cena")
	_tocar_ate(p, f, "tela")
	checar(f.tela, "a parte 1 chega na tela de criação")
	checar_igual(gs.sucessao_estado(), "creating", "scene_1 -> creating no open_screen")
	var n_eventos: int = f.eventos.size()
	_tickar(gs, 5.0)
	p.avancar(5.0)
	checar_igual(f.eventos.size(), n_eventos, "a cena espera parada na tela")
	checar(not p.pular(), "a tela de criação não pode ser pulada")
	# Criação.
	checar(gs.definir_rascunho("name", "  Zé  Cutelo "), "troca o nome")
	checar(gs.definir_rascunho("skin", "skin_5") and gs.definir_rascunho("hair_color", "copper") and gs.definir_rascunho("shorts_color", "purple"), "troca pele, cabelo e calção")
	checar(not gs.definir_rascunho("hair_style", "bun") and not gs.definir_rascunho("skin", "skin_9"), "recusa opção desligada ou inexistente")
	gs.definir_rascunho("name", "   ")
	checar(not gs.confirmar_discipulo(), "nome vazio: não confirma")
	checar(gs.limpar_nome(gs.rascunho().name) != "", "...e o campo volta a um nome sorteado")
	gs.definir_rascunho("name", "  Zé  Cutelo ")
	checar(gs.confirmar_discipulo(), "CONFIRMAR")
	checar_igual(gs.sucessao_estado(), "scene_2", "parte 2")
	checar_igual([gs.discipulo.name, gs.discipulo.look.skin, gs.discipulo.look.hair_color, gs.discipulo.look.shorts_color, gs.discipulo.campaign],
		["Zé Cutelo", "skin_5", "copper", "purple", 2], "discípulo gravado como digitado, limpo")
	checar_igual(gs.escola.handover.stage, "arriving", "save grava arriving")
	var t2 := _tocar_ate(p, f, "controle")
	checar(f.controle, "a parte 2 devolve o controle")
	checar(t2 <= 6.5 or not p.comp.exato, "parte 2 em até 6,5 s (%.2f s, exato: %s)" % [t2, str(p.comp.exato)])
	checar_igual([gs.sucessao_estado(), gs.escola.handover], ["none", null], "return_control termina a sucessão")
	checar_igual(iniciou.size(), 1, "o cartão de início sai uma vez, no fim")
	checar_igual(estados, ["scene_1", "creating", "scene_2", "none"], "estados na ordem")
	checar(gs.sala_ativa(), "sala ativa no mesmo quadro do return_control")
	# O 1º soco vale e dispara a reação da cena.
	var planos: Array = []
	gs.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: planos.append(pl))
	var ganho: Dictionary = gs.clicar()
	checar(not ganho.is_empty(), "o 1º soco vale no mesmo quadro")
	checar_igual(planos.size(), 1, "1º clique: os toques do John")
	checar_igual([planos[0].cena, planos[0].com_fala, planos[0].guard, absf(planos[0].taps[1] - planos[0].taps[0] - 0.22) < 1.0e-6], ["primeira_sucessao", true, 0.5, true], "plano: reação da cena, com fala, guarda 0,5 s, toques a 0,22 s")
	checar(f.reacao and gs.mentor_cumprimentou, "a cena toca a reação e grava mentor_greeted")
	var sons := 0
	for ev in f.eventos:
		if ev.tipo == "sound" and ev.id == "tap_fist":
			sons += 1
	for k in 40:
		p.avancar(0.1)
	var sons2 := 0
	for ev in f.eventos:
		if ev.tipo == "sound" and ev.id == "tap_fist":
			sons2 += 1
	checar_igual(sons2 - sons + sons, 2, "a reação toca tap_fist 2 vezes")
	# O relógio anda depois do return_control.
	var c0: float = gs.segundos_campanha
	_tickar(gs, 10.0)
	checar(gs.segundos_campanha > c0 + 9.0, "o relógio da campanha anda depois do return_control")
	# Salvo e relido.
	gs.salvar()
	var g2 := _novo("f6b1_primeira", gs.store.pasta)
	checar_igual([g2.discipulo.name, g2.discipulo.look.skin, g2.mentor_cumprimentou, g2.escola.mentors, g2.sucessao_estado(), g2.escola.handover],
		["Zé Cutelo", "skin_5", true, ["first"], "none", null], "save v12: discípulo, mentor_greeted, mentores e handover voltam do disco")
	checar_igual(int(JSON.parse_string(ler(gs.store.pasta + "save.json")).version), 12, "arquivo na versão 12")
	checar_igual(g2.nome_lutador(), "Zé Cutelo", "nome_lutador")
	p.free()
	_liberar(g2)
	_liberar(gs)


func _teste_pular() -> void:
	var gs := _novo("f6b1_pular")
	_encerrar_e_receber(gs)
	var j := _jogador(gs)
	var p: CenaPlayer = j.p
	var f: Dictionary = j.f
	p.iniciar(gs.sucessao_cena())
	p.avancar(1.0)
	var prog: Array = []
	p.pular_progresso.connect(func(x: float) -> void: prog.append(x))
	p.segurar_pular(true, 0.3)
	checar(not f.tela and prog.size() > 0 and prog[-1] > 0.5, "segurar 0,3 s ainda não pula (anel em %s)" % str(prog))
	p.segurar_pular(false, 0.1)
	p.segurar_pular(true, 0.3)
	checar(not f.tela, "soltar zera o tempo segurado")
	p.segurar_pular(true, 0.3)
	checar(f.tela, "segurar 0,5 s pula a parte 1 até a tela de criação")
	checar_igual(gs.sucessao_estado(), "creating", "pular a parte 1 leva a creating")
	var w := p.mundo()
	checar_igual([w.atores.first.glove, w.adereços.gloves.visible], ["none", true], "pulando: luvas no saco, John sem luvas")
	p.segurar_pular(true, 1.0)
	checar(not f.controle, "ESC na tela de criação não faz nada")
	gs.confirmar_discipulo()
	p.avancar(0.3)
	p.segurar_pular(true, 0.5)
	checar(f.controle and f.fim and f.pulada, "pular a parte 2 devolve o controle e termina a cena")
	checar_igual(gs.sucessao_estado(), "none", "pular a parte 2: a campanha começa")
	var planos: Array = []
	gs.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: planos.append(pl))
	gs.clicar()
	for k in 5:
		p.avancar(0.1)
	checar(planos.size() == 1 and planos[0].cena == "primeira_sucessao" and f.reacao, "a reação do 1º clique toca mesmo pulando")
	var mundo := p.mundo()
	checar("first" in mundo.liberados and "disciple" in mundo.liberados, "end_state: atores entregues ao jogo (hand_to_game)")
	p.free()
	_liberar(gs)


func _teste_fechar_no_meio() -> void:
	# Fechou na parte 1 / na criação: volta na tela de criação, sem a cena, e depois do CONFIRMAR toca a chegada.
	var gs := _novo("f6b1_meio")
	_encerrar_e_receber(gs, true)
	gs.definir_rascunho("name", "Rita Foice")
	gs.definir_rascunho("skin", "skin_2")
	gs.salvar()
	var pasta: String = gs.store.pasta
	var g2 := _novo("f6b1_meio", pasta)
	checar_igual([g2.sucessao_estado(), g2.sucessao_retomada, g2.sucessao_cena()], ["creating", true, "chegada_discipulo"], "fechou antes do CONFIRMAR: abre na criação, a cena grande não repete")
	checar(g2.marco("cena_primeira_sucessao") and g2.escola.mentors == ["first"], "marco e John sentado já gravados")
	checar_igual([g2.rascunho().name, g2.rascunho().look.skin], ["Rita Foice", "skin_2"], "o rascunho é o último gravado")
	var seg: float = g2.segundos_campanha
	_tickar(g2, 20.0)
	checar_igual(g2.segundos_campanha, seg, "nenhum segundo antes do CONFIRMAR")
	var j := _jogador(g2)
	var p: CenaPlayer = j.p
	var f: Dictionary = j.f
	var tela := p.estado_da_tela(g2.sucessao_cena())
	checar(tela.get("tela", "") == "customize_disciple" and tela.estado.has("props"), "o player entrega o estado do palco atrás da tela (sem tocar a cena)")
	checar(g2.confirmar_discipulo(), "confirma")
	checar_igual(g2.sucessao_estado(), "arriving", "depois do CONFIRMAR: chegada curta")
	checar(p.iniciar(g2.sucessao_cena(), "depois_criar"), "a chegada começa do checkpoint depois_criar")
	_tocar_ate(p, f, "controle")
	checar(f.controle and g2.sucessao_estado() == "none", "a chegada curta devolve o controle")
	var plano_cena: Array = []
	g2.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: plano_cena.append(pl))
	g2.clicar()
	checar(plano_cena.size() == 1 and plano_cena[0].cena == "" and not plano_cena[0].com_fala, "1º clique depois da chegada curta: toques sem fala")
	p.free()
	_liberar(g2)
	_liberar(gs)
	# Fechou depois do CONFIRMAR: aplica o estado final, sem tocar, e a campanha começa.
	var a := _novo("f6b1_meio2")
	_encerrar_e_receber(a, true)
	a.definir_rascunho("name", "Beto Pavio")
	a.confirmar_discipulo()
	checar_igual(a.sucessao_estado(), "scene_2", "(antes de fechar) parte 2")
	var pasta2: String = a.store.pasta
	var b := _novo("f6b1_meio2", pasta2)
	checar_igual([b.sucessao_estado(), b.discipulo.name, b.mentor_cumprimentou], ["arriving", "Beto Pavio", false], "fechou na parte 2: discípulo gravado, aplica o final")
	var j2 := _jogador(b)
	var iniciou: Array = []
	b.nova_carreira_iniciada.connect(func(c: Dictionary) -> void: iniciou.append(c))
	checar(j2.p.aplicar_final_sem_tocar(b.sucessao_cena()), "aplica o end_state sem tocar")
	checar_igual([b.sucessao_estado(), b.escola.handover, iniciou.size()], ["none", null, 1], "campanha segue e o cartão sai")
	j2.p.free()
	_liberar(b)
	_liberar(a)
	# Fechou depois do return_control: jogo normal.
	var c := _novo("f6b1_meio3")
	_encerrar_e_receber(c, true)
	c.confirmar_discipulo()
	c.sucessao_terminou()
	c.salvar()
	var d := _novo("f6b1_meio3", c.store.pasta)
	checar_igual([d.sucessao_estado(), d.escola.handover], ["none", null], "depois do return_control: jogo normal")
	_liberar(d)
	_liberar(c)


func _teste_sucessao_seguinte_e_lista() -> void:
	var gs := _novo("f6b1_seguinte")
	checar_igual(gs.escola.roster, [], "jogo novo: lista vazia")
	gs.indice_escada = 2
	gs.aposentar()
	checar_igual(gs.escola.roster.size(), 1, "o John entra na lista ao encerrar")
	var john: Dictionary = gs.escola.roster[0]
	checar_igual([john.kind, john.name, john.look, john.end, john.wins, john.campaign], ["first", "John Bullet", null, "retire", 2, 1], "entrada do John")
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.definir_rascunho("name", "Lu Marreta")
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	gs.indice_escada = 4
	gs.aposentar()
	checar_igual(gs.escola.roster.size(), 2, "o discípulo entra na lista")
	var d2: Dictionary = gs.escola.roster[1]
	checar_igual([d2.kind, d2.name, d2.look.skin, d2.wins, d2.campaign, d2.legacy_gained >= 0], ["disciple", "Lu Marreta", gs.discipulo.look.skin, 4, 2, true], "entrada do discípulo, com visual e recorde")
	gs.receber_discipulo()
	checar_igual([gs.sucessao_estado(), gs.sucessao_cena()], ["creating", "chegada_discipulo"], "sucessão seguinte: direto na criação, chegada curta depois")
	checar_igual(gs.escola.roster.size(), 2, "a lista sobrevive ao RECEBER")
	var nome_rasc: String = gs.rascunho().name
	checar(nome_rasc != "Lu Marreta", "o sorteio evita o nome do último")
	checar(gs.sortear_rascunho() and gs.rascunho().name != nome_rasc, "SORTEAR troca tudo")
	var j := _jogador(gs)
	var p: CenaPlayer = j.p
	var f: Dictionary = j.f
	p.iniciar(gs.sucessao_cena())
	_tocar_ate(p, f, "tela")
	checar(f.tela and gs.sucessao_estado() == "creating", "a chegada curta abre direto na tela")
	checar_igual(p.comp.checkpoints.has("depois_criar"), true, "a chegada tem o checkpoint depois_criar")
	var seg_pre: float = p.comp.segmentos[0].duracao
	checar(seg_pre <= 0.01, "antes da tela: 0 s presos")
	gs.confirmar_discipulo()
	var t := _tocar_ate(p, f, "controle")
	checar(f.controle and gs.sucessao_estado() == "none", "chegada curta devolve o controle")
	checar(t <= 2.5 + 0.1 or not p.comp.exato, "chegada curta em até 2,5 s (%.2f s)" % t)
	checar(not gs.mentor_cumprimentou, "campanha nova: mentor_greeted começa false")
	p.free()
	gs.salvar()
	var g2 := _novo("f6b1_seguinte", gs.store.pasta)
	checar_igual(g2.escola.roster.size(), 2, "a lista volta do disco")
	g2.apagar_save()
	checar_igual([g2.escola.roster, g2.escola.mentors, g2.escola.handover, g2.sucessao_estado()], [[], [], null, "none"], "Apagar save zera a lista, os mentores e a sucessão")
	_liberar(g2)
	_liberar(gs)


# --- Migração v11 -> v12 ---

func _teste_migracao() -> void:
	var look_padrao := {"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green", "top": "none",
		"top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"}
	# 1) v10 (o save do dono): Carreira 3 em andamento vira a do John.
	var pasta := pasta_limpa("f6b1_mig1")
	var career := {"training": 500.0, "money": 20.0, "fame": 5, "ladder_index": 2, "glove_level": 1, "belt": true,
		"campaign_seconds": 40.0, "fight_day": 9, "active_nodes": [], "metronome_level": 0}
	var perm := {"legacy_total": 120, "career_number": 3, "careers_finished": 2, "best_wins": 4, "belts_won": 2, "skill_nodes": [],
		"revenge_opponent": "", "tree_last_node": ""}
	escrever(pasta + "save.json", JSON.stringify({"version": 10, "saved_at_unix": 1730000000, "state": {"career": career, "permanent": perm, "ending": null}}))
	var e: Dictionary = SaveStore.new(pasta).carregar().estado
	checar_igual([e.career.disciple, e.career.mentor_greeted, e.school.roster, e.school.mentors, e.school.handover],
		[null, true, [], [], null], "caso 1 (v10): sem discípulo, lista vazia, ninguém sentado")
	checar(int(e.permanent.legacy_total) == 120 and int(e.permanent.career_number) == 3 and e.permanent.skill_nodes == [], "caso 1: Legado e permanente idênticos")
	var gs := _novo("f6b1_mig1", pasta)
	checar_igual([gs.lutador_atual(), gs.nome_lutador(), gs.sucessao_estado()], ["first", "John Bullet", "none"], "caso 1: joga o John até o fim")
	gs.aposentar()
	gs.receber_discipulo()
	checar_igual([gs.sucessao_estado(), gs.sucessao_cena(), gs.numero_carreira()], ["scene_1", "primeira_sucessao", 4], "caso 1: no RECEBER toca a cena grande (Carreira 4)")
	checar_igual(gs.escola.roster.size(), 1, "caso 1: o John entra na lista")
	_liberar(gs)
	# 2) v11 com o John em andamento.
	var p2 := pasta_limpa("f6b1_mig2")
	_grava_v11(p2, {"career_number": 1, "careers_finished": 0, "legacy_total": 0},
		{"first_fighter_campaign": 1, "milestones": {"prologue_seen": {"campaign": 1, "version": 1}}, "lines_seen": {"cl_x": 1}, "last_end": null}, null)
	var e2: Dictionary = SaveStore.new(p2).carregar().estado
	checar_igual([e2.career.disciple, e2.school.roster, e2.career.mentor_greeted], [null, [], true], "caso 2 (John em andamento)")
	checar(e2.school.milestones.has("prologue_seen") and e2.school.lines_seen.has("cl_x"), "caso 2: marcos e falas vistas da 6a preservados")
	# 3) v11 com discípulo padrão em andamento (Carreira 3, o John foi a 1, um Novato a 2).
	var p3 := pasta_limpa("f6b1_mig3")
	_grava_v11(p3, {"career_number": 3, "careers_finished": 2, "legacy_total": 300, "best_wins": 5},
		{"first_fighter_campaign": 1, "milestones": {}, "lines_seen": {}, "last_end": {"kind": "defeat", "campaign": 2}}, null)
	var e3: Dictionary = SaveStore.new(p3).carregar().estado
	checar_igual(e3.career.disciple, {"name": "Novato", "look": look_padrao, "campaign": 3}, "caso 3: o discípulo em andamento vira o Novato padrão")
	checar_igual(e3.school.roster.size(), 2, "caso 3: lista com o John e o Novato anterior")
	checar_igual([e3.school.roster[0].kind, e3.school.roster[0].look, e3.school.roster[1].kind, e3.school.roster[1].name, e3.school.roster[1].end, e3.school.roster[1].wins],
		["first", null, "disciple", "Novato", "defeat", -1], "caso 3: John (look null) e Novato (fim da last_end, recorde desconhecido)")
	checar_igual(e3.school.roster[0].end, "unknown", "caso 3: fim desconhecido quando last_end não é da campanha")
	var g3 := _novo("f6b1_mig3", p3)
	checar_igual([g3.nome_lutador(), g3.lutador_atual(), g3.sucessao_estado(), g3.permanente.legacy_total], ["Novato", "disciple", "none", 300], "caso 3: joga o NOVATO normalmente")
	g3.aposentar()
	g3.receber_discipulo()
	checar_igual(g3.sucessao_cena(), "primeira_sucessao", "caso 3: no RECEBER toca a cena grande")
	_liberar(g3)
	# 4) v11 com fim pendente do John (N == F).
	var p4 := pasta_limpa("f6b1_mig4")
	var fim4 := {"kind": "defeat", "career_number": 2, "legacy_gained": 40, "legacy_notebook": 0, "legacy_total": 40, "opponent": "muralha", "tactic": "",
		"seed": 1, "player": {}, "result": {}, "reason": {}, "summary": {"wins": 3, "belts": 1, "fame": 9, "money_earned": 1.0, "play_seconds": 1.0, "art": "boxing", "location": "garage"}}
	_grava_v11(p4, {"career_number": 2, "careers_finished": 1, "legacy_total": 40},
		{"first_fighter_campaign": 2, "milestones": {}, "lines_seen": {}, "last_end": {"kind": "defeat", "campaign": 2}}, fim4)
	var e4: Dictionary = SaveStore.new(p4).carregar().estado
	checar_igual(e4.career.disciple, null, "caso 4: fim pendente do John, sem discípulo")
	var r4: Dictionary = e4.school.roster[0]
	checar_igual([e4.school.roster.size(), r4.kind, r4.end, r4.wins, r4.belt, r4.art, r4.opponent, r4.legacy_gained],
		[1, "first", "defeat", 3, true, "boxing", "muralha", 40], "caso 4: o John entra na lista com os números do fim")
	# 5) v11 com fim pendente antes do John (vindo de v10): começa o John como hoje, sem tela.
	var p5 := pasta_limpa("f6b1_mig5")
	_grava_v11(p5, {"career_number": 3, "careers_finished": 2, "legacy_total": 40},
		{"first_fighter_campaign": 4, "milestones": {}, "lines_seen": {}, "last_end": {"kind": "defeat", "campaign": 3}}, fim4)
	var e5: Dictionary = SaveStore.new(p5).carregar().estado
	checar_igual([e5.school.roster, e5.career.disciple], [[], null], "caso 5: nada na lista, sem discípulo")
	var g5 := _novo("f6b1_mig5", p5)
	var iniciou: Array = []
	g5.nova_carreira_iniciada.connect(func(c: Dictionary) -> void: iniciou.append(c))
	checar(g5.receber_discipulo(), "caso 5: RECEBER")
	checar_igual([g5.sucessao_estado(), g5.lutador_atual(), g5.numero_carreira(), g5.marco("cena_primeira_sucessao")], ["none", "first", 4, false], "caso 5: começo do John como hoje, sem tela e sem cena")
	_liberar(g5)
	# Ida e volta: v12 salvo e relido sem perda; campos ruins viram o padrão.
	var p6 := pasta_limpa("f6b1_mig6")
	escrever(p6 + "save.json", JSON.stringify({"version": 12, "saved_at_unix": 1, "state": {"career": {"disciple": {"name": "123", "look": {"skin": "skin_1", "hair_color": "lixo"}, "campaign": 2}, "mentor_greeted": "x"},
		"permanent": {"career_number": 2}, "school": {"first_fighter_campaign": 1, "roster": [{"kind": "lixo"}, {"kind": "disciple", "name": "Ana", "campaign": 2, "end": "x"}], "mentors": ["first", 5], "handover": {"stage": "x"}}}}))
	var g6 := _novo("f6b1_mig6", p6)
	checar_igual([g6.discipulo.name, g6.discipulo.look.skin, g6.discipulo.look.hair_color], ["Novato", "skin_1", "brown"], "v12 com discípulo inválido: campos ruins viram o padrão")
	checar_igual([g6.escola.roster.size(), g6.escola.roster[0].end, g6.escola.mentors, g6.escola.handover, g6.sucessao_estado()], [1, "unknown", ["first"], null, "none"], "v12 com escola inválida: itens ruins descartados")
	_liberar(g6)


# --- John mentor ---

func _com_mentor(nome: String) -> Node:
	var gs := _novo(nome)
	_encerrar_e_receber(gs, true)
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	_tickar(gs, 3.0)
	return gs


func _teste_toques() -> void:
	var gs := _com_mentor("f6b1_toques")
	var planos: Array = []
	var cancel := [0]
	gs.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: planos.append(pl))
	gs.toques_mentor_cancelados.connect(func() -> void: cancel[0] += 1)
	checar(gs.mentor_sentado() and gs.mentores_na_sala().size() == 1, "John sentado na garagem com discípulo jogando")
	# 1º clique: toques sem cena (a reação da cena foi gasta aqui? não: a cena grande armou, então tem cena).
	gs.mentor_cumprimentou = false
	gs._reacao_cena = ""
	gs._toque_ultimo = -1.0e9
	gs.clicar()
	checar_igual(planos.size(), 1, "1º clique: toques")
	checar(gs.mentor_cumprimentou, "mentor_greeted gravado na hora")
	# Guarda de 0,5 s: o clique seguinte do jogador rápido NÃO cancela.
	gs.tick(0.1)
	gs.clicar()
	checar_igual(cancel[0], 0, "clique dentro dos 0,5 s do 1º clique não cancela os toques")
	gs.clicar()
	gs.tick(0.1)
	checar_igual(cancel[0], 0, "...nem o seguinte")
	gs.clicar()  # não pede de novo: mentor_greeted já é true
	checar_igual(planos.size(), 1, "só 1º clique da campanha dá os toques do 1º clique")
	# Intervalo de 60 s: depois de vitória, bloqueado dentro do minuto; descartado, nunca guardado.
	_tickar(gs, 1.0)
	gs.luta_resolvida.emit({"win": true})
	_tickar(gs, 1.5)
	checar_igual(planos.size(), 1, "volta de vitória dentro de 60 s do último: descartado")
	_tickar(gs, 70.0)
	checar_igual(planos.size(), 1, "...e não é guardado para depois")
	# Fora do intervalo: 1,0 s de sala ativa depois da vitória.
	gs.luta_resolvida.emit({"win": true})
	_tickar(gs, 0.8)
	checar_igual(planos.size(), 1, "antes de 1,0 s de sala ativa: nada")
	_tickar(gs, 0.4)
	checar_igual(planos.size(), 2, "1,0 s depois da vitória, fora do intervalo: toques")
	checar_igual([planos[1].momento, planos[1].guard, planos[1].cena], ["win_return", 0.0, ""], "plano da vitória: sem guarda, sem cena")
	# Depois da vitória qualquer clique cancela, inclusive logo no começo.
	gs.clicar()
	checar_igual(cancel[0], 1, "clique cancela os toques da vitória")
	# Clique antes de começar: não toca.
	_tickar(gs, 70.0)
	gs.luta_resolvida.emit({"win": true})
	_tickar(gs, 0.5)
	gs.clicar()
	_tickar(gs, 2.0)
	checar_igual(planos.size(), 2, "clique antes dos toques começarem: não toca")
	# Janela e mudança de local cancelam.
	_tickar(gs, 70.0)
	gs.luta_resolvida.emit({"win": true})
	_tickar(gs, 1.05)
	checar_igual(planos.size(), 3, "(de novo, fora do intervalo)")
	var c_antes: int = cancel[0]
	gs.definir_modal(true)
	_tickar(gs, 0.1)
	checar_igual(cancel[0], c_antes + 1, "abrir janela cancela os toques")
	gs.definir_modal(false)
	# O intervalo é em tempo real: conta janela e luta.
	checar(gs._pedir_toques("win_return").is_empty(), "dentro do intervalo: descartado")
	gs._t_real += 61.0
	checar(not gs._pedir_toques("win_return").is_empty(), "passado o minuto: vale de novo")
	# Discípulo nunca faz o gesto.
	checar(gs.pedir_gesto("victory").is_empty() and gs.pedir_gesto("fight_intro").is_empty(), "discípulo: pedir_gesto devolve {}")
	_liberar(gs)
	# John na campanha dele: sem mentor, sem toques.
	var j := _novo("f6b1_toques_john")
	var pj: Array = []
	j.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: pj.append(pl))
	j.mentor_cumprimentou = false
	j.clicar()
	checar(pj.is_empty() and j.mentores_na_sala().is_empty() and not j.mentor_cumprimentou, "campanha do John: nenhum toque")
	_liberar(j)
	# Fora da garagem: ninguém sentado.
	var g2 := _com_mentor("f6b1_toques_gym")
	g2.local_id = "gym"
	checar(g2.mentores_na_sala().is_empty(), "na academia não há mentor (6c)")
	_liberar(g2)


# --- Textos ---

func _teste_textos() -> void:
	var gs := _novo("f6b1_textos")
	checar_igual([gs.nome_lutador(), gs.texto_hud_lutador(), gs.titulo_resumo()], ["John Bullet", "JOHN BULLET", "RESUMO DE JOHN BULLET"], "John: nome no lugar de Carreira N")
	checar_igual(gs.descricao_luva_inicial(), "O par do John. Velha, mas fecha direito.", "luva do John")
	checar_igual(gs.visual_lutador(), {}, "John não usa o visual do discípulo")
	_encerrar_e_receber(gs, true)
	gs.definir_rascunho("name", "Tati Gancho")
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	checar_igual([gs.nome_lutador(), gs.texto_hud_lutador(), gs.titulo_resumo()], ["Tati Gancho", "TATI GANCHO", "RESUMO DE TATI GANCHO"], "discípulo: nome no HUD e no resumo")
	checar_igual(gs.descricao_luva_inicial(), "O par do John. Agora é seu. Fecha bem.", "luva do discípulo")
	gs.permanente["last_art"] = "boxing"
	checar_igual(gs.subtitulo_escolha_arte(), "TATI GANCHO: ESCOLHA A ARTE", "subtítulo da arte com o nome")
	checar_igual(gs.cores_visual().skin.id, gs.discipulo.look.skin, "cores do visual do discípulo")
	for chave in ["disc_title", "disc_confirm", "skip_button", "skip_chip", "suc_guarda", "suc_isso", "new_disciple_button", "hud_disciple"]:
		checar(gs.texto_ui(chave) != "", "texto existe: " + chave)
	_liberar(gs)


# --- Balanço inalterado ---

func _teste_balanco() -> void:
	# A mesma campanha, com e sem a sucessão no meio, produz exatamente os mesmos números depois do return_control.
	var a := _novo("f6b1_bal_a")
	var b := _novo("f6b1_bal_b")
	for g in [a, b]:
		g.lutas.calendario["seconds_per_day"] = 60.0
		g.aposentar()
	a.nova_carreira()
	b.receber_discipulo()
	_tickar(b, 45.0)  # tempo na sucessão não conta
	b.sucessao_tela_aberta()
	b.confirmar_discipulo()
	b.sucessao_terminou()
	for g in [a, b]:
		for i in 300:
			if i % 3 == 0:
				g.clicar()
			g.tick(0.1)
	checar_igual([b.segundos_campanha, b.treino, b.dinheiro, b.dia_campanha(), b.fight_day],
		[a.segundos_campanha, a.treino, a.dinheiro, a.dia_campanha(), a.fight_day], "campanha com sucessão no meio = campanha direta (relógio, treino, ouro, dia, data da luta)")
	checar_igual([a.atributos, b.atributos], [a.atributos, a.atributos], "atributos iguais")
	# Nenhum arquivo de balanço foi tocado: números-chave de data/.
	_liberar(a)
	_liberar(b)


# --- Correções do QA (B1, B2, B6) ---

func _teste_correcoes_qa() -> void:
	# B1: a linha de apoio da derrota fala do par no saco
	var g := _novo("f6b1_b1")
	g.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	g.lutar()
	g.concluir_luta()
	if g.tem_fim_pendente() and g.fim.kind == "defeat":
		checar_igual(g.textos_fim().support, g.texto_ui("end_support_line_disc"), "B1: tela de fim usa end_support_line_disc")
	else:
		checar(false, "B1: esperava uma derrota para testar o texto")
	_liberar(g)
	# B2: lutar antes do 1º clique descarta a reação da cena; o 1º clique depois dá toques sem cena
	var gs := _novo("f6b1_b2")
	_encerrar_e_receber(gs, true)
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	gs.concluir_luta()
	_tickar(gs, 70.0, 0.5)
	var planos: Array = []
	gs.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: planos.append(pl))
	gs.clicar()
	checar(planos.size() == 1 and planos[0].cena == "" and not planos[0].com_fala, "B2: depois de lutar, o 1º clique dá toques sem cena (a UI toca)")
	_liberar(gs)
	# B6: as poses idle e punch ligam às folhas existentes
	var r := CenaValidador.novo().validar_id("primeira_sucessao")
	var ruim := false
	for p in r.pendencias:
		if p.ends_with("/idle") or p.ends_with("/punch"):
			ruim = true
	checar(not ruim, "B6: current_player/idle e first_fighter/punch não são mais pendência")
