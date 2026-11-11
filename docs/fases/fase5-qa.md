# Fase 5: QA (refeito sobre a branch `integra/fase5-ui`, com os PRs 1 e 2 do Matheus)

Dono: QA. Data: 2026-11-11. Substitui o QA de 07/11, que era anterior aos PRs (rounds, luva dourada, golpes novos, quedas, barra de especial, Metrônomo/Shift mais fortes, mudança automática com prêmio de $2.500).
Nada em `scripts/`, `scenes/`, `ui/`, `data/` foi alterado. Save real do dono intacto (`save.json` de 2026-11-07 16:24, igual antes e depois; guarda do `run_tests.ps1` passou). Nada commitado.
Fora do meu escopo, por pedido: balanço (critérios 9 a 14, F4 8/23a/23b/24, tempo do Kid); o Designer refaz o simulador. `fase4_sim.py`/`fase4b_sim.py` (B5 antigo) não foram retestados.
Decididos, não são bugs: preço "$1.00K", "RESIST." no botão estreito, dica F11 escondida com o chip da arte, aba TREINO rola, mudança automática após o cinturão.

**alinhamento-ui: 98 estados, 0 problemas**

## 1. O que rodei

| Verificação | Comando | Resultado |
|---|---|---|
| Bateria | `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` | `TODOS OS TESTES PASSARAM` (18 grupos, cena principal 120 frames sem erro, guarda do save real OK). Sem erro de parse do MovesData |
| Cena principal | `Godot --headless --quit-after 300 -- --save-dir=user://test/cena_qa300/` | 0 ERROR/WARNING |
| Alinhamento | `Godot --path . --resolution 1280x720 --script res://tools/ui/ui_audit.gd -- --estados todos` | `ESTADOS 98 \| PROBLEMAS 0`. Olhei os `f5_*` e as capturas de luta (rounds, barra de especial, combo, K.O., TEMPO!) |
| Extras antigos | `tests/qa_f5_extra.gd`, `qa_f5_extra2.gd` (headless), `qa_f5_ui.gd` (janela) | passam. Corrigi 3 falsos negativos dos próprios scripts (risco do HUD desligado no teste da dica; `tempo_jogo` x relógio da arte; contagem de botões ESCOLHER = 4) |
| Extras novos | `tests/qa_f5_extra3.gd` (51 checks), `qa_f5_ui2.gd` (vitória/MUDAR/corda), `qa_f5_ui3.gd` (luta com capturas) | resultados nas seções 3 e 4 |
| Sessão longa pela UI | `tests/qa_f5_play.gd -- p 1 6 4.5 3` | 3 carreiras: derrota, cinturão e mudança automática com janela de arte (Jiu-jitsu), 2ª academia com Boxe até a escada completa e aposentadoria. Console: 1 SCRIPT ERROR, do próprio script (usa janela já liberada após a mudança automática), nenhum do jogo |

## 2. Critérios (função, UI e estabilidade)

| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Sem cinturão MUDAR não existe; com cinturão mostra preço; apagado sem $ | OK | `f5_mudar_travado/sem_dinheiro/pronto.png`; `qa_f5_extra` $999,99 recusa |
| 2 | Mudar: sala nova, tudo intacto, $ cobrado uma vez, multiplicador | OK | `qa_f5_ui2` A1/A2/A3: $2.623 -> $1.623 sempre, uma cobrança, mesmo apertando MUDAR duas vezes ou CONTINUAR+MUDAR; HUD "ACADEMIA: TREINO x2" |
| 3 | NOVA CARREIRA volta à garagem | OK | `qa_f5_extra3`: local garagem, arte "", escolha pendente, foco volta ao saco, MUDAR trancado, sem reserva, pera some |
| 4 | 1ª chegada abre a janela, 1 clique, 2 artes liberadas | OK | `f5_arte_primeira.png`; `qa_f5_play` e `qa_f5_ui2` A2 |
| 5 | Início da carreira seguinte: escolha antes do cartão; sem troca | OK | `f5_nova_carreira*.png`; `escolher_arte` recusa troca |
| 6 | Aparelho da arte: marca, só após esteira, zera, o da outra arte não existe | OK | `f5_*_marca.png`; extra3: com Jiu-jitsu a pera é `absent`, compra e foco recusados |
| 7 | Boxe só no clique manual; Jiu-jitsu na equipe até o teto | OK | extra3: `por_clique` 3,0 (Boxe) x `por_auto_soco` 2,0 igual nas duas artes; Jiu-jitsu sem bônus de clique; teto estável de 1e12 s a 1e300 s; produção finita |
| 8 | Prévia mostra o traço; risco honesto | OK | `f5_previa_kid.png`; `qa_f5_extra2` 26/26 |
| 15 | Save v5->v6, v0->v6, guarda do save real | OK | `test_migration`, `test_fase5`; v5 com cinturão e < $1.000 vira $1.000 |
| 16 | `data/` muda o jogo sem código | OK | `test_fase5` |
| 17 | `run_tests.ps1` passa | OK | `TODOS OS TESTES PASSARAM` |
| 18 | Alinhamento 0 problemas | OK | 98 estados, 0 problemas |
| 19 | Sessão com 3 carreiras sem erro no console | OK | sessão longa acima; o único SCRIPT ERROR é do script de QA |
| PRs | Rounds | OK | 2.880 lutas simuladas (6 adversários, 4 níveis de força, 3 táticas): todo K.O. e evento cai nos rounds 1 a 3, `t_ko` máximo 15,3 s; capturas mostram "1º/2º/3º ROUND", relógio 0:15 -> 0:00, "TEMPO! POR PONTOS" |
| PRs | Golpes e quedas são só visuais e determinísticos | OK | `luta_atual()` duas vezes = mesma lista de golpes; luta recarregada do save = mesmos golpes e resultado; motor puro = resultado animado |
| PRs | Barra de especial | OK | capturas `qa5c`: barra amarela sob a tática enche com o combo, cheia perto do fim, COMBO xN na tela, sem sobreposição |
| PRs | Luva dourada | OK | não aparece com escolha de arte pendente (200 s), não pega em luta, não pega 2x, FRENESI x7 no clique, zera na nova carreira, não vai para o save, `tick(1e9)` finito |
| PRs | Metrônomo/Shift mais fortes | OK | 12 compras seguidas de Metrônomo sem erro; Boxe não vale no automático |
| PRs | Mudança automática x botão MUDAR da vitória | FALHOU em parte | ver N1 e N2 |
| PRs | Corda girando | OK com ressalva | ver seção 4 |

## 3. Tentei quebrar

| Cenário | Resultado |
|---|---|
| MUDAR sem $, em luta, na tela de fim, duas vezes | recusa; cobra uma vez |
| Vitória do cinturão: MUDAR / CONTINUAR / ambos | sempre uma mudança e uma cobrança. Mas ver N1 (soft-lock) |
| Fechar o jogo com a vitória do cinturão aberta | reabre na garagem com cinturão, prêmio guardado ($2.623) e MUDAR pronto; sem janela de arte (ainda não mudou) |
| Fechar com a escolha de arte pendente | `qa_f5_ui`: janela volta ao reabrir, ações bloqueadas |
| Reserva da LOJA | funciona (`f5_loja_reserva.png`: "GUARDE $1.00K PARA A MUDANÇA", Nelson compra, luva "GUARDE $1.00K"; 501 de 1.500 recusa). Ver N6: com a mudança automática quase nunca aparece |
| Teclas 1 a 4 | sem arte e com aparelho trancado não fazem nada; comprado, trocam o foco |
| Aparelho da outra arte | `absent`, compra e foco recusados |
| Save corrompido com campos novos (local numérico, arte em lista, `art_seconds` texto, gear nulo, `arts_unlocked` string, arte inexistente) | carrega sem erro, valores finitos, avisos no console (esperado) |
| Migração v5->v6 em `user://test/` | OK (testes) |
| Aba ESTILO, dica de aposentar | `f5_arvore_estilo.png` (nós centralizados, "SÓ VALE JOGANDO DE ..."); dica "APOSENTAR AGORA LEVA 750 DE LEGADO" aos 300 s com risco do HUD ligado (`f5_dica_aposentar.png`) |
| Tonhão e Kid em 3 rounds, com arte | lutas completas na UI (Boxe x Tonhão, Jiu-jitsu x Kid), tela de fim com arte no resumo |
| Textos | acentos corretos; os 3 travessões do `ui_texts.json` são convertidos em ":" ou "-" no código; "A PERA" e "O BONECO" no gênero certo; nada cortado |

## 4. Corda (capturas `qa5b/corda_*`)
A corda gira de fato em volta do lutador, em 6 quadros: atrás, passa acima da cabeça, desce na frente na altura da cintura, embaixo dos pés, volta por trás e repousa. Dá a volta inteira. Nos 2 quadros de repouso ela fica um pouco solta e torta atrás das mãos (cosmético). A marca na parede (garagem e academia) fica no meio da parede, ao lado do saco, com a plaquinha acima: não está alta demais nem colada no teto.

## 5. Bugs

| ID | Gravidade | Dono | Descrição | Como reproduzir |
|---|---|---|---|---|
| N1 | Média (baixa probabilidade) | designer-ui-ux (`ui/fluxo.gd`) | `_mudar_da_vitoria` e `_fechar_vitoria` não são idempotentes. Uma 2ª chamada (MUDAR duas vezes, ou CONTINUAR e MUDAR) roda `_fechar_tudo()` e fecha a janela de arte recém aberta. Resultado: `escolha_arte_pendente()=true`, nenhuma janela, `acoes_bloqueadas()=true`. O jogo fica travado até fechar e reabrir | `tests/qa_f5_ui2.gd` caso A3 (`INFO A3 pendente=true janela=null acoes_bloqueadas=true`) e A1 (FAIL "janela de arte (null)") |
| N2 | Baixa (UX) | designer-ui-ux / roteirista | Na vitória do cinturão há MUDAR ($1.00K) e CONTINUAR, mas os dois mudam para a academia: parece uma escolha e não é. O botão MUDAR mostra um preço que já foi descontado do prêmio. Cabeçalho do `ui/janela_vitoria.gd` ainda diz "O único botão é CONTINUAR" | `f5_vitoria_cinturao_mudar.png` |
| N3 | Baixa | designer-ui-ux / diretor-de-arte | (era B3) Na garagem a plaquinha "BONECO / DEPOIS DA ESTEIRA" fica coberta pelo parceiro de treino: o "D" de DEPOIS some | `f5_garagem_boneco_depois.png` |
| N4 | Baixa | programador + roteirista | (era B4) `tip_move_belt` ("GUARDE O DINHEIRO. A BOA ESQUINA ESPERA", "NA PRÓXIMA, MUDE...") aparece para quem já mudou e aposentou sem lutar na academia; com a mudança automática a dica ficou sem sentido para qualquer um (`game_state.gd:1993`) | `qa_f5_extra2` linha `INFO tip_extra`: sempre "GUARDE O DINHEIRO..." |
| N5 | Informativo | designer-ui-ux | (era B2) O acento de "ÚLTIMA: BOXE" agora aparece, mas encosta na borda de cima do selo | `f5_arte_ultima.png` |
| N6 | Informativo | diretor / designer | A reserva de $1.000 da LOJA ficou quase sem uso: o prêmio de $2.500 e a mudança automática fazem o estado "cinturão sem mudar" só existir por save migrado ou jogo fechado na vitória | seção 3 |
| N7 | Informativo | programador | `tempo_jogo` anda com a escolha de arte aberta (o relógio da arte não). Sem ganho indevido | `qa_f5_extra` item 3 |

Resolvidos desde 07/11: B1 (ERROR `Resource file not found` ao abrir a janela de arte: não aparece mais no `ui_audit` nem no `qa_f5_ui`).

## 6. Riscos
- N1 é raro (precisa de duas ativações no mesmo frame), mas o efeito é travar a carreira; correção é barata.
- Nenhum teste automático do `run_tests.ps1` abre a janela de vitória ou a de arte; os `qa_f5_ui*` não rodam na bateria.
- Fora do meu escopo e não validado: critérios de balanço com os números novos do Metrônomo, Shift e prêmio $2.500.

## 7. Arquivos de QA
`E:\Fightclicker\tests\qa_f5_extra.gd`, `qa_f5_extra2.gd`, `qa_f5_extra3.gd`, `qa_f5_ui.gd`, `qa_f5_ui2.gd`, `qa_f5_ui3.gd`, `qa_f5_play.gd` (usam só `user://test/`). Capturas em `C:\Users\deivi\AppData\Local\Temp\claude\4ea5d9e6a0b1fa65\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\` (`audit\`, `qa5b\`, `qa5c\`).

## 8. Veredito
Quase pronto para o Diretor revisar. Nenhum critério de função, UI ou estabilidade falha na bateria, no alinhamento (0 problemas) nem na sessão longa. Pedir antes: N1 (travamento raro) e N2 (botões da vitória). N3 a N7 podem ir junto ou ficar como dívida.
