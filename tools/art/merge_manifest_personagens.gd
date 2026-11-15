extends SceneTree
## Junta ao assets/sprites/manifest.json as entradas de um ou mais manifests de personagem do Artista
## (ex.: docs/arte/manifest-6b2-personagens.json). Mexe SÓ nas chaves que o arquivo traz: sprites.<id> (troca a
## entrada inteira) e by_data_id.<chave> (troca o bloco). Relê o manifest na hora de gravar; o resto fica como está.
## Rodar headless de uma pasta temporária com project.godot vazio:
##   godot --headless --path <tmp> --script E:/Fightclicker/tools/art/merge_manifest_personagens.gd -- <json> [<json>...] [--seco]
##   --seco = só conta o que mudaria, não grava.

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"

## Números inteiros voltam a ser inteiros (o JSON do Godot lê tudo como float); fps fica como veio.
func intify(v):
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = v[k] if str(k) == "fps" else intify(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(intify(x))
		return a
	if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 1e9:
		return int(v)
	return v

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seco := args.has("--seco")
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível; nada foi escrito")
		quit(1)
		return
	var doc: Dictionary = intify(j.data)
	var sp: Dictionary = doc.get("sprites", {})
	var bd: Dictionary = doc.get("by_data_id", {})
	var novos := 0
	var trocados := 0
	for a in args:
		if str(a).begins_with("--"):
			continue
		var path: String = a if (str(a).contains(":") or str(a).begins_with("/")) else ROOT + a
		var je := JSON.new()
		if je.parse(FileAccess.get_file_as_string(path)) != OK or not (je.data is Dictionary):
			push_error("ilegível: " + path)
			quit(1)
			return
		var src: Dictionary = je.data
		var sin: Dictionary = src.get("sprites", {})
		for id in sin:
			if str(id).begins_with("_"):
				continue
			if sp.has(id):
				trocados += 1
			else:
				novos += 1
			sp[id] = intify(sin[id])
		var bin: Dictionary = src.get("by_data_id", {})
		for k in bin:
			bd[k] = intify(bin[k])
		print("%s: %d sprites, by_data_id %s" % [path.get_file(), sin.size(), str(bin.keys())])
	doc["sprites"] = sp
	doc["by_data_id"] = bd
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 6b2 (Artista") < 0:
		doc["_sobre"] = sobre + " Fase 6b2 (Artista de Personagens): discípulo em camadas com cortes, regata/camiseta, faixa e meião (docs/arte/manifest-6b2-personagens.json)."
	print("sprites: %d novos, %d trocados" % [novos, trocados])
	if not seco:
		var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
		fa.store_string(JSON.stringify(doc, "\t", false))
		fa.close()
		print("manifest gravado")
	quit()
