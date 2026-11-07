# Fase 5: contrato da lógica para a UI (academia, mudança, artes)

Dono: Programador. Tudo no autoload `GameState` (`scripts/game_state.gd`). Dados novos: `data/locations.json`, `data/arts.json` (classe `GymData`, `scripts/gym_data.gd`), aparelhos de arte em `data/training.json`, Tonhão e Kid em `data/opponents.json`, ramo ESTILO em `data/skill_tree.json`, chaves novas em `data/ui_texts.json`. A UI não soma nem sorteia nada.

## 1. Estado novo
| Variável | Significado |
|---|---|
| `local_id` | `"garage"` ou `"gym"` (`career.location`) |
| `arte_id` | `""` (sem arte), `"boxing"`, `"bjj"` (`career.art`) |
| `arte_segundos` | tempo desde a escolha da arte (`career.art_seconds`) |
| `permanente.arts_unlocked` / `permanente.last_art` | artes liberadas para sempre / última escolhida |
| `academia` | `GymData` (locais e artes) |

Sinais: `local_mudou(local)`, `arte_mudou(arte)`, `escolha_arte_pedida(primeira: bool)`. `_emitir_tudo` (carga do save) emite os três quando cabe.

## 2. Escada e cinturão (mudou)
- `cinturao` = a escada passou do Muralha (`indice_escada > índice do adversário com belt`). Com 6 adversários, `escada_completa()` só vale depois do Kid.
- `proximo_adversario()` devolve `{}` também quando o próximo só luta em outro local (Tonhão na garagem). `pode_lutar()` e `lutar()` recusam.
- `estado_escada()` -> `"fight"` | `"move"` (mostrar MUDAR / `hud_next_move`) | `"end"` (mostrar `no_more_fights_gym`).
- `precisa_mudar()` bool. `info_proxima()` ganhou `move` e `end`.
- A UI de hoje já cai em `_mostrar_cinturao()` quando `proximo_adversario()` é `{}`: na garagem com cinturão deve mostrar o MUDAR no lugar do aviso; com `end`, `no_more_fights_gym`.

## 3. Mudança
| API | Faz |
|---|---|
| `mudanca() -> Dictionary` | `{}` se já está no destino. Senão `{id, location, cost, name, mult, button, description, title, price_text ("$1.00K"), effect_text, keeps_text, per_career_text, state}` |
| `estado_mudanca()` | `"none"`, `"locked"` (sem cinturão: o botão **não existe**), `"missing"` (cinturão sem $: apagado), `"ready"` |
| `pode_mudar()`, `mudar() -> bool` | desconta $ uma vez, `local_id="gym"`, na 1ª vez libera as 2 artes e pede a escolha; salva na hora. Não tira nada |
| `sufixo_aparelhos()` | `"_gym"` na academia (sprite dos aparelhos básicos: `punching_bag_gym` etc.), `""` na garagem |
| `texto_hud_local()` | "ACADEMIA: TREINO x2" ou `""` na garagem; `em_academia()`, `mult_local()` |
| `local_atual()` | dicionário do local (name, ambience...) |

Toast de chegada: `texto_ui("move_arrived")`.

### Reserva na LOJA
`reserva_mudanca()` ($1.000 entre o cinturão e a mudança, senão 0). `loja_estado(custo) -> "ok" | "money" | "reserve"`. `pode_comprar_luva/gerador_pago/metronomo` já usam. Item em `"reserve"`: botão apagado com `texto_reserva()` ("GUARDE $1.00K PARA A MUDANÇA") ou `texto_reserva(true)` (curto). Nunca só apagar sem motivo.

## 4. Arte
| API | Faz |
|---|---|
| `escolha_arte_pendente()` | true = a janela deve estar aberta (artes liberadas, carreira viva, `arte_id==""`). Vale na 1ª chegada, início de toda carreira e ao reabrir o jogo |
| `acoes_bloqueadas()` | já inclui a escolha pendente (sem clique, compra, luta, Metrônomo, assistido) |
| `escolha_arte_primeira()`, `subtitulo_escolha_arte()` | 1ª vez x "CARREIRA n: ESCOLHA A ARTE" |
| `artes_para_escolha()` | `[{id, name, tagline, icon, rule_text, fight_text, apparatus, apparatus_name, last, last_text}]`; `last` = vem marcada |
| `escolher_arte(id) -> bool` | 1 clique; vale a carreira; salva. **Não existe troca** |
| `artes_liberadas()`, `nome_arte(id)` | consultas |
| `texto_hud_arte()` | "BOXE: +50% NO SEU CLIQUE" / "JIU-JITSU: EQUIPE +48%" / "... (MÁX.)"; ler 1x/s |
| `bonus_arte_clique()`, `bonus_arte_equipe()`, `arte_no_teto()`, `estilo_arte(id)` | números |
| `cartao_inicio()` | ganhou `art` e `art_text` ("ARTE: BOXE"); `{}` só sem nós **e** sem arte |

Fluxo NOVA CARREIRA: `nova_carreira_iniciada(cartao)` sai com `art==""`; em seguida `escolha_arte_pedida(false)`. A UI abre a janela, e **depois da escolha** chama `cartao_inicio()` de novo para mostrar o cartão. A janela chama `definir_modal(true)` como as outras. Sem janela, o jogo fica travado (ações bloqueadas): a UI precisa tratar `escolha_arte_pedida` e checar `escolha_arte_pendente()` ao iniciar.

Regras (todas lidas de `data/arts.json`):
- Clique manual: `por_clique()` já inclui Boxe e local. `por_auto_soco()` = Metrônomo/assistido, sem Boxe. Equipe (`producao_total()`) inclui local e Jiu-jitsu. `texto_efeito_loja` do Nelson também.
- Traço de luta: `previa()` ganhou `art` e `art_fight_text`. A tática efetiva é montada no motor (`motor.traco`), igual na luta e na prévia. `tatica_efetiva(id)` para testes.

## 5. Aparelho da arte (4º foco)
- `aparelhos_da_carreira() -> Array`: os 3 de sempre + o da arte (se houver). **Usar no lugar de `dados.aparelhos`** para botões de foco (tecla 4), cartões da aba TREINO, marcas de fita. `dados.aparelhos` continua só com os 3 básicos (a UI antiga não quebra); `dados.aparelhos_arte` e `dados.todos_aparelhos()` existem.
- `estado_aparelho(id)` ganhou `"absent"` (aparelho de outra arte; não desenhar nada). `aparelho_existe(id)`.
- Compra, chegada, `aparelho_comprado`, `textos_trancado`, foco e melhorias (as 2 técnicas) seguem o padrão da 4b. Pede a esteira; 2.500 Treino. Plaquinha: "PERA — 2.50K TREINO" / "BONECO — DEPOIS DA ESTEIRA". `nome_curto_aparelho` = "Pera"/"Boneco". `attr_locked` ("COMPRE A {nome} PARA TREINAR") não serve ao Boneco: não usar (o aparelho de arte não tem linha na aba ATRIBUTOS).
- Divisão do treino: `divisao_aparelho(id)` `{atributo: fração}`; `texto_divisao(id)` "FOR 40% / AGI 45% / RES 15%" ("" nos básicos). O saldo recebe o valor inteiro; cada atributo recebe `valor x fração` (um `atributo_mudou` por atributo). `clicou`/`auto_socou` trazem em `atributo` o de maior fatia (cor/ícone). Dado de aparelho: `attribute` (maior fatia), `split`, `art`.
- A dica de fim de derrota (`unlock_tip`) continua só olhando os 3 básicos.

## 6. Árvore, aba ESTILO
- `arvore_ramos() -> [{id, name}]`: ESTILO só aparece com artes liberadas. Usar no lugar de `lutas.ramos`.
- `arvore_nos()` só lista nós de ramos visíveis; ganhou `requires_art` e `art_only_text` ("SÓ VALE JOGANDO DE BOXE"). Estado `"locked"` se a arte não está liberada. Compra/estado igual aos outros. Efeito `art_rule_bonus` vale a partir da NOVA CARREIRA, só na arte do nó. Texto curto: `tree_short_style_*`.

## 7. Dica de aposentar (academia)
`dica_aposentar() -> {show, text, legacy, seconds}`: `show` quando o adversário da academia está PERIGOSO (melhor das 3 táticas) há >= `career.json gym_retire_hint_seconds` (300). Texto "APOSENTAR AGORA LEVA {n} DE LEGADO" com o Legado da confirmação (`previa_aposentar().total`). Não vai no save. Mostrar no bloco PRÓXIMA LUTA; passa pela `alinhamento-ui`.

## 8. Dicas extras de fim (opcional)
`textos_fim()` ganhou `tip_extra` (derrota na academia: `tip_gym_loss`; derrota com arte: `tip_art_<arte>`; aposentou com cinturão sem lutar na academia: `tip_move_belt`; senão `""`). `fim.summary.art` guarda a arte (`sum_art`).

## 9. Save v6
`career.location`, `career.art`, `career.art_seconds`, `permanent.arts_unlocked`, `permanent.last_art`, `ending.summary.art`. Migração v5->v6: carreira na garagem, sem arte; com cinturão e menos de $1.000, dinheiro = $1.000 (`MIGRACAO_V6_DINHEIRO_MUDANCA`). Validação: local/arte inexistente ou arte não liberada -> padrão/`""` com aviso; aparelho de outra arte sai do save (técnicas zeram, foco volta); escada além do 1º da academia na garagem -> academia; luta pendente do Tonhão na garagem é descartada. NOVA CARREIRA: `location=garage`, `art=""`, `art_seconds=0`.

## 10. O que a UI precisa construir
1. Botão MUDAR (bloco PRÓXIMA LUTA e vitória do cinturão): só com `estado_mudanca()` `ready`/`missing`; preço, apagado sem $; chama `mudar()`; toast `move_arrived`; `hud_next_move` quando `estado_escada()=="move"`; `no_more_fights_gym` quando `"end"`.
2. Sala da academia + sprites `_gym` dos 3 aparelhos (`sufixo_aparelhos()`), reagir a `local_mudou`.
3. Janela de escolha da arte (sem X, 1 clique, `last` marcada), antes do cartão de início; modal.
4. 4º foco (tecla 4), marca de fita, cartão da aba TREINO, pera/boneco e chegada; iterar `aparelhos_da_carreira()`; `focus_split`.
5. HUD da arte (`texto_hud_arte`) e do local (`texto_hud_local`); linha do traço na prévia (`art_fight_text`); `career_card_art` no cartão; `sum_art` no resumo.
6. LOJA: `loja_estado` e `texto_reserva`.
7. Aba ESTILO na árvore (`arvore_ramos`, `art_only_text`).
8. `dica_aposentar` no bloco PRÓXIMA; `tip_extra` na tela de fim (opcional).
9. Tudo passa pela skill `alinhamento-ui`. Larguras de atenção: "GUARDE $1.00K PARA A MUDANÇA", "JIU-JITSU: EQUIPE +150% (MÁX.)", `rule_text` do Jiu-jitsu.

Obs.: o `NumberFormat.fmt` escreve $1.000 como "$1.00K"; os textos do design dizem "$1.000".
