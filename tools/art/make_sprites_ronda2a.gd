extends SceneTree
## Ronda 2a1 (Artista de Personagens): o VULTO LUTANDO, a arena do BECO e a prancha de amostra.
## Padrão: .claude/skills/padrao-personagem. Direção: docs/arte/direcao-visual.md §36 (traje) e §29.2 (o R).
##
## VULTO LUTANDO = o traje do Gato Preto VESTIDO SOBRE as folhas de luta do discípulo (as 28 ações das 3 artes do
## by_data_id.player_fight), em camadas, com o mesmo sistema do DiscVisual (troca de cor pela disciple_palette):
##   body  = a camada body do discípulo (luva velha) com a LUVA DA NOITE (pano escuro, punho vermelho da faixa) e a CAPA
##           desenhada ATRÁS do corpo (só onde o corpo é vazio: nunca tapa braço, perna nem luva);
##   head.<corte> = o CAPUZ com orelhas e a faixa vermelha nos olhos (o mesmo mapa aprovado na Ronda 1, make_sprites_ronda.gd
##           HOOD/HOOD_CUTS), carimbado no ponto e no giro da cabeça de cada quadro (anchors.head / head_rot do manifest), com
##           o contorno só onde dá no vazio. Ele SUBSTITUI a cabeça do discípulo (o cabelo some; só o queixo é pele).
##   top / socks / school_symbol.leg / front_mask = os MESMOS arquivos do discípulo (nada novo: o pivô, as mãos e a ordem
##           de desenho são os dele). Sem band (o capuz cobre a faixa), sem school_symbol.chest (como na Ronda 1).
## Nada muda de tamanho, pivô, mãos, hit_frame nem hit_point: são os da folha do discípulo (o manifest copia).
## A folha nunca é espelhada (o vulto luta virado para a DIREITA, como o jogador): o R de raiz da coxa lê certo.
## Sem variantes _glove_lN: de noite a luva é a do traje.
##
## Rodar headless de uma pasta temporária com project.godot vazio, APPDATA temporário, um Godot por vez:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_sprites_ronda2a.gd -- <repo> <saida> [modos]
##   modos: vulto, beco, prancha (sem modo = os três). A prancha lê as folhas dos bandidos de <saida>/opponents/ (modo
##   "alley" do make_sprites_elenco.gd) e as do vulto/beco desta mesma saída.
## Grava em <saida>/ronda2a/ (copiar para assets/sprites/ronda2a/), <saida>/ronda2a_vulto_beco.json (entradas do manifest),
## <saida>/conf/ (conferência ampliada) e <saida>/ronda2a_amostra_luta.png (copiar para docs/arte/mockups/).

const FW := 112
const FH := 104
const CUTS := ["short", "buzz", "volume", "bun"]
const RES := "res://assets/sprites/ronda2a/"

var L
var P
var M: Dictionary
var PAL: Dictionary
var REPO := ""
var OUT := ""
var report: Array = []
var ENT := {}      # entradas do manifest
var BY := {}       # by_data_id

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================================================ capuz (Ronda 1, aprovado)
## Cópia fiel de make_sprites_ronda.gd (HOOD, HOOD_ANCHOR, HOOD_CUTS, HOOD_FACES, hood_legend): o capuz aprovado pelo dono.
## A cabeça de luta é a mesma 14x14 da garagem, então o mapa entra sem escala, no mesmo ponto (âncora (8,11) = (7,7) + (1,4)).
## B5 (Diretor de Arte, 2026-11-26): orelhas de GATO COSTURADAS, não de morcego. As pontas finas de 1 px (linhas 0-2, que em 2x
## liam como orelha de morcego) viraram orelhas baixas de ponta arredondada (2 px em cima, 4-5 na base, nenhuma ponta de 1 px), sem o rosa de
## dentro, e a linha 3 ganhou a COSTURA (t = pontos claros alternados) onde a orelha foi pregada no moletom. Mesmo tamanho
## do mapa (16x22) e mesma âncora: nada muda de lugar.
const HOOD := [
	"................",
	"..KK.....jj.....",
	".KkkK...kjjj....",
	".KtktKKKktjtjj..",
	".KkkkkkkkkjjjjK.",
	".Kkkkkkkkkkjjjj.",
	"KKkkkkkkkkkkjjj.",
	"KKkkkkkkkkkkkjr.",
	"KKkkkkkkkkkkrr..",
	"GGFFFFFFFFFFFF..",
	"GGGGGGGGGGwGGG..",
	".KkkkkkrSsssl...",
	".KkkkkkrSsssll..",
	".KkkKkkrSsssss..",
	".KkkKkkrSssss...",
	".KkkkKkrSsmSs...",
	".KkkkKkrSsss....",
	".KKkkkkrSSs.....",
	".KkkkkkkrK......",
	"KKkkkkkkkrK.....",
	"KkkkKkkkkkrK....",
	"KKkkkKkkkkkK....",
]
const HOOD_ANCHOR := Vector2i(8, 11)
const HOOD_CUTS := {
	"buzz": {},
	"short": {8: "KKkkkkkkkkkkrrH."},
	"volume": {6: "KKkkkkkkkkkkjjjh", 7: "KKkkkkkkkkkkkjHh", 8: "KKkkkkkkkkkkrrH."},
	"bun": {2: "KKkkK...kjjj....", 3: "KKtktKKKktjtjj..", 4: "KkkkkkkkkkjjjjK.", 5: "KKkkkkkkkkkjjjj."},
}
const HOOD_FACES := {
	"normal": {},
	"smirk": {15: "..KkkkkrSssxs..."},
	"scare": {15: "..KkkkkrSxxSs...", 16: "..KKkkkrSxs....."},
	"oops": {15: "..KkkkkrSsxSs...", 16: "..KKkkkrSxs....."},
}
## Expressões da luta -> boca do capuz. No K.O. o olho de gato apaga (a fresta da faixa fica toda vermelha).
const FIGHT_FACE := {"normal": "normal", "joy": "smirk", "pain": "scare", "tired": "oops", "ko": "oops"}
const BAND := ["r1", "r2", "r3"]

func hood_rows(cut: String, face: String) -> Array:
	var rows: Array = HOOD.duplicate()
	var c: Dictionary = HOOD_CUTS[cut]
	for k in c:
		rows[int(k)] = c[k]
	var f: Dictionary = HOOD_FACES[FIGHT_FACE.get(face, "normal")]
	for k in f:
		rows[int(k)] = f[k]
	if face == "ko":
		rows[10] = (rows[10] as String).replace("w", "G")
	return rows

func hood_legend() -> Dictionary:
	var ks: Dictionary = PAL.keys
	return {"K": L.col("d1"), "k": L.col("d2"), "j": L.col("g0"), "n": L.col("g1"), "r": L.col("g1"), "t": L.col("g1"),
		"F": L.col(BAND[1]), "G": L.col(BAND[0]), "w": L.col("y2"),
		"H": Color.html(ks.hair_color.dark), "h": Color.html(ks.hair_color.light),
		"S": Color.html(ks.skin.shadow), "s": Color.html(ks.skin.base), "l": Color.html(ks.skin.light),
		"m": Color.html(ks.skin.shadow), "x": L.col("ink"), "e": L.col("ink")}

## Igual ao pmap do personagem_lib (mesmo arredondamento e mesmo giro), escrevendo numa imagem.
func stamp(img: Image, rows: Array, legend: Dictionary, p: Vector2, anchor: Vector2i, ang: float) -> void:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var px := int(round(p.x))
	var py := int(round(p.y))
	var rad := maxi(w, h) + 2
	for y in range(py - rad, py + rad + 1):
		for x in range(px - rad, px + rad + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var s: Vector2 = P.rotv(Vector2(x - px, y - py), -ang)
			var i := int(round(s.x)) + anchor.x
			var j := int(round(s.y)) + anchor.y
			if j < 0 or j >= h or i < 0 or i >= w:
				continue
			var r: String = rows[j]
			if i >= r.length():
				continue
			var k := r[i]
			if k == "." or not legend.has(k):
				continue
			img.set_pixel(x, y, legend[k])

# ================================================================================================ capa (atrás do corpo)
## A capa da Ronda 1, presa na nuca e desenhada SÓ onde o corpo é vazio (fica atrás de tudo); na luta ela acompanha o
## tronco com atraso (o quadro anterior empurra a barra para trás) e, deitada, amontoa no chão.
## B5 (Diretor de Arte, 2026-11-26): ela tem de ler como LONA CINZA amarrada no pescoço, não como capa de herói:
##   - tom de lona (cinzas g0/g1/g2, bem mais claro que o capuz preto: dois materiais, não um traje de super-herói);
##   - caimento pesado e mais curto (até a virilha/alto da coxa; quase não ondula nem abre em bandeira no golpe);
##   - BARRA CORTADA TORTA: um corte reto inclinado com um dente de tesoura, no lugar da barra recortada pelas pregas
##     (que fazia as pontas de asa de morcego);
##   - ILHÓS de metal (g3 com anel g0) na beira de trás e no canto da barra;
##   - REMENDO de lona azul (b1) com pontos de costura claros.
const CAPE := ["g0", "g1", "g2"]
const CAPE_PATCH := "b1"
const CAPE_STITCH := "g3"
## Ilhós: (t = 0 na nuca .. 1 na barra, un = -1 beira de trás .. 1 beira da frente).
const GROMMETS := [[0.38, -0.62], [0.66, -0.62], [0.86, -0.5]]

func cape_point(A: Vector2, D: Vector2, Nn: Vector2, cp: Dictionary, t: float, un: float) -> Vector2:
	var ln: float = cp.len
	var ph: float = cp.get("phase", 0.0)
	var wave: float = cp.get("wave", 0.3)
	var w0: float = 3.0
	var w1: float = cp.get("w1", 7.5)
	var off := wave * sin(t * PI * 2.2 + ph) * t + float(cp.get("bulge", 1.2)) * sin(PI * pow(t, 0.6))
	var w := lerpf(w0, w1, pow(t, 0.8))
	return A + D * ln * t + Nn * (off + (w - w0) * 0.8) + Nn * un * w

## Comprimento da barra (em px a partir do fim) por posição na largura: corte reto e inclinado (mais curto na frente) com
## um dente de tesoura perto do meio. Sem nenhuma relação com as pregas: a barra não faz ondas nem pontas.
func cape_hem(un: float) -> float:
	var h := 1.0 + 2.6 * (un + 1.0) * 0.5
	if un > 0.05 and un < 0.3:
		h += 1.6
	return h

func cape_draw(img: Image, body: Image, ox: int, top: Vector2, hip: Vector2, cp: Dictionary) -> void:
	var dn := (top - hip).normalized()
	var fr := Vector2(-dn.y, dn.x)
	var A: Vector2 = top - fr * 3.5 - dn * 0.5 + Vector2(0.5, 0.5)
	var D: Vector2 = (cp.dir as Vector2).normalized()
	var ln: float = cp.len
	var ph: float = cp.get("phase", 0.0)
	var w0: float = 3.0
	var w1: float = cp.get("w1", 7.5)
	var gy: float = float(cp.gy) - 1.0
	var Nn := Vector2(-D.y, D.x)
	if Nn.x > 0.0 or (is_zero_approx(Nn.x) and Nn.y > 0.0):
		Nn = -Nn
	var steps := int(ln * 4.0)
	var done := {}
	for i in steps + 1:
		var t := float(i) / float(steps)
		var w := lerpf(w0, w1, pow(t, 0.8))
		var u := -w
		while u <= w:
			var un := u / w
			var p := cape_point(A, D, Nn, cp, t, un)
			u += 0.35
			if p.y > gy:
				p = Vector2(p.x - (p.y - gy) * 0.9, gy)
			var q := Vector2i(int(floor(p.x)), int(floor(p.y)))
			var key := q.x * 1000 + q.y
			if done.has(key):
				continue
			done[key] = true
			# lona: 2 pregas largas e duras (pano grosso não faz leque fino); crista g2, vale g0
			var c: String = CAPE[1]
			var pl := sin((un + 1.0) * PI * 1.0 + 0.25 * sin(t * 2.0 + ph) + 0.4)
			var fold_on := smoothstep(0.15, 0.4, t)
			if pl * fold_on > 0.7:
				c = CAPE[2]
			elif pl * fold_on < -0.6:
				c = CAPE[0]
			if un < -0.74:
				c = CAPE[0]
			var hem := cape_hem(un)
			var left := (1.0 - t) * ln
			if left < hem - 0.9:
				continue
			if left < hem + 0.2:
				c = CAPE[0]       # a beira cortada (pano grosso, 1 px de espessura)
			if t > 0.42 and t < 0.6 and un > 0.0 and un < 0.6:
				c = CAPE_PATCH    # remendo de lona azul
				var borda := absf(un - 0.0) < 0.12 or absf(un - 0.6) < 0.12 or absf(t - 0.42) * ln < 0.6 or absf(t - 0.6) * ln < 0.6
				if borda and (q.x + q.y) % 2 == 0:
					c = CAPE_STITCH
			var x := ox + q.x
			if q.x < 0 or q.x >= FW or q.y < 0 or q.y >= FH:
				continue
			if body.get_pixel(x, q.y).a > 0.0:
				continue
			img.set_pixel(x, q.y, L.col(c))
	# ilhós: anel escuro com o furo/aro claro no meio, só onde a capa aparece (atrás do corpo nada é desenhado)
	for g in GROMMETS:
		var p := cape_point(A, D, Nn, cp, float(g[0]), float(g[1]))
		if p.y > gy:
			continue
		var q := Vector2i(int(floor(p.x)), int(floor(p.y)))
		var x := ox + q.x
		if q.x < 1 or q.x >= FW - 1 or q.y < 1 or q.y >= FH - 1:
			continue
		var cape_c := [L.col(CAPE[0]), L.col(CAPE[1]), L.col(CAPE[2])]
		if not (img.get_pixel(x, q.y) in cape_c):
			continue
		img.set_pixel(x, q.y, L.col("g3"))
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var xx: int = x + d.x
			var yy: int = q.y + d.y
			if img.get_pixel(xx, yy) in cape_c:
				img.set_pixel(xx, yy, L.col("d2"))

## Parâmetros da capa de um quadro: cai para trás e para baixo; o tronco que andou desde o quadro anterior arrasta a capa
## para o lado oposto (atraso do pano). Deitado (tronco quase na horizontal), ela fica curta e amontoa no chão.
func cape_params(anc: Array, q: int, loop: bool, piv: Vector2) -> Dictionary:
	var a: Dictionary = anc[q]
	var top := v2(a.top)
	var hip := v2(a.hip)
	var prev := top
	if q > 0:
		prev = v2(anc[q - 1].top)
	elif loop:
		prev = v2(anc[anc.size() - 1].top)
	var vel := top - prev
	var dn := (top - hip).normalized()
	var lying := absf(dn.y) < 0.55
	# B5: lona pesada: cai mais reto, o golpe empurra a metade do que empurrava, quase não ondula, e é mais curta.
	var d := V(-0.22, 1.0) - V(vel.x * 0.05, vel.y * 0.02)
	d.x = clampf(d.x, -0.9, 0.1)
	var spd := clampf(vel.length() / 6.0, 0.0, 1.0)
	return {"dir": d, "len": 17.0 if lying else 24.0, "w1": 7.5, "wave": 0.25 + spd * 0.45, "phase": float(q) * 1.3,
		"bulge": 1.2 + spd * 0.5, "gy": piv.y}

# ================================================================================================ luva da noite
## Luva de pano escuro com o punho vermelho da faixa. Os pixels da luva são achados pela diferença entre a camada body da
## luva velha e as das luvas L1/L2/L3 (só a luva muda entre elas; contorno igual), então nada fora da luva é trocado.
const NIGHT_GLOVE := {"5a1a22": "d1", "9c2a2a": "d2", "d4473a": "g0", "f07a5a": "g1"}
const CUFF := {"d9cdb4": "r2", "b8b0aa": "r1", "8f8890": "r0", "f2ece0": "r3"}       # punho (vermelho da faixa)
const STITCH := {"d9cdb4": "g1", "b8b0aa": "g0", "8f8890": "d2", "f2ece0": "g1"}     # costura do polegar (no pano)

func night_glove(body: Image, others: Array) -> int:
	var w := body.get_width()
	var h := body.get_height()
	var mask := PackedByteArray()
	mask.resize(w * h)
	mask.fill(0)
	for y in h:
		for x in w:
			var c := body.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			for o in others:
				if (o as Image).get_pixel(x, y) != c:
					mask[y * w + x] = 1
					break
	var skin := {}
	for s in PAL.keys.skin.values():
		skin[(s as String).trim_prefix("#").to_lower()] = true
	# punho = pixels claros da luva ligados ao antebraço (pele) por outros pixels claros; o resto claro é costura
	var cuff := PackedByteArray()
	cuff.resize(w * h)
	cuff.fill(0)
	var fila := []
	for y in h:
		for x in w:
			var i := y * w + x
			if mask[i] == 0 or not CUFF.has(body.get_pixel(x, y).to_html(false)):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var xx: int = x + d.x
				var yy: int = y + d.y
				if xx >= 0 and yy >= 0 and xx < w and yy < h and skin.has(body.get_pixel(xx, yy).to_html(false)):
					cuff[i] = 1
					fila.append(Vector2i(x, y))
					break
	while not fila.is_empty():
		var p: Vector2i = fila.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var xx: int = p.x + d.x
			var yy: int = p.y + d.y
			if xx < 0 or yy < 0 or xx >= w or yy >= h:
				continue
			var j := yy * w + xx
			if mask[j] == 1 and cuff[j] == 0 and CUFF.has(body.get_pixel(xx, yy).to_html(false)):
				cuff[j] = 1
				fila.append(Vector2i(xx, yy))
	var n := 0
	for y in h:
		for x in w:
			var i := y * w + x
			if mask[i] == 0:
				continue
			var hx := body.get_pixel(x, y).to_html(false)
			var to := ""
			if NIGHT_GLOVE.has(hx):
				to = NIGHT_GLOVE[hx]
			elif CUFF.has(hx):
				to = CUFF[hx] if cuff[i] == 1 else STITCH[hx]
			if to != "":
				body.set_pixel(x, y, L.col(to))
				n += 1
	return n

# ================================================================================================ util
func v2(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func rel(res: String) -> String:
	return res.trim_prefix("res://assets/sprites/")

func load_res(res: String) -> Image:
	return P.load_png(REPO + res.trim_prefix("res://"))

func save_res(im: Image, res: String) -> void:
	var path := OUT + rel(res)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	im.save_png(path)

func outline_into(layer: Image, under: Image) -> void:
	## Contorno ink só onde a peça encosta no vazio (nem a peça nem o que está embaixo têm cor).
	var w := layer.get_width()
	var h := layer.get_height()
	var add := []
	for y in h:
		for x in w:
			if layer.get_pixel(x, y).a > 0.0 or under.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var xx: int = x + d.x
				var yy: int = y + d.y
				if xx >= 0 and yy >= 0 and xx < w and yy < h and layer.get_pixel(xx, yy).a > 0.0 and layer.get_pixel(xx, yy) != L.col("ink"):
					add.append(Vector2i(x, y))
					break
	for p in add:
		layer.set_pixel(p.x, p.y, L.col("ink"))

# ================================================================================================ VULTO: folhas
var VULTO := {}    # ação -> {"n", "body": Image, "heads": {corte: Image}, "src": entrada do discípulo}

func run_vulto() -> void:
	var acts: Dictionary = M.by_data_id.player_fight.actions
	var by_act := {}
	var tot_glove := 0
	for a in acts:
		var base_id: String = str(acts[a]) + "_disc_layered"
		var e: Dictionary = M.sprites[base_id]
		var lay: Dictionary = e.layers
		var n := int(e.frames)
		var piv := v2(e.pivot)
		var body := load_res(str(lay.body))
		var others := []
		for g in ["_glove_l1", "_glove_l2", "_glove_l3"]:
			var gid: String = str(acts[a]) + g + "_disc_layered"
			others.append(load_res(str(M.sprites[gid].layers.body)))
		tot_glove += night_glove(body, others)
		var anc: Array = e.anchors
		var loop := bool(e.get("loop", false))
		# capa atrás do corpo
		var cape: Image = L.blank(body.get_width(), body.get_height())
		for q in n:
			var a2: Dictionary = anc[q]
			cape_draw(cape, body, q * FW, piv + v2(a2.top), piv + v2(a2.hip), cape_params(anc, q, loop, piv))
		outline_into(cape, body)
		var vb: Image = cape.duplicate()
		vb.blend_rect(body, Rect2i(0, 0, body.get_width(), body.get_height()), Vector2i.ZERO)
		# capuz, um por corte
		var heads := {}
		var lg := hood_legend()
		for cut in CUTS:
			var hl: Image = L.blank(body.get_width(), body.get_height())
			for q in n:
				var a2: Dictionary = anc[q]
				stamp(hl, hood_rows(cut, str(a2.get("face", "normal"))), lg, V(q * FW, 0) + piv + v2(a2.head), HOOD_ANCHOR, float(a2.get("head_rot", 0.0)))
			outline_into(hl, vb)
			heads[cut] = hl
		VULTO[a] = {"n": n, "body": vb, "heads": heads, "src": e, "base": str(acts[a])}
		# arquivos e entrada
		var id: String = "fight_vulto_" + a
		var f_body := RES + "vulto/%s_disc_body.png" % id
		save_res(vb, f_body)
		var hd := {}
		for cut in CUTS:
			var f_h := RES + "vulto/%s_disc_head_%s.png" % [id, cut]
			save_res(heads[cut], f_h)
			hd[cut] = f_h
		var ent: Dictionary = e.duplicate(true)
		ent.erase("anchors")      # sem âncoras: o remendo do patrocinador (8a2) não entra no traje
		ent.erase("same_as")
		ent["file"] = f_body
		ent["who"] = "vulto"
		ent["layers"] = {"order": ["body", "top", "socks", "school_symbol", "head", "front_mask"], "body": f_body,
			"top": lay.top, "socks": lay.socks, "school_symbol": {"leg": lay.school_symbol.leg}, "head": hd,
			"front_mask": lay.front_mask}
		ent["note"] = ("Ronda 2a1: o VULTO lutando (traje do Gato Preto sobre %s). Mesmos quadros, fps, pivô, mãos e hit de %s. "
			+ "Montar como o discípulo (DiscVisual.textura com o look do discípulo da vez; layers.order): body (capa atrás + luva da "
			+ "noite) -> top -> socks -> school_symbol.leg (sem parte de cima) -> head.<hair_style> (o CAPUZ) -> front_mask. Sem band, "
			+ "sem chest, sem anchors (o remendo do patrocinador não entra). Nunca espelhar (o R da coxa). Sem _glove_lN.") % [base_id, base_id]
		ENT[id] = ent
		by_act[a] = id
	BY["vulto_fight"] = {"actions": by_act, "pos": [296, 318], "facing": "direita", "portrait": "portrait_vulto",
		"_nota": "Ronda 2a1 (Artista de Personagens): o vulto na luta da noite. Mesmas ações do player_fight (28, as 3 artes), em camadas pela disciple_palette, sem sufixo de luva. Detalhes: docs/arte/ronda2a-manifest.md."}
	report.append("vulto: %d ações, %d px de luva trocados" % [by_act.size(), tot_glove])
	portrait_vulto()

## Retrato 32x32 do HUD (o vulto de perfil, virado para a direita, fundo noite). É camada única com as cores-chave: o rosto
## não aparece (só o queixo, como na luta). Montado do quadro 0 do idle com o corte short, top none.
func portrait_vulto() -> void:
	var v: Dictionary = VULTO["idle"]
	var e: Dictionary = v.src
	var f := compose_frame("idle", 0, {"hair_style": "short", "top": "none", "socks": "none"}, {}, false)
	var piv := v2(e.pivot)
	var hd: Vector2 = piv + v2(e.anchors[0].head)
	var im: Image = L.blank(32, 32)
	im.fill(L.col("d1"))
	for y in 32:
		for x in 32:
			if (x + y) % 2 == 0 and y > 20:
				im.set_pixel(x, y, L.col("b0"))
	var ox := int(hd.x) - 17
	var oy := int(hd.y) - 13
	for y in 32:
		for x in 32:
			var sx := ox + x
			var sy := oy + y
			if sx >= 0 and sy >= 0 and sx < FW and sy < FH:
				var c := f.get_pixel(sx, sy)
				if c.a > 0.0:
					im.set_pixel(x, y, c)
	save_res(im, RES + "vulto/portrait_vulto.png")
	ENT["portrait_vulto"] = {"file": RES + "vulto/portrait_vulto.png", "frame_size": [32, 32], "frames": 1, "fps": 0.0,
		"pivot": [0, 0], "facing": "direita", "palette_swap": "disciple_palette",
		"note": "Ronda 2a1: retrato 32x32 do VULTO para o HUD da luta da noite (no lugar do retrato do discípulo; o nome é '???'). Capuz com a faixa vermelha, sem rosto. Tem as cores-chave da pele (queixo) e do cabelo (franja do short): trocar pela disciple_palette como as folhas (DiscVisual._trocar com o mapa do look), ou usar assim (pele e cabelo padrão)."}

## Monta um quadro como o DiscVisual (body -> top -> socks -> symbol.leg -> head -> front_mask) e troca as cores.
func compose_frame(a: String, q: int, look: Dictionary, cmap: Dictionary, symbol: bool) -> Image:
	var v: Dictionary = VULTO[a]
	var lay: Dictionary = v.src.layers
	var r := Rect2i(q * FW, 0, FW, FH)
	var base: Image = (v.body as Image).get_region(r)
	if str(look.get("top", "none")) != "none":
		var t := load_res(str(lay.top[look.top])).get_region(r)
		base.blend_rect(t, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if str(look.get("socks", "none")) != "none":
		var s := load_res(str(lay.socks)).get_region(r)
		base.blend_rect(s, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if symbol and str(look.get("top", "none")) == "none":
		var sy := load_res(str(lay.school_symbol.leg)).get_region(r)
		base.blend_rect(sy, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var out: Image = base.duplicate()
	out.blend_rect((v.heads[look.get("hair_style", "short")] as Image).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var mk := load_res(str(lay.front_mask)).get_region(r)
	for y in FH:
		for x in FW:
			var m := mk.get_pixel(x, y)
			if m.a > 0.5 and m.r > 0.5:
				var c := base.get_pixel(x, y)
				if c.a > 0.0:
					out.set_pixel(x, y, c)
	if not cmap.is_empty():
		recolor(out, cmap)
	return out

func recolor(im: Image, cmap: Dictionary) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var k := c.to_html(false)
			if cmap.has(k):
				im.set_pixel(x, y, cmap[k])

# ================================================================================================ paleta (estilos da noite)
## As 3 peças de estilo da Ronda 2a1 = 3 opções novas na by_data_id.disciple_palette.options (só cor; a arte é a que já existe).
## Cores da paleta de 45; ver docs/arte/ronda2a-manifest.md §estilos.
const NIGHT_OPTIONS := {
	"headband_color": {"id": "night", "ramp": {"light": "#e0a040", "dark": "#2a2233", "deep": "#14101a"}},
	"shorts_color": {"id": "night", "ramp": {"band": "#e0a040", "light": "#3d3346", "mid": "#2a2233", "dark": "#14101a", "deep": "#14101a"}},
	"socks": {"id": "night_wraps", "ramp": {"base": "#d9cdb4", "shadow": "#8f8890", "stripe": "#6b6570"}},
}

func opt_ramp(field: String, id: String) -> Dictionary:
	if NIGHT_OPTIONS.has(field) and NIGHT_OPTIONS[field].id == id:
		return NIGHT_OPTIONS[field].ramp
	for o in PAL.options.get(field, []):
		if str(o.id) == id:
			return o.ramp
	return {}

## {hex da chave: Color} para um look (como DiscVisual._mapa; o meião usa look.socks_color se houver, senão a cor do calção).
func keymap(look: Dictionary) -> Dictionary:
	var m := {}
	var fields := {"skin": look.skin, "hair_color": look.hair_color, "shorts_color": look.shorts_color,
		"top_color": look.get("top_color", "white"), "headband_color": look.get("headband_color", "red"),
		"socks": look.get("socks_color", look.shorts_color)}
	for f in fields:
		var ramp := opt_ramp(f, str(fields[f]))
		var ks: Dictionary = PAL.keys[f]
		for slot in ks:
			if ramp.has(slot):
				m[(ks[slot] as String).trim_prefix("#").to_lower()] = Color.html(ramp[slot])
	# R da coxa pela school_symbol_source.leg (calção night -> amarelo)
	var src: Dictionary = PAL.school_symbol_source.leg
	var sid: String = src.map.get(look.shorts_color, "yellow")
	var sr := opt_ramp("school_symbol", sid)
	for slot in PAL.keys.school_symbol:
		if sr.has(slot):
			m[(PAL.keys.school_symbol[slot] as String).trim_prefix("#").to_lower()] = Color.html(sr[slot])
	return m

# ================================================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	REPO = args[0].trim_suffix("/") + "/"
	OUT = args[1].trim_suffix("/") + "/"
	var modes: Array = args.slice(2) if args.size() > 2 else ["vulto", "beco", "prancha"]
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(REPO + "assets/sprites/manifest.json"))
	PAL = M.by_data_id.disciple_palette
	run_vulto()
	if "conf" in modes:
		conf_vulto()
	if "beco" in modes or "prancha" in modes or "antes_depois" in modes:
		run_beco()
	if "prancha" in modes:
		prancha()
	if "antes_depois" in modes:
		antes_depois()
	if "antes_depois_r1" in modes:
		antes_depois_r1()
	# estilos da noite: 3 opções novas na disciple_palette (o Programador acrescenta às listas que já existem)
	var pal_add := {"options": {}, "school_symbol_source": {"leg": {"map": {"night": "yellow"}}},
		"_nota": "Ronda 2a1 (Artista de Personagens): ACRESCENTAR estas opções às listas de by_data_id.disciple_palette.options (não substituir) e o par night -> yellow ao school_symbol_source.leg.map. A bandagem (socks night_wraps) usa as próprias cores: o DiscVisual tem de desenhar a camada socks também com look.socks == night_wraps e trocar as chaves do meião por options.socks[night_wraps] (hoje ele usa a entrada com o id do calção). docs/arte/ronda2a-manifest.md."}
	for fld in NIGHT_OPTIONS:
		pal_add.options[fld] = [{"id": NIGHT_OPTIONS[fld].id, "ramp": NIGHT_OPTIONS[fld].ramp}]
	var f := FileAccess.open(OUT + "ronda2a_vulto_beco.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"sprites": ENT, "by_data_id": BY, "disciple_palette_add": pal_add}, "\t"))
	f.close()
	for l in report:
		print(l)
	quit()

# ================================================================================================ conferência
const LOOKS := [
	{"id": "a", "skin": "skin_3", "hair_color": "brown", "hair_style": "short", "top": "none", "shorts_color": "green", "socks": "none", "symbol": true},
	{"id": "b", "skin": "skin_1", "hair_color": "copper", "hair_style": "volume", "top": "tank", "top_color": "yellow", "shorts_color": "purple", "socks": "none"},
	{"id": "c", "skin": "skin_5", "hair_color": "black", "hair_style": "bun", "top": "tee", "top_color": "white", "shorts_color": "night", "socks": "on", "socks_color": "night_wraps"},
]

func conf_vulto() -> void:
	DirAccess.make_dir_recursive_absolute(OUT + "conf")
	for look in LOOKS:
		var cm := keymap(look)
		var rows := []
		for a in VULTO:
			var n: int = VULTO[a].n
			var strip: Image = L.blank(FW * n, FH)
			strip.fill(L.col("st1"))
			for q in n:
				var fr := compose_frame(a, q, look, cm, bool(look.get("symbol", false)))
				strip.blend_rect(fr, Rect2i(0, 0, FW, FH), Vector2i(q * FW, 0))
			rows.append(strip)
		var wmax := 0
		for r in rows:
			wmax = maxi(wmax, (r as Image).get_width())
		var sheet: Image = L.blank(wmax, FH * rows.size())
		sheet.fill(L.col("st1"))
		for i in rows.size():
			sheet.blit_rect(rows[i], Rect2i(0, 0, (rows[i] as Image).get_width(), FH), Vector2i(0, i * FH))
		sheet.save_png(OUT + "conf/vulto_%s_x1.png" % look.id)

# ================================================================================================ BECO (arena_alley)
## Arena da briga da noite no contrato das outras (manifest fight_layout): 640x360, y 0..45 ink liso (HUD), pés em y 318,
## pivôs x 296/346, chão livre x 200..440, primeiro plano só nos cantos (x < 138 e > 502). Base: o beco dos mockups da
## Ronda 2a (make_mockup_ronda2a_*.gd, beco()), refeito em resolução cheia. Luz da arandela no alto do meio: a parede ATRÁS
## dos lutadores fica em MEIO-TOM (tijolo br1/br2) e escurece para as bordas, para o vulto escuro e os bandidos lerem.
## Camadas: arena_alley_bg (fundo), arena_alley_lamp (arandela: acesa, fraca, apagada = o poste piscando),
## arena_alley_crowd_back (GAROA atrás dos lutadores, 2 quadros, no lugar do público) e arena_alley_crowd_front (cantos:
## sacos de lixo, caixote e respingo na poça, 2 quadros).
const AW := 640
const AH := 360
const WALL_BASE := 262
const LAMP := Vector2(320, 104)
const BAY := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

func bay(x: int, y: int) -> float:
	return (float(BAY[y % 4][x % 4]) + 0.5) / 16.0

func hsh(a: int, b: int) -> float:
	var n := (a * 374761393 + b * 668265263) & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177 & 0x7fffffff
	return float(n % 1000) / 1000.0

## Passo de luz da arandela em (x,y): +1 perto, 0 meio-tom (atrás dos lutadores), -1/-2 nas bordas. Dither nas transições.
func light_step(x: int, y: int) -> int:
	var b := (bay(x, y) - 0.5) * 22.0
	if y < WALL_BASE:
		# parede: poça de luz em volta da arandela; atrás dos lutadores (y 180..262, x 240..400) fica no meio-tom (0)
		var d := Vector2(x - LAMP.x, (y - LAMP.y) * 0.8).length() + b
		if d < 72.0:
			return 1
		if d < 200.0:
			return 0
		if d < 300.0:
			return -1
		return -2
	# chão: a luz cai numa elipse achatada em volta dos pés (y 318)
	var df := Vector2(x - LAMP.x, (y - 316.0) * 3.2).length() + b
	if df < 165.0:
		return 0
	if df < 270.0:
		return -1
	return -2

func put_l(im: Image, x: int, y: int, c: String, lit := true, minstep := -2) -> void:
	if x < 0 or y < 0 or x >= AW or y >= AH:
		return
	var col: Color = L.col(c)
	if lit:
		var st := maxi(light_step(x, y), minstep)
		var sc: Color = L.shade(col, st)
		while sc == L.col("ink") and c != "ink" and st < 0:   # a sombra nunca vira contorno
			st += 1
			sc = L.shade(col, st)
		col = sc
	im.set_pixel(x, y, col)

func rect_l(im: Image, x: int, y: int, w: int, h: int, c: String, minstep := -2) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			put_l(im, xx, yy, c, true, minstep)

func ell_l(im: Image, cx: float, cy: float, rx: float, ry: float, c: String, minstep := -2) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if Vector2((x - cx) / rx, (y - cy) / ry).length() <= 1.0:
				put_l(im, x, y, c, true, minstep)

var BECO: Dictionary = {}

func run_beco() -> void:
	var bg := beco_bg()
	save_res(bg, RES + "arena/arena_alley_bg.png")
	var lamp := beco_lamp()
	save_res(lamp, RES + "arena/arena_alley_lamp.png")
	var rain := beco_rain()
	save_res(rain, RES + "arena/arena_alley_crowd_back.png")
	var front := beco_front()
	save_res(front, RES + "arena/arena_alley_crowd_front.png")
	BECO = {"bg": bg, "lamp": lamp, "rain": rain, "front": front}
	ENT["arena_alley_bg"] = {"file": RES + "arena/arena_alley_bg.png", "frame_size": [AW, AH], "frames": 1, "fps": 0.0,
		"pivot": [0, 0], "pos": [0, 0], "layer": "fundo", "z": -100,
		"note": "Ronda 2a1: arena do BECO à noite (briga da noite, data/ronda.json kind alley_fight). Tijolo sob a luz da arandela (meio-tom atrás dos lutadores, escurece para as bordas), prédio de reboco descascado com porta de ferro à esquerda, cano, janela gradeada com ar-condicionado pingando, pichação VILA, cartaz rasgado, fios, caixas e pneu à esquerda, caçamba verde 07 e sacos de lixo à direita, asfalto molhado com sarjeta e poças refletindo a luz, garoa. Mesmo contrato das outras arenas: y 0..45 ink liso (HUD), pés em y 318, pivôs 296/346, chão livre x 200..440. Luz já aplicada. Sem sangue, sem texto que diga quem é o vulto. Gerador: tools/art/make_sprites_ronda2a.gd (beco)."}
	ENT["arena_alley_lamp"] = {"file": RES + "arena/arena_alley_lamp.png", "frame_size": [40, 40], "frames": 3, "fps": 0.0,
		"pivot": [20, 0], "pos": [320, 84], "layer": "frente_do_fundo", "z": -50,
		"anim": {"idle": [0], "flicker": [2, 0], "swing": [1, 0, 1, 0]},
		"frames_note": "0 acesa, 1 fraca (falha), 2 apagada. 'swing' aqui = a arandela falhando (1,0,1,0): não balança, pisca.",
		"note": "Ronda 2a1: arandela de parede do beco (o 'poste piscando'). Braço de ferro e cúpula de esmalte verde; a luz da parede e do chão já está no fundo. Tocar flicker de vez em quando e swing no golpe forte/K.O., como o refletor da borracharia."}
	ENT["arena_alley_crowd_back"] = {"file": RES + "arena/arena_alley_crowd_back.png", "frame_size": [AW, 314], "frames": 2, "fps": 4.0,
		"pivot": [0, 0], "pos": [0, 46], "layer": "fundo", "z": -60, "loop": true, "anim": {"idle": [0], "cheer": [1, 0, 1, 0]},
		"note": "Ronda 2a1: no beco não tem público; esta camada é a GAROA atrás dos lutadores (traços finos, mais claros perto da arandela, respingos no chão), 2 quadros alternando. Quadro maior que o das outras arenas (640x314 em (0,46)): a tela usa frame_size e pos do manifest. Não cobre o HUD (começa em y 46)."}
	ENT["arena_alley_crowd_front"] = {"file": RES + "arena/arena_alley_crowd_front.png", "frame_size": [AW, 48], "frames": 2, "fps": 4.0,
		"pivot": [0, 0], "pos": [0, 312], "layer": "frente", "z": 50, "loop": true, "anim": {"idle": [0], "cheer": [1, 0, 1, 0]},
		"note": "Ronda 2a1: primeiro plano do beco só nos cantos (x 0..137 e 503..640; nada em x 138..502): sacos de lixo e lata à esquerda, poça com respingo de chuva e caixote à direita. 2 quadros (o respingo muda)."}
	BY["arena_alley"] = {"_nota": "Ronda 2a1: prefixo de arena da briga da noite ('arena_alley': _bg, _lamp, _crowd_back = garoa, _crowd_front). A tela da noite pede a arena pelo kind (alley_fight -> arena_alley). Mesmo fight_layout das outras.",
		"lugar": "beco à noite (briga da noite)", "lamp": true}
	var bad := 0
	for y in 46:
		for x in AW:
			if bg.get_pixel(x, y) != L.col("ink"):
				bad += 1
	var bad_f := 0
	for f in 2:
		for y in 48:
			for x in range(138, 503):
				if front.get_pixel(f * AW + x, y).a > 0.0:
					bad_f += 1
	report.append("beco: %d px fora do ink na faixa do HUD; %d px do primeiro plano no meio (x 138..502)" % [bad, bad_f])

func beco_bg() -> Image:
	var im: Image = L.blank(AW, AH)
	im.fill(L.col("ink"))
	# --- céu na fresta e prédios ao longe (sem a luz da arandela)
	for y in range(46, 90):
		for x in AW:
			var c := "b0"
			if y < 58 and bay(x, y) > float(y - 46) / 12.0:
				c = "d1"
			im.set_pixel(x, y, L.col(c))
	for st in [V(212, 52), V(268, 57), V(371, 50), V(455, 55), V(402, 62), V(236, 63)]:
		im.set_pixel(int(st.x), int(st.y), L.col("st2"))
	var far := [[150, 72, 40], [190, 64, 34], [224, 70, 46], [270, 60, 30], [300, 68, 50], [350, 63, 38], [388, 71, 44], [432, 66, 40], [472, 70, 60], [532, 62, 108]]
	for b in far:
		L.R(im, b[0], b[1], b[2], 90 - b[1], "d1")
		for wy in range(b[1] + 3, 86, 5):
			for wx in range(b[0] + 3, b[0] + b[2] - 3, 6):
				if hsh(wx, wy) > 0.8:
					L.R(im, wx, wy, 2, 2, "y0" if hsh(wy, wx) > 0.5 else "br3")
	L.R(im, 402, 56, 14, 8, "d1")
	L.R(im, 404, 64, 2, 6, "d1")
	L.R(im, 412, 64, 2, 6, "d1")
	# --- prédio da esquerda (reboco), do beiral até a calçada
	for y in range(50, WALL_BASE):
		for x in range(0, 150):
			var c := "g1"
			if (x + y * 3) % 23 == 0 and hsh(x, y) > 0.5:
				c = "g0"
			put_l(im, x, y, c)
	for sp in [Rect2i(16, 72, 30, 18), Rect2i(110, 150, 26, 22), Rect2i(6, 200, 22, 16)]:
		for y in range(sp.position.y, sp.end.y):
			for x in range(sp.position.x, sp.end.x):
				var e: float = Vector2((x - sp.get_center().x) / (sp.size.x * 0.5), (y - sp.get_center().y) / (sp.size.y * 0.5)).length()
				if e < 1.0 - 0.25 * bay(x, y):
					var mort := (y % 6 == 5) or ((x + (y / 6 % 2) * 8) % 16 == 0)
					put_l(im, x, y, "br0" if mort else "br1")
				elif e < 1.12:
					put_l(im, x, y, "g0")
	rect_l(im, 0, 50, 150, 3, "g2")
	rect_l(im, 0, 53, 150, 1, "d2")
	# janela alta gradeada + ar-condicionado pingando
	rect_l(im, 56, 84, 48, 38, "d2")
	rect_l(im, 58, 86, 44, 34, "d1")
	rect_l(im, 60, 88, 40, 14, "b0")
	for bx in range(60, 100, 6):
		rect_l(im, bx, 86, 1, 34, "st1")
	rect_l(im, 56, 122, 48, 2, "g2")
	rect_l(im, 108, 128, 32, 18, "g2")
	rect_l(im, 108, 128, 32, 1, "g3")
	for gx in range(110, 138, 3):
		rect_l(im, gx, 131, 1, 12, "g1")
	rect_l(im, 120, 146, 1, 6, "b1")
	put_l(im, 120, 156, "b2")
	# porta de ferro com degrau
	rect_l(im, 44, 164, 62, 98, "st0")
	rect_l(im, 46, 166, 58, 96, "st1")
	for k in 6:
		rect_l(im, 48, 170 + k * 15, 54, 1, "st0")
		rect_l(im, 48, 171 + k * 15, 54, 1, "st2")
	rect_l(im, 94, 214, 4, 3, "st3")
	rect_l(im, 40, 160, 70, 4, "d2")
	rect_l(im, 40, 258, 72, 4, "g2")
	rect_l(im, 40, 258, 72, 1, "g3")
	# cano de descida
	rect_l(im, 150, 54, 5, WALL_BASE - 54, "st1")
	rect_l(im, 150, 54, 1, WALL_BASE - 54, "st0")
	rect_l(im, 153, 54, 1, WALL_BASE - 54, "st2")
	for cy in [90, 150, 210]:
		rect_l(im, 149, cy, 7, 2, "st0")
	# --- muro de tijolo do beco (o fundo atrás dos lutadores, meio-tom). A luz é decidida POR TIJOLO (centro do tijolo +
	# sorteio do tijolo na borda da faixa), não por pixel: o degradê sai em tijolos inteiros, sem chuvisco de dither.
	var BR := {1: ["br2", "br3", "br1", "br1"], 0: ["br1", "br2", "br0", "br0"], -1: ["br0", "br1", "d2", "d1"], -2: ["d2", "br0", "d1", "d1"]}
	for y in range(80, WALL_BASE):
		for x in range(155, AW):
			var row := (y - 80) / 6
			var off := (row % 2) * 8
			var bxi := (x + off) / 16
			var cx := bxi * 16 - off + 8
			var cy := 80 + row * 6 + 2
			var d := Vector2(cx - LAMP.x, (cy - LAMP.y) * 0.8).length() + (hsh(bxi, row) - 0.5) * 22.0
			var lvl := 1 if d < 72.0 else (0 if d < 200.0 else (-1 if d < 300.0 else -2))
			var pal: Array = BR[lvl]
			var mortar := (y - 80) % 6 == 5 or (x + off) % 16 == 0
			var c: String = pal[2]
			if not mortar:
				var tt := hsh(row, bxi)
				c = pal[0] if tt < 0.88 else pal[3]
				if (y - 80) % 6 == 0 and lvl >= 0 and tt < 0.88:
					c = pal[1]
			im.set_pixel(x, y, L.col(c))
	rect_l(im, 155, 78, AW - 155, 3, "g1")
	rect_l(im, 155, 81, AW - 155, 1, "d2")
	for sx in [190, 236, 333, 391, 452, 588]:
		var ln := 18 + int(hsh(sx, 7) * 40)
		for y in range(82, 82 + ln):
			if bay(sx, y) < 0.6 - float(y - 82) / float(ln) * 0.6:
				put_l(im, sx, y, "d2")
				put_l(im, sx + 1, y, "d2")
	# janela gradeada no tijolo
	rect_l(im, 196, 104, 50, 42, "g0")
	rect_l(im, 198, 106, 46, 38, "d1")
	rect_l(im, 200, 108, 42, 18, "b0")
	rect_l(im, 200, 108, 10, 34, "p0")
	for bx in range(199, 245, 5):
		rect_l(im, bx, 106, 1, 38, "st0")
	rect_l(im, 194, 146, 54, 3, "g1")
	# cartaz rasgado
	rect_l(im, 270, 150, 30, 38, "cream")
	rect_l(im, 270, 150, 30, 8, "r1")
	for ly in [162, 167, 172]:
		rect_l(im, 274, ly, 20 - (ly - 162), 2, "g2")
	for y in range(176, 188):
		for x in range(270, 300):
			if hsh(x, y) > 0.55 + float(188 - y) * 0.03:
				put_l(im, x, y, "br1")
	# pichação VILA (com escorrido) e o gatinho de spray (a marca da Ronda; não diz quem é)
	var gi: Image = L.blank(AW, AH)
	L.text(gi, "VILA", 448, 138, "r1", 3)
	for y in range(130, 170):
		for x in range(440, 540):
			if gi.get_pixel(x, y).a > 0.0:
				put_l(im, x + 1, y + 1, "r0", true, 0)
				put_l(im, x, y, "r2", true, 0)
				if hsh(x, y) > 0.93:
					for k in range(1, 4 + int(hsh(y, x) * 6)):
						put_l(im, x, y + k + 1, "r0")
	for x in range(444, 521):
		put_l(im, x, 162 - int(float(x - 444) * 4.0 / 76.0), "r0")
	var cat := ["#.....#", "##...##", "#######", "#.###.#", "#######", ".#####."]
	for j in cat.size():
		for i in (cat[j] as String).length():
			if cat[j][i] == "#":
				put_l(im, 172 + i, 228 + j, "d1")
			elif j == 3:
				put_l(im, 172 + i, 228 + j, "y0")
	# fios
	for w in [[V(0, 70), V(640, 64), 18.0], [V(0, 84), V(640, 92), 12.0], [V(150, 60), V(640, 100), 10.0]]:
		var a: Vector2 = w[0]
		var b2: Vector2 = w[1]
		for x in range(int(a.x), int(b2.x)):
			var t := (float(x) - a.x) / (b2.x - a.x)
			var y: float = a.y + (b2.y - a.y) * t + float(w[2]) * 4.0 * t * (1.0 - t)
			im.set_pixel(x, int(y), L.col("ink"))
	# --- rodapé de concreto
	for y in range(WALL_BASE - 10, WALL_BASE):
		for x in range(155, AW):
			put_l(im, x, y, "g1" if y > WALL_BASE - 9 else "g2")
			if y > WALL_BASE - 5 and bay(x, y) > 0.55:
				put_l(im, x, y, "g0")
	# --- chão: asfalto molhado
	for y in range(WALL_BASE, AH):
		for x in AW:
			var c := "g0"
			if hsh(x / 3, y / 2) > 0.86:
				c = "d2"
			put_l(im, x, y, c)
	for y in range(WALL_BASE, WALL_BASE + 6):
		for x in AW:
			put_l(im, x, y, "b0" if y > WALL_BASE + 1 else "d2", true, -1)
	rect_l(im, 0, WALL_BASE + 6, AW, 1, "d2")
	for y in range(WALL_BASE + 2, WALL_BASE + 6):
		for x in range(312, 329):
			if bay(x, y) > 0.35:
				im.set_pixel(x, y, L.col("y1" if absf(x - 320.0) < 3 else "br3"))
	var pocas := [[V(248, 334), 46.0, 6.0], [V(424, 344), 40.0, 5.0], [V(86, 300), 32.0, 4.0], [V(566, 294), 28.0, 4.0], [V(330, 292), 22.0, 3.0]]
	for pz in pocas:
		var c0: Vector2 = pz[0]
		for y in range(int(c0.y - pz[2]), int(c0.y + pz[2]) + 1):
			for x in range(int(c0.x - pz[1]), int(c0.x + pz[1]) + 1):
				var e: float = Vector2((x - c0.x) / pz[1], (y - c0.y) / pz[2]).length()
				if e <= 1.0:
					put_l(im, x, y, "b1" if e < 0.75 and (x + y) % 3 != 0 else "b0", true, -1)
		var rx := int(c0.x + (LAMP.x - c0.x) * 0.15)
		for k in range(-2, 3):
			var yy := int(c0.y) - 1 + (k % 2)
			if light_step(rx + k, yy) >= 0:
				im.set_pixel(rx + k, yy, L.col("y1" if absi(k) < 2 else "br3"))
	rect_l(im, 132, 340, 28, 8, "d1")
	for k in 6:
		rect_l(im, 134 + k * 4, 341, 2, 6, "g0")
	# --- caixas e pneu à esquerda
	rect_l(im, 108, 230, 34, 34, "br2")
	rect_l(im, 108, 230, 34, 2, "br3")
	rect_l(im, 108, 230, 1, 34, "br1")
	rect_l(im, 123, 230, 3, 34, "y0")
	rect_l(im, 114, 210, 26, 20, "br3")
	rect_l(im, 114, 210, 26, 1, "y0")
	rect_l(im, 114, 210, 1, 20, "br2")
	rect_l(im, 125, 214, 8, 1, "br1")
	ell_l(im, 172, 250, 14, 15, "d1")
	ell_l(im, 172, 250, 11, 12, "d2")
	ell_l(im, 172, 250, 6, 7, "g0")
	ell_l(im, 172, 250, 4, 5, "d1")
	for a in 8:
		var an := float(a) / 8.0 * TAU
		put_l(im, int(172 + cos(an) * 12.5), int(250 + sin(an) * 13.5), "g0")
	# --- caçamba verde à direita, sacos de lixo
	var dx := 476
	var dy := 196
	rect_l(im, dx, dy, 136, 70, "gr0")
	rect_l(im, dx + 2, dy + 2, 132, 66, "gr1")
	for k in 5:
		rect_l(im, dx + 12 + k * 26, dy + 4, 3, 62, "gr0")
		rect_l(im, dx + 15 + k * 26, dy + 4, 1, 62, "gr2")
	rect_l(im, dx - 6, dy - 10, 148, 10, "gr0")
	rect_l(im, dx - 5, dy - 9, 146, 4, "gr2")
	rect_l(im, dx - 5, dy - 5, 146, 1, "gr3")
	var t07: Image = L.blank(AW, AH)
	L.text(t07, "07", dx + 56, dy + 24, "cream", 2)
	for y in range(dy, dy + 70):
		for x in range(dx, dx + 136):
			if t07.get_pixel(x, y).a > 0.0 and bay(x, y) > 0.2:
				put_l(im, x, y, "g3")
	for k in 7:
		var rx := dx + 6 + int(hsh(k, 3) * 120)
		for y in range(dy + 8, dy + 8 + 6 + int(hsh(3, k) * 18)):
			if bay(rx, y) > 0.4:
				put_l(im, rx, y, "br1")
	for wx in [dx + 10, dx + 118]:
		ell_l(im, wx, dy + 70, 5, 4, "ink")
		ell_l(im, wx, dy + 70, 2, 2, "g0")
	for sb in [[V(452, 252), 16.0, 12.0], [V(468, 242), 12.0, 10.0], [V(500, 186), 14.0, 8.0], [V(530, 184), 10.0, 7.0]]:
		var c0: Vector2 = sb[0]
		ell_l(im, c0.x, c0.y, sb[1] + 1.0, sb[2] + 1.0, "ink")
		ell_l(im, c0.x, c0.y, sb[1], sb[2], "d2")
		ell_l(im, c0.x - sb[1] * 0.3, c0.y - sb[2] * 0.35, sb[1] * 0.45, sb[2] * 0.35, "g0")
		put_l(im, int(c0.x - sb[1] * 0.4), int(c0.y - sb[2] * 0.5), "g1")
	# --- garoa parada no fundo (a que se mexe é a crowd_back)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2041
	for i in 260:
		var x := rng.randi_range(0, AW)
		var y := rng.randi_range(48, AH - 4)
		var c := "st1" if light_step(clampi(x, 0, AW - 1), y) < 0 else "st2"
		for k in 3:
			var px: int = x - k / 2
			var py: int = y + k
			if px >= 0 and px < AW and py < AH:
				im.set_pixel(px, py, L.col(c))
	L.R(im, 0, 0, AW, 46, "ink")
	return im

func beco_lamp() -> Image:
	var im: Image = L.blank(120, 40)
	for f in 3:
		var o := f * 40
		L.R(im, o + 4, 2, 3, 8, "st0")
		L.R(im, o + 6, 4, 14, 2, "st1")
		L.R(im, o + 6, 6, 14, 1, "st0")
		L.R(im, o + 18, 4, 3, 6, "st1")
		L.R(im, o + 14, 10, 13, 2, "gr1")
		L.R(im, o + 12, 12, 17, 2, "gr2")
		L.R(im, o + 10, 14, 21, 2, "gr1")
		L.R(im, o + 10, 16, 21, 1, "gr0")
		L.R(im, o + 15, 10, 4, 1, "gr3")
		var bulb: String = ["y2", "y1", "g1"][f]
		L.R(im, o + 17, 17, 7, 3, bulb)
		L.R(im, o + 18, 20, 5, 1, bulb if f < 2 else "g0")
		if f == 0:
			L.R(im, o + 19, 17, 3, 2, "white")
	var out: Image = L.blank(120, 40)
	for f in 3:
		var fr: Image = im.get_region(Rect2i(f * 40, 0, 40, 40))
		var ol: Image = L.outlined(fr)
		out.blend_rect(ol.get_region(Rect2i(1, 1, 40, 40)), Rect2i(0, 0, 40, 40), Vector2i(f * 40, 0))
	# brilho em dither abaixo da cúpula, sem contorno (acesa forte, fraca mais curta, apagada nada)
	for f in 2:
		var o := f * 40
		var rr := 11.0 if f == 0 else 6.0
		for y in range(22, 36):
			for x in range(o + 6, o + 35):
				var d := Vector2(x - (o + 20), (y - 20) * 1.5).length()
				if d < rr and bay(x, y) > d / rr + 0.2 and out.get_pixel(x, y).a == 0.0:
					out.set_pixel(x, y, L.col("y1" if f == 0 else "br3"))
	return out

func beco_rain() -> Image:
	var h := 314
	var im: Image = L.blank(AW * 2, h)
	for f in 2:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + f * 13
		for i in 230:
			var x := rng.randi_range(0, AW + 10)
			var y := rng.randi_range(0, h - 6)
			var c := "st1" if light_step(clampi(x, 0, AW - 1), clampi(y + 46, 0, AH - 1)) < 0 else "st2"
			var ln := 3 if rng.randf() < 0.7 else 4
			for k in ln:
				var px: int = x - k / 2
				if px >= 0 and px < AW and y + k < h:
					im.set_pixel(f * AW + px, y + k, L.col(c))
		for i in 26:
			var x := rng.randi_range(4, AW - 4)
			var y := rng.randi_range(222, h - 4)
			im.set_pixel(f * AW + x - 1, y, L.col("st2"))
			im.set_pixel(f * AW + x + 1, y, L.col("st2"))
			im.set_pixel(f * AW + x, y - 1, L.col("st3"))
	return im

func beco_front() -> Image:
	var im: Image = L.blank(AW * 2, 48)
	for f in 2:
		var o := f * AW
		for sb in [[V(30, 34), 22.0, 15.0], [V(64, 38), 17.0, 11.0], [V(10, 40), 14.0, 10.0]]:
			var c0: Vector2 = sb[0]
			for y in 48:
				for x in range(0, 136):
					var e: float = Vector2((x - c0.x) / sb[1], (y - c0.y) / sb[2]).length()
					if e <= 1.0:
						var c := "d1"
						if e < 0.86:
							c = "d2" if (x - c0.x) > -sb[1] * 0.2 else "d1"
						if e < 0.5 and x < c0.x and y < c0.y:
							c = "g0"
						im.set_pixel(o + x, y, L.col(c))
		for y in range(26, 31):
			for x in range(36, 40):
				im.set_pixel(o + x, y, L.col("r1" if y < 28 else "g2"))
		im.set_pixel(o + 41, 16, L.col("g2"))
		for y in range(14, 48):
			for x in range(556, 612):
				var c := "br1"
				if (y - 14) % 9 < 2:
					c = "br0"
				elif x % 14 == 0:
					c = "br0"
				elif (y - 14) % 9 == 2:
					c = "br2"
				im.set_pixel(o + x, y, L.col(c))
		for y in range(38, 46):
			for x in range(508, 552):
				var e: float = Vector2((x - 530.0) / 22.0, (y - 42.0) / 4.0).length()
				if e <= 1.0:
					im.set_pixel(o + x, y, L.col("b1" if e < 0.7 else "b0"))
		var sp: Array = [[526, 40], [534, 39]] if f == 0 else [[522, 39], [538, 41]]
		for s in sp:
			im.set_pixel(o + s[0], s[1] - 1, L.col("st3"))
			im.set_pixel(o + s[0] - 1, s[1], L.col("st2"))
			im.set_pixel(o + s[0] + 1, s[1], L.col("st2"))
	var out: Image = L.blank(AW * 2, 48)
	for f in 2:
		var fr: Image = im.get_region(Rect2i(f * AW, 0, AW, 48))
		var ol: Image = L.outlined(fr)
		out.blend_rect(ol.get_region(Rect2i(1, 1, AW, 48)), Rect2i(0, 0, AW, 48), Vector2i(f * AW, 0))
	return out

# ================================================================================================ PRANCHA de amostra
## docs/arte/mockups/ronda2a_amostra_luta.png: o vulto lutando em 3 discípulos x 3 artes (com o antes), as 28 ações em 1x,
## os 3 bandidos, o beco com a luta montada (1x e 2x) e os estilos da noite.
func cell_bg(w: int, h: int) -> Image:
	var im: Image = L.blank(w, h)
	im.fill(L.col("b0"))
	return im

## O discípulo de sempre (sem o traje), montado pelas camadas dele (com faixa), para o "antes" e para os estilos.
func compose_disc(base_id: String, q: int, look: Dictionary) -> Image:
	var e: Dictionary = M.sprites[base_id]
	var lay: Dictionary = e.layers
	var r := Rect2i(q * FW, 0, FW, FH)
	var base: Image = load_res(str(lay.body)).get_region(r)
	if str(look.get("top", "none")) != "none":
		base.blend_rect(load_res(str(lay.top[look.top])).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if str(look.get("socks", "none")) != "none":
		base.blend_rect(load_res(str(lay.socks)).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if bool(look.get("symbol", false)) and str(look.get("top", "none")) == "none":
		base.blend_rect(load_res(str(lay.school_symbol.leg)).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var out: Image = base.duplicate()
	out.blend_rect(load_res(str(lay.head[look.get("hair_style", "short")])).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if str(look.get("headband", "none")) != "none":
		out.blend_rect(load_res(str(lay.band)).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var mk := load_res(str(lay.front_mask)).get_region(r)
	for y in FH:
		for x in FW:
			var m := mk.get_pixel(x, y)
			if m.a > 0.5 and m.r > 0.5 and base.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, base.get_pixel(x, y))
	recolor(out, keymap(look))
	return out

func opp_frame(oid: String, act: String, q: int) -> Image:
	var im: Image = P.load_png(OUT + "opponents/%s/%s_%s.png" % [oid, oid, act])
	var n := im.get_width() / FW
	return im.get_region(Rect2i(clampi(q, 0, n - 1) * FW, 0, FW, FH))

const SAMPLE_LOOKS := [
	{"nome": "A: PADRÃO (PELE 3, CURTO, SEM CAMISA, CALÇÃO VERDE, R NA COXA)", "skin": "skin_3", "hair_color": "brown", "hair_style": "short", "top": "none", "shorts_color": "green", "socks": "none", "symbol": true, "headband": "on", "headband_color": "red"},
	{"nome": "B: PELE 1, VOLUME RUIVO, REGATA AMARELA, CALÇÃO ROXO", "skin": "skin_1", "hair_color": "copper", "hair_style": "volume", "top": "tank", "top_color": "yellow", "shorts_color": "purple", "socks": "none", "headband": "on", "headband_color": "blue"},
	{"nome": "C: PELE 5, COQUE, CAMISETA BRANCA, COM OS ESTILOS DA NOITE (CALÇÃO ESCURO E BANDAGEM)", "skin": "skin_5", "hair_color": "black", "hair_style": "bun", "top": "tee", "top_color": "white", "shorts_color": "night", "socks": "on", "socks_color": "night_wraps", "headband": "on", "headband_color": "night"},
]
## [ação, quadro, rótulo] por arte.
const SAMPLE_POSES := [["idle", 0, "GUARDA"], ["jab", 1, "JAB"], ["hook", 4, "GANCHO"],
	["clinch_push", 3, "CLINCH"], ["takedown", 5, "QUEDA"], ["submission", 6, "FINALIZA"],
	["mt_idle", 0, "GUARDA"], ["low_kick", 4, "CHUTE BAIXO"], ["spin_kick", 5, "GIRATÓRIO"]]
const CROP := Rect2i(8, 4, 96, 100)

func prancha() -> void:
	var K := 2
	var cw := CROP.size.x * K
	var ch := CROP.size.y * K
	var gap := 8
	var W := 20 + (cw + gap) * 10 + 12
	var H := 5000
	var im: Image = L.blank(W, H)
	im.fill(L.col("d1"))
	var y := 16
	L.text(im, "RONDA 2A1 - AMOSTRA DA LUTA NO BECO: O VULTO, OS 3 BANDIDOS E O BECO", 20, y, "y1", 3)
	y += 30
	L.text(im, "ARTE GERADA POR CÓDIGO NO PADRÃO DAS FOLHAS DE LUTA (112X104, PIVÔ 56,98). O TRAJE É CAMADA SOBRE A FOLHA DO DISCÍPULO: VESTE QUALQUER LOOK, NAS 28 AÇÕES.", 20, y, "g3")
	y += 22
	# --- 1. vulto
	L.text(im, "1. O VULTO LUTANDO: 3 DISCÍPULOS X 3 ARTES (2X). À ESQUERDA, O MESMO DISCÍPULO SEM O TRAJE (ANTES).", 20, y, "y1", 2)
	y += 24
	for look in SAMPLE_LOOKS:
		L.text(im, str(look.nome), 20, y, "cream")
		y += 12
		var x := 20
		var lbl := ["ANTES"]
		var frames := [compose_disc("fight_player_idle_disc_layered", 0, look)]
		var cm := keymap(look)
		for ps in SAMPLE_POSES:
			frames.append(compose_frame(ps[0], int(ps[1]), look, cm, bool(look.get("symbol", false))))
			lbl.append(ps[2])
		for i in frames.size():
			var c: Image = cell_bg(cw, ch)
			if i == 0:
				c.fill(L.col("d2"))
			var fr: Image = (frames[i] as Image).get_region(CROP)
			c.blend_rect(P.scaled(fr, K), Rect2i(0, 0, cw, ch), Vector2i.ZERO)
			im.blit_rect(c, Rect2i(0, 0, cw, ch), Vector2i(x, y))
			L.text(im, lbl[i], x + 4, y + 4, "y1" if i > 0 else "g3")
			if i in [1, 4, 7]:
				L.text(im, {1: "BOXE", 4: "JIU-JITSU", 7: "MUAY THAI"}[i], x + 4, y + ch - 12, "r3")
			x += cw + gap
		y += ch + 14
	# --- 1b. 1x de todas as ações do vulto (look A)
	L.text(im, "1B. AS 28 AÇÕES DO VULTO EM 1X (LOOK A): O TRAJE VESTE AS 3 ARTES INTEIRAS (CAPA ATRÁS DO CORPO, CAPUZ NO GIRO DA CABEÇA)", 20, y, "y1", 2)
	y += 24
	var xx := 20
	var lookA: Dictionary = SAMPLE_LOOKS[0]
	var cmA := keymap(lookA)
	var row_h := FH + 6
	for a in VULTO:
		var n: int = VULTO[a].n
		var cwid := 64
		if xx + n * cwid > W - 12:
			xx = 20
			y += row_h
		var bgc: Image = cell_bg(n * cwid, FH)
		im.blit_rect(bgc, Rect2i(0, 0, bgc.get_width(), FH), Vector2i(xx, y))
		for q in n:
			var fr := compose_frame(a, q, lookA, cmA, true)
			im.blend_rect(fr.get_region(Rect2i(24, 0, cwid, FH)), Rect2i(0, 0, cwid, FH), Vector2i(xx + q * cwid, y))
		L.text(im, str(a).to_upper(), xx + 2, y + 2, "y1")
		xx += n * cwid + 8
	y += row_h + 12
	# --- 2. bandidos
	L.text(im, "2. OS 3 BANDIDOS NO RIG DE LUTA DOS ADVERSÁRIOS (2X): GUARDA, JAB, DIRETO, LEVA, PASSIVA, FUGA TONTA, APAGOU", 20, y, "y1", 2)
	y += 24
	var bands := [["opp_alley_tire", "ZECA ESTEPE (FORTE): BAIXINHO E LARGO. PASSIVA BASE LARGA: NÃO CAI (PÉS PLANTADOS)", "plant_feet", 4],
		["opp_alley_bike", "FIO (RÁPIDO): MAGRELO COMPRIDO. PASSIVA BLINDADO: GUARDA FECHADA NO 1º ROUND", "guard", 1],
		["opp_alley_gate", "SEU PÉ DE CABRA (RESISTENTE): BARRIGUDO CARECA. PASSIVA QUEIXO DE FERRO: AGUENTOU!", "shake_head", 6]]
	for bd in bands:
		L.text(im, bd[1], 20, y, "cream")
		y += 12
		var x := 20
		var seq := [["idle", 0, "GUARDA"], ["jab", 1, "JAB"], ["heavy", 2, "DIRETO"], ["hit_head", 2, "LEVA"], [bd[2], bd[3], "PASSIVA"],
			["daze_flee", 1, "FUGA TONTA"], ["daze_flee", 4, ""], ["ko", 2, "APAGOU"], ["ko", 4, ""]]
		for s in seq:
			var c: Image = cell_bg(cw, ch)
			var fr := opp_frame(bd[0], s[0], int(s[1])).get_region(Rect2i(FW - CROP.end.x, CROP.position.y, CROP.size.x, CROP.size.y))
			c.blend_rect(P.scaled(fr, K), Rect2i(0, 0, cw, ch), Vector2i.ZERO)
			im.blit_rect(c, Rect2i(0, 0, cw, ch), Vector2i(x, y))
			L.text(im, s[2], x + 4, y + 4, "y1")
			x += cw + gap
		var por: Image = P.load_png(OUT + "opponents/portrait_%s.png" % bd[0])
		im.blit_rect(P.scaled(por, 4), Rect2i(0, 0, 128, 128), Vector2i(x + 20, y + 30))
		L.text(im, "RETRATO 4X", x + 20, y + 164, "g3")
		y += ch + 14
	# --- 3. beco
	L.text(im, "3. O BECO (ARENA_ALLEY) COM A LUTA MONTADA NA POSIÇÃO DO JOGO: 1X (EM CIMA) E 2X DO MEIO (EMBAIXO)", 20, y, "y1", 2)
	y += 24
	var sc1 := cena_luta(SAMPLE_LOOKS[0], "opp_alley_bike", "jab", 1, "hit_head", 1, 0)
	var sc2 := cena_luta(SAMPLE_LOOKS[1], "opp_alley_gate", "idle", 0, "idle", 0, 1)
	im.blit_rect(sc1, Rect2i(0, 0, AW, AH), Vector2i(20, y))
	im.blit_rect(sc2, Rect2i(0, 0, AW, AH), Vector2i(20 + AW + 20, y))
	y += AH + 10
	im.blit_rect(P.scaled(sc1.get_region(Rect2i(160, 150, 320, 210)), 2), Rect2i(0, 0, 640, 420), Vector2i(20, y))
	var sc3 := cena_luta(SAMPLE_LOOKS[2], "opp_alley_tire", "low_kick", 4, "hit_leg", 1, 1)
	im.blit_rect(P.scaled(sc3.get_region(Rect2i(160, 150, 320, 210)), 2), Rect2i(0, 0, 640, 420), Vector2i(20 + AW + 20, y))
	y += 430
	L.text(im, "CAMADAS: ARANDELA (ACESA / FRACA / APAGADA, 4X) E A GAROA (CROWD_BACK, QUADRO 0, SOBRE FUNDO LISO)", 20, y, "cream")
	y += 12
	var lbg: Image = L.blank(120, 40)
	lbg.fill(L.col("br0"))
	lbg.blend_rect(BECO.lamp, Rect2i(0, 0, 120, 40), Vector2i.ZERO)
	im.blit_rect(P.scaled(lbg, 4), Rect2i(0, 0, 480, 160), Vector2i(20, y))
	var rr: Image = L.blank(AW, 160)
	rr.fill(L.col("d2"))
	rr.blend_rect((BECO.rain as Image).get_region(Rect2i(0, 0, AW, 160)), Rect2i(0, 0, AW, 160), Vector2i.ZERO)
	im.blit_rect(rr, Rect2i(0, 0, AW, 160), Vector2i(520, y))
	y += 172
	# --- 4. estilos da noite
	L.text(im, "4. ESTILOS DA NOITE NA PERSONALIZAÇÃO (3X): SÓ COR NA ARTE QUE JÁ EXISTE (FAIXA, MEIÃO, CALÇÃO)", 20, y, "y1", 2)
	y += 24
	var base_look := {"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "top": "none", "shorts_color": "green", "socks": "none", "headband": "on", "headband_color": "red", "symbol": true}
	var variants := [["PADRÃO", {}], ["FAIXA DA NOITE", {"headband_color": "night"}], ["BANDAGEM", {"socks": "on", "socks_color": "night_wraps"}],
		["CALÇÃO ESCURO", {"shorts_color": "night"}], ["OS 3 JUNTOS", {"headband_color": "night", "socks": "on", "socks_color": "night_wraps", "shorts_color": "night"}]]
	var x3 := 20
	for v in variants:
		var lk: Dictionary = base_look.duplicate()
		lk.merge(v[1], true)
		var fr := compose_disc("fight_player_idle_disc_layered", 0, lk).get_region(Rect2i(20, 8, 72, 96))
		var c: Image = cell_bg(216, 288)
		c.blend_rect(P.scaled(fr, 3), Rect2i(0, 0, 216, 288), Vector2i.ZERO)
		im.blit_rect(c, Rect2i(0, 0, 216, 288), Vector2i(x3, y))
		L.text(im, v[0], x3 + 4, y + 4, "y1")
		x3 += 216 + gap
	var lkv: Dictionary = base_look.duplicate()
	lkv.merge(variants[4][1], true)
	var frv := compose_frame("idle", 0, lkv, keymap(lkv), true).get_region(Rect2i(20, 8, 72, 96))
	var cv: Image = cell_bg(216, 288)
	cv.blend_rect(P.scaled(frv, 3), Rect2i(0, 0, 216, 288), Vector2i.ZERO)
	im.blit_rect(cv, Rect2i(0, 0, 216, 288), Vector2i(x3, y))
	L.text(im, "VULTO COM OS 3", x3 + 4, y + 4, "y1")
	L.text(im, "(A FAIXA SOME", x3 + 4, y + 16, "g3")
	L.text(im, "SOB O CAPUZ)", x3 + 4, y + 26, "g3")
	y += 300
	L.text(im, "O VULTO NUNCA MOSTRA O ROSTO (SÓ O QUEIXO, COMO NA RONDA 1). A FOLHA NUNCA É ESPELHADA: O R DA COXA LÊ CERTO. NENHUM SANGUE: QUEM APAGA FICA COM O OLHO EM X.", 20, y, "g3")
	y += 20
	im.get_region(Rect2i(0, 0, W, y)).save_png(OUT + "ronda2a_amostra_luta.png")
	report.append("prancha: %dx%d" % [W, y])

## Monta a tela de luta no beco: fundo, arandela, garoa, sombras, vulto (296,318), bandido (346,318), primeiro plano.
func cena_luta(look: Dictionary, oid: String, va: String, vq: int, oa: String, oq: int, rain_f: int) -> Image:
	var im: Image = (BECO.bg as Image).duplicate()
	im.blend_rect((BECO.lamp as Image).get_region(Rect2i(0, 0, 40, 40)), Rect2i(0, 0, 40, 40), Vector2i(300, 84))
	im.blend_rect((BECO.rain as Image).get_region(Rect2i((rain_f % 2) * AW, 0, AW, 314)), Rect2i(0, 0, AW, 314), Vector2i(0, 46))
	for cx in [296, 346]:
		for yy in range(315, 322):
			for xx in range(cx - 16, cx + 17):
				var e := Vector2((xx - cx) / 16.0, (yy - 318) / 3.0).length()
				if e <= 1.0 and (xx + yy) % 2 == 0:
					im.set_pixel(xx, yy, L.col("ink"))
	var v := compose_frame(va, vq, look, keymap(look), bool(look.get("symbol", false)))
	im.blend_rect(v, Rect2i(0, 0, FW, FH), Vector2i(296 - 56, 318 - 98))
	var o := opp_frame(oid, oa, oq)
	im.blend_rect(o, Rect2i(0, 0, FW, FH), Vector2i(346 - 56, 318 - 98))
	im.blend_rect((BECO.front as Image).get_region(Rect2i((rain_f % 2) * AW, 0, AW, 48)), Rect2i(0, 0, AW, 48), Vector2i(0, 312))
	return im

# ================================================================================================ B5: ANTES E DEPOIS
## docs/arte/mockups/ronda2a_vulto_antes_depois.png (Diretor de Arte, 2026-11-26). "Antes" = as folhas do vulto que estão em
## FC_ANTES (pasta com os fight_vulto_*_disc_body/head_*.png antigos; sem a variável, assets/sprites/ronda2a/vulto/ do repo);
## "depois" = as geradas agora. Mostra: 1) poses 3x lado a lado; 2) SILHUETA chapada (o teste do morcego); 3) capuz e capa
## ampliados 6x; 4) no beco, 2x.
func antes_frame(a: String, q: int, look: Dictionary) -> Image:
	var dir := OS.get_environment("FC_ANTES")
	if dir == "":
		dir = REPO + "assets/sprites/ronda2a/vulto"
	dir = dir.trim_suffix("/") + "/"
	var id := "fight_vulto_" + a
	var r := Rect2i(q * FW, 0, FW, FH)
	var src: Dictionary = VULTO[a].src.layers
	var base: Image = P.load_png(dir + id + "_disc_body.png").get_region(r)
	if str(look.get("top", "none")) != "none":
		base.blend_rect(load_res(str(src.top[look.top])).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if bool(look.get("symbol", false)) and str(look.get("top", "none")) == "none":
		base.blend_rect(load_res(str(src.school_symbol.leg)).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var out: Image = base.duplicate()
	out.blend_rect(P.load_png(dir + id + "_disc_head_%s.png" % look.get("hair_style", "short")).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var mk := load_res(str(src.front_mask)).get_region(r)
	for y in FH:
		for x in FW:
			var m := mk.get_pixel(x, y)
			if m.a > 0.5 and m.r > 0.5 and base.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, base.get_pixel(x, y))
	recolor(out, keymap(look))
	return out

func silhueta(im: Image, c: String) -> Image:
	var o: Image = L.blank(im.get_width(), im.get_height())
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.0:
				o.set_pixel(x, y, L.col(c))
	return o

func antes_depois() -> void:
	var look: Dictionary = SAMPLE_LOOKS[0]
	var lookC: Dictionary = SAMPLE_LOOKS[2]
	var cm := keymap(look)
	var K := 3
	var cw := CROP.size.x * K
	var ch := CROP.size.y * K
	var gap := 8
	var poses := [["idle", 0, "GUARDA"], ["jab", 1, "JAB"], ["hook", 4, "GANCHO"], ["low_kick", 4, "CHUTE BAIXO"], ["spin_kick", 5, "GIRATÓRIO"], ["hit_head", 2, "LEVA"]]
	var W := 20 + (cw + gap) * poses.size() + 12
	var H := 4000
	var im: Image = L.blank(W, H)
	im.fill(L.col("d1"))
	var y := 16
	L.text(im, "RONDA 2A1 - B5: O VULTO FOGE DO MORCEGO (ANTES X DEPOIS)", 20, y, "y1", 3)
	y += 30
	L.text(im, "MESMO CONCEITO APROVADO: CAPUZ PRETO DE MOLETOM COM ORELHAS DE GATO COSTURADAS, A FAIXA VERMELHA DA ESCOLA NOS OLHOS E UMA CAPA DE LONA.", 20, y, "g3")
	y += 12
	L.text(im, "DEPOIS: ORELHAS BAIXAS E REDONDAS COM COSTURA (SEM PONTA), CAPA DE LONA CINZA MAIS CURTA E PESADA, BARRA CORTADA TORTA, ILHÓS E REMENDO AZUL.", 20, y, "g3")
	y += 12
	L.text(im, "QUADRO, PIVÔ, MÃOS E PONTOS IGUAIS (112X104, PIVÔ 56,98): SÓ MUDA O DESENHO DO CAPUZ E DA CAPA.", 20, y, "g3")
	y += 22
	for fase in [["ANTES", true], ["DEPOIS", false]]:
		L.text(im, "1. %s (3X, LOOK A)" % fase[0], 20, y, "y1" if fase[0] == "DEPOIS" else "r3", 2)
		y += 22
		var x := 20
		for ps in poses:
			var fr: Image = antes_frame(ps[0], int(ps[1]), look) if fase[1] else compose_frame(ps[0], int(ps[1]), look, cm, true)
			var c: Image = cell_bg(cw, ch)
			c.blend_rect(P.scaled(fr.get_region(CROP), K), Rect2i(0, 0, cw, ch), Vector2i.ZERO)
			im.blit_rect(c, Rect2i(0, 0, cw, ch), Vector2i(x, y))
			L.text(im, ps[2], x + 4, y + 4, "y1")
			x += cw + gap
		y += ch + 12
	# silhuetas
	L.text(im, "2. SILHUETA CHAPADA (O TESTE DO MORCEGO): EM CIMA ANTES, EMBAIXO DEPOIS (2X)", 20, y, "y1", 2)
	y += 22
	var K2 := 2
	for fase in [true, false]:
		var x := 20
		for ps in poses:
			var fr: Image = antes_frame(ps[0], int(ps[1]), look) if fase else compose_frame(ps[0], int(ps[1]), look, cm, true)
			var c: Image = L.blank(CROP.size.x * K2, CROP.size.y * K2)
			c.fill(L.col("g3"))
			c.blend_rect(P.scaled(silhueta(fr.get_region(CROP), "ink"), K2), Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i.ZERO)
			im.blit_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i(x, y))
			L.text(im, "ANTES" if fase else "DEPOIS", x + 4, y + 4, "r1" if fase else "b1")
			x += c.get_width() + gap
		y += CROP.size.y * K2 + 8
	y += 8
	# zoom do capuz e da capa
	L.text(im, "3. CAPUZ E CAPA AMPLIADOS (6X, GUARDA E GIRATÓRIO): ANTES | DEPOIS", 20, y, "y1", 2)
	y += 22
	var Z := 6
	var zr := Rect2i(22, 10, 52, 62)
	var x2 := 20
	for ps in [["idle", 0], ["spin_kick", 5]]:
		for fase in [true, false]:
			var fr: Image = antes_frame(ps[0], int(ps[1]), look) if fase else compose_frame(ps[0], int(ps[1]), look, cm, true)
			var c: Image = cell_bg(zr.size.x * Z, zr.size.y * Z)
			c.blend_rect(P.scaled(fr.get_region(zr), Z), Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i.ZERO)
			im.blit_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i(x2, y))
			L.text(im, "ANTES" if fase else "DEPOIS", x2 + 6, y + 6, "r3" if fase else "y1", 2)
			x2 += c.get_width() + gap
	y += zr.size.y * Z + 12
	# no beco
	L.text(im, "4. NO BECO (2X DO MEIO DA TELA, LOOK C COM OS ESTILOS DA NOITE): ANTES | DEPOIS", 20, y, "y1", 2)
	y += 22
	var x4 := 20
	for fase in [true, false]:
		var sc: Image = (BECO.bg as Image).duplicate()
		sc.blend_rect((BECO.lamp as Image).get_region(Rect2i(0, 0, 40, 40)), Rect2i(0, 0, 40, 40), Vector2i(300, 84))
		var v: Image = antes_frame("jab", 1, lookC) if fase else compose_frame("jab", 1, lookC, keymap(lookC), false)
		sc.blend_rect(v, Rect2i(0, 0, FW, FH), Vector2i(296 - 56, 318 - 98))
		var op: Image = load_res("res://assets/sprites/opponents/opp_alley_bike/opp_alley_bike_hit_head.png")
		sc.blend_rect(op.get_region(Rect2i(FW, 0, FW, FH)), Rect2i(0, 0, FW, FH), Vector2i(346 - 56, 318 - 98))
		var part: Image = P.scaled(sc.get_region(Rect2i(200, 190, 200, 140)), 2)
		im.blit_rect(part, Rect2i(0, 0, part.get_width(), part.get_height()), Vector2i(x4, y))
		L.text(im, "ANTES" if fase else "DEPOIS", x4 + 6, y + 6, "r3" if fase else "y1", 2)
		x4 += part.get_width() + gap
	y += 280 + 12
	L.text(im, "PLACEHOLDER POR CÓDIGO: A CAPA É UMA FUNÇÃO (PREGAS E ATRASO), NÃO PANO DESENHADO QUADRO A QUADRO. UM PIXEL ARTIST DARIA PESO E DOBRA DE LONA À MÃO.", 20, y, "g3")
	y += 18
	im.get_region(Rect2i(0, 0, W, y)).save_png(OUT + "ronda2a_vulto_antes_depois.png")
	report.append("antes/depois: %dx%d" % [W, y])

## B5 na Ronda 1 (o mesmo ajuste, para o vulto ser um só): docs/arte/mockups/ronda_vulto_antes_depois_r1.png. "Antes" =
## folhas e capuz no prego em FC_ANTES_R1 (cópia de assets/sprites/minigame/ronda_vulto_* e dos hood_on_nail*.png antigos);
## "depois" = os do repo. Quadro 96x100 da Ronda 1, montado body -> symbol.leg -> head.short e trocado pela paleta do look A.
func r1_frame(dir: String, a: String, q: int, look: Dictionary) -> Image:
	var fw := 96
	var fh := 100
	var r := Rect2i(q * fw, 0, fw, fh)
	var im: Image = P.load_png(dir + "ronda_vulto_%s_disc_body.png" % a).get_region(r)
	if bool(look.get("symbol", false)):
		im.blend_rect(P.load_png(dir + "ronda_vulto_%s_disc_symbol_leg.png" % a).get_region(r), Rect2i(0, 0, fw, fh), Vector2i.ZERO)
	im.blend_rect(P.load_png(dir + "ronda_vulto_%s_disc_head_short.png" % a).get_region(r), Rect2i(0, 0, fw, fh), Vector2i.ZERO)
	recolor(im, keymap(look))
	return im

func antes_depois_r1() -> void:
	var ant := OS.get_environment("FC_ANTES_R1").replace("\\", "/").trim_suffix("/") + "/"
	var dep := REPO + "assets/sprites/minigame/"
	var look: Dictionary = SAMPLE_LOOKS[0]
	var poses := [["roof", 0, "TELHADO"], ["sneak_walk", 1, "ANDANDO"], ["freeze", 0, "ESTÁTUA"], ["scare", 2, "PULO"], ["scare", 5, "SUSTO!"], ["seen", 0, "VISTO"]]
	var K := 3
	var cw := 96 * K
	var ch := 100 * K
	var gap := 8
	var W := 20 + (cw + gap) * poses.size() + 12
	var im: Image = L.blank(W, 2400)
	im.fill(L.col("d1"))
	var y := 16
	L.text(im, "RONDA 1 COM O MESMO AJUSTE DO B5 (ANTES X DEPOIS): O VULTO DA RUA, A ESTÁTUA E O CAPUZ NO PREGO", 20, y, "y1", 2)
	y += 22
	L.text(im, "ORELHAS DE GATO COSTURADAS (SEM PONTA), CAPA DE LONA CINZA UM POUCO MAIS CURTA, BARRA CORTADA TORTA, ILHÓS E REMENDO AZUL. POSES, QUADROS E PIVÔS IGUAIS (96X100, PIVÔ 50,94).", 20, y, "g3")
	y += 18
	for fase in [["ANTES", ant], ["DEPOIS", dep]]:
		L.text(im, "%s (3X, LOOK A, FUNDO NOITE)" % fase[0], 20, y, "r3" if fase[0] == "ANTES" else "y1", 2)
		y += 22
		var x := 20
		for ps in poses:
			var c: Image = L.blank(cw, ch)
			c.fill(L.col("b0"))
			c.blend_rect(P.scaled(r1_frame(fase[1], ps[0], int(ps[1]), look), K), Rect2i(0, 0, cw, ch), Vector2i.ZERO)
			im.blit_rect(c, Rect2i(0, 0, cw, ch), Vector2i(x, y))
			L.text(im, ps[2], x + 4, y + 4, "y1")
			x += cw + gap
		y += ch + 12
	L.text(im, "SILHUETA CHAPADA (2X): ANTES | DEPOIS", 20, y, "y1", 2)
	y += 22
	var x2 := 20
	for ps in poses:
		for fase in [ant, dep]:
			var sh := silhueta(r1_frame(fase, ps[0], int(ps[1]), look), "ink")
			var c: Image = L.blank(96, 100)
			c.fill(L.col("g3"))
			c.blend_rect(sh, Rect2i(0, 0, 96, 100), Vector2i.ZERO)
			var c2: Image = P.scaled(c.get_region(Rect2i(16, 20, 64, 80)), 2)
			im.blit_rect(c2, Rect2i(0, 0, c2.get_width(), c2.get_height()), Vector2i(x2, y))
			x2 += c2.get_width() + 4
		x2 += 8
		if x2 > W - 300:
			x2 = 20
			y += 168
	if x2 > 20:
		y += 168
	L.text(im, "CAPUZ NO PREGO (16X22, 8X): GARAGEM E ACADEMIA/CENTRO, ANTES | DEPOIS", 20, y, "y1", 2)
	y += 22
	var x3 := 20
	for f in ["hood_on_nail.png", "hood_on_nail_gym.png"]:
		var sub := "garage/" if f == "hood_on_nail.png" else "gym/"
		for src in [ant + f, REPO + "assets/sprites/" + sub + f]:
			var h: Image = P.load_png(src).get_region(Rect2i(0, 0, 16, 22))
			var c: Image = L.blank(16, 22)
			c.fill(L.col("g1" if f == "hood_on_nail.png" else "cream"))
			c.blend_rect(h, Rect2i(0, 0, 16, 22), Vector2i.ZERO)
			var c8: Image = P.scaled(c, 8)
			im.blit_rect(c8, Rect2i(0, 0, 128, 176), Vector2i(x3, y))
			L.text(im, "ANTES" if src.begins_with(ant) else "DEPOIS", x3 + 4, y + 4, "ink")
			x3 += 128 + gap
		x3 += 16
	y += 176 + 14
	im.get_region(Rect2i(0, 0, W, y)).save_png(OUT + "ronda_vulto_antes_depois_r1.png")
	report.append("antes/depois r1: %dx%d" % [W, y])
