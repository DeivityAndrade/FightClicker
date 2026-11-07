class_name JanelaAposentar
extends JanelaBase
## Confirmação de APOSENTAR: mostra quanto Legado você leva (100% do pote, mais o bônus de sair com o
## cinturão), avisa que tudo da carreira se perde e pede para confirmar. Aposentar com o pote zerado é permitido
## ("você leva 0 de Legado"). Não muda nada até o jogador confirmar.

signal confirmou
signal cancelou


func abrir_com(previa: Dictionary) -> void:
	moldura("ui_end_frame_retire", Rect2(170, 50, 300, 236))
	faixa_titulo("retire", Rect2(178, 58, 284, 22), UiTema.txt("retire_confirm_title", "PENDURAR AS LUVAS?"), UiTema.WHITE, 2)
	var luvas := UiTema.nome_luvas_penduradas()
	var luvas_rect := UiTema.textura_rect(painel, luvas, roundf(320.0 - UiTema.tamanho_quadro(luvas).x / 2.0), 90)
	luvas_rect.set_meta("ui_pos", "center_h")

	var y := 152.0
	var zero := bool(previa.get("zero", false))
	var texto := UiTema.txt("retire_confirm_zero", "VOCÊ LEVA 0 DE LEGADO") if zero \
		else UiTema.txt("retire_confirm_take", "VOCÊ LEVA {n} DE LEGADO", {"n": int(previa.total)})
	var total := 16.0 + 4.0 + UiTema.largura_visivel(texto)
	var x0 := roundf(320.0 - total / 2.0)
	UiTema.textura_rect(painel, "icon_legacy_16", x0, y - 2.0)  # ícone de 16 px na altura do texto
	UiTema.rotulo(painel, texto, UiTema.P2 if not zero else UiTema.G3, x0 + 20.0, y)
	y += 15.0
	if bool(previa.get("cinturao", false)) and int(previa.get("bonus", 0)) > 0:
		UiTema.rotulo_centro(painel, UiTema.txt("retire_confirm_bonus", "INCLUI +{n} POR SAIR COM O CINTURÃO",
			{"n": int(previa.bonus)}), UiTema.Y1, 320.0, y)
		y += 12.0
	y += 4.0
	divisor(190, y, 260)
	y += 8.0
	UiTema.rotulo_centro(painel, UiTema.txt("retire_confirm_lose", "TUDO DESTA CARREIRA SE PERDE"), UiTema.R3, 320.0, y)

	var sim := botao_texto(Rect2(186, 242, 130, 30), UiTema.txt("retire_yes", "APOSENTAR"), UiTema.P2, "", 1, "ui_button_retire")
	sim.pressed.connect(func() -> void: confirmou.emit())
	var nao := botao_texto(Rect2(324, 242, 130, 30), UiTema.txt("retire_no", "CONTINUAR"))
	nao.pressed.connect(func() -> void: cancelou.emit())
	animar_entrada()
