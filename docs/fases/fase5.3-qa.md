# Fase 5.3: Calendário da campanha, relatório do QA

Data: 2026-11-13. Branch `fase-5.3`. QA não corrigiu código. Save real do dono: SHA256 igual antes e depois (9E63...7CA7). Janelas de teste abertas com `--position 1950,40`.

**alinhamento-ui: 171 estados, 0 problemas** (verificador). Mas há 1 sobreposição visível que o verificador não cobre (B1).

## 1. Execuções
| Verificação | Resultado |
|---|---|
| `tools/run_tests.ps1` | **TODOS OS TESTES PASSARAM** (inclui `test_fase53.gd`, guarda do save real, cena principal) |
| `ui_audit.gd --estados todos` (1280x720, `--position 1950,40`) | 171 estados, 0 problemas; capturas `f53_*` conferidas |
| `tests/qa_f53_ui.gd` (cena real, headless): tabela da seção 2 do design, dia, VOLTAR, reabrir no dia | 75 PASS, 0 FAIL |
| `tests/qa_f53_extra.gd` (datas, delta gigante, avisos, dica, v8 para v9, `fight_day` corrompido) | 44/45; o 1 FAIL é expectativa errada minha (ver 5, nota) |
| `tests/qa_f53_shot.gd` (janela real): prévia do dia com revanche + arte; janela minimizada | ver B1 e critério 3 |
| `tests/qa_f53_retrato.gd` (janela real): retrato L0 a L4 | OK |
| `tests/qa_f53_play.gd` / `qa_f53_play2.gd` (sessão longa pela UI, entrada sintética) | ver seção 4 |
| `fase5_sim.py b23c` e `f53` | reproduzem exatamente as tabelas do design (seção 3) |

## 2. Critérios de aceite
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Próxima luta, "Faltam X dias" e risco sempre à vista; 6 datas | **OK** | folgas lidas: [12,13,10,16,24,16]; Dudu Dia 13, Brutão = dia da luta+13, Dinho +10, Muralha +16, Tonhão +24, Kid +16. Capturas `f53_hud_*` (placa "TONHÃO", "Falta 1 dia", "É HOJE!") |
| 2 | Faixa a 3 dias; faixa + som a 1 dia | **OK** | `f53_aviso_3_dias`, `f53_aviso_1_dia_a/b`; série de 2 datas: [3,1] por data, 4 avisos; 3/4/s chegam ao Dinho no dia (sim), então aparecem na 1ª campanha |
| 3 | No dia tudo para; prévia com Lutar e Passar o posto; 10 min parado e nada começa | **OK** | `qa_f53_ui`: relógio trava em (data-1)*30 = 360,0 exato; 600 ticks de 1 s sem mudança; sessão real a x10: 10 s reais (100 s de jogo) parado, relógio +0,000, treino +0,000, nenhuma luta |
| 4 | Passar o posto no dia = 100% do Legado | **OK** | UI: Legado +previsto; sessão real: "legado previsto=20 ganho=20 fim=retire"; confirmação obrigatória (`f53_dia_passar_confirma`) |
| 5 | Lutar antes é livre; data seguinte conta do dia da luta | **OK** | `qa_f53_extra`: luta no Dia 2 dá Brutão = 15; Dia 3 dá Dinho = 13; UI: fight_day = dia+13 |
| 6 | Relógio não anda na luta, arte e janelas; equipe junto | **OK** | tabela inteira (seção 2.1 abaixo); `test_fase53` sorteio de 600 quadros sem divergência |
| 7 | Segundos por dia e folgas em `data/` | **OK** | `career.json calendar` e `opponents.json prep_days`; teste muda `prep_days` e a data muda; `seconds_per_day` 0 desliga; inválido cai em 14 com aviso |
| 8 | 23b com 2.000: <=25% (+-2), ninguém antes de 19:30, <=1% antes de 20:00 | **OK** | 5/s **26,4%**, mais cedo **20:44**, 0 antes de 19:30, 0 antes de 20:00 (4/s 0,2%; 3/s 0%). Alavanca $300K não necessária |
| 9 | Tempo morto carreira 1 a 3/s <=10:32; academia <=10:00; 1ª derrota 10 a 15 min | **OK** | 3/s p90 **6:00** (<=10:00 desejável também); academia p90 4:00 a 6:30 (pior caso isolado 9:32); 1ª derrota 5/s **13:39**, 4/s **14:09** (3/s 15:26 de fim da carreira, aceito pelo Diretor) |
| 10 | Metas de pé da 5.2 | **OK com ressalva aceita** | Kid: mediana 0 carreiras depois da chegada, 96 a 100% em <=1 (Decisão do Diretor 1); Jiu-jitsu 3/s Kid 0,06 x Boxe 0,02 (ruído, 3 de 48); cinturão JJ à frente do Boxe; clique no fim 54 a 72% (>=25%); árvore fecha na 4ª (Decisão 2) |
| 11 | Tabela no dia x antes | **OK** | reproduzida: 96 a 97% antes; vermelho no dia 0,5 a 2,3% das lutas (3/s 2,3% <= 25%) |
| 12 | Retrato segue a luva L1 a L4; Grito visível sem rolar | **OK** | folha de retratos: L0 vermelha, L1 creme, L2 marrom, L3 preta, L4 azul, na prévia e no topo da luta; tela de fim usa a mesma função (`UiTema.nome_retrato_jogador`); `f53_loja_grito_sem_rolar` mostra o card do Grito inteiro 2º na LOJA |
| 13 | Save antigo: folga cheia; depois do Kid = completa | **OK** | v8 em andamento (Muralha): treino, luva, Grito, dinheiro, fama, Metrônomo, caixa e Legado preservados, Dia 1, data 17; Kid vencido: -1 e "completa"; academia: data 25; cópia do save real (v6) abre com data 13 |
| 14 | `ui_audit` com 0 problemas | **FALHOU (parcial)** | verificador 0/171, porém prévia do dia com revanche + arte: selo "HOJE" toca o retrato (B1) |
| 15 | `run_tests.ps1` passa; não toca save real | **OK** | hash do save real idêntico; guarda 4/4 |

### 2.1 Tabela da seção 2 do design (verificada na cena real)
Param (relógio, equipe, Metrônomo, FRENESI, arte, ouro e clique recusado, 10 s): prévia pelo LUTAR, confirmação de passar o posto, luta, vitória, tela de fim, árvore, escolha da arte, cartão de início (fecha com 1 ação), prévia do dia, confirmação no dia. Andam (relógio +10 s e equipe junta): sala livre, aba LOJA, janela sem foco, caixa de equipamento aberta, depois de VOLTAR A TREINAR, depois da vitória, depois da arte. Janela **minimizada** de verdade (janela real): 3 s reais, relógio +3,04 s, treino +30,4. Tudo conforme a tabela.

### 2.2 Extras do Diretor
- **Dica só no vermelho com <=3 dias:** varredura de 0 a 5 dias x 3 cores: só aparece com <=3 e vermelho; pote 0 sem dica; academia mostra; selo de outro adversário não mostra. OK.
- **VOLTAR no dia volta para a prévia do dia:** UI e sessão real. Fora do dia volta para a sala. OK.
- **Prévia não fecha:** Esc ignorado, sem VOLTAR A TREINAR, não abre 2ª prévia, LOJA desabilitada, compras recusadas.
- **Avisos 1 vez por data, também ao reabrir:** reabrir com Faltam 3 emite [3], com 2 emite [2], com 1 emite [1,1] (ver B2).
- **Nunca pula data:** tick de 1e7 s e 400 deltas de até 90 s: relógio para exato na data.
- **fight_day corrompido:** string, NaN, Infinity, negativo, 0, -1, 1e12, bool, nulo, array, dict, 1005 viram 13; 999 e 1000 aceitos (limite é > dia+999); `campaign_seconds` inválido vira 0.

## 3. Balanço (simulador, rodado por mim)
- `b23c` 2.000 jogadores: 5/s 26,4% / 20:44 / p1 21:00; 4/s 0,2% / 22:58; 3/s 0%. Fim da carreira 1: 13:39, 14:09, 15:26.
- `f53` 48x8: antes da data 96 a 97%; no dia vermelho 0,5% (5/s) a 2,3% (3/s). Tempo morto garagem carreira 1 p90: 7:43 (5/s), 5:30 (4/s), 6:00 (3/s). Clique no fim: 54 a 72%.
- AFK: 10 min parado perde 4,2 a 4,7 min de equipe+Metrônomo (42 a 47%); 30 min perde 80 a 82%. Equivale a 0,8 a 1,6 min de jogo ativo: tolerável, mas é o ponto que o dono deve validar (item 5 da seção 7 do escopo).
- Observação: a 3 e 4/s a campanha 1 termina no Dinho por passar o posto em 43 a 45 de 48 jogadores (decisão do Diretor 3 e 4, aceita).

## 4. Sessão longa pela UI
- `qa_f53_play.gd` (robô que luta no verde/amarelo, x5, 4 carreiras): carreira 2 venceu a escada inteira e passou o posto no Kid (Legado 1710); carreiras com derrota no Dudu por azar. Nenhum dia de luta chegou (robô bom), 0 violações de relógio parado (4 alertas eram só o zerar do relógio ao começar campanha nova, falso positivo corrigido no `play2`), 10 lutas = 10 cliques em LUTAR (nenhuma luta sozinha).
- `qa_f53_play2.gd` (robô passivo, x10): 4 dias de luta alcançados, cada opção escolhida: #1 Dudu: PASSAR, VOLTAR (voltou à prévia do dia), LUTAR e venceu; #2 Brutão (data 26, relógio 750,0): PASSAR + confirmar, Legado ganho = previsto; #3 Dudu da campanha seguinte: LUTAR direto; #4 Brutão: 10 s reais parado sem mudança, depois LUTAR. 0 mensagens de BUG/violação. A sessão foi interrompida antes das carreiras finais (a sessão anterior caiu); a parte rodada cobre todas as opções.

## 5. Bugs e riscos
| # | Gravidade | Dono | Descrição / como reproduzir |
|---|---|---|---|
| **B1** | **Média** (visual, bloqueia a fase pela regra do alinhamento) | UI/UX | Na **prévia do dia com a fita "VOCÊ PERDEU PRA ELE" e o traço da arte ao mesmo tempo**, o selo "HOJE nn" no canto esquerdo sobrepõe o canto do quadro do retrato do adversário (cerca de 5 px de jogo; a janela cresce e sobe, o retrato fica em y=33 e o selo chega a y=38). Reproduzir: `godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f53_shot.gd`, captura `scratchpad\qa53\previa_dia_revanche_arte.png` (zoom `zoom_badge.png`). Sem revanche (Tonhão com arte) a folga é de só 3 px. O `ui_audit` não tem esse estado; sugerir incluí-lo e subir/encolher o selo ou fixá-lo na janela. |
| B2 | Baixa | Programador | `aviso_data` pode sair duas vezes com o mesmo valor (reabrir com Faltam 1 emite [1,1]); a faixa trata (não repete som), então sem efeito visível. Um tick gigante saindo de Faltam >3 até o dia não emite aviso nenhum (só a prévia do dia). Fase 13: offline deve emitir os avisos ou aceitar o salto. |
| B3 | Baixa | Designer/Programador | Tonhão com o jogador ainda na garagem: o relógio segue passando da data (dia 29 com data 25); ao mudar para a academia cai direto no dia (depois da escolha da arte). Raro, pois a vitória do cinturão muda automaticamente. |
| B4 | Info | Roteirista | Em `ui_texts.json`, `floor_mark_price` e `floor_mark_after` (da 5.1) têm travessão "—", se aparecerem na fita do chão violam a regra; `career_card_title` tem, mas a UI troca por ":". Ramo da árvore ainda se chama "CARREIRA" (`skill_tree.json`). Nada disso é novo na 5.3. |
| Nota | Info | | Migração de "fim pendente" mantém a escada do save (data 11 no meu caso), diferente do "Dudu 13" do design, mas `nova_carreira()` recalcula para 13 (testado). Meu 1 FAIL do `qa_f53_extra` era essa expectativa. |

Risco de design (já conhecido): jogo parado no dia para quem sai (AFK); proteção é aviso com som, ícone que pisca (não testável em headless; código em `Fluxo._pedir_atencao`) e a data sempre visível.

## 6. Renomeações
"Passar o posto" (botão da barra, prévia do dia, confirmação "PASSAR O POSTO?", PASSAR/VOLTAR), "PASSOU O POSTO", "CAMPANHA ENCERRADA", "NOVA CAMPANHA", "RESUMO DA CAMPANHA n", "CAMPANHA n" no HUD, "CAMPANHA COMPLETA", dica "PASSAR O POSTO TAMBÉM É UMA BOA LUTA": todos presentes, acentos corretos, nada cortado nas capturas. Nenhum "aposentar" restante em `ui_texts.json`. Sem travessão nos textos novos.

## Veredito
**Não está pronto para o Diretor ainda**: tudo passa, exceto B1 (selo "HOJE" tocando o retrato na prévia do dia com revanche + arte). Corrigido B1 e incluído o estado no `ui_audit`, a fase está pronta.
