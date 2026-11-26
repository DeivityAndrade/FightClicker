extends RefCounted
## Estados do ui_audit.gd: ID4 (menu principal). Sem save, com save no meio e cheio (parede), foco em cada botão, confirmação 1 e 2,
## OPÇÕES e a intro em 3 momentos. O menu recebe `dados_teste` (nunca toca o save nem a janela). Roda com o auditor `au`.

const NOMES := [
	"menu_sem_save", "menu_meio", "menu_cheio",
	"menu_foco_continuar", "menu_foco_novo", "menu_foco_opcoes", "menu_foco_sair",
	"menu_confirma1", "menu_confirma2", "menu_opcoes", "menu_opcoes_efeitos", "menu_opcoes_tela_cheia", "menu_opcoes_voltar",
	"menu_intro_faixa", "menu_intro_impacto", "menu_intro_botoes",
]
const MEIO := ["soco", "luta_sabado", "luvas_velhas", "aluga_se", "recorte_vitoria", "raizes", "foto_equipe", "foto_antiga", "faixas_john", "liga"]

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _todas() -> Array:
	var ids: Array = []
	var json := JSON.new()
	json.parse(FileAccess.get_file_as_string("res://assets/sprites/menu/parede.json"))
	for c in json.data.layers:
		ids.append(str(c.id))
	return ids


func _menu(tem_save: bool, camadas: Array, ms: float = 860.0):
	au._novo_jogo()
	var m = load("res://ui/menu_principal.gd").new()
	m.dados_teste = {"tem_save": tem_save, "camadas": camadas, "volume_geral": 0.8, "volume_efeitos": 0.5, "tela_cheia": false}
	m.animar = false
	au._cena = m
	au.root.add_child(m)
	await au.process_frame
	m.ir_para_ms(ms)
	await au._esperar(0.2)
	return m


func _rodar_menu() -> void:
	if not _alguma():
		return
	var todas := _todas()
	if au._quer("menu_sem_save"):
		await _menu(false, ["soco", "luta_sabado", "luvas_velhas", "aluga_se"])
		await au._ver("menu_sem_save")
	if au._quer("menu_meio"):
		await _menu(true, MEIO)
		await au._ver("menu_meio")
	if au._quer("menu_cheio"):
		await _menu(true, todas)
		await au._ver("menu_cheio")
	var nomes := ["menu_foco_continuar", "menu_foco_novo", "menu_foco_opcoes", "menu_foco_sair"]
	for i in 4:
		if au._quer(nomes[i]):
			var m = await _menu(true, MEIO)
			m._focar(i, false)
			await au._ver(nomes[i])
	if au._quer("menu_confirma1"):
		var m = await _menu(true, MEIO)
		m._ativar(1)
		await au._esperar(0.4)
		await au._ver("menu_confirma1")
	if au._quer("menu_confirma2"):
		var m = await _menu(true, MEIO)
		m._abrir_confirmacao(2)
		await au._esperar(0.4)
		await au._ver("menu_confirma2")
	for par in [["menu_opcoes", 0], ["menu_opcoes_efeitos", 1], ["menu_opcoes_tela_cheia", 2], ["menu_opcoes_voltar", 3]]:
		if au._quer(par[0]):
			var m = await _menu(false, ["soco", "luta_sabado", "luvas_velhas", "aluga_se"])
			m._abrir_opcoes()
			m._jan_focar(int(par[1]))
			await au._esperar(0.4)
			await au._ver(par[0])
	for par in [["menu_intro_faixa", 150.0], ["menu_intro_impacto", 360.0], ["menu_intro_botoes", 640.0]]:
		if au._quer(par[0]):
			await _menu(true, MEIO, par[1])
			await au._ver(par[0])
