# Ronda Noturna do Gato Preto: arte e entradas do manifest

Diretor de Arte, 2026-11-23. Gerador: `tools/art/make_arte_ronda.gd` (headless, de uma pasta com `project.godot` vazio:
`godot --headless --max-fps 30 --path <vazia> --script <worktree>/tools/art/make_arte_ronda.gd -- --root <worktree>`;
`--no-assets` só refaz os mockups; `--caps <pasta>` cola o capuz nas capturas do `ui_audit` com a sala cheia).
Registro: `python tools/art/manifest_ronda.py` (lê `tools/art/ronda_sprites.json`; idempotente; tab/CRLF; só acrescenta chaves
desta fase, não apaga as do Artista de Personagens, que registra o vulto e os ladrões com o script dele, em qualquer ordem).
Direção: `direcao-visual.md` §36. Tudo placeholder por código, original. Textos das manchetes = provisórios **[ROT]** (constantes
`TXT_*` no topo do gerador; o Roteirista confirma e é só rodar de novo).

## Mockups (`docs/arte/mockups/`)
| Arquivo | O quê |
|---|---|
| `ronda_tela_aviso_x2.png` | **o mockup da tela** (feito antes de tudo): trecho 1, vulto andando, ladrão no AVISO (?), barra, HUD, instrução, SAIR |
| `ronda_tela_perto_x2.png` | trecho 2 (marquise), vulto PERTO com o SUSTO! piscando, lenda nível 3 (pichação + faixa) |
| `ronda_tela_susto_x2.png` | trecho 3, SUSTO! (vulto caído atrás do ladrão, pé de cabra voando, poeira), lenda nível 5 |
| `ronda_fundo(_x2).png` | só a rua |
| `ronda_camadas_niveis.png`, `ronda_camadas_zoom_x2.png` | a rua nos 6 níveis da lenda; nível 5 x nível 0 em 2x |
| `ronda_pontos_x2.png` | conferência: caminho do vulto, zona 0,8, caixa do vulto, ladrão, queda do SUSTO, prop, barra, faixas de HUD, pose do telhado |
| `ronda_letreiros_x2.png` | SUSTO! grande, SUSTO! pequeno (2 quadros), ESCAPOU, os 3 avisos do ladrão, na rua |
| `ronda_capuz_locais_x3.png`, `ronda_capuz_garagem|academia|centro_x2.png` | o capuz no prego nos 3 locais (zoom 3x e a sala inteira; com `--caps`, nas capturas da sala cheia) |
| `ronda_recortes_x4.png` | os recortes do nível 0 (7a2) ao 5, garagem e academia, 1x e 4x, e os zooms |
| `ronda_pecas_x4.png` | capuz, props, ícones da LENDA, aviso, barra, peças do mapa e os 3 nós |
| `ronda_mapa_x2.png` | a região GATO PRETO montada (ladrilho, anel noite, nó lacrado, plaquinha) |

Nos mockups o vulto e os ladrões são **dublês** (vulto agachado desenhado no gerador; ladrão = pedestre da Panfletagem com o
moletom escurecido). As folhas de verdade são do Artista de Personagens.

## Sprites novos
| id | Tamanho | Onde / regra |
|---|---|---|
| `ronda_bg` | 640x360 | `minigame_layout.ronda.bg`, (0,0), z -100 |
| `ronda_layer_graffiti` / `_banner` / `_kid_ears` / `_whole_street` | 640x360 cada | (0,0), z -90, cumulativas na ordem de `street_layers_by_level` (`minigame_layout.ronda.layers`) |
| `ronda_prop_tire` | 20x20, pivô (10,19) | estepe no chão em `occurrences.tire.prop` (212,314); voa no SUSTO |
| `ronda_prop_pliers` / `ronda_prop_crowbar` | 12x8 / 18x7, pivô no meio | o que voa no SUSTO da bicicleta / do portão (na mão do ladrão enquanto trabalha: é da folha do Artista) |
| `hood_on_nail` (garagem), `hood_on_nail_gym` (academia), `hood_on_nail_center` (atalho p/ o da academia) | 16x22, 2 quadros, pivô (8,1) | `layout.hood_spot` / `gym_hood_spot` / `center_hood_spot` = **(352,95)** nos 3; quadro 0 parado, 1 hover |
| `wall_clipping_black_cat_l1..l5` | 23x28 | garagem, `clipping_spot` (304,100) |
| `wall_clipping_black_cat_gym_l1..l5` (+ atalhos `_center_l1..l5`) | 23x28 | academia (340,60) e centro (340,60) |
| `ui_clipping_black_cat_zoom_l1..l5` | 128x96 | zoom do hover / prêmio (o do nível 0 é o da 7a2, 100x84) |
| `icon_legend`, `icon_legend_16` | 9, 16 | LENDA (lua cheia com o capuz na frente) |
| `ui_legend_pip` | 7x7, 3 quadros, pivô no meio | nível da lenda: apagada / acesa / acendendo; 5 com passo 9 |
| `ui_ronda_track` (9-slice 1,1,1,1), `ui_ronda_fill` (4x4, 2 q.), `ui_ronda_zone` (4x4, 2 q.) | | barra de distância embaixo da capa do muro (y 206, 6 px) de `start-4` a `end+4`; zona de 0,8 ao fim |
| `ui_thief_warn` | 13x14, 3 quadros, pivô (6,13) | AVISO começando (? cinza) / AVISO (? branco) / OLHANDO (! no balão vermelho) |
| `ui_banner_scare` | fonte 3x, pivô no meio | SUSTO! (2x no jogo em 320,118, tremida do K.O.) |
| `ui_banner_scare_near` | fonte 2x, 2 quadros | SUSTO! piscando em cima do vulto quando PERTO (y = walk_y − 50) |
| `ui_banner_escaped` | fonte 2x | ESCAPOU (cinza, sem tremida) |
| `icon_ronda_16`, `icon_occurrence` | 16, 9 | prêmio (o capuz) e OCORRÊNCIAS (o estepe solto; também os 3 sustos no HUD) |
| `icon_region_black_cat(_9)`, `ui_map_region_label_black_cat`, `map_tile_black_cat_region` | 16/9, 16x13, 32x32 | região GATO PRETO (`skill_map.region_icons/region_label/region_tiles.black_cat`) |
| `map_node_s|b_owned_night` | 24 / 38 | anel "noite" (tom `night`) dos nós comprados |
| `map_node_s|b_sealed` | 24 / 38 | nó lacrado (D7): sem ícone, sem preço |
| `skill_black_cat_roof` / `_watch` / `_thanks` | 16x16 | os 3 nós (`icon_by_node` e o campo `icon` do `ronda.json`): o desenho de hoje do mesmo efeito + o carimbo do gato |

## Tela da Ronda (`minigame_layout.ronda`, 1x)
| Coisa | Valor |
|---|---|
| HUD de cima | y 0..35 (só céu; conferido: 0 px de outra coisa) |
| Faixa de baixo | y 336..359 (asfalto): SAIR (8,334,48,18) e a instrução centrada em (340,343) |
| Pés do vulto | y **196** nos 3 trechos (capa do muro / marquise / capa do muro verde); x = lerp(start, end, distância) |
| Trechos (start → end) | tire 26 → 146 · bike 256 → 346 · gate 494 → 546 |
| Ladrão (pés, de costas = virado para a direita) | tire (192,314) · bike (392,314) · gate (592,314) |
| Queda do SUSTO (pés do vulto) | tire (166,314) · bike (366,314) · gate (566,314) |
| Barra de distância | y 206..211, x de start−4 a end+4, zona do SUSTO a partir de 0,8 |
| Aviso do ladrão | x do ladrão + 2, y 244 (pivô de baixo) |
| Pose no telhado | pés (552,114) na cumeeira da casa 15, contra a lua (552,70) r 24 |

## Para o Programador / UI/UX (só o que a arte pede)
1. **Sala:** o capuz é objeto de parede (camada `wall`, z −44, logo acima do recorte); `click_rect` em `layout.*hood_spot_info`.
   Hover = quadro 1 + o texto `hood_hover`. Sem clique: continua o quadro 0, sem hover.
2. **Recorte:** trocar o sprite pelo nível (`clipping_spot_info.sprite_by_level[n]`, idem `gym_` e `center_clipping_black_cat_spot_info`);
   o zoom pelo `zoom_by_level[n]`.
3. **Mapa:** região `black_cat` com o tom `night` (`tone_by_branch_or_region`); `janela_mapa.gd` precisa de `black_cat` em
   `ORDEM_REGIOES` e do ladrilho `map_tile_black_cat_region`; estado `sealed` desenha `map_node_*_sealed` sem ícone e sem preço.
   **Conserto da 8a2:** `skill_map.node.big.owned_by_tone` não tinha o `steel` (o script da 8a2 procurava a chave `milestone`): o
   marco comprado do CENTRO caía sem anel aço. Este script acrescenta. Conferir no mapa.
4. **Ladrão e vulto:** desenhar o vulto por cima do muro e do ladrão (o vulto está atrás na profundidade, mas no SUSTO ele cai na
   frente: a partir do pulo, desenhar depois do ladrão). As 3 camadas da lenda ficam atrás de todo mundo.

## Placeholder / precisa de pixel artist
- A rua é montagem por código (blocos, chapa em listras, luz em faixas com dither). À mão: chapa com amassados, reboco com
  textura, a árvore com folhagem de verdade, a lua com relevo, fios de poste e gato no telhado de verdade.
- As camadas da lenda são desenhos simples (estêncil, faixa, criança em 30 px, bandeirinhas): um artista faria a pichação com
  traço de spray, a criança com rosto e a rua do nível 5 com mais gente desenhando.
- O capuz no prego tem 16x22; à mão ganharia o volume do pano e a costura das orelhas mais legível.
- Os recortes pequenos dependem da foto de 11x8 para contar o nível; os zooms são o lugar da piada (e a 1ª peça a cortar).
- Tamanhos, pivôs e pontos fixos: trocar a arte é trocar o arquivo.
