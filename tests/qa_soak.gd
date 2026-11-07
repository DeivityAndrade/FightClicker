extends SceneTree
## QA Fase 2: sessao longa simulada (headless, --fixed-fps 60). 15 min = 54000 frames.
## Uso: godot --headless --fixed-fps 60 --path . --script res://tests/qa_soak.gd -- <cliques_por_s> <rodizio 0|1> <minutos>
## Joga pela UI (clique sintetico na sala) e compra "melhor" por heuristica simples.

var gs: Node
var cena: Control
var sala


func clicar(pt: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = root.get_final_transform() * pt
	ev.global_position = ev.position
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate() as InputEventMouseButton
	ev2.pressed = false
	Input.parse_input_event(ev2)


func fmt(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cps := float(args[0]) if args.size() > 0 else 5.0
	var rodizio := (args[1] == "1") if args.size() > 1 else false
	var minutos := float(args[2]) if args.size() > 2 else 15.0
	gs = root.get_node("GameState")
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	await process_frame
	gs.apagar_save()
	sala = cena.get_node("Sala")
	var cont := {"n": 0, "c": 0}
	
	var soma_clique := 0.0
	gs.clicou.connect(func(g: float, c: bool, _a: String, _b: String, _t: String) -> void:
		cont.n += 1
		soma_clique += g
		if c:
			cont.c += 1)
	var marcos := {}
	var total_frames := int(minutos * 60.0 * 60.0)
	var acum := 0.0
	var passo_clique := 60.0 / cps
	var ger_clique_acum := 0.0
	var soma_passivo := 0.0
	var ultimo_min := 0
	var focos := ["punching_bag", "jump_rope", "treadmill"]
	for f in total_frames:
		await process_frame
		var t := float(f) / 60.0
		acum += 1.0
		if acum >= passo_clique:
			acum -= passo_clique
			clicar(Vector2(336, 222))
		# compras a cada 0,5 s
		if f % 30 == 0:
			# melhoria do foco, depois tio, depois vizinho: o mais "barato por ganho" simples
			var foco: String = gs.foco
			var comprou := true
			while comprou:
				comprou = false
				var m: Dictionary = gs.proxima_melhoria(foco)
				var custo_m: float = m.cost if not m.is_empty() else INF
				var custo_t: float = gs.custo_gerador("retired_uncle")
				var custo_v: float = gs.custo_gerador("neighbor_kid")
				# escolhe o de melhor razao ganho/custo (aprox): melhoria vale (mult-1)*por_clique*cps*1.2
				var ganho_m := 0.0
				if not m.is_empty():
					ganho_m = (float(m.multiplier) - 1.0) * gs.por_clique() * cps * 1.2
				var r_m := ganho_m / custo_m if not m.is_empty() else 0.0
				var r_t := 8.0 / custo_t
				var r_v := 1.0 / custo_v
				var melhor := "m" if (r_m >= r_t and r_m >= r_v) else ("t" if r_t >= r_v else "v")
				if melhor == "m" and gs.comprar_melhoria(foco):
					comprou = true
					if not marcos.has("melhoria1") :
						marcos["melhoria1"] = t
				elif melhor == "t" and gs.comprar_gerador("retired_uncle"):
					comprou = true
					if not marcos.has("tio"):
						marcos["tio"] = t
				elif melhor == "v" and gs.comprar_gerador("neighbor_kid"):
					comprou = true
					if not marcos.has("vizinho"):
						marcos["vizinho"] = t
		if rodizio and f % 3600 == 3599:
			gs.definir_foco(focos[(int(f / 3600) + 1) % 3])
		if f % 3600 == 3599:
			var minuto := int(f / 3600) + 1
			var clique_s := 0.0
			clique_s = gs.por_clique() * 1.2 * cps
			print("QA| min %2d: clique/s~%.0f passivo/s=%.0f (%.0f%% do clique) saldo=%s atr=%s viz=%d tio=%d niv=%s cliques=%d crit=%d" % [minuto, clique_s, gs.producao_total(), 100.0 * gs.producao_total() / maxf(clique_s, 0.0001), NumberFormat.fmt(gs.treino, NumberFormat.TRUNCAR), gs.atributos.values().map(func(x): return NumberFormat.fmt(x, NumberFormat.TRUNCAR)), gs.quantidade_gerador("neighbor_kid"), gs.quantidade_gerador("retired_uncle"), gs.niveis_melhoria.values(), cont.n, cont.c])
	var ms := ""
	for k in marcos:
		ms += "%s=%s " % [k, fmt(marcos[k])]
	print("QA| marcos: ", ms)
	print("QA| FIM: avisos=", gs.avisos, " total clicks=", cont.n)
	quit(0)
