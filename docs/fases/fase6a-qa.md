# Fase 6a (Prólogo e voz): relatório do QA

Data: 2026-11-14. Branch `fase-6a`. QA: `qa-tester`. Nenhum arquivo de `scripts/`, `scenes/`, `ui/`, `data/` foi alterado.
Scripts novos de QA (save de teste em `user://test/`): `tests/qa_f6a_extra.gd`, `tests/qa_f6a_dono.gd`, `tests/qa_f6a_sim.gd`.

## Veredito
**APROVA COM RESSALVAS** para o Diretor revisar. Nenhum bug bloqueante. A parte de sistema (marcos, migração, abertura única, balanço) está sólida.
Há **1 bug de média gravidade** (B1: treinador "fala" na academia sem aparecer) e 2 de baixa (B2, B3), mais 1 candidato visual não conferido (B4). Recomendo corrigir o B1 antes de o dono jogar, porque ele cai logo na 1ª ida à academia.

## 1. Bateria automática
| Item | Resultado |
|---|---|
| `tools/run_tests.ps1` | **TODOS OS TESTES PASSARAM** (inclui `test_fase6a.gd`, cena principal 120 frames sem erro, guarda do save real) |
| `ui_audit --resolution 1280x720 --position 1950,40 --estados todos` | `ESTADOS 215 \| PROBLEMAS 0` |
| Capturas `f6a_*` conferidas | abertura (b3, fim, gesto), gym_osmar, vitoria_selo, parede_antes/depois, osmar_borda, gesto_luta: balões dentro da sala, sem cobrir o alvo, plaquinha legível, selo legível. Única anomalia: B1 (`f6a_gym_osmar.png`) |
| Cena principal `--quit-after 300` (com `--save-dir=user://test/qa6_cena/`) | sem ERROR, sem vazamento |
| Save real do dono (md5 antes/depois, backup em scratchpad) | idêntico (`5db03c1f...`) |

Observação: o log do `test_fase6a.gd` traz WARNINGs do validador (`fala 'ok' desligada`...), são de propósito (testam o validador).

## 2. Critérios de aceite (`fase6a-escopo.md` §5)
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Save novo: saco vale em ≤3 s; abertura ≤20 s; ESC 0,5 s pula | **OK** | `qa_f6a_extra` S2: `clicar()` vale no 1º quadro. `test_fase6a`: abertura real 13,9 s previstos (teto 20). `ui/pular_abertura.gd:64-90`: a contagem só vale se o aperto começou sem janela/cartão; soltar antes zera. Segurar de verdade com teclado real só foi lido no código e nas capturas (`f6a_esc_chip`), não digitado por um humano |
| 2 | Fechar no meio e reabrir: não toca de novo | **OK** | S2: `prologue_seen` gravado em t=0 (`game_state.gd:3240`); reabrir aos 3 s -> `over`, 30 s sem nenhuma fala |
| 3 | Sem ler (balões escondidos) | **OK (por lógica)** | `baloes_escondidos` (`game_state.gd:3303`): marcos e `lines_seen` iguais (coberto em `test_fase6a._teste_baloes_escondidos`). Selo de vitória está na UI (`f6a_vitoria_selo.png`). Não joguei a Carreira 1 inteira à mão |
| 4 | Fala letra a letra, 1 blip a cada 2 letras, clique no saco nunca consumido | **OK parcial** | Código: `Balao` com `mouse_filter` ignore; `completar()` só por `clique_vazio` (clique fora do alvo, `sala.gd:472`). Cadência 28 c/s e timbres: dados e teste de tempos passam. **"Reconhecível de olhos fechados" não é testável por QA: o dono valida** |
| 5 | Balão nunca cobre o alvo; ui_audit 0 | **OK** | audit 0 problemas; `Balao.NO_COVER` + `_checar_balao`. Ver B1 e B4 para dois pontos fora do audit |
| 6 | Gesto: começo de toda luta da C1, nenhum da C2+, duração da luta igual, clique cancela, vitória/luva/parada | **OK** | S7: discípulo, 130 s de sala parada, `fight_intro`, `victory`, `glove`, `idle`, `opening`: todos `{}`, nenhum `gesto_pedido`. `clicar()` chama `registrar_clique()` antes de `_socar` (`game_state.gd:552`): treino não se perde (S6). Duração: ver 10 |
| 7 | Treinador 5-10 comentários na C1, nunca <60 s, sem repetir, nada na luta/janela/dia de luta | **OK (limite inferior em risco)** | S8 (15 min simulados, compra a cada 45 s e 2 caixas): 4 comentários, menor intervalo 134,9 s, nenhuma repetição. O número 5-10 depende de eventos reais (luta marcada, derrota, idle); só o jogo real confirma. Risco: a C1 pode ficar em 4-5 |
| 8 | Arco 1 | **OK** | `test_fase6a._teste_marcos` + S4: selo só na vez em que o marco nasce; aviso/abertura nunca voltam em C2+ (S4: 0 selos na C2); `garage_saved_seen` só na garagem; comentário `cl_garagem_salva` volta ao reabrir se ficou pendente |
| 9 | Save antigo (cópia) | **OK** | `qa_f6a_dono.gd` migra uma **cópia** do save real v10 do dono (carreira 3): carreira, Legado (100), árvore (9 nós), `belts_won`, treino e dia de luta (13) iguais; campanha atual = John; abertura `pending`; nenhum marco criado; regravado v11. S3: mesmo com `belts_won=4` e `belt:true`, nenhuma garagem salva por migração. S4: no v10 o **próximo** cinturão ao vivo salva a garagem |
| 10 | Balanço igual | **OK** | `qa_f6a_sim.gd`: mesma simulação determinística (seed 1234, 10 cliques/s, 20 min, calendário real) rodada na 5.4 (`git archive HEAD`) e na 6a: saídas **idênticas** (treino 3604 -> 7189 -> 1804 -> 5419; lutas aos 360 s, 750 s, 1110 s; 1ª derrota aos 750 s). Fala e gesto não somam segundo: o gesto de entrada vai de 0,30 a 1,19 s dentro dos 1,5 s (`test_fase6a._teste_gesto`) |
| 11 | Testes em save de teste, janelas no 2º monitor | **OK** | `test_real_save_guard` + md5 próprio; audit rodado com `--position 1950,40` |

## 3. Pontos específicos pedidos
- **ESC curto não pula sem querer**: `pular_abertura.gd:69` marca `_valido=false` se há janela/cartão aberto no aperto; `_process` zera se uma janela abrir durante o aperto. OK.
- **Falas únicas (prio ≥ 9)**: `cl_garagem_salva` e `cl_primeira_derrota` ignoram o intervalo de 60 s (`game_state.gd:3395`) e ficam em `_vaga` com `persiste` (`:3361`), sem o limite de 15 s. `cl_garagem_salva` volta ao reabrir (`:3351`, S/teste). **`cl_primeira_derrota` NÃO volta ao reabrir** (B2).
- **Garagem salva só ao vivo**: S4 confirma (reabrir e vencer de novo não traz selo; migração não cria marco).
- **Discípulo**: sem gesto (S7). Sprites `_disc`: confirmado pelas capturas `f6a_discipulo_*` e pelo manifest (`sprite_suffix_disciple`). Observação sem gravidade: o `cl_luva_par` ("a velha é o par do john") toca também na C2+ (`campaign: qualquer` no design). Está de acordo com o design, só aviso.

## 4. Perguntas abertas do UI/UX
- **(a) `gym_arrival` na academia: SIM, dispara.** O Osmar só é desenhado na garagem (`sala.gd:1430`), mas `ponto_cabeca("coach")` devolve sempre (197,173) e a `cl_primeira_academia` não tem condição de local. Resultado em `f6a_gym_osmar.png`: balão "osmar" apontando para a parede vazia. Confirmado por S9 (o gatilho passa pelo `mudar()`). Mesmo vale para uma abertura que comece na academia (save em `gym` sem `prologue_seen`) e para as `cl_academia_volta_*`. Ver **B1**.
- **(b) Balão por cima da faixa de aviso da data**: a conferência (`garagem.gd:163-166`, `balao.gd:128`) exige corpo.y-6 >= base da faixa (y=40). Pelas coordenadas reais os balões ficam em y ≈ 143-175, **nunca perto de y=40**, então na prática não dispara. Se qualquer cálculo falhar (`calcular` -> `ok:false`) o balão é descartado e `GameState.fala_terminada()` é chamado, **mas `lines_seen` já foi gravado antes** (`game_state.gd:3299`, antes do `fala_pedida` em `:3304`): uma fala única se perderia para sempre sem ter aparecido. Hoje inalcançável, é um risco latente (**B3**).
- **(c) `descricao_luva_inicial()`**: sem nenhum chamador fora do teste (`grep` em `ui/`, `scripts/`). A descrição "O par do John..." não aparece em lugar nenhum da UI. Só anotado; o escopo (§2 item 6) diz que ela aparece "na descrição da luva", então hoje essa promessa está cumprida só pela fala `cl_luva_par`.

## 5. Bugs

### B1 — Média — Treinador "fala" na academia sem estar na tela
- **Passos:** jogo em garagem, ganhar cinturão, MUDAR para a academia, escolher a arte, esperar ~2,5 s (o `test_fase6a` já faz isso e valida que a fala sai). Ou: abrir um save sem `prologue_seen` já na academia.
- **Esperado:** nenhum balão sem personagem embaixo; a fala única `cl_primeira_academia` não pode ser gasta sem o jogador ver o Osmar (a escolha do Diretor era "os dois lugares, com menos falas na academia", mas com o treinador presente).
- **Obtido:** balão com plaquinha "osmar" aponta para a parede vazia; a fala única fica marcada como vista (`lines_seen`). Captura: `ui_audit_saida\f6a_gym_osmar.png`.
- **Onde:** `scripts/game_state.gd:2083` (`gym_arrival` sem checar quem existe na cena), `data/dialogos.json` linhas 60 e 94-96 (sem `conditions.location`), `ui/sala.gd:1475-1485` (`ponto_cabeca("coach")` fixo na garagem), `ui/sala.gd:1430` (treinador só na garagem).
- **Quem:** decisão do Diretor/Designer (pôr o Osmar na academia, ou limitar a fala à garagem). Programador (condição em `data/dialogos.json`, usar `conditions.location` que já existe em `dialogos_data.gd:225`) ou artista + designer-ui-ux (sprite do Osmar na academia). Hoje a menor correção é de dados.

### B2 — Baixa — `cl_primeira_derrota` se perde se o jogo fecha logo depois de NOVA CAMPANHA
- **Passos:** (`qa_f6a_extra.gd` S1) 1ª derrota -> NOVA CAMPANHA -> fechar o jogo antes do assentamento de 2 s (salvar) -> reabrir -> esperar 30 s.
- **Esperado:** falas únicas de prioridade ≥ 9 "ficam pendentes até ter vaga e retornam ao reabrir" (escopo §3.3 e pedido do Produtor).
- **Obtido:** nenhuma fala (`FAIL S1`, `v = []`). O gatilho `after_defeat` só é disparado dentro de `nova_carreira()` (`game_state.gd:1647-1650`) e nunca é rearmado na carga; `last_end` fica no save mas não é consultado em `inicializar`/`_tick_falas` (diferente do que foi feito para `garage_saved_return`, `:3351`). A fala não é marcada como vista, então tocaria na **próxima** derrota, com o texto "todo mundo cai primeiro" fora de hora.
- Caso feliz funciona (S1c: derrota -> fecha na tela de fim -> reabre -> NOVA CAMPANHA: toca).
- **Quem:** programador. Sugestão: no tick, se `last_end.kind == "defeat"` e `last_end.campaign == numero_carreira()-1` e `cl_primeira_derrota` não está em `lines_seen` e a campanha ainda é a seguinte, redisparar `after_defeat` (como a garagem salva).

### B3 — Baixa (latente) — Fala única é marcada como vista antes de a UI aceitar o balão
- **Onde:** `scripts/game_state.gd:3292-3304` (`lines_seen` gravado e `salvar()` antes de `fala_pedida.emit`) x `ui/garagem.gd:165-166` (`mostrar` recusa -> só chama `fala_terminada`).
- **Esperado:** se o balão for descartado por falta de espaço, a fala única não deve contar como vista.
- **Obtido:** perde para sempre. Não consegui reproduzir com posições reais (S5 teórico; a conferência do audit passa e os balões ficam longe da faixa), então é só risco se a arte mudar (outros aparelhos/foco, resolução).
- **Quem:** programador (reverter `lines_seen` quando a UI recusar, por exemplo um `fala_recusada(id)` ou retorno do sinal) + designer-ui-ux (chamar).

### B4 — Baixa (visual, não conferido em captura) — Rabicho do John ignora o foco na ESTEIRA
- `ui/sala.gd:1483`: `ponto_cabeca("first")` usa `foco_corda` se o foco é CORDA e senão `foco_saco` (303,272). Com foco na ESTEIRA o John fica em `foco_esteira` (339,269, `sala.gd:332`), ~36 px à direita. O rabicho apontaria para o ar, ao lado dele. O audit não tem estado "balão do John na esteira".
- **Quem:** designer-ui-ux (conferir com captura; se confirmado, ponto de cabeça por foco).

## 6. Riscos e observações
- **Contagem de comentários (critério 7)** só se confirma jogando: a simulação deu 4 com poucos eventos. `fight_won` só fala com revanche ou recorde, então na C1 o Osmar pode ficar bem calado depois de uma luta comum. O Diretor/dono decidem se é pouco.
- **Som**: os `voice_*`, `strap_rip.wav`, `tap_glove.wav`, `hit_heavy` (selo) existem e carregam sem erro; execução `--headless` não toca áudio, então timbre, volume (-8 dB) e se "o blip incomoda" são do dono.
- **Vazamento no final de scripts**: avisos `ObjectDB instances were leaked` aparecem nos meus scripts avulsos (`qa_f6a_sim.gd` não libera o `GameState`), são da forma do script (também aparecem na 5.4); a cena principal e a bateria oficial não vazam.
- **Gesto ao calçar luva** e **gesto na parada** só têm cobertura de lógica (plano e cancelamento); a animação foi conferida nas capturas `f6a_gesto_sala/curto/cancela`.
- **Rodar a cena principal sem `--save-dir=user://test/...` escreve no save real**: usei sempre a pasta de teste (um comando sem isso foi bloqueado pela política e não rodou).

## 7. Resumo por responsável
| Bug | Gravidade | Para quem |
|---|---|---|
| B1 treinador fala na academia sem aparecer | Média | Programador (dados/condição) + decisão Designer/Diretor; opcional artista + UI/UX se o Osmar for à academia |
| B2 `cl_primeira_derrota` se perde ao reabrir | Baixa | Programador |
| B3 fala única marcada antes da UI aceitar | Baixa (latente) | Programador + UI/UX |
| B4 rabicho do John na esteira | Baixa (a conferir) | Designer UI/UX |
