extends "res://tests/test_base.gd"
## ID4 (menu principal), lado da lógica: tem_save, NOVO JOGO com cópia de segurança, opções fora do save, parede de cartazes
## e o gancho do Fluxo (com um menu falso). Tudo em user://test/, nunca o save real (o test_base confere no fim).

const GameStateScript := preload("res://scripts/game_state.gd")
const MENU_FALSO := "res://tests/data/menu_falso.gd"


func rodar_testes() -> void:
	_teste_tem_save()
	_teste_novo_jogo()
	_teste_opcoes()
	_teste_parede()
	_teste_menu_aberto()
	await _teste_fluxo()


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.baloes_escondidos = true
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _arquivos(pasta: String) -> Array:
	var a: Array = Array(DirAccess.get_files_at(pasta))
	a.sort()
	return a


func _copias(pasta: String) -> Array:
	return _arquivos(pasta).filter(func(n: String) -> bool: return n.begins_with("save_copia_"))


func _teste_tem_save() -> void:
	var gs := _novo("menu_tem_save")
	checar(not gs.tem_save(), "sem save: tem_save() é falso (CONTINUAR não existe)")
	gs.salvar()
	checar(gs.tem_save(), "depois de salvar: tem_save() é verdadeiro")
	# Só o backup também conta (o carregar abre o backup).
	var pasta: String = gs.store.pasta
	DirAccess.rename_absolute(pasta.path_join("save.json"), pasta.path_join("save.json.bak"))
	checar(gs.tem_save(), "só com o backup: tem_save() é verdadeiro")
	_liberar(gs)


func _teste_novo_jogo() -> void:
	var gs := _novo("menu_novo_jogo")
	checar_igual(gs.novo_jogo_com_copia(), "", "sem save: novo_jogo_com_copia() devolve vazio")
	checar(_copias(gs.store.pasta).is_empty(), "sem save: nenhuma cópia criada")
	gs.treino = 1234.0
	gs.pular_abertura()  # grava o marco e salva
	gs.salvar()
	var pasta: String = gs.store.pasta
	var antes := FileAccess.get_file_as_string(pasta.path_join("save.json"))
	checar(antes.find("1234") >= 0, "o save de partida tem o progresso")
	var copia: String = gs.novo_jogo_com_copia()
	checar(copia != "" and copia.begins_with(pasta) and FileAccess.file_exists(copia), "cópia de segurança criada na pasta do save")
	checar_igual(FileAccess.get_file_as_string(copia), antes, "a cópia é idêntica ao save apagado")
	checar(copia.get_file().begins_with("save_copia_") and copia.get_file().ends_with(".json"), "nome com data: save_copia_AAAAMMDD_HHMMSS.json")
	checar(not FileAccess.file_exists(pasta.path_join("save.json")), "save.json foi apagado")
	checar(not gs.tem_save(), "depois do NOVO JOGO: tem_save() é falso")
	checar_igual(gs.treino, 0.0, "o estado voltou ao zero")
	checar_igual(gs.abertura_estado(), "pending", "a abertura vai tocar de novo")
	# Segunda cópia no mesmo segundo nunca sobrescreve a primeira.
	gs.treino = 99.0
	gs.salvar()
	var copia2: String = gs.novo_jogo_com_copia()
	checar(copia2 != "" and copia2 != copia, "duas cópias seguidas têm nomes diferentes")
	checar_igual(_copias(pasta).size(), 2, "as duas cópias continuam lá")
	_liberar(gs)


func _teste_opcoes() -> void:
	var gs := _novo("menu_opcoes")
	checar_igual(gs.volume_geral, 1.0, "padrão: volume geral 1")
	checar_igual(gs.volume_efeitos, 1.0, "padrão: volume dos efeitos 1")
	checar(not gs.tela_cheia, "padrão: janela (não tela cheia)")
	gs.salvar()
	var pasta: String = gs.store.pasta
	var save_antes := FileAccess.get_md5(pasta.path_join("save.json"))
	gs.volume_geral = 0.5
	gs.volume_efeitos = 0.25
	gs.tela_cheia = false
	gs.opcoes_aplicar()
	checar(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.5)) < 0.01, "o volume geral foi para o bus Master")
	var efeitos := AudioServer.get_bus_index("Efeitos")
	checar(efeitos >= 0 and absf(AudioServer.get_bus_volume_db(efeitos) - linear_to_db(0.25)) < 0.01, "o volume dos efeitos foi para o bus Efeitos")
	checar(gs.opcoes_salvar(), "opcoes_salvar() grava")
	checar(FileAccess.file_exists(pasta.path_join("opcoes.cfg")), "opcoes.cfg fica ao lado do save (nos testes, na pasta de teste)")
	checar_igual(FileAccess.get_md5(pasta.path_join("save.json")), save_antes, "gravar opções não toca no save")
	checar(FileAccess.get_file_as_string(pasta.path_join("save.json")).find("volume") < 0, "o save não tem nada de opções")
	_liberar(gs)
	# Outro GameState na mesma pasta lê de volta.
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar_igual(g2.volume_geral, 0.5, "relido: volume geral")
	checar_igual(g2.volume_efeitos, 0.25, "relido: volume dos efeitos")
	# NOVO JOGO não apaga as opções.
	g2.novo_jogo_com_copia()
	checar(FileAccess.file_exists(pasta.path_join("opcoes.cfg")), "NOVO JOGO não apaga opcoes.cfg")
	_liberar(g2)
	# Arquivo sujo: volta aos padrões.
	escrever(pasta.path_join("opcoes.cfg"), "[audio]\ngeral=\"alto\"\nefeitos=9.0\n[video]\ntela_cheia=3\n")
	var g3: Node = GameStateScript.new()
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar_igual(g3.volume_geral, 1.0, "opção suja (texto): volta ao padrão")
	checar_igual(g3.volume_efeitos, 1.0, "opção suja (acima de 1): trava em 1")
	checar(not g3.tela_cheia, "opção suja (tela cheia não booleana): janela")
	_liberar(g3)
	# Volta o áudio do processo ao normal (não importa para o jogo, só limpeza).
	var g4 := _novo("menu_opcoes_limpa")
	g4.opcoes_aplicar()
	_liberar(g4)


func _teste_parede() -> void:
	var gs := _novo("menu_parede")
	var sempre: Array = ["soco", "luta_sabado", "luvas_velhas", "aluga_se"]
	checar_igual(gs.parede_menu(), sempre, "sem save: só as camadas 'sempre', na ordem do arquivo")
	# Sem save, nem com marcos na memória aparece mais (o menu mostra o que o disco tem).
	gs.escola.milestones["first_school_win"] = {"campaign": 1, "version": 1}
	checar_igual(gs.parede_menu(), sempre, "sem save: marcos soltos na memória não enchem a parede")
	gs.salvar()
	checar_igual(gs.parede_menu(), ["soco", "luta_sabado", "luvas_velhas", "aluga_se", "recorte_vitoria"], "com save e 1 marco: a camada do marco entra")
	for m in ["garage_saved", "cena_primeira_sucessao", "cena_primeira_academia", "cena_saida_primeiro_mentor",
			"regional_league_opened", "regional_belt_first", "center_arrival", "black_cat_rumor_heard"]:
		gs.escola.milestones[m] = {"campaign": 1, "version": 1}
	gs.permanente["black_cat"] = {"rounds": 1}
	var cheia: Array = gs.parede_menu()
	checar_igual(cheia.size(), 14, "com todos os marcos e 1 ronda: as 14 camadas")
	checar(cheia.find("liga") < cheia.find("liga_campeoes"), "a tira CAMPEÕES vem depois da Liga (ordem do arquivo)")
	checar_igual(cheia.back(), "capuz", "o capuz fecha a lista (pede ronda feita)")
	gs.permanente["black_cat"] = {"rounds": 0}
	checar(not ("capuz" in gs.parede_menu()), "sem ronda feita: sem capuz")
	var c: Array = gs.parede_camadas()
	checar(c[0].has("pos") and c[0].has("file") and str(c[0].id) == "soco", "parede_camadas() traz pos e file")
	_liberar(gs)


func _teste_menu_aberto() -> void:
	var gs := _novo("menu_aberto")
	gs.definir_menu_aberto(true)
	checar(gs.menu_aberto and gs.modal_aberto, "menu aberto: jogo parado (modal)")
	checar(not gs.sala_ativa(), "menu aberto: a sala não anda")
	checar(not gs.salvar(), "menu aberto: salvar() não grava")
	checar(not gs.tem_save(), "menu aberto sem save: continua sem save (nenhum save fantasma)")
	gs.definir_menu_aberto(false)
	checar(gs.salvar() and gs.tem_save(), "menu fechado: salvar() volta a gravar")
	_liberar(gs)


## Para todo som e solta a cena: um som tocando na hora de sair deixa "recurso em uso" (falso alarme do Godot).
func _encerrar_cena(cena: Node) -> void:
	for p in cena.find_children("*", "AudioStreamPlayer", true, false):
		(p as AudioStreamPlayer).stop()
	root.remove_child(cena)
	cena.free()
	await create_timer(0.6).timeout  # o mixer de áudio solta os sons que ainda tocavam (sem isso, 'recurso em uso' às vezes)


func _teste_fluxo() -> void:
	var gs: Node = root.get_node("GameState")
	gs.inicializar(pasta_limpa("menu_fluxo"), "res://data/config.json")
	gs.autosave_ativo = false
	var cena: Control = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	for i in 5:
		await process_frame
	var fluxo = cena.get_node("Fluxo")  # sem tipo: o autoload GameState não existe na hora de compilar o teste
	checar(fluxo.menu == null, "em teste o menu não abre sozinho")
	fluxo.caminho_menu = "res://ui/nao_existe_menu.gd"
	checar(not fluxo.mostrar_menu() and fluxo.menu == null, "sem ui/menu_principal.gd: mostrar_menu() é falso e o jogo segue como hoje")
	fluxo.caminho_menu = MENU_FALSO
	checar(fluxo.mostrar_menu() and fluxo.menu != null, "com o script do menu: mostrar_menu() abre")
	checar(fluxo.ocupado() and gs.menu_aberto, "menu aberto: Fluxo ocupado e GameState parado")
	var escolhas: Array = []
	fluxo.menu_escolheu.connect(func(a: String) -> void: escolhas.append(a))
	# CONTINUAR
	fluxo.menu.escolheu.emit("continuar")
	checar(fluxo.menu == null and not gs.menu_aberto and not fluxo.ocupado(), "CONTINUAR: menu fecha e o jogo anda")
	checar_igual(escolhas, ["continuar"], "CONTINUAR: sinal menu_escolheu")
	# NOVO JOGO com save
	gs.treino = 777.0
	gs.pular_abertura()
	gs.salvar()
	var pasta: String = gs.store.pasta
	fluxo.mostrar_menu()
	fluxo.menu.escolheu.emit("novo_jogo")
	checar(fluxo.menu == null and not gs.menu_aberto, "NOVO JOGO: menu fecha")
	checar_igual(_copias(pasta).size(), 1, "NOVO JOGO com save: uma cópia de segurança")
	checar(not gs.tem_save() and gs.treino == 0.0, "NOVO JOGO: save apagado e estado zerado")
	checar_igual(gs.abertura_estado(), "pending", "NOVO JOGO: a abertura toca de novo")
	checar_igual(escolhas.back(), "novo_jogo", "NOVO JOGO: sinal menu_escolheu")
	# NOVO JOGO sem save: não cria cópia.
	fluxo.mostrar_menu()
	fluxo.menu.escolheu.emit("novo_jogo")
	checar_igual(_copias(pasta).size(), 1, "NOVO JOGO sem save: nenhuma cópia nova")
	# Ação desconhecida é ignorada.
	fluxo.mostrar_menu()
	fluxo.menu.escolheu.emit("qualquer_coisa")
	checar(fluxo.menu != null, "ação desconhecida: o menu continua aberto")
	fluxo._fechar_menu()
	await _encerrar_cena(cena)
