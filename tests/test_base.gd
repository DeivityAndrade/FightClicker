extends SceneTree
## Base dos testes headless: conta PASS/FAIL, sai com código 1 se algo falhar
## e confere que o save REAL do dono não mudou durante o teste.
## Cada teste estende este arquivo e implementa rodar_testes().

const RAIZ_TESTES := "user://test/"

var _falhas := 0
var _total := 0


func _initialize() -> void:
	var antes := foto_save_real()
	print("== %s ==" % get_script().resource_path.get_file())
	# Espera um frame para a árvore estar pronta (nós adicionados rodam _ready).
	await process_frame
	await rodar_testes()
	checar(foto_save_real() == antes, "save real do dono não mudou durante este teste")
	print("%d/%d PASS" % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


## Implementado por cada arquivo de teste.
func rodar_testes() -> void:
	pass


func checar(condicao: bool, nome: String) -> void:
	_total += 1
	if condicao:
		print("PASS  " + nome)
	else:
		_falhas += 1
		print("FAIL  " + nome)


func checar_igual(obtido: Variant, esperado: Variant, nome: String) -> void:
	checar(obtido == esperado, "%s (obtido: %s, esperado: %s)" % [nome, str(obtido), str(esperado)])


## "Foto" dos arquivos na pasta do save real: nomes, tamanho, md5 e data de modificação.
static func foto_save_real() -> Dictionary:
	var foto := {}
	var pasta := SaveStore.PASTA_REAL
	for nome in DirAccess.get_files_at(pasta):
		var p := pasta.path_join(nome)
		foto[nome] = [FileAccess.get_md5(p), FileAccess.get_modified_time(p)]
	return foto


## Pasta de teste limpa (só aceita caminhos dentro de user://test/).
static func pasta_limpa(nome: String) -> String:
	var pasta := RAIZ_TESTES.path_join(nome) + "/"
	assert(pasta.begins_with(RAIZ_TESTES))
	_apagar_recursivo(pasta)
	DirAccess.make_dir_recursive_absolute(pasta)
	return pasta


static func _apagar_recursivo(pasta: String) -> void:
	if not pasta.begins_with(RAIZ_TESTES) or not DirAccess.dir_exists_absolute(pasta):
		return
	for sub in DirAccess.get_directories_at(pasta):
		_apagar_recursivo(pasta.path_join(sub))
	for arq in DirAccess.get_files_at(pasta):
		DirAccess.remove_absolute(pasta.path_join(arq))
	DirAccess.remove_absolute(pasta)


static func escrever(caminho: String, texto: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


static func ler(caminho: String) -> String:
	return FileAccess.get_file_as_string(caminho)
