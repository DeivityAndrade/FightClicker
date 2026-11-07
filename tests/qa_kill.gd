extends SceneTree
## QA: modo "write" salva em loop (para ser morto no meio); modo "read" carrega e imprime o status.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var s := SaveStore.new("user://test/qa_kill/")
	if a[0] == "write":
		var i := 0
		while true:
			i += 1
			s.salvar({"treino": float(i)})
	else:
		var r := s.carregar()
		print("QA status=", r.status, " treino=", r.estado.get("treino"), " msg=", r.mensagem)
		quit(0)
