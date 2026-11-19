class_name BarraBaixo
extends Control
## Faixa de baixo (6d2, 30 px): "+N /CLIQUE", os botões de foco numa linha, LUTAR! e PASSAR O POSTO (só o ícone, a descrição
## vem no balão). Os botões só pedem a ação (sinais): quem abre a prévia/confirmação é o Fluxo.
## Foco trancado: o clique não treina nem troca o foco; pede a compra (`compra_pedida`) e a garagem abre o painel no cartão dele.

signal lutar_pedido
signal aposentar_pedido
signal compra_pedida(aparelho: String)  # clique no botão de foco trancado: a garagem abre o painel no cartão do aparelho

const ALTURA := 30.0
const Y0 := 330.0
const X_BOTOES := 92.0
const LARG_BOTAO := 86.0
const PASSO_BOTAO := 90.0
const ALTURA_BOTAO := 20.0
const Y_BOTAO := 5.0
const REGIAO_CLIQUE := 84.0  # largura de "+N /CLIQUE" (x 4..88)
const LUTAR := Rect2(507, 3, 102, 24)
const POSTO := Rect2(613, 4, 22, 22)
const X_SALVO := 430.0  # 6d3: o rótulo SALVO termina em 460, antes do botão SEGURAR (464); com 4 focos não há espaço e ele não aparece
const X_AJUDA := 488.0

var _por_clique: Label
var _sufixo: Label
var _dica: Label
var _salvo: Label
var _botoes: Dictionary = {}  # aparelho -> {botao, dono, trancado, estilo, id}
var _ajuda: Button
var _ids_botoes := ""  # aparelhos da carreira que têm botão agora (refaz os botões se a lista mudar)
var _fundo: Panel
var _focos: Control  # a fileira dos botões de foco (iguais entre si); LUTAR, PASSAR O POSTO e "?" têm tamanhos próprios
var _dica_aposentar := false  # a dica da academia está no ar: o botão de passar o posto "respira" em roxo
var _t_poll := 0.0
var _lutar: Button
var _aposentar: Button
var _dica_ativa := false
var _janela_aberta := false
var _t := 0.0
var _ultimo := ""
var _pulso_foco := false
var _so_sala := false
var _dica_livre := true  # há largura para a dica da primeira vez depois dos botões de foco
var _tween_salvo: Tween


func _ready() -> void:
	position = Vector2(0, Y0)
	z_index = 1200
	size = Vector2(640, ALTURA)
	mouse_filter = Control.MOUSE_FILTER_STOP  # a faixa segura o clique: nada por baixo (a sala) recebe
	_fundo = UiTema.painel(self, "ui_panel", Rect2(0, 0, 640, ALTURA))

	_por_clique = UiTema.rotulo(self, "+1", UiTema.COL_TREINO, 6, 4)  # txt_hero
	_por_clique.scale = Vector2(2, 2)
	UiTema.alinhar(_por_clique, "ignore")
	_sufixo = UiTema.rotulo(self, UiTema.txt("per_click_short", "/CLIQUE"), UiTema.G2, 20, 13)
	UiTema.alinhar(_sufixo, "ignore")
	_salvo = UiTema.rotulo(self, "", UiTema.COL_DISABLED, X_SALVO, UiTema.y_texto(Rect2(0, 0, 640, ALTURA)), 30, HORIZONTAL_ALIGNMENT_RIGHT)
	_salvo.modulate.a = 0.0
	UiTema.alinhar(_salvo, "ignore")
	set_meta("ui_align_row", "free")
	_focos = Control.new()
	_focos.name = "Focos"
	_focos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focos.size = Vector2(640, ALTURA)
	add_child(_focos)
	_montar_ajuda()
	_reconstruir_botoes()

	# Dica da primeira vez (some no primeiro treino): ao lado dos botões, em até 2 linhas.
	_dica = UiTema.rotulo(self, "", UiTema.Y1, 364, 5, 88, HORIZONTAL_ALIGNMENT_LEFT)
	UiTema.alinhar(_dica, "ignore")
	_posicionar_dica()
	_montar_lutar()
	_montar_aposentar()

	GameState.clicou.connect(func(_g: float, _c: bool, _a: String, _b: String, _t2: String) -> void: _dica_ativa = false)
	GameState.salvo.connect(_ao_salvo)
	GameState.carreira_mudou.connect(_checar_dica)
	GameState.arte_mudou.connect(func(_a: String) -> void: atualizar())
	_checar_dica()
	atualizar()


## Texto "SALVO" discreto: acende ao salvar e some em ~2 s (o texto fixo com a hora saiu da tela).
func _ao_salvo(_hora: String) -> void:
	if X_SALVO < X_BOTOES + float(GameState.aparelhos_da_carreira().size()) * PASSO_BOTAO:
		return  # 4 focos: o rótulo bateria no último botão
	_salvo.text = UiTema.txt("saved_footer", "SALVO").replace("{HORA}", "").strip_edges()
	if _tween_salvo != null and _tween_salvo.is_valid():
		_tween_salvo.kill()
	_salvo.modulate.a = 1.0
	_tween_salvo = create_tween()
	_tween_salvo.tween_interval(1.4)
	_tween_salvo.tween_property(_salvo, "modulate:a", 0.0, 0.6)


## Refaz os botões de foco quando a lista de aparelhos da carreira muda (escolha da arte, NOVA CARREIRA): 3 ou 4 botões de 86 px.
func _reconstruir_botoes() -> void:
	var lista: Array = GameState.aparelhos_da_carreira()
	var ids: Array = lista.map(func(a: Dictionary) -> String: return str(a.id))
	var chave := ",".join(ids)
	if chave == _ids_botoes:
		return
	_ids_botoes = chave
	for id in _botoes:
		_botoes[id].botao.queue_free()
	_botoes.clear()
	var i := 0
	for ap in lista:
		_botoes[ap.id] = _montar_botao(ap, i)
		i += 1
	_ultimo = ""
	_posicionar_dica()


## B3: a dica da primeira vez fica depois do último botão e só até a "?" (x 460, antes do botão SEGURAR); sem 70 px livres (4 focos), ela não aparece.
func _posicionar_dica() -> void:
	if _dica == null:
		return
	var x_dica := X_BOTOES + float(GameState.aparelhos_da_carreira().size()) * PASSO_BOTAO + 2.0
	_dica.position.x = x_dica
	_dica_livre = 460.0 - x_dica >= 70.0
	_dica.custom_minimum_size.x = maxf(0.0, minf(88.0, 460.0 - x_dica))
	_dica.size.x = _dica.custom_minimum_size.x


func _montar_botao(ap: Dictionary, i: int) -> Dictionary:
	var x := X_BOTOES + float(i) * PASSO_BOTAO
	var b := UiTema.botao(_focos, Rect2(x, Y_BOTAO, LARG_BOTAO, ALTURA_BOTAO))
	# Aparelho da arte: ícone da arte (art_boxing_9 / art_bjj_9) no lugar do ícone do atributo (ele treina os três).
	var arte_ap := str(ap.get("art", ""))
	var icone_foco := "art_%s_9" % arte_ap if arte_ap != "" else "icon_" + str(ap.attribute)
	if UiTema.sprite(icone_foco).is_empty():
		icone_foco = "icon_" + str(ap.attribute)
	var linhas: Array = ap.get("focus_label", ["", ""])
	var nome := str(linhas[1] if linhas.size() > 1 else linhas[0]).to_upper()
	# Aparelho comprado: ícone do atributo + nome, como grupo centralizado. O botão não tem texto próprio.
	var r_dono := UiTema.botao_conteudo(b, nome, UiTema.WHITE, 1, icone_foco, 4.0)
	var dono: Array = [r_dono, b.get_meta("icone")]
	# Aparelho que ainda não chegou: cadeado + nome (o preço e o motivo vêm no balão). Um segundo grupo, mesmo centro.
	var r_tr := UiTema.botao_conteudo(b, GameState.nome_curto_aparelho(str(ap.id)).to_upper(), UiTema.WHITE, 1, "mark_padlock", 4.0)
	var trancado: Array = [r_tr, b.get_meta("icone")]
	b.set_meta("icone", dono[1])
	var id: String = ap.id
	b.mouse_entered.connect(func() -> void: Dica.pedir(_texto_foco(id), b))
	b.mouse_exited.connect(func() -> void: Dica.limpar())
	b.pressed.connect(func() -> void:
		if GameState.aparelho_montado(id):
			GameState.definir_foco(id)
			atualizar()
		else:
			compra_pedida.emit(id)  # trancado: não troca o foco, só pede a compra no painel
	)
	return {"botao": b, "estilo": "ui_button_normal", "dono": dono, "trancado": trancado, "id": id,
		"m": UiTema.manifest().get("by_data_id", {}).get(str(GameState.desbloqueio(str(ap.id)).get("id", "")), {})}


## Dica do botão de foco de um aparelho que não está montado (preço, requisito, caixa).
func _texto_foco(id: String) -> String:
	var estado := GameState.estado_aparelho(id)
	if estado == "owned":
		return ""
	if estado == "boxed":
		return GameState.texto_ui("focus_boxed")
	var u: Dictionary = GameState.desbloqueio(id)
	var nome := GameState.nome_curto_aparelho(id)
	var req := str(u.get("requires", ""))
	var req_nome := GameState.nome_curto_aparelho(req).to_lower() if req != "" else ""
	var cost := float(u.get("cost", 0.0))
	match estado:
		"locked":
			return GameState.preencher(GameState.texto_ui("tape_locked_box" if GameState.tem_caixa(req) else "tape_locked"), {"nome": nome, "requisito": req_nome})
		"missing":
			return GameState.preencher(GameState.texto_ui("tape_short"), {"nome": nome, "n": NumberFormat.fmt(maxf(0.0, cost - GameState.treino))})
		"buyable":
			return GameState.preencher(GameState.texto_ui("tape_open"), {"nome": nome, "preco": NumberFormat.fmt(cost)})
	return ""


## "?" pequeno da faixa: as teclas (Espaço, Shift, 1 a 4, L, E, H, F11) aparecem no balão.
func _montar_ajuda() -> void:
	_ajuda = UiTema.botao(self, Rect2(X_AJUDA, 7, 16, 16))
	UiTema.botao_conteudo(_ajuda, "?", UiTema.COL_TEXT_1, 1)
	_ajuda.mouse_entered.connect(func() -> void: Dica.pedir(GameState.texto_ui("hint_keys"), _ajuda))
	_ajuda.mouse_exited.connect(func() -> void: Dica.limpar())


func _montar_lutar() -> void:
	_lutar = UiTema.botao_estilizado(self, LUTAR, "ui_button_fight")
	UiTema.botao_conteudo(_lutar, UiTema.txt("fight_button", "LUTAR!"), UiTema.Y2, 2)
	_lutar.pressed.connect(func() -> void: lutar_pedido.emit())


## PASSAR O POSTO: só o ícone da luva que passa; o nome e o Legado que ele leva vêm no balão ao passar o mouse.
func _montar_aposentar() -> void:
	_aposentar = UiTema.botao_estilizado(self, POSTO, "ui_button_retire")
	var a := UiTema.area_botao(_aposentar)
	var q := UiTema.tamanho_quadro("icon_pass_post")
	UiTema.textura_rect(_aposentar, "icon_pass_post", roundf(a.position.x + (a.size.x - q.x) / 2.0), UiTema.y_imagem(a, q.y))
	_aposentar.pressed.connect(func() -> void: aposentar_pedido.emit())
	_aposentar.mouse_entered.connect(func() -> void: Dica.pedir(_texto_posto(), _aposentar))
	_aposentar.mouse_exited.connect(func() -> void: Dica.limpar())


func _texto_posto() -> String:
	var texto := UiTema.txt("retire_button", "PASSAR O POSTO")
	var d: Dictionary = GameState.dica_aposentar()
	if bool(d.get("show", false)):
		texto += "\n" + str(d.get("text", "")).to_upper()
	return texto


func _checar_dica() -> void:
	var soma := 0.0
	for id in GameState.atributos:
		soma += float(GameState.atributos[id])
	_dica_ativa = soma <= 0.0


## Para o garçom da sala (seta que aponta o alvo).
func dica_ativa() -> bool:
	return _dica_ativa


## O Fluxo avisa quando uma janela (prévia, confirmação, vitória...) está aberta por cima.
func definir_janela_aberta(aberta: bool) -> void:
	_janela_aberta = aberta
	atualizar()


## Modo "só a sala": some tudo menos o LUTAR (e o Treino, que é do HUD).
func modo_so_sala(ativo: bool) -> void:
	_so_sala = ativo
	_fundo.visible = not ativo
	_por_clique.visible = not ativo
	_sufixo.visible = not ativo and _sufixo.visible
	_ajuda.visible = not ativo
	_aposentar.visible = not ativo
	for id in _botoes:
		_botoes[id].botao.visible = not ativo
	if not ativo:
		_ultimo = ""
		atualizar()


func atualizar() -> void:
	_reconstruir_botoes()
	# LUTAR! e PASSAR O POSTO só entre lutas: desabilitados durante a luta, com a tela de fim e depois do cinturão.
	var pode_lutar := GameState.pode_lutar() and not _janela_aberta
	var pode_aposentar := GameState.pode_aposentar() and not _janela_aberta
	_lutar.disabled = not pode_lutar
	_aposentar.disabled = not pode_aposentar
	UiTema.escurecer(_aposentar, pode_aposentar)
	if not pode_lutar:
		_lutar.modulate = Color(0.62, 0.6, 0.66)

	var foco := GameState.foco
	var estados := ""
	for id in _botoes:
		estados += GameState.estado_aparelho(id).left(2) + ","  # o(wned) b(uyable) m(issing) l(ocked)
	var chave := "%s|%s|%s" % [NumberFormat.fmt(GameState.por_clique()), foco, estados]
	if chave != _ultimo:
		_ultimo = chave
		_atualizar_por_clique()
		for id in _botoes:
			_aplicar_botao(_botoes[id], foco)


## "+N" em 2x e "/CLIQUE" pequeno ao lado, na região x 4..88. Se o número é grande, o sufixo sai e, se ainda assim não cabe, o número vai a 1x.
func _atualizar_por_clique() -> void:
	var texto := "+%s" % NumberFormat.fmt(GameState.por_clique())
	_por_clique.text = texto
	_por_clique.add_theme_color_override("font_color", UiTema.COL_TREINO)
	var w2 := UiTema.largura_visivel(texto) * 2.0
	var ws := UiTema.largura_visivel(_sufixo.text)
	var escala := 2 if w2 <= REGIAO_CLIQUE else 1
	_por_clique.scale = Vector2(escala, escala)
	_por_clique.position = Vector2(6, UiTema.y_texto(Rect2(0, 0, 640, ALTURA), escala))
	var w := w2 if escala == 2 else UiTema.largura_visivel(texto)
	_sufixo.visible = not _so_sala and 6.0 + w + 2.0 + ws <= 6.0 + REGIAO_CLIQUE
	_sufixo.position.x = 6.0 + w + 2.0


## Botão de foco do aparelho: normal (montado) ou trancado (comprável / sem Treino / depois do anterior).
func _aplicar_botao(d: Dictionary, foco: String) -> void:
	var id: String = d.id
	var estado := GameState.estado_aparelho(id)
	var montado := estado == "owned"
	for n in d.dono:
		(n as CanvasItem).visible = montado
	for n in d.trancado:
		(n as CanvasItem).visible = not montado
	if montado:
		var ativo: bool = id == foco
		var atributo := GameState.atributo_do_aparelho(id)
		var estilo := "ui_button_focus_" + atributo if ativo else "ui_button_normal"
		if ativo and str(GameState.dados.aparelho(id).get("art", "")) != "":
			estilo = "ui_button_focus_art"  # aparelho da arte: botão roxo (treina os 3 atributos)
		if estilo != d.estilo:
			d.estilo = estilo
			UiTema.aplicar_estilo_botao(d.botao, estilo)
		return
	var cor_nome := UiTema.COL_TEXT_1 if estado == "buyable" else (UiTema.COL_TEXT_2 if estado in ["missing", "boxed"] else UiTema.COL_DISABLED)
	(d.trancado[0] as Label).add_theme_color_override("font_color", cor_nome)
	_estilo_trancado(d, "locked" if estado == "boxed" else estado, false)


## Moldura do botão trancado. O comprável alterna com o quadro de pulso (3 fps) para chamar a atenção.
func _estilo_trancado(d: Dictionary, estado: String, pulso: bool) -> void:
	var fotos: Dictionary = d.m.get("focus_button", {})
	var chave_estilo := "buyable_pulse" if estado == "buyable" and pulso else estado
	var estilo := str(fotos.get(chave_estilo, "ui_button_focus_locked_" + chave_estilo))
	if estilo == d.estilo:
		return
	d.estilo = estilo
	UiTema.aplicar_estilo_botao(d.botao, estilo)
	d.botao.add_theme_stylebox_override("pressed", UiTema.estilo(estilo))  # clicar não "afunda": não treina nem troca foco


func _process(delta: float) -> void:
	_t += delta
	var ap := GameState.dados.aparelho(GameState.foco)
	_dica.visible = _dica_ativa and not _so_sala and _dica_livre
	# A dica de passar o posto da academia depende de relógio (1 leitura por segundo).
	_t_poll += delta
	if _t_poll >= 1.0:
		_t_poll = 0.0
		_dica_aposentar = bool(GameState.dica_aposentar().get("show", false))
	if _dica_aposentar and not _aposentar.disabled:
		_aposentar.modulate = Color.WHITE.lerp(Color(1.3, 1.15, 1.45), 0.5 + 0.5 * sin(_t * 4.0))  # respira em roxo
	if _dica_ativa:
		_dica.text = str(ap.get("first_hint", "")).to_upper()
		_dica.modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(_t * 5.0))
	# Botões de foco prontos para comprar piscam a borda (verde / verde claro, 3 fps).
	var pulso := int(_t * 3.0) % 2 == 1
	if pulso != _pulso_foco:
		_pulso_foco = pulso
		for id in _botoes:
			var d: Dictionary = _botoes[id]
			if GameState.estado_aparelho(id) == "buyable":
				_estilo_trancado(d, "buyable", pulso)
	# LUTAR! "respira" de leve quando está disponível (convite sem gritar).
	if not _lutar.disabled:
		var k := 0.5 + 0.5 * sin(_t * 3.0)
		_lutar.modulate = Color.WHITE.lerp(Color(1.18, 1.1, 1.1), k)
