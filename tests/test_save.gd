extends "res://tests/test_base.gd"
## Testa o SaveStore: ida e volta, migração, backup, corrupção e save do futuro.
## Tudo em user://test/save/, nunca no save real.

var pasta := ""


func rodar_testes() -> void:
	_teste_ida_e_volta()
	_teste_backup_criado()
	_teste_migracao_v0()
	_teste_campos_faltando_e_desconhecidos()
	_teste_corrompido_usa_backup()
	_teste_vazio_usa_backup()
	_teste_tudo_corrompido()
	_teste_principal_ausente_usa_backup()
	_teste_futuro_nao_sobrescreve()
	_teste_versao_gigante()
	_teste_versao_invalida()
	_teste_apagar()


func _novo_store() -> SaveStore:
	pasta = pasta_limpa("save")
	return SaveStore.new(pasta)


func _teste_ida_e_volta() -> void:
	var s := _novo_store()
	checar(s.caminho().begins_with("user://test/"), "store de teste usa user://test/")
	checar_igual(s.carregar().status, SaveStore.Status.NOVO, "sem arquivo: jogo novo")
	for valor in [0.0, 1.5, 123456.789, 1.0e300, 1.7976931348623157e308]:
		checar(s.salvar({"treino": valor}) > 0, "salvar %s" % str(valor))
		var r := s.carregar()
		checar_igual(r.status, SaveStore.Status.OK, "carregar após salvar")
		checar_igual(float(r.estado.treino), valor, "valor mantido na ida e volta")
	var r2 := s.carregar()
	checar(r2.saved_at_unix > 0, "save guarda data/hora do último save")
	var doc = JSON.parse_string(ler(s.caminho()))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "campo version no arquivo")
	checar(not FileAccess.file_exists(s.caminho_temporario()), "temporário não fica para trás")


func _teste_backup_criado() -> void:
	var s := _novo_store()
	s.salvar({"treino": 1.0})
	checar(not FileAccess.file_exists(s.caminho_backup()), "primeiro save não tem backup")
	s.salvar({"treino": 2.0})
	var bak = JSON.parse_string(ler(s.caminho_backup()))
	checar_igual(float(bak.state.treino), 1.0, "save anterior virou .bak")
	s.salvar({"treino": 3.0})
	bak = JSON.parse_string(ler(s.caminho_backup()))
	checar_igual(float(bak.state.treino), 2.0, ".bak acompanha o save anterior")


func _teste_migracao_v0() -> void:
	var s := _novo_store()
	escrever(s.caminho(), '{"treino": 42}')
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.OK, "save v0 (sem version) abre")
	checar_igual(float(r.estado.career.training), 42.0, "save v0 migrado mantém o treino")
	s.salvar(r.estado)
	var doc = JSON.parse_string(ler(s.caminho()))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "save v0 regravado na versão atual")

	escrever(s.caminho(), '{"version": 0, "treino": 7}')
	checar_igual(float(s.carregar().estado.career.training), 7.0, "save com version 0 explícito migra")


func _teste_campos_faltando_e_desconhecidos() -> void:
	var s := _novo_store()
	escrever(s.caminho(), '{"version": 1, "state": {"campo_futuro": 5}, "outra_coisa": [1,2]}')
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.OK, "campos desconhecidos não dão erro")
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.inicializar(pasta_limpa("save_campos"), "res://data/config.json")
	gs.aplicar_save(r.estado)
	checar_igual(gs.treino, 0.0, "campo faltando recebe padrão")
	gs.aplicar_save({"career": {"training": "lixo"}})
	checar_igual(gs.treino, 0.0, "campo com tipo errado recebe padrão")
	gs.free()


func _teste_corrompido_usa_backup() -> void:
	var s := _novo_store()
	s.salvar({"treino": 10.0})
	s.salvar({"treino": 20.0})
	escrever(s.caminho(), "{isso não é json")
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.BACKUP, "JSON inválido carrega o backup")
	checar_igual(float(r.estado.treino), 10.0, "valor do backup")
	checar(r.mensagem != "", "aviso para a tela")
	var corrompidos := _arquivos_corrompidos()
	checar_igual(corrompidos.size(), 1, "arquivo corrompido guardado, não apagado")
	if corrompidos.size() == 1:
		checar_igual(ler(pasta.path_join(corrompidos[0])), "{isso não é json", "conteúdo corrompido intacto")
	# Próximo save não pode destruir o backup bom.
	s.salvar({"treino": 11.0})
	var bak = JSON.parse_string(ler(s.caminho_backup()))
	checar_igual(float(bak.state.treino), 10.0, "backup bom preservado após novo save")


func _teste_vazio_usa_backup() -> void:
	var s := _novo_store()
	s.salvar({"treino": 5.0})
	s.salvar({"treino": 6.0})
	escrever(s.caminho(), "")
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.BACKUP, "save vazio carrega o backup")
	checar_igual(float(r.estado.treino), 5.0, "valor do backup (vazio)")
	escrever(s.caminho(), "[1, 2, 3]")
	checar_igual(s.carregar().status, SaveStore.Status.BACKUP, "JSON que não é objeto carrega o backup")


func _teste_tudo_corrompido() -> void:
	var s := _novo_store()
	escrever(s.caminho(), "lixo")
	escrever(s.caminho_backup(), "mais lixo")
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.CORROMPIDO_NOVO, "save e backup ruins: jogo novo")
	checar(r.estado.is_empty(), "estado vazio no jogo novo")
	checar(r.mensagem != "", "aviso de corrupção")
	checar_igual(_arquivos_corrompidos().size(), 2, "os dois arquivos ruins guardados para análise")
	checar(s.salvar({"treino": 1.0}) > 0, "consegue salvar depois")


func _teste_principal_ausente_usa_backup() -> void:
	var s := _novo_store()
	s.salvar({"treino": 3.0})
	s.salvar({"treino": 4.0})
	DirAccess.remove_absolute(s.caminho())
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.BACKUP, "principal sumido carrega o backup")
	checar_igual(float(r.estado.treino), 3.0, "valor do backup (ausente)")


func _teste_futuro_nao_sobrescreve() -> void:
	var s := _novo_store()
	var futuro := '{"version": %d, "state": {"treino": 999}}' % (SaveStore.VERSAO_ATUAL + 1)
	escrever(s.caminho(), futuro)
	var r := s.carregar()
	checar_igual(r.status, SaveStore.Status.FUTURO, "save do futuro detectado")
	checar(r.mensagem != "", "aviso de save do futuro")
	checar(s.bloqueado, "store bloqueado para gravar")
	checar_igual(s.salvar({"treino": 1.0}), -1, "salvar recusado")
	checar_igual(ler(s.caminho()), futuro, "save do futuro intacto")
	checar(not FileAccess.file_exists(s.caminho_backup()), "nenhum backup criado por cima")

	# Pelo GameState: autosave e salvar() também não gravam.
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.inicializar(pasta, "res://data/config.json")
	checar(not gs.salvar(), "GameState.salvar() recusa save do futuro")
	gs.tick(gs.config.autosave_intervalo_segundos + 1.0)
	checar_igual(ler(s.caminho()), futuro, "autosave não sobrescreve save do futuro")
	checar(not gs.avisos.is_empty(), "GameState mostra aviso")
	gs.free()


# B1: version gigante é versão futura (não corrompida): não abre, não sobrescreve.
func _teste_versao_gigante() -> void:
	for v in ["1e30", "9223372036854775807", "1e308", str(SaveStore.VERSAO_ATUAL + 1)]:
		var s := _novo_store()
		var txt := '{"version": %s, "state": {"treino": 5}}' % v
		escrever(s.caminho(), txt)
		var r := s.carregar()
		checar_igual(r.status, SaveStore.Status.FUTURO, "version %s = futuro" % v)
		checar(s.bloqueado, "version %s bloqueia" % v)
		checar_igual(s.salvar({"treino": 1.0}), -1, "version %s: salvar recusado" % v)
		checar_igual(ler(s.caminho()), txt, "version %s: arquivo intacto" % v)


func _teste_versao_invalida() -> void:
	var s := _novo_store()
	escrever(s.caminho(), '{"version": "abc", "state": {}}')
	checar_igual(s.carregar().status, SaveStore.Status.CORROMPIDO_NOVO, "version inválida = corrompido")
	escrever(s.caminho(), '{"version": 1.5, "state": {}}')
	checar_igual(s.carregar().status, SaveStore.Status.CORROMPIDO_NOVO, "version não inteira = corrompido")


func _teste_apagar() -> void:
	var s := _novo_store()
	s.salvar({"treino": 1.0})
	s.salvar({"treino": 2.0})
	s.apagar()
	checar(not FileAccess.file_exists(s.caminho()) and not FileAccess.file_exists(s.caminho_backup()),
		"apagar remove save e backup")
	checar_igual(s.carregar().status, SaveStore.Status.NOVO, "depois de apagar: jogo novo")


func _arquivos_corrompidos() -> Array:
	var lista := []
	for nome in DirAccess.get_files_at(pasta):
		if ".corrompido-" in nome:
			lista.append(nome)
	return lista
