extends RefCounted
## Cena "torta de propósito" para provar que o verificador pega cada regra (ui_audit.gd -- --torta).
## Cada peça abaixo erra de um jeito só. Não usa a classe UiTema pelo nome (compila antes dos autoloads).

## Regras que a cena torta TEM de reprovar (código no começo da linha do relatório).
const ESPERADOS := ["TXT_OFFCENTER", "CLIPPED", "IGNORE_SEM_MOTIVO", "IGNORE_PROIBIDO", "OPACO_FORA", "JANELA_ASSIM", "JANELA_MARGEM",
	"TXT_SOZINHO", "DRAW_TEXTO", "TXT_COLADO", "TXT_NA_MOLDURA", "TXT_CONTRASTE", "FOLGA_VIZINHO"]
## As regras novas (as de ESPERADOS que não existiam antes): no modo padrão elas NÃO podem virar problema.
const NOVAS := ["IGNORE_SEM_MOTIVO", "IGNORE_PROIBIDO", "OPACO_FORA", "JANELA_ASSIM", "JANELA_MARGEM", "TXT_SOZINHO", "DRAW_TEXTO",
	"TXT_COLADO", "TXT_NA_MOLDURA", "TXT_CONTRASTE", "FOLGA_VIZINHO"]


static func montar(raiz: Control) -> void:
	var T = load("res://ui/ui_tema.gd")
	var cor := Color.WHITE
	raiz.size = Vector2(640, 360)

	# 1. Botão com o texto fora do centro (Label filho colado à esquerda): TXT_OFFCENTER.
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.position = Vector2(400, 20)
	b.size = Vector2(100, 24)
	raiz.add_child(b)
	T.rotulo(b, "TORTO", cor, 4, 8)

	# 2. Texto cortado: o rótulo é mais estreito que o texto: CLIPPED.
	var cortado: Label = T.rotulo(raiz, "TEXTO MUITO LONGO PARA CAIR", cor, 20, 20)
	cortado.clip_text = true
	cortado.size = Vector2(30, 12)

	# 3. ignore sem motivo: IGNORE_SEM_MOTIVO.
	var sem_motivo := Panel.new()  # Panel: Control puro sem texto agora é arte isenta
	sem_motivo.position = Vector2(20, 60)
	sem_motivo.size = Vector2(10, 10)
	sem_motivo.mouse_filter = Control.MOUSE_FILTER_IGNORE  # com mouse ativo e sem filhos seria área de hover (isenta)
	sem_motivo.set_meta("ui_align", "ignore")
	raiz.add_child(sem_motivo)

	# 4. ignore (com motivo) em Button: IGNORE_PROIBIDO.
	var b_ign := Button.new()
	b_ign.position = Vector2(40, 60)
	b_ign.size = Vector2(60, 20)
	b_ign.text = "X"
	T.ignorar(b_ign, "motivo escrito, mas é botão")
	raiz.add_child(b_ign)

	# 5. ignore (com motivo) que engole um Label de texto fixo: IGNORE_PROIBIDO.
	var caixa_ign := Control.new()
	caixa_ign.position = Vector2(120, 60)
	caixa_ign.size = Vector2(100, 20)
	T.ignorar(caixa_ign, "motivo escrito, mas engole texto fixo")
	raiz.add_child(caixa_ign)
	T.rotulo(caixa_ign, "FIXO", cor, 2, 4)

	# 6. Sprite opaco saindo de 640x360: OPACO_FORA.
	var spr := Sprite2D.new()
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.position = Vector2(630, 350)
	raiz.add_child(spr)

	# 7. Janela fora do centro da tela (esq 100, dir 240) e com conteúdo de margens desiguais: JANELA_ASSIM e JANELA_MARGEM.
	var jan := Panel.new()
	jan.position = Vector2(100, 150)
	jan.size = Vector2(300, 160)
	raiz.add_child(jan)
	T.rotulo(raiz, "DENTRO", cor, 110, 160)

	# 8. Texto sozinho na linha, colado à esquerda de uma caixa: TXT_SOZINHO.
	var caixa := Control.new()
	caixa.position = Vector2(430, 100)
	caixa.size = Vector2(200, 40)
	raiz.add_child(caixa)
	T.rotulo(caixa, "SOZINHO", cor, 6, 14)

	# 9. Texto desenhado por código com o centro errado (o registro diz x0=0 numa área de 100 px): DRAW_TEXTO.
	var des := Control.new()
	des.position = Vector2(430, 200)
	des.size = Vector2(100, 20)
	des.set_meta("ui_texto_desenhado", {"x": {"area": Rect2(0, 0, 100, 20), "x0": 0.0, "texto": "TORTO", "escala": 1, "lw": 30.0}})
	raiz.add_child(des)

	# 10. (R1) O caso B1 da ID2: cartão sem ui_indent, contador "0/4" centralizado, colado na borda, com autowrap de largura igual
	# ao texto e a 1 px do botão logo abaixo: TXT_COLADO.
	var cartao := Control.new()
	cartao.position = Vector2(240, 20)
	cartao.size = Vector2(120, 44)
	raiz.add_child(cartao)
	T.painel(cartao, "ui_card", Rect2(0, 0, 120, 44))
	T.rotulo(cartao, "0/4", cor, 4, 18, 18, HORIZONTAL_ALIGNMENT_CENTER)
	T.botao(cartao, Rect2(4, 28, 112, 14))

	# 11. (R2) O caso B2: selo carimbo com a moldura de 12 px de altura (margens de 4): o texto de 7 px não cabe nos 4 px internos:
	# TXT_NA_MOLDURA.
	var selo := Control.new()
	selo.position = Vector2(240, 100)
	selo.size = Vector2(80, 12)
	raiz.add_child(selo)
	T.nine_patch(selo, "c_carimbo_moldura", Rect2(0, 0, 80, 12))
	T.rotulo(selo, "EQUILIBRADO", cor, 6, 2)

	# 12. (R3) G2 sobre D2 (o contador 0/4 da loja): 3,46:1, abaixo de 4,5:1: TXT_CONTRASTE.
	var fundo := ColorRect.new()
	fundo.color = Color("3d3346")
	fundo.position = Vector2(240, 140)
	fundo.size = Vector2(80, 20)
	raiz.add_child(fundo)
	T.rotulo(fundo, "BAIXO", Color("8f8890"), 10, 6)

	# 13. (FOLGA_VIZINHO) réplicas do B1 e do B2 da ID3, numa janela de verdade (JanelaBase, moldura c_janela).
	var JB = load("res://ui/janela_base.gd")
	var jan_b = JB.new()
	jan_b.name = "JanelaTorta"
	raiz.add_child(jan_b)
	jan_b.moldura("", Rect2(410, 170, 220, 160))
	var painel_j: Control = jan_b.painel
	# B1 (Ronda): botão VOLTAR a 0 px da borda interna e "NÍVEL 2" a 1 px dele.
	T.rotulo(painel_j, "NÍVEL 2", cor, 456, 300)
	var voltar: Button = T.botao(painel_j, Rect2(450, 310, 140, 20))
	T.rotulo(voltar, "VOLTAR", cor, 50, 6)
	# B2 (mural): descrição de 2 linhas e a tarja (desenhada depois) cobrindo a 2ª linha.
	var desc: Label = T.rotulo(painel_j, "COMPRA NO FIM\nDA CAMPANHA", cor, 420, 184)
	desc.autowrap_mode = TextServer.AUTOWRAP_OFF
	var tarja := ColorRect.new()
	tarja.color = Color("3d3346")
	tarja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarja.position = Vector2(418, 195)
	tarja.size = Vector2(120, 12)
	painel_j.add_child(tarja)
