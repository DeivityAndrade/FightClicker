# Fase 7a1 — Cada arte luta do seu jeito: relatório de QA

QA, 2026-11-19. Base: `docs/fases/fase7a-escopo.md` (§7 critérios 1–6 e 13–14, §8 decisões do dono), `docs/fases/fase7a1-design.md`,
`docs/codigo/mapa.md` (seção 7a1). Branch com mudanças ainda sem commit. Nenhum código de `scripts/`, `scenes/`, `ui/`, `data/` foi alterado.
Todos os comandos rodaram com `$env:APPDATA` temporário e `--position 1950,40` quando abriram janela; o save real foi conferido por hash (igual ao
backup; só `shader_cache` do Godot mudou, de outra sessão). O worktree temporário de `origin/main` foi removido no fim.

## Veredito

**Pronto para o Diretor revisar, com 3 bugs médios de apresentação abertos (B1, B2, B3), todos no Jiu-jitsu.** Nenhum critério de aceite
automatizado falhou: testes verdes, `ui_audit` com 0 problemas, prévia honesta, foto igual à main, duração 8–19 s. Recomendo corrigir B1 e B2
antes de aprovar, porque aparecem na luta com a tática da própria arte (Jiu-jitsu Defensivo) e atrapalham o "o testador diz qual é a arte só olhando".

## Critérios de aceite (escopo §7) e itens pedidos

| # | Item | Resultado | Evidência |
|---|---|---|---|
| 1 | Boxe: golpes de boxe, ritmo rápido, K.O. | **OK** | `tests/qa_f7a1_ko.gd`: contra Tonhão, Kid e Muralha a maioria dos K.O. pela passiva cai no 1º/2º round (ex.: Tonhão Agressivo, 1.198 K.O.: R1 123, R2 1.045, R3 30). Intervalo do jogador 1,46 s nos rounds 1–2, 1,98 s depois. |
| 1 | Jiu-jitsu: queda, chão e "FINALIZOU!" em 1 de cada 3 vitórias vs Tonhão | **OK** (números) / ressalvas visuais B1–B3 | `qa_f7a1_logica.gd`: 392 vitórias em 400, **61%** por finalização com a melhor tática (Defensivo fixo: 75%). `qa_f7a1_eventos.gd`: 936 lutas, o jogador JJ nunca usa golpe de boxe (0 de 936); só `clinch_push`, `takedown`, `ground_pressure`, `submission`. |
| 1 | "Um testador diz a arte só olhando" | **OK com ressalva** | Boxe (5 bolinhas, CANSADO, K.O.) e JJ (barra, queda, chão, FINALIZOU!) se distinguem nas capturas `f7a1_luta_*`. Mas B1 e B2 quebram a leitura do JJ em parte das lutas. |
| 1b | Boxe: embalo 0–5, zera na esquiva | **OK** | 3 táticas x 3.000 lutas: embalo nunca fora de 0–5; evento de esquiva do jogador sempre com `streak = 0`. Captura `f7a1_luta_boxe_embalo`: bolinhas acesas. |
| 1c | CANSADO a partir do 3º round, nunca no Defensivo (`tires`) | **OK** | Nenhum evento `tired` antes de t = 10,66 s. Defensivo: `tires=false`, 0 eventos `tired` em 3.000 lutas; HUD sem CANSADO (`f7a1_luta_boxe_defensivo`). Agressivo/Contra-ataque: `tires=true` em 3.000 de 3.000. |
| 1d | Agressivo leva contragolpe | **OK** | 1.111 contragolpes dele em 3.000 lutas Agressivas; 0 nas outras duas táticas. Prévia mostra "ELE CONTRAGOLPEIA". |
| 1e | JJ: barra de pegada, "PEGADA!", queda (`takedown`+`fall`), chão, `submission`+`tap_out` parados | **OK** (ressalvas B1–B3) | `tests/qa_f7a1_poses.gd` (linha do tempo por luta real): `clinch_push` em pé, `takedown` + `fall` na 1ª vez que a pegada passa de 50%, repouso em `ground_top_idle`/`ground_bottom_idle`, `submission` e `tap_out` terminam parados no último quadro (jogador #9 de 10, adversário #7 de 8) com o letreiro FINALIZOU! visível. Pegada monótona e 100% a partir de `grip_full_at`; 0 finalizações antes da pegada cheia. |
| 1f | 3 ou mais visuais de discípulo nas poses novas | **OK** | `tests/qa_f7a1_folhas.gd`: 4 visuais bem diferentes (careca/pele clara/sem camisa; coque/pele escura/regata/faixa azul/meião; topete/amarelo/camiseta verde; cobre/camiseta branca/faixa verde/meião), 6 poses x 3 quadros. 42 checagens PASS (todas as camadas existem, mesmo tamanho do corpo). O símbolo R aparece (32–120 pixels por folha, no peito com camiseta ou regata, no calção sem camisa), legível, não espelhado, nenhuma camada faltando. Folha de contato olhada a olho. |
| 2 | Prévia: cartão da passiva muda com a tática | **OK** | `f7a1_previa_boxing_*`: Agressivo "K.O. ATÉ 14%... CANSA NO 3º ROUND. ELE CONTRAGOLPEIA", Defensivo "K.O. ATÉ 7%... NÃO CANSA". JJ: "PEGADA CHEIA NO 2º ROUND (5,3 S). 28% POR GOLPE", barra com marca e "N EM 10 VITÓRIAS". O cartão cabe ao lado da janela. |
| 2 | **Prévia honesta**, ±5 pontos | **OK** | `qa_f7a1_logica.gd`: 6 adversários x 2 artes x 3 táticas, 12 estados por célula (x0,6 a x1,4), 1.000 lutas reais por estado: **36 de 36 células a ≤ 2,0 pontos** (pior: JJ Seu Muralha Defensivo, −2,0). `fase7a1_sim.py honesta` (300 lutas): pior −2,6. Ver risco R1 sobre estados isolados. |
| 3 | Sem arte (1ª carreira): luta e balanço idênticos | **OK** | `tools/refatoracao/foto.gd` com worktree de `origin/main` x árvore atual: 712 linhas, **12 blocos diferentes, todos aceitos**: 6 do texto/valor dos nós `box_counter`/`bjj_guard` (+10% -> K.O. +50%; -10% recebido -> pegada +50%) e 6 do campo `fight_arena: "arena"` em `local_atual`. Hashes do robô de 3.000 passos e simulação iguais. |
| 4 | Luta curta, 8 a 20 s, com ou sem finalização | **OK** | 18.000 lutas aleatórias (x0,3 a x3,0 do adversário): tela de **8,00 a 19,00 s** nas três situações (sem arte, Boxe, JJ). |
| 5 | Arena GINÁSIO ALVORADA: Tonhão e Kid na liga; 4 amadores na borracharia | **OK** | `test_fase7a1.gd` (arena por adversário e por local); capturas `f7a1_arena_liga`, `f7a1_arena_borracharia`. Letreiros K.O. e FINALIZOU! legíveis sobre a arena nova. |
| 5b | Fim depois de derrota com a arena visível (pendência 5.4/B2) | **OK** | `f7a1_fim_derrota_arena`: tela de fim por cima da arena escurecida, nada cortado, botões alinhados. |
| 6 | Derrota: nota da passiva e dica, caixa sem cortar texto | **OK** | `tests/qa_f7a1_fim.gd`: 5 dos 6 ids de nota renderizados na cena real (`boxing_counter`, `boxing_tired`, `boxing_streak`, `bjj_never_hurt`, `bjj_escaped`) mais o caso sem nota; **`bjj_grip_late` não apareceu** na busca de lutas perdidas (não testado em tela; o texto dele é curto, a regra está coberta por `test_fase7a1.gd`). A caixa vermelha comporta 5 linhas (motivo, estatística, nota, dica da nota, "espere o verde") e o respiro até o rodapé fica em 3 px. Capturas olhadas: `fim_boxing_counter`, `fim_bjj_never_hurt`, `fim_bjj_escaped` (as outras duas foram geradas, textos lidos no console). Ver B4 (plural). |
| 7 | Janela de escolha da arte: cartões novos, sem `{pct}` | **OK** | `f5_arte_primeira`: sem `{pct}` sobrando; texto não corta. Árvore: tooltip "BOXE: CHANCE DE K.O. +50%" preenchido (`f54_cartao_arte`). Ver B7 (cópia repetida). |
| 8 | Números com vírgula | **OK** | Cartão ampliado: "SOCO A CADA 1,52 S" e "(5,3 S)" com vírgula. |
| 9 | `tools/run_tests.ps1` verde | **OK** | "TODOS OS TESTES PASSARAM", cena principal 120 quadros sem erros, guarda do save real igual. `test_fase7a1.gd` direto: **147/147 PASS**. |
| 9 | `ui_audit --estados todos` (1280x720, `--position 1950,40`) com 0 problemas | **OK** | Saída: `ESTADOS 401 | PROBLEMAS 0`, código 0. Os 20 estados `f7a1_*` olhados a olho (prévias, embalo, cansado, defensivo, K.O., pegada, chão, finalizou, arenas, fim): nada torto, cortado ou sobreposto. |
| 9 | `validar_cenas` sem erros | **OK** | 4 cenas, 0 erros, 0 avisos, 0 pendências. |
| 9 | `fase7a1_sim.py` bate com o jogo | **OK** | `exportar_casos.py` regenerado numa cópia: `fase7a1_casos.json` **idêntico byte a byte** ao do repositório; 147 PASS no teste exato Python x GDScript. `ident`: 2.000 de 2.000 lutas iguais à `fase3_sim`. `campanha` (100 jogadores): ver abaixo. |
| 6s | Balanço (critério 6, Designer): diferença Boxe x JJ ≤ 15% | **OK** (média/mediana) | `SIM_N7=100 ... campanha`: 4/s tempo até o Kid 40:56 x 41:45 (**2,0%**), 3/s 46:11 x 46:33 (**0,8%**); Kid na 1ª tentativa 93 x 95% e 82 x 87%; 1ª carreira 13:56 / 15:26 e cinturão amador na 2ª carreira (igual ao design). O p90 de 3/s foi 73:49 x 90:10 (22%) com N=100; o design já registrava p90 largo no JJ (ver R2). |

## Testes extras escritos por mim (em `tests/qa_f7a1_*.gd`, sem PNG em `docs/arte`)

| Arquivo | O que faz | Resultado |
|---|---|---|
| `qa_f7a1_logica.gd` | prévia honesta x lutas reais, embalo/cansaço/pegada, 1 em 3, duração, valores extremos (zeros, 1e15, tática inexistente/vazia) | 167/167 PASS, sem NaN/inf em nenhum extremo |
| `qa_f7a1_ko.gd` | K.O. do Boxe por round e adversário; intervalos antes/depois do cansaço | 1,46 -> 1,98 s (Agressivo/Contra), 1,46 -> 1,80 s (Defensivo) |
| `qa_f7a1_folhas.gd` | camadas e símbolo R das poses novas do JJ em 4 visuais | 42 PASS, folhas de contato olhadas |
| `qa_f7a1_fim.gd` | tela de fim com cada nota da passiva (cena real, janela) | sem texto cortado |
| `qa_f7a1_poses.gd` | linha do tempo de poses/quadros numa luta real; captura de poses (`-- --cap=<pasta>`) | achou B1, B2, B3 |
| `qa_f7a1_eventos.gd` | golpe escolhido por evento em 936 lutas de JJ | 0 golpes de boxe do jogador |
| `qa_f7a1_savebad.gd` | luta pendente com `finish` incoerente/lixo/ausente, recarregando o save | sem erro de script; ver B9 |

## Bugs

### B1 — Média — Jiu-jitsu Defensivo: o jogador "levanta" em pose de guarda em pé no meio da luta no chão
- **Passos:** Jiu-jitsu, tática Defensivo, luta contra o Tonhão até a queda e o chão. Reproduzir: `godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f7a1_poses.gd -- --cap=<pasta temporária>` (grava `pose_block.png`).
- **Esperado:** no chão o jogador fica em `ground_top_idle`/`ground_top_hit` quando o adversário acerta o `ground_punch`.
- **Obtido:** toda vez que o adversário acerta no chão, o jogador troca para a pose `block` (em pé, guarda alta) por ~0,2 s e volta ao chão: aparece de pé ao lado do adversário deitado (t = 3,65; 5,43; 7,29; 9,05; 10,89; 12,65 na luta de teste). Com Agressivo isso não acontece (usa `ground_top_hit`). Causa provável: a tática Defensivo tem `block: true`, o evento sai com `defender_anim = "block"` e `_acertou`/`_tocar` não troca para a reação de chão (`tela_luta.gd` ~linha 836–850; `_montar_info_luta` ~linha 296).
- **Quem corrige:** UI/UX (`ui/tela_luta.gd`), com o Artista só se quiserem um `ground_block` próprio.

### B2 — Média — "SUPER UPPERCUT!" (especial de cliques da fase 6) toca dentro da luta de Jiu-jitsu, tirando os dois do chão
- **Passos:** Jiu-jitsu, combo alto (X5 em diante) numa luta que já está no chão. Mesmo script de B1 (`pose_uppercut.png`, t = 9,93; também em t = 11,94 na luta 3).
- **Obtido:** o letreiro "SUPER UPPERCUT!" e as poses `uppercut` / `hit_up` (de boxe, em pé) aparecem com `_fase_visual = "ground"`: os dois lutadores aparecem em pé durante 1 s e depois voltam ao chão. Quebra a leitura "Jiu-jitsu = chão" e mistura com a passiva do Boxe. O código do especial é anterior à 7a1 (`tela_luta.gd` ~linha 453/674: `especial` força `anim = "uppercut"`), mas a 7a1 não o restringiu por arte nem por fase.
- **Quem corrige:** Designer decide o que o especial vira no Jiu-jitsu (desligar, ou versão de chão); UI/UX implementa.

### B3 — Média — As animações `takedown` e `fall` são cortadas pelo próximo golpe do adversário
- **Passos:** qualquer luta de JJ em que o adversário ataca até ~1 s depois da queda (acontece sempre: ele ataca a cada 1,8 s). `qa_f7a1_poses.gd` (sem `--cap`), linha do tempo.
- **Obtido:** nas 3 lutas amostradas a queda do jogador (12 quadros a 12 fps, 1,0 s) é interrompida por outra pose após 0,2 a 0,7 s (ex.: t = 2,95 `takedown#0`, 3,15 `takedown#3`, 3,46 `takedown#6`, 3,66 `block#0`; na luta 2, `takedown#0` em 5,21 vira `ground_top_hit#0` em 5,45). O `fall` do adversário foi cortado no quadro 3 de 9 (luta 1) e ainda saiu um `ground_punch` dele no mesmo instante da queda, com a fase ainda em pé (luta 2, t = 5,21). O escopo diz que a queda "não se corta".
- **Quem corrige:** UI/UX (`_agendar_evento`: segurar o evento seguinte do adversário até o fim de `takedown`/`fall`, ou encurtar a folha) ou Designer (afastar os tempos). Não afeta número nem prévia.

### B4 — Baixa — Plural errado: "ELE ESCAPOU 1 VEZES"
- **Passos:** derrota de Jiu-jitsu com `bjj_escaped` e `n = 1` (`fim_bjj_escaped.png`, `tests/qa_f7a1_fim.gd`).
- **Quem corrige:** Roteirista (`reason_passive_bjj_escaped` precisa de forma para n = 1) e Programador, se o plural for por código.

### B5 — Baixa — Boxe Defensivo diz "NÃO CANSA", mas o ritmo cai
- No 3º round o intervalo do Defensivo sobe de 1,46 s para 1,80 s (−19% de golpes), sem CANSADO. Está no design (§2.2), mas o texto da prévia promete "NÃO CANSA". Sugestão: "CANSA MENOS" ou "VOLTA A 1,80 S".
- **Quem corrige:** Designer/Roteirista (decisão de texto).

### B6 — Baixa — A nota `boxing_tired` aparece em quase toda derrota por pontos do Boxe fora do Defensivo
- A regra é `t_fim >= tired_at` (10,67 s); quem perde por pontos chega a 16 s, então a nota "VOCÊ CANSOU NO 3º ROUND" aparece junto de "FALTARAM 539K DE AGILIDADE" (`f7a1_fim_derrota_arena`), mesmo quando o cansaço não pesou. É a regra do design (§9), só pouco informativa.
- **Quem corrige:** Designer (apertar a regra, ex.: só se o adversário passou a frente depois do cansaço).

### B7 — Baixa — Cartão do Boxe na janela de escolha repete "MÃO RÁPIDA"
- A frase de efeito "MÃO RÁPIDA. CABEÇA FRIA. QUEM CLICA, MANDA." e a linha da passiva "MÃO RÁPIDA: SOCA MAIS RÁPIDO..." aparecem no mesmo cartão (`f5_arte_primeira`). **Quem corrige:** Roteirista.

### B8 — Baixa (limpeza) — Comentário e arquivo desatualizados
- `scripts/game_state.gd:488` ainda descreve o traço "+10% DE DANO" que saiu na 7a1. **Quem corrige:** Programador.
- Fora da 7a1, só informativo: o `tests/data/fase3_casos.json` do repositório não é regenerado igual pelo `exportar_casos.py` atual (valores de adversário diferentes). O teste da fase 3 passa porque o arquivo carrega os próprios números.
- O estado `f7a1_luta_jj_finalizou_letreiro` do `ui_audit` captura a janela VENCEU (a captura do letreiro de verdade é `f7a1_luta_jj_finalizou`). **Quem corrige:** UI/UX (tempo da captura).

### B9 — Informativo — Save editado com `finish` incoerente
- O validador aceita `result.finish` válido mesmo sem a arte correspondente (ex.: "submission" numa luta sem Jiu-jitsu); valor lixo vira "points". Sem erro de script em nenhum dos 6 casos testados (`qa_f7a1_savebad.gd`). Só afeta quem edita o save à mão. Nenhuma ação obrigatória.

## Riscos

- **R1 — prévia por estado isolado:** a média por célula fica a ≤ 2 pontos, mas um estado isolado pode divergir mais (pior: 12,2 pontos no JJ Seu Muralha Defensivo; 200 sementes fixas da prévia contra 1.000 reais). O critério (por adversário e arte) passa; o jogador pode, raramente, ver um rótulo (verde/amarelo) que erra por uma faixa.
- **R2 — p90 da campanha do JJ:** a 3/s o p90 do JJ ficou 22% atrás do Boxe (N=100) e, no design, a 4/s chegou a 32%. A média e a mediana estão dentro dos 15%. Vale o Designer reler a nota na revisão.
- **R3 — Kid fácil a 4/s:** continua perto de 93–95% na 1ª tentativa (registrado no design §13 para a 8a); não piorou.
- **R4 — leitura da arte no JJ:** B1, B2 e B3 caem justo na tática da arte (Defensivo) e no "chão"; o critério 1 ("o testador diz a arte olhando") depende de corrigi-los.
- Nota de processo: `run_tests.ps1` redirecionado para arquivo só deixa o resumo (o `Out-Host` dos testes não é capturado); por isso os números por teste vêm das execuções diretas listadas acima.
