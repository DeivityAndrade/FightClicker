class_name JanelaPremioBriga
extends JanelaPremioRonda
## Ronda 2a1: prêmio da noite de briga (depois da luta no beco). Mesma janela do prêmio da Ronda, com outro conteúdo: BRIGA GANHA
## (ficha nova, recorte, desafio cumprido, estilo novo, lenda) ou NOITE PERDIDA (SAIU MANCANDO, o capuz volta no próximo relógio e a
## REVANCHE fica no quadro). Só lê o `night_prize` que `GameState.briga_lutar()` devolveu; nada de regra aqui.
## Ronda 2a2 (o chefe, `boss`): na vitória vêm também o capacete (normal e/ou o raro aceso), o título da imprensa e o cartaz no menu.


func _titulo_da_janela(_sobe: bool) -> String:
	return str(_premio.get("title", UiTema.txt("alley_prize_title", "BRIGA GANHA"))).to_upper()


func _linhas(sobe: bool) -> Array:
	var p := _premio
	var r: Array = []
	var venceu := bool(p.get("win", false))
	var nivel := int(p.get("level", 0))
	r.append({"h": 28.0, "f": func(y: float) -> void: _ganho(y, 2)})
	if sobe:
		var sube := str(p.get("level_up_line", "")).to_upper()
		if sube != "":
			var n := _linhas_de(sube)
			r.append({"h": 9.0 * float(n) + 7.0, "f": func(y: float) -> void: _texto(sube, UiTema.Y1, y, n)})
	if venceu:
		var linha := str(p.get("line", "")).to_upper()
		if linha != "":
			var n2 := _linhas_de(linha)
			r.append({"h": 9.0 * float(n2) + 7.0, "f": func(y: float) -> void: _texto(linha, UiTema.G3, y, n2)})
		if bool(p.get("dossier_new", false)):
			var d := str(p.get("dossier_line", "")).to_upper()
			r.append({"h": 11.0, "f": func(y: float) -> void: _linha_centrada(d, UiTema.Y1, y)})
			var c := str(p.get("clipping_line", "")).to_upper()
			r.append({"h": 11.0, "f": func(y: float) -> void: _linha_centrada(c, UiTema.Y1, y)})
			var manchete := str(p.get("headline", "")).to_upper()
			if manchete != "":
				var n3 := _linhas_de(manchete)
				r.append({"h": 9.0 * float(n3) + 8.0, "f": func(y: float) -> void: _texto(manchete, UiTema.G3, y, n3)})
		if bool(p.get("boss", false)):
			r.append_array(_linhas_chefe())
		if bool(p.get("challenge_done", false)):
			r.append({"h": 19.0, "f": func(y: float) -> void: _faixa_desafio(y)})
			var estilo := str(p.get("style_text", "")).to_upper()
			if estilo != "":
				r.append({"h": 14.0, "f": func(y: float) -> void: _linha_centrada(estilo, UiTema.Y1, y)})
	else:
		var perdeu := str(p.get("line", "")).to_upper()
		if perdeu != "":
			r.append({"h": 17.0, "f": func(y: float) -> void: _linha_centrada(perdeu, UiTema.R3, y)})
		var sub := str(p.get("sub", "")).to_upper()
		if sub != "":
			var n4 := _linhas_de(sub)
			r.append({"h": 9.0 * float(n4) + 8.0, "f": func(y: float) -> void: _texto(sub, UiTema.G3, y, n4)})
		if bool(p.get("revenge", false)):
			r.append({"h": 22.0, "f": func(y: float) -> void: _carimbo_revanche(y)})
	r.append({"h": 32.0, "f": func(y: float) -> void: _bolinhas(y, nivel, sobe)})
	r.append({"h": 40.0, "f": func(y: float) -> void: _botao_voltar(y)})
	return r


## O que o chefe dá: o capacete (a lâmpada acesa no raro), as linhas do troféu, do título da imprensa e do cartaz do menu.
func _linhas_chefe() -> Array:
	var p := _premio
	var r: Array = []
	var trofeu := str(p.get("trophy_new", ""))
	if trofeu != "":
		var spr := ""
		for t in GameState.esconderijo().get("trophies", []):
			if str(t.get("state", "empty")) != "empty":
				spr = str(t.get("sprite", ""))
		if spr != "" and not UiTema.sprite(spr).is_empty():
			r.append({"h": UiTema.tamanho_quadro(spr).y + 4.0, "f": func(y: float) -> void: _capacete(spr, y)})
	for k in ["trophy_line", "trophy_rare_line", "press_title_line", "poster_line"]:
		var tx := str(p.get(k, "")).to_upper()
		if tx == "":
			continue
		var n := _linhas_de(tx)
		var cor: Color = UiTema.Y2 if k == "trophy_rare_line" else UiTema.Y1
		r.append({"h": 9.0 * float(n) + 2.0, "f": func(y: float) -> void: _texto(tx, cor, y, n)})
	return r


func _capacete(spr: String, y: float) -> void:
	var q := UiTema.tamanho_quadro(spr)
	var t := UiTema.textura_rect(painel, spr, roundf(320.0 - q.x / 2.0), y)
	UiTema.alinhar(t, "center_h")


## Faixa vermelha "DESAFIO CUMPRIDO" com o gato, no meio da janela (fundo escuro: texto cream).
func _faixa_desafio(y: float) -> void:
	var texto := str(_premio.get("challenge_line", "")).to_upper()
	var iw := 9.0
	var grupo := iw + 4.0 + UiTema.largura_visivel(texto)
	var w := roundf(grupo + 24.0)
	if int(w) % 2 != 0:
		w += 1.0
	var faixa := UiTema.nine_patch(painel, "c_carimbo_moldura", Rect2(320.0 - w / 2.0, y, w, 16))
	faixa.set_meta("ui_pos", "center_h")
	var area := UiTema.area_nove("c_carimbo_moldura", Vector2(w, 16))
	var gx := roundf(area.position.x + (area.size.x - grupo) / 2.0)
	UiTema.textura_rect(faixa, "icon_region_black_cat_9", gx, UiTema.y_imagem(area, 9.0))
	UiTema.rotulo(faixa, texto, UiTema.R1, gx + iw + 4.0, UiTema.y_texto(area))


## Carimbo REVANCHE (a marca que fica no quadro depois da derrota).
func _carimbo_revanche(y: float) -> void:
	var texto := UiTema.txt("alley_revenge_mark", "REVANCHE")
	var w := roundf(UiTema.largura_visivel(texto)) + 14.0
	if int(w) % 2 != 0:
		w += 1.0
	var c := UiTema.nine_patch(painel, "c_carimbo_moldura", Rect2(320.0 - w / 2.0, y, w, 16))
	c.set_meta("ui_pos", "center_h")
	UiTema.rotulo_centrado(c, UiTema.area_nove("c_carimbo_moldura", Vector2(w, 16)), texto, UiTema.R1, 1, false, "center")
