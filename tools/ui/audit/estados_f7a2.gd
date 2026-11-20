extends RefCounted
## Estados do ui_audit.gd: Fase 7a2 (Treino fora de hora): balão do convite do Osmar nos dois locais (Choque e Panfletagem), tela do
## Choque Boxe e Jiu-jitsu (começo, rajada, pausa, finta, fôlego baixo, ponto, prêmio), Panfletagem (começo com o boato, sinal,
## ACEITOU!, NÃO VALEU, prêmio), prévia e HUD com AQUECIDO e o recorte de jornal do vulto nos dois locais.
## Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd). O roteiro do minigame é semeado de novo depois do IR para o estado
## ser sempre o mesmo (o IR sorteia o roteiro com `randomize()`).

const NOMES := [
	"f7a2_balao_garagem_spar", "f7a2_balao_garagem_flyers", "f7a2_balao_academia_spar", "f7a2_balao_academia_flyers", "f7a2_balao_espera",
	"f7a2_choque_boxe_comeco", "f7a2_choque_boxe_rajada", "f7a2_choque_boxe_pausa", "f7a2_choque_boxe_finta", "f7a2_choque_boxe_folego",
	"f7a2_choque_boxe_ponto", "f7a2_choque_boxe_premio", "f7a2_choque_boxe_premio_derrota",
	"f7a2_choque_jj_comeco", "f7a2_choque_jj_rajada", "f7a2_choque_jj_pausa", "f7a2_choque_jj_finta", "f7a2_choque_jj_folego",
	"f7a2_choque_jj_ponto", "f7a2_choque_jj_premio",
	"f7a2_panfleto_comeco", "f7a2_panfleto_sinal", "f7a2_panfleto_aceitou", "f7a2_panfleto_erro", "f7a2_panfleto_premio",
	"f7a2_previa_aquecido", "f7a2_hud_aquecido", "f7a2_recorte_garagem", "f7a2_recorte_academia",
]

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _quer_prefixo(p: String) -> bool:
	for n in NOMES:
		if n.begins_with(p) and au._quer(n):
			return true
	return false


# ---------------------------------------------------------------------------------------------
# Montagem
# ---------------------------------------------------------------------------------------------

## Põe a carreira no local com arte (ou sem) e marcos, e deixa o convite `tipo` aberto. Antes de _abrir().
func _preparar(local: String, arte: String, tipo: String) -> void:
	au._novo_jogo()
	if local == "gym":
		au._academia(arte if arte != "" else "boxing", ["treadmill", "jump_rope"], 800.0, "punching_bag", 4)
		au.gs._gravar_marco("cena_primeira_academia", {}, false)
	elif arte != "":
		au._garagem_arte(arte, ["treadmill", "jump_rope"], 800.0)
	au.gs._gravar_marco("garage_saved", {}, false)
	au.gs._gravar_marco("garage_saved_seen", {}, false)
	if tipo != "":
		au.gs.convite = {"room_s": 400.0, "next_at": 640.0, "open": tipo, "open_since": 395.0, "last": tipo, "warm": false}
	au.gs._convite_local = au.gs.local_id  # chegar de outro local fecha o convite (MUDAR); aqui já estamos nele


## Abre a cena com o balão do convite, aperta IR pelo botão de verdade e devolve a tela do minigame (ou null).
func _entrar(nome: String, local: String, arte: String, tipo: String) -> Node:
	au._estado = nome
	_preparar(local, arte, tipo)
	await au._abrir()
	await au._esperar(0.3)
	var conv: Node = au._cena._convite
	au._exigir(conv.ativo() and conv.kind == tipo, nome, "o balão do convite deveria estar na tela (%s)" % tipo)
	if not conv.ativo():
		return null
	conv._botao.pressed.emit()
	await au._esperar(0.15)
	var tela: Node = au._cena.get_node("Fluxo").treino
	au._exigir(tela != null, nome, "IR deveria abrir a tela do minigame")
	return tela


## Troca o minigame por um com o roteiro semeado (k): o estado de cada captura é sempre o mesmo.
func _semear_choque(tela: Node, arte: String, k: int) -> Variant:
	var r := RandomNumberGenerator.new()
	r.seed = k
	var j = load("res://scripts/minigame_choque.gd").new(au.gs.minigames.spar, arte, au.gs.indice_escada, r)
	au.gs._treino_jogo = j
	tela.jogo = j
	return j


## Semente cujo roteiro tem rajada, pausa e finta depois dos 4 s (para as capturas do meio do jogo).
func _achar_roteiro(arte: String) -> int:
	for k in range(1, 400):
		var r := RandomNumberGenerator.new()
		r.seed = k
		var j = load("res://scripts/minigame_choque.gd").new(au.gs.minigames.spar, arte, au.gs.indice_escada, r)
		var tem := {"burst": false, "pause": false, "feint": false}
		for p in j.roteiro():
			if float(p.a) >= 4.0 and float(p.f) < 24.0:
				tem[str(p.tipo)] = true
		if tem.burst and tem.pause and tem.feint:
			return k
	return 1


func _padrao(j: Variant, tipo: String) -> Dictionary:
	for p in j.roteiro():
		if str(p.tipo) == tipo and float(p.a) >= 4.0:
			return p
	return {}


## Anda o jogo até o tempo `t` (a lógica anda em passos fixos; a UI não faz isto, só a ferramenta de captura).
func _ir(j: Variant, t: float) -> void:
	if j.fase == "contagem":
		j.passo(2.05)
	if j.tempo < t:
		j.passo(t - j.tempo)


func _checar_hud(nome: String, tela: Node) -> void:
	au._exigir(tela.visible and tela.get_global_rect().encloses(Rect2(Vector2.ZERO, Vector2(640, 360))), nome, "a tela do treino cobre a janela inteira")


# ---------------------------------------------------------------------------------------------
# Estados
# ---------------------------------------------------------------------------------------------

func _rodar_fase7a2() -> void:
	if not _alguma():
		return
	await _baloes()
	for par in [["boxing", "boxe"], ["bjj", "jj"]]:
		await _choque(par[0], par[1])
	await _panfleto()
	await _aquecido()
	await _recortes()


func _checar_balao_convite(nome: String) -> void:
	var b: Node = au._cena._convite
	au._exigir(b.ativo(), nome, "o balão do convite deveria estar na tela")
	if not b.ativo():
		return
	var r: Rect2 = b.retangulo_total()
	au._exigir(not r.intersects(au.NO_COVER_6A), nome, "o balão cobre a zona do alvo: %s" % au._fmt(r))
	au._exigir(au.UTIL_6A.encloses(r), nome, "o balão sai da sala: %s" % au._fmt(r))
	var sala: Node = au._cena.get_node("Sala")
	for e in sala.cabecas_a_evitar("coach"):
		au._exigir(not r.intersects(e), nome, "o balão cobre a cabeça de outro personagem: %s x %s" % [au._fmt(r), au._fmt(e)])
	var bt: Control = b._botao
	au._exigir(bt != null and r.encloses(bt.get_global_rect()), nome, "o botão IR fica dentro do balão")


func _baloes() -> void:
	var casos := [["f7a2_balao_garagem_spar", "garage", "spar"], ["f7a2_balao_garagem_flyers", "garage", "flyers"],
		["f7a2_balao_academia_spar", "gym", "spar"], ["f7a2_balao_academia_flyers", "gym", "flyers"]]
	for c in casos:
		if not au._quer(c[0]):
			continue
		au._estado = c[0]
		_preparar(c[1], "boxing", c[2])
		await au._abrir()
		await au._esperar(0.4)
		_checar_balao_convite(c[0])
		await au._ver(c[0])
	if au._quer("f7a2_balao_espera"):
		# A caixa de equipamento anima abrindo: o balão espera; terminou a animação, ele aparece.
		au._estado = "f7a2_balao_espera"
		_preparar("garage", "boxing", "spar")
		await au._abrir()
		await au._esperar(0.4)
		var sala: Node = au._cena.get_node("Sala")
		sala._revelar["speed_bag"] = true
		await au._esperar(0.25)
		au._exigir(not au._cena._convite.ativo(), "f7a2_balao_espera", "o balão deve esperar a caixa abrindo")
		sala._revelar.erase("speed_bag")
		await au._esperar(0.3)
		au._exigir(au._cena._convite.ativo(), "f7a2_balao_espera", "o balão volta quando a caixa termina")
		# Em cena, o balão não existe (convite escondido pelo estado, UI também).
		au._cena.cena_forcada = true
		await au._esperar(0.2)
		au._exigir(not au._cena._convite.ativo(), "f7a2_balao_espera", "em cena o balão do convite não aparece")
		au._cena.cena_forcada = false
		await au._esperar(0.2)
		await au._ver("f7a2_balao_espera")


func _choque(arte: String, tag: String) -> void:
	var p := "f7a2_choque_%s_" % tag
	if not _quer_prefixo(p):
		return
	var local := "gym"
	var k := 1
	# Começo: contagem PREPARAR.
	if au._quer(p + "comeco"):
		var tela: Node = await _entrar(p + "comeco", local, arte, "spar")
		if tela != null:
			_checar_hud(p + "comeco", tela)
			au._exigir(tela._centro.visible and tela._centro.text == au._txt("mini_ready"), p + "comeco", "a contagem mostra PREPARAR")
			au._exigir(tela._dica.text == au._txt("spar_tip_bjj" if arte == "bjj" else "spar_tip_boxing"), p + "comeco", "a dica de controle da arte")
			await au._ver(p + "comeco")
	# Meio do jogo: rajada, pausa, finta, fôlego baixo, ponto.
	for tipo in ["rajada", "pausa", "finta", "folego", "ponto"]:
		var nome: String = p + tipo
		if not au._quer(nome):
			continue
		var tela: Node = await _entrar(nome, local, arte, "spar")
		if tela == null:
			continue
		if k == 1:
			k = _achar_roteiro(arte)
		var j = _semear_choque(tela, arte, k)
		match tipo:
			"rajada":
				var r := _padrao(j, "burst")
				_ir(j, float(r.a) + 0.15 * (float(r.i) - float(r.a)))
				await au._esperar(0.05)
				au._exigir(tela._aviso_ico.visible and tela._aviso_txt.visible, nome, "o aviso da rajada aparece no parceiro")
				au._exigir(tela._aviso_txt.text == au._txt("spar_warn_pull" if arte == "bjj" else "spar_warn_burst"), nome, "texto do aviso da rajada")
			"pausa":
				var r := _padrao(j, "pause")
				_ir(j, float(r.i) + 0.12)
				await au._esperar(0.05)
				au._exigir(tela._x2.visible, nome, "o X2 aparece enquanto a pausa vale")
			"finta":
				var r := _padrao(j, "feint")
				_ir(j, float(r.a) + 0.62 * (float(r.i) - float(r.a)))
				await au._esperar(0.05)
				au._exigir(tela._aviso_ico.visible and tela._aviso_ico.nome_sprite == "ui_warn_feint", nome, "a finta usa o ícone dela")
			"folego":
				_ir(j, 0.0)
				if arte == "bjj":
					j.apertar()
					j.passo(5.5)  # segurando o tempo todo: o fôlego zera
				else:
					for i in 40:
						j.apertar()
						j.soltar()
						j.passo(0.05)
				await au._esperar(0.1)
				au._exigir(float(j.estado().folego) < 0.25, nome, "o fôlego ficou baixo (%.2f)" % float(j.estado().folego))
				au._exigir(tela._folego_frame == 2, nome, "a barra de fôlego fica vermelha")
			"ponto":
				_ir(j, 0.0)
				j.barra = 0.99
				j.apertar()
				j.soltar()
				j.barra = 1.3
				j.passo(0.04)
				await au._esperar(0.12)
				au._exigir(j.pontos >= 1, nome, "o jogador marcou um ponto")
		await au._ver(nome)
	# Prêmio: venceu (AQUECIDO) e, no Boxe, perdeu pelo SAIR.
	if au._quer(p + "premio"):
		var tela2: Node = await _entrar(p + "premio", local, arte, "spar")
		if tela2 != null:
			var j2 = _semear_choque(tela2, arte, 1)
			_ir(j2, 29.9)
			j2.barra = 0.0
			j2.pontos = 3
			j2.pontos_dele = 1
			j2.passo(0.5)
			await au._esperar(0.8)
			au._exigir(tela2.janela != null, p + "premio", "a tela de prêmio abre no fim")
			if tela2.janela != null:
				au._exigir(bool(tela2.premio.get("aquecido", false)), p + "premio", "vencer guarda o AQUECIDO")
			await au._ver(p + "premio")
	if tag == "boxe" and au._quer(p + "premio_derrota"):
		var tela3: Node = await _entrar(p + "premio_derrota", local, arte, "spar")
		if tela3 != null:
			var j3 = _semear_choque(tela3, arte, 1)
			_ir(j3, 6.0)
			j3.barra = 0.0
			j3.pontos = 1
			j3.pontos_dele = 2
			await au._esperar(0.1)
			tela3._botao_sair.pressed.emit()
			await au._esperar(0.8)
			au._exigir(tela3.janela != null and not bool(tela3.premio.get("venceu", true)), p + "premio_derrota", "SAIR leva o prêmio sem AQUECIDO")
			await au._ver(p + "premio_derrota")


## Sorteia um roteiro de rua e devolve o PanfletoLogica semeado (a tela troca o jogo por ele).
func _semear_panfleto(tela: Node, k: int) -> Variant:
	var r := RandomNumberGenerator.new()
	r.seed = k
	var j = load("res://scripts/minigame_panfleto.gd").new(au.gs.minigames.flyers, au.gs.indice_escada, r)
	au.gs._treino_jogo = j
	tela.jogo = j
	return j


func _panfleto() -> void:
	if not _quer_prefixo("f7a2_panfleto_"):
		return
	if au._quer("f7a2_panfleto_comeco"):
		var tela: Node = await _entrar("f7a2_panfleto_comeco", "garage", "boxing", "flyers")
		if tela != null:
			_checar_hud("f7a2_panfleto_comeco", tela)
			au._exigir(tela._centro.visible, "f7a2_panfleto_comeco", "a contagem mostra PREPARAR")
			au._exigir(tela._boato != null, "f7a2_panfleto_comeco", "a 1ª Panfletagem com o recorte visível traz o boato do Osmar")
			await au._ver("f7a2_panfleto_comeco")
	for nome in ["f7a2_panfleto_sinal", "f7a2_panfleto_aceitou", "f7a2_panfleto_erro"]:
		if not au._quer(nome):
			continue
		var tela: Node = await _entrar(nome, "garage", "boxing", "flyers")
		if tela == null:
			continue
		var j = _semear_panfleto(tela, 7)
		_ir_panfleto(j, 4.0)
		# Anda até haver alguém dando o sinal de verdade na rua.
		var alvo := {}
		for i in 400:
			for q in j.pessoas():
				if str(q.sinal) == "interesse" and not bool(q.resolvida):
					alvo = q
			if not alvo.is_empty():
				break
			j.passo(0.1)
		au._exigir(not alvo.is_empty(), nome, "achei alguém dando o sinal")
		await au._esperar(0.05)
		if nome == "f7a2_panfleto_sinal":
			au._exigir(not tela._vivos.is_empty() and tela._vivos.values().any(func(v: Dictionary) -> bool: return v.marca.visible), nome, "o ? aparece em quem dá o sinal")
		elif nome == "f7a2_panfleto_aceitou" and not alvo.is_empty():
			tela._ao_clique_mundo(_ponto_da_pessoa(alvo))
			au._exigir(j.aceitos == 1, nome, "clicar no sinal = ACEITOU")
		elif nome == "f7a2_panfleto_erro":
			var sem := {}
			for q in j.pessoas():
				if str(q.sinal) == "" and not bool(q.resolvida):
					sem = q
			au._exigir(not sem.is_empty(), nome, "achei alguém sem sinal para errar")
			if not sem.is_empty():
				tela._ao_clique_mundo(_ponto_da_pessoa(sem))
				au._exigir(j.erros == 1, nome, "clicar em quem não quer = erro")
		await au._ver(nome)
	if au._quer("f7a2_panfleto_premio"):
		var tela4: Node = await _entrar("f7a2_panfleto_premio", "garage", "boxing", "flyers")
		if tela4 != null:
			var j4 = _semear_panfleto(tela4, 7)
			_ir_panfleto(j4, 8.0)
			j4.aceitos = 6
			_ir_panfleto(j4, 40.0)
			await au._esperar(0.8)
			au._exigir(tela4.janela != null and int(tela4.premio.get("fama", 0)) > 0, "f7a2_panfleto_premio", "a tela de prêmio mostra a FAMA")
			await au._ver("f7a2_panfleto_premio")


func _ir_panfleto(j: Variant, t: float) -> void:
	if j.fase == "contagem":
		j.passo(2.05)
	if j.tempo < t:
		j.passo(t - j.tempo)


## Ponto da tela onde a pessoa está (o clique cai no meio do corpo).
func _ponto_da_pessoa(q: Dictionary) -> Vector2:
	var x := lerpf(-30.0, 670.0, float(q.x))
	var y := lerpf(292.0, 308.0, float(q.faixa))
	return Vector2(x, y - 30.0)


func _aquecido() -> void:
	if au._quer("f7a2_previa_aquecido"):
		au._estado = "f7a2_previa_aquecido"
		_preparar("gym", "boxing", "")
		au.gs.atributos = {"strength": 600.0, "agility": 450.0, "endurance": 500.0}
		au.gs.convite = {"room_s": 400.0, "next_at": 640.0, "open": "", "open_since": 0.0, "last": "spar", "warm": true}
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		var j: Node = au._cena.get_node("Fluxo").janela
		au._exigir(j != null and j._aquec != null, "f7a2_previa_aquecido", "a prévia mostra a linha do AQUECIDO")
		await au._ver("f7a2_previa_aquecido")
	if au._quer("f7a2_hud_aquecido"):
		au._estado = "f7a2_hud_aquecido"
		_preparar("gym", "boxing", "")
		au.gs.convite = {"room_s": 400.0, "next_at": 640.0, "open": "", "open_since": 0.0, "last": "spar", "warm": true}
		await au._abrir()
		await au._esperar(0.3)
		au._exigir(au._cena.get_node("Hud")._aquecido.visible, "f7a2_hud_aquecido", "o ícone do AQUECIDO aparece no HUD")
		await au._ver("f7a2_hud_aquecido")


func _recortes() -> void:
	for c in [["f7a2_recorte_garagem", "garage"], ["f7a2_recorte_academia", "gym"]]:
		if not au._quer(c[0]):
			continue
		au._estado = c[0]
		_preparar(c[1], "boxing", "")
		await au._abrir()
		await au._esperar(0.3)
		var sala: Node = au._cena.get_node("Sala")
		var r: Dictionary = au.gs.recorte_gato_preto()
		au._exigir(not r.is_empty(), c[0], "o recorte deveria existir (campanha 2+ com garage_saved)")
		au._exigir(sala._recorte.visible, c[0], "o recorte é desenhado na parede")
		if sala._recorte.visible:
			var ponto: Vector2 = sala._recorte_rect.get_center()
			sala._hover_em(ponto)
			var inst = au._dica_inst()
			inst.ancora_fixa = ponto + Vector2(30, 60)
			await au._esperar(0.15)
			au._exigir(sala._recorte_zoom != null and sala._recorte_zoom.visible, c[0], "a dica de zoom do recorte aparece")
		await au._ver(c[0])
		sala._sair_hover()
		au._sem_dica()
