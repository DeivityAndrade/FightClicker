class_name TelaRonda
extends Control
## Ronda Noturna do Gato Preto: tela do minigame "Estátua no telhado". Rua da borracharia à noite, vista de cima do muro: o vulto anda
## agachado no muro (segurar o botão ou o Espaço), vira estátua ao soltar, e quando está PERTO do ladrão o próximo aperto é o SUSTO!
## Tela própria 640x360 por cima da sala (mesmo padrão das telas do treino fora de hora da 7a2): cenário e camadas da lenda,
## HUD (LENDA, ocorrência, tempo, SAIR, instrução), contagem, juice (letreiro, tremida, flash, poeira, props voando) e a tela de prêmio.
## A UI só lê `GameState.ronda_jogo().estado()` e manda `apertar()` / `soltar()`; quem faz o tempo passar é o tick do GameState
## (a UI NÃO chama `passo`). Nenhuma regra de jogo aqui: distâncias, avisos, SUSTO, VISTO e prêmio vêm prontos da lógica.
## Contrato de arte: manifest.minigame_layout.ronda (docs/arte/ronda-manifest.md). O vulto e os ladrões usam as folhas do Artista de
## Personagens quando existirem no manifest (NOMES_VULTO / NOMES_LADRAO); sem elas, dublês de código (placeholder, trocar a arte = trocar o arquivo).

const TELA := Vector2(640, 360)
const Z_MUNDO := 100
const Z_HUD := 500
## Folhas do vulto por estado e do ladrão por ocorrência/estado. Preencher quando o Artista registrar (ronda-personagens-manifest.md).
const NOMES_VULTO := {"walk": "ronda_vulto_walk", "still": "ronda_vulto_still", "scare": "ronda_vulto_scare"}
const NOMES_LADRAO := {"tire": "ronda_thief_tire", "bike": "ronda_thief_bike", "gate": "ronda_thief_gate"}
const DUBLE_LADRAO := {"tire": "ped_trabalhador_walk", "bike": "ped_estudante_walk", "gate": "ped_trabalhador_walk"}
const COR_LADRAO := Color(0.55, 0.55, 0.68)
const PULO_S := 0.3  # o vulto salta do muro até a calçada
const FUGA_S := 0.75

var info: Dictionary = {}
var premio: Dictionary = {}
var janela: JanelaPremioRonda
var sfx: Sfx

var _mundo: Node2D  # cenário, vulto, ladrão, letreiros e efeitos (posição livre de propósito; treme)
var _hud: Control  # parte fixa: não treme
var _flash: ColorRect
var _botao_sair: Button
var _rotulo_tempo: Label
var _rotulo_ocorrencia: Label
var _pips_sustos: Array = []
var _pips_lenda: Array = []
var _dica: Label
var _titulo: Label
var _centro: Label
var _fase := ""
var _oc_atual := -1
var _oc_fase_antes := ""
var _ladrao_antes := ""
var _segurava := false

var _barra: Control
var _barra_fill: TextureRect
var _barra_zone: TextureRect
var _fill_tex: Array = []
var _zone_tex: Array = []
var _vulto: Node2D
var _vulto_dub: Node2D
var _vulto_anim: AnimSprite
var _ladrao: AnimSprite
var _ladrao_base := Vector2.ZERO
var _aviso: AnimSprite
var _perto: AnimSprite
var _estepe: AnimSprite
var _banner_susto: AnimSprite
var _banner_fugiu: AnimSprite
var _tween_vulto: Tween
var _tween_ladrao: Tween
var _tween_fuga: Tween
var _tween_flash: Tween
var _tween_centro: Tween
var _tw_banners: Array = []
var _t := 0.0
var _shake_t := 0.0
var _shake_dur := 0.1
var _shake_amp := 0
var _rng := RandomNumberGenerator.new()  # só enfeite (direção da tremida); o jogo nunca usa este


func layout() -> Dictionary:
	var l = UiTema.manifest().get("minigame_layout", {}).get("ronda", {})
	return l if l is Dictionary else {}


static func retangulo(a: Array) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


func abrir(info_: Dictionary) -> void:
	info = info_
	position = Vector2.ZERO
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.randomize()
	sfx = Sfx.new()
	add_child(sfx)
	_montar()
	set_process(true)


# ---------------------------------------------------------------- montagem
func _ocorrencias() -> Array:
	var ids: Array = info.get("occurrences", [])
	return ids if not ids.is_empty() else layout().get("occurrence_order", ["tire", "bike", "gate"])


func _dados_oc(id: String) -> Dictionary:
	var d = layout().get("occurrences", {}).get(id, {})
	return d if d is Dictionary else {}


func _montar() -> void:
	var L := layout()
	var fundo := ColorRect.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.color = UiTema.INK
	fundo.size = TELA
	add_child(fundo)
	_mundo = Node2D.new()
	_mundo.z_index = Z_MUNDO
	UiTema.alinhar(_mundo, "ignore")
	add_child(_mundo)
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = UiTema.textura(str(L.get("bg", "ronda_bg")))
	bg.z_index = -100
	_mundo.add_child(bg)
	# As camadas da lenda (cumulativas, na ordem do ronda.json), atrás de todo mundo.
	var camadas: Dictionary = L.get("layers", {})
	for nome in info.get("layers", []):
		var folha := str(camadas.get(str(nome), ""))
		if folha == "" or UiTema.sprite(folha).is_empty():
			continue
		var s := Sprite2D.new()
		s.centered = false
		s.texture = UiTema.textura(folha)
		s.z_index = -90
		_mundo.add_child(s)
	_montar_barra()
	_montar_palco()
	_montar_hud()
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = TELA
	_flash.z_index = 800
	add_child(_flash)
	_nova_ocorrencia(0)


## Textura de um quadro de uma folha pequena (para repetir em ladrilho): a AtlasTexture não ladrilha, então vira uma imagem própria.
func _quadro_img(nome: String, indice: int) -> Texture2D:
	var q := UiTema.tamanho_quadro(nome)
	var img: Image = UiTema.textura(nome).get_image()
	return ImageTexture.create_from_image(img.get_region(Rect2i(int(q.x) * indice, 0, int(q.x), int(q.y))))


func _montar_barra() -> void:
	var T: Dictionary = layout().get("track", {})
	var sp: Dictionary = T.get("sprites", {})
	_barra = Control.new()
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra.z_index = 30
	UiTema.alinhar(_barra, "ignore")
	_mundo.add_child(_barra)
	var fr := str(sp.get("frame", "ui_ronda_track"))
	var fi := str(sp.get("fill", "ui_ronda_fill"))
	var zo := str(sp.get("zone", "ui_ronda_zone"))
	var nome_moldura := UiTema.nine_patch(_barra, fr, Rect2(0, 0, 40, float(T.get("h", 6))))
	nome_moldura.name = "Moldura"
	for i in 2:
		_fill_tex.append(_quadro_img(fi, i))
		_zone_tex.append(_quadro_img(zo, i))
	_barra_zone = TextureRect.new()
	_barra_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_zone.stretch_mode = TextureRect.STRETCH_TILE
	_barra_zone.texture = _zone_tex[0]
	_barra.add_child(_barra_zone)
	_barra_fill = TextureRect.new()
	_barra_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_fill.stretch_mode = TextureRect.STRETCH_TILE
	_barra_fill.texture = _fill_tex[0]
	_barra.add_child(_barra_fill)


func _montar_palco() -> void:
	# Estepe no chão (só na ocorrência do estepe, enquanto o ladrão trabalha).
	_estepe = AnimSprite.new()
	_estepe.z_index = 300
	_estepe.visible = false
	_mundo.add_child(_estepe)
	# O ladrão (dublê: pedestre da Panfletagem escurecido) e o aviso em cima da cabeça dele.
	_ladrao = AnimSprite.new()
	_mundo.add_child(_ladrao)
	_aviso = AnimSprite.new()
	_aviso.definir("ui_thief_warn")
	_aviso.z_index = 700
	_aviso.visible = false
	_mundo.add_child(_aviso)
	# O vulto: folha do Artista (quando existir) ou o dublê de código.
	_vulto = Node2D.new()
	_mundo.add_child(_vulto)
	_vulto_anim = AnimSprite.new()
	_vulto_anim.visible = false
	_vulto.add_child(_vulto_anim)
	_vulto_dub = _fazer_vulto_dub()
	_vulto.add_child(_vulto_dub)
	# O SUSTO! pequeno que pisca em cima do vulto quando está PERTO.
	_perto = AnimSprite.new()
	_perto.definir("ui_banner_scare_near")
	_perto.tocar([0, 1], 6.0, true)
	_perto.z_index = 720
	_perto.visible = false
	_mundo.add_child(_perto)
	# Letreiros do SUSTO! (grande, 2x, no meio) e do ESCAPOU (menor, em cima do ladrão).
	var sb: Dictionary = layout().get("scare_banner", {})
	_banner_susto = AnimSprite.new()
	_banner_susto.definir("ui_banner_scare")
	var bp: Array = sb.get("pos", [320, 118])
	_banner_susto.position = Vector2(float(bp[0]), float(bp[1]))
	_banner_susto.scale = Vector2(2, 2)
	_banner_susto.z_index = 900
	_banner_susto.visible = false
	_mundo.add_child(_banner_susto)
	_banner_fugiu = AnimSprite.new()
	_banner_fugiu.definir("ui_banner_escaped")
	_banner_fugiu.z_index = 900
	_banner_fugiu.visible = false
	_mundo.add_child(_banner_fugiu)


## Vulto de código: capa de lona caída reta, capuz com as orelhas largas e baixas e a faixa vermelha dos olhos com as pontas voando.
## Pés em (0,0), olhando para a direita. Só placeholder: a folha do Artista de Personagens substitui.
func _fazer_vulto_dub() -> Node2D:
	var raiz := Node2D.new()
	var preto := Color("1b1626")
	var luz := UiTema.D2
	var pecas := [
		[PackedVector2Array([Vector2(-22, 0), Vector2(8, 0), Vector2(14, -22), Vector2(4, -34), Vector2(-14, -30), Vector2(-20, -14)]), preto],
		[PackedVector2Array([Vector2(-14, -30), Vector2(4, -34), Vector2(0, -26), Vector2(-12, -23)]), luz],
		[PackedVector2Array([Vector2(-2, -44), Vector2(8, -44), Vector2(15, -44), Vector2(16, -34), Vector2(14, -27), Vector2(0, -27), Vector2(-3, -34)]), preto],
		[PackedVector2Array([Vector2(-2, -43), Vector2(1, -53), Vector2(6, -43)]), preto],
		[PackedVector2Array([Vector2(8, -43), Vector2(13, -52), Vector2(16, -42)]), preto],
		[PackedVector2Array([Vector2(1, -38), Vector2(16, -38), Vector2(17, -35), Vector2(1, -35)]), UiTema.R2],
		[PackedVector2Array([Vector2(1, -38), Vector2(-8, -41), Vector2(-7, -36), Vector2(1, -35)]), UiTema.R2],
	]
	for p in pecas:
		var poly := Polygon2D.new()
		poly.polygon = p[0]
		poly.color = p[1]
		raiz.add_child(poly)
	return raiz


func _montar_hud() -> void:
	var L := layout()
	var HS: Dictionary = L.get("hud_suggestion", {})
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.size = TELA
	_hud.z_index = Z_HUD
	add_child(_hud)
	# LENDA: o ícone, o nome e as 5 bolinhas do nível (o que a ronda constrói).
	var li: Array = HS.get("legend_icon", [8, 8])
	UiTema.textura_rect(_hud, "icon_legend", float(li[0]), float(li[1]))
	var ll: Array = HS.get("legend_label", [28, 8])
	var lbl := UiTema.rotulo(_hud, UiTema.txt("legend_label", "LENDA"), UiTema.WHITE, float(ll[0]), float(ll[1]), 0, HORIZONTAL_ALIGNMENT_LEFT, true, true)
	UiTema.alinhar(lbl, "left")
	var lp: Array = HS.get("legend_pips", [28, 18])
	var passo := float(HS.get("pip_step", 9))
	var nivel := int(info.get("level", 0))
	for i in 5:
		var pip := TelaTreino.imagem_quadro(_hud, "ui_legend_pip", 1 if i < nivel else 0, float(lp[0]) + passo * float(i), float(lp[1]))
		UiTema.alinhar(pip, "left")
		_pips_lenda.append(pip)
	# Caixa da ocorrência: o nome de quem está no muro e as 3 marcas de SUSTO (a lenda de cada ocorrência).
	var ob := retangulo(HS.get("occurrence_box", [252, 4, 136, 22]))
	ob.size.y = maxf(ob.size.y, 28.0)
	var cartao := UiTema.painel(_hud, "ui_card", ob)
	var area := UiTema.area_nove("ui_card", ob.size)
	_rotulo_ocorrencia = UiTema.rotulo_centrado(cartao, Rect2(area.position.x, area.position.y + 1.0, area.size.x, 10.0), "", UiTema.WHITE, 1, false, "center_h")
	var iw := 9.0
	var gap := 4.0
	var gw := iw * 3.0 + gap * 2.0
	var grupo := Control.new()
	grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grupo.size = Vector2(gw, iw)
	grupo.position = Vector2(roundf((ob.size.x - gw) / 2.0), area.position.y + 12.0)
	UiTema.alinhar(grupo, "center_h")
	cartao.add_child(grupo)
	for i in 3:
		var ic := UiTema.textura_rect(grupo, "icon_occurrence", (iw + gap) * float(i), 0.0)
		ic.modulate = Color(0.42, 0.4, 0.47)
		_pips_sustos.append(ic)
	# Tempo da noite: "27 S" no meio do cartão do canto.
	var tb := retangulo(HS.get("timer_box", [586, 4, 48, 18]))
	var tcard := UiTema.painel(_hud, "ui_card", tb)
	var ta := UiTema.area_nove("ui_card", tb.size)
	_rotulo_tempo = UiTema.rotulo_centrado(tcard, ta, "", UiTema.WHITE, 1, false, "center_h")
	# SAIR: em qualquer momento; leva a lenda do que já fez.
	var sb := retangulo(HS.get("exit_button", [8, 334, 48, 18]))
	_botao_sair = UiTema.botao(_hud, sb)
	UiTema.botao_conteudo(_botao_sair, UiTema.txt("mini_exit", "SAIR"), UiTema.WHITE, 1)
	_botao_sair.pressed.connect(_sair)
	# Instrução (1 linha, no pé da tela, sobre o asfalto) e o título da noite durante a contagem.
	_dica = UiTema.rotulo(_hud, str(info.get("tip", "")).to_upper(), UiTema.CREAM, 0.0, 338.0, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_dica.size = Vector2(TELA.x, 12.0)
	UiTema.alinhar(_dica, "center_h")
	_titulo = UiTema.rotulo_centrado(_hud, Rect2(0, 108, TELA.x, 12), str(info.get("name", "")).to_upper(), UiTema.CREAM, 1, true, "center_h")
	_centro = UiTema.rotulo_centrado(_hud, Rect2(0, 130, TELA.x, 28), UiTema.txt("mini_ready", "PREPARAR"), UiTema.Y2, 2, true, "center_h")


# ---------------------------------------------------------------- ocorrência (trecho do muro)
func _nova_ocorrencia(i: int) -> void:
	_oc_atual = i
	var ids := _ocorrencias()
	var id := str(ids[mini(i, ids.size() - 1)])
	var D := _dados_oc(id)
	var th: Array = D.get("thief", [192, 314])
	_ladrao_base = Vector2(float(th[0]), float(th[1]))
	for t in [_tween_ladrao, _tween_fuga, _tween_vulto]:
		if t != null and t.is_valid():
			t.kill()
	_ladrao.position = _ladrao_base
	_ladrao.z_index = int(_ladrao_base.y)
	_ladrao.rotation = 0.0
	_ladrao.modulate = Color.WHITE
	_ladrao.flip_h = false
	_ladrao.visible = true
	_pose_ladrao(id, "work")
	_aviso.position = Vector2(_ladrao_base.x + 2.0, float(layout().get("thief_feet_y", 314)) - 70.0)
	_aviso.visible = false
	var tipo_estepe := str(D.get("prop_sprite", "")) == "ronda_prop_tire" and id == "tire"
	_estepe.visible = tipo_estepe
	if tipo_estepe:
		_estepe.definir("ronda_prop_tire")
		var pp: Array = D.get("prop", [212, 314])
		_estepe.position = Vector2(float(pp[0]), float(pp[1]))
		_estepe.rotation = 0.0
		_estepe.modulate = Color.WHITE
	_vulto.rotation = 0.0
	_vulto.modulate = Color.WHITE
	_vulto.z_index = int(layout().get("walk_y", 196))
	_vulto.position = Vector2(_x_vulto(id, 0.0), float(layout().get("walk_y", 196)))
	_pose_vulto("still")
	_banner_fugiu.visible = false
	_ajustar_barra(id)
	if _oc_atual > 0:
		_entrada_vulto()
	# Bolinhas de SUSTO: a ocorrência atual destaca (piscando de leve), as já feitas mostram o resultado (ver _atualizar_hud).


func _entrada_vulto() -> void:
	_vulto.modulate = Color(2.0, 2.0, 2.0)
	_vulto.scale = Vector2(1.0, 1.3)
	var tw := _vulto.create_tween().set_parallel(true)
	tw.tween_property(_vulto, "modulate", Color.WHITE, 0.25)
	tw.tween_property(_vulto, "scale", Vector2.ONE, 0.15)
	_poeira(_vulto.position + Vector2(0, 0))


func _x_vulto(id: String, dist: float) -> float:
	var D := _dados_oc(id)
	return roundf(lerpf(float(D.get("start", 26)), float(D.get("end", 146)), dist))


func _id_atual() -> String:
	var ids := _ocorrencias()
	return str(ids[mini(maxi(_oc_atual, 0), ids.size() - 1)])


## Barra de distância: do começo ao fim do trecho, embaixo da capa do muro. A zona do SUSTO (0,8 em diante) pisca por baixo do enchimento.
func _ajustar_barra(id: String) -> void:
	var T: Dictionary = layout().get("track", {})
	var D := _dados_oc(id)
	var x0 := float(D.get("start", 26)) - 4.0
	var x1 := float(D.get("end", 146)) + 4.0
	var h := float(T.get("h", 6))
	_barra.position = Vector2(x0, float(T.get("y", 206)))
	_barra.size = Vector2(x1 - x0, h)
	var m := _barra.get_node("Moldura") as Control
	m.size = Vector2(x1 - x0, h)
	var zona := float(T.get("zone_from", 0.8))
	var zx := float(D.get("start", 26)) + zona * (float(D.get("end", 146)) - float(D.get("start", 26))) - x0
	_barra_zone.position = Vector2(zx, 1.0)
	_barra_zone.size = Vector2(maxf(x1 - x0 - 1.0 - zx, 1.0), h - 2.0)
	_barra_fill.position = Vector2(1.0, 1.0)
	_barra_fill.size = Vector2(1.0, h - 2.0)


# ---------------------------------------------------------------- poses (folha do Artista ou dublê)
func _pose_vulto(estado: String) -> void:
	var nome := str(NOMES_VULTO.get(estado, ""))
	var tem := nome != "" and not UiTema.sprite(nome).is_empty()
	_vulto_anim.visible = tem
	_vulto_dub.visible = not tem
	if not tem:
		return
	_vulto_anim.definir(nome)
	var n := int(UiTema.sprite(nome).get("frames", 1))
	var seq: Array = []
	for i in n:
		seq.append(i)
	_vulto_anim.tocar(seq, float(UiTema.sprite(nome).get("fps", 8.0)), bool(UiTema.sprite(nome).get("loop", false)))


func _pose_ladrao(id: String, _estado: String) -> void:
	var nome := str(NOMES_LADRAO.get(id, ""))
	if nome == "" or UiTema.sprite(nome).is_empty():
		nome = str(DUBLE_LADRAO.get(id, "ped_trabalhador_walk"))
		_ladrao.definir(nome)
		_ladrao.parar(0)
		_ladrao.self_modulate = COR_LADRAO  # dublê escurecido; a folha do Artista vem com as cores dela
	else:
		_ladrao.definir(nome)
		_ladrao.self_modulate = Color.WHITE
		_ladrao.parar(0)


# ---------------------------------------------------------------- andamento
func _process(delta: float) -> void:
	_t += delta
	var j = GameState.ronda_jogo()
	if j == null:
		return  # a noite acabou por baixo (a sala já voltou); o Fluxo fecha esta tela
	var e: Dictionary = j.estado()
	_atualizar_fase(e)
	if int(e.ocorrencia) != _oc_atual and str(e.fase) != "fim":
		_nova_ocorrencia(int(e.ocorrencia))
	_atualizar_hud(e)
	_atualizar_palco(e, delta)
	for ev in j.pegar_eventos():
		_evento(str(ev), e)
	_atualizar_tremida(delta)
	_oc_fase_antes = str(e.oc_fase)
	_ladrao_antes = str(e.ladrao)
	if str(e.fase) == "fim" and janela == null:
		_concluir()


func _atualizar_fase(e: Dictionary) -> void:
	var fase := str(e.fase)
	if fase == _fase:
		return
	_fase = fase
	if _tween_centro != null and _tween_centro.is_valid():
		_tween_centro.kill()
	match fase:
		"contagem":
			_centro.text = UiTema.txt("mini_ready", "PREPARAR")
			_centro.modulate.a = 1.0
			_centro.visible = true
			_titulo.visible = true
		"jogando":
			_centro.text = UiTema.txt("mini_go", "VAI!")
			_centro.modulate.a = 1.0
			_centro.visible = true
			_titulo.visible = false
			sfx.sino_inicio()
			_tween_centro = create_tween()
			_tween_centro.tween_interval(0.45)
			_tween_centro.tween_property(_centro, "modulate:a", 0.0, 0.25)
			_tween_centro.tween_callback(func() -> void: _centro.visible = false)
		_:
			_centro.visible = false
			_titulo.visible = false


func _atualizar_hud(e: Dictionary) -> void:
	var restante := float(e.get("restante", 0.0))
	var n := int(ceil(restante - 1.0e-6)) if str(e.fase) != "fim" else 0
	var texto := UiTema.txt("mini_time", "{n} S", {"n": n})
	if _rotulo_tempo.text != texto:
		_rotulo_tempo.text = texto
	_botao_sair.visible = str(e.fase) != "fim" and janela == null
	var ids := _ocorrencias()
	var nomes: Array = info.get("occurrence_names", [])
	var i := mini(int(e.ocorrencia), ids.size() - 1)
	var nome := str(nomes[i]) if i < nomes.size() else UiTema.txt("ronda_occ_" + str(ids[i]), str(ids[i]).to_upper())
	if _rotulo_ocorrencia.text != nome.to_upper():
		_rotulo_ocorrencia.text = nome.to_upper()
	# Marcas de SUSTO: apagada = ainda não, ouro = SUSTO, vermelha = ESCAPOU; a da vez pisca devagar.
	var feitas := _resultados_ocorrencias(e)
	for k in _pips_sustos.size():
		var p: TextureRect = _pips_sustos[k]
		match str(feitas[k]):
			"susto":
				p.modulate = Color(1.0, 0.95, 0.6)
			"visto":
				p.modulate = Color(0.85, 0.3, 0.3)
			_:
				var viva := k == int(e.ocorrencia) and str(e.fase) == "jogando"
				p.modulate = Color(0.42, 0.4, 0.47).lerp(Color(0.75, 0.73, 0.8), 0.5 + 0.5 * sin(_t * 5.0)) if viva else Color(0.42, 0.4, 0.47)


## Resultado de cada ocorrência até agora ("susto" | "visto" | ""): a lógica só guarda os totais, o histórico é desta tela.
var _resultados: Array = ["", "", ""]


func _resultados_ocorrencias(_e: Dictionary) -> Array:
	return _resultados


func _atualizar_palco(e: Dictionary, delta: float) -> void:
	var id := _id_atual()
	var D := _dados_oc(id)
	var oc_fase := str(e.oc_fase)
	var dist := float(e.distancia)
	var walk_y := float(layout().get("walk_y", 196))
	# O vulto acompanha a distância no muro (no SUSTO e no ESCAPOU quem manda é a animação / a posição congelada).
	var andando := bool(e.segurando) and oc_fase == "jogando" and dist < 1.0
	if oc_fase in ["intro", "jogando"] and (_tween_vulto == null or not _tween_vulto.is_valid()):
		_vulto.position.x = _x_vulto(id, dist)
		_vulto.position.y = walk_y - (1.0 if andando and int(_t * 8.0) % 2 == 0 else 0.0)
	# Barra de distância: enchimento até o vulto; ouro quando PERTO.
	var x0 := float(D.get("start", 26))
	var larg := float(D.get("end", 146)) - x0
	_barra_fill.size.x = maxf(1.0, roundf(4.0 + larg * dist))
	var perto := bool(e.perto)
	_barra_fill.texture = _fill_tex[1 if perto else 0]
	_barra_zone.texture = _zone_tex[int(_t * 6.0) % 2] if oc_fase == "jogando" else _zone_tex[0]
	_barra.visible = oc_fase in ["intro", "jogando"] or (oc_fase == "visto")
	# SUSTO! pequeno piscando em cima do vulto.
	_perto.visible = perto
	_perto.position = Vector2(_vulto.position.x, walk_y - 50.0)
	# Aviso do ladrão (? começando, ? cheio, ! olhando).
	var lad := str(e.ladrao)
	if oc_fase in ["intro", "jogando"] and lad != "trabalha":
		_aviso.visible = true
		var f := 2 if lad == "olhando" else (0 if float(e.ladrao_frac) < 0.4 else 1)
		_aviso.parar(f)
	else:
		_aviso.visible = false
	# Ladrão: de costas trabalhando (balança de leve), virado para trás no OLHANDO.
	if oc_fase in ["intro", "jogando"]:
		_ladrao.flip_h = lad == "olhando"
		_ladrao.position.y = _ladrao_base.y - (1.0 if lad == "trabalha" and int(_t * 5.0) % 2 == 0 else 0.0)
	# Dica de "estátua": soltou o botão com o ladrão olhando.
	var seg := bool(e.segurando)
	if _segurava and not seg and lad == "olhando" and oc_fase == "jogando":
		_flutuar(UiTema.txt("ronda_still_hint", "ESTÁTUA"), UiTema.CREAM, Vector2(_vulto.position.x, walk_y - 62.0), 1, 10.0, 0.6)
	_segurava = seg


func _evento(ev: String, e: Dictionary) -> void:
	var id := _id_atual()
	match ev:
		"aviso":
			sfx.foco()
			_flutuar(UiTema.txt("ronda_warn_text", "SOLTE!"), UiTema.Y1, Vector2(_ladrao_base.x + 2.0, float(layout().get("thief_feet_y", 314)) - 90.0), 1, 8.0, 0.7)
		"susto":
			_resultado(int(e.ocorrencia), "susto")
			_susto(id)
		"visto":
			_resultado(int(e.ocorrencia), "visto")
			_visto(id)
		"fim_tempo", "sair":
			pass


func _resultado(i: int, r: String) -> void:
	if i >= 0 and i < _resultados.size():
		_resultados[i] = r


# ---------------------------------------------------------------- juice
## SUSTO!: o vulto salta do muro até a calçada; ao pousar sai a tremida, o flash e o letreiro; o ladrão cai de bunda, larga o objeto e foge.
func _susto(id: String) -> void:
	var D := _dados_oc(id)
	var walk_y := float(layout().get("walk_y", 196))
	var land: Array = D.get("land", [166, 314])
	var ini := _vulto.position
	var fim := Vector2(float(land[0]), float(land[1]))
	_perto.visible = false
	if _tween_vulto != null and _tween_vulto.is_valid():
		_tween_vulto.kill()
	_pose_vulto("scare")
	_vulto.z_index = int(fim.y) + 10
	_tween_vulto = create_tween()
	_tween_vulto.tween_method(func(k: float) -> void:
		var q := ini.lerp(fim, k)
		_vulto.position = Vector2(roundf(q.x), roundf(q.y - 58.0 * sin(k * PI))), 0.0, 1.0, PULO_S).set_trans(Tween.TRANS_SINE)
	_tween_vulto.tween_callback(func() -> void: _pousou(id, fim))
	_ladrao.flip_h = true


func _pousou(id: String, fim: Vector2) -> void:
	var D := _dados_oc(id)
	_tremer(3, 0.28)
	_piscar(Color.WHITE, 0.45, 0.22)
	sfx.golpe("punching_bag", true)
	sfx.queda()
	_poeira(fim)
	_poeira(_ladrao_base)
	_letreiro(_banner_susto, 2.0, 1.25)
	_pose_vulto("still")
	# O ladrão cai sentado e larga o que estava fazendo (o objeto voa), depois foge.
	_tween_ladrao = create_tween()
	_tween_ladrao.tween_property(_ladrao, "rotation", deg_to_rad(-70.0), 0.12)
	_tween_ladrao.tween_interval(0.3)
	_tween_ladrao.tween_callback(func() -> void:
		_ladrao.rotation = 0.0
		_ladrao.flip_h = false)
	_fugir_ladrao(0.0)
	_largar_objeto(id, D)


func _largar_objeto(id: String, D: Dictionary) -> void:
	var folha := str(D.get("prop_sprite", ""))
	if folha == "" or UiTema.sprite(folha).is_empty():
		return
	var pp: Array = D.get("prop", [212, 314])
	var obj := AnimSprite.new()
	obj.definir(folha)
	obj.z_index = 750
	var ini := Vector2(float(pp[0]), float(pp[1]))
	obj.position = ini
	_mundo.add_child(obj)
	if id == "tire":
		_estepe.visible = false
		obj.position = ini + Vector2(0, -10)
	var dest := ini + Vector2(60.0 + _rng.randf_range(0, 24.0), 30.0)
	var tw := obj.create_tween().set_parallel(true)
	tw.tween_method(func(k: float) -> void:
		var q := (ini + Vector2(0, -12)).lerp(dest, k)
		obj.position = Vector2(roundf(q.x), roundf(q.y - 46.0 * sin(k * PI)))
		obj.rotation = k * 9.0, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(func() -> void:
		_poeira(dest)
		obj.queue_free())


## Ladrão correndo para a direita, para fora da tela (some no fim). `atraso` espera antes de sair correndo.
func _fugir_ladrao(atraso: float) -> void:
	var tw := create_tween()
	_tween_fuga = tw
	tw.tween_interval(0.3 + atraso)
	tw.tween_callback(func() -> void:
		_ladrao.flip_h = false
		if _ladrao.nome_sprite.ends_with("_walk"):
			_ladrao.tocar([0, 1, 2, 3, 4, 5, 6, 7], 14.0, true))
	tw.tween_method(func(k: float) -> void:
		_ladrao.position = Vector2(roundf(_ladrao_base.x + 150.0 * k), _ladrao_base.y)
		_ladrao.modulate.a = 1.0 - maxf(0.0, (k - 0.6) / 0.4), 0.0, 1.0, FUGA_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## ESCAPOU: o ladrão grita e foge correndo; letreiro cinza menor, sem tremida (falha leve).
func _visto(id: String) -> void:
	var feet := float(layout().get("thief_feet_y", 314))
	_perto.visible = false
	_banner_fugiu.position = Vector2(_ladrao_base.x, feet - 90.0)
	sfx.bloqueio()
	_letreiro(_banner_fugiu, 1.0, 0.9)
	_ladrao.flip_h = true
	_fugir_ladrao(0.05)


## Letreiro que dá um "pop" de escala e some.
func _letreiro(spr: AnimSprite, escala: float, dur: float) -> void:
	for t in _tw_banners:
		if t != null and t.is_valid():
			t.kill()
	_tw_banners.clear()
	spr.visible = true
	spr.modulate = Color.WHITE
	spr.scale = Vector2(escala * 1.5, escala * 1.5)
	var tw := spr.create_tween().set_parallel(true)
	tw.tween_property(spr, "scale", Vector2(escala, escala), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "modulate:a", 0.0, 0.25).set_delay(maxf(dur - 0.25, 0.1))
	tw.chain().tween_callback(func() -> void: spr.visible = false)
	_tw_banners.append(tw)


func _poeira(p: Vector2) -> void:
	if UiTema.sprite("fx_dust_fall").is_empty():
		return
	var d := AnimSprite.new()
	d.definir("fx_dust_fall")
	d.position = p
	d.z_index = 740
	_mundo.add_child(d)
	d.tocar([0, 1, 2, 3], 12.0, false, d.queue_free)


## Texto que sobe e some, centrado em `p` (coordenadas do mundo), com contorno.
func _flutuar(texto: String, cor: Color, p: Vector2, escala: int = 1, subida: float = 16.0, dur: float = 0.85) -> void:
	var l := UiTema.rotulo(_mundo, texto, cor, 0, 0, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	l.size = Vector2(220.0, 12.0)
	l.scale = Vector2(escala, escala)
	l.z_index = 900
	l.position = Vector2(roundf(p.x - 110.0 * float(escala)), roundf(p.y))
	var tw := l.create_tween().set_parallel(true)
	tw.tween_method(func(k: float) -> void: l.position.y = roundf(p.y - subida * k), 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
	tw.chain().tween_callback(l.queue_free)


func _tremer(amp: int, dur: float) -> void:
	if amp >= _shake_amp or _shake_t <= 0.0:
		_shake_amp = amp
		_shake_dur = dur
		_shake_t = dur


func _atualizar_tremida(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t -= delta
		var amp := 0
		if _shake_t > 0.0:
			amp = maxi(1, int(round(float(_shake_amp) * _shake_t / _shake_dur)))
		_mundo.position = Vector2(_rng.randi_range(-amp, amp), _rng.randi_range(-amp, amp)) if amp > 0 else Vector2.ZERO
	elif _mundo.position != Vector2.ZERO:
		_mundo.position = Vector2.ZERO


func _piscar(cor: Color, alfa: float, dur: float = 0.16) -> void:
	if _tween_flash != null and _tween_flash.is_valid():
		_tween_flash.kill()
	_flash.color = Color(cor, alfa)
	_tween_flash = create_tween()
	_tween_flash.tween_property(_flash, "color:a", 0.0, dur)


# ---------------------------------------------------------------- fim, SAIR e prêmio
func _sair() -> void:
	if janela != null:
		return
	_concluir()


## Aplica e mostra o prêmio (uma vez). `ronda_concluir()` encerra a noite se ainda estava rodando (SAIR) e devolve o mesmo prêmio de novo.
func _concluir() -> void:
	if janela != null:
		return
	premio = GameState.ronda_concluir()
	if premio.is_empty():
		return
	_soltar()
	_centro.visible = false
	_titulo.visible = false
	_botao_sair.visible = false
	_perto.visible = false
	janela = JanelaPremioRonda.new()
	add_child(janela)
	janela.abrir_com(premio, info)
	janela.voltar_pedido.connect(_voltar)
	if int(premio.get("scares", 0)) > 0:
		sfx.vitoria()
	else:
		sfx.moeda()


## VOLTAR: devolve a sala. O Fluxo fecha esta tela quando o GameState avisa (`ronda_mudou("")`).
func _voltar() -> void:
	GameState.ronda_voltar()


# ---------------------------------------------------------------- entradas
func _apertar() -> void:
	var j = GameState.ronda_jogo()
	if j != null and janela == null:
		j.apertar()


func _soltar() -> void:
	var j = GameState.ronda_jogo()
	if j != null:
		j.soltar()


func _gui_input(event: InputEvent) -> void:
	if janela != null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_apertar()
		accept_event()


func _input(event: InputEvent) -> void:
	if janela != null or not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_soltar()
	elif event is InputEventKey and event.keycode == KEY_SPACE:
		if not event.echo:
			if event.pressed:
				_apertar()
			else:
				_soltar()
		get_viewport().set_input_as_handled()  # o Espaço nunca chega ao treino da garagem


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_soltar()  # perdeu o foco com o botão apertado: larga (senão o vulto anda sozinho)
