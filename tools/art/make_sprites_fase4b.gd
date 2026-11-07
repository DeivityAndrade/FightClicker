extends SceneTree
## Sprites PLACEHOLDER da Fase 4b — Aparelhos que chegam (esteira e corda compradas com Treino) + modo assistido no Shift.
## Tudo gerado por código, paleta fechada de docs/arte/direcao-visual.md (fonte da verdade: tools/art/pixel_lib.gd).
## Rodar headless a partir de uma pasta com um project.godot vazio (não importa nada no projeto):
##   godot --headless --path <pasta_tmp> --quit-after 60 --script E:/Fightclicker/tools/art/make_sprites_fase4b.gd
## Saída:
##   assets/sprites/garage/tape_mark_*.png        contorno de fita crepe no lugar do aparelho que falta
##   assets/sprites/garage/ghost_*.png            silhueta apagada + cadeado do aparelho que falta (opcional, por baixo da fita)
##   assets/sprites/garage/sign_*.png             plaquinha de papelão (9-slice) + pedaço de fita + tijolo de apoio
##   assets/sprites/garage/fx_arrive_*.png        chegada do aparelho (poeira e brilho)
##   assets/sprites/ui/icon_*_locked*.png         silhueta 16x16 com cadeado (botão de foco e linha da aba TREINO)
##   assets/sprites/ui/ui_button_focus_locked_*   botão de foco trancado (9-slice 16x17 + versão pronta 122x34)
##   assets/sprites/ui/ui_card_unlock*.png        cartão da linha de compra (normal e piscando)
##   assets/sprites/ui/ui_assist_*.png, icon_assist_*.png, icon_key_shift.png   indicador do assistido e botão SEGURAR
##   assets/sprites/manifest.json                 ACRESCENTA as entradas da 4b (não apaga as anteriores)
##   docs/arte/mockups/fase4b_sprites_x3.png, fase4b_garagem_x2.png
## Não toca em personagens (characters/, fight/fight_player_*, opponents/) nem em personagem_lib.gd.

const ROOT := "E:/Fightclicker/"
const OUT := ROOT + "assets/sprites/"
const RES := "res://assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"
const SCRATCH := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/art4b/"

var L
var M := {}
var F := {}
var SHEETS := []
var OLD := {}

# Posições da sala (iguais ao manifest da Fase 2)
const TREAD_POS := Vector2i(445, 267)     # pivô da esteira em lado_direito (meio da base, no chão)
const NAIL := Vector2i(352, 72)           # prego da corda
# Marca da esteira: frente em y 268, fundo em y 255 (perspectiva do ponto de fuga 320,-28)
const TM_FRAME := Vector2i(96, 18)
const TM_PIVOT := Vector2i(48, 13)        # = TREAD_POS
# Marca da corda: na parede, em volta do prego (quadro de ferramentas desenhado com fita)
const RM_FRAME := Vector2i(26, 48)
const RM_PIVOT := Vector2i(13, 2)         # = NAIL
# Plaquinhas (posição sugerida; o tamanho sai do texto)
const SIGN_TREAD_BOTTOM := Vector2i(445, 257)   # centro da base da plaquinha da esteira (em pé no fundo da marca, apoiada no tijolo)
const SIGN_ROPE_TOPLEFT := Vector2i(340, 37)     # plaquinha da corda colada na parede, acima do prego (à direita da corrente)
# Botão de foco (ui/barra_baixo.gd)
const FOCUS_W := 122
const FOCUS_H := 34

func V(x, y) -> Vector2:
	return Vector2(x, y)

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func save_sheet(id: String, rel: String, frames: Array, fps: float, pivot: Vector2i, info := {}, contact := true) -> void:
	var s := strip(frames)
	var path := OUT + rel
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	s.save_png(path)
	var e := {"file": RES + rel, "frame_size": [frames[0].get_width(), frames[0].get_height()],
		"frames": frames.size(), "fps": fps, "pivot": [pivot.x, pivot.y]}
	for k in info:
		e[k] = info[k]
	M[id] = e
	F[id] = frames
	if contact:
		SHEETS.append([id, s, frames[0].get_width()])

func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

func pmap(img: Image, x: int, y: int, rows: Array, leg: Dictionary) -> void:
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			var ch := r[i]
			if ch != "." and leg.has(ch):
				L.P(img, x + i, y + j, leg[ch])

# ================================================================ cadeado
## Cadeado 7x10 com contorno ink. body = [sombra, base, luz].
func padlock(img: Image, x: int, y: int, body: Array, shackle := "st3") -> void:
	pmap(img, x, y, [
		"..kkk..",
		".kssskk",
		".ks.sk.",
		".ks.sk.",
		"kkkkkkk",
		"khhhhbk",
		"kbbkbbk",
		"kbbkbdk",
		"kdddddk",
		"kkkkkkk"], {"k": "ink", "s": shackle, "h": body[2], "b": body[1], "d": body[0]})

const LOCK_GOLD := ["br2", "y0", "y1"]
const LOCK_GRAY := ["g0", "g1", "g2"]
const LOCK_DARK := ["d1", "d2", "g0"]

# ================================================================ fita crepe
## Pedaço de fita horizontal (no chão ou na parede): base cream, borda de baixo g3, pontas rasgadas.
func tape_h(img: Image, x0: int, x1: int, y: int, thick := 2) -> void:
	for x in range(x0, x1 + 1):
		var torn := (x == x0 or x == x1)
		for t in thick:
			if torn and t == (0 if (x + y) % 2 == 0 else thick - 1):
				continue
			L.P(img, x, y + t, "cream" if t < thick - 1 else "g3")

## Pedaço de fita vertical (na parede): base cream, borda direita g3.
func tape_v(img: Image, x: int, y0: int, y1: int, thick := 2) -> void:
	for y in range(y0, y1 + 1):
		var torn := (y == y0 or y == y1)
		for t in thick:
			if torn and t == (0 if (x + y) % 2 == 0 else thick - 1):
				continue
			L.P(img, x + t, y, "cream" if t < thick - 1 else "g3")

## Fita "inclinada" no chão (lado do trapézio): segue a linha para o ponto de fuga, 2 px de largura.
func tape_slant(img: Image, xa: float, ya: int, xb: float, yb: int) -> void:
	for y in range(ya, yb + 1):
		var t := float(y - ya) / float(maxi(yb - ya, 1))
		var x := int(round(lerpf(xa, xb, t)))
		var torn := (y == ya or y == yb)
		if not torn or (x + y) % 2 == 0:
			L.P(img, x, y, "cream")
		L.P(img, x + 1, y, "g3")

func make_tape_marks() -> void:
	# --- esteira: trapézio no chão em volta da base (86 px na frente)
	var img: Image = L.blank(TM_FRAME.x, TM_FRAME.y)
	var front := 14          # y local da frente (tela 268)
	var back := 1            # y local do fundo (tela 255)
	var k := float(back + 254 + 28) / float(front + 254 + 28)
	var ox := TREAD_POS.x - TM_PIVOT.x   # 397
	var fl := 402.0 - ox
	var fr := 488.0 - ox
	var bl := 320.0 + (402.0 - 320.0) * k - ox
	var br := 320.0 + (488.0 - 320.0) * k - ox
	# frente: dois pedaços que se cruzam no meio (fita colada às pressas)
	tape_h(img, int(fl) - 1, int(fl + fr) / 2 + 2, front)
	tape_h(img, int(fl + fr) / 2 - 3, int(fr) + 1, front + 1)
	# fundo: um pedaço com um vão (a fita acabou)
	tape_h(img, int(bl), int(bl) + 30, back)
	tape_h(img, int(bl) + 36, int(br) + 1, back)
	# lados
	tape_slant(img, bl, back + 1, fl, front)
	tape_slant(img, br - 1, back + 1, fr - 1, front)
	# "X" de fita no meio marcando o lugar
	for i in 5:
		L.P(img, 43 + i * 2, 5 + i, "cream"); L.P(img, 44 + i * 2, 5 + i, "g3")
		L.P(img, 51 - i * 2, 5 + i, "cream"); L.P(img, 52 - i * 2, 5 + i, "g3")
	save_sheet("tape_mark_treadmill", "garage/tape_mark_treadmill.png", [img], 0, TM_PIVOT, {
		"positions": {"lado_direito": xy(TREAD_POS)}, "layer": "chao", "z": -30, "sort_y": 255,
		"note": "Contorno de fita crepe no chão onde a esteira vai ficar (mesmo pivô e posição da treadmill_lN_side). Desenhar logo depois do garage_bg, antes de pessoas e sacos (é chão). Some na chegada (no quadro de impacto do fx_arrive_dust)."})

	# --- corda: contorno na parede em volta do prego (quadro de ferramentas)
	var r: Image = L.blank(RM_FRAME.x, RM_FRAME.y)
	# topo em duas tiras, deixando o prego livre no meio
	tape_h(r, 1, 10, 4)
	tape_h(r, 16, 24, 4)
	tape_v(r, 1, 3, 44)
	tape_v(r, 23, 3, 44)
	tape_h(r, 1, 24, 45)
	# silhueta da corda pendurada desenhada à caneta (tracejado d2) dentro do contorno
	var loop := [[13, 6], [11, 9], [9, 13], [8, 18], [8, 24], [9, 30], [10, 35], [12, 39], [13, 40], [15, 39], [16, 35], [17, 30], [18, 24], [18, 18], [17, 13], [15, 9]]
	for i in loop.size():
		if i % 2 == 0:
			var a: Array = loop[i]
			var b: Array = loop[(i + 1) % loop.size()]
			L.line(r, a[0], a[1], b[0], b[1], "d2")
	save_sheet("tape_mark_rope", "garage/tape_mark_rope.png", [r], 0, RM_PIVOT, {
		"positions": {"prego": xy(NAIL)}, "layer": "frente_do_fundo", "z": -40,
		"note": "Contorno de fita crepe na parede em volta do prego, como num quadro de ferramentas, com a forma da corda tracejada a caneta. É o 'lugar exato' da corda (ela fica no prego quando não está em foco). Mesmo pivô da rope_lN_idle (o prego). Some na chegada."})

# ================================================================ silhuetas na sala (fantasma + cadeado)
func ghost_of(src: Image, lock_at: Vector2i) -> Image:
	var out: Image = L.blank(src.get_width(), src.get_height())
	for y in src.get_height():
		for x in src.get_width():
			if src.get_pixel(x, y).a > 0.0 and (x + y) % 2 == 0:
				out.set_pixel(x, y, L.C.ink)
	padlock(out, lock_at.x, lock_at.y, LOCK_GRAY)
	return out

func make_ghosts() -> void:
	var tm: Image = frame_of("treadmill_l0_idle")
	save_sheet("ghost_treadmill", "garage/ghost_treadmill.png", [ghost_of(tm, Vector2i(58, 28))], 0, Vector2i(43, 41), {
		"positions": {"lado_direito": xy(TREAD_POS)}, "layer": "chao", "z": -29,
		"note": "Opcional: sombra pontilhada (dither ink 50%) da esteira com cadeado, por cima da tape_mark_treadmill. Deixa claro QUE aparelho falta. Some junto com a marca."})
	var rp: Image = frame_of("rope_l0_idle")
	save_sheet("ghost_rope", "garage/ghost_rope.png", [ghost_of(rp, Vector2i(6, 16))], 0, Vector2i(9, 0), {
		"positions": {"prego": xy(NAIL)}, "layer": "frente_do_fundo", "z": -39,
		"note": "Opcional: sombra pontilhada da corda com cadeado, no prego, por cima da tape_mark_rope. Some junto com a marca."})

# ================================================================ plaquinha de papelão
func make_sign() -> void:
	# 9-slice 20x18: papelão br3 com luz y0 no alto, sombra br2 embaixo, quinas rasgadas (fixas nos cantos)
	var s: Image = L.blank(20, 18)
	L.R(s, 0, 0, 20, 18, "ink")
	L.R(s, 1, 1, 18, 16, "br3")
	L.R(s, 1, 1, 18, 1, "y0")
	L.R(s, 1, 15, 18, 2, "br2")
	# quina de cima à esquerda rasgada / canto de baixo à direita amassado
	L.P(s, 0, 0, Color(0, 0, 0, 0)); L.P(s, 1, 0, Color(0, 0, 0, 0)); L.P(s, 0, 1, Color(0, 0, 0, 0)); L.P(s, 1, 1, "ink"); L.P(s, 2, 1, "br2")
	L.P(s, 19, 17, Color(0, 0, 0, 0)); L.P(s, 18, 17, "ink"); L.P(s, 19, 16, "ink"); L.P(s, 18, 16, "br1"); L.P(s, 17, 16, "br1")
	L.P(s, 19, 0, Color(0, 0, 0, 0)); L.P(s, 0, 17, Color(0, 0, 0, 0))
	# onda do papelão aparecendo na borda rasgada da esquerda
	L.P(s, 1, 5, "br2"); L.P(s, 1, 9, "br2"); L.P(s, 1, 13, "br2")
	save_sheet("sign_cardboard", "garage/sign_cardboard.png", [s], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 4, "top": 4, "right": 4, "bottom": 4},
		"text_color": "br0", "text_margin": [5, 4, 5, 5], "line_gap": 2,
		"note": "Plaquinha de papelão escrita à mão (9-slice). Texto 1x em br0 (caneta), SEM sombra, centrado. Tamanho = texto + margem [esq 5, cima 4, dir 5, baixo 5]; 2 linhas com 2 px entre elas. Texto vem de floor_mark_price / floor_mark_after: a UI quebra no ' — ' (nome na 1ª linha, preço na 2ª). A fonte 5x7 dos mockups não tem travessão; com 1 linha só, usar '-'."})
	# pedaço de fita para colar a plaquinha na parede (cantos de cima)
	var t: Image = L.blank(7, 4)
	for y in 4:
		for x in 7:
			if (x == 0 and y == 3) or (x == 6 and y == 0):
				continue
			L.P(t, x, y, "cream" if y < 3 else "g3")
	L.P(t, 0, 0, "g3"); L.P(t, 6, 3, "g3")
	save_sheet("sign_tape_bit", "garage/sign_tape_bit.png", [t], 0, Vector2i(3, 1), {
		"note": "Pedaço de fita crepe para colar a plaquinha na parede: um em cada canto de cima (pivô no canto da plaquinha, um pouco para dentro: x+2 e x+w-3, y+1)."})
	# tijolo de apoio (plaquinha em pé no chão, no meio da marca da esteira)
	var b: Image = L.blank(16, 7)
	L.R(b, 1, 1, 14, 5, "g1")
	L.R(b, 1, 1, 14, 1, "g2")
	L.R(b, 1, 5, 14, 1, "g0")
	L.P(b, 4, 3, "g0"); L.P(b, 10, 2, "g0"); L.P(b, 12, 4, "g0")
	b = ol(b)
	save_sheet("sign_brick", "garage/sign_brick.png", [b], 0, Vector2i(8, 6), {
		"note": "Meio bloco de concreto onde a plaquinha da esteira se apoia, no chão. Pivô = meio da base. Desenhar DEPOIS da plaquinha (a base dela fica atrás do tijolo, 3 px)."})

## Desenha uma plaquinha com as linhas de texto (para mockup e para conferir o tamanho).
func sign_box(lines: Array) -> Vector2i:
	var w := 0
	for ln in lines:
		w = maxi(w, L.text_w(str(ln)))
	return Vector2i(w + 10, lines.size() * 7 + (lines.size() - 1) * 2 + 9)

func draw_sign(dst: Image, x: int, y: int, lines: Array) -> Vector2i:
	var sz := sign_box(lines)
	ns(dst, "sign_cardboard", x, y, sz.x, sz.y)
	var ty := y + 4
	for ln in lines:
		L.text_center(dst, str(ln), x + sz.x / 2, ty, "br0")
		ty += 9
	return sz

# ================================================================ ícones 16x16 com cadeado
func silhouette(src: Image) -> Image:
	var out: Image = src.duplicate()
	var ink_hex: String = L.C.ink.to_html(false)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a == 0.0 or c.to_html(false) == ink_hex:
				continue
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			out.set_pixel(x, y, L.C["g1"] if lum > 0.5 else L.C["g0"])
	return out

func make_locked_icons() -> void:
	for ap in [["treadmill", "icon_treadmill", "esteira"], ["jump_rope", "icon_rope", "corda"]]:
		var base: Image = silhouette(frame_of(ap[1]))
		for v in [["", LOCK_GRAY, "cadeado cinza: trancado ou sem Treino"], ["_buyable", LOCK_GOLD, "cadeado dourado: dá para comprar agora"]]:
			var img: Image = base.duplicate()
			# limpa um respiro em volta do cadeado (canto de baixo à direita)
			L.R(img, 8, 6, 8, 10, Color(0, 0, 0, 0))
			padlock(img, 9, 6, v[1])
			save_sheet(ap[1] + "_locked" + v[0], "ui/%s_locked%s.png" % [ap[1], v[0]], [img], 0, Vector2i.ZERO, {
				"note": "Silhueta da %s com %s. Mesmo tamanho do %s: linha de compra da aba TREINO (5,3 no cartão) e botão de foco trancado (2,9 no botão, no lugar do ícone 9x9 do atributo)." % [ap[2], v[2], ap[1]]})

# ================================================================ botão de foco trancado
## Botão 16x17 no mesmo formato do ui_button_*: contorno ink, luz em cima, 2 linhas de sombra embaixo, sombra de base.
func btn_tex(bg: String, hi: String, lo: String, border = null) -> Image:
	var b: Image = L.blank(16, 17)
	L.R(b, 1, 16, 15, 1, "ink")
	L.R(b, 0, 0, 16, 16, "ink")
	L.R(b, 1, 1, 14, 14, bg)
	L.R(b, 1, 1, 14, 1, hi)
	L.R(b, 1, 13, 14, 2, lo)
	if border != null:
		L.R(b, 1, 1, 14, 1, border)
		L.R(b, 1, 1, 1, 12, border)
		L.R(b, 14, 1, 1, 12, border)
	return b

func make_focus_locked() -> void:
	var defs := {
		"buyable": [btn_tex("d2", "g0", "d1", "gr2"), "white", "y1", "Dá para comprar (Treino suficiente): borda verde = 'comprável', como no resto do jogo. Preço em y1 com icon_treino. Alternar com _buyable_pulse a 3 fps para chamar atenção."],
		"buyable_pulse": [btn_tex("d2", "g0", "d1", "gr3"), "white", "y1", "2º quadro do comprável (borda gr3)."],
		"missing": [btn_tex("d1", "d2", "ink"), "g3", "r2", "Sem Treino: botão apagado, preço em r2 (como ui_price_cannot). Sem aviso de erro."],
		"locked": [btn_tex("d1", "d1", "ink"), "g1", "g1", "Falta o aparelho anterior: o mais apagado, sem preço; 2ª linha 'DEPOIS DA ESTEIRA' (focus_locked_after) em g1."],
	}
	for st in defs:
		var d: Array = defs[st]
		save_sheet("ui_button_focus_locked_" + st, "ui/ui_button_focus_locked_%s.png" % st, [d[0]], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 4}, "text_color": d[1], "price_color": d[2],
			"note": "Botão de foco trancado (9-slice, mesmas margens dos ui_button_focus_*). " + d[3]})
		var full: Image = L.blank(FOCUS_W, FOCUS_H)
		nine(full, d[0], 0, 0, FOCUS_W, FOCUS_H, {"left": 2, "top": 2, "right": 2, "bottom": 4})
		save_sheet("ui_button_focus_locked_%s_full" % st, "ui/ui_button_focus_locked_%s_full.png" % st, [full], 0, Vector2i.ZERO, {
			"note": "O mesmo fundo já no tamanho do botão de foco (122x34), sem texto nem ícone, para usar direto se preferir textura fixa."}, false)

# ================================================================ cartão da linha de compra (aba TREINO)
func make_unlock_card() -> void:
	for v in [["ui_card_unlock", "d2", "br2", "br1", "Linha de compra do aparelho na seção MELHORIAS: cartão com borda de papelão (br2) para ligar à plaquinha da sala."],
			["ui_card_unlock_flash", "g0", "y1", "y0", "Piscada da linha (ao clicar na marca do chão ou no botão de foco trancado): alternar com ui_card_unlock a ~6 fps por 1 s (3 piscadas)."]]:
		var c: Image = L.blank(12, 12)
		L.R(c, 0, 0, 12, 12, "ink")
		L.R(c, 1, 1, 10, 10, v[2])
		L.R(c, 2, 2, 8, 8, v[1])
		L.R(c, 2, 2, 8, 1, v[3])
		save_sheet(v[0], "ui/%s.png" % v[0], [c], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3}, "note": v[4] + " Mesmo tamanho e margens do ui_card (120x44 no painel)."})

# ================================================================ efeito de chegada

## Grão de poeira: borda pontilhada g2, miolo g3 só nos quadros fortes (sem contorno: é fumaça).
func dust_blob(img: Image, cx: float, cy: float, r: float, fade: int, ph: int) -> void:
	if r < 1.0:
		return
	if fade == 0:
		L.ellipse(img, cx, cy, r, r * 0.7, "g2")
		L.ellipse_dither(img, cx, cy - r * 0.2, r * 0.8, r * 0.5, "g3", ph)
		L.ellipse(img, cx - r * 0.2, cy - r * 0.3, r * 0.4, r * 0.25, "g3")
	elif fade == 1:
		L.ellipse_dither(img, cx, cy, r, r * 0.7, "g2", ph)
		L.ellipse_dither(img, cx, cy - r * 0.2, r * 0.5, r * 0.35, "g3", ph + 1)
	else:
		L.ellipse_dither(img, cx, cy, r * 0.8, r * 0.5, "g2", ph)

func clear_dither(img: Image, phase: int) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if (x + y + phase) % 2 == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

func star(img: Image, x: int, y: int, s: int, c := "y2") -> void:
	L.P(img, x, y, "white")
	for i in range(1, s + 1):
		var cc: String = c if i < s else "y0"
		L.P(img, x + i, y, cc); L.P(img, x - i, y, cc); L.P(img, x, y + i, cc); L.P(img, x, y - i, cc)

func make_arrival() -> void:
	# poeira no chão (esteira): 104x36, pivô no meio da base (= pivô do aparelho)
	var W := 104
	var H := 36
	var cx := 52.0
	var by := 32.0
	var frames := []
	var spread := [10.0, 24.0, 33.0, 38.0, 41.0, 43.0]
	var rad := [5.0, 7.0, 7.0, 6.0, 5.0, 4.0]
	var rise := [0.0, 2.0, 5.0, 8.0, 10.0, 11.0]
	for f in 6:
		var img: Image = L.blank(W, H)
		var fade := 0 if f < 3 else (1 if f < 5 else 2)
		# faixa de poeira rolando rente ao chão: o miolo abre (a esteira assentou) e as pontas vão para fora
		var inner: float = [0.0, 8.0, 16.0, 22.0, 27.0, 31.0][f]
		var outer: float = spread[f]
		for side in [-1.0, 1.0]:
			var d := inner
			var k := 0
			while d <= outer:
				var hgt: float = rad[f] * (0.55 + 0.45 * float((k * 7 + f * 3) % 5) / 4.0)
				dust_blob(img, cx + side * d, by - hgt * 0.6 - rise[f] * 0.25, hgt, fade, k + f)
				d += 4.0
				k += 1
		if f == 0:
			# risco de impacto no chão
			L.R(img, int(cx) - 30, int(by), 60, 1, "g3")
			L.R(img, int(cx) - 20, int(by) + 1, 40, 1, "g2")
		# brilho de "chegou!" (estrelinhas em cima)
		if f >= 1 and f <= 4:
			var st := [[18, 10], [86, 8], [52, 2], [32, 4], [72, 3]]
			for i in st.size():
				if (i + f) % 2 == 0 or f == 2:
					star(img, st[i][0], st[i][1] + f, 2 if f < 4 else 1)
		frames.append(img)
	save_sheet("fx_arrive_dust", "garage/fx_arrive_dust.png", frames, 12.0, Vector2i(52, 32), {
		"loop": false, "impact_frame": 0, "positions": {"lado_direito": xy(TREAD_POS)},
		"drop": {"offsets_y": [-20, -10, -3, 0, 1, 0], "fps": 24, "shake_px": 1, "shake_frames": 2,
			"note": "A esteira cai: desenhar a treadmill_l0_side deslocada em y por estes valores (pixel inteiro, 24 fps). No quadro do 0 (impacto): some a marca, toca o fx_arrive_dust do quadro 0, som de queda e a tela treme 1 px por 2 quadros."},
		"note": "Chegada da esteira: poeira que abre para os lados + estrelinhas de 'chegou!'. 6 quadros a 12 fps (0,5 s), sem loop. Por cima de tudo da sala, menos o lutador em foco."})
	# brilho na parede (corda chegando ao prego): 40x52, pivô no prego
	var rf := []
	for f in 5:
		var img: Image = L.blank(40, 52)
		var pts := [[6, 10], [34, 6], [4, 34], [36, 30], [20, 48], [12, 22], [30, 44]]
		for i in pts.size():
			if (i + f) % 3 != 0 or f == 1:
				star(img, pts[i][0], pts[i][1] - f, 2 if f < 3 else 1)
		# pozinho caindo do prego (reboco) nos 3 primeiros quadros
		if f < 3:
			for i in 4:
				L.P(img, 18 + i * 2, 6 + f * 4 + i, "g3")
				L.P(img, 19 + i * 2, 8 + f * 5 + i * 2, "g2")
		rf.append(img)
	save_sheet("fx_arrive_sparkle", "garage/fx_arrive_sparkle.png", rf, 12.0, Vector2i(20, 2), {
		"loop": false, "impact_frame": 0, "positions": {"prego": xy(NAIL)},
		"drop": {"offsets_y": [-8, -3, 0, 1, 0], "fps": 24, "shake_px": 0,
			"note": "A corda é pendurada: desenhar a rope_l0_idle deslocada em y por estes valores. No quadro do 0: some a marca, toca o fx_arrive_sparkle, som curto. Sem tremida (é leve)."},
		"note": "Chegada da corda: estrelinhas em volta do prego e um pozinho de reboco caindo. 5 quadros a 12 fps. Também serve de brilho extra na esteira (pivô no topo dela)."})

# ================================================================ modo assistido
func icon_key_shift() -> Image:
	var img: Image = L.blank(9, 9)
	pmap(img, 0, 0, [
		".kkkkkkk.",
		"kccckccck",
		"kcckkkcck",
		"kckkkkkck",
		"kcckkkcck",
		"kcckkkcck",
		"kgggggggk",
		"kdddddddk",
		".kkkkkkk."], {"k": "ink", "c": "cream", "g": "g3", "d": "g2"})
	return img

func icon_wait() -> Image:
	var img: Image = L.blank(9, 9)
	pmap(img, 0, 0, [
		".kkkkkkk.",
		".kbbbbbk.",
		"..kyyyk..",
		"...kyk...",
		"....k....",
		"...kck...",
		"..kcyck..",
		".kbbbbbk.",
		".kkkkkkk."], {"k": "ink", "b": "br2", "y": "y1", "c": "g2"})
	return img

func icon_active() -> Image:
	var img: Image = L.blank(9, 9)
	pmap(img, 0, 0, [
		"...kkkkk.",
		"..krrhrrk",
		"kkkrrrrrk",
		"kwkrrrrrk",
		"kwkkrrrrk",
		"kkkdrrrdk",
		"...kkkkk.",
		".........",
		"........."], {"k": "ink", "r": "r2", "h": "r3", "d": "r1", "w": "white"})
	# riscos de movimento em baixo (o soco "sozinho")
	L.R(img, 0, 8, 3, 1, "gr3"); L.R(img, 4, 8, 4, 1, "gr3")
	return img

func icon_metro9() -> Image:
	var img: Image = L.blank(9, 9)
	L.trap(img, 1, 7, 4, 4, 1, 7, "br2")
	L.R(img, 1, 7, 7, 1, "br1")
	L.P(img, 3, 3, "br3"); L.P(img, 3, 4, "br3"); L.P(img, 2, 5, "br3")
	L.line(img, 4, 6, 6, 0, "st3")
	L.P(img, 5, 3, "y1")
	return ol(img) if false else outline_keep(img)

## Contorno ink sem perder a borda (usa o quadro com 1 px a mais e recorta).
func outline_keep(src: Image) -> Image:
	var big: Image = L.blank(src.get_width() + 2, src.get_height() + 2)
	big.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(1, 1))
	var o: Image = L.outlined(big)
	return o.get_region(Rect2i(2, 2, src.get_width(), src.get_height()))

func make_assist() -> void:
	save_sheet("icon_key_shift", "ui/icon_key_shift.png", [icon_key_shift()], 0, Vector2i.ZERO, {
		"note": "Tecla Shift (seta para cima numa tecla). Vai na dica 'SEGURE SHIFT' e no botão SEGURAR."})
	save_sheet("icon_assist_wait", "ui/icon_assist_wait.png", [icon_wait()], 0, Vector2i.ZERO, {
		"note": "Ampulheta: segurando, mas a mão ainda mexeu há menos de 1 s (estado waiting)."})
	save_sheet("icon_assist_active", "ui/icon_assist_active.png", [icon_active()], 0, Vector2i.ZERO, {
		"note": "Luva com riscos verdes: o assistido está socando (estado active)."})
	save_sheet("icon_metronome_9", "ui/icon_metronome_9.png", [icon_metro9()], 0, Vector2i.ZERO, {
		"note": "Metrônomo pequeno 9x9 para o estado 'METRÔNOMO TOCANDO' (o da LOJA é o icon_metronome_lN 16x16)."})
	# chips 9-slice 12x13
	var chips := {
		"hint": ["d1", "d2", "g0", "g2", "Dica fixa (Metrônomo 0, sem segurar): fundo apagado, texto g2 + icon_key_shift."],
		"waiting": ["d2", "y0", "br2", "y1", "Segurando, mão ainda mexendo: borda âmbar, texto y1 + icon_assist_wait. Sem animação."],
		"active": ["gr0", "gr2", "gr1", "gr3", "Socando: fundo verde escuro, borda gr2, texto gr3 + icon_assist_active."],
		"active_pulse": ["gr1", "gr3", "gr2", "white", "Pulso do 'socando': trocar para este a cada auto-soco por 0,15 s (texto white) e voltar ao active."],
		"metronome": ["br0", "y0", "br1", "y1", "Metrônomo ≥ 1: madeira escura, borda âmbar, texto y1 + icon_metronome_9. Sem botão SEGURAR."],
	}
	for st in chips:
		var c: Array = chips[st]
		var img: Image = L.blank(12, 13)
		L.R(img, 0, 0, 12, 13, "ink")
		L.R(img, 1, 1, 10, 11, c[1])
		L.R(img, 2, 2, 8, 9, c[0])
		L.R(img, 2, 10, 8, 1, c[2])
		L.P(img, 0, 0, Color(0, 0, 0, 0)); L.P(img, 11, 0, Color(0, 0, 0, 0)); L.P(img, 0, 12, Color(0, 0, 0, 0)); L.P(img, 11, 12, Color(0, 0, 0, 0))
		save_sheet("ui_assist_chip_" + st, "ui/ui_assist_chip_%s.png" % st, [img], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3}, "text_color": c[3],
			"note": "Indicador do assistido (9-slice, altura 13: ícone 9x9 em x 3, y 2; texto 1x em x 15, y 3). " + c[4]})
	# botão SEGURAR: tecla de aço (normal) e verde afundada (pressionado = assistido ligado enquanto segura)
	var bn := btn_tex("st1", "st2", "st0")
	save_sheet("ui_button_hold_normal", "ui/ui_button_hold_normal.png", [bn], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 4}, "text_color": "white",
		"note": "Botão SEGURAR (assist_button) para quem só usa o mouse: cor de tecla (aço). Conteúdo: icon_key_shift + texto. Tamanho sugerido 64x15."})
	var bp: Image = L.blank(16, 17)
	L.R(bp, 0, 1, 16, 16, "ink")
	L.R(bp, 1, 2, 14, 14, "gr1")
	L.R(bp, 1, 2, 14, 1, "gr0")
	L.R(bp, 1, 15, 14, 1, "gr0")
	L.R(bp, 2, 3, 12, 1, "gr2")
	save_sheet("ui_button_hold_pressed", "ui/ui_button_hold_pressed.png", [bp], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 2, "top": 3, "right": 2, "bottom": 3}, "text_color": "gr3",
		"note": "SEGURAR pressionado: afunda 1 px (sem sombra de base) e fica verde = está assistindo. Volta ao normal ao soltar o mouse ou sair do botão."})

# ================================================================ manifest
func intify(v):
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = v[k] if str(k) == "fps" else intify(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(intify(x))
		return a
	if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 1e9:
		return int(v)
	return v

func write_manifest() -> void:
	var doc: Dictionary = intify(OLD)
	doc["_sobre"] = "Sprites PLACEHOLDER das Fases 2 (garagem), 3 (lutas), 4 (árvore, Metrônomo, revanche) e 4b (aparelhos que chegam, modo assistido), gerados por tools/art/make_sprites_fase2.gd, make_sprites_fase3.gd, make_sprites_fase4.gd e make_sprites_fase4b.gd (personagens: make_sprites_elenco.gd / make_sprites_jogador.gd). Tudo 1x na resolução base 640x360, filtro nearest. Folhas = quadros lado a lado, da esquerda para a direita."
	var spr_d: Dictionary = doc.get("sprites", {})
	for k in M:
		spr_d[k] = intify(M[k])
	doc["sprites"] = spr_d
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["_nota_fase4b"] = "Fase 4b: aparelhos que chegam (training.json → apparatus[].unlock, ids unlock_treadmill e unlock_jump_rope) e modo assistido (training.json → assist). Estados do aparelho: owned / buyable / missing / locked (fase4b-design §2.2)."
	bd["unlock_treadmill"] = {
		"apparatus": "treadmill", "requires": "",
		"floor_mark": "tape_mark_treadmill", "ghost": "ghost_treadmill", "mark_pos": xy(TREAD_POS),
		"sign": {"frame": "sign_cardboard", "mode": "chao", "bottom_center": xy(SIGN_TREAD_BOTTOM), "brick": "sign_brick", "brick_pos": [SIGN_TREAD_BOTTOM.x, SIGN_TREAD_BOTTOM.y + 3],
			"note": "Plaquinha em pé no fundo da marca (encostada na parede), apoiada no tijolo, para não cobrir a fita da frente: desenhar a plaquinha com a base em bottom_center e o sign_brick por cima, em brick_pos."},
		"icon_locked": "icon_treadmill_locked", "icon_locked_buyable": "icon_treadmill_locked_buyable",
		"focus_button": {"buyable": "ui_button_focus_locked_buyable", "buyable_pulse": "ui_button_focus_locked_buyable_pulse", "missing": "ui_button_focus_locked_missing", "locked": "ui_button_focus_locked_locked"},
		"card": "ui_card_unlock", "card_flash": "ui_card_unlock_flash",
		"arrive": {"fx": "fx_arrive_dust", "fx_pos": xy(TREAD_POS), "sprite": "treadmill_lN_side", "drop": "ver sprites.fx_arrive_dust.drop", "extra": "fx_arrive_sparkle (opcional, pivô em 445,226)"},
		"text_keys": {"sign_price": "floor_mark_price", "sign_after": "floor_mark_after", "focus_price": "focus_locked_price", "focus_after": "focus_locked_after", "arrived": "unlock_arrived"}}
	bd["unlock_jump_rope"] = {
		"apparatus": "jump_rope", "requires": "treadmill",
		"floor_mark": "tape_mark_rope", "ghost": "ghost_rope", "mark_pos": xy(NAIL),
		"sign": {"frame": "sign_cardboard", "mode": "parede", "top_left": xy(SIGN_ROPE_TOPLEFT), "tape": "sign_tape_bit",
			"note": "Plaquinha colada na parede ACIMA do prego, com a borda esquerda em x 340 (à direita da corrente do saco, x 335) e 2 sign_tape_bit nos cantos de cima. Cresce para a direita. Na parede não cabe 'DEPOIS DA ESTEIRA' numa linha só com o nome: usar 3 linhas (CORDA / DEPOIS DA / ESTEIRA)."},
		"icon_locked": "icon_rope_locked", "icon_locked_buyable": "icon_rope_locked_buyable",
		"focus_button": {"buyable": "ui_button_focus_locked_buyable", "buyable_pulse": "ui_button_focus_locked_buyable_pulse", "missing": "ui_button_focus_locked_missing", "locked": "ui_button_focus_locked_locked"},
		"card": "ui_card_unlock", "card_flash": "ui_card_unlock_flash",
		"arrive": {"fx": "fx_arrive_sparkle", "fx_pos": xy(NAIL), "sprite": "rope_lN_idle", "drop": "ver sprites.fx_arrive_sparkle.drop"},
		"text_keys": {"sign_price": "floor_mark_price", "sign_after": "floor_mark_after", "focus_price": "focus_locked_price", "focus_after": "focus_locked_after", "arrived": "unlock_arrived"}}
	bd["focus_locked_layout"] = {
		"button_size": [FOCUS_W, FOCUS_H],
		"icon": "icon_<aparelho>_locked(_buyable) 16x16 em (2,9) do botão, no lugar do icon_<atributo> 9x9",
		"line1": "nome do aparelho (focus_label[0]) em (20,4), cor = text_color do estado",
		"line2": "preço em (20,15): icon_treino 9x9 + número (focus_locked_price), cor = price_color; no locked, 'DEPOIS DA ESTEIRA' (focus_locked_after) em g1, a partir de x 20 (98 px úteis: cabe, ver relatório)",
		"key_number": "o número da tecla (canto de cima à direita) some no botão trancado (o teclado pula os trancados)",
		"underline": "sem sublinhado (nunca está selecionado)"}
	bd["assist"] = {
		"states": {"off": "ui_assist_chip_hint", "waiting": "ui_assist_chip_waiting", "active": "ui_assist_chip_active", "metronome": "ui_assist_chip_metronome"},
		"pulse": "ui_assist_chip_active_pulse",
		"icons": {"off": "icon_key_shift", "waiting": "icon_assist_wait", "active": "icon_assist_active", "metronome": "icon_metronome_9"},
		"text_keys": {"off": "assist_hint", "waiting": "assist_waiting", "active": "assist_active", "metronome": "assist_metronome", "button": "assist_button"},
		"button": {"normal": "ui_button_hold_normal", "pressed": "ui_button_hold_pressed", "icon": "icon_key_shift", "size": [64, 15]},
		"layout_sugerido": {"chip": [196, 275, 188, 13], "button": [388, 274, 64, 15],
			"note": "Faixa de baixo da sala (abaixo dos pés do lutador, y 272), centrada: chip do estado + botão SEGURAR à direita. O botão some no estado metronome (o chip fica sozinho, centrado em x 320). Quem decide é o UI/UX (passa pela alinhamento-ui)."},
		"signal": "assistido_mudou(estado): troca o chip; auto_socou com o estado active: 0,15 s no ui_assist_chip_active_pulse."}
	doc["by_data_id"] = bd
	var fa := FileAccess.open(OUT + "manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

# ================================================================ helpers de mockup
func nine(dst: Image, src: Image, x: int, y: int, w: int, h: int, m: Dictionary) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	var l: int = m.left
	var r: int = m.right
	var t: int = m.top
	var bo: int = m.bottom
	for yy in h:
		var sy := yy
		if yy >= h - bo:
			sy = sh - (h - yy)
		elif yy >= t:
			sy = t + (yy - t) % maxi(sh - t - bo, 1)
		for xx in w:
			var sx := xx
			if xx >= w - r:
				sx = sw - (w - xx)
			elif xx >= l:
				sx = l + (xx - l) % maxi(sw - l - r, 1)
			var c := src.get_pixel(clampi(sx, 0, sw - 1), clampi(sy, 0, sh - 1))
			if c.a > 0.0 and x + xx >= 0 and y + yy >= 0 and x + xx < dst.get_width() and y + yy < dst.get_height():
				dst.set_pixel(x + xx, y + yy, c)

func spr(id: String) -> Dictionary:
	if M.has(id):
		return M[id]
	return OLD.get("sprites", {}).get(id, {})

func frame_of(id: String, i := 0) -> Image:
	if F.has(id):
		return F[id][i]
	var e := spr(id)
	var img := Image.load_from_file(ROOT + str(e.file).replace("res://", ""))
	img.convert(Image.FORMAT_RGBA8)
	var fw: int = int(e.frame_size[0])
	var fh: int = int(e.frame_size[1])
	return img.get_region(Rect2i(i * fw, 0, fw, fh))

func put(dst: Image, id: String, i: int, pos: Vector2i) -> void:
	var fr: Image = frame_of(id, i)
	var pv: Array = spr(id).get("pivot", [0, 0])
	dst.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), pos - Vector2i(int(pv[0]), int(pv[1])))

func ns(dst: Image, id: String, x: int, y: int, w: int, h: int) -> void:
	nine(dst, frame_of(id), x, y, w, h, spr(id).nine_slice)

func save_x(img: Image, path: String, k: int) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	b.save_png(path)

## Garagem no começo da carreira: só o saco; a esteira e a corda são marca de fita + plaquinha.
## tread / rope: "mark" (falta), "owned" (está lá), "none" (não desenha)
func garage_start(tread: String, rope: String, tread_lines: Array, rope_lines: Array, tm_drop := 0, fx_f := -1) -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	img.blit_rect(frame_of("garage_bg"), Rect2i(0, 0, 384, 272), Vector2i(128, 18))
	if tread == "mark":
		put(img, "tape_mark_treadmill", 0, TREAD_POS)
		put(img, "ghost_treadmill", 0, TREAD_POS)
	if rope == "mark":
		put(img, "tape_mark_rope", 0, NAIL)
		put(img, "ghost_rope", 0, NAIL)
		var sz := draw_sign(img, SIGN_ROPE_TOPLEFT.x, SIGN_ROPE_TOPLEFT.y, rope_lines)
		put(img, "sign_tape_bit", 0, Vector2i(SIGN_ROPE_TOPLEFT.x + 2, SIGN_ROPE_TOPLEFT.y + 1))
		put(img, "sign_tape_bit", 0, Vector2i(SIGN_ROPE_TOPLEFT.x + sz.x - 3, SIGN_ROPE_TOPLEFT.y + 1))
	elif rope == "owned":
		put(img, "rope_l0_idle", 0, NAIL)
	put(img, "lamp", 0, Vector2i(300, 32))
	for yy in range(33, 183, 4):
		put(img, "bag_chain_tile", 0, Vector2i(335, yy))
	if tread == "mark":
		var sz2 := sign_box(tread_lines)
		draw_sign(img, SIGN_TREAD_BOTTOM.x - sz2.x / 2, SIGN_TREAD_BOTTOM.y - sz2.y, tread_lines)
		put(img, "sign_brick", 0, Vector2i(SIGN_TREAD_BOTTOM.x, SIGN_TREAD_BOTTOM.y + 3))
	elif tread == "owned":
		put(img, "treadmill_l0_side", 0, TREAD_POS + Vector2i(0, tm_drop))
	put(img, "floor_shadow", 0, Vector2i(303, 271))
	put(img, "bag_l0_idle", 0, Vector2i(336, 183))
	put(img, "fighter_punch", 1, Vector2i(303, 272))
	if fx_f >= 0:
		put(img, "fx_arrive_dust", fx_f, TREAD_POS)
	return img

func hud_start() -> Dictionary:
	return {"money": "$ 0", "treino": "420", "treino_s": "+0/S", "fama": "0", "local": "FUNDO DA GARAGEM",
		"carreira": "CARREIRA 1", "attrs": [["FORÇA", "38", 0.1, "r2", "r2"], ["AGILIDADE", "0", 0.0, "b3", "b2"], ["RESISTÊNCIA", "0", 0.0, "y1", "y0"]],
		"legado": "0", "adv": "DUDU", "adv2": "ALONGADO", "risco": "PERIGOSO", "risco_cor": "r2", "cmp": [["FOR", 60, 38], ["AGI", 40, 0], ["RES", 50, 0]],
		"shop": [], "ups": [], "prox_local": "ACADEMIA", "prox_req": "CINTURÃO", "clique": "+1", "focos": [["", "", "d2", false]], "dica": ""}

## Botão de foco no layout real (ui/barra_baixo.gd): 122x34 em x 134 + i*128, y 304.
func focus_button(img: Image, x: int, y: int, st: String, l1: String, l2: String, icon: String, num := "") -> void:
	if st == "owned_sel" or st == "owned":
		var id := "ui_button_focus_strength" if st == "owned_sel" else "ui_button_normal"
		ns(img, id, x, y, FOCUS_W, FOCUS_H)
		put(img, icon, 0, Vector2i(x + 7, y + 11))
		L.text(img, l1, x + 20, y + 4, "white", 1, "ink")
		L.text(img, l2, x + 20, y + 15, "g3", 1, "ink")
		if num != "":
			L.text_right(img, num, x + FOCUS_W - 6, y + 4, "g1", 1, "ink")
		if st == "owned_sel":
			L.R(img, x + 3, y + 36, FOCUS_W - 6, 2, "r2")
		return
	var key := "ui_button_focus_locked_" + st
	ns(img, key, x, y, FOCUS_W, FOCUS_H)
	put(img, icon, 0, Vector2i(x + 2, y + 9))
	var e := spr(key)
	L.text(img, l1, x + 20, y + 4, e.text_color, 1, "ink")
	if st == "locked":
		L.text(img, l2, x + 20, y + 15, "g1", 1, "ink")
	else:
		put(img, "icon_treino", 0, Vector2i(x + 20, y + 14))
		L.text(img, l2, x + 31, y + 15, e.price_color, 1, "ink")
		L.text(img, "TREINO", x + 33 + L.text_w(l2), y + 15, "g2" if st == "buyable" or st == "buyable_pulse" else "g0", 1, "ink")

func assist_chip(img: Image, x: int, y: int, w: int, st: String, txt: String) -> void:
	ns(img, "ui_assist_chip_" + st, x, y, w, 13)
	var icons := {"hint": "icon_key_shift", "waiting": "icon_assist_wait", "active": "icon_assist_active", "active_pulse": "icon_assist_active", "metronome": "icon_metronome_9"}
	put(img, icons[st], 0, Vector2i(x + 3, y + 2))
	L.text(img, txt, x + 15, y + 3, spr("ui_assist_chip_" + st).text_color, 1, "ink")

func hold_button(img: Image, x: int, y: int, pressed: bool) -> void:
	var id := "ui_button_hold_pressed" if pressed else "ui_button_hold_normal"
	ns(img, id, x, y, 64, 15)
	var dy := 1 if pressed else 0
	put(img, "icon_key_shift", 0, Vector2i(x + 5, y + 2 + dy))
	L.text(img, "SEGURAR", x + 17, y + 3 + dy, spr(id).text_color, 1, "ink")

func unlock_card(img: Image, x: int, y: int, st: String, name: String, desc: String, price: String, flash := false) -> void:
	ns(img, "ui_card_unlock_flash" if flash else "ui_card_unlock", x, y, 120, 44)
	var icon := "icon_treadmill_locked_buyable" if st == "buyable" else ("icon_treadmill_locked" if name.begins_with("ESTEIRA") else "icon_rope_locked")
	if name.begins_with("CORDA") and st == "buyable":
		icon = "icon_rope_locked_buyable"
	put(img, icon, 0, Vector2i(x + 5, y + 3))
	L.text(img, name, x + 25, y + 4, "white" if st != "locked" else "g2", 1, "ink")
	L.text(img, desc, x + 25, y + 14, "g2" if st != "locked" else "g1", 1, "ink")
	if st == "locked":
		ns(img, "ui_button_disabled", x + 4, y + 28, 112, 13)
		L.text_center(img, price, x + 60, y + 31, "g1", 1, "ink")
	else:
		var bid := "ui_button_normal" if st == "buyable" else "ui_button_disabled"
		ns(img, bid, x + 4, y + 28, 112, 13)
		L.text(img, "COMPRAR", x + 9, y + 31, "white" if st == "buyable" else "g1", 1, "ink")
		var pw: int = L.text_w(price)
		put(img, "icon_treino", 0, Vector2i(x + 110 - pw - 11, y + 30))
		L.text(img, price, x + 110 - pw, y + 31, "y1" if st == "buyable" else "r2", 1, "ink")

func right_panel_treino(img: Image, tread_st: String, rope_st: String, flash_tread := false) -> void:
	L.panel(img, 512, 18, 128, 272)
	ns(img, "ui_button_focus_endurance", 515, 21, 58, 14)
	L.text(img, "TREINO", 530, 24, "y2", 1, "ink")
	ns(img, "ui_button_normal", 576, 21, 58, 14)
	L.text(img, "LOJA", 594, 24, "g3", 1, "ink")
	var y := 40
	# 1 gerador (vizinho) para dar contexto
	ns(img, "ui_card", 516, y, 120, 44)
	put(img, "icon_neighbor", 0, Vector2i(521, y + 11))
	L.text(img, "VIZINHO", 541, y + 4, "white", 1, "ink")
	L.text(img, "+0,5/S", 541, y + 14, "gr3", 1, "ink")
	ns(img, "ui_button_normal", 520, y + 28, 112, 13)
	L.text(img, "CHAMAR", 525, y + 31, "white", 1, "ink")
	put(img, "icon_treino", 0, Vector2i(611, y + 30)); L.text(img, "15", 622, y + 31, "y1", 1, "ink")
	y += 48
	L.text(img, "MELHORIAS", 518, y, "cream", 1, "ink")
	y += 10
	ns(img, "ui_card", 516, y, 120, 44)
	put(img, "icon_bag", 0, Vector2i(521, y + 3))
	L.text(img, "FITA NO SACO", 541, y + 4, "white", 1, "ink")
	L.text(img, "+1 POR CLIQUE", 541, y + 14, "r3", 1, "ink")
	ns(img, "ui_button_normal", 520, y + 28, 112, 13)
	L.text(img, "COMPRAR", 525, y + 31, "white", 1, "ink")
	put(img, "icon_treino", 0, Vector2i(604, y + 30)); L.text(img, "300", 615, y + 31, "y1", 1, "ink")
	y += 47
	unlock_card(img, 516, y, tread_st, "ESTEIRA", "RESISTÊNCIA", "500", flash_tread)
	y += 47
	unlock_card(img, 516, y, rope_st, "CORDA", "AGILIDADE", "DEPOIS DA ESTEIRA" if rope_st == "locked" else "1.5K")

func bottom_bar(img: Image, tread_st: String, rope_st: String) -> void:
	L.panel(img, 0, 290, 640, 70)
	L.text(img, "POR CLIQUE", 8, 298, "g2", 1, "ink")
	L.text(img, "+1", 8, 312, "y1", 2, "ink")
	L.text(img, "AUTO +0/S", 8, 334, "gr3", 1, "ink")
	L.text(img, "FOCO DE TREINO", 136, 293, "g2", 1, "ink")
	L.text_right(img, "F11 TELA CHEIA", 506, 293, "g1", 1, "ink")
	focus_button(img, 134, 304, "owned_sel", "SACO", "FORÇA", "icon_strength", "1")
	focus_button(img, 262, 304, rope_st, "CORDA", "DEPOIS DA ESTEIRA" if rope_st == "locked" else "1.5K", "icon_rope_locked_buyable" if rope_st == "buyable" else "icon_rope_locked")
	focus_button(img, 390, 304, tread_st, "ESTEIRA", "500", "icon_treadmill_locked_buyable" if tread_st.begins_with("buyable") else "icon_treadmill_locked")
	L.text_center(img, "ESPAÇO OU CLIQUE PARA TREINAR", 323, 346, "g1", 1, "ink")
	ns(img, "ui_button_fight_normal", 520, 295, 112, 34)
	L.text_center(img, "LUTAR!", 576, 304, "y2", 2, "ink")
	ns(img, "ui_button_retire_normal", 520, 333, 112, 22)
	L.text_center(img, "APOSENTAR", 576, 340, "p2", 1, "ink")

func make_mock_garage() -> void:
	var out: Image = L.blank(1280, 360)
	# ---- esquerda: começo da carreira (só o saco), esteira comprável, corda trancada, assistido em dica
	var img := garage_start("mark", "mark", ["ESTEIRA", "500 TREINO"], ["CORDA", "DEPOIS DA", "ESTEIRA"])
	L.game_ui(img, hud_start())
	# repinta a sala por cima do game_ui? (game_ui só desenha painéis fora da sala)
	right_panel_treino(img, "buyable", "locked")
	bottom_bar(img, "buyable", "locked")
	var chip_txt := "SEGURE SHIFT: TREINO ASSISTIDO"
	var cw: int = L.text_w(chip_txt) + 19
	var tot := cw + 4 + 64
	var cx := 320 - tot / 2
	assist_chip(img, cx, 275, cw, "hint", chip_txt)
	hold_button(img, cx + cw + 4, 274, false)
	out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i.ZERO)

	# ---- direita: prancha de detalhes
	var p: Image = L.blank(640, 360)
	L.R(p, 0, 0, 640, 360, "d1")
	L.text(p, "BOTÃO DE FOCO TRANCADO (122X34, LAYOUT REAL)", 8, 5, "y1", 1, "ink")
	focus_button(p, 8, 16, "buyable", "ESTEIRA", "500", "icon_treadmill_locked_buyable")
	focus_button(p, 136, 16, "missing", "ESTEIRA", "500", "icon_treadmill_locked")
	focus_button(p, 264, 16, "locked", "CORDA", "DEPOIS DA ESTEIRA", "icon_rope_locked")
	focus_button(p, 392, 16, "buyable_pulse", "CORDA", "1.5K", "icon_rope_locked_buyable")
	L.text(p, "COMPRÁVEL", 8, 53, "gr3", 1, "ink"); L.text(p, "SEM TREINO", 136, 53, "r2", 1, "ink")
	L.text(p, "DEPOIS DA ESTEIRA", 264, 53, "g2", 1, "ink"); L.text(p, "COMPRÁVEL (PULSO)", 392, 53, "gr3", 1, "ink")
	L.text(p, "MODO ASSISTIDO: 4 ESTADOS + SEGURAR", 8, 66, "y1", 1, "ink")
	var rows := [["hint", "SEGURE SHIFT: TREINO ASSISTIDO", true, false], ["waiting", "MÃO PARADA = ASSISTIDO", true, true],
		["active", "ASSISTIDO", true, true], ["active_pulse", "ASSISTIDO", true, true], ["metronome", "METRÔNOMO TOCANDO", false, false]]
	var ry := 78
	for r in rows:
		var w: int = L.text_w(r[1]) + 19
		assist_chip(p, 8, ry, w, r[0], r[1])
		if r[2]:
			hold_button(p, 8 + w + 4, ry - 1, r[3])
		L.text(p, str(r[0]).to_upper(), 290, ry + 3, "g2", 1, "ink")
		ry += 17
	L.text(p, "PLAQUINHAS (TEXTO DO UI_TEXTS POR CIMA)", 8, 166, "y1", 1, "ink")
	var sx := 8
	for ls in [["ESTEIRA", "500 TREINO"], ["CORDA", "1.5K TREINO"], ["CORDA", "DEPOIS DA", "ESTEIRA"], ["CORDA - 1.5K TREINO"]]:
		var sz := draw_sign(p, sx, 178, ls)
		sx += sz.x + 8
	put(p, "icon_treadmill_locked", 0, Vector2i(sx + 4, 180)); put(p, "icon_treadmill_locked_buyable", 0, Vector2i(sx + 22, 180))
	put(p, "icon_rope_locked", 0, Vector2i(sx + 40, 180)); put(p, "icon_rope_locked_buyable", 0, Vector2i(sx + 58, 180))
	# chegada da esteira: 6 quadros (recorte da sala)
	L.text(p, "CHEGADA DA ESTEIRA (QUEDA 24 FPS + POEIRA 12 FPS)", 8, 214, "y1", 1, "ink")
	var drops := [-20, -10, 0, 0, 0, 0]
	for f in 6:
		var g := garage_start("owned" if f > 0 else "mark", "mark", ["ESTEIRA", "500 TREINO"], ["CORDA", "1.5K TREINO"], drops[f], f - 1 if f > 0 else -1)
		if f == 0:
			g = garage_start("mark", "mark", ["ESTEIRA", "500 TREINO"], ["CORDA", "1.5K TREINO"])
		var crop: Image = g.get_region(Rect2i(390, 200, 110, 80))
		p.blit_rect(crop, Rect2i(0, 0, 104, 80), Vector2i(8 + f * 106, 226))
		L.text(p, "ANTES" if f == 0 else str(f - 1), 10 + f * 106, 308, "cream", 1, "ink")
	# corda chegando (recorte da parede)
	L.text(p, "CHEGADA DA CORDA", 8, 322, "y1", 1, "ink")
	for f in 5:
		var g2 := garage_start("owned", "owned", [], [])
		put(g2, "fx_arrive_sparkle", f, NAIL)
		var c2: Image = g2.get_region(Rect2i(326, 60, 52, 30))
		p.blit_rect(c2, Rect2i(0, 0, 52, 30), Vector2i(110 + f * 56, 326))
	out.blit_rect(p, Rect2i(0, 0, 640, 360), Vector2i(640, 0))
	save_x(out, MOCK + "fase4b_garagem_x2.png", 2)
	img.save_png(SCRATCH + "garagem_inicio_base.png")
	save_x(img, SCRATCH + "garagem_inicio_x2.png", 2)

# ================================================================ folha de contato
func make_contact_sheet(path: String, title: String) -> void:
	var S := 3
	var W := 1800
	var gap := 18
	var x := gap
	var y := 50
	var row_h := 0
	var places := []
	for e in SHEETS:
		var img: Image = e[1]
		var w: int = img.get_width() * S
		var lw: int = L.text_w(str(e[0]), 2)
		var h: int = img.get_height() * S + 22
		if x + maxi(w, lw) > W - gap:
			x = gap
			y += row_h + gap
			row_h = 0
		places.append([e, Vector2i(x, y)])
		x += maxi(w, lw) + gap
		row_h = maxi(row_h, h)
	var H := y + row_h + gap
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, title, gap, 14, "y1", 3, "ink")
	for pl in places:
		var e: Array = pl[0]
		var p: Vector2i = pl[1]
		var img: Image = e[1]
		var fw: int = e[2]
		L.text(out, str(e[0]), p.x, p.y, "cream", 2, "ink")
		var big: Image = img.duplicate()
		big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
		var oy := p.y + 20
		for yy in range(0, big.get_height(), 6):
			for xx in range(0, big.get_width(), 6):
				L.R(out, p.x + xx, oy + yy, mini(6, big.get_width() - xx), mini(6, big.get_height() - yy), "d2" if ((xx + yy) / 6) % 2 == 0 else "g0")
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(p.x, oy))
		var nf := img.get_width() / fw
		for i in range(1, nf):
			L.R(out, p.x + i * fw * S, oy, 1, big.get_height(), "y0")
	out.save_png(path)

# ================================================================ main
func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(OUT + "manifest.json")) == OK:
		OLD = j.data
	DirAccess.make_dir_recursive_absolute(SCRATCH)
	make_tape_marks()
	make_ghosts()
	make_sign()
	make_locked_icons()
	make_focus_locked()
	make_unlock_card()
	make_arrival()
	make_assist()
	write_manifest()
	make_contact_sheet(MOCK + "fase4b_sprites_x3.png", "FIGHTCLICKER - FASE 4B - SPRITES PLACEHOLDER (x3)")
	make_mock_garage()
	for s in ["DEPOIS DA ESTEIRA", "SEGURE SHIFT: TREINO ASSISTIDO", "MÃO PARADA = ASSISTIDO", "METRÔNOMO TOCANDO", "CORDA - 1.5K TREINO", "ESTEIRA - 500 TREINO", "1.5K TREINO"]:
		print("largura '%s' = %d px" % [s, L.text_w(s)])
	print("ok: sprites da fase 4b gerados")
	quit()
