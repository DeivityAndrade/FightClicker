extends RefCounted
## Regras ESTRITAS do verificador (fase Identidade, ID1). Rodam sempre e são anotadas em `achados`, mas só viram
## problema (e fazem o verificador sair com código 1) com a flag `--estrito`. Modo padrão: não quebra os outros fluxos.
##
## Regras (código = o que aparece na linha do relatório):
##   IGNORE_SEM_MOTIVO  ui_align=ignore (ou ui_align_row=free) sem `ui_align_motivo` (use UiTema.ignorar(no, motivo)).
##   IGNORE_PROIBIDO    ignore em Button, em Label de texto fixo, ou num contêiner que engole um Button/Label de texto fixo.
##                      Texto que muda em tempo de jogo: UiTema.ignorar(no, motivo, true) (meta ui_texto_dinamico).
##   TXT_SOZINHO        Label sem declaração, alinhado à esquerda, sozinho na linha, com margem esquerda != direita no pai.
##   JANELA_ASSIM       janela (Panel/NinePatch >= 160x80, filha da tela cheia) fora do centro de 640x360 (topo=base se declarada).
##   JANELA_MARGEM      conteúdo da janela com margem esquerda != direita (mesmo sem `ui_margens`).
##   OPACO_FORA         Sprite2D/Node2D ou nó ignorado, opaco (alfa >= 0,9), saindo de 640x360. Isenção: `ui_align_motivo` no nó ou ancestral.
##   DRAW_TEXTO         texto desenhado por código (UiTema.desenhar_texto_centro) com centro diferente do centro da área.
##   TXT_COLADO         (R1) texto de cartão (qualquer ui_card/c_cartao, com ou sem ui_indent) a menos de FOLGA_BORDA px da borda interna
##                      do cartão ou a menos de FOLGA_BOTAO px de um botão vizinho; rótulo com autowrap sem FOLGA_BORDA de sobra na largura.
##   TXT_NA_MOLDURA     (R2) texto sobre moldura (NinePatchRect ou carimbo) que não cabe na área interna (moldura menos margens do 9-slice).
##   TXT_CONTRASTE      (R3) texto habilitado com contraste < 4,5:1 contra a cor média do fundo logo atrás (estilo/textura/ColorRect).
## Placar: todo `ignore` visto é contado em `placar` (meta do estúdio: no máximo 15 no fim da fase).

const BASE := Vector2(640, 360)
const TOL := 1.0
const CODIGOS := ["IGNORE_SEM_MOTIVO", "IGNORE_PROIBIDO", "TXT_SOZINHO", "JANELA_ASSIM", "JANELA_MARGEM", "OPACO_FORA", "DRAW_TEXTO",
	"TXT_COLADO", "TXT_NA_MOLDURA", "TXT_CONTRASTE"]
const FOLGA_BORDA := 4.0  # px entre o texto e a borda interna do cartão (depois das margens do 9-slice)
const FOLGA_BOTAO := 2.0  # px entre o texto e um botão vizinho
const CONTRASTE_MIN := 4.5

var a  # o ui_audit (SceneTree)
var estrito := false
var achados := {}  # chave -> {codigo, arquivo, caminho, estado, n, detalhe}
var placar := {}  # chave -> {arquivo, caminho, motivo, classe}
var _cena: Node = null
var _medias := {}  # cache: textura+margens -> cor média


func _init(audit) -> void:
	a = audit


## Roda as regras estritas sobre a árvore atual.
func auditar(raiz: Node, estado: String) -> void:
	_cena = raiz
	_varrer(raiz, false, estado)
	var lista: Array[Control] = []
	a._coletar(raiz, lista)
	for n in lista:
		_regra_txt_sozinho(n, estado)
		_regra_janela(n, estado)
		if n is Label and n.text != "":
			_regra_cartao(n, estado)
			_regra_contraste(n, estado)
		elif n is NinePatchRect or n is Panel:
			_regra_moldura(n, estado)


# ---------------------------------------------------------------------------------------------
# Varredura de tudo (inclusive o que está sob ignore e Node2D)
# ---------------------------------------------------------------------------------------------

func _varrer(n: Node, sob_ignore: bool, estado: String) -> void:
	if n is CanvasItem and not n.visible:
		return
	var ign := n.has_meta("ui_align") and str(n.get_meta("ui_align")) == "ignore"
	if ign:
		_regra_ignore(n, estado)
	if str(n.get_meta("ui_align_row", "")) == "free" and str(n.get_meta("ui_align_motivo", "")).strip_edges() == "":
		_achado("IGNORE_SEM_MOTIVO", n, estado, "ui_align_row=free sem motivo escrito")
	if n.has_meta("ui_texto_desenhado"):
		_regra_draw(n, estado)
	_regra_opaco(n, sob_ignore or ign, estado)
	for c in n.get_children():
		_varrer(c, sob_ignore or ign, estado)


func _regra_ignore(n: Node, estado: String) -> void:
	var motivo := str(n.get_meta("ui_align_motivo", "")).strip_edges()
	var chave := _arquivo(n) + "|" + _caminho(n)
	if not placar.has(chave):
		placar[chave] = {"arquivo": _arquivo(n), "caminho": _caminho(n), "motivo": motivo, "classe": n.get_class()}
	if motivo == "":
		_achado("IGNORE_SEM_MOTIVO", n, estado, "ignore sem motivo escrito (ui_align_motivo)")
	var ofensores: Array[String] = []
	if n is Button:
		ofensores.append("o próprio Button")
	elif n is Label and n.text != "" and not _dinamico(n, n):
		ofensores.append('o próprio Label "%s"' % n.text.left(16))
	for b in n.find_children("*", "Button", true, false):
		if b.is_visible_in_tree():
			ofensores.append('Button "%s"' % a._texto_botao(b).left(16))
	for l in n.find_children("*", "Label", true, false):
		if l.is_visible_in_tree() and l.text != "" and not _dinamico(l, n):
			ofensores.append('Label "%s"' % l.text.replace("\n", " ").left(16))
	if not ofensores.is_empty():
		_achado("IGNORE_PROIBIDO", n, estado, "ignore engole %d botão/texto fixo: %s" % [ofensores.size(), ", ".join(ofensores.slice(0, 3))])


## O Label (ou um ancestral até o nó ignorado) declarou que o texto muda em tempo de jogo?
func _dinamico(l: Node, ate: Node) -> bool:
	var p := l
	while p != null:
		if bool(p.get_meta("ui_texto_dinamico", false)):
			return true
		if p == ate:
			break
		p = p.get_parent()
	return false


func _regra_opaco(n: Node, sob_ignore: bool, estado: String) -> void:
	var r := Rect2()
	if n is Sprite2D:
		if n.texture == null:
			return
		r = n.get_global_transform() * n.get_rect()
	elif n is Control and sob_ignore and (n is ColorRect or n is TextureRect or n is Panel or n is NinePatchRect):
		r = a._rect(n)  # Controls fora de ignore já são cobertos por OFFSCREEN
	else:
		return
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	if _alfa(n) < 0.9 or _isento(n) or _recortado_por_pai(n):
		return
	if r.position.x < -0.5 or r.position.y < -0.5 or r.end.x > BASE.x + 0.5 or r.end.y > BASE.y + 0.5:
		_achado("OPACO_FORA", n, estado, "opaco sai de 640x360: %s" % a._fmt(r))


func _alfa(n: Node) -> float:
	var v := 1.0
	var p := n
	while p != null:
		if p is CanvasItem:
			v *= p.modulate.a * p.self_modulate.a
			if p is ColorRect:
				v *= p.color.a
		p = p.get_parent()
	return v


func _isento(n: Node) -> bool:
	var p := n
	while p != null:
		if str(p.get_meta("ui_align_motivo", "")).strip_edges() != "":
			return true
		p = p.get_parent()
	return false


func _recortado_por_pai(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is Control and p.clip_contents:
			return true
		p = p.get_parent()
	return false


func _regra_draw(n: Node, estado: String) -> void:
	var reg: Dictionary = n.get_meta("ui_texto_desenhado")
	for k in reg:
		var e: Dictionary = reg[k]
		var area: Rect2 = e.area
		var centro: float = float(e.x0) + float(e.lw) * float(e.escala) / 2.0
		var d := centro - area.get_center().x
		if absf(d) > TOL + 0.01:
			_achado("DRAW_TEXTO", n, estado, 'texto desenhado "%s" com centro x=%.1f, esperado %.1f (Δ=%.1fpx)' % [str(e.texto).left(16), centro, area.get_center().x, d])


# ---------------------------------------------------------------------------------------------
# Texto e janelas (só nós visíveis e não ignorados)
# ---------------------------------------------------------------------------------------------

func _regra_txt_sozinho(n: Control, estado: String) -> void:
	if not (n is Label) or n.text == "" or n.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT:
		return
	if n.has_meta("ui_align") or n.has_meta("ui_pos"):
		return
	var p := n.get_parent()
	if not (p is Control) or p is Button or p.size.x >= BASE.x:
		return
	var vr: Rect2 = a._rect_texto(n)
	for o in p.get_children():
		if o == n or not (o is Control) or not o.visible:
			continue
		if o is Button or o is TextureRect or (o is Label and o.text != ""):
			var vo: Rect2 = a._visual(o)
			if vo.position.y < vr.end.y and vo.end.y > vr.position.y:
				return  # não está sozinho na linha
	var pr: Rect2 = a._rect(p)
	var esq := vr.position.x - pr.position.x
	var dir := pr.end.x - vr.end.x
	if absf(esq - dir) > TOL + 0.01:
		_achado("TXT_SOZINHO", n, estado, "sozinho na linha: margem esquerda %.1f, direita %.1f (Δ=%.1fpx)" % [esq, dir, esq - dir])


func _regra_janela(n: Control, estado: String) -> void:
	if not (n is NinePatchRect or n is Panel) or n.size.x < 160.0 or n.size.y < 80.0:
		return
	var r: Rect2 = a._rect(n)
	var p := n.get_parent()
	# Janela de verdade: filha direta da tela cheia, menor que ela. Margens da tela simétricas.
	if p is Control and p.size.x >= BASE.x - 0.5 and p.size.y >= BASE.y - 0.5 and (r.size.x < BASE.x - 0.5 or r.size.y < BASE.y - 0.5):
		var esq := r.position.x
		var dir := BASE.x - r.end.x
		if r.size.x < BASE.x - 0.5 and absf(esq - dir) > TOL + 0.01:
			_achado("JANELA_ASSIM", n, estado, "margem da tela: esquerda %.1f, direita %.1f (Δ=%.1fpx)" % [esq, dir, esq - dir])
		var m1: String = a._modo(n, "ui_pos")
		var m2: String = a._modo(n)
		if (m1 in ["center", "center_v"] or m2 in ["center", "center_v"]) and r.size.y < BASE.y - 0.5:
			var topo := r.position.y
			var base := BASE.y - r.end.y
			if absf(topo - base) > TOL + 0.01:
				_achado("JANELA_ASSIM", n, estado, "margem da tela: topo %.1f, base %.1f (Δ=%.1fpx)" % [topo, base, topo - base])
	# Conteúdo com margens internas simétricas (quando já declarou ui_margens, a regra MARGIN_ASYM cuida).
	if a._modo(n, "ui_margens") != "":
		return
	var us: Array[Rect2] = []
	if n.get_child_count() > 0 and not (n is NinePatchRect or n is Panel):
		a._unidades(n, us, r)
	else:
		var todos: Array[Rect2] = []
		if p is Control:
			a._unidades(p, todos, Rect2())
		for u in todos:
			if r.encloses(u) and not u.is_equal_approx(r):
				us.append(u)
	if us.is_empty():
		return
	var uni: Rect2 = a._uniao(us)
	var e2 := uni.position.x - r.position.x
	var d2 := r.end.x - uni.end.x
	if absf(e2 - d2) > TOL + 0.01:
		_achado("JANELA_MARGEM", n, estado, "conteúdo: margem esquerda %.1f, direita %.1f (Δ=%.1fpx)" % [e2, d2, e2 - d2])


# ---------------------------------------------------------------------------------------------
# R1: folga do texto dentro do cartão
# ---------------------------------------------------------------------------------------------

## Margens (esq, topo, dir, base) do 9-slice de um Panel/NinePatchRect, ou null se não tiver textura.
func _margens(n: Control) -> Variant:
	if n is NinePatchRect:
		return Vector4(n.patch_margin_left, n.patch_margin_top, n.patch_margin_right, n.patch_margin_bottom)
	if n is Panel:
		var sb := n.get_theme_stylebox("panel")
		if sb is StyleBoxTexture:
			return Vector4(sb.texture_margin_left, sb.texture_margin_top, sb.texture_margin_right, sb.texture_margin_bottom)
	return null


func _textura_de(n: Control) -> Texture2D:
	if n is NinePatchRect:
		return n.texture
	if n is Panel:
		var sb := n.get_theme_stylebox("panel")
		if sb is StyleBoxTexture:
			return sb.texture
	return null


func _nome_textura(n: Control) -> String:
	var t := _textura_de(n)
	return t.resource_path.get_file().get_basename() if t != null else ""


func _eh_cartao(n: Node) -> bool:
	if not (n is Control):
		return false
	if bool(n.get_meta("ui_card", false)):
		return true
	var nome := _nome_textura(n)
	return nome.begins_with("ui_card") or nome.begins_with("c_cartao")


func _eh_carimbo(n: Node) -> bool:
	return n is Control and _nome_textura(n).begins_with("c_carimbo")


## Cartão que contém o texto: o próprio pai (ou ancestral) ou um irmão-fundo (Panel/NinePatch) de algum ancestral.
func _cartao_de(l: Label, centro: Vector2) -> Control:
	var filho: Node = l
	var p := l.get_parent()
	while p != null and p is Control:
		if _eh_cartao(p) and a._rect(p).has_point(centro):
			return p
		for c in p.get_children():
			if c != filho and c is Control and c.visible and _eh_cartao(c) and a._rect(c).has_point(centro) and c.size.x < BASE.x:
				return c
		if p.size.x >= BASE.x - 0.5 and p.size.y >= BASE.y - 0.5:
			break
		filho = p
		p = p.get_parent()
	return null


func _dentro_de_botao(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is Button:
			return true
		p = p.get_parent()
	return false


func _modo_centro(l: Label) -> bool:
	return a._modo(l) in ["center", "center_h"]


func _regra_cartao(l: Label, estado: String) -> void:
	if _modo_centro(l) or _dentro_de_botao(l):
		return
	var vr: Rect2 = a._rect_texto(l)
	var cartao := _cartao_de(l, vr.get_center())
	if cartao == null:
		return
	var cr: Rect2 = a._rect(cartao)
	var m = _margens(cartao)
	var ml := 0.0
	var mr := 0.0
	if m != null:
		ml = m.x
		mr = m.z
	var esq := vr.position.x - (cr.position.x + ml)
	var dir := (cr.end.x - mr) - vr.end.x
	if esq < FOLGA_BORDA - 0.01 or dir < FOLGA_BORDA - 0.01:
		_achado("TXT_COLADO", l, estado, "folga até a borda interna do cartão: esquerda %.1f, direita %.1f (mínimo %.0f)" % [esq, dir, FOLGA_BORDA])
	# Rótulo com autowrap: a largura tem de passar a do texto em FOLGA_BORDA, senão qualquer dígito a mais quebra a linha.
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
		var larg := 0.0
		for w in a._larguras(l):
			larg = maxf(larg, w)
		if larg > l.size.x - FOLGA_BORDA + 0.01:
			_achado("TXT_COLADO", l, estado, "autowrap: texto %.0fpx num rótulo de %.0fpx (falta folga de %.0fpx; um caractere a mais quebra)" % [larg, l.size.x, FOLGA_BORDA])
	# Botão vizinho dentro do cartão.
	for b in cartao.get_parent().find_children("*", "Button", true, false):
		if not b.is_visible_in_tree() or b.is_ancestor_of(l):
			continue
		var br: Rect2 = a._rect(b)
		if not cr.intersects(br) or br.has_point(vr.get_center()):
			continue  # fora do cartão, ou texto sobre o botão (decoração)
		var gx := maxf(br.position.x - vr.end.x, vr.position.x - br.end.x)
		var gy := maxf(br.position.y - vr.end.y, vr.position.y - br.end.y)
		if maxf(gx, gy) < FOLGA_BOTAO - 0.01:
			_achado("TXT_COLADO", l, estado, 'a %.1fpx do botão "%s" (mínimo %.0f)' % [maxf(gx, gy), a._texto_botao(b).left(14), FOLGA_BOTAO])
			break


# ---------------------------------------------------------------------------------------------
# R2: texto dentro da moldura
# ---------------------------------------------------------------------------------------------

func _regra_moldura(n: Control, estado: String) -> void:
	var m = _margens(n)
	if m == null or not (n is NinePatchRect or _eh_carimbo(n)):
		return
	var r: Rect2 = a._rect(n)
	if r.size.x >= BASE.x - 0.5 and r.size.y >= BASE.y - 0.5:
		return
	var interna := Rect2(r.position + Vector2(m.x, m.y), r.size - Vector2(m.x + m.z, m.y + m.w))
	var candidatos: Array[Node] = []
	candidatos.append_array(n.get_children())
	if n.get_parent() != null:
		candidatos.append_array(n.get_parent().get_children())
	for c in candidatos:
		if not (c is Label) or not c.visible or c.text == "" or a._ignorado(c) or c.get_parent() is Button:
			continue
		var vr: Rect2 = a._rect_texto(c)
		if not r.has_point(vr.get_center()):
			continue
		if vr.position.x < interna.position.x - 0.01 or vr.end.x > interna.end.x + 0.01 \
				or vr.position.y < interna.position.y - 0.01 or vr.end.y > interna.end.y + 0.01:
			_achado("TXT_NA_MOLDURA", c, estado, "texto %s fora da área interna %s da moldura (margens %d/%d/%d/%d)" % [
				a._fmt(vr), a._fmt(interna), m.x, m.y, m.z, m.w])


# ---------------------------------------------------------------------------------------------
# R3: contraste
# ---------------------------------------------------------------------------------------------

func _regra_contraste(l: Label, estado: String) -> void:
	if _desabilitado(l):
		return
	var fg: Color = l.get_theme_color("font_color")
	var alfa := fg.a
	var p: Node = l
	while p != null:
		if p is CanvasItem:
			alfa *= p.modulate.a
		p = p.get_parent()
	if alfa < 0.5:
		return  # texto aparecendo/apagando
	var vr: Rect2 = a._rect_texto(l)
	var bg = _cor_fundo(l, vr.get_center())
	if bg == null:
		return  # sem fundo conhecido: sem veredito
	fg.a = 1.0
	var cr := _contraste(fg, bg)
	if cr < CONTRASTE_MIN - 0.005:
		_achado("TXT_CONTRASTE", l, estado, "contraste %.2f:1 (mínimo %.1f): texto #%s sobre fundo #%s" % [cr, CONTRASTE_MIN, fg.to_html(false), (bg as Color).to_html(false)])


func _desabilitado(l: Node) -> bool:
	var p := l
	while p != null:
		if p is BaseButton and p.disabled:
			return true
		if bool(p.get_meta("ui_desabilitado", false)):
			return true
		p = p.get_parent()
	return false


func _luz(c: Color) -> float:
	var v: Array[float] = []
	for x in [c.r, c.g, c.b]:
		v.append(x / 12.92 if x <= 0.03928 else pow((x + 0.055) / 1.055, 2.4))
	return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]


func _contraste(c1: Color, c2: Color) -> float:
	var l1 := _luz(c1)
	var l2 := _luz(c2)
	return (maxf(l1, l2) + 0.05) / (minf(l1, l2) + 0.05)


## Cor de fundo logo atrás do texto: o que foi desenhado antes dele (irmãos anteriores, depois o pai, subindo a árvore).
## Devolve null quando não dá para saber (melhor esforço, sem captura).
func _cor_fundo(l: Label, centro: Vector2) -> Variant:
	var filho: Node = l
	var p := l.get_parent()
	while p != null and p is Control:
		for i in range(filho.get_index() - 1, -1, -1):
			var c = _cor_de(p.get_child(i), centro, 0)
			if c != null:
				return c
		var cp = _cor_de_proprio(p, centro)
		if cp != null:
			return cp
		filho = p
		p = p.get_parent()
	return null


func _cor_de(n: Node, centro: Vector2, prof: int) -> Variant:
	if not (n is Control) or not n.visible or prof > 3 or not a._rect(n).has_point(centro):
		return null
	if a._modo(n) == "ignore":
		return null
	var c = _cor_de_proprio(n, centro)
	if c != null:
		return c
	if n is Label or n is Button:
		return null
	for i in range(n.get_child_count() - 1, -1, -1):
		c = _cor_de(n.get_child(i), centro, prof + 1)
		if c != null:
			return c
	return null


func _cor_de_proprio(n: Node, centro: Vector2) -> Variant:
	if not (n is Control) or not a._rect(n).has_point(centro):
		return null
	var c = null
	if n is ColorRect:
		c = n.color
	elif n is NinePatchRect:
		c = _media(n.texture, Rect2i(n.region_rect), _margens(n))
	elif n is TextureRect:
		c = _media(n.texture, Rect2i(), null)
	elif n is Panel:
		c = _de_estilo(n.get_theme_stylebox("panel"))
	elif n is Button:
		c = _de_estilo(n.get_theme_stylebox("normal"))
	if c != null:
		var cc: Color = c
		if cc.a < 0.5:
			return null
		cc.a = 1.0
		return cc
	return null


func _de_estilo(sb: StyleBox) -> Variant:
	if sb is StyleBoxFlat:
		return sb.bg_color if sb.bg_color.a >= 0.5 else null
	if sb is StyleBoxTexture:
		var m := Vector4(sb.texture_margin_left, sb.texture_margin_top, sb.texture_margin_right, sb.texture_margin_bottom)
		return _media(sb.texture, Rect2i(sb.region_rect), m)
	return null


## Cor média dos pixels opacos do miolo da textura (sem as margens do 9-slice).
func _media(tex: Texture2D, regiao: Rect2i, m: Variant) -> Variant:
	if tex == null:
		return null
	var chave := "%s|%s|%s" % [tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id()), regiao, m]
	if _medias.has(chave):
		return _medias[chave]
	var img := tex.get_image()
	var r = null
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var area := Rect2i(Vector2i.ZERO, img.get_size())
		if regiao.size.x > 0 and regiao.size.y > 0:
			area = area.intersection(regiao)
		var miolo := area
		if m != null:
			miolo = Rect2i(area.position + Vector2i(int(m.x), int(m.y)), area.size - Vector2i(int(m.x + m.z), int(m.y + m.w)))
			if miolo.size.x <= 0 or miolo.size.y <= 0:
				miolo = area
		var soma := Vector3.ZERO
		var n := 0
		for y in range(miolo.position.y, miolo.end.y):
			for x in range(miolo.position.x, miolo.end.x):
				var px := img.get_pixel(x, y)
				if px.a >= 0.5:
					soma += Vector3(px.r, px.g, px.b)
					n += 1
		if n > 0:
			r = Color(soma.x / n, soma.y / n, soma.z / n, 1.0)
	_medias[chave] = r
	return r


# ---------------------------------------------------------------------------------------------
# Registro
# ---------------------------------------------------------------------------------------------

func _achado(codigo: String, n: Node, estado: String, detalhe: String) -> void:
	var caminho := _caminho(n)
	var chave := "%s|%s|%s|%s" % [codigo, _arquivo(n), caminho, detalhe]
	if achados.has(chave):
		achados[chave].n += 1
	else:
		achados[chave] = {"codigo": codigo, "arquivo": _arquivo(n), "caminho": caminho, "estado": estado, "n": 1, "detalhe": detalhe}
	if estrito:
		a._problema(codigo, n, detalhe)


func _caminho(n: Node) -> String:
	var c := str(n.name)
	if _cena != null and _cena.is_ancestor_of(n):
		c = _estavel(str(_cena.get_path_to(n)))
	if n is Label and n.text != "":
		c += ' "%s"' % n.text.replace("\n", " ").left(24)
	elif n is Button:
		var tx: String = a._texto_botao(n)
		if tx != "":
			c += ' "%s"' % tx.left(24)
	return c


## Arquivo de origem: o primeiro script (ou cena) do nó para cima.
func _arquivo(n: Node) -> String:
	var p := n
	while p != null:
		var s: Script = p.get_script()
		if s != null and s.resource_path != "":
			return s.resource_path
		if p.scene_file_path != "":
			return p.scene_file_path
		p = p.get_parent()
	return "?"


## Resumo por regra, para o fim do relatório.
func contagem_por_regra() -> Dictionary:
	var r := {}
	for c in CODIGOS:
		r[c] = 0
	for k in achados:
		r[achados[k].codigo] += 1
	return r


## Nomes automáticos (@Control@123) mudam a cada vez que a tela é montada: troca por * para o mesmo nó contar uma vez só.
func _estavel(caminho: String) -> String:
	var re := RegEx.new()
	re.compile("@([A-Za-z0-9]+)@[0-9]+")
	return re.sub(caminho, "@$1", true)
