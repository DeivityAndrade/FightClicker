# Fase 4b — QA

Dono: QA. Data: 2026-11-06. Escopo: `fase4b-escopo.md` (respostas do dono e "Decisão do Diretor (23b)" prevalecem), `fase4b-design.md`, `fase4b-api.md`, `fase4b-textos.md`.
Nada em `scripts/`, `scenes/`, `ui/`, `data/` foi alterado. Arquivos novos de QA em `tests/` (não entram no runner): `qa_f4b_extra.gd`, `qa_f4b_ui.gd`, `qa_f4b_shot.gd`, `qa_f4b_play.gd`.
Save real do dono: backup feito antes, hash conferido no fim (`save.json` e `save.json.bak` idênticos) e `test_real_save_guard.gd` passou antes e depois.

alinhamento-ui: 63 estados, 0 problemas (capturas em `C:\Users\deivi\AppData\Local\Temp\claude\ui_audit\`, incluindo as 21 `b4_*`; `b4_assist_socando` passou de primeira).

## Resumo
- `powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1` imprime **TODOS OS TESTES PASSARAM** (inclui `test_fase4b.gd` e a cena principal sem erros).
- Verificador de alinhamento: `ESTADOS 63 | PROBLEMAS 0`. Olhei as capturas (marcas, plaquinhas, botões de foco com 1, 2 e 3 aparelhos, chip do assistido nos 4 estados, chegada, dica do fim): nada torto, cortado ou com travessão aparecendo (a plaquinha quebra no " — ").
- Simuladores batem com o `fase4b-design.md` e a meta 23b nova fecha.
- Nenhum bug bloqueante nem alto. 5 itens baixos/médios abaixo.

## Critérios de aceite
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Save novo / NOVA CARREIRA: só o saco, foco no saco, duas marcas com plaquinha | OK | `qa_f4b_ui.gd`: "começa só com o saco"; `qa_f4b_extra.gd` `_nova_carreira`; captura `b4_inicio_marcas.png` (marcas de fita, "ESTEIRA 500 TREINO", "CORDA DEPOIS DA ESTEIRA") |
| 2 | 2º aparelho desde o minuto 0; 3º com "DEPOIS DA ESTEIRA" e recusa | OK | `qa_f4b_extra.gd`: corda recusada com 1e6 de Treino sem a esteira, saldo intacto; `b4_corda_sem_treino.png`, `b4_inicio_marcas.png` |
| 3 | Compra: 1 clique, desconta o `data/`, saldo nunca negativo, não reduz atributo | OK | 500 exatos compram e deixam 0; 499 e 1499,999 recusam; Treino 1e300 compra e fica finito; atributos intactos (`test_fase4b.gd`) |
| 4 | Chegada com efeito, marca some, foco vai ao aparelho novo | OK | `b4_chegada_esteira_queda.png`, `b4_chegada_esteira_poeira.png`, `b4_chegada_corda.png`; UI: compra deixa foco=esteira e Treino 100 |
| 5 | Clique na marca / botão trancado: sem treino, sem trocar foco, abre TREINO e pisca | OK | `qa_f4b_ui.gd`: clique na marca gera 0 `clicou`, foco continua no saco; `b4_clique_marca_e_foco.png` (linha da esteira com borda amarela) |
| 6 | Trancado não é foco em lugar nenhum; melhorias só depois da compra | OK | `definir_foco` recusa esteira e corda; teclas 1/2/3 e Espaço pulam trancados (UI); `proxima_melhoria` vazia e `comprar_melhoria` false em trancado |
| 7 | NOVA CARREIRA tranca de novo (derrota e aposentadoria) | OK | `qa_f4b_extra.gd`: depois de derrota e depois de aposentar, `["punching_bag"]`, foco no saco, melhorias zeradas |
| 8 | 4–5/s: 2º ≤ 3 min, 3º antes do Brutão em ≥ 90% (mediana ≤ 8 min) | OK | `fase4b_sim.py inicio`: esteira 1:19 (5/s) e 1:37 (4/s); corda 4:36 e 5:34; 58 de 58 e 64 de 64 antes do Brutão |
| 9 | Lento 3/s: os dois antes do Dinho em ≥ 90% | OK | esteira 2:06, corda 6:26, 55 de 55 |
| 10 | Carreiras 2+ com os nós da derrota típica: os dois em ≤ 2 min | OK com ressalva | mediana 1:05 / 1:18, p90 1:20 / 1:36 (5/s e 4/s). Pior caso 2:45 (5/s, após derrota no Dudu sem nós). Lento 3/s: p90 2:21, pior 4:42 (ver B4) |
| 11 | Metas da Fase 4 continuam na faixa (23b com a meta nova) | OK | tabela abaixo |
| 12 | Dica de fim nunca manda treinar sem dizer como conseguir | OK | `b4_fim_dica_esteira.png` ("COMPRE A ESTEIRA CEDO NA PRÓXIMA CARREIRA"), `b4_fim_dica_corda.png`; teste de dica: montado vira dica normal, `luck` não muda, ending antigo sem `unlock_tip` funciona (`qa_f4b_extra.gd`) |
| 13 | v4 em andamento abre na v5 com 3 aparelhos, foco, melhorias e Treino; próxima carreira só o saco; cadeia v0→v5 | OK | v4 com fim pendente (focus=treadmill, treino 777, metrônomo 1, melhorias): tudo preservado, regrava como `version 5`; v0 e v3 migram para os 3 aparelhos; NOVA CARREIRA volta ao saco |
| 14 | Fechar e reabrir logo após comprar: comprado e descontado uma vez | OK | recarga sem salvar de novo: `[punching_bag, treadmill, jump_rope]`, treino 20, foco corda |
| 15 | Mudar preço em `data/` muda o jogo | OK | `test_fase4b.gd` (custo do JSON, `cost` inválido, `requires` em ciclo) passou |
| 16 | `run_tests.ps1` passa inteiro, guarda do save real cobre tudo | OK | saída "TODOS OS TESTES PASSARAM"; guarda `4/4 PASS`; hash do save real igual ao backup |
| 17 | Verificador de alinhamento: 0 problemas com 1, 2 e 3 aparelhos | OK | `ESTADOS 63 | PROBLEMAS 0` (`b4_inicio_marcas` = 1, `b4_corda_*` = 2, `b4_tres_aparelhos` = 3) |
| 18 | Sessão de 30 min com 2 carreiras sem erro no console | OK parcial | `qa_f4b_play.gd` (4,5 cliques/s, 3x, Shift segurado o tempo todo, compra os aparelhos): 2 carreiras completas e a 3ª iniciada, 16:52 de tempo de jogo, 4.214 cliques, 0 linhas ERROR/WARNING, 0 avisos do GameState. Não cobri 30 min inteiros (ver Riscos) |
| 19 | Assistido só enquanto Shift segurado (decisão do dono); botão SEGURAR igual; indicador certo | OK | UI: Shift pressionado liga, eco do Shift não muda nada, soltar desliga, toque curto não deixa ligado; botão SEGURAR liga no `button_down` e desliga no `button_up`; Shift+botão: soltar um dos dois mantém, soltar os dois desliga |
| 20 | 1 auto-soco a cada X s, pelo caminho do clique, crítico na taxa do clique | OK | 65 s segurando: socos em 1,0 / 4,0 / 7,0 / 10,0 s (1º em 1 s, depois a cada 3 s), 22 em 65 s; 1.000 auto-socos deram 107 críticos (taxa do `data/` é 10%); UI real: 2 socos em 7,5 s |
| 21 | Mão parada: clicando 4–5/s dá 0 socos; ao parar, o 1º sai ≥ 1 s depois | OK | clicando a 5/s por 30 s segurando: 0; clicando a cada 0,9 s por 90 s: 0; ao parar, 1º soco em 1,95 s (passo de 0,05 s) |
| 22 | Metrônomo ≥ 1: assistido não soca e o Shift não muda o treino | OK | comprado com Shift apertado: estado vira `metronome` no mesmo quadro, `assist_socos_total` para; em 20 s só o Metrônomo soca no ritmo dele, com ou sem Shift; `b4_assist_metronomo.png` |
| 23 | Não soca na luta, prévia, fim, árvore, cartão | OK | 5 lutas reais com Shift segurado: 0 socos durante a luta e 0 na tela de fim; modal aberto, `luta` pendente e `fim`: 0 em 30 s cada; voltando da janela não despeja socos acumulados; UI: Shift com a prévia aberta, 0 socos |
| 24 | Só-assistido vence ao menos o Dudu sem clicar; típico ≥ 8× | OK | só-assistido vence o Dudu aos 10:44 (16 de 16); eficiência 12× (4/s), 13,5× (4,5/s), 15× (5/s) |
| 25 | Típico igual com e sem Shift | OK | "4b típico 5/s, Shift sempre" idêntico em todas as colunas (1ª derrota 12:14, cinturão 68 de 400 aos 23:51, tempo morto igual) |
| 26 | Preferência do assistido | N/A | Removido pela decisão do dono (3). Conferi que o save não contém nada de assist e que `permanent` não ganhou campo |
| 27 | Mudar `interval` e `still_seconds` em `data/` muda o jogo | OK | `test_fase4b.gd` (validação e mudança de `interval`/`still_seconds`) passou |

### Metas que não podem quebrar (critério 11), simulador do próprio QA
Comando: `"C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" tools/sim/fase4b_sim.py tudo` com `SIM_N=32 SIM_CARREIRAS=8 SIM_N_REV=120 SIM_N_INI=64`; 23b com `SIM_N=400 SIM_CARREIRAS=1 ... carreiras` e `SIM_N_REV=400 ... revanche`. Os números reproduzem o `fase4b-design.md` §9.
| Meta | Resultado | Situação |
|---|---|---|
| 1ª melhoria ≤ 3:00 | 0:53 / 1:04 / 1:27 | OK |
| Tio em 5–8 min | 5:23 / 6:15 / 7:01 | OK |
| 1ª vitória em 2–5 min | 3:13 / 4:14 / 4:44 | OK |
| F4 22: 1ª derrota em 10–15 min | 12:14 (5/s), 14:14 (4/s); lento 16:14 | OK (4–5/s) |
| F4 23a: cinturão entre a 2ª e a 4ª carreira (mediana) | 2 (1–3) / 2 (1–3) | OK |
| **23b novo, 400 jogadores: ≤ 20% a 5/s** | **68 de 400 = 17,0%** | **OK** |
| **23b novo, ≤ 25% a 4/s** | **97 de 400 = 24,25%** | **OK (margem de 0,75 ponto)** |
| 23b: nunca antes de 20:00 | mais cedo 23:51 (5/s) e 27:20 (4/s) | OK |
| F4 24: tempo morto carreira 1, mediana ≤ 10 e p90 ≤ 13 | 5:30 / 11:01 (5/s), 6:00 / 12:32 (4/s) | OK. Lento 3/s tem p90 14:33, igual ao da Fase 4 (14:33), fora da meta de 4–5/s |
| F4 24: carreiras 2–4 p90 ≤ 10 | máx. 7:30 (5/s e 4/s); 3/s máx. 8:31 | OK |
| F4 25: revanche Dinho ≥ 80%, Muralha ≥ 60% (com L1, 400×2) | Dinho 92% / 92% (5/s, 4/s); Muralha 86% / 79% | OK (ver B5 sobre o texto "≥ 80%" do escopo) |
| F4 26: protótipo ~20 min (até 25) | 21:31 / 24:28 | OK (4/s a 0:32 do teto) |
| F4 8: árvore entre a 5ª e a 8ª carreira | 6 (6–7) / 6 (5–8); lento 7 (6–8) | OK |
| Menos derrotas "bobas" no Dudu | 4/s: 4 de 400 (Fase 4: 34) | confirma a causa descrita pelo Diretor |
| Só-assistido (informativo) | Dudu 10:44 (16/16), Brutão 20:44 (14/16), Dinho 27:46 (7/16); 1ª carreira, tempo morto p90 24:05 | informativo, sem meta |

Regressão `fase4_sim.py` (sem L1 como referência, como já rotulado): as curvas e a seção de revanche reproduzem as linhas "Fase 4" do `fase4b_sim.py` (59,1K de Treino aos 10 min, vitória no Dudu 3:13, Brutão 8:44, Dinho 11:44). A seção "carreiras" terminou: 1ª derrota 11:44 / 13:44 / 15:14, cinturão na carreira 2 (1–4) / 3 (1–3) / 3, árvore fecha na 6 (5–7) / 6 (6–8) / 7, tempo morto carreira 1 p90 11:01, carreiras 2–4 p90 ≤ 6:00 (5/s). Sem diferença para a Fase 4 aprovada.

## Tentativas de quebrar (resumo)
Tudo em `tests/qa_f4b_extra.gd` (87/87 PASS) e `tests/qa_f4b_ui.gd` (26 checagens PASS), sempre em `user://test/`.
- Compra fora de ordem, sem Treino, em luta e na tela de fim: recusada, saldo e estado intactos; compra dupla recusada e não cobra; ids vazio, inexistente e saco recusados.
- Treino negativo, 1e300; `tick` com 1e9, NaN, INF e negativo: no máximo 3 socos, nada quebra.
- Salvar e carregar no meio: compra grava na hora; `save.json` não contém "assist".
- Save corrompido: v5 sem `apparatus_owned` (e com `null`, número, texto, objeto, lista com lixo, lista vazia) volta só com o saco, foco corrigido e melhorias de trancado zeradas, com aviso; corda sem esteira (editado) é mantida; JSON quebrado vira jogo novo.
- Migração v4→v5 com fim pendente, v3 e v0: OK (ver critério 13). `textos_fim` com ending antigo funciona.
- NOVA CARREIRA reseta aparelhos depois de derrota e de aposentadoria; o estado "Shift segurado" atravessa a nova carreira (é estado da tecla, esperado).
- Teclas 1/2/3 e Espaço com trancados: foco não muda, Espaço treina só o saco; Shift+Espaço treina, Shift+3 não troca para trancado. Depois de montar: 2 troca para a esteira, 3 continua recusando a corda.
- Shift+SEGURAR juntos, soltar Shift com janela sem foco (perda de foco solta tudo, inclusive botão preso), eco do Shift, toque curto: OK.
- Shift na luta, na prévia (UI real), na tela de fim e no cartão: 0 socos. Aposentar com o assistido ativo: estado coerente (o chip lê `assistido_estado()` a cada quadro).
- Metrônomo ≥ 1 com Shift: não empilha (ver critério 22).
- Ritmo: 1 soco a cada 3 s, mão parada 1 s, Shift batido 2×/s rende 0.
- Dica "unlock" na tela de fim: textos certos nas capturas, acentos corretos.

## Textos (conferidos contra `fase4b-textos.md` e `data/ui_texts.json`)
- Todas as chaves do bloco estão em `data/ui_texts.json` com o texto do Roteirista (acentos de PRÓXIMA, FÔLEGO, ESTÁ, MÃO, METRÔNOMO corretos).
- Nada cortado nas capturas: "SEGURE SHIFT: TREINO ASSISTIDO" cabe (a variante curta só entra se o grupo não couber), "ESPERANDO A MÃO PARAR", "METRÔNOMO TOCANDO", "DEPOIS DA ESTEIRA" no botão de foco e na linha da aba, descrições da esteira e da corda na caixa de informação, dicas de fim.
- Travessão: a fonte pixel não tem "—"; `sala.gd` quebra a plaquinha em duas linhas ("ESTEIRA / 500 TREINO", "CORDA / DEPOIS DA / ESTEIRA"), nenhum travessão renderizado.
- Preço "1.50K" na plaquinha, no botão de foco e no COMPRAR: decisão do Produtor, não reportado.
- "METRÔNOMO TOCANDO" com Metrônomo ≥ 1 sem dica e sem SEGURAR: decisão do Produtor, não reportado.
- Loja, Metrônomo nível 0: "AGORA: 1 SOCO A CADA 3.0 S COM SHIFT" aparece na caixa de informação (capturei com `tests/qa_f4b_shot.gd`), no mesmo formato "2.0 S" do Metrônomo.

## Bugs e observações
Nenhum bloqueante nem alto.

| # | Gravidade | Descrição | Como reproduzir | Dono |
|---|---|---|---|---|
| B1 | baixa | O aviso "COMPRE A ESTEIRA PARA TREINAR" (escopo §5, design §3) só aparece quando o mouse passa sobre o atributo (caixa de informação). No painel o único sinal fixo é o nome do atributo apagado em cinza. O escopo pede "uma linha". | Começar carreira, olhar o painel ATRIBUTOS sem passar o mouse: AGILIDADE e RESISTÊNCIA só ficam cinza. Passar o mouse: a linha aparece (`tests/qa_f4b_shot.gd`, `attr_hover.png`). | designer-ui-ux |
| B2 | baixa | `docs/fases/fase4b-api.md` desatualizado: diz que a ordem do array de aparelhos é saco, corda, esteira e que "nenhum arquivo de `ui/` foi alterado"; hoje a ordem em `data/training.json` é saco, esteira, corda (teclas 1/2/3 e fileira de foco seguem isso) e a UI existe. | Ler as linhas 21 e 45–46 do api.md contra `data/training.json`. | programador |
| B3 | baixa | Tecla Shift esquerda e direita: o `_shift` é um só. Segurar os dois e soltar um deles desliga o assistido mesmo com o outro ainda apertado. | `ui/faixa_assistido.gd` linhas 86–92 (`_shift = k.pressed` para `KEY_SHIFT`, sem distinguir `physical_keycode`). Reprodução: segurar Shift esquerdo e direito, soltar um. | designer-ui-ux |
| B4 | baixa | Critério 10 ("≤ 2 min nas carreiras 2+"): mediana e p90 fecham a 4–5/s, mas o lento 3/s tem p90 2:21 (pior 4:42) e o 5/s tem pior caso 2:45 depois de derrota no Dudu sem nós. O design já documenta o pior caso como "igual à 1ª carreira"; só registro que o texto do critério não tem esse recorte. | `SIM_N=32 SIM_CARREIRAS=8 ... fase4b_sim.py carreiras`, coluna "aparelhos nas carreiras 2+". | designer-de-jogo (decidir se o critério aceita o recorte) |
| B5 | baixa | O escopo §8 diz "revanche ≥ 80% (Dinho e Muralha separados)", o design e a Fase 4 usam Dinho ≥ 80% e Muralha ≥ 60%. Com 400×2 a 4/s a Muralha dá 79% (a Fase 4 dava 74%, a 4b melhorou). Pelo critério aprovado da Fase 4 (≥ 60%) passa. | `SIM_N_REV=400 ... fase4b_sim.py revanche`, linha "4b, típico 4/s, L1 / tank". | diretor-de-jogo (esclarecer o texto do escopo) |
| B6 | baixa (cosmético, simulador) | No `fase4b_sim.py carreiras`, as linhas "Fase 4" mostram "16666666:40" na coluna "aparelhos nas carreiras 2+" (a Fase 4 não tem compra de aparelho; devia ser "-"). Com 400×1 carreira a coluna fica "-", então só aparece com 8 carreiras. | `SIM_N=32 SIM_CARREIRAS=8 ... fase4b_sim.py carreiras`, linhas "Fase 4, típico ...". | designer-de-jogo |

## Riscos
- **23b a 4/s com margem curta (24,25% contra o limite de 25%).** Com 400 jogadores o ruído é de cerca de ±2 pontos; uma mexida pequena em qualquer preço ou número de luta pode cruzar o limite. A trava D1 do Diretor já cobre; vale rerodar o 23b com 400 sempre que mexer em `data/`.
- **Sessão longa (critério 18):** a minha rodada cobriu 16:52 de jogo em 2 carreiras completas (3x de velocidade, sem erro). Não rodei 30 min corridos; o `qa_soak.gd` antigo não compra aparelhos, por isso criei `qa_f4b_play.gd`.
- **Só-assistido:** vence o Dudu aos 10:44 mas o tempo morto p90 da 1ª carreira é de 24 min e só 7 de 16 chegam a vencer o Dinho. É aceito pela decisão do dono (R8), mas o dono deve saber.
- **Shift fisicamente apertado ao voltar o foco da janela:** o jogo solta o assistido na perda de foco e só volta a socar num novo aperto. Comportamento seguro (a tecla nunca fica "presa"), só pode surpreender quem segura Shift enquanto troca de janela.
- O QA não testou o jogo numa janela real com teclado físico; entrada sintética via `Input.parse_input_event` cobre tecla, botão e perda de foco.

## Veredito
**Pronto para o Diretor revisar.** Todos os critérios passam (18 com cobertura parcial de duração), o verificador de alinhamento deu 0 problemas e a meta 23b nova fecha (17,0% a 5/s, 24,25% a 4/s, mais cedo 23:51). Sem bloqueantes; B1 a B6 são baixos e não impedem a revisão.
