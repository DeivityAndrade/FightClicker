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
	var atores := {"p": {"character": "current_player", "pos": [300, 200], "anim": "idle"}}
	var antes: Dictionary = gs.visual_lutador()
	cs.montar({}, atores, {}, "teste", {"p": {"personagem": "current_player", "look": antes, "existe": true, "pos": [300, 200]}})
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
	cs.limpar()
	var sf: Node = cs.sala
	cs.free()
	sf.free()
