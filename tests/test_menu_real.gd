extends "res://tests/test_base.gd"
## ID4: integração com o MENU REAL (ui/menu_principal.gd) pelo Fluxo.mostrar_menu(): CONTINUAR, NOVO JOGO (com save: confirmação dupla,
## cópia, abertura de novo; sem save: direto) e SAIR. Save de teste em user://test/, nunca o save real (o test_base confere no fim).

var _gs: Node
var _fluxo  # sem tipo: o autoload GameState não existe na hora de compilar o teste
var _escolhas: Array = []
var _saiu := 0


func rodar_testes() -> void:
	_gs = root.get_node("GameState")
	_gs.inicializar(pasta_limpa("menu_real"), "res://data/config.json")
	_gs.autosave_ativo = false
	var cena: Control = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	for i in 5:
		await process_frame
	_fluxo = cena.get_node("Fluxo")
	_fluxo.acao_sair = func() -> void: _saiu += 1
	_fluxo.menu_escolheu.connect(func(a: String) -> void: _escolhas.append(a))

	await _sem_save()
	await _continuar()
	await _novo_jogo_com_save()
	await _sair()

	for p in cena.find_children("*", "AudioStreamPlayer", true, false):
		(p as AudioStreamPlayer).stop()
	root.remove_child(cena)
	cena.free()
	await create_timer(0.6).timeout  # o mixer de áudio solta os sons que ainda tocavam


func _abrir() -> void:
	checar(_fluxo.mostrar_menu() and _fluxo.menu != null, "mostrar_menu() abre o menu real")
	await process_frame
	_fluxo.menu.pular_intro()


func _botao(acao: String) -> int:
	return _fluxo.menu._ids.find(acao)


func _copias() -> Array:
	return Array(DirAccess.get_files_at(_gs.store.pasta)).filter(func(n: String) -> bool: return n.begins_with("save_copia_"))


func _sem_save() -> void:
	_gs.apagar_save()  # os 5 quadros de arranque já deixaram a abertura gravar um save: volta a "sem save"
	await _abrir()
	checar(_fluxo.menu.get_script().resource_path == "res://ui/menu_principal.gd", "o menu aberto é o MenuPrincipal de verdade")
	checar(_botao("continuar") == -1, "sem save: o botão CONTINUAR não existe")
	checar(_botao("novo_jogo") >= 0 and _botao("opcoes") >= 0 and _botao("sair") >= 0, "sem save: NOVO JOGO, OPÇÕES e SAIR existem")
	checar(_gs.menu_aberto and _fluxo.ocupado(), "menu aberto: jogo parado")
	checar(not _gs.salvar() and not _gs.tem_save(), "menu aberto sem save: nada é gravado")
	_fluxo.menu._ativar(_botao("novo_jogo"))
	await process_frame
	checar(_fluxo.menu == null and not _gs.menu_aberto, "sem save: NOVO JOGO vai direto (sem confirmação) e fecha o menu")
	checar(_escolhas.back() == "novo_jogo" and _copias().is_empty(), "sem save: nenhuma cópia")


func _continuar() -> void:
	_gs.pular_abertura()
	_gs.treino = 555.0
	_gs.salvar()
	await _abrir()
	checar(_botao("continuar") == 0, "com save: CONTINUAR é o primeiro botão")
	_fluxo.menu._ativar(0)
	await process_frame
	checar(_fluxo.menu == null and not _gs.menu_aberto and not _fluxo.ocupado(), "CONTINUAR: menu fecha e o jogo anda")
	checar(_escolhas.back() == "continuar" and _gs.treino == 555.0 and _gs.tem_save(), "CONTINUAR: o save segue intacto")


func _novo_jogo_com_save() -> void:
	await _abrir()
	var m = _fluxo.menu
	m._ativar(_botao("novo_jogo"))
	checar(m._jan_tipo == "confirma1" and _fluxo.menu != null, "com save: NOVO JOGO abre a 1ª confirmação")
	m._jan_ativar(0)  # VOLTAR
	checar(m._jan_tipo == "" and _gs.tem_save() and _copias().is_empty(), "VOLTAR na 1ª: nada acontece")
	m._ativar(_botao("novo_jogo"))
	m._jan_ativar(1)  # SIM, NOVO JOGO
	checar(m._jan_tipo == "confirma2" and _gs.tem_save() and _copias().is_empty(), "a 2ª confirmação aparece e ainda não apagou nada")
	m._jan_ativar(0)  # VOLTAR na 2ª
	checar(m._jan_tipo == "" and _gs.tem_save(), "VOLTAR na 2ª: nada acontece")
	m._ativar(_botao("novo_jogo"))
	m._jan_ativar(1)
	var antes := FileAccess.get_file_as_string(_gs.store.pasta.path_join("save.json"))
	m._jan_ativar(1)  # COPIAR E COMEÇAR (o Fluxo age na hora, antes de qualquer quadro)
	checar(_fluxo.menu == null and not _gs.menu_aberto, "depois da 2ª confirmação o menu fecha")
	checar(_escolhas.back() == "novo_jogo", "sinal menu_escolheu(novo_jogo)")
	var copias := _copias()
	checar_igual(copias.size(), 1, "uma cópia de segurança criada")
	if copias.size() == 1:
		checar_igual(FileAccess.get_file_as_string(_gs.store.pasta.path_join(copias[0])), antes, "a cópia é igual ao save que foi apagado")
	checar(not _gs.tem_save() and _gs.treino == 0.0, "save apagado e estado zerado")
	checar_igual(_gs.abertura_estado(), "pending", "a abertura está de volta (pendente)")
	for i in 90:
		await process_frame
	checar(_gs.abertura_estado() in ["pending", "playing"], "a abertura segue o fluxo normal (pendente ou tocando)")
	print("  (treinador na sala: %s, abertura: %s)" % [_gs.coach_presente(), _gs.abertura_estado()])
	if _gs.coach_presente():
		checar_igual(_gs.abertura_estado(), "playing", "o treinador está na sala: a abertura toca")


func _sair() -> void:
	_gs.pular_abertura()
	_gs.salvar()
	var md5 := FileAccess.get_md5(_gs.store.pasta.path_join("save.json"))
	await _abrir()
	_fluxo.menu._ativar(_botao("sair"))
	await process_frame
	checar_igual(_saiu, 1, "SAIR pede para fechar o jogo")
	checar(_escolhas.back() == "sair", "sinal menu_escolheu(sair)")
	checar_igual(FileAccess.get_md5(_gs.store.pasta.path_join("save.json")), md5, "SAIR não mexe no save")
	_fluxo._fechar_menu()
