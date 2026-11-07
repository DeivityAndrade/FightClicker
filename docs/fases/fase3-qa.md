# Fase 3 — Lutas e fim de carreira: relatório de QA

Dono: QA. Versão 1 (2026-11-05). Base: `fase3-escopo.md` (30 critérios), `fase3-design.md`, `fase3-api.md`, `fase3-textos.md`, `data/*.json`, código de `scripts/`, `ui/`, `scenes/`, `tests/`, `tools/`.
Nenhum código de `scripts/`, `ui/`, `scenes/` ou `data/` foi alterado. O save real do dono não foi tocado (a pasta `%APPDATA%\Godot\app_userdata\Fightclicker\` não tinha `save.json`; foi feito backup antes e nenhum arquivo de save existe lá agora; o guarda `test_real_save_guard.gd` passou antes e depois). Todos os testes jogáveis usaram `--save-dir=user://test/qa3/` (e `qa3b`, `qa3c`).

Material do QA (fora do projeto): `C:\Users\deivi\AppData\Local\Temp\claude\d03e7314839aa25e\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\qa3\` — `gd\hq.gd` (harness de jogo com mouse sintético, janela real), `gd\qa_*.gd` (testes headless), `shots\` (screenshots), `sim_*.txt`, `out_*.txt`.

## 1. Veredito curto

**Pronto para o Diretor revisar, com ressalvas.** Nenhum bug bloqueante: tudo o que é lógica, save, luta, loja, Legado, aposentadoria e fluxo de telas funciona e bate com o design. Os critérios de **metas de tempo (22, 23, 24)** só fecham em parte (o designer já havia avisado em `fase3-design.md` §13.9) e há 3 itens de qualidade de mensagem de derrota para o Designer/Roteirista decidirem (B2, B3, B4). Resumo: 26 critérios OK, 3 PARCIAL (22, 23, 24), 1 PARCIAL por falta de meio de teste (30, DPI 125%).

## 2. Suspeitas do Produtor

### (a) "LEGADO GANHO +0" no screenshot 12 (1 vitória, 10 de fama)
**Não é erro de fórmula. É um quadro intermediário da animação de contagem.**
- Fórmula conferida: pote = floor(10 × 0,2) = 2; derrota = floor(2 × 0,5) = **1**. Código: `scripts/game_state.gd:341-348` (`legado_em_jogo`, `legado_se_perder`), `data/career.json` (`legacy_per_fame 0.2`, `defeat_share 0.5`).
- O jogo dá +1. Prova (script `gd\qa_a.gd`): `pote=2 perder=1 aposentar={pote 2, total 2}` e a derrota real devolveu `fim.legacy_gained=1`, `legacy_total=1`. Também em fama 10/40/100/200: 1 / 4 / 10 / 20 (= 50% do pote, `gd\qa_leg.gd`).
- Por que o screenshot mostra +0: `ui/janela_fim.gd:157-169` faz uma contagem de 0,3 s a 1,0 s depois de abrir. Com ganho = 1 a conta é `floor(1 × p + 0.0001)`, que dá 0 até o fim da animação. O screenshot foi tirado ~50 quadros depois de abrir, no meio dela. Medido em janela real (`suspeita_a`): +250 ms: `+1 / total 0`; +600 ms: `+0 / total 0`; +900 ms: `+0 / total 0`; +1400 ms: `+1 / total 1`.
- **Mas existe um defeito de UI real aqui (B1):** o rótulo nasce já com o valor final (`+1`, linha 126), a animação o zera (`+0`) e só depois sobe: "pisca +1 → +0 → +1". Para ganhos pequenos (1 a 4, o caso típico da 1ª derrota) o jogador pode ver "+0" por ~0,7 s e achar que não ganhou nada, que é exatamente a impressão ruim que o escopo quer evitar.

### (b) Motivo principal mostra "ELE TIROU 100% DA SUA VIDA EM 1 GOLPE" em vez de "FALTARAM n DE …"
**Confirmado, e explicado.**
- Quando o "FALTARAM" aparece: `GameState.textos_fim` (`scripts/game_state.gd:812-817`) só usa o modelo "FALTARAM" se `reason.faltaram >= 0`. `faltaram` é -1 quando nem `16 × T + 1000` de treino extra num único atributo deixa a luta fácil (`scripts/luta.gd:280-295`, `data/fights.json` `reason.search_max_share 16`). Nesse caso a estatística vira a linha principal (`game_state.gd:816`).
- Quando isso acontece (só-saco, `gd\qa_front.gd`): "FALTARAM" some quando o treino total é menor que ~300 contra o Dudu, ~3 K contra o Brutão, ~10 K contra o Dinho, ~50 K contra o Seu Muralha. O estado do screenshot (T = 320 contra o Brutão, que exige ~28 K) é artificial e cai nessa faixa. Num estado real típico (T de 14 K a 130 K) o "FALTARAM" apareceu sempre (28 de 28 derrotas medidas, ver critério 14).
- Em 10 derrotas reais o motivo aponta o atributo decisivo? **Sim**, 28 de 28 (critério 14).
- Conclusão: o comportamento é o que o código promete, mas quem luta cedo demais (por exemplo, jogador que aperta LUTAR no minuto 1 contra o Brutão) vê só a estatística, sem "faltaram N". Ver B2.

## 3. Resultados dos testes automáticos

`powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1` → **TODOS OS TESTES PASSARAM** (guarda do save real antes e depois OK; cena principal 120 quadros sem erro). Contagens por arquivo: 3/3, 162/162, 69/69, 72/72, 266/266, 73/73, 37/37, 57/57, 66/66, 76/76, 4/4. Cena principal com `--quit-after 300` (headless): sem nenhuma linha de erro.

Simulador (`tools/sim/fase3_sim.py carreiras` e `risco duracao taticas motivo dica`, rodados completos): as tabelas batem com o `fase3-design.md` §13 (risco honesto 99,8 / 69,4 / 1,4%; duração 8,0–19,0 s; motivo 19 de 20; dica Dinho 4 de 5, Muralha 5 de 17).

## 4. Critérios de aceite (30)

Legenda: OK / PARCIAL / FALHOU. Janela real = Godot com janela, mouse sintético (`Input.parse_input_event`), save isolado.

### Lutar e prévia
1. **OK.** Minuto 0 (save zerado): LUTAR! habilitado; 1 clique abre a prévia (janela real, `p1`). Texto lido da tela: "PRÓXIMA LUTA / DUDU ALONGADO / EQUILIBRADO / VOCÊ CARREIRA 1 0 VITÓRIAS / 1.20K FORÇA 0 / 100 AGILIDADE 0 / 800 RESISTÊNCIA 0 / ELE É MUITO MAIS FORTE / RISCO PERIGOSO / SE VENCER: $50 + 10 FAMA / PERDER ENCERRA A CARREIRA (METADE DO LEGADO) / SEM K.O. NO TEMPO… / EMPATE EXATO: FICA COM ELE / VOLTAR A TREINAR / LUTAR!". Screenshot `shots\a720_02_previa_tatica_counter.png`.
2. **OK.** Em todos os 4 adversários o rótulo muda com a tática (`gd\qa_stats.gd`, perfil 1/3, treino em que a melhor dá ~65%): Dudu 1,73 K: counter EQUILIBRADO, outras PERIGOSO; Brutão 25,3 K: counter EQUILIBRADO (0,60), agressivo/defensivo PERIGOSO; Dinho 75,2 K: agressivo/defensivo EQUILIBRADO (0,48 / 0,71), counter PERIGOSO (0,40); Muralha 489 K: agressivo/counter EQUILIBRADO, defensivo PERIGOSO. Na janela real o selo muda ao clicar na tática (`selo_rotulo` lido após clique real). Atenção: no minuto 0 as 3 táticas dão PERIGOSO (esperado, sem treino).
3. **OK.** Risco honesto, estados variados (adversário, treino de 0,15× a 6×, divisão aleatória, 40% com foco único, tática aleatória), rótulo pela prévia (sementes 1..200), resultado com semente nova, **1.500 lutas por rótulo**: fácil **99,4%**, equilibrado **68,6%**, perigoso **2,1%**. Só foco único (6.000 lutas): fácil 98,6%, equilibrado 70,7%, perigoso 3,4%. Todos dentro de ≥ 85 / 40–85 / < 40.
4. **OK.** Janela real: abrir a prévia, clicar nas 3 táticas, clicar VOLTAR A TREINAR: fecha e o estado (menos `play_seconds`) é idêntico ao de antes (`para_save()` comparado). A tática volta à original (`fluxo.gd:_voltar_da_previa`). Nota: se o jogo é **fechado pelo X** com a prévia aberta, a tática trocada na prévia fica salva como "última tática" (inofensivo; ver R6).

### A luta
5. **OK.** 10.000 lutas de estados variados (de 0,05× a 10× o adversário), sem registro de tempo fora do limite: tela mín. **8,00 s**, máx. **19,00 s**; maior instante de evento 15,80 s (< 16 s); K.O. em 95,4% (`gd\qa_stats.gd`). Em janela real as lutas duraram 8,00 / 8,90 / 9,30 / 10,20 / 16,50 / 19,00 s.
6. **OK.** 500 pares (mesmo estado + mesma semente, com registro): lista de eventos idêntica golpe a golpe (`JSON.stringify` igual) e mesmo vencedor.
7. **OK.** Harness de janela real com amostragem por quadro (`hq.gd:verificar_luta`): **mais de 20 lutas** completas de ponta a ponta (a bateria `luta4` de 5 lutas rodou em 1280x720, 1920x1080 e tela cheia; mais a 1ª vitória, a luta do cinturão e a luta com luva). Para cada evento da simulação (barra, número, som, animação do atacante e reação de quem recebe): 8, 8, 8, 17 e 1 eventos na bateria `luta4` (e 15 no cinturão) casaram **sem nenhuma divergência**. Cobriu: golpe normal, crítico (`!` e vermelho), contra-golpe (azul `!`), esquiva ("ESQUIVOU" + som de esquiva), bloqueio com tática defensiva (animação `block`, som de bloqueio), grogue (`tired` de 0,9 s a 5,0 s), K.O. (`ko` no perdedor, `victory` no vencedor, som de queda), fim por pontos (Muralha: 19,0 s, "TEMPO!", vencedor `victory`, outro `tired`). Instante do golpe: o início da animação cai `hit_frame/fps` antes do `t` do evento com **desvio máximo de 6 ms** (3 lutas, 37 golpes, `contato`); quadro no contato = `hit_frame` em todos. Screenshots: `shots\c720_luta_crit_4.png`, `c720_luta_esq_2.png`, `c720_l5_fim.png`.
8. **OK.** Comprada a luva de lona (janela real, clique no botão da loja): cursor `cursor_glove` → `cursor_glove_l1`; mão da garagem `fighter_run` → `fighter_run_glove_l1`; na luta o `idle` já é `fight_player_idle_glove_l1` e **todos** os 46 sprites do jogador durante a luta terminam em `_glove_l1`. Depois de NOVA CARREIRA volta ao cursor e mão da luva velha. Screenshots `d720_13_garagem_luva_l1.png`, `d720_14_luta_luva_l1.png`.
9. **OK.** Mesmo treino total, melhor tática de cada um (`qa_stats`): só Força contra equilibrado 1/3: Dudu 0% × 78%, Brutão 3% × 78%, Dinho 28% × 90%, Muralha 0% × 91%. Só Agilidade e só Resistência também perdem (0–14%). Treino para "fácil" com o equilibrado: 2,10 K / 31,5 K / 82,8 K / 526 K (tabela do design).
10. **OK.** Melhor tática (perfil equilibrado, `qa_stats` e sim): Dudu → contra-ataque (0,775 contra 0,59 / 0,25), Brutão → contra-ataque (0,78), Dinho → defensivo (0,90), Muralha → agressivo (0,91). Cada uma é a melhor em pelo menos 1.
11. **OK.** Fechar pelo X (`WM_CLOSE_REQUEST`, o mesmo caminho do X) com a luta rodando e reabrir em outro processo: **derrota** → reabre na tela de fim, Legado 5 → 6 (+1, uma vez só), `ending` mantido; fechar de novo e reabrir: Legado continua 6 (sem duplicar); NOVA CARREIRA funciona e fechar/reabrir depois mantém Carreira 2, Legado 6. **Vitória** → reabre na tela "VENCEU!", dinheiro 77 → 227 (+150 uma vez), fama 10 → 40; fechar e reabrir não repete o prêmio. Fechar na prévia ou na confirmação de aposentar: reabre na garagem sem perder nada (a prévia e a confirmação não são salvas). Não há como escapar da derrota por fechar.

### Vitória, derrota e aposentadoria
12. **OK.** Janela real: 1ª vitória → "VENCEU! +$50 +10 FAMA +2 LEGADO / LEGADO EM JOGO 2 / PRÓXIMO: BRUTÃO DO POSTO"; HUD depois de CONTINUAR: `$ 50`, `FAMA 10`, `LEGADO EM JOGO 2`, `PRÓXIMA: BRUTÃO DO POSTO PERIGOSO`, `SE VENCER: $150 + 30 FAMA`. Brutão +150/+30, Dinho +400/+60, Muralha +1.000/+100 (+30 de Legado: 20 de fama + 10 do cinturão) conferidos na tela.
13. **OK.** Tela de fim (janela real) mostra quem venceu e quando ("DINHO PULGA VENCEU NO 1º ROUND"), motivo com número ("FALTARAM 70.3K DE RESISTÊNCIA PRA AGUENTAR"), estatística, dica ("MAIS ESTEIRA. FÔLEGO TAMBÉM LUTA"), resumo (vitórias, cinturões, fama, dinheiro ganho, tempo de jogo), Legado ganho e total. Legado = 50% do pote conferido em fama 10/40/100/200 (1/4/10/20) e nos 4 fins de carreira jogados. Ver B1, B2, B3, B4 sobre qualidade do texto.
14. **OK (28 de 28; 2 quase-empates).** 28 derrotas reais variadas (14 de qualquer estado + 14 só com prévia entre 20% e 85%; 40% com foco único; 4 adversários; 3 táticas), pelo jogo (`gd\qa_motivo.gd`, `qa_motivo2.gd`): o atributo escolhido pelo jogo foi comparado com uma busca independente com sementes novas (400 por ponto, 12 passos). Concordam em 26 de 28; os outros 2 foram quase-empates (falta 23,8 K de Força contra 24,4 K de Resistência; 32,1 K contra 34,2 K, diferença de 2–7%). A dica sempre veio do mesmo atributo (`tip_<atributo>`), 28 de 28. Como no design (§13.7), o QA escolheu derrotas com prévia < 85%. Ver B3 para derrota com prévia FÁCIL e B4 para a estatística.
15. **OK.** Da tela de fim até a garagem: **1 clique, 0,05 s** (janela real). Volta como "CARREIRA 2", treino 0, dinheiro 0, fama 0, escada 0, luva velha, Legado total mantido (6; 75 depois de uma aposentadoria com cinturão).
16. **OK.** APOSENTAR habilitado entre lutas e **desabilitado** durante a luta, na prévia (janela modal) e na tela de fim (e LUTAR! junto). A confirmação mostra o que leva ("VOCÊ LEVA 0 DE LEGADO" com pote zerado; "VOCÊ LEVA 75 DE LEGADO / INCLUI +25 POR SAIR COM O CINTURÃO / TUDO DESTA CARREIRA SE PERDE" com cinturão). CONTINUAR cancela sem mudar nada. Aposentar com 0 funciona (+0), com cinturão leva 75 (= 50 + 25). Propriedade em 4.000 estados (fama 0–1999, com e sem cinturão): **aposentar ≥ perder sempre, e > quando o pote ≥ 1**, zero violações.
17. **OK.** Depois do cinturão: LUTAR! desabilitado (clicar não abre nada), tela "CINTURÃO AMADOR" com "ACADEMIA DE BAIRRO LIBERADA (EM BREVE)" e "NÃO HÁ MAIS LUTAS NESTA VERSÃO. APOSENTAR VALE MAIS.", HUD "SEM MAIS ADVERSÁRIOS POR ENQUANTO". Botões visíveis na tela do cinturão: só CONTINUAR. Botões da garagem: nada de local, árvore ou artes. Screenshots `e720_22_cinturao.png`, `e720_23_garagem_pos_cinturao.png`.

### Dinheiro e loja
18. **OK.** Nelson custa $50 = prêmio da 1ª vitória; luva de lona $120 cabe em 2 vitórias ($50 + $150). Conferido na janela real (comprou Nelson $400 → $350; comprou a luva $400 → $280).
19. **OK.** Luva de lona multiplica por 2 o clique dos 3 aparelhos (saco, corda, esteira: 1,0 → 2,0 cada); cliques reais deram 2,0 (e 6,0 no crítico); cursor, mão da garagem e mão da luta trocam juntos (critério 8). A luva de couro (x2 de novo = x4) foi verificada por `test_fight_game` (passou); na janela real eu não consegui repetir o passo do couro (erro do meu roteiro, a luva de lona já havia sido comprada de novo depois de NOVA CARREIRA), então o couro não foi visto na tela por mim.
20. **OK.** Nelson aparece na sala na 1ª compra (sprite visível, `shots\d720_11_nelson_na_sala.png`). Compra não mexe em Treino nem em atributo. Sem dinheiro: Nelson e luva recusados com clique real (quantidade e saldo iguais; botão "FALTA DINHEIRO"). Com fim ou luta pendente `comprar_*` e `clicar()` retornam recusa (`qa_save3`).

### Metas de tempo
21. **OK.** 1ª vitória aos **3:30** de jogo (bot clicando a 5 cliques/s com cliques reais, janela real). Simulador: 2:00 (8/s), 3:00 (5/s), 3:31 (4/s), 4:01 (3/s). Todos dentro de 2–5 min.
22. **PARCIAL.** Simulador (40 carreiras por linha, `saco`, luta em "equilibrado"): mediana da derrota 12:44 (5/s), 14:14 (4/s), 16:14 (3/s), 9:14 (8/s): as medianas estão dentro de 10–15 min (4–5/s) ou da folga de ±3 min (3 e 8/s). Mas **só 38–40% das carreiras terminam dentro da janela 10–15 min** e o p90 da derrota é 49–52 min: ~25–28% das carreiras "saco" (foco fixo) sobrevivem e conquistam o cinturão aos 37–58 min. Quem luta com impaciência perde antes (8:44–9:44, abaixo da janela). Na minha partida de QA (bot, foco no saco, luta em "equilibrado"), a 1ª carreira só acabou aos **63,7 min** (3 vitórias aos 3,5 / 18,2 / 23,9 min, esperou ~40 min a 3,5 K de Força no "perigoso" contra o Muralha e perdeu a luta "equilibrado"). O `fase3-design.md` §13.9 já lista isso como "fecha pela metade".
23. **PARCIAL.** O lado positivo fecha: o jogador bom (`bom`, luta só em "fácil") conquista o cinturão aos **26:26 (8/s), 33:58 (5/s), 36:28 (4/s), 40:29 (3/s, no limite)**. O segundo lado, "o jogador típico não chega ao cinturão na 1ª carreira", **não fecha**: o `saco` típico conquista o cinturão em 20–28% das carreiras (37:20 a 57:52). Ver R1.
24. **PARCIAL.** Simulador: depois de perder para o Dinho (caso típico) e seguir a dica, vence esse adversário em **4 de 5** (11:31); contra o Brutão 1 de 1; contra o Dudu 1 de 1; contra o Seu Muralha só **5 de 17** (36:04). Jogando uma vez (bot, janela real) seguindo a dica (esteira ou corda alternando com o saco a cada 60 s), a 2ª carreira **não** venceu quem tinha derrotado: perdi de novo no "equilibrado" (para o Dinho aos 18,5 min com 31,9K/0/25,4K, e uma segunda tentativa para o Brutão aos 14,2 min). Uma amostra de 2; mas confirma o alerta do designer: seguir a dica **e** lutar quando "equilibrado" ainda dá derrota frequente. Observação: a dica depois da 1ª derrota do `saco` contra o Muralha foi "AGILIDADE" (faltaram 29,5K), não "Resistência" como o §13.7 do design afirma para o só-saco típico; o motivo continua coerente com o número, só difere do texto do design.

### Dados, save, saúde
25. **OK.** `tests/test_fight_game.gd` troca `prize_money` (777) e atributo de adversário em JSON de teste e confirma que o jogo muda; os JSON de `data/` são lidos no start sem código (`FightData.carregar`). Os valores de `data/opponents.json` batem com a tabela do design.
26. **OK.** Save v2 (formato da Fase 2: treino 123.456,5; atributos 90K/20K/13,4K; foco esteira; geradores 12/3; melhorias 2/1/0) abre como **Carreira 1**, tudo mantido, `permanent` zerado (`legacy_total 0, career_number 1`), `paid_generators 0`, tática `defensive`, `ladder_index 0`; HUD mostra "PRÓXIMA: DUDU ALONGADO FÁCIL" e a prévia lista os atributos migrados. O arquivo vira v3 no próximo save. (Não existia save real da Fase 2 na máquina; usei um v2 escrito no formato do `fase2-api`.) Também passam em `test_migration` (v0 → v3).
27. **OK.** Fechar e reabrir em qualquer ponto volta a estado coerente sem duplicar nem perder Legado: garagem, prévia, luta (derrota e vitória), tela de fim (2 aberturas), confirmação de aposentar, depois de NOVA CARREIRA (ver 11). Saves ruins (`gd\qa_save3.gd`): luta salva fora da vez ou com adversário inexistente é descartada com aviso; `belt: true` sem escada completa vira false; `glove_level 9` vira 2; tática inválida vira `defensive`; dinheiro negativo vira 0; `ending` com tipo desconhecido é descartado; versão 99 bloqueia sem sobrescrever; JSON lixo e arquivo vazio começam jogo novo (guarda `.corrompido`). Luta salva com resultado diferente da simulação: vale o salvo (aviso).
28. **OK.** `run_tests.ps1` passa inteiro; o guarda fotografa todos os arquivos da pasta do save real (um arquivo só) e passou antes e depois.
29. **OK.** Sessão com 2 carreiras completas (1ª de 63,7 min e 2ª de 24 min de tempo de jogo, rodadas a 8× de velocidade, com cliques reais, compras, 7 lutas e 2 telas de fim) + as demais rodadas: nenhum `SCRIPT ERROR`, nenhum `ERROR`/`WARNING` do jogo no console (só o aviso de vazamento ao fechar o processo do meu harness; a cena principal pelo `--quit-after 300` sai limpa). Árvore, artes e mudança de local não aparecem (lista de botões visíveis conferida).
30. **PARCIAL (sem meio de testar o DPI).** 1280x720: tela da luta lê bem. 1920x1080 em janela: a janela fica com 1.061 px úteis (barra de título), então a escala inteira fica em **2×** com faixas pretas grandes (era assim na Fase 2 por `scale_mode integer`); em **tela cheia** a escala é **3×** e fica perfeita. Os dois passaram nas 5 lutas de conferência (26/26 verificações). DPI de 125% do Windows: não consegui simular nesta máquina.

## 5. Bugs e observações

Nenhum bug bloqueante (nenhum travamento, perda de save, duplicação de Legado/prêmio, ou fuga da derrota).

| Id | Gravidade | Dono | Resumo |
|---|---|---|---|
| B1 | Baixa | ui | Legado ganho pisca +1 → +0 → +1 na tela de fim |
| B2 | Média | design | "FALTARAM n" some quando o jogador luta cedo demais |
| B3 | Média | design / texto | Derrota por azar numa luta FÁCIL mostra "FALTARAM 3 DE RESISTÊNCIA" |
| B4 | Baixa | texto / design | Estatística sem sentido: "ELE BATIA 0% MAIS FORTE", "…20982% MAIS FORTE" |
| B5 | Baixa | programador | Engasgo de ~160 ms (aos 2,0 s da luta) nas lutas que o jogador perde |
| B6 | Baixa | ui | Letreiro "1º ROUND" cobre a placa "BORRACHARIA" e fica ilegível |
| B7 | Muito baixa | programador | Save editado à mão: escada completa sem cinturão; tela de fim incompleta |

### B1 — Legado ganho pisca (+1 → +0 → +1)
- **Passos:** carreira com 1 vitória (fama 10) → perder a próxima luta → olhar "LEGADO GANHO" por 1,5 s.
- **Esperado:** a contagem sobe de 0 até o valor (ou fica no valor).
- **Obtido (medido em janela real):** +250 ms: "+1, total 0"; +600/+900 ms: "+0, total 0"; +1.400 ms: "+1, total 1". É o que o Produtor viu no screenshot 12.
- **Onde:** `ui/janela_fim.gd:122-126` (rótulo criado já com `"+%d" % _ganho`) e `ui/janela_fim.gd:157-169` (animação zera e conta de novo; `floorf(_ganho * p + 0.0001)` dá 0 até p ≈ 1 quando o ganho é 1). O "Legado total" também fica mostrando o total antigo até o fim da animação.
- **Sugestão:** mostrar o valor final desde o 1º quadro e animar só um brilho, ou começar a contagem do valor e usar `ceil`. Para ganhos de 1 a 4 não vale contar.

### B2 — "FALTARAM n" ausente quando a falta passa de 16 × T + 1000
- **Passos:** carreira nova, treinar ~1 min, LUTAR contra o Brutão (perigoso), perder.
- **Obtido:** linha principal "ELE TIROU 100% DA SUA VIDA EM 1 GOLPE" (estatística), sem número do que faltou; dica ainda aponta o atributo certo.
- **Medido** (`gd\qa_front.gd`, só-saco): o "FALTARAM" some abaixo de T ≈ 300 (Dudu), 3 K (Brutão), 10 K (Dinho), 50 K (Muralha). Acima disso aparece (28 de 28 nas minhas derrotas típicas).
- **Onde:** `scripts/luta.gd:284-295` (teto `search_max_share × T + 1000`), `data/fights.json` `reason.search_max_share 16`; texto em `scripts/game_state.gd:812-817`.
- **Sugestão (design):** teto relativo ao adversário (por exemplo `max(16×T+1000, 2× o total do adversário)`), ou frase de fallback do tipo "FALTA MUITO MAIS: ELE TEM {n}× O SEU …". O escopo pede o número "comparando atributos".

### B3 — Derrota com risco FÁCIL (azar) vira "FALTARAM 3 DE RESISTÊNCIA"
- **Passos:** (`gd\qa_easyloss.gd`) Dudu, T = 3.000 (1/3 cada, prévia 100%): a 204ª tentativa deu derrota.
- **Obtido:** "FALTARAM 3 DE RESISTÊNCIA PRA AGUENTAR / ELE TIROU 100% DA SUA VIDA EM 3 GOLPES / RESISTÊNCIA PRIMEIRO. DEPOIS A LUTA".
- **Por quê é ruim:** o jogador já estava "fácil"; faltar "3" é nada. O jogo se explica como se faltasse treino, mas foi azar (1% de chance). Contradiz "nunca o jogo me roubou". Também o critério 3 permite ≥ 15% de derrota em "fácil".
- **Onde:** `scripts/game_state.gd:659-684` (`_calcular_motivo` não sabe que a chance era alta), `scripts/luta.gd:304-327`.
- **Sugestão:** se a chance da prévia (tática usada) ≥ `easy_min`, trocar o motivo por uma frase "FOI AZAR: ELE ACERTOU {k} CRÍTICOS" (texto novo do Roteirista) e manter a dica "tente de novo".

### B4 — Estatística sem sentido
- **Exemplos (`qa_motivo.gd`):** decisivo Força com "ELE BATIA 0% MAIS FORTE" (Dinho, prévia 56%) e "ELE BATIA 20982% MAIS FORTE" (Brutão, T = 8,6 K só-agilidade).
- **Onde:** `scripts/luta.gd:351-356` (`n = 100 × (dele/meu − 1)`; "meu" pode ser quase 0 ou maior que "dele").
- **Sugestão:** limitar a 3 casas ("MAIS DE 10×") ou trocar por "ELE BATE {n}× MAIS FORTE"; quando `n ≤ 0` usar a outra estatística (esquivas, críticos).

### B5 — Engasgo na derrota
- **Medido (janela real, GPU a ~160 fps):** maior intervalo entre quadros **159 ms**, no instante t = 2,00 s da luta, que é onde `tela_luta.gd:307` chama `GameState.motivo_da_luta()` (só em luta perdida). `qa_perf.gd`: motivo custa 95–190 ms (prévia 7–14 ms, HUD 1,4–3,7 ms). Numa máquina mais lenta pode passar de 0,5 s com a luta rodando.
- **Onde:** `ui/tela_luta.gd:306-307`, `scripts/game_state.gd:648-656`.
- **Sugestão:** calcular em fatias (por frame) ou em `Thread`; ou antes de começar a animação, já que a luta é decidida no LUTAR.

### B6 — Letreiro sobre a placa
- **Onde:** `ui/tela_luta.gd:147-149, 627-636` (letreiro centralizado em y ≈ 96–100, mesmo lugar da placa "BORRACHARIA" da arena). Screenshot `shots\d720_14_luta_luva_l1.png`: "BORRACHARI 1º ROUND". Sugestão: fundo escuro atrás do texto ou mover o letreiro.

### B7 — Saves editados à mão
- `ladder_index` ≥ 4 com `belt: false` (`game_state.gd:983-984`) deixa "escada completa sem cinturão" (LUTAR! some, sem Legado de cinturão). Tela de fim com campos faltando mostra " VENCEU POR PONTOS" sem nome. Só aparece se o jogador editar o JSON; fica como risco.

### Observações (não são bugs)
- Textos e acentos: sem palavra sem acento nos JSON de `data/` nas chaves da fase; singular tratado (`1 VITÓRIAS` → `1 VITÓRIA`; `1 GOLPES` → `1 GOLPE`; `1 CRÍTICOS` → `1 CRÍTICO`; `FALTARAM 1 DE` → `FALTOU 1 DE`, `gd\qa_sing.gd`). Falas do adversário (`entry`, `wins_line`, `loses_line`) não aparecem (Fase 8, correto).
- A tela de vitória diz "+2 LEGADO" (Legado **em jogo**); numa leitura rápida parece Legado total. A linha de baixo explica ("LEGADO EM JOGO 2"), então só aviso.
- Depois de NOVA CARREIRA a dica "CLIQUE NO SACO PARA TREINAR" reaparece (esperado, carreira nova).
- Dica de tática (`tip_tactic`) aparece só quando outra tática era ≥ 25 pontos melhor: apareceu nas derrotas em que fazia sentido, nunca no lugar da dica do atributo.

## 6. Riscos
- **R1 (balanceamento, o mais importante):** os critérios 22/23/24 não fecham juntos (o designer já avisava). O jogador "saco" que só luta em "equilibrado" tem ~38–40% de chance de acabar em 10–15 min, mas 25–28% atravessa a escada inteira (37–58 min) e metade do resto fica preso no Seu Muralha por 40+ minutos antes de perder (minha partida: 63,7 min). Isso é uma decisão do dono/Diretor: relaxar a meta ou mexer em Seu Muralha / Dinho. As alavancas estão em `data/` (nenhum código).
- **R2:** com a regra "luta em equilibrado" (~50% de vitória na 1ª vez), muita derrota vem de sorteio, não de erro; a tela de fim explica o atributo e a dica, mas B3 mostra que o texto pode culpar o treino quando foi azar.
- **R3:** o Legado de uma derrota típica é 1 a 10, e a tela diz que "vai servir na próxima versão". Honesto, mas o 1º impacto (B1: "+0") pode parecer castigo puro.
- **R4:** o motivo (até 9.000 lutas na hora, 95–190 ms aqui) não escala em PC fraco (B5).
- **R5:** não testei DPI 125% nem áudio audível (só o instante/tipo de cada som via sonda no `Sfx`).
- **R6:** fechar o jogo com a prévia aberta guarda a tática trocada na prévia como "última tática" (inofensivo).

## 7. Como reproduzir o que o QA fez

```
# testes do projeto
powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1
# simulador
"C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" E:\Fightclicker\tools\sim\fase3_sim.py carreiras
# jogo com cliques sintéticos (janela real, save isolado), modos: p1, primeira_vitoria, luta4, loja, cinturao, reopen_a/b/c/d, migr, contato, hitch, carreira2
godot --path E:\Fightclicker --resolution 1280x720 --script <scratchpad>\qa3\gd\hq.gd -- --save-dir=user://test/qa3/ <modo> <prefixo>
```
