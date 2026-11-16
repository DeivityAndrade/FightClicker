# Fase 6c1 (Casa nova) - relatório do QA

**Veredito: APROVADA, com 1 bug médio e 2 observações para o Diretor decidir.** Nenhum critério falhou; o bug médio (comentário da arte perdido) não impede jogar, mas faz o critério 10 valer só em parte do jogo.

## Como foi testado
Save do dono intocado: `APPDATA` apontado para uma pasta temporária e o guarda `test_real_save_guard` passou (antes/depois). Janelas com `--position 1950,40`.

| Comando | Resultado |
|---|---|
| `tools\run_tests.ps1` (28 arquivos `test_*.gd`, cena principal, guarda do save) | `TODOS OS TESTES PASSARAM`, 0 FAIL, 3200 PASS (os blocos de "stack" no log são do teste de arquivo ausente, esperados) |
| cena principal `--quit-after 300` | 0 erros |
| `tools/cenas/validar_cenas.gd` | `primeira_academia`: 0 erros, 12,90 s presos; `saida_primeiro_mentor`: 0 erros, 0,00 s presos; `chegada_discipulo` 2,37 s; `primeira_sucessao` 14,75 s |
| `tests/qa_f6c1_ui.gd` (janela, 2º monitor) | TOTAL 19, FALHAS 0 |
| `tools/ui/ui_audit.gd --estados todos` | **ESTADOS 309, PROBLEMAS 0** (capturas em `...\scratchpad\audit\`; 4 estados da 6c1) |
| `tests/qa_f6c1_logica.gd` (novo, meu) | 19/19 PASS |

## Critérios de aceite (6c1)
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Cena da academia, ≤ 15 s presos, foto torta, arte abre depois | OK | validador 12,90 s; `qa_f6c1_ui`: "a cena terminou sozinha", "academia: foto torta"; captura `fase6c1_ui_chegada_escolha_da_arte.png` |
| 2 | Pular em ≤ 0,3 s deixa tudo montado | OK | `qa_f6c1_ui`: PULAR disponível/soltou o relógio/academia montada; `test_fase6c1` (PULAR com esteira) |
| 3 | Toca uma vez só; fechar no meio = estado final | OK | `test_fase6c1` `_teste_cena_academia_save`, chegada seguinte sem cena; fala volta 1x só |
| 4 | Elenco certo (John joga: vizinho carrega; John mentor carrega; depois, o último) | OK | `test_fase6c1` `_teste_elenco`; `qa` Carreira 1: vizinho, sem mentores na sala |
| 5 | Save antigo: cena na próxima chegada + `cl_primeira_academia` 1x | OK | `test_fase6c1` `_teste_save_antigo`; meu cenário G: única fala do Osmar na academia foi `cl_primeira_academia` |
| 6 | Osmar só onde está desenhado, sem balão sem personagem | OK | cenário G: nenhuma fala durante a cena nem com a arte pendente; nenhuma fala de `coach` com Osmar não desenhado |
| 7 | Mentores na academia (regra da garagem) | OK | `_teste_mentores_por_local`; captura `fase6c1_ui_academia_cheia.png` (John no caixote, último em pé) |
| 8 | Saída: gatilho, clique livre, interrupções, nunca duas vezes | OK | vitória REAL na academia arma o marco e a saída sai 1x (cenário A); `_teste_saida_interrupcoes`; meu cenário D: dia da luta interrompe (interrompidas=1); `_teste_saida_fechar_no_meio` |
| 9 | Depois da saída: ninguém do John, último no caixote, `mentor_2_spot` vazio, Carreira 2 caixote vazio | OK | `_teste_depois_da_saida`, `_teste_saida_fechar_no_meio`; captura `..._saida_interrompida_c2.png` (caixote vazio, Osmar de volta) |
| 10 | Comentário da arte, sem chamar de "certa", com o espaçamento | **OK em parte** | Textos ok. Mas ver BUG-1: no fluxo normal da 1ª academia ele se perde |
| 11 | Balanço inalterado; relógio parado na cena | OK | `_teste_balanco` (cena tocada = pulada; com saída = sem saída), relógio/treino/ouro parados durante a cena |
| 20 (parte 6c1) | `ui_audit` 0 problemas | OK, com cobertura curta | 309 estados, 0 problemas. Ver OBS-1 |
| 21 | Testes verdes, save de teste, janelas no 2º monitor | OK | acima |

## Cenários que tentei quebrar
- Fechar no meio da cena da chegada e no meio da saída: ao reabrir, marco gravado, John fora, nada repete. OK.
- Pular a cena: OK. Save antigo sem marcos: OK. Carreira 1 (John joga, vizinho carrega, nenhuma saída em 300 s, vitória na academia não arma). OK.
- Saída pelos dois caminhos: vitória real na academia (cenário A) e reserva Carreira 4+ (cenário E). Ambas saem 1x. OK.
- Interromper com janela, luta, MUDAR, fim, RECEBER e dia da luta. OK.
- Derrota na academia não arma a saída (cenário B, marco falso). OK.
- Durante a cena da academia e com a arte pendente a saída não dispara (cenário F). OK.
- Quem fica onde (garagem e academia, antes e depois): conferido por `mentores_na_sala()`. OK.
- Balanço: iguais nos testes comparativos. OK.

## Bugs
### BUG-1 (média) - o comentário da arte (`cl_arte_*`) se perde na 1ª academia
- **Quem corrige:** Programador (`scripts/game_state.gd`, `_resolver_gatilhos`, ~linhas 3480-3535), com o Roteirista/Designer se for ajustar o tempo.
- **Passos:** campanha 2 com John, MUDAR para a academia, pular/ver a cena, escolher a arte e esperar sem clicar. Reproduzi em `tests/qa_f6c1_logica.gd` (cenário G, 150 s: 0 falas `cl_arte_*`).
- **Causa:** `cl_primeira_academia` sai ~2 s depois da escolha da arte. O `art_choice` cruza 60 s de arte, ou seja ~58 s depois, e o intervalo mínimo entre comentários é 60 s (`gap_min_seconds`). Nesse caso o gatilho é descartado (comentário "sem intervalo: o novo some") e `_arte_comentada` já foi marcada como true, então não volta mais. Medi `_t_real - _ultimo_comentario = 59,5` e `_arte_comentada = true` sem fala. Com `cl_primeira_academia` já vista antes, `cl_arte_4` sai normalmente.
- **Efeito:** na 1ª academia de cada save (justamente o caso que o design §5.4 queria cobrir), o Osmar não comenta a arte. Nas campanhas seguintes funciona se o último comentário foi há mais de 60 s.
- **Sugestão:** marcar `_arte_comentada` só quando a fala sair, ou guardar o gatilho na vaga (`defer`) quando falhar só pelo intervalo.

## Observações (não são bugs; para o Diretor/Produtor)
- **OBS-1 (UI/UX):** o `ui_audit` cobre só 4 estados da 6c1 (`f6c1_chegada_cena`, `f6c1_chegada_2x`, `f6c1_academia_cheia`, `f6c1_saida`). O critério 20 pede também Osmar e os dois mentores **com balão** na academia e a saída **em cada quadro, na garagem e na academia**. A saída na garagem (por baixo da porta de enrolar) não tem captura nem verificação visual; só a lógica está testada. Recomendo UI/UX acrescentar esses estados antes da 6c2.
- **OBS-2 (ordem):** com a vitória já armada, a saída pode sair ~2 s depois da escolha da arte (cenário com Carreira 3: `SAIDA_PEDIDA` em t=2,0 s). A `cl_primeira_academia` fica para 74 s depois, porque a saída conta como comentário. Funciona e nada se perde, só é uma sequência apertada: cena, arte, saída, e a fala do Osmar muito depois.

## Capturas conferidas
`docs/arte/mockups/fase6c1_ui_academia_cheia.png`, `..._chegada_A4_2x.png`, `..._chegada_A7.png`, `..._chegada_escolha_da_arte.png`, `..._saida_J4.png`, `..._saida_interrompida_c2.png`: nada cortado ou torto; balão do John legível, janela da arte centralizada, PULAR visível só na cena. (O teste `qa_f6c1_ui.gd` regrava essas capturas.)

## Riscos
- A saída na garagem não foi vista em tela (OBS-1).
- Com muitos vizinhos, o Osmar na academia pode ser coberto (decisão já aceita pelo dono, não reportado).

## Arquivos novos do QA
`tests/qa_f6c1_logica.gd` (cenários A a G; roda headless com `APPDATA` de teste).

**Pronto para o Diretor revisar: sim**, com o BUG-1 anotado como pendência média.

## Save real (cópia)
Critério 5 do escopo e a migração (save v12, sem v13 na 6c1) conferidos com uma **cópia** do save real do dono, em uma pasta temporária (`APPDATA` apontando para ela, `--headless`, sem janela). Só li o original; hash SHA-256 de `save.json` antes e depois: `98ace68c509cf9463f8955ba1ea816214f78ad5b253898160957209f5893013a` (igual); `save.json.bak`: `5f4d4a48e5193f01ba9fd330d1e85b79b29f3b2489245ce6b9dbdf27b9f5de06` (igual). Script: `scratchpad/qa_save_real.gd` (fora do projeto).
- **Carga:** sem aviso nem erro. Moedas, Carreira 6, Legado 450, cinturões/carreiras, árvore, atributos, discípulo atual, roster (3), mentores (`["first"]`) e os 5 marcos antigos idênticos. Salvar e reler: `permanent`, `school` e os campos da carreira idênticos (sem perda).
- **Estado do save:** estava na garagem, Carreira 6, John ainda na escola, sem nenhum marco da 6c1 (`cena_primeira_academia`, `cena_saida_primeiro_mentor`, `disciple_gym_win` ausentes). OK.
- **Antes da academia (garagem):** John no caixote (`first:seat:mentor_spot`) e o último que passou o posto em pé (`last:stand:mentor_2_spot`), Osmar presente. OK.
- **1ª ida à academia:** MUDAR toca a `primeira_academia` (marco gravado na hora), elenco `fighter: disciple`, `box: first` (John carrega a caixa); a saída não dispara durante a cena. Depois: John `seat` em `gym_mentor_spot`, último `stand` em `gym_mentor_2_spot`, Osmar presente, foto torta (`old_photo_gym`). A arte já estava escolhida (boxe), então não reabre escolha. OK.
- **`cl_primeira_academia`:** toca 1 vez. **Saída do John:** pelo gatilho de reserva (Carreira 6 >= campanha do John + 3), 1 vez, depois da cena; `mentors` fica vazio e o marco é gravado. Depois, só o último (Dani Cutelo) no caixote. OK.
- **Cena não repete** em idas seguintes. OK.
- Nota: o harness acusou "save real mudou" (28/29) porque, com `APPDATA` redirecionado, ele compara a **cópia** que o teste salvou de propósito; o save real não foi tocado (hashes acima).
- Observação: neste save a saída do John já estava devida desde a carga (reserva). Se o dono ficasse na garagem, ela dispararia lá no 1º momento calmo, antes de ir à academia (comportamento previsto no §3 da API); aqui o teste foi feito com a ida à academia primeiro.

**Resultado: critério 5 OK com save real.**
