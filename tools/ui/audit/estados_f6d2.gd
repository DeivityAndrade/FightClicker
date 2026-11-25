extends RefCounted
## Estados do ui_audit.gd: Fase 6d2 (tela C: sala na tela toda, faixa de baixo de 30 px, painel que entra pela direita, atalhos L / E / H,
## aparelho não comprado invisível). Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const ZONA_ALVO := Rect2(273, 150, 98, 142)  # alvo + 8 px de folga (docs/arte/fase6d2-layout.md)
const NOMES := ["f6d2_tela_fechada", "f6d2_painel_solto", "f6d2_so_sala", "f6d2_foco_trancado",
	"f6d2_aparelho_invisivel", "f6d2_aparelho_caixa", "f6d2_aparelho_aberto", "f6d2_garagem_cheia", "f6d2_garagem_pequena",
	"f6d2_academia_cheia", "f6d2_academia_pequena", "f6d2_clique_fecha", "f6d2_cena_fecha"]

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _no(nome: String) -> Control:
	return au._cena.get_node(nome)


## Nenhum painel da tela cobre a zona do alvo (com o painel da direita fechado ou aberto).
func _sem_cobrir_alvo(nome: String) -> void:
	for n in ["PainelAtributos", "PainelProxima", "Hud", "BarraBaixo"]:
		var c: Control = _no(n)
		au._exigir(not c.get_global_rect().intersects(ZONA_ALVO), nome, "%s cobre a zona do alvo: %s" % [n, str(c.get_global_rect())])
	var corpo: Control = _no("PainelLoja").get_node("Corpo")
	if corpo.visible:
		au._exigir(not corpo.get_global_rect().intersects(ZONA_ALVO), nome, "o painel da direita cobre a zona do alvo")


## Atalho de teclado (aperta e solta) e espera o quadro processar.
func _teclar(k: Key) -> void:
	au._tecla(k, true)
	au._tecla(k, false)
	await au._esperar(0.3)


func _equipe(qtd: int) -> void:
	for g in au.gs.dados.geradores:
		au.gs.geradores[g.id] = qtd


func _clicar_na_sala(p: Vector2) -> void:
	au._mouse(p, true)
	au._mouse(p, false)
	await au._esperar(0.4)


func _rodar_fase6d2() -> void:
	if not _alguma():
		return
	# --- Tela fechada: a sala ocupa a tela toda, a faixa de baixo tem 30 px, só a aba de borda aparece à direita ---
	if au._quer("f6d2_tela_fechada"):
		au._novo_jogo()
		au.painel_modo = "fechado"
		await au._abrir()
		var sala: Control = _no("Sala")
		au._exigir(sala.size == Vector2(640, 312) and sala.position == Vector2(0, 18), "f6d2_tela_fechada", "a sala deveria ocupar x 0..640, y 18..330: %s %s" % [str(sala.position), str(sala.size)])
		var barra: Control = _no("BarraBaixo")
		au._exigir(barra.size.y == 30.0 and barra.position.y == 330.0, "f6d2_tela_fechada", "a faixa de baixo tem 30 px em y 330")
		var loja: Control = _no("PainelLoja")
		au._exigir(not loja.get_node("Corpo").visible and not loja.esta_aberto(), "f6d2_tela_fechada", "o painel começa fechado")
		au._exigir(loja.get_node("Alca").visible and loja.get_node("Alca").get_global_rect().end.x <= 640.0, "f6d2_tela_fechada", "a aba de borda aparece")
		_sem_cobrir_alvo("f6d2_tela_fechada")
		await au._ver("f6d2_tela_fechada")
	# --- Painel solto aberto (clique na aba) ---
	if au._quer("f6d2_painel_solto"):
		au._novo_jogo()
		au.gs.dinheiro = 5000.0
		au.painel_modo = "fechado"
		await au._abrir()
		var loja2: Control = _no("PainelLoja")
		loja2.alternar()  # o mesmo que o clique na aba
		await au._esperar(0.4)
		au._exigir(loja2.esta_aberto() and loja2.get_node("Corpo").position.x == 508.0, "f6d2_painel_solto", "a aba abre o painel em x 508")
		au._exigir(not loja2.get_node("Corpo").get_global_rect().intersects(ZONA_ALVO), "f6d2_painel_solto", "painel aberto não cobre o alvo")
		await au._ver("f6d2_painel_solto")
	# --- 6d3: clique na sala NÃO fecha o painel; só a aba/seta (ou L/E na mesma aba) fecha ---
	if au._quer("f6d2_clique_fecha"):
		au._novo_jogo()
		au.gs.dinheiro = 5000.0
		au.painel_modo = "solto"
		await au._abrir()
		var loja3: Control = _no("PainelLoja")
		au._exigir(loja3.esta_aberto(), "f6d2_clique_fecha", "começa aberto")
		await _clicar_na_sala(Vector2(150, 200))
		await au._esperar(0.3)
		au._exigir(loja3.esta_aberto() and loja3.get_node("Corpo").position.x == 508.0, "f6d2_clique_fecha", "o clique na sala não fecha o painel")
		await _clicar_na_sala(Vector2(150, 200))
		au._exigir(loja3.esta_aberto(), "f6d2_clique_fecha", "clicar de novo no saco continua aberto")
		await au._ver("f6d2_clique_fecha")
		loja3.alternar()  # o clique na área de toque da aba chama isto
		await au._esperar(0.4)
		au._exigir(not loja3.esta_aberto() and not loja3.get_node("Corpo").visible, "f6d2_clique_fecha", "o clique na aba/seta fecha")
	# --- Só a sala (tecla H) ---
	if au._quer("f6d2_so_sala"):
		au._novo_jogo()
		au.painel_modo = "fixo"
		await au._abrir()
		await _teclar(KEY_H)
		au._exigir(au._cena.esta_so_sala(), "f6d2_so_sala", "H liga o modo só a sala")
		au._exigir(not _no("PainelAtributos").visible and not _no("PainelProxima").visible and not _no("PainelLoja").visible and not _no("BotaoMapa").visible,
			"f6d2_so_sala", "atributos, próxima luta, painel e mapa somem")
		au._exigir(_no("BarraBaixo")._lutar.visible and not _no("BarraBaixo")._aposentar.visible, "f6d2_so_sala", "fica o LUTAR; o resto da faixa some")
		await au._ver("f6d2_so_sala")
		await _teclar(KEY_H)
		au._exigir(not au._cena.esta_so_sala() and _no("PainelAtributos").visible and _no("PainelLoja").visible, "f6d2_so_sala", "H de novo traz tudo de volta")
		# O1: com o só-sala ligado, L sai dele e abre a loja; 6d3: a mesma aba fecha, a outra só troca e continua aberto
		var loja_h: Control = _no("PainelLoja")
		await _teclar(KEY_H)
		await _teclar(KEY_L)
		au._exigir(not au._cena.esta_so_sala() and loja_h.esta_aberto() and loja_h._aba == "loja", "f6d2_so_sala", "O1: L tira do só-sala e abre a loja")
		await _teclar(KEY_E)
		au._exigir(loja_h.esta_aberto() and loja_h._aba == "treino", "f6d2_so_sala", "O2: E com a loja aberta só troca a aba e continua aberta")
		await _teclar(KEY_E)
		au._exigir(not loja_h.esta_aberto(), "f6d2_so_sala", "O2: E na aba aberta fecha")
	# --- Foco trancado: o clique abre o painel no cartão do aparelho; atalhos L e E ---
	if au._quer("f6d2_foco_trancado"):
		au._novo_jogo()
		au._com_aparelhos([], 700.0)
		au.painel_modo = "fechado"
		await au._abrir()
		var loja5: Control = _no("PainelLoja")
		var botao: Control = _no("BarraBaixo")._botoes["treadmill"].botao
		await _clicar_na_sala(botao.get_global_rect().get_center())
		au._exigir(loja5.esta_aberto() and loja5._aba == "treino", "f6d2_foco_trancado", "o clique no foco trancado abre o painel na aba TREINO")
		au._exigir(au.gs.foco == "punching_bag", "f6d2_foco_trancado", "o foco não troca")
		au._exigir(loja5._unl["treadmill"].cartao.visible, "f6d2_foco_trancado", "o cartão da esteira está na aba")
		await au._ver("f6d2_foco_trancado")
		loja5.fechar(false)
		await _teclar(KEY_L)
		au._exigir(loja5.esta_aberto() and loja5._aba == "loja", "f6d2_foco_trancado", "L abre a loja")
		await _teclar(KEY_E)
		au._exigir(loja5.esta_aberto() and loja5._aba == "treino", "f6d2_foco_trancado", "E troca para a equipe")
		await _teclar(KEY_E)
		au._exigir(not loja5.esta_aberto(), "f6d2_foco_trancado", "E de novo fecha")
	# --- Aparelho: invisível -> caixa -> aparelho ---
	if au._quer("f6d2_aparelho_invisivel") or au._quer("f6d2_aparelho_caixa") or au._quer("f6d2_aparelho_aberto"):
		au._novo_jogo()
		au._com_aparelhos([], 700.0)
		au.painel_modo = "fechado"
		await au._abrir()
		var sala2: Control = _no("Sala")
		au._exigir(not au._aparelho_visivel("treadmill") and not au._aparelho_visivel("jump_rope") and sala2._caixas.is_empty(), "f6d2_aparelho_invisivel",
			"antes da compra não há nada: nem aparelho nem caixa")
		await au._ver("f6d2_aparelho_invisivel")
		au._exigir(au.gs.comprar_aparelho("treadmill"), "f6d2_aparelho_caixa", "compra a esteira")
		await au._esperar(0.8)
		au._exigir(sala2._caixas.has("treadmill") and not au._aparelho_visivel("treadmill"), "f6d2_aparelho_caixa", "comprou: só a caixa")
		au._exigir(sala2._caixas["treadmill"].position.distance_to(Vector2(466, 324)) < 2.0, "f6d2_aparelho_caixa", "a caixa está no ponto do manifest (466,324): %s" % str(sala2._caixas["treadmill"].position))
		await au._ver("f6d2_aparelho_caixa")
		for i in 3:
			au.gs.bater_caixa("treadmill")
		await au._esperar(1.6)
		au._exigir(au._aparelho_visivel("treadmill") and not sala2._caixas.has("treadmill"), "f6d2_aparelho_aberto", "abriu: aparece o aparelho")
		await au._ver("f6d2_aparelho_aberto")
	# --- Salas cheias e pequenas, garagem e academia (painel fixado e fechado) ---
	for q in [["f6d2_garagem_cheia", "garage", 30, "fixo"], ["f6d2_garagem_pequena", "garage", 1, "fechado"],
			["f6d2_academia_cheia", "gym", 30, "fixo"], ["f6d2_academia_pequena", "gym", 1, "fechado"]]:
		if not au._quer(q[0]):
			continue
		au._novo_jogo()
		_equipe(int(q[2]))
		if q[1] == "gym":
			au._academia("boxing", ["treadmill", "jump_rope", "speed_bag"] if int(q[2]) > 1 else ["treadmill"], 3000.0, "punching_bag")
		else:
			au._com_aparelhos(["treadmill", "jump_rope"] if int(q[2]) > 1 else [], 700.0)
		au.painel_modo = q[3]
		await au._abrir()
		await au._esperar(0.4)
		_sem_cobrir_alvo(q[0])
		var chip: Control = _no("FaixaAssistido")._botao
		au._exigir(not chip.get_global_rect().intersects(Rect2(100, 250, 46, 80)), q[0], "B1: o chip do assistido não cobre o vizinho 2 (126,322): %s" % str(chip.get_global_rect()))
		await au._ver(q[0])
	# --- O painel fecha sozinho durante a cena e volta como estava ---
	if au._quer("f6d2_cena_fecha"):
		au._novo_jogo()
		au.painel_modo = "fixo"
		await au._abrir()
		var loja6: Control = _no("PainelLoja")
		au._exigir(loja6.esta_aberto(), "f6d2_cena_fecha", "começa aberto")
		au._cena.cena_forcada = true
		await au._esperar(0.4)
		au._exigir(not loja6.esta_aberto() and not loja6.get_node("Corpo").visible, "f6d2_cena_fecha", "na cena o painel fecha (e lembra que estava aberto)")
		au._cena.cena_forcada = false
		await au._esperar(0.4)
		au._exigir(loja6.esta_aberto() and loja6.get_node("Corpo").position.x == 508.0, "f6d2_cena_fecha", "no fim da cena volta como estava")
		await au._ver("f6d2_cena_fecha")
