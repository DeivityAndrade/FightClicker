extends SceneTree
## Gera os sons PLACEHOLDER (Fases 2 e 3) em assets/sfx/*.wav, 100% sintetizados por código
## (seno, ruído e envelopes). Nada baixado: origem = este script.
## Uso: godot --headless --path E:/Fightclicker --script res://tools/sfx/make_sfx.gd
## Depois rode `--import` uma vez para o Godot gerar os .import.

const TAXA := 22050
const PASTA := "res://assets/sfx/"

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 20261105
	# Impacto de soco: 4 variações de tom.
	var tons := [0.85, 1.0, 1.15, 1.3]
	for i in tons.size():
		_salvar("punch_%d" % (i + 1), _soco(tons[i], false))
	_salvar("punch_crit", _soco(1.0, true))
	_salvar("rope_1", _corda(1.0))
	_salvar("rope_2", _corda(1.18))
	_salvar("step_1", _passo(1.0))
	_salvar("step_2", _passo(1.2))
	_salvar("buy", _compra())
	_salvar("focus", _foco())
	# Fase 3 (depois dos antigos: a sequência do ruído dos sons da Fase 2 não muda).
	_salvar("hit_heavy", _golpe_forte())
	_salvar("whoosh", _whoosh())
	_salvar("block", _bloqueio())
	_salvar("ko", _queda())
	_salvar("bell_start", _sino(2, 0.34))
	_salvar("bell_end", _sino(3, 0.24))
	_salvar("crowd", _publico())
	_salvar("win", _vitoria())
	_salvar("lose", _derrota())
	_salvar("coin", _moeda())
	# Fase 6a (DEPOIS de todos os antigos: o ruído tem semente fixa e a ordem mudaria os sons que já existem).
	# Voz: um arquivo por timbre e por vogal (u, o, a, e, i = 0, +2, +4, +5, +7 semitons acima da base).
	var vogais := ["u", "o", "a", "e", "i"]
	var passos := [0, 2, 4, 5, 7]
	for timbre in [["first", 180.0], ["coach", 110.0], ["disciple", 260.0]]:
		for k in vogais.size():
			_salvar("voice_%s_%s" % [timbre[0], vogais[k]], _voz(timbre[0], timbre[1] * pow(2.0, passos[k] / 12.0)))
	_salvar("strap_rip", _fecho_rasgando())
	_salvar("tap_glove", _toque_de_luva())
	print("sfx gerados em ", PASTA)
	quit(0)


func _soco(tom: float, critico: bool) -> PackedFloat32Array:
	var dur := 0.34 if critico else 0.17
	var n := int(dur * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var fase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		# Corpo grave: seno que desce de ~170 Hz para ~55 Hz.
		var f := (55.0 + 120.0 * exp(-t * 30.0)) * tom
		fase += TAU * f / TAXA
		var corpo := sin(fase) * exp(-t * 20.0)
		# Estalo de couro: ruído passa-baixa que morre rápido.
		var r := _rng.randf_range(-1.0, 1.0)
		lp += (r - lp) * 0.45
		var estalo := lp * exp(-t * 75.0) * 0.9
		var v := corpo * 0.9 + estalo
		if critico:
			v += sin(TAU * 880.0 * t) * exp(-t * 13.0) * 0.28
			v += sin(TAU * 1320.0 * t) * exp(-t * 17.0) * 0.18
		s[i] = tanh(v * 1.3)
	return s


func _corda(tom: float) -> PackedFloat32Array:
	var n := int(0.16 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var a := 0.0
	var b := 0.0
	for i in n:
		var t := float(i) / TAXA
		var x := t / 0.16
		var r := _rng.randf_range(-1.0, 1.0)
		var c1 := 0.10 + 0.35 * x * tom
		a += (r - a) * c1
		b += (a - b) * 0.5
		var amp := sin(PI * x) * 0.8
		var v := (a - b) * 2.2 * amp
		# "Tec" da corda batendo no chão no fim.
		if t > 0.12:
			v += sin(TAU * 260.0 * tom * t) * exp(-(t - 0.12) * 120.0) * 0.5
		s[i] = tanh(v)
	return s


func _passo(tom: float) -> PackedFloat32Array:
	var n := int(0.09 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var fase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		fase += TAU * (95.0 * tom - 400.0 * t) / TAXA
		var r := _rng.randf_range(-1.0, 1.0)
		lp += (r - lp) * 0.25
		s[i] = tanh((sin(fase) * exp(-t * 45.0) + lp * exp(-t * 90.0) * 0.5) * 1.2)
	return s


func _compra() -> PackedFloat32Array:
	var n := int(0.26 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var f := 523.25 if t < 0.09 else 784.0
		var te := t if t < 0.09 else t - 0.09
		# Onda triangular: som de "moeda" suave.
		var ph := fmod(t * f, 1.0)
		var tri := 4.0 * absf(ph - 0.5) - 1.0
		s[i] = tri * exp(-te * 14.0) * 0.55
	return s


func _foco() -> PackedFloat32Array:
	var n := int(0.05 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / TAXA
		s[i] = sin(TAU * 660.0 * t) * exp(-t * 70.0) * 0.5
	return s


# --- Fase 3 ---

# Baque pesado (crítico, contra-golpe, K.O.): seno grave descendo e estalo abafado.
func _golpe_forte() -> PackedFloat32Array:
	var n := int(0.34 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var fase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		fase += TAU * (40.0 + 110.0 * exp(-t * 22.0)) / TAXA
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.18
		s[i] = tanh((sin(fase) * exp(-t * 11.0) * 1.1 + lp * exp(-t * 45.0) * 0.8) * 1.5)
	return s


# Vento de um soco que passa: ruído filtrado que sobe e desce.
func _whoosh() -> PackedFloat32Array:
	var n := int(0.24 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var a := 0.0
	var b := 0.0
	for i in n:
		var t := float(i) / TAXA
		var x := t / 0.24
		var c := 0.06 + 0.5 * sin(PI * x)
		a += (_rng.randf_range(-1.0, 1.0) - a) * c
		b += (a - b) * 0.35
		s[i] = tanh((a - b) * 3.0 * sin(PI * x) * 0.9)
	return s


# "Tok" curto de luva em luva (defesa).
func _bloqueio() -> PackedFloat32Array:
	var n := int(0.13 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.5
		var v := sin(TAU * 330.0 * t) * exp(-t * 38.0) * 0.7 + sin(TAU * 495.0 * t) * exp(-t * 50.0) * 0.4
		s[i] = tanh(v + lp * exp(-t * 120.0) * 0.8)
	return s


# Queda: corpo no chão, uma batida grave e outra mais fraca (quicando).
func _queda() -> PackedFloat32Array:
	var n := int(0.7 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var fase := 0.0
	var fase2 := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		fase += TAU * (34.0 + 80.0 * exp(-t * 18.0)) / TAXA
		var v := sin(fase) * exp(-t * 7.0)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.12
		v += lp * exp(-t * 28.0) * 0.9
		if t > 0.2:
			var t2 := t - 0.2
			fase2 += TAU * (30.0 + 55.0 * exp(-t2 * 20.0)) / TAXA
			v += sin(fase2) * exp(-t2 * 12.0) * 0.5
		s[i] = tanh(v * 1.4)
	return s


# Sino de ringue: parciais inarmônicos; `batidas` pancadas espaçadas por `passo` segundos.
func _sino(batidas: int, passo: float) -> PackedFloat32Array:
	var dur := passo * (batidas - 1) + 0.9
	var n := int(dur * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var parciais := [1.0, 2.76, 5.4, 8.93]
	var amps := [1.0, 0.55, 0.3, 0.15]
	var decs := [4.5, 6.5, 9.0, 13.0]
	for b in batidas:
		var t0 := b * passo
		var i0 := int(t0 * TAXA)
		for i in range(i0, n):
			var t := float(i - i0) / TAXA
			var v := 0.0
			for k in 4:
				v += sin(TAU * 620.0 * parciais[k] * t) * amps[k] * exp(-t * decs[k])
			s[i] += v * 0.42
	for i in n:
		s[i] = tanh(s[i])
	return s


# Torcida: ruído passa-baixa que cresce e some, com palmas picadas por cima.
func _publico() -> PackedFloat32Array:
	var n := int(1.4 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	var palma := 0.0
	for i in n:
		var t := float(i) / TAXA
		var env := minf(t / 0.35, 1.0) * exp(-maxf(t - 0.35, 0.0) * 2.3)
		var r := _rng.randf_range(-1.0, 1.0)
		lp += (r - lp) * 0.22
		lp2 += (lp - lp2) * 0.4
		if _rng.randf() < 0.004:
			palma = 1.0
		palma *= 0.9
		s[i] = tanh((lp2 * 1.6 + r * palma * 0.25) * env * 1.5)
	return s


# Vitória: arpejo ascendente (dó, mi, sol, dó) com brilho no fim.
func _vitoria() -> PackedFloat32Array:
	var notas := [523.25, 659.25, 783.99, 1046.5]
	var n := int(1.0 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	for k in notas.size():
		var i0 := int(k * 0.11 * TAXA)
		var dur_decay := 5.0 if k < 3 else 2.8
		for i in range(i0, n):
			var t := float(i - i0) / TAXA
			var ph := fmod(t * notas[k], 1.0)
			var tri := 4.0 * absf(ph - 0.5) - 1.0
			s[i] += (tri * 0.5 + sin(TAU * notas[k] * 2.0 * t) * 0.15) * exp(-t * dur_decay) * 0.55
	for i in n:
		s[i] = tanh(s[i])
	return s


# Derrota: três notas descendo, "wah wah wah" mole.
func _derrota() -> PackedFloat32Array:
	var notas := [440.0, 349.23, 293.66]
	var n := int(1.1 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	for k in notas.size():
		var i0 := int(k * 0.26 * TAXA)
		for i in range(i0, n):
			var t := float(i - i0) / TAXA
			var f: float = notas[k] * (1.0 - 0.03 * minf(t * 4.0, 1.0))
			var ph := fmod(t * f, 1.0)
			var saw := 2.0 * ph - 1.0
			s[i] += (saw * 0.3 + sin(TAU * f * t) * 0.4) * exp(-t * (3.2 if k < 2 else 2.0)) * 0.55
	for i in n:
		s[i] = tanh(s[i])
	return s


# Moeda: dois "plim" agudos (mais brilhante que o `buy`).
func _moeda() -> PackedFloat32Array:
	var n := int(0.3 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var f := 987.77 if t < 0.07 else 1318.5
		var te := t if t < 0.07 else t - 0.07
		var v := sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.0 * t) * 0.2 + sin(TAU * f * 3.0 * t) * 0.07
		s[i] = v * exp(-te * 13.0) * 0.6
	return s


func _salvar(nome: String, amostras: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		bytes.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.data = bytes
	var erro := w.save_to_wav(PASTA + nome + ".wav")
	if erro != OK:
		push_error("make_sfx: falha ao gravar %s (%d)" % [nome, erro])


# --- Fase 6a: voz dos balões e sons do gesto (docs/cutscenes/balao-e-voz.md §6) ---

# Blip de voz de um timbre ("first", "coach" ou "disciple") na frequência f0. Sem tanh: a onda fica limpa.
func _voz(timbre: String, f0: float) -> PackedFloat32Array:
	var dur := 0.040
	var ataque := 0.003
	var queda := 38.0
	var soltura := 0.005
	var pico := 0.85
	if timbre == "coach":
		dur = 0.048
		ataque = 0.006
		queda = 26.0
		soltura = 0.006
		pico = 0.90
	elif timbre == "disciple":
		dur = 0.034
		ataque = 0.002
		queda = 45.0
		soltura = 0.004
		pico = 0.78
	var n := int(dur * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var fase := 0.0  # começa em 0 para não estalar
	var lp := 0.0
	var lp_ruido := 0.0
	for i in n:
		var t := float(i) / TAXA
		var f := f0
		if timbre == "first":
			f = f0 * (1.0 + 0.10 * exp(-t * 90.0))  # o "bup": começa 10% acima e cai
		elif timbre == "coach":
			f = f0 * (1.0 - 0.05 * t / dur)
		else:
			f = f0 * (1.0 + 0.04 * t / dur)
		fase += TAU * f / TAXA
		var seno := sin(fase)
		var v := 0.0
		if timbre == "first":
			lp += (signf(seno) - lp) * 0.30
			v = lp + 0.15 * seno
		elif timbre == "coach":
			lp += (signf(seno) - lp) * 0.18
			v = lp
			lp_ruido += (_rng.randf_range(-1.0, 1.0) - lp_ruido) * 0.5
			if seno > 0.0:
				v += lp_ruido * 0.30  # a rouquidão só na metade positiva da onda
		else:
			var ph := fmod(fase / TAU, 1.0)
			v = 4.0 * absf(ph - 0.5) - 1.0
		var env := minf(t / ataque, 1.0) * exp(-maxf(t - ataque, 0.0) * queda)
		if t > dur - soltura:
			env *= maxf((dur - t) / soltura, 0.0)
		s[i] = v * env
	return _normalizar(s, pico)


# Fecho da luva puxado com os dentes: ruído passa-alta que fica mais agudo, em grãos que aceleram (70 a 150 por s).
func _fecho_rasgando() -> PackedFloat32Array:
	var dur := 0.16
	var n := int(dur * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	var inicio_grao := 0.0
	var proximo_grao := 1.0 / 70.0
	for i in n:
		var t := float(i) / TAXA
		var x := t / dur
		var r := _rng.randf_range(-1.0, 1.0)
		lp += (r - lp) * 0.25
		var alta := r - lp
		lp2 += (alta - lp2) * (0.35 + 0.45 * x)
		if t >= proximo_grao:
			inicio_grao = t
			proximo_grao += 1.0 / (70.0 + 80.0 * x)
		var v := lp2 * exp(-(t - inicio_grao) * 400.0) * pow(x, 0.6)
		if t > dur - 0.008:
			v *= maxf((dur - t) / 0.008, 0.0)
		s[i] = v
	return _normalizar(s, 0.5)


# Toque de luva em luva: mais seco e curto que o soco, mais grave que o bloqueio.
func _toque_de_luva() -> PackedFloat32Array:
	var n := int(0.075 * TAXA)
	var s := PackedFloat32Array()
	s.resize(n)
	var fase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		fase += TAU * (150.0 + 90.0 * exp(-t * 60.0)) / TAXA
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.35
		var v := sin(fase) * 0.8 * exp(-t * 48.0) + lp * 0.6 * exp(-t * 170.0)
		s[i] = tanh(v * 1.2)
	return _normalizar(s, 0.6)


# Escala a onda para que o pico (valor absoluto) seja `alvo`.
func _normalizar(s: PackedFloat32Array, alvo: float) -> PackedFloat32Array:
	var maximo := 0.0
	for v in s:
		maximo = maxf(maximo, absf(v))
	if maximo > 0.0:
		for i in s.size():
			s[i] = s[i] / maximo * alvo
	return s
