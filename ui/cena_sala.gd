class_name CenaSala
extends Node2D
## Palco da cena de passar o posto (Fase 6b1) dentro da Sala: atores (John, Osmar, discípulo), a porta de enrolar em camadas,
## luz do dia, sombra dos pés, luvas penduradas, saco e lâmpada da sala. Só desenha o que o CenaPlayer manda (sinal `evento`,
## `estado_aplicado`); não tem regra de jogo. Os nós ficam em coordenadas da tela base (a Sala compensa a posição e a câmera 2x).
## Ordem de desenho (manifest.by_data_id.garage_door_scene.draw_order): fundo -> wall (porta de fora) -> floor (luz do dia, depois
## a sombra de pés) -> sorted por y dos pés (porta 222, caixote, luvas 254, gente).
## Arte que falta não quebra: a pose sem folha mantém a folha anterior (ver `_nome_folha`).

const Z_PAREDE := -80
const Z_CHAO := -30

var sala: Sala
var cena_id := ""

var _atores: Dictionary = {}  # id -> {id, char, sp, sombra, pos, facing, nome, glove, mov, visivel}
var _props: Dictionary = {}  # id -> {sp, sala (id do objeto da sala) ou null}
var _lacos: Dictionary = {}  # id do som -> AudioStreamPlayer
var _liberados: Dictionary = {}  # atores entregues ao jogo (o John vira o mentor da sala)
var _personagens: Dictionary = {}
var _ativa := false
var _livre := false  # cena sem controle preso (saída do John)
static var _paletas: Dictionary = {}


func esta_ativa() -> bool:
	return _ativa


# --- Montagem ---

## Monta o palco: `palco` = stage da cena, `atores` = actors da cena, `personagens` = data/cena_player.json > characters.
## 6c1: `resolvidos` = CenaPlayer.mundo().atores (papel resolvido pelo jogo: personagem, look, posição de nascimento, se existe);
## `livre` = cena sem controle preso (a saída do John): a sala continua do jogador.
func montar(palco: Dictionary, atores: Dictionary, personagens: Dictionary, id: String = "", resolvidos: Dictionary = {}, livre: bool = false) -> void:
	limpar()
	cena_id = id
	_ativa = true
	_livre = livre
	_personagens = personagens
	sala.cena_iniciar(palco.get("hide", []), livre)
	for pid in palco.get("props", {}):
		var loc := str(palco.props[pid].get("location", ""))
		if loc != "" and loc != GameState.local_id:
			continue  # adereço de outro local (formato §9 item 22)
		_montar_prop(str(pid), palco.props[pid])
	for aid in atores:
		_montar_ator(str(aid), atores[aid], resolvidos.get(str(aid), {}))


func limpar() -> void:
	for id in _props:
		var p: Dictionary = _props[id]
		if p.get("sp", null) != null:
			(p.sp as Node).queue_free()
	_props.clear()
	for id in _atores:
		(_atores[id].sp as Node).queue_free()
		(_atores[id].sombra as Node).queue_free()
	_atores.clear()
	for id in _lacos.keys():
		_parar_laco(str(id), 0.0)
	_liberados.clear()
	_ativa = false


func _ponto(v: Variant) -> Vector2:
	if v is Array and v.size() == 2:
		return Vector2(float(v[0]), float(v[1]))
	if v is String and v == "mentor_spot":
		return sala.ponto_mentor()
	return Vector2.ZERO


func _montar_prop(id: String, d: Dictionary) -> void:
	if d.has("room_object"):
		_props[id] = {"sp": null, "sala": str(d.room_object)}
		if str(d.room_object) == "punching_bag":
			sala.cena_saco_visivel(bool(d.get("visible", true)))
		return
	var sp := AnimSprite.new()
	sp.definir(str(d.get("sprite", "")))
	sp.position = _ponto(d.get("pos", [0, 0]))
	if str(UiTema.sprite(sp.nome_sprite).get("point", "")) != "":
		sp.position += UiTema.pivo(sp.nome_sprite)  # sprite de ponto (caixote): `pos` é o canto de cima, o pivô é o ponto de pés
	match str(d.get("layer", "sorted")):
		"wall":
			sp.z_index = Z_PAREDE
		"floor":
			sp.z_index = Z_CHAO + _props.size()  # luz do dia primeiro, sombra de pés depois (ordem do manifest)
		_:
			sp.z_index = int(d.get("sort_y", sp.position.y))
	sp.visible = bool(d.get("visible", true))
	add_child(sp)
	_props[id] = {"sp": sp, "sala": ""}
	if d.get("frame", null) != null:
		sp.parar(int(d.frame))
	if str(d.get("anim", "")) != "":
		_anim_prop(sp, str(d.anim))


func _montar_ator(id: String, d: Dictionary, r: Dictionary = {}) -> void:
	var sombra := Sprite2D.new()
	sombra.texture = UiTema.textura("floor_shadow")
	add_child(sombra)
	var sp := AnimSprite.new()
	add_child(sp)
	var existe := bool(r.get("existe", true))
	var personagem := str(r.get("personagem", ""))
	if personagem == "":
		personagem = str(d.get("character", ""))
	var look = r.get("look", {})
	var a := {"id": id, "char": personagem, "sp": sp, "sombra": sombra, "pos": _ponto(r.get("pos", d.get("pos", [0, 0]))),
		"facing": str(r.get("facing", d.get("facing", "right"))), "nome": "", "glove": str(d.get("glove", "")), "mov": {},
		"visivel": bool(r.get("visible", d.get("visible", true))) and existe, "ausente": not existe,
		"look": look if look is Dictionary else {}}
	_atores[id] = a
	if existe:
		_pose(a, str(r.get("anim", d.get("anim", "idle"))), true, [], 0.0)
	_posicionar(a)


# --- Atores ---

func _look() -> Dictionary:
	var l: Dictionary = GameState.visual_lutador()
	if l.is_empty():
		l = GameState.rascunho().get("look", {})
	if l.is_empty():
		l = GameState.disciples.look_padrao
	return l


## Folha do manifest para (personagem, anim). Ordem: manifest.scene_anims, <prefixo>_<anim>, <anim>, casos especiais.
func _nome_folha(char_id: String, anim: String, glove: String) -> String:
	var mapa = UiTema.manifest().get("scene_anims", {})
	if mapa is Dictionary and mapa.has(char_id) and mapa[char_id] is Dictionary and mapa[char_id].has(anim):
		var s := str(mapa[char_id][anim])
		if not UiTema.sprite(s).is_empty():
			return s
	var prefixo := str(_personagens.get(char_id, {}).get("sprite_prefix", ""))
	var sufixo := GameState.sufixo_aparelhos()  # academia: a folha com a luz dos tubos, se existir (coach_idle_gym)
	var cand: Array = []
	if sufixo != "":
		cand.append(prefixo + "_" + anim + sufixo)
	if anim == "idle":
		if char_id == "first_fighter":
			cand = ["fighter_idle"]
		elif char_id == "current_player":
			cand = ["fighter_idle_disc_layered" if glove != "none" else "disciple_stand_bare"]
	elif anim == "punch" and char_id == "first_fighter":
		cand = ["fighter_punch"]
	cand.append(prefixo + "_" + anim)
	cand.append(anim)
	cand.append(prefixo + "_" + anim + "_left")  # folhas que só existem viradas para a esquerda (look_room, nod)
	for c in cand:
		if not UiTema.sprite(str(c)).is_empty():
			return str(c)
	return ""


func _pose(a: Dictionary, anim: String, em_laco: bool, faixa: Array, fps_mult: float, vezes: int = 1, gap: float = 0.0, quadro: int = -1, folha_ev: String = "") -> void:
	var nome := _nome_folha(str(a.char), anim, str(a.glove))
	if nome == "" and folha_ev != "" and not UiTema.sprite(folha_ev).is_empty():
		nome = folha_ev  # folha resolvida pelo compilador (sprite_aliases)
	if nome == "":
		push_warning("CenaSala: sem folha para %s/%s (a pose anterior continua)" % [a.char, anim])
		return
	if str(a.facing) == "left" and str(UiTema.sprite(nome).get("left_variant", "")) != "":
		nome = str(UiTema.sprite(nome).left_variant)  # versão própria para a esquerda (arte), sem espelhar
	var sp: AnimSprite = a.sp
	sp.definir(nome)
	if a.char == "current_player":
		var lk: Dictionary = a.get("look", {})
		sp.texture = DiscVisual.textura(nome, lk if not lk.is_empty() else _look())
	elif str(_personagens.get(a.char, {}).get("palette", "")) != "":
		sp.texture = _textura_paleta(nome, str(_personagens[a.char].palette))  # o 2º vizinho: regata vermelha
	a.nome = nome
	_aplicar_flip(a)
	var s := UiTema.sprite(nome)
	var n := int(s.get("frames", 1))
	var fps := float(s.get("fps", 10.0)) * (fps_mult if fps_mult > 0.0 else 1.0)
	if quadro >= 0:
		sp.parar(quadro)
		return
	var base: Array = []
	if faixa.size() == 2:
		for i in range(int(faixa[0]), int(faixa[1]) + 1):
			base.append(mini(i, n - 1))
	else:
		for i in n:
			base.append(i)
	var seq: Array = []
	for k in maxi(1, vezes):
		seq.append_array(base)
		if k < vezes - 1:
			for g in int(round(gap * fps)):
				seq.append(base[0])
	if seq.size() <= 1:
		sp.parar(int(seq[0]))
	else:
		sp.tocar(seq, fps, em_laco)


## Troca exata de cor por pixel (manifest.by_data_id.personagens_6c1.palette_variants.<paleta>.swap), em cache.
func _textura_paleta(nome: String, paleta: String) -> Texture2D:
	var chave := nome + "|" + paleta
	if _paletas.has(chave):
		return _paletas[chave]
	var base := UiTema.textura(nome)
	var troca: Dictionary = UiTema.manifest().get("by_data_id", {}).get("personagens_6c1", {}).get("palette_variants", {}).get(paleta, {}).get("swap", {})
	if base == null or troca.is_empty():
		return base
	var img := base.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var mapa := {}
	for k in troca:
		mapa[Color(str(k)).to_rgba32()] = Color(str(troca[k]))
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and mapa.has(c.to_rgba32()):
				var n: Color = mapa[c.to_rgba32()]
				img.set_pixel(x, y, Color(n.r, n.g, n.b, c.a))
	var t := ImageTexture.create_from_image(img)
	_paletas[chave] = t
	return t


func _aplicar_flip(a: Dictionary) -> void:
	var sp: AnimSprite = a.sp
	var nome := str(a.nome)
	var piv := UiTema.pivo(nome)
	var natural := "left" if str(UiTema.sprite(nome).get("facing", "direita")) == "esquerda" else "right"
	var vira: bool = str(a.facing) != natural  # só espelha quando o lado pedido difere do lado em que a folha foi desenhada
	sp.flip_h = vira
	if vira:
		var pm = UiTema.sprite(nome).get("pivot_mirrored", null)
		var px: float = float(pm[0]) if pm is Array else UiTema.tamanho_quadro(nome).x - 1.0 - piv.x
		sp.offset = Vector2(-px, -piv.y)
	else:
		sp.offset = -piv


func _posicionar(a: Dictionary) -> void:
	var p: Vector2 = a.pos
	var sp: AnimSprite = a.sp
	sp.position = p
	sp.z_index = int(p.y)
	var sb: Sprite2D = a.sombra
	sb.position = p + Vector2(0, -1)
	sb.z_index = int(p.y) - 1
	sp.visible = bool(a.visivel)
	sb.visible = bool(a.visivel)


func ator_visivel(id: String) -> bool:
	return _atores.has(id) and bool(_atores[id].visivel)


func ator_nome_folha(id: String) -> String:
	return str(_atores[id].nome) if _atores.has(id) else ""


func ator_pos(id: String) -> Vector2:
	return _atores[id].pos if _atores.has(id) else Vector2.ZERO


## Ponto logo acima da cabeça de um ator (head_anchor da folha atual; espelha o x se ele está virado).
func cabeca_do_ator(id: String) -> Vector2:
	if not _atores.has(id):
		return Vector2.ZERO
	var a: Dictionary = _atores[id]
	var h: Array = UiTema.sprite(str(a.nome)).get("head_anchor", [1, -65])
	var natural := "left" if str(UiTema.sprite(str(a.nome)).get("facing", "direita")) == "esquerda" else "right"
	var hx := float(h[0]) * (-1.0 if str(a.facing) != natural else 1.0)  # folha própria da esquerda já vem virada
	return Vector2(a.pos) + Vector2(hx, float(h[1]))


## Retângulos das cabeças dos atores visíveis (menos `excluir`): o balão não cobre ninguém.
func cabecas_a_evitar(excluir: String) -> Array:
	var r: Array = []
	for id in _atores:
		if id == excluir or not ator_visivel(str(id)):
			continue
		var h := cabeca_do_ator(str(id))
		r.append(Rect2(h.x - 9.0, h.y, 18.0, 18.0))
	if sala != null and sala.mentor2_visivel():  # 6b2: quem passou o posto fica parado no canto e nenhum balão o cobre
		var h2 := sala.cabeca_mentor2()
		r.append(Rect2(h2.x - 9.0, h2.y, 18.0, 18.0))
	return r


func _process(delta: float) -> void:
	for id in _atores:
		var a: Dictionary = _atores[id]
		var m: Dictionary = a.mov
		if m.is_empty():
			continue
		m.t = float(m.t) + delta
		var k := clampf(float(m.t) / maxf(float(m.dur), 0.001), 0.0, 1.0)
		a.pos = Vector2(m.de).lerp(Vector2(m.para), k).round()
		_posicionar(a)
		if k >= 1.0:
			a.mov = {}


# --- Eventos do CenaPlayer ---

func evento(ev: Dictionary) -> void:
	if not _ativa:
		return
	var tipo := str(ev.get("tipo", ""))
	match tipo:
		"pose", "move", "face", "show", "hide":
			var aid := str(ev.get("ator", ""))
			if _liberados.has(aid):
				if tipo == "pose" and aid == "first":
					sala.cena_mentor_pose(str(ev.get("anim", "sit_rest")))
				return
			_evento_ator(tipo, ev)
		"prop":
			_evento_prop(ev)
		"sound":
			_som(ev)
		"camera":
			sala.cena_camera(int(ev.get("scale", 1)), ev.get("rect", []))
		"shake":
			sala.cena_tremer(int(ev.get("px", 1)), float(ev.get("seconds", 0.1)))
		"fx":
			sala.cena_fx(str(ev.get("sprite", "")), ev.get("pos", []))


func _evento_ator(tipo: String, ev: Dictionary) -> void:
	if str(ev.get("adereco", "")) != "":
		var p: Dictionary = _props.get(str(ev.adereco), {})
		if p.get("sp", null) != null:
			(p.sp as AnimSprite).visible = tipo == "show"
		return
	var a: Dictionary = _atores.get(str(ev.get("ator", "")), {})
	if a.is_empty() or bool(a.get("ausente", false)):
		return  # ator que não existe nesta cena (ex.: sem esteira, sem último que passou o posto): passos pulados
	if str(ev.get("facing", "")) != "":
		a.facing = str(ev.facing)
	match tipo:
		"show", "hide":
			a.visivel = tipo == "show"
			_posicionar(a)
		"face":
			_aplicar_flip(a)
		"pose":
			if str(ev.get("glove", "")) != "":
				a.glove = str(ev.glove)
			var anim := str(ev.get("anim", "idle"))
			_pose(a, anim, bool(ev.get("loop", false)), ev.get("frames", []), 0.5 if bool(ev.get("slow", false)) else 1.0,
				int(ev.get("times", 1)), float(ev.get("gap", 0.0)), -1, str(ev.get("folha", "")))
			if anim == "sit_down" or anim == "sit_rest":
				sala.cena_caixote(true)  # o caixote aparece quando o John vai sentar
		"move":
			var de: Vector2 = a.pos
			var para := _ponto(ev.get("to", []))
			a.mov = {"de": de, "para": para, "t": 0.0, "dur": float(ev.get("seconds", 0.5))}
			_pose(a, str(ev.get("anim", "walk")), true, [], 1.0)
			if float(ev.get("seconds", 0.5)) <= 0.0:
				a.pos = para
				a.mov = {}
				_posicionar(a)


func _evento_prop(ev: Dictionary) -> void:
	var id := str(ev.get("id", ""))
	var p: Dictionary = _props.get(id, {})
	if p.is_empty():
		return
	if str(p.sala) != "":
		var anim := str(ev.get("anim", ""))
		var q = ev.get("frame", null)
		if str(p.sala) == "punching_bag":
			if ev.get("visible", null) != null:
				sala.cena_saco_visivel(bool(ev.visible))
			if anim != "" or q != null:
				sala.cena_saco(anim, int(q) if q != null else 0)
		elif str(p.sala) == "lamp":
			sala.cena_lampada(anim)
		return
	var sp: AnimSprite = p.sp
	if ev.get("visible", null) != null:
		sp.visible = bool(ev.visible)
	if ev.get("frame", null) != null:
		sp.parar(int(ev.frame))
	elif str(ev.get("anim", "")) != "":
		_anim_prop(sp, str(ev.anim))


func _anim_prop(sp: AnimSprite, anim: String) -> void:
	var s := UiTema.sprite(sp.nome_sprite)
	var mapa = s.get("anim", {})
	if not (mapa is Dictionary) or not mapa.has(anim):
		return
	var seq: Array = []
	for q in mapa[anim]:
		seq.append(int(q))
	if seq.size() <= 1:
		sp.parar(int(seq[0]) if seq.size() == 1 else 0)
	else:
		sp.tocar(seq, float(s.get("fps", 10.0)), false)


# --- Estados inteiros (pular, abrir um save na criação) ---

func aplicar_estado(e: Dictionary) -> void:
	if not _ativa:
		return
	for id in e.get("actors", {}):
		var v = e.actors[id]
		var a: Dictionary = _atores.get(str(id), {})
		if a.is_empty() or not (v is Dictionary):
			continue
		if v.has("facing"):
			a.facing = str(v.facing)
		if v.has("glove"):
			a.glove = str(v.glove)
		if v.has("pos"):
			a.pos = _ponto(v.pos)
		a.mov = {}
		if v.has("visible"):
			a.visivel = bool(v.visible)
		if v.has("anim"):
			_pose(a, str(v.anim), not v.has("frame"), [], 1.0, 1, 0.0, int(v.get("frame", -1)))
		_posicionar(a)
	for id in e.get("props", {}):
		var v = e.props[id]
		if v is Dictionary:
			_evento_prop({"id": str(id), "visible": v.get("visible", null), "anim": str(v.get("anim", "")), "frame": v.get("frame", null)})
	if e.has("camera"):
		sala.cena_camera(int(e.camera.get("scale", 1)), e.camera.get("rect", []))
	for s in e.get("sounds", {}).get("stop", []):
		_parar_laco(str(s), 0.0)
	var f1 = e.get("actors", {}).get("first", null)
	if f1 is Dictionary and str(f1.get("anim", "")).begins_with("sit"):
		sala.cena_caixote(true)


## O controle voltou ao jogador: os atores do palco somem e a sala do jogo assume (o John vira o mentor da sala).
func devolver_controle() -> void:
	if not _ativa:
		return
	for id in _atores:
		var a: Dictionary = _atores[id]
		a.visivel = false
		a.mov = {}
		_posicionar(a)
	if _atores.has("first"):
		_liberados["first"] = true
	sala.cena_palco_liberado()
	if _liberados.has("first"):
		sala.cena_mentor_pose("sit_rest")


## A linha do tempo acabou: sem porta, sem luz do dia, sem sons em laço.
func terminar() -> void:
	var tinha_john := _liberados.has("first")
	for id in _props:
		var p: Dictionary = _props[id]
		if p.get("sp", null) != null:
			(p.sp as Node).queue_free()
	_props.clear()
	for id in _atores:
		(_atores[id].sp as Node).queue_free()
		(_atores[id].sombra as Node).queue_free()
	_atores.clear()
	for id in _lacos.keys():
		_parar_laco(str(id), 0.3)
	_ativa = false
	sala.cena_palco_liberado()
	if tinha_john:
		_liberados["first"] = true  # a reação do 1º clique ainda pode mexer no John da sala
		_ativa = true


## A saída do John acabou (sozinha ou interrompida): o palco some e a sala redesenha pelo que o jogo diz agora.
func terminar_livre() -> void:
	for id in _props:
		var p: Dictionary = _props[id]
		if p.get("sp", null) != null:
			(p.sp as Node).queue_free()
	_props.clear()
	for id in _atores:
		(_atores[id].sp as Node).queue_free()
		(_atores[id].sombra as Node).queue_free()
	_atores.clear()
	for id in _lacos.keys():
		_parar_laco(str(id), 0.3)
	_ativa = false
	_livre = false
	sala.cena_livre_encerrada()


## A reação acabou, foi cancelada ou descartada: nada mais para entregar.
func encerrar_reacoes() -> void:
	_liberados.clear()
	if _atores.is_empty():
		_ativa = false


# --- Sons ---

func _som(ev: Dictionary) -> void:
	var id := str(ev.get("id", ""))
	if bool(ev.get("stop", false)):
		_parar_laco(id, float(ev.get("fade", 0.0)))
		return
	var vol := float(ev.get("volume", 1.0))
	if bool(ev.get("loop", false)):
		if _lacos.has(id):
			return
		var caminho := "res://assets/sfx/%s.wav" % id
		if not ResourceLoader.exists(caminho):
			return
		var st := (load(caminho) as AudioStreamWAV).duplicate() as AudioStreamWAV
		var amostras := st.data.size() / (2 if st.format == AudioStreamWAV.FORMAT_16_BITS else 1) / (2 if st.stereo else 1)
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = amostras
		var p := AudioStreamPlayer.new()
		p.stream = st
		p.volume_db = linear_to_db(maxf(vol, 0.01)) - 4.0
		add_child(p)
		p.play()
		_lacos[id] = p
	else:
		sala.sfx.por_id(id, vol)


func _parar_laco(id: String, fade: float) -> void:
	if not _lacos.has(id):
		return
	var p: AudioStreamPlayer = _lacos[id]
	_lacos.erase(id)
	if fade > 0.0 and is_inside_tree():
		var tw := p.create_tween()
		tw.tween_property(p, "volume_db", -60.0, fade)
		tw.tween_callback(p.queue_free)
	else:
		p.stop()
		p.queue_free()
