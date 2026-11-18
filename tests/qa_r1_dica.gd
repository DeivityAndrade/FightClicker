extends SceneTree
func _initialize() -> void:
	await process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var fora := 0; var cobre := 0; var longe := 0; var n := 0
	var ex_cobre := []
	for i in 20000:
		var tam := Vector2(rng.randi_range(40, 160), rng.randi_range(16, 90))
		var alvo := Rect2(rng.randf_range(0, 600), rng.randf_range(0, 340), rng.randi_range(8, 140), rng.randi_range(8, 40))
		var m := alvo.position + Vector2(rng.randf() * alvo.size.x, rng.randf() * alvo.size.y)
		var p: Vector2 = Dica.posicionar(tam, m, alvo)
		var r := Rect2(p, tam)
		n += 1
		if r.position.x < 2 or r.position.y < 2 or r.end.x > 638 or r.end.y > 358: fora += 1
		if r.intersects(alvo):
			cobre += 1
			if ex_cobre.size() < 3: ex_cobre.append([tam, alvo, m, p])
		var dx := maxf(maxf(r.position.x - m.x, m.x - r.end.x), 0.0); var dy := maxf(maxf(r.position.y - m.y, m.y - r.end.y), 0.0)
		if Vector2(dx, dy).length() > 60: longe += 1
	print("casos ", n, " fora_da_tela ", fora, " cobre_alvo ", cobre, " longe_do_cursor(>60px) ", longe)
	print(ex_cobre)
	quit()
