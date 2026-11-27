# Ronda 2a2 (o chefe Apagão): relatório do QA

QA, 2026-11-26. Branch `ronda-2a2` (HEAD e2700b9, base `origin/main` b5cc359). Critérios: `ronda2a2-design.md` §9 (B1–B16).
Todas as rodadas usaram APPDATA temporário (scratchpad), nunca o save real. Um Godot por vez; o `ui_audit` com janela rodou uma vez
(`--position 1950,40 --max-fps 30`), mais um reteste de 2 estados para diagnóstico.

## Veredito
**Aprovado para o Diretor revisar.** Nenhum bug de gravidade média ou alta. Todos os critérios com evidência de execução estão OK.
Os achados são 1 bug baixo de UI/UX (estado de teste da captura do prêmio), 2 pontos baixos já existentes na 2a1 e 3 observações.
Uma ressalva: o placar de `ignore` da rodada completa é 26 (veja B14).

## Tabela B1–B16
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| B1 | Foto idêntica à da main | **OK** | `foto.gd` rodado na `origin/main` (cópia via `git archive` + `--import`) e no branch: SHA-256 `D5653653245186743D81F11DC049125BBC1AD43F9C83946333F53FC12201DB99` nos dois (302 750 bytes) |
| B2 | Mesma campanha só com SUSTO x com chefe: save igual fora de `black_cat` e capuz | **OK** | `test_ronda2a2.gd` `_teste_chefe_igual` (save igual campo a campo e os 5 estados de sorteio iguais; rascunho da sucessão igual com `live_wire` liberado). No roteiro real (`tests/qa_ronda2a2_e2e.gd`), o diff do save depois da derrota e depois da vitória só tem `permanent.black_cat`, `career.black_cat_hood` e o que é do relógio (`play_seconds`, `training_invite.room_s`, fala da sala) e os atributos que o próprio roteiro troca. Nenhum `school.milestones` novo (`black_cat_rumor_heard`, `prologue_seen`, `regional_league_opened` antes e depois) |
| B3 | Teto ≤ 10% (esperado 8,8%) | **OK** | `ronda2a_sim.py teto` (Blender Python `-I`, `SIM_NF=24`, `SIM_THANKS=0.25`, 24 jogadores). `tudo_max` (+20%): pior trecho **8,8%** (Boxe Contragolpista 4/s, CENTRO cheio); próximo 8,7% (JJ Finalização 3/s). Variante +25%: **9,2%** (JJ Finalização 3/s, CENTRO cheio). Bate com o design §7. Saída `scratchpad\teto_a.log` |
| B4 | Perder do chefe: nada some, lenda +1 (+1 com SUSTO), capuz volta em 300 s, REVANCHE | **OK** | Roteiro: lenda 64 -> 65 sem SUSTO (aproximação natural "time"), `rounds` 12 -> 13, `boss.apagao {won 0, lost 1}`, capuz `hood_s 180 / next_at 480` (= +300), `revenge: true` no cartão, `trophies` todos vazios. Com SUSTO: +2 (teste do time). Carreira, Legado, FAMA, dias e AQUECIDO iguais (diff acima) |
| B5 | Destrave (a)–(d) | **OK** | Roteiro com 4 saves: (a) lenda 63: "PRECISA DA LENDA 5"; (b) 2 bandidos: ficha "VENÇA OS 3 DO BECO" (o 2º cartão do quadro é o próximo bandido, como no §2.1); (c) sem cinturão: "PRECISA DO CINTURÃO DO VALE"; (d) tudo: cartão com IR. Em (a)–(c) `ronda_ir("alley","apagao")` devolve `{}`. Capturas `r2b_esc_trancado_lenda/bandidos/cinturao` conferem |
| B6 | Prévia = motor; casos do simulador; desafio ≤ 20% | **OK (parte)** | Prévia e casos de `tests/data/ronda2a_casos.json` passam em `test_ronda2a2.gd`/`test_ronda2a.gd`. Sem SUSTO a prévia mostra "DESAFIO: PERDIDO" (roteiro: `challenge.lost true`; captura `r2b_previa_perdido`). **A secção `ronda2a_sim.py chefe` (12 x 14 por linha) não foi reexecutada**; as metas 34% / campanha 11 / 4% / 13% são as do design |
| B7 | Apagão só visual | **OK** | Varredura de 108 lutas (36 escalas de 0,03x a 10 000x do Apagão x 3 táticas): com apagão 13, sem 95; **0 violações** da regra "apagão só se `t_end` > 10,667 s"; **0** vitórias por K.O. até o round 2 com apagão. `t_apagao = 2 x 5,3333 = 10,6666`. Mesmos eventos/resultado com a mesma semente (teste do time). No roteiro, a vitória com desafio vem com `blackout = {}` |
| B8 | Noite inteira ≤ ~60 s; SAIR não gasta o capuz | **OK (por conta)** | Contagem 2 s + aproximação 8 s + entrada 1,5 s + luta ≤ 16 s (`time_limit` 16 em `fights.json`) + prêmio ~4 s = ~32 s mais o tempo de decidir na prévia. SAIR na aproximação: capuz fica no prego, nada gravado (`test_ronda2a2.gd`). Não cronometrei uma noite animada de verdade |
| B9 | Letreiro, K.O., sem sangue, sem rosto/nome, ??? até vencer | **OK** | Busca de sangue/blood em `data/ scripts/ ui/ scenes/`: só o comentário "sem sangue" em `ui/tela_luta.gd:1714`. Roteiro: antes de vencer, quadro, Esconderijo e Dossiê não contêm "NÉLSON/NELSON"; nome e apelido da ficha "???", textos vazios; a luta devolve `fighter_name "???"`; ocorrência "O DA CAIXA DE LUZ". Capturas: silhueta no cartão, na ficha e na prévia. Veja a observação O1 |
| B10 | Busca batman/morcego/gotham = 0; dono aprovou a amostra | **OK** | Busca em `data/ scripts/ ui/ scenes/` = 0 (só comentários de arte "não de morcego" em `tools/art/make_*.gd`, de antes). A aprovação da amostra/arena não é verificável pelo QA: o escopo (`ronda2a-escopo.md` linha 195) registra a escolha do dono pelo Apagão v2 e o design registra o FIO DESENCAPADO como escolha do dono |
| B11 | Vitória (ficha, capacete, título, cartaz) e desafio (raro no mesmo lugar, estilo) | **OK** | Roteiro: vitória sem desafio -> `trophy_new "normal"`, `press_title_new`, `poster_new`, `dossier_new`, sem estilo (`live_wire` fora da lista de cor do calção). 2ª vitória cumprindo -> `trophy_new "rare"`, `style_unlocked live_wire`, `challenge_done`, `legend_gain 4`; prateleira com 1 capacete `rare` no lugar 1; `live_wire` é o último da lista do calção. Disco depois de 3 noites: `boss.apagao {won 2, lost 1, challenge true, first_win_campaign 9}`. Cartaz do menu só com vitória. Capturas `r2b_esc_vencido`, `r2b_esc_raro`, `r2b_menu_cartaz`, `r2b_personalizacao` (calção amarelo com cós preto e o gato dourado) |
| B12 | Save: fechar na aproximação/prévia = nada; na luta/prêmio = 1 vez; saves sujos; cópia do save do dono | **OK** | `test_ronda2a2.gd` `_teste_save` (aproximação, prévia, luta, reabrir sem duplicar, saves sujos: número ruim, gigante, id desconhecido, `challenge` sem vitória, sem requisitos, formato errado, sem o campo). Roteiro: derrota e vitórias persistem ao reabrir do disco. O save real do dono não foi aberto por QA |
| B13 | `tools/run_tests.ps1` verde | **OK** | "TODOS OS TESTES PASSARAM"; `test_ronda2a2.gd` 144/144; `test_ronda.gd` 178/178; `test_ronda2a.gd` 477/477. Os stack traces no log são `push_warning` de dados ruins plantados de propósito, não falhas |
| B14 | `ui_audit --estrito` 0 problemas; `ignore` ≤ 15; telas novas sem `ignore` | **OK, com ressalva** | Rodada completa `--estados todos --estrito`: 610 estados, `ESTRITO 0 achados`, `PROBLEMAS 2`, ambos fora das telas da 2a2 e instáveis (veja BUG-3). Os 18 estados `r2b_*`, os `r2a_*` e os `ronda_capuz_*` sem problema; a 2a2 não acrescentou nenhum `ignore` (`git diff` só tem `MOUSE_FILTER_IGNORE`). **Placar de ignore da rodada completa: 26 (meta ≤ 15)**, todos com motivo, vindos de telas antigas; nenhum de arquivo novo da 2a2. Na rodada só dos estados novos o placar é 8 |
| B15 | Capuz a 300 s | **OK** | `test_ronda2a2.gd` `_teste_capuz_300`: 1º aos 180 s; seguinte = `hood_s` da volta + 300; relógio parado fora da sala; não acumula; chefe usa o mesmo intervalo; save com `next_at 740` carrega e vale (o capuz volta 240 s depois) e o seguinte usa 300. Roteiro: `next_at 480 = 180 + 300` |
| B16 | Limiares 1/10/24/42/64; save com lenda 25; capuz + convite do Osmar | **OK** | `_teste_limiares`: `nivel_de()` bate com `ronda_casos.json`; lenda 24 = nível 3, 64 = nível 5; lenda 25 carrega no nível 3 e a subida aparece uma vez no próximo prêmio da Ronda e não repete. Captura `r2b_capuz_convite`: balão do Osmar com IR e o capuz na parede, sem encobrir nada. "PRECISA DA LENDA {n}" cabe nas fichas dos bandidos (`r2a_esc_travado`: "PRECISA DA LENDA 3" nos três) |

## Ponta a ponta com save em disco (pedido 1)
`tests/qa_ronda2a2_e2e.gd` (36/36). Save de teste com lenda 64, 3 bandidos vencidos e cinturão do Vale, gravado e reaberto do disco.
1. Quadro: cartão do chefe aberto, nome "???".
2. `ronda_ir("alley","apagao")` com aproximação natural, sem clicar: resultado "time". A prévia mostra o desafio perdido.
3. Derrota: `legend_gain 1`, `level 5`, `legend 65`, REVANCHE.
4. Reabrir do disco e esperar o capuz: volta com +300 s.
5. Vitória sem desafio: lenda 68 (+3), capacete normal, título da imprensa e cartaz.
6. Vitória com SUSTO e K.O. no 1º round: lenda 72 (+4), capacete raro, `live_wire`, sem apagão.
7. Reabrir do disco: `won 2, lost 1, challenge true, first_win_campaign 9`.

## Ponto 2 (captura `r2b_premio_raro`: "+4 LENDA" e "LENDA 3")
Só o estado de teste. `tools/ui/audit/estados_ronda2a.gd:348` (`_premio_base`) fixa `level 3` e `legend 36`, e `estados_ronda2a2.gd:259` só troca o ganho para 4. O prêmio real sai com o nível certo: `night_prize.level = 5` e `max_level true` em todas as noites do roteiro (lenda 65, 68 e 72). Isso é o BUG-1 abaixo.

## Bugs e observações
| ID | Gravidade | Descrição | Quem corrige |
|---|---|---|---|
| BUG-1 | Baixa | O estado de captura `r2b_premio_normal` e `r2b_premio_raro` mostra "LENDA 3" com as bolinhas em 3 de 5 e "+4 LENDA", um prêmio impossível (o chefe só abre no nível 5). O prêmio real está certo. `_premio()` em `tools/ui/audit/estados_ronda2a2.gd` deveria fixar `level 5`, `level_before 5`, `max_level true`, `legend` 68 | UI/UX |
| BUG-2 | Baixa, de antes (2a1) | No Dossiê, o bandido que já pode ser enfrentado, mas ainda não foi vencido, mostra "???" com o cadeado e **sem texto** (capturas `r2a_dossie_meio`, "Fio", e `r2b_esc_trancado_bandidos`, "Seu Pé de Cabra"). Não é regressão da 2a2 | UI/UX (opcional) |
| BUG-3 | Baixa, instável | A rodada completa acusou `f6b1_s8` ("balão deveria estar na tela") e `f8a1_luta_guarda_clink` (SUBPIXEL, barra animada 21,47 px). Nenhum é estado da 2a2. Reteste dos dois: na `origin/main` o SUBPIXEL reproduziu (`tam=6.11`) e no branch deu 0 problemas. É dependente de tempo/fps, não regressão. Convém o UI/UX deixar o estado determinístico (esperar o fim da animação) | UI/UX |
| O1 | Observação | O letreiro "O APAGÃO" e o texto do desafio "ANTES DO APAGÃO" mostram o **apelido** antes de o chefe ser vencido. O design prescreve esses textos e o nome real (NÉLSON VOLT) fica oculto. Aceito pelo Produtor | — |
| O2 | Observação | Na luta, o Apagão aparece desenhado em cores (capacete, luvas, bateria) antes de vencer. Só o retrato, o cartão e a prévia são silhueta. O design limita o "??? e silhueta" a esses lugares; vale o Diretor de Arte confirmar | Diretor de Arte |
| O3 | Observação | `ronda2a_sim.py chefe` e a cronometragem de uma noite animada de verdade não foram refeitos; ficam confiados ao design e ao teste de previa/casos | — |

## Riscos
- **Teto com margem curta:** 8,8% x 10% (9,2% se o "Bairro agradece" voltar a +25%). Qualquer mudança da 8b em equipe, Legado ou região exige repetir `ronda2a_sim.py teto`.
- **Placar de `ignore` 26 na rodada completa** x meta 15. Vem de telas antigas, mas o critério B14 fala do placar. O Diretor decide se a meta vale para a rodada completa ou só para as telas novas.
- Os 2 problemas instáveis do `ui_audit` completo (BUG-3) podem reaparecer e confundir a próxima fase.

## Arquivos do QA
- `tests/qa_ronda2a2_e2e.gd` (e `.gd.uid`): ferramenta de QA, deixada no worktree sem commit. **Recomendo virar teste da suíte** (renomear para `tests/test_ronda2a2_e2e.gd`, porque o `run_tests.ps1` só pega `test_*.gd`). Ela cobre o que o `test_ronda2a2.gd` não cobre: aproximação natural, save reaberto do disco entre noites, varredura de 108 lutas para o B7 e os 4 casos do B5 pelo Esconderijo. Antes disso, os `print` de depuração devem sair e o ramo da sucessão deve ser removido: `receber_discipulo()` devolveu `false` ali e o resultado não é verificado.
- Logs no scratchpad: `run_tests.log`, `teto_a.log`, `e2e.log`, `audit.log`, `audit2_main.log`, `audit2_2a2.log`, `foto_main.txt`, `foto_2a2.txt`. Capturas: `scratchpad\capt\`.
- Higiene do worktree: 3 081 `.import` e `project.godot` só com fim de linha foram restaurados com `git restore`. Sobram sem commit os `.uid` gerados pelo Godot e os dois arquivos do QA.

## Correções do Produtor depois do QA (2026-11-26)
- **BUG-1:** os estados `r2b_premio_*` passaram para a lenda 68, nível 5 e `max_level`.
- **Bug real achado na reconferência:** no nível 5, o prêmio da briga mostrava `OCORRÊNCIAS: 0`, porque o `night_prize` não trazia `scares_total`. Corrigido em `briga_beco.gd`; vale também para os bandidos da 2a1.
- **Prêmio do chefe:** ganhou 4 px de ar entre o bloco do chefe e as bolinhas.
- **Provas:** `test_ronda2a2` 144/144, `test_ronda2a` 477/477, `qa_ronda2a2_e2e` 36/36, `ui_audit --estrito` nos 2 estados com 0 problemas.
