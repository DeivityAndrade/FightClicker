# Fase 5.3: contrato do GameState para a UI (calendário)

Autoload `GameState` (`scripts/game_state.gd`). Números em `data/career.json -> calendar` e `data/opponents.json -> prep_days`.

## Consultas
| Chamada | Retorno |
|---|---|
| `sala_ativa()` | **A única condição de tick.** Relógio, equipe, Metrônomo, assistido, clique, luva dourada (espera, visível, FRENESI), bolsa e Jiu-jitsu só andam com ela. Falso com: `fim`, `luta`, escolha da arte, `modal_aberto` ou dia da luta. Perder foco/minimizar NÃO desliga. |
| `calendario_ligado()` | false se `seconds_per_day` = 0 (jogo da 5.2: sem data, sem dia; HUD como antes) |
| `dia_campanha()` | int, começa em 1 |
| `dias_para_luta()` | int: dias que faltam (0 = é hoje); -1 sem calendário ou sem próxima luta |
| `no_dia_da_luta()` | true quando o relógio travou na data (e o adversário luta neste local) |
| `campanha_completa()` | true depois do Kid: HUD mostra `hud_campaign_complete`, sem relógio |
| `segundos_campanha`, `fight_day` | relógio e data (dia da campanha); `fight_day` = -1 sem próxima luta |
| `dica_aposentar()` | `{show, text, legacy, days}`: `show` com Faltam <= `retire_hint_days`, risco do HUD vermelho e pote > 0 (garagem e academia). Texto `retire_hint`. |
| `data.calendar` (`GameState.lutas.calendario`) | `seconds_per_day`, `warn_days`, `warn_sound_days`, `retire_hint_days`, `offline_stops_at_fight_day` |
| `GameState.lutas.adversarios[i].prep_days` | folga em dias |

## Como a UI avisa qual janela está aberta
`GameState.definir_modal(true)` ao abrir QUALQUER janela (prévia, confirmação de passar o posto, vitória/cinturão, cartão de início, futuras opções) e `definir_modal(false)` ao fechar. `Fluxo._abrir` já faz isso. A escolha da arte, a luta e a tela de fim já param a sala pelo estado do jogo (não precisam de chamada). Abas da LOJA/TREINO, painéis de atributos, dicas, toasts, caixa de equipamento, luva dourada visível e faixa de aviso NÃO são janela: não chamam nada.

## Sinais
| Sinal | Quando |
|---|---|
| `dia_mudou(dia)` | o relógio virou o dia |
| `aviso_data(dias)` | uma vez por data ao ficar `dias <= warn_days` (faixa) e uma vez ao ficar `dias <= warn_sound_days` (faixa + som; `dias <= warn_sound_days` diz qual é). Reabrir o jogo com Faltam <= 3 emite a faixa uma vez. Não dispara no dia nem se lutou antes. Cada verificação emite no máximo um aviso (reabrir com Faltam 1 emite só `1`); um tick grande que salta direto ao dia emite um aviso com `warn_sound_days` (1). |
| `dia_da_luta_chegou()` | o relógio travou na data (também ao reabrir um save que está no dia): abrir a **prévia do dia**, sem X/Esc, só LUTAR e PASSAR O POSTO |
| `campanha_completa_mudou()` | venceu o Kid; também em carga de save/nova campanha (consultar `campanha_completa()`) |
| `sala_ativa_mudou(ativa)` | a condição única mudou (a UI pode esconder o relógio/atenuar) |

## Luta em outro local (B3)
- Enquanto `estado_escada() == "move"` (ex.: Tonhão com o jogador na garagem) o relógio da campanha **não conta**: a data não se aproxima e o dia da luta não chega.
- `mudar()` para o local da luta recalcula `fight_day = dia_atual + prep_days(próximo)` (folga cheia a partir da chegada).

## No dia da luta
- `lutar()` e `aposentar()` funcionam; `clicar()`, compras (`comprar_*`, `bater_caixa`, `mudar`) e Metrônomo estão bloqueados (`acoes_bloqueadas()` é true no dia). A LOJA deve fechar.
- **Passar o posto = `aposentar()`** (100% do Legado + bônus do cinturão; `previa_aposentar()` alimenta a confirmação). Cancelar a confirmação volta para a prévia do dia.
- Após `concluir_luta()` vitorioso: `fight_day = dia + prep_days(próximo)` (resumo traz `fight_day`); depois do Kid, -1.
- A janela do jogo sem foco: use `DisplayServer.window_request_attention()` ao receber `aviso_data` de 1 dia e `dia_da_luta_chegou` (UI).

## Textos (`ui_texts.json`)
`hud_fight_date` ({n}), `hud_fight_date_one`, `hud_fight_today`, `hud_campaign_day`, `hud_campaign_complete`, `warn_3_days`/`warn_1_day` ({nome}), `retire_hint` ({n}), `enrolled_toast` ({nome},{n}), `fight_day_title/line/fight/pass`, `retire_*`, `end_title_campaign`, `sum_days`. O nome do adversário vem de `proximo_adversario().name`.

## Retrato do jogador por luva
`assets/sprites/manifest.json -> by_data_id.player_portrait`: `{base: "portrait_player", by_glove: {glove_old: "portrait_player", glove_l1: "portrait_player_glove_l1", ...}}`.
Na prática: `"portrait_player" + GameState.sufixo_luva()` (o sufixo é `""` para a luva velha e `_glove_l1`... para as outras; sinal `luva_mudou(nivel, sprite_suffix)`). Use a chave do manifesto para achar o arquivo.

## Save v9
`career.campaign_seconds` (float) e `career.fight_day` (int). Migração v8 -> v9: Dia 1 com folga cheia (a migração grava `fight_day = 0` = recalcular; o GameState põe `1 + prep_days` do próximo adversário, ou -1 com a escada completa). `fight_day` inválido recalcula do dia atual.

## Observações
- Luta em outro local (Tonhão com o jogador na garagem): ver a seção "Luta em outro local (B3)". O relógio não conta essa data, e ela é recalculada com a folga cheia ao chegar ao novo local.
- `gym_retire_hint_seconds` não é mais lido.
