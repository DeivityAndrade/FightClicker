extends "make_tema_c.gd"
## Identidade, parte ID3: as peças do tema C (cartaz de luta) que ainda estavam no estilo antigo. Diretor de Arte.
## Herda os ajudantes do make_tema_c.gd (paleta, fonte, papel/asfalto, 9-slice, medidas, contraste, manifest) e troca só o _main.
## Rodar de uma pasta com project.godot vazio (não dispara import no projeto), headless:
##   godot --headless --max-fps 30 --path <pasta_vazia> --script <worktree>/tools/art/make_tema_c_id3.gd -- --root <worktree>
## Grava:
##   assets/sprites/ui/tema_c/  balão, plaquinhas do nome, placa do calendário, cartão da mudança, selos de risco 16 px,
##                              fundo de tela cheia, faixa de tela, barra de vida, peças do mapa, molduras de retrato
##   assets/sprites/ui/tema_c/manifest_tema_c.json  (junta as entradas novas com as do make_tema_c.gd)
##   docs/arte/mockups/identidade/tema_c_pecas_id3_x2.png  (prancha montada COM as PNGs gravadas, em 2x só para ver)
## Spec: docs/arte/tema-c-spec.md §6. Meta: 0 avisos (centro do texto e contraste).

const NOVE3 := {
	"c_balao": [5, 5, 5, 5],
	"c_balao_placa_red": [2, 2, 2, 2], "c_balao_placa_gold": [2, 2, 2, 2], "c_balao_placa_blue": [2, 2, 2, 2],
	"c_balao_placa_green": [2, 2, 2, 2], "c_balao_placa_purple": [2, 2, 2, 2], "c_balao_placa_gray": [2, 2, 2, 2],
	"c_balao_placa_steel": [2, 2, 2, 2],
	"c_contagem_easy": [5, 2, 2, 4], "c_contagem_even": [5, 2, 2, 4], "c_contagem_hard": [5, 2, 2, 4],
	"c_contagem_today": [5, 2, 2, 4], "c_contagem_done": [5, 2, 2, 4],
	"c_mudanca": [5, 5, 5, 7], "c_mudanca_pronto": [5, 5, 5, 7], "c_mudanca_apagado": [5, 5, 5, 7],
	"c_selo_risco_perigoso_base": [16, 3, 3, 5], "c_selo_risco_equilibrado_base": [16, 3, 3, 5], "c_selo_risco_facil_base": [16, 3, 3, 5],
	"c_tela_asfalto": [0, 0, 0, 0], "c_faixa_tela": [0, 1, 0, 3],
	"c_vida_moldura": [2, 2, 2, 2], "c_vida_cheia": [1, 0, 1, 0], "c_vida_baixa": [1, 0, 1, 0], "c_vida_rastro": [1, 0, 1, 0],
	"c_mapa_moldura": [5, 5, 5, 5], "c_mapa_topo": [1, 1, 1, 2], "c_mapa_ficha": [3, 3, 3, 5], "c_mapa_ficha_proxima": [1, 1, 1, 1],
	"c_mapa_preco_ok": [2, 2, 2, 1], "c_mapa_preco_falta": [2, 2, 2, 1],
	"c_cartao_apagado": [2, 2, 2, 4],
}
## Plaquinha do nome: cor do balão -> [corpo, filete de luz, texto]. O texto segue o `tag_text_color` do manifest
## ("white" -> WHITE, o resto -> INK), então o código do balão não muda.
const PLACAS := {
	"red": ["r1", "r2", "white"], "gold": ["y1", "y2", "ink"], "blue": ["b3", "white", "ink"], "green": ["gr3", "y2", "ink"],
	"purple": ["p2", "f2", "ink"], "gray": ["g3", "white", "ink"], "steel": ["st0", "st1", "white"],
}
## Placa do calendário: risco -> [faixa da esquerda, corpo, linha 1, linha 2].
const CONTAGEM := {
	"easy": ["gr2", "cream", "ink", "g0"], "even": ["y0", "cream", "ink", "g0"], "hard": ["r2", "cream", "ink", "g0"],
	"today": ["y1", "r1", "y2", "cream"], "done": ["b1", "cream", "br1", "br1"],
}
## Selo de risco: nome -> [chave do jogo, corpo, luz, texto, palavra].
const SELOS := {
	"perigoso": ["hard", "r1", "r2", "cream", "PERIGOSO"],
	"equilibrado": ["even", "y1", "y2", "ink", "EQUILIBRADO"],
	"facil": ["easy", "gr3", "y2", "ink", "FÁCIL"],
}
const REGIOES := ["garage", "gym", "boxing", "bjj", "muay_thai", "campaign", "center", "black_cat"]

var cores_regiao := {}


func _main() -> void:
	for k in NOVE3:
		nove_map[k] = NOVE3[k]
	print("== ID3: balão e plaquinhas")
	_balao()
	print("== ID3: calendário, mudança, selos")
	_contagem()
	_mudanca()
	_selos()
	print("== ID3: telas cheias (fundo, faixa, vida, mapa, retratos)")
	_telas()
	print("== ID3: medidas e contraste")
	_medir_id3()
	print("== PRANCHA")
	_prancha_id3().save_png(MOCK_OUT + "tema_c_pecas_id3_x2.png")
	_manifest_tema()
	print("== peças gravadas:")
	for p in pecas:
		print("  %-36s %-9s %s %s" % [p[0], p[1], p[2], p[3]])
	print("== TOTAL: %d aviso(s) %s" % [avisos.size(), str(avisos) if avisos.size() > 0 else ""])


# ================================================================= ajudantes
## Face com borda ink de 1 px e cantos cortados (1 px), luz de 1 px em cima e sombra dura `sombra` px RETA para baixo.
func caixa(w: int, h_face: int, sombra: int, corpo: Callable, luz = null, borda := "ink") -> Image:
	var im := novo(w, h_face + sombra)
	if sombra > 0:  # a 1ª linha da sombra segue os cantos cortados da face; as outras vão de ponta a ponta
		hl(im, 1, h_face, w - 2, "ink")
		rect(im, 0, h_face + 1, w, sombra - 1, "ink")
	for y in h_face:
		for x in w:
			var c = corpo.call(x, y)
			if x == 0 or y == 0 or x == w - 1 or y == h_face - 1:
				c = borda
			elif y == 1 and luz != null:
				c = luz
			if c != null:
				px(im, x, y, c)
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h_face - 1), Vector2i(w - 1, h_face - 1)]:
		limpa(im, p.x, p.y)
	return im


func papel(per := 8, ox := 0, oy := 0) -> Callable:
	return func(x: int, y: int) -> String: return papel_px(x - ox, y - oy, per)


func papel_apagado(per := 8, ox := 0, oy := 0) -> Callable:
	return func(x: int, y: int) -> String: return "g2" if papel_px(x - ox, y - oy, per) == "g3" else "g3"


func liso(c: String) -> Callable:
	return func(_x: int, _y: int) -> String: return c


## Converte uma cor qualquer para a chave da paleta mais próxima.
func chave(c: Color) -> String:
	var melhor := "ink"
	var dmin := 99.0
	for k in PAL:
		var p := C(k)
		var d := absf(p.r - c.r) + absf(p.g - c.g) + absf(p.b - c.b)
		if d < dmin:
			dmin = d
			melhor = k
	return melhor


# ================================================================= 1. balão de fala
func _balao() -> void:
	# corpo 16x16: face 15 (borda ink com canto de 2 px, filete white) + sombra ink de 1 RETA para baixo
	var b := novo(16, 16)
	for y in 15:
		for x in 16:
			var c := papel_px(x - 5, y - 5, 8)
			if x == 0 or x == 15 or y == 0 or y == 14:
				c = "ink"
			elif y == 1:
				c = "white"
			px(b, x, y, c)
	for p in [Vector2i(0, 0), Vector2i(15, 0), Vector2i(0, 14), Vector2i(15, 14)]:
		limpa(b, p.x, p.y)
	for p in [Vector2i(1, 1), Vector2i(14, 1), Vector2i(1, 13), Vector2i(14, 13)]:
		px(b, p.x, p.y, "ink")
	hl(b, 1, 15, 14, "ink")
	salvar_ui(b, "c_balao", "L5 T5 R5 B5", "ladrilho; rect = corpo inteiro (17 ou 26 de altura), a sombra é a última LINHA (não há mais sombra à direita)")
	# rabichos 7x6 (K = ink, c = papel); a linha 0 cai no contorno de baixo do corpo e o apaga
	var formas := {
		"c_balao_rabicho": ["KcccccK", ".KcccK.", "..KcK..", "..KcK..", "...K...", "...K..."],
		"c_balao_rabicho_e": ["KcccccK", "KcccK..", "KccK...", "KcK....", "KK.....", "K......"],
		"c_balao_rabicho_d": ["KcccccK", "..KcccK", "...KccK", "....KcK", ".....KK", "......K"],
	}
	var pontas := {"c_balao_rabicho": "ponta (3,5)", "c_balao_rabicho_e": "ponta (0,5)", "c_balao_rabicho_d": "ponta (6,5)"}
	for n in formas:
		var t := novo(7, 6)
		var linhas: Array = formas[n]
		for y in 6:
			var l: String = linhas[y]
			for x in 7:
				if l[x] == "K":
					px(t, x, y, "ink")
				elif l[x] == "c":
					px(t, x, y, "cream")
		salvar_ui(t, n, "", "fixo 7x6; " + pontas[n] + " (mesmo tip_offset do ui_balloon_tail*)")
	# seta de fim de fala: 2 quadros 5x4 lado a lado (aceso r1, apagado g3); sombra ink de 1 embaixo da ponta
	var s := novo(10, 4)
	for f in 2:
		var cor := "r1" if f == 0 else "g3"
		hl(s, f * 5, 0, 5, cor)
		hl(s, f * 5 + 1, 1, 3, cor)
		px(s, f * 5 + 2, 2, cor)
		px(s, f * 5 + 2, 3, "ink")
	salvar_ui(s, "c_balao_seta", "", "2 quadros 5x4 a 2 fps (aceso r1, apagado g3)")
	# plaquinhas do nome (8x10, 9-slice 2): fita de cor com contorno ink e cantos cortados
	for cor in PLACAS:
		var a: Array = PLACAS[cor]
		var pl := caixa(8, 10, 0, liso(a[0]), a[1])
		# ponta da direita cortada em serrilha (fita rasgada): a borda de fora fica só nas linhas pares e a de dentro
		# entra 1 px nas ímpares; a face lida termina em x = w - 2 e o nome (em x 3) fica no meio dela.
		for y in range(1, 9):
			if y % 2 == 1:
				limpa(pl, 7, y)
				px(pl, 6, y, "ink")
		salvar_ui(pl, "c_balao_placa_" + cor, "L2 T2 R2 B2", "altura 10, largura = largura visível do nome + 7; texto minúsculo " + str(a[2]) + " em (3,2)")


# ================================================================= 2. calendário e mudança
func _contagem() -> void:
	for r in CONTAGEM:
		var a: Array = CONTAGEM[r]
		var corpo := papel(8, 5, 2) if a[1] == "cream" else liso(a[1])
		var luz := "white" if a[1] == "cream" else "r2"
		var im := caixa(16, 16, 2, corpo, luz)
		for y in range(1, 15):
			for x in range(1, 4):
				px(im, x, y, a[0])
			px(im, 4, y, "ink")
		salvar_ui(im, "c_contagem_" + r, "L5 T2 R2 B4", "uso 116x28 (face 26 + sombra 2); faixa da esquerda " + str(a[0]))


func _mudanca() -> void:
	var cfg := {"c_mudanca": ["cream", false], "c_mudanca_pronto": ["cream", true], "c_mudanca_apagado": ["g3", false]}
	for n in cfg:
		var a: Array = cfg[n]
		var corpo: Callable = papel(16, 5, 5)
		if a[0] != "cream":
			corpo = papel_apagado(16, 5, 5)
		var im := caixa(26, 20, 2, corpo, "white" if a[0] == "cream" else "cream")
		if a[1]:  # faixa de cartaz em cima (r2 com listras r1, período 16 = o miolo do 9-slice)
			for y in range(1, 4):
				for x in range(1, 25):
					var k := posmod(x - 5 + y, STRIPE)
					px(im, x, y, "r1" if k < 3 else "r2")
			hl(im, 1, 4, 24, "ink")
		# pedaços de fita nos cantos de cima (white com borda g3), dentro do canto de 5x5
		for y in 5:
			for x in 5:
				var d := x + y
				if d >= 1 and d <= 4:
					var c := "g3" if d == 1 or d == 4 else "white"
					px(im, x, y, c)
					px(im, 25 - x, y, c)
		salvar_ui(im, n, "L5 T5 R5 B7", "ladrilho; rect +2 px de altura (sombra)")


func _selos() -> void:
	for n in SELOS:
		var a: Array = SELOS[n]
		var w := 16 + tw(a[4]) + 7
		salvar_ui(_selo(w, a, true), "c_selo_risco_" + n, "", "fixo %dx16; risco %s; texto %s" % [w, a[0], a[3]])
		salvar_ui(_selo(24, a, false), "c_selo_risco_" + n + "_base", "L16 T3 R3 B5", "9-slice para outra palavra; texto " + str(a[3]))


## Selo 16 px: face 14 + sombra 2. À esquerda, o cabo ink com o ícone do risco (cores próprias), corte diagonal 1:3; à direita,
## o corpo na cor do risco com a palavra. Área do texto: de x 16 até a borda (margem 3).
func _selo(w: int, a: Array, com_texto: bool) -> Image:
	var corpo: String = a[1]
	var im := caixa(w, 14, 2, liso(corpo), a[2])
	for y in range(1, 13):
		var e := 12 + (13 - y) / 4  # corte diagonal do cabo
		for x in range(1, e):
			px(im, x, y, "ink")
		px(im, e, y, "ink" if y % 2 == 0 else corpo)
	blit(im, icon("icon_risk_" + str(a[0])), 2, 2)
	if com_texto:
		var sh = Vector2i(0, 1) if a[3] == "cream" else null
		tx_c(im, a[4], Rect2i(16, 0, w - 19, 14), a[3], 1, sh)
	return im


# ================================================================= 4. telas cheias
func _telas() -> void:
	# asfalto em ladrilho (qualquer tamanho) e o fundo pronto 640x360 com as faixas de cartaz
	var asf := novo(16, 16)
	for y in 16:
		for x in 16:
			px(asf, x, y, asfalto_px(x, y))
	salvar_ui(asf, "c_tela_asfalto", "", "ladrilho 16x16 (TextureRect stretch TILE)")
	salvar_ui(_tela_fundo(), "c_tela_fundo", "", "fixo 640x360: fundo das telas cheias sem cenário")
	# faixa do topo das telas cheias (HUD da luta, criação, minigames): asfalto + fio ink + fio r1 + sombra em dither
	var fx := novo(16, 20)
	for y in 17:
		for x in 16:
			px(fx, x, y, "d2" if y == 0 else asfalto_px(x, y - 1))
	hl(fx, 0, 17, 16, "ink")
	hl(fx, 0, 18, 16, "r1")
	for x in 16:
		if x % 2 == 0:
			px(fx, x, 19, "ink")
	salvar_ui(fx, "c_faixa_tela", "L0 T1 R0 B3", "ladrilho; HUD da luta 640x49 (46 + 3 por cima da arena)")

	# barra de vida estilo cartaz (12 de altura; o preenchimento fica dentro, 2 px de margem)
	var mol := novo(16, 12)
	for y in 12:
		for x in 16:
			var c := "d2" if posmod(x + y, 4) == 0 else "d1"
			if x == 0 or y == 0 or x == 15 or y == 11:
				c = "ink"
			elif x == 1 or y == 1 or x == 14 or y == 10:
				c = "cream"
			px(mol, x, y, c)
	for p in [Vector2i(0, 0), Vector2i(15, 0), Vector2i(0, 11), Vector2i(15, 11)]:
		limpa(mol, p.x, p.y)
	salvar_ui(mol, "c_vida_moldura", "L2 T2 R2 B2", "ladrilho; uso 236x12; miolo vazio d1 com hachura d2")
	var fills := {"c_vida_cheia": ["y1", "y2", "y0", true], "c_vida_baixa": ["r2", "r3", "r1", true], "c_vida_rastro": ["cream", "white", "g3", false]}
	for n in fills:
		var a: Array = fills[n]
		var f := novo(18, 8)
		for y in 8:
			for x in 18:
				var c: String = a[0]
				if y == 0:
					c = a[1]
				elif y == 7 or x == 0 or x == 17:
					c = a[2]
				elif a[3] and posmod(x - 1 - y, 8) == 0:
					c = a[2]
				px(f, x, y, c)
		salvar_ui(f, n, "L1 T0 R1 B0", "ladrilho na horizontal dentro da moldura (área 8 de altura)")

	# mapa
	var mm := novo(24, 24)
	for y in 24:
		for x in 24:
			var d := mini(mini(x, y), mini(23 - x, 23 - y))
			var c = null
			if d == 0 or d == 4:
				c = "ink"
			elif d == 3:
				c = "r1"
			elif d < 3:
				c = asfalto_px(x, y)
			if c != null:
				px(mm, x, y, c)
	for cx in [1, 21]:  # cantoneiras de papel
		for cy in [1, 21]:
			rect(mm, cx, cy, 2, 2, "cream")
	salvar_ui(mm, "c_mapa_moldura", "L5 T5 R5 B5", "ladrilho, miolo vazio; 640x360 por cima do mapa")
	var topo := novo(16, 20)
	for y in 20:
		for x in 16:
			var c := asfalto_px(x, y)
			if x == 0 or x == 15 or y == 0:
				c = "ink"
			elif y == 1:
				c = "d2"
			elif y == 18:
				c = "ink"
			elif y == 19:
				c = "r1"
			px(topo, x, y, c)
	salvar_ui(topo, "c_mapa_topo", "L1 T1 R1 B2", "ladrilho; 630x20 em (5,5); texto cream")
	var ficha := caixa(16, 16, 2, papel(8, 3, 3), "white")
	hl(ficha, 1, 2, 14, "r2")  # a linha vermelha da ficha
	for i in 3:  # orelha dobrada no canto de baixo à direita
		for j in 3 - i:
			px(ficha, 14 - j, 14 - i, "g3")
	px(ficha, 12, 14, "ink"); px(ficha, 13, 13, "ink"); px(ficha, 14, 12, "ink")
	salvar_ui(ficha, "c_mapa_ficha", "L3 T3 R3 B5", "ladrilho; cartão do nó; rect +2 px (sombra); texto ink")
	var prox := caixa(16, 13, 0, liso("p0"), "p1")
	salvar_ui(prox, "c_mapa_ficha_proxima", "L1 T1 R1 B1", "faixa VALE NA PRÓXIMA CAMPANHA; texto cream")
	var pok := caixa(12, 11, 0, papel(8, 2, 2), "white")
	salvar_ui(pok, "c_mapa_preco_ok", "L2 T2 R2 B1", "preço que o Legado paga; número p0")
	var pfa := caixa(12, 11, 0, liso("d2"), "g0")
	salvar_ui(pfa, "c_mapa_preco_falta", "L2 T2 R2 B1", "preço sem Legado; número g3")
	for rid in REGIOES:
		var velho: String = ROOT + "/assets/sprites/ui/map/ui_map_region_label_" + rid + ".png"
		var cor := "g2"
		if FileAccess.file_exists(velho):
			cor = chave(_img(velho).get_pixel(2, 6))
		if cor in ["g3", "cream", "white"]:  # giz (garagem): no papel some; um passo mais escuro
			cor = "g2"
		cores_regiao[rid] = cor
		nove_map["c_mapa_aba_" + rid] = [5, 2, 2, 2]
		print("  região %-10s faixa antiga -> %s" % [rid, cor])
		var aba := caixa(16, 13, 0, papel(8, 5, 2), "white")
		for y in range(1, 12):
			for x in range(1, 4):
				px(aba, x, y, cor)
			px(aba, 4, y, "ink")
		salvar_ui(aba, "c_mapa_aba_" + rid, "L5 T2 R2 B2", "aba da região (faixa %s); ícone em (5,2), texto ink em (17,3)" % cor)
	var fechar := {"normal": ["cream", "white", "ink", 0, "r1"], "hover": ["r1", "r2", "cream", 0, "ink"], "pressed": ["r1", "r0", "cream", 2, ""]}
	for st in fechar:
		var a: Array = fechar[st]
		var im := novo(16, 16)
		var dy: int = a[3]
		if a[4] != "":
			rect(im, 0, 14, 16, 2, a[4])
		var face := caixa(16, 14, 0, liso(a[0]) if a[0] != "cream" else papel(8), a[1])
		blit(im, face, 0, dy)
		for i in 6:  # X de 2 px de traço, 6x6, no meio da face
			for k in 2:
				px(im, 5 + i + k, 4 + i + dy, a[2])
				px(im, 10 - i + k, 4 + i + dy, a[2])
		salvar_ui(im, "c_mapa_fechar_" + st, "", "fixo 16x16 em (616,7)")

	# retratos
	for n in ["c_retrato_moldura", "c_retrato_moldura_ouro"]:
		var im := novo(36, 36)
		var ouro: bool = n.ends_with("ouro")
		frame(im, 0, 0, 36, 36, "ink")
		frame(im, 1, 1, 34, 34, "y1" if ouro else "cream")
		hl(im, 2, 1, 32, "y2" if ouro else "white")
		hl(im, 2, 34, 32, "y0" if ouro else "g3")
		for p in [Vector2i(0, 0), Vector2i(35, 0), Vector2i(0, 35), Vector2i(35, 35)]:
			limpa(im, p.x, p.y)
		if ouro:
			for p in [Vector2i(1, 1), Vector2i(34, 1), Vector2i(1, 34), Vector2i(34, 34)]:
				px(im, p.x, p.y, "r2")
		salvar_ui(im, n, "", "fixo 36x36; furo 32x32 em (2,2)")
	for n in ["c_mural_moldura", "c_mural_moldura_primeiro"]:
		var im := novo(62, 66)
		var pri: bool = n.ends_with("primeiro")
		frame(im, 0, 0, 62, 66, "ink")
		frame(im, 1, 1, 60, 64, "y1" if pri else "cream")
		hl(im, 2, 1, 58, "y2" if pri else "white")
		hl(im, 2, 64, 58, "y0" if pri else "g3")
		frame(im, 2, 2, 58, 62, "ink")
		for p in [Vector2i(0, 0), Vector2i(61, 0), Vector2i(0, 65), Vector2i(61, 65)]:
			limpa(im, p.x, p.y)
		if pri:  # cantoneiras vermelhas de cartaz
			for c in [Vector2i(1, 1), Vector2i(57, 1), Vector2i(1, 61), Vector2i(57, 61)]:
				rect(im, c.x, c.y, 4, 4, "r1")
				px(im, c.x + (0 if c.x == 1 else 3), c.y + (0 if c.y == 1 else 3), "r2")
		salvar_ui(im, n, "", "fixo 62x66; furo 56x60 em (3,3)")
	var fu := novo(56, 60)
	for y in 60:
		for x in 56:
			var c := asfalto_px(x, y)
			var u := x - (59 - y) / 2
			if u >= 4 and u < 22:
				c = "r1" if posmod(x + y, 6) < 2 else "r0"
			if y >= 53:
				c = "ink" if y == 53 else "d1"
			px(fu, x, y, c)
	salvar_ui(fu, "c_mural_fundo", "", "fixo 56x60: fundo do retrato do mural (asfalto + faixa de cartaz)")
	# cartão apagado (no lugar do ui_card_dim)
	var cap := caixa(12, 12, 2, papel_apagado(8, 2, 2), "cream")
	salvar_ui(cap, "c_cartao_apagado", "L2 T2 R2 B4", "ladrilho; rect +2 px (sombra); texto ink")


func _tela_fundo() -> Image:
	var im := novo(640, 360)
	for y in 360:
		for x in 640:
			px(im, x, y, asfalto_px(x, y))
	# faixa diagonal de cartaz no canto de cima à esquerda e no de baixo à direita (r2 com listras r1, fios cream e ink)
	for y in 360:
		for x in 640:
			var u := x + y  # linhas a 45°
			for faixa in [[0, 120], [880, 1000]]:
				var a: int = faixa[0]
				var b: int = faixa[1]
				if u >= a and u < b:
					var c := "r1" if posmod(x - y, STRIPE) < 6 else "r2"
					if u == a or u == b - 1:
						c = "ink"
					elif u == a + 1 or u == b - 2:
						c = "cream"
					elif u == a + 2 or u == b - 3:
						c = "ink"
					px(im, x, y, c)
	# marcas de rua apagadas (traço creme gasto) no meio, para o asfalto não ficar chapado
	for i in 6:
		var x0 := 140 + i * 64
		for x in range(x0, x0 + 28):
			for y in range(296, 299):
				if bayer(x, y) < 9:
					px(im, x, y, "d2")
	return im


# ================================================================= medidas
func _medir_id3() -> void:
	print("-- balão (texto ink, bloco centrado; face sem a linha de sombra)")
	for s in ["OI.", "BORA TREINAR, GAROTO!", "UM SOCO DE CADA VEZ"]:
		var w := clampi(s.length() * 6 + 16, 40, 172)
		var im := novo(w + 4, 30)
		nove_peca(im, "c_balao", Rect2i(2, 2, w, 17))
		var x0 := 2 + int(floor((w - tw(s)) / 2.0))
		tx(im, s, x0, 2 + 5, "ink")
		medir("c_balao 1 linha '%s'" % s, Rect2i(2, 2, w, 16), tx_box(s, x0, 7))
	print("-- plaquinhas (texto em (3,2), h 10)")
	# gap = pixels de corpo entre a borda e a letra; à direita a borda de dentro da serrilha fica em w - 2
	# Largura pedida para o balao.gd: w = largura VISÍVEL do nome + 7 (a regra antiga, nome x 6 + 6, deixa 2 a 4 px à direita
	# porque as minúsculas têm larguras diferentes; impressa só como informação).
	for nome in ["téo", "osmar", "james", "zé", "john"]:
		var w: int = tw(nome) + 7
		var ml := 3 - 1
		var mr := (w - 2) - (3 + tw(nome))
		var mr_velho: int = (nome.length() * 6 + 6 - 2) - (3 + tw(nome))
		var ok := absi(ml - mr) <= 1
		print("  %-30s esq %d dir %d %s  (regra antiga: dir %d)" % ["c_balao_placa '" + nome + "'", ml, mr, "ok" if ok else "AVISO", mr_velho])
		if not ok:
			avisos.append("placa " + nome)
	for cor in PLACAS:
		conferir_contraste("placa " + cor, PLACAS[cor][2], PLACAS[cor][0])
	print("-- selos de risco 16 px")
	for n in SELOS:
		var a: Array = SELOS[n]
		var w := 16 + tw(a[4]) + 7
		var x0 := 16 + int(floor((w - 19 - tw(a[4])) / 2.0))
		var t := tx_box(a[4], x0, ycap_in(0, 14))
		medir("c_selo_risco_" + n, Rect2i(13, 0, w - 13, 14), t)
		conferir_contraste("selo " + n, a[3], a[1])
	print("-- calendário 116x28 (linha 1 em y+5, linha 2 em y+15, texto em x 35)")
	for r in CONTAGEM:
		var a: Array = CONTAGEM[r]
		conferir_contraste("contagem %s linha 1" % r, a[2], a[1])
		conferir_contraste("contagem %s linha 2" % r, a[3], a[1])
	print("-- mapa e cartões")
	var ab := novo(80, 13)
	nove_peca(ab, "c_mapa_aba_garage", Rect2i(0, 0, 80, 13))
	var tb := tx_box("GARAGEM", 17, 3)
	# só a vertical conta (o texto da aba é alinhado à esquerda, depois do ícone): face 13 sem borda = linhas 1..11
	var mt := tb.position.y - 1
	var mb := 12 - tb.end.y
	print("  %-30s cima %d baixo %d %s" % ["c_mapa_aba (vertical)", mt, mb, "ok" if absi(mt - mb) <= 1 else "AVISO"])
	if absi(mt - mb) > 1:
		avisos.append("aba vertical")
	var pr := novo(40, 11)
	var pc := chip_em(pr, "c_mapa_preco_ok", Rect2i(0, 0, 40, 11), "12", "p0")
	medir("c_mapa_preco_ok (centrado)", pc[0], pc[1], 2, 1)
	conferir_contraste("ficha / aba / mudança", "ink", "cream")
	conferir_contraste("ficha 2ª linha", "g0", "cream")
	conferir_contraste("preço ok", "p0", "cream")
	conferir_contraste("preço falta", "g3", "d2")
	conferir_contraste("ficha próxima", "cream", "p0")
	conferir_contraste("topo do mapa", "cream", "d1")
	conferir_contraste("mudança apagada", "ink", "g3")
	conferir_contraste("mudança apagada 2ª linha", "br1", "g3", 1, true)
	conferir_contraste("cartão apagado", "ink", "g3")
	conferir_contraste("faixa de tela (nomes)", "cream", "d1")
	conferir_contraste("mapa fechar normal X", "ink", "cream")
	conferir_contraste("mapa fechar hover X", "cream", "r1")


# ================================================================= prancha
func _prancha_id3() -> Image:
	var b := novo(640, 432)
	b.fill(C("d2"))
	tx(b, "TEMA C, ID3: PEÇAS NOVAS EM 1X (NO TAMANHO DE USO)", 8, 6, "cream")
	# --- balões
	var y := 30
	_balao_em(b, Rect2i(16, y, 64, 17), "oi.", "red", "c", ["OI."])
	_balao_em(b, Rect2i(96, y, 154, 26), "téo", "blue", "e", ["BORA TREINAR,", "GAROTO! UM SOCO"])
	_balao_em(b, Rect2i(268, y, 100, 17), "osmar", "gold", "d", ["SEGURA ESSA."])
	var cores := ["green", "purple", "gray", "steel"]
	for i in 4:
		var nome: String = ["léo", "zuza", "zé", "james"][i]
		_balao_em(b, Rect2i(384 + i * 62, y, 56, 17), nome, cores[i], "c", ["..."])
	var seta := peca("c_balao_seta")
	blit(b, seta.get_region(Rect2i(0, 0, 5, 4)), 238, y + 17)
	# --- calendário
	y = 96
	tx(b, "PLACA DO CALENDÁRIO (116X28)", 8, y - 10, "g3")
	var linhas := {"easy": "FÁCIL", "even": "EQUILIBRADO", "hard": "PERIGOSO", "today": "HOJE!", "done": "FEITO"}
	var idx := 0
	for r in CONTAGEM:
		var a: Array = CONTAGEM[r]
		var x := 8 + idx * 124
		nove_peca(b, "c_contagem_" + r, Rect2i(x, y, 116, 28))
		tx(b, "FALTAM 3 DIAS" if r != "today" and r != "done" else ("DIA DA LUTA" if r == "today" else "CAMPANHA FEITA"), x + 9, y + 5, a[2])
		tx(b, linhas[r], x + 9, y + 15, a[3])
		idx += 1
	# --- mudança e selos
	y = 146
	tx(b, "CARTÃO DA MUDANÇA", 8, y - 10, "g3")
	var mud := [["c_mudanca", "MUDAR DE CASA"], ["c_mudanca_pronto", "DÁ PARA PAGAR"], ["c_mudanca_apagado", "SEM DINHEIRO"]]
	for k in 3:
		var x := 8 + k * 104
		nove_peca(b, mud[k][0], Rect2i(x, y, 96, 46))
		tx(b, mud[k][1], x + 8, y + 10, "ink")
		tx(b, "$ 5.00K", x + 8, y + 22, "br1" if k < 2 else "ink")
	tx(b, "SELOS DE RISCO (16 PX)", 330, y - 10, "g3")
	var sx := 330
	for n in SELOS:
		var im := peca("c_selo_risco_" + n)
		blit(b, im, sx, y)
		sx += im.get_width() + 6
	nove_peca(b, "c_selo_risco_equilibrado_base", Rect2i(330, y + 22, 80, 16))
	tx_c(b, "PAREJO", Rect2i(346, y + 22, 61, 14), "ink")
	# --- HUD da luta: faixa de tela + retratos + barras
	y = 214
	tx(b, "LUTA: FAIXA DE TELA, RETRATO, BARRA DE VIDA", 8, y - 10, "g3")
	var arena := novo(640, 60)
	arena.fill(C("st0"))
	blit(b, arena, 0, y)
	nove_peca(b, "c_faixa_tela", Rect2i(0, y, 640, 49))
	var pj := _img(ROOT + "/assets/sprites/fight/portrait_player.png")
	blit(b, peca("c_retrato_moldura"), 6, y + 6)
	blit(b, pj.get_region(Rect2i(0, 0, 32, 32)), 8, y + 8)
	tx(b, "VOCÊ", 46, y + 8, "cream")
	_vida(b, Rect2i(46, y + 18, 236, 12), 0.62, 0.75, false)
	var po := _img(ROOT + "/assets/sprites/opponents/portrait_opp_gym_1.png").get_region(Rect2i(0, 0, 32, 32))
	po.flip_x()
	blit(b, peca("c_retrato_moldura_ouro"), 598, y + 6)
	blit(b, po, 600, y + 8)
	tx(b, "ADVERSÁRIO", 594 - tw("ADVERSÁRIO"), y + 8, "cream")
	_vida(b, Rect2i(358, y + 18, 236, 12), 0.2, 0.35, true)
	# --- mapa
	y = 296
	tx(b, "MAPA: MOLDURA, TOPO, ABA, FICHA, PREÇO, FECHAR", 8, y - 10, "g3")
	var mapa := novo(300, 130)
	mapa.fill(C("gr1"))
	blit(b, mapa, 8, y)
	nove_peca(b, "c_mapa_moldura", Rect2i(8, y, 300, 130))
	nove_peca(b, "c_mapa_topo", Rect2i(13, y + 5, 290, 20))
	tx(b, "MAPA DA ESCOLA", 20, y + 11, "cream")
	var fe := peca("c_mapa_fechar_normal")
	blit(b, fe, 284, y + 7)
	blit(b, peca("c_mapa_fechar_hover"), 266, y + 7)
	nove_peca(b, "c_mapa_aba_garage", Rect2i(20, y + 34, 76, 13))
	blit(b, icon("icon_region_garage_9"), 25, y + 36)
	tx(b, "GARAGEM", 37, y + 37, "ink")
	nove_peca(b, "c_mapa_aba_center", Rect2i(20, y + 52, 70, 13))
	blit(b, icon("icon_region_center_9"), 25, y + 54)
	tx(b, "CENTRO", 37, y + 55, "ink")
	nove_peca(b, "c_mapa_preco_ok", Rect2i(30, y + 76, 26, 11))
	blit(b, icon("icon_legacy"), 32, y + 77)
	tx(b, "3", 45, y + 78, "p0")
	nove_peca(b, "c_mapa_preco_falta", Rect2i(62, y + 76, 26, 11))
	tx(b, "9", 77, y + 78, "g3")
	nove_peca(b, "c_mapa_ficha", Rect2i(130, y + 34, 164, 62))
	tx(b, "PUNHO DE FERRO", 138, y + 42, "ink")
	tx(b, "+10% NO SACO", 138, y + 54, "g0")
	nove_peca(b, "c_mapa_ficha_proxima", Rect2i(132, y + 76, 160, 13))
	tx(b, "VALE NA PRÓXIMA", 149, y + 79, "cream")
	# --- mural e fundo de tela
	var mx := 322
	tx(b, "MURAL", mx, y - 10, "g3")
	for k in 2:
		var mn := "c_mural_moldura" if k == 0 else "c_mural_moldura_primeiro"
		blit(b, peca(mn), mx + k * 68, y)
		blit(b, peca("c_mural_fundo"), mx + k * 68 + 3, y + 3)
		var busto := _img(ROOT + "/assets/sprites/characters/mural_portrait_john.png")
		var bw := mini(56, busto.get_width())
		var bh := mini(60, busto.get_height())
		var reg := busto.get_region(Rect2i(0, 0, bw, bh))
		blit(b, reg, mx + k * 68 + 3 + (56 - bw) / 2, y + 3 + 60 - bh)
	tx(b, "FUNDO DE TELA (1/4)", 470, y - 10, "g3")
	var tf := peca("c_tela_fundo")
	tf.resize(160, 90, Image.INTERPOLATE_NEAREST)
	blit(b, tf, 470, y)
	nove_peca(b, "c_cartao_apagado", Rect2i(470, y + 98, 70, 24))
	tx(b, "APAGADO", 480, y + 105, "ink")
	var bx: Image = b.duplicate()
	bx.resize(640 * 2, 432 * 2, Image.INTERPOLATE_NEAREST)
	return bx


func _vida(b: Image, r: Rect2i, v: float, rastro: float, dir: bool) -> void:
	nove_peca(b, "c_vida_moldura", r)
	var lw := r.size.x - 4
	var wt := int(lw * rastro)
	var wf := int(lw * v)
	var baixa := v <= 0.25
	if dir:
		nove_peca(b, "c_vida_rastro", Rect2i(r.end.x - 2 - wt, r.position.y + 2, wt, 8))
		nove_peca(b, "c_vida_baixa" if baixa else "c_vida_cheia", Rect2i(r.end.x - 2 - wf, r.position.y + 2, wf, 8))
	else:
		nove_peca(b, "c_vida_rastro", Rect2i(r.position.x + 2, r.position.y + 2, wt, 8))
		nove_peca(b, "c_vida_baixa" if baixa else "c_vida_cheia", Rect2i(r.position.x + 2, r.position.y + 2, wf, 8))


## Balão montado como o balao.gd monta (corpo, rabicho em by+h-2, plaquinha em (bx+6, by-6), texto ink com topo em by+5).
func _balao_em(b: Image, r: Rect2i, nome: String, cor: String, lado: String, linhas: Array) -> void:
	var yy := r.position.y + 8
	var rr := Rect2i(r.position.x, yy, r.size.x, r.size.y)
	nove_peca(b, "c_balao", rr)
	var tn: String = {"c": "c_balao_rabicho", "e": "c_balao_rabicho_e", "d": "c_balao_rabicho_d"}[lado]
	var px_: int = {"c": rr.position.x + rr.size.x / 2 - 3, "e": rr.position.x + 8, "d": rr.end.x - 8 - 6}[lado]
	blit(b, peca(tn), px_, rr.position.y + rr.size.y - 2)
	var maior := 0
	for l in linhas:
		maior = maxi(maior, tw(str(l)))
	var x0 := rr.position.x + int(floor((rr.size.x - maior) / 2.0))
	for k in linhas.size():
		tx(b, str(linhas[k]), x0, rr.position.y + 5 + 9 * k, "ink")
	var w := tw(nome) + 7
	nove_peca(b, "c_balao_placa_" + cor, Rect2i(rr.position.x + 6, rr.position.y - 6, w, 10))
	tx(b, nome, rr.position.x + 9, rr.position.y - 4, PLACAS[cor][2])
