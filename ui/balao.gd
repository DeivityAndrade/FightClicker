class_name Balao
extends Control
## Balão de fala preso a um personagem (Fase 6a, docs/cutscenes/balao-e-voz.md). Modo passivo: não recebe mouse,
## escreve letra a letra (28 c/s por padrão, pausas na pontuação), toca um blip de voz a cada 2 letras e some sozinho
## depois do tempo de leitura. Nunca cobre a zona do alvo (NO_COVER). Só desenho e som: quem decide quando falar é o GameState.
## Coordenadas = base 640x360 (a Garagem é a pai).

signal fechou(id: String, speaker: String)  # saiu da tela (leitura acabou ou cancelado)
signal falando(speaker: String, sim: bool)  # escrevendo (sim) / parou de escrever (não)

const NO_COVER := Rect2(310, 180, 52, 94)
const UTIL := Rect2(132, 22, 375, 263)  # sala (132..507, 22..285)
const AVANCO := 6
const MARGEM_H := 8
const TAIL_MAX_DESVIO := 6
const PONTA_MAX_Y := 178
const PASTA_VOZ := "res://assets/sfx/"
const MULT_PERGUNTA := [1.06, 1.12, 1.19]

static var _vozes: Dictionary = {}

var id := ""
var speaker := ""
var corpo := Rect2()  # retângulo do balão (sem plaquinha nem rabicho), na base
var _linhas: Array = []
var _rotulos: Array[Label] = []
var _chars_por_linha: Array = []
var _tempos: Array[float] = []  # instante em que cada letra aparece
var _blips: Dictionary = {}  # índice da letra -> {vogal, mult, db}
var _total_chars := 0
var _escreve := 0.0
var _total := 0.0
var _t := 0.0
var _visivel := 0
var _completo_por_clique := false
var _ativo := false
var _entrada := 0.0
var _raiz: Control
var _fundo: NinePatchRect
var _player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _timbre := "first"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(640, 360)
	z_index = 2400  # acima da sala e dos números, abaixo de qualquer janela (Fluxo = 3000)
	_rng.randomize()
	_player = AudioStreamPlayer.new()
	add_child(_player)
	set_process(false)


func ativo() -> bool:
	return _ativo


## Retângulo que o balão inteiro ocupa (plaquinha em cima e rabicho embaixo) para a conferência da zona proibida.
func retangulo_total() -> Rect2:
	if not _ativo:
		return Rect2()
	return Rect2(corpo.position.x, corpo.position.y - 6.0, corpo.size.x, corpo.size.y + 6.0 + 4.0)


# --- Posição (balao-e-voz.md §3) ---

## Devolve {ok, corpo, ponta_x, ponta_y}. `cabeca` = ponto logo acima da cabeça.
static func calcular(cabeca: Vector2, w: float, h: float, evitar: Array = []) -> Dictionary:
	var by := cabeca.y - h - 9.0  # ponta do rabicho 6 px acima da cabeça; ponta = by + h + 3
	var bx := cabeca.x - floorf(w / 2.0)
	var r := _dentro(Rect2(bx, by, w, h))
	var modo := "em_cima"
	if _toca(r, evitar):
		# 2: desliza para o lado de onde o personagem está até ficar 2 px fora da zona.
		var esq := cabeca.x < 336.0
		var rx := (NO_COVER.position.x - 2.0 - w) if esq else (NO_COVER.end.x + 2.0)
		var d := _dentro(Rect2(rx, by, w, h))
		var ponta := clampf(cabeca.x, d.position.x + 8.0, d.end.x - 8.0)
		if absf(ponta - cabeca.x) <= TAIL_MAX_DESVIO and not _toca(d, evitar):
			r = d
			modo = "desliza"
		else:
			# 3: volta ao centro e SOBE até a ponta do rabicho ficar em y <= 178.
			r = _dentro(Rect2(bx, by, w, h))
			var ponta_y := r.position.y + h + 3.0
			if ponta_y > PONTA_MAX_Y:
				r.position.y -= ponta_y - PONTA_MAX_Y
			modo = "sobe"
			if _toca(r, evitar) or r.position.y - 6.0 < UTIL.position.y:
				return {"ok": false}
	var ponta_x := clampf(cabeca.x, r.position.x + 8.0, r.end.x - 8.0)
	return {"ok": true, "corpo": r, "ponta_x": ponta_x, "ponta_y": r.position.y + h + 3.0, "modo": modo}


static func _dentro(r: Rect2) -> Rect2:
	var x := clampf(r.position.x, UTIL.position.x, UTIL.end.x - r.size.x)
	var y := maxf(r.position.y, UTIL.position.y + 6.0)  # a plaquinha sai 6 px por cima
	return Rect2(floorf(x), floorf(y), r.size.x, r.size.y)


## O balão inteiro (plaquinha em cima, rabicho embaixo) toca a zona do alvo ou a cabeça de outro personagem?
static func _toca(r: Rect2, evitar: Array = []) -> bool:
	var total := Rect2(r.position.x, r.position.y - 6.0, r.size.x, r.size.y + 10.0)
	if total.intersects(NO_COVER):
		return true
	for e in evitar:
		if total.intersects(e):
			return true
	return false


# --- Mostrar / fechar ---

## `faixa_y`: base da faixa de aviso do topo, se estiver visível (o balão não cobre a faixa).
func mostrar(id_: String, speaker_: String, texto: String, cabeca: Vector2, faixa_base_y: float = -1.0, evitar: Array = []) -> bool:
	fechar_agora(false)
	id = id_
	speaker = speaker_
	_linhas = texto.split("\n")
	var maior := 0
	for l in _linhas:
		maior = maxi(maior, str(l).length())
	var w := clampf(float(maior * AVANCO + 16), 40.0, 172.0)
	var h := 26.0 if _linhas.size() > 1 else 17.0
	var c := calcular(cabeca, w, h, evitar)
	if not bool(c.ok) or (faixa_base_y >= 0.0 and Rect2(c.corpo).position.y - 6.0 < faixa_base_y):
		push_warning("Balao: a fala '%s' não cabe sem cobrir o alvo; descartada." % id_)
		return false
	corpo = c.corpo
	_montar(w, h, Vector2(float(c.ponta_x), float(c.ponta_y)))
	_preparar_tempos(texto)
	_t = 0.0
	_visivel = 0
	_completo_por_clique = false
	_ativo = true
	_entrada = 0.06  # entra em 2 quadros: metade do tamanho, depois inteiro
	_raiz.visible = true
	_aplicar_entrada(true)
	set_process(true)
	falando.emit(speaker, true)
	return true


func _montar(w: float, h: float, ponta: Vector2) -> void:
	if _raiz != null:
		_raiz.queue_free()
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.size = Vector2(640, 360)
	add_child(_raiz)
	var by_data: Dictionary = UiTema.manifest().get("by_data_id", {}).get("speech_bubble", {})
	_fundo = UiTema.nine_patch(_raiz, "ui_balloon", corpo)
	# Rabicho: central, ou à esquerda/direita quando a ponta fica perto da borda.
	var perto_e := ponta.x - corpo.position.x < 14.0
	var perto_d := corpo.end.x - ponta.x < 15.0
	var nome_t := str(by_data.get("tail_l", "ui_balloon_tail_l")) if perto_e else (str(by_data.get("tail_r", "ui_balloon_tail_r")) if perto_d else str(by_data.get("tail", "ui_balloon_tail")))
	var off: Array = by_data.get("tail_rule", {}).get("tip_offset", {}).get("l" if perto_e else ("r" if perto_d else "c"), [3, 5])
	UiTema.textura_rect(_raiz, nome_t, ponta.x - float(off[0]), corpo.position.y + h - 2.0)
	# Texto: linhas à esquerda, bloco centrado; Label em y = by + 3 (célula do BMFont).
	_rotulos.clear()
	_chars_por_linha.clear()
	for i in _linhas.size():
		var l := UiTema.rotulo(_raiz, str(_linhas[i]), UiTema.INK, corpo.position.x + float(MARGEM_H), corpo.position.y + 3.0 + 9.0 * float(i), 0,
			HORIZONTAL_ALIGNMENT_LEFT, false)
		_rotulos.append(l)
		_chars_por_linha.append(str(_linhas[i]).length())
	# Plaquinha do nome na cor do personagem.
	var p: Dictionary = GameState.dialogos.personagem(speaker)
	var cor_nome := str(by_data.get("tag_by_speaker", {}).get(speaker, "gray"))
	var nome := str(p.get("short", speaker))
	var tw := float(nome.length() * AVANCO + 6)
	var tag := UiTema.nine_patch(_raiz, str(by_data.get("tag_by_color", {}).get(cor_nome, "ui_balloon_tag_gray")),
		Rect2(corpo.position.x + 6.0, corpo.position.y - 6.0, tw, 10.0))
	var cor_txt := UiTema.WHITE if str(by_data.get("tag_text_color", {}).get(cor_nome, "ink")) == "white" else UiTema.INK
	UiTema.rotulo(tag, nome, cor_txt, 3.0, 0.0, 0, HORIZONTAL_ALIGNMENT_LEFT, false)
	_timbre = str(p.get("voice", speaker))


func _aplicar_entrada(meia: bool) -> void:
	if _raiz == null:
		return
	for c in _raiz.get_children():
		if c != _fundo:
			(c as CanvasItem).visible = not meia
	if meia:
		var w := floorf(corpo.size.x / 2.0)
		var h := floorf(corpo.size.y / 2.0)
		_fundo.size = Vector2(w, h)
		_fundo.position = Vector2(corpo.position.x + floorf((corpo.size.x - w) / 2.0), corpo.end.y - h)
	else:
		_fundo.size = corpo.size
		_fundo.position = corpo.position


func _preparar_tempos(texto: String) -> void:
	var tp: Dictionary = GameState.dialogos.typing
	var cps := float(GameState.dialogos.voices.get(_timbre, {}).get("cps", 28.0))
	var plano := texto.replace("\n", "")
	_total_chars = plano.length()
	_tempos.clear()
	_blips.clear()
	var acum := 0.0
	var letras := 0
	var cada := maxi(1, int(tp.get("blip_every_letters", 2)))
	var ult_vogal := "a"
	var lista_blips: Array = []
	for i in _total_chars:
		acum += 1.0 / maxf(cps, 1.0)
		_tempos.append(acum)
		var c := plano[i]
		if i < _total_chars - 1:
			if c in [",", ";", ":"]:
				acum += float(tp.get("pause_comma", 0.12))
			elif c in [".", "!", "?"]:
				var reticencias: bool = c == "." and ((i > 0 and plano[i - 1] == ".") or plano[i + 1] == ".")
				acum += float(tp.get("pause_ellipsis_dot", 0.13)) if reticencias else float(tp.get("pause_stop", 0.28))
		if _eh_letra(c):
			if letras % cada == 0:
				var v := _vogal(c)
				if v == "":
					# vogal do par: a letra seguinte
					var j := i + 1
					while j < _total_chars and not _eh_letra(plano[j]):
						j += 1
					v = _vogal(plano[j]) if j < _total_chars else ""
				if v == "":
					v = ult_vogal
				ult_vogal = v
				var maiusc: bool = c != c.to_lower()
				lista_blips.append(i)
				_blips[i] = {"vogal": v, "mult": 1.122 if maiusc else 1.0, "db": 2.0 if maiusc else 0.0}
			letras += 1
	_escreve = acum
	var leitura := maxf(float(tp.get("hold_min", 1.2)), float(tp.get("hold_per_char", 0.06)) * float(_total_chars))
	_total = _escreve + leitura
	if plano.ends_with("?") and lista_blips.size() > 0:
		var n := mini(3, lista_blips.size())
		for k in n:
			var idx: int = lista_blips[lista_blips.size() - n + k]
			_blips[idx].mult = float(_blips[idx].mult) * float(MULT_PERGUNTA[3 - n + k])


static func _eh_letra(c: String) -> bool:
	return c.to_lower() != c.to_upper() or (c >= "0" and c <= "9")


static func _vogal(c: String) -> String:
	var m := c.to_lower()
	if m >= "0" and m <= "9":
		return "a"
	if m in ["a", "á", "â", "ã", "à"]:
		return "a"
	if m in ["e", "é", "ê"]:
		return "e"
	if m in ["i", "í", "y"]:
		return "i"
	if m in ["o", "ó", "ô", "õ"]:
		return "o"
	if m in ["u", "ú"]:
		return "u"
	return ""


# --- Andamento ---

func _process(delta: float) -> void:
	if not _ativo:
		return
	if _entrada > 0.0:
		_entrada -= delta
		if _entrada <= 0.0:
			_aplicar_entrada(false)
			_atualizar_texto()
		return
	_t += delta
	var novo := _visivel
	if not _completo_por_clique:
		while novo < _total_chars and _tempos[novo] <= _t:
			if _blips.has(novo):
				_blip(_blips[novo])
			novo += 1
	if novo != _visivel:
		_visivel = novo
		_atualizar_texto()
		if _visivel >= _total_chars:
			falando.emit(speaker, false)
	if _t >= _total:
		_terminou()


func _atualizar_texto() -> void:
	var resto := _visivel
	for i in _rotulos.size():
		var n: int = _chars_por_linha[i]
		_rotulos[i].visible_characters = clampi(resto, 0, n)
		resto -= n


## Clique na sala fora da zona do alvo: completa a fala na hora, sem blip. O tempo de leitura segue o relógio normal.
func completar() -> void:
	if not _ativo or _entrada > 0.0 or _visivel >= _total_chars:
		return
	_completo_por_clique = true
	_visivel = _total_chars
	_atualizar_texto()
	falando.emit(speaker, false)


func _blip(b: Dictionary) -> void:
	var f := _som(_timbre, str(b.vogal))
	if f == null:
		return
	var tp: Dictionary = GameState.dialogos.typing
	var jit := float(tp.get("blip_pitch_jitter", 0.03))
	_player.stream = f
	_player.volume_db = float(tp.get("blip_volume_db", -8.0)) + float(b.db)
	_player.pitch_scale = float(b.mult) * (1.0 + _rng.randf_range(-jit, jit))
	_player.play()  # um tocador só: o blip novo corta o anterior


static func _som(timbre: String, vogal: String) -> AudioStream:
	var k := timbre + "_" + vogal
	if not _vozes.has(k):
		var caminho := "%svoice_%s_%s.wav" % [PASTA_VOZ, timbre, vogal]
		_vozes[k] = load(caminho) if ResourceLoader.exists(caminho) else null
	return _vozes[k]


func _terminou() -> void:
	var antigo := id
	var quem := speaker
	fechar_agora(false)
	GameState.fala_terminada(antigo)
	fechou.emit(antigo, quem)


## Fecha na hora (1 quadro, sem fade). `avisar`: emite `fechou`.
func fechar_agora(avisar: bool = true) -> void:
	var tinha := _ativo
	var antigo := id
	var quem := speaker
	_ativo = false
	set_process(false)
	if _player != null:
		_player.stop()
	if _raiz != null:
		_raiz.queue_free()
		_raiz = null
	if tinha:
		falando.emit(quem, false)
		if avisar:
			fechou.emit(antigo, quem)


## O GameState cancelou a fala (janela, luta, abertura pulada): fecha só se for a do id.
func cancelar(id_: String) -> void:
	if _ativo and id == id_:
		fechar_agora(true)


func texto_completo() -> bool:
	return _ativo and _visivel >= _total_chars
