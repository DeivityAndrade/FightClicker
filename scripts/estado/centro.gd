extends RefCounted
## Fase 8a2: centro de treinamento (local 3), Alunos da Raízes, 5ª melhoria dos aparelhos, patrocínio pequeno, arco 4 (cartaz e recorte).
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.
## Dados: data/center.json (lido por CentroData; a região e os nós da árvore pelo FightData). Design: docs/fases/fase8a2-design.md.
## Antes do 1º Cinturão do Vale da linhagem nada daqui existe: tudo depende de cinturao_regional(), permanent.regional_belts
## ou permanent.center_reached.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


# ---------------------------------------------------------------- local
func no_centro() -> bool:
	return gs.centro.ativo and gs.local_id == gs.centro.local


## Chamada por mudar() com o local já trocado: na chegada ao centro abre a região da árvore e grava o marco `center_arrival`
## (sem salvar: quem chama salva no mesmo save da mudança). true se chegou ao centro agora.
func ao_mudar_para(local: String) -> bool:
	if not gs.centro.ativo or local != gs.centro.local:
		return false
	gs.permanente["center_reached"] = true
	gs._escola._gravar_marco("center_arrival", {}, false)
	return true


# ---------------------------------------------------------------- geradores e melhorias (só no centro)
## Geradores de Treino da sala atual: os de sempre + os do local (Alunos da Raízes no centro).
func geradores_do_local() -> Array:
	var r: Array = gs.dados.geradores.duplicate()
	for g in gs.centro.geradores:
		if str(g.location) == gs.local_id:
			r.append(g)
	return r


## O gerador do centro existe e vale no local atual? (false para os geradores de sempre.)
func gerador_do_centro_vale(gerador_id: String) -> bool:
	var g: Dictionary = gs.centro.gerador(gerador_id)
	return not g.is_empty() and str(g.location) == gs.local_id


## Melhorias que o aparelho tem AGORA: as 4 de sempre + as extras do local (a 5ª só no centro).
func melhorias_do_aparelho(aparelho_id: String) -> Array:
	var r: Array = gs.dados.aparelho(aparelho_id).get("upgrades", []).duplicate()
	r.append_array(extras_validas(aparelho_id))
	return r


## Só as extras que valem no local atual.
func extras_validas(aparelho_id: String) -> Array:
	var r: Array = []
	for m in gs.centro.melhorias_do(aparelho_id):
		if str(m.location) == gs.local_id:
			r.append(m)
	return r


## Maior nível que o aparelho aceita no save: as de sempre + todas as extras do local do centro (conta fora do centro também, para validar).
func nivel_maximo(aparelho_id: String) -> int:
	return gs.dados.aparelho(aparelho_id).get("upgrades", []).size() + gs.centro.melhorias_do(aparelho_id).size()


# ---------------------------------------------------------------- patrocínio
func _def() -> Dictionary:
	return gs.centro.patrocinio


## O patrocínio existe para esta linhagem? (definido nos dados e a linhagem já tem o Cinturão do Vale.)
func _existe() -> bool:
	var p := _def()
	return not p.is_empty() and int(gs.permanente.get("regional_belts", 0)) >= int(p.requires_regional_belts)


## {state ("" | "offered" | "signed"), name, short_name, brand (sprite), win_line (modelo), bonus_line (modelo com a marca), offer_title,
## offer_line, accept, close, envelope, signed_text}; {} se o patrocínio não existe na linhagem.
func patrocinio() -> Dictionary:
	if not _existe():
		return {}
	var p := _def()
	return {"state": gs.patrocinio_estado, "name": p.name, "short_name": p.short_name, "brand": p.brand_sprite,
		"win_line": p.win_line, "bonus_line": gs.preencher(str(p.win_line), {"marca": p.short_name}),
		"offer_title": p.offer_title, "offer_line": p.offer_line, "accept": p.accept_button, "close": p.close_button,
		"envelope": gs.texto_ui("sponsor_envelope", "PROPOSTA"), "signed_text": gs.texto_ui("sponsor_signed", "CONTRATO ASSINADO")}


## Oferta por fama: "" -> "offered" quando a linhagem tem o cinturão e a fama da campanha chegou ao mínimo. Chamada em concluir_luta
## (depois de somar a fama, antes do salvar) e ao carregar. true se mudou.
func avaliar_oferta() -> bool:
	if gs.patrocinio_estado != "" or not _existe() or gs.fama < int(_def().fame_at_least):
		return false
	# só nas campanhas DEPOIS da do 1º Cinturão do Vale (nem ao recarregar o save da própria campanha do cinturão)
	if gs.numero_carreira() <= int(gs.permanente.get("first_regional_belt_campaign", 0)):
		return false
	gs.patrocinio_estado = "offered"
	gs.patrocinio_mudou.emit(gs.patrocinio_estado)
	return true


## ASSINAR: "offered" -> "signed", salva. Não é bloqueado por janelas da economia, só por luta/fim/sucessão pendentes.
func assinar_patrocinio() -> bool:
	if gs.patrocinio_estado != "offered" or gs._carreira._bloqueio_base():
		return false
	gs.patrocinio_estado = "signed"
	gs.salvar()
	gs.patrocinio_mudou.emit(gs.patrocinio_estado)
	return true


## Bônus em $ da vitória contra `opp` (só assinado): floor(prize_money base x prize_share + 0,5). Sem os nós de dinheiro.
func bonus_vitoria(opp: Dictionary) -> int:
	if gs.patrocinio_estado != "signed" or not _existe():
		return 0
	return int(floor(float(opp.prize_money) * float(_def().prize_share) + 0.5))


## career.sponsor lido do save: ausente/ruim = ""; "offered"/"signed" sem o patrocínio (linhagem sem cinturão) = "" (com aviso).
func validar_estado(v: Variant) -> String:
	var e := str(v) if v is String else ""
	if not (e in ["offered", "signed"]):
		return ""
	if not _existe():
		gs._avisar("Patrocínio salvo sem o Cinturão do Vale na linhagem: descartado.")
		return ""
	return e


# ---------------------------------------------------------------- arco 4 (cartaz vencido e recorte)
## {campaign, name, poster {title, text, sponsor_line}, clipping {title, text, footer}, brand} ou {} antes do 1º Cinturão do Vale da linhagem.
## `name` = o discípulo daquela campanha (o roster só ganha a entrada quando a campanha acaba; na em curso vale o nome atual).
func recorte_do_vale() -> Dictionary:
	var camp := int(gs.permanente.get("first_regional_belt_campaign", 0))
	if camp <= 0:
		return {}
	var nome := ""
	if camp == gs.numero_carreira():
		nome = gs.nome_lutador()
	else:
		for e in gs.escola.get("roster", []):
			if int(e.get("campaign", 0)) == camp:
				nome = str(e.get("name", ""))
	var d: DialogosData = gs.dialogos
	var cartaz := {"title": d.texto_objeto("regional_poster_won", "title"),
		"text": d.texto_objeto("regional_poster_won").replace("{nome}", nome.to_upper()) if nome != "" else d.texto_objeto("regional_poster_won").split("
")[0],
		"sponsor_line": ""}
	var marca := ""
	if gs.patrocinio_estado == "signed" and _existe():
		marca = str(_def().brand_sprite)
		cartaz["sponsor_line"] = d.texto_objeto("regional_poster_sponsor").replace("{marca}", str(_def().short_name))
	return {"campaign": camp, "name": nome, "poster": cartaz, "brand": marca, "text": cartaz.text,
		"clipping": {"title": d.texto_objeto("regional_clipping", "title"), "text": d.texto_objeto("regional_clipping"),
			"footer": d.texto_objeto("regional_clipping", "footer")}}


# ---------------------------------------------------------------- save
## Save com career.location "center" mas sem o Cinturão do Vale (escada antes do fim): volta para o local de antes (a academia), com
## aviso; alunos zerados e a 5ª melhoria volta a 4 (o centro não existe para esse save).
func corrigir_local_sem_cinturao() -> void:
	if not gs.centro.ativo or gs.local_id != gs.centro.local or gs.cinturao_regional():
		return
	var i := 0
	for k in gs.academia.locais.size():
		if gs.academia.locais[k].id == gs.local_id:
			i = k
	gs.local_id = str(gs.academia.locais[maxi(0, i - 1)].id)
	gs._avisar("Save no centro sem o Cinturão do Vale: voltou para '%s'." % gs.local_id)
	for g in gs.centro.geradores:
		gs.geradores.erase(g.id)
	for ap in gs.dados.todos_aparelhos():
		gs.niveis_melhoria[ap.id] = mini(int(gs.niveis_melhoria.get(ap.id, 0)), ap.upgrades.size())
	gs._academia._atualizar_passiva()


## permanent.center_reached (só gravado quando verdadeiro). Nó `ctr_*` comprado liga o campo mesmo que ele tenha se perdido.
func validar_permanente(p: Dictionary, r: Dictionary) -> void:
	var chegou: bool = typeof(p.get("center_reached", false)) == TYPE_BOOL and p.get("center_reached", false)
	for id in r.get("skill_nodes", []):
		if str(gs.lutas.no_da_arvore(str(id)).get("lock", "")) == "center":
			chegou = true
	if chegou:
		r["center_reached"] = true
