extends SceneTree
var UT: GDScript
var DV: GDScript
func _init() -> void:
	_main.call_deferred()
func _main() -> void:
	UT = load("res://ui/ui_tema.gd")
	DV = load("res://ui/disc_visual.gd")
	var out := OS.get_environment("QA_OUT")
	var look := {"skin": "skin_3", "hair_color": "brown", "hair_style": "bun", "shorts_color": "blue", "top": "tank", "top_color": "white", "headband": "band", "headband_color": "white", "socks": "on"}
	for nome in ["fight_player_idle_disc_layered", "fight_player_hit_disc_layered", "fight_player_guard_disc_layered", "fight_player_jab_disc_layered"]:
		if UT.sprite(nome).is_empty():
			print("sem ", nome); continue
		var a: Image = DV.textura(nome, look, true).get_image()
		var fw := int(UT.sprite(nome).get("frame", [112, 104])[0]) if UT.sprite(nome).has("frame") else 112
		print(nome, " ", a.get_size(), " frame ", UT.sprite(nome).keys())
		var q := a.get_region(Rect2i(0, 0, mini(a.get_width(), 336), a.get_height()))
		q.resize(q.get_width() * 3, q.get_height() * 3, Image.INTERPOLATE_NEAREST)
		q.save_png(out + nome + ".png")
	quit(0)
