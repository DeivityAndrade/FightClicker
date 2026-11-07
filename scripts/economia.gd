class_name Economia
extends RefCounted
## Regras de custo e compra (funções puras, sem estado).

# Tolerância de float: evita "saldo 59.9999999 não compra o item de 60".
const EPS := 1.0e-9


## Arredonda PARA CIMA mantendo 3 dígitos significativos (inteiro abaixo de 1000).
static func teto3(x: float) -> float:
	if is_nan(x) or x <= 0.0:
		return 0.0
	if is_inf(x):
		return x
	x = x * (1.0 - EPS)  # 60.0000000001 vira 60, não 61
	if x < 1000.0:
		return ceilf(x)
	var e := int(floor(log(x) / log(10.0))) - 2
	var f := pow(10.0, e)
	return ceilf(x / f) * f


static func pode_pagar(saldo: float, custo: float) -> bool:
	return is_finite(custo) and saldo >= custo * (1.0 - EPS)


## Custo da próxima unidade de um gerador que já tem n unidades.
static func custo_gerador(base_cost: float, growth: float, n: int) -> float:
	return teto3(base_cost * pow(growth, n))
