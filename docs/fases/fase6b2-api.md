# Fase 6b2: API para a UI (cara de lutador)

Dono: Programador. Base: `fase6b2-design.md`, `fase6b1-api.md`. Só lógica: nada de `ui/`, `assets/` nem do manifest foi tocado.
Mudou: `scripts/disciples_data.gd` (`DiscipulosData`), `scripts/game_state.gd`, `tests/test_fase6b2.gd` (novo), `tests/test_fase6b1.gd` (linha "campos da 6b2").
Save: continua **v12**, sem migração e sem campo novo. O save da 6b1 abre com os valores padrão.

## 1. Ligar as opções
`data/disciples.json` ainda tem as opções novas com `enabled: false`. Quando as camadas estiverem no manifest, troque para `true` (corte buzz/volume/bun, top tank/tee, todas as `top_color`, `headband band`, todas as `headband_color`, `socks on`). Nenhum código muda. Em teste: `gs.disciples.ligar_todas_as_opcoes()` liga tudo só em memória.

## 2. Sorteio (já pronto)
`disciples.sortear(rng, roster, nome_atual)`: pesos (`weight`) entre opções ligadas; calção diferente do último discípulo; corte+cabelo diferentes do último (1 novo sorteio do corte); `avoid_pairs` até `max_rerolls` (8) rodadas, sem travar. `disciples.par_feio(look)` diz se um look bate com um par (testes). A tela continua livre: `definir_rascunho` aceita qualquer combinação.

## 3. Cores do visual (troca de paleta)
`GameState.cores_visual(look = {})` / `disciples.cores(look)` devolve as **9 peças**: `{campo: {id, slots, colors (hex), tokens}}`.
- `skin`, `hair_color`, `shorts_color`, `top_color`, `headband_color`: cores da opção escolhida.
- `socks`: sem cor própria, copia da origem. `none` = pele `[shadow, base, base]`; `on` = calção `[dark, mid, band]`. Trocar o calção ou a pele troca o meião junto.
- `hair_style`, `top`, `headband`: só o `id` (`slots`, `colors`, `tokens` vazios): servem para escolher a camada.
- `top_color`/`headband_color` vêm sempre com a cor guardada; a UI só desenha a peça se `top != "none"` / `headband != "none"`.
- John (`visual_lutador()` vazio): `{}`.

## 4. Linhas da tela
`GameState.linhas_tela_criacao()` (rascunho atual) ou `disciples.linhas_tela(look)`: lista na ordem de `screen.rows`, cada uma `{field, label (chave de ui_texts), kind ("" | "colors" | "text"), chips, depends_on, coluna (1 cabeça | 2 corpo), apagada, opcoes (ids ligados)}`.
- `apagada` = o pai (`depends_on`) está em `none`: desenhe rótulo e chips em tom -2, a seta não faz nada, o valor fica guardado e volta ao ligar o pai.
- Linha `text`: a seta passa por `opcoes` em volta; texto da opção = `disc_opt_<campo>_<id>`.
- A linha `name` vem com `opcoes` vazio. Rótulos e textos novos são do Roteirista (design §3.3).

## 5. Segundo mentor
`GameState.segundo_mentor() -> Dictionary`: `{}` ou
`{nome, look (9 campos), ponto [x, y] (manifest layout.mentor_2_spot, hoje [150,262]), ponto_nome, pose "stand_bare", glove "none", facing "right"|"left" (virado ao saco; x < 320 = right), campaign}`.
- Regra: última entrada do roster com `kind == "disciple"` e `end` em `passed_ends` (defeat, retire, unknown). Look ausente = visual padrão.
- Só devolve algo na **garagem**, com o **John sentado** (`mentor_sentado()`), e **não** durante a `primeira_sucessao`. Durante a `chegada_discipulo` aparece (já é o novo último).
- Folha: `disciple_stand_bare` (facing right) ou `disciple_stand_bare_left`, com as camadas e paletas do `look`. Sem fala, sem gesto, sem clique, ordenado pelo y dos pés (`ponto.y`).
- `mentores_na_sala()` devolve até 2: `{id "first", spot "mentor_spot", pose "sit_rest"}` e `{id "second", spot "mentor_2_spot", pose, glove, facing, campaign, name, look}`.
- A troca acontece no RECEBER: o novo registro do roster é gravado no fim da campanha, então quem passou o posto já é o 2º mentor com a tela de criação aberta. Reconsulte em `sucessao_mudou` / `carreira_mudou`.
- `GameState.segundo_mentor_entrada()`: a entrada do roster sem as condições de sala (para a 6c).

## 6. Balanço
Nenhum arquivo de balanço mudou; o visual e o 2º mentor não são lidos pela economia (teste: duas campanhas iguais, uma com 2º mentor e outro visual, dão relógio, treino, ouro, dia e luta idênticos).

## 7. Dúvidas
- `segundo_mentor()` aplica as condições de sala (como pediu o Produtor); o design §7.2 o descrevia sem elas, por isso a versão pura ficou em `segundo_mentor_entrada()`.
- O `top_color` do JSON ainda não tem `red`; save editado à mão com `red` cai no padrão pela leitura tolerante.
