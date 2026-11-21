# Fase 7b2 (2ª passiva das 3 artes) — relatório do QA

Pasta `E:\Fightclicker\.claude\worktrees\continue-agents-config-722700`, sem commit, nenhum código de `scripts/`, `scenes/`, `ui/`, `data/` alterado. Tudo com `APPDATA` temporário (`C:\Users\deivi\AppData\Local\Temp\qa7b2\appdata`): o save real do dono nem foi tocado (`save.json` segue com a data de 20/11 15:04) e a "cópia do save do dono" foi aberta numa pasta de teste. Um Godot por vez; janela só no `ui_audit` (`--max-fps 30 --position 1950,40`, uma vez). Para comparar com a main usei uma cópia isolada de `HEAD` (3cbb19b = main com a 7b1), apagada depois. Logs e capturas em `C:\Users\deivi\AppData\Local\Temp\qa7b2\` (capturas `f7b2_*` em `caps\`).

## Veredito
**Ainda NÃO está pronto para o Diretor: 1 bug de tela (B1) reprova o critério "letreiros acima dos números de dano".** O resto passa: suíte verde, prévia honesta nas médias, meta, escolha, save, duração, balanço pela mediana e `ui_audit` com 0 problemas. B1 volta para o UI/UX; os demais itens são cosméticos ou observações para o Diretor.

## Automáticos
| Item | Resultado |
|---|---|
| `tools/run_tests.ps1` (suíte inteira, headless) | **OK** — "TODOS OS TESTES PASSARAM": 4.617 de 4.617 PASS nos 35 arquivos, 0 FAIL, 0 erro de script (inclui `test_fase7b2`, `test_fase7b1`, `test_migration`, `test_save`, guarda do save real, cena principal 120 quadros) |
| `ui_audit --estados todos` (janela, 1 vez) | **OK pelo verificador**: `ESTADOS 470 \| PROBLEMAS 0`. Capturas `f7b2_*` olhadas (23). **Mas veja B1 e B2** (o verificador não mede número de dano sobre letreiro) |
| `foto.gd` x main (7b1) | **OK, só campos novos.** Depois de tirar `effect_text_2`, `art_passive` (prévia), `passive_goal/passive2_*` (resumo da vitória) e `art_passive/last_passive/passive_wins/passives_unlocked` (save), o arquivo de 713 linhas fica **idêntico byte a byte** ao da main. Sem arte, nada mudou |
| `fase7b2_sim.py ident` | **OK**: sem arte 3000/3000, Boxe 3000/3000, Jiu-jitsu 3000/3000, Muay Thai 3000/3000 idênticas ao motor da 7b1 (1ª passiva intocada) |
| `fase7b2_sim.py limiar` | Igual ao design (§7.4) |
| `fase7b2_sim.py campanha` (100 jogadores x 6 campanhas) | Ver critério 11 |

## Critérios de aceite (escopo §7, 9–14)
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 9 | 2ª passiva só aparece liberada depois da meta; progresso no cartão confere com o que o jogador fez | **OK** | Lutas REAIS (`tests/qa_f7b2_extra.gd`, `gs.lutar()` + `concluir_luta()`, 400 tentativas no máximo): Boxe 15 vitórias (12 por pontos, 3 por `knockout`) -> progressão 1, 2, 3; Jiu-jitsu 9 vitórias (6 pontos, 3 `submission`) -> 1, 2, 3; Muay Thai 5 vitórias (2 pontos, 3 `spin_kick`) -> 1, 2, 3. Vitória por pontos/dano nunca contou (0 contagens erradas), com 2/3 o cartão segue travado, a 3ª libera e o aviso sai 1 vez; depois de liberada, 30 lutas seguidas: 0 avisos novos. Progresso das outras 2 artes ficou em 0. Capturas `f7b2_arte_2de3` ("2/3 K.O. DE EMBALO", "1/3 FINALIZAÇÕES", "2/3 CHUTES RODADOS" com barra e cadeado), `f7b2_arte_liberada`, `f7b2_arte_selecionada` (a destravada fica com estrela/moldura), `f7b2_fim_meta` ("1/3 K.O. DE EMBALO") |
| 10 | Escolha real: cada 2ª pede outro foco/tática; testador diz qual passiva está ativa olhando | **OK com ressalvas** | Tabela do design §7.3 confere com o simulador. Em lutas do motor (600 vitórias por linha, Tonhão e Kid, 1,05x), o sinal próprio da 2ª passiva aparece em: Contragolpista **100%** das vitórias (a carga sobe em toda luta; a 1ª passiva dá 0%); Por cima **88–98%** (luta no chão); Clinch **50–65%** vs Tonhão e **64–86%** vs Kid (a 1ª passiva, Canela, **0%** de clinch e 100% de perna marcada). Letreiros do fim: ver B1. Ressalvas: R1 e R2 abaixo |
| 11 | 6 combinações a ≤ 15% (tempo até o Kid); nenhuma 2ª vence a 1ª em todos os adversários | **OK pela mediana (decisão do dono)** | Campanha 100x6, tempo até o 1º Kid: **4/s** mediana 40:47 a 41:50 (**2,6%**), média 44:45 a 47:25 (6,0%); **3/s** mediana 45:52 a 46:41 (**1,8%**), média 51:36 a 61:39 (**19,5%**, só o Por cima 61:39 e a cauda dele; igual ao que o Designer documentou, 20,5%). Por cima é a única 2ª pior que a 1ª em 1 adversário só (Dinho: 0,487 contra 0,476 no amarelo); as outras 2ª são piores no verde de 4 a 5 adversários. Nenhuma vence em todos |
| 12 | Prévia honesta (±5) com as 6 combinações | **OK nas médias; estados isolados passam de 5 pelo ruído das 200 sementes** | Ver seção "Prévia honesta" abaixo: 2.251 estados x 1.000 lutas; diferença média por adversário de -3,3 a +2,2 pontos; pior estado 10,3 pontos |
| 13 | `run_tests.ps1` verde com save de teste; janelas no 2º monitor; cópia do save do dono abre sem erro | **OK** | Suíte acima. Cópia do save real (4.496 bytes, boxe, escada 0, 3 artes liberadas) aberta em pasta própria com `tests/qa_f7b2_copia.gd`: 5/5 PASS, 0/3 nas 3 artes, travadas, passiva 1, salva na cópia |
| 14 | `ui_audit` com 0 problemas, estados da 7b2 | **OK pelo verificador, com B1/B2** | 470 estados, 0 problemas. Estados 7b2 presentes: 3 cartões com cadeado e progresso (0/3 e 2/3, liberada, selecionada), prévia Boxe Agressivo/Contra-ataque, Jiu-jitsu Defensivo e "tarde", Muay Thai Agressivo e "tarde", carga 0 a 3, letreiros nas duas arenas (K.O. NO CONTRAGOLPE! liga e borracharia), Jiu-jitsu no chão/levantou/juiz parou, clinch e joelhada, fim com meta e com liberação |

## Prévia honesta (critério 12; item 2 do pedido)
`tests/qa_f7b2_previa.gd`: 3 passivas novas x extra do nó 0,0 e 0,5 x 6 adversários (Dudu, Brutão, Dinho, Muralha, Tonhão, Kid) x 40 estados aleatórios (total de 0,5x a 1,3x o do adversário, divisão aleatória) x 3 táticas, descartando estados saturados (chance < 3% ou > 97%). **2.251 estados, 1.000 lutas reais em cada** (2,25 milhões de lutas, 187 s). Diferença = vitória real - chance mostrada.

| Passiva (nó) | Estados | \|dif\| média | Viés (real - mostrada) | Pior | Estados > 5 pts |
|---|---|---|---|---|---|
| Contragolpista (sem nó) | 422 | 1,84 | -0,03 | 9,3 | 20 |
| Contragolpista (nó) | 408 | 2,10 | +0,20 | 7,4 | 29 |
| Por cima (sem nó) | 365 | 2,32 | -1,45 | 10,3 | 33 |
| Por cima (nó) | 342 | 2,03 | -0,61 | 7,7 | 27 |
| Clinch (sem nó) | 358 | 2,24 | -0,90 | 8,6 | 32 |
| Clinch (nó) | 356 | 2,58 | -1,46 | 9,5 | 47 |

- **Diferença média por adversário:** de **-3,3** (Clinch com nó contra o Brutão) a **+2,2** (Contragolpista com nó contra o Kid). Todas dentro de ±5.
- **Estados individuais:** 188 de 2.251 (**8,4%**) passam de 5 pontos; o pior é **10,3** (Por cima, Brutão, Contra-ataque: mostrada 34,5%, real 24,2% em 1.000 e **26,4% em 8.000** lutas). Os 6 piores estados, remedidos com 8.000 lutas, ficam entre -4,7 e +5,9 (um deles -8,1). A prévia usa 200 sementes fixas, com erro-padrão de até 3,5 pontos; com 2.251 estados é natural aparecer um erro de 3 desvios. É o mesmo padrão da 7b1 (pior estado 5,0 e 7,0).
- **Viés pequeno e com sinal:** Brutão e Dudu têm a prévia otimista em 2 a 3 pontos nas três artes (Brutão: Jiu-jitsu -2,8/-2,6, Muay Thai -2,8/-3,3, Boxe -1,9/-2,0). Não passa de 5, mas é constante, vale o Designer olhar se o fator de amador do motor ainda cabe.
- **Resposta ao pedido:** o "pior estado 5,3 com 200 sementes" do Programador é ruído de uma amostra; medido de novo com 1.000+ lutas por estado, a **prévia passa pela média por adversário (±5)** e por 91,6% dos estados individuais. **Não passa se o critério for "todo estado individual a ±5"** (pior 10,3). Quem decide é o Diretor (ver R3).

## Meta, aviso e fala do mentor (item 3 do pedido)
Tudo com lutas reais do jogo (`gs.lutar()` + `concluir_luta()`), além dos casos montados do `test_fase7b2`:
- **2 de 3 trava, a 3ª libera** nas 3 artes; `passive2_unlocked` e a linha "NOVO JEITO DE LUTAR: {NOME}. ESCOLHA NA PRÓXIMA CARREIRA" saem **uma vez só** (1 aviso por arte; 0 em 30 lutas seguintes; captura `f7b2_fim_libera`).
- **Não contam:** vitória por pontos/dano, vitória com a 2ª passiva (60 lutas reais do Contragolpista no Contra-ataque: nenhuma contou, `passive_wins.boxing` ficou em 3), vitória de uma arte somando em outra, 1ª carreira sem arte (20 lutas: nada somou). Fim de outra arte (ex. `spin_kick` com o Boxe) não conta (`test_fase7b2`).
- **Soma da linhagem:** duas carreiras diferentes do mesmo Jiu-jitsu somam 2/3 (`test_fase7b2`); depois da nova carreira (aposentar + `nova_carreira()`) `passive_wins.bjj` e a liberação continuam.
- **Fala do mentor:** 1 gatilho `passive2_<arte>_unlocked` na fila por arte; `dialogos.candidatas` devolve 1 fala antes e 0 depois de vista (`test_fase7b2`). Não vi o balão na tela (o audit não tem estado para a fala).

## Escolha, carreira e save (itens 4 do pedido)
- **Só liberada:** 2ª travada recusada nas 3 artes e a escolha segue pendente; liberar o Jiu-jitsu não libera o Boxe; passiva 3 recusada (`qa_f7b2_extra.gd`, 601/601 PASS).
- **Vale a carreira toda:** sem troca no meio (nem de passiva nem de arte); luta real da carreira usa `top_control`, `art_passive` 2.
- **Nova carreira:** `aposentar()` + `nova_carreira()` -> escolha pendente, sem arte, passiva 1 até escolher, cartão do Jiu-jitsu destravado e marcado na 2ª (`last_passive`); dá para escolher a 1ª e o motor volta para `submission`.
- **Save antigo** (arquivo v13 sem nenhum campo 7b2, aberto pelo caminho normal): 0/3 nas 3 artes, travadas, passiva 1; salvar e reabrir cria os campos.
- **Save sujo/corrompido (16 casos aplicados a um jogo, salvos de volta, telas montando):** `passive_wins` array/string/valores string-null-NaN/1e30/-1e30, `passives_unlocked` inteiro/dict/lixo com duplicata, `last_passive` tipos errados e string, `art_passive` 2 sem meta (e com a arte vazia), "2", 99, -1, null, 2.0 com a meta batida só por `passive_wins` (libera ao carregar), `finish` de 2ª passiva numa carreira de 1ª. Em todos: campos sanados (inteiros >= 0, só artes com `passive_2`, sem duplicata); com `art_passive` 2 sem meta volta para 1 com aviso no console. Arquivo truncado ao meio: abre pelo backup/jogo novo sem erro. `VERSAO_ATUAL` continua 13.

## Reconhecimento (critério 10; item 5 do pedido)
Dados por luta do motor (vitórias, 600 lutas por linha), "sinal" = carga >= 1 (Contragolpista), jogador no chão (Por cima), clinch ou perna marcada (Muay Thai):
- **Contragolpista:** sinal em 100% das vitórias contra Tonhão e Kid nas 3 táticas; a 1ª passiva (Mão rápida) em 0%. O fim **K.O. NO CONTRAGOLPE!** (`counter_ko`) só sai em parte das lutas: com o jogador a 1,05x do adversário, Contra-ataque 0–4% (ganha por pontos, 43 de 43 vitórias reais com 1,0x), Agressivo 14–20%; nos estados apertados do design (0,8x a 0,9x, Kid/Tonhão) o Contra-ataque leva **5 a 6 de cada 10 vitórias** ao K.O. (`qa_f7b2_ko.gd`: por exemplo Kid 0,9x 1/1/1: Contra-ataque 5,1 em 10, Agressivo 1,4 em 10). A prévia avisa com "N EM 10".
- **Por cima:** no chão em 88–98% das vitórias; fim **O JUIZ PAROU!** em 25–39% (Agressivo), ~0% no Defensivo/Contra-ataque a 1,05x; nos 0,9x do Kid, 3,6–6,3 em 10.
- **Clinch:** clinch em 50–65% das vitórias contra o Tonhão (a prévia já diz "SÓ PRENDE EM n DE 10 LUTAS" quando < metade) e 64–86% contra o Kid; fim **JOELHADA!** em 0–6% a 1,05x e 2–4 em 10 a 0,8–0,9x.
- **Letreiros acima dos números de dano: FALHA (B1).** `f7b2_luta_cp_ko_liga`, `f7b2_luta_cp_ko_borracharia` e `f7b2_luta_mt_joelhada` mostram números de dano ("88K!", "580K", "110K!", "51M!") desenhados POR CIMA das letras do letreiro. `f7b2_luta_jj_juiz` e `f7b2_luta_jj_levantou` não têm número sobre o texto, mas porque os números estavam em outro ponto.

## Duração (item 6 do pedido)
- 2ª passivas: `t_end` mínimo **5,00 s**, máximo **16,00 s** em 2.251 estados x 1.000 lutas (as 3 passivas, 6 adversários, 3 táticas) => na tela (+3 s) **8,0 a 19,0 s**. Campanha simulada (robô): 8,2–9,3 s de média, mínimo/máximo 8,0–19,0 s nas 12 linhas.
- 1ª passiva e luta sem arte: idênticas à 7b1 (simulador 3000/3000 e foto idêntica; `test_fase7b1` com os 360 casos da 7b1 e os da 7a1 passa).

## Valores extremos e soak
- `qa_f7b2_extra.gd` (extremos): 3 passivas novas x extra do nó (0, 0,5, 1e9, -3) x 13 cenários (zeros, adversário zero, ambos zero, 1e300, 1e-300, negativos, só FORÇA/AGILIDADE/RESISTÊNCIA, adversário só RESISTÊNCIA 1e9, NaN, INF) x 3 táticas: chance em [0,1], `t_end` <= 60, `estado_passiva`, `share`/`at`/`charge_med` e carga 0–3 todos finitos. Nenhum erro.
- `qa_f7b2_soak.gd` (robô aleatório, 4 carreiras x 6.000 passos, escolhendo arte e passiva 0/1/2, comprando nós e lutando nas 3 táticas, aposentando): 0 erro de script, treino/dinheiro finitos, 0 violações de invariante (passiva 2 só com a meta; fim de 2ª passiva só com a 2ª; contagem nunca negativa).
- Compra sem dinheiro e outras regras de loja não mudaram nesta fase (nada novo a testar além do que o `test_fase7b2` e a suíte cobrem).

## Balanço e meta no tempo (decisões do dono: meta 3, mediana)
- Tempo até o 1º Kid, mediana: 4/s 40:47 a 41:50; 3/s 45:52 a 46:41. Metas da visão intactas (1ª carreira 13:56 e 15:26; cinturão na campanha 2).
- Quanto leva a meta de 3 com o robô padrão (campanhas COM a arte; mediana; p90; nunca em 6): Boxe 3; 4; 2 de 100 (3/s) e 3; 4; 0 (4/s); Jiu-jitsu 2; 3; 0; **Muay Thai 3; 5; 7 de 100 (4/s) e 4; nunca; 13 de 100 (3/s)**. O escopo pediu "cerca de 2 campanhas"; Boxe e Muay Thai ficam em 3 a 4 na mediana (R4).

## Bugs
**B1 — média — Os letreiros do fim da 2ª passiva ("K.O. NO CONTRAGOLPE!" e "JOELHADA!") ficam atrás dos números de dano.**
Como ver: `f7b2_luta_cp_ko_liga.png`, `f7b2_luta_cp_ko_borracharia.png` e `f7b2_luta_mt_joelhada.png` (ampliar o meio da tela). Números como "88K!", "580K", "47K", "110K!" e "1/?/J0" (vermelhos) cobrem partes das letras do letreiro. O pedido era "confirmar que os letreiros ficam acima dos números". Pelo código o letreiro tem `z_index = 1000` (`ui/tela_luta.gd:294`, em `_mundo` de z 100) e os números `900 + 50 + n` (`tela_luta.gd:1264`), então deveria ganhar; a captura mostra o contrário, então a causa está em outro ponto (ordem real de desenho / camada dos números do crítico / captura do audit antes do letreiro subir). Gravidade: não trava nada, mas o final da luta fica sujo justamente no momento de reconhecer a passiva. Quem corrige: **UI/UX** (`ui/tela_luta.gd`, `_montar_letreiros_fim`/`_banner_fim_mostrar`, e conferir `ui/sala.gd` `Numero.definir_z`). O B2 da 7b1 era o mesmo problema no letreiro do chute rodado. Depois de corrigir: repetir o `alinhamento-ui` **olhando** as 3 capturas.

**B2 — baixa (cosmético, provavelmente da 7a) — O selo "ÚLTIMA: BOXE" cobre o topo do "E" do título BOXE no cartão** (`f7b2_arte_*`, ampliar o título do cartão da esquerda). O selo (`janela_arte.gd`, `art_last`) já existia antes da 7b2; confirmo só que o "E" fica com o topo achatado. Quem corrige: UI/UX, se quiser (subir o selo 1–2 px ou deslocar à direita).

Nenhum bug de lógica, de save, de meta ou de balanço encontrado.

## Observações e riscos (decisão do Diretor)
- **R1 — Reconhecimento do Clinch:** em 35–50% das vitórias contra o Tonhão o jogador nunca prende (Clinch só com ele <= 80%, 15% por acerto no Agressivo), então um testador que veja só uma luta dessas não vê o clinch. A prévia já avisa ("SÓ PRENDE EM 0 DE 10 LUTAS" na captura `f7b2_previa_mt_tarde`), mas o critério 10 fica frágil no Agressivo; no Defensivo e contra o Kid aparece mais (50–86%). Ajuste, se quiser, é do Designer.
- **R2 — Os fins "K.O. NO CONTRAGOLPE!", "O JUIZ PAROU!" e "JOELHADA!" são raros no jogador forte:** só aparecem com frequência nos estados apertados (design §8.2). O jogador com atributo de sobra ganha por pontos e vê só carga/chão/clinch. É o desenho (a prévia mostra "N EM 10"), mas vale o Diretor saber que o letreiro não é a pista principal.
- **R3 — Prévia honesta:** o critério passa pela média por adversário (±3,3), não pelo pior estado (10,3 com 200 sementes). Se o Diretor quiser "todo estado a ±5", é preciso mais sementes na prévia (custo de CPU) ou reduzir o ruído; o Brutão e o Dudu têm viés de 2–3 pontos (prévia otimista).
- **R4 — Meta no tempo:** com N = 3 o robô padrão leva 3 campanhas (mediana) no Boxe e 3–4 no Muay Thai (13 de 100 nunca em 6 campanhas a 3/s); no Jiu-jitsu 2. Para quem busca a meta é menos (design §9.3).
- **R5 — Média a 3/s:** 19,5% entre as 6 (Por cima 61:39); passa pela mediana (1,8%) como o dono decidiu, mas é a cauda de 1 em 10 jogadores.
- **Não vi na janela:** o balão da fala do mentor ao liberar a 2ª passiva, nem as animações em movimento (só quadros parados do audit). Teste de reconhecimento por um humano (3 lutas sem HUD) não foi feito (só automático).

## Arquivos de teste que deixei
`tests/qa_f7b2_extra.gd` (meta real, escolha, nova carreira, save sujo/antigo/truncado, reconhecimento, extremos; 601/601 PASS), `tests/qa_f7b2_previa.gd` (prévia honesta + duração; variáveis `QA_ESTADOS`, `QA_LUTAS`), `tests/qa_f7b2_ko.gd` (frequência do fim pela 2ª passiva por tática), `tests/qa_f7b2_soak.gd` (11/11 PASS), `tests/qa_f7b2_copia.gd` (abre cópia do save, variável `QA_SAVE_COPIA`). Logs: `suite.log`, `previa.log`, `extra.log`, `ko.log`, `soak.log`, `campanha.log`, `audit.log`, `foto_main.txt`/`foto_wt.txt` em `C:\Users\deivi\AppData\Local\Temp\qa7b2\`.

## Veredito curto
**Não está pronto para o Diretor: corrigir o B1 (UI/UX) e repetir o `alinhamento-ui` olhando as capturas dos letreiros.** Depois disso a fase passa; B2 é opcional e R1–R5 são decisões de design/Diretor.
