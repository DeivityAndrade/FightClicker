# Fase 8a2: Alunos da Raízes (entradas para o manifest)

Artista de Personagens, pela skill `padrao-personagem`. Quem grava no `assets/sprites/manifest.json` é o
`python tools/art/manifest_8a2_personagens.py` (idempotente; `--check` só mostra; aceita outro caminho para testar numa cópia).
Ele lê `tools/art/fase8a2_personagens.json`: 4 entradas de `sprites` (`student_1`..`student_4`) e `by_data_id.center_students.people`
(+ `_nota_personagens`). As outras chaves de `by_data_id.center_students` (ícone etc.) não são tocadas. Nenhum arquivo antigo foi
sobrescrito. Folha de conferência: `docs/arte/mockups/fase8a2_alunos.png`.

## Contrato (igual à equipe de hoje: vizinhos, tios, Prof. Nelson)
- Quadro **48x72**, **4 quadros**, pivô **(22,67)**, `loop: true`, mesmo rig (`personagem_lib.gd`, vista 3/4) e a mesma altura da
  equipe: cabeça 13 px, ~57 px dos pés ao topo. Corpo dentro do normal (ombro 0,90–1,00, quadril 0,93–1,00, braços finos de gente
  comum). A personalidade vem do rosto, do cabelo, da pele, do calção e do exercício.
- A sala desenha como os outros geradores: pessoa i aparece se `GameState.pessoas_desenhadas('center_students') > i`
  (`draw_thresholds` 1, 5, 12, 25 em `data/center.json`), com `floor_shadow` nos pés, ordenada por y.
- Camisa **preta** da escola (rampa d1/d2/g0) com o **R de raiz** no peito (o 5x5 aprovado na 6d3) em **tinta amarela** y1
  (regra da 6c2: carimbo azul só em peça branca/amarela). O R já vem pintado na folha (não é camada nem cor-chave). Nas folhas
  viradas para a esquerda o R é desvirado no lugar (regra da 6d3): lê "R" nos dois sentidos.
- Luz pintada: pernas 1 tom abaixo (luz de cima), igual em todos os quadros e **sem depender do ponto**: o Diretor de Arte pode
  mover os alunos sem gerar de novo.

## Quem é quem
| id | aparece com | Pessoa | Ciclo (4 quadros) | fps | facing | pos (proposta) |
|---|---|---|---|---|---|---|
| `student_1` | 1 | homem, pele média, degradê; camiseta; calção cinza; tênis branco | **sombra**: guarda, jab com o corpo, pêndulo (afunda e sai da linha), direto girando o quadril | 7 | direita | 150,258 |
| `student_2` | 5 | mulher, pele clara, rabo de cavalo castanho com elástico rosa; regata; calção azul-marinho | **pula corda**: pousa (corda por cima), sobe (corda na frente), no alto (corda sob o pé), desce (corda atrás); cotovelos colados, punhos girando | 8 | esquerda | 232,254 |
| `student_3` | 12 | homem, pele escura, raspado; camiseta; calção preto; tênis vermelho | **corrida no lugar, joelho alto**: joelho esquerdo em cima, troca, joelho direito, troca; braços a 90 graus alternando | 8 | esquerda | 438,254 |
| `student_4` | 25 | mulher, pele escura, coque afro alto com elástico amarelo; regata; calção de Muay Thai vinho com cós branco | **joelhada**: guarda, agarra a nuca imaginária, puxa e sobe o joelho na ponta do pé de apoio, volta à guarda | 6 | direita | 500,260 |

`pos` é proposta (ao fundo, longe do alvo central e dos pontos da equipe antiga, conferida sobre o fundo da academia porque o fundo do
centro ainda não existe). O Diretor de Arte confirma no layout do centro; se mudar, basta trocar `pos` no
`tools/art/fase8a2_personagens.json` (ou no gerador, `POS`) e rodar o registro de novo.

## Como foi gerado (dá para rodar de novo)
Numa pasta temporária com `project.godot` vazio (nunca no projeto), APPDATA temporário, `--headless --max-fps 30`:
```
godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_sprites_fase8a2.gd -- <repo> <tmp>/out <tmp>/mock.png
```
Depois copiar `<tmp>/out/characters/student_*_idle.png` para `assets/sprites/characters/`, `<tmp>/out/fase8a2_personagens.json`
para `tools/art/` e `<tmp>/mock.png` para `docs/arte/mockups/fase8a2_alunos.png`; por fim `python tools/art/manifest_8a2_personagens.py`.
Os `.png.import` saem na primeira importação do editor.

## Fica de fora / pede pixel artist
- **Calção com a marca `sponsor_vale`** (pedido do design para o Artista, "a primeira peça a cortar"): não feito nesta entrega.
- Corrida no lugar: o braço que vai à frente fica quase todo atrás do tronco em 3/4 (lê pelas pernas; um artista desenharia o
  ombro girando). Joelhada: no quadro do golpe os braços cobrem o R (5 px de 16).
- Abdominal (sugestão do pedido) não entrou: deitado no chão não cabe no rig 3/4 em pé de 48x72 sem mudar a proporção.
