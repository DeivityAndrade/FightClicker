extends RefCounted
## ID4 (menu principal): tem save?, NOVO JOGO com cópia de segurança, parede de cartazes do fundo e opções (volume e tela cheia).
## As opções ficam em `opcoes.cfg` (fora do save). Contrato com a tela: docs/fases/identidade-id4-contrato.md.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

const CAMINHO_PAREDE := "res://assets/sprites/menu/parede.json"
const NOME_OPCOES := "opcoes.cfg"
const BUS_EFEITOS := "Efeitos"
const PREFIXO_COPIA := "save_copia_"

var gs: EstadoJogo  # o GameState (autoload)
var _parede: Array = []  # camadas do parede.json (lidas uma vez)
var _parede_lida := false
var _roteando := false  # já liguei o roteamento dos AudioStreamPlayer para o bus Efeitos


func _init(g: EstadoJogo) -> void:
	gs = g


# --- Save e NOVO JOGO ---

## true se há save (principal ou backup) na pasta de save. É o que decide se o CONTINUAR existe.
func tem_save() -> bool:
	return gs.store != null and (FileAccess.file_exists(gs.store.caminho()) or FileAccess.file_exists(gs.store.caminho_backup()))


## Copia o save para `save_copia_AAAAMMDD_HHMMSS.json` (mesma pasta), apaga o save e zera o estado.
## Devolve o caminho da cópia. "" = não havia save (só zerou) OU a cópia falhou: neste caso o save NÃO é apagado
## (confira `tem_save()` depois: se ainda é true, nada foi feito).
func novo_jogo_com_copia() -> String:
	var copia := ""
	if tem_save():
		copia = _copiar_save()
		if copia == "":
			gs._avisar("Não foi possível guardar a cópia de segurança: o save foi mantido.")
			return ""
	gs.apagar_save()
	return copia


func _copiar_save() -> String:
	var origem: String = gs.store.caminho()
	if not FileAccess.file_exists(origem):
		origem = gs.store.caminho_backup()
	var bytes := FileAccess.get_file_as_bytes(origem)
	if bytes.is_empty():
		return ""
	var t := Time.get_datetime_dict_from_system()
	var base := "%s%04d%02d%02d_%02d%02d%02d" % [PREFIXO_COPIA, t.year, t.month, t.day, t.hour, t.minute, t.second]
	var destino: String = gs.store.pasta.path_join(base + ".json")
	var n := 1
	while FileAccess.file_exists(destino):  # duas cópias no mesmo segundo: nunca sobrescreve
		destino = gs.store.pasta.path_join("%s_%d.json" % [base, n])
		n += 1
	DirAccess.make_dir_recursive_absolute(gs.store.pasta)
	var f := FileAccess.open(destino, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(bytes)
	f.close()
	if FileAccess.get_file_as_bytes(destino) != bytes:  # só vale se ficou igual
		return ""
	return destino


## O menu está aberto: o jogo para (modal), nada é salvo e nenhuma janela abre por baixo.
func definir_menu_aberto(aberto: bool) -> void:
	gs.menu_aberto = aberto
	gs.definir_modal(aberto)


# --- Parede de cartazes ---

func _ler_parede() -> void:
	if _parede_lida:
		return
	_parede_lida = true
	var j = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_PAREDE))
	if j is Dictionary and j.get("layers") is Array:
		for c in j.layers:
			if c is Dictionary and str(c.get("id", "")) != "":
				_parede.append(c)


## As camadas visíveis (dicionários do parede.json), na ordem do arquivo. Sem save: só as de `requires` vazio.
func parede_camadas() -> Array:
	_ler_parede()
	var saida: Array = []
	var com_save := tem_save()
	for c in _parede:
		var req = c.get("requires", {})
		if not (req is Dictionary):
			continue
		if req.is_empty() or (com_save and _requisito_ok(req)):
			saida.append(c.duplicate(true))
	return saida


## Só os ids, na ordem.
func parede_menu() -> Array:
	var ids: Array = []
	for c in parede_camadas():
		ids.append(str(c.id))
	return ids


# Todas as chaves precisam valer; chave desconhecida = não vale (a camada nunca aparece por engano).
func _requisito_ok(req: Dictionary) -> bool:
	for chave in req:
		match str(chave):
			"milestone":
				if not gs.marco(str(req[chave])):
					return false
			"black_cat_rounds_min":
				if int(gs.lenda().get("rounds", 0)) < int(req[chave]):
					return false
			_:
				return false
	return true


# --- Opções ---

## Onde fica o opcoes.cfg: ao lado do save (no jogo real, `user://opcoes.cfg`; nos testes, na pasta de teste).
func caminho_opcoes() -> String:
	return gs.store.pasta.path_join(NOME_OPCOES) if gs.store != null else SaveStore.PASTA_REAL.path_join(NOME_OPCOES)


## Lê o arquivo (ausente ou ruim = padrões) e aplica.
func opcoes_carregar() -> void:
	gs.volume_geral = 1.0
	gs.volume_efeitos = 1.0
	gs.tela_cheia = false
	var cfg := ConfigFile.new()
	if cfg.load(caminho_opcoes()) == OK:
		gs.volume_geral = _volume(cfg.get_value("audio", "geral", 1.0))
		gs.volume_efeitos = _volume(cfg.get_value("audio", "efeitos", 1.0))
		var cheia = cfg.get_value("video", "tela_cheia", false)
		gs.tela_cheia = typeof(cheia) == TYPE_BOOL and cheia
	opcoes_aplicar()


func _volume(v: Variant) -> float:
	if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v)):
		return clampf(float(v), 0.0, 1.0)
	return 1.0


## Grava só o opcoes.cfg. Nunca mexe no save.
func opcoes_salvar() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "geral", snappedf(clampf(gs.volume_geral, 0.0, 1.0), 0.001))
	cfg.set_value("audio", "efeitos", snappedf(clampf(gs.volume_efeitos, 0.0, 1.0), 0.001))
	cfg.set_value("video", "tela_cheia", gs.tela_cheia)
	DirAccess.make_dir_recursive_absolute(caminho_opcoes().get_base_dir())
	return cfg.save(caminho_opcoes()) == OK


## Põe os valores nos buses de áudio (Master = geral, Efeitos = efeitos) e na janela.
func opcoes_aplicar() -> void:
	gs.volume_geral = _volume(gs.volume_geral)
	gs.volume_efeitos = _volume(gs.volume_efeitos)
	_garantir_bus()
	_volume_do_bus(0, gs.volume_geral)
	var efeitos := AudioServer.get_bus_index(BUS_EFEITOS)
	if efeitos >= 0:
		_volume_do_bus(efeitos, gs.volume_efeitos)
	# Janela: só mexe se mudou (assim ferramentas com janela não são alteradas à toa) e nunca no headless.
	if DisplayServer.get_name() != "headless" and gs.tela_cheia != tela_cheia_atual():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if gs.tela_cheia else DisplayServer.WINDOW_MODE_WINDOWED)


func _volume_do_bus(idx: int, v: float) -> void:
	AudioServer.set_bus_mute(idx, v <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


## Estado real da janela (F11 pode ter mudado por fora).
func tela_cheia_atual() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


# O jogo não tinha bus de efeitos: cria "Efeitos" (filho do Master) e manda todo AudioStreamPlayer novo para ele.
func _garantir_bus() -> void:
	if AudioServer.get_bus_index(BUS_EFEITOS) < 0:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_EFEITOS)
		AudioServer.set_bus_send(idx, "Master")
	if not _roteando and gs.is_inside_tree():
		_roteando = true
		gs.get_tree().node_added.connect(_rotear_no)


func _rotear_no(no: Node) -> void:
	if no is AudioStreamPlayer and (no as AudioStreamPlayer).bus == &"Master":
		(no as AudioStreamPlayer).bus = BUS_EFEITOS
