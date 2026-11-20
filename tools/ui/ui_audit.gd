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
	# Fase 6a: prólogo e voz
	"f6a_esc_chip", "f6a_abertura_gesto", "f6a_abertura_b1", "f6a_abertura_b2", "f6a_abertura_b3", "f6a_abertura_b4", "f6a_abertura_fim",
	"f6a_osmar_1l", "f6a_osmar_2l", "f6a_osmar_borda", "f6a_john_1l", "f6a_john_2l", "f6a_pergunta", "f6a_john_corda", "f6a_john_esteira",
	"f6a_gym_sem_osmar", "f6a_gym_john", "f6a_parede_antes", "f6a_hover_ficha", "f6a_hover_aviso", "f6a_parede_recorte", "f6a_parede_depois",
	"f6a_hover_ficha_depois", "f6a_gesto_sala", "f6a_gesto_curto", "f6a_gesto_cancela", "f6a_gesto_luta", "f6a_gesto_vitoria",
	"f6a_discipulo_garagem", "f6a_discipulo_previa", "f6a_discipulo_luta", "f6a_vitoria_selo", "f6a_vitoria_sem_selo",
	# Fase 6b1: passar o posto (cena, tela de criação, chegada, John mentor, nome no lugar de Carreira N)
	"f6b1_s1", "f6b1_s2", "f6b1_s3", "f6b1_s4", "f6b1_s5", "f6b1_s6", "f6b1_s7", "f6b1_s8", "f6b1_s9", "f6b1_s10", "f6b1_linha",
	"f6b1_criar", "f6b1_criar_nome14", "f6b1_criar_cores", "f6b1_criar_vazio", "f6b1_chegada", "f6b1_mentor_sentado",
	"f6b1_mentor_balao", "f6b1_mentor_balao_isso", "f6b1_mentor_toques", "f6b1_fim_botao", "f6b1_fim_nome14", "f6b1_hud_nome14",
	"f6b1_cartao", "f6b1_arte", "f6b1_luva_hover", "f6b1_save_criacao", "f6b1_pular_anel", "f6b1_pular",
	# Fase 6b2: cara de lutador (tela de criação em 2 colunas, cortes, roupas, faixa, meião, segundo mentor)
	"f6b2_criar", "f6b2_criar_apagadas", "f6b2_criar_nome14", "f6b2_criar_cheio", "f6b2_cortes", "f6b2_partes", "f6b2_faixa_meiao",
	"f6b2_luta_cheio", "f6b2_luta_regata", "f6b2_mentor2", "f6b2_mentor2_dica", "f6b2_mentor2_balao_osmar", "f6b2_mentor2_balao_john",
	"f6b2_mentor2_cena", "f6b2_mentor2_chegada",
	# Fase 6c1: casa nova (cena da 1a chegada a academia, academia cheia, saida do John)
	"f6c1_chegada_cena", "f6c1_chegada_2x", "f6c1_academia_cheia", "f6c1_saida",
	"f6c1_academia_balao_osmar", "f6c1_academia_balao_john",
	"f6c1_saida_gym_J1", "f6c1_saida_gym_J2", "f6c1_saida_gym_J3", "f6c1_saida_gym_J4", "f6c1_saida_gym_J5", "f6c1_saida_gym_J6", "f6c1_saida_gym_J7",
	"f6c1_saida_gar_J1", "f6c1_saida_gar_J2", "f6c1_saida_gar_J3", "f6c1_saida_gar_J4", "f6c1_saida_gar_J5", "f6c1_saida_gar_J6", "f6c1_saida_gar_J7",
	# Fase 6c2: mural, Honra, hall, falas dos mentores, simbolo da escola
	"f6c2_mural_garagem", "f6c2_mural_garagem_hover", "f6c2_mural_academia", "f6c2_foto_academia_hover", "f6c2_mural_academia_hover",
	"f6c2_tela_mural_vazio", "f6c2_tela_mural_1", "f6c2_tela_mural_4", "f6c2_tela_mural_9", "f6c2_tela_mural_nomes_longos", "f6c2_tela_mural_30", "f6c2_tela_mural_30_ultima",
	"f6c2_aposentar_honra", "f6c2_aposentar_honra_cinturao", "f6c2_aposentar_sem_honra",
	"f6c2_fim_honra_1", "f6c2_fim_honra_27", "f6c2_fim_sem_honra", "f6c2_fim_derrota_mural",
	"f6c2_hall_nada", "f6c2_hall_meio", "f6c2_hall_tudo", "f6c2_hall_comprado", "f6c2_hall_fechado",
	"f6c2_previa_falta", "f6c2_previa_falta_max", "f6c2_cartao_mural",
	"f6c2_balao_mentor_john", "f6c2_balao_mentor_last",
	"f6c2_simbolo_peito", "f6c2_simbolo_perna", "f6c2_simbolo_luta",
	# Fase 6d: balão de descrição colado ao cursor (loja, melhorias, mapa, hall) e números do treino por atributo
	"f6d_balao_gerador", "f6d_balao_melhoria", "f6d_balao_melhoria_baixo", "f6d_balao_loja", "f6d_balao_loja_metronomo",
	"f6d_balao_cantos", "f6d_balao_mapa", "f6d_balao_hall",
	"f6d_numeros_bjj", "f6d_numeros_bjj_critico", "f6d_numeros_pera", "f6d_numeros_um_atributo",
	# Fase 6d2: tela C (sala larga, faixa de 30 px, painel pela direita, atalhos L/E/H, aparelho invisível até a caixa)
	"f6d2_tela_fechada", "f6d2_painel_solto", "f6d2_so_sala", "f6d2_foco_trancado", "f6d2_aparelho_invisivel",
	"f6d2_aparelho_caixa", "f6d2_aparelho_aberto", "f6d2_garagem_cheia", "f6d2_garagem_pequena", "f6d2_academia_cheia", "f6d2_academia_pequena",
	"f6d2_clique_fecha", "f6d2_cena_fecha",
	# Fase 7a1: passiva de cada arte (prévia, luta, fim) e arena da liga
	"f7a1_previa_boxing_aggressive", "f7a1_previa_boxing_defensive", "f7a1_previa_boxing_counter", "f7a1_previa_bjj_aggressive",
	"f7a1_previa_bjj_defensive", "f7a1_previa_bjj_counter", "f7a1_previa_bjj_kid", "f7a1_luta_boxe_embalo", "f7a1_luta_boxe_cansado",
	"f7a1_luta_boxe_defensivo", "f7a1_luta_boxe_ko", "f7a1_luta_jj_pegada", "f7a1_luta_jj_chao", "f7a1_luta_jj_finalizou",
	"f7a1_luta_jj_finalizou_letreiro", "f7a1_arena_borracharia", "f7a1_arena_liga", "f7a1_fim_derrota_arena", "f7a1_fim_nota_boxe",
	"f7a1_fim_nota_jj",
	# Fase 7a2: treino fora de hora (convite do Osmar, Choque, Panfletagem, AQUECIDO e o recorte do vulto)
	"f7a2_balao_garagem_spar", "f7a2_balao_garagem_flyers", "f7a2_balao_academia_spar", "f7a2_balao_academia_flyers", "f7a2_balao_espera",
	"f7a2_choque_boxe_comeco", "f7a2_choque_boxe_rajada", "f7a2_choque_boxe_pausa", "f7a2_choque_boxe_finta", "f7a2_choque_boxe_folego",
	"f7a2_choque_boxe_ponto", "f7a2_choque_boxe_premio", "f7a2_choque_boxe_premio_derrota",
	"f7a2_choque_jj_comeco", "f7a2_choque_jj_rajada", "f7a2_choque_jj_pausa", "f7a2_choque_jj_finta", "f7a2_choque_jj_folego",
	"f7a2_choque_jj_ponto", "f7a2_choque_jj_premio",
	"f7a2_panfleto_comeco", "f7a2_panfleto_sinal", "f7a2_panfleto_aceitou", "f7a2_panfleto_erro", "f7a2_panfleto_premio",
	"f7a2_previa_aquecido", "f7a2_hud_aquecido", "f7a2_recorte_garagem", "f7a2_recorte_academia",
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
var _f4 = preload("res://tools/ui/audit/estados_f4.gd").new(self)
var _f5 = preload("res://tools/ui/audit/estados_f5.gd").new(self)
var _f52_f53 = preload("res://tools/ui/audit/estados_f52_f53.gd").new(self)
var _f54_f6a = preload("res://tools/ui/audit/estados_f54_f6a.gd").new(self)
var _f6b1 = preload("res://tools/ui/audit/estados_f6b1.gd").new(self)
var _f6b2_f6c1 = preload("res://tools/ui/audit/estados_f6b2_f6c1.gd").new(self)
var _f6c2 = preload("res://tools/ui/audit/estados_f6c2.gd").new(self)
var _f6d = preload("res://tools/ui/audit/estados_f6d.gd").new(self)
var _f6d2 = preload("res://tools/ui/audit/estados_f6d2.gd").new(self)
var _f7a1 = preload("res://tools/ui/audit/estados_f7a1.gd").new(self)
var _f7a2 = preload("res://tools/ui/audit/estados_f7a2.gd").new(self)


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
	await _f4._rodar_fase4()
	await _f4._rodar_fase4b()
	await _f5._rodar_fase5()
	await _f5._rodar_fase51()
	await _f52_f53._rodar_fase52()
	await _f52_f53._rodar_fase53()
	await _f54_f6a._rodar_fase54()
	await _f54_f6a._rodar_fase6a()
	await _f6b1._rodar_fase6b1()
	await _f6b1._rodar_fase6b1_pular()
	await _f6b2_f6c1._rodar_fase6b2()
	await _f6b2_f6c1._rodar_fase6c1()
	await _f6b2_f6c1._rodar_fase6c1_extra()
	await _f6c2._rodar_fase6c2()
	await _f6d._rodar_fase6d()
	await _f6d2._rodar_fase6d2()
	await _f7a1._rodar_fase7a1()
	await _f7a2._rodar_fase7a2()
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


## 6d2: não existe mais marca de fita. Continua respondendo "falta comprar o aparelho" (o que a marca significava); o que a sala
## mostra de verdade (nada, só a caixa, o aparelho) é conferido pelos estados f6d2_.
func _marca_visivel(id: String) -> bool:
	var e: String = gs.estado_aparelho(id)
	return e != "owned" and e != "absent"


## O sprite do aparelho está desenhado na sala?
func _aparelho_visivel(id: String) -> bool:
	return bool(_cena.get_node("Sala")._anim_do(id).visible)


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


## Jogo novo com save isolado: dados medianos de treino (números reais nos painéis).
func _novo_jogo() -> void:
	_fechar_cena()
	gs.definir_assistido(false)
	gs.inicializar(PASTA_SAVE, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 1
	gs.pular_abertura()  # Fase 6a: sem a abertura (e sem balão) nos estados antigos; os estados 6a a pedem de volta
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


## Como o painel da direita (loja e equipe) fica ao abrir a tela: "fixo" e "solto" = aberto (desde a 6d3 não há mais diferença:
## só fecha quando o jogador manda) ou "fechado" (só a aba de borda). Os estados f6d2_ trocam.
var painel_modo := "fixo"


func _abrir() -> void:
	_fechar_cena()
	_cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_cena)
	await process_frame
	_aplicar_painel_modo()
	await _esperar(0.5)


func _aplicar_painel_modo() -> void:
	var p: Node = _cena.get_node_or_null("PainelLoja")
	if p != null:
		p.definir_estado(painel_modo != "fechado", false)


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
	for b in _cena.get_node("PainelProxima").find_children("*", "Button", true, false):
		return b
	return null


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


func _abrir_loja(rolar_ate_o_fim: bool = false) -> Node:
	await _abrir()
	var painel: Node = _cena.get_node("PainelLoja")
	painel._tab["loja"].botao.pressed.emit()
	await _esperar(0.2)
	if rolar_ate_o_fim:
		painel._rolar_a(painel._rolagem_max)
	await _esperar(0.1)
	return painel


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


const NO_COVER_6A := Rect2(310, 180, 52, 94)
const UTIL_6A := Rect2(4, 22, 632, 304)  # 6d2: a sala é a tela toda (menos o HUD e a faixa de baixo)


func _balao() -> Node:
	return _cena._balao


## Mostra uma fala de teste (sem passar pela fila do GameState) e completa a digitação.
func _falar(speaker: String, texto: String, id: String = "t") -> void:
	gs.fala_pedida.emit(speaker, texto, id)
	await _esperar(0.15)
	_balao().completar()
	await _esperar(0.1)


## O balão não cobre a zona do alvo, fica dentro da sala e não cobre a cabeça do outro personagem.
func _checar_balao(nome: String, speaker: String) -> void:
	var b: Node = _balao()
	_exigir(b.ativo(), nome, "o balão deveria estar na tela")
	if not b.ativo():
		return
	var r: Rect2 = b.retangulo_total()
	_exigir(not r.intersects(NO_COVER_6A), nome, "o balão cobre a zona do alvo: %s" % _fmt(r))
	_exigir(UTIL_6A.encloses(r), nome, "o balão sai da sala: %s" % _fmt(r))
	var sala: Node = _cena.get_node("Sala")
	for e in sala.cabecas_a_evitar(speaker):
		_exigir(not r.intersects(e), nome, "o balão cobre a cabeça do outro personagem: %s x %s" % [_fmt(r), _fmt(e)])
	if sala.mentor2_visivel():
		var m2: Vector2 = sala.cabeca_mentor2()
		_exigir(not r.intersects(Rect2(m2.x - 9.0, m2.y, 18.0, 18.0)), nome, "o balão cobre a cabeça do segundo mentor: %s" % _fmt(r))


func _cena_ui() -> Node:
	for c in _cena.get_children():
		if _eh(c, "CenaUi"):
			return c
	return null


## Campanha 2 (discípulo) encerrada com a tela de fim pendente. `marco`: a cena grande já tocou (sucessão seguinte = chegada curta).
func _f6b1_fim(nome: String = "", marco: bool = false) -> void:
	_derrota_pendente(NOS_MISTA, 40)
	if nome != "":
		gs.discipulo = {"name": nome, "look": gs.disciples.look_padrao.duplicate(), "campaign": 2}
	if marco:
		gs._gravar_marco("cena_primeira_sucessao", {}, false)
		gs.escola["mentors"] = ["first"]


func _f6b1_janela_criar() -> Node:
	var fl: Node = _cena.get_node("Fluxo")
	for i in 80:
		if fl.janela != null and _eh(fl.janela, "TelaCriarDiscipulo"):
			return fl.janela
		await _esperar(0.1)
	return null


## Balão da 6b1: fora da zona do alvo, dentro da sala e sem cobrir a cabeça do Osmar, do lutador nem de ninguém em cena.
func _checar_balao_6b1(nome: String, speaker: String) -> void:
	var b: Node = _balao()
	if not b.ativo():
		return
	var r: Rect2 = b.retangulo_total()
	_exigir(not r.intersects(NO_COVER_6A), nome, "o balão cobre a zona do alvo: %s" % _fmt(r))
	_exigir(UTIL_6A.encloses(r), nome, "o balão sai da sala: %s" % _fmt(r))
	var sala: Node = _cena.get_node("Sala")
	var cabecas: Array = []
	var o: Vector2 = sala.ponto_cabeca("coach")
	cabecas.append(Rect2(o.x - 9.0, o.y, 18.0, 18.0))
	if sala._cena_ativa:
		cabecas.append_array(sala.cena.cabecas_a_evitar(speaker))
	else:
		var l: Vector2 = sala.ponto_cabeca("first")
		cabecas.append(Rect2(l.x - 9.0, l.y, 18.0, 18.0))
	for c in cabecas:
		_exigir(not r.intersects(c), nome, "o balão cobre a cabeça de alguém: %s x %s" % [_fmt(r), _fmt(c)])
	if sala.mentor2_visivel():
		var m2: Vector2 = sala.cabeca_mentor2()
		_exigir(not r.intersects(Rect2(m2.x - 9.0, m2.y, 18.0, 18.0)), nome, "o balão cobre a cabeça do segundo mentor: %s" % _fmt(r))


const LOOK_CHEIO_6B2 := {"skin": "skin_2", "hair_color": "copper", "hair_style": "bun", "shorts_color": "blue", "top": "tee",
	"top_color": "gray", "headband": "band", "headband_color": "white", "socks": "on"}
const LOOK_MENTOR_6B2 := {"skin": "skin_5", "hair_color": "black", "hair_style": "volume", "shorts_color": "yellow", "top": "tank",
	"top_color": "blue", "headband": "band", "headband_color": "red", "socks": "on"}


func _look_6b2(mudar: Dictionary = {}) -> Dictionary:
	var l: Dictionary = LOOK_CHEIO_6B2.duplicate()
	l.merge(mudar, true)
	return l


## Campanha do discípulo na garagem com o John sentado; com `look_mentor` o roster tem quem passou o posto (o 2º mentor).
func _f6b2_jogo(look: Dictionary, look_mentor: Dictionary = {}, com_cinturao: bool = false) -> void:
	_novo_jogo()
	gs.escola["mentors"] = ["first"]
	gs.discipulo = {"name": "Tati Gancho", "look": look.duplicate(), "campaign": 3}
	if not look_mentor.is_empty():
		gs.escola["roster"] = [
			{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire"},
			{"campaign": 2, "kind": "disciple", "name": "Beto Cruz", "look": look_mentor.duplicate(), "end": "defeat", "wins": 3,
				"belt": com_cinturao, "art": "", "opponent": "", "legacy_gained": 0}]


func _f6b2_luta(nome: String, look: Dictionary, com_cinturao: bool = false) -> void:
	var achada := _achar_luta(true, true)
	_f6b2_jogo(look, LOOK_MENTOR_6B2, com_cinturao)
	gs.atributos = achada.atr
	await _abrir()
	await _esperar(0.4)
	gs.rng.seed = int(achada.k)
	var fl: Node = _cena.get_node("Fluxo")
	fl.abrir_previa()
	await _esperar(0.3)
	fl.janela.lutar_pedido.emit()
	await _esperar(1.0)
	_estado = nome
	_exigir(fl.tela._l[0].spr.nome_sprite.ends_with("_disc") and fl.tela._l[0].spr.texture != null, nome, "a luta usa a folha _disc em camadas")
	await _ver(nome)
	await _esperar(0.9)
	await _ver(nome + "_b")


## A cena da 1a chegada a academia esta tocando: PULAR (como o jogador) e espera a escolha da arte abrir.
func _pular_cena_academia() -> void:
	var cu: Node = _cena_ui()
	if cu != null and cu.player.pode_pular():
		cu.player.pular()
	await _esperar(0.9)
