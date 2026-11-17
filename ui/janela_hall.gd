extends "res://ui/janela_base.gd"
## Janela da Árvore do Hall (Fase 6c2). Lê estado via sinais do GameState; chama funções públicas dele.
## ui_align metadata em todos os Controls intencionais.

@onready var titulo: Label = %Titulo
@onready var saldo_label: Label = %SaldoHonor
@onready var branches_container: HBoxContainer = %Branches
@onready var painel_info: PanelContainer = %PainelInfo
@onready var nome_no: Label = %NomeNo
@onready var desc_no: Label = %DescNo
@onready var custo_label: Label = %CustoLabel
@onready var botao_comprar: Button = %BotaoComprar
@onready var efeito_label: Label = %EfeitoLabel
@onready var juice: Node = %JuiceHall

var _nos_dados: Array = []
var _branch_atual: String = ""
var _no_selecionado: String = ""

func _ready() -> void:
	super._ready()
	set_meta("ui_align", "center")
	titulo.set_meta("ui_align", "center")
	saldo_label.set_meta("ui_align", "center")
	painel_info.set_meta("ui_align", "center")
	nome_no.set_meta("ui_align", "center")
	desc_no.set_meta("ui_align", "center")
	custo_label.set_meta("ui_align", "center")
	botao_comprar.set_meta("ui_align", "center")
	efeito_label.set_meta("ui_align", "center")
	botao_comprar.pressed.connect(_on_comprar)
	GameState.honor_changed.connect(_atualizar_saldo)
	GameState.hall_node_bought.connect(_on_no_comprado)
	_carregar_dados()

func abrir() -> void:
	super.abrir()
	_atualizar_saldo(GameState.honor_balance())
	_mostrar_branch("hall_roots")

func fechar() -> void:
	super.fechar()

func _carregar_dados() -> void:
	_nos_dados = GameState.hall_tree.get("nodes", [])

func _mostrar_branch(branch_id: String) -> void:
	_branch_atual = branch_id
	for c in branches_container.get_children():
		c.queue_free()
	for no in _nos_dados:
		if str(no.get("branch", "")) != branch_id:
			continue
		var btn := Button.new()
		btn.text = str(no.get("name", no.get("id", ""))).to_upper()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.set_meta("ui_align", "center")
		var id := str(no.get("id", ""))
		btn.pressed.connect(_selecionar_no.bind(id))
		branches_container.add_child(btn)
	_no_selecionado = ""
	_limpar_info()

func _selecionar_no(id: String) -> void:
	var no := _achar_no(id)
	if no.is_empty():
		return
	_no_selecionado = id
	nome_no.text = str(no.get("name", "")).to_upper()
	desc_no.text = str(no.get("description", ""))
	var custo := int(no.get("cost", 0))
	custo_label.text = "%d HONRA" % custo
	var eff_text := str(no.get("effect_text", ""))
	if "{pct}" in eff_text:
		var val := float(no.get("effect", {}).get("value", 0))
		eff_text = eff_text.replace("{pct}", str(int(val * 100)))
	efeito_label.text = eff_text.to_upper()
	_atualizar_botao_compra(no)

func _atualizar_botao_compra(no: Dictionary) -> void:
	var id := str(no.get("id", ""))
	var comprados := GameState.hall_nodes_comprados()
	if id in comprados:
		botao_comprar.text = "APRENDIDO"
		botao_comprar.disabled = true
		return
	var req := str(no.get("requires", ""))
	if req != "" and not (req in comprados):
		botao_comprar.text = "PEDE: %s" % str(_nome_no(req)).to_upper()
		botao_comprar.disabled = true
		return
	var custo := float(no.get("cost", 0))
	if GameState.honor_balance() < custo:
		botao_comprar.text = "FALTA HONRA"
		botao_comprar.disabled = true
		return
	botao_comprar.text = "COMPRAR"
	botao_comprar.disabled = false

func _on_comprar() -> void:
	if _no_selecionado == "":
		return
	var ok := GameState.hall_buy(_no_selecionado)
	if ok and juice and botao_comprar:
		juice.punch(botao_comprar)
		var no := _achar_no(_no_selecionado)
		if not no.is_empty():
			var pos := botao_comprar.global_position + botao_comprar.size / 2.0
			juice.float_number("+NÓ", pos, self, Color(1, 0.9, 0.4))

func _atualizar_saldo(balance: float) -> void:
	saldo_label.text = "HONRA: %d" % int(balance)
	if _no_selecionado != "":
		var no := _achar_no(_no_selecionado)
		if not no.is_empty():
			_atualizar_botao_compra(no)

func _on_no_comprado(node_id: String) -> void:
	if node_id == _no_selecionado:
		var no := _achar_no(node_id)
		if not no.is_empty():
			_atualizar_botao_compra(no)

func _achar_no(id: String) -> Dictionary:
	for no in _nos_dados:
		if str(no.get("id", "")) == id:
			return no
	return {}

func _nome_no(id: String) -> String:
	var no := _achar_no(id)
	return str(no.get("name", id))

func _limpar_info() -> void:
	nome_no.text = ""
	desc_no.text = ""
	custo_label.text = ""
	efeito_label.text = ""
	botao_comprar.text = "COMPRAR"
	botao_comprar.disabled = true