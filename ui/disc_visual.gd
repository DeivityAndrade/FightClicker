class_name DiscVisual
extends RefCounted
## Monta o discípulo em camadas (corpo, cabeça, corpo recortado pela máscara da frente) e troca as cores-chave pela
## pele, cabelo e calção escolhidos (manifest.by_data_id.disciple_palette). Só desenho: o visual vem de
## GameState.visual_lutador() / rascunho(). Sem camadas no manifest, devolve a folha pronta (fallback sem quebrar).
## O resultado é uma textura por (folha, visual), guardada em cache.

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
	var chave := "%s|%s|%s|%s|%s" % [nome, look.get("skin", ""), look.get("hair_color", ""), look.get("shorts_color", ""), look.get("hair_style", "short")]
	if _cache.has(chave):
		return _cache[chave]
	var corpo := _imagem(str(cam.get("body", "")))
	if corpo == null:
		return UiTema.textura(nome)
	var cortes: Dictionary = cam.get("head", {}) if cam.get("head", {}) is Dictionary else {}
	var caminho_cabeca := str(cortes.get(str(look.get("hair_style", "short")), ""))
	if caminho_cabeca == "" and not cortes.is_empty():
		caminho_cabeca = str(cortes.values()[0])
	var cabeca := _imagem(caminho_cabeca)
	var mascara := _imagem(str(cam.get("front_mask", "")))
	var mapa := _mapa(look)
	_trocar(corpo, mapa)
	var saida := Image.create(corpo.get_width(), corpo.get_height(), false, Image.FORMAT_RGBA8)
	saida.blend_rect(corpo, Rect2i(Vector2i.ZERO, corpo.get_size()), Vector2i.ZERO)
	if cabeca != null:
		_trocar(cabeca, mapa)
		saida.blend_rect(cabeca, Rect2i(Vector2i.ZERO, cabeca.get_size()), Vector2i.ZERO)
	if mascara != null and mascara.get_size() == corpo.get_size():
		for y in corpo.get_height():
			for x in corpo.get_width():
				var m := mascara.get_pixel(x, y)
				if m.a > 0.5 and m.r > 0.5:
					var c := corpo.get_pixel(x, y)
					if c.a > 0.0:
						saida.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(saida)
	_cache[chave] = t
	return t


## Troca de cor de um quadro 1 (miniatura/retrato) por nome de folha "_layered" do jogador ("..._disc" -> "..._disc_layered").
static func nome_em_camadas(nome_disc: String) -> String:
	var n := nome_disc + "_layered"
	return n if not UiTema.sprite(n).is_empty() else ""


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


## {cor-chave rgba32: cor nova} para o visual.
static func _mapa(look: Dictionary) -> Dictionary:
	if _paleta.is_empty():
		_paleta = UiTema.manifest().get("by_data_id", {}).get("disciple_palette", {})
	var r := {}
	var chaves: Dictionary = _paleta.get("keys", {})
	var opcoes: Dictionary = _paleta.get("options", {})
	for campo in ["skin", "hair_color", "shorts_color"]:
		var id := str(look.get(campo, ""))
		for o in opcoes.get(campo, []):
			if str(o.get("id", "")) != id:
				continue
			var rampa: Dictionary = o.get("ramp", {})
			var ks: Dictionary = chaves.get(campo, {})
			for slot in rampa:
				if ks.has(slot):
					r[Color(str(ks[slot])).to_rgba32()] = Color(str(rampa[slot]))
	return r
