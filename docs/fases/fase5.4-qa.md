# Fase 5.4 (árvore grande): QA

Data: 2026-11-13. Branch `fase-5.4`. Testador: QA. Só reporto; nada em `scripts/`, `scenes/`, `ui/`, `data/` foi mexido.
Save real do dono: copiado antes (cópia em `%TEMP%\qa54_backup`), nunca tocado. `run_tests.ps1` confere o md5 no fim e confirmou "não mudou". Meus testes usam só `user://test/`.
Janelas não-headless abriram com `--position 1950,40`.

alinhamento-ui: 183 estados, 0 problemas

## 1. Veredito curto

**NÃO está pronto para o Diretor.** Há 1 bug de gravidade alta (B1): depois de uma **derrota**, o botão ÁRVORE da tela de fim não faz nada, então o critério 1 ("abre na tela de fim") falha no caso mais comum de fim de campanha. O resto passa: testes, alinhamento, balanço e efeitos. Corrigido o B1, volta para uma conferência rápida.

## 2. Critérios de aceite (escopo, seção 5) -> resultado

| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Sem abas; botão abre o mapa por cima da sala; fecha com 1 clique ou Esc; abre durante a campanha e na tela de fim | **FALHOU (parcial)** | Sala: OK (sessão longa: 4 aberturas pelo botão, 9 compras, Esc fecha; `qa_f54_diag.gd` "botão abre o mapa", "Esc fecha o mapa"). Fim por aposentadoria/passar o posto: OK. **Fim por derrota: o botão ÁRVORE não abre (B1)** |
| 2 | Botão brilha só quando há nó à vista que o Legado paga | OK | `test_fase54.gd` (Legado 9 sem brilho, 10 brilha); `qa_f54_diag.gd` (botão real: 5 apagado, 10 brilha, 9 apaga); na sessão longa `brilhando == ha_no_compravel()` em todas as leituras; mapa cheio: 0 compráveis |
| 3 | 35–40 nós, 12 atuais no centro, regiões Garagem/Academia/Boxe/Jiu-jitsu/Campanha, ≥3 ligações | OK | `qa_f54_extra.gd`: 39 nós; Garagem 6, Campanha(AGENDA) 4, Academia 5, Boxe 4, JJ 4, ligações 4; menor distância entre nós 56,6 px (>=40); posições únicas; os 12 ids do centro iguais; soma dos preços 16.810 |
| 4 | Comprar revela vizinhos na hora; travas (Academia, artes) respeitadas | OK | `test_fase54.gd` + extra: com `body_jab` aparecem `gar_tape`, `body_crew`, `body_muscle_memory`, `career_purse`; `gar_rope` escondido. Sem arte: 23 nós compráveis no máximo e nenhum de `gym`/`boxing`/`bjj`, nem por ligação. Com artes: todos os 39 alcançáveis |
| 5 | Dados em `skill_tree.json`, mudar número muda o jogo | OK | `test_fase54.gd` `_teste_dados_no_json` (preço 3 e valor +400% lidos de um JSON de teste) |
| 6 | Corda montada; +1 dia; Grito mais alto | OK | Seção 4 |
| 7 | Compra no meio só vale na próxima, cartão diz | OK | `por_clique()` e produção iguais depois de comprar no meio; `active_nodes` só muda em NOVA CAMPANHA; sessão longa: 9 compras sem nenhuma violação; cartão mostra "VALE NA PRÓXIMA CAMPANHA" (`f54_cartao_comprado.png`, `f54_cartao_arte.png`) |
| 8 | Com o mapa aberto relógio, equipe e clique não andam | OK | `qa_f54_diag.gd`: `sala_ativa()` falso, `tick(5)` não mexe no relógio, `clicar()` recusado. Sessão longa: 0 violações de relógio e de treino (4 mapas, 1,5 s reais cada com cliques no vazio) |
| 9 | Ramo aparece como CAMPANHA, sem "CARREIRA" sobrando na árvore | OK | `tree_branch_career` = CAMPANHA; nenhum nome/efeito/`tree_*`/`map_*` com "CARREIRA". Região leste = AGENDA (decidido) |
| 10 | Save antigo abre com nós acesos, vizinhos à vista, Legado igual | OK | Seção 5 |
| 11 | Simulação conferida | OK, com ressalva | Seção 6. Rodei `f54x b23c f54dia`; os números batem com o design, e as metas novas do Diretor fecham |
| 12 | `ui_audit` 0 problemas | OK | `ESTADOS 183 | PROBLEMAS 0`. `JanelaMapa.diagnostico()` roda no audit e acusa defeito injetado (seção 3) |
| 13 | `run_tests.ps1` inteiro, sem tocar o save real | OK | `TODOS OS TESTES PASSARAM`, 2.544 PASS, guarda do save real OK |

## 3. Testes automáticos e alinhamento

- `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` -> **TODOS OS TESTES PASSARAM** (2.544 linhas PASS, 0 FAIL; cena principal 120 frames sem erro; save real igual).
- Alinhamento: `ui_audit.gd -- --estados todos` -> `ESTADOS 183 | PROBLEMAS 0`. Olhei os `f54_*` (mapa inicial, meio, completo, noroeste, sudeste, botão normal/brilho/hover/Grito, cartões comprável/sem Legado/comprado/ativo/arte/Grito sem loja, fim com botão, mapa do fim, volta ao fim, save antigo). Nada cortado, preços dentro das etiquetas, cartão dentro da janela, texto centrado nos botões. Observações só visuais, sem acusação: o cartão cobre a plaquinha de região quando o mouse está em cima dela (normal para dica); o botão da sala brilhando é sutil (2 quadros) em tela cheia, o dono vai julgar (ponto 1 da seção 7 do escopo).
- **Diagnóstico do mapa** (`tests/qa_f54_diag.gd`): `diagnostico()` no mapa real devolve `[]`. Injetando defeitos acusa `nó body_jab cobre nó career_purse`, `etiqueta de body_jab cobre nó career_purse` e `nó body_jab fora do mundo`. Funciona.

## 4. Efeitos dos nós novos (cada um testado)

Scripts: `tests/qa_f54_extra.gd` (241 checagens, 240 PASS; a única falha é o travessão pré-existente, ver B3) e `tests/test_fase54.gd`.

| Efeito | Resultado |
|---|---|
| Corda montada (`gar_rope`) | OK: `aparelho_montado("jump_rope")`, sem caixa; esteira continua na compra; sobrevive a salvar/recarregar; repete na campanha seguinte; sem o nó não monta |
| Metrônomo nível 2 (`gar_metro`) | OK: nível 2 (o máximo entre 1 e 2); produz no tick |
| 5 Vizinhos (`gar_crew_start`) | OK: `quantidade = 5`; preço do próximo 184 = 60 x 1,25^5 (arredondado); dá para comprar mais (chega a 8) |
| +1 dia (`camp_extra_day`) | OK: as 6 lutas têm exatamente +1 dia (`_data_da_proxima_luta`) |
| Academia x2,5 (`gym_fan`) | OK: x2,5 na academia, garagem x1; comprado e fora da foto não vale (x2) |
| Grito mais alto (`link_shout`) | OK: sem o Grito da loja = 0; com ele 1,5 s da equipe/s; sem o nó 1,0 s; sem equipe = 0. Cartão mostra "PEDE O GRITO DA EQUIPE (LOJA)" (`f54_cartao_grito_sem_loja.png`) |
| `art_fight_bonus` | OK: Boxe dano 1,21 (+21%), Jiu-jitsu recebido 0,81 (-19%); texto "BOXE: +21% DE DANO" e "JIU-JITSU: -19% DE DANO RECEBIDO" (também na janela de escolha da arte, `f54_cartao_arte.png`); a prévia carrega a arte |
| +15% Legado (`camp_diary`) | OK nos 3 fins: aposentar/passar o posto (ganho == prévia, 1.150 vs 1.000), derrota (575 vs 500; derrota real: ganho == `legado_se_perder()`); piso (floor); Legado 0 fica 0, nunca negativo; linha do caderno > 0 |
| Nó de arte só vale na arte | OK: no Boxe `passive_bonus` do Respirar fundo = 0, clique +25% do Jogo de pernas vale; no JJ o contrário; regra da arte (`bonus_arte_clique`/`bonus_arte_equipe`) = 0 na outra arte. `estilo_arte("bjj")` devolve 0,75 mesmo jogando Boxe, mas só é lido para a arte jogada (inofensivo) |

Compra restrita (`pode_abrir_arvore`, `comprar_no`): recusa na luta, no dia da luta, na escolha da arte e com caixa de 2 batidas; aceita com caixa sem batida e com tela de fim pendente (`fim.legacy_total` acompanha o Legado). Sem Legado: recusa, Legado intacto; Legado negativo: sem compra e sem brilho. 30 rodadas de compra/aposentar/nova campanha: nenhum nó duplicado, Legado nunca < 0, 39 nós no máximo.

## 5. Save (v9 -> v10, só em `user://test/`)

- Save v9 com os **12 nós antigos** + artes liberadas + Legado 1.234: os 12 ficam na ordem, todos `owned`, 12 ativos, **todos os vizinhos à vista**, Legado 1.234 (sem reembolso de `body_crew_2` e `career_good_loser`), regrava em v10, reabre igual, `tree_last_node = style_bjj`.
- v9 sem nós; v9 com tela de fim pendente (árvore abre, compra `gar_tape` por 15, NOVA CAMPANHA ativa o nó); id desconhecido: OK.
- **Corrompido** (14 casos, `qa_f54_extra.gd`): `active_nodes` string/int/dict/null/lixo misto/5.000 itens; `tree_last_node` número/array/nó não comprado; `skill_nodes` string/dict/null/duplicado/nós escondidos; JSON quebrado; versão 99. Todos abrem sem erro, `active_nodes` fica só com ids comprados e conhecidos (String), `tree_last_node` é String e vazio ou comprado, o mapa devolve 39 nós.

## 6. Balanço (`fase5_sim.py f54x b23c f54dia`, 400 por perfil e arte x 10 campanhas; 23b com 2.000)

Rodei por conta própria `f54x` e `b23c` completos; os números reproduzem a seção 5 do design linha a linha.

| Meta | Resultado | |
|---|---|---|
| Árvore fecha entre a 5ª e a 8ª campanha | mediana 6 (B5, J5, B4, B3) e 7 (J4, J3); p10–p90 6–8; 100% fecham até a 10ª | OK |
| Boxe x JJ até o Kid <= 10% | 5/s 6,9%; 4/s 9,4%; 3/s 9,4% (amostra 400 por perfil e arte) | OK (no limite a 3–4/s) |
| Kid, média dos 6 perfis <= 80% | (72,5 + 69,2 + 95,5 + 91,8 + 89,0 + 56,2) / 6 = **79,0%** | OK |
| Kid, nenhum perfil < 50% | menor: JJ 3/s 56,2% | OK |
| Kid, mediana 1–2 e p90 <= 4 | mediana 1 nos 6; p90 2 / 3 / 1 / 1 / 2 / 4 | OK (JJ 3/s no teto, p90 = 4) |
| JJ 3/s: média <= 2,2 campanhas | 2,07 | OK |
| JJ 3/s: <= 25% atrás do Boxe em tempo acumulado até o 1º Kid | 21,5% (45:37 x 55:26) | OK |
| JJ 3/s não fica atrás na mediana | 1 x 1 | OK |
| 5/s: Boxe abre <= 0,3 campanha | 0,19 | OK |
| 23b (2.000) | 5/s 26,4%; 4/s 0,2%; mais cedo 20:44; 0 antes de 20:00 | OK (idêntico à 5.3) |
| 1ª derrota da campanha 1 em 10–15 min | 13:39 (5/s), 14:39 (4/s); a 3/s quase todos passam o posto (fim da campanha 1 em 15:26) | OK |
| Cinturão amador na 2ª–4ª campanha | mediana 2 em todos | OK |
| Tempo morto, campanha 1, 3/s (p90) <= 10:32 | 6:00 | OK |
| Tempo morto academia (p90) <= 10:00 | 4:30–7:27 (pior caso isolado 11:02 em JJ 4/s) | OK |
| Late game, clique >= 25% da renda | 66–85% (árvore cheia) | OK |
| 1ª derrota compra >= 1 nó | 100% das campanhas 1 com Legado > 0 | OK |

Pontos para o Diretor saber (não são bugs):
- Kid a 4/s continua vencendo 92–96% na 1ª tentativa (registrado na decisão D1). JJ 3/s: 95 derrotas e 80 passou-o-posto em 400 na 1ª tentativa.
- Cinturão amador nas campanhas com arte: JJ ~20–23% na frente a 3–4/s (só leitura, como na 5.3).
- AFK: o simulador mostra que 10 min parado perde ~40% do tempo útil, igual à 5.3.
- `f54dia` (96 x 10) terminou depois da entrega e confere com a tabela 5.8 do design: corda na mão aos 0:00 com o nó contra 0:29–0:46 sem ele; campanhas com +1 dia 100% antes da data (JJ 3/s: 14 dias, p90 16); mapa completo, JJ 3/s: 95,9% antes da data, 4,1% no dia, 1,9% no vermelho. OK.

## 7. Sessão longa pela UI (`tests/qa_f54_play.gd`, adaptado de `qa_f53_play2.gd`)

`godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f54_play.gd -- a 1 5 4.5 5` (escala 5x, 4,5 cliques/s, 25 min reais: 4 campanhas completas e parte da 5ª, ~125 min de relógio).
- Mapa aberto **4 vezes pelo botão da sala**, **9 compras clicando nos nós de verdade** (mover o mouse abre o cartão do nó certo; clique compra; Legado desconta exato). Ex.: campanha 4 abriu com 385 de Legado e comprou `camp_poster`, `career_scouting`, `body_muscle_memory`, `gar_radio`, `body_crew`; campanha 5 comprou `gym_membership` depois da academia (a trava abriu na hora certa).
- Cada compra no meio da campanha: `por_clique`/produção iguais, nó não está em `nos_ativos()`, `next_campaign` verdadeiro. Na NOVA CAMPANHA a foto é tirada (`nos=[...]` no log).
- 0 violações de relógio/treino com o mapa aberto; botão: `brilhando == ha_no_compravel` em todas as leituras; diagnóstico do mapa sem problema; 20 lutas, 0 BUG54 acusado.
- **Mapa aberto pela tela de fim: 0 vezes.** As 3 derrotas da sessão (campanhas 1, 2 e 3) terminaram em tela de fim; o harness clicou ÁRVORE e o mapa não abriu. Reproduzido de forma determinística em `qa_f54_diag.gd` (B1). Pelo caminho de aposentadoria o mapa abre (`qa_f54_diag.gd`) e a volta ao fim está coberta por `ui_audit` (`f54_fim_volta`).
- Erro do harness (não do jogo): `achar_botao` recebe janela já liberada logo depois de escolher a arte (`qa_f54_play.gd:579`). Só no script de teste.

## 8. Textos

- Acentos corretos em todos os nomes e textos dos 39 nós e nas chaves `map_*`; nome <= 16 e frase <= 44 em todos (o maior nome tem 16, "Caderno do velho"; a maior frase 43).
- Sem travessão em `skill_tree.json`. Em `ui_texts.json` há 1 (B3, pré-existente, a UI troca por ":").
- "VALE NA PRÓXIMA CAMPANHA", "SÓ VALE JOGANDO DE BOXE" (em todo nó de arte, inclusive `box_footwork` e `bjj_breath`), "PEDE O GRITO DA EQUIPE (LOJA)" aparecem sem corte nas capturas. "+0.5 S" com ponto (decidido). Preço 1.200 aparece como "1.20K" no mapa e "800" sem K: formatador do jogo, igual ao resto.

## 9. Bugs

| # | Gravidade | Dono | Descrição | Como reproduzir |
|---|---|---|---|---|
| B1 | **Alta** | UI/UX (`ui/fluxo.gd`) | **Depois de uma derrota, o botão ÁRVORE da tela de fim não abre o mapa.** `Fluxo.abrir_arvore()` retorna cedo se `tela.visible`; na derrota a tela de fim abre por cima da arena e a arena continua visível (o comentário em `_ao_terminar_luta` diz isso). `pode_abrir_arvore()` é verdadeiro, então o jogador clica e nada acontece. Pela aposentadoria funciona (arena fechada). Fere o critério 1 e a decisão 1 do Diretor. É o caminho mais comum de fim de campanha (a sessão longa teve 3 derrotas, 0 mapas abertos do fim). Sugestão: na condição, tratar `tela.visible` com `GameState.tem_fim_pendente()` como aceitável (a arena fecha ao entrar no mapa ou na volta), ou fechar a arena ao abrir o mapa. | `godot --headless --path . --script res://tests/qa_f54_diag.gd` -> `FAIL BUG? ARVORE na tela de fim DEPOIS DE DERROTA abre o mapa (janela=JanelaFim, tela.visible=true)`. À mão: perder uma luta, na tela "CAMPANHA ENCERRADA" clicar ÁRVORE |
| B2 | Baixa | UI/UX ou Programador | `ui_audit` não cobre a derrota (o estado `f54_mapa_do_fim` usa fim sem arena visível), por isso o B1 passou com 0 problemas. Acrescentar um estado "fim depois de derrota com arena" ao audit | Ver B1 |
| B3 | Baixa (pré-existente) | Roteirista | `data/ui_texts.json:188` `career_card_title` tem travessão ("CAMPANHA {n} — O QUE VOCÊ TROUXE:"). Já existia antes da 5.4 e `ui/cartao_inicio.gd:32` troca por ":" na tela, então o jogador não vê; só a regra "sem travessão" de dados | `grep "—" data/ui_texts.json` |
| B4 | Info | Programador | `tests/qa_f54_*.gd` novos ficam no repositório (não commitei). `estilo_arte(outra_arte)` devolve o valor dos nós da outra arte (0,75); só é lido para a arte jogada, sem efeito no jogo | `qa_f54_extra.gd` |

Nada mais encontrado: sem erro de script/engine nos testes, na cena principal, no audit e na sessão longa.

## 10. Riscos

- B1 pode esconder o aviso "vale na próxima campanha" para quem perde (o dono vai perder muito na 1ª campanha, a árvore só tem o que gastar depois do 1º fim).
- Kid a 4/s ainda fácil (92–96%): decisão do Diretor, vigiar no teste do dono (ponto 8).
- Tempo de simulação: `f54x` com 400 x 10 leva cerca de 40–50 min na máquina de QA.
- A sessão longa usou robô que compra o mais barato; um jogador real pode abrir o mapa em momentos ruins (dia da luta: botão apagado, sem dica, já decidido).

## 11. Como reproduzir meus testes
```
godot --headless --path . --script res://tests/qa_f54_extra.gd        # dados, compra, efeitos, legado, save corrompido, migração
godot --headless --path . --script res://tests/qa_f54_diag.gd         # botão, diagnóstico do mapa, Esc, derrota (B1)
godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f54_play.gd -- a 1 5 4.5 5
"C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" tools\sim\fase5_sim.py f54x b23c f54dia
```
