extends RefCounted
## personagem_lib.gd — sistema de corpo reutilizável para TODOS os personagens do Fightclicker
## (lutador do jogador, adversários, ajudantes, figurantes). Artista de Personagens.
## Padrão: .claude/skills/padrao-personagem/SKILL.md (seções 1–5b). Diagnóstico: docs/arte/personagens-diagnostico.md.
##
## Uso (num script SceneTree rodado headless a partir de uma pasta temporária):
##   var L = load(".../pixel_lib.gd").new()             # paleta, rampas, fonte
##   var P = load(".../personagem_lib.gd").new(L)
##   var b: Dictionary = P.build({...parâmetros do personagem...})   # ver build()
##   var img: Image = P.fight_frame(b, {"hip": Vector2(0,-37), "top": Vector2(2,-61), "hf": ..., "hb": ...}, "tag")
##   var img2: Image = P.garage_frame(b, {...}, "tag")
##
## Como o corpo é montado:
##  1. Tela única com MAPA DE PARTES (id por pixel; id maior = mais na frente). Nada de contorno por peça.
##     finish(): sombra de contato onde uma parte da frente encosta numa de trás (exceto perto das juntas
##     ligadas: ombro, cotovelo, quadril, joelho, que se fundem) + contorno ink de 1 px SÓ na silhueta.
##  2. Comprimentos fixos (braço, antebraço, coxa, canela) + IK de 2 ossos; avisa no log se um alvo está
##     fora do alcance (log_lines).
##  3. Pé ancorado pela PONTA (tênis em mapa de pixels; "ball" = calcanhar levantado; "up" = deitado).
##  4. Cabeça, luvas e tênis = mapas de pixels desenhados à mão (dados), com rotação/espelho exatos em
##     múltiplos de 90° (e rotação livre por vizinho mais próximo, para a cabeça no meio da queda).
##     Luva em 5 orientações desenhadas (up/diag/side/diagdown/down) + espelhos, escolhida pela direção
##     do antebraço: gira com o corpo (inclusive no K.O.).
##  5. Tronco por fatias ao longo do eixo quadril->peito (qualquer ângulo: em pé, inclinado, deitado),
##     com giro (tw), largura de ombro/quadril, barriga e roupa parametrizáveis.
##  6. Uma luz só: de cima e da frente do personagem (já pintada nos mapas; membros usam LD).

const HALF := Vector2(0.5, 0.5)
const LD := Vector2(0.55, -0.83)

## ids de profundidade (espaçados de 10 para caber camadas extras)
const FAR_THIGH := 10
const FAR_SHIN := 11
const FAR_SHOE := 12
const G_LEG_L := 13              # garagem: perna esquerda (na frente da direita, atrás do tronco)
const FAR_UP := 20
const FAR_FORE := 21
const FAR_GLOVE := 22
const TORSO := 30
const HEAD := 40
const FAR_GLOVE_FRONT := 45
const NEAR_THIGH := 50
const NEAR_SHIN := 51
const NEAR_SHOE := 52
const NEAR_UP := 60
const NEAR_FORE := 61
const NEAR_GLOVE := 62
const NEAR_GLOVE_TOP := 70

var L
var log_lines: Array = []

var cw := 0
var ch := 0
var img: Image
var ids := PackedInt32Array()
var joints: Array = []

func _init(pixel_lib) -> void:
	L = pixel_lib

# ================================================================ DISCÍPULO EM CAMADAS (Fase 6b1)
## Escopo 6b §4.4. Cada quadro do discípulo vira 3 imagens do MESMO tamanho e pivô:
##   body  = o corpo inteiro SEM a cabeça (pescoço, tronco, braços, pernas, calção, tênis e luvas);
##   head  = só o que a cabeça muda no quadro (cabeça, cabelo, contorno dela e a sombra que ela faz no pescoço/ombro);
##   mask  = máscara (branco) dos pixels do corpo que ficam NA FRENTE da cabeça, perto dela (luva/braço passando na
##           frente do rosto). Montagem no jogo: body -> head -> body de novo recortado pela mask. Com o visual padrão o
##           resultado é idêntico ao quadro inteiro (conferido pixel a pixel no gerador).
## Como sai: capture = true faz cada fight_frame/garage_frame desenhar 2 vezes (com e sem cabeça) e guardar as camadas
## em `captured` (o quadro devolvido continua o inteiro, então os geradores antigos funcionam igual).
## Cortes novos (6b2): outro mapa de cabeça (head_34/head_side) com o mesmo corpo -> outra camada head, pela mesma conta.
## Parte de cima (6b2): body com top != "none" menos body sem top = camada do meio (entre body e head).
## As âncoras do quadro (cabeça, quadril, peito, giro, vista, rosto) ficam em `anchor` de cada captura.
var capture := false
var captured: Array = []
var _cap_busy := false
var skip_head := false
var last_anchor := {}
const HEAD_ZONE_PAD := 6
var key_mode := false
var build_ref := {}   # personagem em uso (ganchos de pose que desenham adereços com a luva dele)

## Cores-chave do discípulo (troca de paleta). Visualmente = o visual padrão (skin_3, castanho, verde), com 1 unidade a
## mais num canal para nenhuma chave coincidir com a paleta de 45 (luva, tênis, contorno e fita NÃO são trocados).
## Rampa = mesma posição das rampas originais (a sombra de contato anda na rampa e continua dentro das chaves).
const KEYS := {
	"skin": {"names": ["k_sk_d", "k_sk0", "k_sk1", "k_sk2", "k_sk_h"], "hex": ["3b2623", "7a4633", "b97450", "e3a276", "fff3c5"],
		"slots": ["deep", "shadow", "base", "light", "highlight"]},
	"hair": {"names": ["ink", "k_hb", "k_h0", "k_h1", "k_h2"], "hex": ["", "3b2722", "6b402a", "9a6036", "c98b4b"],
		"slots": ["ink", "brow", "dark", "light", "shine"]},
	"shorts": {"names": ["k_sh_d", "k_sh0", "k_sh1", "k_sh2", "k_sh3"], "hex": ["15101a", "203d33", "306b4a", "5ba25a", "a7d86a"],
		"slots": ["deep", "dark", "mid", "light", "band"]},
	## Fase 6b2: parte de cima (visual = camiseta branca g2/g3/cream/white +1 no azul), faixa (vermelha r0/r1/r2 +1 no azul)
	## e meião (calção verde gr0/gr1/gr3 +1 no azul; o calção usa +1 no vermelho, então nunca se confundem).
	"top": {"names": ["k_tp_d", "k_tp0", "k_tp1", "k_tp2"], "hex": ["8f8891", "b8b0ab", "d9cdb5", "f2ece1"],
		"slots": ["deep", "dark", "mid", "light"]},
	"band": {"names": ["k_bd_d", "k_bd0", "k_bd1"], "hex": ["5a1a23", "9c2a2b", "d4473b"],
		"slots": ["deep", "dark", "light"]},
	"socks": {"names": ["k_so0", "k_so1", "k_so2"], "hex": ["1f3d34", "2f6b4b", "a6d86b"],
		"slots": ["shadow", "base", "stripe"]},
	## Fase 6c2: símbolo da escola (visual = carimbo azul b0/b1 da 6a com +1 num canal)
	"symbol": {"names": ["k_sy0", "k_sy1"], "hex": ["1f2a45", "304a78"], "slots": ["shadow", "base"]},
}

# ---------------------------------------------------------------- Fase 6b2: cortes, faixa, parte de cima, meião
## Cortes do discípulo. Cada corte = os dois mapas de cabeça (3/4 da garagem e perfil da luta) com o MESMO rosto
## do mapa-base (HEAD_34 / HEAD_SIDE): só o cabelo muda. pad = [colunas a mais à esquerda, linhas a mais em cima]
## em relação ao mapa-base (a âncora anda junto, então o rosto e o centro da cabeça ficam no mesmo pixel).
## Regra da faixa: as linhas 3 e 4 do mapa-base (testa) têm o MESMO contorno em todos os cortes, e os pixels do nó
## (atrás) existem em todos; assim a faixa é uma camada só, igual para os 4 cortes (o gerador confere).
## H = tom escuro do cabelo (a franja sempre nele), h = tom claro, b = sobrancelha; o resto = HEAD_*.
const CUT_ORDER := ["short", "buzz", "volume", "bun"]
const DISC_CUTS := {
	"short": {"pad": [0, 0], "34": HEAD_34, "side": HEAD_SIDE},
	# raspado: o crânio 1 px mais baixo, sem brilho, entradas na testa e nuca rala (pele aparecendo)
	"buzz": {"pad": [0, 0],
		"34": [
			".............",
			"...HHHHHHH...",
			".HHHSHHHSHHH.",
			"HHHHHHHSHHSls",
			"HHHSsslllllll",
			"HHSSsbbsslbbl",
			"HSESsesssles.",
			"HEsSssssslll.",
			".SESssssssss.",
			".SSsssssssSs.",
			"..SsssmmmSs..",
			"...SSsssss...",
			".....SSSs....",
		],
		"side": [
			"..............",
			"....HHHHHHH...",
			"..HHHSHHHSHH..",
			".HHHHHHHSHSll.",
			"HHHHHHssssll..",
			"HHHHHsssbbbl..",
			"HHSEEssssesl..",
			"HSSEsEsssssl..",
			".SSEEssssssll.",
			".SSSsssssssss.",
			"..SSssssssss..",
			"...SSssssmSs..",
			"....SSsssss...",
			".....SSSss....",
		]},
	# volume: topete alto penteado para cima e para a frente (2 linhas a mais), franja escura caindo na testa
	"volume": {"pad": [0, 2],
		"34": [
			"...HHHHHHH....",
			".HHHhhhhhHHH..",
			"HHHhhhhhhhhHH.",
			"HHHHhhhhhhhhHH",
			"HHHHHhhhhhHHHH",
			"HHHHHHHHHHHHs.",
			"HHHHHHHllllll.",
			"HHHSsbbsslbbl.",
			"HHESsesssles..",
			"HEsSssssslll..",
			".HESssssssss..",
			".HSsssssssSs..",
			"..SsssmmmSs...",
			"...SSsssss....",
			".....SSSs.....",
		],
		"side": [
			"....HHHHHHH...",
			"..HHHhhhhhHHH.",
			".HHHhhhhhhhhHH",
			"HHHHhhhhhhhHHH",
			"HHHHHHhhhhHHH.",
			".HHHHHHHHHHHH.",
			"HHHHHHHHssll..",
			"HHHHHHssbbbl..",
			"HHHEEssssesl..",
			"HHHEsEsssssl..",
			".HHEEssssssll.",
			".HHHsssssssss.",
			"..HSssssssss..",
			"...SSssssmSs..",
			"....SSsssss...",
			".....SSSss....",
		]},
	# coque: cabelo puxado para trás (riscas claras indo para a nuca) e coque alto atrás (3 linhas a mais)
	"bun": {"pad": [1, 3],
		"34": [
			".HHH..........",
			"HhhHH.........",
			"HHhHHH........",
			".HHHHHHHHH....",
			"..HhhhhHHHHHH.",
			".HHHHHhhhhHHHH",
			".HHHHHHHHHHHHs",
			".HHHHsslllllll",
			".HHHSsbbsslbbl",
			".HHESsesssles.",
			".HEsSssssslll.",
			"..HESssssssss.",
			"..HSsssssssSs.",
			"...SsssmmmSs..",
			"....SSsssss...",
			"......SSSs....",
		],
		"side": [
			".HHH...........",
			"HhhHH..........",
			"HHhHH..........",
			".HHHHHHHHHH....",
			"..HHHhhhhHHHH..",
			"..HHHHHhhhHHHH.",
			"..HHHHHHHHHHHH.",
			".HHHHHHHsssll..",
			".HHHHHHssbbbl..",
			".HHHEEssssesl..",
			".HHHEsEsssssl..",
			"..HHEEssssssll.",
			"..HHHsssssssss.",
			"...HSssssssss..",
			"....SSssssmSs..",
			".....SSsssss...",
			"......SSSss....",
		]},
}
## Faixa (Fase 6b2): linhas 3 e 4 do mapa-base inteiras (F = tom claro em cima, na frente; G = tom escuro embaixo e
## atrás) + o nó atrás (pixels G em [coluna, linha] do mapa-base). Desenhada por cima do cabelo e da testa.
const BAND := {
	"34": {"rows": [3, 4], "back_cols": 4, "knot": [[0, 5], [0, 6]]},
	"side": {"rows": [3, 4], "back_cols": 4, "knot": [[0, 5], [1, 5], [0, 6]]},
}
const BAND_LEGEND := {"F": "k_bd1", "G": "k_bd0"}
## Meião (Fase 6b2): da canela (t = SOCK_FROM, 0 = joelho, 1 = tornozelo) até o tênis; 1 px de listra no alto.
const SOCK_FROM := 0.38

## Fase 6c2 (Diretor de Arte): símbolo da escola Raízes Fight Club na roupa do discípulo (docs/arte/direcao-visual.md §26).
## 6d3 (aprovado pelo dono): o "R de raiz" (proposta D, docs/arte/fase6d3-simbolo.md): 3/4 = o school_symbol_5 (5x5);
## perfil e coxa = o R em 3x5. O R NÃO é simétrico: nas folhas viradas (_left, capture_flip_last) o carimbo sai espelhado e o
## tools/art/make_arte_fase6d3_simbolo.gd desvira o carimbo no lugar (depois de copiar as camadas).
## Uma cor só (estampa), em cor-chave k_sy1 (k_sy0 = a sombra de contato que o finish() faz quando o braço encosta):
## o jogo troca pela cor da parte de cima (peito) ou do calção (coxa): by_data_id.disciple_palette.school_symbol_source.
## center = pixel do mapa que cai no ponto do corpo.
const SYMBOL := {
	"34": {"rows": ["AAAA.", "A..A.", "AAA..", "A.AA.", "AA.AA"], "center": Vector2i(2, 2)},
	"side": {"rows": ["AA.", "A.A", "AA.", "A.A", "A.A"], "center": Vector2i(1, 2)},
	"leg": {"rows": ["AA.", "A.A", "AA.", "A.A", "A.A"], "center": Vector2i(1, 2)},
}
const SYMBOL_LEGEND := {"A": "k_sy1"}
## Peito: t (0 = quadril, 1 = ombro) do centro; s = mid_34 + 1 (3/4) ou back + 2,5 (perfil: nas costas, porque o braço da guarda tapa o peito). Fica abaixo do decote
## da regata do discípulo (tank_neck 0,68), então regata e camiseta dão o mesmo desenho (o gerador confere).
const SYMBOL_T := {"34": 0.55, "side": 0.66}
## Coxa da frente (G_LEG_L na garagem, NEAR_THIGH na luta): centro a 0,3 do quadril até o joelho, só sobre o calção.
const SYMBOL_LEG_T := 0.3

## Ponto (pixel) do símbolo no peito para este tronco, ou Vector2i(-999, -999) se o build não pede.
func _symbol_origin(b: Dictionary, hip: Vector2, d: Vector2, fr: Vector2, sl: Array, view: String, tw: float) -> Vector2i:
	if b.get("school_symbol", "") != "chest":
		return Vector2i(-999, -999)
	var v := "side" if view == "side" else "34"
	var tc: float = SYMBOL_T[v]
	var bf := _interp_slices(sl, tc)
	var k := smoothstep(0.45, 0.9, tc)
	var back := bf.x
	var front := bf.y
	if view == "side":
		front += tw * k
		back -= tw * 0.5 * k
	else:
		back += tw * 1.5 * k
		front += tw * 0.5 * k
	var sc := (back + 2.5) if view == "side" else (mid_34(back, front) + 1.0)   # perfil: nas costas (6c2 B2: na frente o braço da guarda tapa)
	var p := hip + d * tc + fr * sc
	var cen: Vector2i = SYMBOL[v].center
	return Vector2i(int(floor(p.x)) - cen.x, int(floor(p.y)) - cen.y)

## Cor do símbolo no pixel (x, y) para o mapa `v` com canto em `o`, ou null.
func _symbol_px(v: String, o: Vector2i, x: int, y: int):
	var rows: Array = SYMBOL[v].rows
	var gy := y - o.y
	var gx := x - o.x
	if gy < 0 or gy >= rows.size() or gx < 0 or gx >= (rows[0] as String).length():
		return null
	var ch_: String = (rows[gy] as String)[gx]
	if ch_ == ".":
		return null
	return SYMBOL_LEGEND[ch_]

func use_keys() -> void:
	if key_mode:
		return
	for k in KEYS:
		L.add_ramp(KEYS[k].names, KEYS[k].hex)
	key_mode = true

## Desenha o quadro com o personagem trocado em `opts` (chaves do build) e devolve [imagem, ids]; o build volta como era.
func _variant(b: Dictionary, fn: Callable, opts: Dictionary, no_head: bool) -> Array:
	var keep := {}
	for k in opts:
		keep[k] = b[k] if b.has(k) else null
		b[k] = opts[k]
	skip_head = no_head
	var im: Image = fn.call()
	skip_head = false
	var idc := ids.duplicate()
	for k in keep:
		if keep[k] == null:
			b.erase(k)
		else:
			b[k] = keep[k]
	return [im, idc]

const LEG_IDS := [FAR_THIGH, FAR_SHIN, FAR_SHOE, G_LEG_L, G_LEG_L + 1, G_LEG_L + 2, NEAR_THIGH, NEAR_SHIN, NEAR_SHOE]
var variants_stats := {"frames": 0, "check_bad": 0, "band_bad": 0, "ids_bad": 0}

func _capture_call(fn: Callable, bref: Dictionary = {}) -> Image:
	if bref.get("disc_layers", false) and key_mode:
		return _capture_call_6b2(fn, bref)
	_cap_busy = true
	var A: Image = fn.call()
	var ids_a := ids.duplicate()
	var anc := last_anchor.duplicate(true)
	var nlog := log_lines.size()
	skip_head = true
	var B: Image = fn.call()
	skip_head = false
	log_lines.resize(nlog)
	_cap_busy = false
	var w := A.get_width()
	var h := A.get_height()
	var H := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var Mk := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in h:
		for x in w:
			if ids_a[y * w + x] == HEAD:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	var zone := Rect2i(x0 - HEAD_ZONE_PAD, y0 - HEAD_ZONE_PAD, x1 - x0 + 1 + 2 * HEAD_ZONE_PAD, y1 - y0 + 1 + 2 * HEAD_ZONE_PAD)
	var white := Color(1, 1, 1, 1)
	var keys := {}
	if key_mode:
		for k in KEYS:
			for n in KEYS[k].names:
				if n != "ink":
					keys[(L.col(n) as Color).to_html(false)] = true
	for y in h:
		for x in w:
			var id := ids_a[y * w + x]
			var a := A.get_pixel(x, y)
			if id > HEAD:
				if x1 >= 0 and zone.has_point(Vector2i(x, y)):
					Mk.set_pixel(x, y, white)
			elif id == HEAD:
				H.set_pixel(x, y, a)
			elif a != B.get_pixel(x, y):
				# sombra que a cabeça faz numa peça que NÃO troca de cor (luva de trás, fita): fica no corpo, senão a
				# camada da cabeça mudaria com a luva. Pele, cabelo, calção e contorno vão para a cabeça.
				if id != HEAD and id != 0 and key_mode and not keys.has(a.to_html(false)):
					B.set_pixel(x, y, a)
				else:
					H.set_pixel(x, y, a)
	ids = ids_a
	anc["head_box"] = [x0, y0, x1 - x0 + 1, y1 - y0 + 1] if x1 >= 0 else []
	captured.append({"full": A.duplicate(), "body": B, "head": H, "mask": Mk, "anchor": anc})
	return A

func _key_set() -> Dictionary:
	var keys := {}
	for k in KEYS:
		for n in KEYS[k].names:
			if n != "ink":
				keys[(L.col(n) as Color).to_html(false)] = true
	return keys

func _head_rect(idv: PackedInt32Array, w: int, h: int) -> Rect2i:
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in h:
		for x in w:
			if idv[y * w + x] == HEAD:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i()
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

## Fase 6b2. Cada quadro do discípulo sai, além de body/head_short/front, com:
##   heads[corte] = a cabeça de cada corte (mesma conta da 6b1: pixels da cabeça + o contorno e a sombra que ela faz);
##   band         = só os pixels que a faixa muda (igual nos 4 cortes: o gerador confere e conta em variants_stats);
##   tops[tank|tee] = corpo com a peça menos corpo sem ela (tronco e braços);
##   socks        = corpo com meião menos corpo sem (pernas);
##   mask         = corpo na frente da cabeça, na zona que cobre o corte mais alto (vale para os 4 cortes).
## Sombra que a cabeça faz onde a roupa pode passar (ombro, peito) fica no body (a camiseta cobre por cima), como a
## sombra em peças que não trocam de cor. Confere: body+tee+socks+head_bun+band+front == quadro desenhado inteiro.
func _capture_call_6b2(fn: Callable, b: Dictionary) -> Image:
	_cap_busy = true
	var nlog := log_lines.size()
	var A: Image = fn.call()
	var ids_a := ids.duplicate()
	var anc := last_anchor.duplicate(true)
	var rB := _variant(b, fn, {}, true)
	var B: Image = rB[0]
	var ids_b: PackedInt32Array = rB[1]
	var cutA := {"short": [A, ids_a]}
	for cut in CUT_ORDER:
		if cut != "short":
			cutA[cut] = _variant(b, fn, cut_opts(cut), false)
	var bandA := {}
	for cut in CUT_ORDER:
		var o := cut_opts(cut)
		o["disc_band"] = true
		bandA[cut] = _variant(b, fn, o, false)
	var tops := {}
	for tk in ["tank", "tshirt"]:
		tops[tk] = _variant(b, fn, {"top": tk, "sock_on": true}, true)
	# Fase 6c2: símbolo da escola (peito com camiseta e com regata; coxa sem parte de cima)
	var symC := _variant(b, fn, {"top": "tshirt", "sock_on": true, "school_symbol": "chest"}, true)
	var symT := _variant(b, fn, {"top": "tank", "sock_on": true, "school_symbol": "chest"}, true)
	var symL := _variant(b, fn, {"school_symbol": "leg"}, true)
	var oc := cut_opts("bun")
	oc.merge({"disc_band": true, "top": "tshirt", "sock_on": true}, true)
	var chk: Array = _variant(b, fn, oc, false)
	log_lines.resize(nlog)
	_cap_busy = false
	var w := A.get_width()
	var h := A.get_height()
	var keys := _key_set()
	var white := Color(1, 1, 1, 1)
	var none := Color(0, 0, 0, 0)
	# zona da máscara: caixa de todos os cortes juntos
	var box_s := _head_rect(ids_a, w, h)
	var box_m := box_s
	for cut in cutA:
		var r := _head_rect(cutA[cut][1], w, h)
		if r.has_area():
			box_m = r if not box_m.has_area() else box_m.merge(r)
	# partes de cima e meião
	var T := {"tank": Image.create_empty(w, h, false, Image.FORMAT_RGBA8), "tshirt": Image.create_empty(w, h, false, Image.FORMAT_RGBA8)}
	var S := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var topzone := PackedByteArray()
	topzone.resize(w * h)
	topzone.fill(0)
	for tk in tops:
		var im: Image = tops[tk][0]
		var tid: PackedInt32Array = tops[tk][1]
		if tid != ids_b:
			variants_stats.ids_bad += 1
		for y in h:
			for x in w:
				var c := im.get_pixel(x, y)
				if c == B.get_pixel(x, y):
					continue
				var i := y * w + x
				if tid[i] in LEG_IDS:
					if tk == "tank":
						S.set_pixel(x, y, c)
				else:
					(T[tk] as Image).set_pixel(x, y, c)
					topzone[i] = 1
	# Fase 6c2: símbolo = variante com símbolo menos a mesma sem. Peito: camiseta e regata têm de dar o mesmo.
	var SYC := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var SYL := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var sym_bad := 0
	var imC: Image = symC[0]
	var imT: Image = symT[0]
	var imL: Image = symL[0]
	var tC: Image = tops["tshirt"][0]
	var tT: Image = tops["tank"][0]
	for y in h:
		for x in w:
			var c := imC.get_pixel(x, y)
			var cc := c if c != tC.get_pixel(x, y) else none
			var ct := imT.get_pixel(x, y)
			var ctt := ct if ct != tT.get_pixel(x, y) else none
			# só o que regata e camiseta mostram igual (a manga da camiseta tapa 1-2 px da borda em 11 quadros):
			# assim a camada nunca pinta por cima de braço ou manga em nenhuma das duas
			if cc.a > 0.0 and cc == ctt:
				SYC.set_pixel(x, y, cc)
			elif cc != ctt:
				sym_bad += 1
			var cl := imL.get_pixel(x, y)
			if cl != B.get_pixel(x, y):
				SYL.set_pixel(x, y, cl)
	if symC[1] != tops["tshirt"][1] or symL[1] != ids_b:
		variants_stats.ids_bad += 1
	variants_stats["symbol_frames"] = int(variants_stats.get("symbol_frames", 0)) + 1
	if sym_bad > 0:
		variants_stats["symbol_bad"] = int(variants_stats.get("symbol_bad", 0)) + 1
		log_lines.append("NOTA símbolo: regata e camiseta diferem em %d px (fica só o que as duas mostram)" % sym_bad)
	# cabeças (o short primeiro: é ele que passa sombras para o body, como na 6b1)
	var Bm: Image = B.duplicate()
	var heads := {}
	for cut in CUT_ORDER:
		var Ac: Image = cutA[cut][0]
		var ic: PackedInt32Array = cutA[cut][1]
		var H := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var i := y * w + x
				var id := ic[i]
				if id > HEAD:
					continue
				var a := Ac.get_pixel(x, y)
				if id == HEAD:
					H.set_pixel(x, y, a)
				elif a != B.get_pixel(x, y):
					if id != 0 and (not keys.has(a.to_html(false)) or topzone[i] == 1):
						if cut == "short":
							Bm.set_pixel(x, y, a)
					else:
						H.set_pixel(x, y, a)
		heads[cut] = H
	# faixa: o que ela muda no short; os outros cortes têm de dar o mesmo
	var D := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var Ds: Image = bandA["short"][0]
	for y in h:
		for x in w:
			var c := Ds.get_pixel(x, y)
			if c != A.get_pixel(x, y):
				D.set_pixel(x, y, c)
	for cut in CUT_ORDER:
		if cut == "short":
			continue
		var Ab: Image = bandA[cut][0]
		var Ac: Image = cutA[cut][0]
		var bad := 0
		for y in h:
			for x in w:
				var c := Ab.get_pixel(x, y)
				var want := c if c != Ac.get_pixel(x, y) else none
				if want != D.get_pixel(x, y):
					bad += 1
		if bad > 0:
			variants_stats.band_bad += 1
			log_lines.append("AVISO faixa: corte %s difere da faixa do short em %d px" % [cut, bad])
	# máscara
	var Mk := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	if box_m.has_area():
		var zone := box_m.grow(HEAD_ZONE_PAD)
		for y in h:
			for x in w:
				if ids_a[y * w + x] > HEAD and zone.has_point(Vector2i(x, y)):
					Mk.set_pixel(x, y, white)
	# conferência com um visual cheio desenhado de verdade
	var comp := compose_full(Bm, T.tshirt, S, heads.bun, D, Mk)
	var nd := 0
	var full_c: Image = chk[0]
	for y in h:
		for x in w:
			if comp.get_pixel(x, y) != full_c.get_pixel(x, y):
				nd += 1
	variants_stats.frames += 1
	if nd > 0 and OS.get_environment("FC_DBG6B2") != "":
		var dd: String = OS.get_environment("FC_DBG6B2")
		var k := int(variants_stats.frames)
		var big := Image.create_empty(w * 3, h, false, Image.FORMAT_RGBA8)
		big.blit_rect(comp, Rect2i(0, 0, w, h), Vector2i(0, 0))
		big.blit_rect(full_c, Rect2i(0, 0, w, h), Vector2i(w, 0))
		for y in h:
			for x in w:
				if comp.get_pixel(x, y) != full_c.get_pixel(x, y):
					big.set_pixel(2 * w + x, y, Color(1, 0, 1))
		big.resize(w * 9, h * 3, Image.INTERPOLATE_NEAREST)
		big.save_png(dd + "/chk_%d.png" % k)
	if nd > 0:
		variants_stats.check_bad += 1
		variants_stats["check_px"] = int(variants_stats.get("check_px", 0)) + nd
	ids = ids_a
	last_anchor = anc
	anc["head_box"] = [box_s.position.x, box_s.position.y, box_s.size.x, box_s.size.y] if box_s.has_area() else []
	anc["head_box_max"] = [box_m.position.x, box_m.position.y, box_m.size.x, box_m.size.y] if box_m.has_area() else []
	captured.append({"full": A.duplicate(), "body": Bm, "head": heads.short, "mask": Mk, "anchor": anc,
		"heads": heads, "band": D, "tops": {"tank": T.tank, "tee": T.tshirt}, "socks": S, "check_px": nd,
		"symbols": {"chest": SYC, "leg": SYL}})
	return A

## Montagem completa da 6b2 (a mesma que o jogo faz): baixo = body + parte de cima + meião; depois cabeça do corte,
## faixa; por fim, nos pixels da máscara front, o "baixo" de novo (só onde ele tem cor). Qualquer camada pode ser null.
func compose_full(body: Image, top, socks, head, band, mask, recolor := {}) -> Image:
	var w := body.get_width()
	var h := body.get_height()
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var lo := body.get_pixel(x, y)
			for ly in [top, socks]:
				if ly != null:
					var lc: Color = (ly as Image).get_pixel(x, y)
					if lc.a > 0.0:
						lo = lc
			var c := lo
			for ly in [head, band]:
				if ly != null:
					var lc: Color = (ly as Image).get_pixel(x, y)
					if lc.a > 0.0:
						c = lc
			if mask != null and (mask as Image).get_pixel(x, y).a > 0.0 and lo.a > 0.0:
				c = lo
			if c.a > 0.0 and not recolor.is_empty():
				var hx := c.to_html(false)
				if recolor.has(hx):
					c = recolor[hx]
			out.set_pixel(x, y, c)
	return out

## Monta body -> head -> body pela máscara (para conferir e para os mockups). recolor = {Color chave: Color nova}.
func compose_layers(body: Image, head: Image, mask: Image, recolor := {}) -> Image:
	var w := body.get_width()
	var h := body.get_height()
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := body.get_pixel(x, y)
			var hc := head.get_pixel(x, y)
			if hc.a > 0.0:
				c = hc
			if mask.get_pixel(x, y).a > 0.0:
				c = body.get_pixel(x, y)
			if c.a > 0.0 and not recolor.is_empty():
				var hx := c.to_html(false)
				if recolor.has(hx):
					c = recolor[hx]
			out.set_pixel(x, y, c)
	return out

## Devolve e esvazia as capturas feitas desde a última chamada.
func capture_take() -> Array:
	var out := captured
	captured = []
	return out

## Espelha a última captura (folhas que o gerador espelha depois de desenhar, ex. fighter_run).
func capture_flip_last() -> void:
	if captured.is_empty():
		return
	var c: Dictionary = captured[-1]
	for k in ["full", "body", "head", "mask", "band", "socks"]:
		if c.has(k):
			(c[k] as Image).flip_x()
	for k in ["heads", "tops", "symbols"]:
		if c.has(k):
			for kk in c[k]:
				if kk != "short":   # heads.short é a mesma imagem de c.head (já virada)
					(c[k][kk] as Image).flip_x()
	c.anchor["flipped"] = true

## Recorte de todas as camadas de uma captura (retrato 32x32). body/full ficam com quem chama (o fundo vai no body).
func capture_crop(c: Dictionary, r: Rect2i) -> Dictionary:
	var out := {"head": (c.head as Image).get_region(r), "mask": (c.mask as Image).get_region(r), "anchor": c.anchor}
	if c.has("heads"):
		var hs := {}
		for k in c.heads:
			hs[k] = out.head if k == "short" else (c.heads[k] as Image).get_region(r)
		out["heads"] = hs
		out["band"] = (c.band as Image).get_region(r)
		out["tops"] = {"tank": (c.tops.tank as Image).get_region(r), "tee": (c.tops.tee as Image).get_region(r)}
		out["socks"] = (c.socks as Image).get_region(r)
		if c.has("symbols"):
			out["symbols"] = {"chest": (c.symbols.chest as Image).get_region(r), "leg": (c.symbols.leg as Image).get_region(r)}
	return out

## Grava as camadas de UMA folha do discípulo (capturas na ordem dos quadros):
##   <dir><base><gsuf>_disc_body.png       (uma por luva)
##   <dir><base>_disc_head_short.png       (cabeça do corte atual; não depende da luva)
##   <dir><base>_disc_front.png            (máscara; não depende da luva)
## store guarda cabeça/máscara da 1ª luva para conferir que as outras luvas dão a mesma coisa (report recebe avisos).
## Confere também body+head+front == quadro inteiro. Devolve a meta da folha (âncoras por quadro).
func save_layer_sheet(caps: Array, dir: String, base: String, gsuf: String, store: Dictionary, report: Array) -> Dictionary:
	var bodies := []
	var heads := []
	var masks := []
	var anchors := []
	for i in caps.size():
		var c: Dictionary = caps[i]
		bodies.append(c.body)
		heads.append(c.head)
		masks.append(c.mask)
		anchors.append(c.anchor)
		var comp := compose_layers(c.body, c.head, c.mask)
		if comp.get_data() != (c.full as Image).get_data():
			report.append("AVISO camadas %s%s[%d]: body+head+front difere do quadro inteiro" % [base, gsuf, i])
	strip(bodies).save_png(dir + base + gsuf + "_disc_body.png")
	var hs := strip(heads)
	var ms := strip(masks)
	if not store.has(base):
		store[base] = {"head": hs, "mask": ms}
		hs.save_png(dir + base + "_disc_head_short.png")
		ms.save_png(dir + base + "_disc_front.png")
	else:
		if (store[base].head as Image).get_data() != hs.get_data():
			var hs0: Image = store[base].head
			var ex := ""
			for y in hs.get_height():
				for x in hs.get_width():
					if hs.get_pixel(x, y) != hs0.get_pixel(x, y) and ex.length() < 200:
						ex += " (%d,%d) %s/%s" % [x, y, hs0.get_pixel(x, y).to_html(), hs.get_pixel(x, y).to_html()]
			report.append("AVISO camadas %s%s: cabeça diferente da luva velha:%s" % [base, gsuf, ex])
		if (store[base].mask as Image).get_data() != ms.get_data():
			report.append("AVISO camadas %s%s: máscara diferente da luva velha" % [base, gsuf])
	# Fase 6b2: cortes, faixa, partes de cima e meião (um arquivo por opção, nunca por combinação; não dependem da luva)
	if (caps[0] as Dictionary).has("heads"):
		var extra := {}
		for cut in CUT_ORDER:
			if cut != "short":
				extra["head_" + cut] = strip(caps.map(func(c): return c.heads[cut]))
		extra["band"] = strip(caps.map(func(c): return c.band))
		extra["top_tank"] = strip(caps.map(func(c): return c.tops.tank))
		extra["top_tee"] = strip(caps.map(func(c): return c.tops.tee))
		extra["socks"] = strip(caps.map(func(c): return c.socks))
		if (caps[0] as Dictionary).has("symbols"):
			extra["symbol_chest"] = strip(caps.map(func(c): return c.symbols.chest))
			extra["symbol_leg"] = strip(caps.map(func(c): return c.symbols.leg))
		var sx: Dictionary = store[base]
		for k in extra:
			var im: Image = extra[k]
			if not sx.has(k):
				sx[k] = im
				im.save_png(dir + base + "_disc_" + k + ".png")
			elif (sx[k] as Image).get_data() != im.get_data():
				if (k as String).begins_with("symbol_") and gsuf != "":
					# 6c2: a luva da frente passa na frente do peito de jeito diferente (ex. fighter_run): arquivo próprio da luva
					im.save_png(dir + base + gsuf + "_disc_" + k + ".png")
					report.append("NOTA camadas %s%s: %s próprio da luva" % [base, gsuf, k])
				else:
					report.append("AVISO camadas %s%s: %s diferente da luva velha" % [base, gsuf, k])
		var bad := 0
		for c in caps:
			bad += int(c.get("check_px", 0))
		if bad > 0:
			report.append("NOTA camadas %s%s: visual cheio montado x desenhado difere em %d px no total (%d quadros)" % [base, gsuf, bad, caps.size()])
	var fw: int = (caps[0].body as Image).get_width()
	var fh: int = (caps[0].body as Image).get_height()
	var an := []
	for a in anchors:
		var d := {}
		for k in a:
			var v = a[k]
			d[k] = v
		an.append(d)
	return {"frame_size": [fw, fh], "frames": caps.size(), "anchors": an}

## O gerador pintou algo por cima do quadro inteiro depois (rastro do golpe): leva para a camada body.
func capture_sync_last(final: Image) -> void:
	if captured.is_empty():
		return
	var c: Dictionary = captured[-1]
	var A: Image = c.full
	var B: Image = c.body
	for y in final.get_height():
		for x in final.get_width():
			var f := final.get_pixel(x, y)
			if f != A.get_pixel(x, y):
				B.set_pixel(x, y, f)
				A.set_pixel(x, y, f)

# ================================================================ tela com mapa de partes
func canvas(w: int, h: int) -> void:
	cw = w
	ch = h
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	ids = PackedInt32Array()
	ids.resize(w * h)
	ids.fill(0)
	joints = []

func put(x: int, y: int, c, id: int) -> void:
	if x < 0 or y < 0 or x >= cw or y >= ch:
		return
	img.set_pixel(x, y, L.col(c))
	ids[y * cw + x] = id

func joint(a: int, b: int, p: Vector2, r: float) -> void:
	joints.append([a, b, p + HALF, r])

func _joint_ok(a: int, b: int, p: Vector2) -> bool:
	for j in joints:
		if (j[0] == a and j[1] == b) or (j[0] == b and j[1] == a):
			if (p - j[2]).length() <= j[3]:
				return true
	return false

func _ramp_of(c: Color) -> int:
	var hx := c.to_html(false)
	if L._lookup.has(hx):
		return L._lookup[hx][0]
	return -1

## Sombra de contato + contorno externo. Devolve a imagem final.
func finish() -> Image:
	var out: Image = img.duplicate()
	var ink: Color = L.col("ink")
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in ch:
		for x in cw:
			var a := ids[y * cw + x]
			if a == 0:
				continue
			for d in dirs:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qx < 0 or qy < 0 or qx >= cw or qy >= ch:
					continue
				var b := ids[qy * cw + qx]
				# só sombreia entre PARTES diferentes (a/10 diferentes = grupos diferentes, ou ids diferentes)
				if b > a and not _joint_ok(a, b, Vector2(x + 0.5, y + 0.5)):
					var ca := img.get_pixel(x, y)
					var cb := img.get_pixel(qx, qy)
					var steps := -2 if _ramp_of(ca) == _ramp_of(cb) else -1
					if ca != ink:
						out.set_pixel(x, y, L.shade(ca, steps))
					break
	var res: Image = out.duplicate()
	for y in ch:
		for x in cw:
			if ids[y * cw + x] != 0:
				continue
			for d in dirs:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qx >= 0 and qy >= 0 and qx < cw and qy < ch and ids[qy * cw + qx] != 0:
					res.set_pixel(x, y, ink)
					break
	return res

# ================================================================ primitivas
## Membro afunilado a->b (raios ra/rb), com volume (bulge) e trecho de pano (cloth) no começo (até cloth_t).
func limb(id: int, a: Vector2, b: Vector2, ra: float, rb: float, ramp: Array, o := {}) -> void:
	a += HALF
	b += HALF
	var d := b - a
	var ln := d.length()
	var dn := d / ln if ln > 0.001 else Vector2(0, 1)
	var n := Vector2(-dn.y, dn.x)
	if n.dot(LD) < 0.0:
		n = -n
	var nl := absf(n.dot(LD))
	var bul: float = o.get("bulge", 0.0)
	var bt: float = o.get("bulge_t", 0.4)
	var bw: float = o.get("bulge_w", 0.3)
	var bdir: Vector2 = o.get("bulge_dir", n)
	var bsign := 1.0 if bdir.dot(n) >= 0.0 else -1.0
	var cloth: Array = o.get("cloth", [])
	var cloth_t: float = o.get("cloth_t", -1.0)
	var cadd: float = o.get("cloth_add", 0.7)
	var hem: bool = o.get("hem", true)
	var cfrom: float = o.get("cloth_from", -1.0)   # 6b2 (meião): pano só de cfrom até o fim do membro
	var rm := maxf(ra, rb) + absf(bul) + cadd + 2.0
	for y in range(int(floor(minf(a.y, b.y) - rm)), int(ceil(maxf(a.y, b.y) + rm)) + 1):
		for x in range(int(floor(minf(a.x, b.x) - rm)), int(ceil(maxf(a.x, b.x) + rm)) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := (p - a).dot(dn) / ln if ln > 0.001 else 0.0
			var tc := clampf(t, 0.0, 1.0)
			var s := (p - a).dot(n)
			var r0 := lerpf(ra, rb, tc)
			var bump := bul * exp(-pow((tc - bt) / bw, 2.0))
			var is_cloth := cloth.size() > 0 and tc <= cloth_t and tc >= cfrom
			var add := cadd if is_cloth else 0.0
			var rpos := r0 + add + (bump if bsign > 0.0 else 0.0)
			var rneg := r0 + add + (bump if bsign < 0.0 else 0.0)
			var inside := false
			if t < 0.0:
				inside = (p - a).length() <= ra + add
			elif t > 1.0:
				inside = (p - b).length() <= rb + (add if is_cloth else 0.0)
			else:
				inside = s <= rpos and s >= -rneg
			if not inside:
				continue
			var rr := rpos if s >= 0.0 else rneg
			var u := s / maxf(rr, 0.5)
			var rp: Array = cloth if is_cloth else ramp
			var c = rp[1]
			var lv := u * (0.45 + nl)
			if lv < -0.40:
				c = rp[0]
			elif lv > 0.62 and rpos + rneg >= 4.5:
				c = rp[2]
			if is_cloth and hem and cloth_t < 0.999 and ln > 0.001 and (cloth_t - tc) * ln < 1.0:
				c = o.get("hem_c", rp[0])
			if is_cloth and o.has("stripe") and (tc - cfrom) * ln < 1.0:
				c = o.stripe                                   # listra no alto do meião
			put(x, y, c, id)

## Gira v por ang graus (positivo = horário na tela, y para baixo).
func rotv(v: Vector2, ang: float) -> Vector2:
	if is_zero_approx(fmod(ang, 360.0)):
		return v
	var r := deg_to_rad(ang)
	var c := cos(r)
	var s := sin(r)
	var x := v.x * c - v.y * s
	var y := v.x * s + v.y * c
	return Vector2(snappedf(x, 0.0001), snappedf(y, 0.0001))

## Mapa de pixels desenhado à mão. anchor = pixel do mapa que vai no ponto p.
## ang = rotação em graus (exata em múltiplos de 90), flip = espelho horizontal do mapa antes de girar.
func pmap(id: int, rows: Array, legend: Dictionary, p: Vector2, anchor: Vector2i, ang := 0.0, flip := false) -> void:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var ax := anchor.x
	if flip:
		ax = w - 1 - anchor.x
	var px := int(round(p.x))
	var py := int(round(p.y))
	if is_zero_approx(fmod(ang, 360.0)):
		for j in h:
			var r: String = rows[j]
			for i in w:
				var si := (w - 1 - i) if flip else i
				if si >= r.length():
					continue
				var k := r[si]
				if k == "." or not legend.has(k):
					continue
				put(px - ax + i, py - anchor.y + j, legend[k], id)
		return
	var rad := maxi(w, h) + 2
	for y in range(py - rad, py + rad + 1):
		for x in range(px - rad, px + rad + 1):
			var v := Vector2(x - px, y - py)
			var s := rotv(v, -ang)
			var i := int(round(s.x)) + ax
			var j := int(round(s.y)) + anchor.y
			if j < 0 or j >= h or i < 0 or i >= w:
				continue
			var r: String = rows[j]
			var si := (w - 1 - i) if flip else i
			if si < 0 or si >= r.length():
				continue
			var k := r[si]
			if k == "." or not legend.has(k):
				continue
			put(x, y, legend[k], id)

## IK de 2 ossos: devolve a junta do meio. prefer = para que lado a junta dobra.
func ik(a: Vector2, c: Vector2, l1: float, l2: float, prefer: Vector2, tag := "") -> Vector2:
	var d := c - a
	var dist := d.length()
	if dist > l1 + l2 + 0.05 and tag != "":
		log_lines.append("AVISO %s: alvo a %.1f px, membro alcança %.1f" % [tag, dist, l1 + l2])
	var dd := clampf(dist, absf(l1 - l2) + 0.01, l1 + l2 - 0.001)
	var dn := d.normalized() if dist > 0.001 else Vector2(0, 1)
	var ang := acos(clampf((l1 * l1 + dd * dd - l2 * l2) / (2.0 * l1 * dd), -1.0, 1.0))
	var e1 := a + dn.rotated(ang) * l1
	var e2 := a + dn.rotated(-ang) * l1
	return e1 if (e1 - a).dot(prefer) >= (e2 - a).dot(prefer) else e2

# ================================================================ mapas (dados de arte)
## Cabeça de perfil virada para a direita (luta). 14x14, âncora (7,7).
## H/h cabelo, S/s/l pele (sombra/base/luz), E orelha, e olho (ink), b sobrancelha, m boca, x pixel de expressão (ink)
const HEAD_SIDE := [
	"....HHHHHH....",
	"..HHHHhhHHHH..",
	".HHHHhhhhHHHH.",
	".HHHHHHHHHHHH.",
	"HHHHHHHsssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHHsssssssss.",
	"..HSssssssss..",
	"...SSssssmSs..",
	"....SSsssss...",
	".....SSSss....",
]
## Expressões = linhas trocadas no mapa de perfil.
const FACES_SIDE := {
	"normal": {},
	"pain": {5: "HHHHHHsbbssl..", 6: "HHHEEssxxssl..", 10: "..HSsssssxss..", 11: "...SSsssxxSs.."},
	"tired": {5: "HHHHHHsssbbl..", 6: "HHHEEssssesl..", 11: "...SSssssxSs..", 12: "....SSsssxs..."},
	"ko": {5: "HHHHHHsssssl..", 6: "HHHEEsssxxsl..", 11: "...SSssssxSs..", 12: "....SSsssxs..."},
	"joy": {4: "HHHHHHHsbbbl..", 5: "HHHHHHssssll..", 11: "...SSsssxxxs..", 12: "....SSssxxs..."},
}
## Cabeça 3/4 virada para a direita (garagem). 13x13, âncora (6,6).
const HEAD_34 := [
	"...HHHHHHH...",
	".HHHHhhhHHHH.",
	"HHHHhhhhhHHHH",
	"HHHHHHHHHHHHs",
	"HHHHsslllllll",
	"HHHSsbbsslbbl",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const FACES_34 := {
	"normal": {},
	"effort": {5: "HHHSsbbsslbbl", 10: "..Sssxxxxss..", 11: "...SSsssss..."},
}

## ---------------------------------------------------------------- 1º LUTADOR (Fase 6a)
## O lutador do jogador da Carreira 1 ganha rosto próprio: cabelo preto com topete (um tufo que sobe e avança sobre a
## testa e uma ponta na nuca) e esparadrapo branco acima da sobrancelha (P). Mesmo tamanho de cabeça; só uma linha a
## mais em cima (o tufo), por isso a âncora desce 1 px e o centro da cabeça fica no mesmo lugar de antes.
## Rostos novos da 6a: "bite" (morde o fecho da luva: sobrancelha baixa, boca aberta para a frente, dentes W) e
## "smile" (sorriso leve, de canto; diferente do "joy" da vitória).
const PRIMEIRO_HEAD_SIDE := [
	"........hHH...",
	"....HHHHHHHH..",
	"..HHHHhhHHHH..",
	".HHHHhhhhHHHH.",
	".HHHHHHHHHHHHH",
	"HHHHHHHssPPl..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	"HHHHsssssssss.",
	"..HSssssssss..",
	"...SSssssmSs..",
	"....SSsssss...",
	".....SSSss....",
]
const PRIMEIRO_FACES_SIDE := {
	"normal": {},
	"pain": {6: "HHHHHHsbbssl..", 7: "HHHEEssxxssl..", 11: "..HSsssssxss..", 12: "...SSsssxxSs.."},
	"tired": {6: "HHHHHHsssbbl..", 7: "HHHEEssssesl..", 12: "...SSssssxSs..", 13: "....SSsssxs..."},
	"ko": {6: "HHHHHHsssssl..", 7: "HHHEEsssxxsl..", 12: "...SSssssxSs..", 13: "....SSsssxs..."},
	"joy": {5: "HHHHHHHsbPPl..", 6: "HHHHHHssssll..", 12: "...SSsssxxxs..", 13: "....SSssxxs..."},
	"bite": {6: "HHHHHHsssbbl..", 7: "HHHEEssbbxsl..", 12: "...SSsssxWWx..", 13: "....SSsssxx..."},
	"smile": {7: "HHHEEssssxsl..", 12: "...SSsssssxs..", 13: "....SSssxxs..."},
}
const PRIMEIRO_HEAD_34 := [
	"......hHH....",
	"..HHHHHHHHHH.",
	".HHHHhhhHHHHH",
	"HHHHhhhhhHHHH",
	"HHHHHHHHHHHHH",
	"HHHHssllllPPl",
	"HHHSsbbsslbbl",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const PRIMEIRO_FACES_34 := {
	"normal": {},
	"effort": {6: "HHHSsbbsslbbl", 11: "..Sssxxxxss..", 12: "...SSsssss..."},
	"bite": {6: "HHHSsssssllll", 7: "HHESsbbsslbb.", 8: "HEsSsxsssxll.", 11: "..SsssxWWxs..", 12: "...SSsssxs..."},
	"smile": {11: "..Ssssmmmxs..", 10: ".HSsssssssxs."},
}

## Identidade de quem usa o corpo do jogador. "primeiro" = 1º lutador (Carreira 1); "disc" = discípulo padrão
## (Carreira 2+ até a personalização da 6b): troca de paleta fixa (cabelo castanho claro sem topete e sem
## esparadrapo, calção verde). Os geradores do jogador fazem P.build(identidade(quem) + luva).
func identidade(quem: String) -> Dictionary:
	if quem == "disc":
		if key_mode:   # Fase 6b1: discípulo em camadas, cores-chave (ver KEYS)
			# 6b2: top "none" no corpo; regata/camiseta/meião/faixa/cortes saem como camadas (ver _capture_call).
			# sleeve_add 0: a manga não engorda o braço (mesmo contorno com e sem camiseta -> uma máscara front só).
			return {"hair": ["k_h0", "k_h1"], "brow": "k_hb", "skin": ["k_sk0", "k_sk1", "k_sk2"],
				"shorts": ["k_sh0", "k_sh1", "k_sh2"], "band": "k_sh3", "top": "none",
				"shirt": ["k_tp0", "k_tp1", "k_tp2"], "sleeve_add": 0.0, "sleeve_t": 0.8, "tank_neck": 0.68, "sock_ramp": ["k_so0", "k_so1", "k_so2"],
				"disc_layers": true}
		return {"hair": ["br1", "br2"], "brow": "br0", "shorts": ["gr0", "gr1", "gr2"], "band": "gr3"}
	return {"hair": ["d1", "g0"], "brow": "ink", "head_side": PRIMEIRO_HEAD_SIDE, "head_34": PRIMEIRO_HEAD_34,
		"faces_side": PRIMEIRO_FACES_SIDE, "faces_34": PRIMEIRO_FACES_34,
		"head_anchor_side": Vector2i(7, 8), "head_anchor_34": Vector2i(6, 7),
		"head_legend_extra": {"P": "white", "W": "white"}}

## Boca (pixel da cabeça) do personagem numa vista, relativa ao centro da cabeça (hd).
func mouth_offset(b: Dictionary, view: String) -> Vector2:
	var rows: Array = b.head_side if view == "side" else b.head_34
	var an: Vector2i = b.head_anchor_side if view == "side" else b.head_anchor_34
	for j in rows.size():
		var r: String = rows[j]
		var i := r.find("m")
		if i >= 0:
			return Vector2(i - an.x, j - an.y)
	return Vector2(2, 4)

## Ponta do fecho da luva (Fase 6a): fita na cor do punho do estilo, do punho da luva até a boca (os dentes),
## desenhada por cima de tudo (gancho de pose "end"). n = quantos pixels de fita (2 = presa, 3 = esticada).
func strap_tip(b: Dictionary, mouth: Vector2, cuff: Vector2, n: int) -> void:
	var st: Dictionary = GLOVE_STYLES.get(b.glove, GLOVE_STYLES["old"])
	var d := cuff - mouth
	var steps := maxi(int(round(maxf(absf(d.x), absf(d.y)))), 1)
	var placed := 0
	var pts := []
	for k in range(steps + 1):
		var p := (mouth + d * (float(k) / float(steps))).round()
		if pts.is_empty() or pts[-1] != p:
			pts.append(p)
	# a fita sai da boca: os n primeiros pixels a partir do dente; o último (no punho) é a costura escura
	for p in pts:
		if placed >= n:
			break
		put(int(p.x), int(p.y), st.c if placed < n - 1 else st.g, NEAR_GLOVE_TOP + 5)
		placed += 1

## Luvas (5 orientações). D/M/L = r0/r1/r2 da luva (a troca de paleta continua valendo),
## c/g = punho (claro/escuro), t/T = fita de remendo (só a luva velha; nas outras vira detalhe do estilo).
const GLOVE_UP := [   # antebraço subindo (guarda): punho embaixo
	"..MMMMM...",
	".MMMMLLLM.",
	"MMMMMMMLLM",
	"MtTMMMMMLM",
	"MtTMMMMMMM",
	"DMMMMMMMMM",
	"DMMDDDMMMM",
	"DMMMMMDMMD",
	".DDMMMMDD.",
	".gccccccg.",
	".gggggggg.",
]
const GLOVE_DIAG := [  # antebraço subindo na diagonal para a frente
	"....MMMMM..",
	"...MMMMLLM.",
	"..MMMMMMLLM",
	".MtTMMMMMLM",
	".MtTMMMMMMM",
	"DMMMMMMMMMD",
	"DMMDDDMMMD.",
	"gDMMMMDMD..",
	"cgDDMMMD...",
	".cgDDDD....",
	"..cg.......",
]
const GLOVE_SIDE := [  # antebraço na horizontal para a frente: punho atrás, nós dos dedos à frente
	"...MMMMMM...",
	"..MMMMMLLLM.",
	"gcMMMMMMMLLM",
	"gcMtTMMMMMLM",
	"gcMtTMMMMMMM",
	"gcMMMDDMMMMD",
	"gcDMMMMDMMMD",
	"..DDMMMMMMD.",
	"....DDDDDD..",
]
const GLOVE_DIAGDOWN := [  # antebraço descendo na diagonal para a frente
	"..cg.......",
	".cgMMLL....",
	"cgMMMMLLM..",
	"gMMMMMMMLM.",
	"DMMMMMMMMLD",
	"DMMtTMMMMMD",
	".MMtTMMMMMD",
	".DMMMMDMMMD",
	"..DMMMMMMD.",
	"...DDMMMD..",
	"....DDDD...",
]
const GLOVE_DOWN := [  # braço caído: punho em cima, punho fechado embaixo
	".gggggggg.",
	".gccccccg.",
	".MMMMMLLM.",
	"MMMMMMMLLM",
	"DMtTMMMMLM",
	"DMtTMMMMMM",
	"DMMMMMMMMM",
	"DMMDDMMMMD",
	"DDMMMMMMMD",
	".DDMMMMDD.",
	"..DDDDDD..",
]
const GLOVES_MAPS := {"up": GLOVE_UP, "diag": GLOVE_DIAG, "side": GLOVE_SIDE, "diagdown": GLOVE_DIAGDOWN, "down": GLOVE_DOWN}
const GLOVE_ANCHOR := {"up": Vector2i(5, 5), "diag": Vector2i(5, 5), "side": Vector2i(6, 4), "diagdown": Vector2i(5, 5), "down": Vector2i(5, 5)}

## Estilos de luva (mesmas cores e detalhes da loja/cursor de make_sprites_fase3.gd).
const GLOVE_STYLES := {
	"old": {"c": "cream", "g": "g3"},
	"lona": {"c": "white", "g": "g3"},
	"couro": {"c": "cream", "g": "br3"},
	"marca": {"c": "white", "g": "g1"},
	"campeao": {"c": "white", "g": "g3"},   # L4: azul de competição, punho branco largo, friso dourado
	"tape": {"c": "g3", "g": "g2"},
	"worn": {"c": "g3", "g": "g2"},
	"tape_red": {"c": "g2", "g": "g1", "w": "r2"},   # Brutão: luva preta remendada com fita isolante vermelha
	"plain": {"c": "g3", "g": "g1"},
}

## Punho nu (ajudantes sem luva). S/s/l = pele sombra/base/luz. Âncora (2,2). "up" = nós dos dedos para cima,
## "side" = nós dos dedos para a frente (soco). Escolhido pela direção do antebraço como a luva.
const FIST_UP := [".sll.", "sslll", "Sssss", "SSsss", ".SSS."]
const FIST_SIDE := [".ssl.", "Sssll", "Ssssl", "SSsss", ".SSS."]
## Mão aberta (Fase 6b1: John sem luvas, discípulo chegando). Mesma legenda do punho. "down" = solta ao lado do corpo
## (dedos para baixo, um pouco curvos); "side" = esticada para a frente, dedos juntos; "diagdown" = apontando o chão à
## frente (mão espalmada); "up" = palma virada para o rosto, dedos abertos para cima (ele olha a própria mão).
const OPEN_MAPS := {
	"down": {"rows": [".sl.", "Ssll", "Sssl", "Ssss", "SsSs", ".S.S"], "anchor": Vector2i(2, 2)},
	"side": {"rows": ["sll...", "Sslll.", "SSsssl", ".SSSS."], "anchor": Vector2i(1, 1)},
	"diagdown": {"rows": ["sll..", "Sslll", ".Sssl", "..SSs", "...S."], "anchor": Vector2i(1, 1)},
	"up": {"rows": ["l.l..", "slsl.", "sssls", "Sssss", "SSsss", ".SSS."], "anchor": Vector2i(2, 3)},
}

## Tênis de perfil. toe = ponta do pé na sola (âncora); ankle = onde a canela encaixa.
const SHOE_FLAT := ["..DMM......", ".DMMMLw....", "DMMMMMMLLD.", "DMMMMMMMMMD", "ccccccccccc"]
const SHOE_BALL := [".DM........", ".DMMw......", "..DMMMLL...", "..DDMMMMLD.", "...ccDMMMMD", ".....cccccc"]
const SHOE_34 := ["..DMM....", ".DMMLw...", "DMMMMMLD.", "DMMMMMMMD", "ccccccccc"]
const SHOE_34_BALL := [".DM......", ".DMMw....", "..DMMML..", "..DMMMMD.", "...cDMMMD", ".....cccc"]
const SHOES := {
	"flat": {"rows": SHOE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
	"ball": {"rows": SHOE_BALL, "toe": Vector2i(10, 5), "ankle": Vector2i(2, 0), "ang": 0.0},
	"up": {"rows": SHOE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": -90.0},   # deitado, ponta para cima
	# 7a1: ajoelhado (montado no chão), peito do pé no chão e sola para cima, ponta para trás. O "toe" fica no canto de
	# cima, atrás; o tornozelo cai 7 px à frente e 4 abaixo dele.
	"kneel": {"rows": SHOE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": 180.0},
	"34": {"rows": SHOE_34, "toe": Vector2i(8, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
	"34ball": {"rows": SHOE_34_BALL, "toe": Vector2i(8, 5), "ankle": Vector2i(2, 0), "ang": 0.0},
}

## Fatias do tronco [t, costas(-), frente(+)] (t=0 quadril, t=1 base do pescoço) — corpo do lutador do jogador.
const SL_SIDE := [[-0.2, -5.4, 3.6], [-0.1, -6.2, 4.6], [0.08, -6.0, 4.8], [0.3, -4.8, 4.2], [0.55, -5.4, 5.6],
	[0.75, -6.2, 7.0], [0.9, -6.0, 6.2], [1.0, -5.0, 4.6], [1.07, -3.5, 2.6]]
const SL_34 := [[-0.16, -4.4, 4.8], [-0.04, -5.0, 5.4], [0.15, -4.9, 5.1], [0.32, -4.4, 4.8], [0.6, -5.8, 6.3],
	[0.82, -7.4, 7.6], [0.95, -7.2, 7.2], [1.02, -5.0, 5.2], [1.1, -2.6, 3.0]]

# ================================================================ personagem (parâmetros)
## build(o): devolve o dicionário completo do personagem. Chaves aceitas (todas opcionais):
##  medidas LUTA (perfil):  lu, lf (braço/antebraço até o centro da luva), lt, ls (coxa/canela),
##                          arm_r [ombro, cotovelo, cotovelo, punho], leg_r [quadril, joelho, joelho, tornozelo]
##  medidas GARAGEM (3/4):  glu, glf, glt, gls, g_arm_r, g_leg_r
##  silhueta:               shoulder (x largura do peito/ombro), hip_w (x largura do quadril), belly (px a mais
##                          na barriga), sl_side/sl_34 (fatias próprias, substitui as do jogador)
##  cabeça:                 head_side/head_34 (mapas próprios), faces_side, faces_34, head_anchor_side/_34,
##                          hair [escuro, claro], brow, skin [sombra, base, luz], stubble (cor), mustache (cor),
##                          headband (cor), cap [d, m, l]
##  roupa:                  top "tank"|"tshirt"|"none", shirt [sombra, base, luz], sleeve_t (0..1 do braço),
##                          bottom "shorts"|"pants", shorts [d, m, l], band (cós), shorts_t (0..1 da coxa),
##                          shoes [D, M, L, w, c] (sola = c), socks (cor da meia; "" = sem)
##                          sleeve_long (manga até o punho), trim (cor da gola/barra da manga), belt [d, m, l, fivela]
##                          (cinturão de pano na cintura), grease (manchas na roupa), shirt_detail "social"|"zip"
##                          (botões+colarinho / zíper do agasalho), shoe_maps {tipo: {rows, toe, ankle, ang}} (calçado
##                          próprio: chinelo, bota, tênis de cadarço solto)
##  luva:                   glove "old"|"lona"|"couro"|"marca"|"campeao"|"tape"|"worn"|"tape_red"|"plain"|"fist"(punho nu)|"none",
##                          glove_ramp [r0, r1, r2]
##  quimono (Fase 5, opcionais; ausentes = resultado idêntico aos anteriores): shirt_detail "gi" (lapela),
##                          neck_v (0..0,3: decote em V), sleeve_add / sleeve_add_fore (manga larga),
##                          pants_add (calça larga), pants_shin_t (0..1: barra da calça na canela)
##  cabeça extra:           head_legend_extra {letra: cor} (chaves livres nos mapas próprios; Q/q = capuz na cor da roupa)
## Ganchos de pose (adereços desenhados na ordem certa de profundidade): "after_torso", "after_near_leg", "end" =
##  Callable(lib, O, ctx) — ctx traz hip, top, dn, fr, hd, sf, sb, hf, hb, elf, elb (luta) ou equivalentes da garagem.
func build(o := {}) -> Dictionary:
	var b := {
		"lu": 12.0, "lf": 13.0, "lt": 17.5, "ls": 16.5,
		"arm_r": [3.0, 2.2, 2.4, 1.7], "leg_r": [4.2, 3.0, 2.7, 1.6],
		"glu": 10.0, "glf": 10.5, "glt": 14.2, "gls": 13.2,
		"g_arm_r": [2.6, 2.0, 2.4, 1.9], "g_leg_r": [3.6, 2.7, 2.5, 1.5],
		"shoulder": 1.0, "hip_w": 1.0, "belly": 0.0,
		"sl_side": SL_SIDE, "sl_34": SL_34,
		"head_side": HEAD_SIDE, "head_34": HEAD_34, "faces_side": FACES_SIDE, "faces_34": FACES_34,
		"head_anchor_side": Vector2i(7, 7), "head_anchor_34": Vector2i(6, 6),
		"hair": ["br0", "br1"], "brow": "br0", "skin": ["sk0", "sk1", "sk2"],
		"stubble": "", "mustache": "", "headband": "", "cap": [],
		"top": "tank", "shirt": ["g3", "cream", "white"], "sleeve_t": 0.45,
		"bottom": "shorts", "shorts": ["b0", "b1", "b2"], "band": "b2", "shorts_t": 0.42,
		"shoes": ["d1", "d2", "g1", "g3", "cream"], "socks": "",
		"glove": "old", "glove_ramp": ["r0", "r1", "r2"],
		"head_legend_extra": {}, "sleeve_long": false, "trim": "", "belt": [], "grease": false,
		"shirt_detail": "", "shoe_maps": {},
	}
	for k in o:
		b[k] = o[k]
	# rampas derivadas (lado de trás = um tom abaixo)
	var sk: Array = b.skin
	b["skin_far"] = [L.shade(L.col(sk[0]), -1), sk[0], sk[1]]
	var shr: Array = b.shorts
	b["shorts_far"] = [L.shade(L.col(shr[0]), -1), shr[0], shr[1]]
	var sh: Array = b.shirt
	b["shirt_far"] = [L.shade(L.col(sh[0]), -1), sh[0], sh[1]]
	var so: Array = b.shoes
	b["shoe_near"] = {"D": so[0], "M": so[1], "L": so[2], "w": so[3], "c": so[4]}
	b["shoe_far"] = {"D": so[0], "M": so[0], "L": so[1], "w": so[2], "c": L.shade(L.col(so[4]), -1)}
	b["sl_side_eff"] = _shape_slices(b.sl_side, b, false)
	b["sl_34_eff"] = _shape_slices(b.sl_34, b, true)
	b["_glove_cache"] = {}
	return b

func _shape_slices(sl: Array, b: Dictionary, sym: bool) -> Array:
	var out := []
	var shm: float = b.shoulder
	var hpm: float = b.hip_w
	var bel: float = b.belly
	for e in sl:
		var t: float = e[0]
		var m := lerpf(hpm, shm, smoothstep(0.3, 0.75, t))
		var bk: float = e[1] * m
		var fr: float = e[2] * m
		var bb := bel * exp(-pow((t - 0.3) / 0.2, 2.0))
		if sym:
			fr += bb * 0.7
			bk -= bb * 0.3
		else:
			fr += bb
		out.append([t, bk, fr])
	return out

# ---------------------------------------------------------------- legendas
func head_legend(b: Dictionary) -> Dictionary:
	var sk: Array = b.skin
	var hr: Array = b.hair
	var lg := {"H": hr[0], "h": hr[1], "S": sk[0], "s": sk[1], "l": sk[2], "e": "ink", "b": b.brow, "E": sk[0], "m": sk[0], "x": "ink",
		"B": b.headband if b.headband != "" else hr[0], "u": b.stubble if b.stubble != "" else sk[0],
		"o": b.mustache if b.mustache != "" else sk[1]}
	if (b.cap as Array).size() == 3:
		lg["C"] = b.cap[0]; lg["c"] = b.cap[1]; lg["k"] = b.cap[2]
	# capuz/gola atrás da nuca (Q/q = roupa sombra/base) e chaves livres do personagem
	lg["Q"] = b.shirt[0]
	lg["q"] = b.shirt[1]
	var ex: Dictionary = b.head_legend_extra
	for k in ex:
		lg[k] = ex[k]
	if b.get("disc_band", false):
		for k in BAND_LEGEND:
			lg[k] = BAND_LEGEND[k]
	return lg

## Linhas da cabeça com expressão + acessórios (faixa, barba, bigode).
func head_rows(b: Dictionary, view: String, face: String) -> Array:
	var base: Array = (b.head_side if view == "side" else b.head_34).duplicate()
	var faces: Dictionary = b.faces_side if view == "side" else b.faces_34
	var ov: Dictionary = faces.get(face, {})
	for k in ov:
		base[int(k)] = ov[k]
	if b.headband != "":
		var row := 3 if view == "side" else 3
		var r: String = base[row]
		var nr := ""
		for ch2 in r:
			nr += "B" if ch2 in ["H", "h", "s", "l", "S"] else ch2
		base[row] = nr
	if b.stubble != "":
		for j in range(base.size() - 4, base.size()):
			var r: String = base[j]
			var nr := ""
			for i in r.length():
				var c := r[i]
				nr += "u" if (c in ["s", "S"] and (i + j) % 2 == 0) else c
			base[j] = nr
	if b.mustache != "" and view == "side":
		var r: String = base[10]
		base[10] = r.substr(0, 9) + "oo" + r.substr(11)
	if b.get("disc_band", false):
		_band_rows(base, view, b.get("head_pad", Vector2i.ZERO))
	return base

## Faixa da 6b2 nas linhas de um mapa de cabeça (qualquer corte: usa o deslocamento do corte).
func _band_rows(rows: Array, view: String, pad: Vector2i) -> void:
	var bd: Dictionary = BAND[view]
	var r_lo: int = int(bd.rows[1])
	for rr in bd.rows:
		var j: int = int(rr) + pad.y
		var r: String = rows[j]
		var nr := ""
		for i in r.length():
			var c := r[i]
			if c != ".":
				c = "G" if (int(rr) == r_lo or i - pad.x < int(bd.back_cols)) else "F"
			nr += c
		rows[j] = nr
	for kn in bd.knot:
		var j: int = int(kn[1]) + pad.y
		var i: int = int(kn[0]) + pad.x
		var r: String = rows[j]
		if i < r.length() and r[i] != ".":
			rows[j] = r.substr(0, i) + "G" + r.substr(i + 1)

## Mapas, rostos e âncoras de um corte (Fase 6b2), para pôr no build por cima do mapa-base.
func cut_opts(cut: String) -> Dictionary:
	var d: Dictionary = DISC_CUTS[cut]
	var px: int = int(d.pad[0])
	var py: int = int(d.pad[1])
	return {"head_34": d["34"], "head_side": d["side"],
		"faces_34": _cut_faces(HEAD_34, FACES_34, d["34"], px, py),
		"faces_side": _cut_faces(HEAD_SIDE, FACES_SIDE, d["side"], px, py),
		"head_anchor_34": Vector2i(6 + px, 6 + py), "head_anchor_side": Vector2i(7 + px, 7 + py),
		"head_pad": Vector2i(px, py)}

## Expressões do mapa-base aplicadas a outro corte: só os pixels que a expressão muda (rosto), nunca o cabelo.
func _cut_faces(base: Array, faces: Dictionary, rows: Array, px: int, py: int) -> Dictionary:
	var out := {}
	for f in faces:
		var ov := {}
		var src: Dictionary = faces[f]
		for k in src:
			var j := int(k)
			var br: String = base[j]
			var fr: String = src[k]
			var r: String = rows[j + py]
			var nr := ""
			for i in r.length():
				var c := r[i]
				var bi := i - px
				if bi >= 0 and bi < fr.length() and bi < br.length() and fr[bi] != br[bi]:
					c = fr[bi]
				nr += c
			ov[j + py] = nr
		out[f] = ov
	return out

func glove_legend(style: String, ramp: Array, far: bool) -> Dictionary:
	var st: Dictionary = GLOVE_STYLES.get(style, GLOVE_STYLES["old"])
	var lg := {"D": ramp[0], "M": ramp[1], "L": ramp[2], "c": st.c, "g": st.g, "t": "g3", "T": "cream",
		"s": "cream", "y": "y1", "w": st.get("w", "white"), "Q": ramp[0]}
	if far:
		lg["L"] = ramp[1]
		for k in ["c", "g", "t", "T", "s", "y", "w"]:
			lg[k] = L.shade(L.col(lg[k]), -1)
	return lg

## Linhas da luva já com o detalhe do estilo (fita, trama de lona, costura, listra da marca).
func glove_rows(kind: String, style: String) -> Array:
	var src: Array = GLOVES_MAPS[kind]
	var out := []
	var h := src.size()
	var w := 0
	for r in src:
		w = maxi(w, (r as String).length())
	for j in h:
		var r: String = src[j]
		var nr := ""
		for i in r.length():
			var c := r[i]
			if style != "old" and c in ["t", "T"]:
				c = "M"
			var body := c in ["M", "L"]
			match style:
				"lona":
					if body and j % 3 == 1 and (i + j) % 3 == 0:
						c = "Q"
				"couro":
					if body and i == w - 4 and j % 2 == 0 and j > 0:
						c = "s"
				"marca":
					if body and (i + j == (w + h) / 2 - 1 or i + j == (w + h) / 2):
						c = "y"
				"campeao":   # L4 (Fase 5.2): friso dourado entre o corpo e o punho branco + selo dourado no lugar da fita
					var orig := r[i]
					if orig in ["t", "T"]:
						c = "y"
					elif c in ["M", "L", "D"] and _touches_cuff(src, i, j):
						c = "y"
				"tape":
					if body and (j == 3 or j == 4):
						c = "w"
				"tape_red":   # duas tiras de fita, uma torta, sem cobrir a luva inteira
					if body and ((j == 3 and i > 1 and i < w - 2) or (j == 4 and i > 2 and i < w - 3) or (i + j == w - 1 and j > 4 and j < h - 3)):
						c = "w"
			nr += c
		out.append(nr)
	return out

## Pixel (i,j) do mapa encosta (4-vizinhos) no punho da luva (c/g)?
func _touches_cuff(src: Array, i: int, j: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var x: int = i + d.x
		var y: int = j + d.y
		if y < 0 or y >= src.size():
			continue
		var r: String = src[y]
		if x >= 0 and x < r.length() and r[x] in ["c", "g"]:
			return true
	return false

## Escolhe a orientação da luva pela direção do antebraço (cotovelo -> mão). Devolve [tipo, espelho].
func glove_kind(el: Vector2, hand: Vector2) -> Array:
	var d := hand - el
	var a := rad_to_deg(atan2(-d.y, d.x))
	var flip := false
	if a > 90.0 or a < -90.0:
		flip = true
		a = 180.0 - a if a > 0.0 else -180.0 - a
	if a > 62.0:
		return ["up", flip]
	if a > 24.0:
		return ["diag", flip]
	if a > -24.0:
		return ["side", flip]
	if a > -62.0:
		return ["diagdown", flip]
	return ["down", flip]

func draw_glove(id: int, b: Dictionary, el: Vector2, hand: Vector2, far: bool, force := "") -> String:
	if b.glove == "none":
		return "none"
	var kf := glove_kind(el, hand)
	var k: String = kf[0]
	var flip: bool = kf[1]
	if force != "":
		var parts := force.split(":")
		k = parts[0]
		flip = parts.size() > 1 and parts[1] == "f"
	if b.glove == "fist":
		var sk: Array = b.skin_far if far else b.skin
		var fk := "side" if k in ["side", "diagdown", "diag"] else "up"
		pmap(id, FIST_SIDE if fk == "side" else FIST_UP, {"S": sk[0], "s": sk[1], "l": sk[2]}, hand, Vector2i(2, 2), 0.0, flip)
		return "fist_" + fk + (":f" if flip else "")
	if b.glove == "open":
		var sk2: Array = b.skin_far if far else b.skin
		var ok: String = {"up": "up", "diag": "up", "side": "side", "diagdown": "diagdown", "down": "down"}[k]
		var om: Dictionary = OPEN_MAPS[ok]
		pmap(id, om.rows, {"S": sk2[0], "s": sk2[1], "l": sk2[2]}, hand, om.anchor, 0.0, flip)
		return "open_" + ok + (":f" if flip else "")
	var key := "%s|%s" % [k, b.glove]
	var cache: Dictionary = b._glove_cache
	if not cache.has(key):
		cache[key] = glove_rows(k, b.glove)
	pmap(id, cache[key], glove_legend(b.glove, b.glove_ramp, far), hand, GLOVE_ANCHOR[k], 0.0, flip)
	return k + (":f" if flip else "")

## Mão com estilo próprio no quadro (Fase 6b1): "" = a luva do personagem; "fist" = punho nu; "open" = mão aberta;
## "none" = sem mão (escondida). Mão nua usa a pele de perto (senão a mão fica mais escura que o próprio antebraço).
func draw_hand(id: int, b: Dictionary, el: Vector2, hand: Vector2, far: bool, force: String, style: String) -> String:
	if style == "":
		return draw_glove(id, b, el, hand, far, force)
	if style == "none":
		return "none"
	var keep: String = b.glove
	b.glove = style
	var r := draw_glove(id, b, el, hand, false, force)
	b.glove = keep
	return r

## Luva SOLTA (sem mão dentro) como adereço da pose: kind = orientação do mapa (up/diag/side/diagdown/down).
func loose_glove(id: int, b: Dictionary, kind: String, center: Vector2, flip := false, far := false, style := "") -> void:
	var st: String = style if style != "" else (b.glove if GLOVE_STYLES.has(b.glove) else "old")
	var ramp: Array = b.glove_ramp
	pmap(id, glove_rows(kind, st), glove_legend(st, ramp, far), center, GLOVE_ANCHOR[kind], 0.0, flip)

## Cadarço (1 px) de a até b.
func lace(id: int, a: Vector2, b2: Vector2, c := "cream") -> void:
	var d := b2 - a
	var n := maxi(int(ceil(maxf(absf(d.x), absf(d.y)))), 1)
	for k in range(n + 1):
		var p := (a + d * (float(k) / float(n))).round()
		put(int(p.x), int(p.y), c, id)

## Luva solta (para ícones/testes): imagem com contorno.
func glove_image(b: Dictionary, kind: String, far := false) -> Image:
	canvas(16, 16)
	pmap(1, glove_rows(kind, b.glove), glove_legend(b.glove, b.glove_ramp, far), Vector2(8, 8), GLOVE_ANCHOR[kind])
	return finish()

# ================================================================ peças do corpo
## Braço: ombro -> (IK) cotovelo -> punho; o antebraço termina embaixo do punho da luva.
func arm(b: Dictionary, id_up: int, sh: Vector2, hand: Vector2, lu: float, lf: float, far: bool, tag: String, prefer: Vector2, r: Array, elbow = null) -> Vector2:
	var el: Vector2 = elbow if elbow != null else ik(sh, hand, lu, lf, prefer, tag)
	var ramp: Array = b.skin_far if far else b.skin
	var wr := el + (hand - el).normalized() * maxf((hand - el).length() - 3.5, 1.0)
	var o := {"bulge": 0.9, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(0, -1)}
	if b.top == "tshirt":
		o["cloth"] = b.shirt_far if far else b.shirt
		o["cloth_t"] = 1.0 if b.sleeve_long else b.sleeve_t
		o["cloth_add"] = b.get("sleeve_add", 0.6)   # manga larga (quimono); padrão 0,6 = todos os anteriores
		o["hem"] = not b.sleeve_long
		if b.trim != "":
			o["hem_c"] = b.trim
	limb(id_up, sh, el, r[0], r[1], ramp, o)
	var long_sleeve: bool = b.top == "tshirt" and b.sleeve_long
	# Manga comprida (moletom): o pano não afina como o pulso e entra inteiro no punho da luva. Sem isso a
	# ponta do antebraço (pele, 1-2 px mais fina) aparecia entre a manga e o punho e a sombra de contato
	# desenhava uma linha escura ali: a luva parecia descolada da manga (QA fase 4, O3).
	var rw: float = maxf(r[3], r[2] * 0.95) if long_sleeve else r[3]
	limb(id_up + 1, el, wr, r[2], rw, ramp, forearm_opts(b, far))
	joint(id_up, id_up + 1, el, 3.2)
	if long_sleeve:
		# manga e punho da luva se encostam sem sombra de contato (o punho já tem a borda escura dele)
		joint(id_up + 1, id_up + 2, wr, 4.5)
		if far:
			joint(id_up + 1, FAR_GLOVE_FRONT, wr, 4.5)
	return el

## Antebraço: pele, ou manga comprida até o punho da luva (inclusive a ponta arredondada).
func forearm_opts(b: Dictionary, far: bool) -> Dictionary:
	var o := {"bulge": 0.5, "bulge_t": 0.2, "bulge_w": 0.3}
	if b.top == "tshirt" and b.sleeve_long:
		o = {"bulge": 0.3, "bulge_t": 0.3, "bulge_w": 0.3, "cloth": b.shirt_far if far else b.shirt, "cloth_t": 1.0, "cloth_add": b.get("sleeve_add_fore", 0.5)}
	return o

## Perna: quadril -> (IK) joelho -> tornozelo do tênis. Tênis ancorado pela ponta (não escorrega).
func leg(b: Dictionary, id_th: int, hip: Vector2, toe: Vector2, shoe: String, lt: float, ls: float, far: bool, tag: String, r: Array, kp: Vector2, ang_add := 0.0) -> Vector2:
	var sm: Dictionary = b.shoe_maps
	var sd: Dictionary = sm[shoe] if sm.has(shoe) else SHOES[shoe]
	var tv: Vector2i = sd.toe
	var av: Vector2i = sd.ankle
	var ang: float = float(sd.ang) + ang_add   # 7b1: "angf"/"angb" giram o pé (chute com o peito do pé esticado)
	var ankle := toe + rotv(Vector2(av - tv), ang)
	var knee := ik(hip, ankle, lt, ls, kp, tag)
	var skin: Array = b.skin_far if far else b.skin
	var cl: Array = b.shorts_far if far else b.shorts
	var pants: bool = b.bottom == "pants"
	limb(id_th, hip, knee, r[0], r[1], skin, {"bulge": 0.7, "bulge_t": 0.45, "bulge_w": 0.3, "bulge_dir": Vector2(1, 0),
		"cloth": cl, "cloth_t": 1.0 if pants else float(b.shorts_t), "cloth_add": b.get("pants_add", 0.6)})
	# Fase 6c2: símbolo da escola na coxa da frente, só sobre o calção (sem parte de cima)
	if b.get("school_symbol", "") == "leg" and (id_th == G_LEG_L or id_th == NEAR_THIGH) and not pants:
		var pc := (hip + HALF).lerp(knee + HALF, SYMBOL_LEG_T)
		var cen: Vector2i = SYMBOL.leg.center
		var o := Vector2i(int(floor(pc.x)) - cen.x, int(floor(pc.y)) - cen.y)
		var cloth := {}
		for cn in cl:
			cloth[(L.col(cn) as Color).to_html(false)] = true
		for yy in range(o.y, o.y + 5):
			for xx in range(o.x, o.x + 3):
				if xx < 0 or yy < 0 or xx >= cw or yy >= ch or ids[yy * cw + xx] != id_th:
					continue
				if not cloth.has(img.get_pixel(xx, yy).to_html(false)):
					continue
				var lc = _symbol_px("leg", o, xx, yy)
				if lc != null:
					put(xx, yy, lc, id_th)
	var down := rotv(Vector2(0, 1), ang)
	var so := {"bulge": 1.1, "bulge_t": 0.3, "bulge_w": 0.25, "bulge_dir": Vector2(-1, 0)}
	if pants:
		# pants_shin_t < 1 = barra acima do tornozelo (calça de quimono); padrão 1,0 e 0,6 = todos os anteriores
		so = {"cloth": cl, "cloth_t": b.get("pants_shin_t", 1.0), "cloth_add": b.get("pants_add", 0.6)}
	elif b.socks != "":
		so["cloth"] = [L.shade(L.col(b.socks), -1), b.socks, b.socks]
		so["cloth_t"] = 2.0
	elif b.get("sock_on", false):
		# 6b2: meião do discípulo (cores-chave k_so*), da canela até o tênis, sem engordar a perna
		var sr: Array = b.sock_ramp
		so["cloth"] = [sr[0], sr[0], sr[1]] if far else [sr[0], sr[1], sr[1]]
		so["cloth_t"] = 2.0
		so["cloth_from"] = SOCK_FROM
		so["cloth_add"] = 0.0
		so["stripe"] = sr[2]
	limb(id_th + 1, knee, ankle + down, r[2], r[3], skin, so)
	if b.socks != "" and not pants:
		pass
	pmap(id_th + 2, sd.rows, b.shoe_far if far else b.shoe_near, toe, tv, ang)
	joint(id_th, id_th + 1, knee, 3.6)
	return knee

func _interp_slices(sl: Array, t: float) -> Vector2:
	for i in range(sl.size() - 1):
		var a: Array = sl[i]
		var c: Array = sl[i + 1]
		if t >= a[0] and t <= c[0]:
			var k: float = (t - a[0]) / maxf(c[0] - a[0], 0.0001)
			return Vector2(lerpf(a[1], c[1], k), lerpf(a[2], c[2], k))
	return Vector2(sl[0][1], sl[0][2])

## Tronco por fatias ao longo do eixo quadril->topo (qualquer ângulo). view = "side" | "34".
## A "frente" é sempre o eixo girado 90° no sentido horário (em pé virado à direita = direita; deitado de
## costas com a cabeça à esquerda = para cima).
func torso(b: Dictionary, id: int, hip: Vector2, top: Vector2, view: String, tw := 0.0) -> void:
	var sl: Array = b.sl_side_eff if view == "side" else b.sl_34_eff
	hip += HALF
	top += HALF
	var d := top - hip
	var ln := d.length()
	var dn := d / ln
	var fr := Vector2(-dn.y, dn.x)
	var t0: float = sl[0][0]
	var t1: float = sl[sl.size() - 1][0]
	var ext := 14.0
	var p0 := hip + d * t0
	var p1 := hip + d * t1
	var bx0 := int(floor(minf(p0.x, p1.x) - ext))
	var bx1 := int(ceil(maxf(p0.x, p1.x) + ext))
	var by0 := int(floor(minf(p0.y, p1.y) - ext))
	var by1 := int(ceil(maxf(p0.y, p1.y) + ext))
	var waist := 0.24
	var shirt: Array = b.shirt
	var skn: Array = b.skin
	var sho: Array = b.shorts
	var top_kind: String = b.top
	var sym_o := _symbol_origin(b, hip, d, fr, sl, view, tw)
	var sym_v := "side" if view == "side" else "34"
	for y in range(by0, by1 + 1):
		for x in range(bx0, bx1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := (p - hip).dot(dn) / ln
			if t < t0 or t > t1:
				continue
			var s := (p - hip).dot(fr)
			var bf := _interp_slices(sl, t)
			var k := smoothstep(0.45, 0.9, t)
			var back := bf.x
			var front := bf.y
			if view == "side":
				front += tw * k
				back -= tw * 0.5 * k
			else:
				back += tw * 1.5 * k
				front += tw * 0.5 * k
			if s < back or s > front:
				continue
			var db := s - back
			var df := front - s
			var c
			if t < waist:
				c = sho[1]
				if db < 2.0:
					c = sho[0]
				elif df < 1.2:
					c = sho[2]
				if view == "34" and absf(s - 0.5) < 0.6 and t < waist - 0.12:
					c = sho[0]
			elif t < waist + 0.05:
				c = b.band
				if db < 1.5:
					c = sho[1]
			else:
				var skin := false
				if top_kind == "none":
					skin = true
				elif view == "side":
					if top_kind == "tank":
						skin = (t > 0.83 and df < 4.5) or t > 0.98
					else:
						skin = (t > 0.93 and df < 3.0) or t > 1.0
						var nv: float = b.get("neck_v", 0.0)   # decote em V (quimono aberto no peito); 0 = todos os anteriores
						if nv > 0.0 and t > 1.0 - nv and df < (t - (1.0 - nv)) / nv * 4.0:
							skin = true
				else:
					var mid := (back + front) * 0.5 + 0.8
					if top_kind == "tank":
						skin = (t > float(b.get("tank_neck", 0.84)) and absf(s - mid) < 3.0) or t > 1.0 or (t > 0.74 and (db < 2.2 or df < 2.2))   # tank_neck: decote (6b2: discípulo mais fundo)
					else:
						skin = (t > 0.92 and absf(s - mid) < 2.4) or t > 1.02
				if skin:
					c = skn[1]
					if db < 1.6:
						c = skn[0]
					elif df < 1.4 or (top_kind == "none" and t > 0.55 and t < 0.8 and df < 3.0):
						c = skn[2]
					if top_kind == "none" and t > 0.5 and t < 0.54 and df < 4.0:
						c = skn[0]                                  # linha do peitoral
				else:
					# regata/camiseta: sombra nas costas, base creme, luz no peito (nada de bloco branco)
					c = shirt[1]
					if db < 2.4:
						c = shirt[0]
					elif view == "side" and df < 3.2 and t > 0.55 and t < 0.86:
						c = shirt[2]                                # peito pegando luz
					elif view == "34" and s > mid_34(back, front) and t > 0.55 and t < 0.84 and df > 1.5:
						c = shirt[2]
					if view == "side" and t > 0.5 and t < 0.555 and df < 3.5:
						c = shirt[0]                                # dobra embaixo do peito
					if view == "side" and t > 0.32 and t < 0.5 and absf(df - 2.5) < 0.5:
						c = shirt[0]                                # vinco lateral
					if view == "34" and t > 0.57 and t < 0.6 and s > 1.5 and s < front - 1.5:
						c = shirt[0]
					if t < waist + 0.1 and fmod(s + 20.0, 3.0) < 1.0 and top_kind == "tank":
						c = shirt[0]                                # regata franzida no cós
					elif t < waist + 0.1 and fmod(s + 20.0, 3.0) < 1.0 and b.belt.is_empty():
						c = shirt[0]
					c = _shirt_detail(b, view, t, s, back, front, db, df, c)
					# Fase 6c2: símbolo da escola no peito liso da parte de cima
					if sym_o.x != -999 and t > waist + 0.12:
						var sc_ = _symbol_px(sym_v, sym_o, x, y)
						if sc_ != null:
							c = sc_
			if not (b.belt as Array).is_empty() and t > waist - 0.05 and t < waist + 0.12:
				c = _belt_px(b, view, t, s, back, front, db, df, waist)
			put(x, y, c, id)

## Detalhes da roupa por cima da cor base (gola colorida, botões, zíper, manchas de graxa).
func _shirt_detail(b: Dictionary, view: String, t: float, s: float, back: float, front: float, db: float, df: float, c):
	var shirt: Array = b.shirt
	var mid := mid_34(back, front)
	if b.trim != "":
		if view == "side" and t > 0.9 and t < 0.97 and df < 4.0:
			return b.trim
		if view == "34" and t > 0.9 and t < 0.96 and absf(s - mid) < 3.4:
			return b.trim
	match b.shirt_detail:
		"social":   # carcela com botões + colarinho
			if view == "34":
				if absf(s - (mid - 0.5)) < 0.55 and t > 0.3 and t < 0.92:
					return shirt[0] if int(t * 40.0) % 3 != 0 else "g3"
				if t > 0.9 and absf(s - mid) < 3.6 and absf(s - mid) > 1.6:
					return shirt[2]
			elif df < 1.0 and t > 0.3 and t < 0.9 and int(t * 40.0) % 3 == 0:
				return "g3"
		"zip":      # agasalho: zíper claro no meio, gola alta
			if view == "34" and absf(s - (mid - 0.5)) < 0.55 and t > 0.28:
				return "g3"
			if view == "side" and df < 1.0 and t > 0.28:
				return "g3"
		"gi":       # quimono (perfil): lapela grossa descendo da nuca até a faixa, na frente do peito
			if view == "side":
				var nv: float = b.get("neck_v", 0.0)
				var t_top := 1.0 - nv
				var w := front - back
				# a lapela acompanha a borda do decote e depois desce em diagonal até a faixa
				var lt := clampf((t - 0.27) / maxf(t_top - 0.27, 0.01), 0.0, 1.0)
				var edge := lerpf(w * 0.42, 0.0, lt) if t <= t_top else (t - t_top) / maxf(nv, 0.01) * 4.0
				var dd := df - edge
				if t > 0.27 and dd >= 0.0 and dd < 1.0:
					return shirt[2]                      # borda da lapela pegando luz
				if t > 0.27 and dd >= 1.0 and dd < 2.6:
					return shirt[1] if dd < 2.0 else shirt[0]   # espessura da lapela e a sombra que ela faz
				if t > 0.27 and dd < 0.0 and t < t_top:
					return shirt[1]                      # aba de dentro (cruzada)
	if b.grease:
		# manchas fixas no corpo (coordenadas do tronco, não da tela: acompanham a pose)
		for sp in [[0.62, 0.35, 1.3], [0.44, 0.7, 0.9], [0.75, -0.2, 0.8], [0.36, 0.1, 0.7]]:
			var ss := lerpf(back, front, sp[1])
			if absf(t - sp[0]) * 26.0 < sp[2] and absf(s - ss) < sp[2]:
				return L.shade(L.col(shirt[0]), -1)
	return c

## Cinturão de pano (vermelho, fivela dourada torta) — o mesmo do ícone do cinturão.
func _belt_px(b: Dictionary, view: String, t: float, s: float, back: float, front: float, db: float, df: float, waist: float):
	var bl: Array = b.belt
	var u := (t - (waist - 0.05)) / 0.17
	var c = bl[1]
	if u > 0.78:
		c = bl[2]
	elif u < 0.2:
		c = bl[0]
	if db < 1.2:
		c = bl[0]
	var buckle := false
	if view == "side":
		buckle = df < 4.0 and u > 0.05 and u < 1.0
	else:
		var mid := mid_34(back, front)
		buckle = absf(s - (mid + 0.5)) < 2.6 and u > 0.0 and u < 1.05
	if buckle:
		c = bl[3]
		if u < 0.3 or (view == "34" and absf(s - (mid_34(back, front) + 0.5)) > 1.9):
			c = L.shade(L.col(bl[3]), -1)
	return c

func mid_34(back: float, front: float) -> float:
	return (back + front) * 0.5 + 0.8

# ================================================================ LUTA (perfil)
## Pose de luta (todas as posições relativas ao pivô = entre os pés, na sola):
##  hip, top (ou lean em graus + torso_len), head (opcional), hrot (graus, opcional), face, tw (giro),
##  sf/sb (ombros, opcionais), hf/hb (centros das luvas, obrigatórios), ef/eb (cotovelo forçado, opcional),
##  pf/pb (lado para onde o cotovelo dobra), toef/toeb + shoef/shoeb ("flat"|"ball"|"up"),
##  kf/kb (lado para onde o joelho dobra), gkf/gkb (orientação forçada da luva, ex. "side:f"),
##  far_glove_front (luva de trás desenhada na frente da cabeça — defesa).
func fight_frame(b: Dictionary, p: Dictionary, tag: String, size := Vector2i(112, 104), pivot := Vector2(56, 98)) -> Image:
	if capture and not _cap_busy:
		return _capture_call(func() -> Image: return fight_frame(b, p, tag, size, pivot), b)
	canvas(size.x, size.y)
	var O := pivot
	var hip: Vector2 = O + p.hip
	var top: Vector2
	if p.has("top"):
		top = O + p.top
	else:
		var tl: float = p.get("torso_len", 24.0)
		var lr := deg_to_rad(float(p.get("lean", 0.0)))
		top = hip + Vector2(sin(lr), -cos(lr)) * tl
	var dn := (top - hip).normalized()
	var fr := Vector2(-dn.y, dn.x)
	var nh := hip + fr * 1.5 - dn * 1.0
	var fh := hip - fr * 1.5 - dn * 1.0
	var sf: Vector2 = (O + p.sf) if p.has("sf") else top + fr * 2.0 - dn * 3.0
	var sb: Vector2 = (O + p.sb) if p.has("sb") else top - fr * 2.0 - dn * 2.0
	var hd: Vector2 = (O + p.head) if p.has("head") else top + fr * 3.0 + dn * 10.0
	var hrot: float = p.get("hrot", rad_to_deg(atan2(dn.x, -dn.y)) if p.get("hrot_auto", false) else 0.0)
	var lu: float = b.lu
	var lf: float = b.lf
	var lt: float = b.lt
	var ls: float = b.ls
	var kp_def := fr * 1.0 - dn * 0.1
	# 7b1: "legs_swap" = chute com a perna de trás. O quadril girou: a perna de trás (toeb) sai do quadril da FRENTE e é
	# desenhada na frente (cores da frente); a de apoio (toef) fica no quadril de trás, atrás do corpo.
	var swap: bool = bool(p.get("legs_swap", false))
	if swap:
		leg(b, FAR_THIGH, fh, O + p.get("toef", Vector2(15, -1)), p.get("shoef", "flat"), lt, ls, true, tag + " perna de apoio", b.leg_r, p.get("kf", kp_def), float(p.get("angf", 0.0)))
	else:
		leg(b, FAR_THIGH, fh, O + p.get("toeb", Vector2(-3, -1)), p.get("shoeb", "flat"), lt, ls, true, tag + " perna de trás", b.leg_r, p.get("kb", kp_def), float(p.get("angb", 0.0)))
	var hb: Vector2 = O + p.hb
	var pdef := -fr * 0.35 - dn * 1.0
	var elb := arm(b, FAR_UP, sb, hb, lu, lf, true, tag + " braço de trás", p.get("pb", pdef), b.arm_r, (O + p.eb) if p.has("eb") else null)
	var gkb := draw_glove(FAR_GLOVE_FRONT if p.get("far_glove_front", false) else FAR_GLOVE, b, elb, hb, true, p.get("gkb", ""))
	torso(b, TORSO, hip, top, "side", p.get("tw", 0.0))
	limb(TORSO, top - dn * 1.0, hd + rotv(Vector2(-1, 4), hrot), 2.6, 2.4, b.skin)   # pescoço (mesma peça do tronco)
	if not skip_head:
		pmap(HEAD, head_rows(b, "side", p.get("face", "normal")), head_legend(b), hd, b.head_anchor_side, hrot)
	last_anchor = {"view": "side", "head": [hd.x - O.x, hd.y - O.y], "head_rot": hrot, "hip": [hip.x - O.x, hip.y - O.y],
		"top": [top.x - O.x, top.y - O.y], "tw": p.get("tw", 0.0), "face": p.get("face", "normal")}
	var ctx := {"hip": hip, "top": top, "dn": dn, "fr": fr, "hd": hd, "sf": sf, "sb": sb, "hb": hb, "elb": elb, "nh": nh, "fh": fh, "hrot": hrot}
	_hook(p, "after_torso", O, ctx)
	if swap:
		leg(b, NEAR_THIGH, nh, O + p.get("toeb", Vector2(-3, -1)), p.get("shoeb", "flat"), lt, ls, false, tag + " perna que chuta", b.leg_r, p.get("kb", kp_def), float(p.get("angb", 0.0)))
	else:
		leg(b, NEAR_THIGH, nh, O + p.get("toef", Vector2(15, -1)), p.get("shoef", "flat"), lt, ls, false, tag + " perna da frente", b.leg_r, p.get("kf", kp_def), float(p.get("angf", 0.0)))
	_hook(p, "after_near_leg", O, ctx)
	var hf: Vector2 = O + p.hf
	var elf := arm(b, NEAR_UP, sf, hf, lu, lf, false, tag + " braço da frente", p.get("pf", pdef), b.arm_r, (O + p.ef) if p.has("ef") else null)
	var gkf := draw_glove(NEAR_GLOVE, b, elf, hf, false, p.get("gkf", ""))
	ctx["hf"] = hf
	ctx["elf"] = elf
	_hook(p, "end", O, ctx)
	joint(TORSO, NEAR_UP, sf, 4.5)
	joint(TORSO, FAR_UP, sb, 4.5)
	joint(TORSO, NEAR_THIGH, nh, 5.5)
	joint(TORSO, FAR_THIGH, fh, 5.5)
	var im := finish()
	log_lines.append("%s: luvas frente '%s' trás '%s'; braço frente %.1f+%.1f, trás %.1f+%.1f" % [tag, gkf, gkb,
		(elf - sf).length(), (hf - elf).length(), (elb - sb).length(), (hb - elb).length()])
	return im

# ================================================================ GARAGEM (3/4)
## Pose da garagem (relativa ao pivô): hip, top, head, face, sl/sr (ombros esq./dir. da tela),
##  hl/hr (centros das luvas), el/er (cotovelos autorais, opcionais: escorço), fs (escala do braço direito
##  quando ele vai para dentro da cena), toel/toer + shoel/shoer ("34"|"34ball"), gkl/gkr, tw.
## Lado ESQUERDO da tela = mão de trás (mais escura); DIREITO = mão da frente (a que soca o saco).
func garage_frame(b: Dictionary, p: Dictionary, tag: String, size := Vector2i(48, 72), pivot := Vector2(22, 67)) -> Image:
	if capture and not _cap_busy:
		return _capture_call(func() -> Image: return garage_frame(b, p, tag, size, pivot), b)
	canvas(size.x, size.y)
	var O := pivot
	var hip: Vector2 = O + p.hip
	var top: Vector2 = O + p.top
	var hl := hip + Vector2(-3, 0)
	var hr := hip + Vector2(3, 0)
	var shl: Vector2 = O + p.sl
	var shr: Vector2 = O + p.sr
	var hdl: Vector2 = O + p.hl
	var hdr: Vector2 = O + p.hr
	var fs: float = p.get("fs", 1.0)
	var glu: float = b.glu
	var glf: float = b.glf
	var ar: Array = b.g_arm_r
	var lr: Array = b.g_leg_r
	var skin: Array = b.skin
	# braço direito: parte de cima atrás do tronco
	var elr: Vector2 = (O + p.er) if p.has("er") else ik(shr, hdr, glu * fs, glf * fs, p.get("pr", Vector2(0.3, 1.0)), tag + " braço direito")
	var o_up := {"bulge": 0.8, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(1, -1)}
	if b.top == "tshirt":
		o_up["cloth"] = b.shirt
		o_up["cloth_t"] = 1.0 if b.sleeve_long else b.sleeve_t
		o_up["cloth_add"] = b.get("sleeve_add", 0.7)
		if b.trim != "":
			o_up["hem_c"] = b.trim
	limb(FAR_UP, shr, elr, ar[0], ar[1], skin, o_up)
	# pernas
	leg(b, FAR_THIGH, hr, O + p.get("toer", Vector2(10, 0)), p.get("shoer", "34"), b.glt, b.gls, false, tag + " perna direita", lr, p.get("kr", Vector2(0.6, 0)), float(p.get("angr", 0.0)))
	leg(b, G_LEG_L, hl, O + p.get("toel", Vector2(-1, 0)), p.get("shoel", "34"), b.glt, b.gls, false, tag + " perna esquerda", lr, p.get("kl", Vector2(0.5, 0)), float(p.get("angl", 0.0)))
	torso(b, TORSO, hip, top, "34", p.get("tw", 0.0))
	var hd: Vector2 = O + p.head
	limb(TORSO, top + Vector2(0, 1), hd + Vector2(0, 4), 2.3, 2.2, skin)
	if not skip_head:
		pmap(HEAD, head_rows(b, "34", p.get("face", "normal")), head_legend(b), hd, b.head_anchor_34)
	last_anchor = {"view": "34", "head": [hd.x - O.x, hd.y - O.y], "head_rot": 0.0, "hip": [hip.x - O.x, hip.y - O.y],
		"top": [top.x - O.x, top.y - O.y], "tw": p.get("tw", 0.0), "face": p.get("face", "normal")}
	var gctx := {"hip": hip, "top": top, "hd": hd, "sl": shl, "sr": shr, "hl": hdl, "hr": hdr, "elr": elr}
	_hook(p, "after_torso", O, gctx)
	# braço esquerdo por cima do tronco
	var ell: Vector2 = (O + p.el) if p.has("el") else ik(shl, hdl, glu, glf, p.get("pl", Vector2(-0.3, 1.0)), tag + " braço esquerdo")
	var o_ul := {"bulge": 0.8, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(-1, -1)}
	if b.top == "tshirt":
		o_ul["cloth"] = b.shirt
		o_ul["cloth_t"] = 1.0 if b.sleeve_long else b.sleeve_t
		o_ul["cloth_add"] = b.get("sleeve_add", 0.7)
		if b.trim != "":
			o_ul["hem_c"] = b.trim
	limb(NEAR_UP, shl, ell, ar[0], ar[1], skin, o_ul)
	var wl := ell + (hdl - ell).normalized() * maxf((hdl - ell).length() - 3.5, 1.0)
	limb(NEAR_FORE, ell, wl, ar[2], ar[3], skin, _g_fore(b))
	var gkl := draw_hand(NEAR_GLOVE, b, ell, hdl, true, p.get("gkl", "up"), p.get("stl", ""))
	_hook(p, "after_left", O, gctx)
	# antebraço + luva direitos na frente
	var wr := elr + (hdr - elr).normalized() * maxf((hdr - elr).length() - 3.5, 1.0)
	limb(NEAR_GLOVE_TOP, elr, wr, ar[2], ar[3], skin, _g_fore(b))
	var gkr := draw_hand(NEAR_GLOVE_TOP + 1, b, elr, hdr, false, p.get("gkr", "up"), p.get("str", ""))
	gctx["ell"] = ell
	_hook(p, "end", O, gctx)
	joint(TORSO, NEAR_UP, shl, 4.0)
	joint(TORSO, FAR_UP, shr, 4.0)
	joint(NEAR_UP, NEAR_FORE, ell, 2.6)
	joint(FAR_UP, NEAR_GLOVE_TOP, elr, 2.6)
	joint(TORSO, G_LEG_L, hl, 5.0)
	joint(TORSO, FAR_THIGH, hr, 5.0)
	var im := finish()
	log_lines.append("%s: luvas esq '%s' dir '%s'; braço dir. %.1f+%.1f (fs %.2f), esq. %.1f+%.1f" % [tag, gkl, gkr,
		(elr - shr).length(), (hdr - elr).length(), fs, (ell - shl).length(), (hdl - ell).length()])
	return im

func _g_fore(b: Dictionary) -> Dictionary:
	if b.top == "tshirt" and b.sleeve_long:
		return {"bulge": 0.3, "bulge_t": 0.3, "bulge_w": 0.3, "cloth": b.shirt, "cloth_t": 0.88, "cloth_add": 0.5}
	return {"bulge": 0.4, "bulge_t": 0.2, "bulge_w": 0.3}

func _hook(p: Dictionary, name: String, O: Vector2, ctx: Dictionary) -> void:
	if p.has(name):
		(p[name] as Callable).call(self, O, ctx)

# ================================================================ utilidades de imagem
func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func load_png(path: String) -> Image:
	var im := Image.load_from_file(path)
	im.convert(Image.FORMAT_RGBA8)
	return im

func frames_of(path: String, fw: int) -> Array:
	var s := load_png(path)
	var out := []
	for i in s.get_width() / fw:
		out.append(s.get_region(Rect2i(i * fw, 0, fw, s.get_height())))
	return out

func scaled(im: Image, k: int) -> Image:
	var b: Image = im.duplicate()
	b.resize(im.get_width() * k, im.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func paste(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))
