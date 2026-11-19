extends SceneTree
## QA 6d2: balao de descricao ao vivo (hover real) na loja e na equipe, painel solto e fixado, garagem e academia.
const PASTA := "user://test/qa6d2dica/"
var gs: Node
var cena: Node
var falhas := 0
var out := ""
var n_teste := 0
var DicaS: GDScript
func ok(c: bool, n: String) -> void:
	if not c: falhas += 1
	print("PASS  " if c else "FAIL  ", n)
func esperar(s: float) -> void:
	await create_timer(s).timeout
func mover(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p * 2.0
	e.global_position = p * 2.0
	Input.parse_input_event(e)
	await process_frame
func varrer(dir: Node, rotulo: String) -> void:
	var botoes: Array = []
	for b in dir.find_children("*", "Button", true, false):
		var bb := b as Button
		if bb.is_visible_in_tree() and bb.mouse_filter == Control.MOUSE_FILTER_STOP and bb.get_global_rect().size.x > 20 and bb.get_global_rect().position.x > 400.0:
			botoes.append(bb)
	var testados := 0
	var com_dica := 0
	var cobre := 0
	var fora := 0
	var lentos := 0
	var maxdist := 0.0
	for b in botoes:
		var r: Rect2 = (b as Button).get_global_rect()
		# so botoes dentro da janela de rolagem (visiveis na tela)
		if r.position.y < 20 or r.end.y > 330 or r.end.x > 640 or r.position.x < 400:
			continue
		testados += 1
		await mover(Vector2(2, 2))
		await process_frame
		var c := r.get_center()
		DicaS.instancia.ancora_fixa = c
		await mover(c)
		var d = DicaS.instancia
		var quadros := 1
		while (d == null or not d.visible) and quadros < 12:
			await process_frame
			quadros += 1
		if quadros > 9: print("  LENTO: ", quadros, " quadros")
		await process_frame
		if d != null and d.visible:
			com_dica += 1
			var rd: Rect2 = d.retangulo()
			if rd.intersects(r.grow(-1.0)): cobre += 1; print("  cobre: ", b.get_path(), " dica ", rd, " item ", r)
			if rd.position.x < 0 or rd.position.y < 0 or rd.end.x > 640 or rd.end.y > 360: fora += 1; print("  fora: ", rd)
			var dist := 0.0
			var q := Vector2(clampf(c.x, rd.position.x, rd.end.x), clampf(c.y, rd.position.y, rd.end.y))
			dist = q.distance_to(c)
			maxdist = maxf(maxdist, dist)
			print("  mouse ", cena.get_local_mouse_position(), (b as Button).text, " item ", r, " dica ", rd, " dist ", snappedf(dist, 0.1), " txt=", d.texto_atual().replace("
", " | "))
		await mover(Vector2(100, 150))
		DicaS.instancia.ancora_fixa = Vector2(-1, -1)
		ok_oculta()
	print("[%s] botoes testados %d com dica %d cobre %d fora %d dist max %.0f" % [rotulo, testados, com_dica, cobre, fora, maxdist])
	ok(cobre == 0 and fora == 0, "%s: balao nunca cobre o item nem sai da tela" % rotulo)
func ok_oculta() -> void:
	if DicaS.instancia != null and DicaS.instancia.visible:
		print("  AVISO: dica continua visivel com o mouse fora")
		falhas += 1
func _initialize() -> void:
	gs = root.get_node("GameState")
	DicaS = load("res://ui/dica.gd")
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.treino = 3000.0
	gs.dinheiro = 5000.0
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(1.0)
	var dir: Node = cena.get_node("PainelLoja")
	dir.definir_estado(true)
	await esperar(0.4)
	dir._trocar_aba("treino")
	await esperar(0.3)
	await varrer(dir, "equipe (fixado)")
	dir._trocar_aba("loja")
	await esperar(0.3)
	await varrer(dir, "loja (fixado)")
	dir.definir_estado(true)
	await esperar(0.4)
	await varrer(dir, "loja (solto)")
	dir._trocar_aba("treino")
	await esperar(0.3)
	await varrer(dir, "equipe (solto)")
	gs.dinheiro = 1.0
	gs.treino = 1.0
	dir._trocar_aba("loja")
	await esperar(0.5)
	await varrer(dir, "loja (sem dinheiro)")
	dir._trocar_aba("treino")
	await esperar(0.5)
	await varrer(dir, "equipe (sem treino)")
	# aparelho trancado na faixa
	var barra: Node = cena.get_node("BarraBaixo")
	var n := 0
	for b in barra.find_children("*", "Button", true, false):
		var bb := b as Button
		if not bb.is_visible_in_tree(): continue
		var r := bb.get_global_rect()
		await mover(Vector2(2, 2)); 
		DicaS.instancia.ancora_fixa = r.get_center()
		await mover(r.get_center())
		await process_frame
		var d = DicaS.instancia
		var texto: String = d.texto_atual() if d != null else ""
		n += 1
		print("barra botao ", bb.get_path().get_name(bb.get_path().get_name_count() - 1), " ", r, " dica='", texto.replace("\n", " | "), "' retangulo=", d.retangulo() if d != null and d.visible else Rect2())
		if d != null and d.visible and d.retangulo().intersects(r.grow(-1.0)):
			falhas += 1
			print("  FAIL dica cobre o botao da barra")
		await mover(Vector2(100, 150))
	print("FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)
