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
## Placar: todo `ignore` visto é contado em `placar` (meta do estúdio: no máximo 15 no fim da fase).

const BASE := Vector2(640, 360)
const TOL := 1.0
const CODIGOS := ["IGNORE_SEM_MOTIVO", "IGNORE_PROIBIDO", "TXT_SOZINHO", "JANELA_ASSIM", "JANELA_MARGEM", "OPACO_FORA", "DRAW_TEXTO"]

var a  # o ui_audit (SceneTree)
var estrito := false
var achados := {}  # chave -> {codigo, arquivo, caminho, estado, n, detalhe}
var placar := {}  # chave -> {arquivo, caminho, motivo, classe}
var _cena: Node = null


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
