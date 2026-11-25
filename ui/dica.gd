class_name Dica
extends Control
## Dica flutuante (Fase 5.1, nível 3 de leitura), único balão de descrição do jogo (Fase 6d): aparece ao passar o mouse,
## colado ao cursor e fora do item apontado, e some ao sair. Aparece no mesmo quadro (bem dentro dos 0,15 s).
## Texto em maiúsculas, no tamanho txt_body, linhas longas quebradas em MAX_LARG px.
##
## Uso:
##   Dica.pedir("texto\noutra linha", alvo)                 no mouse_entered (alvo = o Control apontado, opcional)
##   Dica.pedir_linhas([{"texto": "...", "cor": Color}], alvo)   linhas coloridas (nome, descrição, efeito, custo)
##   Dica.limpar()                                          no mouse_exited
## Quem desenha o próprio cartão (mapa da árvore) usa só `Dica.posicionar(...)` para a mesma regra de posição.

const MAX_LARG := 150.0  # largura máxima do texto de uma linha (px da base 640x360)
const TELA := Rect2(4, 4, 632, 352)  # limite: o balão nunca passa daqui (margem mínima de 4 px da borda)
const FOLGA := 3.0  # espaço entre o balão e o item apontado

static var instancia: Dica = null

var _fundo: NinePatchRect
var _caixa: Control
var _texto := ""
var _linhas: Array = []  # [{texto, cor}] já em maiúsculas
var _alvo: Control = null
var ancora_fixa := Vector2(-1, -1)  # só para o verificador: fixa a dica num ponto da tela


func _ready() -> void:
	instancia = self
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 4096  # o teto do Godot: acima das janelas (Fluxo 3000 + janela 2000) e do cursor-luva (4000); empate = ordem da árvore
	visible = false
	UiTema.alinhar(self, "ignore")  # flutua junto do mouse: posição livre de propósito
	set_anchors_preset(Control.PRESET_TOP_LEFT)


func _exit_tree() -> void:
	if instancia == self:
		instancia = null


static func pedir(texto: String, alvo: Control = null) -> void:
	if instancia != null:
		instancia.mostrar(texto, alvo)


static func pedir_linhas(linhas: Array, alvo: Control = null) -> void:
	if instancia != null:
		instancia.mostrar_linhas(linhas, alvo)


static func limpar() -> void:
	if instancia != null:
		instancia.esconder()


func mostrar(texto: String, alvo: Control = null) -> void:
	var t := texto.to_upper()
	var linhas: Array = []
	var i := 0
	for l in t.split("\n"):
		linhas.append({"texto": l, "cor": UiTema.WHITE if i == 0 and t.contains("\n") else UiTema.G3})
		i += 1
	if t == "":
		linhas = []
	_mostrar(t, linhas, alvo)


func mostrar_linhas(linhas: Array, alvo: Control = null) -> void:
	var l2: Array = []
	var chave := ""
	for l in linhas:
		var tx := str(l.get("texto", "")).to_upper()
		if tx == "":
			continue
		l2.append({"texto": tx, "cor": l.get("cor", UiTema.G3)})
		chave += tx + "\n"
	_mostrar(chave, l2, alvo)


func _mostrar(chave: String, linhas: Array, alvo: Control) -> void:
	if linhas.is_empty():
		esconder()
		return
	_alvo = alvo
	if chave != _texto:
		_texto = chave
		_linhas = linhas
		_montar()
	visible = true
	_seguir()


func esconder() -> void:
	visible = false
	_texto = ""
	_alvo = null
	if _caixa != null:
		_caixa.queue_free()
		_caixa = null


func texto_atual() -> String:
	return _texto.strip_edges() if visible else ""


## Retângulo do balão agora (na base 640x360), para o verificador e os testes.
func retangulo() -> Rect2:
	return Rect2(position, size)


## Quebra `texto` em linhas de no máximo `larg` px (por palavras; palavra maior que a linha é cortada).
static func quebrar(texto: String, larg: float) -> Array:
	var r: Array = []
	var atual := ""
	for palavra in texto.split(" ", false):
		var p: String = palavra
		while UiTema.largura_visivel(p) > larg and p.length() > 1:
			var corte := p.length() - 1
			while corte > 1 and UiTema.largura_visivel(p.substr(0, corte)) > larg:
				corte -= 1
			if atual != "":
				r.append(atual)
				atual = ""
			r.append(p.substr(0, corte))
			p = p.substr(corte)
		var teste := p if atual == "" else atual + " " + p
		if UiTema.largura_visivel(teste) <= larg:
			atual = teste
		else:
			r.append(atual)
			atual = p
	if atual != "":
		r.append(atual)
	return r


func _montar() -> void:
	if _caixa != null:
		_caixa.queue_free()
	_caixa = Control.new()
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caixa)
	var finas: Array = []  # [{texto, cor}] depois de quebrar
	var larg := 0.0
	for l in _linhas:
		var partes := quebrar(str(l.texto), MAX_LARG)
		if partes.is_empty():
			partes = [""]  # linha em branco de propósito (separador)
		for parte in partes:
			finas.append({"texto": parte, "cor": l.cor})
			larg = maxf(larg, UiTema.largura_visivel(parte))
	var w := ceilf(larg) + 12.0
	var h := float(finas.size()) * 9.0 + 7.0
	_caixa.size = Vector2(w, h)
	size = _caixa.size
	UiTema.painel(_caixa, "ui_card", Rect2(0, 0, w, h))
	for i in finas.size():
		UiTema.rotulo(_caixa, finas[i].texto, finas[i].cor, 6, 2 + i * 9)


func _process(_d: float) -> void:
	if visible:
		_seguir()


func _seguir() -> void:
	if _caixa == null:
		return
	var pai := get_parent()
	var m: Vector2
	if ancora_fixa.x >= 0.0:
		m = ancora_fixa
	else:
		m = pai.get_local_mouse_position() if pai is Control else Vector2.ZERO
	var alvo := Rect2()
	if _alvo != null and is_instance_valid(_alvo) and _alvo.is_inside_tree() and pai is Control:
		alvo = Rect2(_alvo.get_global_rect().position - (pai as Control).get_global_rect().position, _alvo.get_global_rect().size)
	position = posicionar(size, m, alvo, TELA)


## Onde pôr um balão de tamanho `tam` ao lado do cursor `m`, dentro de `limite`, sem cobrir `alvo` (o item apontado;
## Rect2() = não há item, só o cursor). Testa embaixo, em cima, à direita e à esquerda do item e fica com o lugar
## mais perto do cursor. Se nenhum couber sem cobrir (balão enorme), fica no que cobre menos.
static func posicionar(tam: Vector2, m: Vector2, alvo: Rect2, limite: Rect2 = TELA) -> Vector2:
	var item := alvo
	if item.size.x <= 0.0 or item.size.y <= 0.0:
		item = Rect2(m, Vector2(10, 12))  # só o cursor: a "luva" ocupa uns 10x12 px a partir da ponta
	var x_min := limite.position.x
	var x_max := limite.end.x - tam.x
	var y_min := limite.position.y
	var y_max := limite.end.y - tam.y
	var cx := clampf(m.x + 8.0, x_min, maxf(x_min, x_max))
	var cy := clampf(m.y - tam.y * 0.5, y_min, maxf(y_min, y_max))
	var candidatos: Array[Vector2] = [
		Vector2(cx, item.end.y + FOLGA),  # embaixo
		Vector2(cx, item.position.y - tam.y - FOLGA),  # em cima
		Vector2(item.end.x + FOLGA, cy),  # à direita
		Vector2(item.position.x - tam.x - FOLGA, cy),  # à esquerda
	]
	var melhor := Vector2.ZERO
	var melhor_nota := INF
	for c in candidatos:
		var r := Rect2(c, tam)
		var dentro := r.position.x >= x_min and r.position.y >= y_min and r.end.x <= limite.end.x and r.end.y <= limite.end.y
		if not dentro:
			continue
		var perto := _dist_ate(r, m)
		if perto < melhor_nota:
			melhor_nota = perto
			melhor = c
	if melhor_nota < INF:
		return Vector2(floorf(melhor.x), floorf(melhor.y))
	# Nada cabe inteiro: encosta no lado com mais espaço e prende na tela (cobre o mínimo possível).
	var sobra_baixo := limite.end.y - item.end.y
	var sobra_cima := item.position.y - limite.position.y
	var y := item.end.y + FOLGA if sobra_baixo >= sobra_cima else item.position.y - tam.y - FOLGA
	return Vector2(floorf(clampf(cx, x_min, maxf(x_min, x_max))), floorf(clampf(y, y_min, maxf(y_min, y_max))))


static func _dist_ate(r: Rect2, p: Vector2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p)
