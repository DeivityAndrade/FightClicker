extends "res://tests/test_base.gd"
## Testa o formatador de números (todas as faixas e casos-limite).


func rodar_testes() -> void:
	var casos := [
		# Abaixo de 1000: inteiro.
		[0.0, "0"], [1.0, "1"], [42.0, "42"], [999.0, "999"], [0.4, "0"], [999.4, "999"],
		# Arredondar para 1000 sobe de faixa.
		[999.5, "1.00K"], [1000.0, "1.00K"],
		# K com 3 dígitos significativos.
		[1200.0, "1.20K"], [1234.0, "1.23K"], [9994.0, "9.99K"], [9996.0, "10.0K"],
		[12300.0, "12.3K"], [99960.0, "100K"], [123000.0, "123K"], [999000.0, "999K"],
		# Nunca "1000K": vira 1.00M.
		[999999.0, "1.00M"], [999500.0, "1.00M"],
		[3.4e6, "3.40M"], [3.45e6, "3.45M"], [56.7e9, "56.7B"], [999e12, "999T"],
		[1.0e12, "1.00T"],
		# Transição para científico.
		[999.4e12, "999T"], [999.6e12, "1.00e15"], [1.0e15, "1.00e15"], [1.23e15, "1.23e15"],
		[4.56e300, "4.56e300"], [1.0e300, "1.00e300"], [9.996e20, "1.00e21"],
		[1.7976931348623157e308, "1.80e308"],
		# Negativos.
		[-1500.0, "-1.50K"], [-5.0, "-5"], [-0.3, "0"],
	]
	for c in casos:
		checar_igual(NumberFormat.fmt(c[0]), c[1], "fmt(%s)" % str(c[0]))

	# Exemplos do critério de aceite 4.
	var aceite := [[1.0, "1"], [999.0, "999"], [1200.0, "1.20K"], [3.4e6, "3.40M"],
		[1.23e15, "1.23e15"], [1.0e300, "1.00e300"]]
	for c in aceite:
		checar_igual(NumberFormat.fmt(c[0]), c[1], "critério 4: fmt(%s)" % str(c[0]))

	# Modo TRUNCAR (saldo e atributos): nunca mostra mais do que se tem.
	var cortes := [
		[999600.0, "999K"], [59.7, "59"], [1150.0, "1.15K"], [1149.99, "1.14K"], [0.9, "0"],
		[999.9, "999"], [1000.0, "1.00K"], [999999.0, "999K"], [1.0e6, "1.00M"], [12345.0, "12.3K"],
		[999.9e12, "999T"], [1.0e15, "1.00e15"], [1.999e15, "1.99e15"], [1.0e300, "1.00e300"],
		[0.0, "0"], [60.0, "60"], [59.9999999999, "60"], [-1500.0, "-1.50K"],
	]
	for c in cortes:
		checar_igual(NumberFormat.fmt(c[0], NumberFormat.TRUNCAR), c[1], "TRUNCAR fmt(%s)" % str(c[0]))
	# ARREDONDAR continua igual à Fase 1 (modo padrão).
	checar_igual(NumberFormat.fmt(999600.0), "1.00M", "ARREDONDAR: 999600 sobe de faixa")
	checar_igual(NumberFormat.fmt(999600.0, NumberFormat.ARREDONDAR), "1.00M", "ARREDONDAR explícito")
	# Varredura: TRUNCAR nunca passa do valor real.
	var vt := 1.0
	var truncou_ok := true
	while vt < 1.0e14:
		var t := NumberFormat.fmt(vt, NumberFormat.TRUNCAR)
		if _para_numero(t) > vt * (1.0 + 1e-9):
			truncou_ok = false
			print("  TRUNCAR passou do valor: %s -> %s" % [str(vt), t])
		vt *= 3.7
	checar(truncou_ok, "TRUNCAR nunca mostra mais do que o valor")

	# Valores inválidos: texto seguro, sem travar.
	checar_igual(NumberFormat.fmt(NAN), "0", "NaN vira 0")
	checar_igual(NumberFormat.fmt(INF), "Infinito", "infinito vira texto seguro")
	checar_igual(NumberFormat.fmt(-INF), "-Infinito", "-infinito vira texto seguro")

	# Varredura: de 1 a ~1e308 nenhum texto tem mais de 3 dígitos antes do sufixo nem "1000".
	var v := 1.0
	var ok := true
	while v < 1.0e308:
		for fator in [1.0, 0.9995, 0.99999, 1.0005]:
			var t := NumberFormat.fmt(v * fator)
			if "1000" in t and not t.contains("e") or t.contains("nan") or t.contains("inf") or t.is_empty():
				ok = false
				print("  texto suspeito: %s -> %s" % [str(v * fator), t])
		v *= 7.3
	checar(ok, "varredura até 1e308 sem texto quebrado")


# Converte "12.3K" de volta para número (só para a varredura).
func _para_numero(t: String) -> float:
	var mult := 1.0
	for i in NumberFormat.SUFIXOS.size():
		var s: String = NumberFormat.SUFIXOS[i]
		if s != "" and t.ends_with(s):
			mult = pow(1000.0, i)
			t = t.trim_suffix(s)
	return t.to_float() * mult
