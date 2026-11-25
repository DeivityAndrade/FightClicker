extends "res://tests/test_base.gd"
## Texto desenhado por código tem ponto único: draw_string/draw_char/draw_multiline_string só em ui/ui_tema.gd.

const PASTAS := ["res://ui", "res://scripts", "res://scenes"]
const PERMITIDO := "res://ui/ui_tema.gd"
const PADROES := ["draw_string", "draw_char", "draw_multiline_string"]


func rodar_testes() -> void:
	var fora: Array[String] = []
	for pasta in PASTAS:
		_varrer(pasta, fora)
	checar(fora.is_empty(), "nenhum draw_string fora de UiTema (%s)" % ", ".join(fora))


func _varrer(pasta: String, fora: Array[String]) -> void:
	for f in DirAccess.get_files_at(pasta):
		if not f.ends_with(".gd"):
			continue
		var caminho := pasta.path_join(f)
		if caminho == PERMITIDO:
			continue
		var texto := FileAccess.get_file_as_string(caminho)
		for p in PADROES:
			if texto.contains(p + "("):
				fora.append(caminho)
				break
	for d in DirAccess.get_directories_at(pasta):
		_varrer(pasta.path_join(d), fora)
