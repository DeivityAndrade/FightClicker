# Fase 5.4: contrato da UI (árvore grande)

Tudo em `GameState` (autoload). Dados em `data/skill_tree.json` v2. A UI não calcula nada: só lê e chama.

## Regras
- Estado de nó: `owned` (comprado), `visible` (raiz ou vizinho de comprado, trava aberta), `hidden`. Não vai para o save.
- Travas (`lock`): `""` sempre; `"gym"` quando há arte liberada (um discípulo chegou à academia); `"art:<id>"` quando a arte está liberada. Trava fechada = `hidden`, mesmo ao lado de nó comprado.
- Compra a qualquer hora, menos: na luta, no dia da luta, na escolha da arte e com caixa já batida (`pode_abrir_arvore()`). Com a tela de fim pendente sempre abre.
- A compra entra em `permanente.skill_nodes` na hora, mas os efeitos vêm de `career.active_nodes` (foto tirada na NOVA CAMPANHA). Nó comprado e fora da foto: etiqueta "VALE NA PRÓXIMA CAMPANHA" (`next_campaign`).
- Nó com `requires_art` só vale jogando aquela arte (qualquer tipo de efeito).

## Funções
| Função | Devolve |
|---|---|
| `pode_abrir_arvore() -> bool` | o mapa pode abrir/comprar agora (`arvore_aberta()` é igual, por compatibilidade) |
| `ha_no_compravel() -> bool` | existe nó `visible` com custo <= Legado (brilho do botão; não olha se o mapa abre) |
| `nos_compraveis() -> int` | quantos nós assim ("{n} NÓS PARA COMPRAR": chaves `map_button_tip_*`) |
| `arvore_mapa() -> Array` | todos os 39 nós (ver abaixo); a UI desenha só os que não são `hidden` |
| `arvore_mapa_info() -> Dictionary` | `{unit_px, regions:[{id,name,icon,lock,open}], last_node, legacy, open, can_buy_count}` |
| `estado_mapa(id) -> String` | `owned` / `visible` / `hidden` / `""` |
| `pode_comprar_no(id)` / `pode_pagar_no(id)` | com / sem olhar `pode_abrir_arvore()` |
| `comprar_no(id) -> bool` | desconta Legado, grava, salva, emite sinais, `permanente.tree_last_node = id` |
| `nos_ativos() -> Array` | ids da foto da campanha |
| `crew_share_efetivo() -> float` | segundos da equipe por clique com o Grito (loja + "Grito mais alto") |
| `estado_no(id)` | **antigo** (abas): owned/buyable/missing/locked; mantido para a UI da 5.3 |

Item de `arvore_mapa()`: `id, region, region_name, kind (small|milestone|link), pos (Vector2, unidades da grade; x pixel = pos * unit_px), root, neighbors, lock, requires_art, cost, name, description, effect_text (já com número; Grito mostra "0,5"), icon, effect_type, effect_value, effect_target, state, can_buy, affordable, missing (Legado que falta, só em visible), active, next_campaign, needs_shout (link_shout sem o Grito da loja: mostrar `map_needs_shout`), art_only_text`.
- Linha entre dois nós: só quando os dois não são `hidden`.
- Plaquinha de região (`regions[].name`, texto `map_region_*`): aparece quando o 1º nó da região fica `visible`/`owned`. A região leste agora se chama **AGENDA** (id `campaign`); o ramo do centro segue CAMPANHA.
- Abrir centralizado em `last_node` (vazio: (0,0)).

## Sinais
- `arvore_mudou()` (compra), `permanente_mudou()` (Legado), **`no_revelado(ids: Array)`** com os nós que ficaram à vista na compra (animar). A tela de fim ganha `fim.legacy_notebook` (Legado vindo do "Caderno do velho"; 0 sem o nó) e `previa_aposentar().notebook`.

## Ícones
Ordem (manifest `skill_map`): `icon_by_node[id]` -> `icon_by_effect[effect_type]` (objeto: pela `requires_art`) -> campo `icon` do nó. Os 6 marcos da 2ª passada já têm `icon` próprio no JSON (`skill_home_metronome`, `skill_crew_regulars`, `skill_coach_notebook`, `skill_standing_fan`, `skill_counter_punch`, `skill_firm_base`).

## Efeitos novos (lidos de `active_nodes`)
`rope_installed` (corda montada, sem caixa), `start_generator` (value n, target gerador), `metronome_start` (máximo), `prep_days_bonus` (soma, em toda data), `crew_click_bonus` (só com o Grito da loja), `gym_training_bonus` (multiplica o x2 da academia), `art_fight_bonus` (Boxe: dano x(1+v); Jiu-jitsu: recebido x(1-v)), `legacy_bonus` (Legado ganho = floor(base x (1+v)) em qualquer fim).

## Save v10
`career.active_nodes` e `permanent.tree_last_node`. Migração v9: nós e Legado iguais, `active_nodes = skill_nodes`, `tree_last_node` = último nó (ou ""). Sem reembolso. Ids desconhecidos em `skill_nodes` continuam sendo descartados com aviso (como na 4).
