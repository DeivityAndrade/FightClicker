# Direção visual — Fightclicker

Dono: Diretor de Arte. Versão 1 (2026-11-05). Base: `PROMPT.md`, `docs/visao.md` (decisões do dono de 2026-11-05).
Mockups desta versão: `docs/arte/mockups/garagem_*.png` e `academia_*.png`, gerados por `tools/art/*.gd`.

> Gênero e linha visual: pixel art arcade de gestão de treino. Punch Club é referência **de gênero**.
> Arte, paleta, personagens, layout e locais são **100% nossos**. Nada copiado nem "redesenhado por cima".

---

## 1. Resolução e escala

| Item | Decisão |
|---|---|
| **Resolução base** | **640 x 360** |
| Janela padrão | 1280 x 720 (escala **2x**) |
| 1920 x 1080 | escala **3x** (inteira, sem borda) |
| 2560 x 1440 / 4K | 4x / 6x |
| Filtro | **Nearest** em tudo (`rendering/textures/canvas_textures/default_texture_filter = Nearest`) |
| Stretch | `display/window/stretch/mode = viewport`, `aspect = keep`, `scale_mode = integer` |
| Snap | `rendering/2d/snap/snap_2d_transforms_to_pixel = true` e `snap_2d_vertices_to_pixel = true` |

**Por que 640x360 e não 320x180:** um incremental vive de números, nomes de geradores e preços.
Em 320x180 cabem uns 50 caracteres por linha e a sala ficaria com uns 150 px de largura: o painel
espremeria a cena ou os textos. Em 640x360 cabem a sala, dois painéis laterais e uma barra de
botões, com fonte 5x7 legível, e o resultado continua "pixelado arcade" porque tudo é desenhado
na grade de 640x360 e ampliado por inteiro. O que dá o ar arcade é a **grade de pixel visível**, a
paleta curta e o contorno escuro, não a resolução mínima.

Regra de ouro: **nada fora da grade**. Sem rotação livre de sprites, sem escala não-inteira, sem
anti-aliasing. Animação = troca de quadros ou deslocamento em pixel inteiro.

## 2. Layout da tela principal (640x360)

```
y 0  ┌──────────────── HUD: $ dinheiro | ⚡ treino +x/s | ★ fama | nome do local ───────────────┐
y 18 ├─ PAINEL ESQ ──┬───────────────── SALA DE TREINO (384x272) ─────────────────┬─ PAINEL DIR ─┤
     │ 0..127        │ 128..511                                                    │ 512..639     │
     │ atributos     │ parede do fundo + chão em leve perspectiva                  │ EQUIPE/ITENS │
     │ legado em jogo│ centro (x=320): lutador + aparelho em foco = ALVO DO CLIQUE │ geradores    │
     │ próxima luta  │ outros aparelhos e gente treinando em volta                 │ melhorias    │
     │ (prévia ELE x │                                                             │ próximo local│
     │  VOCÊ, risco) │                                                             │              │
y 290├───────────────┴─────────────────────────────────────────────────────────────┴──────────────┤
     │ por clique / auto  │  [FOCO 1] [FOCO 2] [FOCO 3] ([FOCO 4 = arte])  │  [ LUTAR! ] [APOSENTAR]│
y 360└──────────────────────────────────────────────────────────────────────────────────────────┘
```

- **O alvo central fica sempre no mesmo ponto da tela** (aparelho em foco em x≈336, y≈190–250;
  lutador ao lado). Trocar o foco troca o aparelho que está no centro, não o lugar do clique (visão).
- Os painéis **nunca** cobrem a sala. Popups (prévia de luta, fim de carreira, mudança de local)
  abrem como janela central por cima, escurecendo a sala com dither 50% de `ink`.
- Números flutuantes saem do ponto clicado e sobem ~24 px em 0,6 s. Normal: `y1` com contorno
  `ink`, fonte 1x. Crítico/bônus: `r3`, fonte **2x**, com "!".
- Cursor do mouse = **a luva equipada** (sprite 10x10 com contorno claro), a mesma que aparece nas
  mãos do lutador.
- Botões: chanfro de 1 px (claro em cima, escuro embaixo), contorno `ink`, sombra de 1 px. Botão
  selecionado/ativo tem a cor do atributo e um sublinhado. Preço que não dá para pagar fica `r2`.
- Cores fixas de atributo em toda a UI: **Força = vermelho (`r1/r2/r3`)**, **Agilidade = azul
  (`b1/b2/b3`)**, **Resistência = amarelo (`y0/y1`)**, **arte marcial = roxo (`p1/p2`)**,
  treino/renda = verde (`gr2/gr3`), dinheiro = amarelo-ouro (`y1`), Legado = roxo (`p2`).
  **Fase 5.1:** tokens de cor e de tamanho no §18 (Fama vira rosa `f2`, Resistência fica só em `y0`, preço sem saldo deixa de ser `r2`).

## 3. Paleta (45 cores, fechada)

Toda cor do jogo sai desta tabela. Sombra e luz **andam na rampa** (nunca escurecer com
multiplicação livre). A UI usa a mesma paleta. Fonte da verdade em código: `tools/art/pixel_lib.gd`
(`PAL_HEX` e `RAMPS`).

| Rampa | Cores (escuro → claro) | Uso |
|---|---|---|
| Neutro | `ink #14101a` · `d1 #2a2233` · `d2 #3d3346` · `g0 #4a4552` · `g1 #6b6570` · `g2 #8f8890` · `g3 #b8b0aa` · `cream #d9cdb4` · `white #f2ece0` | contorno, painéis, concreto, texto |
| Madeira/couro | `br0 #3b2622` · `br1 #6b3f2a` · `br2 #9a5f36` · `br3 #c98a4b` → `y0` `y1` `y2` | viga, prateleira, madeira, ferrugem |
| Luz quente | `y0 #e0a040` · `y1 #f5d26b` · `y2 #fff3c4` | lâmpada, dinheiro, número do clique |
| Vermelho | `r0 #5a1a22` · `r1 #9c2a2a` · `r2 #d4473a` · `r3 #f07a5a` | luva, saco, Força, crítico, perigo |
| Pele | `sk0 #7a4632` · `sk1 #b9744f` · `sk2 #e3a275` | personagens (mais tons de pele entram como rampas extras) |
| Pele extra (6b1, só troca de paleta do discípulo) | `skin_1` #a8684e/#e0a888/#f4d0b4 · `skin_2` #8f5238/#cc8c62/#eebd94 · `skin_4` #5a3029/#8c5545/#b8806a · `skin_5` #422529/#73453f/#a06a5a | `[sombra, base, luz]`; `skin_3` = sk0/sk1/sk2. Conferência em `paletas-6b1.md` e §23.3 |
| Azul | `b0 #1f2a44` · `b1 #2f4a78` · `b2 #4d7bb3` · `b3 #8fbbe0` | calção, ringue, céu, Agilidade |
| Verde | `gr0 #1f3d33` · `gr1 #2f6b4a` · `gr2 #5aa25a` · `gr3 #a6d86a` | barrado da academia, treino/s, "fácil" |
| Aço | `st0 #3a4452` · `st1 #5a6676` · `st2 #7f8c9a` · `st3 #a9b4bf` | porta de garagem, esteira, metal |
| Roxo | `p0 #4a2f6b` · `p1 #7a4fa0` · `p2 #b07ad8` | Legado, arte marcial, (locais absurdos) |
| Rosa (só UI, Fase 5.1) | `f0 #7a2a52` · `f1 #d4558f` · `f2 #f59ac0` | Fama. Não usar em cenário nem em personagem (§18) |

- Fundo de tela e contorno: sempre `ink` (preto arroxeado, nunca #000).
- Locais 5 e 6 (templo, dojo fora da realidade) podem ganhar **uma** rampa nova cada (ex.: dourado
  de templo, ciano "irreal"). Fora isso, a paleta não cresce.

## 4. Perspectiva da sala

**Vista frontal de "caixa de diorama"**: parede do fundo reta e de frente, duas paredes laterais
estreitas em perspectiva e chão em trapézio. **Sem teto visível** (uma viga atravessa o alto da
parede e segura saco, lâmpada e corda). É a leitura mais clara para clicar e a mais barata de
animar: sprites são desenhados de frente / 3/4, sem precisar de versões isométricas.

Geometria fixa (em pixels da base), igual em todos os locais:

| Elemento | Valor |
|---|---|
| Área da sala | x 128..511, y 18..289 (384x272) |
| Ponto de fuga | (320, −28) |
| Parede do fundo | x 170..470, do topo até y 220 (escala 0,78 da moldura) |
| Chão | trapézio de y 220 (x 170..470) a y 289 (x 128..511), ~70 px de profundidade |
| Linha de piso a y | largura = 384·(y+28)/317, centrada em x 320 |
| Viga | y 24..31 |
| "Pés" de quem está no centro | y ≈ 272 |

Profundidade por **ordem de desenho** (quem tem os pés mais embaixo desenha por cima), não por
escala: todo personagem tem o mesmo tamanho em qualquer ponto do chão. Sombra no chão: elipse
achatada (`ink` ou um tom abaixo do piso) com dither nas bordas.

## 5. Regras de desenho

- **Contorno de 1 px `ink`** em todo objeto. **Personagens (revisado em 2026-11-05):** contorno só na
  **silhueta externa**; entre partes do mesmo corpo use sombra de contato, nunca contorno por parte
  (isso deixava riscos pretos no ombro, quadril e joelho). Vale a skill `padrao-personagem`
  (`.claude/skills/padrao-personagem/`), que prevalece sobre esta seção para gente.
- **2 a 3 tons por material** + 1 brilho pontual: base, sombra (rampa −1), luz (rampa +1).
- Luz principal de cada local definida (garagem: lâmpada no alto, ao centro; academia: tubos frios).
  Sombra do lado oposto à luz; a cena recebe um passo de luz em faixas com **dither ordenado 4x4
  (Bayer)** só nas bordas das faixas. A UI nunca recebe luz.
- Dither: só para luz, sombra no chão, umidade, tecido/lona. Nunca em texto.
- Nada de gradiente suave nem cor fora da paleta.

## 6. Tamanhos padrão

| Coisa | Tamanho (px da base) | Observação |
|---|---|---|
| Lutador / pessoas | **~64 de altura**, quadro **44x72** | pés na linha 67 do quadro; ~5,5 cabeças |
| Luva equipada | 10x11 na mão, 10x10 no cursor | mesma arte, mesmo item |
| Aparelho central (saco) | **30x62** + corrente | alvo de clique; área clicável sugerida 48x90 |
| Saco longo (Muay Thai) | 22x112 | |
| Esteira | 86x42 (vista de lado) | |
| Corda de pular | ~16x40 pendurada; ~44x64 em uso (quadros do lutador) | |
| Aparelho de arte no chão (boneco, tatame) | até 64x40 | |
| Ícones de UI | 9x9 (HUD), 16x16 (loja) | |
| Grade de piso/parede | blocos 20x10 (garagem), placas no chão em 10 colunas | |

Um sprite por arquivo PNG, cada um com o quadro do tamanho padrão e o ponto de apoio (pés / gancho)
na mesma coordenada, para trocar a arte depois sem mexer em cena.

## 7. Fonte pixel

- **Padrão do projeto: fonte bitmap própria 5x7** (maiúsculas, números, pontuação e acentos do
  português: Ç Ã Á Â É Ê Í Ó Ô Õ Ú). Já existe desenhada em `tools/art/pixel_lib.gd` (`GLYPHS`) e é
  a dos mockups. É 100% nossa, sem licença para checar, e encaixa na grade de 640x360. **Fase 2:**
  exportada como BMFont (`assets/sprites/font/fightclicker_5x7.fnt` + `_contorno.fnt`), com minúsculas; Godot carrega direto (`font_size = 11`; 22 = 2x).
- **Alternativas livres (SIL OFL 1.1), sem baixar agora:**
  - *Press Start 2P* (CodeMan38) — 8x8, bem arcade, para títulos e números grandes ("LUTAR!", "K.O.").
    Conferir se tem todos os acentos do português antes de adotar.
  - *Silkscreen* (Jason Kottke) — pequena e limpa para rótulos.
  - *Pixelify Sans* — tem acentos e minúsculas, boa para textos longos (diálogos do mentor).
- Tamanhos: texto 1x (7 px de altura), destaque 2x (14 px). Sempre com sombra de 1 px `ink` ou
  contorno `ink` quando estiver sobre a cena.

## 8. Evolução dos locais

A sala é **sempre a mesma caixa** (mesma geometria, mesmo ponto do alvo central). O que muda é o
"material" da caixa, a luz, os aparelhos e quantas pessoas treinam. Isso deixa cada local barato
(um conjunto de peças trocáveis) e a mudança muito visível.

| # | Local | Paredes | Chão | Luz | Aparelhos (versão) | Gente / detalhes |
|---|---|---|---|---|---|---|
| 1 | **Fundo de garagem** | blocos de concreto cinza, umidade na base, viga de madeira | concreto manchado de óleo, juntas | **uma lâmpada pendurada**, quente e fraca, cantos escuros; luz do dia vazando sob a porta | saco remendado com fita, corda de varal, esteira enferrujada | carro coberto com lona, prateleira de latas, pôster rasgado, **foto do mentor anterior** |
| 2 | **Academia de bairro** | pintura creme + barrado verde, tinta descascada, rachadura | placas de borracha | **tubos fluorescentes** frios, luz uniforme; janela alta com grade | saco de couro, corda com cabos, esteira que funciona, **aparelho da arte** | ringue pequeno, espelho, relógio, pôsteres desbotados, banco; treinador e parceiros |
| 3 | **Centro de treinamento** | galpão: chapa metálica, faixas de patrocinador | tatame/emborrachado com faixas pintadas | refletores industriais, mais claro | aparelhos de marca, pera e saco duplos | logos, alunos em fila, quadro de horários |
| 4 | **Complexo de elite** | painéis escuros com LED, vidro | piso polido com reflexo (dither) | holofotes de palco, contraluz colorido | aparelhos "high-tech" caricatos | equipe enorme, câmeras, troféus |
| 5 | **Templo na montanha** | madeira e pedra, portas de correr, montanha ao fundo | tábuas antigas | luz de lanternas e pôr do sol | saco de couro antigo amarrado em corda, tronco de madeira | monges, **um urso parceiro de treino** |
| 6 | **Dojo no fim da realidade** | sala flutuando no vazio, paredes rachando em pixels | tatame que se desfaz nas bordas | luz sem fonte, roxo/ciano | aparelhos absurdos (meteoro acorrentado, corda que deixa rastro, esteira que gira o chão) | estrelas, fragmentos flutuando |

Entre mudanças, dentro do mesmo local, a sala evolui aos poucos: cada upgrade de aparelho troca o
sprite (saco remendado → saco novo → saco de couro), e cada gerador comprado coloca mais gente em
pontos fixos da sala (até um limite de desenho; o número continua subindo).

## 9. Aparelhos por arte e por atributo

Segue a tabela do Diretor de Jogo em `docs/visao.md`. Básicos (todo local) e um aparelho por arte:

| Aparelho | Atributo / arte | Garagem | Academia de bairro | Centro de treinamento | Fim absurdo |
|---|---|---|---|---|---|
| Saco de pancada | Força | saco remendado com fita, corrente | saco de couro com faixa | saco de marca + mola | meteoro acorrentado |
| Corda de pular | Agilidade | corda de varal num prego, marcas de giz | corda com cabos, num gancho | corda de aço com rolamento | corda que deixa rastro de luz |
| Esteira | Resistência | esteira enferrujada, visor apagado | esteira branca, visor verde aceso | esteira de alto rendimento | esteira que gira o chão |
| Pera (saco de velocidade) | **Boxe** | — (arte só a partir da academia) | plataforma de madeira com pera vermelha | pera dupla, plataforma metálica | — |
| Saco longo | **Muay Thai** | — | saco longo preto com faixas vermelhas | saco longo + aparador de chute | — |
| Boneco de grappling no tatame | **Jiu-jitsu** | — | boneco de lona num tatame azul | tatame grande, boneco de couro | — |
| Boneco de arremesso | **Judô/Wrestling** | — | boneco de lona de pé, com pegada | boneco de couro + colchão de queda | — |

Estilo por arte (para os aparelhos e detalhes da sala quando a arte é escolhida):
- **Boxe:** vermelho e madeira, couro, cordas de ringue. Formas redondas.
- **Muay Thai:** preto com faixas vermelhas/douradas, bandagens, formas longas e verticais.
- **Jiu-jitsu:** azul de tatame e lona branca, formas baixas, no chão.
- **Judô/Wrestling:** branco/cru e azul-escuro, lona grossa, formas largas e pesadas.

## 10. Animações mínimas

Toda animação em quadros de pixel inteiro, 8–12 fps (a UI pode ser mais rápida). O lutador é
articulado em partes separadas (cabeça, tronco, braços, pernas, luvas), como já está nos mockups.

| Aparelho / ação | Repouso | No clique / em uso | Quadros |
|---|---|---|---|
| Saco de pancada | balanço leve (±1 px, 1,5 s) | empurra 3–4 px para longe do golpe, volta em 3 quadros com 1 px de sobra; corrente acompanha | 4 |
| Corda de pular | parada no prego | lutador pula: corda faz arco em cima → frente → embaixo (pés sobem 3 px) | 4 |
| Esteira | parada | faixas da lona correm 2 px por quadro, rolos giram, visor pisca | 2–4 (loop) |
| Pera | parada | vai e volta rápido (3 posições) | 3 |
| Saco longo | parado | balanço lateral maior, mais lento que o saco | 4 |
| Boneco de grappling | deitado | lutador por cima, boneco amassa 2 px | 3 |
| Boneco de arremesso | de pé | inclina e volta (sem rotação livre: quadros desenhados) | 4 |
| Lutador parado | respiração (tronco/cabeça ±1 px) | — | 2 |
| Lutador golpe | — | antecipação → golpe (braço da frente estica) → volta | 3 |
| Lâmpada (garagem) | pisca 1 quadro a cada ~8 s; balança quando o saco é atingido forte | — | 2 |
| Tubos (academia) | um tubo falha de vez em quando | — | 2 |
| Número do clique | sobe e some (troca para tom mais escuro no fim) | crítico: escala 2x e tremida de 1 px | — |
| Impacto | 3 a 5 traços brancos no ponto do golpe, 2 quadros | tela treme 1–2 px (só pixel inteiro) | 2 |

## 11. O que é placeholder e o que precisa de artista humano

- **Tudo nos mockups é placeholder gerado por código** (formas, retângulos, elipses e luz
  calculada). Serve para fixar resolução, paleta, layout, tamanhos e clima. Não é a arte final.
- **Precisa de pixel artist humano para a versão final:** o lutador e as pessoas (anatomia, rosto,
  silhueta com personalidade, poses de cada golpe/esquiva/queda/vitória), as animações quadro a
  quadro, os aparelhos com material convincente (couro, lona, metal), o cenário de cada local com
  detalhe narrativo, o rival e o mentor, e os locais 3–6.
- O que pode ficar do código: paleta, grade de layout, a fonte 5x7 (com revisão), molduras de
  painel/botão, sombras, luz em faixas e a montagem da sala por peças.
- Poses atuais: todos usam a mesma guarda de boxe (inclusive quem corre na esteira e o treinador).
  É limitação do placeholder.

## 12. Como gerar os mockups de novo

Os scripts ficam em `tools/art/` (`pixel_lib.gd` + `make_mockup_garage.gd` + `make_mockup_academia.gd`).
Rodar a partir de uma pasta com um `project.godot` vazio (para não disparar import no projeto):

```
godot --headless --path <pasta_temporaria_com_project.godot> --quit-after 5 --script E:/Fightclicker/tools/art/make_mockup_garage.gd
godot --headless --path <pasta_temporaria_com_project.godot> --quit-after 5 --script E:/Fightclicker/tools/art/make_mockup_academia.gd
```

(`--quit-after` garante que o Godot fecha mesmo se o script der erro.) Saída: `*_base.png`
(640x360) e `*_x2.png` (1280x720, nearest) em `docs/arte/mockups/`.

## 13. Sprites da Fase 2 (garagem)

- Gerador: `tools/art/make_sprites_fase2.gd` (usa `pixel_lib.gd`, que agora tem minúsculas e o
  personagem articulado por poses `character()`). Teste da fonte: `tools/art/test_font.gd`.
- Saída: `assets/sprites/{garage,equipment,characters,fx,ui,font}/`, 1x, uma folha por animação
  (quadros lado a lado). `assets/sprites/manifest.json` traz quadro, nº de quadros, fps, pivô,
  posição na sala, 9-slice e a ponte com os ids de `data/` (`by_data_id`).
- Regra de foco: o aparelho em foco vai para o centro (saco em x 336); o saco descansa à esquerda
  (x 258), a esteira à direita (x 445), a corda no prego (352,72).
- Pessoas: pontos fixos com a luz da lâmpada já aplicada (vizinho 1/2/3, tio 1/2).
- Lutador: quadro 48x72 (a guia antiga dizia 44x72; ficou 48 para caber o soco esticado), pés na linha 67.
- Conferência: `docs/arte/mockups/fase2_sala_x2.png` (sala montada só com os sprites e as
  posições do manifest) e `fase2_sprites_x3.png` (folha de contato).

## 14. Fase 3 (lutas, fim de carreira)

Gerador: `tools/art/make_sprites_fase3.gd` (rodar como no §12; **acrescenta** ao `manifest.json`, não apaga a Fase 2).
Se rodar o `make_sprites_fase2.gd` de novo, ele reescreve o manifest só com a Fase 2: rode o da Fase 3 logo depois.
A fonte 5x7 ganhou `º` e `ª` ("2º ROUND").

**Arena (única):** estacionamento de uma borracharia à noite. Galpão de chapa ondulada, placa pintada à mão,
porta de enrolar "07", pneus e tambores, carro com farol aceso, alambrado e poste de sódio. Luz vem de um
refletor de obra pendurado num cabo em cima do "ringue" riscado a giz no asfalto; cantos quase pretos.
Público em silhueta (`arena_crowd_back` atrás, `arena_crowd_front` nos cantos de baixo), 2 quadros (parado / vibrando).
Faixa y 0..45 é céu escuro: o HUD de luta fica ali (`fight_layout` no manifest).

**Vista de luta:** de lado. Jogador à esquerda virado para a direita (pivô 296,318), adversário à direita virado
para a esquerda (346,318). Quadro **112x104 para todos**, pivô (56,98) nos pés. Mesmo rig articulado da garagem
(perna de trás, braço de trás, tronco, perna da frente, cabeça, luva de trás, braço da frente + luva), cada parte
com contorno ink próprio; tamanho do corpo por escala (Dinho 0,92 · Dudu 0,98 · jogador 1,0 · Brutão 1,08 · Muralha 1,12).
9 ações por lutador: idle, jab, heavy, hit, dodge, block, tired, victory, ko (3–5 quadros). O manifest traz
`hit_frame`, `hit_point` e a posição das duas mãos em cada quadro (`hands`), para casar efeito e número com a simulação.

**Adversários** (aparência do Roteirista, `docs/fases/fase3-textos.md`): cada um com silhueta e cor dominante própria
— Dudu Alongado (branco/verde-musgo, meião, faixa mole), Brutão do Posto (o mais largo, boné do posto, macacão azul,
luva com fita isolante vermelha), Dinho Pulga (baixo, moletom azul com capuz, bandana, tênis laranja, cadarço solto,
saltita), Seu Muralha (alto, barriga, bigode grisalho, camiseta amarela, cinturão de pano — o mesmo do ícone).

**Luvas:** velha (r0/r1/r2, fita e punho encardido), lona (bege, fita branca), couro (marrom-avermelhado, costura clara),
marca (preta, listra amarela torta). Cada luva tem: item 12x13, ícone 16x16 da loja, cursor (+ x2/x3), folhas da
garagem e da luta já pintadas (sufixo `_glove_lN`) e a arte "luvas penduradas". Regra: trocar a luva troca tudo pelo
mesmo sufixo (`by_data_id.glove_lN.sprite_suffix`). Conferência: `mockups/fase3_luvas_x3.png`.

**Cores de UI novas:** tática agressivo = vermelho (Força), defensivo = amarelo (Resistência), contra-ataque = azul
(Agilidade), usando os botões de foco já existentes como "selecionado". Risco fácil/equilibrado/perigoso = verde/amarelo/
vermelho, sempre com ícone (✓, =, caveira) além da cor. Dinheiro `y1` ($), fama `p2` (estrela), Legado `p2` (chama roxa
— a chama que passa de um lutador para o próximo). LUTAR! é vermelho (arriscar); APOSENTAR é roxo (Legado).
Fim de carreira: moldura de concreto com fita vermelha; aposentadoria: moldura roxa com cantos dourados.

**Mockups:** `fase3_luta_x2.png` (luta montada + tira de quadros-chave), `fase3_previa_x2.png` (ELE x VOCÊ sobre a
garagem escurecida), `fase3_fim_x2.png` (derrota e aposentadoria), `fase3_sprites_x3.png` (folha de contato).

**Placeholder:** tudo gerado por código. Para a versão final precisa de pixel artist: rostos e expressões (hoje são
2–3 pixels), anatomia e peso de cada adversário, poses de golpe com antecipação e follow-through de verdade (hoje os
golpes são interpolação de pontos), a queda (o quadro "caindo" é rígido), o público com gente desenhada, a arena com
mais história, e o cinturão. As luvas e a UI podem ficar com retoque.

## 15. Fase 4 (árvore de habilidades, Metrônomo, revanche)

Gerador: `tools/art/make_sprites_fase4.gd` (rodar como no §12; **acrescenta** ao `manifest.json`). Se rodar os da Fase 2/3 de novo,
rode o da Fase 4 depois. Nenhuma arte de personagem nesta fase (o auto-soco usa o rig e o jab que já existem).

**Ícones dos nós:** `skill_<id>` 16x16 em cor (cartão de início, resumo da garagem) e `skill_<id>_gray` (trancado). Na árvore, peça
24x24 por estado: `_owned` (moldura acesa na cor do ramo + ✓ verde), `_buyable` (borda verde viva, 2 quadros a 3 fps — verde = "dá
para comprar", como o preço da loja), `_missing` (ícone meio apagado + moeda roxa riscada; preço em r2/r3), `_locked` (cinza + cadeado).
Cor dos ramos: **Corpo = vermelho** (`r1/r2/r3`, efeito em r3), **Carreira = ouro** (`br2/y0/y1`, efeito em y1). Símbolos: jab = luva
com risco de velocidade; Memória muscular = metrônomo com faísca roxa; Mão pesada = punho descendo com estouro; Garagem animada/lotada =
2 / 3 bustos de camiseta verde (renda passiva); Bolsa = saco de dinheiro; Olho de treinador = olho + %; Empresário = maleta com notas;
Torcida = braços erguidos + estrela; Saber cair = chama do Legado pousada num colchonete.

**Tela da árvore:** janela `ui_tree_window` (quadro de madeira com pregos, 9-slice) + título `ui_window_title_retire` (roxo).
Duas colunas `ui_tree_column_body/career` com faixa de cabeçalho na cor do ramo. O "Y" logo abaixo do 1º nó são três peças
empilhadas no mesmo ponto (`ui_tree_fork_stem/left/right_normal|active`), e a ligação do 1º ao 2º nó de cada caminho é
`ui_tree_link_normal|active` (há ladrilhos `ui_tree_link_v/h_*` para outros tamanhos). Linha **ativa = roxo do Legado** com faísca
branca a cada 4 px; normal = cinza. Uma ligação acende quando o nó de baixo dela está comprado. Plaquinhas de preço/estado
`ui_tree_plate_buy/owned/missing/locked`. Geometria recomendada em `manifest.tree_layout` (janela 480x300 em 80,20). Nome longo em
"PEDE: {nome}" passa de 104 px: o UI/UX decide entre nome curto, 2 linhas ou "PEDE O DE CIMA".

**Metrônomo:** prop `garage/metronome_l1|l2|l3` (quadro 18x26, pivô 9,25 no pé), na prateleira da garagem em **(240,118)**, na
frente da caixa de papelão; nível 0 = sem prop. l1 = metrônomo velho de feira (madeira gasta, quina lascada, fita crepe, haste de
lata), l2 = madeira envernizada com peso de latão, l3 = laca preta com frisos dourados. 8 quadros = um vai-e-volta = 2 auto-socos;
quadros 0 e 4 são os extremos e têm o risquinho do "tic". fps = 4 / intervalo (2,0 / 4,0 / 5,7), ou sincronizar pelo acumulador
(fórmula em `by_data_id.metronome.sync`). Ícones da LOJA `icon_metronome_lN` (16x16, pontinhos = nível).

**Revanche:** marca = **esparadrapo em X** com pingo de mertiolate (`icon_revenge` 9x9, `icon_revenge_16`), sobre fita vermelha
9-slice `ui_seal_revenge` com o texto `revenge_mark` do ui_texts. `seal_revenge_mark` traz o texto padrão embutido (só usar se o
texto não mudar). Vitória: `ui_banner_revenge` ("REVANCHE!" 3x sobre estouro vermelho, 2 quadros) e `ui_banner_revenge_burst` (só o
estouro, para escrever o texto do ui_texts por cima).

**Cartão "o que você trouxe":** `ui_career_card` (roxo com cantos dourados, 9-slice), `ui_career_card_title`, `ui_career_card_row`
(ícone 16 + effect_text na cor do ramo). Resumo da garagem: `ui_legacy_nodes_badge`.

**Mockups:** `fase4_arvore_x2.png` (árvore com 3 nós comprados, 1 comprável, 3 faltando Legado e 3 trancados), `fase4_garagem_x2.png`
(garagem com Metrônomo, cartão de início, marca no bloco PRÓXIMA; prateleira ampliada nos 3 níveis, os 8 quadros do pêndulo e o
REVANCHE!), `fase4_sprites_x3.png` (folha de contato).

**Placeholder:** ícones e molduras podem ficar com retoque de um pixel artist (principalmente Mão pesada, Empresário e Saber cair, que
são os menos imediatos em 16 px). O Metrônomo precisa de artista para ter material de verdade (veio da madeira, metal da haste).

## 16. Fase 4b (aparelhos que chegam, modo assistido)

Gerador: `tools/art/make_sprites_fase4b.gd` (rodar como no §12; **acrescenta** ao `manifest.json`). Se rodar os das Fases 2/3/4 de novo,
rode o da 4b depois. Nenhuma arte de personagem.

**Aparelho que falta = fita crepe + plaquinha de papelão** (nunca caixa fechada). Fita = `cream` com borda `g3`, pontas rasgadas.
- Esteira: `garage/tape_mark_treadmill` (trapézio no chão em perspectiva, mesmo pivô e posição da `treadmill_lN_side`, 445,267) +
  `ghost_treadmill` (sombra pontilhada ink 50% com cadeado, opcional). Plaquinha em pé no fundo da marca (base em 445,257) com o
  `sign_brick` na frente.
- Corda: `garage/tape_mark_rope` na **parede**, em volta do prego (352,72), como quadro de ferramentas + `ghost_rope`. Plaquinha colada
  acima do prego, borda esquerda em x 340 (à direita da corrente do saco), com 2 `sign_tape_bit`.
- `sign_cardboard` é 9-slice; texto 1x em `br0`, sem sombra, centrado, 2 linhas (nome / preço). A fonte 5x7 não tem travessão.

**Trancado na UI:** `icon_<aparelho>_locked` (cadeado cinza) e `_locked_buyable` (dourado), 16x16, no cartão da aba TREINO (5,3) e no
botão de foco (2,9). Botão de foco trancado `ui_button_focus_locked_buyable|buyable_pulse|missing|locked` (9-slice 16x17, mesmas margens;
`_full` = 122x34 pronto). Verde = comprável, como no resto do jogo. Cartão de compra `ui_card_unlock` (borda de papelão) e `_flash` (piscada).

**Chegada:** a esteira cai (offsets y -20,-10,-3,0,1,0 a 24 fps) e no impacto some a marca, toca `fx_arrive_dust` (6 quadros, 12 fps)
e a tela treme 1 px. A corda é pendurada (-8,-3,0,1,0) com `fx_arrive_sparkle` (5 quadros, 12 fps). Detalhes em `manifest.by_data_id.unlock_*`.

**Modo assistido:** chip 9-slice `ui_assist_chip_hint|waiting|active|active_pulse|metronome` (altura 13; ícone 9x9 em 3,2, texto em 15,3) com
`icon_key_shift`, `icon_assist_wait`, `icon_assist_active`, `icon_metronome_9`. Botão `ui_button_hold_normal` (tecla de aço) e `_pressed`
(afunda 1 px, verde = assistindo). Sugestão: faixa de baixo da sala, centrada, abaixo dos pés do lutador (`manifest.by_data_id.assist`).

**Mockups:** `fase4b_garagem_x2.png` (começo de carreira + prancha dos estados) e `fase4b_sprites_x3.png` (folha de contato).
**Placeholder:** a fita, o papelão e a poeira podem ficar com retoque. Um pixel artist melhoraria a textura do papelão, a letra "à mão"
(hoje é a fonte 5x7) e a poeira (volume de verdade, não bolinhas pontilhadas).

## 17. Fase 5 (Academia Boa Esquina, Boxe e Jiu-jitsu)

Gerador: `tools/art/make_sprites_fase5.gd` (rodar como no §12; **acrescenta** ao `manifest.json` e relê o arquivo na hora de gravar,
para não apagar o que o Artista de Personagens gravou). Se rodar os das Fases 2/3/4/4b de novo, rode o da Fase 5 depois.
Nenhuma arte de personagem aqui (os 2 adversários da academia são do Artista de Personagens).

**A sala (`gym/gym_bg`, 384x272 em 128,18):** a mesma caixa da garagem, com os mesmos ganchos (336 e 258), o mesmo prego da corda (352,72),
o mesmo ponto do Metrônomo (240,118, na ponta da prateleira) e os mesmos pontos de gente. O degrau acima da garagem se lê por:
- **parede pintada** (creme em cima, barrado verde `gr1` embaixo, tinta descascando na borda, rachaduras) no lugar do bloco de concreto;
- **viga de aço** e **2 tubos frios** (`gym_tube` em 218,34 e 422,34; quadro 1 = tubo falhando) no lugar da lâmpada: luz uniforme,
  clara embaixo dos tubos, caindo só nos cantos e na frente do chão (`gym_step()` no gerador; a mesma luz vai nos sprites `_side/_wall/_rest_gym`);
- **nome pintado à mão** "ACADEMIA / BOA ESQUINA" acima do **espelho trincado** (estrela de trinca, um caco faltando e fita crepe em X);
- **pôsteres desbotados** (LUTA, SÁB), relógio, prateleira com troféu pequeno, quadro de cortiça da **mensalidade** (papel com carimbo vermelho),
  banco com toalha e mochila, relógio de round (3:00, 3 luzes), luvas penduradas, extintor, porta da rua com vidro aramado e plaquinha
  verde, janela alta com grade na parede lateral, halteres;
- **piso de borracha** em xadrez e **tatame azul gasto** no canto da frente à esquerda (com rasgo remendado).
O lugar acima da porta (x 410–462, y 44–98) fica livre de propósito: é onde a pera mora.

**Aparelhos básicos na academia:** sufixo `_gym` no nome do sprite (`bag_l1_idle` → `bag_l1_idle_gym`), mesmos quadros, pivôs, fps e pontos.
Sem `_gym` no manifest = usa o da garagem. Saco: couro marrom com tiras creme (l0) / preto com faixas vermelhas e emblema (l1).
Esteira: branca com visor verde aceso (l0) / faixa verde e chave vermelha (l1). Corda: PVC vermelho com cabos pretos (l0) / aço encapado com
cabos de madeira (l1); a `rope_lN_swing_gym` é a mesma animação recolorida.

**Pera veloz (Boxe):** silhueta oposta à do saco: **haste fina + tábua larga + gota pequena** (o saco é um cilindro gordo numa corrente).
- Foco: `speed_bag_lN_idle/hit` num pedestal em pé, pivô no chão em **(330,274)**, ordenar como y 268 (o lutador, em 303,272, fica na frente).
  A pera fica na altura do soco (y 215–226). O clique tem 5 quadros a 18 fps (vai para trás, bate, volta direita/esquerda, assenta).
- Descanso: `speed_bag_lN_wall(_gym)`, plataforma parafusada na parede acima da porta, pivô no meio de cima da tábua em **(436,46)**.
- l0 = pera remendada com fita, compensado, saco de areia no pé; l1 (Jab duplo) = couro com costura, tábua envernizada, anilha.
- Falta: `tape_mark_speed_bag` (quadro de fita na parede com o contorno a caneta) + `ghost_speed_bag`; plaquinha colada logo abaixo,
  centrada em x 432 a partir de y 102 (na garagem cai na porta de enrolar). Chegada: offsets -8,-3,0,1,0 + `fx_arrive_sparkle` + `speed_bag_l0_wall_swing`.

**Boneco de tatame (Jiu-jitsu):** formas baixas, azul de tatame e lona.
- Foco: `grappling_dummy_lN_idle/hit`, sentado de perfil olhando para o lutador, sobre um pedaço de tatame; pivô no chão em **(338,279)**,
  ordenar como y 266. Clique: amassa 2 px, tomba 2 px, volta (3 quadros, 12 fps). O lutador usa o `fighter_punch` (placeholder: sem pose de grappling nesta fase).
- Descanso: `grappling_dummy_lN_rest(_gym)`, deitado de costas no canto da frente à esquerda, pivô **(228,283)** (na academia, em cima do tatame gasto).
- l0 = lona crua com fita prata num tatame velho; l1 (Guarda fechada) = couro azul com alças e faixa preta, tatame novo.
- Falta: `tape_mark_grappling_dummy` no chão + `ghost_grappling_dummy`; plaquinha em pé no fundo da marca, base em (230,268) com o `sign_brick`.
  Chegada: offsets -18,-8,-2,0,1,0 + `fx_arrive_dust_small` + tremida de 1 px.

**UI da fase:**
- Artes: `art_boxing` (luva vermelha) e `art_bjj` (nó da faixa azul) em 16x16 e `_9`; ilustração do cartão `art_card_<arte>` (72x56).
  Cor de arte marcial continua roxa (botão de foco `ui_button_focus_art`, chip do HUD `ui_art_chip`), e cada arte tem sua cor de faixa:
  Boxe vermelho, Jiu-jitsu azul (`ui_art_card_header_<arte>`).
- Janela de arte: `ui_art_card` / `_hover` / `_last` (borda dourada) + selo `ui_art_tag_last` + botão `ui_button_art_*`. Layout sugerido em
  `manifest.by_data_id.art_window` (janela 420x268 em 110,34; 2 cartões de 190x220).
- Técnicas: `icon_tech_boxing_1|2`, `icon_tech_bjj_1|2` (16x16). Aparelhos: `icon_speed_bag`, `icon_grappling_dummy` + `_locked(_buyable)`.
- MUDAR: `icon_move` (caixa de papelão com fita), botão `ui_button_move_normal|hover|pressed|disabled` (verde = dá para pagar; apagado nunca some)
  e cartão `ui_move_card|_ready|_dim` para o bloco PRÓXIMA. HUD do local: `icon_location_gym` / `icon_location_garage`.
- Árvore: `ui_tree_column_style` (faixa roxa), `icon_branch_style`, abas `ui_tree_tab_normal|active` (se o UI/UX preferir abas), nós
  `skill_style_boxing` (luva + sininho) e `skill_style_bjj` (ampulheta sobre a faixa) com as 4 peças de estado da Fase 4.
- 4 botões de foco: cabem em 372 px com largura 90 e passo 94 (134, 228, 322, 416); "RESISTÊNCIA" não cabe em 90 px: usar "RESIST." ou 2 linhas
  (decisão do UI/UX, passa pela `alinhamento-ui`).

**Onde fica cada um na academia:** lutador, equipe (vizinhos, tios, Prof. Nelson), Metrônomo, corrente e corda nos **mesmos pontos da garagem**
(`manifest.by_data_id.gym`). A sala foi desenhada em volta deles. As pessoas têm a luz da lâmpada pintada: na academia ficam um pouco mais quentes.

**Mockups:** `fase5_academia_x2.png` (academia com Boxe, equipe completa e pera na parede + janela de arte da 1ª chegada),
`fase5_marcas_x2.png` (garagem de uma carreira de Boxe com a marca da pera e o cartão MUDAR; prancha com o boneco em marca/foco/descanso,
pera em foco, as 2 chegadas, MUDAR sem dinheiro, aba ESTILO e ícones), `fase5_sprites_x3.png` (folha de contato).

**Placeholder / precisa de pixel artist:** a sala da academia é o marco da fase e merece um artista: textura de tinta e reboco, o espelho
(reflexo de verdade), os pôsteres com ilustração, o banco e a porta com material. O boneco precisa de anatomia e volume de lona/couro
(hoje é feito de cápsulas), e o lutador precisa de uma pose de grappling por cima dele (Artista de Personagens). A pera pede o couro
brilhante e o borrão de movimento desenhados à mão. Os ícones de técnica (principalmente Guarda fechada e Esquiva e volta) são os menos
imediatos em 16 px. As pessoas deveriam ganhar uma versão com a luz fria da academia.

## 18. Fase 5.1 (garagem clara, caixa da escola, corda no gancho)

Gerador: `tools/art/make_sprites_fase51.gd` (rodar como no §12; **acrescenta** ao `manifest.json` e relê o arquivo na hora de gravar).
**Rodar por último**, depois dos geradores das Fases 2 a 5: ele retoca os dois fundos e corrige as posições da corda.
`-- --teste=<pasta>/` grava tudo numa pasta de teste, sem tocar no projeto. Nenhuma arte de personagem aqui.

### 18.1 Tokens de hierarquia (nomes iguais aos do `docs/fases/fase5.1-design.md` §3)
Cópia em dados: `manifest.json → ui_tokens`.

**Cores**
| Token | Paleta | Hex | Uso |
|---|---|---|---|
| `col_treino` | `gr3` | a6d86a | Treino, +/s, por clique, todo preço em Treino |
| `col_money` | `y1` | f5d26b | Dinheiro e todo preço em $ (sempre com `$` ou a moeda) |
| `col_fame` | `f2` | f59ac0 | Fama (ícone `icon_fame` já recolorido) |
| `col_legacy` | `p2` | b07ad8 | Legado em jogo e permanente |
| `col_text_1` | `white` | f2ece0 | texto principal (níveis 1 e 2) |
| `col_text_2` | `g2` | 8f8890 | rótulos, "cada", descrições, **preço sem saldo** |
| `col_disabled` | `g1` | 6b6570 | item trancado (1 linha) |
| `col_buyable` | `y2` | fff3c4 | contorno de 1 px do comprável mais barato (nunca texto) |
| `col_strength` / `col_agility` / `col_endurance` / `col_art` | `r2` / `b3` / `y0` / `p1` | — | atributos e arte marcial (já existiam) |

Decisões:
- **Treino continua verde e Dinheiro continua ouro** (o Designer sugeriu o contrário). O raio verde, o `+/s` verde e a moeda dourada já
  estão em todos os ícones e na árvore ("verde = dá para comprar com Treino"); trocar custaria refazer ícones sem ganho de leitura.
- **Fama sai do roxo e ganha uma rampa nova, só de UI: `f0 #7a2a52` · `f1 #d4558f` · `f2 #f59ac0`** (rosa de letreiro). Fama e Legado
  eram o mesmo `p2`, e o azul sugerido é a Agilidade. A paleta passa de 42 para **45 cores**; a rampa `f` não entra em cenário nem em personagem.
- **Resistência usa `y0` (âmbar), que já é a cor da barra dela; Dinheiro usa `y1` (ouro claro).** Hoje `ui_tema.cor_atributo("endurance")`
  devolve `Y1`, igual ao dinheiro: é a única linha de atributo que muda (1 passo na mesma rampa). É o par mais próximo da tabela; se o dono
  achar perto demais, o plano B é o Dinheiro em `y2`.
- **Legado (`p2`) e arte marcial (`p1`) seguem na mesma família roxa**, de propósito: os dois são "o que fica". A arte usa `p1` como
  **fundo** (botão, chip); o Legado usa `p2` como **texto**. Nunca escrever número de arte em `p2`.
- **Nenhum preço em vermelho.** Sem saldo = `col_text_2` e ícone da moeda em `g1`. Vermelho é só Força, risco e LUTAR.
- Comprável mais barato: cartão normal + contorno `col_buyable`; pode pulsar alternando com `y1` a 2 fps.

**Tamanhos (no máximo 3, uma fonte só)**
| Token | Fonte | Uso |
|---|---|---|
| `txt_hero` | 5x7 em **2x** (`font_size` 22, 14 px) | saldo de Treino, valor por clique, LUTAR! |
| `txt_title` | 5x7 em 1x, CAIXA ALTA, `col_text_1`, **filete `g0` de 1 px** embaixo | título de bloco |
| `txt_body` | 5x7 em 1x, maiúsculas e minúsculas | todo o resto |

O tamanho maior é a **mesma fonte em escala 2x**, não uma segunda fonte: continua na grade, já tem todos os acentos e o BMFont já carrega.
Uma fonte só de números em 10x14 desenhada à mão (cantos arredondados no 0, 6, 8, 9) deixaria o número-herói mais bonito: fica como pedido
para um pixel artist, não entra agora. Título e texto têm o mesmo tamanho: a diferença é caixa alta, cor e filete.

### 18.2 Corda no gancho
- **Gancho em (296,166)** nas duas salas (`layout.rope_hook`): altura do ombro de quem está encostado na parede; a corda vai de y 166 a 206.
  O desenho original punha o prego em (352,72), perto da viga; o PR do Matheus já tinha descido a posição no manifest para (296,155), mas os
  fundos não tinham gancho ali e ainda mostravam o prego antigo.
- `garage_bg` e `gym_bg` foram **retocados** (não regerados): some o prego antigo; entra um prego grosso e torto com 3 riscos de giz
  (garagem) e uma chapinha de aço com gancho no barrado (academia).
- `rope_lN_idle(_gym)` regeradas com a luz do ponto novo. `tape_mark_rope`, `ghost_rope`, `fx_arrive_sparkle` e `unlock_jump_rope` seguem o gancho.
- `rope_lN_swing`, `rope_lN_swing_back` e `fighter_rope` **não foram tocados** (são do `make_golpes_jogador.gd` / Artista de Personagens).
- Os geradores das Fases 2, 4b e 5 ainda têm o prego em (352,72): se rodarem de novo, rodar o da 5.1 depois.

### 18.3 Marcas sem texto
A plaquinha de papelão saiu da sala (`sign_cardboard`, `sign_brick`, `sign_tape_bit` ficam no projeto, sem uso). A marca diz sozinha
**onde** e **o quê**:
- **Fita** (`tape_mark_<aparelho>`): agora com sombra de 1 px, para ler também na parede creme da academia.
- **Silhueta riscada** (`ghost_<aparelho>`): contorno tracejado branco e ink + miolo pontilhado, sem cadeado. Lê em bloco cinza, chão
  escuro, barrado verde e parede clara. É ela que diz qual aparelho falta.
- Três estados, por sprite (nada de `modulate`):
  | Estado | Sprites | Quando |
  |---|---|---|
  | normal | `tape_mark_X` + `ghost_X` | dá para comprar |
  | aceso | `tape_mark_X_hi` + `ghost_X` | mouse em cima (a dica abre) ou pulso lento de "dá para comprar" |
  | trancado | `tape_mark_X_dim` + `ghost_X_dim` + `mark_padlock` | pede outro aparelho antes |
- Ponto do cadeado: `by_data_id.unlock_*.lock_pos` — corda (296,187), esteira (445,249), pera (436,68), boneco (228,271).
- Mesmos quadros, pivôs e posições de antes (a da corda desceu com o gancho). Com a caixa esperando, a marca fica embaixo dela.

### 18.4 A caixa da escola
- **Dois tamanhos**, 4 quadros cada (0 fechada, 1 racha 1, 2 racha 2, 3 aberta): `box_big` (quadro 76x62, pivô 38,58; corpo 52x41) para
  esteira e boneco; `box_small` (quadro 48x42, pivô 24,38; corpo 28x25) para corda, pera e luvas. Pivô = meio da base, no chão.
- **Uma arte para os dois locais.** A caixa vem da escola, não do lugar, e **não recebe a luz da sala**: é o objeto novo da cena e tem
  que saltar ao olho. Sombra de contato já no quadro.
- Papelão `br3/br2` com tampa `y0`, fita crepe, setas "este lado para cima", carimbo vermelho e **etiqueta branca com o símbolo**.
  Na sala a etiqueta e o carimbo são **ilegíveis de propósito** (nenhum texto fixo sobre a cena). O texto de verdade aparece na dica de
  hover, na etiqueta de papel `ui_box_tag` (9-slice) com o carimbo `ui_box_stamp` (9-slice): layout em `by_data_id.box.tag`.
- **Símbolo da escola: PROVISÓRIO** (`school_symbol_9/16/32`): um frontão de garagem com as ripas do portão, em azul de carimbo. A
  história diz que o símbolo nasce quando a garagem é salva; quando existir, trocar os 3 arquivos e rodar o gerador (ele também está
  pintado dentro das caixas).
- **Lugares** (`layout.box_slots`, iguais na garagem e na academia; seguem a regra do design 1.4, com os tamanhos reais):
  | Slot | Pivô | Caixa | Observação |
  |---|---|---|---|
  | `treadmill` | (445,268) | grande | em cima da marca da esteira |
  | `jump_rope` | (258,244) | pequena | no pé da parede, embaixo do gancho. **Mudou** do (262,288) proposto: ali a caixa grande do boneco encostava nela |
  | `art` | (228,283) | grande (boneco) ou pequena (pera) | canto da frente à esquerda |
  | `glove` | (386,288) | pequena | na frente, à direita do alvo. Era (382,288): 4 px para dar os 8 px de folga |
  Faixa livre do lutador e do alvo: x 281..362. Ordenar por y do pivô, como as pessoas. O Prof. Nelson (394,280) fica **atrás** da caixa
  da luva, que cobre as canelas dele.
- **Parada:** balança 1 px a cada 4 s e pisca o `fx_box_glint` na quina. É isso que chama o clique, sem texto.
- **Cliques** (`by_data_id.box.clicks`):
  | Clique | Quadro depois | Tremida (x, 30 fps) | Efeito |
  |---|---|---|---|
  | 1 | 1 | -1, 1, -1, 0 | `fx_box_chips_1` (5 lascas, 0,36 s) |
  | 2 | 2 | -2, 2, -2, 1, 0 | `fx_box_chips_2` (10 lascas + faísca, 0,43 s) |
  | 3 | 3 | -3, 3, -2, 2, 0 + tela 1 px | `fx_box_burst` (clarão, abas, estrelas, 0,5 s) |
  Os efeitos têm pivô no **meio de cima da caixa** (pos + `top_center_offset` do sprite).
- **Abertura: 1,2 s** do 3º clique ao item assentado (limite 1,5 s): tremida 0–0,15 · estouro 0–0,5 · item aparece 0,15–0,6 · caixa
  aberta some 0,6–0,9 (piscando, sem alpha) · assenta e o foco vai para ele 0,9–1,2. Aparelho de chão sobe de dentro da caixa e pousa;
  corda, pera e luva aparecem direto no lugar com a animação de pendurar que já existe.
- Sons: não há som novo. Sugestão com o que existe: `block.wav`, `hit_heavy.wav`, `punch_crit.wav` + `buy.wav`.

### 18.5 Como a UI convive com a sala
Nenhum texto fixo em cima da cena: saem as plaquinhas, "SEGURE SHIFT", "SEGURAR" e o chip da arte. Na sala só ficam o número do clique
(efeito) e a dica de hover (painel `d1` com borda `ink`, 1ª linha `col_text_1`, 2ª `col_text_2`).
Conferência: `mockups/fase51_garagem_antes_depois_x2.png` (proposta de leitura; quem fecha o layout é o UI/UX, pela `alinhamento-ui`).

### 18.6 Mockups
`fase51_garagem_antes_depois_x2.png` (captura de hoje x os 3 níveis, com a legenda dos tokens), `fase51_caixa_x3.png` (4 estados nos 2
tamanhos, os 3 efeitos quadro a quadro, etiqueta, símbolo e linha do tempo), `fase51_corda_marcas_x2.png` (garagem e academia com as
marcas nos 3 estados, a corda no gancho e as caixas nos lugares, com a equipe cheia), `fase51_sprites_x3.png` (folha de contato).

### 18.7 Placeholder / precisa de pixel artist
- A caixa aguenta retoque: falta textura de papelão (ondulado, amassado de verdade) e os quadros de racha são o mesmo desenho com
  rasgos por cima; um artista faria a caixa deformar. As lascas são quadradinhos com gravidade: falta rotação desenhada.
- O "tchan" é uma estrela de 8 pontas e um anel: funciona, mas é o efeito que mais ganha com animação feita à mão.
- As silhuetas riscadas são o contorno do sprite calculado por código. Servem; à mão ficariam com traço de giz de verdade.
- O gancho da garagem tem 6 pixels. O símbolo da escola é provisório e depende da história.
- A cor da Fama (rampa `f`) foi escolhida para separar das outras 7; vale um olhar humano na tela real, ao lado da Força.

## 19. Fase 5.2 (Bolsa da torcida, Grito da equipe, caixas da L3/L4)
Gerado por código a partir do scratchpad do Diretor de Arte (`art52/make52.gd`, rodado com `--path E:/Fightclicker -- --final`);
o manifest foi relido na hora de gravar e só ganhou as chaves abaixo. A luva L4 (mãos, luta, cursor, `icon_glove_l4`,
`art_hung_glove_l4`, `equipment/glove_l4`) é do Artista de Personagens.

### 19.1 Bolsa da torcida (`event_golden_crew`)
- **Mesmo pacote da luva ×7:** quadro 22x21, pivô (11,10), 3 quadros em loop a 6 fps, o mesmo ouro (fora da paleta de cena de
  propósito: é o evento que salta da sala), o mesmo contorno marrom-escuro e o mesmo brilho em cruz passeando da esquerda para a
  direita. Aparece, flutua e some do mesmo jeito (sala.gd); só troca o sprite (`training.json → golden_event.crew_sprite`).
- **Silhueta oposta, para ler de longe:** a luva é um **cogumelo** (cúpula larga em cima, punho reto creme embaixo); a bolsa é uma
  **pera invertida** (boca franzida em 3 abas e cordão creme em cima, bojo largo embaixo, moeda estampada no meio). O creme do cordão
  é o mesmo do punho da luva: as duas são da mesma família, mas o creme fica embaixo numa e em cima na outra.
- `by_data_id.golden_event` junta as duas variantes (`frenzy_sprite`, `crew_sprite`, anim, fps, área de clique).

### 19.2 Grito da equipe (`icon_crew_click`)
Ícone 16x16 da LOJA (como os outros): megafone **verde** (a cor da equipe nos ícones de Corpo/equipe) gritando para a direita,
com duas ondas de som amarelas sem contorno. `by_data_id.crew_click.icon`.

### 19.3 Caixas da L3 e da L4
`by_data_id.box.sprite_by_item` / `slot_by_item`: `glove_l3` e `glove_l4` = `box_small` no slot `glove` (igual L1 e L2; a L3 não
estava na lista). Etiqueta: `box_label` "LUVA MARCA" / "LUVA TORNEIO" e `box_stamp` "ETIQUETA INTACTA" / "NÃO EMPRESTAR" cabem na
etiqueta de 104 px do padrão 5.1 (conferido no mockup). Conferência da L3: ícone, cursor, luva pendurada e item já existem no padrão
atual; faltava só a caixa.

### 19.4 Mockup e placeholder
`mockups/fase52_bolsa_x3.png`: as duas lado a lado (3 quadros, silhueta, na garagem e na academia em 1x), os ícones da LOJA
(L3, L4, Grito) e as etiquetas das caixas.
Precisa de pixel artist: a bolsa pede volume de tecido de verdade (dobras, peso das moedas puxando o fundo) e um brilho desenhado à
mão; o megafone pede um ângulo de 3/4. Manter 22x21, pivô (11,10) e 3 quadros para trocar só o arquivo.
Nota para o Roteirista: o toast diz "PASSOU O CHAPÉU", mas o objeto é uma bolsa. Ou o texto fala de bolsa/sacola, ou a arte vira
chapéu (perde a silhueta oposta à luva; não recomendo).

## 20. Fase 5.3 (calendário da campanha, Passar o posto, retrato por luva)
Gerador: `tools/art/make_sprites_fase53.gd` (rodar de uma pasta temporária com `project.godot` vazio;
`-- --final` grava no projeto e só acrescenta chaves ao manifest, relendo o arquivo na hora). Retratos por luva:
`tools/art/make_sprites_jogador.gd -- <saida> --so-retratos`. Mockup: `mockups/fase53_calendario_x2.png`.
Dados para a UI: `manifest.json → by_data_id.campaign_calendar`, `pass_post_button`, `player_portrait`. Posições em 1x.

### 20.1 Ideia visual
**Uma folhinha de parede** (argolas, cabeçalho vermelho, picote da folha arrancada) é o símbolo de tudo: o dia anda = folha
arrancada; a data da luta = **dia circulado de caneta vermelha**; campanha completa = folhinha dourada com estrela.
Nenhum relógio de ponteiro, nenhuma contagem em segundos: o jogador pensa em dias.

### 20.2 HUD (nível 2, não grita)
- Fica na coluna da esquerda, no lugar do "PRÓXIMA:" de hoje: plaquinha 9-slice `ui_countdown_plate_<risco>` (7,131) 116x26,
  folhinha `ui_calendar_page` (11,133) com o **dia da campanha** (1x, `d1`), linha 1 "Faltam X dias" (`col_text_1`, x 35, y 136),
  linha 2 o adversário (`col_text_2`, y 146), e embaixo o selo de risco que já existe (35,160).
- A **faixa de 2 px à esquerda da plaquinha tem a cor do risco** (verde/âmbar/vermelho, os mesmos `col_risk_*`); o selo repete
  com ícone, para quem não distingue cor. Nada em `txt_hero`: o número grande da tela continua sendo o Treino.
- Dia da luta: `ui_countdown_plate_today` (fundo `r0`, faixa ouro) + folhinha no quadro 1 (dia circulado). Depois do Kid:
  `ui_countdown_plate_done` + `icon_campaign_complete` e "CAMPANHA / COMPLETA" em `col_money`; sem número, o relógio some.
- Dia virando: `fx_calendar_tear` (4 quadros, 12 fps, uma vez) por cima da folhinha. Sem som novo.

### 20.3 Avisos
| Quando | Sprite | Onde | Comportamento sugerido |
|---|---|---|---|
| 3 dias | `ui_warn_strip_3d` + `icon_calendar` | topo da sala, centrada em x 320, y 22, 18 de altura | desce em 0,2 s, fica ~6 s, sobe |
| 1 dia | `ui_warn_strip_1d` ↔ `_1d_hi` a 2 fps + `icon_calendar_alert` | mesmo lugar | som que já existe ao entrar; fica até a luta ou até clicar |

A de 1 dia é urgente sem ser feia: vermelho da própria paleta, pontas com listras diagonais vermelhas (fita de aviso sem o
amarelo-e-preto de obra), filete dourado, pulso por troca de quadro (sem alpha, sem tremida). Largura = conteúdo + margens;
nenhuma das duas cobre o lutador nem o alvo.

### 20.4 Dia da luta
- A sala fica atrás do **mesmo pontilhado** que já escurece a sala na prévia; o HUD mostra a plaquinha "today".
- A prévia ganha a folhinha grande `ui_day_badge` (40x40) **presa com fita crepe** no canto de cima à esquerda (offset -10,-12),
  por cima da borda: cabeçalho "HOJE" 1x branco, número do dia em `txt_hero` dentro do círculo de caneta.
- Dois botões **diferentes no peso**: **LUTAR!** o vermelho cheio de sempre (`fight_button`); **PASSAR O POSTO** de contorno
  roxo sobre `d1` (`ui_button_pass_*` + `icon_pass_post`, texto `p2`). Roxo = Legado, que é o que ele rende. O contorno deixa a
  escolha clara e diminui o clique sem querer (a confirmação continua obrigatória). Sem botão de voltar a treinar.
- Fora do dia, o botão roxo da sala segue igual e só troca o texto; sugestão: ícone `icon_pass_post` também ali, para a mesma
  ação ter o mesmo desenho. "PASSAR O POSTO" + ícone cabem em 103 px (o botão tem 115).

### 20.5 Retrato da luta por luva (B1)
`portrait_player` (velha) + `portrait_player_glove_l1..l4`: mesmo recorte, fundo e virada; só a luva muda. Regra igual à das
folhas: id = `portrait_player` + sufixo da luva equipada; vale no topo da luta e na prévia (inclusive a do dia).
O `portrait_player` regerado saiu idêntico ao arquivo de antes.

### 20.6 Placeholder / precisa de pixel artist
- A folhinha e a folha arrancada são retângulos girados por código: falta a folha dobrar de verdade e um rasgo desenhado.
- O círculo de caneta é uma elipse com espessura variável; à mão ficaria com traço de marcador (começo e fim sobrepostos).
- O selo da campanha (roseta) e o `icon_pass_post` (luva → estrela) pedem desenho à mão; manter 40x44 e 16x16.
- Números da folhinha usam a fonte 5x7; uma fonte de calendário (números condensados) ficaria melhor e é o mesmo pedido da §18.1.

## 21. Fase 5.4 (árvore grande: o mapa que se revela)
Gerador: `tools/art/make_sprites_fase54.gd` (rodar de uma pasta temporária com `project.godot` vazio; `-- --final` grava no projeto e só
acrescenta chaves ao manifest, relendo o arquivo na hora). Mockup: `mockups/fase54_mapa_x2.png`. Dados para a UI e o Programador:
`manifest.json → by_data_id.skill_map` (tela, regras de pintura, neblina, linhas, estados, posições). Peças do mapa em `assets/sprites/ui/map/`.

### 21.1 Ideia visual
**O quadro de avisos da escola.** No meio, um quadro de **cortiça** com os 12 nós de sempre. Em volta, cada região é um **pedaço de
material pregado na parede**: concreto (Garagem), azulejo verde (Academia), lona vermelha do ringue (Boxe), tatame azul (Jiu-jitsu) e
feltro roxo do mural (Campanha). O que sobra é a parede escura. Nó comprado = **plaquinha pregada com tachinha dourada**; linha acesa =
o **Legado correndo** (roxo, com um pixel branco andando). O resto fica sob **neblina** (ink com nuvem d1 em dither), que recua quando o
nó aparece. Nenhuma região precisa de texto para ser reconhecida: o material diz.

### 21.2 Tela (640x360, por cima da sala)
| Peça | Sprite | Lugar |
|---|---|---|
| Moldura de madeira com pregos (9-slice) | `ui_map_frame` | (0,0) 640x360 |
| Barra do topo | `ui_map_topbar` | (5,5) 630x20 |
| Título | `icon_skill_map` + texto `col_text_1` | ícone (9,7), texto (29,11) |
| Dica "arraste ou use a roda" | texto `col_text_2` | 12 px depois do título, y 11 |
| **Legado** (o número herói desta tela) | `icon_legacy_16` + `txt_hero` `col_legacy` | texto termina em x 610, y 8 |
| Fechar | `ui_map_close_normal/hover/pressed` | (616,7) 16x16 |
| Janela do mapa | recorte | (5,26) 630x329 |
| Borda rebaixada (miolo vazio) | `ui_map_viewport_edge` | (4,25) 632x331, por cima do mapa |

Ordem de desenho do mapa: fundo pintado → linhas → neblina → nós → plaquinhas de região e preços → efeitos → cartão.

### 21.3 Fundo e regiões
- Ladrilhos 32x32 que emendam: `map_tile_wall|center|garage|gym|boxing|bjj|campaign`.
- **Pintura por células de 8x8, feita uma vez ao abrir**: cada célula pega a região do nó mais perto até 44 px; nó de ligação pinta
  xadrez das duas regiões; nada perto = parede. Região trancada (Academia antes do 1º discípulo lá; arte não liberada) = parede.
  Costura de 1 px ink entre materiais, 1 px de luz no topo do recorte e 1 px de sombra na parede embaixo. O recorte sai em degraus de
  8 px, de propósito: parece pedaço cortado e pregado. Código de referência: `region_grid()` / `paint_regions()` no gerador.
- Distância mínima entre centros: **40 px** (nó pequeno) e **52 px** (marco). Pedido ao Designer ao escolher as posições.

### 21.4 Nós (3 tamanhos, 4 estados)
| | Pequeno 24x24 (pivô 12,12) | Marco 38x38 (pivô 19,19) | Ligação 28x24 (pivô 14,12) |
|---|---|---|---|
| Comprado | `map_node_s_owned_<tom>` | `map_node_b_owned_<tom>` | `map_node_link_owned_<a>_<b>` |
| À vista, Legado paga | `map_node_s_buyable` (2 quadros, 2 fps) | `map_node_b_buyable` | `map_node_l_buyable` |
| À vista, sem Legado | `map_node_s_missing` + `map_node_veil` | `map_node_b_missing` + véu | `map_node_l_missing` + véu |
| Escondido | não desenha (`_hidden` com "?" = quadro de partida da revelação) | `map_node_b_hidden` | `map_node_l_hidden` |
| Mouse em cima | `map_node_s_hover` | `map_node_b_hover` | `map_node_l_hover` |

- Forma: **octógono** (plaquinha), diferente dos quadrados da árvore antiga. O marco tem anel duplo e 4 pontas; a ligação tem elos dos
  dois lados e, comprada, o anel cortado na diagonal com as cores das duas regiões (`<a>_<b>` na ordem garage, gym, boxing, bjj, campaign).
- Ícone 16x16 sempre no centro (pivô −8,−8). Comprado leva a tachinha dourada no canto de cima à direita.
- **Tom do anel** (`tone_by_branch_or_region`): Corpo e Boxe = vermelho (`r2/r3`, o Boxe herda a luva); Campanha (ramo e região) = ouro
  (`y0/y1`); Estilo = roxo (`p1/p2`); Garagem = giz (`g3/white`); Academia = verde (`gr2/gr3`); Jiu-jitsu = azul (`b2/b3`).
  O fundo diz a região, o anel diz o ramo: o ouro da Campanha em cima do feltro roxo tem contraste de sobra.
- À vista que o Legado paga = anel `col_buyable` piscando (mesma regra da 5.1). Sem Legado = anel escuro e véu pontilhado no ícone
  (ainda dá para ler o que é). **Preço**: etiqueta 9-slice embaixo de cada nó à vista, `ui_map_price_ok` (p0, número `col_legacy`) ou
  `ui_map_price_missing` (d1, número `col_text_2`). Nunca vermelho. Comprado não mostra preço.

### 21.5 Linhas
Retas de centro a centro em **pixels de Bresenham** (nada de Line2D com antialias nem textura girada):

| Estado | Quando | Desenho |
|---|---|---|
| Acesa | os dois comprados | 2 px (`p2` + `p1`) + sombra ink; 1 pixel branco a cada 8, andando 1 px por quadro a 8 fps |
| À vista | os dois revelados, pelo menos um não comprado | 1 px `g2` + sombra ink |
| Apagada | um lado escondido | 1 px `g0` tracejado 2/2, **antes da neblina** (some aos poucos dentro dela: diz "tem mais ali") |

### 21.6 Neblina e revelação
- `map_fog_25|50|75|100` (32x32, Bayer). Por célula de 8x8, pela distância ao nó revelado mais perto: < 40 px limpa; 40–48 = 25%;
  48–56 = 50%; 56–64 = 75%; além = 100%.
- **Revelar (≤ 0,5 s):** as células em volta do nó novo descem um nível a cada 0,1 s (0,4 s no total) e `fx_map_reveal` (40x40,
  6 quadros, 12 fps) toca no centro: a nuvem com "?" se abre em fiapos e ficam 4 faíscas. O nó aparece no quadro 2.
- **Comprar:** `fx_map_buy` (40x40, 5 quadros, 12 fps): clarão no formato do nó, anel ouro abrindo, faíscas. O anel vira "comprado" no
  quadro 1; no quadro 2 começam as revelações dos vizinhos, todas juntas. Sem alpha e sem som novo (reaproveitar `buy.wav`).

### 21.7 Plaquinhas de região e cartão
- `ui_map_region_label_<região>` (9-slice, 13 px, faixa na cor do anel) + `icon_region_<região>_9` + nome 1x. Aparece quando o 1º
  nó da região fica à vista, uns 30–40 px acima dele, no mundo (anda com o mapa). O centro não tem plaquinha.
- Cartão: `ui_map_card` (d1, igual à dica) com nome / efeito na cor do tipo / preço, e no pé a faixa roxa `ui_map_card_next` com
  `icon_calendar` e "VALE NA PRÓXIMA CAMPANHA". Abre ao lado do nó, sempre inteiro dentro da janela do mapa.

### 21.8 Botão da sala
- `ui_map_button_normal|hover|pressed` 22x22 com `icon_skill_map` (cortiça com 3 tachinhas e barbante). **Lugar: (132,22)**, canto de
  cima à esquerda da sala, na parede lateral (igual na garagem e na academia). Fica longe do alvo (x 281..362), das faixas de aviso
  (centradas em x 320, y 22) e da faixa do assistido (y 273..290). O `debug_overlay` também usa (134,24), mas só aparece em debug.
- Brilho: `ui_map_button_glow` (2 quadros a 2 fps, borda ouro + faísca trocando de canto) **só** quando há nó à vista que o Legado
  paga. Sem compra: peça normal, parada. A hierarquia da 5.1 não muda: é nível 3, sem texto fixo e sem número.
- Dica (hover) padrão: "ÁRVORE" + 2ª linha `col_text_2` com quantos nós dá para comprar.
- Plano B, se o dono não achar o botão: a mesma ação como botão com texto "ÁRVORE" no fim da coluna da esquerda, (7,264) 116x22.
- Na tela de fim, o botão ÁRVORE pode ganhar `icon_skill_map` à esquerda do texto, para as duas portas terem o mesmo desenho.

### 21.9 Ícones
- **Regiões:** `icon_region_garage|gym|boxing|bjj|campaign` (16x16) e `_9` (9x9): fachada com portão de aço, halter no azulejo,
  canto do ringue com 3 cordas, nó da faixa no tatame, folhinha com estrela. Também são o ícone **provisório dos marcos** da região.
- **Nós novos:** `skill_rope_ready` (corda montada: corda pendurada no prego, com brilho), `skill_prep_day` (+1 dia: folhinha com
  "+1"), `skill_shout_loud` (Grito mais alto: o megafone do Grito, maior, com 3 ondas).
- **Nós pequenos usam o ícone do tipo de efeito** (`by_data_id.skill_map.icon_by_effect`), reaproveitando os 12 atuais e os ícones da
  LOJA dos aparelhos. Os nomes dos tipos novos ali são sugestão; vale o que o Designer puser no `skill_tree.json`.
- **2ª passada (feita):** os 6 marcos do `fase5.4-design.md` §9 têm ícone próprio 16x16 em `assets/sprites/ui/`:
  `skill_home_metronome` (gar_metro), `skill_crew_regulars` (gar_crew_start), `skill_coach_notebook` (camp_diary),
  `skill_standing_fan` (gym_fan), `skill_counter_punch` (box_counter), `skill_firm_base` (bjj_guard).
- **Qual ícone cada nó usa:** `skill_map.icon_by_node` (os 39 nós do `skill_tree.json` v2) manda; depois `icon_by_effect`
  (com os nomes reais dos tipos; `art_rule_bonus`/`art_fight_bonus` escolhem pela `requires_art`); por último o campo `icon` do nó.
- **Mapa real conferido** (`mockups/fase54_mapa_real_x2.png`, `skill_map.map_check`): 741 pares, menor distância 57 px, nenhum
  abaixo de 40/52; plaquinhas de região não cobrem nó. Ressalva: as linhas `gar_radio–link_mat` e `gar_rope–link_shout` passam a
  11 px do centro de `body_crew_2` e `body_heavy_hands` (parecem ligadas a eles). Proposta ao Designer: `link_mat` (-6,4) e
  `link_shout` (-6,-4) (folga de 40 px; painel B do mockup).

### 21.10 Placeholder / precisa de pixel artist
- Os ladrilhos são ruído por código: um artista faria cortiça com furos de tachinha, concreto com manchas e tatame com costura.
  A neblina repete a cada 32 px; à mão, ladrilhos de 64 com nuvens desenhadas ficariam bem melhores.
- A borda das regiões em degraus de 8 px é proposital, mas um recorte desenhado (papel rasgado, lona com bainha) daria mais vida.
- `fx_map_reveal` e `fx_map_buy` são anéis e pontos calculados; são os efeitos que mais ganham com animação feita à mão.
- O ícone da corda montada é o mais fraco em 16 px. Manter os tamanhos (24/38/28, ícone 16, ladrilho 32) para trocar só os arquivos.

## 22. Fase 6a (Prólogo e voz: balão, parede da memória, garagem salva)
Gerador: `tools/art/make_cenario_fase6a.gd` (rodar de uma pasta temporária com `project.godot` vazio; `-- --final` grava no projeto e
só acrescenta chaves ao manifest, relendo o arquivo na hora). O `make_sprites_fase6a.gd` é do Artista de Personagens (Téo, Osmar, gesto).
Mockup: `mockups/fase6a_garagem_x2.png`. Dados para a UI: `manifest.json → by_data_id.speech_bubble`, `skip_hold`, `garage_saved_seal`,
`garage_story_wall`, `coach_point`, `school_symbol`. Posições em 1x. Valores do balão: `docs/cutscenes/balao-e-voz.md` (manda).

### 22.1 Fonte 5x7 (conferida antes de tudo)
- Minúsculas acentuadas (á à â ã é ê í ó ô õ ú ç) **existiam**, mas o acento encostava na letra (ã e õ viravam borrão). Agora a marca
  fica 1 linha acima, com 1 linha de folga. O `í` perdeu a bandeirinha (lia como "1"). Entraram `—` e `…` (117 caracteres).
  Mesmo atlas, mesma ordem, mesma métrica (`lineHeight` 12, `base` 9): nenhuma largura de texto muda.
- Maiúsculas `Í Â Ã Ç É` renderizam (RAÍZES, COBRANÇA, CINTURÃO). O acento da maiúscula encosta na letra porque a célula não tem
  mais linhas em cima; lê bem no contexto. Separar exigiria fonte mais alta (mexe em todo o layout): não vale agora.
- A fonte não tem `▼`: a seta é o sprite `ui_balloon_next`.

### 22.2 Balão
| Peça | Tamanho | Regra |
|---|---|---|
| `ui_balloon` | 9-slice 16x16, cantos 5 | cream, contorno ink com canto de 2 px, sombra dura `d1` embaixo e à direita **dentro** do retângulo w x h |
| `ui_balloon_tail` (+ `_l`, `_r`) | 7x6 | linha 0 cream em y = by + h - 2 (apaga o contorno); ponta em by + h + 3. `_l`/`_r` só quando a ponta está a menos de 14/15 px da quina |
| `ui_balloon_tag_<cor>` | 9-slice 8x10 | em (bx + 6, by - 6), largura nome x 6 + 6, nome em minúsculas. **10 px e não 9**: o acento de "téo" precisa de folga. Téo `red` (r2, texto white), Osmar `gold` (y0, texto ink), discípulo `blue` (b3) |
| `ui_balloon_next` | 5x4, 2 quadros | modo cena (6b) |
- Texto ink sem sombra, topo da maiúscula em by + 5, linhas a 9 px; 1 linha = 17, 2 linhas = 26 de altura.
- Na parede creme da academia o balão cream se separa pelo contorno e pela sombra (conferido no mockup).
- **Proposta de regra extra (DC/UI):** o balão não cobre o `head_anchor` de outro personagem na sala. Sem ela, o "desliza" do Téo
  em `foco_saco` (x 154..307, y 175..200) tapa a cabeça do Osmar (197,173); com ela, o balão sobe (x 226..379, y 149..174, ponta em y 178).
- **Segurar ESC** (só na abertura): chip `ui_skip_chip` (apagado) / `_active`, anel `ui_skip_ring` (9 quadros) e tecla `icon_key_esc`;
  altura 16, canto de baixo à direita da sala (direita em 507, base em 285). Texto sugerido: `esc: pular`.

### 22.3 Parede da memória (garagem, Arco 1)
Faixa **x 176..256, y 38..87**: ajuste da proposta do DC (180..262, 56..104), porque abaixo de y 92 está o metrônomo (231..249) e
em y 101 a prateleira. Não encosta no gancho da corda, no pôster, na lâmpada, na corrente (x 335), na pera da parede nem na porta.
| Objeto | Sprite | Pos (canto sup. esq.) | Quando |
|---|---|---|---|
| Aviso de cobrança | `wall_notice_debt` 22x28 | (178,52) | desde o começo até a garagem salva |
| Ficha amassada | `wall_form_blank` → `wall_form_named` 22x24 | (205,62) | sempre; troca quando a garagem é salva |
| Foto antiga (Osmar jovem, torta) | `wall_photo_old` 18x21 | (237,67) | sempre (cobre a fotinho pintada no fundo) |
| Recorte de jornal | `wall_clipping` 20x24 | (236,40) | 1ª vitória da escola |
| Foto da equipe | `wall_photo_team` 26x21 | (176,54) | garagem salva (no lugar do aviso) |
| Símbolo pintado | `wall_school_symbol` 32x40 | (344,38) | garagem salva (alto, à direita da corrente) |
- Nenhum objeto tem texto legível na sala (regra da 5.1). "ESCOLA: NENHUMA" / "ESCOLA: RAÍZES FIGHT CLUB", "AVISO DE COBRANÇA" etc.
  vão na dica de hover (textos do Roteirista). A ficha "depois" tem o rabisco riscado de vermelho e o nome à mão em caneta azul.
- Luz da lâmpada aplicada em cada ponto: não mover para longe. Só na garagem; troca de estado sem animação.
- **Osmar em (196,236)** (decisão do Produtor): balão em cima, sem ajuste (x 132..285, y 138..163), não cobre a parede da memória.
  Os vizinhos 1 e 2 passam na frente das pernas dele com a equipe cheia (ordem por y): aceito.

### 22.4 Símbolo da escola: Raízes Fight Club
A lâmpada da garagem, de pé, plantada: bulbo, soquete, uma linha de chão e raízes embaixo. `school_symbol_5/9/16/32` em tinta de
carimbo azul (b1/b2), como o provisório; `box_big`/`box_small` tiveram a etiqueta retocada (só o símbolo). Na parede, o 16 em 2x:
bulbo em tinta amarela que afunda no rejunte, raízes em tinta marrom, escorridos. O 5x5 é o limite: lê como "lâmpada com raiz" só de perto.

### 22.5 Selo "garagem salva"
O próprio aviso de cobrança, despregado, com o carimbo azul da escola. `seal_garage_saved` 52x54 na tela de vitória do cinturão em
**(418,146)** (à direita das linhas de prêmio), mais uma linha de prêmio `icon_garage_saved` + "GARAGEM SALVA" / "O LUGAR CONTINUA
NOSSO". Entrada: 2 quadros em 2x e depois 1x, tremida de 1 px, som que já existe. `seal_garage_saved_text` (96x64, com fita) e a fita
9-slice `ui_seal_garage_band` servem para espaços maiores.

### 22.6 Placeholder / precisa de pixel artist
- Papéis (aviso, ficha, recorte) são retângulos com riscos: um artista faria o amassado de verdade, a letra à mão e o papel de jornal.
- As fotos têm 5–10 px de gente: o retrato do Osmar jovem e a foto da equipe pedem desenho à mão (mesmos tamanhos).
- O símbolo é o que mais pede mão humana: em 5x5 a raiz é um traço. Manter 5/9/16/32 para trocar só os arquivos.
- O carimbo e a tinta na parede usam falhas por sorteio fixo; à mão ficariam com pressão e borda de carimbo real.

## 23. Fase 6b1 (Passar o posto: porta, luz do dia, caixote do mentor)
Gerador: `tools/art/make_cenario_fase6b1.gd` (pasta temporária com `project.godot` vazio; `-- --final` grava no projeto, mexe no manifest
só nas chaves desta fase e junta `docs/arte/manifest-6b1-personagens.json` do Artista, se existir). Pedido: `docs/cutscenes/pedidos-6b1.md` §2.
Manifest: `by_data_id.garage_door_scene`, `by_data_id.mentor_spot`, `layout.mentor_spot`, `layout.box_slots.jump_rope`.

### 23.1 Peças
| Sprite | Quadro | Ponto | Camada | Nota |
|---|---|---|---|---|
| `garage_door` | 84x**68**, 9 quadros, pivô (0,12) | pos (381,166) → desenha em (381,154) | `sorted` 222 | Borda ink por quadro: 219 (fechada = recorte do fundo), 216, 209, 201, 193, 185, 178, 172, **171**. **Mudança:** o pedido era 84x56; com isso a cabeça de quem está na soleira (quadro dele começa em y 154) aparecia acima da porta. O pivô mantém o `pos` da cena |
| `garage_door_outside` | 82x52 | (382,168) | `wall` | Dia claro branco (escolha A), y2 em dither embaixo, muro cream do outro lado, calçada cream y 213..219 com meio-fio g3 |
| `garage_daylight` | 170x70, 3 | (308,220) | `floor` | O próprio chão do `garage_bg` +1 na rampa (miolo junto à porta +2), borda em Bayer 4x4 de 5–7 px |
| `garage_door_shadow` | 64x32, 4 | (374,214) | `floor` | Assada sobre a luz (quadro 0 sobre a luz 0; 1..3 sobre a luz 2): desenhar depois do `garage_daylight` |
| `garage_crate` | 26x19, pivô (16,20) | `mentor_spot` | `sorted` 250 | Engradado de feira (ripas com fresta escura, montantes, pregos). Sem fita/etiqueta: não confunde com a caixa da escola |
| `garage_hung_gloves_old` | 20x34, 4, pivô (17,1) | argola (335,186) | `sorted` 254 | Quadro 0 só sobe 4 e vai 1 px à esquerda (o quadro de 20 px não deixa os 4) |

Quem está do lado de fora contra a luz: tom −1 (silhueta), como na prancha.

### 23.2 Mentor e caixas (conflito resolvido)
- **`mentor_spot` = (254,252)** (era 268,268). Em 268 o John sentado ia até x ~285, dentro da faixa do alvo (281..362, folga até 273), e tapava a caixa da corda.
  Em (254,252) ele ocupa x 238..270, y 200..252: encostado no fim do carro, olhando o saco, longe do Osmar (196,236) e do vizinho 2 (220,258).
  Caixote em (238,232). Com foco na corda/esteira o saco de lado (258,160) fica atrás da cabeça dele pela ordem por y: aceito.
- **Caixa da corda = (424,287)** (era 258,244): na frente, à direita da caixa da luva (386,280), 6 px de folga entre os cliques. Cobre 5 px da base
  da esteira encostada (atrás, pela ordem por y; o mesmo caso já aceito da caixa da esteira com o tio 1). Fora do caminho da porta até o saco.
- **Para o Diretor de Cutscenes:** a cena usa o nome `mentor_spot`, então não quebra, mas o `step_back` agora anda ~55 px (não 35): 0,73 s fica
  rápido; sugiro ~1,1 s ou 4 passos. A mão do `point_spot` continua apontando o chão em frente ao saco (a direção não muda).
- Conferência: `mockups/fase6b1_garagem_conferencia_x2.png` (alvo+folga em vermelho, caixa antiga em cinza, caixa nova em amarelo, mentor em azul).

### 23.3 Paletas do discípulo
Fonte da verdade: `docs/arte/paletas-6b1.md` (o Designer/Programador copia para `data/disciples.json`). Mudanças sobre o alvo do design §6.3:
`skin_4` → #5a3029/#8c5545/#b8806a e `skin_5` → #422529/#73453f/#a06a5a (o alvo tinha a base da `skin_5` igual ao `br1` e a da `skin_4` quase
igual ao `br2`: cabelo e sobrancelha sumiam); sobrancelha do `copper` e do `blond` → `br0`. Calções sem mudança.

### 23.4 Fonte
`Í Ã Ç` (e todas as maiúsculas e minúsculas de `allowed_letters`, inclusive `À/à`) já existem nos dois `.fnt`. Nada acrescentado.

### 23.5 Placeholder / precisa de pixel artist
- A porta sobe com as lâminas paradas (só a barra anda): um artista animaria o rolo e a lâmina vibrando no tranco.
- A luz do dia é o chão +1 passo; à mão ganharia poeira no feixe e a borda da sombra do batente.
- O caixote e as luvas penduradas são pequenos e honestos; o par balançando pede 2 quadros a mais desenhados à mão.

## 24. Fase 6b2 (o segundo mentor na garagem)
Gerador: `tools/art/make_mockup_fase6b2_mentor2.gd` (pasta temporária com `project.godot` vazio; `-- --final` grava os mockups no projeto,
`--manifest` grava só `layout.mentor_2_spot`, `layout.mentor_2_spot_info` e `by_data_id.mentor_2_spot`, relendo o arquivo; ele confere
as regras abaixo e não grava se alguma falhar). Nenhum sprite novo.

### 24.1 `mentor_2_spot` = (150,262), de pé, encostado na parede esquerda
- **Quem:** o último que passou o posto, da Carreira 3 em diante, enquanto o John está no caixote. Parado, sem luvas, não fala, não é clicável.
- **Pose:** `disciple_stand_bare` (já existe no discípulo em camadas), virado à **direita** (olha o saco), sem espelho, quadros 0-3 a 4 fps
  (a respiração de 1 px é a "pose viva"). O "olha o saco de vez em quando" é o próprio facing: não pede folha nova. Sentado pediria uma
  folha `sit` do discípulo e um 2º caixote; de pé ocupa menos chão, e o escopo já previa isso para a garagem lotada.
- **Visual:** o que ele tinha (troca de cor `disciple_palette`, corte da cabeça dele). Sem luz pintada, como as folhas do discípulo.
  `floor_shadow` nos pés. Ordem por y (`sort_y` 262).
- **head_anchor** (1,-65) relativo ao pivô = (151,197) na sala. Ocupa x 138..162, y 197..263.
- **Conferido** (equipe cheia, 4 caixas com a corda em (424,287), porta fechada e emperrada, Osmar, John no caixote, discípulo no saco):
  fora da faixa do alvo com folga (273..370), fora da `no_cover`, fora do caminho da porta até o saco (faixa de 24 px de (423,221) a
  (303,272)), não encosta no vizinho 1 (que começa em x 163), no Osmar, no vizinho 2, no John nem na caixa da arte (188..220).
  Balões "em cima" do Osmar (132..285, y 132..167), do John sentado ou de pé (178..331, y ≥ 146, até 191) e do discípulo no saco
  não chegam na cabeça dele (x 145..157, y 199..211).
- **Por que não (490,250):** lá ele fica atrás do vizinho 3 (700 px² de sobreposição), do tio 1 e colado na caixa da esteira; some no canto.
  Em (152,262) o punho do vizinho 1 encostava na coxa: 2 px para a esquerda resolveram.
- **6c:** quando o John sair, o último que passou o posto vai para o `mentor_spot` (caixote) e este ponto fica livre.
- Mockups: `mockups/fase6b2_mentor2_garagem_x1.png` / `_x2.png` (jogo), `fase6b2_mentor2_conferencia_x2.png` (zonas, caminho, balão),
  `fase6b2_mentor2_candidatos_x2.png` (A x B).

### 24.2 Placeholder / precisa de pixel artist
- Sem luz da lâmpada no corpo dele: no canto ele fica um pouco mais claro que a equipe (que tem luz assada). Se incomodar, `modulate`
  ~(0.9, 0.9, 0.95) só nele, ou uma folha com luz assada para este ponto.
- Uma pose própria de mentor (ombro na parede, braços cruzados, olhar que vira para o saco) daria mais personalidade: 4 quadros, mesmo
  quadro 48x72 e pivô (22,67), com as mesmas camadas do discípulo.

## 25. Fase 6c1 (Casa nova: chegada à academia e saída do John)
Gerador: `tools/art/make_cenario_fase6c1.gd` (pasta temporária com `project.godot` vazio; `-- --final` grava no projeto e mexe no
manifest só nas chaves desta fase; sem `--final` = prévia em `<tmp>/out`). A raiz é a pasta acima de `tools/art` (ou `FIGHTCLICKER_ROOT`).
Ele confere os 4 pontos e não grava o manifest se algum falhar. `-- --busca [--sem-m2] [--min]` procura pontos livres para o Osmar.
Folhas do Artista: `tools/art/merge_manifest_6c1.gd` (lê `docs/arte/manifest-6c1-personagens.json`; variantes de paleta e a
sugestão de `scene_anims` vão para `by_data_id.personagens_6c1`). Rodar o merge **depois** do `--final`. Pedido: `docs/cutscenes/pedidos-6c1.md` §2.
Manifest: `layout.gym_coach_spot`, `gym_mentor_spot`, `gym_mentor_2_spot`, `gym_photo_spot` (cada um `[x, y]`, com `<nome>_info` à parte)
e `by_data_id.gym_arrival_scene` (ordem de desenho, quadros claros/escuros da porta, luz por quadro da porta).

### 25.1 Peças
| Sprite | Quadro | Ponto | Camada | Nota |
|---|---|---|---|---|
| `gym_half_dark` | 384x272 | (128,18) | `floor` | O `gym_bg` -1 de x 340 em diante, dither Bayer de x 300 a 339. **Furo** transparente no retângulo da porta (401,116,60,108). Com ele, o `gym_tube` quadro 1 no tubo da direita |
| `gym_door` | 60x108, 6 | (401,116) | `wall` | 0 fechada (= fundo), 1 meio (folha a 45°, rua na fresta), 2 aberta (folha de perfil em x 452..459, rua inteira no vão). **3..5 = os mesmos no escuro** (a rua não escurece): animações `*_dark`. **Mudança:** o pedido era 3 quadros; a metade escura cobriria a porta, então ela tem furo e a porta traz a versão escura |
| `gym_daylight` | 146x70, 2 | (330,220) | `floor` | O chão +1 (miolo +2), trapézio y 221..289, base x 336..470. 0 = porta aberta, 1 = meio aberta. **Desenhar depois do `gym_half_dark`** |
| `wall_photo_old_gym` | 18x21, 2 | `gym_photo_spot` | `wall` | 0 reta (a mesma conta das folhas do Artista), 1 torta (= `wall_photo_old`). No jogo, sempre 1 |
| `john_duffel` | 18x11 | (268,242) | `sorted` 251 | É a `mockups/fase6c1_bolsa_ref.png` do Artista pixel a pixel: no `grab_frame` da `john_pick_duffel` (56x72, pivô 22,67) a bolsa não pula (conferido em `fase6c1_cenario_pecas_x3.png`) |
| `garage_crate_gym` | 26x19, pivô (16,20) | `gym_mentor_spot` | `sorted` 250 | O caixote com a luz dos tubos. Regra do sufixo `_gym`: na academia o jogo troca sozinho |

A rua no vão fica na mesma altura de tela da `garage_door_outside` (muro em y 198, calçada até 219), com céu branco e uma fachada cream.
Ordem: `gym_bg` → wall (porta, foto) → floor (`gym_half_dark`, depois `gym_daylight`) → `gym_tube` → sorted. No A7 a porta passa do
quadro 5 para o 2 no mesmo tique em que o `gym_half_dark` some.

### 25.2 Pontos da academia = os mesmos da garagem
| Ponto | Valor | Ocupa |
|---|---|---|
| `gym_coach_spot` | (196,236) | Osmar x 185..209, y 174..237 |
| `gym_mentor_spot` | (254,252), caixote em (238,232) | x 238..270, y 196..253 |
| `gym_mentor_2_spot` | (150,262) | x 138..162, y 197..263 |
| `gym_photo_spot` | (212,158) | x 212..229, y 158..178, no barrado verde acima da mochila do banco pintado |

Conferido (`mockups/fase6c1_academia_conferencia_x2.png`): fora da faixa do alvo com folga (273..370), fora da `no_cover`, fora dos
caminhos da porta (428,224) → espera (352,262) → centro (303,272), fora das 4 caixas; a foto não é coberta por ninguém nem pelo saco
de lado (x 238..278) ou pela corrente; o balão do Osmar (132,132,154,36) não cobre cabeça nenhuma (passa por cima da foto: aceito).
As folhas do Osmar (`hang_photo`, `nudge_photo`) foram feitas para esta distância entre ele e a foto: mudar um ponto muda os dois.

**O que NÃO dá para cumprir com a equipe máxima (aviso, igual à garagem desde a 6a/6b1):**
- o vizinho 2 (220,258) cobre 167 px do Osmar e o vizinho 1 (176,284) cobre 67 px das pernas dele;
- o mentor sentado cobre o saco de lado (258,160) quando o foco não é o saco (619 px), como já aceito na 6b1.
A busca (`--busca`) mostra que, com equipe máxima, 2º mentor e caixote, **não existe ponto livre para o Osmar em nenhum lugar do chão**;
tirando o 2º mentor, só a coluna da parede esquerda (x 136..152) fica livre, e aí o 2º mentor não cabe em lugar nenhum. Para chegar a
0 seria preciso mexer na equipe na academia (pontos próprios da academia para os vizinhos, lidos pelo jogo), o que é código.
Durante a cena da chegada a equipe está escondida, então a cena não tem esse problema.

### 25.3 Mockups
`fase6c1_academia_cheia_x1.png` / `_x2.png` (4 caixas; tudo comprado com o boneco no tatame; depois da saída com o último sentado),
`fase6c1_academia_conferencia_x2.png`, `fase6c1_cenario_pecas_x3.png` (porta 0..5, luz, metade escura, foto, bolsa, caixotes, John
pegando a bolsa), `fase6c1_cenario_quadros_x1.png` (A1, A3, A6, A7 com as peças finais e as folhas do Artista).

### 25.4 Placeholder / precisa de pixel artist
- A folha aberta é uma faixa de 8 px; à mão ganharia a espessura com veio, a dobradiça e a sombra no batente.
- A porta meio aberta é a face pintada apertada por vizinho mais próximo: o vidro aramado fica serrilhado. Pede um desenho próprio.
- A rua no vão é branca e chapada (escolha "dia claro"); um artista poria poeira no feixe e a borda da sombra do batente no chão.
- A metade escura é o fundo -1 com dither: à mão, o escuro seguiria a forma da luz do tubo que ficou aceso.

### 25.5 Pontos próprios da equipe na academia: não cabem (estudo, sem gravar no manifest)
Pedido do Produtor: `by_data_id.gym.people_pos` com a equipe máxima sem ninguém cobrir ninguém, mantendo Osmar, caixote, 2º mentor e foto.
Modo `-- --equipe` do gerador (busca com volta, pixel a pixel, todos os quadros de cada folha, normal e virada) e `-- --capacidade`.
Ocupado: Osmar, John sentado e último sentado, caixote, 2º mentor, foto, saco de lado (l0 e l1), esteira encostada, boneco no tatame,
pera na parede, as 4 caixas em todos os quadros, faixa do alvo com folga (x 273..370), `no_cover`, caminhos porta → espera → centro e
parada da saída → porta, e a cabeça de ninguém dentro do balão do Osmar. Pés no chão (fora das paredes laterais).

| Situação | Resultado |
|---|---|
| Com as 4 caixas | `neighbor_1`, `neighbor_2` e `uncle_1` não têm **nenhum** ponto livre nem sozinhos (nem virados). Cabem juntos no máximo 3 corpos de 25 px (pose estreita como a `disciple_stand_bare`): (175,252), (225,253), (498,288) |
| Sem caixas (tudo comprado) | no máximo 5 corpos de 25 px, ou 2 a 4 com as folhas atuais (vizinhos e tios têm 34 a 44 px de largura pelos braços) |
| Sem o caminho da saída | igual: o que trava é o lado esquerdo cheio e as caixas à direita |

Os 3 lugares que sobram são apertados (entre o 2º mentor e o Osmar, entre o Osmar e o caixote, canto da frente à direita).
Mapa: `mockups/fase6c1_academia_espaco_livre_x2.png`. Nenhuma folha virada ou pose nova resolve sozinha: falta chão, não forma.
Para ter 0 sobreposições com a equipe inteira é preciso uma destas decisões (Produtor/Designer):
1. **Menos gente desenhada na academia** (ex.: até 3, nos 3 lugares acima, com uma pose parada estreita de 25 px para os vizinhos e tios;
   o resto "treina fora"). Folhas novas: `neighbor_N_stand_gym` / `uncle_N_stand_gym`, 48x72, pivô (22,67), braços junto ao corpo.
2. **Liberar chão:** tirar o 2º mentor ou o Osmar do chão nesta sala (ex.: Osmar só aparece quando fala), ou levar as caixas para outro lugar.
3. **Aceitar sobreposição só entre pessoas da equipe** (nunca sobre Osmar, mentores, foto, aparelhos e caixas): ainda assim os 3 vizinhos
   largos precisariam da pose estreita, porque com as caixas não têm lugar nem sozinhos.
Até a decisão, a academia segue com os pontos da garagem (`people_pos` não foi mexido) e as sobreposições do §25.2.

**Decisão do dono (2026-11-15):** aceitar como na garagem. Na academia a equipe usa os mesmos pontos da garagem; com a equipe
máxima, as sobreposições da §25.2 ficam como aviso, sem travar. Revisitar quando a academia ganhar arte feita à mão.

## 26. Fase 6c2 (Mais longe que eu: mural, Honra, hall e símbolo na roupa)
Gerador: `tools/art/make_arte_fase6c2.gd` (pasta temporária com `project.godot` vazio; `-- --final` grava no projeto,
`--manifest` relê o manifest e mexe só nas chaves desta fase, voltando os números inteiros para int e com CRLF: o diff fica só
nas chaves novas; não grava se a conferência do mural falhar). A camada do símbolo nas poses sai dos geradores de personagem
(`personagem_lib.gd`, `_capture_call_6b2`): rodar numa pasta temporária, com `FC_LUTADOR=disc FC_CAMADAS=1`, os geradores
`make_sprites_jogador.gd`, `make_golpes_jogador.gd`, `make_sprites_fase6b1.gd` e `make_sprites_fase6c1.gd`, e copiar só os
`*_disc_symbol_*.png`. **Conferido: as 490 camadas que já existiam saem idênticas, byte a byte.**

### 26.1 O objeto do mural (garagem e academia)
| Sprite | Quadro | Ponto | Nota |
|---|---|---|---|
| `wall_mural` | 55x23, 4 quadros | `layout.mural_spot` = (176,128) | Moldura de madeira, cortiça escura, papel com o carimbo da escola (`school_symbol_9`) e polaroides presas com alfinete. A 1ª é o John, em sépia; quem saiu por cima tem 1 px de prata no pé da foto. Luz da lâmpada: o lado esquerdo fica 1 passo mais escuro |
| `wall_mural_gym` | 55x23, 4 | `layout.gym_mural_spot` = (176,128) | O mesmo com a luz dos tubos. **Cobre inteiro o quadro de cortiça pintado no `gym_bg`** (178..227, 128..145): o mural da escola toma o lugar do quadro da mensalidade |
- Os dois pontos ficam no formato `[x, y]`; o resto está em `layout.mural_spot_info` / `gym_mural_spot_info` (`click_rect` 54x22, camada `wall`, `object_text` `mural`, marco da academia, regra do quadro).
- Quadro pelo tamanho do roster: 1 entrada → 0 (só o John); 2–3 → 1; 4–7 → 2; 8+ → 3 (10 fotos). Os 55x23 incluem 1 px de sombra na parede (recortada do fundo de cada sala: não mover).
- Conferido nas duas salas, com foco no saco e com o saco de lado: fora da faixa do alvo com folga (273..370), da `no_cover`, do saco de lado (238..278) e da corrente (x 257), da prateleira (até y 127) e do metrônomo; nenhum pixel de gente (Osmar, mentor no caixote, 2º mentor, equipe, lutador) cai dentro dele, e ele não cobre a foto (garagem 237,67; academia 212,158, 8 px abaixo). O balão do Osmar passa por cima, como já passa pela foto da academia (aceito).
- Mockups: `fase6c2_mural_garagem_x2.png`, `fase6c2_mural_academia_x2.png`, `fase6c2_mural_*_conferencia_x3.png`.

### 26.2 Retrato do mural (busto)
- **Recorte:** 28x30 do quadro 0 da `disciple_stand_bare` (48x72, pivô 22,67), em (9,-1): da faixa do coque (1 px de folga em cima) até o meio da barriga, com os ombros. Mostrar em **2x = 56x60**.
- `mural_portrait_disc` traz todas as camadas recortadas (body, top tank/tee, 4 cabeças, faixa, front, `school_symbol.chest`), com a mesma montagem e troca de cor do discípulo. Sem meião (não aparece). John: `mural_portrait_john` (mesmo recorte do `john_step_back` q0, sorrindo). Nenhuma folha nova do Artista foi preciso: o recorte é da pose que já existe.
- Moldura `ui_mural_portrait_frame` 62x66 (furo 56x60 em 3,3) sobre o fundo `ui_mural_portrait_bg`; o John usa `ui_mural_portrait_frame_first` (madeira escura, cantoneiras de latão).
- **Selo "saiu por cima"** `ui_mural_seal` 20x24: roseta prateada com o símbolo da escola e duas fitas azuis, em (48,48) da moldura (sai um pouco para fora, embaixo à direita).
- Conferido com os 4 cortes, 5 peles, faixas e partes de cima: `fase6c2_retratos_x2.png`. Tela: `fase6c2_tela_mural_x2.png` (John + 8, 5x2 por página, selo, "parou em", "?", hall ao lado; o layout final é da UI/UX).

### 26.3 Símbolo da escola na roupa (decisão do ponto aberto 5)
- **Desenho:** o `school_symbol_5` da 6a (a lâmpada de pé com raízes). Não há símbolo novo: o da escola já existe. Em 3/4 é o 5x5 igual; em perfil (luta) e na coxa, a mesma leitura em 3x5.
- **Na luta (perfil) o símbolo vai nas COSTAS** (correção B2 do QA da 6c2): no peito, de perfil, o braço da guarda tapava quase tudo (0 a 2 px por quadro). Agora o 3x5 fica a 2,5 px da borda das costas, na altura da escápula: 12 px (o desenho inteiro) em quase todos os quadros de todas as poses; só some deitado no K.O. de costas e no começo do K.O. (o corpo está sobre ele). Na garagem (3/4) continua no peito. Mockup: `fase6c2_simbolo_luta_x4.png`.
- **Com parte de cima (tank/tee):** no peito, abaixo do decote da regata (assim regata e camiseta dão o mesmo desenho; onde a manga da camiseta tapa 1–2 px, fica só o que as duas mostram).
- **Sem parte de cima: na perna do calção** (coxa da frente), confirmado. No peito nu ele vira tatuagem, e não é isso.
- **No busto:** aparece só o do peito (entra no recorte). Sem parte de cima o símbolo está na coxa e não aparece no retrato.
- **Cor:** uma cor (estampa) em cor-chave (`keys.school_symbol`), trocada pela cor da peça: carimbo azul (b0/b1) em camiseta branca ou amarela e em calção branco ou amarelo; tinta amarela (y0/y1) nas outras. Mapa em `disciple_palette.school_symbol_source`.
- **Camada:** `<base>_disc_symbol_chest.png` e `_symbol_leg.png` em todas as 39 poses em camadas (inclui as `_left` e o retrato 32x32 da luta); `layers.school_symbol` em 139 entradas (todas as luvas). Não depende da luva (conferido: nenhuma luva cobre o peito de outro jeito). Ordem: body, top, socks, **school_symbol**, head, band, front_mask (o passo 6 redesenha o símbolo junto com o "baixo"). O John nunca usa.
- Mockups: `fase6c2_simbolo_x3.png` (6 cores de camiseta, regata, sem parte de cima por calção, sentado, luta), `fase6c2_simbolo_luvas_x4.png`.

### 26.4 Honra e hall
- Cor da Honra: **`col_honor` = st3** (prata/aço; ouro é dinheiro, roxo é Legado, rosa é Fama). `icon_honor` 9x9 e `icon_honor_16` (roseta prateada com fitas azuis: a mesma do selo, pequena). Nunca no HUD da sala.
- `ui_honor_chip` 12x11 (9-slice 3/2/3/2): plaquinha d1 com filete de aço para "HONRA: N" e o custo/estado dos nós.
- Nós do hall, 16x16 + `_gray`: `icon_hall_box` (caixa com a fita soltando), `icon_hall_fund` (lata com moeda), `icon_hall_notes` (caderno azul com lápis), `icon_hall_crew` (três cabeças), `icon_hall_glove` (luva de lona no prego), `icon_hall_wall` (mural com setas para os lados). Prancha: `fase6c2_pecas_x4.png`.

### 26.5 Placeholder / precisa de pixel artist
- As polaroides do mural são 6x7 com uma cabeça de 2 px: à mão, cada foto teria uma pose. O ideal seria o mural mostrar os retratos de verdade em miniatura (código).
- O símbolo em 5x5 no peito lê como "estampa da escola", não como lâmpada; um artista faria a versão de 7x7 para a camiseta e uma de bordado para o calção.
- Sentado (`disciple_sit_rest`) sem parte de cima, a coxa fica atrás dos braços: o símbolo da perna quase some. Aceito.
- O busto é recorte de pose de corpo inteiro (braços caídos). Um retrato feito para o mural (ombro virado, olhar para a câmera, luz de estúdio) pediria uma folha `bust` própria com as mesmas camadas.
- A roseta e os ícones do hall são placeholder honesto; os ícones cinza são conversão por luminância.

## 27. Fase 6d (tela principal maior: o dono escolheu a C; a sala larga vale pelo §28)
Opções A (gavetas), B (HUD mínimo) e C (híbrido, recomendada) em `docs/arte/fase6d-tela-opcoes.md`; mockups
`mockups/fase6d_tela_*.png` (gerador `tools/art/make_mockup_fase6d_tela.gd`). Regra proposta para qualquer opção: a sala de
384x272 **não se move** (alvo em x 281..362); o fundo cresce para 640x360 continuando a mesma perspectiva (ponto de fuga
320,-28), e a UI vira plaquetas flutuantes que nunca encostam na zona do alvo (x 273..370, y 150..291) quando fechadas.
Enquanto o dono não escolher, o §2 (layout com painéis laterais) continua valendo.

## 28. Fase 6d2 (sala larga de verdade, pontos novos, aparelho invisível até a caixa)
Aprovado pelo dono em 2026-11-18. Proposta completa, tabela de pontos e ajustes das cenas: `docs/arte/fase6d2-layout.md`.
Gerador: `tools/art/make_mockup_fase6d2_layout.gd` (pasta temporária com `project.godot` vazio; `-- --final` grava os sprites; parte
sempre dos originais guardados em `tools/art/fonte_6d2/`, então pode rodar de novo). Manifest: `python tools/art/manifest_6d2.py`
(só as chaves desta fase, mantém tab/CRLF; rodar de novo não muda nada). Mockups: `mockups/fase6d2_layout_*.png`.

### 28.1 Geometria nova (substitui a tabela do §4 e o layout do §2 na tela principal)
| Elemento | Valor |
|---|---|
| Sala | tela inteira: `room_rect` = (0,18,640,312); HUD em cima, faixa de 30 px embaixo (y 330), painel da opção C por cima à direita |
| Fundos | `garage_bg` / `gym_bg` 640x360 em (0,0) |
| Parede do fundo | x 70..569, até y 220; **miolo x 171..469 = a sala de antes, pixel a pixel** (nada de parede mudou de lugar) |
| Pilares | x 164..174 e 468..478 (escondem as emendas; a sala lê como 3 vãos) |
| Ponto de fuga | (320,-28), igual |
| Chão | de y 220 até y 329; meia-largura = 250·(y+28)/248 (de y ~289 para baixo cobre a tela toda) |
| Paredes laterais | cunhas x 0..69 e 570..639; altura de um ponto da parede do fundo `yb` na coluna x: −28 + (yb+28)·|320−x|/250 |
| Alvo | **igual**: lutador (303,272), saco (336,183), zona protegida x 273..370, y 150..291 |
| Painel fixado | cobre x 506..639: ali só decoração e quem não decide nada (vizinho 3, Prof. Nelson, 28 px da esteira) |

Fileiras: fundo (pés y 236..262), alvo (272), frente (pés y 318..327). Fundo e frente não se tocam: é isso que dá espaço.

### 28.2 Peças novas e refeitas
- **Garagem:** janela basculante e cano (parede esquerda), chapa de ferramentas + bancada com morsa, caixa de ferramentas, balde e
  aro (ala esquerda), geladeira velha, pilha de pneus, relógio de luz, mangueira (ala direita), escada de alumínio (parede direita),
  juntas e manchas no chão novo. Luz: a lâmpada de sempre + janela (34,176) + luminária de obra (540,70).
- **Academia:** 2 janelas altas (parede esquerda), quadro branco da semana, suporte de halteres, kettlebell, medicine ball (ala
  esquerda), 3 armários, bebedouro, árvore de anilhas (ala direita), espaldar (parede direita), piso em xadrez em toda a largura e
  tatame na frente à esquerda. 2 tubos novos pintados no fundo (x 104 e 536); o `gym_tube` continua só nos 2 de sempre.
- **Refeitas sobre o chão novo** (mesmos passos de luz por pixel): `garage_daylight` (170x**90**), `garage_door_shadow`,
  `gym_daylight` (146x**90**; os quadros cheios continuam 20 px abaixo de y 289, esmaecendo), `gym_door` (as linhas de chão),
  `gym_half_dark` (agora **640x360 em 0,0**, furo na porta).
- **Luz refeita para o ponto novo:** `treadmill_l0|l1_side(_gym)`, `grappling_dummy_l0|l1_rest_gym`
  (`grappling_dummy_*_rest` da garagem e `garage_crate_gym` passaram pela mesma conta e saíram iguais; `garage_crate` não tem luz).

### 28.3 Pontos
Tabela completa em `fase6d2-layout.md` §4. Resumo: Osmar, foto, mural, saco de lado, gancho da corda e pera na parede **iguais**;
John/último sentado (132,254) com caixote em (116,234); 2º mentor (62,256); vizinhos (72,322), (126,322), (590,322); tios (400,324),
(484,262); Prof. Nelson (548,250); esteira encostada (466,324); boneco deitado (192,318); caixas: esteira (466,324), arte (192,318),
luva (292,327), corda (348,327); bolsa do John (146,244). Conferido pixel a pixel: 0 sobreposições, nada na zona do alvo nem no caminho
da porta, balão do Osmar livre.

### 28.4 Aparelho não comprado = invisível
Antes de comprar: **nada** na sala. Comprado: **só a caixa**. Caixa aberta: o aparelho (chegadas de sempre). Nos 4 `unlock_*` saíram
`floor_mark`, `ghost`, `ghost_dim`, `mark_states`, `mark_pos`, `lock`, `lock_pos`, `sign` e `mark_note_fase51`; entrou
`room_before_box: "nothing"`. `tape_mark_*`, `ghost_*` e `mark_padlock` ficam no projeto com `unused_since: "6d2"`. O "dá para
comprar" mora só na faixa de focos e no painel. **Isto substitui o §16 (marca de fita) e o §18.3.**

### 28.5 Placeholder / precisa de pixel artist
- Os fundos são montagem por código; os pilares existem para esconder a emenda com a sala antiga. À mão, cada fundo seria pintado inteiro.
- As pessoas (vizinhos, tios, Prof. Nelson) ainda têm a luz pintada dos pontos antigos: pedido de folhas novas ao Artista de Personagens.

## 29. Fase 6d3 (garagem: carro, pneus, geladeira; sem escada e sem ralo)
Pedido do dono depois de testar a garagem da 6d2. Prancha: `mockups/fase6d3_garagem_antes_depois.png`; sala montada:
`mockups/fase6d3_garagem_cheia.png` e `_pequena.png`. Quem desenha é o mesmo gerador da 6d2
(`tools/art/make_mockup_fase6d2_layout.gd -- --final`: funções `garage_car`, `car_wheel`, `tire_stack`, `tire_standing`, `fridge`);
a prancha sai de `tools/art/make_mockup_fase6d3_garagem.gd` (ordem dos passos no topo do arquivo); nota do manifest:
`python tools/art/manifest_6d3.py`. A luz do dia e a sombra da porta saíram iguais (conferido).

- **Carro:** era um carrinho de 96x50 colado do fundo antigo, sem roda nem janela legível. Agora é um **sedã velho de lado**,
  frente para a esquerda, x 69..194, y 167..229 (126x58: altura do ombro de um adulto, ~2 pessoas de comprimento). Lê como carro
  pela silhueta de 3 volumes, rodas com calota e caixa de roda escura, vidros escuros com reflexo em diagonal, farol, pisca,
  lanterna na traseira (a face virada para o centro, que a perspectiva mostra), para-choques cromados, friso, portas e maçanetas,
  retrovisor e antena. Personalidade: azul desbotado, ferrugem no estribo, pneu de trás meio murcho. **Lona** cinza-azulada (rampa
  `st`, a cor e o caimento da lona da 6d2, pedido do dono) cobrindo a metade de trás: teto de trás, vidro de trás e porta-malas,
  caindo até o alto da roda de trás; borda da frente em diagonal com rolo claro, dobras verticais, barra ondulada, corda amarrada.
  A frente (farol, roda, para-choque, porta) fica à mostra. Lona marrom ou verde não funciona (lê como madeira/lixeira).
  Prancha: `mockups/fase6d3_carro_lona.png`. Pintado no fundo: fica atrás de todo mundo; o Osmar continua "encostado no carro" e o John no caixote na frente dele. Longe da zona do alvo (x 273..370).
  A **bancada** saiu (ficava inteira atrás do carro e virava ruído); a chapa de ferramentas fica na parede, acima do capô.
- **Pneus:** cilindros vistos um pouco de cima (ponto de fuga em y −28): banda com ranhuras em zigue-zague (mais juntas nas bordas),
  brilho `g0/g1` em cima vindo da luminária, linha `ink` de contato entre um e outro, pneus desencontrados 1 px, o de cima com a
  face e o furo à mostra; mais um **em pé com roda de aço** encostado na pilha.
- **Geladeira:** lado esquerdo e tampo à mostra (está à direita do ponto de fuga), cantos de cima arredondados, porta do congelador
  separada, puxadores de alavanca cromados, plaquinha da marca, bilhete com ímã, foto com ímã, 2 ímãs soltos, ferrugem embaixo, grade
  do rodapé, pés, e um **rádio de madeira** com antena torta em cima. Continua em x 483..517, y 136..221.
- **Escada:** tirada; a parede direita fica limpa (atrás do painel fixado, de qualquer jeito).
- **"Retângulo preto solto":** era o **ralo** do chão (14x5 em 388,290, grade `ink` sobre `d2`). Em 1x e no chão escuro não lia
  como ralo; foi tirado.
- **Pontos:** nenhum ponto do manifest mudou (pessoas, aparelhos, caixas, parede). O verificador de pontos do gerador: 0 problemas.

### 29.1 Varredura de arte (todas as telas)
Lista priorizada e o que ficou para o UI/UX e para depois: `docs/arte/fase6d3-varredura.md`. Pranchas:
`mockups/fase6d3_varredura_antes_depois.png` e `_detalhes.png` (`tools/art/make_mockup_fase6d3_varredura.gd`).
Peças refeitas por `tools/art/make_arte_fase6d3.gd` (parte dos originais em `tools/art/fonte_6d3/`):
- `wall_school_symbol`: o símbolo da escola pintado deixa de ser a lâmpada amarela viva com raízes marrons (lia como borrão
  aceso) e vira **emblema a estêncil na tinta azul da escola** (`b1/b2`), lâmpada creme dentro do disco, raízes para fora.
  **Regra:** símbolo pintado em parede = uma cor de tinta + o creme, nunca amarelo de luz (amarelo vivo na sala = coisa acesa).
- `lamp`: sem o anel de pontinhos; brilho de lâmpada pequena é **dither de 1 passo no fundo**, nunca anel tracejado solto.
- `arena_bg`: manchas redondas viraram ferrugem escorrendo pela chapa; "07" limpo; lâmpadas pequenas com brilho em dither.
- `gym_bg` (`gym_fix_6d3` no gerador da 6d2): nome inteiro (BOA lia BOR); espelho limpo com uma trinca curta no canto.
- `garage_bg`: além do §29, sem círculo de giz, mancha de óleo sem miolo chapado.
**Regra geral da varredura:** mancha/borrão só se tiver forma que se explique (escorrido, rastro, sombra de objeto); textura
aleatória redonda não entra. Nada chapado em `ink`/`d1` solto no chão (lê como buraco).

Placeholder / precisa de pixel artist: o carro é montado por linhas e elipses; à mão ele ganharia volume de
verdade nos para-lamas, reflexo da lâmpada na lataria e uma lona com peso. Os pneus pediriam ranhura desenhada à mão.

### 29.2 Símbolo da escola: R de raiz (aprovado)
O dono recusou a lâmpada com raízes e, das 5 propostas (`mockups/fase6d3_simbolo_opcoes.png`, `docs/arte/fase6d3-simbolo.md`),
**aprovou a D: um R de traço grosso cujas pernas viram raízes.** Aplicado em tudo por `tools/art/make_arte_fase6d3_simbolo.gd`
(originais em `tools/art/fonte_6d3/simbolo/`; ordem dos geradores no topo do arquivo). Prancha: `mockups/fase6d3_simbolo_aplicado.png`.
- `ui/school_symbol_5/9/16/32`: desenhados à mão em cada tamanho (o 32 é o 16 em 2x), azul de carimbo `b1` + realce `b2`.
- Parede da garagem salva (`wall_school_symbol` 32x40 em 344,38): o 16 em 2x, tinta `b1` com realce creme, 2 escorridos.
- Peito/coxa do discípulo (camada `school_symbol`, 76 folhas + `fighter_rope` + busto do mural): 3/4 = o 5x5; perfil e coxa = R 3x5
  (`personagem_lib.gd`, `SYMBOL`). **O R não é simétrico:** nas folhas viradas (`_left`, `capture_flip_last`) o carimbo é desvirado
  no lugar depois da captura (50 carimbos). Regra: símbolo de escola que não for simétrico precisa desse passo.
- Selo do mural (`ui_mural_seal`), plaquinha do mural (`wall_mural`, `wall_mural_gym`), etiqueta das caixas (`box_big` 9x9,
  `box_small` 5x5) e o carimbo redondo do selo GARAGEM SALVA (`seal_garage_saved`, `_text`, R 16 com falhas de tinta).
- Cuidado: o R dentro do carimbo redondo lembra o símbolo de marca registrada (®). Pequeno e com as raízes, passa; à mão,
  dá para deixar as raízes saírem do anel para afastar essa leitura.

### 29.3 Ninguém na frente do carro (bug B1 do QA)
O carro maior ficava atrás do Osmar e do John sentado. Correção (garagem só; a academia não muda):
- O carro encolheu 36 px no miolo das portas (`car_squeeze`: frente, rodas, traseira e lona inteiras) e foi 11 px para a esquerda:
  **x 69..194** (126x58).
- Pontos da garagem que mudaram (manifest; o verificador do gerador agora acusa qualquer um na frente do carro):
  Osmar `coach_point`/`original_trainer` **196,236 -> 52,258** (encostado na frente do carro); mentor sentado `mentor_spot`
  **132,254 -> 210,254**, caixote **116,234 -> 194,234** (logo atrás do carro, perto do saco, como era antes da 6d2);
  2º mentor `mentor_2_spot` **62,256 -> 26,304** (canto da frente à esquerda). `primeira_sucessao.json`: o Osmar da cena lê o
  ponto da sala (`from_room: coach`). `validar_cenas`: 0 erros (a 1ª tentativa, com o caixote à esquerda, deixava o recuo do
  John longo demais e a cena passava de 16 s; a 2ª, com ele logo atrás do carro em 221, deixava a cabeça dele onde o balão
  do lutador precisa ficar).
- A luz pintada nas folhas do Osmar e do John sentado ainda é a dos pontos antigos (diferença pequena): pedir folhas novas ao
  Artista de Personagens quando houver rodada de personagens.
- **7b (pedido do dono): o sedã comprido volta.** Sem `car_squeeze` (`CAR_CUTS = []`), 14 px para a esquerda: **x 66..226**
  (~160 px, 2 portas). A lona volta ao estilo da 6d2: cinza-ardósia fosco (rampa `st`), cúpula arredondada com brilho
  pontilhado, faixa clara no ombro, dobras verticais onduladas, barra escura e corda laranja com nó; cobre a metade de trás
  (teto e vidro de trás, porta-malas, traseira) até o alto da roda de trás, que aparece no arco. Único ponto mexido: mentor
  sentado `mentor_spot` **210,254 -> 232,270**, caixote **194,234 -> 216,250** (sort 266); mais à direita a cabeça bate no saco
  de lado. Osmar e 2º mentor não mudam. Manifest: `tools/art/manifest_7b.py`. Prancha: `mockups/fase7b_carro_comprido.png`.
- Também trocados para o R: `icon_garage_saved` (linha de prêmio GARAGEM SALVA) e `icon_honor_16` (roseta da Honra).

## 30. Fase 7a1 (arena da liga, FINALIZOU! e HUD da passiva)
Gerador: `tools/art/make_arte_fase7a1.gd` (rodar como no §29, de uma pasta com `project.godot` vazio; `-- --assets <pasta>`
grava fora do projeto, `-- --debug <pasta>` grava as cenas montadas em 2x). Manifest: `python tools/art/manifest_7a1.py`
(só acrescenta as chaves da 7a1; lê o arquivo na hora de gravar).

**Arena da liga da academia** (`arena_league_bg` / `_crowd_back` / `_crowd_front`, mesmo contrato e mesmas posições da borracharia;
**sem `_lamp`**, é de dia). Duas opções em `mockups/fase7a1_arena_A.png` e `_B.png` (em pé com K.O. / deitados com FINALIZOU!):
- **A (recomendada, aplicada): quadra coberta do bairro, sábado de manhã.** Treliça do telhado em contraluz, janelões basculantes
  com sol entrando em faixas de dither pela esquerda, placar "LIGA", faixa da liga, arquibancada de concreto com gente sentada
  (menos gente no meio, onde passa o letreiro), mureta com placas de patrocinador da vizinhança (inclui a BOA ESQUINA), quadra de
  madeira com linhas de outros esportes e o **tatame oficial azul com borda vermelha** no meio. Mesa dos juízes com sino à esquerda,
  banco do corner à direita, fora do centro. Lê como degrau acima: lugar público, organizado, com plateia sentada e regra.
- **B: salão do clube do bairro, sábado à tarde.** Lambri, bandeirinhas, ventiladores, palco com cortina vinho e mesa de troféus,
  janelas com grade, cadeiras de plástico empilhadas, chão de taco em cesto e tatame de EVA azul e verde. Mais aconchegante, lê
  menos como "competição".
- Regras que as duas cumprem: y 0..45 em `ink` liso (o gerador confere: 0 px fora); pés em y 318 sobre o tatame (topo y 272,
  base x 112..528 em y 350, lados no ponto de fuga 320,-28); x ~200..440 sem objeto na frente dos pés (cabem os dois deitados);
  o público da frente só nos cantos (x 0..137 e 503..640). Mais clara que a borracharia, mas o miolo atrás do letreiro é escuro
  (placar) ou de meio-tom; o contorno `ink` dos letreiros resolve o resto (prancha `mockups/fase7a1_hud_icones_x4.png`).
- **Aprovada pelo dono: opção A.** Faixa com o nome do Roteirista, **GINÁSIO ALVORADA** (`const FAIXA` no gerador; faixa de 24 px
  para o acento do Á não encostar na barra, pendurada na frente do corrimão).
- Público de dia: roupa colorida, luz da janela na borda esquerda, crianças na frente, bandeirinhas azuis no "cheer".

**Letreiro FINALIZOU!** (`ui_banner_submission`, 161x40, pivô 80,20): mesma receita do `ui_banner_ko` (amarelo y1 em cima / y0
embaixo, contorno `ink`, sombra de 1 px de fonte), com a **sombra azul b1** (cor do Jiu-jitsu) em vez da vermelha. Fonte 3x
(o K.O.! é 4x) para caber: ampliado 2x no jogo dá 322 px. Lê nas três arenas.

**HUD da passiva** (posição final é do UI/UX):
- Embalo (Boxe): `ui_streak_pip` 7x7, 3 quadros (apagada `d2` / acesa vermelho do Boxe / acendendo clarão). 5 com passo 9 px.
- CANSADO: `icon_tired` 9x9 (gota de suor azul) ao lado do texto.
- Pegada (Jiu-jitsu, azul): `ui_grip_bar` (moldura 9-slice 8x6), `ui_grip_fill` (4x4 repetido, 2 quadros: enchendo / cheia para
  piscar com "PEGADA!"), `ui_grip_tick` (1x4, marcas de round em 1/3 e 2/3), `ui_grip_mark` (setinha 7x5 "enche aqui" na prévia),
  `icon_grip` 9x9 (mão fechando na gola).

**Placeholder / precisa de pixel artist:** a plateia é feita de blocos (rosto, braço e roupa à mão dariam vida), a arquibancada e
a treliça são repetição pura, as placas de patrocinador pediriam logotipos desenhados, e o tatame pediria textura e desgaste.
O letreiro e os ícones podem ficar com retoque.

## 31. Fase 7a2 (Treino fora de hora: Choque, Panfletagem, AQUECIDO e o recorte do vulto)
Gerador: `tools/art/make_arte_fase7a2.gd` (de uma pasta com `project.godot` vazio; `-- --no-assets` grava só os mockups,
`-- --assets <pasta>` grava fora do projeto). Manifest: `python tools/art/manifest_7a2.py` (só as chaves da 7a2; lê o arquivo na
hora; também registra as folhas do Artista de Personagens se existir `docs/arte/fase7a2-personagens-manifest.md`, formato da 7a1).
Contrato das telas em `manifest.json → minigame_layout` (o mesmo das constantes no topo do gerador: mudar nos dois).

**Mockups:** `mockups/fase7a2_choque_boxe.png` (aviso de RAJADA), `fase7a2_choque_jj.png` (PUXADA, fôlego no fim),
`fase7a2_choque_estados_x3.png` (normal, rajada, pausa com X2, finta, ENCOSTOU!, afobado), `fase7a2_panfletagem.png`,
`fase7a2_recorte_x3.png`, `fase7a2_convite_x2.png` (balão com IR + AQUECIDO na prévia/HUD) e `fase7a2_pecas_x4.png`.
Nos mockups os personagens são folhas que já existem (medida e leitura); as poses do Choque, os pedestres e o lutador
entregando são do Artista de Personagens.

### 31.1 Choque: fundos da academia depois do expediente (`minigame/spar_bg`)
- Parede de trás da Boa Esquina (reboco creme gasto + barrado verde, a cor de dentro vista de fora), porta dos FUNDOS aberta e
  acesa, janela gradeada, ar-condicionado pingando, relógio de luz; à direita o alambrado da praça com árvores; poste com braço
  iluminando um **tatame de EVA velho** (azul e verde, gasto no meio) no chão de cimento. Tralha só nos cantos (latão, pneu de
  trator, caixotes, caixote com garrafa e toalha). Lua pequena e fria; a luz que manda é a do poste.
- **Pés em y 318, lutador x 296 e parceiro x 346** (iguais à luta: as poses do Artista podem sair do mesmo quadro 112x104).
  O **Osmar fica lá atrás, na porta (150,262)**, em escala da sala: a perspectiva explica o tamanho menor e ele não disputa com a dupla.
- **y 0..71 = céu escuro** (o HUD fica ali). Centro x 200..440 sem objeto na frente.

### 31.2 HUD do Choque
| Peça | Regra |
|---|---|
| `ui_tug_track` 260x16 | Esquerda = **você (azul)**, direita = **ele (vermelho)**; cada ponta é a "parede". Marcador de x 8 (−1) a 251 (+1). Ganhar = empurrar a agulha até a parede dele (vale para Boxe e JJ) |
| `ui_tug_marker` 11x22, 3 quadros | Agulha ouro (cabeça em triângulo, haste atravessando a barra). 1 = clique (claro, 1 quadro), 2 = contragolpe valendo |
| `ui_tug_touch` 24x24, 3 | Estalo do ENCOSTOU! na ponta |
| `ui_point_pip` 7x7, 3 | Pontos: vazia / seu (ouro) / dele (vermelho); meta 3 |
| `ui_breath_bar` + `ui_breath_fill` + `icon_breath` | Fôlego só seu: verde > 50%, amarelo 25–50%, **vermelho < 25%** (a força já caiu: é o aviso do "afobado") |
| `ui_warn_burst` 17x17, 2 | RAJADA/PUXADA: **estrela pontuda vermelha, ! branco**, acima da cabeça do parceiro |
| `ui_warn_pause` 17x17, 2 | ELE ABRIU: **balão redondo branco, ! escuro**. Forma e cor mudam juntas: lê sem depender de cor |
| `ui_warn_feint` 17x17, 3 | Finta: 0 rajada → 1 meio → 2 pausa, trocando na metade do aviso |
| `ui_counter_x2` 19x13, 2 | X2 em cima da agulha enquanto a pausa vale |
- O aviso fica **no corpo do parceiro** (acima da cabeça), não na barra: o jogador aprende a olhar o ombro dele.
- Texto do aviso (RAJADA!, PUXADA!, ELE ABRIU!) com contorno ink, 10 px acima do ícone.

### 31.3 Panfletagem: a rua do bairro (`minigame/flyers_bg`)
- Mesma noite: muro com lambe-lambes e o **cartaz da escola** (R de raiz, RAÍZES, faixa AULA) em (26,168), padaria fechada com
  "ALUGA", **LANCHES DA NENA** aceso (a luz quente na calçada), casa 27 com portão, ponto de ônibus. Dois postes (x 104 e 494);
  no da esquerda, um lambe-lambe pequeno da escola, perto do lutador.
- **Pedestres com pés em y 300** atravessando a tela inteira na frente das fachadas (fundo de meio-tom: a silhueta com contorno
  ink lê bem); **lutador na frente à esquerda (70,324)**, **Osmar no canto direito (604,326)**. Tudo em escala da sala (~64 px):
  as folhas de pedestre podem nascer das folhas de vizinhos e tios.
- Peças: `ui_tell_mark` (? do sinal, 3 quadros; o sinal falso some em dither), `ui_flyer_fly` (panfleto voando), `icon_flyer`
  (contador), `icon_flyers_16`. ACEITOU! em `gr3`, NÃO, VALEU em `g3`, os dois com contorno ink acima da pessoa.

### 31.4 Convite, AQUECIDO e prêmio
- Balão do convite = o `ui_balloon` de sempre com a etiqueta ouro do Osmar e o botão **`ui_invite_go`** (9-slice 14x13, ouro
  `y0`, texto IR em ink) à direita do texto, na 2ª linha. Sem ícone dentro do balão (fica pequeno, como pede o design).
- **AQUECIDO = chama laranja de miolo claro** (`icon_warm` 9x9 na prévia e ao lado do risco; `icon_warm_16` no prêmio).
  Não é vermelho de Força nem roxo de arte: é "corpo quente", vale para todos os atributos.
- `icon_spar_16` (luva vermelha x luva azul) e `icon_flyers_16` (maço com o R) para a tela de prêmio.

### 31.5 Recorte de jornal do vulto (semente do Gato Preto)
| Sprite | Ponto | Onde |
|---|---|---|
| `wall_clipping_black_cat` 23x28 | `clipping_spot` (304,100) | garagem: à direita do pôster SOCO, embaixo da lâmpada |
| `wall_clipping_black_cat_gym` 23x28 | `gym_clipping_spot` (340,60) | academia: entre o espelho e o relógio de rounds |
- **Manchete VULTO legível em 1x** (fonte 3x5 só deste objeto), foto granulada com a silhueta, colunas, borda picotada e fita.
  A frase inteira vai no hover (`black_cat_clipping`). O nome "Gato Preto" não aparece nesta fase (Roteirista).
- **O vigilante (original):** capuz preto com **orelhas de gato costuradas** (triângulos largos nas quinas da cabeça, com
  ponto de costura), **faixa da escola amarrada nos olhos** com as duas pontas voando para o lado, **capa de lona caindo reta**
  até o telhado, com remendo. Regras para nunca lembrar o morcego: capa **nunca aberta em asa**, orelhas **largas e baixas**
  (não chifres finos e altos), nada de símbolo no peito, nada de cinto de utilidades. A faixa voando é a marca dele.
- `ui_clipping_black_cat_zoom` 100x84 (opcional): o recorte grande para a dica, CORREIO DA ESQUINA / VULTO MASCARADO.
- Conferido no gerador (0 problemas): fora da parede da memória, das correntes (x 257 e 335), da lâmpada, do metrônomo, do
  letreiro, do relógio, do Osmar, da foto, do mural e da zona do alvo.

### 31.6 Placeholder / precisa de pixel artist
- Os dois cenários são montagem por código (blocos, elipses, dither). À mão: tijolo e reboco com textura de verdade, alambrado
  com perspectiva, árvores com folhagem, fachadas com mais história (placas, fios, pichação com forma), luz do poste com cone.
- A silhueta do vigilante tem 7x8 px no recorte e 18x19 no zoom: o desenho dele de verdade (folha de personagem) é do Artista
  de Personagens quando o Gato Preto ganhar fase.
- A agulha, os avisos e o X2 são peças honestas de placeholder; um artista faria a agulha como um nó de corda ou uma luva.

## 32. Fase 7b1 (Muay Thai: saco comprido, marcas na perna, CHUTE RODADO!, região da árvore)
Gerador: `tools/art/make_arte_fase7b1.gd` (`godot --headless --path <projeto> --script res://tools/art/make_arte_fase7b1.gd`;
`-- --no-assets` grava só os mockups). Manifest: `python tools/art/manifest_7b1.py` (lê `tools/art/fase7b1_sprites.json`, que o
gerador grava; só acrescenta as chaves da 7b1; rodar de novo não muda nada). Textos dos letreiros = finais do Roteirista
(`fase7b1-textos.md`): `BANNER_TEXT` e `MARKS_TEXT` no topo do gerador.

**Cor do Muay Thai: laranja de couro** (`br1/br2/br3`, brilho `y0`). Boxe é vermelho, Jiu-jitsu azul, Campanha ouro (`y0/y1`):
o anel do mapa usa `br2/br3` (tom `orange`) para não confundir com o ouro.

**Saco comprido de chute** (`kick_bag`, mesmo padrão da pera e do boneco):
- Silhueta oposta à do saco de pancada: **fino e comprido** (corpo 22x68 contra 30x62), **pendurado baixo**. Foco:
  `kick_bag_lN_idle/hit` (quadro 34x80, pivô 17,0 no gancho) em **(336,190)**, corrente `bag_chain_tile` de y 33; corpo em y 200..267,
  4 px acima do chão do lutador. Ordenar como y 266 (o lutador em 303,272 fica na frente). Clique: o pé do saco vai 5 px e afunda
  na altura da canela, 4 quadros a 12 fps. A lona é **gasta na altura da canela** (y 244..260): é ali que se chuta.
- Descanso: `kick_bag_lN_rest(_gym)` (80x28, pivô 40,25), **deitado de lado no canto da frente à esquerda (192,318)**, o slot `art`
  da caixa e o mesmo lugar do boneco (só existe o aparelho da arte da carreira). Tiras e corrente enrolada à esquerda. Luz pintada
  (garagem: as 3 luzes da 6d2; academia: os 4 tubos). Conferido com os vizinhos (72,322) e (126,322): não encosta.
- l0 = lona cor de couro cru, cintas creme, remendo de fita prata ("veio enrolado num tapete"); l1 (`tech_mt_1` Chute baixo) =
  vinil preto com faixas laranja e as 3 marquinhas. Chega na **caixa grande** (`box_big`, slot `art`), cai deitado como o boneco.
- O lutador usa `fighter_punch` até o Artista de Personagens fazer a pose de chute baixo no saco: contato da canela em **(326,250)**.
- UI: `icon_kick_bag` (+ `_locked`, `_locked_buyable`), `art_muay_thai` (perna no chute de frente, calção laranja, faixa no
  tornozelo; 16 e `_9`), `art_card_muay_thai` (72x56), `ui_art_card_header_muay_thai`.

**HUD da passiva (Canela):** `ui_shin_mark` 11x11, 4 quadros (apagada / acesa / acendendo / cheia), 3 com passo 12 px ao lado da
vida **dele**; `icon_shin` 9x9 para a prévia e o motivo; `ui_banner_marks_full` (PERNA CHEIA!, fonte 2x) para piscar com as
marcas cheias. `by_data_id.shin_hud` tem a regra. Posição final é do UI/UX.

**Letreiro CHUTE RODADO!** (`ui_banner_spin_kick`, pivô no meio, y 20): receita do K.O.!/FINALIZOU! com **sombra laranja `br1`**,
fonte 3x; em 2x no jogo dá ~430 px em (320,118). Lê nas duas arenas (`mockups/fase7b1_chute_rodado_alcance.png`).

**Conferência do chute rodado entre os pivôs (296/346):** lutador com 80 px, quadril em (296,278), perna ~40 px; queixo do Tonhão
(×1,04) em (340,243): **56 px do quadril**. Parado no pivô, a perna esticada + 6 px de quadril (46 px) **alcança a costela e o
ombro, não o queixo**. Para o rodado no rosto, o Artista desenha o giro com **um passo de ~10 px para a frente dentro do quadro**
(o pé de apoio gira e avança; o pivô não muda). Tudo cabe no quadro 112x104: o pé chega a x ~340 (pivô +44; o quadro vai até +56)
e a y ~243 (pivô −75; o quadro vai até −98). Nada da arena atrapalha: x 200..440 é livre nas duas e o público da frente fica nos
cantos. Os pivôs não mudam; o passo volta no fim do golpe (ou fica, se derrubar).

**Árvore:** região MUAY THAI = **corda de cânhamo trançada** (`map_tile_muay_thai`), anel `orange`
(`map_node_s|b_owned_orange`), plaquinha `ui_map_region_label_muay_thai`, `icon_region_muay_thai(_9)` (o mongkol, cordão
trançado da cabeça). Nós: `skill_style_muay_thai` (Canela de ferro: canela de aço estalando), `skill_shin_kick` (Chute na coxa:
perna dele com 3 marcas), `skill_thai_oil` (frasco âmbar), `skill_thai_rope` (corda sob o pé na ponta). `icon_by_node` manda sobre o
campo `icon` do `skill_tree.json`. Falta no código: `ui/janela_mapa.gd` lista os ladrilhos na mão; precisa ganhar `muay_thai`.

**Mockups:** `fase7b1_saco_sala.png` (garagem e academia: foco, descanso, caixa), `fase7b1_saco_zoom.png` (zoom + quadros),
`fase7b1_pecas_x4.png` (ícones, marcas, cartão, PERNA CHEIA!, nós no chão de corda), `fase7b1_chute_rodado_alcance.png`.

**Placeholder / precisa de pixel artist:** o saco é um cilindro com cisalhamento (balanço sem volume de verdade); à mão teria
couro amassando e a corrente reagindo. O ícone da arte em 9 px e a corda do `skill_thai_rope` são os menos imediatos. As marcas
na perna leem como "botinha" em 11 px: um artista faria a canela com o roxo do hematoma mais claro. Tamanhos fixos para trocar só
os arquivos.

## 33. Fase 7b2 (2ª passiva: cadeado e meta no cartão, ícones, carga do Contragolpista, letreiros)
Gerador: `tools/art/make_arte_fase7b2.gd` (`godot --headless --path <projeto> --script res://tools/art/make_arte_fase7b2.gd`;
`-- --no-assets` grava só os mockups). Manifest: `python tools/art/manifest_7b2.py` (lê `tools/art/fase7b2_sprites.json`; só
acrescenta as chaves da 7b2; rodar de novo não muda nada). Lista completa, tamanhos e onde a UI usa: `docs/arte/fase7b2-manifest.md`.
Textos = Roteirista (`fase7b2-textos.md`): constantes `TXT_*` no topo do gerador.

**Regra de leitura (critério 10):** cada peça da 2ª passiva tem **forma** diferente da peça da 1ª, não só cor.
| Arte | 1ª passiva | 2ª passiva |
|---|---|---|
| Boxe | bolinha redonda 7x7 (embalo), letreiro K.O.! | **losango 9x9** (carga 0–3), ícone luva em guarda alta + seta em L que volta, letreiro **K.O. NO CONTRAGOLPE!** |
| Jiu-jitsu | barra da pegada + mão na gola, FINALIZOU! | ícone **seta azul pressionando quem está deitado no tatame**, letreiro **O JUIZ PAROU!** |
| Muay Thai | canela marcada, CHUTE RODADO! | ícone **braços fechando atrás da nuca + joelho subindo**, letreiro **JOELHADA!** |
A cor continua a da arte (Boxe vermelho, Jiu-jitsu azul, Muay Thai laranja de couro); a meta usa **ouro** (é recompensa, como o
cadeado "dá para comprar" da loja).

**Cartão da arte, 2ª opção** (mockup de sugestão `mockups/fase7b2_cartao_x2.png`; layout final é do UI/UX):
- Trancada: `passive_<tipo>_locked` (16x16, cinza + cadeado no canto), nome em `g1`, linha `{n}/{m} {fim}` em `y1` (texto da
  fonte do tema, não imagem), barra da meta embaixo e `ui_passive_lock` (quadro 0) à direita.
- Barra: `ui_passive_progress_bar` (9-slice 8x6, a medida da `ui_grip_bar`) + `ui_passive_progress_fill` (4x4 repetido; quadro 1
  quando n ≥ m) + `ui_passive_progress_tick` (1x4 em cada 1/m). **Ou** as estrelas `ui_passive_goal_pip` (7x7, passo 9) quando
  m ≤ 5. As duas valem para qualquer m (o gerador não fixa 3).
- Meta batida: cadeado 0 → 1 (clarão, 1 quadro) → 2 (aberto, ouro) e some; o ícone vira o colorido.

**Carga do Contragolpista:** `ui_charge_pip` 9x9, 4 quadros (vazia / carregada: borda `r2` e miolo ouro / acendendo / cheia:
contorno `r2`, piscar 1/3 a 6 fps com `ui_banner_charge_full` CARGA!). 3 com passo 11 px ao lado da **sua** vida (a canela
fica ao lado da dele). `icon_charge` 9x9 para a prévia e o motivo.

**Letreiros:** receita do K.O.!/FINALIZOU!/CHUTE RODADO! (amarelo `y1` em cima / `y0` embaixo, contorno `ink`, sombra de fonte
na cor da arte: `r1` / `b1` / `br1`), fonte 3x, 2x no jogo em (320,118), pivô no meio. Texto mais largo que 300 px em 1x quebra
sozinho em 2 linhas no espaço mais perto do meio: K.O. NO CONTRAGOLPE! sai em "K.O. NO / CONTRAGOLPE!" (209x68 → 418x136 em
2x, y 50..186: não cobre o HUD nem as cabeças). Pequenos (fonte 2x, família do PERNA CHEIA!): CARGA!, LEVANTOU, CLINCH! —
opcionais, o UI/UX pode usar texto. Conferido nas duas arenas: `mockups/fase7b2_letreiros.png`.

**Animação:** nada novo. A guarda alta do Contragolpista é a pose `block` que já existe (a opcional "guarda alta" do Artista
de Personagens ficou de fora: não seria barata sem refazer o idle do boxeador nas 5 luvas).

**Mockups:** `fase7b2_pecas_x4.png` (todas as peças em 4x, lado a lado com as da 1ª), `fase7b2_cartao_x2.png`, `fase7b2_letreiros.png`.

**Placeholder / precisa de pixel artist:** o ícone do Clinch em 16 px é o mais fraco (os braços em volta da cabeça leem como
capuz de longe; à mão, de perfil, com os dois corpos colados, ficaria claro); o do Por cima pede o lutador de cima visível,
não só a seta. Cadeado, estrelas, barra e losango são peças de UI honestas e podem ficar. Tamanhos fixos para trocar só os arquivos.

## 34. Fase 8a1 (Liga Regional do Vale: arena com ringue, cartaz, Cinturão do Vale, passivas dos adversários)
Gerador: `tools/art/make_arte_fase8a1.gd` (`godot --headless --path <projeto> --script res://tools/art/make_arte_fase8a1.gd`;
`-- --no-assets` grava só os mockups). Manifest: `python tools/art/manifest_8a1.py` (lê `tools/art/fase8a1_sprites.json`; só
acrescenta as chaves da 8a1; rodar de novo não muda nada). Lista completa, tamanhos e onde a UI usa: `docs/arte/fase8a1-manifest.md`.
Textos = Roteirista (`fase8a1-textos.md`): constantes `TXT_*` no topo do gerador.

**Arena regional `arena_regional` = CLUBE FERROVIÁRIO, à noite.** Degrau acima do Ginásio Alvorada: de dia/tatame/bairro vira
noite/ringue/TV. Mesmo contrato e mesma câmera das outras arenas (y 0..45 ink liso, pés em y 318, pivôs 296/346, chão livre
x 200..440, público da frente só nos cantos, ponto de fuga 320,-28).
- Fundo: ginásio de clube antigo de ferroviários. Tijolo, janelas altas em arco (noite lá fora), **nome do clube pintado e
  descascado** com a roda alada dos dois lados, **relógio de estação** à esquerda, placa **AO VIVO** à direita, galeria com
  bandeiras da torcida, arquibancada de madeira com gente sentada, treliça com 4 refletores e a **faixa LIGA REGIONAL DO VALE**
  pendurada nela (no alto, para o letreiro do meio não cobri-la inteira), **câmera da TV VALE** num praticável à direita,
  mesa dos juízes com sino e microfone à esquerda, banco do corner à direita.
- **Ringue de verdade:** lona creme de y 262 (x 151..489) a y 342 (x 104..536), emblema LIGA DO VALE no meio, saia preta com
  **AUTOPEÇAS VALE FORTE** até y 357; postes com protetores (**azul à esquerda = você, vermelho à direita = ele**, brancos na
  frente); 3 cordas (azul embaixo, branca, vermelha em cima) **atrás e dos lados**. **Não há corda na frente**: cortaria os
  lutadores na cintura; a câmera é a da TV, de dentro. As cordas laterais ficam fora de x 151..489 e nunca tocam os pivôs.
- Luz de noite: o ringue claro, o resto cai em faixas com dither (−2 passos nas bordas) e 4 fachos em dither dos refletores.
- **Público:** o do Ginásio Alvorada (as mesmas figuras), com **troca de paleta** para a torcida do Vale e a mesma luz de noite,
  **recortado** onde o ringue, a mesa e a câmera ficam na frente (a camada do público é desenhada por cima do fundo; o recorte
  é que põe as cordas e a lona na frente dele). Frente: as silhuetas da liga com boné/bandeira verdes e um **câmera de mão** da TV.
- **Camadas novas, opcionais:** `arena_regional_ropes_side` (cordas laterais + postes da frente, z 40, por cima dos lutadores;
  são os mesmos pixels do fundo, então não muda nada parado) e `arena_regional_spot` (facho em dither y2 que segue quem entra).
  As duas existem para a **entrada no ringue** (animação principal do dono): o lutador vem da torcida à esquerda, passa entre
  as cordas em x ~118 (a camada das cordas fica na frente dele: parece que ele entra entre elas), acena e anda até 296. Tempos e
  caminho em `fight_layout.arenas.arena_regional.entrance`; a pose de "passar entre as cordas" é do Artista de Personagens.
- Letreiros das 3 artes e das 6 passivas conferidos em 2x em (320,118): leem no fundo escuro (`mockups/fase8a1_letreiros_arena.png`).

**Cinturão do Vale** (`belt_regional_*`): o amador é pano vermelho com caixinha de ouro; o regional é **couro preto com costura,
placa de ouro grande com esmalte azul (dois morros e o vale, sol no meio) e VALE**, 4 plaquinhas laterais. Grande 120x52 (tela de
fim, 3 quadros de brilho), **erguido** 40x22 em escala de corpo (refeito em 2026-11-22: o de
80x48 cobria cabeça e tronco). Pivô (20,15) = meio de `hand_front`/`hand_back` do quadro de `fight_player_victory`; pegadas
(15,15) e (25,15), 10 px como as luvas, com vão transparente para as luvas aparecerem na frente da tira; placa 13x14 em cima
das luvas, tira reta caindo só nas pontas, rosto livre (`mockups/fase8a1_cinturao_erguido.png`). Ícones 16 e 9.

**Cartaz da liga na academia** (`wall_poster_league_regional_gym`, 38x54, em `layout.gym_league_poster_spot` = (412,54), em cima
da porta, a partir de `regional_league_opened`): faixa vermelha LIGA, DO VALE (fonte 3x5), **foto do James em 2 tons** (impressão
barata, azul, tirada do `portrait_opp_james`), JAMES, fita nos cantos. Zoom 112x148 com as 3 linhas do Roteirista e CLUBE FERROVIÁRIO. A foto sai do retrato
`portrait_opp_james` quando ele existir (o gerador procura o arquivo; até lá, busto provisório): **rodar o gerador de novo depois
do Artista de Personagens**.

**Passivas dos adversários** (`adv_*`, 16 e 9): **escudinho de borda vermelha** = é dele (as suas passivas não têm borda), e o
desenho é material de defesa, nunca golpe: Queixo de ferro = **bigorna** com faísca; Base larga = **base aberta com os pés em
blocos de cimento**; Ensaboado = **sabão com bolhas**; Blindado = **chapa de aço com rebites** e, depois de 5,33 s, `adv_blindado_open`
(as duas metades afastadas, cinza).

**Sinais (§3.2):** letreiros pequenos (família do PERNA CHEIA!, fonte 2x) **branco/aço com sombra vermelha r1** = a passiva dele
segurou: AGUENTOU!, NÃO CAIU, ESCAPOU!, GUARDA FECHADA (opcional). **A GUARDA ABRIU** é boa notícia sua: ouro com sombra aço.
Ouro continua sendo só conquista sua. `fx_guard_clink` (estalo de aço, 3 quadros) no lugar do impacto quando `guard: true`; o
número de dano cinza e 1x é regra do UI/UX. As poses de assinatura (Bigorna sacode a cabeça etc.) são do Artista.

**James no balão e no HUD (pedido do Diretor de Cutscenes):** plaquinha `ui_balloon_tag_steel` (aço escuro st0, texto branco;
o azul é do discípulo), ligada em `speech_bubble.tag_by_speaker.rival`. Moldura do retrato = a **dourada que já existe**
(`ui_portrait_frame_gold`, dono do cinturão, como o Seu Muralha): sem moldura nova.

**Mockups:** `fase8a1_arena_regional.png` (em pé com AGUENTOU! / deitados com FINALIZOU!), `fase8a1_arena_regional_vazia.png`,
`fase8a1_letreiros_arena.png`, `fase8a1_entrada_cinturao.png` (entrada em 4 tempos, cinturão erguido, camadas),
`fase8a1_pecas_x4.png`, `fase8a1_cartaz_academia.png`. Nos mockups entram as folhas do Artista (Bigorna, Estaca e James, com o gesto de desprezo no canto dele).

**Placeholder / precisa de pixel artist:** tijolo, arquibancada e treliça são repetição; a torcida é a mesma da liga recolorida
(à mão: casacos, cachecóis, gente em pé na galeria); as cordas não balançam (um artista faria a corda reagir quando alguém bate
nela e na entrada); a lona pediria manchas e marcas de uso; o cinturão erguido em 80 px é o mais fraco (as tiras caindo pedem
curva desenhada à mão); a foto do cartaz é só o retrato em 2 tons. Tamanhos fixos para trocar só os arquivos.

## 35. Fase 8a2 (Centro de Treinamento Raízes: sala larga, aparelhos do centro, recorte, cartaz vencido, patrocínio)
Gerador: `tools/art/make_arte_fase8a2.gd` (headless; `-- --no-assets` só mockups). Manifest: `python tools/art/manifest_8a2.py`
(depois do `manifest_8a2_personagens.py` do Artista; os dois são idempotentes). Lista, pontos e pedidos ao código:
`docs/arte/fase8a2-manifest.md`. Mockups: `mockups/fase8a2_*.png`.

**A sala (`center_bg`, padrão da 6d2):** mesma caixa de diorama larga (parede x 70..569, chão até y 329, pilares x 164..174 e
468..478, ponto de fuga 320,-28, viga y 26..33 com os ganchos em 258 e 336). O que diz "centro" e não "academia":
- **Pé-direito alto**: treliça escura acima da viga, 2 janelões no fundo (alas) e 2 nas paredes laterais, luz do dia + 4 painéis de LED
  (`center_led`, falha opcional). Luz quase toda no passo 0; só os cantos e a frente caem 1 passo. É a sala mais clara do jogo.
- **Cores da escola**: concreto pintado de branco em blocos em cima, **barrado azul da escola** (b1) embaixo, pilares de aço, o R
  pintado na parede. Garagem = cinza e lâmpada; academia = creme e verde; centro = branco, azul e aço.
- **Piso de borracha** em placas (o nó da árvore tem esse nome), tatame **vermelho** na frente à esquerda (onde a arte deita) e uma fita
  de área de treino em volta do alvo.
- **História na parede:** vitrine com os 2 cinturões (amador e do Vale) na ala direita; **canto da memória** na ala esquerda com o
  recorte emoldurado e a **foto da garagem, torta de propósito**; o mural (176,128), o recorte do vulto (340,60) e o Metrônomo
  (240,118) nos mesmos pontos da academia. Espelho inteiro (o da academia era trincado), porta de vidro dupla.
- Os pontos de Osmar, mentores, equipe antiga, aparelhos e caixas são **os mesmos da academia**. Novos: os 4 alunos (fileira do
  fundo à direita, canto direito da frente e canto esquerdo), o canto da memória e o envelope. Conferido pixel a pixel: 0 problemas.

**Aparelhos `_center` (D4):** as 37 folhas dos 6 aparelhos, com a forma, os quadros e os pivôs da academia e **material novo**:
saco de couro azul-marinho com faixas brancas; corda de cabo azul; esteira grafite com painel azul; pera caramelo em madeira clara;
boneco de couro vermelho; saco comprido de lona crua com alças de couro. O nível visual continua 0/1 (a 5ª melhoria não troca sprite).

**Recorte do Vale (D10):** a mesma peça nos dois lugares: papel creme, manchete RAÍZES (3x5, legível em 1x quando cabe), foto
granulada do discípulo erguendo o cinturão, colunas, picote. Emoldurado no centro (36x36, moldura preta com filete de ouro);
solto e preso com fita no **cartaz vencido** da academia (42x58: o cartaz da 8a1 + **adesivo redondo do R** em cima da cara do
James + recorte passando da borda; quadro 1 com a marca no canto).

**Patrocínio Autopeças Vale Forte:** marca original = **engrenagem amarela com os dois morros do Vale**, sobre preto (o amarelo da
saia do ringue da 8a1). Selo 20, larga com VALE FORTE, 9x9, e o **remendo do calção** (5x3, etiqueta amarela sem contorno, no
`hip` de cada quadro + (-2,+3)). O **envelope PROPOSTA** fica no chão no mesmo ponto nos 3 locais (250,302), brilhando de vez em quando.

**Região CENTRO do mapa:** ícone da fachada com o R, plaquinha azul, ladrilho de piso de borracha, anel **aço** (`steel`) nos nós
comprados. Nós usam os ícones que já existem (data). Atenção ao conflito da chave `center` no `janela_mapa.gd` (fase8a2-manifest.md).

**Placeholder / precisa de pixel artist:** o fundo é montagem por código (blocos, reflexos em diagonal, vitrine plana); os aparelhos
são troca de material, não forma nova; a silhueta do recorte tem 7 px; o remendo do calção só lê como marca no contexto. Tamanhos e
pivôs fixos: trocar a arte é trocar o arquivo.

## 36. Ronda Noturna do Gato Preto (a rua da borracharia, o capuz no prego, a lenda no jornal e no bairro)
Gerador: `tools/art/make_arte_ronda.gd` (headless, de uma pasta com `project.godot` vazio, `-- --root <worktree>`; `--no-assets` só
mockups; `--caps <pasta>` cola o capuz nas capturas do `ui_audit`). Manifest: `python tools/art/manifest_ronda.py` (idempotente;
não mexe nas chaves do Artista). Lista, pontos e pedidos ao código: `docs/arte/ronda-manifest.md`. Mockups: `mockups/ronda_*.png`.
Textos das manchetes e do recorte = provisórios [ROT] (`TXT_*` no topo do gerador).

### 36.1 A cor da Ronda: NOITE
- **Azul-marinho `b0/b1` + o creme da lua.** É a cor da LENDA (ícone, bolinhas do nível, anel `night` do mapa, plaquinha da região).
- **Ouro só no PERTO e no SUSTO!** (é conquista sua, como no resto do jogo). **Nunca** o roxo do Legado (a lenda não é Legado) nem o
  azul vivo `b2/b3` do Jiu-jitsu em peça grande.
- Letreiro SUSTO! = receita do K.O.! com a **sombra de fonte `b0`**. ESCAPOU = cinza (`g3/g2`, sombra `d2`), menor e sem tremida.

### 36.2 O traje (regra de cor para o Artista e para todo objeto do vulto)
Capuz e capa: `d1` base, `d2` luz, `ink` contorno; luz da lua por trás = 1 passo (`g0`) só na borda de cima. Orelhas **largas e
baixas**, com 2 pontos de costura `g1`. **Faixa vermelha `r2`** (luz `r3`, sombra `r1`), a mesma da amostra do Artista (`mockups/ronda_amostra_vulto.png`), nó atrás e as duas pontas voando para trás. No gerador é uma constante só (`BAND`): se o dono pedir a faixa azul da escola, troca em tudo de uma vez. **Aprovado (2026-11-25): o dono aprovou a amostra do vulto com a faixa VERMELHA**; `BAND` fica vermelha (`r1/r2/r3`). Elenco completo (vulto em camadas + 3 ladrões): `tools/art/make_sprites_ronda.gd`, `docs/arte/ronda-personagens-manifest.md`, `mockups/ronda_elenco.png`.
Pele só na boca/queixo. Capa de lona com remendo `g0`, **caindo reta** (nunca aberta em asa). Sem símbolo no peito, sem cinto.
O dublê do gerador (52x50, agachado ~46 px) só mede o cenário: a folha é do Artista de Personagens (skill `padrao-personagem`).

### 36.3 A rua (`ronda_bg`, 640x360)
- **Vista de lado, na altura da rua**, como a Panfletagem: o vulto anda **em cima** do que separa as casas da calçada, o ladrão
  trabalha **na calçada**, logo depois do fim do trecho. Um cenário, **3 trechos na mesma altura (pés y 196)**, da esquerda para a
  direita: **capa do muro do terreno baldio** (tire, x 26→146), **marquise de concreto da borracharia** (bike, 256→346), **capa do muro
  verde da casa 15** (gate, 494→546). A ronda anda pela tela inteira e acaba perto da lua.
- **Borracharia = a da arena da fase 3** (chapa ondulada, letreiro laranja BORRACHARIA, 24H aceso, porta de enrolar 07): o jogador
  reconhece o bairro. Do lado: o sobrado ocre (janela de cima acesa, bicicleta encostada embaixo da janela, presa com corrente na
  grade) e a casa 15 (muro verde, pilar com luminária, portão de chapa com grade, caixa d'água azul no telhado).
- **Regra de luz (é a regra do jogo virando imagem):** cada ladrão fica numa **poça de luz** (poste, arandela, luminária do pilar);
  o vulto anda **na sombra do alto**. Atrás do caminho do vulto, **só meio-tom** (parede da casa de fundos `st1`, chapa `st1/st2`,
  fachada `g3`), nunca `ink/d1/b0` chapado: o vulto preto com contorno `ink` precisa ler. Conferido no gerador (% escuro atrás de
  cada trecho e chão aceso embaixo de cada ladrão).
- Céu só em y 0..35 (HUD); asfalto em y 336..359 (SAIR e a instrução). O poste fica entre o trecho 1 e o 2 e **nunca corta o vulto**.
- **Lua cheia** em (552,70) r 24, com halo em dither; **pose no telhado**: pés em (552,114) na cumeeira da casa 15, a silhueta cobre
  a lua (o quadro do top 3 do dono).

### 36.4 As camadas da lenda (640x360 em 0,0, cumulativas, `street_layers_by_level`)
| Nível | Camada | O quê | Onde |
|---|---|---|---|
| 2 | `graffiti` | o gato do bairro a estêncil creme (capuz com orelhas largas, faixa nos olhos com as pontas, sorrisinho) + GP vermelho | muro do terreno, embaixo da barra |
| 3 | `banner` | faixa de pano VALEU, GATO PRETO pintada à mão, com cordinhas e uma dobra | chapa da borracharia, entre o letreiro e a marquise (atrás do trecho 2: pano claro, o vulto lê por cima) |
| 4 | `kid_ears` | criança na janela de cima do sobrado com orelhinhas de papelão e a faixa vermelha, acenando; desenho do gato colado no vidro | janela acesa do sobrado |
| 5 | `whole_street` | bandeirinhas com o capuz, gatos de giz na calçada, adesivo no poste, gato na caixa d'água, orelhas na janela da casa 15, GP no portão | a rua toda, fora dos pés dos ladrões e da lua |
O nível 1 não muda a rua (só o jornal dá o nome). Corte (escopo §9): as camadas viram só recortes.

### 36.5 O capuz no prego (sala)
- `hood_on_nail` (garagem) / `hood_on_nail_gym` (academia e centro), 16x22, **pivô (8,1) na cabeça do prego**, ponto **(352,95) nos 3
  locais**: parede lisa entre a corrente do saco (x 335) e a porta da garagem / o relógio de rounds, logo **ao lado do recorte do
  vulto** (garagem: o recorte à esquerda da corrente; academia/centro: o recorte logo acima). O capuz e o jornal contam a mesma
  história na mesma parede.
- Capuz preto pendurado pela nuca (orelhas costuradas nas quinas, abertura do rosto escura) e a **faixa vermelha enrolada no prego** com
  as pontas caindo: a faixa vermelha é a única cor do objeto, para ele ser achado sem piscar. Parado: sem brilho, sem som, sem anim. Quadro 1 = hover
  (contorno creme, como os outros objetos de parede).
- Conferido: fora da zona do alvo (y < 150), dos cards da esquerda e do painel fixado; 0 sobreposição com o manifest e com a
  ocupação conhecida das 3 salas; colado nas capturas do `ui_audit` com a sala cheia (ninguém da equipe chega a y 117).

### 36.6 O jornal que exagera (recortes por nível)
- Pequeno 23x28 no **mesmo ponto** do recorte da 7a2 (o nível 0 não muda). Em 1x a escalada se lê pela **foto** (11x8: o vulto e a
  lua; o gato pichado e um ladrão fugindo; a faixa e o povo; a janela com a criança de orelha; o ônibus erguido) e pela **tinta**:
  manchete preta nos níveis 1–3 (sublinhada no 3), **vermelha no 4**, **tarja vermelha de EXTRA no 5**. Manchete 3x5 de 2 linhas
  (GATO/PRETO, GATO/VOLTA, VALEU/GATO, GATO/MANIA, UMA/MÃO!) [ROT].
- Zoom 128x96 (hover e prêmio, "o jornal do dia seguinte"): CORREIO DA ESQUINA (no 5, faixa vermelha EDIÇÃO EXTRA), chamada 1x +
  título 2x, foto 56x42 em tons de cinza com a piada do nível, colunas. É a 1ª peça a cortar.

### 36.7 HUD e mapa
- HUD (sugestão; a final é do UI/UX): LENDA (ícone 16 + 5 bolinhas) em cima à esquerda, OCORRÊNCIA n DE 3 com os sustos no meio,
  tempo à direita; a **barra de distância fica no muro**, embaixo da capa (y 206), só do trecho atual, com a zona do SUSTO de 0,8 ao
  fim (pisca em ouro com o PERTO). O aviso do ladrão fica **em cima da cabeça dele** (? cinza → ? branco → ! no balão vermelho:
  forma e cor mudam juntas).
- Região GATO PRETO: ícone (telhado de telha, lua e o vulto na cumeeira), plaquinha com a faixa da noite, ladrilho de **telha
  capa-canal azul-marinho**, anel `night`, **nó lacrado** (o "faltando" com um lacre cinza do capuz). Os 3 nós usam o desenho de
  hoje do mesmo efeito (`skill_crew_regulars`, `skill_prep_day` com **+2**, `skill_body_crew`) com o **carimbo do gato** no canto.

### 36.8 Placeholder / precisa de pixel artist
A rua é montagem por código (blocos, chapa em listras, luz em faixas com dither, poças de luz redondas); à mão: chapa amassada,
reboco com textura, folhagem, lua com relevo, fios, gente nas janelas. As camadas são desenhos simples (a criança tem 30 px). O capuz
tem 16x22 (à mão: volume do pano, costura legível). Os recortes contam o nível pela foto de 11x8. Tamanhos, pivôs e pontos fixos.

## 37. Identidade visual (proposta, aguarda o dono)
Três direções para o HUD, a barra, as janelas e o menu principal: A vidro pixelado, B lona e placa de academia, C cartaz de luta.
Paletas, leitura, custo e recomendação (B, com o C nas telas de luta) estão em `docs/arte/identidade-direcoes.md`. Mockups em
`mockups/identidade/`, feitos pelo gerador `tools/art/make_mockup_identidade.gd`. Até o dono escolher, a UI de hoje continua valendo.
