class_name NumberFormat
extends RefCounted
## Formatador único de números do jogo. Toda a UI usa NumberFormat.fmt().
## Formato: 3 dígitos significativos, ponto decimal.
##   abaixo de 1000: inteiro (0, 42, 999)
##   K, M, B, T: 1.00K, 12.3K, 123K, 3.45M
##   a partir de 1e15: científico (1.23e15)
## Dois modos:
##   ARREDONDAR (padrão): arredonda para o mais próximo (treino/s, por clique, números flutuantes).
##   TRUNCAR: corta para baixo, nunca mostra mais do que o jogador tem (saldo e atributos).

const ARREDONDAR := 0
const TRUNCAR := 1

# Sufixos por grupo de mil (índice 1 = mil). Trocar aqui muda o jogo inteiro.
const SUFIXOS: Array[String] = ["", "K", "M", "B", "T"]
# Textos seguros para valores inválidos.
const TEXTO_NAN := "0"
const TEXTO_INFINITO := "Infinito"
# Evita 1.15 * 100 = 114.999... virar 1.14 no modo TRUNCAR.
const EPS_TRUNCAR := 1.0e-9


static func fmt(valor: float, modo: int = ARREDONDAR) -> String:
	if is_nan(valor):
		push_warning("NumberFormat: valor NaN recebido, mostrando 0.")
		return TEXTO_NAN
	if is_inf(valor):
		push_warning("NumberFormat: valor infinito recebido.")
		return ("-" if valor < 0.0 else "") + TEXTO_INFINITO
	var texto := _positivo(absf(valor), modo)
	if valor < 0.0 and texto != "0":
		return "-" + texto
	return texto


# Formata um valor >= 0 e finito.
static func _positivo(a: float, modo: int) -> String:
	# Abaixo de 1000 (depois de arredondar/truncar): inteiro.
	var inteiro := _inteiro(a, modo)
	if inteiro < 1000.0:
		return str(int(inteiro))

	# Descobre o grupo (1 = K, 2 = M...). Acima do último sufixo, científico.
	var grupo := 1
	while grupo < SUFIXOS.size() and a >= pow(1000.0, grupo + 1):
		grupo += 1
	if grupo >= SUFIXOS.size():
		return _cientifico(a, modo)

	var m := maxf(a / pow(1000.0, grupo), 1.0)
	var casas := _casas(m)
	var r := _corta(m, casas, modo)
	# O arredondamento pode subir de faixa (9.996 -> 10.0, 999.6 -> 1000).
	if _casas(r) != casas:
		casas = _casas(r)
		r = _corta(r, casas, modo)
	if r >= 1000.0:
		grupo += 1
		if grupo >= SUFIXOS.size():
			return _cientifico(pow(1000.0, grupo), modo)
		r = 1.0
		casas = 2
	return _com_casas(r, casas) + SUFIXOS[grupo]


static func _cientifico(a: float, modo: int) -> String:
	var e := int(floor(log(a) / log(10.0)))
	# Corrige erro de ponto flutuante do log.
	if pow(10.0, e) > a:
		e -= 1
	elif pow(10.0, e + 1) <= a:
		e += 1
	var r := _corta(a / pow(10.0, e), 2, modo)
	if r >= 10.0:
		r = 1.0
		e += 1
	return "%se%d" % [_com_casas(r, 2), e]


static func _inteiro(a: float, modo: int) -> float:
	if modo == TRUNCAR:
		return floorf(a + EPS_TRUNCAR)
	return roundf(a)


# Casas decimais para manter 3 dígitos significativos.
static func _casas(m: float) -> int:
	if m < 10.0:
		return 2
	if m < 100.0:
		return 1
	return 0


static func _corta(m: float, casas: int, modo: int) -> float:
	var f := pow(10.0, casas)
	if modo == TRUNCAR:
		return floorf(m * f + EPS_TRUNCAR) / f
	return roundf(m * f) / f


static func _com_casas(r: float, casas: int) -> String:
	match casas:
		2:
			return "%.2f" % r
		1:
			return "%.1f" % r
	return "%d" % int(r)
