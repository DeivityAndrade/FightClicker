class_name TelaCriarDiscipulo
extends JanelaBase
## Tela "RECEBER NOVO DISCÍPULO" (Fase 6b1, prancha S5): nome editável e as linhas de aparência com setas, SORTEAR e CONFIRMAR,
## a linha "LUVA: O PAR DO JOHN" e o preview do discípulo com tudo o que foi escolhido (troca de paleta em tempo real, DiscVisual).
## Só desenho: lê `GameState.rascunho()` e `GameState.linhas_tela_criacao()` (Fase 6b2: 10 linhas, data/disciples.json > screen) e chama
## `definir_rascunho`, `sortear_rascunho` e `confirmar_discipulo`. Não fecha com ESC nem tem X: só sai pelo CONFIRMAR (`confirmou`).
## Linha "colors" mostra chips + contador; linha "text" mostra o nome da opção (disc_opt_<campo>_<id>). Com mais de 6 linhas a tela
## abre uma 2ª coluna. A linha de cor fica apagada (e a seta desligada) quando a peça de que ela depende está em "sem".

signal confirmou

const LARG_COLUNA := 330.0  # janela com 1 coluna
const PASSO_COLUNA := 219.0  # 207 px de rótulo + seletor, mais 12 de vão
const LINHAS_POR_COLUNA := 6
const ALT_LINHA := 18.0
const PASSO_LINHA := 24.0
const LARG_VALOR := 119.0

var sfx: Sfx
var _origem := Vector2.ZERO
var _nome: LineEdit
var _nome_caixa: Panel
## Uma entrada por linha com seta: {campo, kind, rotulo, valor, esq, dir, chips: Array[ColorRect], contador: Label, texto: Label, n}
var _campos: Array = []
var _grupos_setas: Dictionary = {}  # coluna (2 em diante) -> Control que guarda as setas dela
var _previa: AnimSprite
var _confirmando := false
var _janela: Rect2


func abrir_com() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	# As linhas vêm do jogo (data/disciples.json > screen.rows). Uma linha de escolha só aparece com mais de uma opção ligada.
	var ativos: Array = []
	for l in GameState.linhas_tela_criacao():
		var k := str(l.get("kind", ""))
		if k != "" and (l.get("opcoes", []) as Array).size() > 1:
			ativos.append(l)
	var linhas := 1 + ativos.size()  # nome + campos
	var colunas := ceili(float(linhas) / float(LINHAS_POR_COLUNA))
	var linhas_col := mini(linhas, LINHAS_POR_COLUNA)
	var larg := LARG_COLUNA + float(colunas - 1) * PASSO_COLUNA
	var fim_linhas := 32.0 + float(linhas_col) * PASSO_LINHA
	var rodape := maxf(fim_linhas, 202.0) + 4.0  # 6d3: a prévia 2x pede o SORTEAR mais embaixo
	var alt := rodape + 24.0 + 22.0 + 12.0
	# Janela no meio da sala (centro em x 320, y 154), tamanho inteiro e posição inteira.
	_origem = Vector2(roundf(320.0 - larg / 2.0), roundf(154.0 - alt / 2.0))
	_janela = Rect2(_origem, Vector2(larg, alt))
	_fundo_tela()
	moldura("ui_window", _janela)
	faixa_titulo("neutral", Rect2(_origem + Vector2(6, 6), Vector2(larg - 12, 16)), UiTema.txt("disc_title", "RECEBER NOVO DISCÍPULO"))
	_montar_previa()
	_montar_linhas(ativos)
	# Rodapé: divisor, a luva que ele recebe e CONFIRMAR.
	divisor(_origem.x + 6.0, _origem.y + rodape, larg - 12.0)
	# 6d2: a linha "LUVA: O PAR DO JOHN" saiu (repete a descrição da luva).
	var b := botao_texto(Rect2(roundf(320.0 - 60.0), _origem.y + rodape + 24.0, 120, 22), UiTema.txt("disc_confirm", "CONFIRMAR"), UiTema.GR3)
	b.set_meta("ui_pos", "center_h")
	b.pressed.connect(_confirmar)
	animar_entrada()
	GameState.rascunho_mudou.connect(_atualizar)
	_atualizar()
	_nome.grab_focus.call_deferred()


## Tema C: a tela cheia sem cenário é o asfalto (c_tela_fundo) por cima do escurecer; entra e sai junto com ele.
func _fundo_tela() -> void:
	var f := TextureRect.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.texture = UiTema.textura("c_tela_fundo")
	f.stretch_mode = TextureRect.STRETCH_KEEP
	f.size = TELA
	f.set_meta("ui_fundo_escuro", true)
	_dim.add_child(f)


func _montar_previa() -> void:
	# Cartão do preview à esquerda; SORTEAR embaixo dele.
	var cartao := UiTema.nine_patch(painel, "c_cartao_apagado", Rect2(_origem + Vector2(12, 30), Vector2(90, 150)))  # 6d3: cartão mais alto: a prévia agora é 2x
	UiTema.ignorar(cartao, "cartão do preview: só moldura; o discípulo 2x dentro dele tem posição própria")
	_previa = AnimSprite.new()
	_previa.definir("fighter_idle_disc_layered")
	_previa.scale = Vector2(2, 2)  # 6d3: 2x (pixel inteiro), como o retrato do mural
	_previa.position = _origem + Vector2(12 + 45, 30 + 150 - 10)
	painel.add_child(_previa)
	var sombra := Sprite2D.new()
	sombra.texture = UiTema.textura("floor_shadow")
	sombra.position = _previa.position + Vector2(0, -1)
	sombra.scale = Vector2(2, 2)
	painel.add_child(sombra)
	painel.move_child(sombra, _previa.get_index())
	_previa.tocar([0, 1, 2, 3], 4.0, true)
	var s := botao_texto(Rect2(_origem + Vector2(12, 184), Vector2(90, 18)), UiTema.txt("disc_roll", "SORTEAR"), UiTema.Y1)
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
	UiTema.ignorar(_nome_caixa, "campo de nome: caixa de texto editável (LineEdit) maior que a borda, recortada pela caixa")
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
	_nome_caixa.add_child(_nome)
	# Linhas dos campos com seta.
	for i in ativos.size():
		var c: Dictionary = ativos[i]
		_montar_campo(i + 1, str(c.field), UiTema.txt(str(c.label)), str(c.kind), int(c.chips))


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
	return _origem.x + 111.0 + float(i / LINHAS_POR_COLUNA) * PASSO_COLUNA


func _y_linha(i: int) -> float:
	return _origem.y + 32.0 + float(i % LINHAS_POR_COLUNA) * PASSO_LINHA


func _rotulo_linha(i: int, texto: String) -> Label:
	var y := _y_linha(i)
	return UiTema.rotulo(painel, texto, UiTema.G3, _x_coluna(i), UiTema.y_texto(Rect2(0, y, 1, ALT_LINHA)))


func _montar_campo(i: int, campo: String, rotulo_txt: String, kind: String, n_cores: int) -> void:
	var rotulo := _rotulo_linha(i, rotulo_txt)
	var y := _y_linha(i)
	var x := _x_coluna(i) + 56.0
	var esq := botao_texto(Rect2(x, y, 16, ALT_LINHA), "<", UiTema.WHITE)
	var dir := botao_texto(Rect2(x + 151.0 - 16.0, y, 16, ALT_LINHA), ">", UiTema.WHITE)
	if i >= LINHAS_POR_COLUNA:
		# Cada coluna tem seu próprio grupo de setas: o verificador compara fileiras só entre irmãos do mesmo pai.
		var coluna := i / LINHAS_POR_COLUNA
		if not _grupos_setas.has(coluna):
			var g := Control.new()
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			g.size = painel.size
			painel.add_child(g)
			_grupos_setas[coluna] = g
		for b in [esq, dir]:
			b.reparent(_grupos_setas[coluna], true)
	var valor := UiTema.nine_patch(painel, "c_cartao_apagado", Rect2(x + 16.0, y, LARG_VALOR, ALT_LINHA))
	# O conteúdo (chips + contador, ou o nome da opção) é centralizado à mão, como grupo, e o texto muda a cada seta apertada.
	UiTema.ignorar(valor, "valor da linha: chips + contador (ou nome da opção) centralizados à mão como grupo", true)
	var chips: Array[ColorRect] = []
	for k in (n_cores if kind == "colors" else 0):
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
	var cont := UiTema.rotulo(valor, "", UiTema.WHITE, 0, 0)  # contador "2/6" (cores) ou nome da opção (texto)
	_campos.append({"campo": campo, "kind": kind, "rotulo": rotulo, "valor": valor, "esq": esq, "dir": dir, "chips": chips,
		"contador": cont, "n": n_cores})
	esq.pressed.connect(func() -> void: _trocar(campo, -1))
	dir.pressed.connect(func() -> void: _trocar(campo, 1))


func _linha_apagada(campo: String) -> bool:
	for l in GameState.linhas_tela_criacao():
		if str(l.field) == campo:
			return bool(l.apagada)
	return false


func _trocar(campo: String, passo: int) -> void:
	var ids: Array = GameState.disciples.opcoes_ativas(campo)
	if ids.is_empty() or _linha_apagada(campo):
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
	var apagadas := {}
	for l in GameState.linhas_tela_criacao():
		apagadas[str(l.field)] = bool(l.apagada)
	for c in _campos:
		var campo := str(c.campo)
		var ids: Array = GameState.disciples.opcoes_ativas(campo)
		var atual := str(look.get(campo, ""))
		var pos := ids.find(atual) + 1
		var cont: Label = c.contador
		var y_txt := UiTema.y_texto(Rect2(0, 0, 1, ALT_LINHA))
		if str(c.kind) == "text":
			var nome_opcao := UiTema.txt("disc_opt_%s_%s" % [campo, atual], atual.to_upper())
			cont.text = nome_opcao
			cont.position = Vector2(roundf((LARG_VALOR - UiTema.largura_visivel(nome_opcao)) / 2.0), y_txt)
		else:
			var hex: Array = cores.get(campo, {}).get("colors", [])
			var chips: Array = c.chips
			for k in chips.size():
				(chips[k] as ColorRect).color = Color(str(hex[k])) if k < hex.size() else UiTema.G0
			var texto := "%d/%d" % [pos, ids.size()]
			cont.text = texto
			# Grupo [chips][6 px][contador] centralizado no valor (119 px de largura, 18 de altura).
			var larg_chips := float(chips.size()) * 16.0 + float(chips.size() - 1) * 2.0
			var total := larg_chips + 6.0 + UiTema.largura_visivel(texto)
			var x0 := roundf((LARG_VALOR - total) / 2.0)
			for k in chips.size():
				((chips[k] as ColorRect).get_parent() as Control).position = Vector2(x0 + float(k) * 18.0, 4)
			cont.position = Vector2(roundf(x0 + larg_chips + 6.0), y_txt)
		# Linha apagada (a peça de que ela depende está em "sem"): tom mais baixo e as setas não fazem nada.
		var apagada: bool = bool(apagadas.get(campo, false))
		UiTema.escurecer(c.rotulo, not apagada)
		UiTema.escurecer(c.valor, not apagada)
		for b in [c.esq, c.dir]:
			(b as Button).disabled = apagada
			UiTema.escurecer(b, not apagada)
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
