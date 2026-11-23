extends RefCounted
## Estados do ui_audit.gd: Fase 8a2 (centro de treinamento): cartão da mudança (apagado / pronto / sem cartão antes do James), a chegada
## (sem cena, fala do Osmar), a sala do centro cheia com cada arte (Boxe, Jiu-jitsu, Muay Thai) e a chegada vazia, a aba EQUIPE com os
## Alunos da Raízes e o cartão do aparelho com a 5ª melhoria, o envelope PROPOSTA no chão e o contrato (ASSINAR / AGORA NÃO), a vitória
## com a linha do patrocínio (normal, cinturão amador e Cinturão do Vale), a marca no calção, o cartaz vencido (sem e com a marca, com
## zoom), a academia de Boxe sem a pera por cima do cartaz, o recorte emoldurado no centro (com zoom) e o mapa com a região CENTRO
## fechada e aberta. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const NOMES := [
	"f8a2_mudar_travado", "f8a2_mudar_faltando", "f8a2_mudar_pronto", "f8a2_chegada", "f8a2_chegada_falou",
	"f8a2_centro_chegada_mt", "f8a2_centro_cheia_boxe", "f8a2_centro_cheia_jj", "f8a2_centro_cheia_mt", "f8a2_centro_cheia_boxe_fechado",
	"f8a2_equipe_alunos", "f8a2_equipe_alunos_fundo", "f8a2_aparelho_5a", "f8a2_aparelho_5a_maximo", "f8a2_academia_sem_5a",
	"f8a2_envelope_garagem", "f8a2_envelope_academia", "f8a2_envelope_centro", "f8a2_envelope_aviso", "f8a2_contrato", "f8a2_contrato_assinado",
	"f8a2_contrato_agora_nao",
	"f8a2_vitoria_bonus", "f8a2_vitoria_bonus_cinturao", "f8a2_vitoria_bonus_james", "f8a2_vitoria_sem_contrato",
	"f8a2_calcao_marca", "f8a2_calcao_sem_marca",
	"f8a2_cartaz_vencido", "f8a2_cartaz_vencido_marca", "f8a2_cartaz_vencido_zoom", "f8a2_cartaz_vencido_zoom_marca",
	"f8a2_academia_boxe_pera", "f8a2_recorte_centro", "f8a2_recorte_centro_zoom", "f8a2_foto_centro",
	"f8a2_mapa_centro_fechado", "f8a2_mapa_centro_aberto", "f8a2_fim_retire_centro",
]
const ZONA_ALVO := Rect2(273, 150, 98, 142)

var au


func _init(auditor) -> void:
	au = auditor


func _tema() -> GDScript:
	return load("res://ui/ui_tema.gd")


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


func _aparelhos(arte: String) -> Array:
	match arte:
		"bjj":
			return ["treadmill", "jump_rope", "grappling_dummy"]
		"muay_thai":
			return ["treadmill", "jump_rope", "kick_bag"]
	return ["treadmill", "jump_rope", "speed_bag"]


## Carreira que já venceu o James (escada completa, Cinturão do Vale na linhagem), na academia ("gym") ou no centro ("center").
## `treino` alto para a 5ª melhoria (150M / 250M) ser comprável; `alunos` = quantidade de Alunos da Raízes.
func _montar(arte: String, local: String, dinheiro: float, alunos: int = 0, treino: float = 4.0e8, foco: String = "punching_bag") -> void:
	au._novo_jogo()
	au._academia(arte, _aparelhos(arte), treino, foco, au.gs.lutas.adversarios.size())
	au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	au.gs.permanente["regional_belts"] = 1
	au.gs.permanente["first_regional_belt_campaign"] = 1
	au.gs.permanente["career_number"] = 2
	au.gs.local_id = local
	if local == "center":
		au.gs.permanente["center_reached"] = true
	au.gs.dinheiro = dinheiro
	au.gs.risco_hud_ativo = false
	for g in au.gs.dados.geradores:
		au.gs.geradores[g.id] = 30
	if alunos > 0:
		au.gs.geradores["center_students"] = alunos
	au.gs._academia._atualizar_passiva()
	au.gs._recalcular_bonus()


func _no_painel_x() -> float:
	return au._cena.get_node("PainelLoja").get_node("Corpo").position.x


func _com_quatro_melhorias() -> void:
	for ap in au.gs.dados.todos_aparelhos():
		au.gs.niveis_melhoria[ap.id] = 4


func _rodar_fase8a2() -> void:
	if not _alguma():
		return
	await _mudanca()
	await _centro()
	await _equipe_e_aparelhos()
	await _contrato()
	await _vitorias()
	await _calcao()
	await _cartaz_e_recorte()
	await _mapa()
	await _fim()


# ---------------------------------------------------------------------------------------------
# Cartão da mudança e chegada
# ---------------------------------------------------------------------------------------------

func _cartao_texto(j: Node) -> String:
	var t := ""
	for l in j.find_children("*", "Label", true, false):
		if l.visible and str(l.text) != "":
			t += str(l.text).replace("\n", " / ") + " | "
	return t


func _mudanca() -> void:
	if au._quer("f8a2_mudar_travado"):
		# Academia, James ainda de pé (escada no Sabão): o MUDAR do centro não existe.
		au._novo_jogo()
		au._academia("boxing", _aparelhos("boxing"), 800.0, "punching_bag", 8)
		au.gs.dinheiro = 90000.0
		await au._abrir()
		au._estado = "f8a2_mudar_travado"
		au._exigir(au.gs.estado_mudanca() == "none" or au.gs.estado_mudanca() == "locked", au._estado, "antes do James o estado da mudança é travado (%s)" % au.gs.estado_mudanca())
		au._exigir(au._botao_mudar() == null, au._estado, "antes do James não existe botão MUDAR")
		await au._ver("f8a2_mudar_travado")
	for q in [["f8a2_mudar_faltando", 10000.0, "missing"], ["f8a2_mudar_pronto", 40000.0, "ready"]]:
		if not au._quer(q[0]):
			continue
		_montar("boxing", "gym", float(q[1]))
		await au._abrir()
		au._estado = q[0]
		var m: Dictionary = au.gs.mudanca()
		au._exigir(str(m.get("state", "")) == q[2], au._estado, "estado da mudança %s (esperava %s)" % [str(m.get("state", "")), q[2]])
		var b: Button = au._botao_mudar()
		au._exigir(b != null, au._estado, "o botão MUDAR do centro existe")
		if b != null:
			au._exigir(b.disabled == (q[2] == "missing"), au._estado, "botão %s" % ("apagado" if q[2] == "missing" else "aceso"))
			var cartao := b.get_parent()
			var t := _cartao_texto(cartao)
			au._exigir(t.contains("CENTRO RAÍZES") and t.contains("ALUNOS NOVOS"), au._estado, "o cartão diz o centro e os alunos novos: %s" % t)
			if q[2] == "missing":
				au._exigir(t.contains("FALTA"), au._estado, "o cartão apagado diz quanto falta: %s" % t)
		var bloco: Node = au._cena.get_node("PainelProxima")
		var tp := _cartao_texto(bloco)
		au._exigir(tp.contains("MUDE PARA O CENTRO"), au._estado, "o título do HUD é MUDE PARA O CENTRO: %s" % tp)
		au._exigir(tp.contains("SEM LUTA NOVA"), au._estado, "o aviso SEM LUTA NOVA POR ENQUANTO aparece: %s" % tp)
		await au._ver(q[0])
	if au._quer("f8a2_chegada") or au._quer("f8a2_chegada_falou"):
		_montar("boxing", "gym", 40000.0)
		await au._abrir()
		au._estado = "f8a2_chegada"
		au.gs._ultimo_comentario = -1000.0  # o intervalo de 60 s entre comentários não vale no teste: a fala da chegada sai
		var b2: Button = au._botao_mudar()
		au._exigir(b2 != null and not b2.disabled, au._estado, "o MUDAR está aceso")
		if b2 != null:
			b2.pressed.emit()
		await au._esperar(0.45)
		au._exigir(au.gs.no_centro() and au.gs.local_id == "center", au._estado, "mudou para o centro")
		au._exigir(au.gs.cena_sala == "", au._estado, "a chegada ao centro não toca cena")
		au._exigir(au.gs.marco("center_arrival"), au._estado, "o marco center_arrival foi gravado")
		au._exigir(au.gs.dinheiro >= 15000.0 and au.gs.dinheiro <= 15001.0, au._estado, "pagou $25.000 (sobra %s)" % str(au.gs.dinheiro))
		au._exigir(au._botao_mudar() == null, au._estado, "depois da chegada o cartão da mudança some")
		if au._quer("f8a2_chegada"):
			await au._ver("f8a2_chegada")
		if au._quer("f8a2_chegada_falou"):
			au._estado = "f8a2_chegada_falou"
			var guarda := 0.0
			while not (au._balao().ativo()) and guarda < 14.0:
				await au._esperar(0.2)
				guarda += 0.2
			au._exigir(au._balao().ativo(), au._estado, "o Osmar fala na chegada (balão aberto)")
			if au._balao().ativo():
				au._balao().completar()
				await au._esperar(0.2)
				au._exigir(str(au._balao().speaker) == "coach", au._estado, "quem fala é o Osmar (%s)" % str(au._balao().speaker))
				au._exigir(Rect2(0, 0, 640, 360).encloses(au._balao().retangulo_total()), au._estado, "o balão cabe na tela")
			await au._ver("f8a2_chegada_falou")


# ---------------------------------------------------------------------------------------------
# A sala do centro
# ---------------------------------------------------------------------------------------------

func _conferir_centro(nome: String, alunos_esperados: int) -> void:
	au._estado = nome
	var sala := _sala()
	au._exigir(str(sala._bg_nome) == "center_bg", nome, "o fundo é o do centro (%s)" % str(sala._bg_nome))
	au._exigir(not sala._lampada.visible, nome, "no centro a lâmpada da garagem não aparece")
	var vis := 0
	for d in sala._pessoas.get("center_students", []):
		if bool(d.sprite.visible):
			vis += 1
	au._exigir(vis == alunos_esperados, nome, "%d alunos desenhados (esperava %d)" % [vis, alunos_esperados])
	au._exigir(au.gs.texto_hud_local() == "TREINO x4", nome, "HUD do treino: %s" % au.gs.texto_hud_local())
	for ap in au.gs.aparelhos_da_carreira():
		var id := str(ap.id)
		if au.gs.aparelho_montado(id):
			var nome_sprite: String = sala._anim_do(id).nome_sprite
			au._exigir(nome_sprite.ends_with("_center"), nome, "%s usa a versão do centro (%s)" % [id, nome_sprite])
	au._exigir(not sala._cartaz.visible, nome, "o cartaz da liga não aparece no centro")


func _centro() -> void:
	if not _quer_prefixo("f8a2_centro_"):
		return
	var casos := [
		["f8a2_centro_chegada_mt", "muay_thai", 1, "fixo", "kick_bag"],
		["f8a2_centro_cheia_boxe", "boxing", 25, "fixo", "punching_bag"],
		["f8a2_centro_cheia_jj", "bjj", 25, "fixo", "punching_bag"],
		["f8a2_centro_cheia_mt", "muay_thai", 25, "solto", "punching_bag"],
		["f8a2_centro_cheia_boxe_fechado", "boxing", 12, "fechado", "treadmill"],
	]
	for c in casos:
		if not au._quer(c[0]):
			continue
		_montar(str(c[1]), "center", 31000.0, int(c[2]), 4.0e8, str(c[4]))
		au.painel_modo = "fechado" if c[3] == "fechado" else "fixo"
		await au._abrir()
		await au._esperar(0.4)
		var esperado := 4 if int(c[2]) >= 25 else (3 if int(c[2]) >= 12 else (2 if int(c[2]) >= 5 else 1))
		_conferir_centro(c[0], esperado)
		await au._ver(c[0])
	au.painel_modo = "fixo"


# ---------------------------------------------------------------------------------------------
# Aba EQUIPE e cartão do aparelho com a 5ª melhoria
# ---------------------------------------------------------------------------------------------

func _equipe_e_aparelhos() -> void:
	if not (_quer_prefixo("f8a2_equipe_") or _quer_prefixo("f8a2_aparelho_") or au._quer("f8a2_academia_sem_5a")):
		return
	if au._quer("f8a2_equipe_alunos") or au._quer("f8a2_equipe_alunos_fundo"):
		_montar("boxing", "center", 31000.0, 3, 6.0e6)
		_com_quatro_melhorias()
		au.painel_modo = "fixo"
		await au._abrir()
		var loja: Node = au._cena.get_node("PainelLoja")
		loja.abrir("treino", false)
		await au._esperar(0.4)
		au._estado = "f8a2_equipe_alunos"
		var cartao: Control = loja._gens["center_students"].cartao
		au._exigir(cartao.visible, au._estado, "o cartão dos Alunos da Raízes aparece na aba EQUIPE do centro")
		au._exigir(str(loja._gens["center_students"].qtd.text) == "X3", au._estado, "a quantidade mostra X3 (%s)" % str(loja._gens["center_students"].qtd.text))
		au._exigir(bool(loja._gens["center_students"].pode), au._estado, "com $0 de Treino sobrando 6M dá para chamar o próximo aluno")
		au._exigir(loja._rot_melhorias.position.y > cartao.position.y, au._estado, "o título MELHORIAS vem depois do cartão dos alunos")
		if au._quer("f8a2_equipe_alunos"):
			await au._ver("f8a2_equipe_alunos")
		if au._quer("f8a2_equipe_alunos_fundo"):
			au._estado = "f8a2_equipe_alunos_fundo"
			loja._rolar_a(9999.0)
			await au._esperar(0.3)
			await au._ver("f8a2_equipe_alunos_fundo")
	if au._quer("f8a2_aparelho_5a") or au._quer("f8a2_aparelho_5a_maximo"):
		_montar("boxing", "center", 31000.0, 3, 4.0e8)
		_com_quatro_melhorias()
		au.painel_modo = "fixo"
		await au._abrir()
		var loja2: Node = au._cena.get_node("PainelLoja")
		loja2.abrir("treino", false)
		await au._esperar(0.3)
		au._estado = "f8a2_aparelho_5a"
		var item: Dictionary = loja2._ups["punching_bag"]
		au._exigir(str(item.nivel.text) == "4/5", au._estado, "o saco mostra 4/5 no centro (%s)" % str(item.nivel.text))
		au._exigir(str(item.efeito.text).contains("X3") or str(item.efeito.text).contains("x3"), au._estado, "a 5ª melhoria é x3 (%s)" % str(item.efeito.text))
		au._exigir(bool(item.pode), au._estado, "com 400M de Treino a 5ª melhoria (150M) é comprável")
		loja2._rolar_para(item.cartao)
		await au._esperar(0.3)
		if au._quer("f8a2_aparelho_5a"):
			await au._ver("f8a2_aparelho_5a")
		if au._quer("f8a2_aparelho_5a_maximo"):
			au._estado = "f8a2_aparelho_5a_maximo"
			au._exigir(au.gs.comprar_melhoria("punching_bag"), au._estado, "comprou a 5ª melhoria do saco")
			loja2.atualizar()
			await au._esperar(0.4)
			au._exigir(str(loja2._ups["punching_bag"].nivel.text) == "5/5", au._estado, "o saco mostra 5/5 (%s)" % str(loja2._ups["punching_bag"].nivel.text))
			await au._ver("f8a2_aparelho_5a_maximo")
	if au._quer("f8a2_academia_sem_5a"):
		_montar("boxing", "gym", 31000.0, 0, 4.0e8)
		_com_quatro_melhorias()
		au.painel_modo = "fixo"
		await au._abrir()
		var loja3: Node = au._cena.get_node("PainelLoja")
		loja3.abrir("treino", false)
		await au._esperar(0.3)
		au._estado = "f8a2_academia_sem_5a"
		au._exigir(str(loja3._ups["punching_bag"].nivel.text) == "4/4", au._estado, "na academia o saco continua em 4/4 (%s)" % str(loja3._ups["punching_bag"].nivel.text))
		au._exigir(not loja3._gens["center_students"].cartao.visible, au._estado, "na academia não existe o cartão dos alunos")
		await au._ver("f8a2_academia_sem_5a")


# ---------------------------------------------------------------------------------------------
# Envelope PROPOSTA e contrato
# ---------------------------------------------------------------------------------------------

func _com_oferta(local: String, estado: String = "offered") -> void:
	_montar("boxing", local, 3000.0, 4 if local == "center" else 0, 4.0e8)
	au.gs.fama = 210
	au.gs.patrocinio_estado = estado
	if local == "garage":  # a garagem de uma campanha comum (a escada ainda no começo), sem o cartão da mudança
		au.gs.indice_escada = 2
		au.gs.cinturao = false


func _envelope_conferir(nome: String) -> void:
	au._estado = nome
	var sala := _sala()
	au._exigir(sala._envelope.visible and sala._envelope_rect.size != Vector2.ZERO, nome, "o envelope PROPOSTA está no chão")
	if sala._envelope.visible:
		var r: Rect2 = sala._envelope_rect
		au._exigir(not r.intersects(ZONA_ALVO), nome, "o envelope não está na zona do alvo: %s" % au._fmt(r))
		au._exigir(Rect2(0, 18, 640, 312).encloses(r), nome, "o envelope cabe na sala: %s" % au._fmt(r))
	sala._hover_em(sala._envelope_rect.get_center())
	await au._esperar(0.3)


func _contrato() -> void:
	if not (_quer_prefixo("f8a2_envelope_") or _quer_prefixo("f8a2_contrato")):
		return
	for q in [["f8a2_envelope_garagem", "garage"], ["f8a2_envelope_academia", "gym"], ["f8a2_envelope_centro", "center"]]:
		if not au._quer(q[0]):
			continue
		_com_oferta(str(q[1]))
		await au._abrir()
		await _envelope_conferir(q[0])
		await au._ver(q[0])
	if au._quer("f8a2_envelope_aviso"):
		_com_oferta("center", "")
		await au._abrir()
		var sala_a := _sala()
		au._estado = "f8a2_envelope_aviso"
		au._exigir(not sala_a._envelope.visible, au._estado, "antes da proposta não há envelope")
		au.gs.fama = 215
		au._exigir(au.gs._centro.avaliar_oferta(), au._estado, "a fama de 215 faz a proposta chegar")
		await au._esperar(0.5)
		au._exigir(sala_a._envelope.visible and sala_a._envelope.esta_tocando(), au._estado, "o envelope aparece piscando")
		var achou := false
		for nn in sala_a._numeros:
			if nn.has_method("ativo") and nn.ativo():
				achou = true
		au._exigir(au.gs.acoes_bloqueadas() == false, au._estado, "o aviso não bloqueia o treino")
		await au._ver("f8a2_envelope_aviso")
	if _quer_prefixo("f8a2_contrato"):
		_com_oferta("center")
		await au._abrir()
		var sala := _sala()
		var fluxo: Node = au._cena.get_node("Fluxo")
		if au._quer("f8a2_contrato") or au._quer("f8a2_contrato_assinado") or au._quer("f8a2_contrato_agora_nao"):
			au._estado = "f8a2_contrato"
			var c: Vector2 = sala._envelope_rect.get_center()
			au._mouse(c, true)
			au._mouse(c, false)
			await au._esperar(0.5)
			au._exigir(au._eh(fluxo.janela, "JanelaPatrocinio"), au._estado, "clicar no envelope abre o contrato")
			if au._eh(fluxo.janela, "JanelaPatrocinio"):
				var j: Node = fluxo.janela
				if au._quer("f8a2_contrato"):
					await au._ver("f8a2_contrato")
				if au._quer("f8a2_contrato_agora_nao"):
					au._estado = "f8a2_contrato_agora_nao"
					j._botao_nao.pressed.emit()
					await au._esperar(0.4)
					au._exigir(fluxo.janela == null, au._estado, "AGORA NÃO fecha a janela")
					au._exigir(au.gs.patrocinio_estado == "offered", au._estado, "AGORA NÃO não assina (estado %s)" % au.gs.patrocinio_estado)
					au._exigir(sala._envelope.visible, au._estado, "o envelope continua no chão depois de AGORA NÃO")
					await au._ver("f8a2_contrato_agora_nao")
					# O mesmo envelope abre o contrato de novo.
					au._mouse(c, true)
					au._mouse(c, false)
					await au._esperar(0.5)
					au._exigir(au._eh(fluxo.janela, "JanelaPatrocinio"), au._estado, "o envelope abre o contrato de novo")
				if au._quer("f8a2_contrato_assinado") and au._eh(fluxo.janela, "JanelaPatrocinio"):
					au._estado = "f8a2_contrato_assinado"
					fluxo.janela._botao_sim.pressed.emit()
					await au._esperar(0.45)
					au._exigir(au.gs.patrocinio_estado == "signed", au._estado, "ASSINAR grava o contrato (estado %s)" % au.gs.patrocinio_estado)
					au._exigir(not sala._envelope.visible, au._estado, "assinado, o envelope sai do chão")
					await au._ver("f8a2_contrato_assinado")
					await au._esperar(1.2)
					au._exigir(fluxo.janela == null, au._estado, "a janela fecha sozinha depois do carimbo")


# ---------------------------------------------------------------------------------------------
# Vitória com a linha do patrocínio
# ---------------------------------------------------------------------------------------------

## Vitória real contra `idx` (assinado ou não) na academia; abre a janela de vitória.
func _vitoria(nome: String, idx: int, assinado: bool) -> Node:
	_montar("boxing", "gym", 3000.0, 0, 800.0)
	au.gs.indice_escada = idx
	au.gs.cinturao = idx > 5
	au.gs.fama = 210
	au.gs.patrocinio_estado = "signed" if assinado else "offered"
	au.gs._escola._gravar_marco("garage_saved", {}, false)  # a garagem já foi salva numa campanha antiga: a linha GARAGEM SALVA não vem junto
	var achada: Dictionary = au._f8a1._buscar(idx, "aggressive", func(r: Dictionary) -> bool: return bool(r.win), [[1.5, 1.5, 1.5], [1.2, 1.2, 1.2], [1.0, 1.0, 1.0], [3.0, 3.0, 3.0]])
	if achada.is_empty():
		au._problema("AUDIT", "estado " + nome, "não achei uma vitória contra o adversário %d" % idx)
		return null
	au.gs.atributos = achada.atr.duplicate()
	au.gs.definir_tatica("aggressive")
	au.gs.rng.seed = int(achada.k)
	au.gs.lutar()
	var resumo: Dictionary = au.gs.concluir_luta()
	await au._abrir()
	au._estado = nome
	au._exigir(bool(resumo.get("win", false)), nome, "a luta montada é uma vitória")
	if assinado:
		au._exigir(int(resumo.get("sponsor_money", 0)) > 0, nome, "o resumo traz sponsor_money (%s)" % str(resumo.get("sponsor_money", 0)))
	else:
		au._exigir(not resumo.has("sponsor_money"), nome, "sem contrato assinado o resumo não traz sponsor_money")
	var fluxo: Node = au._cena.get_node("Fluxo")
	fluxo._fechar_tudo()
	fluxo._abrir_vitoria(resumo, false)
	await au._esperar(1.1)
	var jv: Node = fluxo.janela
	au._exigir(au._eh(jv, "JanelaVitoria"), nome, "a janela de vitória abre")
	if assinado and jv != null:
		var achou := false
		for l in jv.find_children("*", "Label", true, false):
			if str(l.text).begins_with("PATROCÍNIO VALE FORTE: +$"):
				achou = true
		au._exigir(achou, nome, "a janela mostra a linha PATROCÍNIO VALE FORTE: +$n")
	return jv


func _vitorias() -> void:
	if not _quer_prefixo("f8a2_vitoria_"):
		return
	if au._quer("f8a2_vitoria_bonus"):
		var j1: Node = await _vitoria("f8a2_vitoria_bonus", 7, true)
		if j1 != null:
			await au._ver("f8a2_vitoria_bonus")
	if au._quer("f8a2_vitoria_sem_contrato"):
		var j2: Node = await _vitoria("f8a2_vitoria_sem_contrato", 7, false)
		if j2 != null:
			await au._ver("f8a2_vitoria_sem_contrato")
	if au._quer("f8a2_vitoria_bonus_cinturao"):
		var ib := 0
		for i in au.gs.lutas.adversarios.size():
			if bool(au.gs.lutas.adversarios[i].belt):
				ib = i
		var j3: Node = await _vitoria("f8a2_vitoria_bonus_cinturao", ib, true)
		if j3 != null:
			await au._ver("f8a2_vitoria_bonus_cinturao")
	if au._quer("f8a2_vitoria_bonus_james"):
		var j4: Node = await _vitoria("f8a2_vitoria_bonus_james", 9, true)
		if j4 != null:
			au._exigir(au.gs.cinturao_regional(), au._estado, "vencer o James dá o Cinturão do Vale")
			await au._ver("f8a2_vitoria_bonus_james")


# ---------------------------------------------------------------------------------------------
# Marca no calção
# ---------------------------------------------------------------------------------------------

## Conta os pixels da cor do remendo (amarelo y1 sem contorno) numa região da folha do lutador na sala, quadro 0.
func _pixels_do_remendo(sala: Node) -> int:
	var sp = sala._lutador
	var folha: Dictionary = _tema().sprite(str(sp.nome_sprite) + "_layered")
	var img: Image = sp.texture.get_image()
	var anc = folha.get("anchors", [])
	if not (anc is Array) or anc.is_empty():
		return -1
	var hip: Array = anc[0].hip
	var pv: Array = folha.get("pivot", [22, 67])
	var x0 := int(pv[0]) + int(hip[0]) - 4
	var y0 := int(pv[1]) + int(hip[1]) + 3
	var n := 0
	var rem: Image = _tema().textura("sponsor_vale_patch").get_image()
	for yy in rem.get_height():
		for xx in rem.get_width():
			var c := rem.get_pixel(xx, yy)
			if c.a > 0.0 and x0 + xx < img.get_width() and y0 + yy < img.get_height():
				var d := img.get_pixel(x0 + xx, y0 + yy)
				if d.is_equal_approx(c):
					n += 1
	return n


func _calcao() -> void:
	if not _quer_prefixo("f8a2_calcao_"):
		return
	for q in [["f8a2_calcao_sem_marca", "offered"], ["f8a2_calcao_marca", "signed"]]:
		if not au._quer(q[0]):
			continue
		_montar("boxing", "center", 3000.0, 4, 800.0)
		au.gs.fama = 210
		au.gs.patrocinio_estado = q[1]
		await au._abrir()
		await au._esperar(0.4)
		au._estado = q[0]
		var sala := _sala()
		var n := _pixels_do_remendo(sala)
		if q[1] == "signed":
			au._exigir(n >= 8, au._estado, "o remendo do patrocinador está pintado no calção (%d de 15 pixels)" % n)
		else:
			au._exigir(n < 8, au._estado, "sem contrato não há remendo no calção (%d pixels)" % n)
		# Zoom 4x em volta do lutador (a marca tem 5x3 px: no quadro inteiro quase não se vê).
		await au._ver(q[0])
		var img: Image = au.root.get_texture().get_image()
		var k := float(img.get_width()) / 640.0
		var p: Vector2 = sala._lutador.global_position  # pés do lutador (base 640x360)
		var rec := Rect2i(int((p.x - 40.0) * k), int((p.y - 78.0) * k), int(80.0 * k), int(60.0 * k))
		var corte: Image = img.get_region(rec)
		corte.resize(corte.get_width() * int(round(8.0 / k)), corte.get_height() * int(round(8.0 / k)), Image.INTERPOLATE_NEAREST)
		corte.save_png(au.saida.path_join(str(q[0]) + "_zoom.png"))


# ---------------------------------------------------------------------------------------------
# Cartaz vencido, pera x cartaz, recorte do Vale no centro
# ---------------------------------------------------------------------------------------------

func _cartaz_e_recorte() -> void:
	if not (_quer_prefixo("f8a2_cartaz_") or au._quer("f8a2_academia_boxe_pera") or _quer_prefixo("f8a2_recorte_") or au._quer("f8a2_foto_centro")):
		return
	for q in [["f8a2_cartaz_vencido", false, false], ["f8a2_cartaz_vencido_marca", true, false],
			["f8a2_cartaz_vencido_zoom", false, true], ["f8a2_cartaz_vencido_zoom_marca", true, true]]:
		if not au._quer(q[0]):
			continue
		_montar("boxing", "gym", 3000.0, 0, 800.0)
		au.gs.indice_escada = au.gs.lutas.adversarios.size()
		au.gs.patrocinio_estado = "signed" if q[1] else ""
		au.gs._escola._gravar_marco("regional_league_opened", {}, false)
		await au._abrir()
		au._estado = q[0]
		var sala := _sala()
		au._exigir(sala._cartaz.visible and sala._cartaz.nome_sprite == "wall_poster_league_regional_won_gym", au._estado, "o cartaz vencido aparece (%s)" % str(sala._cartaz.nome_sprite))
		au._exigir(sala._cartaz.frame == (1 if q[1] else 0), au._estado, "quadro %d (marca %s)" % [sala._cartaz.frame, str(q[1])])
		var tip: String = sala._texto_parede(sala._cartaz_rect.get_center())
		print("TIP_CARTAZ ", tip.replace("
", " / "), " | nome=", au.gs.recorte_do_vale().get("name", "?"))
		au._exigir(tip.contains("RAÍZES LEVA O CINTURÃO DO VALE"), au._estado, "o hover diz RAÍZES LEVA O CINTURÃO DO VALE: %s" % tip.replace("\n", " / "))
		au._exigir(tip.contains("APOIO") == bool(q[1]), au._estado, "a linha APOIO só com contrato: %s" % tip.replace("\n", " / "))
		if q[2]:
			sala._hover_em(sala._cartaz_rect.get_center())
			await au._esperar(0.4)
			au._exigir(sala._cartaz_zoom != null and sala._cartaz_zoom.visible, au._estado, "o zoom do cartaz vencido aparece")
			if sala._cartaz_zoom != null:
				var rz: Rect2 = sala._cartaz_zoom.get_global_rect()
				au._exigir(Rect2(0, 0, 640, 360).encloses(rz), au._estado, "o zoom cabe na tela: %s" % au._fmt(rz))
				au._exigir(not rz.intersects(Rect2(310, 180, 52, 94)), au._estado, "o zoom não cobre a zona do alvo: %s" % au._fmt(rz))
		await au._ver(q[0])
	if au._quer("f8a2_academia_boxe_pera"):
		# Boxe na academia: a pera na parede e o cartão (vencido e normal) não se sobrepõem.
		for vencido in [true, false]:
			_montar("boxing", "gym", 3000.0, 0, 800.0)
			au.gs.indice_escada = au.gs.lutas.adversarios.size() if vencido else 6
			if not vencido:
				au.gs.permanente["first_regional_belt_campaign"] = 0
				au.gs.permanente["regional_belts"] = 0
			au.gs._escola._gravar_marco("regional_league_opened", {}, false)
			await au._abrir()
			au._estado = "f8a2_academia_boxe_pera"
			var sala2 := _sala()
			var pera: Rect2 = sala2._area_lateral("speed_bag")
			au._exigir(sala2._pera.visible and sala2._cartaz.visible, au._estado, "a pera na parede e o cartaz estão na sala (%s)" % ("vencido" if vencido else "normal"))
			au._exigir(not pera.intersects(sala2._cartaz_rect), au._estado, "a pera %s não se sobrepõe ao cartaz %s" % [au._fmt(pera), au._fmt(sala2._cartaz_rect)])
			if sala2._recorte.visible:
				au._exigir(not pera.intersects(sala2._recorte_rect), au._estado, "a pera não cobre o recorte do vulto")
			au._exigir(Rect2(0, 18, 640, 312).encloses(pera), au._estado, "a pera cabe na sala: %s" % au._fmt(pera))
			var painel_x: float = float(_no_painel_x())
			au._exigir(pera.end.x <= painel_x, au._estado, "a pera fica visível fora do painel fixado (borda dela %.0f, painel em x %.0f)" % [pera.end.x, painel_x])
			au._exigir(sala2._cartaz_rect.end.x <= painel_x, au._estado, "o cartaz fica visível fora do painel fixado")
			if vencido:
				await au._ver("f8a2_academia_boxe_pera")
	if _quer_prefixo("f8a2_recorte_") or au._quer("f8a2_foto_centro"):
		_montar("bjj", "center", 3000.0, 5, 800.0)
		await au._abrir()
		await au._esperar(0.3)
		var sala3 := _sala()
		au._estado = "f8a2_recorte_centro"
		au._exigir(sala3._clipvale.visible and sala3._clipvale_rect.size != Vector2.ZERO, au._estado, "o recorte emoldurado está na parede do centro")
		au._exigir(sala3._parede.has("photo_old_gym") and sala3._parede["photo_old_gym"].sprite.visible and sala3._parede["photo_old_gym"].sprite.frame == 1, au._estado, "a foto torta da garagem está pendurada (quadro 1)")
		var tip3: String = sala3._texto_parede(sala3._clipvale_rect.get_center())
		au._exigir(tip3.contains("ESCOLA DE GARAGEM DERRUBA O BLINDADO"), au._estado, "o hover do recorte traz o título: %s" % tip3.replace("\n", " / "))
		au._exigir(not sala3._clipvale_rect.intersects(sala3._parede["photo_old_gym"].sprite.get_global_rect() if false else Rect2(130, 128, 18, 21)), au._estado, "o recorte não cobre a foto")
		if au._quer("f8a2_recorte_centro"):
			await au._ver("f8a2_recorte_centro")
		if au._quer("f8a2_recorte_centro_zoom"):
			au._estado = "f8a2_recorte_centro_zoom"
			sala3._hover_em(sala3._clipvale_rect.get_center())
			await au._esperar(0.4)
			au._exigir(sala3._clipvale_zoom != null and sala3._clipvale_zoom.visible, au._estado, "o zoom do recorte aparece")
			if sala3._clipvale_zoom != null:
				var rz3: Rect2 = sala3._clipvale_zoom.get_global_rect()
				au._exigir(Rect2(0, 0, 640, 360).encloses(rz3), au._estado, "o zoom do recorte cabe na tela: %s" % au._fmt(rz3))
				au._exigir(not rz3.intersects(Rect2(310, 180, 52, 94)), au._estado, "o zoom do recorte não cobre a zona do alvo: %s" % au._fmt(rz3))
			await au._ver("f8a2_recorte_centro_zoom")
		if au._quer("f8a2_foto_centro"):
			au._estado = "f8a2_foto_centro"
			var rf := Rect2(130, 128, 18, 21)
			var tf: String = sala3._texto_parede(rf.get_center())
			au._exigir(tf.contains("Torta de novo"), au._estado, "o hover da foto fala da torta: %s" % tf.replace("\n", " / "))
			await au._ver("f8a2_foto_centro")


# ---------------------------------------------------------------------------------------------
# Mapa da árvore: região CENTRO fechada e aberta
# ---------------------------------------------------------------------------------------------

func _mapa() -> void:
	if not _quer_prefixo("f8a2_mapa_"):
		return
	if au._quer("f8a2_mapa_centro_fechado"):
		_montar("boxing", "gym", 3000.0)
		au.gs.permanente["center_reached"] = false
		au._f54_f6a._com_nos54(["body_jab", "gym_membership", "gym_league"], 900)
		var j: Node = await au._f54_f6a._abrir_arvore()
		au._estado = "f8a2_mapa_centro_fechado"
		au._exigir(au._eh(j, "JanelaMapa"), au._estado, "o mapa abre")
		if au._eh(j, "JanelaMapa"):
			au._exigir(not ("ctr_door" in j.nos_desenhados()), au._estado, "com a região CENTRO fechada os nós dela não aparecem")
			au._exigir(not ("center" in j.placas_desenhadas()), au._estado, "a plaquinha CENTRO não aparece fechada")
			# O miolo (corpo/carreira/estilo) continua cortiça e não virou parede: o 1º nó de cada ramo está sobre o miolo.
			au._exigir(j._tiles.has("miolo") and j._tiles.has("center"), au._estado, "as chaves de ladrilho 'miolo' e 'center' são diferentes")
			au._exigir(j._tiles["miolo"] != j._tiles["center"], au._estado, "o ladrilho do miolo não é o da região CENTRO")
			j.ir_para("gym_league")
			await au._esperar(0.4)
		await au._ver("f8a2_mapa_centro_fechado")
	if au._quer("f8a2_mapa_centro_aberto"):
		_montar("boxing", "center", 3000.0, 4)
		au._f54_f6a._com_nos54(["body_jab", "gym_membership", "gym_league", "ctr_door"], 30000)
		var j2: Node = await au._f54_f6a._abrir_arvore()
		au._estado = "f8a2_mapa_centro_aberto"
		au._exigir(au._eh(j2, "JanelaMapa"), au._estado, "o mapa abre")
		if au._eh(j2, "JanelaMapa"):
			j2.ir_para("ctr_door")
			await au._esperar(0.5)
			for id in ["ctr_door", "ctr_schedule", "ctr_floor"]:
				au._exigir(id in j2.nos_desenhados(), au._estado, "o nó %s está desenhado" % id)
			au._exigir("center" in j2.placas_desenhadas(), au._estado, "a plaquinha da região CENTRO aparece (%s)" % str(j2.placas_desenhadas()))
		await au._ver("f8a2_mapa_centro_aberto")


# ---------------------------------------------------------------------------------------------
# Tela de fim no centro (a linha "a mudança chega na próxima versão" saiu)
# ---------------------------------------------------------------------------------------------

func _fim() -> void:
	if not au._quer("f8a2_fim_retire_centro"):
		return
	_montar("boxing", "center", 3000.0, 6)
	au.gs.fama = 900
	au.gs.aposentar()
	await au._abrir()
	await au._esperar(0.9)
	au._estado = "f8a2_fim_retire_centro"
	au._exigir(au.gs.cinturao_regional(), au._estado, "a escada passou do James")
	await au._ver("f8a2_fim_retire_centro")
