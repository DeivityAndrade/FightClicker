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
