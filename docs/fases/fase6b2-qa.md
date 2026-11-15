# Fase 6b2 (Cara de lutador): relatório de QA

Dono: QA. Data: 2026-11-15. Branch `fase-6b2`. Critérios: 13–17 (6b2) e 18–20 (as duas partes) de `fase6b-escopo.md`.
Só reporte; nenhum código de `scripts/`, `ui/`, `data/` ou `assets/` foi alterado pelo QA.
Save real do dono: não tocado (o guarda do `run_tests` confirma "igual antes e depois"). Scripts novos: `tests/qa_f6b2_camadas.gd`, `tests/qa_f6b2_logica.gd`.

## Veredito
**Pronto para o Diretor revisar**, com 2 bugs de gravidade baixa (B1, B2) e 1 risco (R1). Nenhum bloqueante.

## Critérios
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 13 | Opções novas certas em todas as poses | **OK** | `qa_f6b2_camadas.gd`: 132 folhas com camadas (poses x 5 luvas x folhas `_left`). Em todas: 4 cortes, 2 partes de cima, faixa, meião e máscara existem e têm o mesmo tamanho do corpo. 6.336 composições (4 cortes x 3 partes x meião x faixa x 132) sem erro. Nenhuma cor-chave repetida entre camadas (0 avisos). Contact sheets (`scratchpad\camadas\sheet_*.png`, 5 luvas x 2 looks x 11 poses x 4 cortes): luva e manga ficam na frente do cabelo e da faixa; coque e volume leem no perfil. Faixa `red` (laranja-avermelhado claro) se distingue da luva vermelha, inclusive no bloqueio (luva junto da testa). |
| 14 | Arquivos crescem com opções, não com combinações | **OK** | 420 PNG em `assets/sprites/disciple/`: 32 poses x 7 camadas novas (buzz, volume, bun, tank, tee, socks, band) = 224 novos, mais body (132, um por luva), front (32) e head_short (32). 131.040 visuais, zero folhas por combinação. |
| 15 | Dois mentores | **OK** | `test_fase6b2` (76/76 no run_tests) e `qa_f6b2_logica`: roster vazio, só John, John+1, John+3 (pega o último), derrota e saída contam, `unknown` conta, academia e `mentors == []` somem, cena grande some, chegada curta aparece, troca no RECEBER, look lixo cai no padrão, roster de 79 entradas. Captura `f6b2_mentor2.png`: John no caixote e o 2º mentor em (150,262) com o visual dele; `f6b2_mentor2_cena.png`: sumiu na cena grande; `f6b2_mentor2_chegada.png`: ele continua no canto na chegada curta; `f6b2_mentor2_dica.png`: dica "NOME: JÁ PASSOU O POSTO." |
| 16 | Nada cobre o jogo | **OK, com B2** | Capturas com equipe, caixas, porta aberta, balão do Osmar e do John: nenhum balão cobre a cabeça do 2º mentor (cabeça em y~197, balões acima de y~170 e a protecção `cabeca_mentor2` entra na lista de áreas). Ele fica fora da faixa do alvo; a chegada curta passa pela porta sem atravessá-lo. Ver B2 sobre a dica. |
| 17 | Save da 6b1 abre sem migração | **OK** | `test_fase6b2`: save v12 gerado como a 6b1 abre em `creating`, rascunho preservado, 2º mentor = último do roster, SORTEAR passa a variar, continua v12. `qa_f6b2_logica`: save com ids lixo (`top_color: red`, `hair_style: mohawk`, `look: "lixo"`, nome de 26 letras) cai no padrão com aviso, sem erro. |
| 18 | Balanço inalterado | **OK** | Nenhum arquivo de balanço mudou (`git diff fase-6b -- data/training.json generators fights opponents shop skill_tree career locations tools/sim` vazio). `qa_f6a_sim.gd` dá a mesma saída da 6b1 guardada (`t=300 treino=3604 dia=13`, `LUTAS 3`; só diferem o BOM da 1ª linha). Relógio parado com a tela de criação aberta: `segundos_campanha` 0.0 depois de 100 ticks. `fase5_sim.py b23c f52`: ver "Pendência" abaixo. |
| 19 | `ui_audit` 0 problemas | **OK** | `--estados todos`: `ESTADOS 305 | PROBLEMAS 0`. Capturas `f6b2_*` olhadas: criação com 10 linhas em 2 colunas, cor apagada com a peça em SEM (`f6b2_criar_apagadas.png`), nome de 14 letras "MMMMMMMMMMMMMM" cabe (`f6b2_criar_cheio.png`), CAMISETA cabe, dois mentores com balão do Osmar e do John sem cobrir cabeça. |
| 20 | Testes passando | **OK** | `tools/run_tests.ps1`: `TODOS OS TESTES PASSARAM` (76/76 no `test_fase6b2`, 4/4 no guarda, cena principal 120 frames sem erro). Nenhum `ERROR` nem `SCRIPT ERROR` no run_tests e no ui_audit. Vazamento "24 ObjectDB / 9 resources" aparece só no `qa_f6a_sim.gd`, igual na saída da 6b1 (anterior à 6b2). |

## Sorteio (item 4 do pedido)
10.000 sorteios (`qa_f6b2_logica`): sem camisa 40,0% / regata 28,8% / camiseta 31,1%; faixa 40,3%; meião 50,1% (dentro de ±2 p.p.). Pares feios: 0 em 10.000. Calção igual ao do último: **3,0%**; cabeça igual: **1,03%** (ver B1).

## Bugs

### B1 (baixa): SORTEAR ainda pode repetir o calção ou a cabeça do último discípulo
- **Passos:** `qa_f6b2_logica.gd` (`_sorteio`): roster com um discípulo `short/brown/green`, 10.000 chamadas a `disciples.sortear(rng, roster, "")`.
- **Esperado:** nenhuma repete calção nem corte+cabelo do último (pedido do QA/escopo: "sem repetir").
- **Obtido:** calção repetido em 300 casos (3,0%), cabeça em 103 (1,03%). A regra faz só "1 novo sorteio" (design §2, itens 3 e 4), e o novo sorteio pode cair no mesmo valor. Como o último agora fica na garagem ao lado do novo, o jogador pode ver dois lutadores de calção igual (raro).
- **Arquivo provável:** `scripts/disciples_data.gd`, `sortear()` (blocos "Calção diferente do último" e "Cabeça diferente do último").
- **Quem corrige:** Programador (excluir o valor do último ao sortear de novo). O Designer pode, em alternativa, aceitar o 1 sorteio como regra e ajustar o texto do design.

### B2 (baixa, cosmético): a dica do 2º mentor cobre jogador e equipe
- **Passos:** garagem com 2 mentores, passar o mouse no 2º mentor (`f6b2_mentor2_dica.png`).
- **Esperado:** a dica não esconde o jogo (critério 16, "nada cobre o jogo").
- **Obtido:** a faixa preta "BETO CRUZ: JÁ PASSOU O POSTO." fica em x~210..376, y~228..243 (base 640x360), em cima do tronco do lutador, do sofá e da equipe. É temporária (só com o mouse parado em cima) e não cobre a cabeça nem a faixa do alvo, por isso a gravidade é baixa.
- **Arquivo provável:** `ui/sala.gd` (onde a dica é montada, ramo `disc_mentor2_hint`): posicionar a dica acima do 2º mentor, fora de `no_cover`.
- **Quem corrige:** UI/UX.

## Riscos
- **R1: faixa branca em cabelo platina e a luva `glove_l1` (creme).** Os pares de `avoid_pairs` valem só no sorteio. Na escolha manual a faixa branca em cabelo platina e a luva creme quase somem (sheets `_glove_l1_b`). É a regra do design (escolha livre), só vale avisar o Diretor.
- Preço visual: a regata/camiseta preta em `skin_5` fica escura, mas legível (contorno separa); também só por escolha manual.

## Pendência
- `fase5_sim.py b23c` e `f52`: o resultado novo foi gerado (`scratchpad\sim_new_b23c.txt`, `sim_new_f52.txt`), mas a rodada do `git archive fase-6b` para comparar byte a byte não terminou durante o teste. A igualdade se apoia em: `tools/sim` e todos os `data/` de balanço idênticos aos da `fase-6b`, e o `qa_f6a_sim.gd` igual ao da 6b1.
- Não verifiquei por script, só por captura, que a prévia da tela de criação é pixel a pixel igual ao lutador na garagem e na luta (as capturas conferem visualmente: mesmo corte, cores e meião).
