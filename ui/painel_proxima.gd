class_name PainelProxima
extends Control
## A próxima luta, sempre à vista (6d2): moldura do canto de cima à esquerda, logo abaixo dos atributos em miniatura.
## Guarda o `BlocoProxima` (folhinha da data, risco, revanche, cartão da mudança) e acompanha a altura dele. Não tem regra de jogo.

const LARGURA := 128.0
const Y := 67.0  # 2 px mais baixo que antes: a sombra do cartão dos atributos (c_cartao) cai logo acima

var bloco: BlocoProxima


func _ready() -> void:
	position = Vector2(0, Y)
	z_index = 1200
	size = Vector2(LARGURA, 49.0)
	mouse_filter = Control.MOUSE_FILTER_STOP  # a sala fica por baixo: o clique na moldura não vai para ela
	set_meta("ui_margens", "h")
	UiTema.painel(self, "c_cartao", Rect2(0, 0, LARGURA, size.y + 2.0))
	bloco = BlocoProxima.new()
	add_child(bloco)
	bloco.altura_mudou.connect(_ao_altura)


## O bloco mede o que ocupa (a fita da revanche, o cartão da mudança...) e a moldura cresce junto, com 3 px de margem em cima e embaixo.
func _ao_altura(altura: int) -> void:
	size.y = float(altura) + 6.0
	for c in get_children():
		if c is Panel:
			(c as Panel).size.y = size.y + 2.0
