extends SceneTree
## QA 6c2: o simbolo aparece em todas as folhas em camadas do discipulo (com e sem parte de cima).
var falhas := 0
var UT: GDScript
var DV: GDScript

func _init() -> void:
	_main.call_deferred()

func _diff(a: Texture2D, b: Texture2D) -> int:
	var ia := a.get_image()
	var ib := b.get_image()
	if ia.get_size() != ib.get_size():
		return -1
	var n := 0
	for y in ia.get_height():
		for x in ia.get_width():
			if ia.get_pixel(x, y) != ib.get_pixel(x, y):
				n += 1
	return n

func _main() -> void:
	UT = load("res://ui/ui_tema.gd")
	DV = load("res://ui/disc_visual.gd")
	var sprites: Dictionary = UT.manifest().get("sprites", {})
	var look_nu := {"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"}
	var look_top := look_nu.duplicate()
	look_top["top"] = "tank"
	look_top["top_color"] = "blue"
	var camadas := 0
	var sem_ordem := []
	var sem_ponto := []
	var sem_diff := []
	var john := []
	for nome in sprites:
		var s: Dictionary = sprites[nome]
		var cam = s.get("layers", {})
		if not (cam is Dictionary) or cam.is_empty():
			continue
		camadas += 1
		if not ("school_symbol" in cam.get("order", [])):
			sem_ordem.append(nome)
		var ss = cam.get("school_symbol", {})
		if not (ss is Dictionary) or not ss.has("chest") or not ss.has("leg"):
			sem_ponto.append(nome)
			continue
		if not str(nome).contains("disc"):
			john.append(nome)
		for lk in [["nu", look_nu], ["top", look_top]]:
			var a: Texture2D = DV.textura(nome, lk[1], false)
			var b: Texture2D = DV.textura(nome, lk[1], true)
			var d := _diff(a, b)
			if d <= 0:
				sem_diff.append("%s/%s=%d" % [nome, lk[0], d])
	print("folhas em camadas: ", camadas)
	print("sem school_symbol na ordem (", sem_ordem.size(), "): ", sem_ordem.slice(0, 15))
	print("sem pontos chest/leg (", sem_ponto.size(), "): ", sem_ponto.slice(0, 15))
	print("simbolo nao muda pixel (", sem_diff.size(), "): ", sem_diff.slice(0, 20))
	print("folhas em camadas sem 'disc' no nome: ", john.slice(0, 10))
	UT.liberar_cache()
	DV.limpar()
	quit(0)
