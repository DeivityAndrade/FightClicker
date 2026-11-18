# Fase 6d, item 1: QA das cenas com o lutador criado

QA, 2026-11-18. Branch `fase-6d`. Só reportado, nada corrigido. Save real intocado: todos os testes rodaram com `APPDATA` apontando para uma pasta temporária nova e `--position 1950,40`.

## Veredito

**NÃO PASSA (critério 1 da 6d).** 1 bug Alto (C1) e 1 Baixo (C2). O discípulo montado na criação aparece **errado (visual padrão)** na entrada pela porta da primeira sucessão e da chegada curta. Em todo o resto (garagem, academia, luta, mural, retratos, mentores, saída do John) as camadas, cores e espelhos estão certos.

## Visuais usados (7 + o padrão)

| # | Pele | Corte | Cabelo | Cima | Faixa | Calção | Meião |
|---|---|---|---|---|---|---|---|
| V1 | skin_1 | buzz | preto | nada | sem | verde | sem |
| V2 | skin_5 | bun | loiro | regata branca | vermelha | azul | com |
| V3 | skin_1 | volume | platinado | camiseta preta | preta | preto | com |
| V4 | skin_5 | short | preto | camiseta branca | branca | branco | com |
| V5 | skin_3 | bun | cobre | nada | amarela | roxo | com |
| V6 | skin_2 | volume | castanho-escuro | regata amarela | sem | amarelo | sem |
| V7 | skin_4 | buzz | castanho | camiseta verde | verde | verde | com |

Quatro jogos completos (primeiro discípulo A = futuro mentor, segundo B = quem joga): V2/V3, V4/V5, V6/V7, V7/V1. Todos os 4 cortes, os 3 estados de parte de cima, com e sem faixa, com e sem meião, peles 1, 2, 3, 4, 5, cores extremas (preto sobre preto, branco sobre branco em pele 5, platinado). Símbolo da escola: aparece no peito (regata/camiseta) e na perna do calção (peito nu) nos quadros onde `simbolo_no_lutador()` é verdadeiro.

## Auditoria de arquivos (`tests/qa_f6d_camadas.gd`, headless)

- 140 folhas com `layers` no manifest. Nenhum arquivo de camada falta, nenhuma camada com tamanho diferente do corpo.
- Toda folha `X_disc` tem `X_disc_layered` (única exceção: `mural_portrait_disc`, que já nasce em camadas). Nenhuma folha antiga `_disc` (regata caindo) é usada como fallback nas cenas, na luta ou no retrato.
- Cada folha: trocar `top`, `headband`, `hair_style` (4 cortes) e `socks` muda a textura. Camadas vazias: só as esperadas (retrato e busto não têm meião nem símbolo de perna; `disciple_carry_crate_left` não tem símbolo no peito porque o caixote cobre o tronco). Ver observação O1.

## Onde foi conferido

| Situação | Resultado | Imagem |
|---|---|---|
| Tela de criação (prévia com todas as camadas) | OK | `fase6d_qa_p23_cria_a.png`, `fase6d_qa_p23_cria_b.png` |
| Primeira sucessão S1-S9, John e Osmar | OK (o discípulo ainda não aparece) | - |
| **Primeira sucessão, parte 2 (S6-S10): entrada pela porta com folhas `_left`, idle com luvas** | **FALHOU (C1)** | `fase6d_qa_p23_s2_00.png`, `_01.png`, `_02.png`, `fase6d_qa_p45_s2_02.png` |
| **Chegada curta (2ª sucessão em diante)** | **FALHOU (C1)** | `fase6d_qa_p23_s2b_chegada_00.png`, `fase6d_qa_p71_s2b_chegada_00.png` |
| Chegada curta e criação retomadas de um save (fechar na criação / depois do CONFIRMAR) | OK | `fase6d_qa_retomar_r1_chegada.png`, `fase6d_qa_retomar_r2_garagem.png` |
| Garagem depois do controle (lutador no saco) | OK | `fase6d_qa_p23_gar_a_parado.png`, `fase6d_qa_p67_gar_b_mentores_x4.png` |
| Mentor sentado (John) + 2º mentor em pé com o visual do discípulo A | OK | `fase6d_qa_p23_gar_b_mentores.png`, `fase6d_qa_p45_gar_b_mentores.png` |
| Chegada à academia, discípulo com o saco e John com o caixote | OK (visual certo do lutador) | `fase6d_qa_p23_gym_chegada_00.png`, `_02.png` |
| Chegada à academia sem o John (o último que passou o posto traz o caixote, com o look dele) | OK | `fase6d_qa_g24_gym_chegada_sem_john_01.png`, `_02.png` |
| Academia depois da cena | OK | `fase6d_qa_p23_gym_depois.png`, `fase6d_qa_p45_gym_depois.png` |
| Saída do John na academia, último aposentado indo para o caixote | OK (look, espelho, sentar) | `fase6d_qa_p23_saida_gym_00.png`, `_02.png`, `_04.png`, `_05.png`, `fase6d_qa_p71_saida_gym_depois_x3.png` |
| Saída do John na garagem | OK | `fase6d_qa_p23_saida_gar_00.png`, `_04.png`, `_05.png`, `fase6d_qa_g24_saida_gar_c4_*.png` |
| Aparelhos: saco, esteira, corda (garagem); pera, boneco (academia) | OK | `fase6d_qa_aparelhos_garage_look3.png`, `fase6d_qa_aparelhos_gym_look2.png` |
| Luta: as 17 poses x luvas L0/L2/L4 x 7 visuais, pelo caminho do jogo (`TelaLuta._nome` + `aplicar_visual_disc`), incluindo `ko`, `ko_back`, `ko_knees` | OK | `fase6d_qa_poses_look0.png` ... `look6.png` |
| Luta real: vitória e K.O. por joelhos (`ko_knees`) | OK | log `poses vistas` em `tests/qa_f6d_cenas.gd` |
| Retrato da prévia e do HUD da luta (4 visuais) | OK | `fase6d_qa_retratos.png` (retrato da prévia em cima, do HUD da luta embaixo; a prévia inteira sai em `tests/qa_f6d_cenas.gd`, bloco `luta`) |
| Mural (busto, 7 visuais + John, com selo) | OK | `fase6d_qa_mural_0.png` |

## Bugs

### C1 (ALTA): o discípulo montado na criação entra pela porta com o visual PADRÃO

- **Onde:** primeira sucessão, parte 2 (depois do CONFIRMAR: entrada pela porta com `walk_bare_left`, `duck_under`, `take_gloves` e o `idle` com luvas até o controle voltar) e chegada curta (2ª sucessão em diante: `walk_bare_left`, `duck_under`, `idle`).
- **Passos:** abrir jogo novo, `aposentar`, RECEBER NOVO DISCÍPULO. Na tela de criação trocar pele, corte, cabelo, parte de cima, faixa, calção, meião (ex.: pele 5, coque loiro, regata branca, faixa vermelha, calção azul, meião). CONFIRMAR. Olhar o discípulo entrando pela porta. Repetir numa 2ª sucessão.
  Reprodução automática: `tests/qa_f6d_cenas.gd -- p=2,3` (comando no fim).
- **Esperado:** quem entra pela porta é o lutador da criação (mesma pele, corte, cabelo, cima, faixa, calção, meião), igual à prévia da tela de criação.
- **Obtido:** entra sempre o discípulo **padrão** (pele 3, cabelo castanho curto, peito nu, sem faixa, calção verde, sem meião), tanto na entrada pela porta, quanto no quadro final da cena (de pé com luvas junto ao saco). Quando o jogo devolve o controle, o lutador da sala "troca" de repente para o visual certo (pop visível). Nas duas sucessões, com os 4 pares de visuais.
- **Contraste que prova a causa:** se o jogador fecha o jogo na criação, reabre e confirma (ou fecha depois do CONFIRMAR), a mesma cena sai **correta** (`fase6d_qa_retomar_r1_chegada.png`, `r2_garagem.png`). Só o caminho vivo (RECEBER, criar, CONFIRMAR sem fechar o jogo) quebra.
- **Imagem:** `docs/arte/mockups/fase6d_qa_p23_s2_00.png` (entrada, calção verde e peito nu; o escolhido era regata branca, calção azul, coque loiro, pele 5), `fase6d_qa_p23_s2_02.png`, `fase6d_qa_p45_s2_02.png`, `fase6d_qa_p23_s2b_chegada_00.png`, `fase6d_qa_p71_s2b_chegada_00.png`. Prova contrária: `fase6d_qa_retomar_r1_chegada.png`.
- **Arquivo provável (causa):** o elenco da cena é resolvido **uma vez, no começo da cena**, antes de existir o discípulo escolhido.
  - `scripts/cena_player.gd:84` (`iniciar`: `_elenco = _resolver_elenco(cena)`) e `:501-502` (`info["look"] = gs.visual_lutador()` para `current_player`), copiado para `mundo.atores[id].look` em `:153`.
  - `scripts/estado/sucessao.gd:63-67` (`visual_lutador()`): sem `gs.discipulo.look` devolve `disciples.look_padrao`, então o valor errado não é vazio e passa.
  - `ui/cena_sala.gd:112-116` (`_montar_ator` guarda `a.look`) e `:173-175` (`_pose` usa `a.look` se não for vazio, em vez de ler o visual atual).
- **Sugestão de rota (quem for corrigir decide):** não congelar o `look` do discípulo no `iniciar`; reler `visual_lutador()` a cada pose do ator `current_player` ou refazer `_resolver_elenco` quando `sucessao_mudou` vira `scene_2`/`arriving`. Reabrir os 4 pares depois.
- **Responsável:** Programador (`scripts/cena_player.gd`, `scripts/estado/sucessao.gd`) e UI/UX só se a correção ficar em `ui/cena_sala.gd`.

### C2 (BAIXA): o John atravessa o lutador parado no saco, na saída

- **Onde:** saída do John, garagem e academia.
- **Passos:** campanha de discípulo com o marco `disciple_gym_win` (ou campanha >= 4), esperar a saída tocar com o lutador no saco.
- **Esperado:** o John contorna o lutador, sem sobrepor o corpo.
- **Obtido:** na caminhada do John até a porta com a mochila ele passa colado e **sobreposto ao lutador** (ordenado por y: fica parcialmente atrás). Não depende do visual escolhido (acontece com todos); só aparece porque o lutador fica parado no ponto de foco do saco.
- **Imagem:** `fase6d_qa_p23_saida_gym_00.png` (quadros 6 a 8), `fase6d_qa_p23_saida_gar_00.png` (quadros 6 a 8).
- **Arquivo provável:** `data/cutscenes/saida_primeiro_mentor.json` (pontos do `move` do `first`).
- **Responsável:** Diretor de Cutscenes (caminho) / Programador (se for preciso ajustar o ponto de saída).

## Observações (não são bugs)

- O1: o símbolo da escola não aparece no busto do mural nem no retrato de quem está sem parte de cima (o busto não pega a perna). Está no design (`fase6c2-design.md` linha 155). Também não há símbolo no peito na folha `disciple_carry_crate_left` (o caixote cobre o tronco).
- O2: preto sobre preto (V3) e branco sobre branco em pele 5 (V4) continuam legíveis; contorno `ink` separa as peças.
- O3: o 2º mentor em pé aparece sem o símbolo quando a campanha dele é anterior à do primeiro cinturão (regra de `campanha_do_simbolo()`); confere com a API da 6c2.
- O4: os modelos de pose da luta foram conferidos no quadro 0 de cada pose (3 luvas); a animação completa passa pelas mesmas folhas em camadas (auditoria de arquivo) e foi vista em luta real.
- Durante a QA outras mudanças de `ui/` (itens 2 e 3 da 6d, feitas em paralelo) estavam no working tree; nenhum erro novo apareceu nas execuções.

## Como reproduzir

```
set APPDATA=<pasta temporaria nova>
godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_cenas.gd -- p=2,3
```
`p=A,B` escolhe os visuais do 1º e do 2º discípulo (índices 1 a 7 do vetor `LOOKS`); `so=s2,s2b,gym,saida,luta` limita os blocos.

Scripts novos (todos em `tests/`): `qa_f6d_camadas.gd` (auditoria de arquivos, headless), `qa_f6d_cenas.gd` (jogo completo: sucessão 1 e 2, garagem, academia, saída, luta, garagem de saída), `qa_f6d_poses.gd` (17 poses x 3 luvas x 7 visuais), `qa_f6d_retomar.gd` (retomada de save), `qa_f6d_gym_sem_john.gd` (academia depois da saída do John), `qa_f6d_aparelhos.gd` (todos os aparelhos), `qa_f6d_mural.gd` (mural e retratos).


## Reteste (parte 1)

Data: 2026-11-18. Itens 1 a 3 e critérios 1, 2, 3 e 5 da 6d. APPDATA temporário em todas as execuções, janelas em `--position 1950,40`, save real intocado (o guarda da bateria confirmou). Nada corrigido: só reporte.

### Resumo

| Item / critério | Resultado |
|---|---|
| C1 (visual do discípulo nas cenas) | **PARCIAL**: quase tudo corrigido, mas a passada por baixo da porta (`duck_under`) ainda sai com o visual padrão. Ver R1. |
| C2 (John passa por trás do lutador) | OK, com ressalva estética (R2, BAIXA) |
| Item 2 / critério 2 (balão junto do cursor) | OK |
| Item 3 / critério 3 (números por atributo) | OK |
| Critério 5: `tools/run_tests.ps1` | OK (`TODOS OS TESTES PASSARAM`, `EXIT=0`, guarda do save real 4/4) |
| Critério 5: `test_golpes.gd` sozinho x10 | 0 falhas em 10 |
| Critério 5: `ui_audit --estados todos` | OK: `ESTADOS 370 \| PROBLEMAS 0` |
| Critério 5: `foto.gd` igual à da main | OK: `cmp` sem diferença (247672 bytes cada; main = `origin/main` daa89fe em worktree temporário, já removido) |
| Critério 1 (6 visuais) | Não fechado enquanto R1 existir |

### C1 reteste

Comandos: cópias dos meus `tests/qa_f6d_cenas.gd` e `qa_f6d_retomar.gd` só com o prefixo das imagens trocado para `fase6d_qa_reteste_` (as cópias foram apagadas). Pares `p=2,3` e `p=4,5`, blocos `s1,cria,s2,s2b` e `s1,cria,s2,gym,saida,gsaida`, mais a retomada de save. `FALHAS 0` nas três execuções.

Corrigido (comparar com o antes, `fase6d_qa_p23_s2_00.png`):
- Parte 2 da primeira sucessão: a caminhada pela porta (`walk_bare_left`), `take_gloves` e o quadro final saem com o visual da criação (regata branca, calção azul, coque loiro, pele 5; no par 4,5 camiseta branca e faixa branca). `fase6d_qa_reteste_p23_s2_00.png` (quadros 5 a 8), `_s2_02.png`, `fase6d_qa_reteste_p45_s2_00.png`.
- Chegada curta da 2ª sucessão: todos os quadros com o visual escolhido (camiseta preta, cabelo platina, volume). `fase6d_qa_reteste_p23_s2b_chegada_00.png`.
- Chegada à academia e saídas (garagem e academia): lutador com o visual certo. `fase6d_qa_reteste_p45_gym_chegada_*.png`, `fase6d_qa_reteste_p45_saida_*_00.png`.
- Retomada de save continua certa: `fase6d_qa_reteste_retomar_r1_chegada.png`.
- O teste novo `tests/test_cena_visual_discipulo.gd` passa na bateria.

**R1 (MÉDIA), sobra do C1: a passada por baixo da porta ainda usa o visual padrão.**
- Onde: primeira sucessão, parte 2, quadros em que o discípulo aparece de costas, sob a porta, na pose `duck_under` (quadros 2 a 4 de cada folha `..._s2_00.png`). Aparece pele 3, peito nu, calção VERDE e, no primeiro passo da caminhada, "troca" de repente para o visual certo. É o mesmo pop do bug original, só que por cerca de 0,7 s.
- Evidência: `fase6d_qa_reteste_p23_s2_00.png` (quadros 3 e 4: costas nuas e calção verde; quadro 5: regata branca e calção azul) e `fase6d_qa_reteste_p45_s2_00.png` (idem; quadro 5 já com camiseta branca). O trecho está idêntico ao de antes da correção (`fase6d_qa_p23_s2_00.png`).
- O que descartei: a folha `disciple_duck_under_left` TEM camadas, e `DiscVisual.textura("disciple_duck_under_left", look)` chamada direto devolve o visual certo (renderizei a folha: coque loiro, regata, calção azul). Ou seja, a textura certa existe; o que aparece na cena não vem dela. Não achei a causa sem mexer no código.
- Arquivos prováveis: `ui/cena_sala.gd` (`_pose` e o caminho do `move` com `anim: duck_under`, `facing: left`) e a ordem dos passos em `data/cutscenes/primeira_sucessao.json` (linhas 140 a 160: `show` de `disciple` em 0,0 e o `move` com `duck_under` em 1,3 s).
- Responsável: UI/UX (`ui/cena_sala.gd`); Programador se for a ordem do elenco (`scripts/cena_player.gd`).
- Passos: `godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_cenas.gd -- p=2,3 so=s1,cria,s2` (APPDATA temporário) e olhar `fase6d_qa_p23_s2_00.png`.

O critério 1 (6 visuais) foi retestado só nos pares 2,3 e 4,5; os pares 6,7 e 7,1 não foram refeitos, e o R1 impede fechar o critério.

### C2 reteste: o John passa atrás do lutador

Imagens: `fase6d_qa_reteste_p45_saida_gar_00.png` e `_01.png` (garagem), `fase6d_qa_reteste_p45_saida_gym_00.png` e `_01.png` (academia).
- Ele contorna: sobe pela parede, passa atrás do saco e desce pela direita até a porta. Não atravessa mais o corpo do lutador.
- Trecho das canelas (primeiros quadros de cada folha): lê como "atrás", mas **sem espaço**. Canelas e pés do John ficam encostados na cabeça (coque) e nas luvas do lutador, com 0 a 2 px de respiro. A ordem de camadas está certa (o lutador cobre o John), então não parece atravessar; só não tem o respiro de "passou por trás", e um olho atento vê "colado" por uns 0,4 s. Igual na garagem e na academia.
- **R2 (BAIXA, cosmética):** subir uns 4 a 6 px o ponto de passagem em `data/cutscenes/saida_primeiro_mentor.json`. Responsável: Diretor de Cutscenes. Sem urgência.

### Itens 2 e 3: conferência

Balão junto do cursor (`ui/dica.gd`, `ui/painel_loja.gd`, `ui/janela_mapa.gd`, `ui/janela_mural.gd`):
- Aparece rápido: `_mostrar` liga `visible` no mesmo quadro do `mouse_entered`, sem temporizador (0 s, abaixo de 0,15 s). Medido por leitura de código, não com relógio na tela.
- Nunca sai da tela e nunca cobre o item apontado: fuzz de `Dica.posicionar` (`tests/qa_r1_dica.gd`), 20 000 casos (balões de 40x16 a 160x90, itens de 8x8 a 140x40 em posições sorteadas): 0 fora da tela, 0 cobrindo o item, 23 com a borda a mais de 60 px do cursor (só itens muito grandes).
- Capturas do verificador (`C:\Users\deivi\AppData\Local\Temp\fcqa_audit\`): `f6d_balao_melhoria.png`, `f6d_balao_cantos.png`, `f6d_balao_mapa.png`, `f6d_balao_hall.png`, `f6d_balao_loja*.png`. O balão fica ao lado do botão apontado e não o cobre.
- Efeito colateral aceitável: o balão cobre cartões vizinhos (ex.: o botão do Tio Aposentado em `f6d_balao_cantos.png`; no hall, o texto do item de cima). Não é o item apontado.
- Some ao tirar o mouse: `_emitir({})` do `PainelLoja` chama `Dica.limpar()` (código). Não testei ao vivo o caso "balão aberto e o painel troca de aba ou fecha com o mouse parado em cima". RISCO, não bug confirmado.
- Painel esquerdo: `ui/garagem.gd` deixou de ligar `info_mudou` à caixa; `ui/painel_atributos.gd` segue usando a caixa só para a dica de cada atributo. Nada importante sumiu: a divisão do aparelho (`FOR 25% / AGI 15% / RES 60%`) continua embaixo da faixa de foco e também vai no balão (`texto_divisao`), junto com efeito e custo.

Números por atributo (`ui/sala.gd`, `ganhos_por_atributo` e `_mostrar_numeros_divididos`):
- `f6d_numeros_bjj.png`: três números na cor de cada atributo (`+120 RES` grande; `+50 FOR` e `+30 AGI` pequenos; divisão 60/25/15), empilhados e legíveis.
- Crítico (`f6d_numeros_bjj_critico.png`): `+360 RES!` vermelho e grande, frase "O TATAME GEMEU!" no topo da pilha, os outros dois pequenos.
- Aparelho de um atributo (`f6d_numeros_um_atributo.png`): continua `+1 FORÇA`, igual ao de antes.
- Máximo de 3 por clique garantido no código (`NUMEROS_MAX_POR_CLIQUE`). Nenhum bug.

### Critério 5: detalhes

- `tools/run_tests.ps1` (APPDATA em `Temp\fcqa_rt2`): `TODOS OS TESTES PASSARAM`, `EXIT=0`, guarda do save real `4/4 PASS`. (Uma 1a tentativa em segundo plano pelo bash morreu junto com o shell; refeita pelo PowerShell.)
- `tests/test_golpes.gd` sozinho, 10 execuções seguidas (APPDATA temporário): **0 falhas em 10**. Não reproduzi a falha intermitente do programador; fica registrada como suspeita de teste instável, sem bloquear.
- `ui_audit --estados todos`: `ESTADOS 370 | PROBLEMAS 0` (inclui os 12 estados novos `f6d_*`). Avisos de console esperados (`_avisar` do `_validar_discipulo` ao carregar saves de teste), nenhum erro de script.
- Foto: `git worktree add --detach <Temp\fcqa_wt_main> origin/main` (daa89fe), `foto.gd` rodada nos dois lados, `cmp foto_main.txt foto_6d.txt` sem diferença. Worktree removido.
- Arquivo novo de teste meu: `tests/qa_r1_dica.gd` (fuzz do posicionamento do balão).

### Veredito

A parte 1 da 6d **ainda não está pronta para o Diretor**: itens 2 e 3 e o critério 5 passam; o C1 melhorou muito, mas sobrou o R1 (MÉDIA, UI/UX ou Programador: o `duck_under` da primeira sucessão ainda sai com o visual padrão), que precisa de novo reteste. R2 (BAIXA, Diretor de Cutscenes) pode ir junto ou depois.
