# Personagens — diagnóstico e proposta de correção

Autor: Artista de Personagens e Animador. Pedido do dono: os personagens parecem "pouco humanos", o encaixe das partes não convence e há partes "contraditórias" na animação.
Padrão usado como régua: `.claude/skills/padrao-personagem/SKILL.md`.

Material analisado (ampliado quadro a quadro): `assets/sprites/characters/fighter_idle.png` e `fighter_punch.png`, `assets/sprites/fight/fight_player_{idle,jab,heavy,ko}.png`, `assets/sprites/opponents/opp_strong/*` e `opp_fast/*`, as folhas `docs/arte/mockups/fase2_sprites_x3.png`, `fase3_sprites_x3.png` e `fase3_luta_x2.png`. Geradores: `tools/art/pixel_lib.gd` (`character()`, `_leg`, `_arm`, `_head`, `_shoe`, `capsule`), `make_sprites_fase2.gd` (`make_fighter`) e `make_sprites_fase3.gd` (`rig`, `poses_for`, `draw_glove`, `taper`, `seg_box`).

---

## 1. Resumo em uma frase

O corpo é montado com **peças geométricas** (retângulos e cápsulas), **cada uma com contorno preto próprio**, posicionadas por **pontos soltos em cada quadro**. Por isso as peças parecem coladas (contorno atravessando o corpo), os membros mudam de tamanho entre os quadros, e a luva, a cabeça e os pés nunca mudam de orientação, mesmo quando o braço ou o corpo mudam.

---

## 2. O que deixa o personagem pouco humano

| Item | O que se vê | Causa no gerador |
|---|---|---|
| **Proporção (garagem)** | Cabeça com ~16 px num corpo de 64 (1/4, cabeção). As pernas (do gancho à sola) têm só ~18 px, **28% da altura**; numa pessoa são ~45–50%. O calção vai até o joelho, então sobra uma "canelinha" de 6 px. | `pixel_lib.POSE_GUARD`: quadril y 49, joelho 57, pé 63. O tronco + calção ocupa y 22–49. |
| **Proporção (luta) diferente da garagem** | Na luta as pernas têm 48% da altura e a cabeça 1/6. O mesmo lutador tem um corpo na garagem e outro na luta. | Dois rigs que não conversam: `character()` (Fase 2) e `rig()` (Fase 3). |
| **Mistura de vistas na garagem** | O tronco é de frente (ombros simétricos, regata retangular), mas a cabeça é de **perfil** (nariz para a direita, um olho na borda, orelha no meio) e os dois tênis são de perfil, lado a lado e idênticos. Parece um boneco montado com peças de vistas diferentes. | `_head()` desenha perfil, `_shoe()` desenha perfil, o tronco é `R()` de frente. |
| **Cabeça** | Caixa de cantos arredondados (`rrect`) com uma "touca" de cabelo. O queixo é reto, não tem mandíbula, a nuca não existe, o nariz é 1 px. | `head_img()` (Fase 3) e `_head()` (Fase 2) fazem a cabeça com retângulos. |
| **Rosto** | Olho = 1x2 px preto, boca = 2 px. A cabeça quase não tem leitura de crânio, por isso o rosto parece colado. | Idem. |
| **Tronco** | Na luta é um tubo estreito (`cw` 12 x `ww` 10): o peito é quase da largura da cintura e as costas são retas. Na garagem é um retângulo 14x18 com uma barra de "ombros" de pele por cima (`R(tx-2, ty, 18, 4)`). Não tem peito, cintura nem omoplata. | `taper(hip, chest, ww, cw)` e `seg_box` (Fase 3). Na Fase 2, `R(L, tx-2, ty, 18, 4, skin)` + `R(L, tx, ty, 14, 18, shirt)`. |
| **Mãos/braços** | Os braços são cápsulas de largura constante (4–5 px), sem deltoide nem antebraço afinando no punho. O braço de trás estendido no golpe forte vira um palito de 3 px. | `capsule(sh, el, ua)`, `capsule(el, hand, fa)`. |
| **Pés** | O tênis é um retângulo 10x4 fixo, que não acompanha a perna. No K.O. ele vira um "bico para cima" 4x9. O pé de trás nunca levanta o calcanhar. | `shoe()` / `_shoe()`. |
| **Sombreamento** | Cada cápsula pega sombra de um lado e luz do outro conforme a direção do próprio segmento (`n.x - n.y`). Quando o braço gira, a luz "pula" de lado. O tronco não tem volume de peito. | `capsule()` em `pixel_lib.gd`, ~linhas 679–701. |

## 3. Encaixes que falham e por quê

1. **Contorno preto em cada peça.** Todas as camadas passam por `L.stamp(out, layer)`, que faz `outlined()`: braço, perna, cabeça e tronco ganham um contorno ink completo, e esse contorno aparece **dentro** do corpo — no ombro (risco atravessando a regata), no quadril (linha separando a coxa do calção), no joelho (o "calombo" do calção) e embaixo do queixo. É o efeito de boneco recortado.
   - Arquivos: `pixel_lib.character()` (todas as chamadas `stamp`), `make_sprites_fase3.rig()` (todas as chamadas `L.stamp`).
   - **Conflito de regra:** `direcao-visual.md §5` manda "contorno ink em cada parte do personagem". O `padrao-personagem §3` manda o contrário (sombra entre partes, contorno só na silhueta). Hoje vale a regra antiga; é a causa número 1 do que o dono reclamou.
2. **Pele aparecendo no gancho (todas as lutas, todos os lutadores).** O tronco de pele (`taper(hip, chest, ww, …)`) termina com uma ponta redonda de raio `ww/2` (5 px no jogador, 7,5 no Brutão) abaixo do quadril, mas o calção (`seg_box(hip - axis*3, …)`) só cobre 3 px abaixo do quadril. Sobram 2–4 px de pele entre as pernas. Dá para ver em `fight_player_jab` (todos os quadros) e é bem visível em `opp_strong_idle` (a mancha marrom entre as pernas da calça).
3. **Luva de trás flutuando.** O braço de trás é desenhado **antes** do tronco (fica escondido), mas a luva de trás é desenhada **depois** da cabeça (`rig()`, "luva de trás na frente da cabeça"). Resultado: a luva aparece sem antebraço, solta na frente do rosto. Exemplos: `fight_player_jab` quadros 1–2, `opp_fast_jab` 1–2, `fight_player_heavy` 2–3 (aí é a luva da frente que flutua junto ao rosto).
4. **Ombro.** Não existe ombro: o braço nasce de um ponto na borda do tronco, com o próprio contorno. No jab esticado, o braço sai do meio do peito como um cano.
5. **Joelho e cotovelo.** Duas cápsulas com contorno próprio se cruzam. O contorno da de baixo atravessa a de cima (em `_leg`, a cápsula do calção até 55% da coxa faz um semicírculo preto no meio da perna).
6. **Pescoço/cabeça.** A cabeça é uma imagem 28x28 carimbada com contorno sobre um pescoço-cápsula. Sem mandíbula, o queixo vira uma linha reta preta em cima do pescoço.

## 4. Partes "contraditórias" na animação

| Animação (arquivo, quadro) | Contradição | Causa |
|---|---|---|
| `fight_player_jab` 0→3 | **O braço muda de tamanho:** braço (ombro→cotovelo) 9,8 / 11,1 / 9,1 / 11,2 px; antebraço (cotovelo→mão) 12,1 / 10,1 / 8,5 / 12,2 px. Até 30% de diferença de um quadro para o outro. | `poses_for("jab")` define ombro, cotovelo e mão como pontos independentes em cada quadro; nada amarra os comprimentos. |
| `fighter_punch` (garagem) 0→2 | O antebraço tem **16 px** na guarda e **5 px** no contato, e a luva continua do mesmo tamanho e de frente. Parece que o braço encolheu. | `make_fighter()`: `felb (31,31) → fhand (32,15)` vs `felb (36,22) → fhand (41,20)`. |
| Todas as lutas, todos os golpes | **A luva nunca gira:** é sempre o mesmo retângulo "em pé", com o punho embaixo, mesmo com o braço na horizontal (jab, golpe forte) ou com o corpo deitado (K.O.: a cabeça gira 90°, as luvas não). | `draw_glove()` sempre desenha a mesma luva; no K.O. só `head_img` recebe `rotate_90`. |
| `fight_player_jab` 1→3 | **O pé da frente desliza:** `ff` x 9 → 12 → 11 → 10 sem passo, 1 px por quadro a 14 fps. | `poses_for("jab")`, chave `"ff"`. |
| `fight_player_jab`, `heavy` | **O tronco não gira:** só translada (`ux`). O ombro da frente não vem para a frente, o calcanhar de trás não levanta, o queixo não se protege. O soco sai "só do braço". | `pz(over, ux, uy)` só soma um deslocamento a todos os pontos de cima. |
| `fight_player_ko` 2 | Queda **rígida**, de prancha: o corpo inteiro inclinado em linha reta, com as luvas em pé no ar. | Pontos interpolados; `rot` só na cabeça. |
| `fighter_idle` / `fight_player_idle` | Respiração ok (1 px), mas tronco, cabeça e luvas sobem em bloco; os joelhos não participam. | `dy` aplicado em bloco. |
| Garagem x luta | Mesmo personagem com proporções diferentes (ver §2). | Dois rigs. |

## 5. Abordagem de correção (testada no protótipo)

Protótipo: `tools/art/proto_personagem.gd` (novo; não altera `pixel_lib.gd` nem os geradores atuais).

1. **Tela única com mapa de partes, nada de contorno por peça.** Todas as partes são pintadas numa só imagem, que guarda também "qual parte ocupa cada pixel" (a ordem de desenho é a profundidade). No fim:
   - **sombra de contato:** quando uma parte da frente encosta numa de trás, o pixel de trás escurece 1 tom (2 tons se for o mesmo material, por exemplo pele sobre pele);
   - **juntas ligadas sem sombra:** num raio de 3–5 px do ombro, cotovelo, quadril e joelho essa sombra não é aplicada, então as peças se fundem;
   - **contorno ink de 1 px só na silhueta externa.**
2. **Comprimentos fixos + IK de 2 ossos.** Braço 12 + antebraço 12,5 (até o centro da luva), coxa 17,5 e canela 16,5 na luta. O cotovelo e o joelho são calculados a partir do ombro/quadril e da mão/pé. As **mãos continuam exatamente nos pontos do manifest**, mas o membro não estica nem encolhe. Na garagem (vista 3/4, com profundidade) os cotovelos são **poses-chave autorais**: o braço que vai para dentro da cena é escorçado de propósito e a luva troca de orientação para justificar isso.
3. **Pé ancorado pela ponta.** O tênis é posicionado pela ponta do pé no chão; o calcanhar de trás levanta no contato (mapa "na ponta do pé") sem a ponta sair do lugar (ver as marcas amarelas na tira do jab).
4. **Mapas de pixels desenhados à mão (dados) para o que primitiva não resolve:** cabeça de perfil 14x14 (luta) e cabeça 3/4 13x13 (garagem), com crânio, nuca, mandíbula, orelha, sobrancelha, olho, nariz e queixo; luva em **3 orientações** (para cima / diagonal / de lado), escolhida por quadro; tênis de perfil e 3/4, apoiado ou na ponta. A luva continua usando só r0/r1/r2 + punho e fita da luva velha, então a troca de paleta segue valendo.
5. **Tronco por fatias** (costas e frente ao longo do eixo quadril→peito): quadril, cintura, peito, trapézio, regata com decote/cava, cós e calção. O parâmetro `tw` gira o tronco no golpe: o ombro da frente avança e o peito fica mais largo.
6. **Membros com volume:** deltoide, antebraço afinando no punho, coxa com quadríceps, panturrilha atrás da canela, tornozelo fino. O calção é a parte de cima da coxa (mesma peça), então não há emenda no quadril.
7. **Uma luz só:** de cima e da frente do lutador (o refletor fica entre os dois). Os mapas já vêm pintados com essa luz.

### O que fica para um pixel artist humano
- Retoque à mão de cada quadro-chave depois do gerador (limpar "degraus" de 1 px, ajustar a silhueta do peito e da regata, que ainda lê como um bloco branco).
- Expressões (dor, cansaço, grito, K.O.) e os rostos dos adversários.
- Poses extremas: K.O., queda com os joelhos cedendo, golpe forte com o corpo inteiro, vitória. Ali o IK ajuda, mas a pose boa é desenho.
- A vista 3/4 da garagem: escorço do braço que vai para o saco e as mãos/luvas vistas de frente.
- Adversários com silhueta própria (barriga, ombrão), feitos com o mesmo sistema mas com mapas próprios.

## 6. Regras que proponho acrescentar ao padrão-personagem (não editei a skill)
1. **Contorno só na silhueta externa** (resolver o conflito com `direcao-visual.md §5`, que hoje manda contorno em cada parte).
2. **Comprimento dos membros constante:** registrar braço, antebraço, coxa e canela por personagem e conferir (o gerador avisa quando um alvo de mão está fora do alcance).
3. **Uma vista por personagem e por cena:** cabeça, tronco e pés na mesma vista (perfil na luta, 3/4 na garagem). Nada de cabeça de perfil em tronco de frente.
4. **A mesma proporção em todas as cenas** (garagem e luta): ~5,5–6 cabeças, pernas ~45–50% da altura.
5. **Luva com orientação por quadro** (para cima / diagonal / de lado / deitada), acompanhando o antebraço. No K.O., as luvas giram com o corpo.
6. **Pé ancorado:** o pixel da ponta do pé de apoio não se move durante um golpe, a menos que haja um passo desenhado de propósito.
7. **Mão de trás sempre ligada ao braço:** se o antebraço some atrás do corpo, a luva precisa ficar parcialmente atrás da cabeça ou do tronco (nunca solta na frente).
8. **Checagem do gancho/quadril:** nenhum pixel de pele entre o calção e as coxas.

## 7. Imagens
- Antes x depois (3x e 1x): `docs/arte/mockups/personagem_antes_depois_x3.png`
- Na arena contra o Brutão (2x): `docs/arte/mockups/personagem_na_arena_x2.png`
- Tira do jab (3x, fundo da arena): `docs/arte/mockups/personagem_jab_tira_x3.png`
- PNGs do protótipo (mesmo formato do jogo): `docs/arte/prototipo/fight_player_idle.png`, `fight_player_jab.png`, `fighter_punch.png` + `prototipo.json` (mãos por quadro).
