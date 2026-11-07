extends SceneTree
## QA Fase 2: mede sobreposicao entre numero critico (2x) e numeros normais em rajada de 10 cliques/s.
## Uso: godot --path . --script res://tests/qa_overlap.gd -- <cliques_por_s> <segundos>

const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/d03e7314839aa25e/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa2/"
var gs: Node
var sala


func clicar(pt: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = root.get_final_transform() * pt
	m.global_position = m.position
	Input.parse_input_event(m)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = m.position
	ev.global_position = ev.position
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate() as InputEventMouseButton
	ev2.pressed = false
	Input.parse_input_event(ev2)


func rect_de(n) -> Rect2:
	var larg: float = UiTema.largura(n._principal.text) * n._principal.scale.x
	var alt: float = 7.0 * n._principal.scale.x
	var c: Vector2 = n._raiz.position
	return Rect2(c.x - larg / 2.0, c.y - alt / 2.0, larg, alt)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cps := float(args[0]) if args.size() > 0 else 10.0
	var segs := float(args[1]) if args.size() > 1 else 60.0
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	var cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	await process_frame
	gs.apagar_save()
	sala = cena.get_node("Sala")
	var t0 := Time.get_ticks_msec()
	var prox := t0
	var frames_crit := 0
	var frames_crit_cobertos := 0
	var pior := 0.0
	var soma_cob := 0.0
	var crit_vs_crit := 0
	var crit_total := 0
	var vistos := {}
	var shots := 0
	while Time.get_ticks_msec() - t0 < segs * 1000.0:
		await process_frame
		var agora := Time.get_ticks_msec()
		if agora >= prox:
			prox += int(1000.0 / cps)
			clicar(Vector2(336, 222))
		var ativos: Array = []
		for i in sala._numeros.size():
			var n = sala._numeros[i]
			if n.ativo:
				ativos.append([i, n])
		for par in ativos:
			var n = par[1]
			if n._principal.scale.x < 2.0:
				continue
			frames_crit += 1
			if not vistos.has(n):
				vistos[n] = true
			var rc := rect_de(n)
			var cob_max := 0.0
			var outros_crit := false
			for q in ativos:
				var o = q[1]
				if o == n:
					continue
				var ro := rect_de(o)
				var inter := rc.intersection(ro)
				if inter.size.x > 0 and inter.size.y > 0:
					if o._principal.scale.x >= 2.0:
						outros_crit = true
					# fracao do texto do crit coberta por numero desenhado depois (mais alto indice = por cima)
					if q[0] > par[0]:
						cob_max = max(cob_max, inter.get_area() / rc.get_area())
			if outros_crit:
				crit_vs_crit += 1
			soma_cob += cob_max
			pior = max(pior, cob_max)
			if cob_max > 0.0:
				frames_crit_cobertos += 1
	print("QA| %.0f cliques/s por %.0fs: frames com crit visivel=%d, com crit parcialmente coberto por numero desenhado por cima=%d (%.0f%%), cobertura media=%.1f%%, pior=%.0f%%, frames com 2 crits sobrepostos=%d" % [cps, segs, frames_crit, frames_crit_cobertos, 100.0 * frames_crit_cobertos / max(1, frames_crit), 100.0 * soma_cob / max(1, frames_crit), 100.0 * pior, crit_vs_crit])
	quit(0)
