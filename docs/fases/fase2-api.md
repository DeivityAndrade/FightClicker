# Fase 2 — API pública da lógica (contrato para a UI)

Dono: Programador. Mantido junto com o código (`scripts/`). Regra: **a UI nunca soma recursos**; ela chama as funções abaixo e escuta os sinais.
Nomes de funções em português, ids de dados em inglês (`punching_bag`, `neighbor_kid`, `bag_patch`...).

## Autoloads
| Nome | Arquivo | Para quê |
|---|---|---|
| `GameState` | `scripts/game_state.gd` | Carreira (saldo, atributos, foco, geradores, melhorias), tick passivo, save |
| `AppControls` | `scripts/app_controls.gd` | **F11** alterna tela cheia. **F12** liga/desliga a depuração (só em build de debug) |

Classes (sem autoload): `NumberFormat` (formatador), `TrainingData` (definições de `data/`), `Economia` (teto3 / pode_pagar), `SaveStore`, `GameConfig`.

## Estado lido pela UI (somente leitura)
| Variável | Tipo | Significado |
|---|---|---|
| `GameState.treino` | float | Saldo de Treino (HUD "TREINO"). Formatar com `NumberFormat.TRUNCAR` |
| `GameState.atributos` | Dictionary | `{"strength": f, "agility": f, "endurance": f}`. Formatar com `TRUNCAR` |
| `GameState.foco` | String | id do aparelho em foco |
| `GameState.geradores` | Dictionary | `id do gerador -> quantidade (int)` |
| `GameState.niveis_melhoria` | Dictionary | `id do aparelho -> nível comprado (0..n)` |
| `GameState.dados` | TrainingData | Definições e textos (ver abaixo) |
| `GameState.config` | Dictionary | `autosave_intervalo_segundos`, `multiplicador_debug`, `ui_atualizacoes_por_segundo`, `debug_unidades_gerador` |

## Sinais (todos em `GameState`)
| Sinal | Quando |
|---|---|
| `treino_mudou(valor: float)` | O saldo mudou (clique, tick, compra). Pode vir a cada frame: a UI deve só marcar "sujo" e redesenhar a 10 Hz |
| `atributo_mudou(atributo: String, valor: float)` | Um atributo subiu (junto com `treino_mudou`) |
| `foco_mudou(aparelho: String)` | Foco trocado |
| `clicou(ganho: float, critico: bool, aparelho: String, atributo: String, texto_critico: String)` | **Um por clique válido.** `ganho` = exatamente o que entrou no saldo e no atributo. `texto_critico` = frase sorteada ("" se não foi crítico). Usar para número flutuante, juice e som |
| `gerador_mudou(gerador: String, quantidade: int)` | Compra de gerador (pessoa pode aparecer na sala) |
| `melhoria_comprada(aparelho: String, melhoria: String, nivel: int)` | Compra de melhoria (trocar sprite se `nivel_visual` mudou) |
| `economia_mudou()` | `producao_total()`, `por_clique()` ou custos mudaram: compra, troca de foco, carga do save. Redesenhar painéis |
| `carreira_mudou()` | O estado inteiro foi substituído (carregar, apagar save, depuração). Redesenhar tudo, incluindo sala |
| `salvo(horario_texto)`, `avisos_mudaram(avisos)`, `carregado(status)` | Como na Fase 1 |

## Ações (a UI chama)
| Função | Retorno | Observação |
|---|---|---|
| `clicar()` | `Dictionary {ganho, critico, aparelho, atributo, texto_critico}` | Chamar **só** se o clique caiu na área do alvo central. Emite `clicou`. Um sorteio de crítico por clique |
| `definir_foco(aparelho_id)` | bool | Grátis e instantâneo; `false` se o id não existe. Clique em aparelho lateral chama isto e **não** `clicar()` |
| `comprar_gerador(gerador_id)` | bool | `false` (nada muda) se não existe ou não há saldo |
| `comprar_melhoria(aparelho_id)` | bool | Compra o **próximo nível** daquele aparelho. `false` se linha completa ou sem saldo |
| `salvar()`, `carregar_save()`, `apagar_save()`, `texto_confirmar_apagar()` | | Como na Fase 1 |
| `debug_disponivel()` | bool | `true` só em build de debug. Esconder a depuração se `false` |
| `debug_multiplicar_saldo()` | | saldo = max(saldo,1) x `multiplicador_debug`. Não mexe em atributo |
| `debug_somar_geradores()` | | +`debug_unidades_gerador` de cada gerador, de graça |

## Consultas (a UI chama para desenhar)
| Função | Retorno |
|---|---|
| `por_clique()` | float: `base x multiplicador do foco`, sem crítico (barra "POR CLIQUE"; formatar ARREDONDAR) |
| `multiplicador_aparelho(aparelho_id)` | float |
| `producao_total()` | float Treino/s (barra "AUTO", HUD "+x/S"; ARREDONDAR) |
| `producao_gerador(gerador_id)` | float: `production x quantidade` daquele gerador |
| `quantidade_gerador(gerador_id)` | int |
| `custo_gerador(gerador_id)` | float: custo da **próxima** unidade (já em 3 dígitos; mostrar exato) |
| `pode_comprar_gerador(gerador_id)` | bool: `false` = preço em `r2` (vermelho) |
| `pessoas_desenhadas(gerador_id)` | int: quantas pessoas desenhar na sala (0..máx.). Acima do limite continua igual |
| `nivel_melhoria(aparelho_id)` | int comprado |
| `proxima_melhoria(aparelho_id)` | Dictionary da próxima melhoria (formato abaixo) ou `{}` se a linha está completa (mostrar "MÁXIMO") |
| `pode_comprar_melhoria(aparelho_id)` | bool: `false` se completa ou sem saldo |
| `nivel_visual(aparelho_id)` | int 0 ou 1: qual sprite do aparelho (0 = remendado, 1 = melhorado) |
| `atributo_do_aparelho(aparelho_id)` | String id do atributo (`strength`...) |
| `texto_efeito_melhoria(melhoria: Dictionary)` | String pronta, ex.: `x3 POR CLIQUE NO SACO` (a UI põe em maiúsculas) |
| `NumberFormat.fmt(valor, modo := NumberFormat.ARREDONDAR)` | String. `NumberFormat.TRUNCAR` para saldo e atributos (nunca mostra "1.00M" sem ter 1M) |

Regra "pode comprar" = `saldo >= custo` com tolerância 1e-9. Como saldo mostrado é truncado e custo já é exato em 3 dígitos, "saldo na tela >= preço na tela" é o mesmo que `pode_comprar_*`.

## Definições e textos (`GameState.dados`, tipo `TrainingData`)
Tudo vem de `data/*.json`. A UI **não** guarda texto nem número de balanceamento.

- `dados.aparelhos` : Array (ordem da tela) de Dictionary:
  `{ id, attribute, name, focus_label: [linha1, linha2], first_hint, crit_texts: [String], upgrades: [melhoria] }`
- `dados.aparelho(id)` : o Dictionary acima (ou `{}`)
- melhoria: `{ id, cost, multiplier, visual_level, name, description }`
- `dados.geradores` : Array (ordem da tela) de `{ id, base_cost, growth, production, draw_thresholds: [int], name, description, appears_as }`
- `dados.gerador(id)` : o Dictionary (ou `{}`)
- `dados.atributos` : Array de ids em ordem `["strength","agility","endurance"]`
- `dados.atributo_info(id)` : `{ name, hint }` — ex.: `{ "name": "FORÇA", "hint": "Força: quanto dói o seu soco." }`
- `dados.crit_chance`, `dados.crit_multiplier`, `dados.base_training`, `dados.default_focus`
- `dados.ui` : Dictionary de textos de interface (`data/ui_texts.json`): `location_name`, `location_ambience`, `hud_training`, `panel_team`, `panel_upgrades`, `per_click`, `auto`, `focus_label`, `can_afford_hint`, `buy_generator` ("CHAMAR"), `maxed` ("MÁXIMO"), `upgrade_effect` (modelo com `{mult}` e `{alvo}`, ex.: "x3 POR CLIQUE: SACO"), `panel_attributes` ("ATRIBUTOS"), `upgrade_button` ("MELHORAR"), `saved_footer` ("SALVO {hora}"), `fullscreen_hint` ("F11 TELA CHEIA"), `debug_add_currency`, `debug_add_generators`, `debug_save`, `debug_reload`, `debug_wipe_save`, `debug_confirm`.
- **Ler qualquer chave:** `GameState.texto_ui(chave, padrao := "")` devolve o texto de `data/ui_texts.json` (ou o padrão se a chave faltar). Equivale a `GameState.dados.ui.get(chave, "")`.
- Os textos vêm em caixa normal (como o Roteirista escreveu); a UI aplica `.to_upper()`.
- Cores dos atributos e posição de pessoas na sala são da UI/Arte, não estão em `data/`.

## Fluxo de um clique (para o juice)
1. UI detecta clique do mouse dentro da área central -> `GameState.clicar()`.
2. `GameState` emite `clicou(ganho, critico, aparelho, atributo, texto_critico)` e o `Dictionary` volta como retorno.
3. A UI mostra `+{NumberFormat.fmt(ganho)} {nome do atributo}` (crítico: 2x, `r3`, "!" e `texto_critico` acima), toca som, tremida, reação do aparelho.
4. Saldo e atributo já estão atualizados; `treino_mudou`/`atributo_mudou` vêm antes de `clicou`.

## Save (v2)
`{"version":2,"saved_at_unix":T,"state":{"career":{"training","attributes":{...},"focus","generators":{...},"upgrades":{aparelho: nivel}}}}`. Migração v0->v1->v2 em `SaveStore`. Custos e produção são recalculados de `data/` ao abrir.

## Arquivos de dados
`data/training.json` (clique, aparelhos, melhorias, atributos, textos deles), `data/generators.json`, `data/ui_texts.json`, `data/config.json`.
