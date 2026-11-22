extends RefCounted
## Fase 8a1: liga regional (4 lutas depois do Kid), passiva do adversário na prévia e no fim, cinturão regional e o James.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.
## Dados: data/league_regional.json (lido pelo FightData; os 4 entram na escada depois do Kid). Design: docs/fases/fase8a1-design.md.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


# ---------------------------------------------------------------- liga e cinturão
## A liga existe (arquivo lido) e a escada já passou do adversário depois do qual ela abre (o Kid).
func liga_aberta() -> bool:
	if gs.lutas.liga.is_empty():
		return false
	var i: int = gs.lutas.indice_adversario(str(gs.lutas.liga.after))
	return i >= 0 and gs.indice_escada > i


## Cinturão regional = a escada passou do James (o adversário com `regional_belt`). Não é salvo: sai do índice.
func cinturao_regional() -> bool:
	var i: int = gs.lutas.indice_cinturao_regional()
	return i >= 0 and gs.indice_escada > i


## O próximo adversário é da liga regional?
func proximo_e_regional() -> bool:
	var opp := gs.proximo_adversario()
	return not opp.is_empty() and str(opp.get("league", "")) != ""


# ---------------------------------------------------------------- prévia: a passiva dele
## Chaves da prévia contra adversário com passiva (§3.1); {} se ele não tem. `hits` = ela atrapalha o SEU jeito de lutar
## (a trava existe para o seu tipo de passiva, ou é a guarda, que vale contra todos).
func chaves_previa(opp: Dictionary) -> Dictionary:
	var pv = opp.get("passive", {})
	if not (pv is Dictionary) or pv.is_empty():
		return {}
	var id := str(pv.id)
	var tipo := str(gs.motor.passiva.get("type", ""))
	var atrapalha := false
	var texto := ""
	if pv.has("guard"):
		atrapalha = true
		texto = gs.texto_ui("opp_passive_guard_hits", "ATRAPALHA: TODOS NO 1º ROUND")
	elif tipo != "" and pv.get("locks", {}).has(tipo):
		atrapalha = true
		texto = gs.preencher(gs.texto_ui("opp_passive_hits", "ATRAPALHA: {jeito}"), {"jeito": gs.texto_ui("opp_passive_%s_jeito" % id, "")})
	else:
		texto = gs.texto_ui("opp_passive_misses", "NÃO ATRAPALHA O SEU JEITO")
	return {"opp_passive_id": id, "opp_passive_name": gs.texto_ui("opp_passive_%s_name" % id, id.to_upper()),
		"opp_passive_line": gs.texto_ui("opp_passive_%s_line" % id, ""), "opp_passive_hits": atrapalha,
		"opp_passive_hits_text": texto, "opp_passive_icon": id}


## Dados da passiva dele para a tela de luta: {id, name, icon, block_text, guard_until, guard_text_closed, guard_text_open} ou {}.
func info_luta(opp: Dictionary) -> Dictionary:
	var pv = opp.get("passive", {})
	if not (pv is Dictionary) or pv.is_empty():
		return {}
	var id := str(pv.id)
	var r := {"id": id, "name": gs.texto_ui("opp_passive_%s_name" % id, id.to_upper()), "icon": id,
		"block_text": gs.texto_ui("fight_opp_block_%s" % id, ""), "guard_until": 0.0,
		"guard_closed_text": "", "guard_open_text": ""}
	if pv.has("guard"):
		r["guard_until"] = float(pv.guard.rounds) * float(gs.lutas.combate.round_length)
		r["guard_closed_text"] = gs.texto_ui("fight_guard_closed", "GUARDA FECHADA")
		r["guard_open_text"] = gs.texto_ui("fight_guard_open", "A GUARDA ABRIU")
	return r


## Motivo da derrota pela passiva dele, em texto: {id, text, tip} ou {} (`nota` = {id, n} do motor).
func textos_nota(nota: Dictionary, semente: int) -> Dictionary:
	if nota.is_empty():
		return {}
	var id := str(nota.id)
	var texto := gs.preencher(gs.texto_ui("reason_opp_%s" % id, ""), {"n": int(nota.get("n", 0))})
	if texto == "":
		return {}
	var dicas := gs._textos.lista_ui("tip_opp_%s" % id)
	var dica := str(dicas[semente % dicas.size()]) if not dicas.is_empty() else ""
	return {"id": id, "text": texto, "tip": dica}


# ---------------------------------------------------------------- vitória: marcos, cinturão e linhagem
## Chamada em concluir_luta DEPOIS de somar o índice da escada e ANTES do salvar() da vitória. Devolve
## {league_opened, regional_belt (ganhou AGORA), first_regional_belt (o 1º da linhagem)}; os gatilhos das falas do Osmar saem daqui.
func ao_vencer(opp: Dictionary) -> Dictionary:
	var r := {}
	if gs.lutas.liga.is_empty():
		return r
	if str(opp.id) == str(gs.lutas.liga.after):
		r["league_opened"] = gs._escola._gravar_marco("regional_league_opened", {}, false)
		if r.league_opened:
			gs.disparar_gatilho("regional_league_opened")
	if bool(opp.get("regional_belt", false)):
		r["regional_belt"] = true
		gs.permanente["regional_belts"] = int(gs.permanente.get("regional_belts", 0)) + 1
		if int(gs.permanente.get("first_regional_belt_campaign", 0)) <= 0:
			gs.permanente["first_regional_belt_campaign"] = gs.numero_carreira()
		r["first_regional_belt"] = gs._escola._gravar_marco("regional_belt_first", {}, false)
		if r.first_regional_belt:
			gs.disparar_gatilho("regional_belt_first")
	return r


## Ao carregar: save antigo que já passou do Kid abre a liga (marco + fala do Osmar, uma vez); a fala nunca se perde.
## Vem DEPOIS de `_reiniciar_falas`.
func ao_carregar() -> void:
	if not liga_aberta():
		return
	if gs._escola._gravar_marco("regional_league_opened", {}, false) or not gs.escola.lines_seen.has("cl_liga_regional"):
		gs.disparar_gatilho("regional_league_opened")
	if cinturao_regional() and not gs.escola.lines_seen.has("cl_cinturao_regional"):
		gs._escola._gravar_marco("regional_belt_first", {}, false)
		gs.disparar_gatilho("regional_belt_first")


# ---------------------------------------------------------------- o James (placar da escola e falas)
## Placar da escola contra o James: {met, school_wins, james_wins}.
func rival() -> Dictionary:
	return gs.escola.get("rival", {"met": 0, "school_wins": 0, "james_wins": 0}).duplicate()


func _e_james(opp: Dictionary) -> bool:
	return bool(opp.get("regional_belt", false))


## Situação da apresentação (§5): many (met >= 3) > school_won (a escola já ganhou) > first (met == 0) > revenge.
func situacao_intro() -> String:
	var r := rival()
	if int(r.met) >= 3:
		return "many"
	if int(r.school_wins) >= 1:
		return "school_won"
	return "first" if int(r.met) == 0 else "revenge"


func _falas_em_ordem(prefixo: String) -> Array:
	var lista: Array = []
	var n := 1
	while true:
		var l: Dictionary = gs.dialogos.linha("%s_%d" % [prefixo, n])
		if l.is_empty():
			break
		lista.append({"id": str(l.id), "speaker": str(l.speaker), "text": gs.dialogos.texto_balao(l)})
		n += 1
	return lista


## A apresentacao vale agora? (proximo e o James e ela ainda nao passou nesta campanha). Sem efeito colateral.
func james_intro_pendente() -> bool:
	var opp := gs.proximo_adversario()
	return not opp.is_empty() and _e_james(opp) and not bool(gs.rival_spoke.before)


## Ids da apresentacao em ordem ([] se nao e o James ou se `rival_spoke.before`). Sem efeito colateral.
func fala_previa_james() -> Array:
	if not james_intro_pendente():
		return []
	return _falas_em_ordem("rival_james_intro_" + situacao_intro()).map(func(f: Dictionary) -> String: return str(f.id))


## Situacao da fala de depois: many (met >= 3) > school_won (a escola ja tinha vencido) > first (met == 1); o resto = many.
## Usa o placar ANTES desta luta (a luta conta como mais um encontro).
func situacao_depois() -> String:
	var r := rival()
	var met := int(r.met) + 1
	if met >= 3:
		return "many"
	if int(r.school_wins) >= 1:
		return "school_won"
	return "first" if met == 1 else "many"


## Id da fala de depois ("" se nao e o James ou se `rival_spoke.after`). `ganhou` = o jogador venceu. Sem efeito colateral.
func fala_depois_james(ganhou: bool) -> String:
	var opp := gs.proximo_adversario()
	if opp.is_empty() or not _e_james(opp) or bool(gs.rival_spoke.after):
		return ""
	var id := "rival_james_after_%s_%s_1" % ["lose" if ganhou else "win", situacao_depois()]
	return id if not gs.dialogos.linha(id).is_empty() else ""


## Chamada em lutar() (a luta ja esta decidida): as falas da apresentacao e a de depois, e grava `rival_spoke` AGORA (o save da
## luta leva junto: pular ou fechar o jogo no meio nao repete). {intro_lines [ids], intro_falas [{id, speaker, text}], outro_line
## (id ou ""), outro_fala {id, speaker, text}}; {} se nao e o James.
func falas_da_luta(ganhou: bool) -> Dictionary:
	var opp := gs.proximo_adversario()
	if opp.is_empty() or not _e_james(opp):
		return {}
	var r := {"intro_lines": [], "intro_falas": [], "outro_line": "", "outro_fala": {}}
	if james_intro_pendente():
		var falas := _falas_em_ordem("rival_james_intro_" + situacao_intro())
		r["intro_falas"] = falas
		r["intro_lines"] = falas.map(func(f: Dictionary) -> String: return str(f.id))
		gs.rival_spoke["before"] = true
	var id := fala_depois_james(ganhou)
	if id != "":
		var l: Dictionary = gs.dialogos.linha(id)
		r["outro_line"] = id
		r["outro_fala"] = {"id": id, "speaker": str(l.speaker), "text": gs.dialogos.texto_balao(l)}
		gs.rival_spoke["after"] = true
	return r


## Placar: chamada em concluir_luta (vitoria ou derrota) ANTES do salvar(). `ganhou` = o jogador venceu.
func registrar_luta(opp: Dictionary, ganhou: bool) -> void:
	if not _e_james(opp):
		return
	if not gs.escola.has("rival"):
		gs.escola["rival"] = {"met": 0, "school_wins": 0, "james_wins": 0}
	var r: Dictionary = gs.escola["rival"]
	r["met"] = int(r.met) + 1
	if ganhou:
		r["school_wins"] = int(r.school_wins) + 1
	else:
		r["james_wins"] = int(r.james_wins) + 1


# ---------------------------------------------------------------- save (tudo opcional; ausente = padrão)
## career.rival_spoke -> {before, after}.
func validar_falou(v: Variant) -> Dictionary:
	var r := {"before": false, "after": false}
	if v is Dictionary:
		r["before"] = typeof(v.get("before", false)) == TYPE_BOOL and v.get("before", false)
		r["after"] = typeof(v.get("after", false)) == TYPE_BOOL and v.get("after", false)
	return r


## school.rival -> {met, school_wins, james_wins}; school_wins + james_wins <= met (senão o `met` sobe).
func validar_escola(s: Dictionary, r: Dictionary) -> void:
	var b = s.get("rival", null)
	var met := 0
	var sw := 0
	var jw := 0
	if b is Dictionary:
		met = gs._inteiro_valido(b.get("met", 0), 1.0e9)
		sw = gs._inteiro_valido(b.get("school_wins", 0), 1.0e9)
		jw = gs._inteiro_valido(b.get("james_wins", 0), 1.0e9)
	elif b != null:
		gs._avisar("Placar do James inválido: zerado.")
	if sw + jw > met:
		met = sw + jw
	r["rival"] = {"met": met, "school_wins": sw, "james_wins": jw}


## permanent.regional_belts / first_regional_belt_campaign (ausente = 0).
func validar_permanente(p: Dictionary, r: Dictionary) -> void:
	r["regional_belts"] = gs._inteiro_valido(p.get("regional_belts", 0), 1.0e9)
	r["first_regional_belt_campaign"] = gs._inteiro_valido(p.get("first_regional_belt_campaign", 0), 1.0e9)
