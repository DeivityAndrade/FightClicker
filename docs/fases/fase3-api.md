# Fase 3 — API pública da lógica (contrato para a UI)

Dono: Programador. Complementa `fase2-api.md` (tudo de lá continua valendo). Regra: **a UI nunca soma recursos nem
sorteia nada**: ela chama as funções abaixo, escuta os sinais e anima o que a simulação já decidiu.
Código: `scripts/game_state.gd` (autoload `GameState`), `scripts/luta.gd` (`Luta`, simulação pura),
`scripts/fight_data.gd` (`FightData`, dados). Dados: `data/fights.json`, `opponents.json`, `shop.json`, `career.json`;
textos em `data/ui_texts.json`. Design: `fase3-design.md`.

## 1. Estado novo (somente leitura)
| Variável | Tipo | Significado |
|---|---|---|
| `GameState.dinheiro` | float | `$`. Formatar `"$ " + NumberFormat.fmt(v, TRUNCAR)` |
| `GameState.fama` | int | inteiro |
| `GameState.indice_escada` | int | vitórias da carreira = índice do próximo adversário (0..4). 4 = escada completa |
| `GameState.cinturao` | bool | só é `true` com a escada completa |
| `GameState.tatica` | String | última tática (`aggressive` / `defensive` / `counter`); padrão `defensive` |
| `GameState.nivel_luva` | int | 0 = luva velha |
| `GameState.geradores_pagos` | Dictionary | `gen_paid_1 -> quantidade` (use `quantidade_gerador(id)`) |
| `GameState.tempo_jogo` | float | segundos de jogo da carreira |
| `GameState.permanente` | Dictionary | `{legacy_total, career_number, careers_finished, best_wins, belts_won}` |
| `GameState.fim` | Dictionary | tela de fim pendente (`{}` = nenhuma). Formato na seção 7 |
| `GameState.luta` | Dictionary | luta decidida e ainda não aplicada (`{}` = nenhuma). **Use `luta_atual()`** |
| `GameState.lutas` | FightData | definições: `adversarios`, `taticas`, `luvas`, `geradores_pagos`, `combate`, `carreira` |

Consultas simples: `numero_carreira()` (int), `legado_em_jogo()` (int, o pote, HUD), `escada_completa()`,
`proximo_adversario()` (Dictionary ou `{}`), `pode_lutar()`, `pode_aposentar()`, `tem_luta_pendente()`,
`tem_fim_pendente()`, `acoes_bloqueadas()` (`true` com luta pendente ou tela de fim: **clique, compras, loja e LUTAR ficam
recusados**; a UI deve também esconder/desabilitar).

Dicionário de adversário (`proximo_adversario()`, `lutas.adversarios[i]`, `lutas.adversario(id)`):
`{id, name, description, profile, entry, wins_line, loses_line, strength, agility, endurance, prize_money, prize_fame, belt}`.
Os atributos dele e os seus são **crus** (os que o jogador treinou); mostrar com `NumberFormat.fmt(v, TRUNCAR)`.

## 2. Sinais novos (todos em `GameState`)
| Sinal | Quando |
|---|---|
| `dinheiro_mudou(valor: float)` | prêmio, compra na loja, carga do save |
| `fama_mudou(valor: int)` | vitória, carga do save |
| `escada_mudou()` | escada, cinturão ou Legado em jogo mudaram (vitória, nova carreira, carga) |
| `tatica_mudou(tatica: String)` | `definir_tatica`, nova carreira, carga |
| `luva_mudou(nivel: int, sprite_suffix: String)` | compra de luva, nova carreira, carga. **Trocar cursor, mão da garagem e mão da luta pelo mesmo `sprite_suffix`** |
| `gerador_pago_mudou(gerador: String, quantidade: int)` | compra do Prof. Nelson |
| `luta_iniciada(luta: Dictionary)` | LUTAR apertado. Já está **salvo em disco**. Formato na seção 5 |
| `luta_resolvida(resumo: Dictionary)` | `concluir_luta()` ou `aposentar()` aplicou o resultado |
| `fim_de_carreira(fim: Dictionary)` | tela de fim criada (derrota ou aposentadoria) |
| `risco_proxima_mudou(adversario: String, rotulo: String)` | o risco do HUD mudou (`easy`/`even`/`hard`; `""` depois do cinturão) |
| `permanente_mudou()` | Legado total / recordes / número da carreira mudaram |
| `economia_mudou()` | também sai a cada compra da loja e a cada vitória (custos / `por_clique()` / produção mudaram) |
| `carreira_mudou()` | também sai em `nova_carreira()` e na carga do save: **redesenhar tudo** (garagem, HUD, sala, luva) |

## 3. Garagem, HUD e LOJA
| Função | Retorno / observação |
|---|---|
| `por_clique()` | agora `base x aparelho x luva`. `multiplicador_aparelho(id)` continua só do aparelho |
| `producao_total()` | inclui o gerador pago |
| `quantidade_gerador(id)`, `producao_gerador(id)`, `pessoas_desenhadas(id)` | aceitam também `gen_paid_1` |
| `custo_gerador_pago(id)` | float (em **dinheiro**, 3 dígitos). `INF` se o id não existe |
| `pode_comprar_gerador_pago(id)` / `comprar_gerador_pago(id)` | `false` (nada muda) sem dinheiro, id inexistente ou `acoes_bloqueadas()`. Preço sem saldo em `r2`, texto `shop_no_money` |
| `luva_equipada()` | `{id, level, name, sprite_suffix, click_multiplier, ...}`; nível 0 = `glove_old`, `sprite_suffix` `""` |
| `sufixo_luva()` | `""`, `"_glove_l1"` ou `"_glove_l2"` (os mesmos de `manifest.json` → `by_data_id.glove_lN.sprite_suffix`; um teste confere) |
| `proxima_luva()` | `{id, level, cost, click_multiplier, sprite_suffix, name, description}` ou `{}` se a linha acabou |
| `pode_comprar_luva()` / `comprar_luva()` | idem acima |
| `multiplicador_luva()` | float (1 com a luva velha) |
| `texto_efeito_loja(item)` | `"x2 POR CLIQUE"` (luva) ou `"+25/S"` (gerador) |
| `lutas.geradores_pagos[i]` | `{id, base_cost, growth, production, draw_thresholds, name, description, appears_as}` |
| `lutas.luvas[i]` | lista dos níveis 1..n; `lutas.luva_base` = nível 0 |

Cursor, mão da garagem (`fighter_*` + sufixo) e mão da luta (`fight_player_*` + sufixo) vêm todos de `sufixo_luva()`:
ouvir `luva_mudou` e `carreira_mudou`.

## 4. Prévia, tática e risco
| Função | Retorno |
|---|---|
| `previa()` | Dictionary (abaixo). Calcula as 3 táticas (~600 lutas, poucos ms). **Não muda nada no jogo** (critério 4). `{}` se a escada acabou |
| `definir_tatica(id)` | bool. Guarda como "última tática", emite `tatica_mudou` e recalcula o risco do HUD |
| `risco_tatica(id := "")` | `{label, chance}` da tática (padrão: a escolhida). Use ao trocar de tática na prévia (200 lutas) |
| `risco_proxima()` | `{adversario, rotulo, tatica}` do HUD (último cálculo) |
| `atualizar_risco_hud()` | recalcula agora e emite `risco_proxima_mudou` se mudou |

`previa()` devolve:
```
{ opponent: {adversário completo}, you: {strength, agility, endurance} (crus),
  tactic: id escolhido, risk: "easy"|"even"|"hard" (da tática escolhida),
  risks: { aggressive: {label, chance}, defensive: {...}, counter: {...} },
  lead: "strength"|"agility"|"endurance"|"" (destaque "ELE É MUITO MAIS ..."; texto = lead_<id>),
  stake_win: "SE VENCER: $50 + 10 FAMA" (já preenchido; para o 4º use texto stake_belt),
  stake_belt: bool (opponent.belt) }
```
- Rótulo -> texto `risk_easy` / `risk_even` / `risk_hard`; cor verde / amarelo / vermelho (da UI).
- **`chance` NÃO se mostra** (a porcentagem é um nó da Fase 4). Está lá só para testes e depuração.
- Textos fixos da janela: `preview_title`, `preview_him`, `preview_you`, `risk_label`, `tactic_label`, `stake_lose`,
  `time_rule`, `time_rule_tie` (EMPATE EXATO: FICA COM ELE), `fight_button`, `back_button`. Táticas: `lutas.taticas[i]`
  = `{id, name (botão), hint (dica de uma linha), ...}`.
- Risco no HUD ("PRÓXIMA: nome + risco"): o `GameState` recalcula sozinho **no máximo 1 vez por segundo e só se um atributo
  ou a tática mudou**. A UI só escuta `risco_proxima_mudou`. Texto: `hud_next_fight` com `{nome}`; depois do cinturão,
  `no_more_fights`.
- Sinais de custo: a prévia é ~600 lutas e o HUD ~200; ambos ficam em milissegundos (medido: 200 lutas = 3 ms).

## 5. A luta
**LUTAR** (`GameState.lutar()`):
1. Só funciona se `pode_lutar()`. Senão devolve `{}`.
2. Sorteia a semente com o RNG do jogo, **simula a luta inteira na hora**, grava `career.fight` e **salva** (um único
   arquivo). Só então emite `luta_iniciada(luta)` e devolve o mesmo Dictionary.
3. A UI **anima** a lista de eventos. Ao fim da animação chama `concluir_luta()`.

`luta_atual()` devolve o mesmo Dictionary a qualquer momento (recalculado da semente; é determinístico). Serve para
reabrir o jogo com a luta pendente: **pular a animação e chamar `concluir_luta()`** (ou animar de novo, à escolha da UI;
o resultado é o mesmo).

Formato da luta (`luta_iniciada`, `lutar()`, `luta_atual()`):
```
{ opponent: id, tactic: id, seed: int,
  player: {strength, agility, endurance},          # atributos crus no momento do LUTAR
  result: { win: bool, ko: bool, t_ko: float (-1 sem K.O.), t_end: float, round: int (0 sem K.O.),
            pct_player: 0..1, pct_opponent: 0..1 },
  life_max: { player, opponent },                  # vida máxima de cada um (para a barra)
  events: [ evento, ... ],                         # em ordem de tempo
  grogue: {} | { who: 0|1, from: t_ko, to: 5.0 }, # K.O. antes de 5 s: o caído fica em `tired` de from até to e então cai
  loser: -1 | 0 | 1,                               # quem cai (0 jogador, 1 adversário); -1 se foi por pontos
  intro_seconds: 1.5, outro_seconds: 1.5,
  screen_seconds: intro + t_end + outro,           # sempre entre 8.0 e 19.0
  counts: { player: {...}, opponent: {...} } }     # attacks, normal_attacks, hits, dodges, crits, damage, counters
```
Linha do tempo: `t = 0` começa depois dos `intro_seconds` (nomes + "LUTEM!"). Último instante da luta: `t_end`
(K.O.: queda em `t_end`, depois a pose de vitória; pontos: "TEMPO!" em 16.0). `round_n` do marcador: `floor(t / 6) + 1`
(`fight_round`). K.O. mostra `fight_ko`, fim por pontos `fight_points`/`fight_time`.

Evento (`who` = quem ataca, `target` = quem recebe; 0 = jogador, 1 = adversário):
| Campo | Valor |
|---|---|
| `t` | segundos desde o `t = 0` (o golpe **acerta** neste instante: comece a animação `hit_frame / fps` antes) |
| `who`, `target` | 0 ou 1 |
| `type` | `"hit"` \| `"crit"` \| `"dodge"` (cru, como no simulador) |
| `counter` | `true` se é contra-golpe (tática contra-ataque; sai 0.5 s depois da esquiva) |
| `kind` | **o que desenhar**: `"jab"` (golpe normal), `"crit"` (crítico que vale mais dano), `"counter"` (contra-golpe), `"dodge"` (esquiva). Crítico contra defensivo (que anula o crítico) vem como `"jab"` |
| `attack_anim` | animação de quem ataca: `"jab"` ou `"heavy"` (heavy em `crit` e `counter`). Em `dodge` quem ataca faz `jab` |
| `defender_anim` | de quem recebe: `"hit"`, `"block"` (jogador com a tática defensiva) ou `"dodge"` |
| `blocked` | `true` quando `defender_anim == "block"` |
| `damage` | dano do golpe (0 na esquiva). Número flutuante: ARREDONDAR; crítico (`kind == "crit"`) maior, em `r3`, com "!" (`fight_crit`) |
| `life_after` / `life_pct_after` | vida de quem recebeu depois do golpe (absoluta / 0..1 da vida máxima dele). Barra de vida |
| `round` | marcador de round do evento |
| `ko` | `true` só no último evento do K.O. |
Esquiva: texto `fight_dodge`; o "esquivou" é de `target`. Tremida leve em golpe forte (`crit`, `counter`), som de soco, traços de impacto:
a UI decide. Grogue: o caído para de atacar (já não há eventos dele) e fica em `tired` até `to`.

Mapeamento de arte (`manifest.json`, ações `fight_*`): `attack_anim` do atacante, `defender_anim` de quem leva, `tired` no
grogue, `ko` no caído, `victory` no vencedor (guarda em `block` enquanto o outro cambaleia).

**`concluir_luta()`** (fim da animação, ou luta pendente ao reabrir): aplica o resultado **uma vez** e salva num único save;
chamar de novo devolve `{}`.
- Vitória -> `{win: true, opponent, money, fame, legacy_gain, legacy_run, belt, next, next_name}`: dinheiro, fama e
  `indice_escada` sobem, cinturão se for o 4º. Textos `victory_title`, `victory_gain` (preencher com `preencher`),
  `victory_next`; cinturão: `belt_title`, `belt_line`, `belt_unlock`, `belt_hint`.
- Derrota -> `{win: false, fim: {...}}`: soma o Legado (50% do pote), recordes, cria `fim` e emite `fim_de_carreira`.
  A carreira fica **congelada** (nada produz, tempo parado) até `nova_carreira()`.
- Emite `luta_resolvida`.

**Motivo da derrota** (`motivo_da_luta()`): calculado dentro de `lutar()` (antes da animação; ~100-200 ms, só quando a luta
é derrota) e guardado em `luta.reason` (vai no save da luta). `motivo_da_luta()` só devolve esse valor (sem custo); em save antigo
sem `reason` ele calcula sob demanda. A UI não precisa chamar nada além disso.

## 6. Aposentar e nova carreira
| Função | Retorno |
|---|---|
| `previa_aposentar()` | `{pote, base, bonus, total, cinturao, zero}`. Texto: `retire_confirm_take` (`{n}` = total), `retire_confirm_bonus` (`{n}` = bonus, só se `cinturao`), `retire_confirm_zero` (se `zero`), `retire_confirm_lose`; botões `retire_yes` / `retire_no` |
| `legado_em_jogo()` / `legado_se_perder()` | int |
| `aposentar()` | Dictionary do `fim` (`kind: "retire"`) ou `{}` se `acoes_bloqueadas()`. Soma 100% do pote (+50% com cinturão) |
| `nova_carreira()` | bool. Só com `fim` pendente. Zera `career` (inclusive luva, tática, dinheiro, escada), `career_number += 1`, **mantém `permanent`**, salva e emite `carreira_mudou`. 1 clique |
Botão APOSENTAR só quando `pode_aposentar()` e a UI não tiver a prévia aberta.

## 7. Tela de fim (`GameState.fim`, sinal `fim_de_carreira`)
```
{ kind: "defeat"|"retire", career_number, legacy_gained, legacy_total (depois de somar),
  opponent: id|"", tactic, seed, player: {...}, result: {...}   (vazios na aposentadoria),
  reason: { kind: "luck"|"missing"|"far"|"far_plain", attribute: "strength"|"agility"|"endurance"|"" (vazio no azar),
            faltaram: float (-1 = não existe), far_n: int, who: "ko"|"points", round, model: 0|1, tip: 0..2,
            stat: {kind, n, k}, better_tactic: id|"" },   ({} na aposentadoria)
  stat.kind: life_taken | stronger (n 20-99) | stronger_x (n 2-9) | stronger_cap (n 10) | crits | dodged | points | luck_odds | luck_rare
  summary: { wins, belts, fame, money_earned, play_seconds } }
```
`GameState.textos_fim()` devolve as **frases prontas** (sentence case; a UI aplica `.to_upper()`):
`{title, who, reason, stat, tip, tip_tactic, support, tactic_name}` (vazias quando não se aplicam).
- `who`: `end_who_ko` com o round, ou `end_who_points`. `{nome}` = nome do adversário.
- **Pós-QA (design §16):** `reason.kind` decide a linha principal: `luck` = `reason_luck[seed % tamanho]` (dica `tip_luck`, nunca
  tip_tactic); `missing` = FALTARAM (abaixo); `far` = `reason_far` com `{n}` = `far_n`; `far_plain` = `reason_far_plain`. A estatística
  (`stat`) usa os textos `stat_stronger_x`, `stat_stronger_cap`, `stat_points`, `stat_luck_odds`, `stat_luck_rare` além dos antigos;
  singular correto ("1 GOLPE"). A UI só mostra `textos_fim()`; nada novo a ligar. Fim salvo antes da correção (sem `kind`) continua
  legível (estatística absurda vira vazia).
- **`reason` (linha principal): `FALTARAM {n} DE <atributo> ...`.** Vem dos modelos 1 e 2 de `reason_<atributo>` (índices 0 e 1 da
  lista em `ui_texts.json`), alternando por semente; `{n}` = "faltaram" (quanto a mais daquele atributo deixaria essa luta FÁCIL).
- **`stat` (segunda linha): estatística do registro da luta**, modelos 3 e 4 (índices 2 e 3): `ELE BATIA {n}% MAIS FORTE`,
  `ELE ESQUIVOU {n}% DOS SEUS GOLPES`, `ELE ACERTOU {n} CRÍTICOS. VOCÊ, {k}`, `ELE TIROU {n}% DA SUA VIDA EM {k} GOLPES`.
  *(O `fase3-design.md` §7 ainda chama a estatística de "modelo 1" e o "faltaram" de "modelo 2"; vale o texto novo do Roteirista:
  principal = "FALTARAM", alternativa = estatística.)* Se `faltaram` não existe (nem 16x o treino basta), a estatística vira a
  linha principal e `stat` fica vazio.
- `tip`: `tip_<atributo>` (variação pela semente). `tip_tactic`: só se outra tática tinha chance >= a usada + 25 pontos
  (`tactic_name` = nome da tática melhor); **nunca** substitui `tip`.
- `support`: `end_support_line` (derrota) ou `retire_line` / `retire_line_belt`. Título: `title` (`end_defeat_title` ou `retire_title`).
- Resumo: `sum_title` (`{n}` = `career_number`), `sum_wins`, `sum_belts`, `sum_fame`, `sum_money`, `sum_time` (`play_seconds`),
  `sum_legacy_gain` (`legacy_gained`), `sum_legacy_total` (`legacy_total`), `legacy_note`, botão `new_career_button`.
- `GameState.preencher(modelo, {chave: valor})` troca `{chave}`; valor em Array troca uma ocorrência por item, na ordem
  (ex.: `stake_win` tem dois `{n}`). `GameState.lista_ui(chave)` devolve listas de `ui_texts.json` (`reason_*`, `tip_*`).
- `NumberFormat.fmt(valor)` para todos os números; dinheiro `$`.

## 8. Ao abrir o jogo (obrigatório para a UI)
Depois de `carregado`/`carreira_mudou`:
1. `GameState.tem_fim_pendente()` -> mostrar a tela de fim (Legado já foi somado; não somar de novo).
2. senão `GameState.tem_luta_pendente()` -> `concluir_luta()` (pula a animação) e mostrar o resultado.
3. senão garagem normal. Prévia e confirmação de aposentar **não são salvas**: ao reabrir voltam para a garagem.
Enquanto 1 ou 2 forem verdade, `acoes_bloqueadas()` recusa clique e compra.

## 9. Save v3
`{"version": 3, "saved_at_unix", "state": {"career": {...Fase 2..., paid_generators, glove_level, money, fame, ladder_index, belt, tactic, play_seconds, money_earned, fight}, "permanent": {legacy_total, career_number, careers_finished, best_wins, belts_won}, "ending": null|{...}}}`.
Um arquivo só (`user://save.json`). Migração `v2 -> v3` em `SaveStore._migrar_2_para_3` (a carreira vira a Carreira 1; permanente zerado).
Momentos de salvar: LUTAR (grava a luta), `concluir_luta()` (vitória: prêmio; derrota: Legado + `ending`), `aposentar()`, `nova_carreira()`.
`career.fight` guarda `{opponent, tactic, seed, player, result}`; os eventos **não** são salvos (recalculados da semente).
Se `data/` mudar entre o LUTAR e a reabertura, vale o `result` salvo (a lista de eventos pode divergir; há um aviso no console).

## 10. Dados (`data/`) e testes
- `fights.json` (combate, táticas, risco, motivo), `opponents.json` (escada + textos), `shop.json` (Nelson, luvas, `sprite_suffix`),
  `career.json` (Legado). Campo inválido -> padrão + `push_warning`. Mudar um número e reabrir muda o jogo.
- `tests/test_fight_sim.gd` (fórmulas, determinismo, 10.000 lutas, grogue, empate, risco honesto, igualdade com o Python),
  `test_fight_game.gd` (fluxo no GameState), `test_fight_data.gd`, `test_migration.gd` (v2 -> v3).
- Casos de referência do Python: `python tools/sim/exportar_casos.py` regrava `tests/data/fase3_casos.json`
  (sorteios explícitos: mesma luta golpe a golpe no Godot e no Python).
- O recálculo de teste usa `GameState.risco_hud_ativo = false` para não gastar tempo.

## 11. Dúvidas / combinados para a UI
- "ELE TIROU {n}% ... EM {k} GOLPES" sai no singular errado com `k = 1` ("1 GOLPES"); texto do Roteirista, a UI pode tratar.
- `GameState.fim` / `luta` guardam números como floats vindos do JSON; use `int()` ao exibir inteiros.
