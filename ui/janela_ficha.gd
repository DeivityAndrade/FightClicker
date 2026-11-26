class_name JanelaFicha
extends JanelaBase
## Ronda 2a1: a ficha de um bandido já vencido (clicar em LER na parede do Dossiê): retrato, nome e apelido, ficha corrida, a manchete do
## dia seguinte, a testemunha (nunca diz quem é o vulto), o carimbo da campanha e o desafio. Só lê o item de `GameState.dossie()`.

signal fechar_pedido

const X0 := 164.0
const X1 := 476.0
const LARG := 312.0


func abrir_com(f: Dictionary) -> void:
	var linhas: Array = []  # {h, f}
	var rap := str(f.get("rap_sheet", "")).to_upper()
	var manchete := str(f.get("headline", "")).to_upper()
	var testemunha := str(f.get("witness", "")).to_upper()
	var h := 18.0 + 6.0 + 36.0 + 8.0  # faixa do título + ar + retrato + ar
	var n_rap := _linhas_de(rap)
	var n_man := _linhas_de(manchete)
	var n_tes := _linhas_de(testemunha)
	h += 9.0 * float(n_rap) + 8.0 + 9.0 * float(n_man) + 8.0 + 9.0 * float(n_tes) + 8.0
	h += 12.0 + 12.0 + 8.0 + 38.0  # carimbo, desafio, ar, botão e margem
	h = ceilf(h)
	var topo := floorf((360.0 - (h + SOMBRA)) / 2.0)
	moldura("ui_window", Rect2(152, topo, 336, h))
	faixa_titulo("neutral", Rect2(154, topo + 2.0, 332, 16), str(f.get("name", "")).to_upper())
	var y := topo + 24.0
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("opp_alley_" + str(f.get("bandit", "")), {})
	var q := UiTema.textura_rect(painel, "c_retrato_moldura", X0, y)
	UiTema.textura_rect(q, str(info.get("portrait", "")), 2, 2)
	UiTema.rotulo(painel, str(f.get("nickname", "")).to_upper(), UiTema.R1, X0 + 42, y + 5)
	UiTema.rotulo(painel, str(f.get("profile", "")).to_upper(), UiTema.cor_nome(str(info.get("color", "g3"))), X0 + 42, y + 17)
	var p: Dictionary = f.get("passive", {})
	if not p.is_empty():
		var ic := str(UiTema.manifest().get("by_data_id", {}).get("opp_passives", {}).get(str(p.get("id", "")), {}).get("icon_9", ""))
		var px := X0 + 42.0
		if ic != "" and not UiTema.sprite(ic).is_empty():
			UiTema.textura_rect(painel, ic, px, y + 27)
			px += 12.0
		UiTema.rotulo(painel, str(p.get("name", "")).to_upper(), UiTema.G3, px, y + 27)
	y += 44.0
	y += _bloco(rap, UiTema.WHITE, y, n_rap)
	y += _bloco(manchete, UiTema.R3, y, n_man)
	y += _bloco(testemunha, UiTema.G3, y, n_tes)
	UiTema.rotulo_centro(painel, str(f.get("stamp", "")).to_upper(), UiTema.Y1, 320.0, y)
	y += 12.0
	UiTema.rotulo_centro(painel, str(f.get("challenge_text", "")).to_upper(), UiTema.GR3 if bool(f.get("challenge", false)) else UiTema.G3, 320.0, y)
	var b := botao_texto(Rect2(240, topo + h - 12.0 - 26.0, 160, 26), UiTema.txt("hideout_close", "FECHAR"), UiTema.WHITE, "", 1, "", true)
	b.pressed.connect(func() -> void: fechar_pedido.emit())
	animar_entrada()


func _linhas_de(texto: String) -> int:
	if texto == "":
		return 0
	var fonte := UiTema.fonte()
	var tam := fonte.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, LARG, UiTema.TAMANHO_FONTE)
	return maxi(1, int(roundf(tam.y / fonte.get_height(UiTema.TAMANHO_FONTE))))


func _bloco(texto: String, cor: Color, y: float, n: int) -> float:
	if n == 0:
		return 0.0
	var l := UiTema.rotulo(painel, texto, cor, X0, y, LARG, HORIZONTAL_ALIGNMENT_CENTER)
	l.size.y = 9.0 * float(n)
	UiTema.alinhar(l, "center_h")
	return 9.0 * float(n) + 8.0
