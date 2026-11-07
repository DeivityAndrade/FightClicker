extends SceneTree
## Sprites PLACEHOLDER da Fase 4 — Árvore de habilidades + Metrônomo + Revanche. Tudo gerado por código,
## paleta fechada de docs/arte/direcao-visual.md (fonte da verdade: tools/art/pixel_lib.gd).
## Rodar headless a partir de uma pasta com um project.godot vazio (não importa nada no projeto):
##   godot --headless --path <pasta_tmp> --quit-after 60 --script E:/Fightclicker/tools/art/make_sprites_fase4.gd
## Saída:
##   assets/sprites/ui/skill_*.png              ícones dos 10 nós (16x16 cor/cinza + peças 24x24 por estado)
##   assets/sprites/ui/ui_tree_*.png            moldura da árvore, colunas, bifurcação "Y", linhas de ligação
##   assets/sprites/ui/icon_metronome_lN.png    ícone 16x16 da LOJA (um por nível)
##   assets/sprites/garage/metronome_lN.png     prop da prateleira com pêndulo animado (8 quadros)
##   assets/sprites/ui/*revenge*.png            marca "VOCÊ PERDEU PRA ELE" e letreiro REVANCHE!
##   assets/sprites/ui/ui_career_card*.png      cartão "o que você trouxe"
##   assets/sprites/manifest.json               ACRESCENTA as entradas da Fase 4 (não apaga as anteriores)
##   docs/arte/mockups/fase4_sprites_x3.png, fase4_arvore_x2.png, fase4_garagem_x2.png
## Não toca em personagens (characters/, fight/fight_player_*, opponents/).

const ROOT := "E:/Fightclicker/"
const OUT := ROOT + "assets/sprites/"
const RES := "res://assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"

var L
var M := {}
var F := {}
var SHEETS := []
var OLD := {}

const T := Color(0, 0, 0, 0)

# ================================================================ dados (espelham docs/fases/fase4-design.md §3)
const NODES := [
	["body_jab", "body", "", "Jab de base"],
	["body_muscle_memory", "body", "body_jab", "Memória muscular"],
	["body_heavy_hands", "body", "body_muscle_memory", "Mão pesada"],
	["body_crew", "body", "body_jab", "Garagem animada"],
	["body_crew_2", "body", "body_crew", "Garagem lotada"],
	["career_purse", "career", "", "Bolsa negociada"],
	["career_scouting", "career", "career_purse", "Olho de treinador"],
	["career_purse_2", "career", "career_scouting", "Empresário de bairro"],
	["career_crowd", "career", "career_purse", "Torcida da rua"],
	["career_good_loser", "career", "career_crowd", "Saber cair"],
]
## Cor de cada ramo: [sombra, base, luz]. Corpo = vermelho (Força), Carreira = ouro (dinheiro/fama).
const BRANCH := {"body": ["r1", "r2", "r3"], "career": ["br2", "y0", "y1"]}
const STATES := ["owned", "buyable", "missing", "locked"]

# Metrônomo: intervalo (s) por nível, do data/shop.json proposto (fase4-design §4.1)
const METRO := {"metronome_l1": 2.0, "metronome_l2": 1.0, "metronome_l3": 0.7}
const METRO_FRAMES := 8
const METRO_POS := Vector2i(240, 118)    # na prateleira da garagem (tela base), pé do metrônomo na tábua

# ================================================================ utilidades
func V(x, y) -> Vector2:
	return Vector2(x, y)

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

## Contorno ink de 1 px dentro do mesmo tamanho (a arte precisa deixar 1 px de margem).
func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

## Desenha um mapa de caracteres (legenda char -> cor). '.' = transparente.
func pmap(img: Image, x: int, y: int, rows: Array, leg: Dictionary) -> void:
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			var ch := r[i]
			if ch != "." and leg.has(ch):
				L.P(img, x + i, y + j, leg[ch])

## Versão "trancada": cada cor vira um cinza escuro pela luminância (ink continua ink).
func grayed(src: Image, dark := true) -> Image:
	var out: Image = src.duplicate()
	var ramp := ["d1", "d2", "g0", "g1"] if dark else ["d2", "g0", "g1", "g2", "g3"]
	var ink_hex: String = L.C.ink.to_html(false)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a == 0.0 or c.to_html(false) == ink_hex:
				continue
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			var i := clampi(int(lum * ramp.size() * 1.05), 0, ramp.size() - 1)
			out.set_pixel(x, y, L.C[ramp[i]])
	return out

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

# ================================================================ ícones dos nós (16x16)
## Luva apontando para a direita (corpo 10x9 + punho), usada no Jab e (girada) na Mão pesada.
func glove_right(img: Image, ox: int, oy: int, ramp := ["r0", "r1", "r2", "r3"]) -> void:
	# punho (esquerda)
	L.R(img, ox, oy + 3, 4, 6, "white"); L.R(img, ox, oy + 7, 4, 2, "cream"); L.R(img, ox, oy + 5, 4, 1, "g3")
	# corpo
	L.rrect(img, ox + 3, oy, 10, 10, ramp[2])
	L.R(img, ox + 4, oy + 7, 9, 2, ramp[1]); L.R(img, ox + 5, oy + 9, 7, 1, ramp[1])
	L.R(img, ox + 7, oy + 1, 4, 1, ramp[3]); L.R(img, ox + 11, oy + 2, 1, 2, ramp[3])
	# polegar (por cima, junto do punho)
	L.R(img, ox + 4, oy + 4, 5, 1, ramp[1]); L.P(img, ox + 9, oy + 3, ramp[1])
	L.P(img, ox + 4, oy + 3, ramp[0])

func icon_body_jab() -> Image:
	var g: Image = L.blank(16, 16)
	glove_right(g, 3, 3)
	var o := ol(g)
	# linhas de velocidade (sem contorno)
	L.R(o, 0, 5, 3, 1, "cream"); L.R(o, 0, 8, 2, 1, "g3"); L.R(o, 0, 11, 3, 1, "cream")
	return o

func icon_body_heavy_hands() -> Image:
	# luva vista de frente batendo para baixo (punho em cima, polegar à esquerda), com faixa de chumbo no punho
	var g: Image = L.blank(16, 16)
	pmap(g, 1, 1, [
		"...LLLLLLL....",
		"...lllllll....",
		"...wwwwwww....",
		"..bccccccdd...",
		".bacccccccdd..",
		"bbacccccccccd.",
		"bbacccccccccd.",
		"bbbacccccccdd.",
		".bbbaccccccd..",
		"..bbbbbbbbb...",
	], {"L": "g0", "l": "d2", "w": "white", "c": "r2", "d": "r3", "b": "r1", "a": "r0"})
	L.R(g, 7, 7, 1, 3, "r1"); L.R(g, 10, 7, 1, 3, "r1")   # dobras dos dedos
	var o := ol(g)
	# impacto embaixo: estouro amarelo e rachadura
	L.R(o, 1, 13, 3, 1, "y1"); L.R(o, 11, 13, 3, 1, "y1"); L.P(o, 0, 12, "y2"); L.P(o, 14, 12, "y2")
	L.R(o, 3, 15, 10, 1, "y0"); L.R(o, 5, 14, 6, 1, "y2")
	return o

## Metrônomo genérico (usado no ícone da Memória muscular e no ícone da LOJA).
## Desenha num retângulo interno w x h começando em (ox, oy). Sem contorno.
func metro_shape(img: Image, ox: int, oy: int, w: int, h: int, mat: Dictionary, ang := 0.0, tick := false) -> void:
	var top := 2 + int(h * 0.12)
	var base_y := h - int(h * 0.18)          # onde começa o pedestal
	var cx := (w - 1) / 2.0
	var tw := maxf(2.0, w * 0.16)
	# corpo (trapézio)
	for y in range(top, base_y):
		var t := float(y - top) / float(base_y - 1 - top)
		var hw := lerpf(tw, w * 0.44, t)
		var a := int(round(cx - hw))
		var b := int(round(cx + hw))
		for x in range(a, b + 1):
			var cname: String = mat.body
			if x <= a + int(hw * 0.35):
				cname = mat.dark
			elif x >= b - int(hw * 0.3):
				cname = mat.light
			L.P(img, ox + x, oy + y, cname)
	# tampa
	L.R(img, ox + int(round(cx - tw)), oy + top - 1, int(tw * 2) + 1, 1, mat.cap)
	# fenda da frente
	for y in range(top + 2, base_y - 2):
		var t := float(y - top) / float(base_y - 1 - top)
		var hw := lerpf(0.6, w * 0.13, t)
		for x in range(int(round(cx - hw)), int(round(cx + hw)) + 1):
			L.P(img, ox + x, oy + y, mat.slot)
	if mat.has("ticks"):
		for y in range(top + 4, base_y - 3, 2):
			L.P(img, ox + int(round(cx)), oy + y, mat.ticks)
	# pedestal
	L.R(img, ox, oy + base_y, w, h - base_y, mat.base)
	L.R(img, ox, oy + base_y, w, 1, mat.base_hi)
	L.R(img, ox, oy + h - 1, w, 1, mat.base_lo)
	if mat.has("trim"):
		L.R(img, ox + 1, oy + base_y + 1, w - 2, 1, mat.trim)
	if mat.get("tape", false):
		var ty := top + int((base_y - top) * 0.55)
		var t2 := float(ty - top) / float(base_y - 1 - top)
		var hw2 := lerpf(tw, w * 0.44, t2)
		L.R(img, ox + int(round(cx - hw2)), oy + ty, int(hw2 * 2) + 1, 2, "cream")
		L.R(img, ox + int(round(cx - hw2)), oy + ty + 1, int(hw2 * 2) + 1, 1, "g3")
	if mat.get("chip", false):
		L.P(img, ox + int(round(cx + tw)), oy + top, T)
		L.P(img, ox + w - 1, oy + base_y, T)

## Haste + peso do pêndulo (pivô embaixo, na fenda), ângulo em graus (+ = topo para a direita).
func metro_rod(img: Image, ox: int, oy: int, w: int, h: int, mat: Dictionary, ang: float) -> Array:
	var base_y := h - int(h * 0.18)
	var cx := (w - 1) / 2.0
	var piv := Vector2(cx, base_y - 2)
	var ln := float(base_y - 2) + 1.0
	var tip := piv + Vector2(sin(deg_to_rad(ang)), -cos(deg_to_rad(ang))) * ln
	L.line(img, ox + int(round(piv.x)), oy + int(round(piv.y)), ox + int(round(tip.x)), oy + int(round(tip.y)), mat.rod)
	var wp := piv.lerp(tip, 0.62)
	var wx := int(round(wp.x))
	var wy := int(round(wp.y))
	L.R(img, ox + wx - 1, oy + wy - 1, 3, 3, mat.weight)
	L.P(img, ox + wx - 1, oy + wy - 1, mat.weight_hi)
	return [Vector2i(ox + int(round(tip.x)), oy + int(round(tip.y)))]

const METRO_MAT := {
	"metronome_l1": {"body": "br1", "dark": "br0", "light": "br2", "cap": "br2", "slot": "ink", "base": "br0", "base_hi": "br1", "base_lo": "ink",
		"rod": "g2", "weight": "g1", "weight_hi": "g2", "tape": true, "chip": true},
	"metronome_l2": {"body": "br2", "dark": "br1", "light": "br3", "cap": "y0", "slot": "br0", "ticks": "cream", "base": "br1", "base_hi": "br2", "base_lo": "br0",
		"rod": "st3", "weight": "y0", "weight_hi": "y1"},
	"metronome_l3": {"body": "d2", "dark": "d1", "light": "g0", "cap": "y1", "slot": "ink", "ticks": "white", "base": "d1", "base_hi": "y0", "base_lo": "ink", "trim": "y1",
		"rod": "white", "weight": "y1", "weight_hi": "y2"},
}

func icon_body_muscle_memory() -> Image:
	var g: Image = L.blank(16, 16)
	var m: Dictionary = METRO_MAT.metronome_l2
	metro_shape(g, 1, 1, 10, 14, m)
	var r: Image = L.blank(16, 16)
	metro_rod(r, 1, 1, 10, 14, m, -22.0)
	g.blend_rect(r, Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	var o := ol(g)
	# brilho roxo do Legado: o ritmo que o lutador anterior deixou
	var sp := [V(13, 2), V(12, 7)]
	L.P(o, 13, 1, "p2"); L.R(o, 12, 2, 3, 1, "p2"); L.P(o, 13, 3, "p2"); L.P(o, 13, 2, "y2")
	L.P(o, 13, 7, "p1"); L.R(o, 12, 8, 3, 1, "p1"); L.P(o, 13, 9, "p1"); L.P(o, 13, 8, "p2")
	L.P(o, 14, 12, "p1"); L.P(o, 14, 13, "p0")
	return o

## Busto de uma pessoa (cabeça + ombros), camiseta verde (renda passiva = verde).
func bust(img: Image, x: int, y: int, skin: Array, shirt: Array, hair: String) -> void:
	L.ellipse(img, x + 3, y + 3, 3, 3, skin[1])
	L.R(img, x + 1, y, 4, 2, hair); L.P(img, x, y + 1, hair)
	L.P(img, x + 4, y + 3, skin[2])
	L.rrect(img, x - 1, y + 6, 9, 6, shirt[1])
	L.R(img, x + 5, y + 7, 2, 4, shirt[2])
	L.R(img, x, y + 10, 7, 2, shirt[0])
	L.P(img, x + 3, y + 6, skin[0])

func icon_crew(n: int) -> Image:
	var g: Image = L.blank(16, 16)
	if n == 2:
		var b: Image = L.blank(16, 16)
		bust(b, 2, 3, ["sk0", "sk0", "sk1"], ["gr0", "gr1", "gr1"], "br0")
		g.blend_rect(ol(b), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
		var f: Image = L.blank(16, 16)
		bust(f, 7, 4, ["sk0", "sk1", "sk2"], ["gr1", "gr2", "gr3"], "ink")
		g.blend_rect(ol(f), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	else:
		var b1: Image = L.blank(16, 16)
		bust(b1, 1, 2, ["br0", "sk0", "sk1"], ["gr0", "gr1", "gr1"], "ink")
		g.blend_rect(ol(b1), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
		var b2: Image = L.blank(16, 16)
		bust(b2, 8, 2, ["sk1", "sk1", "sk2"], ["gr0", "gr1", "gr1"], "br1")
		g.blend_rect(ol(b2), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
		var f: Image = L.blank(16, 16)
		bust(f, 4, 4, ["sk0", "sk1", "sk2"], ["gr1", "gr2", "gr3"], "br0")
		g.blend_rect(ol(f), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	return g

func icon_career_purse() -> Image:
	var g: Image = L.blank(16, 16)
	L.ellipse(g, 7.5, 10.0, 6.0, 5.0, "br3")
	L.ellipse_dither(g, 6.0, 12.0, 4.5, 2.5, "br2")
	L.R(g, 5, 4, 6, 2, "br3")              # pescoço
	L.R(g, 5, 5, 6, 1, "r1")               # cordão
	L.R(g, 4, 2, 2, 2, "br3"); L.R(g, 10, 2, 2, 2, "br3"); L.R(g, 7, 3, 2, 1, "br2")
	L.P(g, 11, 7, "y1"); L.P(g, 12, 8, "y1")
	var o := ol(g)
	# cifrão
	pmap(o, 6, 7, [".#.", "###", "#..", "###", "..#", "###", ".#."], {"#": "br0"})
	return o

func icon_career_scouting() -> Image:
	var g: Image = L.blank(16, 16)
	# olho
	pmap(g, 1, 2, [
		"....######....",
		"..##wwwwww##..",
		".#wwwbbbbwww#.",
		"#wwwbbkkbbwww#",
		".#wwwbbbbwww#.",
		"..##wwwwww##..",
		"....######....",
	], {"#": "ink", "w": "white", "b": "b2", "k": "ink"})
	L.P(g, 7, 4, "b3"); L.P(g, 8, 5, "y2")
	# porcentagem
	var p: Image = L.blank(16, 16)
	pmap(p, 8, 10, ["##..#", "##.#.", "..#..", ".#.##", "#..##"], {"#": "y1"})
	g.blend_rect(ol(p), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	return g

func icon_career_purse_2() -> Image:
	# maleta do empresário com notas saindo pela fresta
	var n: Image = L.blank(16, 16)
	L.R(n, 9, 2, 5, 4, "gr2"); L.R(n, 9, 2, 5, 1, "gr3"); L.R(n, 11, 3, 1, 2, "gr1")
	L.R(n, 2, 3, 4, 3, "gr1"); L.R(n, 2, 3, 4, 1, "gr2")
	var g: Image = ol(n)
	var b: Image = L.blank(16, 16)
	L.R(b, 5, 3, 6, 1, "br0"); L.R(b, 5, 3, 1, 3, "br0"); L.R(b, 10, 3, 1, 3, "br0")   # alça
	L.rrect(b, 1, 6, 14, 8, "br1")
	L.R(b, 1, 6, 14, 1, "br2"); L.R(b, 2, 7, 12, 1, "br2")
	L.R(b, 1, 10, 14, 1, "br0")
	L.R(b, 7, 9, 2, 3, "y1"); L.P(b, 7, 11, "y0")
	L.P(b, 13, 8, "br3")
	g.blend_rect(ol(b), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	return g

func icon_career_crowd() -> Image:
	var g: Image = L.blank(16, 16)
	# três braços levantados com punho fechado
	for a in [[1, 7, "sk0", "sk1"], [6, 5, "sk1", "sk2"], [11, 7, "br1", "sk0"]]:
		var l: Image = L.blank(16, 16)
		L.R(l, a[0] + 1, a[1] + 3, 2, 16 - a[1] - 3, a[2])
		L.rrect(l, a[0], a[1], 4, 4, a[3])
		L.P(l, a[0] + 3, a[1] + 1, a[2])
		g.blend_rect(ol(l), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	# estrela da fama
	var s: Image = L.blank(16, 16)
	pmap(s, 5, 0, ["..#..", "#####", ".###.", ".#.#."], {"#": "p2"})
	L.P(s, 7, 1, "y2")
	g.blend_rect(s, Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	return g

func icon_career_good_loser() -> Image:
	var g: Image = L.blank(16, 16)
	# colchonete de queda
	var mat: Image = L.blank(16, 16)
	L.rrect(mat, 1, 11, 14, 4, "b2")
	L.R(mat, 1, 11, 14, 1, "b3"); L.R(mat, 1, 14, 14, 1, "b1")
	L.R(mat, 5, 12, 1, 2, "b1"); L.R(mat, 10, 12, 1, 2, "b1")
	g.blend_rect(ol(mat), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	# chama do Legado pousada no colchão (a queda não apaga)
	var f: Image = L.blank(16, 16)
	pmap(f, 4, 1, [
		"....#...",
		"...##...",
		"..###.#.",
		"..####..",
		".#####..",
		".##c###.",
		".#ccc##.",
		"..ccc#..",
		"...##...",
	], {"#": "p1", "c": "p2"})
	L.P(f, 7, 7, "y2"); L.P(f, 7, 8, "white")
	g.blend_rect(ol(f), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	# seta curva da queda
	L.P(g, 13, 2, "cream"); L.P(g, 14, 3, "cream"); L.P(g, 14, 4, "cream"); L.P(g, 14, 5, "cream"); L.P(g, 13, 6, "cream"); L.P(g, 13, 5, "cream"); L.P(g, 12, 6, "cream")
	return g

func node_icon(id: String) -> Image:
	match id:
		"body_jab": return icon_body_jab()
		"body_muscle_memory": return icon_body_muscle_memory()
		"body_heavy_hands": return icon_body_heavy_hands()
		"body_crew": return icon_crew(2)
		"body_crew_2": return icon_crew(3)
		"career_purse": return icon_career_purse()
		"career_scouting": return icon_career_scouting()
		"career_purse_2": return icon_career_purse_2()
		"career_crowd": return icon_career_crowd()
		"career_good_loser": return icon_career_good_loser()
	return L.blank(16, 16)

## Peça 24x24 do nó na árvore (moldura + ícone), por estado.
func node_tile(icon: Image, branch: String, state: String, frame := 0) -> Image:
	var t: Image = L.blank(24, 24)
	var br: Array = BRANCH[branch]
	match state:
		"owned":
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, br[1])
			L.R(t, 2, 1, 20, 1, br[2]); L.R(t, 1, 2, 1, 20, br[2])
			L.R(t, 2, 22, 20, 1, br[0]); L.R(t, 22, 2, 1, 20, br[0])
			L.R(t, 3, 3, 18, 18, "ink")
			L.R(t, 4, 4, 16, 16, "d2")
			L.R(t, 4, 4, 16, 1, "g0")
			t.blend_rect(icon, Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			# selo de aprendido (✓ verde) no canto
			L.R(t, 15, 15, 9, 9, "ink"); L.R(t, 16, 16, 7, 7, "gr1"); L.R(t, 16, 16, 7, 1, "gr2")
			pmap(t, 17, 17, [".....", "....#", "...#.", "#.#..", ".#..."], {"#": "gr3"})
		"buyable":
			var edge: String = "gr3" if frame == 0 else "white"
			var edge2: String = "gr2" if frame == 0 else "gr3"
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, edge)
			L.R(t, 2, 22, 20, 1, edge2); L.R(t, 22, 2, 1, 20, edge2)
			L.R(t, 2, 2, 20, 20, "ink")
			L.R(t, 3, 3, 18, 18, "gr1" if frame == 1 else "d2")
			L.R(t, 4, 4, 16, 16, "d1")
			L.dither(t, 4, 4, 16, 16, "gr0", frame)
			t.blend_rect(icon, Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			# cantinhos acesos (chamam o clique)
			for c in [Vector2i(0, 0), Vector2i(21, 0), Vector2i(0, 21), Vector2i(21, 21)]:
				L.R(t, c.x + 1, c.y + 1, 2, 2, "white" if frame == 1 else "y2")
		"missing":
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, "g0")
			L.R(t, 2, 1, 20, 1, "g1")
			L.R(t, 2, 2, 20, 20, "ink")
			L.R(t, 3, 3, 18, 18, "d1")
			t.blend_rect(icon, Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			# escurece meio a meio (dá para ver o que é, mas não está ao alcance)
			for y in range(4, 20):
				for x in range(4, 20):
					if (x + y) % 2 == 0 and t.get_pixel(x, y).a > 0.0:
						t.set_pixel(x, y, L.shade(t.get_pixel(x, y), -1))
			# moedinha de Legado faltando (canto, roxo apagado)
			L.R(t, 16, 16, 7, 7, "ink"); L.R(t, 17, 17, 5, 5, "p0"); L.R(t, 19, 18, 1, 3, "r2")
		"locked":
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, "d2")
			L.R(t, 2, 2, 20, 20, "ink")
			L.R(t, 3, 3, 18, 18, "d1")
			t.blend_rect(grayed(icon), Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			# cadeado
			var lk: Image = L.blank(9, 10)
			pmap(lk, 0, 0, [
				"..kkkkk..",
				".kgg.ggk.",
				".kg...gk.",
				"kkkkkkkkk",
				"kGGGGGGGk",
				"kGGGkGGGk",
				"kGGGkGGGk",
				"kgggggggk",
				"kkkkkkkkk",
			], {"k": "ink", "g": "g1", "G": "g2"})
			t.blend_rect(lk, Rect2i(0, 0, 9, 9), Vector2i(15, 15))
	return t

func make_node_icons() -> void:
	for n in NODES:
		var id: String = n[0]
		var br: String = n[1]
		var ic := node_icon(id)
		var sid := "skill_" + id
		save_sheet(sid, "ui/%s.png" % sid, [ic], 0, Vector2i.ZERO, {"note": "Ícone 16x16 do nó '%s' (ramo %s), em cor. Cartão 'o que você trouxe', resumo da garagem e dentro da peça 24x24." % [n[3], "Corpo" if br == "body" else "Carreira"]})
		save_sheet(sid + "_gray", "ui/%s_gray.png" % sid, [grayed(ic)], 0, Vector2i.ZERO, {"note": "Ícone 16x16 do nó '%s' trancado (cinza escuro)." % n[3]}, false)
		for st in STATES:
			var frames := [node_tile(ic, br, st, 0)]
			var fps := 0.0
			if st == "buyable":
				frames.append(node_tile(ic, br, st, 1))
				fps = 3.0
			var notes := {"owned": "COMPRADO: moldura acesa na cor do ramo e ✓ verde.",
				"buyable": "COMPRÁVEL: borda verde viva pulsando (2 quadros, loop) — é o que chama o clique.",
				"missing": "FALTA LEGADO: ícone visível, meio apagado, moeda roxa com risco vermelho. Preço em r2 ('FALTAM {n}').",
				"locked": "TRANCADO (pede o nó anterior): ícone cinza e cadeado. Texto 'PEDE: {nome}' em g1."}
			var info := {"note": "Peça 24x24 do nó '%s'. %s" % [n[3], notes[st]]}
			if st == "buyable":
				info["loop"] = true
			save_sheet(sid + "_" + st, "ui/%s_%s.png" % [sid, st], frames, fps, Vector2i.ZERO, info)
		# amostra dos estados lado a lado só para a folha de contato

# ================================================================ moldura da árvore
## Geometria recomendada da árvore (janela 480x292 centrada na tela 640x360).
const TREE := {
	"window": [80, 20, 480, 300],
	"title_band": [86, 26, 468, 16],
	"columns": {"body": [90, 48, 226, 228], "career": [324, 48, 226, 228]},
	"col_header_h": 14,
	"node_slots": {"root": [113, 22], "a1": [56, 100], "a2": [56, 167], "b1": [170, 100], "b2": [170, 167]},
	"fork": [55, 78],
	"link": [[56, 155], [170, 155]],
	"button": [240, 284, 160, 24],
}
## Por ramo: qual nó vai em cada slot. "a" = caminho da esquerda, "b" = caminho da direita.
const SLOTS := {
	"body": {"root": "body_jab", "a1": "body_muscle_memory", "a2": "body_heavy_hands", "b1": "body_crew", "b2": "body_crew_2"},
	"career": {"root": "career_purse", "a1": "career_scouting", "a2": "career_purse_2", "b1": "career_crowd", "b2": "career_good_loser"},
}
const FORK_W := 117      # 2 x 57 + 3
const FORK_H := 22

func link_cols(active: bool) -> Array:
	return ["p0", "p2", "p0"] if active else ["ink", "g1", "ink"]

func vline(img: Image, x: int, y: int, h: int, active: bool) -> void:
	var c := link_cols(active)
	for i in 3:
		L.R(img, x + i, y, 1, h, c[i])
	if active:
		for yy in range(y + 1, y + h, 4):
			L.P(img, x + 1, yy, "white")

func hline(img: Image, x: int, y: int, w: int, active: bool) -> void:
	var c := link_cols(active)
	for i in 3:
		L.R(img, x, y + i, w, 1, c[i])
	if active:
		for xx in range(x + 1, x + w, 4):
			L.P(img, xx, y + 1, "white")

func make_tree_frame() -> void:
	# janela: quadro de cortiça/madeira do velho, pregado na parede (9-slice)
	var w: Image = L.blank(24, 24)
	L.R(w, 0, 0, 24, 24, "ink")
	L.R(w, 1, 1, 22, 22, "br1")
	L.R(w, 1, 1, 22, 1, "br2"); L.R(w, 1, 1, 1, 22, "br2")
	L.R(w, 1, 22, 22, 1, "br0"); L.R(w, 22, 1, 1, 22, "br0")
	L.P(w, 9, 2, "br0"); L.P(w, 15, 21, "br0"); L.P(w, 2, 14, "br0"); L.P(w, 21, 8, "br0")   # veios
	L.R(w, 5, 5, 14, 14, "ink"); L.R(w, 6, 6, 12, 12, "d1")
	for c in [Vector2i(2, 2), Vector2i(20, 2), Vector2i(2, 20), Vector2i(20, 20)]:
		L.R(w, c.x, c.y, 2, 2, "st2"); L.P(w, c.x, c.y, "st3"); L.P(w, c.x + 1, c.y + 1, "st0")   # pregos
	save_sheet("ui_tree_window", "ui/ui_tree_window.png", [w], 0, Vector2i.ZERO, {"nine_slice": {"left": 6, "top": 6, "right": 6, "bottom": 6},
		"note": "Janela da árvore (9-slice): quadro de madeira com pregos, fundo escuro. Tamanho recomendado 480x300 em (80,20) — ver tree_layout. Título com ui_window_title_retire (roxo do Legado)."})
	# colunas (Corpo / Carreira): faixa de cabeçalho na cor do ramo
	for b in ["body", "career"]:
		var br: Array = BRANCH[b]
		var c: Image = L.blank(20, 32)
		L.R(c, 0, 0, 20, 32, "ink")
		L.R(c, 1, 1, 18, 30, "d1")
		L.R(c, 1, 1, 18, 13, br[0]); L.R(c, 1, 1, 18, 1, br[1]); L.R(c, 1, 13, 18, 1, L.shade(L.col(br[0]), -1))
		L.R(c, 1, 14, 18, 1, "ink")
		L.R(c, 1, 15, 1, 15, "d2"); L.R(c, 18, 15, 1, 15, "ink")
		save_sheet("ui_tree_column_" + b, "ui/ui_tree_column_%s.png" % b, [c], 0, Vector2i.ZERO,
			{"nine_slice": {"left": 3, "top": 16, "right": 3, "bottom": 3},
			"note": "Coluna do ramo %s (9-slice). Faixa de cima (14 px) = nome do ramo (tree_branch_%s) centralizado, branco com sombra ink, com icon_branch_%s à esquerda." % ["CORPO" if b == "body" else "CARREIRA", b, b]})
	# ícones 9x9 dos ramos
	var ib: Image = L.blank(9, 9)
	L.rrect(ib, 2, 1, 6, 6, "r2"); L.R(ib, 1, 3, 2, 4, "white"); L.R(ib, 3, 5, 5, 2, "r1"); L.P(ib, 6, 2, "r3")
	save_sheet("icon_branch_body", "ui/icon_branch_body.png", [ol(ib)], 0, Vector2i.ZERO, {"note": "Ícone 9x9 do ramo CORPO (luva)."})
	var ic: Image = L.blank(9, 9)
	L.ellipse(ic, 4.5, 4.5, 3.5, 3.5, "y0"); L.ellipse(ic, 4.0, 4.0, 2.5, 2.5, "y1"); L.R(ic, 4, 2, 1, 5, "br2"); L.P(ic, 3, 3, "y2")
	save_sheet("icon_branch_career", "ui/icon_branch_career.png", [ol(ic)], 0, Vector2i.ZERO, {"note": "Ícone 9x9 do ramo CARREIRA (moeda da bolsa)."})
	# bifurcação "Y": três peças no MESMO quadro (empilhar), cada uma normal/ativa
	var parts := {"stem": [], "left": [], "right": []}
	for active in [false, true]:
		var s: Image = L.blank(FORK_W, FORK_H)
		vline(s, 57, 0, 10, active)
		var lft: Image = L.blank(FORK_W, FORK_H)
		hline(lft, 0, 9, 59, active); vline(lft, 0, 9, FORK_H - 9, active)
		var rgt: Image = L.blank(FORK_W, FORK_H)
		hline(rgt, 58, 9, 59, active); vline(rgt, FORK_W - 3, 9, FORK_H - 9, active)
		# nó do encontro (pino) desenhado na haste
		L.R(s, 56, 8, 5, 5, "ink"); L.R(s, 57, 9, 3, 3, "p2" if active else "g0"); L.P(s, 57, 9, "white" if active else "g1")
		var suf := "active" if active else "normal"
		save_sheet("ui_tree_fork_stem_" + suf, "ui/ui_tree_fork_stem_%s.png" % suf, [s], 0, Vector2i(58, 0), {"note": "Bifurcação Y, haste (do 1º nó até o pino). Ativa quando o 1º nó do ramo está comprado. Empilhar as 3 peças no mesmo ponto (pivô = topo da haste)."})
		save_sheet("ui_tree_fork_left_" + suf, "ui/ui_tree_fork_left_%s.png" % suf, [lft], 0, Vector2i(58, 0), {"note": "Bifurcação Y, braço esquerdo (pino até o nó a1). Ativo quando o nó a1 está comprado."})
		save_sheet("ui_tree_fork_right_" + suf, "ui/ui_tree_fork_right_%s.png" % suf, [rgt], 0, Vector2i(58, 0), {"note": "Bifurcação Y, braço direito (pino até o nó b1). Ativo quando o nó b1 está comprado."})
	# linhas retas em ladrilho (esticar/repetir)
	for active in [false, true]:
		var suf := "active" if active else "normal"
		var v: Image = L.blank(3, 4)
		vline(v, 0, 0, 4, active)
		save_sheet("ui_tree_link_v_" + suf, "ui/ui_tree_link_v_%s.png" % suf, [v], 0, Vector2i.ZERO,
			{"tile": "vertical", "note": "Linha de ligação vertical (3 px de largura), repetir na vertical (TextureRect stretch Tile). Ativa = roxo do Legado com faísca a cada 4 px; normal = cinza escuro."})
		var h: Image = L.blank(4, 3)
		hline(h, 0, 0, 4, active)
		save_sheet("ui_tree_link_h_" + suf, "ui/ui_tree_link_h_%s.png" % suf, [h], 0, Vector2i.ZERO,
			{"tile": "horizontal", "note": "Linha de ligação horizontal, repetir na horizontal."})
	# linha vertical do 1º para o 2º nó de cada caminho, com tamanho fixo do layout
	for active in [false, true]:
		var suf := "active" if active else "normal"
		var lk: Image = L.blank(3, 12)
		vline(lk, 0, 0, 12, active)
		save_sheet("ui_tree_link_" + suf, "ui/ui_tree_link_%s.png" % suf, [lk], 0, Vector2i(1, 0),
			{"note": "Ligação fixa (12 px) entre o 1º e o 2º nó de um caminho (layout recomendado). Ativa quando o nó de baixo está comprado."})
	# placa de preço/estado sob o nó (9-slice), para o texto do botão do nó
	for t in [["buy", "gr1", "gr2", "Preço comprável: '{n} DE LEGADO' em y1."], ["owned", "d2", "g0", "'APRENDIDO' em gr3."],
			["missing", "r0", "r1", "'FALTAM {n}' em r3."], ["locked", "d1", "d2", "'PEDE: {nome}' em g1."]]:
		var pl: Image = L.blank(10, 11)
		L.rrect(pl, 0, 0, 10, 11, "ink"); L.R(pl, 1, 1, 8, 9, t[1]); L.R(pl, 1, 1, 8, 1, t[2]); L.R(pl, 1, 9, 8, 1, L.shade(L.col(t[1]), -1))
		save_sheet("ui_tree_plate_" + t[0], "ui/ui_tree_plate_%s.png" % t[0], [pl], 0, Vector2i.ZERO,
			{"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2}, "note": "Plaquinha 9-slice do preço/estado sob o nó. " + t[3]})

# ================================================================ Metrônomo
const MW := 16
const MH := 24

func metro_frame(id: String, k: int) -> Image:
	var m: Dictionary = METRO_MAT[id]
	var amp := 20.0 if id != "metronome_l1" else 18.0
	var ang := amp * cos(k * PI / 4.0)
	var body: Image = L.blank(MW, MH)
	metro_shape(body, 0, 0, MW, MH, m)
	var b2: Image = L.blank(MW + 2, MH + 2)
	b2.blit_rect(L.outlined(body), Rect2i(0, 0, MW + 2, MH + 2), Vector2i.ZERO)
	var rod: Image = L.blank(MW + 2, MH + 2)
	var tip: Array = metro_rod(rod, 1, 1, MW, MH, m, ang)
	var rodo: Image = ol(rod)
	b2.blend_rect(rodo, Rect2i(0, 0, MW + 2, MH + 2), Vector2i.ZERO)
	# "tic" no quadro do extremo (k = 0 e 4): dois risquinhos ao lado da ponta
	if k == 0 or k == 4:
		var tp: Vector2i = tip[0]
		var dx := 2 if k == 0 else -2
		L.P(b2, tp.x + dx, tp.y - 1, "white"); L.P(b2, tp.x + dx + (1 if dx > 0 else -1), tp.y - 2, "y2")
		L.P(b2, tp.x + dx, tp.y + 2, "y2")
	return b2

func make_metronome() -> void:
	var names := {"metronome_l1": "nível 1 — metrônomo velho de feira: madeira gasta, quina lascada, fita crepe segurando, haste e peso de lata",
		"metronome_l2": "nível 2 — madeira envernizada, escala creme na fenda, peso de latão",
		"metronome_l3": "nível 3 — laca preta com frisos dourados, escala branca, peso dourado brilhante"}
	for id in METRO:
		var frames := []
		for k in METRO_FRAMES:
			frames.append(metro_frame(id, k))
		var interval: float = METRO[id]
		var fps := snappedf(4.0 / interval, 0.1)
		save_sheet(id, "garage/%s.png" % id, frames, fps, Vector2i(9, 25), {"loop": true, "pos": xy(METRO_POS),
			"layer": "frente_do_fundo", "z": -60, "tick_frames": [0, 4],
			"note": "Metrônomo na prateleira (%s). 8 quadros = um vai-e-volta completo do pêndulo = 2 auto-socos. Quadros 0 e 4 são os extremos (o 'tic': coincidem com o auto-soco). fps = 4 / intervalo (%.1f s). Pivô = meio da base, na tábua da prateleira. Não aparece no nível 0." % [names[id], interval]})
		# ícone da LOJA 16x16
		var ic: Image = L.blank(16, 16)
		var m: Dictionary = METRO_MAT[id]
		metro_shape(ic, 2, 1, 12, 14, m)
		var r: Image = L.blank(16, 16)
		metro_rod(r, 2, 1, 12, 14, m, 20.0)
		ic.blend_rect(r, Rect2i(0, 0, 16, 16), Vector2i.ZERO)
		var ico := ol(ic)
		# marquinha de nível (1, 2 ou 3 pontos) no canto
		var lv := int(id.right(1))
		for i in lv:
			L.P(ico, 1, 13 - i * 2, "y1")
		save_sheet("icon_" + id, "ui/icon_%s.png" % id, [ico], 0, Vector2i.ZERO, {"note": "Ícone 16x16 da LOJA para o %s. Pontinhos amarelos à esquerda = nível." % id})

# ================================================================ revanche
func bandage_x(img: Image, x: int, y: int, s: int) -> void:
	# dois esparadrapos cruzados, com o pontinho de mertiolate no meio (marca de quem apanhou)
	var l: Image = L.blank(s, s)
	for i in s:
		for d in [-1, 0, 1]:
			L.P(l, i, i + d, "cream")
			L.P(l, s - 1 - i, i + d, "cream")
	for i in range(1, s - 1, 2):
		L.P(l, i, i, "g3"); L.P(l, s - 1 - i, i, "g3")
	var c := s / 2
	L.R(l, c - 1, c - 1, 2 if s < 12 else 3, 2 if s < 12 else 3, "r2")
	L.P(l, c - 1, c - 1, "r3")
	var o: Image = L.outlined(l)
	img.blend_rect(o, Rect2i(0, 0, o.get_width(), o.get_height()), Vector2i(x - 1, y - 1))

func make_revenge() -> void:
	var i9: Image = L.blank(9, 9)
	bandage_x(i9, 1, 1, 7)
	save_sheet("icon_revenge", "ui/icon_revenge.png", [i9], 0, Vector2i.ZERO, {"note": "Ícone 9x9 da marca de revanche (esparadrapo em X): ao lado do nome no bloco PRÓXIMA do HUD."})
	var i16: Image = L.blank(16, 16)
	bandage_x(i16, 1, 1, 14)
	save_sheet("icon_revenge_16", "ui/icon_revenge_16.png", [i16], 0, Vector2i.ZERO, {"note": "Ícone 16x16 da marca de revanche (prévia, tela de vitória)."})
	# fita 9-slice para o texto revenge_mark (pontas recortadas em V)
	var rb: Image = L.blank(18, 13)
	for y in 13:
		var notch := 3 - absi(y - 6) / 2
		L.R(rb, notch, y, 18 - notch * 2, 1, "ink")
		if y > 0 and y < 12:
			L.R(rb, notch + 1, y, 16 - notch * 2, 1, "r1")
	L.R(rb, 3, 1, 12, 1, "r2"); L.R(rb, 3, 10, 12, 1, "r0"); L.R(rb, 3, 11, 12, 1, "ink")
	save_sheet("ui_seal_revenge", "ui/ui_seal_revenge.png", [rb], 0, Vector2i.ZERO, {"nine_slice": {"left": 6, "top": 3, "right": 6, "bottom": 3},
		"note": "Fita vermelha 9-slice da marca de revanche. Texto revenge_mark (ui_texts) 1x em cream com sombra ink, icon_revenge à esquerda. Altura 13 (HUD) ou 15 (prévia)."})
	# selo pronto (com o texto padrão) — conveniência; preferir fita + texto do ui_texts
	var txt := "VOCÊ PERDEU PRA ELE"
	var sw: int = L.text_w(txt) + 26
	var seal: Image = L.blank(sw, 15)
	for y in 15:
		var notch := 3 - absi(y - 7) / 2
		L.R(seal, notch, y, sw - notch * 2, 1, "ink")
		if y > 0 and y < 14:
			L.R(seal, notch + 1, y, sw - 2 - notch * 2, 1, "r1")
	L.R(seal, 3, 1, sw - 6, 1, "r2"); L.R(seal, 3, 12, sw - 6, 1, "r0")
	bandage_x(seal, 5, 3, 9)
	L.text(seal, txt, 17, 4, "cream", 1, "r0")
	save_sheet("seal_revenge_mark", "ui/seal_revenge_mark.png", [seal], 0, Vector2i.ZERO, {"note": "Selo pronto 'VOCÊ PERDEU PRA ELE' (texto padrão embutido). Só use se o texto de ui_texts for igual; senão monte ui_seal_revenge + icon_revenge + Label."})
	# letreiro REVANCHE! (tela de vitória), com estouro atrás
	var bw := 168
	var bh := 52
	var frames := []
	for f in 2:
		var bimg: Image = L.blank(bw, bh)
		var burst: Image = L.blank(bw, bh)
		var cx := bw / 2.0
		var cy := bh / 2.0
		for y in bh:
			for x in bw:
				var dx := (x + 0.5 - cx) / (bw * 0.5)
				var dy := (y + 0.5 - cy) / (bh * 0.5)
				var a := atan2(dy, dx)
				var r := sqrt(dx * dx + dy * dy)
				var spikes := 0.80 + 0.17 * (1.0 if int(floor((a + PI) / (PI / 8.0) + f * 0.5)) % 2 == 0 else -0.2)
				if r < spikes:
					burst.set_pixel(x, y, L.C.r1 if r > spikes - 0.12 else L.C.r2)
		bimg.blend_rect(L.outlined(burst).get_region(Rect2i(1, 1, bw, bh)), Rect2i(0, 0, bw, bh), Vector2i.ZERO)
		var word := "REVANCHE!"
		var tw: int = L.text_w(word, 3)
		var tx := (bw - tw) / 2
		var t: Image = L.blank(bw, bh)
		L.text(t, word, tx, 18, "r0", 3)
		L.text(t, word, tx, 15, "y1", 3)
		var to := ol(t)
		for y in range(15 + 12, 15 + 21):
			for x in bw:
				if to.get_pixel(x, y).to_html(false) == L.C.y1.to_html(false):
					to.set_pixel(x, y, L.C.y0)
		if f == 1:
			for y in range(15, 15 + 21):
				for x in bw:
					if to.get_pixel(x, y).to_html(false) == L.C.y1.to_html(false) and (x - y) % 11 == 0:
						to.set_pixel(x, y, L.C.y2)
		bimg.blend_rect(to, Rect2i(0, 0, bw, bh), Vector2i.ZERO)
		bandage_x(bimg, 10, 6, 10)
		frames.append(bimg)
	save_sheet("ui_banner_revenge", "ui/ui_banner_revenge.png", frames, 4, Vector2i(bw / 2, bh / 2), {"loop": true,
		"note": "Letreiro REVANCHE! da tela de vitória (texto padrão embutido, 2 quadros: estouro gira meio dente e brilho corre na letra). Entra com tremida de 2 px; pode ampliar 2x inteiro."})
	save_sheet("ui_banner_revenge_burst", "ui/ui_banner_revenge_burst.png", [frames[0].duplicate()], 0, Vector2i(bw / 2, bh / 2), {"note": "Só o estouro (sem texto) para o caso de victory_revenge mudar: texto 3x y1 com contorno ink por cima, centralizado."}, false)
	var bonly: Image = L.blank(bw, bh)
	var burst2: Image = L.blank(bw, bh)
	for y in bh:
		for x in bw:
			var dx := (x + 0.5 - bw / 2.0) / (bw * 0.5)
			var dy := (y + 0.5 - bh / 2.0) / (bh * 0.5)
			var a := atan2(dy, dx)
			var r := sqrt(dx * dx + dy * dy)
			var spikes := 0.80 + 0.17 * (1.0 if int(floor((a + PI) / (PI / 8.0))) % 2 == 0 else -0.2)
			if r < spikes:
				burst2.set_pixel(x, y, L.C.r1 if r > spikes - 0.12 else L.C.r2)
	bonly.blend_rect(L.outlined(burst2).get_region(Rect2i(1, 1, bw, bh)), Rect2i(0, 0, bw, bh), Vector2i.ZERO)
	bandage_x(bonly, 10, 6, 10)
	bonly.save_png(OUT + "ui/ui_banner_revenge_burst.png")
	F["ui_banner_revenge_burst"] = [bonly]

# ================================================================ cartão "o que você trouxe"
func make_card() -> void:
	var c: Image = L.blank(24, 24)
	L.rrect(c, 0, 0, 24, 24, "ink")
	L.rrect(c, 1, 1, 22, 22, "p1")
	L.R(c, 2, 1, 20, 1, "p2"); L.R(c, 1, 2, 1, 20, "p2"); L.R(c, 2, 22, 20, 1, "p0"); L.R(c, 22, 2, 1, 20, "p0")
	L.R(c, 3, 3, 18, 18, "ink"); L.R(c, 4, 4, 16, 16, "d1"); L.R(c, 4, 4, 16, 1, "d2")
	for p in [Vector2i(0, 0), Vector2i(19, 0), Vector2i(0, 19), Vector2i(19, 19)]:
		L.R(c, p.x + 1, p.y + 1, 3, 3, "y0"); L.P(c, p.x + 1, p.y + 1, "y2")
	save_sheet("ui_career_card", "ui/ui_career_card.png", [c], 0, Vector2i.ZERO, {"nine_slice": {"left": 5, "top": 5, "right": 5, "bottom": 5},
		"note": "Cartão de início de carreira 'O QUE VOCÊ TROUXE' (9-slice): roxo do Legado com cantos dourados, menor e mais leve que a moldura de aposentadoria. Sugestão 260 x (34 + 14 por nó), centrado acima do alvo, sem cobrir o saco."})
	var tb: Image = L.blank(16, 14)
	L.R(tb, 0, 0, 16, 14, "ink"); L.R(tb, 1, 1, 14, 12, "p0"); L.R(tb, 1, 1, 14, 1, "p1"); L.R(tb, 1, 11, 14, 2, "ink")
	L.P(tb, 0, 0, T); L.P(tb, 15, 0, T)
	save_sheet("ui_career_card_title", "ui/ui_career_card_title.png", [tb], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 4},
		"note": "Faixa do título do cartão (career_card_title), texto 1x cream com sombra ink e icon_legacy à esquerda."})
	var rw: Image = L.blank(12, 14)
	L.R(rw, 0, 0, 12, 14, "d2"); L.R(rw, 0, 0, 12, 1, "g0"); L.R(rw, 0, 13, 12, 1, "d1")
	save_sheet("ui_career_card_row", "ui/ui_career_card_row.png", [rw], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 1, "right": 1, "bottom": 1},
		"note": "Linha de um nó no cartão: skill_<id> 16x16 à esquerda (encosta 1 px acima), effect_text 1x à direita (cor do ramo: r3 Corpo, y1 Carreira)."})
	# selo pequeno "LEGADO: N NÓS" da garagem
	var bd: Image = L.blank(12, 11)
	L.rrect(bd, 0, 0, 12, 11, "ink"); L.R(bd, 1, 1, 10, 9, "p0"); L.R(bd, 1, 1, 10, 1, "p1")
	save_sheet("ui_legacy_nodes_badge", "ui/ui_legacy_nodes_badge.png", [bd], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 2, "right": 3, "bottom": 2},
		"note": "Plaquinha do resumo 'LEGADO: {n} NÓS' na garagem (texto p2 1x). Ao passar o mouse abre a lista no estilo do ui_career_card."})

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
	doc["_sobre"] = "Sprites PLACEHOLDER das Fases 2 (garagem), 3 (lutas) e 4 (árvore, Metrônomo, revanche), gerados por tools/art/make_sprites_fase2.gd, make_sprites_fase3.gd e make_sprites_fase4.gd (personagens: make_sprites_elenco.gd / make_sprites_jogador.gd). Tudo 1x na resolução base 640x360, filtro nearest. Folhas = quadros lado a lado, da esquerda para a direita."
	var spr: Dictionary = doc.get("sprites", {})
	for k in M:
		spr[k] = intify(M[k])
	doc["sprites"] = spr
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["_nota_fase4"] = "Fase 4: nós da árvore (data/skill_tree.json, campo icon = skill_<id>), Metrônomo (data/shop.json bloco metronome), revanche e cartão de início."
	for n in NODES:
		var id: String = n[0]
		var e := {"icon": "skill_" + id, "icon_gray": "skill_%s_gray" % id, "branch": n[1], "requires": n[2], "name_hint": n[3],
			"tile": {}, "tile_size": [24, 24]}
		for st in STATES:
			e.tile[st] = "skill_%s_%s" % [id, st]
		var slot := ""
		for s in SLOTS[n[1]]:
			if SLOTS[n[1]][s] == id:
				slot = s
		e["slot"] = slot
		bd[id] = e
	bd["body"] = {"column": "ui_tree_column_body", "icon": "icon_branch_body", "color": BRANCH.body[1], "effect_text_color": "r3"}
	bd["career"] = {"column": "ui_tree_column_career", "icon": "icon_branch_career", "color": BRANCH.career[1], "effect_text_color": "y1"}
	var lv := []
	for id in METRO:
		lv.append(id)
		bd[id] = {"prop": id, "icon": "icon_" + id, "interval_hint": METRO[id], "fps": snappedf(4.0 / METRO[id], 0.1), "tick_frames": [0, 4], "pos": xy(METRO_POS)}
	bd["metronome"] = {"levels": lv, "icon": "icon_metronome_l1", "prop_by_level": {"0": "", "1": "metronome_l1", "2": "metronome_l2", "3": "metronome_l3"},
		"pos": xy(METRO_POS), "pivot": [9, 25],
		"sync": "Para o pêndulo bater junto com o auto-soco: quadro = int(4.0 * (socos % 2 + acc / intervalo)) % 8, onde socos = auto-socos dados e acc = acumulador do Metrônomo. No soco o quadro é 0 ou 4 (extremo, risquinho do 'tic'). Se preferir fps fixo: fps = 4 / intervalo (já no sprite).",
		"paused": "Com o alvo bloqueado (modal, luta, tela de fim) o acc não anda: o pêndulo congela no quadro em que está.",
		"_nota": "Nível 0 = sem prop. Mais de 3 níveis no data/: usar o metronome_l3 para os acima de 3. Desenhar depois do garage_bg e antes das pessoas (fica na prateleira do fundo, nada passa na frente)."}
	bd["revenge"] = {"icon": "icon_revenge", "icon_16": "icon_revenge_16", "ribbon": "ui_seal_revenge", "seal": "seal_revenge_mark",
		"banner": "ui_banner_revenge", "banner_burst": "ui_banner_revenge_burst", "color": "r1", "text_color": "cream",
		"_nota": "HUD (bloco PRÓXIMA) e topo da prévia: fita ui_seal_revenge + icon_revenge + revenge_mark. Tela de vitória: ui_banner_revenge centrado acima do resumo."}
	bd["career_card"] = {"frame": "ui_career_card", "title": "ui_career_card_title", "row": "ui_career_card_row", "badge": "ui_legacy_nodes_badge"}
	doc["by_data_id"] = bd
	var tl := {"_regra": "Árvore em janela central sobre a sala escurecida (ui_dim_dither). Coordenadas da tela base 640x360. Dentro de cada coluna as posições são relativas ao canto da coluna; node_slots = CENTRO-TOPO da peça 24x24 (x = centro, y = topo).",
		"window": TREE.window, "title_band": TREE.title_band, "columns": TREE.columns, "col_header_h": TREE.col_header_h,
		"node_slots": TREE.node_slots, "slots_by_branch": SLOTS,
		"node_text": "Embaixo da peça (a partir de y+26): nome 1x branco, efeito curto 1x na cor do ramo, plaquinha ui_tree_plate_* com preço/estado. Largura útil por nó: 104 px.",
		"fork_pos": TREE.fork, "fork_note": "Pivô das peças ui_tree_fork_* (topo da haste), relativo à coluna. A haste começa logo abaixo da plaquinha do 1º nó.",
		"links": TREE.link, "links_note": "ui_tree_link_* (12 px), topo relativo à coluna, ligando o 1º e o 2º nó de cada caminho.",
		"legacy_counter": "Faixa do título: tree_title à esquerda, icon_legacy_16 + tree_legacy à direita (p2).",
		"button": TREE.button}
	doc["tree_layout"] = intify(tl)
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

func button9(dst: Image, id: String, x: int, y: int, w: int, h: int, label: String, scale := 1) -> void:
	ns(dst, id, x, y, w, h)
	var tc = spr(id).get("text_color", "white")
	L.text(dst, label, x + (w - L.text_w(label, scale)) / 2, y + (h - 7 * scale) / 2 - 1, tc, scale, "ink")

func dim(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if (x + y) % 2 == 0:
				img.set_pixel(x, y, L.C.ink)

func save_x(img: Image, path: String, k: int) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	b.save_png(path)

func garage_base(metro_id: String, metro_f: int) -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	img.blit_rect(frame_of("garage_bg"), Rect2i(0, 0, 384, 272), Vector2i(128, 18))
	if metro_id != "":
		put(img, metro_id, metro_f, METRO_POS)
	put(img, "lamp", 0, Vector2i(300, 32))
	put(img, "rope_l0_idle", 0, Vector2i(352, 72))
	put(img, "treadmill_l0_side", 0, Vector2i(445, 267))
	for yy in range(33, 183, 4):
		put(img, "bag_chain_tile", 0, Vector2i(335, yy))
	put(img, "floor_shadow", 0, Vector2i(303, 271))
	put(img, "bag_l0_idle", 0, Vector2i(336, 183))
	put(img, "fighter_punch", 1, Vector2i(303, 272))
	return img

func hud_data(legado: String, adv: String) -> Dictionary:
	return {"money": "$ 120", "treino": "31.2K", "treino_s": "+69/S", "fama": "10", "local": "FUNDO DA GARAGEM",
		"carreira": "CARREIRA 2", "attrs": [["FORÇA", "410", 0.5, "r2", "r2"], ["AGILIDADE", "120", 0.3, "b3", "b2"], ["RESISTÊNCIA", "180", 0.35, "y1", "y0"]],
		"legado": legado, "adv": adv, "adv2": "RÁPIDO", "risco": "EQUILIBRADO", "risco_cor": "y1", "cmp": [["FOR", 260, 410], ["AGI", 300, 120], ["RES", 200, 180]],
		"shop": [], "ups": [], "prox_local": "ACADEMIA", "prox_req": "CINTURÃO", "clique": "+36", "focos": [["SACO", "FORÇA", "r1", true], ["CORDA", "AGILIDADE", "b1", false], ["ESTEIRA", "RESISTÊNCIA", "br2", false]],
		"dica": ""}

# ================================================================ mockup: árvore
func make_mock_tree() -> void:
	var img := garage_base("", 0)
	L.game_ui(img, hud_data("0", "DUDU"))
	dim(img)
	var wnd: Array = TREE.window
	var wx: int = wnd[0]
	var wy: int = wnd[1]
	ns(img, "ui_tree_window", wx, wy, wnd[2], wnd[3])
	var tb: Array = TREE.title_band
	ns(img, "ui_window_title_retire", tb[0], tb[1], tb[2], tb[3])
	L.text(img, "O QUE O VELHO TE ENSINOU", tb[0] + 6, tb[1] + 4, "cream", 1, "ink")
	var lg := "LEGADO: 40"
	L.text_right(img, lg, tb[0] + tb[2] - 6, tb[1] + 4, "p2", 1, "ink")
	put(img, "icon_legacy", 0, Vector2i(tb[0] + tb[2] - 6 - L.text_w(lg) - 12, tb[1] + 3))
	# estado de exemplo: Legado 40 depois de comprar jab + bolsa + olho (derrota no Muralha)
	var owned := ["body_jab", "career_purse", "career_scouting"]
	var legacy := 40
	var cost := {"body_jab": 10, "body_muscle_memory": 30, "body_heavy_hands": 500, "body_crew": 150, "body_crew_2": 900,
		"career_purse": 10, "career_scouting": 25, "career_purse_2": 500, "career_crowd": 250, "career_good_loser": 800}
	var short := {"body_jab": ["JAB DE BASE", "+100% CLIQUE"], "body_muscle_memory": ["MEMÓRIA MUSCULAR", "METRÔNOMO NV 1"],
		"body_heavy_hands": ["MÃO PESADA", "+50% CLIQUE"], "body_crew": ["GARAGEM ANIMADA", "+50% EQUIPE"], "body_crew_2": ["GARAGEM LOTADA", "+50% EQUIPE"],
		"career_purse": ["BOLSA NEGOCIADA", "+50% DINHEIRO"], "career_scouting": ["OLHO DE TREINADOR", "PRÉVIA COM %"],
		"career_purse_2": ["EMPRESÁRIO", "+50% DINHEIRO"], "career_crowd": ["TORCIDA DA RUA", "+50% FAMA"], "career_good_loser": ["SABER CAIR", "DERROTA 75%"]}
	var names := {}
	for n in NODES:
		names[n[0]] = short[n[0]][0]
	var req := {}
	for n in NODES:
		req[n[0]] = n[2]
	for b in ["body", "career"]:
		var col: Array = TREE.columns[b]
		var cx: int = col[0]
		var cy: int = col[1]
		ns(img, "ui_tree_column_" + b, cx, cy, col[2], col[3])
		var hdr := "CORPO" if b == "body" else "CARREIRA"
		var hw: int = L.text_w(hdr) + 12
		put(img, "icon_branch_" + b, 0, Vector2i(cx + (col[2] - hw) / 2, cy + 3))
		L.text(img, hdr, cx + (col[2] - hw) / 2 + 12, cy + 4, "white", 1, "ink")
		var sl: Dictionary = SLOTS[b]
		# ligações primeiro (ficam atrás)
		var root_owned: bool = sl.root in owned
		var fk: Array = TREE.fork
		put(img, "ui_tree_fork_stem_" + ("active" if root_owned else "normal"), 0, Vector2i(cx + fk[0] + 58, cy + fk[1]))
		put(img, "ui_tree_fork_left_" + ("active" if sl.a1 in owned else "normal"), 0, Vector2i(cx + fk[0] + 58, cy + fk[1]))
		put(img, "ui_tree_fork_right_" + ("active" if sl.b1 in owned else "normal"), 0, Vector2i(cx + fk[0] + 58, cy + fk[1]))
		var lks: Array = TREE.link
		put(img, "ui_tree_link_" + ("active" if sl.a2 in owned else "normal"), 0, Vector2i(cx + lks[0][0], cy + lks[0][1]))
		put(img, "ui_tree_link_" + ("active" if sl.b2 in owned else "normal"), 0, Vector2i(cx + lks[1][0], cy + lks[1][1]))
		for s in ["root", "a1", "a2", "b1", "b2"]:
			var id: String = sl[s]
			var p: Array = TREE.node_slots[s]
			var nx: int = cx + p[0]
			var ny: int = cy + p[1]
			var st := "locked"
			if id in owned:
				st = "owned"
			elif req[id] == "" or req[id] in owned:
				st = "buyable" if cost[id] <= legacy else "missing"
			put(img, "skill_%s_%s" % [id, st], 0, Vector2i(nx - 12, ny))
			var tcol := "white" if st != "locked" else "g1"
			L.text_center(img, short[id][0], nx, ny + 26, tcol, 1, "ink")
			L.text_center(img, short[id][1], nx, ny + 35, (BRANCH[b][2] if b == "body" else "y1") if st != "locked" else "g0", 1, "ink")
			var plate: String = {"owned": "owned", "buyable": "buy", "missing": "missing", "locked": "locked"}[st]
			var ptxt: String = {"owned": "APRENDIDO", "buyable": "%d DE LEGADO" % cost[id], "missing": "FALTAM %d" % (cost[id] - legacy), "locked": "PEDE: " + names.get(req[id], "")}[st]
			if st == "locked" and L.text_w(ptxt) > 100:
				ptxt = "PEDE O DE CIMA"
			var pcol: String = {"owned": "gr3", "buyable": "y1", "missing": "r3", "locked": "g1"}[st]
			var pw: int = mini(L.text_w(ptxt) + 8, 106)
			ns(img, "ui_tree_plate_" + plate, nx - pw / 2, ny + 44, pw, 11)
			L.text_center(img, ptxt, nx, ny + 46, pcol, 1, "ink")
	var bt: Array = TREE.button
	button9(img, "ui_button_normal", bt[0], bt[1], bt[2], bt[3], "NOVA CARREIRA")
	save_x(img, MOCK + "fase4_arvore_x2.png", 2)
	img.save_png(SCRATCH + "arvore_base.png")

# ================================================================ mockup: garagem + Metrônomo + revanche + cartão
func make_mock_garage() -> void:
	var out: Image = L.blank(1280, 360)
	# esquerda: garagem com Metrônomo nv 2, marca de revanche no HUD e cartão de início aberto
	var img := garage_base("metronome_l2", 0)
	L.game_ui(img, hud_data("20", "DINHO"))
	# marca de revanche no bloco PRÓXIMA LUTA (y do card ~ 156): fita sob o nome
	ns(img, "ui_seal_revenge", 6, 262, 116, 13)
	put(img, "icon_revenge", 0, Vector2i(12, 264))
	L.text(img, "VOCÊ PERDEU PRA ELE", 23, 265, "cream", 1, "r0")
	# selo "LEGADO: 2 NÓS"
	ns(img, "ui_legacy_nodes_badge", 64, 124, 40, 11)
	L.text(img, "2 NÓS", 70, 126, "p2", 1, "ink")
	# cartão de início
	var cw := 230
	var chh := 34 + 14 * 2
	var cx := 320 - cw / 2 + 16
	var cy := 40
	ns(img, "ui_career_card", cx, cy, cw, chh)
	ns(img, "ui_career_card_title", cx + 5, cy + 5, cw - 10, 14)
	put(img, "icon_legacy", 0, Vector2i(cx + 9, cy + 7))
	L.text(img, "CARREIRA 2 - O QUE VOCÊ TROUXE:", cx + 21, cy + 8, "cream", 1, "ink")
	var rows := [["body_jab", "+100% TREINO POR CLIQUE", "r3"], ["career_purse", "+50% DINHEIRO POR VITÓRIA", "y1"]]
	var ry := cy + 22
	for r in rows:
		ns(img, "ui_career_card_row", cx + 6, ry, cw - 12, 14)
		put(img, "skill_" + r[0], 0, Vector2i(cx + 7, ry - 1))
		L.text(img, r[1], cx + 27, ry + 4, r[2], 1, "ink")
		ry += 15
	out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i.ZERO)
	# direita: prateleira ampliada 3x com os 3 níveis e o vai-e-volta, + letreiro REVANCHE!
	var pnl: Image = L.blank(640, 360)
	L.R(pnl, 0, 0, 640, 360, "d1")
	L.text(pnl, "METRÔNOMO NA PRATELEIRA (x3) - NÍVEL 1 / 2 / 3", 8, 6, "y1", 1, "ink")
	for i in 3:
		var id: String = ["metronome_l1", "metronome_l2", "metronome_l3"][i]
		var g := garage_base(id, 0)
		var crop: Image = g.get_region(Rect2i(188, 84, 66, 40))
		crop.resize(198, 120, Image.INTERPOLATE_NEAREST)
		var px := 8 + i * 210
		pnl.blit_rect(crop, Rect2i(0, 0, 200, 120), Vector2i(px, 18))
		L.text(pnl, "NÍVEL %d - %s" % [i + 1, ["2.0 S", "1.0 S", "0.7 S"][i]], px, 141, "cream", 1, "ink")
	L.text(pnl, "PÊNDULO: 8 QUADROS = 2 SOCOS (TIC NOS QUADROS 0 E 4)", 8, 158, "y1", 1, "ink")
	for k in 8:
		var fr: Image = frame_of("metronome_l2", k).duplicate()
		fr.resize(fr.get_width() * 3, fr.get_height() * 3, Image.INTERPOLATE_NEAREST)
		var fx := 8 + k * 60
		L.R(pnl, fx, 170, 56, 82, "g0")
		pnl.blend_rect(fr, Rect2i(0, 0, fr.get_width(), fr.get_height()), Vector2i(fx + 1, 172))
		L.text(pnl, str(k), fx + 2, 244, "y1" if k % 4 == 0 else "g2", 1, "ink")
	# REVANCHE! sobre uma faixa escura (tela de vitória)
	L.R(pnl, 0, 262, 640, 98, "ink")
	L.text(pnl, "TELA DE VITÓRIA", 8, 266, "g2", 1, "ink")
	put(pnl, "ui_banner_revenge", 0, Vector2i(150, 314))
	put(pnl, "ui_banner_revenge", 1, Vector2i(330, 314))
	put(pnl, "seal_revenge_mark", 0, Vector2i(440, 290))
	put(pnl, "icon_revenge_16", 0, Vector2i(440, 316))
	put(pnl, "icon_metronome_l1", 0, Vector2i(470, 316)); put(pnl, "icon_metronome_l2", 0, Vector2i(490, 316)); put(pnl, "icon_metronome_l3", 0, Vector2i(510, 316))
	L.text(pnl, "LOJA", 534, 320, "g2", 1, "ink")
	out.blit_rect(pnl, Rect2i(0, 0, 640, 360), Vector2i(640, 0))
	save_x(out, MOCK + "fase4_garagem_x2.png", 2)

# ================================================================ folha de contato
func make_contact_sheet(path: String, title: String) -> void:
	var S := 3
	var W := 2400
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

## Prancha de legibilidade: os 10 ícones em 1x e 2x, sobre fundo escuro e claro, e as 4 peças por nó.
func make_icon_board(path: String) -> void:
	var out: Image = L.blank(10 * 40 + 20, 230)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	L.R(out, 0, 56, out.get_width(), 22, "g1")
	for i in NODES.size():
		var id: String = NODES[i][0]
		var x := 10 + i * 40
		put(out, "skill_" + id, 0, Vector2i(x, 4))
		put(out, "skill_%s_gray" % id, 0, Vector2i(x + 18, 4))
		var big: Image = frame_of("skill_" + id).duplicate()
		big.resize(32, 32, Image.INTERPOLATE_NEAREST)
		put(out, "skill_" + id, 0, Vector2i(x + 8, 59))
		for s in STATES.size():
			put(out, "skill_%s_%s" % [id, STATES[s]], 0, Vector2i(x + 4, 82 + s * 30))
		var bz: Image = frame_of("skill_" + id).duplicate()
		bz.resize(32, 32, Image.INTERPOLATE_NEAREST)
		out.blend_rect(bz, Rect2i(0, 0, 32, 32), Vector2i(x, 22))
	save_x(out, path, 3)

const SCRATCH := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/art4/"

# ================================================================ main
func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(OUT + "manifest.json")) == OK:
		OLD = j.data
	make_node_icons()
	make_tree_frame()
	make_metronome()
	make_revenge()
	make_card()
	write_manifest()
	make_contact_sheet(MOCK + "fase4_sprites_x3.png", "FIGHTCLICKER - FASE 4 - SPRITES PLACEHOLDER (x3)")
	make_icon_board(SCRATCH + "icones_x3.png")
	make_mock_tree()
	make_mock_garage()
	print("ok: sprites da fase 4 gerados")
	quit()
