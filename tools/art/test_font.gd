extends SceneTree
## Confere se a fonte bitmap da Fase 2 carrega no Godot.
## Uso 1 (sem importar): godot --headless --path <tmp> --script E:/Fightclicker/tools/art/test_font.gd
## Uso 2 (importada): copiar assets/sprites/font/ para <tmp>/font/, rodar --import e depois este script;
## ele também tenta load("res://font/*.fnt").

const DIR := "E:/Fightclicker/assets/sprites/font/"
const AMOSTRA := "FORÇA AGILIDADE RESISTÊNCIA Treino ação ÇÃÁÂÉÊÍÓÔÕÚ áàâãéêíóôõúç +12 ×3 100%"

func _init() -> void:
	var ok := true
	for nm in ["fightclicker_5x7", "fightclicker_5x7_contorno"]:
		var ff: FontFile = FontFile.new()
		var err := ff.load_bitmap_font(DIR + nm + ".fnt")
		var sz := ff.fixed_size
		var missing := []
		for i in AMOSTRA.length():
			var c: int = AMOSTRA.unicode_at(i)
			if c != 32 and not ff.has_char(c):
				missing.append(AMOSTRA[i])
		print("[direto] %s err=%d fixed_size=%d altura=%d ascent=%d largura(\"FORÇA\")=%s faltando=%s" % [
			nm, err, sz, ff.get_height(sz), ff.get_ascent(sz), ff.get_string_size("FORÇA", HORIZONTAL_ALIGNMENT_LEFT, -1, sz), missing])
		ok = ok and err == OK and missing.is_empty()
		var res_path: String = "res://font/" + nm + ".fnt"
		if ResourceLoader.exists(res_path):
			var r = load(res_path)
			print("[importada] %s -> %s" % [res_path, r])
			ok = ok and r is FontFile
	print("FONTE_OK" if ok else "FONTE_FALHOU")
	quit()
