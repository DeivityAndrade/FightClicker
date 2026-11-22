class_name CartaoAdversario
extends Control
## Fase 8a1: cartão da passiva DO ADVERSÁRIO, à esquerda da janela da prévia (o da sua passiva mora à direita). Mostra o ícone e o nome
## (QUEIXO DE FERRO / BASE LARGA / ENSABOADO / BLINDADO), a linha do efeito e, embaixo, a quem ela atrapalha ("ATRAPALHA: K.O. DE EMBALO"
## em vermelho ou "NÃO ATRAPALHA O SEU JEITO" em verde). Só lê as chaves `opp_passive_*` de `GameState.previa()`; a chance mostrada na
## prévia já vem com a passiva, e o texto de quem ela atrapalha vem pronto do GameState.

const LARG := 136.0
const PAD := 6.0
const INTERIOR := LARG - PAD * 2.0
const PASSO := 10.0  # o rótulo de verdade gasta 10 px por linha (fonte 12 - 2 de espaçamento)

var _altura := 0.0
var linha_rotulo: Label
var hits_rotulo: Label


func altura() -> float:
	return _altura


## `d` = a prévia: lê opp_passive_id | name | line | hits | hits_text | icon.
func montar(d: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	var nome := str(d.get("opp_passive_name", "")).to_upper()
	var linha := _quebrar(str(d.get("opp_passive_line", "")).to_upper(), INTERIOR)
	var atrapalha := bool(d.get("opp_passive_hits", false))
	var hits := _quebrar(str(d.get("opp_passive_hits_text", "")).to_upper(), INTERIOR)
	var icone := str(d.get("opp_passive_icon", ""))
	var y := 6.0
	var y_nome := y
	y += 16.0 + 5.0
	var y_linha := y
	y += float(linha.size()) * PASSO + 4.0
	var y_hits := y
	y += float(hits.size()) * PASSO + 5.0
	_altura = y
	size = Vector2(LARG, _altura)
	var fundo := UiTema.nine_patch(self, "ui_card", Rect2(0, 0, LARG, _altura))
	fundo.set_meta("ui_align", "ignore")
	# Ícone 16x16 + nome, o grupo centralizado no cartão.
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = Vector2(PAD, y_nome)
	faixa.size = Vector2(INTERIOR, 16)
	faixa.set_meta("ui_margens", "h")
	add_child(faixa)
	var tem_icone := icone != "" and not UiTema.sprite(icone).is_empty()
	var lw := UiTema.largura_visivel(nome)
	var grupo := lw + (20.0 if tem_icone else 0.0)
	var gx := roundf((INTERIOR - grupo) / 2.0)
	if tem_icone:
		UiTema.textura_rect(faixa, icone, gx, 0)
	UiTema.rotulo(faixa, nome, UiTema.R3, gx + (20.0 if tem_icone else 0.0), 4)
	linha_rotulo = _texto(linha, UiTema.CREAM, y_linha)
	hits_rotulo = _texto(hits, UiTema.R3 if atrapalha else UiTema.GR3, y_hits)


func _texto(linhas: Array[String], cor: Color, y: float) -> Label:
	var l := UiTema.rotulo(self, "\n".join(linhas), cor, PAD, y, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(INTERIOR, float(linhas.size()) * PASSO + 2.0)
	UiTema.alinhar(l, "center_h")
	return l


## Quebra por palavra em linhas de até `larg` px (a mesma conta do CartaoPassiva e do verificador).
func _quebrar(texto: String, larg: float) -> Array[String]:
	var linhas: Array[String] = []
	var atual := ""
	for palavra in texto.split(" ", false):
		var tentativa: String = palavra if atual == "" else atual + " " + palavra
		if atual != "" and UiTema.largura_visivel(tentativa) > larg:
			linhas.append(atual)
			atual = palavra
		else:
			atual = tentativa
	if atual != "":
		linhas.append(atual)
	return linhas
