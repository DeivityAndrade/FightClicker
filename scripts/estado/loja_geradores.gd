extends RefCounted
## Produção, cliques, geradores, melhorias, evento dourado, luvas, loja de dinheiro e Metrônomo.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## Atributo do aparelho (nos aparelhos de arte, o de maior fatia: para cor e ícone). A conta real é `divisao_aparelho`.
func atributo_do_aparelho(aparelho_id: String) -> String:
	return str(gs.dados.aparelho(aparelho_id).get("attribute", ""))


## Como o treino do aparelho se divide nos atributos: {atributo: fração} (soma 1). Aparelho comum: 100% num atributo.
func divisao_aparelho(aparelho_id: String) -> Dictionary:
	var ap := gs.dados.aparelho(aparelho_id)
	var d = ap.get("split", {})
	if d is Dictionary and not d.is_empty():
		return d
	var a := str(ap.get("attribute", ""))
	return {a: 1.0} if a != "" else {}


func multiplicador_aparelho(aparelho_id: String) -> float:
	var m := 1.0
	var ap := gs.dados.aparelho(aparelho_id)
	var nivel := nivel_melhoria(aparelho_id)
	var base: int = ap.upgrades.size()
	var extras: Array = gs.centro.melhorias_do(aparelho_id)
	for i in nivel:
		if i < base:
			m *= float(ap.upgrades[i].multiplier)
		elif i - base < extras.size():
			m *= float(extras[i - base].multiplier)  # 8a2: a 5ª melhoria (só se compra no centro; o nível só passa de 4 lá)
	return m


## Treino por clique MANUAL normal (sem crítico) com o foco atual: base x aparelho x luva x árvore x local x (1 + Boxe).
func por_clique() -> float:
	return _base_soco() * (1.0 + gs.bonus_arte_clique()) + bonus_crew_click()


## Treino por auto-soco (Metrônomo e assistido): igual ao clique, mas sem o bônus do Boxe.
func por_auto_soco() -> float:
	return _base_soco()


func _base_soco() -> float:
	return gs.dados.base_training * multiplicador_aparelho(gs.foco) * multiplicador_luva() * (1.0 + gs._arvore._b("click_bonus")) * gs.mult_local() * gs.mult_escola()


## Fator que a equipe recebe: (1 + árvore) x local x (1 + Jiu-jitsu).
func _fator_equipe() -> float:
	return (1.0 + gs._arvore._b("passive_bonus")) * gs.mult_local() * (1.0 + gs.bonus_arte_equipe()) * gs.mult_escola() * (1.0 + gs._honra._hall_valor("crew_mult"))


## Treino/s vindo de todos os geradores (da garagem e pagos).
func producao_total() -> float:
	var total := 0.0
	for g in gs.dados.geradores:
		total += producao_gerador(g.id)
	for g in gs.lutas.geradores_pagos:
		total += producao_gerador(g.id)
	for g in gs.centro.geradores:  # 8a2: Alunos da Raízes (0 fora do centro)
		total += producao_gerador(g.id)
	return total


## Aceita id de gerador da garagem ou pago.
func producao_gerador(gerador_id: String) -> float:
	var g := _def_gerador(gerador_id)
	if g.is_empty() or (g.has("location") and str(g.location) != gs.local_id):  # 8a2: gerador de um local só produz nele
		return 0.0
	return float(g.production) * quantidade_gerador(gerador_id) * _fator_equipe()


## Aceita id de gerador da garagem ou pago.
func quantidade_gerador(gerador_id: String) -> int:
	if not gs.lutas.gerador_pago(gerador_id).is_empty():
		return int(gs.geradores_pagos.get(gerador_id, 0))
	return int(gs.geradores.get(gerador_id, 0))


func _def_gerador(gerador_id: String) -> Dictionary:
	var g := gs.dados.gerador(gerador_id)
	if g.is_empty():
		g = gs.lutas.gerador_pago(gerador_id)
	return g if not g.is_empty() else gs.centro.gerador(gerador_id)


## Gerador de Treino que se compra com Treino: os de sempre, ou o do centro quando se está lá (8a2). {} se não.
func _gerador_de_compra(gerador_id: String) -> Dictionary:
	var g := gs.dados.gerador(gerador_id)
	if not g.is_empty():
		return g
	return gs.centro.gerador(gerador_id) if gs._centro.gerador_do_centro_vale(gerador_id) else {}


## Custo da próxima unidade (já em 3 dígitos significativos).
func custo_gerador(gerador_id: String) -> float:
	var g := _gerador_de_compra(gerador_id)
	if g.is_empty():
		return INF
	return Economia.custo_gerador(g.base_cost, g.growth, quantidade_gerador(gerador_id))


func pode_comprar_gerador(gerador_id: String) -> bool:
	return not _gerador_de_compra(gerador_id).is_empty() and Economia.pode_pagar(gs.treino, custo_gerador(gerador_id))


## Quantas pessoas desenhar na sala (limite só de desenho; comprar nunca é bloqueado).
func pessoas_desenhadas(gerador_id: String) -> int:
	var g := _def_gerador(gerador_id)
	if g.is_empty():
		return 0
	var q := quantidade_gerador(gerador_id)
	var n := 0
	for limite in g.draw_thresholds:
		if limite <= q:
			n += 1
	return n


func nivel_melhoria(aparelho_id: String) -> int:
	return int(gs.niveis_melhoria.get(aparelho_id, 0))


## Próxima melhoria do aparelho, ou {} se a linha está completa.
func proxima_melhoria(aparelho_id: String) -> Dictionary:
	var ap := gs.dados.aparelho(aparelho_id)
	if ap.is_empty() or not gs.aparelho_montado(aparelho_id):
		return {}
	var nivel := nivel_melhoria(aparelho_id)
	if nivel >= ap.upgrades.size():
		var extras: Array = gs._centro.extras_validas(aparelho_id)  # 8a2: a 5ª só aparece e só se compra no centro
		var j: int = nivel - ap.upgrades.size()
		return extras[j] if j < extras.size() else {}
	return ap.upgrades[nivel]


func pode_comprar_melhoria(aparelho_id: String) -> bool:
	var m := proxima_melhoria(aparelho_id)
	return not m.is_empty() and Economia.pode_pagar(gs.treino, m.cost)


## Sprite do aparelho: maior visual_level entre as melhorias compradas (0 se nenhuma).
func nivel_visual(aparelho_id: String) -> int:
	var ap := gs.dados.aparelho(aparelho_id)
	var v := 0
	for i in mini(nivel_melhoria(aparelho_id), ap.get("upgrades", []).size()):
		v = maxi(v, int(ap.upgrades[i].visual_level))
	return v  # (as extras do centro não trocam o sprite: o do centro já vem do sufixo `_center`)


## Um clique no alvo central. Soma no saldo e no atributo do foco; emite `clicou`.
func clicar() -> Dictionary:
	gs._ocioso = 0.0  # mão mexendo, mesmo se a ação for recusada
	gs.registrar_clique()  # Fase 6a: cancela o gesto e zera a "sala parada"
	if gs.acoes_bloqueadas() or not gs.sala_ativa():
		return {}
	gs._sucessao._toques_do_primeiro_clique()
	return _socar(false)


## Um auto-soco do Metrônomo: o MESMO caminho do clique (aparelho em foco, luva, árvore, crítico, treino no
## atributo), mas emite `auto_socou` em vez de `clicou` (a UI não treme a tela e usa número menor).
## Normalmente chamado pelo tique do Metrônomo; público para testes.
func auto_socar() -> Dictionary:
	if gs.acoes_bloqueadas() or not gs.sala_ativa():
		return {}
	gs.auto_socos_total += 1
	return _socar(true)


func _socar(auto: bool) -> Dictionary:
	var aparelho_id := gs.foco
	var atributo := atributo_do_aparelho(aparelho_id)
	# 7b1: Muay Thai (clique com picos) sobe a chance e o multiplicador do crítico, só no clique manual. Continua UM randf() aqui.
	var cc := gs.bonus_arte_critico() if not auto else {"chance": gs.dados.crit_chance, "mult": gs.dados.crit_multiplier}
	var critico := gs.rng.randf() < float(cc.chance)
	var ganho := (por_auto_soco() if auto else por_clique()) * (float(cc.mult) if critico else 1.0) * mult_frenesi()
	var texto := ""
	if critico:
		var textos: Array = gs.dados.aparelho(aparelho_id).crit_texts
		texto = str(textos[gs.rng.randi() % textos.size()])
	gs._ganhar(ganho)
	var info := {"ganho": ganho, "critico": critico, "aparelho": aparelho_id,
		"atributo": atributo, "texto_critico": texto, "auto": auto}
	if auto:
		gs.auto_socou.emit(ganho, critico, aparelho_id, atributo, texto)
	else:
		gs.clicou.emit(ganho, critico, aparelho_id, atributo, texto)
	return info


## 7 enquanto o FRENESI está ligado, 1 nos outros casos.
func mult_frenesi() -> float:
	return gs.FRENESI_MULT if gs.frenesi_restante > 0.0 else 1.0


## O jogador clicou no evento dourado. Tipo "frenzy": liga o FRENESI. Tipo "crew" (bolsa da torcida): paga
## `valor_bolsa()` de uma vez, sem FRENESI e sem crítico. false se não havia evento (ou se há janela aberta).
func pegar_evento_dourado() -> bool:
	if gs.evento_dourado_restante <= 0.0 or gs.modal_aberto or gs.acoes_bloqueadas():
		return false
	gs.evento_dourado_restante = 0.0
	if gs.evento_dourado_tipo == "crew":
		var ganho := valor_bolsa()
		gs._ganhar(ganho)
		gs.bolsa_paga.emit(ganho)
		return true
	gs.frenesi_restante = gs.FRENESI_DURACAO
	gs.frenesi_mudou.emit(gs.frenesi_restante)
	return true


## Quanto a bolsa da torcida paga agora: max(crew_seconds x renda_sem_mao, crew_floor_clicks x por_clique).
func valor_bolsa() -> float:
	return maxf(gs.dados.golden_crew_seconds * renda_sem_mao(), gs.dados.golden_crew_floor_clicks * por_clique())


## Treino/s sem a mão: equipe + auto-socos do Metrônomo (sem crítico e sem FRENESI).
func renda_sem_mao() -> float:
	return producao_total() + socos_por_segundo_metronomo() * por_auto_soco()


## Extra do Grito da equipe em cada clique da mão: crew_share x equipe/s (0 sem a melhoria). Não vale no auto-soco.
func bonus_crew_click() -> float:
	if not gs.crew_click_comprado or gs.lutas.crew_click.is_empty():
		return 0.0
	return crew_share_efetivo() * producao_total()


## Segundos da equipe por clique com o Grito: loja + nó "Grito mais alto" (Fase 5.4).
func crew_share_efetivo() -> float:
	return float(gs.lutas.crew_click.get("crew_share", 0.0)) + gs._arvore._b("crew_click_bonus")


func pode_comprar_crew_click() -> bool:
	return not gs.lutas.crew_click.is_empty() and not gs.crew_click_comprado and gs.loja_estado(float(gs.lutas.crew_click.cost)) == "ok"


func comprar_crew_click() -> bool:
	if gs.acoes_bloqueadas() or not pode_comprar_crew_click():
		return false
	gs._gastar_dinheiro(float(gs.lutas.crew_click.cost))
	gs.crew_click_comprado = true
	gs.crew_click_mudou.emit(true)
	gs.economia_mudou.emit()
	return true


func _tick_evento_dourado(delta: float) -> void:
	if gs.frenesi_restante > 0.0:
		gs.frenesi_restante = maxf(0.0, gs.frenesi_restante - delta)
		if gs.frenesi_restante == 0.0:
			gs.frenesi_mudou.emit(0.0)
	if gs.evento_dourado_restante > 0.0:
		gs.evento_dourado_restante = maxf(0.0, gs.evento_dourado_restante - delta)  # ninguém clicou: o cinturão some
		return
	if gs.modal_aberto or gs.acoes_bloqueadas():
		return  # luta ou janela aberta: o relógio do próximo evento espera
	if gs._evento_espera < 0.0:
		gs._evento_espera = gs._rng_evento.randf_range(gs.EVENTO_ESPERA_MIN, gs.EVENTO_ESPERA_MAX)
	gs._evento_espera -= delta
	if gs._evento_espera <= 0.0:
		gs._evento_espera = -1.0
		gs.evento_dourado_tipo = "crew" if gs.dados.golden_crew_chance >= 1.0 or (gs.dados.golden_crew_chance > 0.0 and gs._rng_evento.randf() < gs.dados.golden_crew_chance) else "frenzy"
		gs.evento_dourado_restante = gs.EVENTO_DURACAO
		gs.evento_dourado.emit(gs.EVENTO_DURACAO)


## Troca o foco (grátis, instantâneo). Retorna false se o aparelho não existe.
func definir_foco(aparelho_id: String) -> bool:
	if gs.dados.aparelho(aparelho_id).is_empty() or not gs.aparelho_montado(aparelho_id):
		return false
	if aparelho_id != gs.foco:
		gs.foco = aparelho_id
		gs.foco_mudou.emit(gs.foco)
		gs.economia_mudou.emit()
	return true


func comprar_gerador(gerador_id: String) -> bool:
	if gs.acoes_bloqueadas() or not pode_comprar_gerador(gerador_id):
		return false
	gs._gastar(custo_gerador(gerador_id))
	gs.geradores[gerador_id] = quantidade_gerador(gerador_id) + 1
	gs.gerador_mudou.emit(gerador_id, gs.geradores[gerador_id])
	gs.economia_mudou.emit()
	return true


## Compra o próximo nível de melhoria do aparelho.
func comprar_melhoria(aparelho_id: String) -> bool:
	if gs.acoes_bloqueadas() or not pode_comprar_melhoria(aparelho_id):
		return false
	var m := proxima_melhoria(aparelho_id)
	gs._gastar(m.cost)
	gs.niveis_melhoria[aparelho_id] = nivel_melhoria(aparelho_id) + 1
	gs.melhoria_comprada.emit(aparelho_id, m.id, gs.niveis_melhoria[aparelho_id])
	gs.economia_mudou.emit()
	return true


func multiplicador_luva() -> float:
	var m := 1.0
	for i in mini(gs.luvas_abertas(), gs.lutas.luvas.size()):
		m *= float(gs.lutas.luvas[i].click_multiplier)
	return m


## Luva equipada: {id, level, name, sprite_suffix, click_multiplier}. Nível 0 = luva velha.
## A UI troca cursor, mão da garagem e mão da luta por `sprite_suffix` (ex.: "" ou "_glove_l1").
func luva_equipada() -> Dictionary:
	var n := gs.luvas_abertas()
	if n <= 0 or n > gs.lutas.luvas.size():
		return gs.lutas.luva_base
	return gs.lutas.luvas[n - 1]


func sufixo_luva() -> String:
	return str(luva_equipada().sprite_suffix)


## Próxima luva da linha, ou {} se completou. Fase 5.1: com a luva anterior ainda na caixa ela NÃO está à venda
## (`pode_comprar_luva` é false e `luva_em_caixa()` é true): a UI mostra `shop_glove_boxed`.
func proxima_luva() -> Dictionary:
	return {} if gs.nivel_luva >= gs.lutas.luvas.size() else gs.lutas.luvas[gs.nivel_luva]


func pode_comprar_luva() -> bool:
	var l := proxima_luva()
	return not l.is_empty() and not gs.luva_em_caixa() and gs.loja_estado(float(l.cost)) == "ok"


func comprar_luva() -> bool:
	if gs.acoes_bloqueadas() or not pode_comprar_luva():
		return false
	var l := proxima_luva()
	gs._gastar_dinheiro(l.cost)
	gs.nivel_luva += 1  # glove_level conta as luvas COMPRADAS (abertas + a da caixa)
	if gs.dados.box_glove:
		gs._aparelhos._criar_caixa(str(l.id), "glove")
		gs.salvar()
		gs.caixa_criada.emit(str(l.id), "glove")
	else:
		gs.luva_mudou.emit(gs.nivel_luva, sufixo_luva())
	gs.economia_mudou.emit()
	return true


func custo_gerador_pago(gerador_id: String) -> float:
	var g := gs.lutas.gerador_pago(gerador_id)
	if g.is_empty():
		return INF
	return Economia.custo_gerador(g.base_cost, g.growth, quantidade_gerador(gerador_id))


func pode_comprar_gerador_pago(gerador_id: String) -> bool:
	return not gs.lutas.gerador_pago(gerador_id).is_empty() and gs.loja_estado(custo_gerador_pago(gerador_id)) == "ok"


func comprar_gerador_pago(gerador_id: String) -> bool:
	if gs.acoes_bloqueadas() or not pode_comprar_gerador_pago(gerador_id):
		return false
	gs._gastar_dinheiro(custo_gerador_pago(gerador_id))
	gs.geradores_pagos[gerador_id] = quantidade_gerador(gerador_id) + 1
	gs.gerador_pago_mudou.emit(gerador_id, gs.geradores_pagos[gerador_id])
	gs.economia_mudou.emit()
	return true


func metronomo_niveis() -> int:
	return gs.lutas.metronomo.levels.size()


## Definição do nível atual ({} se 0).
func metronomo_atual() -> Dictionary:
	if gs.nivel_metronomo <= 0 or gs.nivel_metronomo > metronomo_niveis():
		return {}
	return gs.lutas.metronomo.levels[gs.nivel_metronomo - 1]


## Próximo nível à venda: {id, level, cost, interval, name, description, appears_as}, ou {} se completo/sem Metrônomo.
func proximo_metronomo() -> Dictionary:
	return {} if gs.nivel_metronomo >= metronomo_niveis() else gs.lutas.metronomo.levels[gs.nivel_metronomo]


## Segundos entre auto-socos no nível atual (0 = sem Metrônomo).
func intervalo_metronomo() -> float:
	return float(metronomo_atual().get("interval", 0.0))


func socos_por_segundo_metronomo() -> float:
	var i := intervalo_metronomo()
	return 1.0 / i if i > 0.0 else 0.0


func pode_comprar_metronomo() -> bool:
	var n := proximo_metronomo()
	return not n.is_empty() and gs.loja_estado(float(n.cost)) == "ok"


func comprar_metronomo() -> bool:
	if gs.acoes_bloqueadas() or not pode_comprar_metronomo():
		return false
	gs._gastar_dinheiro(proximo_metronomo().cost)
	gs.nivel_metronomo += 1
	gs._acc_metronomo = 0.0
	gs.metronomo_mudou.emit(gs.nivel_metronomo)
	gs._aparelhos._atualizar_estado_assist()
	gs.economia_mudou.emit()
	return true


## true quando o Metrônomo pode socar agora: garagem na tela (sem luta, sem tela de fim, sem janela da UI).
func metronomo_ativo() -> bool:
	return gs.nivel_metronomo > 0 and gs.sala_ativa()


## API da UI (Fase 5.3): chamar com true quando QUALQUER janela abre (prévia, confirmação, vitória, cartão,
## futuras opções) e false quando fecha. Janela aberta = sala parada (relógio, equipe, Metrônomo, clique...).
## Toda janela passa por `Fluxo._abrir`, que já chama isto.
func definir_modal(aberto: bool) -> void:
	gs.modal_aberto = aberto
	gs._aparelhos._atualizar_estado_assist()
	gs._calendario._checar_sala()


# Acumula tempo só com o alvo livre; no máximo 3 socos por quadro (nunca acumula socos para depois).
func _tick_metronomo(delta: float) -> void:
	if not metronomo_ativo():
		return
	var intervalo := intervalo_metronomo()
	if intervalo <= 0.0:
		return
	gs._acc_metronomo += delta
	var n := 0
	while gs._acc_metronomo >= intervalo and n < 3:
		gs._acc_metronomo -= intervalo
		auto_socar()
		n += 1
	if gs._acc_metronomo >= intervalo:
		gs._acc_metronomo = fmod(gs._acc_metronomo, intervalo)
