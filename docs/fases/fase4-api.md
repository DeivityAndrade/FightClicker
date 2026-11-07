# Fase 4 — API pública da lógica (contrato para a UI)

Dono: Programador. Complementa `fase3-api.md` (tudo de lá vale). Regra de sempre: a UI não soma nem sorteia nada;
chama as funções, escuta os sinais. Código: `scripts/game_state.gd` (autoload `GameState`), `scripts/fight_data.gd`,
`scripts/save_store.gd`. Dados: `data/skill_tree.json` (novo), bloco `metronome` em `data/shop.json`, `career.json`
(Legado x10), `opponents.json` (Dinho $800), textos novos em `data/ui_texts.json`. Design: `fase4-design.md`.

## 1. Árvore (só abre com a tela de fim pendente)
| Função / variável | Retorno |
|---|---|
| `arvore_aberta()` | `true` só com `fim` pendente (derrota ou aposentadoria). Fora disso nenhum botão deve levar à árvore |
| `legado_disponivel()` | int, Legado total que ainda dá para gastar |
| `arvore_nos()` | Array, na ordem do arquivo. Cada item: `{id, branch, branch_name, requires, requires_name, cost, name, description, effect_text (já com número, ex. "+100% TREINO POR CLIQUE"), icon, effect_type, effect_value, state, missing}` |
| `state` | `"owned"` (aprendido) / `"buyable"` (comprável) / `"missing"` (falta Legado; `missing` = quanto falta) / `"locked"` (pede `requires_name`) |
| `estado_no(id)` | o mesmo `state` de um nó (`""` se o id não existe) |
| `pode_comprar_no(id)` / `comprar_no(id)` | bool. `comprar_no` desconta o custo exato, grava o nó, atualiza `fim.legacy_total` e **salva na hora**. Recusa (nada muda, sem erro) sem tela de fim, nó comprado, anterior faltando ou sem Legado |
| `nos_comprados()` / `tem_no(id)` | ids em ordem de compra |
| `lutas.ramos` | `[{id, name}]` (CORPO, CARREIRA). `lutas.arvore` = nós brutos |
| `bonus_ativos()` | soma por tipo dos bônus da carreira em andamento |

Sinais: `arvore_mudou()` e `permanente_mudou()` a cada compra (a UI redesenha nós, Legado e preços). Textos fixos:
`tree_button`, `tree_title`, `tree_legacy {n}`, `tree_branch_body/career`, `tree_buy {n}`, `tree_owned`, `tree_missing {n}`,
`tree_locked {nome}`, `tree_new_career`. O botão "NOVA CARREIRA" da árvore chama `nova_carreira()` (1 clique).
Os bônus só valem a partir de `nova_carreira()`: depois de comprar, `por_clique()` etc. **não** mudam até lá.
Legado agora na escala x10 (pote = fama x 2 + 100 do cinturão).

## 2. Cartão "o que você trouxe" e resumo da garagem
| Função / sinal | Significado |
|---|---|
| `nova_carreira_iniciada(cartao)` | emitido **só** por `nova_carreira()` (não ao carregar o save). `cartao = {title, career, nodes:[{id,name,effect_text,icon}]}`; `{}` se não há nós (não mostrar nada) |
| `cartao_inicio()` | o mesmo dicionário, a qualquer hora |
| `resumo_legado()` | `{count, label ("LEGADO: 2 NÓS"), nodes:[...]}`. Com `count == 0` não mostrar o rótulo |
| `definir_modal(bool)` / `modal_aberto` | a UI deve chamar `definir_modal(true)` enquanto prévia, confirmação, vitória **ou o cartão** estiverem abertos (o Metrônomo pausa). O `Fluxo` já faz isso para as janelas dele; o **cartão novo precisa chamar também** |
Efeitos visíveis: `por_clique()` já inclui o bônus (número flutuante e painel); `producao_gerador()`/`producao_total()` incluem o
passivo; `texto_efeito_loja(item)` do Nelson já sai com o bônus; `texto_stake_win(opp)` = "SE VENCER: $75 (+50%) + 15 FAMA (+50%)".

## 3. Metrônomo (loja, dinheiro)
| Função / sinal | Retorno |
|---|---|
| `nivel_metronomo` | 0 = sem Metrônomo; 1..3. Vai no save (`career.metronome_level`), zera em NOVA CARREIRA (ou volta a 1 com Memória muscular) |
| `proximo_metronomo()` | `{id, level, cost, interval, name, description, appears_as}` ou `{}` (linha completa / sem Metrônomo) |
| `metronomo_atual()`, `intervalo_metronomo()`, `socos_por_segundo_metronomo()` | nível atual (`{}` se 0), segundos entre socos, socos/s (máx. 1,43) |
| `pode_comprar_metronomo()` / `comprar_metronomo()` | bool; paga em **dinheiro**, em ordem; bloqueado durante luta/tela de fim |
| `texto_efeito_metronomo(def)` | "1 SOCO A CADA 2.0 S" (passar `proximo_metronomo()`) |
| `metronomo_ativo()` | `true` se o tique está socando agora (nível > 0, sem luta, sem tela de fim, sem modal) |
| `metronomo_mudou(nivel)` | compra, nova carreira, carga do save. Prop da prateleira: some no 0, oscila no andamento de `intervalo_metronomo()` |
| `auto_socou(ganho, critico, aparelho, atributo, texto_critico)` | **um auto-soco** (mesmo caminho do clique: foco x luva x árvore, mesmo crítico, treino no saldo e no atributo). **Não** emite `clicou`: tratar com número menor/mais transparente, **sem tremer a tela**, som mais baixo, jab do rig com `sufixo_luva()` |
| `lutas.metronomo` | `{name, description, appears_as, levels:[...]}` para a linha da LOJA |
Tique: em `_process` (via `tick`), só acumula com o alvo livre, no máximo 3 socos por quadro, sem guardar socos do tempo parado.
`auto_socar()` é público para teste. `auto_socos_total` conta para QA.

## 4. Revanche e dica do verde
| Função | Significado |
|---|---|
| `algoz()` / `e_algoz(id)` | id do adversário da última derrota (`permanent.revenge_opponent`), `""` se aposentou/venceu ele |
| `previa()` ganhou | `revenge` (bool: mostrar `revenge_mark`), `wait_green` (bool: mostrar `preview_wait_green`; regra L1 da decisão D2), `stake_lose` (texto pronto, 50% ou o % real), `show_percent`, `percent` (int, arredondado para baixo), `percent_text` ("62%"), e `risks[t].percent` |
| `info_proxima()` | `{revenge, wait_green}` do próximo adversário, para o bloco PRÓXIMA do HUD (usa o último rótulo do HUD) |
| `esperar_verde(id, rotulo)` | a regra L1: algoz definido, adversário com índice na escada <= o do algoz, rótulo != "easy" |
| `concluir_luta()` (vitória) | resumo ganhou `revenge` (true uma vez, ao vencer o algoz; a marca some no mesmo save) e `revenge_line` ("DINHO PULGA NÃO ESPERAVA ESSA."), além de `money`/`fame` já com bônus |
| `textos_fim()` ganhou | `wait_green`: "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE" em toda derrota que não é azar; `""` no azar e na aposentadoria |
Textos: `revenge_mark`, `victory_revenge`, `victory_revenge_line {nome}`, `tip_wait_green`, `preview_wait_green`, `preview_percent {n}`,
`stake_bonus {n}`, `stake_lose_pct {n}`, `victory_gain` (agora "... LEGADO EM JOGO"). `legacy_note` **não deve mais aparecer** na tela de fim
(o Programador não removeu da `janela_fim.gd`; é tarefa da UI).

## 5. Valores com bônus (para exibir)
`por_clique()`, `producao_total()`, `premio_dinheiro(opp)`, `premio_fama(opp)` (inteiro), `parte_derrota()` (0.5 ou 0.75),
`legado_se_perder()`, `tem_previa_detalhada()`. Efeitos somam por tipo (nunca multiplicam entre nós).

## 6. Tempo morto (debug/QA)
`tempo_morto()` -> `{atual, maximo, total}` em segundos: garagem livre, próximo adversário perigoso na melhor das 3 táticas e nada da
loja (Nelson, luva, Metrônomo) cabe no dinheiro. Só anda com `risco_hud_ativo`. Zera em NOVA CARREIRA; não vai no save.
`menor_preco_loja()` expõe o preço usado.

## 7. Save v4
`version 4`. Novo: `career.metronome_level`, `permanent.skill_nodes` (ids em ordem de compra), `permanent.revenge_opponent`.
Migração `_migrar_3_para_4`: Legado e Legado do `ending` pendente x10 (constante `ESCALA_LEGADO_V4`), sem nós, sem marca, Metrônomo 0,
carreira intacta. Cadeia v0 -> v4 funciona. Na leitura: nó inexistente/repetido/sem o anterior é ignorado com aviso (Legado não devolvido);
algoz inexistente vira `""`; nível do Metrônomo recortado. Bônus recalculados de `skill_nodes` ao carregar e em NOVA CARREIRA (nunca somados de novo).
Salva na hora: compra de nó, compra de Metrônomo (via economia/autosave), derrota/aposentadoria (com a marca), vitória sobre o algoz, NOVA CARREIRA.

## 8. Dados (`data/`)
`skill_tree.json`: `branches`, `nodes[{id, branch, requires, cost, effect{type,value}, name, description, effect_text, icon}]`.
Tipos: `click_bonus`, `passive_bonus`, `money_bonus`, `fame_bonus`, `defeat_share_bonus`, `metronome_start`, `preview_percent`.
Nó inválido (tipo desconhecido, ramo inexistente, custo < 1) é ignorado com aviso; `requires` inválido ou ciclo vira `""`.
`shop.json.metronome.levels[{id, cost, interval, name, description, appears_as}]`: intervalo recortado a [0.667, 60] (<= 1,5 soco/s),
níveis precisam ficar mais rápidos. `{pct}` = round(100 x valor), `{n}` = valor.

## 9. Pendências de UI (não feitas pelo Programador)
Tela da árvore e botão ÁRVORE na tela de fim; cartão de início (chamar `definir_modal`); rótulo do resumo na garagem; prop e linha do Metrônomo
na LOJA; tratar `auto_socou`; marca/linha do verde na prévia e no PRÓXIMA; momento "REVANCHE!" na vitória; `wait_green` na tela de fim;
tirar `legacy_note`; porcentagem na prévia. Ajustes mínimos já feitos em `ui/`: `fluxo.gd` (`definir_modal`), `bloco_proxima.gd` (prêmio com bônus),
`painel_loja.gd` (produção do gerador com bônus).
