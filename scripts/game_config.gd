class_name GameConfig
extends RefCounted
## Lê a configuração ajustável de data/config.json.
## Se o arquivo faltar ou tiver valor errado, usa padrões seguros e avisa no console.
## Chave que não existe mais em PADROES (ex.: treino_por_segundo_teste da Fase 1) é ignorada.

const CAMINHO_PADRAO := "res://data/config.json"

# Padrões seguros (só usados se o arquivo de dados falhar).
const PADROES := {
	"autosave_intervalo_segundos": 30.0,
	"multiplicador_debug": 1000.0,
	"ui_atualizacoes_por_segundo": 10.0,
	"debug_unidades_gerador": 10.0,
}

# Faixa válida de cada valor: [mínimo, máximo].
const FAIXAS := {
	"autosave_intervalo_segundos": [1.0, 3600.0],
	"multiplicador_debug": [1.0, 1.0e300],
	"ui_atualizacoes_por_segundo": [1.0, 60.0],
	"debug_unidades_gerador": [0.0, 1000.0],
}


## Retorna um Dictionary com todas as chaves de PADROES, sempre válidas.
static func carregar(caminho: String = CAMINHO_PADRAO) -> Dictionary:
	var config := PADROES.duplicate()
	if not FileAccess.file_exists(caminho):
		push_warning("GameConfig: '%s' não encontrado, usando padrões." % caminho)
		return config

	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(caminho)) != OK or not (json.data is Dictionary):
		push_warning("GameConfig: '%s' com JSON inválido, usando padrões." % caminho)
		return config

	var dados: Dictionary = json.data
	for chave in PADROES:
		if not dados.has(chave):
			push_warning("GameConfig: '%s' sem a chave '%s', usando padrão." % [caminho, chave])
			continue
		var v = dados[chave]
		var faixa: Array = FAIXAS[chave]
		if (typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT) or not is_finite(float(v)) \
				or float(v) < faixa[0] or float(v) > faixa[1]:
			push_warning("GameConfig: valor inválido em '%s' (%s), usando padrão." % [chave, str(v)])
			continue
		config[chave] = float(v)
	return config
