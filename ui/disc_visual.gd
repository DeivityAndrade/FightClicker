class_name DiscVisual
extends RefCounted
## Monta o discípulo em camadas na ordem de manifest layers.order (corpo, parte de cima, meião, cabelo, faixa, máscara da frente)
## e troca as cores-chave pelas escolhidas (manifest.by_data_id.disciple_palette): pele, cabelo, calção, parte de cima, faixa e
## meião (o meião copia a cor do calção). Só desenho: o visual vem de GameState.visual_lutador() / rascunho() / do roster.
## Sem camadas no manifest, devolve a folha pronta (fallback sem quebrar). Uma textura por (folha, 9 campos), em cache.

const CAMPOS_COR := ["skin", "hair_color", "shorts_color", "top_color", "headband_color"]

static var _cache: Dictionary = {}
static var _paleta: Dictionary = {}


static func limpar() -> void:
	_cache.clear()
	_paleta = {}


## Textura da folha `nome` (ex.: "disciple_walk_bare", "fighter_idle_disc_layered") com o visual `look`.
static func textura(nome: String, look: Dictionary) -> Texture2D:
	var s := UiTema.sprite(nome)
	var cam: Dictionary = s.get("layers", {}) if s.get("layers", {}) is Dictionary else {}
	if cam.is_empty() or look.is_empty():
		return UiTema.textura(nome)
	var estilo := str(look.get("hair_style", "short"))
	var top := str(look.get("top", "none"))
	var faixa := str(look.get("headband", "none"))
	var meiao := str(look.get("socks", "none"))
	var chave := "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [nome, look.get("skin", ""), look.get("hair_color", ""), look.get("shorts_color", ""),
		estilo, top, look.get("top_color", ""), faixa, look.get("headband_color", ""), meiao]
	if _cache.has(chave):
		return _cache[chave]
	var corpo := _imagem(str(cam.get("body", "")))
	if corpo == null:
		return UiTema.textura(nome)
	var mapa := _mapa(look)
	_trocar(corpo, mapa)
	# Base = corpo + parte de cima + meião (é o que a máscara da frente redesenha por cima do cabelo e da faixa).
	var base := _copia(corpo)
	var tops: Dictionary = cam.get("top", {}) if cam.get("top", {}) is Dictionary else {}
	var ordem: Array = cam.get("order", ["body", "top", "socks", "head", "band", "front_mask"])
	var saida: Image = null
	for camada in ordem:
		match str(camada):
			"top":
				if top != "none":
					_somar(base, _imagem(str(tops.get(top, ""))), mapa)
			"socks":
				if meiao != "none":
					_somar(base, _imagem(str(cam.get("socks", ""))), mapa)
			"head":
				if saida == null:
					saida = _copia(base)
				var cortes: Dictionary = cam.get("head", {}) if cam.get("head", {}) is Dictionary else {}
				var caminho := str(cortes.get(estilo, ""))
				if caminho == "" and not cortes.is_empty():
					caminho = str(cortes.values()[0])
				_somar(saida, _imagem(caminho), mapa)
			"band":
				if saida == null:
					saida = _copia(base)
				if faixa != "none":
					_somar(saida, _imagem(str(cam.get("band", ""))), mapa)
			"front_mask":
				if saida == null:
					saida = _copia(base)
				var mascara := _imagem(str(cam.get("front_mask", "")))
				if mascara != null and mascara.get_size() == base.get_size():
					for y in base.get_height():
						for x in base.get_width():
							var m := mascara.get_pixel(x, y)
							if m.a > 0.5 and m.r > 0.5:
								var c := base.get_pixel(x, y)
								if c.a > 0.0:
									saida.set_pixel(x, y, c)
	if saida == null:
		saida = base
	var t := ImageTexture.create_from_image(saida)
	_cache[chave] = t
	return t


## Troca de cor de um quadro 1 (miniatura/retrato) por nome de folha "_layered" do jogador ("..._disc" -> "..._disc_layered").
static func nome_em_camadas(nome_disc: String) -> String:
	var n := nome_disc + "_layered"
	return n if not UiTema.sprite(n).is_empty() else ""


static func _copia(img: Image) -> Image:
	var c := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	c.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
	return c


## Troca as cores da camada e a desenha por cima de `destino` (mesmo tamanho e pivô).
static func _somar(destino: Image, camada: Image, mapa: Dictionary) -> void:
	if camada == null:
		return
	_trocar(camada, mapa)
	destino.blend_rect(camada, Rect2i(Vector2i.ZERO, camada.get_size()), Vector2i.ZERO)


static func _imagem(caminho: String) -> Image:
	if caminho == "" or not ResourceLoader.exists(caminho):
		return null
	var t := load(caminho) as Texture2D
	if t == null:
		return null
	var img := t.get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


static func _trocar(img: Image, mapa: Dictionary) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var k := c.to_rgba32()
			if mapa.has(k):
				var n: Color = mapa[k]
				img.set_pixel(x, y, Color(n.r, n.g, n.b, c.a))


## {cor-chave rgba32: cor nova} para o visual (as chaves de cada peça não se repetem entre peças).
static func _mapa(look: Dictionary) -> Dictionary:
	if _paleta.is_empty():
		_paleta = UiTema.manifest().get("by_data_id", {}).get("disciple_palette", {})
	var r := {}
	var chaves: Dictionary = _paleta.get("keys", {})
	var opcoes: Dictionary = _paleta.get("options", {})
	var padrao: Dictionary = _paleta.get("default", {})
	for campo in CAMPOS_COR:
		_aplicar_opcao(r, chaves.get(campo, {}), opcoes.get(campo, []), str(look.get(campo, padrao.get(campo, ""))))
	# Meião: sem cor própria, usa a entrada de options.socks com o mesmo id do calção.
	_aplicar_opcao(r, chaves.get("socks", {}), opcoes.get("socks", []), str(look.get("shorts_color", padrao.get("shorts_color", ""))))
	return r


static func _aplicar_opcao(r: Dictionary, ks: Dictionary, lista: Array, id: String) -> void:
	for o in lista:
		if str(o.get("id", "")) != id:
			continue
		var rampa: Dictionary = o.get("ramp", {})
		for slot in rampa:
			if ks.has(slot):
				r[Color(str(ks[slot])).to_rgba32()] = Color(str(rampa[slot]))
