class_name JanelaMapa
extends JanelaBase
## Árvore grande da Fase 5.4: um mapa que se revela a cada compra, por cima da sala (tela cheia, 640x360).
## Topo: título, "arraste ou use a roda", Legado e X. Janela do mapa (5,26 630x329): arrasta com o mouse e rola com a roda
## (sem zoom). Camadas do mundo, de baixo para cima: fundo pintado por regiões (células 8x8) -> linhas (pixel a pixel) ->
## neblina por distância -> nós (3 estados) com preço -> plaquinhas de região -> efeitos. Cartão do nó ao passar o mouse.
## A UI só lê `arvore_mapa()` / `arvore_mapa_info()` e chama `comprar_no()`; nenhuma conta de jogo aqui.
## Geometria e regras de pintura: manifest.by_data_id.skill_map (docs/arte/direcao-visual.md §21).
## Alinhamento: o mundo (nós em posição livre) é declarado `ui_align = ignore`; o resto (barra do topo, X, cartão) é
## auditado normalmente, e `diagnostico()` confere por conta própria o que está no mundo (preço dentro da etiqueta, nó sobre nó...).

signal fechar_pedido

const VP := Rect2(5, 26, 630, 329)
const CELULA := 8
const RAIO_REGIAO := 44.0
const MARGEM_MUNDO := 96
const CARTAO_L := 176.0
const PASSO_RODA := 32
const LIMITE_ARRASTO := 3.0
const NIVEIS_NEBLINA := [40.0, 48.0, 56.0, 64.0]  # distância -> nível 0..3; além = 4 (100%)
const KIND_SUFIXO := {"small": "s", "milestone": "b", "link": "l"}
const RAIO_POR_KIND := {"small": 12.0, "milestone": 19.0, "link": 14.0}
const METADE_ALTURA := {"small": 12.0, "milestone": 19.0, "link": 12.0}
const ORDEM_REGIOES := ["garage", "gym", "boxing", "bjj", "campaign"]
const CENTRO := ["body", "career", "style"]

var sfx: Sfx
var _info: Dictionary = {}
var _nos: Array = []
var _por_id: Dictionary = {}  # id -> item de arvore_mapa() + {wp: Vector2, par: Array}
var _unit := 40.0
var _desloc := Vector2.ZERO  # mundo = pos x unit + _desloc
var _mundo_w := 0
var _mundo_h := 0
var _gw := 0
var _gh := 0
var _cam := Vector2i.ZERO

var _janela: Control
var _mundo: Control
var _img_fundo: Image
var _img_linhas: Image
var _img_neblina: Image
var _tex_linhas: ImageTexture
var _tex_neblina: ImageTexture
var _faiscas: Control
var _camada_nos: Control
var _camada_placas: Control
var _camada_fx: Control
var _cartao: Control
var _tiles: Dictionary = {}  # chave -> Image
var _fog_tiles: Array = []  # índice 1..4
var _nev := PackedByteArray()  # nível de neblina atual por célula (0..4)
var _pts_acesos: Array = []  # caminhos das linhas acesas (para a faísca andando)
var _vis: Dictionary = {}  # id -> {no, frame, hover, tag, centro, raio, rect, rect_tag}
var _placas: Array = []  # {id, rect}
var _ocultos: Array = []  # nós ainda escondidos durante a animação de compra
var _dono_temp := ""  # nó recém-comprado que ainda aparece como "à vista" (o anel troca no quadro 1)
var _novos: Array = []
var _arrasto: Dictionary = {}
var _hover_id := ""
var _cartao_id := ""
var _t := 0.0
var _fase := -1
var _legado_rotulo: Label
var _legado_icone: TextureRect
var _legado_mostrado := 0
var _tw_legado: Tween
var _tw_compra: Tween
var _tw_neblina: Tween
var _fx_ativos := 0


func abrir_com() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	_info = GameState.arvore_mapa_info()
	_unit = float(_info.get("unit_px", 40.0))
	_legado_mostrado = int(_info.get("legacy", GameState.legado_disponivel()))
	_montar_fixo()
	_atualizar_dados(true)
	_pintar_fundo()
	_assar_linhas()
	_montar_neblina()
	_desenhar_nos()
	_desenhar_placas()
	_centralizar(str(_info.get("last_node", "")))
	GameState.no_revelado.connect(_ao_revelado)
	GameState.arvore_mudou.connect(_ao_arvore_mudou)
	animar_entrada()


# --- Peças fixas: moldura, barra do topo, Legado, X, janela do mapa ---

func _montar_fixo() -> void:
	var m := UiTema.nine_patch(painel, "ui_map_frame", Rect2(0, 0, 640, 360))
	m.set_meta("ui_pos", "center_h")
	# Janela do mapa (recorta o mundo). Atrás do mundo, tinta: fora do mundo nunca aparece buraco.
	_janela = Control.new()
	_janela.position = VP.position
	_janela.size = VP.size
	_janela.clip_contents = true
	_janela.mouse_filter = Control.MOUSE_FILTER_STOP
	_janela.set_meta("ui_pos", "center_h")
	_janela.gui_input.connect(_entrada)
	_janela.mouse_exited.connect(func() -> void: _sobre(""))
	painel.add_child(_janela)
	var fundo := ColorRect.new()
	fundo.color = UiTema.INK
	fundo.size = VP.size
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_janela.add_child(fundo)
	_mundo = Control.new()
	_mundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTema.alinhar(_mundo, "ignore")  # nós em posição livre: conferidos por diagnostico()
	_janela.add_child(_mundo)
	var borda := UiTema.nine_patch(painel, "ui_map_viewport_edge", Rect2(4, 25, 632, 331))
	borda.set_meta("ui_pos", "center_h")

	var barra := UiTema.nine_patch(painel, "ui_map_topbar", Rect2(5, 5, 630, 20))
	barra.set_meta("ui_pos", "center_h")
	UiTema.textura_rect(painel, "icon_skill_map", 9, 7)
	var titulo := UiTema.rotulo(painel, UiTema.txt("tree_title", "O QUE O VELHO TE ENSINOU"), UiTema.COL_TEXT_1, 29, 11)
	UiTema.alinhar(titulo, "left")
	var x_dica := roundf(29.0 + UiTema.largura_visivel(titulo.text) + 12.0)
	var dica := UiTema.rotulo(painel, UiTema.txt("map_hint", "ARRASTE OU USE A RODA"), UiTema.COL_TEXT_2, x_dica, 11)
	UiTema.alinhar(dica, "left")
	_legado_icone = UiTema.textura_rect(painel, "icon_legacy_16", 0, 7)
	_legado_rotulo = UiTema.rotulo(painel, "", UiTema.COL_LEGACY, 0, 8)
	_legado_rotulo.scale = Vector2(2, 2)
	_mostrar_legado(_legado_mostrado)
	var x := UiTema.botao_estilizado(painel, Rect2(616, 7, 16, 16), "ui_map_close")
	x.name = "Fechar"
	x.pressed.connect(func() -> void: fechar_pedido.emit())


## Legado: número herói (escala 2) terminando em x 610, com o ícone 16x16 logo antes.
func _mostrar_legado(valor: int) -> void:
	var texto := NumberFormat.fmt(float(valor))
	_legado_rotulo.text = texto
	var larg := roundf(UiTema.largura_visivel(texto) * 2.0)
	_legado_rotulo.position.x = 610.0 - larg
	_legado_icone.position.x = 610.0 - larg - 3.0 - 16.0


# --- Dados ---

func _atualizar_dados(primeira: bool = false) -> void:
	_nos = GameState.arvore_mapa()
	if primeira:
		var mn := Vector2(INF, INF)
		var mx := Vector2(-INF, -INF)
		for it in _nos:
			var p: Vector2 = it.pos
			mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
			mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
		_desloc = Vector2(-mn.x * _unit + MARGEM_MUNDO, -mn.y * _unit + MARGEM_MUNDO)
		var w := (mx.x - mn.x) * _unit + 2.0 * MARGEM_MUNDO
		var h := (mx.y - mn.y) * _unit + 2.0 * MARGEM_MUNDO
		_gw = int(ceil(w / CELULA))
		_gh = int(ceil(h / CELULA))
		_mundo_w = _gw * CELULA
		_mundo_h = _gh * CELULA
		_mundo.size = Vector2(_mundo_w, _mundo_h)
	_por_id.clear()
	for it in _nos:
		var p: Vector2 = it.pos
		it["wp"] = Vector2(roundi(p.x * _unit + _desloc.x), roundi(p.y * _unit + _desloc.y))
		_por_id[str(it.id)] = it
	for it in _nos:
		it["par"] = _par_da_ligacao(it)


## Ligação: as duas regiões que ela junta (pelas regiões dos vizinhos, na ordem garage, gym, boxing, bjj, campaign).
func _par_da_ligacao(it: Dictionary) -> Array:
	if str(it.kind) != "link":
		return []
	var par: Array = []
	for v in it.neighbors:
		var o: Dictionary = _por_id.get(str(v), {})
		var r := str(o.get("region", ""))
		if r in ORDEM_REGIOES and not (r in par):
			par.append(r)
	par.sort_custom(func(a, b) -> bool: return ORDEM_REGIOES.find(a) < ORDEM_REGIOES.find(b))
	while par.size() < 2:
		par.append(par[0] if not par.is_empty() else "campaign")
	return par


## Estado que a tela mostra agora (durante a animação de compra alguns nós ainda estão escondidos).
func _estado(it: Dictionary) -> String:
	var id := str(it.id)
	if id in _ocultos:
		return "hidden"
	if id == _dono_temp:
		return "visible"
	return str(it.state)


func _imagem(nome: String) -> Image:
	var i: Image = UiTema.textura(nome).get_image()
	if i.get_format() != Image.FORMAT_RGBA8:
		i.convert(Image.FORMAT_RGBA8)
	return i


# --- Fundo: células 8x8, região do nó mais perto até 44 px ---

func _pintar_fundo() -> void:
	for chave in ["center", "garage", "gym", "boxing", "bjj", "campaign", "wall"]:
		_tiles[chave] = _imagem("map_tile_" + chave)
	var aberta := {}
	for r in _info.regions:
		aberta[str(r.id)] = bool(r.open)
	var n := _gw * _gh
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist.fill(RAIO_REGIAO)
	var chave_cel := PackedStringArray()
	chave_cel.resize(n)
	chave_cel.fill("wall")
	for it in _nos:
		if not GameState.trava_aberta(str(it.lock)):
			continue  # região trancada conta como parede
		var c: Vector2 = it.wp
		var reg := str(it.region)
		var x0 := maxi(0, int(floor((c.x - RAIO_REGIAO) / CELULA)))
		var x1 := mini(_gw - 1, int(ceil((c.x + RAIO_REGIAO) / CELULA)))
		var y0 := maxi(0, int(floor((c.y - RAIO_REGIAO) / CELULA)))
		var y1 := mini(_gh - 1, int(ceil((c.y + RAIO_REGIAO) / CELULA)))
		for cy in range(y0, y1 + 1):
			for cx in range(x0, x1 + 1):
				var d := Vector2((cx + 0.5) * CELULA, (cy + 0.5) * CELULA).distance_to(c)
				var i := cy * _gw + cx
				if d >= dist[i]:
					continue
				dist[i] = d
				var chave := reg
				if reg == "link":
					var par: Array = it.par
					chave = str(par[(cx + cy) % 2])
					if not aberta.get(chave, true):
						chave = str(par[(cx + cy + 1) % 2])
				elif reg in CENTRO:
					chave = "center"
				if chave != "wall" and not aberta.get(chave, true):
					chave = "wall"
				chave_cel[i] = chave
	_img_fundo = Image.create(_mundo_w, _mundo_h, false, Image.FORMAT_RGBA8)
	for cy in _gh:
		for cx in _gw:
			var t: Image = _tiles[chave_cel[cy * _gw + cx]]
			_img_fundo.blit_rect(t, Rect2i((cx * CELULA) % 32, (cy * CELULA) % 32, CELULA, CELULA), Vector2i(cx * CELULA, cy * CELULA))
	_costurar(chave_cel)
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture = ImageTexture.create_from_image(_img_fundo)
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.size = _mundo.size
	_mundo.add_child(tr)


## Costura de 1 px ink entre materiais, 1 px de luz no topo do recorte e sombra na parede embaixo.
func _costurar(chave_cel: PackedStringArray) -> void:
	var ink := UiTema.INK
	for cy in _gh:
		for cx in _gw:
			var k := chave_cel[cy * _gw + cx]
			if k == "wall":
				continue
			var x0 := cx * CELULA
			var y0 := cy * CELULA
			if cx + 1 < _gw and chave_cel[cy * _gw + cx + 1] != k:
				_img_fundo.fill_rect(Rect2i(x0 + CELULA - 1, y0, 1, CELULA), ink)
			if cx > 0 and chave_cel[cy * _gw + cx - 1] != k:
				_img_fundo.fill_rect(Rect2i(x0, y0, 1, CELULA), ink)
			if cy + 1 < _gh and chave_cel[(cy + 1) * _gw + cx] != k:
				_img_fundo.fill_rect(Rect2i(x0, y0 + CELULA - 1, CELULA, 1), ink)
				if chave_cel[(cy + 1) * _gw + cx] == "wall":
					_img_fundo.fill_rect(Rect2i(x0 + 1, y0 + CELULA, CELULA, 1), ink)
			if cy > 0 and chave_cel[(cy - 1) * _gw + cx] != k:
				_img_fundo.fill_rect(Rect2i(x0, y0, CELULA, 1), ink)
				var luz := _img_fundo.get_pixel(x0 + 2, y0 + 2).lightened(0.16)
				_img_fundo.fill_rect(Rect2i(x0 + 1, y0 + 1, CELULA - 2, 1), luz)


# --- Linhas: Bresenham, pixel a pixel ---

func _assar_linhas() -> void:
	if _img_linhas == null:
		_img_linhas = Image.create(_mundo_w, _mundo_h, false, Image.FORMAT_RGBA8)
		_tex_linhas = ImageTexture.create_from_image(_img_linhas)
		var tr := TextureRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture = _tex_linhas
		tr.stretch_mode = TextureRect.STRETCH_KEEP
		tr.size = _mundo.size
		_mundo.add_child(tr)
	_img_linhas.fill(Color(0, 0, 0, 0))
	_pts_acesos.clear()
	var vistos := {}
	for it in _nos:
		for v in it.neighbors:
			var o: Dictionary = _por_id.get(str(v), {})
			if o.is_empty():
				continue
			var chave := (str(it.id) + "|" + str(v)) if str(it.id) < str(v) else (str(v) + "|" + str(it.id))
			if vistos.has(chave):
				continue
			vistos[chave] = true
			var sa := _estado(it)
			var sb := _estado(o)
			if sa == "hidden" and sb == "hidden":
				continue
			var pts := _bresenham(it.wp, o.wp)
			if sa == "owned" and sb == "owned":
				_linha_acesa(pts)
			elif sa != "hidden" and sb != "hidden":
				_linha_aberta(pts)
			else:
				# Um lado escondido: só tracejada se o lado escondido não está atrás de uma trava fechada.
				var escondido: Dictionary = it if sa == "hidden" else o
				if GameState.trava_aberta(str(escondido.lock)):
					_linha_apagada(pts)
	_tex_linhas.update(_img_linhas)
	_faiscas_atualizar()


func _bresenham(a: Vector2, b: Vector2) -> Array:
	var out: Array = []
	var x0 := int(a.x)
	var y0 := int(a.y)
	var x1 := int(b.x)
	var y1 := int(b.y)
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		out.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return out


func _px(x: int, y: int, cor: Color) -> void:
	if x >= 0 and y >= 0 and x < _mundo_w and y < _mundo_h:
		_img_linhas.set_pixel(x, y, cor)


## Segunda camada: 1 px para baixo se a linha é mais larga que alta, senão 1 px para a direita.
func _desvio(pts: Array) -> Vector2i:
	var a: Vector2i = pts[0]
	var b: Vector2i = pts[pts.size() - 1]
	return Vector2i(0, 1) if absi(b.x - a.x) >= absi(b.y - a.y) else Vector2i(1, 0)


func _linha_acesa(pts: Array) -> void:
	var off := _desvio(pts)
	for p in pts:
		_px(p.x + off.x * 2, p.y + off.y * 2, UiTema.INK)
	for p in pts:
		_px(p.x, p.y, UiTema.P2)
		_px(p.x + off.x, p.y + off.y, UiTema.P1)
	_pts_acesos.append(pts)


func _linha_aberta(pts: Array) -> void:
	var off := _desvio(pts)
	for p in pts:
		_px(p.x + off.x, p.y + off.y, UiTema.INK)
	for p in pts:
		_px(p.x, p.y, UiTema.G2)


func _linha_apagada(pts: Array) -> void:
	for i in pts.size():
		if i % 4 < 2:
			_px(pts[i].x, pts[i].y, UiTema.G0)


## O pixel branco que anda pelas linhas acesas (o "Legado correndo"): 1 a cada 8, andando 1 px por quadro a 8 fps.
func _faiscas_atualizar() -> void:
	if _faiscas == null:
		_faiscas = Control.new()
		_faiscas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_faiscas.size = _mundo.size
		_faiscas.draw.connect(_desenhar_faiscas)
		_mundo.add_child(_faiscas)
	_faiscas.queue_redraw()


func _desenhar_faiscas() -> void:
	for pts in _pts_acesos:
		for i in range(0, pts.size()):
			if (i + _fase) % 8 == 0:
				var p: Vector2i = pts[i]
				_faiscas.draw_rect(Rect2(p.x, p.y, 1, 1), UiTema.WHITE)


func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * 8.0)
	if f != _fase:
		_fase = f
		if _faiscas != null and not _pts_acesos.is_empty():
			_faiscas.queue_redraw()


# --- Neblina: nível por célula pela distância ao nó revelado mais perto ---

func _montar_neblina() -> void:
	_fog_tiles = [null]
	for nivel in ["25", "50", "75", "100"]:
		_fog_tiles.append(_imagem("map_fog_" + nivel))
	_img_neblina = Image.create(_mundo_w, _mundo_h, false, Image.FORMAT_RGBA8)
	_tex_neblina = ImageTexture.create_from_image(_img_neblina)
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture = _tex_neblina
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.size = _mundo.size
	_mundo.add_child(tr)
	_nev = _niveis_alvo()
	for i in _nev.size():
		_pintar_celula_neblina(i)
	_tex_neblina.update(_img_neblina)


func _niveis_alvo() -> PackedByteArray:
	var n := _gw * _gh
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist.fill(9999.0)
	var alcance: float = float(NIVEIS_NEBLINA[3])
	for it in _nos:
		if _estado(it) == "hidden":
			continue
		var c: Vector2 = it.wp
		var x0 := maxi(0, int(floor((c.x - alcance) / CELULA)))
		var x1 := mini(_gw - 1, int(ceil((c.x + alcance) / CELULA)))
		var y0 := maxi(0, int(floor((c.y - alcance) / CELULA)))
		var y1 := mini(_gh - 1, int(ceil((c.y + alcance) / CELULA)))
		for cy in range(y0, y1 + 1):
			for cx in range(x0, x1 + 1):
				var d := Vector2((cx + 0.5) * CELULA, (cy + 0.5) * CELULA).distance_to(c)
				var i := cy * _gw + cx
				if d < dist[i]:
					dist[i] = d
	var r := PackedByteArray()
	r.resize(n)
	for i in n:
		var nivel := 4
		for k in 4:
			if dist[i] < float(NIVEIS_NEBLINA[k]):
				nivel = k
				break
		r[i] = nivel
	return r


func _pintar_celula_neblina(i: int) -> void:
	var cx := i % _gw
	var cy := i / _gw
	var dst := Vector2i(cx * CELULA, cy * CELULA)
	_img_neblina.fill_rect(Rect2i(dst, Vector2i(CELULA, CELULA)), Color(0, 0, 0, 0))
	var nivel := int(_nev[i])
	if nivel > 0:
		_img_neblina.blit_rect(_fog_tiles[nivel], Rect2i((cx * CELULA) % 32, (cy * CELULA) % 32, CELULA, CELULA), dst)


## Revelar: as células que ficam limpas descem um nível a cada 0,1 s (0,4 s no total).
func _animar_neblina() -> void:
	var alvo := _niveis_alvo()
	var mudar: Array = []
	for i in alvo.size():
		if alvo[i] < _nev[i]:
			mudar.append(i)
	if mudar.is_empty():
		return
	if _tw_neblina != null and _tw_neblina.is_valid():
		_tw_neblina.kill()
	_tw_neblina = create_tween()
	for passo in 4:
		_tw_neblina.tween_callback(func() -> void:
			for i in mudar:
				if _nev[i] > alvo[i]:
					_nev[i] -= 1
					_pintar_celula_neblina(i)
			_tex_neblina.update(_img_neblina))
		_tw_neblina.tween_interval(0.1)


# --- Nós ---

func _tom(it: Dictionary) -> String:
	var tons: Dictionary = UiTema.manifest().get("by_data_id", {}).get("skill_map", {}).get("node", {}).get("tone_by_branch_or_region", {})
	return str(tons.get(str(it.region), "chalk"))


## Ícone 16x16: icon_by_node -> icon_by_effect (objeto: pela requires_art) -> campo icon do nó.
func _icone(it: Dictionary) -> String:
	var mapa: Dictionary = UiTema.manifest().get("by_data_id", {}).get("skill_map", {})
	var nome := str(mapa.get("icon_by_node", {}).get(str(it.id), ""))
	if nome == "" or UiTema.sprite(nome).is_empty():
		var por_efeito = mapa.get("icon_by_effect", {}).get(str(it.effect_type), "")
		if por_efeito is Dictionary:
			nome = str(por_efeito.get(str(it.requires_art), ""))
		else:
			nome = str(por_efeito)
	if nome == "" or UiTema.sprite(nome).is_empty():
		nome = str(it.get("icon", ""))
	if nome == "" or UiTema.sprite(nome).is_empty():
		nome = "icon_legacy_16"
	return nome


func _quadro_do_no(it: Dictionary, estado: String) -> String:
	var k: String = KIND_SUFIXO.get(str(it.kind), "s")
	match estado:
		"owned":
			if k == "l":
				return "map_node_link_owned_%s_%s" % [str(it.par[0]), str(it.par[1])]
			return "map_node_%s_owned_%s" % [k, _tom(it)]
		"visible":
			return "map_node_%s_%s" % [k, "buyable" if bool(it.affordable) else "missing"]
	return "map_node_%s_hidden" % k


func _topo_esq(spr_nome: String, topo_esq: Vector2) -> Vector2:
	return topo_esq + UiTema.pivo(spr_nome)


func _desenhar_nos() -> void:
	if _camada_nos == null:
		_camada_nos = Control.new()
		_camada_nos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada_nos.size = _mundo.size
		_mundo.add_child(_camada_nos)
		_camada_fx = Control.new()
		_camada_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada_fx.size = _mundo.size
		_camada_placas = Control.new()
		_camada_placas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada_placas.size = _mundo.size
		_mundo.add_child(_camada_placas)
		_mundo.add_child(_camada_fx)
	for c in _camada_nos.get_children():
		c.free()
	_vis.clear()
	for it in _nos:
		var estado := _estado(it)
		if estado == "hidden":
			continue
		_montar_no(it, estado)


func _montar_no(it: Dictionary, estado: String) -> void:
	var id := str(it.id)
	var kind := str(it.kind)
	var centro: Vector2 = it.wp
	var no := Control.new()
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no.position = centro
	no.name = id
	_camada_nos.add_child(no)
	var quadro := _quadro_do_no(it, estado)
	var frame := AnimSprite.new()
	frame.definir(quadro)
	frame.position = Vector2.ZERO  # o pivô do sprite já é o centro do nó
	no.add_child(frame)
	if UiTema.sprite(quadro).get("frames", 1) > 1:
		frame.tocar([0, 1], float(UiTema.sprite(quadro).get("fps", 2.0)), true)
	var icone_nome := _icone(it)
	var icone := AnimSprite.new()
	icone.definir(icone_nome)
	icone.position = _topo_esq(icone_nome, Vector2(-8, -8))
	no.add_child(icone)
	if estado == "visible" and not bool(it.affordable):
		var veu := AnimSprite.new()
		veu.definir("map_node_veil")
		veu.position = _topo_esq("map_node_veil", Vector2(-8, -8))
		no.add_child(veu)
	var k: String = KIND_SUFIXO.get(kind, "s")
	var hover := AnimSprite.new()
	hover.definir("map_node_%s_hover" % k)
	hover.visible = false
	no.add_child(hover)
	var d := {"no": no, "frame": frame, "hover": hover, "tag": null, "centro": centro, "raio": float(RAIO_POR_KIND.get(kind, 12.0))}
	var meia: float = float(METADE_ALTURA.get(kind, 12.0))
	var larg_no := 28.0 if kind == "link" else (38.0 if kind == "milestone" else 24.0)
	d["rect"] = Rect2(centro - Vector2(larg_no / 2.0, meia), Vector2(larg_no, meia * 2.0))
	if estado == "visible":
		var tag := _montar_etiqueta(it, meia)
		no.add_child(tag)
		d["tag"] = tag
		d["rect_tag"] = Rect2(centro + tag.position, tag.size)
	_vis[id] = d


## Etiqueta do preço embaixo do nó à vista: ícone do Legado + número. Largura = 12 + texto + 5.
func _montar_etiqueta(it: Dictionary, meia_altura: float) -> Control:
	var ok := bool(it.affordable)
	var texto := NumberFormat.fmt(float(it.cost))
	var w := 12.0 + roundf(UiTema.largura_visivel(texto)) + 5.0
	var tag := Control.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size = Vector2(w, 11)
	tag.position = Vector2(-floorf(w / 2.0), meia_altura + 1.0)
	UiTema.nine_patch(tag, "ui_map_price_ok" if ok else "ui_map_price_missing", Rect2(0, 0, w, 11))
	UiTema.textura_rect(tag, "icon_legacy", 2, 1)
	UiTema.rotulo(tag, texto, UiTema.COL_LEGACY if ok else UiTema.COL_TEXT_2, 12, 0)
	return tag


# --- Plaquinhas de região (aparecem com o 1º nó da região à vista; não cobrem nó) ---

func _desenhar_placas() -> void:
	for c in _camada_placas.get_children():
		c.free()
	_placas.clear()
	for r in _info.regions:
		var rid := str(r.id)
		if str(r.get("icon", "")) == "" or not (rid in ORDEM_REGIOES):
			continue
		var primeiro: Dictionary = {}
		for it in _nos:
			if str(it.region) != rid:
				continue
			if primeiro.is_empty() or (bool(it.root) and not bool(primeiro.root)):
				primeiro = it
		if primeiro.is_empty() or _estado(primeiro) == "hidden":
			continue
		var nome := UiTema.txt("map_region_" + rid, str(r.name))
		var w := 21.0 + roundf(UiTema.largura_visivel(nome))
		var c: Vector2 = primeiro.wp
		var candidatos: Array = [Vector2(0, -36), Vector2(0, 44), Vector2(-(w / 2.0 + 30.0), -26), Vector2(w / 2.0 + 30.0, -26)]
		var escolhido := Rect2()
		var achou := false
		for off in candidatos:
			var cand := Rect2(Vector2(roundf(c.x + off.x - w / 2.0), roundf(c.y + off.y)), Vector2(w, 13))
			if _livre(cand):
				escolhido = cand
				achou = true
				break
		if not achou:
			escolhido = Rect2(Vector2(roundf(c.x - w / 2.0), roundf(c.y - 36.0)), Vector2(w, 13))
		var placa := Control.new()
		placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placa.position = escolhido.position
		placa.size = escolhido.size
		placa.name = "Placa_" + rid
		_camada_placas.add_child(placa)
		UiTema.nine_patch(placa, "ui_map_region_label_" + rid, Rect2(0, 0, w, 13))
		UiTema.textura_rect(placa, "icon_region_%s_9" % rid, 5, 2)
		UiTema.rotulo(placa, nome, UiTema.COL_TEXT_1, 17, 1)
		_placas.append({"id": rid, "rect": escolhido})


## true se o retângulo não cobre nenhum nó, etiqueta de preço ou outra plaquinha.
func _livre(r: Rect2) -> bool:
	for id in _vis:
		var d: Dictionary = _vis[id]
		if r.intersects((d.rect as Rect2).grow(2.0)):
			return false
		if d.tag != null and r.intersects((d.rect_tag as Rect2).grow(1.0)):
			return false
	for p in _placas:
		if r.intersects((p.rect as Rect2).grow(2.0)):
			return false
	return true


# --- Câmera ---

## Onde a câmera pode ir: a caixa dos nós à vista com folga, dentro do mundo (nunca para a parede vazia).
func _limites() -> Rect2:
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for it in _nos:
		if _estado(it) == "hidden":
			continue
		var c: Vector2 = it.wp
		mn = Vector2(minf(mn.x, c.x), minf(mn.y, c.y))
		mx = Vector2(maxf(mx.x, c.x), maxf(mx.y, c.y))
	if mn.x == INF:
		mn = Vector2(_mundo_w / 2.0, _mundo_h / 2.0)
		mx = mn
	var r := Rect2(mn, mx - mn).grow(90.0)
	var cortado := r.intersection(Rect2(0, 0, _mundo_w, _mundo_h))
	return cortado if cortado.has_area() else r


func _prender_camera(c: Vector2i) -> Vector2i:
	var lim := _limites()
	var x := c.x
	var y := c.y
	var xmin := int(floor(lim.position.x))
	var xmax := int(ceil(lim.end.x)) - int(VP.size.x)
	var ymin := int(floor(lim.position.y))
	var ymax := int(ceil(lim.end.y)) - int(VP.size.y)
	x = int(lim.get_center().x - VP.size.x / 2.0) if xmax <= xmin else clampi(x, xmin, xmax)
	y = int(lim.get_center().y - VP.size.y / 2.0) if ymax <= ymin else clampi(y, ymin, ymax)
	return Vector2i(x, y)


func _definir_camera(c: Vector2i) -> void:
	_cam = _prender_camera(c)
	_mundo.position = -Vector2(_cam)
	if _cartao != null:
		_esconder_cartao()


func _centralizar(id: String) -> void:
	var alvo := _desloc  # sem último nó: o centro do mapa (posição 0,0)
	if id != "" and _por_id.has(id):
		alvo = _por_id[id].wp
	_definir_camera(Vector2i(int(alvo.x - VP.size.x / 2.0), int(alvo.y - VP.size.y / 2.0)))


# --- Mouse: arrastar, roda, passar por cima e clicar ---

func _no_em(local: Vector2) -> String:
	var mundo := local + Vector2(_cam)
	var melhor := ""
	var melhor_d := 9999.0
	for id in _vis:
		var d: Dictionary = _vis[id]
		var dist := mundo.distance_to(d.centro)
		if dist <= float(d.raio) and dist < melhor_d:
			melhor_d = dist
			melhor = id
	return melhor


func _entrada(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_arrasto = {"inicio": mb.position, "cam": _cam, "moveu": false}
				else:
					var era_arrasto: bool = not _arrasto.is_empty() and bool(_arrasto.moveu)
					_arrasto = {}
					if not era_arrasto:
						_clicar(_no_em(mb.position))
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT:
				if mb.pressed:
					_rolar(mb)
	elif ev is InputEventMouseMotion:
		var mm: InputEventMouseMotion = ev
		if not _arrasto.is_empty():
			var delta: Vector2 = mm.position - Vector2(_arrasto.inicio)
			if bool(_arrasto.moveu) or delta.length() > LIMITE_ARRASTO:
				_arrasto.moveu = true
				var c: Vector2i = _arrasto.cam
				_definir_camera(c - Vector2i(delta.round()))
		else:
			_sobre(_no_em(mm.position))


func _rolar(mb: InputEventMouseButton) -> void:
	var passo := Vector2i.ZERO
	match mb.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			passo = Vector2i(-PASSO_RODA, 0) if mb.shift_pressed else Vector2i(0, -PASSO_RODA)
		MOUSE_BUTTON_WHEEL_DOWN:
			passo = Vector2i(PASSO_RODA, 0) if mb.shift_pressed else Vector2i(0, PASSO_RODA)
		MOUSE_BUTTON_WHEEL_LEFT:
			passo = Vector2i(-PASSO_RODA, 0)
		MOUSE_BUTTON_WHEEL_RIGHT:
			passo = Vector2i(PASSO_RODA, 0)
	_definir_camera(_cam + passo)
	_sobre(_no_em(_janela.get_local_mouse_position()))


func _sobre(id: String) -> void:
	if id == _hover_id:
		return
	if _vis.has(_hover_id):
		(_vis[_hover_id].hover as Node2D).visible = false
	_hover_id = id
	if id == "" or not _vis.has(id):
		_hover_id = ""
		_esconder_cartao()
		return
	(_vis[id].hover as Node2D).visible = true
	mostrar_cartao(id)


func _clicar(id: String) -> void:
	if id == "" or not _por_id.has(id):
		return
	var it: Dictionary = _por_id[id]
	if str(it.state) == "owned":
		return
	if not GameState.comprar_no(id):
		_recusar(id)


## Nó que não dá para comprar (falta Legado): a etiqueta treme de leve e pisca.
func _recusar(id: String) -> void:
	if not _vis.has(id) or _vis[id].tag == null:
		return
	var tag: Control = _vis[id].tag
	var x0 := tag.position.x
	var tw := create_tween()
	for d in [2.0, -2.0, 1.0, 0.0]:
		tw.tween_property(tag, "position:x", x0 + d, 0.035)
	tag.modulate = Color(1.6, 0.9, 0.9)
	create_tween().tween_property(tag, "modulate", Color.WHITE, 0.3)


# --- Cartão do nó ---

func _cor_efeito(tipo: String) -> Color:
	match tipo:
		"money_bonus":
			return UiTema.COL_MONEY
		"fame_bonus":
			return UiTema.COL_FAME
		"legacy_bonus", "defeat_share_bonus", "art_rule_bonus", "art_fight_bonus":
			return UiTema.COL_LEGACY
		"prep_days_bonus", "preview_percent":
			return UiTema.CREAM
	return UiTema.COL_TREINO


func mostrar_cartao(id: String) -> void:
	_esconder_cartao()
	if not _por_id.has(id) or not _vis.has(id):
		return
	var it: Dictionary = _por_id[id]
	var estado := _estado(it)
	var fonte := UiTema.fonte()
	var larg_txt := CARTAO_L - 14.0
	var linhas: Array = [
		{"texto": str(it.name).to_upper(), "cor": UiTema.COL_TEXT_1},
		{"texto": str(it.description).to_upper(), "cor": UiTema.G3},
		{"texto": str(it.effect_text).to_upper(), "cor": _cor_efeito(str(it.effect_type))},
	]
	if str(it.art_only_text) != "":
		linhas.append({"texto": str(it.art_only_text).to_upper(), "cor": UiTema.COL_TEXT_2})
	if bool(it.needs_shout):
		linhas.append({"texto": UiTema.txt("map_needs_shout", "PEDE O GRITO DA EQUIPE (LOJA)"), "cor": UiTema.Y0})
	var altura := 5.0
	for l in linhas:
		var tam := fonte.get_multiline_string_size(str(l.texto), HORIZONTAL_ALIGNMENT_LEFT, larg_txt, UiTema.TAMANHO_FONTE)
		l["n"] = maxi(1, int(roundf(tam.y / fonte.get_height(UiTema.TAMANHO_FONTE))))
		altura += 9.0 * float(l.n) + 3.0
	var y_preco := altura + 1.0
	altura = y_preco + 9.0 + 5.0
	var com_faixa := estado != "owned" or bool(it.next_campaign)
	var y_faixa := altura
	if com_faixa:
		altura += 13.0 + 2.0
	else:
		altura += 1.0
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.z_index = 10
	c.name = "CartaoNo"
	c.size = Vector2(CARTAO_L, altura)
	var d: Dictionary = _vis[id]
	var centro_tela: Vector2 = d.centro - Vector2(_cam) + VP.position
	var x := centro_tela.x + float(d.raio) + 6.0
	if x + CARTAO_L > VP.end.x - 2.0:
		x = centro_tela.x - float(d.raio) - 6.0 - CARTAO_L
	x = clampf(x, VP.position.x + 2.0, VP.end.x - 2.0 - CARTAO_L)
	var y := clampf(centro_tela.y - altura / 2.0, VP.position.y + 2.0, VP.end.y - 2.0 - altura)
	c.position = Vector2(roundf(x), roundf(y))
	painel.add_child(c)
	_cartao = c
	_cartao_id = id
	UiTema.nine_patch(c, "ui_map_card", Rect2(0, 0, CARTAO_L, altura))
	var yy := 5.0
	for l in linhas:
		var r := UiTema.rotulo(c, str(l.texto), l.cor, 7, yy - 1.0, larg_txt)
		r.size.y = 9.0 * float(l.n)
		yy += 9.0 * float(l.n) + 3.0
	# Preço (ou APRENDIDO) com o ícone do Legado.
	if estado == "owned":
		UiTema.rotulo(c, UiTema.txt("tree_owned", "APRENDIDO"), UiTema.GR3, 7, y_preco - 1.0)
	else:
		UiTema.textura_rect(c, "icon_legacy", 7, y_preco)
		var ok := bool(it.affordable)
		var texto := NumberFormat.fmt(float(it.cost))
		if not ok:
			texto += "  " + UiTema.txt("tree_missing", "FALTAM {n}", {"n": NumberFormat.fmt(float(it.missing))})
		UiTema.rotulo(c, texto, UiTema.COL_LEGACY if ok else UiTema.COL_TEXT_2, 19, y_preco - 1.0)
	if com_faixa:
		var faixa_tam := Vector2(CARTAO_L - 4.0, 13.0)
		var faixa := UiTema.nine_patch(c, "ui_map_card_next", Rect2(Vector2(2, y_faixa), faixa_tam))
		faixa.name = "FaixaProxima"
		var area := UiTema.area_nove("ui_map_card_next", faixa_tam)
		var texto_faixa := UiTema.txt("map_next_campaign", "VALE NA PRÓXIMA CAMPANHA")
		var ic := UiTema.tamanho_quadro("icon_calendar")
		var grupo := ic.x + 3.0 + UiTema.largura_visivel(texto_faixa)
		var gx := roundf(area.position.x + (area.size.x - grupo) / 2.0)
		UiTema.textura_rect(faixa, "icon_calendar", gx, UiTema.y_imagem(area, ic.y))
		UiTema.rotulo(faixa, texto_faixa, UiTema.COL_TEXT_1, gx + ic.x + 3.0, UiTema.y_texto(area))


func _esconder_cartao() -> void:
	if _cartao != null and is_instance_valid(_cartao):
		_cartao.free()
	_cartao = null
	_cartao_id = ""


# --- Compra: o nó acende, os vizinhos aparecem, a neblina recua, o Legado desce contando ---

func _ao_revelado(ids: Array) -> void:
	_novos = ids.duplicate()


func _ao_arvore_mudou() -> void:
	call_deferred("_aplicar_compra")  # `no_revelado` vem logo depois, no mesmo quadro


func _aplicar_compra() -> void:
	if not is_inside_tree():
		return
	var novos := _novos.duplicate()
	_novos.clear()
	var dono := str(GameState.arvore_mapa_info().get("last_node", ""))
	_contar_legado(GameState.legado_disponivel())
	_esconder_cartao()
	_hover_id = ""
	if _tw_compra != null and _tw_compra.is_valid():
		_tw_compra.kill()
		_ocultos.clear()
		_dono_temp = ""
	_atualizar_dados()
	_ocultos = novos
	_dono_temp = dono
	_desenhar_nos()  # t = 0: o dono ainda aparece como à vista; os novos ainda não existem
	_fx("fx_map_buy", dono)
	sfx.no_aprendido()
	_tw_compra = create_tween()
	_tw_compra.tween_interval(1.0 / 12.0)
	_tw_compra.tween_callback(func() -> void:
		_dono_temp = ""  # quadro 1: o anel vira "comprado"
		_desenhar_nos())
	_tw_compra.tween_interval(1.0 / 12.0)
	_tw_compra.tween_callback(func() -> void:
		# quadro 2: as revelações dos vizinhos começam todas juntas (efeito + neblina recuando)
		for id in novos:
			_fx("fx_map_reveal", str(id))
		_ocultos = []  # a neblina já considera os nós novos
		_animar_neblina()
		_ocultos = novos)
	_tw_compra.tween_interval(1.0 / 12.0)
	_tw_compra.tween_callback(func() -> void:
		_ocultos = []  # quadro 2 do efeito de revelação: o nó aparece, a linha acende
		_assar_linhas()
		_desenhar_nos()
		_desenhar_placas()
		_definir_camera(_cam)
		_sobre(_no_em(_janela.get_local_mouse_position())))


func _fx(nome: String, id: String) -> void:
	if not _por_id.has(id):
		return
	var spr := AnimSprite.new()
	spr.definir(nome)
	spr.position = (_por_id[id].wp as Vector2)
	_camada_fx.add_child(spr)
	var quadros := int(UiTema.sprite(nome).get("frames", 1))
	var seq: Array = []
	for i in quadros:
		seq.append(i)
	spr.tocar(seq, 12.0, false, spr.queue_free)


func _contar_legado(alvo: int) -> void:
	if _tw_legado != null and _tw_legado.is_valid():
		_tw_legado.kill()
	var de := _legado_mostrado
	_legado_mostrado = alvo
	if de == alvo:
		_mostrar_legado(alvo)
		return
	_tw_legado = create_tween()
	_tw_legado.tween_method(func(p: float) -> void:
		_mostrar_legado(int(roundf(lerpf(float(de), float(alvo), p)))), 0.0, 1.0, 0.35)
	_tw_legado.tween_callback(func() -> void: _mostrar_legado(alvo))
	_legado_rotulo.modulate = Color(1.9, 1.9, 1.9)
	create_tween().tween_property(_legado_rotulo, "modulate", Color.WHITE, 0.4)
	var gasto := de - alvo
	if gasto > 0:
		var flut := UiTema.rotulo(painel, "-%s" % NumberFormat.fmt(float(gasto)), UiTema.COL_LEGACY, _legado_rotulo.position.x, 26.0, 0,
			HORIZONTAL_ALIGNMENT_LEFT, true)
		UiTema.alinhar(flut, "ignore")
		var tw := create_tween().set_parallel(true)
		tw.tween_property(flut, "position:y", 36.0, 0.6)
		tw.tween_property(flut, "modulate:a", 0.0, 0.6)
		tw.chain().tween_callback(flut.queue_free)


# --- Para o verificador (tools/ui/ui_audit.gd) e os testes ---

## Centro do nó na tela (base 640x360), se estiver dentro da janela do mapa; senão (-1,-1).
func centro_na_tela(id: String) -> Vector2:
	if not _vis.has(id):
		return Vector2(-1, -1)
	var p: Vector2 = (_vis[id].centro as Vector2) - Vector2(_cam) + VP.position
	return p if VP.has_point(p) else Vector2(-1, -1)


func camera() -> Vector2i:
	return _cam


func mover_camera(c: Vector2i) -> void:
	_definir_camera(c)


## Centraliza a câmera num nó (o mapa também abre assim, no último nó comprado).
func ir_para(id: String) -> void:
	_centralizar(id)


func nos_desenhados() -> Array:
	return _vis.keys()


func placas_desenhadas() -> Array:
	return _placas.map(func(p: Dictionary) -> String: return str(p.id))


func cartao_aberto() -> String:
	return _cartao_id


func clicar_no(id: String) -> void:
	_clicar(id)


func fog_nivel_em(id: String) -> int:
	if not _por_id.has(id):
		return -1
	var c: Vector2 = _por_id[id].wp
	return int(_nev[int(c.y / CELULA) * _gw + int(c.x / CELULA)])


## O que o verificador genérico não alcança (o mundo é posição livre): problemas como texto.
func diagnostico() -> Array:
	var erros: Array = []
	var mundo := Rect2(0, 0, _mundo_w, _mundo_h)
	var ids := _vis.keys()
	for i in ids.size():
		var a: Dictionary = _vis[ids[i]]
		if not mundo.encloses(a.rect):
			erros.append("nó %s fora do mundo" % ids[i])
		if a.tag != null:
			var tag: Control = a.tag
			for filho in tag.get_children():
				if filho is Label:
					var larg := UiTema.largura_visivel((filho as Label).text)
					if filho.position.x + larg > tag.size.x - 1.0:
						erros.append("preço de %s não cabe na etiqueta (%.0f > %.0f)" % [ids[i], filho.position.x + larg, tag.size.x])
		for j in range(i + 1, ids.size()):
			var b: Dictionary = _vis[ids[j]]
			if (a.rect as Rect2).intersects(b.rect):
				erros.append("nó %s cobre nó %s" % [ids[i], ids[j]])
			if a.tag != null and (a.rect_tag as Rect2).intersects(b.rect):
				erros.append("etiqueta de %s cobre nó %s" % [ids[i], ids[j]])
			if b.tag != null and (b.rect_tag as Rect2).intersects(a.rect):
				erros.append("etiqueta de %s cobre nó %s" % [ids[j], ids[i]])
			if a.tag != null and b.tag != null and (a.rect_tag as Rect2).intersects(b.rect_tag):
				erros.append("etiqueta de %s cobre etiqueta de %s" % [ids[i], ids[j]])
	for p in _placas:
		for id in ids:
			var d: Dictionary = _vis[id]
			if (p.rect as Rect2).intersects(d.rect) or (d.tag != null and (p.rect as Rect2).intersects(d.rect_tag)):
				erros.append("plaquinha %s cobre %s" % [p.id, id])
	if _cartao != null and is_instance_valid(_cartao):
		var cr := Rect2(_cartao.position, _cartao.size)
		if not VP.encloses(cr):
			erros.append("cartão fora da janela do mapa: %s" % str(cr))
	return erros
