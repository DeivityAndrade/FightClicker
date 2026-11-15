extends SceneTree
## Valida as cenas por dados, sem abrir o jogo (formato-dados.md §7).
## Uso: godot --headless --path E:/Fightclicker --script res://tools/cenas/validar_cenas.gd [-- --rascunhos]
## Sem argumento: todas as cenas de data/cutscenes/ (a pasta _rascunhos/ fica de fora).
## Com --rascunhos: valida também os arquivos de data/cutscenes/_rascunhos/ (só para o Diretor de Cutscenes conferir).
## Erros saem com código 1; arte que falta aparece como pendência e não reprova.


func _initialize() -> void:
	var v := CenaValidador.novo()
	var relatorios: Array = v.validar_tudo()
	if "--rascunhos" in OS.get_cmdline_user_args():
		var pasta := CenaDados.PASTA + "_rascunhos/"
		for arq in DirAccess.get_files_at(pasta):
			if arq.ends_with(".json"):
				relatorios.append(v.validar_caminho(pasta + arq))
	var falhou := false
	for r in relatorios:
		print("== %s: %d erro(s), %d aviso(s), %d pendência(s), tempo preso %.2f s%s" % [r.id, r.erros.size(), r.avisos.size(),
			r.pendencias.size(), r.tempo_preso, "" if r.tempo_exato else " (provisório)"])
		for e in r.erros:
			print("  ERRO: " + e)
			falhou = true
		for a in r.avisos:
			print("  aviso: " + a)
		for p in r.pendencias:
			print("  pendência: " + p)
	quit(1 if falhou else 0)
