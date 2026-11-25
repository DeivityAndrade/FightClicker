extends RefCounted
## Estados do ui_audit.gd: Ronda Noturna do Gato Preto. O capuz no prego (garagem, academia, centro; sem e com hover), a tela da Ronda
## (contagem, ladrão no AVISO, vulto PERTO, SUSTO!, ESCAPOU, SAIR), a tela de prêmio (sobe de nível, normal, nível máximo), VOLTAR devolvendo
## a sala, os recortes por nível da lenda (com zoom) e a região GATO PRETO no mapa (nó lacrado e nó comprado). Roda com o auditor `au`.
## Nos estados da noite o relógio do GameState é pausado (`set_process(false)`) e a lógica anda por `passo()` quadro a quadro, para o
## estado ser sempre o mesmo; a UI continua rodando normal.

const NOMES := [
	"ronda_capuz_garagem", "ronda_capuz_hover", "ronda_capuz_academia", "ronda_capuz_centro", "ronda_capuz_janela",
	"ronda_contagem", "ronda_aviso", "ronda_perto", "ronda_susto", "ronda_visto", "ronda_sair",
	"ronda_premio_sobe", "ronda_premio_normal", "ronda_premio_max", "ronda_premio_sem_susto", "ronda_voltar",
	"ronda_recorte_n1", "ronda_recorte_n3", "ronda_recorte_n5", "ronda_recorte_n5_zoom", "ronda_recorte_academia_n3",
	"ronda_mapa_lacrado", "ronda_mapa_aberto",
]
## Lenda de cada nível (RondaData.niveis = 1/12/30/52/80).
const LENDA_NIVEL := {0: 0, 1: 1, 2: 12, 3: 30, 4: 52, 5: 80}

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


func _sala() -> Node:
	return au._cena.get_node("Sala")


func _fluxo() -> Node:
	return au._cena.get_node("Fluxo")


## Carreira 3 com o boato ouvido, `lenda` pontos de lenda e o capuz no prego (direto no estado) no local pedido ("garage" | "gym" | "center").
func _montar(local: String, lenda: int, com_capuz: bool = true) -> void:
	au._novo_jogo()
	au.gs.risco_hud_ativo = false
	au.gs.baloes_escondidos = true
	au.gs.permanente["career_number"] = 3
	au.gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": 2, "version": 1}
	au.gs._gravar_marco("garage_saved", {}, false)  # o recorte do jornal pede a garagem salva (7a2)
	au.gs._gravar_marco("garage_saved_seen", {}, false)
	if local == "gym" or local == "center":
		au.gs._gravar_marco("cena_primeira_academia", {}, false)
		au._academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 800.0, "punching_bag", au.gs.lutas.adversarios.size())
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		au.gs.permanente["regional_belts"] = 1
		au.gs.permanente["first_regional_belt_campaign"] = 1
		au.gs.local_id = local
		if local == "center":
			au.gs.permanente["center_reached"] = true
	if lenda > 0:
		var nivel: int = au.gs.ronda_cfg.nivel_de(lenda)
		au.gs.permanente["black_cat"] = {"legend": lenda, "shown_level": nivel, "scares": lenda, "rounds": maxi(1, lenda / 3), "open_campaign": 3}
	au.gs._recalcular_bonus()
	if com_capuz:
		au.gs.capuz["hood_s"] = 200.0  # o capuz já está no prego (o relógio de 180 s é coberto por tests/test_ronda.gd)
		au.gs.capuz["open"] = au.gs._ronda._escolher_noite()
		au.gs._ronda.atualizar_visivel()


func _rodar_fim() -> void:
	au.gs.set_process(true)
	au.gs.baloes_escondidos = false


## Abre a Ronda pelo clique do capuz (o caminho real) e pausa o relógio do GameState: quem anda é a lógica, por `passo()`.
func _entrar() -> Node:
	var info: Dictionary = au.gs.capuz_info()
	au._exigir(bool(info.get("clickable", false)), au._estado, "o capuz está clicável (%s)" % str(info))
	_sala().capuz_clicado.emit()
	await au._esperar(0.3)
	au.gs.set_process(false)
	var tela = _fluxo().ronda
	au._exigir(tela != null and au.gs.ronda_jogo() != null, au._estado, "o clique no capuz abre a tela da Ronda")
	return tela


## Anda a lógica `s` segundos em quadros de 1/60 s.
func _andar(j, s: float, segurando: bool = false) -> void:
	var n := int(round(s * 60.0))
	for _i in n:
		j.passo(1.0 / 60.0, segurando, false)


## Até o ladrão avisar (AVISO), com o botão solto.
func _ate_aviso(j) -> void:
	for _i in 1200:
		var e: Dictionary = j.estado()
		if e.fase == "jogando" and e.oc_fase == "jogando" and e.ladrao == "aviso" and float(e.ladrao_frac) > 0.5:
			return
		j.passo(1.0 / 60.0, false, false)


## Segura o botão só enquanto o ladrão trabalha, até chegar PERTO.
func _ate_perto(j) -> void:
	for _i in 6000:
		var e: Dictionary = j.estado()
		if e.perto:
			return
		j.passo(1.0 / 60.0, e.ladrao == "trabalha" and float(e.distancia) < 0.95, false)


func _dentro_da_tela(r: Rect2) -> bool:
	return Rect2(0, 0, 640, 360).encloses(r)


## N1 do QA: nenhum pixel opaco do vulto (quadro atual da folha) sai da tela 0..640, com 4 px de folga.
func _conferir_vulto(t) -> void:
	var a: Sprite2D = t._vulto_anim
	if a == null or not a.visible or a.texture == null:
		return
	var img := a.texture.get_image()
	var fw := img.get_width() / maxi(a.hframes, 1)
	var x0 := fw
	var x1 := -1
	for x in fw:
		for y in img.get_height():
			if img.get_pixel(a.frame * fw + x, y).a > 0.1:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				break
	var base: float = a.get_global_transform().origin.x + a.offset.x
	var esq := base + float(x0)
	var dir := base + float(x1) + 1.0
	au._exigir(esq >= 4.0 and dir <= 636.0, au._estado, "o vulto fica dentro da tela (pose %s, quadro %d): pixel opaco de x %.0f a %.0f" % [t._pose_vulto_atual, a.frame, esq, dir])


func _rodar_fase_ronda() -> void:
	if not _alguma():
		return
	await _capuz()
	await _noite()
	await _premios()
	await _recortes()
	await _mapa()
	_rodar_fim()


# ---------------------------------------------------------------------------------------------
# Capuz no prego
# ---------------------------------------------------------------------------------------------

func _capuz() -> void:
	for q in [["ronda_capuz_garagem", "garage"], ["ronda_capuz_academia", "gym"], ["ronda_capuz_centro", "center"]]:
		if not au._quer(q[0]):
			continue
		_montar(q[1], 12)
		await au._abrir()
		au._estado = q[0]
		var sala := _sala()
		au._exigir(sala._capuz != null and sala._capuz.visible, au._estado, "o capuz está no prego")
		au._exigir(sala._capuz_rect.size != Vector2.ZERO and _dentro_da_tela(sala._capuz_rect), au._estado, "a área de clique do capuz cabe na tela: %s" % au._fmt(sala._capuz_rect))
		au._exigir(sala._capuz_dica(sala._capuz_rect.get_center()) != "", au._estado, "o hover do capuz tem texto")
		await au._ver(q[0])
	if au._quer("ronda_capuz_hover"):
		_montar("garage", 12)
		await au._abrir()
		au._estado = "ronda_capuz_hover"
		var sala2 := _sala()
		au._dica_inst().ancora_fixa = sala2._capuz_rect.get_center()  # sem mouse real a dica iria para (0,0): o mouse "está" no capuz
		sala2._hover_em(sala2._capuz_rect.get_center())
		await au._esperar(0.4)
		au._exigir(sala2._capuz.frame == 1, au._estado, "o capuz muda para o quadro 1 no hover")
		var tip: String = sala2._capuz_dica(sala2._capuz_rect.get_center())
		au._exigir(tip != "", au._estado, "o hover mostra o texto: %s" % tip)
		var dr: Rect2 = au._dica_inst().retangulo()
		au._exigir(dr.position.x >= 4.0 and dr.position.y >= 4.0 and dr.end.x <= 636.0 and dr.end.y <= 356.0, au._estado, "a dica fica a 4 px ou mais da borda: %s" % au._fmt(dr))
		await au._ver("ronda_capuz_hover")
	if au._quer("ronda_capuz_janela"):
		# Com uma janela aberta o capuz continua desenhado, mas sem hover e sem clique.
		_montar("garage", 12)
		await au._abrir()
		au._estado = "ronda_capuz_janela"
		_fluxo().abrir_previa()
		await au._esperar(0.5)
		var sala3 := _sala()
		au._exigir(sala3._capuz.visible, au._estado, "o capuz segue desenhado com a janela aberta")
		au._exigir(sala3._capuz_dica(sala3._capuz_rect.get_center()) == "", au._estado, "sem hover com a janela aberta")
		au._exigir(not bool(au.gs.capuz_info().get("clickable", true)), au._estado, "sem clique com a janela aberta")
		await au._ver("ronda_capuz_janela")


# ---------------------------------------------------------------------------------------------
# A noite
# ---------------------------------------------------------------------------------------------

func _noite() -> void:
	if not (au._quer("ronda_contagem") or au._quer("ronda_aviso") or au._quer("ronda_perto") or au._quer("ronda_susto") or au._quer("ronda_visto") or au._quer("ronda_sair")):
		return
	if au._quer("ronda_contagem"):
		_montar("garage", 0)
		await au._abrir()
		au._estado = "ronda_contagem"
		var t = await _entrar()
		await au._esperar(0.3)
		au._exigir(str(au.gs.ronda_jogo().fase) == "contagem", au._estado, "começa pela contagem")
		au._exigir(t != null and t._centro.visible and t._titulo.visible, au._estado, "PREPARAR e o título da noite aparecem")
		# A3: a contagem fica no céu, acima dos telhados e da placa 24H da borracharia (y 115 em diante na base).
		au._exigir(t._centro.get_global_rect().end.y <= 112.0 and t._titulo.get_global_rect().end.y <= 112.0, au._estado, "PREPARAR/título não pisam na placa 24H: %s %s" % [au._fmt(t._centro.get_global_rect()), au._fmt(t._titulo.get_global_rect())])
		_conferir_vulto(t)
		await au._ver("ronda_contagem")
		_rodar_fim()
	if au._quer("ronda_aviso"):
		_montar("garage", 12)
		await au._abrir()
		au._estado = "ronda_aviso"
		var t2 = await _entrar()
		var j = au.gs.ronda_jogo()
		_andar(j, 2.1)
		_ate_aviso(j)
		await au._esperar(0.3)
		au._exigir(t2 != null and t2._aviso.visible, au._estado, "o aviso aparece em cima do ladrão")
		au._exigir(t2._hud.get_global_rect().encloses(t2._rotulo_tempo.get_global_rect()), au._estado, "o tempo cabe no HUD")
		_conferir_vulto(t2)
		await au._ver("ronda_aviso")
		_rodar_fim()
	if au._quer("ronda_perto") or au._quer("ronda_susto"):
		_montar("garage", 30)
		await au._abrir()
		au._estado = "ronda_perto"
		var t3 = await _entrar()
		var j3 = au.gs.ronda_jogo()
		_andar(j3, 2.1)
		_andar(j3, 0.9)
		_ate_perto(j3)
		await au._esperar(0.3)
		au._exigir(t3 != null and t3._perto.visible, au._estado, "o SUSTO! pequeno pisca em cima do vulto")
		if au._quer("ronda_perto"):
			_conferir_vulto(t3)
			await au._ver("ronda_perto")
		if au._quer("ronda_susto"):
			au._estado = "ronda_susto"
			# Soltar e apertar: o aperto no PERTO é o SUSTO (com o ladrão trabalhando).
			j3.passo(1.0 / 60.0, false, false)
			j3.passo(1.0 / 60.0, true, true)
			au._exigir(int(j3.sustos) == 1, au._estado, "o aperto no PERTO deu o SUSTO (sustos %d, vistos %d)" % [j3.sustos, j3.vistos])
			await au._esperar(0.55)
			au._exigir(t3._banner_susto.visible, au._estado, "o letreiro SUSTO! aparece")
			_conferir_vulto(t3)
			await au._ver("ronda_susto")
		_rodar_fim()
	if au._quer("ronda_visto"):
		_montar("garage", 12)
		await au._abrir()
		au._estado = "ronda_visto"
		var t4 = await _entrar()
		var j4 = au.gs.ronda_jogo()
		_andar(j4, 3.0)
		for _i in 3000:
			if int(j4.vistos) > 0:
				break
			j4.passo(1.0 / 60.0, true, false)
		await au._esperar(0.3)
		au._exigir(int(j4.vistos) == 1, au._estado, "andou com o ladrão olhando: ESCAPOU")
		au._exigir(t4._banner_fugiu.visible, au._estado, "o letreiro ESCAPOU aparece")
		au._exigir(absf(t4._banner_fugiu.position.x - 320.0) <= 1.0, au._estado, "o letreiro ESCAPOU está no centro da tela (x %.0f)" % t4._banner_fugiu.position.x)
		_conferir_vulto(t4)
		await au._ver("ronda_visto")
		_rodar_fim()
	if au._quer("ronda_sair"):
		_montar("garage", 12)
		await au._abrir()
		au._estado = "ronda_sair"
		var t5 = await _entrar()
		_andar(au.gs.ronda_jogo(), 3.0)
		await au._esperar(0.2)
		au._exigir(t5._botao_sair.visible, au._estado, "o botão SAIR aparece")
		t5._botao_sair.pressed.emit()
		await au._esperar(0.8)
		au._exigir(t5.janela != null, au._estado, "SAIR mostra o prêmio")
		au._exigir(str(t5.premio.get("ended", "")) == "exit", au._estado, "o prêmio diz que saiu cedo")
		_conferir_vulto(t5)
		await au._ver("ronda_sair")
		_rodar_fim()


# ---------------------------------------------------------------------------------------------
# Prêmio
# ---------------------------------------------------------------------------------------------

func _fechar_noite(lenda: int, sustos: int, nome: String) -> Node:
	_montar("garage", lenda)
	await au._abrir()
	au._estado = nome
	var t = await _entrar()
	var j = au.gs.ronda_jogo()
	j.sustos = sustos
	j.fase = "fim"
	await au._esperar(0.9)
	au._exigir(t != null and t.janela != null, au._estado, "a tela de prêmio abre quando a noite acaba")
	if t != null and t.janela != null:
		var r: Rect2 = t.janela.painel.get_global_rect() if t.janela.painel != null else Rect2()
		au._exigir(_dentro_da_tela(r), au._estado, "a janela do prêmio cabe na tela: %s" % au._fmt(r))
		_conferir_margens_vertical(t.janela.painel)
	return t


## A1 do QA: a janela do prêmio tem de ter a mesma folga em cima (borda ao primeiro conteúdo) e embaixo (último conteúdo à borda), ±2 px.
func _conferir_margens_vertical(painel: Control) -> void:
	var moldura: Control = null
	for c in painel.get_children():
		if c is Control and (moldura == null or (c as Control).size.x * (c as Control).size.y > moldura.size.x * moldura.size.y):
			moldura = c
	if moldura == null:
		return
	var topo := INF
	var fundo := -INF
	for c in painel.get_children():
		if c == moldura or not (c is Control) or not (c as Control).visible:
			continue
		var r: Rect2 = (c as Control).get_global_rect()
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			continue
		topo = minf(topo, r.position.y)
		fundo = maxf(fundo, r.end.y)
	var mr: Rect2 = moldura.get_global_rect()
	var em_cima := topo - mr.position.y
	var embaixo := mr.end.y - fundo
	# Tema C: o título fica colado no topo da moldura (cima ~2 px) e o botão de baixo segue o padrão
	# das janelas (12 ± 2 px até a borda interna, o mesmo que FOLGA_VIZINHO exige).
	au._exigir(em_cima >= 0.0 and em_cima <= 4.0, au._estado, "título colado no topo da moldura (0–4 px): cima %.0f" % em_cima)
	au._exigir(absf(embaixo - 15.0) <= 2.0, au._estado, "botão de baixo no padrão das janelas (12 ± 2 px + 3 de sombra): baixo %.0f" % embaixo)


func _premios() -> void:
	if au._quer("ronda_premio_sobe"):
		var t = await _fechar_noite(0, 3, "ronda_premio_sobe")
		au._exigir(t != null and bool(t.premio.get("level_up", false)), au._estado, "a primeira ronda sobe a lenda ao nível 1")
		await au._ver("ronda_premio_sobe")
		if true:
			await au._esperar(0.3)
			t.janela.voltar_pedido.emit()
			await au._esperar(0.4)
			au._estado = "ronda_voltar"
			au._exigir(au.gs.ronda_ativa == "" and _fluxo().ronda == null, au._estado, "VOLTAR fecha a tela da Ronda")
			au._exigir(au.gs.sala_ativa(), au._estado, "VOLTAR devolve a sala")
			au._exigir(au.gs.capuz_visivel() == "" and not _sala()._capuz.visible, au._estado, "o prego fica vazio")
			if au._quer("ronda_voltar"):
				au.gs.set_process(true)
				await au._esperar(0.2)
				await au._ver("ronda_voltar")
		_rodar_fim()
	if au._quer("ronda_voltar") and not au._quer("ronda_premio_sobe"):
		var t2 = await _fechar_noite(0, 2, "ronda_voltar")
		await au._esperar(0.3)
		t2.janela.voltar_pedido.emit()
		await au._esperar(0.4)
		au._exigir(au.gs.ronda_ativa == "" and _fluxo().ronda == null and au.gs.sala_ativa(), au._estado, "VOLTAR devolve a sala")
		au.gs.set_process(true)
		await au._esperar(0.2)
		await au._ver("ronda_voltar")
		_rodar_fim()
	if au._quer("ronda_premio_normal"):
		await _fechar_noite(12, 2, "ronda_premio_normal")
		await au._ver("ronda_premio_normal")
		_rodar_fim()
	if au._quer("ronda_premio_sem_susto"):
		await _fechar_noite(12, 0, "ronda_premio_sem_susto")
		await au._ver("ronda_premio_sem_susto")
		_rodar_fim()
	if au._quer("ronda_premio_max"):
		var t3 = await _fechar_noite(85, 3, "ronda_premio_max")
		au._exigir(t3 != null and bool(t3.premio.get("max_level", false)), au._estado, "nível 5: o prêmio mostra as OCORRÊNCIAS")
		await au._ver("ronda_premio_max")
		_rodar_fim()


# ---------------------------------------------------------------------------------------------
# Recortes por nível da lenda
# ---------------------------------------------------------------------------------------------

func _recorte(nome: String, local: String, nivel: int, zoom: bool = false) -> void:
	_montar(local, int(LENDA_NIVEL[nivel]), false)
	await au._abrir()
	await au._esperar(0.3)
	au._estado = nome
	var sala := _sala()
	au._exigir(sala._recorte.visible and sala._recorte_rect.size != Vector2.ZERO, au._estado, "o recorte está na parede")
	var esperado := "wall_clipping_black_cat%s_l%d" % ["_gym" if local == "gym" else "", nivel]
	au._exigir(str(sala._recorte.nome_sprite) == esperado, au._estado, "o recorte do nível %d usa %s (%s)" % [nivel, esperado, str(sala._recorte.nome_sprite)])
	var tip: String = sala._texto_parede(sala._recorte_rect.get_center())
	au._exigir(tip != "", au._estado, "o hover traz a manchete: %s" % tip)
	if nivel >= 1:
		au._exigir(tip.contains("GATO PRETO"), au._estado, "do nível 1 em diante a manchete tem o nome: %s" % tip)
	if zoom:
		au._dica_inst().ancora_fixa = sala._recorte_rect.get_center()  # o mouse "está" no recorte
		sala._hover_em(sala._recorte_rect.get_center())
		await au._esperar(0.4)
		au._exigir(sala._recorte_zoom != null and sala._recorte_zoom.visible, au._estado, "o zoom do recorte aparece")
		if sala._recorte_zoom != null:
			var rz: Rect2 = sala._recorte_zoom.get_global_rect()
			au._exigir(_dentro_da_tela(rz), au._estado, "o zoom cabe na tela: %s" % au._fmt(rz))
			au._exigir(not rz.intersects(Rect2(310, 180, 52, 94)), au._estado, "o zoom não cobre a zona do alvo: %s" % au._fmt(rz))
	await au._ver(nome)


func _recortes() -> void:
	if au._quer("ronda_recorte_n1"):
		await _recorte("ronda_recorte_n1", "garage", 1)
	if au._quer("ronda_recorte_n3"):
		await _recorte("ronda_recorte_n3", "garage", 3)
	if au._quer("ronda_recorte_n5"):
		await _recorte("ronda_recorte_n5", "garage", 5)
	if au._quer("ronda_recorte_n5_zoom"):
		await _recorte("ronda_recorte_n5_zoom", "garage", 5, true)
	if au._quer("ronda_recorte_academia_n3"):
		await _recorte("ronda_recorte_academia_n3", "gym", 3)


# ---------------------------------------------------------------------------------------------
# Mapa: região GATO PRETO
# ---------------------------------------------------------------------------------------------

func _mapa() -> void:
	if not _quer_prefixo("ronda_mapa_"):
		return
	if au._quer("ronda_mapa_lacrado"):
		_montar("garage", 1, false)
		au._f54_f6a._com_nos54(["body_jab", "cat_rooftop"], 900)
		var j: Node = await au._f54_f6a._abrir_arvore()
		au._estado = "ronda_mapa_lacrado"
		au._exigir(au._eh(j, "JanelaMapa"), au._estado, "o mapa abre")
		if au._eh(j, "JanelaMapa"):
			j.ir_para("cat_watch")
			await au._esperar(0.5)
			au._exigir("cat_watch" in j.nos_desenhados(), au._estado, "o nó lacrado está desenhado")
			au._exigir("black_cat" in j.placas_desenhadas(), au._estado, "a plaquinha GATO PRETO aparece (%s)" % str(j.placas_desenhadas()))
			j.clicar_no("cat_watch")  # clicar no lacrado só treme; o cartão vem do hover
			j.mostrar_cartao("cat_watch")
			await au._esperar(0.4)
			au._exigir(j.cartao_aberto() == "cat_watch", au._estado, "o cartão do nó lacrado abre")
		await au._ver("ronda_mapa_lacrado")
	if au._quer("ronda_mapa_aberto"):
		_montar("garage", 30, false)
		au._f54_f6a._com_nos54(["body_jab", "cat_rooftop"], 900)
		var j2: Node = await au._f54_f6a._abrir_arvore()
		au._estado = "ronda_mapa_aberto"
		au._exigir(au._eh(j2, "JanelaMapa"), au._estado, "o mapa abre")
		if au._eh(j2, "JanelaMapa"):
			j2.ir_para("cat_rooftop")
			await au._esperar(0.5)
			for id in ["cat_rooftop", "cat_watch", "cat_thanks"]:
				au._exigir(id in j2.nos_desenhados(), au._estado, "o nó %s está desenhado" % id)
			au._exigir("black_cat" in j2.placas_desenhadas(), au._estado, "a plaquinha GATO PRETO aparece")
		await au._ver("ronda_mapa_aberto")
