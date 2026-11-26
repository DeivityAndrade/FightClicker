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
static func textura(nome: String, look: Dictionary, simbolo: bool = false) -> Texture2D:
	var s := UiTema.sprite(nome)
	var cam: Dictionary = s.get("layers", {}) if s.get("layers", {}) is Dictionary else {}
	if cam.is_empty() or look.is_empty():
		return UiTema.textura(nome)
	var estilo := str(look.get("hair_style", "short"))
	var top := str(look.get("top", "none"))
	var faixa := str(look.get("headband", "none"))
	var meiao := str(look.get("socks", "none"))
	var marca := GameState.patrocinio_estado == "signed"  # 8a2: a marca do patrocinador no calção (só com o contrato assinado)
	var chave := "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [nome, look.get("skin", ""), look.get("hair_color", ""), look.get("shorts_color", ""),
		estilo, top, look.get("top_color", ""), faixa, look.get("headband_color", ""), meiao, "sym" if simbolo else "-", "pat" if marca else "-"]
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
			"school_symbol":
				if simbolo:
					var lugar := "chest" if top != "none" else "leg"
					var sims: Dictionary = cam.get("school_symbol", {}) if cam.get("school_symbol", {}) is Dictionary else {}
					if sims.has(lugar):
						_somar(base, _imagem(str(sims[lugar])), _mapa_simbolo(look, lugar))
			"head":
				if saida == null:
					if marca:
						_remendo(base, s)  # o remendo fica na base: a máscara da frente (braço, luva) passa por cima dele
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


## 8a2: remendo do patrocinador (sponsor_vale_patch, 5x3) no calção: em cada quadro, no `hip` + (-2,+3) com o pivô do remendo (2,0)
## (= canto de cima à esquerda em hip - 4); quadro virado (`flipped`) espelha em torno do hip. Só pinta onde já há corpo (calção).
static func _remendo(base: Image, folha: Dictionary) -> void:
	var rem := _imagem(str(UiTema.sprite("sponsor_vale_patch").get("file", "")))
	if rem == null:
		return
	var ancoras = folha.get("anchors", [])
	var fs: Array = folha.get("frame_size", [48, 72])
	var pv: Array = folha.get("pivot", [22, 67])
	var n := maxi(1, int(folha.get("frames", 1)))
	for q in n:
		var a = ancoras[q] if ancoras is Array and q < ancoras.size() else (ancoras if ancoras is Dictionary else {})
		if not (a is Dictionary) or not a.has("hip"):
			continue
		var hip: Array = a.hip
		var x0 := q * int(fs[0]) + int(pv[0]) + int(hip[0]) + (-1 if bool(a.get("flipped", false)) else -4)
		var y0 := int(pv[1]) + int(hip[1]) + 3
		for yy in rem.get_height():
			for xx in rem.get_width():
				var c := rem.get_pixel(xx, yy)
				var px := x0 + (rem.get_width() - 1 - xx if bool(a.get("flipped", false)) else xx)
				var py := y0 + yy
				if c.a > 0.0 and px >= 0 and py >= 0 and px < base.get_width() and py < base.get_height() and base.get_pixel(px, py).a > 0.0:
					base.set_pixel(px, py, c)


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
	# Meião: sem cor própria, usa a entrada de options.socks com o mesmo id do calção; a bandagem da noite (night_wraps) tem a sua.
	var id_meiao := "night_wraps" if str(look.get("socks", "")) == "night_wraps" else str(look.get("shorts_color", padrao.get("shorts_color", "")))
	_aplicar_opcao(r, chaves.get("socks", {}), opcoes.get("socks", []), id_meiao)
	_aplicar_estilos(r, look, chaves)
	return r


## Estilos da noite (Ronda 2a1): opção com `requires` no disciples.json (faixa/calção `night`, meião `night_wraps`) não existe na paleta do
## manifest; pinta pelas cores do próprio disciples.json (o nome do slot = a chave do manifest). O meião "on" sobre o calção `night` também.
static func _aplicar_estilos(r: Dictionary, look: Dictionary, chaves: Dictionary) -> void:
	var d: DiscipulosData = GameState.disciples
	if d == null:
		return
	var cores: Dictionary = {}
	for campo in ["headband_color", "shorts_color", "socks"]:
		var id := str(look.get(campo, ""))
		var estilo := d.tem_requisito(campo, id)
		if campo == "socks" and id == "on":
			estilo = d.tem_requisito("shorts_color", str(look.get("shorts_color", "")))
		if not estilo:
			continue
		if cores.is_empty():
			cores = d.cores(look)
		var c: Dictionary = cores.get(campo, {})
		var ks: Dictionary = chaves.get(campo, {})
		var slots: Array = c.get("slots", [])
		var cs: Array = c.get("colors", [])
		for i in mini(slots.size(), cs.size()):
			if ks.has(slots[i]):
				r[Color(str(ks[slots[i]])).to_rgba32()] = Color(str(cs[i]))
		if ks.has("deep") and not slots.has("deep") and not cs.is_empty():  # a paleta do manifest tem uma 3ª sombra sem slot nos dados
			r[Color(str(ks["deep"])).to_rgba32()] = Color(str(cs[0])).darkened(0.3)


static func _aplicar_opcao(r: Dictionary, ks: Dictionary, lista: Array, id: String) -> void:
	for o in lista:
		if str(o.get("id", "")) != id:
			continue
		var rampa: Dictionary = o.get("ramp", {})
		for slot in rampa:
			if ks.has(slot):
				r[Color(str(ks[slot])).to_rgba32()] = Color(str(rampa[slot]))


## Cores do símbolo da escola (estampa de uma cor): o peito segue a cor da parte de cima, a coxa a do calção
## (manifest disciple_palette.school_symbol_source -> options.school_symbol).
static func _mapa_simbolo(look: Dictionary, lugar: String) -> Dictionary:
	if _paleta.is_empty():
		_paleta = UiTema.manifest().get("by_data_id", {}).get("disciple_palette", {})
	var r := {}
	var fonte: Dictionary = _paleta.get("school_symbol_source", {}).get(lugar, {})
	var padrao: Dictionary = _paleta.get("default", {})
	var campo := str(fonte.get("field", ""))
	var cor := str(look.get(campo, padrao.get(campo, "")))
	var id := str(fonte.get("map", {}).get(cor, "blue"))
	_aplicar_opcao(r, _paleta.get("keys", {}).get("school_symbol", {}), _paleta.get("options", {}).get("school_symbol", []), id)
	return r
