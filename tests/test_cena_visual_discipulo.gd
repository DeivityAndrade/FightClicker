extends "res://tests/test_base.gd"
## 6d C1: depois do CONFIRMAR o ator `current_player` da cena tem o visual do rascunho confirmado
## (e não o padrão congelado no começo da cena). Usa o autoload com pasta de save de teste.

# Os scripts de ui/ citam o autoload GameState: só podem ser carregados depois que ele existe (load em tempo de execução).
const FONTE_SALA_FALSA := "extends \"res://ui/sala.gd\"
func cena_iniciar(_oculta: Array, _livre: bool = false) -> void:
	pass
"


func rodar_testes() -> void:
	var gs: Node = root.get_node("GameState")
	gs.inicializar(pasta_limpa("cena_visual"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	# Cena montada ANTES do CONFIRMAR, com o visual padrão (como o CenaPlayer faz no começo).
	var falsa := GDScript.new()
	falsa.source_code = FONTE_SALA_FALSA
	falsa.reload()
	var cs: Node2D = load("res://ui/cena_sala.gd").new()
	cs.sala = falsa.new()
	root.add_child(cs)
	var personagens: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cena_player.json")).get("characters", {})
	var atores := {"p": {"character": "current_player", "glove": "none", "pos": [300, 200], "anim": "idle"}}
	var antes: Dictionary = gs.visual_lutador()
	cs.montar({}, atores, personagens, "teste", {"p": {"personagem": "current_player", "look": antes, "existe": true, "pos": [300, 200]}})
	# O jogador sorteia um visual diferente do padrão e confirma.
	gs._rng_sucessao.seed = 5
	var look: Dictionary = {}
	for i in 20:
		gs.sortear_rascunho()
		look = gs.rascunho().look
		if look != antes:
			break
	checar(look != antes, "o rascunho sorteado difere do visual padrão")
	checar(gs.confirmar_discipulo(), "CONFIRMAR aceito")
	var visual: Dictionary = gs.visual_lutador()
	checar(visual == gs.disciples.validar_look(look), "o discípulo ficou com o visual do rascunho")
	var a: Dictionary = cs._atores["p"]
	cs._pose(a, "idle", true, [], 0.0)
	var esperado: Texture2D = load("res://ui/disc_visual.gd").textura(str(a.nome), visual, false)
	checar(a.sp.texture == esperado, "o ator da cena usa o visual confirmado, não o padrão da criação")
	# Todas as poses do current_player nas cenas (parte 2 da primeira sucessão e chegada curta), viradas para os dois lados.
	var dv = load("res://ui/disc_visual.gd")
	for anim in ["idle", "stand_bare", "walk_bare", "duck_under", "take_gloves"]:
		for lado in ["left", "right"]:
			a.facing = lado
			cs._pose(a, anim, true, [], 1.0)
			var nome := str(a.nome)
			var certo: Texture2D = dv.textura(nome, visual, false)
			var padrao: Texture2D = dv.textura(nome, antes, false)
			checar(a.sp.texture == certo, "pose %s (%s, folha %s) usa o visual confirmado" % [anim, lado, nome])
			if certo != padrao:
				checar(a.sp.texture != padrao, "pose %s (%s) não ficou com o visual padrão" % [anim, lado])
	# Pelo caminho dos eventos do CenaPlayer: show (textura velha da montagem) e move com duck_under / walk_bare.
	a.facing = "right"
	cs._pose(a, "idle", true, [], 1.0)
	a.sp.texture = dv.textura(str(a.nome), antes, false)  # a textura velha, de antes do CONFIRMAR
	cs.evento({"tipo": "show", "ator": "p"})
	checar(a.sp.texture == dv.textura(str(a.nome), visual, false), "evento show: a textura já é a do visual confirmado")
	for anim in ["duck_under", "walk_bare", "take_gloves"]:
		cs.evento({"tipo": "move", "ator": "p", "to": [410, 236], "seconds": 0.7, "anim": anim, "facing": "left"})
		checar(a.sp.texture == dv.textura(str(a.nome), visual, false) and a.sp.texture != dv.textura(str(a.nome), antes, false),
			"evento move %s (%s): visual confirmado" % [anim, a.nome])
	cs.limpar()
	var sf: Node = cs.sala
	cs.free()
	sf.free()
