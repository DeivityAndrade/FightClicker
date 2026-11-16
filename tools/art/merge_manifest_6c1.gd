extends SceneTree
## Fase 6c1: junta ao assets/sprites/manifest.json as entradas do Artista de Personagens
## (docs/arte/manifest-6c1-personagens.json, gerado por make_sprites_fase6c1.gd).
##   sprites.<id>                 troca a entrada inteira (ids novos ou já existentes)
##   by_data_id.<chave>           troca o bloco, se o arquivo trouxer
##   palette_variants, props_in_sheets, scene_anims_sugestao
##                                vão juntos para by_data_id.personagens_6c1 (o Programador liga os nomes em scene_anims)
## Relê o manifest na hora de gravar; o resto fica como está. Pode rodar quantas vezes quiser (idempotente).
## Rodar headless de uma pasta temporária com project.godot vazio:
##   godot --headless --path <tmp> --script <repo>/tools/art/merge_manifest_6c1.gd -- [<json>] [--seco]
## Sem <json> usa docs/arte/manifest-6c1-personagens.json. --seco = só conta, não grava.
## A raiz do projeto é a pasta acima de tools/art (ou FIGHTCLICKER_ROOT, se definida).

var ROOT := ""

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
	ROOT = OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else (get_script().resource_path.get_base_dir().get_base_dir().get_base_dir() + "/")
	var args := OS.get_cmdline_user_args()
	var seco := args.has("--seco")
	var src_path := ROOT + "docs/arte/manifest-6c1-personagens.json"
	for a in args:
		if not str(a).begins_with("--"):
			src_path = a if (str(a).contains(":") or str(a).begins_with("/")) else ROOT + a
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível; nada foi escrito")
		quit(1)
		return
	var je := JSON.new()
	if not FileAccess.file_exists(src_path) or je.parse(FileAccess.get_file_as_string(src_path)) != OK or not (je.data is Dictionary):
		push_error("ilegível ou ausente: " + src_path)
		quit(1)
		return
	var doc: Dictionary = intify(j.data)
	var src: Dictionary = je.data
	var sp: Dictionary = doc.get("sprites", {})
	var bd: Dictionary = doc.get("by_data_id", {})
	var novos := 0
	var trocados := 0
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
	var extra := {"_nota": "Fase 6c1 (Artista de Personagens), juntado por tools/art/merge_manifest_6c1.gd. Fonte: docs/arte/manifest-6c1-personagens.json."}
	for k in ["palette_variants", "props_in_sheets", "scene_anims_sugestao"]:
		if src.has(k):
			extra[k] = intify(src[k])
	bd["personagens_6c1"] = extra
	doc["sprites"] = sp
	doc["by_data_id"] = bd
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 6c1 (Artista") < 0:
		doc["_sobre"] = sobre + " Fase 6c1 (Artista de Personagens): folhas da chegada à academia e da saída do John (docs/arte/manifest-6c1-personagens.json; variantes de paleta e sugestão de scene_anims em by_data_id.personagens_6c1)."
	print("%s: %d sprites (%d novos, %d trocados), by_data_id %s + personagens_6c1" % [src_path.get_file(), sin.size(), novos, trocados, str(bin.keys())])
	if not seco:
		var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
		fa.store_string(JSON.stringify(doc, "\t", false))
		fa.close()
		print("manifest gravado")
	quit()
