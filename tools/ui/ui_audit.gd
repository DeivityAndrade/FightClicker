extends SceneTree
## Verificador de alinhamento de UI (skill `alinhamento-ui`, regras em .claude/skills/alinhamento-ui/references/regras.md).
##
## Uso (com janela, sem --headless, para as fontes medirem certo):
##   Godot_console.exe --path E:\Fightclicker --resolution 1280x720 --script res://tools/ui/ui_audit.gd -- --estados todos [--saida <pasta>]
## `--estados` aceita "todos" ou nomes separados por vírgula (ex.: garagem_treino,luta_inicio).
##
## Leva o jogo a cada estado pela API pública do GameState / Fluxo, mede os Controls na base 640x360
## (tolerância 1 px), salva uma captura PNG por estado e imprime uma linha por problema.
## Save de teste isolado em user://test/ui_audit/ (nunca o save real). Código de saída 1 se houver problema.
##
## Metadata lida (set_meta no código ou metadata/ no .tscn):
##   ui_align = center | center_h | center_v | left | right | ignore
##     - Control comum: centro dele igual ao do pai (nos eixos pedidos).
##     - Button: intenção do CONTEÚDO dentro do botão (padrão center). left/right: só confere o eixo vertical.
##     - ignore: o nó e tudo abaixo dele ficam fora da auditoria (números flutuantes, sala, efeitos).
##   ui_pos = center | center_h | center_v : posição do PRÓPRIO nó (inclusive Button) centrada no pai.
##   ui_margens = "h" | "hv" : margem esquerda = direita (e topo = base) do conteúdo dentro do nó.
##   ui_indent = card : linhas de texto do cartão fora da coluna do ícone (x < 20 px) começam no mesmo x do texto do botão (INDENT_UNEVEN).
##   ui_align_row = free (no pai): não cobra tamanhos iguais entre botões irmãos da mesma fileira.

const BASE := Vector2(640, 360)
const TOL := 1.0
const PASTA_SAVE := "user://test/ui_audit/"
const SAIDA_PADRAO := "C:/Users/deivi/AppData/Local/Temp/claude/ui_audit"
const CONFIG := "res://data/config.json"

const ESTADOS_TODOS := [
	"garagem_treino", "garagem_dica", "garagem_loja", "garagem_maximo", "garagem_numeros_grandes", "hud_legado_grande",
	"f12",
	"previa_aggressive", "previa_defensive", "previa_counter", "previa_cinturao",
	"luta_inicio", "luta_meio", "luta_fim_ko", "luta_fim_pontos",
	"vitoria", "cinturao", "garagem_pos_cinturao",
	"fim_derrota", "fim_azar", "aposentar", "aposentar_cinturao", "saiu_por_cima", "saiu_por_cima_cinturao",
	# Fase 4
	"garagem_metronomo", "garagem_loja_metronomo", "garagem_loja_metronomo_max", "garagem_dica_nos", "garagem_revanche",
	"cartao_inicio", "previa_revanche", "previa_revanche_porcentagem",
	"arvore_mista", "arvore_vazia", "arvore_completa", "arvore_dica_compravel", "arvore_dica_trancado", "arvore_compra",
	"vitoria_revanche", "fim_derrota_verde", "luta_numeros", "cartao_clique_fecha",
	# Fase 4b: aparelhos que chegam e treino assistido
	"b4_inicio_marcas", "b4_esteira_compravel", "b4_corda_compravel", "b4_corda_sem_treino", "b4_tres_aparelhos",
	"b4_cartao_destaque", "b4_info_aparelho", "b4_chegada_esteira_queda", "b4_chegada_esteira_poeira",
	"b4_chegada_corda", "b4_nova_carreira", "b4_clique_marca_e_foco",
	"b4_assist_dica", "b4_assist_esperando", "b4_assist_socando", "b4_assist_pulso", "b4_assist_botao",
	"b4_assist_metronomo", "b4_assist_entradas",
	"b4_fim_dica_esteira", "b4_fim_dica_corda",
	# Fase 5
	"f5_mudar_travado", "f5_mudar_sem_dinheiro", "f5_mudar_pronto", "f5_arte_primeira", "f5_academia_chegada", "f5_academia_boxe",
	"f5_arte_ultima", "f5_gym_boxe_marca", "f5_gym_boneco_foco", "f5_gym_pera_foco", "f5_gym_pera_clique", "f5_gym_descanso",
	"f5_garagem_boneco_marca", "f5_garagem_boneco_depois", "f5_garagem_pera_marca", "f5_chegada_pera", "f5_chegada_boneco",
	"f5_chip_jj_max", "f5_teclas_arte", "f5_loja_reserva", "f5_arvore_abas", "f5_arvore_estilo", "f5_arvore_estilo_dica",
	"f5_arvore_sem_artes", "f5_dica_aposentar", "f5_escada_fim", "f5_previa_tonhao", "f5_luta_tonhao", "f5_previa_kid",
	"f5_previa_kid_revanche", "f5_vitoria_cinturao_mudar", "f5_fim_dica_extra", "f5_fim_aposentou_cinturao",
	"f5_nova_carreira", "f5_nova_carreira_cartao",
]

const NOS_MISTA := ["body_jab", "career_purse", "career_scouting"]
const NOS_TODOS := ["body_jab", "body_muscle_memory", "body_heavy_hands", "body_crew", "body_crew_2", "career_purse",
	"career_scouting", "career_purse_2", "career_crowd", "career_good_loser"]

var gs: Node
var saida := SAIDA_PADRAO
var pedidos: Array = []
var estados_feitos := 0
var problemas: Array[String] = []
var _chaves := {}
var _cena: Control = null
var _estado := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var sel := "todos"
	var i := 0
	while i < args.size():
		if args[i] == "--estados" and i + 1 < args.size():
			sel = args[i + 1]
			i += 1
		elif args[i] == "--saida" and i + 1 < args.size():
			saida = args[i + 1]
			i += 1
		i += 1
	pedidos = ESTADOS_TODOS.duplicate() if sel == "todos" else Array(sel.split(","))
	DirAccess.make_dir_recursive_absolute(saida)
	gs = root.get_node("GameState")
	await process_frame
	await _rodar()
	await _esperar(0.4)  # deixa o áudio esvaziar antes de sair
	print("ESTADOS %d | PROBLEMAS %d" % [estados_feitos, problemas.size()])
	quit(1 if problemas.size() > 0 else 0)


func _quer(nome: String) -> bool:
	return nome in pedidos


# ---------------------------------------------------------------------------------------------
# Condução dos estados
# ---------------------------------------------------------------------------------------------

func _rodar() -> void:
	# Garagem
	if _quer("garagem_treino"):
		_novo_jogo()
		await _abrir()
		await _ver("garagem_treino")
	if _quer("garagem_loja"):
		_novo_jogo()
		gs.dinheiro = 120.0
		await _abrir()
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.3)
		await _ver("garagem_loja")
	if _quer("f12"):
		_novo_jogo()
		await _abrir()
		root.get_node("AppControls").alternar_debug()
		await _esperar(0.3)
		await _ver("f12")
	if _quer("garagem_dica"):
		_novo_jogo()
		gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
		gs.treino = 0.0
		await _abrir()
		await _ver("garagem_dica")
	if _quer("garagem_maximo"):
		_novo_jogo()
		for ap in gs.dados.aparelhos:
			gs.niveis_melhoria[ap.id] = ap.upgrades.size()
		gs.nivel_luva = gs.lutas.luvas.size()
		gs.dinheiro = 5000.0
		await _abrir()
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.3)
		await _ver("garagem_maximo")
	if _quer("garagem_numeros_grandes"):
		_novo_jogo()
		gs.treino = 987654321012345.0
		gs.dinheiro = 98765432101.0
		gs.fama = 9999999
		gs.atributos = {"strength": 98765432101234.0, "agility": 1234567890.0, "endurance": 555555555555.0}
		gs.geradores = {"gen_1": 99, "gen_2": 99}
		for g in gs.dados.geradores:
			gs.geradores[g.id] = 99
		await _abrir()
		await _ver("garagem_numeros_grandes")

	# Prévia (cada tática) e confirmar aposentar
	if _quer("previa_aggressive") or _quer("previa_defensive") or _quer("previa_counter"):
		_novo_jogo()
		await _abrir()
		var fluxo: Node = _cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await _esperar(0.5)
		var j: Node = fluxo.janela
		for t in gs.lutas.taticas:
			var nome := "previa_" + str(t.id)
			if _quer(nome):
				j._rotulo_tatica[str(t.id)].botao.pressed.emit()
				await _esperar(0.5)
				await _ver(nome)
	if _quer("previa_cinturao"):
		_novo_jogo()
		gs.indice_escada = 3
		gs.fama = 150
		await _abrir()
		_cena.get_node("Fluxo").abrir_previa()
		await _esperar(0.5)
		await _ver("previa_cinturao")
	if _quer("aposentar"):
		_novo_jogo()
		gs.fama = 40
		await _abrir()
		_cena.get_node("Fluxo").abrir_aposentar()
		await _esperar(0.5)
		await _ver("aposentar")
	if _quer("aposentar_cinturao"):
		_novo_jogo()
		gs.indice_escada = gs.lutas.adversarios.size()
		gs.cinturao = true
		gs.fama = 340
		await _abrir()
		_cena.get_node("Fluxo").abrir_aposentar()
		await _esperar(0.5)
		await _ver("aposentar_cinturao")

	# Luta (animada): uma luta que acaba em K.O., outra por pontos
	if _quer("luta_inicio") or _quer("luta_meio") or _quer("luta_fim_ko") or _quer("vitoria"):
		var achada := _achar_luta(true, true)
		_novo_jogo()
		gs.atributos = achada.atr
		await _abrir()
		gs.rng.seed = int(achada.k)
		var fluxo: Node = _cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await _esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await _esperar(0.25)
		await _ver("luta_inicio")
		var tela: Node = fluxo.tela
		tela._clock = 5.0
		await _esperar(0.3)
		await _ver("luta_meio")
		var res: Dictionary = gs.luta.result
		tela._clock = float(res.t_end) + 1.0
		await _esperar(0.25)
		await _ver("luta_fim_ko")
		tela._clock = tela._fim_total + 0.1
		await _esperar(0.8)
		await _ver("vitoria")
	if _quer("luta_fim_pontos"):
		var achada := _achar_luta(true, false, true)  # por pontos: quem vence não importa para a tela
		_novo_jogo()
		gs.atributos = achada.atr
		await _abrir()
		gs.rng.seed = int(achada.k)
		var fluxo: Node = _cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await _esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await _esperar(0.3)
		var res: Dictionary = gs.luta.result
		fluxo.tela._clock = float(res.t_end) + 0.7
		await _esperar(0.25)
		await _ver("luta_fim_pontos")

	# Pendentes ao abrir o jogo: vitória do cinturão e telas de fim
	if _quer("cinturao") or _quer("garagem_pos_cinturao"):
		_novo_jogo()
		gs.indice_escada = 3
		gs.fama = 150
		gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		gs.rng.seed = 7
		gs.lutar()
		await _abrir()
		await _esperar(0.7)
		await _ver("cinturao")
		if _quer("garagem_pos_cinturao"):
			_cena.get_node("Fluxo").janela.continuar_pedido.emit()
			await _esperar(0.4)
			await _ver("garagem_pos_cinturao")
	if _quer("fim_derrota"):
		_novo_jogo()
		gs.atributos = {"strength": 20.0, "agility": 5.0, "endurance": 15.0}
		gs.fama = 30
		gs.indice_escada = 2
		gs.rng.seed = 3
		gs.lutar()
		gs.aguardar_motivo()
		gs.concluir_luta()
		await _abrir()
		await _esperar(0.9)
		await _ver("fim_derrota")
	if _quer("fim_azar"):
		_novo_jogo()
		if _preparar_azar():
			await _abrir()
			await _esperar(0.9)
			await _ver("fim_azar")
		else:
			_problema("AUDIT", "estado fim_azar", "não achei uma derrota por azar (reason.kind == luck)")
	if _quer("saiu_por_cima"):
		_novo_jogo()
		gs.fama = 80
		gs.indice_escada = 2
		gs.aposentar()
		await _abrir()
		await _esperar(0.9)
		await _ver("saiu_por_cima")
	if _quer("saiu_por_cima_cinturao"):
		_novo_jogo()
		gs.indice_escada = gs.lutas.adversarios.size()
		gs.cinturao = true
		gs.fama = 340
		gs.aposentar()
		await _abrir()
		await _esperar(0.9)
		await _ver("saiu_por_cima_cinturao")
	await _rodar_fase4()
	await _rodar_fase4b()
	await _rodar_fase5()
	_fechar_cena()


# ---------------------------------------------------------------------------------------------
# Fase 4: árvore, cartão de início, Metrônomo, revanche, número de dano na arena
# ---------------------------------------------------------------------------------------------

## Põe nós comprados e Legado no save de teste (recalcula os bônus, como o carregamento faz).
func _com_nos(ids: Array, legado: int) -> void:
	gs.permanente["skill_nodes"] = ids.duplicate()
	gs.permanente["legacy_total"] = legado
	gs._recalcular_bonus()


## Deixa uma derrota pendente (tela de fim) com os nós e o Legado pedidos.
func _derrota_pendente(ids: Array, legado: int) -> void:
	_novo_jogo()
	gs.atributos = {"strength": 20.0, "agility": 5.0, "endurance": 15.0}
	gs.fama = 30
	gs.indice_escada = 2
	gs.rng.seed = 3
	gs.lutar()
	gs.aguardar_motivo()
	gs.concluir_luta()
	_com_nos(ids, legado)
	gs.fim["legacy_total"] = legado


func _abrir_arvore() -> Node:
	await _abrir()
	var fluxo: Node = _cena.get_node("Fluxo")
	fluxo.abrir_arvore()
	await _esperar(0.5)
	return fluxo.janela


func _rodar_fase4() -> void:
	var adv0: String = str(gs.lutas.adversarios[0].id)
	var fracos := {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	if _quer("garagem_metronomo"):
		_novo_jogo()
		_com_nos(NOS_MISTA, 12)
		gs.nivel_metronomo = 2
		gs.dinheiro = 200.0
		await _abrir()
		await _esperar(1.2)  # deixa o Metrônomo dar uns socos (número leve, sem tremida)
		await _ver("garagem_metronomo")
	if _quer("garagem_loja_metronomo"):
		_novo_jogo()
		gs.nivel_metronomo = 1
		gs.dinheiro = 100.0
		await _abrir()
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.3)
		await _ver("garagem_loja_metronomo")
	if _quer("garagem_loja_metronomo_max"):
		_novo_jogo()
		gs.nivel_metronomo = gs.metronomo_niveis()
		gs.dinheiro = 5000.0
		await _abrir()
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.3)
		await _ver("garagem_loja_metronomo_max")
	if _quer("garagem_dica_nos"):
		_novo_jogo()
		_com_nos(NOS_TODOS, 0)
		await _abrir()
		_cena.get_node("Hud")._abrir_dica_nos()
		await _esperar(0.2)
		await _ver("garagem_dica_nos")
	if _quer("garagem_revanche"):
		_novo_jogo()
		_com_nos(["body_jab", "career_purse"], 40)
		gs.permanente["revenge_opponent"] = adv0
		gs.atributos = fracos.duplicate()
		await _abrir()
		gs.atualizar_risco_hud()
		await _esperar(0.3)
		if not bool(gs.info_proxima().get("wait_green", false)):
			_problema("AUDIT", "estado garagem_revanche", "esperava wait_green=true (risco não é verde); ajuste os atributos do estado")
		await _ver("garagem_revanche")
	if _quer("cartao_inicio"):
		_novo_jogo()
		_com_nos(NOS_MISTA, 12)
		await _abrir()
		_cena.get_node("Fluxo")._ao_nova_carreira_iniciada(gs.cartao_inicio())
		await _esperar(0.4)
		if not gs.modal_aberto:
			_problema("AUDIT", "estado cartao_inicio", "o cartão deveria ter chamado definir_modal(true)")
		await _ver("cartao_inicio")
		await _esperar(1.6)
		if gs.modal_aberto:
			_problema("AUDIT", "estado cartao_inicio", "o cartão sumiu mas o modal continua aberto")
	if _quer("cartao_clique_fecha"):
		# O cartão aberto: clique no alvo central só fecha o cartão (não treina); o Espaço também só fecha.
		_novo_jogo()
		_com_nos(NOS_MISTA, 12)
		await _abrir()
		var fl: Node = _cena.get_node("Fluxo")
		fl._ao_nova_carreira_iniciada(gs.cartao_inicio())
		await _esperar(0.3)
		var cliques := [0]
		gs.clicou.connect(func(_a, _b, _c, _d, _e) -> void: cliques[0] += 1)
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = Vector2(336, 222) * 2.0  # janela 1280x720 = base x2  # alvo central, fora do cartão
		ev.global_position = ev.position
		ev.pressed = true
		Input.parse_input_event(ev)
		await _esperar(0.2)
		if cliques[0] > 0:
			_problema("AUDIT", "estado cartao_clique_fecha", "clique no alvo com o cartão aberto treinou")
		if fl.cartao != null:
			_problema("AUDIT", "estado cartao_clique_fecha", "o clique não fechou o cartão")
		# Espaço com o cartão aberto: só fecha.
		fl._ao_nova_carreira_iniciada(gs.cartao_inicio())
		await _esperar(0.3)
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_SPACE
		tecla.pressed = true
		Input.parse_input_event(tecla)
		await _esperar(0.2)
		if cliques[0] > 0:
			_problema("AUDIT", "estado cartao_clique_fecha", "Espaço com o cartão aberto treinou")
		if fl.cartao != null:
			_problema("AUDIT", "estado cartao_clique_fecha", "o Espaço não fechou o cartão")
		await _ver("cartao_clique_fecha")
	if _quer("hud_legado_grande"):
		# HUD no pior caso de largura: números enormes, Legado de 5 dígitos e o emblema de nós ao lado de CARREIRA.
		_novo_jogo()
		_com_nos(NOS_TODOS, 0)
		gs.treino = 987654321012345.0
		gs.dinheiro = 98765432101.0
		gs.fama = 49950  # Legado em jogo = 99900
		await _abrir()
		await _ver("hud_legado_grande")
	if _quer("previa_revanche"):
		_novo_jogo()
		_com_nos(["body_jab", "career_purse"], 40)
		gs.permanente["revenge_opponent"] = adv0
		gs.atributos = fracos.duplicate()
		await _abrir()
		_cena.get_node("Fluxo").abrir_previa()
		await _esperar(0.5)
		if _quer("previa_revanche"):
			await _ver("previa_revanche")
	if _quer("previa_revanche_porcentagem"):
		_novo_jogo()
		_com_nos(["body_jab", "career_purse", "career_scouting", "career_crowd", "career_good_loser"], 40)
		gs.permanente["revenge_opponent"] = adv0
		gs.atributos = fracos.duplicate()
		await _abrir()
		_cena.get_node("Fluxo").abrir_previa()
		await _esperar(0.5)
		await _ver("previa_revanche_porcentagem")

	# Árvore
	if _quer("arvore_mista") or _quer("arvore_dica_compravel") or _quer("arvore_dica_trancado") or _quer("arvore_compra"):
		_derrota_pendente(NOS_MISTA, 40)
		var j: Node = await _abrir_arvore()
		if _quer("arvore_mista"):
			await _ver("arvore_mista")
		if _quer("arvore_dica_compravel"):
			j.mostrar_dica("body_muscle_memory")
			await _esperar(0.2)
			await _ver("arvore_dica_compravel")
		if _quer("arvore_dica_trancado"):
			j.mostrar_dica("career_good_loser")
			await _esperar(0.2)
			await _ver("arvore_dica_trancado")
		if _quer("arvore_compra"):
			j._esconder_dica()
			var antes: int = gs.legado_disponivel()
			if not gs.comprar_no("body_muscle_memory"):
				_problema("AUDIT", "estado arvore_compra", "comprar_no(body_muscle_memory) recusou")
			await _esperar(0.8)
			if gs.legado_disponivel() != antes - 30:
				_problema("AUDIT", "estado arvore_compra", "Legado %d depois da compra, esperava %d" % [gs.legado_disponivel(), antes - 30])
			await _ver("arvore_compra")
	if _quer("arvore_vazia"):
		_derrota_pendente([], 0)
		await _abrir_arvore()
		await _ver("arvore_vazia")
	if _quer("arvore_completa"):
		_derrota_pendente(NOS_TODOS, 0)
		await _abrir_arvore()
		await _ver("arvore_completa")

	# Vitória com revanche (o algoz é o 1º adversário; o jogador é forte e vence)
	if _quer("vitoria_revanche"):
		_novo_jogo()
		_com_nos(["body_jab", "career_purse", "career_crowd"], 0)
		gs.permanente["revenge_opponent"] = adv0
		gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		gs.rng.seed = 7
		gs.lutar()
		await _abrir()
		await _esperar(0.9)
		await _ver("vitoria_revanche")

	# Tela de fim com a dica do verde (derrota que não é azar) e o botão ÁRVORE com Legado para gastar
	if _quer("fim_derrota_verde"):
		_derrota_pendente([], 12)
		gs.fim["legacy_total"] = 12
		await _abrir()
		await _esperar(0.9)
		var tx: Dictionary = gs.textos_fim(gs.fim)
		if str(tx.get("wait_green", "")) == "":
			_problema("AUDIT", "estado fim_derrota_verde", "textos_fim() sem wait_green numa derrota que não é azar")
		await _ver("fim_derrota_verde")

	# Números de dano na arena: dois golpes no mesmo ponto não podem se encavalar
	if _quer("luta_numeros"):
		var achada := _achar_luta(true, true)
		_novo_jogo()
		gs.atributos = achada.atr
		await _abrir()
		gs.rng.seed = int(achada.k)
		var fluxo: Node = _cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await _esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await _esperar(0.25)
		var tela: Node = fluxo.tela
		tela._clock = 3.0
		await _esperar(0.3)
		var p := Vector2(330, 250)
		tela._numero_de_dano(757800.0, "crit", false, p)
		tela._numero_de_dano(2400.0, "hit", false, p)
		tela._numero_de_dano(2500.0, "hit", false, p + Vector2(4, 0))
		tela._numero_de_dano(310.0, "counter", false, p + Vector2(-6, 2))
		await _esperar(0.05)
		_estado = "luta_numeros"
		var vivos: Array = []
		for n in tela._numeros:
			if n.ativo:
				vivos.append(n)
		for i in vivos.size():
			for k in range(i + 1, vivos.size()):
				var ra: Rect2 = vivos[i].retangulo()
				var rb: Rect2 = vivos[k].retangulo()
				var inter := ra.grow(1.0).intersection(rb.grow(1.0))  # com o contorno da fonte (1 px por lado)
				if inter.size.x > 0.5 and inter.size.y > 0.5:
					_problema("OVERLAP_NUM", "números de dano da arena", "%s cobre %s" % [_fmt(ra), _fmt(rb)])
		await _ver("luta_numeros")



# ---------------------------------------------------------------------------------------------
# Fase 4b: marcas de fita, botões de foco trancados, cartão de compra, chegada e treino assistido (Shift)
# ---------------------------------------------------------------------------------------------

## Deixa só estes aparelhos (além do saco) montados, com o Treino e o foco pedidos. Chamar antes de _abrir().
func _com_aparelhos(ids: Array, treino: float, foco: String = "punching_bag") -> void:
	gs.aparelhos_montados_ids = ["punching_bag"] + ids
	gs.foco = foco
	gs.treino = treino


func _exigir(condicao: bool, nome_estado: String, mensagem: String) -> void:
	if not condicao:
		_problema("AUDIT", "estado " + nome_estado, mensagem)


## Texto da interface em maiúsculas (não referencia UiTema: o verificador compila antes dos autoloads existirem).
func _txt(chave: String) -> String:
	return str(gs.preencher(gs.texto_ui(chave, ""), {})).to_upper()


func _marca_visivel(id: String) -> bool:
	return bool(_cena.get_node("Sala")._marcas[id].fita.visible)


func _tecla(codigo: Key, aperta: bool, eco: bool = false, direita: bool = false) -> void:
	var ev := InputEventKey.new()
	ev.location = KEY_LOCATION_RIGHT if direita else KEY_LOCATION_LEFT
	ev.keycode = codigo
	ev.physical_keycode = codigo
	ev.pressed = aperta
	ev.echo = eco
	Input.parse_input_event(ev)


## Evento de mouse na posição da base 640x360 (a janela do verificador é a base x2).
func _mouse(pos_base: Vector2, aperta: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos_base * 2.0
	ev.global_position = ev.position
	ev.pressed = aperta
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if aperta else 0
	Input.parse_input_event(ev)


func _centro_botao_segurar() -> Vector2:
	var faixa: Control = _cena.get_node("FaixaAssistido")
	var b: Control = faixa._botao
	return b.get_global_rect().get_center()


func _rodar_fase4b() -> void:
	var nomes_4b: Array = ESTADOS_TODOS.filter(func(n: String) -> bool: return n.begins_with("b4_"))
	var alguma := false
	for n in nomes_4b:
		if _quer(n):
			alguma = true
	if not alguma:
		return
	# --- Começo de carreira: só o saco, duas marcas de fita com a plaquinha ---
	if _quer("b4_inicio_marcas"):
		_novo_jogo()
		_com_aparelhos([], 0.0)
		await _abrir()
		_estado = "b4_inicio_marcas"
		_exigir(_marca_visivel("treadmill") and _marca_visivel("jump_rope"), _estado, "as duas marcas de fita deveriam aparecer")
		_exigir(not _cena.get_node("Sala")._esteira.visible, _estado, "esteira desenhada sem estar comprada")
		_exigir(not _cena.get_node("Sala")._corda_prego.visible, _estado, "corda desenhada sem estar comprada")
		_exigir(gs.estado_aparelho("treadmill") == "missing" and gs.estado_aparelho("jump_rope") == "locked", _estado, "estados esperados: esteira missing, corda locked")
		await _ver("b4_inicio_marcas")
	if _quer("b4_esteira_compravel"):
		_novo_jogo()
		_com_aparelhos([], 600.0)
		await _abrir()
		_estado = "b4_esteira_compravel"
		_exigir(gs.estado_aparelho("treadmill") == "buyable", _estado, "esteira deveria estar comprável com 600 de Treino")
		await _ver("b4_esteira_compravel")
	if _quer("b4_corda_compravel"):
		_novo_jogo()
		_com_aparelhos(["treadmill"], 2000.0, "treadmill")
		await _abrir()
		_estado = "b4_corda_compravel"
		_exigir(gs.estado_aparelho("jump_rope") == "buyable", _estado, "corda deveria estar comprável")
		_exigir(not _marca_visivel("treadmill") and _marca_visivel("jump_rope"), _estado, "marcas: só a da corda")
		await _ver("b4_corda_compravel")
	if _quer("b4_corda_sem_treino"):
		_novo_jogo()
		_com_aparelhos(["treadmill"], 100.0, "treadmill")
		await _abrir()
		_estado = "b4_corda_sem_treino"
		_exigir(gs.estado_aparelho("jump_rope") == "missing", _estado, "corda deveria estar sem Treino (missing)")
		await _ver("b4_corda_sem_treino")
	if _quer("b4_tres_aparelhos"):
		_novo_jogo()
		_com_aparelhos(["treadmill", "jump_rope"], 800.0, "jump_rope")
		await _abrir()
		_estado = "b4_tres_aparelhos"
		_exigir(not _marca_visivel("treadmill") and not _marca_visivel("jump_rope"), _estado, "com os 3 aparelhos não sobra marca")
		await _ver("b4_tres_aparelhos")

	# --- Cartão de compra: piscada ao apontar, informação do aparelho ---
	if _quer("b4_cartao_destaque"):
		_novo_jogo()
		_com_aparelhos([], 600.0)
		await _abrir()
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.1)
		_cena._apontar_compra("treadmill")
		_estado = "b4_cartao_destaque"
		_exigir(_cena.get_node("PainelLoja")._aba == "treino", _estado, "apontar a compra deveria abrir a aba TREINO")
		await _ver("b4_cartao_destaque")
	if _quer("b4_info_aparelho"):
		_novo_jogo()
		_com_aparelhos([], 600.0)
		await _abrir()
		_cena.get_node("PainelLoja")._sobre("a:treadmill")
		await _esperar(0.1)
		await _ver("b4_info_aparelho")

	# --- Chegada ---
	if _quer("b4_chegada_esteira_queda") or _quer("b4_chegada_esteira_poeira"):
		_novo_jogo()
		_com_aparelhos([], 600.0)
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("treadmill"), "b4_chegada_esteira", "comprar_aparelho(treadmill) recusou com 600 de Treino")
		await _esperar(0.03)
		_exigir(sala._chegando == "treadmill", "b4_chegada_esteira", "a esteira deveria estar caindo")
		_exigir(_marca_visivel("treadmill"), "b4_chegada_esteira", "a marca só some no quadro de impacto")
		if _quer("b4_chegada_esteira_queda"):
			await _ver("b4_chegada_esteira_queda")
		await _esperar(0.12)
		_exigir(not _marca_visivel("treadmill"), "b4_chegada_esteira", "a marca deveria ter sumido no impacto")
		if _quer("b4_chegada_esteira_poeira"):
			await _ver("b4_chegada_esteira_poeira")
		await _esperar(0.6)
		_exigir(sala._chegando == "" and gs.foco == "treadmill" and sala._esteira.visible, "b4_chegada_esteira",
			"depois da chegada a esteira fica no foco e visível")
		_exigir(sala._lutador.nome_sprite.begins_with("fighter_run"), "b4_chegada_esteira", "o lutador deveria estar na esteira")
	if _quer("b4_chegada_corda"):
		_novo_jogo()
		_com_aparelhos(["treadmill"], 2000.0, "treadmill")
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("jump_rope"), "b4_chegada_corda", "comprar_aparelho(jump_rope) recusou")
		await _esperar(0.03)
		_exigir(sala._chegando == "jump_rope", "b4_chegada_corda", "a corda deveria estar sendo pendurada")
		await _ver("b4_chegada_corda")
		await _esperar(0.5)
		_exigir(sala._chegando == "" and gs.foco == "jump_rope" and not _marca_visivel("jump_rope"), "b4_chegada_corda",
			"depois da chegada a corda fica no foco e sem marca")

	# --- NOVA CARREIRA: a sala volta a ter só o saco ---
	if _quer("b4_nova_carreira"):
		_derrota_pendente([], 12)
		_com_aparelhos(["treadmill", "jump_rope"], 50.0, "jump_rope")
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(not _marca_visivel("treadmill"), "b4_nova_carreira", "antes: os 3 aparelhos, sem marca")
		gs.nova_carreira()
		await _esperar(0.7)
		_estado = "b4_nova_carreira"
		_exigir(gs.aparelhos_montados() == ["punching_bag"], _estado, "nova carreira deveria deixar só o saco: %s" % str(gs.aparelhos_montados()))
		_exigir(_marca_visivel("treadmill") and _marca_visivel("jump_rope"), _estado, "as duas marcas deveriam voltar")
		_exigir(not sala._esteira.visible and not sala._corda_prego.visible, _estado, "esteira e corda não deveriam ser desenhadas")
		await _ver("b4_nova_carreira")

	# --- Clique na marca / no botão trancado / tecla 2: nada de treino nem troca de foco ---
	if _quer("b4_clique_marca_e_foco"):
		_novo_jogo()
		_com_aparelhos([], 100.0)
		await _abrir()
		_estado = "b4_clique_marca_e_foco"
		var cliques := [0]
		gs.clicou.connect(func(_a, _b, _c, _d, _e) -> void: cliques[0] += 1)
		var loja: Node = _cena.get_node("PainelLoja")
		loja._tab["loja"].botao.pressed.emit()
		await _esperar(0.1)
		_mouse(Vector2(445, 262), true)  # plaquinha da esteira no chão
		_mouse(Vector2(445, 262), false)
		await _esperar(0.2)
		_exigir(loja._aba == "treino", _estado, "clique na marca da esteira deveria abrir a aba TREINO")
		_exigir(gs.foco == "punching_bag" and cliques[0] == 0, _estado, "clique na marca não pode treinar nem trocar o foco")
		loja._tab["loja"].botao.pressed.emit()
		await _esperar(0.1)
		var barra: Control = _cena.get_node("BarraBaixo")
		var b2: Control = barra._botoes["treadmill"].botao
		var c2 := b2.get_global_rect().get_center()
		_mouse(c2, true)
		_mouse(c2, false)
		await _esperar(0.2)
		_exigir(loja._aba == "treino", _estado, "clique no botão de foco trancado deveria abrir a aba TREINO")
		_exigir(gs.foco == "punching_bag" and cliques[0] == 0, _estado, "botão trancado não pode treinar nem trocar o foco")
		_tecla(KEY_2, true)
		_tecla(KEY_2, false)
		await _esperar(0.1)
		_exigir(gs.foco == "punching_bag", _estado, "a tecla 2 não deveria focar um aparelho que não chegou")
		await _ver("b4_clique_marca_e_foco")

	# --- Treino assistido: chip em cada estado, botão, entradas ---
	if _quer("b4_assist_dica") or _quer("b4_assist_esperando") or _quer("b4_assist_socando") or _quer("b4_assist_pulso") \
			or _quer("b4_assist_botao") or _quer("b4_assist_entradas"):
		_novo_jogo()
		_com_aparelhos([], 0.0)
		await _abrir()
		var faixa: Node = _cena.get_node("FaixaAssistido")
		if _quer("b4_assist_dica"):
			_estado = "b4_assist_dica"
			_exigir(gs.assistido_estado() == "off" and faixa._chip_texto.text == _txt("assist_hint"), _estado, "dica fixa esperada: %s" % faixa._chip_texto.text)
			await _ver("b4_assist_dica")
		if _quer("b4_assist_esperando"):
			_estado = "b4_assist_esperando"
			gs.clicar()
			_tecla(KEY_SHIFT, true)
			await _esperar(0.05)
			_exigir(gs.assistido_estado() == "waiting", _estado, "segurando com a mão mexendo deveria ser waiting: " + gs.assistido_estado())
			await _ver("b4_assist_esperando")
		if _quer("b4_assist_socando") or _quer("b4_assist_pulso"):
			_estado = "b4_assist_socando"
			gs.clicar()  # mão mexendo em t=0
			_tecla(KEY_SHIFT, true)
			var socos0: int = gs.assist_socos_total
			await _esperar(2.2)  # clique em t=0: mão parada em 1 s, primeiro soco 1 s depois; o número dura 0,5 s
			_exigir(gs.assistido_estado() == "active", _estado, "deveria estar active: %s (segurando gs=%s faixa=%s modal=%s bloq=%s)" % [gs.assistido_estado(), gs.assistido_segurando(), faixa.segurando(), gs.modal_aberto, gs.acoes_bloqueadas()])
			_exigir(gs.assist_socos_total > socos0, _estado, "nenhum auto-soco do assistido em 2,2 s")
			var vivos := 0
			for nn in _cena.get_node("Sala")._numeros:
				if nn.ativo:
					vivos += 1
			_exigir(vivos > 0, _estado, "o auto-soco do assistido deveria mostrar um número flutuante")
			if _quer("b4_assist_socando"):
				await _ver("b4_assist_socando")
			if _quer("b4_assist_pulso"):
				faixa.pulsar(5.0)
				await _ver("b4_assist_pulso")
				faixa._pulso_t = 0.0
		if _quer("b4_assist_botao"):
			_estado = "b4_assist_botao"
			_tecla(KEY_SHIFT, false)
			await _esperar(0.1)
			_exigir(gs.assistido_estado() == "off", _estado, "soltou o Shift: deveria voltar a off")
			_mouse(_centro_botao_segurar(), true)
			await _esperar(0.25)
			_exigir(gs.assistido_segurando(), _estado, "botão SEGURAR pressionado deveria segurar o assistido")
			await _ver("b4_assist_botao")
			_mouse(_centro_botao_segurar(), false)
			await _esperar(0.2)
			_exigir(not gs.assistido_segurando(), _estado, "soltar o botão deveria soltar o assistido")
		if _quer("b4_assist_entradas"):
			_estado = "b4_assist_entradas"
			gs.definir_assistido(false)
			await _esperar(0.1)
			_tecla(KEY_SHIFT, true)
			await _esperar(0.05)
			_exigir(gs.assistido_segurando(), _estado, "Shift pressionado deveria segurar")
			_tecla(KEY_SHIFT, true, true)  # repetição da tecla presa: ignorada
			_tecla(KEY_SHIFT, false)
			await _esperar(0.05)
			_exigir(not gs.assistido_segurando(), _estado, "Shift solto deveria soltar (a repetição não conta)")
			_tecla(KEY_SHIFT, true)
			await _esperar(0.05)
			faixa.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)  # alt-tab com o Shift pressionado
			await _esperar(0.05)
			_exigir(not gs.assistido_segurando() and not faixa.segurando(), _estado, "perder o foco da janela deveria soltar tudo")
			_tecla(KEY_SHIFT, false)
			# Os dois Shifts: soltar um com o outro apertado continua segurando; soltar o outro solta.
			_tecla(KEY_SHIFT, true)
			_tecla(KEY_SHIFT, true, false, true)
			await _esperar(0.05)
			_tecla(KEY_SHIFT, false)
			await _esperar(0.05)
			_exigir(gs.assistido_segurando(), _estado, "soltar o Shift esquerdo com o direito apertado: continua segurando")
			_tecla(KEY_SHIFT, true)
			_tecla(KEY_SHIFT, false, false, true)
			await _esperar(0.05)
			_exigir(gs.assistido_segurando(), _estado, "soltar o Shift direito com o esquerdo apertado: continua segurando")
			_tecla(KEY_SHIFT, false)
			await _esperar(0.05)
			_exigir(not gs.assistido_segurando(), _estado, "os dois Shifts soltos: não deveria segurar")
			_mouse(_centro_botao_segurar(), true)
			await _esperar(0.1)
			_tecla(KEY_SHIFT, true)
			_tecla(KEY_SHIFT, false)
			await _esperar(0.05)
			_exigir(gs.assistido_segurando(), _estado, "soltar o Shift com o botão ainda apertado: continua segurando")
			_mouse(_centro_botao_segurar(), false)
			await _esperar(0.1)
			_exigir(not gs.assistido_segurando(), _estado, "tudo solto: não deveria segurar")
			await _ver("b4_assist_entradas")
		gs.definir_assistido(false)
	if _quer("b4_assist_metronomo"):
		_novo_jogo()
		_com_aparelhos([], 0.0)
		gs.nivel_metronomo = 1
		await _abrir()
		_estado = "b4_assist_metronomo"
		var faixa: Node = _cena.get_node("FaixaAssistido")
		_exigir(gs.assistido_estado() == "metronome" and faixa._chip_texto.text == _txt("assist_metronome"), _estado, "chip METRÔNOMO TOCANDO esperado")
		_exigir(not faixa._botao.visible, _estado, "com o Metrônomo o botão SEGURAR some")
		await _ver("b4_assist_metronomo")

	# --- Tela de fim: dica de comprar o aparelho ---
	for ap_dica in ["treadmill", "jump_rope"]:
		var nome_estado := "b4_fim_dica_esteira" if ap_dica == "treadmill" else "b4_fim_dica_corda"
		if _quer(nome_estado):
			_derrota_pendente([], 12)
			gs.fim.reason["kind"] = "missing"
			gs.fim.reason["attribute"] = "endurance" if ap_dica == "treadmill" else "agility"
			gs.fim.reason["unlock_tip"] = ap_dica
			await _abrir()
			await _esperar(0.9)
			_estado = nome_estado
			var dicas: Array = gs.lista_ui("tip_unlock_" + ap_dica)
			var dica_fim: String = str(gs.textos_fim(gs.fim).get("tip", ""))
			_exigir(dica_fim in dicas, _estado, "a dica da tela de fim deveria ser de tip_unlock_%s: \"%s\"" % [ap_dica, dica_fim])
			await _ver(nome_estado)


## Jogo novo com save isolado: dados medianos de treino (números reais nos painéis).
func _novo_jogo() -> void:
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
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0, "arts_unlocked": [], "last_art": ""}
	gs.nivel_metronomo = 0
	gs.modal_aberto = false
	gs._recalcular_bonus()
	for g in gs.dados.geradores:
		gs.geradores[g.id] = 3


func _abrir() -> void:
	_fechar_cena()
	_cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_cena)
	await _esperar(0.5)


func _fechar_cena() -> void:
	if _cena != null:
		for p in _cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()  # som tocando ao sair segura o recurso de áudio
		_cena.queue_free()
		_cena = null
	var am: Node = root.get_node_or_null("AppControls")
	if am != null and am.debug_visivel:
		am.alternar_debug()


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout


## Derrota "por azar": jogador forte que perde mesmo assim. Deixa a tela de fim pendente.
func _preparar_azar() -> bool:
	var opp: Dictionary = gs.lutas.adversarios[0]
	gs.fama = 20
	# Quanto mais forte o jogador, mais raro perder; testa vários níveis até achar uma derrota que o jogo chama de azar.
	for fator in [1.2, 1.1, 1.0, 0.95, 0.9, 0.85, 0.8, 0.7]:
		var atr := {"strength": opp.strength * fator, "agility": opp.agility * fator, "endurance": opp.endurance * fator}
		gs.atributos = atr.duplicate()
		var snap: Dictionary = gs.para_save()
		for k in range(1, 1500):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = gs.motor.lutar([atr.strength, atr.agility, atr.endurance],
				[opp.strength, opp.agility, opp.endurance], gs.tatica, int(r.randi()), false)
			if bool(res.win):
				continue
			gs.rng.seed = k
			gs.lutar()
			gs.aguardar_motivo()
			gs.concluir_luta()
			if gs.tem_fim_pendente() and str(gs.fim.reason.get("kind", "")) == "luck":
				return true
			gs.aplicar_save(snap.duplicate(true))
			break  # uma derrota por nível basta; se não foi azar, sobe o nível
	return false


# ---------------------------------------------------------------------------------------------
# Captura + auditoria de um estado
# ---------------------------------------------------------------------------------------------

func _ver(nome: String) -> void:
	_estado = nome
	_chaves.clear()
	await _esperar(0.1)
	_auditar(_cena)
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_width() < 1280:
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(saida.path_join(nome + ".png"))
	estados_feitos += 1


func _problema(codigo: String, no: Variant, detalhe: String) -> void:
	var caminho := str(no)
	if no is Node and _cena != null and _cena.is_ancestor_of(no):
		caminho = str(_cena.get_path_to(no))
		if no is Label and str(no.text) != "":
			caminho += ' "%s"' % str(no.text).replace("\n", " ").left(24)
		elif no is Button:
			var tx := _texto_botao(no)
			if tx != "":
				caminho += ' "%s"' % tx.left(24)
	var chave := "%s|%s|%s" % [codigo, caminho, detalhe]
	if _chaves.has(chave):
		return
	_chaves[chave] = true
	var linha := "%s  %s  %s  %s" % [codigo, caminho, _estado, detalhe]
	problemas.append(linha)
	print(linha)


func _texto_botao(b: Button) -> String:
	if b.text != "":
		return b.text
	for c in b.get_children():
		if c is Label and c.visible and c.text != "":
			return c.text
	return ""


# ---------------------------------------------------------------------------------------------
# Medidas
# ---------------------------------------------------------------------------------------------

func _modo(n: Node, chave: String = "ui_align") -> String:
	return str(n.get_meta(chave, ""))


func _ignorado(n: Node) -> bool:
	var p: Node = n
	while p != null:
		if p.has_meta("ui_align") and str(p.get_meta("ui_align")) == "ignore":
			return true
		p = p.get_parent()
	return false


func _coletar(n: Node, lista: Array[Control]) -> void:
	if n is CanvasItem and not n.visible:
		return
	if n.has_meta("ui_align") and str(n.get_meta("ui_align")) == "ignore":
		return
	if n is Control:
		if _recortado(n):
			return  # rolado para fora da janela de um pai que recorta (aba TREINO rolada): não aparece, não se audita
		lista.append(n)
	elif n is CanvasItem or n is Window:
		if n != root:
			return  # Node2D e afins: arte, não interface
	for c in n.get_children():
		_coletar(c, lista)


## true se algum pai que recorta o conteúdo (clip_contents) não cobre este controle nenhum pouco.
func _recortado(n: Control) -> bool:
	var r := _rect(n)
	var p := n.get_parent()
	while p != null:
		if p is Control and p.clip_contents and not _rect(p).intersects(r):
			return true
		p = p.get_parent()
	return false


func _rect(n: Control) -> Rect2:
	return n.get_global_transform() * Rect2(Vector2.ZERO, n.size)


## Retângulo do texto realmente desenhado (fonte 5x7: cap de 7 px, sem a folga de 1 px depois da última letra).
func _rect_texto(l: Label) -> Rect2:
	var fonte: Font = l.get_theme_font("font")
	var fs: int = l.get_theme_font_size("font_size")
	var lh: float = fonte.get_height(fs)
	var ls: float = float(l.get_theme_constant("line_spacing"))
	var larguras := _larguras(l)
	var n_lin: int = maxi(1, larguras.size())
	var minx := INF
	var maxx := -INF
	for i in n_lin:
		var lw: float = larguras[i]
		var off := 0.0
		match l.horizontal_alignment:
			HORIZONTAL_ALIGNMENT_CENTER:
				off = (l.size.x - lw) / 2.0
			HORIZONTAL_ALIGNMENT_RIGHT:
				off = l.size.x - lw
		minx = minf(minx, off)
		maxx = maxf(maxx, off + lw - 1.0)
	var altura := n_lin * lh + (n_lin - 1) * ls
	var oy := 0.0
	match l.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			oy = (l.size.y - altura) / 2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			oy = l.size.y - altura
	var topo := oy + 2.0
	var base := oy + (n_lin - 1) * (lh + ls) + 9.0
	return l.get_global_transform() * Rect2(minx, topo, maxx - minx, base - topo)


func _visual(n: Control) -> Rect2:
	if n is Label:
		return _rect_texto(n)
	return _rect(n)


## Área útil: o retângulo do botão sem as margens do estilo (o "degrau" de baixo do botão não é conteúdo).
func _area(n: Control) -> Rect2:
	var r := _rect(n)
	if n is Button:
		var sb: StyleBox = n.get_theme_stylebox("normal")
		if sb != null:
			var e := sb.get_margin(SIDE_LEFT)
			var t := sb.get_margin(SIDE_TOP)
			var d := sb.get_margin(SIDE_RIGHT)
			var b := sb.get_margin(SIDE_BOTTOM)
			return Rect2(r.position + Vector2(e, t), r.size - Vector2(e + d, t + b))
	return r


func _tem_texto(n: Node) -> bool:
	return n is Label and n.visible and n.text != ""


func _conteudo_botao(b: Button) -> Array[Control]:
	var itens: Array[Control] = []
	for c in b.get_children():
		if not (c is Control) or not c.visible or _modo(c) == "ignore":
			continue
		if _tem_texto(c) or c is TextureRect:
			itens.append(c)
	return itens


func _uniao(rs: Array[Rect2]) -> Rect2:
	var u: Rect2 = rs[0]
	for i in range(1, rs.size()):
		u = u.merge(rs[i])
	return u


## Unidades visuais de um nó: Labels (texto), imagens, botões e caixas; Control comum vira seus filhos.
func _unidades(n: Control, saida_: Array[Rect2], excluir_fundo: Rect2 = Rect2()) -> void:
	for c in n.get_children():
		if not (c is Control) or not c.visible or _modo(c) == "ignore":
			continue
		if c is Label:
			if c.text != "":
				saida_.append(_rect_texto(c))
		elif c is Button or c is TextureRect or c is ColorRect or c is Panel or c is NinePatchRect:
			var r := _rect(c)
			if excluir_fundo.size != Vector2.ZERO and r.is_equal_approx(excluir_fundo):
				continue
			saida_.append(r)
		else:
			_unidades(c, saida_, excluir_fundo)


# ---------------------------------------------------------------------------------------------
# Regras
# ---------------------------------------------------------------------------------------------

func _auditar(raiz: Node) -> void:
	var lista: Array[Control] = []
	_coletar(raiz, lista)
	for n in lista:
		_regras_botao(n)
		_regras_label(n)
		_regra_centro(n)
		_regra_margens(n)
		_regra_recuo(n)
		_regra_fora_e_corte(n)
		_regra_subpixel(n)
	_regra_fileiras(lista)
	_regra_sobreposicao(lista)


func _regras_botao(n: Control) -> void:
	if not (n is Button):
		return
	var b: Button = n
	var modo := _modo(b)
	if modo == "ignore":
		return
	if modo == "":
		modo = "center"
	if b.text != "" and modo in ["center", "center_h", "center_v"] and b.alignment != HORIZONTAL_ALIGNMENT_CENTER:
		_problema("TXT_ALIGN", b, "Button com texto sem alignment = CENTER")
	var itens := _conteudo_botao(b)
	if itens.is_empty():
		return
	var rs: Array[Rect2] = []
	var tem_icone := false
	for c in itens:
		rs.append(_visual(c))
		if c is TextureRect:
			tem_icone = true
	var u := _uniao(rs)
	var a := _area(b)
	if modo in ["center", "center_h"]:
		var dx := u.get_center().x - a.get_center().x
		if absf(dx) > TOL + 0.01:
			_problema("ICON_GROUP" if tem_icone else "TXT_OFFCENTER", b,
				"conteúdo centro x=%.1f, esperado %.1f, Δ=%.1fpx" % [u.get_center().x, a.get_center().x, dx])
	if modo != "ignore":
		var dy := u.get_center().y - a.get_center().y
		if absf(dy) > TOL + 0.01:
			_problema("ICON_GROUP" if tem_icone else "TXT_OFFCENTER", b,
				"conteúdo centro y=%.1f, esperado %.1f, Δ=%.1fpx" % [u.get_center().y, a.get_center().y, dy])
	# Conteúdo que não cabe no botão.
	if u.position.x < a.position.x - 0.01 - 2.0 or u.end.x > a.end.x + 0.01 + 2.0:
		_problema("CLIPPED", b, "conteúdo %.0f..%.0f passa da área útil %.0f..%.0f" % [u.position.x, u.end.x, a.position.x, a.end.x])


func _regras_label(n: Control) -> void:
	if not (n is Label):
		return
	var l: Label = n
	var modo := _modo(l)
	if modo in ["center", "center_h"] and l.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		_problema("TXT_ALIGN", l, "ui_align=%s mas horizontal_alignment não é CENTER" % modo)
	if modo in ["center", "center_v"] and l.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		_problema("TXT_ALIGN", l, "ui_align=%s mas vertical_alignment não é CENTER" % modo)
	if modo == "left" and l.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT:
		_problema("TXT_ALIGN", l, "ui_align=left mas horizontal_alignment não é LEFT")
	if modo == "right" and l.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		_problema("TXT_ALIGN", l, "ui_align=right mas horizontal_alignment não é RIGHT")
	if l.text == "":
		return
	# Texto que passa da largura do próprio rótulo.
	var larg_max := 0.0
	for w in _larguras(l):
		larg_max = maxf(larg_max, w)
	if l.size.x > 0.0 and larg_max > l.size.x + 0.01 and l.autowrap_mode == TextServer.AUTOWRAP_OFF:
		_problema("CLIPPED", l, "texto %.0fpx mais largo que o rótulo (%.0fpx)" % [larg_max, l.size.x])
	# Texto que sai do pai.
	var p := l.get_parent()
	if p is Control and _modo(p) != "ignore" and (p.size.x < BASE.x or p.size.y < BASE.y):
		var pr := _rect(p)
		var vr := _rect_texto(l)
		if vr.position.x < pr.position.x - TOL or vr.end.x > pr.end.x + TOL \
				or vr.position.y < pr.position.y - TOL or vr.end.y > pr.end.y + TOL:
			_problema("CLIPPED", l, "texto %s sai do pai %s" % [_fmt(vr), _fmt(pr)])


## Largura de cada linha do texto (com quebra automática quando o rótulo tem autowrap).
func _larguras(l: Label) -> PackedFloat32Array:
	var tp := TextParagraph.new()
	tp.add_string(l.text, l.get_theme_font("font"), l.get_theme_font_size("font_size"))
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
		tp.width = l.size.x
		tp.break_flags = TextServer.BREAK_WORD_BOUND | TextServer.BREAK_MANDATORY
	else:
		tp.break_flags = TextServer.BREAK_MANDATORY
	var r := PackedFloat32Array()
	for i in tp.get_line_count():
		r.append(tp.get_line_width(i))
	if r.is_empty():
		r.append(0.0)
	return r


func _fmt(r: Rect2) -> String:
	return "[%.1f,%.1f %.1fx%.1f]" % [r.position.x, r.position.y, r.size.x, r.size.y]


## ui_align (nós comuns) e ui_pos (qualquer nó, inclusive botões): centro igual ao do pai.
func _regra_centro(n: Control) -> void:
	var pedidos_centro: Array[String] = []
	if not (n is Button):
		pedidos_centro.append(_modo(n))
	pedidos_centro.append(_modo(n, "ui_pos"))
	var p := n.get_parent()
	if not (p is Control):
		return
	for modo in pedidos_centro:
		if modo not in ["center", "center_h", "center_v"]:
			continue
		var a := _area(p)
		var v := _visual(n)
		if modo in ["center", "center_h"]:
			var dx := v.get_center().x - a.get_center().x
			if absf(dx) > TOL + 0.01:
				_problema("CHILD_OFFCENTER", n, "centro x=%.1f, esperado %.1f, Δ=%.1fpx" % [v.get_center().x, a.get_center().x, dx])
		if modo in ["center", "center_v"]:
			var dy := v.get_center().y - a.get_center().y
			if absf(dy) > TOL + 0.01:
				_problema("CHILD_OFFCENTER", n, "centro y=%.1f, esperado %.1f, Δ=%.1fpx" % [v.get_center().y, a.get_center().y, dy])


## ui_margens: margem esquerda = direita (e topo = base) do conteúdo dentro do nó.
func _regra_margens(n: Control) -> void:
	var m := _modo(n, "ui_margens")
	if m == "":
		return
	var us: Array[Rect2] = []
	var r := _rect(n)
	if n.get_child_count() > 0 and not (n is NinePatchRect or n is Panel):
		_unidades(n, us, r)
	else:
		# Moldura sem filhos: conteúdo = irmãos que caem dentro dela.
		var p := n.get_parent()
		var todos: Array[Rect2] = []
		_unidades(p, todos, Rect2())
		for u in todos:
			if r.encloses(u) and not u.is_equal_approx(r):
				us.append(u)
	if us.is_empty():
		return
	var u := _uniao(us)
	var esq := u.position.x - r.position.x
	var dir := r.end.x - u.end.x
	if absf(esq - dir) > TOL + 0.01:
		_problema("MARGIN_ASYM", n, "margem esquerda %.1f, direita %.1f (Δ=%.1fpx)" % [esq, dir, esq - dir])
	if m == "hv":
		var topo := u.position.y - r.position.y
		var base := r.end.y - u.end.y
		if absf(topo - base) > TOL + 0.01:
			_problema("MARGIN_ASYM", n, "margem de cima %.1f, de baixo %.1f (Δ=%.1fpx)" % [topo, base, topo - base])


## ui_indent = card: linhas de texto soltas na coluna esquerda do cartão (x < 20 px do cartão) começam no mesmo x do
## texto do botão do cartão. Pega a linha que "encosta" na borda sem o recuo das irmãs.
func _regra_recuo(n: Control) -> void:
	if _modo(n, "ui_indent") != "card":
		return
	var ref := -1.0
	for c in n.get_children():
		if c is Button and c.visible:
			for t in c.get_children():
				if t is Label and t.visible and t.text != "" and _modo(t) != "ignore" and t.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT:
					ref = _rect_texto(t).position.x
					break
		if ref >= 0.0:
			break
	if ref < 0.0:
		return
	var x0 := _rect(n).position.x
	for c in n.get_children():
		if c is Label and c.visible and c.text != "" and _modo(c) != "ignore":
			var x := _rect_texto(c).position.x
			if x - x0 < 20.0 and absf(x - ref) > TOL + 0.01:
				_problema("INDENT_UNEVEN", c, "linha começa em x=%.1f, o texto do botão em x=%.1f (Δ=%.1fpx)" % [x, ref, x - ref])


func _regra_fora_e_corte(n: Control) -> void:
	if n.modulate.a < 0.05 or n.size == Vector2.ZERO:
		return
	if n is Label and n.text == "":
		return
	var v := _visual(n)
	var tela := Rect2(Vector2.ZERO, BASE)
	if v.position.x < -0.5 or v.position.y < -0.5 or v.end.x > BASE.x + 0.5 or v.end.y > BASE.y + 0.5:
		if n is Label or n is Button or n is TextureRect or n is Panel or n is NinePatchRect or n is ColorRect:
			_problema("OFFSCREEN", n, "fora da tela 640x360: %s" % _fmt(v))


func _regra_subpixel(n: Control) -> void:
	if n.modulate.a < 0.05:
		return
	var t := n.get_global_transform()
	var o := t.origin
	var s := n.size * t.get_scale()
	for val in [o.x, o.y, s.x, s.y]:
		var f: float = absf(fposmod(val, 1.0))
		if f > 0.01 and f < 0.99:
			_problema("SUBPIXEL", n, "posição/tamanho não inteiro na base: pos=(%.2f,%.2f) tam=(%.2f,%.2f)" % [o.x, o.y, s.x, s.y])
			return


## Botões irmãos na mesma fileira (mesmo y): mesmo tamanho e espaçamento.
func _regra_fileiras(lista: Array[Control]) -> void:
	var pais := {}
	for n in lista:
		if n is Button and _modo(n) != "ignore":
			var p := n.get_parent()
			if p != null and str(p.get_meta("ui_align_row", "")) != "free":
				if not pais.has(p):
					pais[p] = []
				pais[p].append(n)
	for p in pais:
		var botoes: Array = pais[p]
		var usados := {}
		for b in botoes:
			if usados.has(b):
				continue
			var fila: Array = []
			for o in botoes:
				if absf(o.position.y - b.position.y) <= TOL and not usados.has(o):
					fila.append(o)
					usados[o] = true
			if fila.size() < 2:
				continue
			fila.sort_custom(func(x: Control, y: Control) -> bool: return x.position.x < y.position.x)
			var ref: Control = fila[0]
			for i in range(1, fila.size()):
				var o: Control = fila[i]
				if absf(o.size.x - ref.size.x) > TOL or absf(o.size.y - ref.size.y) > TOL:
					_problema("ROW_UNEVEN", o, "tamanho %.0fx%.0f difere do irmão %.0fx%.0f" % [o.size.x, o.size.y, ref.size.x, ref.size.y])
			if fila.size() >= 3:
				var gap0: float = fila[1].position.x - fila[0].position.x - fila[0].size.x
				for i in range(1, fila.size() - 1):
					var g: float = fila[i + 1].position.x - fila[i].position.x - fila[i].size.x
					if absf(g - gap0) > TOL:
						_problema("ROW_UNEVEN", fila[i + 1], "espaçamento %.0f difere do primeiro (%.0f)" % [g, gap0])


## Irmãos (texto, imagem, botão) que se cobrem.
func _regra_sobreposicao(lista: Array[Control]) -> void:
	var por_pai := {}
	for n in lista:
		if not (n is Button or n is TextureRect or _tem_texto(n)):
			continue
		if n.modulate.a < 0.05:
			continue
		var p := n.get_parent()
		if not por_pai.has(p):
			por_pai[p] = []
		por_pai[p].append(n)
	for p in por_pai:
		var itens: Array = por_pai[p]
		for i in itens.size():
			for j in range(i + 1, itens.size()):
				var a: Control = itens[i]
				var b: Control = itens[j]
				var ra := _visual(a)
				var rb := _visual(b)
				var inter := ra.intersection(rb)
				if inter.size.x > TOL and inter.size.y > TOL:
					_problema("OVERLAP", a, "cobre \"%s\" %s x %s" % [_nome_curto(b), _fmt(ra), _fmt(rb)])


func _nome_curto(n: Control) -> String:
	if n is Label:
		return n.text.left(20)
	if n is Button:
		return "botão " + _texto_botao(n).left(16)
	return n.name


## Procura (sem efeitos, só a simulação) uma luta contra o 1º adversário com o resultado pedido, variando a força
## do jogador. O RNG do jogo sorteia a semente com randi(): `gs.rng.seed = k` reproduz a luta achada.
func _achar_luta(vitoria: bool, ko: bool, qualquer_resultado: bool = false) -> Dictionary:
	var opp: Dictionary = gs.lutas.adversarios[0]
	for fs in [4.0, 2.0, 1.0, 0.5, 0.25, 0.1, 0.05]:  # força do jogador / força do adversário
		for fe in [4.0, 2.0, 1.0, 0.5]:  # resistência do jogador / resistência do adversário
			var r0 := _achar_luta_com(opp, {"strength": opp.strength * fs, "agility": opp.agility, "endurance": opp.endurance * fe}, vitoria, ko, qualquer_resultado)
			if not r0.is_empty():
				return r0
	_problema("AUDIT", "estado luta", "não achei uma luta com win=%s ko=%s" % [str(vitoria), str(ko)])
	return {"atr": {"strength": 6000.0, "agility": 1200.0, "endurance": 4800.0}, "k": 1}


func _achar_luta_com(opp: Dictionary, atr: Dictionary, vitoria: bool, ko: bool, qualquer: bool) -> Dictionary:
	for k in range(1, 300):
		var r := RandomNumberGenerator.new()
		r.seed = k
		var res: Dictionary = gs.motor.lutar([atr.strength, atr.agility, atr.endurance],
			[opp.strength, opp.agility, opp.endurance], gs.lutas.tatica_padrao, int(r.randi()), false)
		if (qualquer or bool(res.win) == vitoria) and bool(res.ko) == ko:
			return {"atr": atr, "k": k}
	return {}


# ---------------------------------------------------------------------------------------------
# Fase 5: mudança, academia, janela de arte, aparelhos das artes, reserva da LOJA, aba ESTILO, dica de aposentar
# ---------------------------------------------------------------------------------------------

## Põe a carreira na academia (cinturão feito, Tonhão na frente), com a arte pedida e as artes liberadas. Antes de _abrir().
func _academia(arte: String, ids: Array, treino: float, foco: String = "punching_bag", escada: int = 4) -> void:
	gs.indice_escada = escada
	gs.cinturao = true
	gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.permanente["last_art"] = arte
	gs.arte_id = arte
	gs.arte_segundos = 0.0
	gs._atualizar_traco()
	_com_aparelhos(ids, treino, foco)


## Garagem de uma carreira com arte desde o minuto 0 (a partir da 3ª carreira).
func _garagem_arte(arte: String, ids: Array, treino: float, foco: String = "punching_bag") -> void:
	gs.local_id = "garage"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.permanente["last_art"] = arte
	gs.arte_id = arte
	gs._atualizar_traco()
	_com_aparelhos(ids, treino, foco)


func _botao_mudar() -> Button:
	for b in _cena.get_node("PainelAtributos").find_children("*", "Button", true, false):
		return b
	return null


func _rodar_fase5() -> void:
	var nomes: Array = ESTADOS_TODOS.filter(func(n: String) -> bool: return n.begins_with("f5_"))
	var alguma := false
	for n in nomes:
		if _quer(n):
			alguma = true
	if not alguma:
		return
	var forte := {"strength": 5.0e6, "agility": 5.0e6, "endurance": 5.0e6}

	# --- MUDAR: cartão em cada estado ---
	if _quer("f5_mudar_travado"):
		_novo_jogo()
		gs.indice_escada = 2
		await _abrir()
		_estado = "f5_mudar_travado"
		_exigir(gs.estado_mudanca() == "locked" and _botao_mudar() == null, _estado, "sem cinturão o botão MUDAR não existe")
		await _ver("f5_mudar_travado")
	if _quer("f5_mudar_sem_dinheiro"):
		_novo_jogo()
		gs.indice_escada = 4
		gs.cinturao = true
		gs.dinheiro = 300.0
		await _abrir()
		_estado = "f5_mudar_sem_dinheiro"
		_exigir(gs.estado_mudanca() == "missing" and _botao_mudar() != null and _botao_mudar().disabled, _estado, "MUDAR apagado sem dinheiro")
		await _ver("f5_mudar_sem_dinheiro")
	if _quer("f5_mudar_pronto") or _quer("f5_arte_primeira") or _quer("f5_academia_chegada") or _quer("f5_academia_boxe"):
		_novo_jogo()
		gs.indice_escada = 4
		gs.cinturao = true
		gs.dinheiro = 1000.0
		await _abrir()
		_estado = "f5_mudar_pronto"
		_exigir(gs.estado_mudanca() == "ready" and _botao_mudar() != null and not _botao_mudar().disabled, _estado, "MUDAR aceso com $1.000")
		_exigir(gs.estado_escada() == "move", _estado, "estado_escada deveria ser move")
		await _ver("f5_mudar_pronto")
		var fl: Node = _cena.get_node("Fluxo")
		_botao_mudar().pressed.emit()
		await _esperar(0.5)
		_estado = "f5_mudar_fluxo"
		_exigir(gs.local_id == "gym" and gs.dinheiro == 0.0, _estado, "MUDAR deveria levar à academia e cobrar $1.000")
		_exigir(fl.janela != null and fl.janela.has_method("_escolher") and gs.modal_aberto, _estado, "a 1ª chegada deveria abrir a janela de arte")
		if _quer("f5_arte_primeira"):
			await _ver("f5_arte_primeira")
		# nada mais é possível enquanto a escolha está pendente
		_exigir(gs.clicar().is_empty() and not gs.pode_lutar(), _estado, "com a escolha pendente o clique e a luta ficam travados")
		fl.janela._escolher("boxing")
		await _esperar(0.7)
		_exigir(gs.arte_id == "boxing" and fl.janela == null and not gs.modal_aberto, _estado, "escolher a arte fecha a janela e solta o modal")
		await _ver("f5_academia_chegada")
		await _esperar(1.0)
		await _ver("f5_academia_boxe")
	if _quer("f5_arte_ultima"):
		_novo_jogo()
		gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		gs.permanente["last_art"] = "boxing"
		gs.permanente["career_number"] = 3
		await _abrir()
		await _esperar(0.4)
		_estado = "f5_arte_ultima"
		var fj: Node = _cena.get_node("Fluxo").janela
		_exigir(fj != null and fj.has_method("_escolher"), _estado, "ao abrir com a escolha pendente a janela deveria abrir")
		await _ver("f5_arte_ultima")

	# --- Academia com cada arte, 4 botões de foco ---
	if _quer("f5_gym_boxe_marca"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope"], 3000.0)
		await _abrir()
		_estado = "f5_gym_boxe_marca"
		_exigir(gs.estado_aparelho("speed_bag") == "buyable" and gs.estado_aparelho("grappling_dummy") == "absent", _estado, "pera comprável, boneco ausente")
		_exigir(_marca_visivel("speed_bag") and not _marca_visivel("grappling_dummy"), _estado, "só a marca da pera")
		_cena._apontar_compra("speed_bag")
		await _esperar(0.3)
		await _ver("f5_gym_boxe_marca")
	if _quer("f5_gym_boneco_foco"):
		_novo_jogo()
		_academia("bjj", ["treadmill", "jump_rope", "grappling_dummy"], 3000.0, "grappling_dummy")
		gs.niveis_melhoria["grappling_dummy"] = 1
		await _abrir()
		await _esperar(0.3)
		_exigir(not _marca_visivel("grappling_dummy") and not _marca_visivel("speed_bag"), "f5_gym_boneco_foco", "sem marcas")
		await _ver("f5_gym_boneco_foco")
	if _quer("f5_gym_pera_foco") or _quer("f5_gym_pera_clique"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 3000.0, "speed_bag")
		await _abrir()
		await _esperar(0.3)
		await _ver("f5_gym_pera_foco")
		if _quer("f5_gym_pera_clique"):
			gs.clicar()
			await _esperar(0.12)
			await _ver("f5_gym_pera_clique")
	if _quer("f5_gym_descanso"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 3000.0, "punching_bag")
		await _abrir()
		await _esperar(0.3)
		await _ver("f5_gym_descanso")
	if _quer("f5_garagem_boneco_marca"):
		_novo_jogo()
		_garagem_arte("bjj", ["treadmill"], 3000.0, "treadmill")
		await _abrir()
		_estado = "f5_garagem_boneco_marca"
		_exigir(_marca_visivel("grappling_dummy") and not _marca_visivel("speed_bag"), _estado, "só a marca do boneco")
		_cena._apontar_compra("grappling_dummy")
		await _esperar(0.3)
		await _ver("f5_garagem_boneco_marca")
	if _quer("f5_garagem_boneco_depois"):
		_novo_jogo()
		_garagem_arte("bjj", [], 0.0)
		await _abrir()
		await _ver("f5_garagem_boneco_depois")
	if _quer("f5_garagem_pera_marca"):
		_novo_jogo()
		_garagem_arte("boxing", ["treadmill"], 3000.0, "treadmill")
		await _abrir()
		await _ver("f5_garagem_pera_marca")
	if _quer("f5_chegada_pera"):
		_novo_jogo()
		_garagem_arte("boxing", ["treadmill"], 3000.0, "treadmill")
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("speed_bag"), "f5_chegada_pera", "comprar_aparelho(speed_bag) recusou")
		await _esperar(0.1)
		_exigir(sala._chegando == "speed_bag", "f5_chegada_pera", "a pera deveria estar chegando")
		await _ver("f5_chegada_pera")
		await _esperar(0.9)
		_exigir(sala._chegando == "" and gs.foco == "speed_bag" and sala._pera.visible, "f5_chegada_pera", "depois da chegada a pera fica no foco")
	if _quer("f5_chegada_boneco"):
		_novo_jogo()
		_garagem_arte("bjj", ["treadmill"], 3000.0, "treadmill")
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("grappling_dummy"), "f5_chegada_boneco", "comprar_aparelho(grappling_dummy) recusou")
		await _esperar(0.12)
		await _ver("f5_chegada_boneco")
		await _esperar(0.6)
		_exigir(sala._chegando == "" and gs.foco == "grappling_dummy", "f5_chegada_boneco", "depois da chegada o boneco fica no foco")
	if _quer("f5_chip_jj_max"):
		_novo_jogo()
		_academia("bjj", ["treadmill", "jump_rope"], 800.0)
		gs.arte_segundos = 900.0
		await _abrir()
		await _esperar(1.2)
		_exigir(_cena.get_node("BarraBaixo")._chip.visible, "f5_chip_jj_max", "o chip da arte deveria aparecer")
		await _ver("f5_chip_jj_max")
	if _quer("f5_teclas_arte"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 800.0, "punching_bag")
		await _abrir()
		_estado = "f5_teclas_arte"
		_tecla(KEY_4, true)
		_tecla(KEY_4, false)
		await _esperar(0.2)
		_exigir(gs.foco == "speed_bag", _estado, "a tecla 4 deveria focar a pera")
		await _ver("f5_teclas_arte")

	# --- LOJA: reserva da mudança ---
	if _quer("f5_loja_reserva"):
		_novo_jogo()
		gs.indice_escada = 4
		gs.cinturao = true
		gs.dinheiro = 1100.0
		await _abrir()
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.3)
		_estado = "f5_loja_reserva"
		_exigir(gs.reserva_mudanca() > 0.0 and gs.loja_estado(900.0) == "reserve", _estado, "a reserva da mudança deveria recusar o item")
		await _ver("f5_loja_reserva")

	# --- Árvore: aba ESTILO ---
	if _quer("f5_arvore_abas") or _quer("f5_arvore_estilo") or _quer("f5_arvore_estilo_dica"):
		_derrota_pendente(NOS_MISTA, 1500)
		gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		var j: Node = await _abrir_arvore()
		_estado = "f5_arvore_abas"
		_exigir(j._abas.size() == 2, _estado, "com as artes liberadas a árvore deveria ter as 2 abas")
		await _ver("f5_arvore_abas")
		j._abas["style"].pressed.emit()
		await _esperar(0.4)
		await _ver("f5_arvore_estilo")
		j.mostrar_dica("style_boxing")
		await _esperar(0.2)
		await _ver("f5_arvore_estilo_dica")
	if _quer("f5_arvore_sem_artes"):
		_derrota_pendente(NOS_MISTA, 40)
		var j: Node = await _abrir_arvore()
		_exigir(j._abas.is_empty(), "f5_arvore_sem_artes", "sem artes liberadas não existe aba ESTILO")
		await _ver("f5_arvore_sem_artes")

	# --- Dica de aposentar, escada ---
	if _quer("f5_dica_aposentar"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope"], 800.0)
		gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
		gs.fama = 200
		await _abrir()
		gs._perigo_gym = 400.0
		await _esperar(1.3)
		_estado = "f5_dica_aposentar"
		_exigir(bool(gs.dica_aposentar().show), _estado, "a dica deveria estar no ar (perigo_gym 400 s)")
		await _ver("f5_dica_aposentar")
	if _quer("f5_escada_fim"):
		_novo_jogo()
		_academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", gs.lutas.adversarios.size())
		await _abrir()
		_exigir(gs.estado_escada() == "end", "f5_escada_fim", "escada completa = end")
		await _ver("f5_escada_fim")

	# --- Prévia e luta com os adversários da academia ---
	if _quer("f5_previa_tonhao") or _quer("f5_luta_tonhao"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope"], 800.0)
		gs.atributos = forte.duplicate()
		await _abrir()
		var fluxo: Node = _cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await _esperar(0.5)
		_exigir(str(gs.previa().get("art_fight_text", "")) != "", "f5_previa_tonhao", "a prévia deveria trazer o traço da arte")
		await _ver("f5_previa_tonhao")
		if _quer("f5_luta_tonhao"):
			fluxo.janela.lutar_pedido.emit()
			await _esperar(0.3)
			await _ver("f5_luta_tonhao")
	if _quer("f5_previa_kid"):
		_novo_jogo()
		_academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", 5)
		gs.atributos = forte.duplicate()
		await _abrir()
		_cena.get_node("Fluxo").abrir_previa()
		await _esperar(0.5)
		await _ver("f5_previa_kid")
	if _quer("f5_previa_kid_revanche"):
		_novo_jogo()
		_com_nos(["body_jab", "career_purse"], 40)
		_academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", 5)
		gs.permanente["revenge_opponent"] = "opp_gym_2"
		gs.atributos = {"strength": 3.0e5, "agility": 5.0e5, "endurance": 9.0e5}
		await _abrir()
		_cena.get_node("Fluxo").abrir_previa()
		await _esperar(0.5)
		await _ver("f5_previa_kid_revanche")

	# --- Vitória do cinturão com MUDAR ---
	if _quer("f5_vitoria_cinturao_mudar"):
		_novo_jogo()
		gs.indice_escada = 3
		gs.fama = 150
		gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		gs.rng.seed = 7
		gs.lutar()
		await _abrir()
		await _esperar(0.7)
		await _ver("f5_vitoria_cinturao_mudar")

	# --- Tela de fim: dica extra e ARTE no resumo ---
	if _quer("f5_fim_dica_extra"):
		_derrota_pendente([], 12)
		gs.arte_id = "boxing"
		gs.fim.summary["art"] = "boxing"
		gs.fim["opponent"] = "opp_gym_1"
		await _abrir()
		await _esperar(0.9)
		_exigir(str(gs.textos_fim(gs.fim).get("tip_extra", "")) != "", "f5_fim_dica_extra", "textos_fim() sem tip_extra na derrota da academia")
		await _ver("f5_fim_dica_extra")
	if _quer("f5_fim_aposentou_cinturao"):
		_novo_jogo()
		gs.indice_escada = 4
		gs.cinturao = true
		gs.fama = 340
		gs.aposentar()
		await _abrir()
		await _esperar(0.9)
		_exigir(str(gs.textos_fim(gs.fim).get("tip_extra", "")) != "", "f5_fim_aposentou_cinturao", "tip_move_belt esperada")
		await _ver("f5_fim_aposentou_cinturao")

	# --- NOVA CARREIRA volta para a garagem; a janela de arte vem antes do cartão ---
	if _quer("f5_nova_carreira") or _quer("f5_nova_carreira_cartao"):
		_derrota_pendente(NOS_MISTA, 40)
		gs.local_id = "gym"
		gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		gs.permanente["last_art"] = "bjj"
		await _abrir()
		await _esperar(0.9)
		var fl: Node = _cena.get_node("Fluxo")
		gs.nova_carreira()
		await _esperar(0.7)
		_estado = "f5_nova_carreira"
		_exigir(gs.local_id == "garage" and gs.arte_id == "", _estado, "NOVA CARREIRA volta para a garagem sem arte")
		_exigir(fl.janela != null and fl.janela.has_method("_escolher") and fl.cartao == null, _estado, "a janela de arte vem antes do cartão")
		await _ver("f5_nova_carreira")
		fl.janela._escolher("bjj")
		await _esperar(0.9)
		_exigir(fl.janela == null and fl.cartao != null, _estado, "depois da escolha o cartão aparece")
		await _ver("f5_nova_carreira_cartao")
