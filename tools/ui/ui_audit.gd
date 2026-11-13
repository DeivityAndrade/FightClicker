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
const SAIDA_PADRAO := "user://ui_audit_saida"  # pasta do usuário do Godot (funciona em qualquer PC)
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
	"f5_chip_jj_max", "f5_teclas_arte", "f5_loja_reserva", 
	"f5_dica_aposentar", "f5_escada_fim", "f5_previa_tonhao", "f5_luta_tonhao", "f5_previa_kid",
	"f5_previa_kid_revanche", "f5_vitoria_cinturao_mudar", "f5_fim_dica_extra", "f5_fim_aposentou_cinturao",
	"f5_nova_carreira", "f5_nova_carreira_cartao",
	# Fase 5.1
	"f51_garagem", "f51_gym", "f51_hover_fama", "f51_hover_legado", "f51_hover_local", "f51_hover_proxima", "f51_hover_teclas",
	"f51_hover_atributo", "f51_hover_assist", "f51_marcas", "f51_marca_hover", "f51_marca_trancada", "f51_loja_trancado", "f51_hover_foco",
	"f51_caixa_0", "f51_caixa_hover", "f51_caixa_1", "f51_caixa_2", "f51_caixa_abrindo", "f51_caixa_aberta", "f51_caixas_varias",
	"f51_caixa_sem_espaco", "f51_caixa_janela", "f51_caixa_luva", "f51_corda_gancho", "f51_caixa_persiste", "f51_anim_saco", "f51_anim_esteira", "f51_previa",
	# Fase 5.2
	"f52_loja_l3_compravel", "f52_loja_l4_sem_dinheiro", "f52_loja_l4_na_caixa", "f52_loja_grito_compravel", "f52_loja_grito_sem_dinheiro",
	"f52_loja_grito_comprado", "f52_loja_grito_hover", "f52_evento_luva", "f52_evento_bolsa", "f52_bolsa_hover", "f52_bolsa_toast",
	"f52_caixa_l3", "f52_caixa_l4", "f52_l4_sala", "f52_l4_luta", "f52_destaque_unico", "f52_contador", "f52_critico_menor",
	# Fase 5.3
	"f53_hud_facil", "f53_hud_equilibrado", "f53_hud_perigoso", "f53_hud_12_dias", "f53_hud_1_dia", "f53_hud_nome_longo", "f53_hud_dia_virou",
	"f53_hud_completa", "f53_dica_posto", "f53_dica_posto_curta", "f53_aviso_3_dias", "f53_aviso_1_dia_a", "f53_aviso_1_dia_b",
	"f53_aviso_nome_longo", "f53_dia_previa", "f53_hud_hoje", "f53_dia_loja_fechada", "f53_dia_passar_confirma", "f53_dia_voltar",
	"f53_dia_previa_tonhao", "f53_dia_previa_revanche_arte", "f53_fim_campanha_encerrada", "f53_fim_selo_completa", "f53_retrato_l1", "f53_retrato_l2", "f53_retrato_l3",
	"f53_retrato_l4", "f53_retrato_luta_l4", "f53_loja_grito_sem_rolar",
	# Fase 5.4: o mapa da árvore grande, o botão da sala e a tela de fim
	"f54_mapa_inicio", "f54_mapa_meio", "f54_mapa_completo", "f54_mapa_completo_noroeste", "f54_mapa_completo_sudeste",
	"f54_cartao_compravel", "f54_cartao_sem_legado", "f54_cartao_arte", "f54_cartao_grito_sem_loja", "f54_cartao_comprado",
	"f54_cartao_ativo", "f54_revelacao", "f54_revelacao_fim", "f54_botao_normal", "f54_botao_brilho", "f54_botao_hover",
	"f54_botao_gym", "f54_fim_botao", "f54_mapa_do_fim", "f54_fim_volta", "f54_save_antigo",
]

const NOS_MISTA := ["body_jab", "career_purse", "career_scouting"]
const NOS_TODOS := ["body_jab", "body_muscle_memory", "body_heavy_hands", "body_crew", "body_crew_2", "career_purse",
	"career_scouting", "career_purse_2", "career_crowd", "career_good_loser"]

var gs: Node
var saida := ProjectSettings.globalize_path(SAIDA_PADRAO)
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
	await _rodar_fase51()
	await _rodar_fase52()
	await _rodar_fase53()
	await _rodar_fase54()
	_fechar_cena()


# ---------------------------------------------------------------------------------------------
# Fase 4: árvore, cartão de início, Metrônomo, revanche, número de dano na arena
# ---------------------------------------------------------------------------------------------

## Põe nós comprados e Legado no save de teste (recalcula os bônus, como o carregamento faz).
func _com_nos(ids: Array, legado: int) -> void:
	gs.permanente["skill_nodes"] = ids.duplicate()
	gs.nos_ativos_ids = ids.duplicate()  # Fase 5.4: os efeitos vêm da foto da campanha (active_nodes)
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

		# --- Chegada (Fase 5.1: caixa da escola; 3 cliques abrem) ---
		if _quer("b4_chegada_esteira_queda") or _quer("b4_chegada_esteira_poeira"):
			_novo_jogo()
			_com_aparelhos([], 600.0)
			await _abrir()
			var sala: Node = _cena.get_node("Sala")
			_exigir(gs.comprar_aparelho("treadmill"), "b4_chegada_esteira", "comprar_aparelho(treadmill) recusou com 600 de Treino")
			await _esperar(0.5)
			_exigir(gs.estado_aparelho("treadmill") == "boxed" and _marca_visivel("treadmill"), "b4_chegada_esteira", "a caixa chega sobre a marca")
			if _quer("b4_chegada_esteira_queda"):
				await _ver("b4_chegada_esteira_queda")
			for i in 3:
				gs.bater_caixa("treadmill")
			await _esperar(0.15)
			if _quer("b4_chegada_esteira_poeira"):
				await _ver("b4_chegada_esteira_poeira")
			await _esperar(1.3)
			_exigir(gs.foco == "treadmill" and sala._esteira.visible and not _marca_visivel("treadmill"), "b4_chegada_esteira",
				"depois da caixa a esteira fica no foco e visível")
			_exigir(sala._lutador.nome_sprite.begins_with("fighter_run"), "b4_chegada_esteira", "o lutador deveria estar na esteira")
		if _quer("b4_chegada_corda"):
			_novo_jogo()
			_com_aparelhos(["treadmill"], 2000.0, "treadmill")
			await _abrir()
			var sala: Node = _cena.get_node("Sala")
			_exigir(gs.comprar_aparelho("jump_rope"), "b4_chegada_corda", "comprar_aparelho(jump_rope) recusou")
			await _esperar(0.5)
			await _ver("b4_chegada_corda")
			for i in 3:
				gs.bater_caixa("jump_rope")
			await _esperar(1.4)
			_exigir(gs.foco == "jump_rope" and not _marca_visivel("jump_rope"), "b4_chegada_corda",
				"depois da caixa a corda fica no foco e sem marca")

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
			# Fase 5.1: sem texto fixo. Parado, só o botão (ícone); depois de 5 s sem clicar aparece a dica curta (3 primeiras vezes).
			_exigir(gs.assistido_estado() == "off" and not faixa._chip.visible, _estado, "sem a dica de primeira vez o chip não aparece")
			faixa._ocioso = 5.5
			await _esperar(0.3)
			_exigir(faixa._chip.visible and faixa._chip_texto.text == _txt("hint_assist_first"), _estado, "dica curta esperada: %s" % faixa._chip_texto.text)
			await _ver("b4_assist_dica")
			faixa._dica_t = 0.01
			await _esperar(0.2)
			_exigir(not faixa._chip.visible, _estado, "a dica some sozinha")
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
			await _esperar(1.4)  # clique em t=0: mão parada em 0,6 s, primeiro soco 0,6 s depois (1,2 s); o número dura 0,5 s
			_exigir(gs.assistido_estado() == "active", _estado, "deveria estar active: %s (segurando gs=%s faixa=%s modal=%s bloq=%s)" % [gs.assistido_estado(), gs.assistido_segurando(), faixa.segurando(), gs.modal_aberto, gs.acoes_bloqueadas()])
			_exigir(gs.assist_socos_total > socos0, _estado, "nenhum auto-soco do assistido em 1,4 s")
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
	_auditar_mapa()
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
	# Fase 5.1: a chegada com poeira acabou; comprar gera uma caixa e 3 cliques abrem (detalhes nos estados f51_caixa_*).
	if _quer("f5_chegada_pera"):
		_novo_jogo()
		_garagem_arte("boxing", ["treadmill"], 3000.0, "treadmill")
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("speed_bag") and gs.estado_aparelho("speed_bag") == "boxed", "f5_chegada_pera", "comprar a pera cria a caixa")
		await _esperar(0.5)
		await _ver("f5_chegada_pera")
		for i in 3:
			gs.bater_caixa("speed_bag")
		await _esperar(1.4)
		_exigir(gs.foco == "speed_bag" and sala._pera.visible, "f5_chegada_pera", "depois da caixa a pera fica no foco")
	if _quer("f5_chegada_boneco"):
		_novo_jogo()
		_garagem_arte("bjj", ["treadmill"], 3000.0, "treadmill")
		await _abrir()
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("grappling_dummy") and gs.estado_aparelho("grappling_dummy") == "boxed", "f5_chegada_boneco", "comprar o boneco cria a caixa")
		await _esperar(0.5)
		await _ver("f5_chegada_boneco")
		for i in 3:
			gs.bater_caixa("grappling_dummy")
		await _esperar(1.4)
		_exigir(gs.foco == "grappling_dummy", "f5_chegada_boneco", "depois da caixa o boneco fica no foco")
	if _quer("f5_chip_jj_max"):
		_novo_jogo()
		_academia("bjj", ["treadmill", "jump_rope"], 800.0)
		gs.arte_segundos = 900.0
		await _abrir()
		await _esperar(1.2)
		_exigir(not _cena.get_node("BarraBaixo")._chip.visible, "f5_chip_jj_max", "Fase 5.1: o chip da arte saiu da tela (vai na dica do local)")
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
	# --- Dica de aposentar, escada ---
	if _quer("f5_dica_aposentar"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope"], 800.0)
		gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
		gs.fama = 200
		await _abrir()
		gs.segundos_campanha = float(gs.fight_day - 3) * gs._segundos_por_dia()  # Fase 5.3: faltam 2 dias
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


# ---------------------------------------------------------------------------------------------
# Fase 5.1: garagem clara (3 niveis de leitura), marcas sem texto, caixa da escola, corda no gancho, previa com respiro
# ---------------------------------------------------------------------------------------------

## Hover simulado: a dica aparece fixa num ponto (o mouse real do verificador nao esta sobre nada).
func _dica_em(texto: String, onde: Vector2) -> void:
	var inst = _dica_inst()
	inst.ancora_fixa = onde
	inst.mostrar(texto)


func _dica_inst() -> Control:
	for c in _cena.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("dica.gd"):
			return c
	return null


func _sem_dica() -> void:
	var inst = _dica_inst()
	inst.ancora_fixa = Vector2(-1, -1)
	inst.esconder()


func _rodar_fase51() -> void:
	var nomes: Array = ESTADOS_TODOS.filter(func(n: String) -> bool: return n.begins_with("f51_"))
	var alguma := false
	for n in nomes:
		if _quer(n):
			alguma = true
	if not alguma:
		return

	# --- Os 3 niveis: garagem e hovers dos itens escondidos ---
	if _quer("f51_garagem") or _quer("f51_hover_fama") or _quer("f51_hover_legado") or _quer("f51_hover_local") \
			or _quer("f51_hover_proxima") or _quer("f51_hover_teclas") or _quer("f51_hover_atributo") or _quer("f51_hover_assist"):
		_novo_jogo()
		gs.fama = 12
		gs.dinheiro = 80.0
		await _abrir()
		_estado = "f51_garagem"
		_exigir(not _dica_inst().visible, _estado, "sem hover nao existe dica na tela")
		await _ver("f51_garagem")
		var hud: Node = _cena.get_node("Hud")
		if _quer("f51_hover_fama"):
			_dica_em(gs.texto_ui("hint_fame") + "\n12", Vector2(520, 24))
			await _esperar(0.1)
			await _ver("f51_hover_fama")
			_sem_dica()
		if _quer("f51_hover_legado"):
			_dica_em(gs.texto_ui("hint_legacy") + "\n" + str(gs.legado_em_jogo()), Vector2(480, 24))
			await _esperar(0.1)
			await _ver("f51_hover_legado")
			_sem_dica()
		if _quer("f51_hover_local"):
			_dica_em(hud.texto_dica_local(), Vector2(380, 24))
			await _esperar(0.1)
			await _ver("f51_hover_local")
			_sem_dica()
		if _quer("f51_hover_proxima"):
			var bloco: Node = _cena.get_node("PainelAtributos").find_children("*", "BlocoProxima", true, false)[0]
			_dica_em(bloco._texto_premio(), Vector2(20, 130))
			await _esperar(0.1)
			await _ver("f51_hover_proxima")
			_sem_dica()
		if _quer("f51_hover_teclas"):
			_dica_em(gs.texto_ui("hint_keys"), Vector2(250, 290))
			await _esperar(0.1)
			await _ver("f51_hover_teclas")
			_sem_dica()
		if _quer("f51_hover_atributo"):
			_cena.get_node("PainelAtributos").mostrar_info({"titulo": "Agilidade", "texto": "Esquiva e velocidade.", "extra": "Compre a corda para treinar"})
			await _esperar(0.1)
			await _ver("f51_hover_atributo")
			_cena.get_node("PainelAtributos").mostrar_info({})
		if _quer("f51_hover_assist"):
			_dica_em(gs.texto_ui("hint_assist"), Vector2(300, 250))
			await _esperar(0.1)
			await _ver("f51_hover_assist")
			_sem_dica()
	if _quer("f51_gym"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 3000.0, "speed_bag")
		gs.fama = 40
		gs.dinheiro = 400.0
		await _abrir()
		await _esperar(0.3)
		await _ver("f51_gym")

	# --- Marcas de fita sem texto: normal, acesa (hover) e trancada ---
	if _quer("f51_marcas") or _quer("f51_marca_hover") or _quer("f51_marca_trancada") or _quer("f51_loja_trancado") or _quer("f51_hover_foco"):
		_novo_jogo()
		gs.treino = 700.0
		await _abrir()
		_estado = "f51_marcas"
		var sala: Node = _cena.get_node("Sala")
		_exigir(sala._marcas["treadmill"].fita.nome_sprite == "tape_mark_treadmill", _estado, "esteira comprável: marca normal")
		_exigir(sala._marcas["jump_rope"].fita.nome_sprite == "tape_mark_rope_dim" and sala._marcas["jump_rope"].cadeado.visible, _estado,
			"corda trancada: marca _dim com cadeado")
		await _ver("f51_marcas")
		if _quer("f51_marca_hover"):
			sala._hover_em(Vector2(445, 267))
			_dica_em(sala._texto_marca("treadmill"), Vector2(430, 200))
			_exigir(sala._marcas["treadmill"].fita.nome_sprite == "tape_mark_treadmill_hi", "f51_marca_hover", "o mouse acende a marca _hi")
			await _esperar(0.1)
			await _ver("f51_marca_hover")
			sala._sair_hover()
			_sem_dica()
		if _quer("f51_marca_trancada"):
			sala._hover_em(Vector2(296, 166))
			_dica_em(sala._texto_marca("jump_rope"), Vector2(250, 120))
			await _esperar(0.1)
			await _ver("f51_marca_trancada")
			sala._sair_hover()
			_sem_dica()
		if _quer("f51_loja_trancado"):
			var loja: Node = _cena.get_node("PainelLoja")
			_dica_em(loja._texto_recolhido("jump_rope"), Vector2(400, 150))
			await _esperar(0.1)
			await _ver("f51_loja_trancado")
			_sem_dica()
		if _quer("f51_hover_foco"):
			_dica_em(_cena.get_node("BarraBaixo")._texto_foco("jump_rope"), Vector2(300, 250))
			await _esperar(0.1)
			await _ver("f51_hover_foco")
			_sem_dica()

	# --- A caixa: 0, 1 e 2 cliques, abrindo ---
	if _quer("f51_caixa_0") or _quer("f51_caixa_1") or _quer("f51_caixa_2") or _quer("f51_caixa_abrindo") or _quer("f51_caixa_hover") \
			or _quer("f51_caixa_aberta"):
		_novo_jogo()
		gs.treino = 3000.0
		for g in gs.dados.geradores:
			gs.geradores[g.id] = 0  # sem renda passiva: o saldo de Treino só mexe se o clique da caixa treinar
		await _abrir()
		_estado = "f51_caixa_0"
		var sala: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("treadmill"), _estado, "comprar a esteira deveria criar a caixa")
		await _esperar(0.6)
		_exigir(gs.tem_caixa("treadmill") and sala._caixas.has("treadmill") and not gs.aparelho_montado("treadmill"), _estado,
			"a caixa da esteira deveria estar na sala e o aparelho nao montado")
		await _ver("f51_caixa_0")
		var tr0: float = gs.treino
		if _quer("f51_caixa_hover"):
			sala._hover_em(Vector2(445, 250))
			await _esperar(0.1)
			_exigir(_dica_inst().visible, "f51_caixa_hover", "a caixa da a dica no hover")
			await _ver("f51_caixa_hover")
			sala._sair_hover()
		sala._clique_em(Vector2(445, 250))  # clique de mouse na caixa
		await _esperar(0.3)
		_exigir(gs.cliques_faltando("treadmill") == 2 and gs.treino == tr0, "f51_caixa_1", "1 clique: faltam 2 e o clique nao treina")
		await _ver("f51_caixa_1")
		sala._clique_em(Vector2(445, 250))
		await _esperar(0.3)
		_exigir(gs.cliques_faltando("treadmill") == 1, "f51_caixa_2", "2 cliques: falta 1")
		await _ver("f51_caixa_2")
		sala._clique_em(Vector2(445, 250))
		await _esperar(0.12)
		_exigir(gs.aparelho_montado("treadmill") and gs.foco == "treadmill" and not gs.tem_caixa("treadmill"), "f51_caixa_abrindo",
			"3 cliques abrem: aparelho montado e foco nele")
		await _ver("f51_caixa_abrindo")
		await _esperar(1.3)
		_exigir(not sala._caixas.has("treadmill") or not is_instance_valid(sala._caixas["treadmill"]) or sala._caixas["treadmill"].is_queued_for_deletion(),
			"f51_caixa_aberta", "a caixa vazia some em ate 1,5 s")
		await _ver("f51_caixa_aberta")
	if _quer("f51_caixas_varias") or _quer("f51_caixa_luva") or _quer("f51_corda_gancho") or _quer("f51_caixa_sem_espaco") or _quer("f51_caixa_janela"):
		_novo_jogo()
		gs.treino = 6000.0
		gs.dinheiro = 400.0
		gs.aparelhos_montados_ids = ["punching_bag", "treadmill"]
		await _abrir()
		var sala2: Node = _cena.get_node("Sala")
		_exigir(gs.comprar_aparelho("jump_rope"), "f51_caixas_varias", "comprar a corda")
		_exigir(gs.comprar_luva(), "f51_caixas_varias", "comprar a luva")
		await _esperar(0.7)
		_estado = "f51_caixas_varias"
		_exigir(gs.caixas().size() == 2 and sala2._caixas.size() == 2, _estado, "duas caixas lado a lado")
		var r1: Rect2 = sala2._caixas["jump_rope"].area()
		var r2: Rect2 = sala2._caixas["glove_l1"].area()
		_exigir(not r1.intersects(r2), _estado, "caixas nao se sobrepoem")
		var alvo := Rect2(312, 182, 48, 90)
		_exigir(not r1.grow(8.0).intersects(alvo) and not r2.grow(8.0).intersects(alvo), _estado, "caixas a 8 px ou mais do alvo")
		await _ver("f51_caixas_varias")
		if _quer("f51_caixa_sem_espaco"):
			_tecla(KEY_SPACE, true)
			_tecla(KEY_SPACE, false)
			await _esperar(0.2)
			_exigir(gs.cliques_faltando("jump_rope") == 3 and gs.cliques_faltando("glove_l1") == 3, "f51_caixa_sem_espaco", "Espaco nunca bate em caixa")
		if _quer("f51_caixa_janela"):
			sala2.janela_aberta = true
			sala2._clique_em(sala2._caixas["jump_rope"].area().get_center())
			_exigir(gs.cliques_faltando("jump_rope") == 3, "f51_caixa_janela", "com janela aberta o clique nao vai para a caixa")
			sala2.janela_aberta = false
		if _quer("f51_caixa_luva") or _quer("f51_corda_gancho"):
			var pl: Vector2 = sala2._caixas["glove_l1"].area().get_center()
			var pc: Vector2 = sala2._caixas["jump_rope"].area().get_center()
			for i in 2:
				sala2._clique_em(pl)
				await _esperar(0.2)
			await _ver("f51_caixa_luva")
			sala2._clique_em(pl)
			await _esperar(0.25)
			_exigir(gs.luvas_abertas() == 1 and not gs.tem_caixa("glove_l1"), "f51_caixa_luva", "3 cliques abrem a luva")
			await _ver("f51_caixa_luva_aberta")
			for i in 3:
				sala2._clique_em(pc)
				await _esperar(0.2)
			await _esperar(1.4)
			_exigir(gs.aparelho_montado("jump_rope") and gs.foco == "jump_rope", "f51_corda_gancho", "corda montada e em foco")
			gs.definir_foco("punching_bag")
			await _esperar(0.3)
			_exigir(sala2._corda_prego.visible and sala2._corda_prego.position == Vector2(296, 166), "f51_corda_gancho",
				"corda pendurada no gancho (296,166): %s" % str(sala2._corda_prego.position))
			await _ver("f51_corda_gancho")
	if _quer("f51_caixa_persiste"):
		_novo_jogo()
		gs.treino = 3000.0
		await _abrir()
		gs.comprar_aparelho("treadmill")
		gs.bater_caixa("treadmill")
		gs.bater_caixa("treadmill")
		await _esperar(0.3)
		var snap: Dictionary = gs.para_save()
		await _abrir()  # recarrega a cena
		gs.aplicar_save(snap.duplicate(true))
		await _esperar(0.5)
		_estado = "f51_caixa_persiste"
		var sala3: Node = _cena.get_node("Sala")
		_exigir(sala3._caixas.has("treadmill") and sala3._caixas["treadmill"].batidas == 2, _estado, "a caixa com 2 cliques volta igual")
		await _ver("f51_caixa_persiste")

	# --- As 3 animacoes novas na sala: soco no saco, corrida na esteira, equipe ---
	if _quer("f51_anim_saco") or _quer("f51_anim_esteira"):
		_novo_jogo()
		_com_aparelhos(["treadmill"], 3000.0, "punching_bag")
		await _abrir()
		var sala4: Node = _cena.get_node("Sala")
		if _quer("f51_anim_saco"):
			for i in 5:
				gs.clicar()
				await _esperar(0.09)
				_exigir(sala4._lutador.nome_sprite.begins_with("fighter_"), "f51_anim_saco", "o lutador toca um golpe do combo: " + sala4._lutador.nome_sprite)
				if i == 4:
					await _ver("f51_anim_saco")
		if _quer("f51_anim_esteira"):
			gs.definir_foco("treadmill")
			await _esperar(0.3)
			gs.clicar()
			await _esperar(0.15)
			_exigir(sala4._lutador.nome_sprite.begins_with("fighter_run") and sala4._esteira.esta_tocando(), "f51_anim_esteira", "lutador e esteira correm juntos")
			await _ver("f51_anim_esteira")

	# --- Previa com respiro ---
	if _quer("f51_previa"):
		_novo_jogo()
		await _abrir()
		_cena.get_node("Fluxo").abrir_previa()
		await _esperar(0.6)
		await _ver("f51_previa")


# ---------------------------------------------------------------------------------------------
# Fase 5.2: luvas L3/L4 e Grito da equipe na LOJA, evento dourado por tipo (luva x7 / bolsa), 3 desvios da 5.1
# ---------------------------------------------------------------------------------------------

func _abrir_loja(rolar_ate_o_fim: bool = false) -> Node:
	await _abrir()
	var painel: Node = _cena.get_node("PainelLoja")
	painel._tab["loja"].botao.pressed.emit()
	await _esperar(0.2)
	if rolar_ate_o_fim:
		painel._rolar_a(painel._rolagem_max)
	await _esperar(0.1)
	return painel


func _rodar_fase52() -> void:
	var alguma := false
	for n in ESTADOS_TODOS:
		if str(n).begins_with("f52_") and _quer(n):
			alguma = true
	if not alguma:
		return

	# --- LOJA: L3 comprável, L4 sem dinheiro, L4 com a L3 ainda na caixa ---
	if _quer("f52_loja_l3_compravel"):
		_novo_jogo()
		gs.nivel_luva = 2
		gs.dinheiro = 1500.0
		await _abrir_loja()
		_exigir(gs.pode_comprar_luva() and str(gs.proxima_luva().id) == "glove_l3", "f52_loja_l3_compravel", "a L3 esta a venda")
		await _ver("f52_loja_l3_compravel")
	if _quer("f52_loja_l4_sem_dinheiro"):
		_novo_jogo()
		gs.nivel_luva = 3
		gs.dinheiro = 300.0
		await _abrir_loja()
		_exigir(str(gs.proxima_luva().id) == "glove_l4" and not gs.pode_comprar_luva(), "f52_loja_l4_sem_dinheiro", "a L4 esta a venda sem dinheiro")
		await _ver("f52_loja_l4_sem_dinheiro")
	if _quer("f52_loja_l4_na_caixa") or _quer("f52_caixa_l3"):
		_novo_jogo()
		gs.nivel_luva = 2
		gs.dinheiro = 6000.0
		await _abrir()
		_exigir(gs.comprar_luva(), "f52_caixa_l3", "comprar a L3")
		await _esperar(0.8)
		_exigir(gs.tem_caixa("glove_l3") and _cena.get_node("Sala")._caixas.has("glove_l3"), "f52_caixa_l3", "a caixa da L3 esta na sala")
		await _ver("f52_caixa_l3")
		_cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await _esperar(0.2)
		_exigir(gs.luva_em_caixa() and not gs.pode_comprar_luva(), "f52_loja_l4_na_caixa", "L4 so depois de abrir a caixa da L3")
		await _ver("f52_loja_l4_na_caixa")
	if _quer("f52_caixa_l4"):
		_novo_jogo()
		gs.nivel_luva = 3
		gs.dinheiro = 6000.0
		await _abrir()
		_exigir(gs.comprar_luva(), "f52_caixa_l4", "comprar a L4")
		await _esperar(0.8)
		_exigir(gs.tem_caixa("glove_l4") and _cena.get_node("Sala")._caixas.has("glove_l4"), "f52_caixa_l4", "a caixa da L4 esta na sala")
		await _ver("f52_caixa_l4")

	# --- LOJA: Grito da equipe ---
	if _quer("f52_loja_grito_compravel") or _quer("f52_loja_grito_hover") or _quer("f52_loja_grito_comprado"):
		_novo_jogo()
		gs.nivel_luva = 4
		gs.dinheiro = 2000.0
		var painel: Node = await _abrir_loja(true)
		_exigir(gs.pode_comprar_crew_click(), "f52_loja_grito_compravel", "o Grito esta comprável")
		await _ver("f52_loja_grito_compravel")
		if _quer("f52_loja_grito_hover"):
			painel._sobre("c")
			await _esperar(0.1)
			await _ver("f52_loja_grito_hover")
			painel._sobre("")
		painel._comprar_crew()
		await _esperar(0.5)
		_exigir(gs.crew_click_comprado and painel._crew.botao.disabled, "f52_loja_grito_comprado", "comprado: botao apagado")
		await _ver("f52_loja_grito_comprado")
	if _quer("f52_loja_grito_sem_dinheiro"):
		_novo_jogo()
		gs.nivel_luva = 4
		gs.dinheiro = 90.0
		await _abrir_loja(true)
		_exigir(not gs.pode_comprar_crew_click(), "f52_loja_grito_sem_dinheiro", "sem dinheiro")
		await _ver("f52_loja_grito_sem_dinheiro")

	# --- Evento dourado: luva x7 e bolsa da torcida ---
	if _quer("f52_evento_luva") or _quer("f52_evento_bolsa") or _quer("f52_bolsa_hover") or _quer("f52_bolsa_toast"):
		for tipo in ["frenzy", "crew"]:
			var nome_ev := "f52_evento_luva" if tipo == "frenzy" else "f52_evento_bolsa"
			if not (_quer(nome_ev) or (tipo == "crew" and (_quer("f52_bolsa_hover") or _quer("f52_bolsa_toast")))):
				continue
			_novo_jogo()
			await _abrir()
			var sala: Node = _cena.get_node("Sala")
			gs.frenesi_restante = 0.0
			gs.evento_dourado_tipo = tipo
			gs.evento_dourado_restante = 10.0
			gs.evento_dourado.emit(10.0)
			await _esperar(0.3)
			var esperado: String = gs.dados.golden_crew_sprite if tipo == "crew" else gs.dados.golden_frenzy_sprite
			_exigir(sala._evento_spr.nome_sprite == esperado, nome_ev, "sprite do evento: " + sala._evento_spr.nome_sprite)
			await _ver(nome_ev)
			var centro: Vector2 = sala._evento_rect.get_center()
			if tipo == "crew":
				if _quer("f52_bolsa_hover"):
					sala._hover_em(centro)
					await _esperar(0.1)
					_exigir(_dica_inst().visible, "f52_bolsa_hover", "a bolsa da dica no hover")
					await _ver("f52_bolsa_hover")
					sala._sair_hover()
				var treino0: float = gs.treino
				sala._clique_em(centro)
				await _esperar(0.35)
				_exigir(gs.frenesi_restante <= 0.0 and gs.treino > treino0, "f52_bolsa_toast", "a bolsa paga e nao liga o FRENESI (fren %s treino %s->%s restante %s tipo %s)" % [gs.frenesi_restante, treino0, gs.treino, gs.evento_dourado_restante, gs.evento_dourado_tipo])
				await _ver("f52_bolsa_toast")
			else:
				sala._clique_em(centro)
				await _esperar(0.2)
				_exigir(gs.frenesi_restante > 0.0, nome_ev, "a luva x7 liga o FRENESI")

	# --- Luva L4 na sala e na luta ---
	if _quer("f52_l4_sala"):
		_novo_jogo()
		gs.nivel_luva = 4
		await _abrir()
		var sala5: Node = _cena.get_node("Sala")
		for i in 3:
			gs.clicar()
			await _esperar(0.08)
		_exigir(str(sala5._lutador.nome_sprite).ends_with("_glove_l4") or gs.sufixo_luva() == "_glove_l4", "f52_l4_sala", "lutador com a L4: " + str(sala5._lutador.nome_sprite))
		await _ver("f52_l4_sala")
	if _quer("f52_l4_luta"):
		var achada := _achar_luta(true, true)
		_novo_jogo()
		gs.nivel_luva = 4
		gs.atributos = achada.atr
		await _abrir()
		gs.rng.seed = int(achada.k)
		var fluxo: Node = _cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await _esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await _esperar(0.25)
		fluxo.tela._clock = 5.0
		await _esperar(0.3)
		await _ver("f52_l4_luta")

	# --- Os 3 desvios da 5.1 ---
	if _quer("f52_destaque_unico"):
		_novo_jogo()
		gs.treino = 5000.0
		await _abrir()
		var loja: Node = _cena.get_node("PainelLoja")
		var vistos := 0
		for r in loja.find_children("*", "ReferenceRect", true, false):
			if (r as Control).is_visible_in_tree():
				vistos += 1
		_exigir(vistos <= 1, "f52_destaque_unico", "no maximo 1 contorno de destaque visivel (achei %d)" % vistos)
		await _ver("f52_destaque_unico")
	if _quer("f52_contador"):
		_novo_jogo()
		await _abrir()
		await _ver("f52_contador")
	if _quer("f52_critico_menor"):
		_novo_jogo()
		await _abrir()
		var sala6: Node = _cena.get_node("Sala")
		sala6._pos_clique = Vector2(336, 232)
		gs.clicou.emit(1500.0, true, "punching_bag", "endurance", "A ESTEIRA GEMEU!")
		await _esperar(0.2)
		await _ver("f52_critico_menor")



# ---------------------------------------------------------------------------------------------
# Fase 5.3: calendário da campanha (folhinha no HUD, faixas de aviso, prévia do dia, PASSAR O POSTO, retrato por luva)
# ---------------------------------------------------------------------------------------------

## Garagem com a data da próxima luta daqui a `dias` dias e o risco do HUD forçado (o recálculo periódico fica desligado).
## `idx` escolhe o adversário (0 Dudu, 1 Brutão...). Chamar ANTES de `_abrir()`.
func _calendario53(dias: int, risco: String, idx: int = 0) -> void:
	_novo_jogo()
	gs.indice_escada = idx
	gs.risco_hud_ativo = false
	var spd: float = gs._segundos_por_dia()
	gs.fight_day = 30
	gs.segundos_campanha = float(30 - dias - 1) * spd + 1.0
	gs._definir_risco_hud(str(gs.proximo_adversario().id), risco)


func _rodar_fase53() -> void:
	var alguma := false
	for n in ESTADOS_TODOS:
		if str(n).begins_with("f53_") and _quer(n):
			alguma = true
	if not alguma:
		return
	var fl: Node

	# --- HUD: a folhinha em cada cor de risco, 12 dias (a linha mais larga), 1 dia, nome longo ---
	for par in [["f53_hud_facil", 11, "easy"], ["f53_hud_equilibrado", 5, "even"], ["f53_hud_perigoso", 4, "hard"],
			["f53_hud_12_dias", 12, "easy"], ["f53_hud_1_dia", 1, "hard"]]:
		if _quer(par[0]):
			_calendario53(par[1], par[2])
			await _abrir()
			_exigir(gs.dias_para_luta() == par[1], par[0], "dias para a luta %d" % gs.dias_para_luta())
			await _ver(par[0])
	if _quer("f53_hud_nome_longo"):
		_calendario53(8, "even", 1)  # Brutão do Posto: o nome passa da linha 2 e é abreviado
		await _abrir()
		await _ver("f53_hud_nome_longo")
	if _quer("f53_hud_dia_virou"):
		_calendario53(6, "easy")
		await _abrir()
		gs.dia_mudou.emit(gs.dia_campanha())
		await _esperar(0.12)  # a folha arrancada no meio da animação
		await _ver("f53_hud_dia_virou")
	if _quer("f53_hud_completa"):
		_novo_jogo()
		_academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", gs.lutas.adversarios.size())
		await _abrir()
		_exigir(gs.campanha_completa(), "f53_hud_completa", "campanha completa")
		await _ver("f53_hud_completa")

	# --- Dica de passar o posto (<= 3 dias, vermelho, pote > 0): versão longa e versão curta ---
	if _quer("f53_dica_posto"):
		_calendario53(2, "hard")
		gs.fama = 200
		await _abrir()
		_exigir(bool(gs.dica_aposentar().show), "f53_dica_posto", "a dica deveria estar no ar")
		await _ver("f53_dica_posto")
	if _quer("f53_dica_posto_curta"):
		_calendario53(2, "hard")
		gs.fama = 200000
		await _abrir()
		_exigir(bool(gs.dica_aposentar().show), "f53_dica_posto_curta", "a dica deveria estar no ar")
		await _ver("f53_dica_posto_curta")

	# --- Faixas de aviso: 3 dias (calma) e 1 dia (urgente, 2 quadros) ---
	if _quer("f53_aviso_3_dias"):
		_calendario53(3, "even")
		await _abrir()
		gs.aviso_data.emit(3)
		await _esperar(0.45)
		var faixa3: Control = _cena.find_children("*", "FaixaAviso", true, false)[0]
		_exigir(faixa3.visible and not faixa3.urgente, "f53_aviso_3_dias", "faixa de 3 dias visível e calma")
		await _ver("f53_aviso_3_dias")
	if _quer("f53_aviso_1_dia_a") or _quer("f53_aviso_1_dia_b"):
		_calendario53(1, "hard")
		await _abrir()
		gs.aviso_data.emit(1)
		await _esperar(0.3)
		var faixa1: Control = _cena.find_children("*", "FaixaAviso", true, false)[0]
		_exigir(faixa1.visible and faixa1.urgente, "f53_aviso_1_dia_a", "faixa de 1 dia visível e urgente")
		await _ver("f53_aviso_1_dia_a")
		await _esperar(0.5)  # 2 fps: o outro quadro
		await _ver("f53_aviso_1_dia_b")
		faixa1.esconder()
	if _quer("f53_aviso_nome_longo"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope"], 800.0)
		gs.risco_hud_ativo = false
		gs.fight_day = 30
		gs.segundos_campanha = 28.0 * gs._segundos_por_dia() + 1.0
		await _abrir()
		gs.aviso_data.emit(1)  # Tonhão do Tatame: o nome mais longo
		await _esperar(0.3)
		await _ver("f53_aviso_nome_longo")

	# --- O dia da luta: a prévia abre sozinha, sem X nem Esc; PASSAR O POSTO pede confirmação e VOLTAR devolve a prévia ---
	if _quer("f53_dia_previa") or _quer("f53_hud_hoje") or _quer("f53_dia_loja_fechada") or _quer("f53_dia_passar_confirma") \
			or _quer("f53_dia_voltar"):
		_calendario53(0, "hard")
		gs.fama = 200
		await _abrir()
		fl = _cena.get_node("Fluxo")
		# A LOJA aberta antes do dia fecha (a aba volta para o TREINO).
		_cena.get_node("PainelLoja")._trocar_aba("loja")
		await _esperar(0.9)
		_exigir(gs.no_dia_da_luta() and not gs.sala_ativa(), "f53_dia_previa", "no dia a sala está parada")
		_exigir(_eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta, "f53_dia_previa", "a prévia do dia abriu sozinha")
		if _eh(fl.janela, "JanelaPrevia"):
			await _ver("f53_dia_previa")
			# Esc não fecha a prévia do dia.
			var esc := InputEventKey.new()
			esc.keycode = KEY_ESCAPE
			esc.pressed = true
			fl._unhandled_key_input(esc)
			await _esperar(0.2)
			_exigir(_eh(fl.janela, "JanelaPrevia"), "f53_dia_previa", "Esc não pode fechar a prévia do dia")
			# A folhinha do HUD (hoje) e a LOJA fechada, com a prévia escondida só para a captura.
			fl.janela.visible = false
			var loja: Node = _cena.get_node("PainelLoja")
			_exigir(loja._tab["loja"].botao.disabled and loja._aba == "treino", "f53_dia_loja_fechada", "LOJA fechada no dia")
			await _ver("f53_hud_hoje")
			fl.janela.visible = true
			if _quer("f53_dia_passar_confirma") or _quer("f53_dia_voltar"):
				fl.janela.passar_pedido.emit()
				await _esperar(0.4)
				_exigir(_eh(fl.janela, "JanelaAposentar"), "f53_dia_passar_confirma", "PASSAR O POSTO abre a confirmação")
				await _ver("f53_dia_passar_confirma")
				if _eh(fl.janela, "JanelaAposentar"):
					fl.janela.cancelou.emit()  # VOLTAR
					await _esperar(0.5)
					_exigir(_eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta, "f53_dia_voltar", "VOLTAR devolve a prévia do dia")
					await _ver("f53_dia_voltar")
	# B1 da QA 5.3: dia da luta + fita da revanche + linha da arte (janela mais alta): a folhinha "HOJE" não pode tocar o retrato.
	if _quer("f53_dia_previa_revanche_arte"):
		_calendario53(0, "hard")
		gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		gs.permanente["last_art"] = "boxing"
		gs.arte_id = "boxing"
		gs._atualizar_traco()
		gs.permanente["revenge_opponent"] = str(gs.proximo_adversario().id)
		gs.fama = 200
		await _abrir()
		fl = _cena.get_node("Fluxo")
		await _esperar(0.9)
		var ok_prev: bool = _eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta
		_exigir(ok_prev, "f53_dia_previa_revanche_arte", "a prévia do dia abriu")
		if ok_prev:
			_exigir(bool(gs.previa().get("revenge", false)) and str(gs.previa().get("art_fight_text", "")) != "",
				"f53_dia_previa_revanche_arte", "o estado deveria ter revanche e traço da arte")
			var folhinha: Control = null
			var quadros: Array = []
			for n in fl.janela.find_children("*", "TextureRect", true, false):
				var tr: TextureRect = n as TextureRect
				if tr.get_child_count() > 0 and tr.get_node_or_null("Cabecalho") != null:
					folhinha = tr
				elif tr.texture != null and tr.get_child_count() == 1 and tr.get_child(0) is TextureRect \
						and tr.size.x >= 30.0 and tr.size.x <= 40.0 and tr.size.y >= 30.0 and tr.size.y <= 40.0:
					quadros.append(tr)
			_exigir(folhinha != null and quadros.size() == 2, "f53_dia_previa_revanche_arte", "achou a folhinha e os 2 retratos")
			if folhinha != null:
				for q in quadros:
					_exigir(not folhinha.get_global_rect().intersects(q.get_global_rect()), "f53_dia_previa_revanche_arte",
						"a folhinha HOJE toca o retrato %s" % str(q.get_global_rect()))
		await _ver("f53_dia_previa_revanche_arte")
	if _quer("f53_dia_previa_tonhao"):
		_novo_jogo()
		_academia("boxing", ["treadmill", "jump_rope"], 800.0)
		gs.risco_hud_ativo = false
		gs.fight_day = 40
		gs.segundos_campanha = 39.0 * gs._segundos_por_dia()
		await _abrir()
		fl = _cena.get_node("Fluxo")
		await _esperar(0.9)
		_exigir(_eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta, "f53_dia_previa_tonhao", "a prévia do dia abriu")
		await _ver("f53_dia_previa_tonhao")

	# --- Fim de campanha: derrota (CAMPANHA ENCERRADA / NOVA CAMPANHA) e passar o posto depois do Kid (selo) ---
	if _quer("f53_fim_campanha_encerrada"):
		_derrota_pendente([], 12)
		await _abrir()
		await _esperar(0.9)
		await _ver("f53_fim_campanha_encerrada")
	if _quer("f53_fim_selo_completa"):
		_novo_jogo()
		gs.indice_escada = gs.lutas.adversarios.size()
		gs.cinturao = true
		gs.fama = 340
		gs.aposentar()
		await _abrir()
		await _esperar(0.9)
		await _ver("f53_fim_selo_completa")

	# --- Retrato do jogador com a luva equipada (L1 a L4) na prévia, e L4 no topo da luta ---
	for n in [1, 2, 3, 4]:
		var nome_r := "f53_retrato_l%d" % n
		if _quer(nome_r):
			_novo_jogo()
			gs.nivel_luva = n
			await _abrir()
			_exigir(("portrait_player" + gs.sufixo_luva()) == "portrait_player_glove_l%d" % n, nome_r, "retrato da luva L%d: %s" % [n, ("portrait_player" + gs.sufixo_luva())])
			_cena.get_node("Fluxo").abrir_previa()
			await _esperar(0.4)
			await _ver(nome_r)
	if _quer("f53_retrato_luta_l4"):
		var achada53 := _achar_luta(true, true)
		_novo_jogo()
		gs.nivel_luva = 4
		gs.atributos = achada53.atr
		await _abrir()
		gs.rng.seed = int(achada53.k)
		fl = _cena.get_node("Fluxo")
		fl.abrir_previa()
		await _esperar(0.3)
		fl.janela.lutar_pedido.emit()
		await _esperar(0.5)
		await _ver("f53_retrato_luta_l4")

	# --- Grito da equipe visível na LOJA sem rolar ---
	if _quer("f53_loja_grito_sem_rolar"):
		_novo_jogo()
		gs.nivel_luva = 4
		gs.dinheiro = 2000.0
		var painel53: Node = await _abrir_loja(false)
		var janela_loja: Control = painel53._janela_loja
		var cartao: Control = painel53._crew.cartao
		var dentro: bool = cartao.get_global_rect().end.y <= janela_loja.get_global_rect().end.y + 0.01 \
			and cartao.get_global_rect().position.y >= janela_loja.get_global_rect().position.y - 0.01
		_exigir(dentro and gs.pode_comprar_crew_click(), "f53_loja_grito_sem_rolar", "o cartão do Grito inteiro à vista, sem rolar")
		await _ver("f53_loja_grito_sem_rolar")
	gs.risco_hud_ativo = true


## Classe da janela pelo nome (o verificador não pode citar classes da UI: elas dependem do autoload GameState na compilação).
func _eh(no: Object, classe: String) -> bool:
	return no != null and no.get_script() != null and str(no.get_script().get_global_name()) == classe


# ---------------------------------------------------------------------------------------------
# Fase 5.4: mapa da árvore grande, botão da sala, cartão do nó, tela de fim e save antigo
# ---------------------------------------------------------------------------------------------

## O mapa em posição livre (nós, etiquetas, plaquinhas) é ui_align = ignore no verificador genérico: ele mesmo confere o que
## está dentro (preço cabe na etiqueta, nó não cobre nó, plaquinha não cobre nó, cartão dentro da janela do mapa).
func _auditar_mapa() -> void:
	var fl: Node = _cena.get_node_or_null("Fluxo") if _cena != null else null
	if fl != null and _eh(fl.janela, "JanelaMapa"):
		for erro in fl.janela.diagnostico():
			_problema("MAPA", fl.janela, str(erro))


func _mapa() -> Node:
	return _cena.get_node("Fluxo").janela


## Nós comprados + Legado + último nó, com a foto da campanha igual (ativos = todos) ou vazia (comprado nesta campanha).
func _com_nos54(ids: Array, legado: int, ativos: bool = true) -> void:
	gs.permanente["skill_nodes"] = ids.duplicate()
	gs.permanente["legacy_total"] = legado
	gs.permanente["tree_last_node"] = str(ids.back()) if not ids.is_empty() else ""
	gs.nos_ativos_ids = ids.duplicate() if ativos else []
	gs._recalcular_bonus()


func _todos_os_nos() -> Array:
	var r: Array = []
	for n in gs.lutas.arvore:
		r.append(str(n.id))
	return r


func _meio54() -> Array:
	return ["body_jab", "career_purse", "body_crew", "body_muscle_memory", "gar_tape", "gar_radio", "camp_poster",
		"career_scouting", "career_crowd"]


func _rodar_fase54() -> void:
	# --- Mapa: começo, meio e completo ---
	if _quer("f54_mapa_inicio"):
		_novo_jogo()
		_com_nos54([], 30)
		await _abrir_arvore()
		_exigir(_mapa() != null and _eh(_mapa(), "JanelaMapa"), "f54_mapa_inicio", "o botão da sala deveria abrir o mapa")
		await _ver("f54_mapa_inicio")
	if _quer("f54_mapa_meio"):
		_novo_jogo()
		_garagem_arte("boxing", [], 800.0)
		_com_nos54(_meio54(), 400)
		await _abrir_arvore()
		await _ver("f54_mapa_meio")
	if _quer("f54_mapa_completo") or _quer("f54_mapa_completo_noroeste") or _quer("f54_mapa_completo_sudeste"):
		_novo_jogo()
		_garagem_arte("boxing", [], 800.0)
		gs.crew_click_comprado = true
		_com_nos54(_todos_os_nos(), 0)
		var j: Node = await _abrir_arvore()
		if _quer("f54_mapa_completo"):
			await _ver("f54_mapa_completo")
		if _quer("f54_mapa_completo_noroeste"):
			j.mover_camera(Vector2i(-9999, -9999))
			await _esperar(0.2)
			await _ver("f54_mapa_completo_noroeste")
		if _quer("f54_mapa_completo_sudeste"):
			j.mover_camera(Vector2i(9999, 9999))
			await _esperar(0.2)
			await _ver("f54_mapa_completo_sudeste")

	# --- Cartão do nó em cada estado ---
	for def in [
			["f54_cartao_compravel", "gar_rope", 400, true],
			["f54_cartao_sem_legado", "body_heavy_hands", 100, true],
			["f54_cartao_arte", "box_counter", 400, true],
			["f54_cartao_grito_sem_loja", "link_shout", 600, true],
			["f54_cartao_comprado", "gar_tape", 400, false],
			["f54_cartao_ativo", "gar_tape", 400, true]]:
		if not _quer(def[0]):
			continue
		_novo_jogo()
		_garagem_arte("boxing", [], 800.0)
		var nos := _meio54()
		if def[1] == "link_shout":
			nos = nos + ["gar_rope"]
		_com_nos54(nos, int(def[2]), bool(def[3]))
		var j: Node = await _abrir_arvore()
		j.ir_para(str(def[1]))
		await _esperar(0.2)
		j.mostrar_cartao(str(def[1]))
		await _esperar(0.2)
		_exigir(j.cartao_aberto() == str(def[1]), str(def[0]), "o cartão de %s deveria estar aberto" % str(def[1]))
		await _ver(str(def[0]))

	# --- Comprar: o nó acende, os vizinhos aparecem, a neblina recua ---
	if _quer("f54_revelacao") or _quer("f54_revelacao_fim"):
		_novo_jogo()
		_com_nos54(["body_jab", "career_purse"], 30)
		var j: Node = await _abrir_arvore()
		j.ir_para("gar_tape")
		await _esperar(0.2)
		var antes: int = gs.legado_disponivel()
		j.clicar_no("gar_tape")
		await _esperar(0.12)
		_exigir(gs.legado_disponivel() == antes - 15 and gs.estado_mapa("gar_tape") == "owned", "f54_revelacao",
			"clicar no nó à vista deveria comprar (Legado %d -> %d)" % [antes, gs.legado_disponivel()])
		await _ver("f54_revelacao")
		await _esperar(1.1)
		_exigir("gar_rope" in j.nos_desenhados() and "gar_radio" in j.nos_desenhados(), "f54_revelacao_fim", "os vizinhos deveriam ter aparecido")
		_exigir(j.fog_nivel_em("gar_rope") == 0, "f54_revelacao_fim", "a neblina deveria ter recuado em volta do nó novo")
		await _ver("f54_revelacao_fim")

	# --- Botão da sala: normal, brilhando, com dica, na academia ---
	if _quer("f54_botao_normal"):
		_novo_jogo()
		_com_nos54([], 0)
		await _abrir()
		var b: Node = _cena.get_node("BotaoMapa")
		_estado = "f54_botao_normal"
		_exigir(not gs.ha_no_compravel() and not b.brilhando(), _estado, "sem nó à vista que o Legado pague o botão fica quieto")
		await _ver("f54_botao_normal")
	if _quer("f54_botao_brilho") or _quer("f54_botao_hover"):
		_novo_jogo()
		_com_nos54([], 30)
		await _abrir()
		var b: Node = _cena.get_node("BotaoMapa")
		_estado = "f54_botao_brilho"
		_exigir(gs.ha_no_compravel() and b.brilhando(), _estado, "com nó à vista que o Legado paga o botão brilha")
		if _quer("f54_botao_brilho"):
			await _ver("f54_botao_brilho")
		if _quer("f54_botao_hover"):
			_dica_em(b.texto_dica(), Vector2(143, 33))
			await _esperar(0.2)
			await _ver("f54_botao_hover")
			_sem_dica()
	if _quer("f54_botao_gym"):
		_novo_jogo()
		_academia("boxing", ["treadmill"], 800.0)
		_com_nos54(["body_jab"], 20)
		await _abrir()
		var b: Node = _cena.get_node("BotaoMapa")
		_exigir(b.position == Vector2(132, 22) and b.size == Vector2(22, 22), "f54_botao_gym", "botão em (132,22) 22x22")
		await _ver("f54_botao_gym")

	# --- Tela de fim: o botão ÁRVORE com o ícone, o mapa por ele e a volta ---
	if _quer("f54_fim_botao") or _quer("f54_mapa_do_fim") or _quer("f54_fim_volta"):
		_derrota_pendente([], 30)
		_com_nos54([], 30)
		gs.fim["legacy_total"] = 30
		await _abrir()
		await _esperar(0.9)
		var fl: Node = _cena.get_node("Fluxo")
		if _quer("f54_fim_botao"):
			await _ver("f54_fim_botao")
		if _quer("f54_mapa_do_fim") or _quer("f54_fim_volta"):
			fl.janela.arvore_pedido.emit()
			await _esperar(0.5)
			_exigir(_eh(fl.janela, "JanelaMapa"), "f54_mapa_do_fim", "o botão ÁRVORE do fim deveria abrir o mesmo mapa")
			if _quer("f54_mapa_do_fim"):
				await _ver("f54_mapa_do_fim")
			if _quer("f54_fim_volta"):
				fl.janela.clicar_no("body_jab")
				await _esperar(1.0)
				fl.janela.fechar_pedido.emit()
				await _esperar(0.9)
				_exigir(_eh(fl.janela, "JanelaFim") and gs.tem_fim_pendente(), "f54_fim_volta", "fechar o mapa volta para a tela de fim")
				await _ver("f54_fim_volta")

	# --- Save antigo (v9, os 12 nós de sempre): abre com eles comprados no centro e os vizinhos à vista ---
	if _quer("f54_save_antigo"):
		_fechar_cena()
		gs.definir_assistido(false)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_SAVE))
		var velhos := ["body_jab", "body_muscle_memory", "body_heavy_hands", "body_crew", "body_crew_2", "career_purse",
			"career_scouting", "career_purse_2", "career_crowd", "career_good_loser", "style_boxing", "style_bjj"]
		var doc := {"version": 9, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0, "art": "boxing"},
			"permanent": {"legacy_total": 60, "career_number": 4, "skill_nodes": velhos, "arts_unlocked": ["boxing", "bjj"], "last_art": "boxing"},
			"ending": null}}
		var f := FileAccess.open(PASTA_SAVE + "save.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(doc))
		f.close()
		gs.inicializar(PASTA_SAVE, CONFIG)
		gs.autosave_ativo = false
		_exigir(gs.estado_mapa("body_jab") == "owned" and gs.estado_mapa("style_boxing") == "owned" and gs.legado_disponivel() == 60,
			"f54_save_antigo", "migração: nós e Legado iguais")
		_exigir(gs.estado_mapa("gar_tape") == "visible" and gs.estado_mapa("box_counter") == "visible", "f54_save_antigo",
			"migração: os vizinhos dos nós antigos abrem à vista")
		await _abrir()
		var fl: Node = _cena.get_node("Fluxo")
		fl.abrir_arvore()
		await _esperar(0.5)
		_exigir(_eh(fl.janela, "JanelaMapa"), "f54_save_antigo", "o mapa deveria abrir com o save migrado")
		await _ver("f54_save_antigo")
		gs.apagar_save()
