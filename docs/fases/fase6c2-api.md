# Fase 6c2 (Mais longe que eu): contrato para a interface

Lógica em `scripts/game_state.gd` (autoload `GameState`), `scripts/save_store.gd` (v13) e `scripts/dialogos_data.gd`.
Dados: `data/hall.json` (Honra, retrato, nós), `data/escola.json` (`mural`, `mentor_lines`, `mentor_voice`, `school_symbol`),
`data/dialogos.json` (`mentor_won`, falas `ml_*`) e `data/ui_texts.json`. Testes: `tests/test_fase6c2.gd`.

## 1. Honra
- Só por saída voluntária (APOSENTAR e PASSAR O POSTO no dia da luta) com 1+ vitória. Derrota e 0 vitórias dão 0. Nunca multiplicada.
- `honra() -> int` saldo; `honra_total() -> int`; `honra_da_saida(wins, belt) -> int` (a fórmula: 0, 1, 3, 6, 15 com cinturão, 20, 27).
- `previa_aposentar()` ganhou `honor` (a Honra desta saída) e `wins`. Com `honor == 0` e `wins == 0`: mostrar `retire_no_honor`.
- `fim.honor_gained` (int) na tela de fim. Mostrar "+N HONRA" só em `kind == "retire"`; derrota: nada sobre Honra. Retire com 0: `retire_no_honor`.
- Sinal `honra_mudou(honor)` (fim por vontade, compra, carga do save). Nunca aparece no HUD da sala.

## 2. Hall (6 nós, lista fixa no MURAL)
- `hall_lista() -> [{id, name, cost, effect_text, state, missing}]`. Nome e descrição vêm de `ui_texts` (`hall_<id>_name`, `hall_<id>_desc`).
  `state`: `owned`, `buyable` (tela de fim pendente e Honra basta), `missing` (faltam `missing` de Honra), `closed` (sem tela de fim: só consulta; usar `hall_buy_only_end`).
- `pode_comprar_hall(id)` e `comprar_hall(id) -> bool`: só com `fim` pendente, sem reembolso, desconta a Honra exata, um `salvar()`. Emite `honra_mudou` e `hall_mudou`.
- `tem_no_hall(id)`. Sinal `hall_mudou()`.
- Efeitos (valem da campanha seguinte): `hall_box` caixa com 2 cliques; `hall_fund` começa com 500 de saldo de Treino (não soma em atributo);
  `hall_notes` linha na prévia; `hall_crew` equipe x1,10; `hall_glove` começa com a luva de lona já aberta (sem caixa, sem gesto, sem `glove_new`); `hall_wall` teto do retrato 8.
- **Cliques da caixa:** use `GameState.cliques_para_abrir()` (não `dados.box_clicks_to_open`). `ui/sala.gd:1285` ainda lê `dados.box_clicks_to_open` na dica "caixa fechada": trocar.
- Prévia: `previa().missing_line` é `""` até o cálculo (segundo plano) ficar pronto; aí vem o sinal `previa_falta_pronta(texto)` ("FALTA ~N DE ATRIBUTO", chave `preview_missing_line`).
  Só aparece com o nó, fora do verde, e só quando dá para dizer o número (se nem 16x o total basta, fica vazia). A UI mostra a linha quando `texto != ""`.

## 3. Bônus do retrato
- `retratos_com_selo()`, `teto_retratos()` (5, ou 8 com `hall_wall`), `mult_escola()` (1 + 0,02 x min(selos, teto)). Já está dentro de `por_clique()`, `por_auto_soco()` e `producao_total()`; a UI não multiplica nada.
- Cartão de início `start_card_mural`: usar `mural().bonus_pct` (> 0).

## 4. Mural
- `mural() -> {entries, honor, sealed, counted, cap, bonus_pct, bonus_line, columns, rows_per_page}`. `entries` na ordem do roster (o John primeiro); a campanha em andamento não entra.
  Cada entrada: `campaign, kind, name, look (null no John), art, wins, belt, end, end_key, end_text, opponent, opponent_name, sealed, honor, symbol, extra_key, career_text, wins_text, art_text`.
  `wins_text` já vem "?" para `wins == -1`. `extra_key` = `mural_first_left` no John depois da saída dele (texto provisório, ainda pendente dos testadores).
  Textos prontos já preenchidos (`end_text`, etc.); `bonus_line` usa `mural_bonus_line`.
- `mural_na_sala() -> {spot [x, y] ou [], spot_name, object_text}`; `{}` onde não aparece (academia sem o marco `cena_primeira_academia`). `spot` vem vazio até o Diretor de Arte pôr `mural_spot` / `gym_mural_spot` no manifest. Hover: `objects.mural`.
- Abre a qualquer hora em que a sala está ativa; o hall só compra com a tela de fim (o botão MURAL da tela de fim abre a mesma janela).

## 5. Falas dos mentores
- Só o mentor sentado no caixote (`mentor_do_caixote() -> {id "first"|"last", name, campaign, kind "first"|"disciple"}`, `{}` sem ninguém).
- Pedido na vitória: `concluir_luta()` devolve `resumo.mentor_line` (`{}` ou `{line "revanche"|"recorde"|"mais_longe", mentor_kind, own, adversario, mentor}`); se não vazio, o Osmar não comenta aquela vitória (`fight_won` não é disparado).
  Ordem revanche > recorde > mais_longe, no máximo uma; tetos: 1 por campanha em `revanche` e 1 em `marca` (recorde e mais_longe dividem). Só gasta o teto quando a fala toca. Só pede se existe fala escrita para o caso.
- O balão sai pelo `fala_pedida(speaker, text, id)` com `speaker == "first"` (o John, voz `first`) ou `"last"` (discípulo no caixote). Os marcadores `{adversario}` e `{mentor}` já vêm preenchidos (minúsculos).
  `speaker "mentor"` em `dialogos.json` nunca chega à UI.
- Voz do discípulo: `voz_do_mentor(kind, campanha) -> {base_hz, cps, vowel_order, vowel_steps}` (200 Hz + 14 x passo da campanha, 26 letras/s). O balão do `last` deve usar essa voz.
- Condições novas em `dialogos.json`: `mentor_line`, `mentor_kind`, `own` (validadas por `DialogosData`).

## 6. Símbolo da escola
- `simbolo_no_lutador() -> bool` (lutador atual), `simbolo_na_entrada(entrada) -> bool` (retratos e mentores: passe `{kind, campaign}`; o mentor sentado/em pé usa a campanha dele; o John nunca), `campanha_do_simbolo() -> int` (0 = nenhuma).
- Nada vai para o save. O lugar do símbolo (`peito`/`perna do calção`) está em `escola.json > school_symbol`.

## 7. Save v13
- `school.honor`, `school.honor_total`, `school.hall_nodes`, `roster[].honor`, `ending.honor_gained`. Migração `_migrar_12_para_13` com constantes congeladas (`HONRA_*_V13` em `SaveStore`).
  Honra retroativa só para `end == "retire"`; `wins -1` = 1; `honor_total = honor = soma`; `hall_nodes = []`.
- Quem tem v13 e abre num build v12: bloqueado como versão mais nova (como sempre).
- Testes antigos que checavam "versão 12" passaram a esperar 13.
