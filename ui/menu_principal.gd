class_name MenuPrincipal
extends Control
## Menu principal (ID4, direção C: cartaz de luta). Fundo = parede de cartazes que enche conforme os marcos do save; por cima a faixa
## vermelha de listras, o logo e a coluna de botões CONTINUAR (só com save), NOVO JOGO, OPÇÕES e SAIR (x 244, 152x22, centrada no eixo 320).
## Contrato com o Fluxo: docs/fases/identidade-id4-contrato.md. O menu só LÊ o GameState; quem age (copiar e apagar o save, sair) é o Fluxo.
## Sinal `escolheu("continuar" | "novo_jogo" | "sair")`; "novo_jogo" só sai depois da confirmação dupla (se há save).
##
## Animação (tempos do spec tema-c-spec.md §4): intro de 860 ms que toca uma vez (clique ou tecla pula) e depois o loop (listras 1 px a cada
## 80 ms, brilho do logo, setas do foco balançando a cada 320 ms). Tudo é função do tempo (`_aplicar_ms`), sempre em posição inteira.
## Teclado e controle: ui_up/ui_down/ui_left/ui_right/ui_accept/ui_cancel (setas, Enter, Esc, direcional e botões do controle).

signal escolheu(acao: String)

const TELA := Vector2(640, 360)
const PASTA := "res://assets/sprites/menu/"
const VERSAO := "v0.8"  # provisória (o dono pediu para ficar como está)
const SUBTITULO := "UM SOCO DE CADA VEZ"  # provisório

const BTN_X := 244.0
const BTN_W := 152.0
const BTN_H := 22.0
const BTN_Y := 164.0
const BTN_PASSO := 28.0

const INTRO_MS := 860
const PASSO_LISTRA_MS := 80
const LOOP_TICKS := 48  # 3840 ms = 3 voltas de 16 px
const BRILHO_QUADROS := 8
const SETA_MS := 320

# Dados de teste do verificador (vazio no jogo): tem_save (bool) e camadas (ids da parede). Nunca toca o GameState nem a janela.
var dados_teste := {}
var animar := true  # o verificador desliga e usa ir_para_ms()

var _ms := 0.0
var _foco := 0
var _tem_save := false
var _travado := false  # já escolheu: ignora entrada até o Fluxo fechar o menu
var _som_impacto := false

var _escuro: ColorRect
var _entra30: TextureRect
var _entra65: TextureRect
var _faixa: Control
var _moldura: TextureRect
var _listras_clip: Control
var _listras: TextureRect
var _logo_grupo: Control
var _logo: TextureRect
var _logo_flash: TextureRect
var _logo_vel: TextureRect
var _lascas: TextureRect
var _brilho: TextureRect
var _brilhos: Array[ImageTexture] = []
var _chip: NinePatchRect
var _versao: Label
var _botoes: Array[Button] = []
var _ids: Array[String] = []
var _y_base: Array[float] = []
var _seta_e: TextureRect
var _seta_d: TextureRect
var _sfx: Sfx

# janela aberta (confirmação ou opções); uma por vez
var _janela: JanelaBase
var _jan_tipo := ""  # "confirma1", "confirma2" ou "opcoes"
var _jan_botoes: Array[Button] = []
var _jan_foco := 0
var _jan_setas: Array[TextureRect] = []
var _barras: Array[MenuBarra] = []
var _op_rotulos: Array[Label] = []
var _op_cheia: Button
var _op_geral := 1.0
var _op_efeitos := 1.0
var _op_tela_cheia := false


func _ready() -> void:
	position = Vector2.ZERO
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tem_save = _ler_tem_save()
	if dados_teste.is_empty():
		_sfx = Sfx.new()
		add_child(_sfx)
	_montar_parede()
	_montar_faixa_e_logo()
	_montar_subtitulo()
	_montar_botoes()
	_montar_versao()
	_foco = 0
	_atualizar_foco()
	_aplicar_ms(0.0 if animar else float(INTRO_MS))


func _process(delta: float) -> void:
	if not animar:
		return
	var antes := _ms
	_ms += delta * 1000.0
	if not _som_impacto and antes < 330.0 and _ms >= 330.0:
		_som_impacto = true
		if _sfx != null:
			_sfx.golpe_luta(true)
	_aplicar_ms(_ms)


## O verificador usa isto para parar o menu num instante da animação (0 a 860 = intro; depois, o loop).
func ir_para_ms(ms: float) -> void:
	animar = false
	_aplicar_ms(ms)


## Pula o resto da intro (clique ou tecla).
func pular_intro() -> void:
	if _ms < INTRO_MS:
		_ms = float(INTRO_MS)
		_som_impacto = true
		_aplicar_ms(_ms)


# ---------------------------------------------------------------------------------------------
# Dados (uma porta só para o GameState; o verificador troca por `dados_teste`)
# ---------------------------------------------------------------------------------------------

## O GameState pelo caminho (o verificador compila este script antes de os autoloads existirem).
func _gs() -> Node:
	return get_node("/root/GameState")


func _ler_tem_save() -> bool:
	if dados_teste.has("tem_save"):
		return bool(dados_teste.tem_save)
	return _gs().has_method("tem_save") and bool(_gs().call("tem_save"))


## Camadas da parede já filtradas, na ordem do parede.json: [{id, file, pos, size}].
func _ler_camadas() -> Array:
	var todas: Array = []
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(PASTA + "parede.json")) == OK and json.data is Dictionary:
		todas = json.data.get("layers", [])
	if dados_teste.has("camadas"):
		var ids: Array = dados_teste.camadas
		return todas.filter(func(c: Dictionary) -> bool: return str(c.id) in ids)
	if _gs().has_method("parede_camadas"):
		return _gs().call("parede_camadas")
	return todas.filter(func(c: Dictionary) -> bool: return (c.get("requires", {}) as Dictionary).is_empty())  # sem o GameState: só o "sempre"


func _ler_opcoes() -> void:
	if not dados_teste.is_empty():
		_op_geral = float(dados_teste.get("volume_geral", 1.0))
		_op_efeitos = float(dados_teste.get("volume_efeitos", 1.0))
		_op_tela_cheia = bool(dados_teste.get("tela_cheia", false))
		return
	var g = _gs().get("volume_geral")
	var e = _gs().get("volume_efeitos")
	_op_geral = float(g) if g != null else 1.0
	_op_efeitos = float(e) if e != null else 1.0
	_op_tela_cheia = bool(_gs().call("tela_cheia_atual")) if _gs().has_method("tela_cheia_atual") else false


## Põe as opções no GameState e aplica (o jogador ouve na hora); `salvar` grava o user://opcoes.cfg (nunca o save).
func _gravar_opcoes(salvar: bool) -> void:
	if not dados_teste.is_empty():
		return
	_gs().set("volume_geral", _op_geral)
	_gs().set("volume_efeitos", _op_efeitos)
	_gs().set("tela_cheia", _op_tela_cheia)
	if _gs().has_method("opcoes_aplicar"):
		_gs().call("opcoes_aplicar")
	if salvar and _gs().has_method("opcoes_salvar"):
		_gs().call("opcoes_salvar")


# ---------------------------------------------------------------------------------------------
# Montagem
# ---------------------------------------------------------------------------------------------

func _imagem(pai: Node, nome: String, pos: Vector2, flip: bool = false) -> TextureRect:
	var tex := load(PASTA + nome + ".png") as Texture2D
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture = tex
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.flip_h = flip
	t.position = pos
	t.size = tex.get_size() if tex != null else Vector2.ONE
	pai.add_child(t)
	return t


func _montar_parede() -> void:
	var parede := Control.new()
	parede.name = "Parede"
	parede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parede.size = TELA
	UiTema.ignorar(parede, "cenário: parede de cartazes em camadas coladas de propósito (a tira CAMPEÕES cobre o cartaz da Liga)")
	add_child(parede)
	_imagem(parede, "menu_parede", Vector2.ZERO)
	for c in _ler_camadas():
		var arq := str(c.file)
		var t := TextureRect.new()
		t.name = str(c.id)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.texture = load(arq) as Texture2D
		t.stretch_mode = TextureRect.STRETCH_KEEP
		t.position = Vector2(float(c.pos[0]), float(c.pos[1]))
		t.size = Vector2(float(c.size[0]), float(c.size[1]))
		parede.add_child(t)
	_escuro = ColorRect.new()
	_escuro.name = "Escuro"
	_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escuro.color = Color(UiTema.INK, 0.75)
	_escuro.size = TELA
	parede.add_child(_escuro)


func _montar_faixa_e_logo() -> void:
	_faixa = Control.new()
	_faixa.name = "Faixa"
	_faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faixa.size = TELA
	UiTema.ignorar(_faixa, "arte da faixa: listras que correm e ponta entrando (intro), sem texto")
	add_child(_faixa)
	_listras_clip = Control.new()
	_listras_clip.name = "ListrasClip"
	_listras_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listras_clip.clip_contents = true
	_listras_clip.position = Vector2(0, 30)
	_listras_clip.size = Vector2(640, 76)
	_faixa.add_child(_listras_clip)
	_listras = _imagem(_listras_clip, "menu_faixa_listras", Vector2(-16, 0))
	_listras.stretch_mode = TextureRect.STRETCH_TILE
	_listras.size = Vector2(656, 76)
	_moldura = _imagem(_faixa, "menu_faixa_moldura", Vector2(0, 26))
	_moldura.stretch_mode = TextureRect.STRETCH_TILE
	_moldura.size = Vector2(640, 88)
	_entra30 = _imagem(_faixa, "menu_faixa_entra_30", Vector2(0, 26))
	_entra65 = _imagem(_faixa, "menu_faixa_entra_65", Vector2(0, 26))

	_logo_grupo = Control.new()
	_logo_grupo.name = "LogoGrupo"
	_logo_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_grupo.size = TELA
	UiTema.ignorar(_logo_grupo, "arte do logo: camadas sobrepostas (logo, flash, brilho, lascas) que tremem no impacto, sem texto")
	add_child(_logo_grupo)
	_logo = _imagem(_logo_grupo, "menu_logo", Vector2(148, 47))
	_logo_flash = _imagem(_logo_grupo, "menu_logo_flash", Vector2(148, 47))
	_brilho = _imagem(_logo_grupo, "menu_logo_mascara", Vector2(148, 47))
	_brilho.texture = null
	_logo_vel = _imagem(_logo_grupo, "menu_logo_velocidade", Vector2(149, 20))
	_lascas = _imagem(_logo_grupo, "menu_lascas", Vector2(127, 73))
	_montar_brilhos()


## O brilho do loop: uma faixa diagonal y1 > white > y2 (2 px cada) varrendo o logo, recortada pela máscara das letras. 8 quadros prontos.
func _montar_brilhos() -> void:
	var tex := load(PASTA + "menu_logo_mascara.png") as Texture2D
	if tex == null:
		return
	var mascara := tex.get_image()
	var w := mascara.get_width()
	var h := mascara.get_height()
	for f in BRILHO_QUADROS:
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var c := lerpf(-6.0, float(w + h), float(f) / float(BRILHO_QUADROS - 1))
		for y in h:
			for x in w:
				if mascara.get_pixel(x, y).a < 0.5:
					continue
				var d := float(x + y) - c
				if d >= -3.0 and d < -1.0:
					img.set_pixel(x, y, UiTema.Y1)
				elif d >= -1.0 and d < 1.0:
					img.set_pixel(x, y, UiTema.WHITE)
				elif d >= 1.0 and d < 3.0:
					img.set_pixel(x, y, UiTema.Y2)
		_brilhos.append(ImageTexture.create_from_image(img))


func _montar_subtitulo() -> void:
	var w := UiTema.largura_visivel(SUBTITULO) + 14.0
	_chip = UiTema.nine_patch(self, "c_chip", Rect2(floorf((TELA.x - w) / 2.0), 103, w, 13))
	_chip.name = "Subtitulo"
	_chip.set_meta("ui_pos", "center_h")
	_chip.set_meta("ui_fundo_escuro", true)
	var area := UiTema.area_nove("c_chip", _chip.size)
	var reta := Control.new()
	reta.name = "Area"
	reta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reta.position = area.position
	reta.size = area.size
	_chip.add_child(reta)
	UiTema.rotulo_centrado(reta, Rect2(Vector2.ZERO, area.size), SUBTITULO, UiTema.CREAM, 1)


func _montar_botoes() -> void:
	var itens: Array = []
	if _tem_save:
		itens.append(["continuar", UiTema.txt("menu_continuar", "CONTINUAR")])
	itens.append(["novo_jogo", UiTema.txt("menu_novo_jogo", "NOVO JOGO")])
	itens.append(["opcoes", UiTema.txt("menu_opcoes", "OPÇÕES")])
	itens.append(["sair", UiTema.txt("menu_sair", "SAIR")])
	var y0 := BTN_Y if _tem_save else BTN_Y + BTN_PASSO / 2.0  # 3 botões ficam no meio do mesmo bloco de 4
	for i in itens.size():
		var y := y0 + BTN_PASSO * i
		var b := _botao(self, Rect2(BTN_X, y, BTN_W, BTN_H), str(itens[i][1]))
		b.name = "Botao_" + str(itens[i][0])
		var idx := i
		b.mouse_entered.connect(func() -> void: _focar(idx))
		b.pressed.connect(func() -> void: _ativar(idx))
		_botoes.append(b)
		_ids.append(str(itens[i][0]))
		_y_base.append(y)
	_seta_e = _imagem(self, "menu_seta", Vector2.ZERO)
	_seta_d = _imagem(self, "menu_seta", Vector2.ZERO, true)


func _montar_versao() -> void:
	_versao = UiTema.rotulo(self, VERSAO, UiTema.G2, 0, 349)
	_versao.name = "Versao"
	UiTema.fixar_direita(_versao, 634.0, "versão colada ao canto de baixo à direita")


## Botão de papel (secundário sobre fundo escuro) com texto centralizado; o texto fica em meta "rotulo" para trocar de estilo.
func _botao(pai: Node, rect: Rect2, texto: String) -> Button:
	var b := UiTema.botao(pai, rect, "c_btn_papel_normal")
	var l := UiTema.botao_conteudo(b, texto, UiTema.INK, 1)
	b.set_meta("rotulo", l)
	if absf(rect.position.x + rect.size.x / 2.0 - TELA.x / 2.0) < 0.5:
		b.set_meta("ui_pos", "center_h")
	return b


## Estilo do botão: "foco" (vermelho, em foco), "papel" (secundário) ou "vermelho" (CONTINUAR sem foco: segue vermelho, sem o filete).
func _estilo_botao(b: Button, modo: String) -> void:
	var l: Label = b.get_meta("rotulo")
	var vermelho := modo == "foco" or modo == "vermelho"
	var base := "c_btn_foco" if vermelho else ("c_btn_normal" if modo == "asfalto" else "c_btn_papel_normal")
	b.add_theme_stylebox_override("normal", UiTema.estilo(base))
	# CONTINUAR fica sempre vermelho; em foco ganha um filete creme de 1 px por dentro (as setas também o acompanham).
	if b.has_meta("realce"):
		(b.get_meta("realce") as Control).visible = modo == "foco"
	elif _ids.size() > 0 and _botoes.find(b) >= 0 and _ids[_botoes.find(b)] == "continuar":
		var r := ReferenceRect.new()
		r.editor_only = false
		r.border_color = UiTema.CREAM
		r.border_width = 1.0
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.position = Vector2(2, 2)
		r.size = b.size - Vector2(4, 4)
		r.visible = modo == "foco"
		b.add_child(r)
		b.set_meta("realce", r)
	if modo == "papel":
		l.add_theme_color_override("font_color", UiTema.INK)
		l.remove_theme_color_override("font_shadow_color")
	else:
		l.add_theme_color_override("font_color", UiTema.CREAM)
		l.add_theme_color_override("font_shadow_color", UiTema.INK)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 1)


# ---------------------------------------------------------------------------------------------
# Animação: tudo é função do tempo
# ---------------------------------------------------------------------------------------------

func _aplicar_ms(ms: float) -> void:
	_ms = ms
	_escuro.visible = ms < 120.0
	_entra30.visible = ms >= 120.0 and ms < 170.0
	_entra65.visible = ms >= 170.0 and ms < 220.0
	var cheia := ms >= 220.0
	_moldura.visible = cheia
	_listras_clip.visible = cheia

	# título: cai (280), impacto (330), tremores (390, 440), repouso (490)
	var logo_pos := Vector2(148, 47)
	var tremor := Vector2.ZERO
	var desce := 0.0
	_logo.visible = ms >= 280.0
	_logo_flash.visible = ms >= 330.0 and ms < 390.0
	_logo_vel.visible = ms >= 280.0 and ms < 330.0
	_lascas.visible = ms >= 330.0 and ms < 440.0
	if ms >= 280.0 and ms < 330.0:
		logo_pos.y = 31.0
	elif ms >= 330.0 and ms < 390.0:
		desce = 3.0
	elif ms >= 390.0 and ms < 440.0:
		tremor = Vector2(-2, 1)
	elif ms >= 440.0 and ms < 490.0:
		tremor = Vector2(1, -1)
	_faixa.position = Vector2(0, desce)
	_logo_grupo.position = Vector2(0, desce) + tremor
	_logo.position = logo_pos
	_logo_flash.position = Vector2(148, 47)
	_brilho.position = Vector2(148, 47)

	# loop: listras e brilho
	var tick := 0
	if ms >= INTRO_MS:
		tick = int((ms - INTRO_MS) / PASSO_LISTRA_MS)
	_listras.position = Vector2(-16 + (tick % 16), 0)
	var q := tick % LOOP_TICKS
	var brilha := ms >= INTRO_MS and q < BRILHO_QUADROS and _brilhos.size() == BRILHO_QUADROS
	_brilho.visible = brilha
	if brilha:
		_brilho.texture = _brilhos[q]

	_chip.visible = ms >= 490.0
	for i in _botoes.size():
		var t0 := 580.0 + 40.0 * i
		_botoes[i].visible = ms >= t0
		var sobe := 0.0
		if ms < t0 + 20.0:
			sobe = 6.0
		elif ms < t0 + 40.0:
			sobe = 3.0
		_botoes[i].position.y = _y_base[i] + sobe
	_versao.visible = ms >= 740.0
	_posicionar_setas()


func _posicionar_setas() -> void:
	if _botoes.is_empty():
		return
	var b := _botoes[_foco]
	var dentro := 1.0 if (int(_ms / SETA_MS) % 2 == 1 and _ms >= INTRO_MS) else 0.0
	_seta_e.visible = b.visible and _janela == null
	_seta_d.visible = _seta_e.visible
	_seta_e.position = Vector2(b.position.x - 11.0 + dentro, b.position.y + 6.0)
	_seta_d.position = Vector2(b.position.x + b.size.x + 5.0 - dentro, b.position.y + 6.0)


# ---------------------------------------------------------------------------------------------
# Foco e ações do menu principal
# ---------------------------------------------------------------------------------------------

func _focar(i: int, com_som: bool = true) -> void:
	if i == _foco or _janela != null or _travado:
		return
	_foco = i
	_atualizar_foco()
	if com_som and _sfx != null:
		_sfx.foco()


func _atualizar_foco() -> void:
	for i in _botoes.size():
		# Decisão do dono (2026-11-25): só o botão em foco é vermelho; os outros, CONTINUAR inclusive, ficam em papel.
		if i == _foco:
			_estilo_botao(_botoes[i], "foco")
		else:
			_estilo_botao(_botoes[i], "papel")
	_posicionar_setas()


func _ativar(i: int) -> void:
	if _travado or _janela != null or _ms < INTRO_MS:
		return
	if _sfx != null:
		_sfx.compra()
	match _ids[i]:
		"continuar":
			_travado = true
			escolheu.emit("continuar")
		"novo_jogo":
			if _tem_save:
				_abrir_confirmacao(1)
			else:
				_travado = true
				escolheu.emit("novo_jogo")
		"opcoes":
			_abrir_opcoes()
		"sair":
			_travado = true
			escolheu.emit("sair")


# ---------------------------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------------------------

func _input(ev: InputEvent) -> void:
	if _travado or not is_visible_in_tree():
		return
	if _ms < INTRO_MS and animar:
		var tecla: bool = ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode != KEY_F11 and ev.keycode != KEY_F12
		var clique: bool = ev is InputEventMouseButton and ev.pressed
		var pad: bool = ev is InputEventJoypadButton and ev.pressed
		if tecla or clique or pad:
			pular_intro()
			get_viewport().set_input_as_handled()
		return
	if _janela != null:
		_entrada_janela(ev)
		return
	if ev.is_action_pressed("ui_down", true) or ev.is_action_pressed("ui_focus_next", true):
		_focar((_foco + 1) % _botoes.size())
		get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("ui_up", true) or ev.is_action_pressed("ui_focus_prev", true):
		_focar((_foco + _botoes.size() - 1) % _botoes.size())
		get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("ui_accept"):
		_ativar(_foco)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------------------------
# Janelas: confirmação dupla do NOVO JOGO e OPÇÕES
# ---------------------------------------------------------------------------------------------

func _nova_janela(tipo: String) -> JanelaBase:
	_fechar_janela()
	_jan_tipo = tipo
	_janela = JanelaBase.new()
	_janela.name = "Janela_" + tipo
	add_child(_janela)
	_jan_botoes.clear()
	_jan_setas.clear()
	_barras.clear()
	_op_rotulos.clear()
	_op_cheia = null
	_jan_foco = 0
	_posicionar_setas()
	return _janela


func _fechar_janela() -> void:
	if _janela != null:
		_janela.queue_free()
		_janela = null
	_jan_tipo = ""
	_posicionar_setas()


## Botão da janela (papel; o do foco fica vermelho). Devolve o botão com o texto em meta "rotulo".
func _botao_janela(j: JanelaBase, rect: Rect2, texto: String) -> Button:
	var b := j.botao_texto(rect, texto)
	for c in b.get_children():
		if c is Label:
			b.set_meta("rotulo", c)
	_jan_botoes.append(b)
	return b


func _abrir_confirmacao(etapa: int) -> void:
	var j := _nova_janela("confirma%d" % etapa)
	var r := Rect2(170, 120, 300, 117)
	j.moldura("", r)
	var titulo := UiTema.txt("menu_novo_t1", "NOVO JOGO?") if etapa == 1 else UiTema.txt("menu_novo_t2", "TEM CERTEZA?")
	j.faixa_titulo("", Rect2(), titulo, UiTema.WHITE, 2)
	var linhas: Array = []
	if etapa == 1:
		linhas = [UiTema.txt("menu_novo_l1a", "JÁ EXISTE UM JOGO SALVO."), UiTema.txt("menu_novo_l1b", "QUER COMEÇAR UM JOGO NOVO?")]
	else:
		linhas = [UiTema.txt("menu_novo_l2a", "SEU JOGO SALVO SERÁ SUBSTITUÍDO POR UM NOVO."),
			UiTema.txt("menu_novo_l2b", "UMA CÓPIA DE SEGURANÇA SERÁ FEITA ANTES.")]
	var y := r.position.y + (44.0 if linhas.size() == 2 else 38.0)
	for i in linhas.size():
		var cor := UiTema.R2 if (etapa == 2 and i == 1) else UiTema.WHITE
		UiTema.rotulo_centro(j.painel, str(linhas[i]), cor, 320.0, y)
		y += 13.0
	var yb := r.position.y + 79.0
	var voltar := _botao_janela(j, Rect2(192, yb, 124, 24), UiTema.txt("menu_voltar", "VOLTAR"))
	var sim_txt := UiTema.txt("menu_sim_novo", "SIM, NOVO JOGO") if etapa == 1 else UiTema.txt("menu_copiar_comecar", "COPIAR E COMEÇAR")
	var sim := _botao_janela(j, Rect2(324, yb, 124, 24), sim_txt)
	for i in 2:
		var idx := i
		_jan_botoes[i].mouse_entered.connect(func() -> void: _jan_focar(idx))
	voltar.pressed.connect(func() -> void: _jan_ativar(0))
	sim.pressed.connect(func() -> void: _jan_ativar(1))
	_jan_foco = 0  # começa em VOLTAR: o lado seguro
	_jan_atualizar()
	j.animar_entrada()


func _abrir_opcoes() -> void:
	_ler_opcoes()
	var j := _nova_janela("opcoes")
	var r := Rect2(170, 93, 300, 171)
	j.moldura("", r)
	j.faixa_titulo("", Rect2(), UiTema.txt("menu_opcoes_t", "OPÇÕES"), UiTema.WHITE, 2)
	var y0 := r.position.y
	var area_x := r.position.x + 2.0
	var area_w := r.size.x - 4.0
	var bx := 320.0 - MenuBarra.LARGURA / 2.0
	for k in 2:
		var ly := y0 + 42.0 + 30.0 * k
		var rot := UiTema.rotulo_centrado(j.painel, Rect2(area_x, ly, area_w, 9), "", UiTema.WHITE, 1, false, "center_h")
		_op_rotulos.append(rot)
		var barra := MenuBarra.new()
		barra.position = Vector2(bx, ly + 12.0)
		barra.valor = _op_geral if k == 0 else _op_efeitos
		barra.set_meta("ui_pos", "center_h")
		j.painel.add_child(barra)
		_barras.append(barra)
		var idx := k
		barra.mudou.connect(func(v: float) -> void: _op_mudou(idx, v))
		barra.soltou.connect(func() -> void: _gravar_opcoes(true))
		barra.mouse_entered.connect(func() -> void: _jan_focar(idx))
	_op_texto(0)
	_op_texto(1)
	_op_cheia = _botao_janela(j, Rect2(244, y0 + 102.0, BTN_W, BTN_H), "")
	_op_cheia.mouse_entered.connect(func() -> void: _jan_focar(2))
	_op_cheia.pressed.connect(func() -> void: _jan_ativar(2))
	_op_texto(2)
	var voltar := _botao_janela(j, Rect2(258, y0 + 135.0, 124, 24), UiTema.txt("menu_voltar", "VOLTAR"))
	voltar.mouse_entered.connect(func() -> void: _jan_focar(3))
	voltar.pressed.connect(func() -> void: _jan_ativar(3))
	_jan_foco = 0
	_jan_atualizar()
	j.animar_entrada()


## Linhas da janela de opções (0 geral, 1 efeitos, 2 tela cheia): texto com o valor.
func _op_texto(i: int) -> void:
	if i < 2:
		var v := _op_geral if i == 0 else _op_efeitos
		var nome := UiTema.txt("menu_vol_geral", "VOLUME GERAL") if i == 0 else UiTema.txt("menu_vol_efeitos", "EFEITOS")
		_op_rotulos[i].text = "%s: %s%%" % [nome, NumberFormat.fmt(roundf(v * 100.0))]
	else:
		var sim := UiTema.txt("menu_sim", "SIM")
		var nao := UiTema.txt("menu_nao", "NÃO")
		var l: Label = _op_cheia.get_meta("rotulo")
		l.text = "%s: %s" % [UiTema.txt("menu_tela_cheia", "TELA CHEIA"), sim if _op_tela_cheia else nao]
		var a := UiTema.area_botao(_op_cheia)
		l.position.x = roundf(a.position.x + (a.size.x - UiTema.largura_visivel(l.text)) / 2.0)
		l.set_meta("y_base", l.position.y)


func _op_mudou(i: int, v: float) -> void:
	if i == 0:
		_op_geral = v
	else:
		_op_efeitos = v
	_op_texto(i)
	_gravar_opcoes(false)


func _jan_focar(i: int) -> void:
	if i == _jan_foco or _janela == null:
		return
	_jan_foco = i
	_jan_atualizar()
	if _sfx != null:
		_sfx.foco()


## Foco na janela: o item focado fica vermelho (botões) ou ganha a alça clara (barras), e as setas ficam ao lado dele.
func _jan_atualizar() -> void:
	for s in _jan_setas:
		s.queue_free()
	_jan_setas.clear()
	if _jan_tipo == "opcoes":
		for k in 2:
			_barras[k].focado = (_jan_foco == k)
		_estilo_botao(_op_cheia, "foco" if _jan_foco == 2 else "papel")
		_estilo_botao(_jan_botoes[1], "foco" if _jan_foco == 3 else "papel")
		var x0 := 0.0
		var x1 := 0.0
		var y := 0.0
		if _jan_foco < 2:
			x0 = _barras[_jan_foco].position.x
			x1 = x0 + MenuBarra.LARGURA
			y = _barras[_jan_foco].position.y
		else:
			var b := _op_cheia if _jan_foco == 2 else _jan_botoes[1]
			x0 = b.position.x
			x1 = x0 + b.size.x
			y = b.position.y + 6.0
		_jan_setas.append(_imagem(_janela.painel, "menu_seta", Vector2(x0 - 11.0, y)))
		_jan_setas.append(_imagem(_janela.painel, "menu_seta", Vector2(x1 + 5.0, y), true))
		for s in _jan_setas:
			s.modulate = Color(1.0, 0.45, 0.4)  # a seta é creme (feita para o fundo escuro): sobre o papel ela vira vermelha
	else:
		for i in _jan_botoes.size():
			_estilo_botao(_jan_botoes[i], "foco" if i == _jan_foco else "papel")


func _jan_ativar(i: int) -> void:
	if _janela == null or _travado:
		return
	if _sfx != null:
		_sfx.compra()
	match _jan_tipo:
		"confirma1":
			if i == 1:
				_abrir_confirmacao(2)
			else:
				_fechar_janela()
		"confirma2":
			if i == 1:
				_travado = true
				_fechar_janela()
				escolheu.emit("novo_jogo")
			else:
				_fechar_janela()
		"opcoes":
			if i == 2:
				_op_tela_cheia = not _op_tela_cheia
				_op_texto(2)
				_gravar_opcoes(true)
			elif i == 3:
				_gravar_opcoes(true)
				_fechar_janela()


func _entrada_janela(ev: InputEvent) -> void:
	var n := _jan_botoes.size() if _jan_tipo != "opcoes" else 4
	var passo_v := 0
	if ev.is_action_pressed("ui_down", true) or ev.is_action_pressed("ui_focus_next", true):
		passo_v = 1
	elif ev.is_action_pressed("ui_up", true) or ev.is_action_pressed("ui_focus_prev", true):
		passo_v = -1
	var h := 0
	if ev.is_action_pressed("ui_right", true):
		h = 1
	elif ev.is_action_pressed("ui_left", true):
		h = -1
	if _jan_tipo == "opcoes":
		if passo_v != 0:
			_jan_focar((_jan_foco + passo_v + n) % n)
		elif h != 0 and _jan_foco < 2:
			_barras[_jan_foco].passo(h)
		elif ev.is_action_pressed("ui_accept"):
			_jan_ativar(_jan_foco)
		elif ev.is_action_pressed("ui_cancel"):
			_jan_ativar(3)
		else:
			return
	else:
		var p := passo_v + h  # nas confirmações os dois botões ficam lado a lado: qualquer seta troca
		if p != 0:
			_jan_focar((_jan_foco + 1) % n)
		elif ev.is_action_pressed("ui_accept"):
			_jan_ativar(_jan_foco)
		elif ev.is_action_pressed("ui_cancel"):
			_jan_ativar(0)
		else:
			return
	get_viewport().set_input_as_handled()
