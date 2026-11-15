class_name TelaCriarDiscipulo
extends JanelaBase
## Tela "RECEBER NOVO DISCÍPULO" (Fase 6b1, prancha S5): nome editável, pele, cabelo e calção com setas, SORTEAR e CONFIRMAR,
## a linha "LUVA: O PAR DO JOHN" e o preview do discípulo com as cores escolhidas (troca de paleta em tempo real, DiscVisual).
## Só desenho: lê `GameState.rascunho()` e chama `definir_rascunho`, `sortear_rascunho` e `confirmar_discipulo`. Não fecha com ESC
## nem tem X: só sai pelo CONFIRMAR (`confirmou`). Fase 6b2: acrescente campos em CAMPOS (ids de data/disciples.json > fields);
## só aparecem os que têm mais de uma opção ligada, e com mais de 6 linhas a tela abre uma 2ª coluna.

signal confirmou

## Campos escolhidos por seta: [campo do look, chave do rótulo, quantas cores mostrar]
const CAMPOS := [
	["skin", "disc_label_skin", 3],
	["hair_color", "disc_label_hair", 2],
	["shorts_color", "disc_label_shorts", 3],
]
const LARG_COLUNA := 330.0
const LINHAS_POR_COLUNA := 6
const ALT_LINHA := 18.0
const PASSO_LINHA := 24.0

var sfx: Sfx
var _origem := Vector2.ZERO
var _nome: LineEdit
var _nome_caixa: Panel
var _campos: Array = []  # {campo, ids, valor (Control raiz), chips: Array[ColorRect], contador: Label, cores_n}
var _previa: AnimSprite
var _confirmando := false
var _janela: Rect2


func abrir_com() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	var ativos: Array = []
	for c in CAMPOS:
		if GameState.disciples.opcoes_ativas(str(c[0])).size() > 1:
			ativos.append(c)
	var linhas := 1 + ativos.size()  # nome + campos
	var colunas := ceili(float(linhas) / float(LINHAS_POR_COLUNA))
	var linhas_col := mini(linhas, LINHAS_POR_COLUNA)
	var larg := LARG_COLUNA + float(colunas - 1) * 170.0
	var fim_linhas := 32.0 + float(linhas_col) * PASSO_LINHA
	var rodape := maxf(fim_linhas, 162.0) + 4.0
	var alt := rodape + 24.0 + 22.0 + 12.0
	# Janela no meio da sala (centro em x 320, y 154), tamanho inteiro e posição inteira.
	_origem = Vector2(roundf(320.0 - larg / 2.0), roundf(154.0 - alt / 2.0))
	_janela = Rect2(_origem, Vector2(larg, alt))
	moldura("ui_window", _janela)
	faixa_titulo("neutral", Rect2(_origem + Vector2(6, 6), Vector2(larg - 12, 16)), UiTema.txt("disc_title", "RECEBER NOVO DISCÍPULO"))
	_montar_previa()
	_montar_linhas(ativos)
	# Rodapé: divisor, a luva que ele recebe e CONFIRMAR.
	divisor(_origem.x + 6.0, _origem.y + rodape, larg - 12.0)
	UiTema.rotulo_centro(painel, UiTema.txt("disc_glove_line", "LUVA: O PAR DO JOHN"), UiTema.R3, 320.0, _origem.y + rodape + 8.0)
	var b := botao_texto(Rect2(roundf(320.0 - 60.0), _origem.y + rodape + 24.0, 120, 22), UiTema.txt("disc_confirm", "CONFIRMAR"), UiTema.GR3)
	b.set_meta("ui_pos", "center_h")
	b.pressed.connect(_confirmar)
	animar_entrada()
	GameState.rascunho_mudou.connect(_atualizar)
	_atualizar()
	_nome.grab_focus.call_deferred()


func _montar_previa() -> void:
	# Cartão do preview à esquerda; SORTEAR embaixo dele.
	var cartao := UiTema.nine_patch(painel, "ui_card_dim", Rect2(_origem + Vector2(12, 30), Vector2(90, 100)))
	cartao.set_meta("ui_align", "ignore")
	_previa = AnimSprite.new()
	_previa.definir("fighter_idle_disc_layered")
	_previa.position = _origem + Vector2(12 + 45, 30 + 100 - 12)
	painel.add_child(_previa)
	var sombra := Sprite2D.new()
	sombra.texture = UiTema.textura("floor_shadow")
	sombra.position = _previa.position + Vector2(0, -1)
	painel.add_child(sombra)
	painel.move_child(sombra, _previa.get_index())
	_previa.tocar([0, 1, 2, 3], 4.0, true)
	var s := botao_texto(Rect2(_origem + Vector2(12, 136), Vector2(90, 18)), UiTema.txt("disc_roll", "SORTEAR"), UiTema.Y1)
	s.pressed.connect(func() -> void:
		sfx.foco()
		GameState.sortear_rascunho())


func _montar_linhas(ativos: Array) -> void:
	# Linha 0: nome editável.
	_rotulo_linha(0, UiTema.txt("disc_label_name", "NOME"))
	var x_sel := _x_coluna(0) + 56.0
	var larg_sel := 151.0  # 56 px de rótulo + 151 de seletor: termina a 12 px da borda direita da janela
	# A caixa (borda) tem 18 px como as outras linhas; o LineEdit fica dentro, mais alto, e a caixa recorta (a fonte pede 24 px).
	_nome_caixa = Panel.new()
	_nome_caixa.position = Vector2(x_sel, _y_linha(0))
	_nome_caixa.size = Vector2(larg_sel, ALT_LINHA)
	_nome_caixa.clip_contents = true
	_nome_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nome_caixa.add_theme_stylebox_override("panel", _caixa(UiTema.G1))
	_nome_caixa.set_meta("ui_align", "ignore")
	painel.add_child(_nome_caixa)
	_nome = LineEdit.new()
	_nome.position = Vector2(0, -3)
	_nome.size = Vector2(larg_sel, 24)
	_nome.focus_mode = Control.FOCUS_ALL
	_nome.context_menu_enabled = false
	_nome.virtual_keyboard_enabled = false
	_nome.add_theme_font_override("font", UiTema.fonte())
	_nome.add_theme_font_size_override("font_size", UiTema.TAMANHO_FONTE)
	_nome.add_theme_color_override("font_color", UiTema.WHITE)
	_nome.add_theme_color_override("caret_color", UiTema.Y1)
	_nome.add_theme_color_override("selection_color", UiTema.P1)
	var vazio := StyleBoxEmpty.new()
	vazio.content_margin_left = 5.0
	_nome.add_theme_stylebox_override("normal", vazio)
	_nome.add_theme_stylebox_override("focus", vazio)
	_nome.focus_entered.connect(func() -> void: _nome_caixa.add_theme_stylebox_override("panel", _caixa(UiTema.Y1)))
	_nome.focus_exited.connect(func() -> void: _nome_caixa.add_theme_stylebox_override("panel", _caixa(UiTema.G1)))
	_nome.text_changed.connect(_ao_digitar)
	_nome.text_submitted.connect(func(_t: String) -> void: _confirmar())
	_nome.set_meta("ui_align", "ignore")  # campo de texto: o verificador mede só o desenho dos rótulos e botões
	_nome_caixa.add_child(_nome)
	# Linhas dos campos com seta.
	for i in ativos.size():
		var c: Array = ativos[i]
		_montar_campo(i + 1, str(c[0]), UiTema.txt(str(c[1])), int(c[2]))


func _caixa(borda: Color) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = UiTema.D1
	e.border_color = borda
	e.set_border_width_all(1)
	e.content_margin_left = 5.0
	e.content_margin_right = 3.0
	e.content_margin_top = 0.0
	e.content_margin_bottom = 0.0
	return e


func _x_coluna(i: int) -> float:
	return _origem.x + 111.0 + float(i / LINHAS_POR_COLUNA) * 170.0


func _y_linha(i: int) -> float:
	return _origem.y + 32.0 + float(i % LINHAS_POR_COLUNA) * PASSO_LINHA


func _rotulo_linha(i: int, texto: String) -> void:
	var y := _y_linha(i)
	UiTema.rotulo(painel, texto, UiTema.G3, _x_coluna(i), UiTema.y_texto(Rect2(0, y, 1, ALT_LINHA)))


func _montar_campo(i: int, campo: String, rotulo: String, n_cores: int) -> void:
	_rotulo_linha(i, rotulo)
	var y := _y_linha(i)
	var x := _x_coluna(i) + 56.0
	var esq := botao_texto(Rect2(x, y, 16, ALT_LINHA), "<", UiTema.WHITE)
	var dir := botao_texto(Rect2(x + 151.0 - 16.0, y, 16, ALT_LINHA), ">", UiTema.WHITE)
	var valor := UiTema.nine_patch(painel, "ui_card_dim", Rect2(x + 16.0, y, 119, ALT_LINHA))
	valor.set_meta("ui_align", "ignore")  # o conteúdo (chips + contador) é centralizado à mão, como grupo
	var chips: Array[ColorRect] = []
	for k in n_cores:
		var fundo := ColorRect.new()
		fundo.color = UiTema.INK
		fundo.size = Vector2(16, 10)
		fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		valor.add_child(fundo)
		var chip := ColorRect.new()
		chip.size = Vector2(14, 8)
		chip.position = Vector2(1, 1)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(chip)
		chips.append(chip)
	var cont := UiTema.rotulo(valor, "", UiTema.G3, 0, 0)
	_campos.append({"campo": campo, "valor": valor, "chips": chips, "contador": cont, "n": n_cores})
	esq.pressed.connect(func() -> void: _trocar(campo, -1))
	dir.pressed.connect(func() -> void: _trocar(campo, 1))


func _trocar(campo: String, passo: int) -> void:
	var ids: Array = GameState.disciples.opcoes_ativas(campo)
	if ids.is_empty():
		return
	var atual := ids.find(str(GameState.rascunho().get("look", {}).get(campo, "")))
	var novo := posmod(atual + passo, ids.size())
	sfx.foco()
	GameState.definir_rascunho(campo, str(ids[novo]))


func _ao_digitar(texto: String) -> void:
	GameState.definir_rascunho("name", texto)
	var limpo := str(GameState.rascunho().get("name", ""))
	if limpo != texto:
		var col := _nome.caret_column
		_nome.text = limpo
		_nome.caret_column = mini(col, limpo.length())


## Coloca no desenho o que o rascunho tem: nome, chips e contadores de cada campo e o preview.
func _atualizar() -> void:
	var r: Dictionary = GameState.rascunho()
	if r.is_empty():
		return
	var look: Dictionary = r.get("look", {})
	if _nome.text != str(r.get("name", "")):
		_nome.text = str(r.get("name", ""))
		_nome.caret_column = _nome.text.length()
	var cores: Dictionary = GameState.cores_visual(look)
	for c in _campos:
		var campo := str(c.campo)
		var ids: Array = GameState.disciples.opcoes_ativas(campo)
		var pos := ids.find(str(look.get(campo, ""))) + 1
		var hex: Array = cores.get(campo, {}).get("colors", [])
		var chips: Array = c.chips
		for k in chips.size():
			(chips[k] as ColorRect).color = Color(str(hex[k])) if k < hex.size() else UiTema.G0
		var texto := "%d/%d" % [pos, ids.size()]
		var cont: Label = c.contador
		cont.text = texto
		# Grupo [chips][6 px][contador] centralizado no valor (119 px de largura, 18 de altura).
		var larg_chips := float(chips.size()) * 16.0 + float(chips.size() - 1) * 2.0
		var total := larg_chips + 6.0 + UiTema.largura_visivel(texto)
		var x0 := roundf((119.0 - total) / 2.0)
		for k in chips.size():
			((chips[k] as ColorRect).get_parent() as Control).position = Vector2(x0 + float(k) * 18.0, 4)
		cont.position = Vector2(roundf(x0 + larg_chips + 6.0), UiTema.y_texto(Rect2(0, 0, 1, ALT_LINHA)))
	if _previa != null:
		_previa.texture = DiscVisual.textura("fighter_idle_disc_layered", look)


func _confirmar() -> void:
	if _confirmando:
		return
	if GameState.confirmar_discipulo():
		_confirmando = true
		sfx.compra()
		confirmou.emit()
	else:
		# Nome vazio: o jogo devolveu um nome sorteado no campo; o campo dá um tranco para o jogador ver.
		var x0 := _nome_caixa.position.x
		var tw := create_tween()
		for d in [-3.0, 3.0, -2.0, 2.0, 0.0]:
			tw.tween_callback(func() -> void: _nome_caixa.position.x = x0 + d)
			tw.tween_interval(0.04)


func _exit_tree() -> void:
	if GameState.rascunho_mudou.is_connected(_atualizar):
		GameState.rascunho_mudou.disconnect(_atualizar)
