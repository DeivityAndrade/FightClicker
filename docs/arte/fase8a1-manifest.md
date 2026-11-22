# Fase 8a1 — arte do Diretor de Arte (manifest)

Gerador: `tools/art/make_arte_fase8a1.gd` → `tools/art/fase8a1_sprites.json` → `python tools/art/manifest_8a1.py`.
Direção: `docs/arte/direcao-visual.md` §34. Tudo placeholder por código, paleta de 45 cores, 1x na base 640x360, nearest.
Quadros lado a lado da esquerda para a direita; pivô relativo ao quadro.

## Arena regional (`fight_layout.arenas.arena_regional`; `league_regional.json → fight_arena: "arena_regional"`)
| Sprite | Arquivo | Quadro | Q | Pivô | pos / z | Uso |
|---|---|---|---|---|---|---|
| `arena_regional_bg` | fight/arena_regional_bg.png | 640x360 | 1 | 0,0 | 0,0 / −100 | fundo com o ringue (lona y 262..342, saia até 357) |
| `arena_regional_crowd_back` | fight/arena_regional_crowd_back.png | 640x100 | 2 | 0,0 | 0,180 / −60 | público de trás, recortado pelo ringue; anim idle [0], cheer [1,0,1,0] |
| `arena_regional_crowd_front` | fight/arena_regional_crowd_front.png | 640x48 | 2 | 0,0 | 0,312 / 50 | cantos de baixo + câmera de mão da TV |
| `arena_regional_ropes_side` | fight/arena_regional_ropes_side.png | 640x161 | 1 | 0,0 | 0,196 / 40 | opcional: cordas laterais e postes da frente por cima dos lutadores (0 px em x 200..440) |
| `arena_regional_spot` | fight/arena_regional_spot.png | 96x262 | 2 | 48,258 | pés de quem entra / −55 | opcional: facho que segue a entrada no ringue (8 fps) |
| `fx_guard_clink` | fight/fx_guard_clink.png | 15x15 | 3 | 7,7 | hit_point / como os fx | golpe na guarda fechada do James (`guard: true`), 18 fps sem loop |

- Sem `arena_regional_lamp`: o `tela_luta.gd` já deixa a lâmpada invisível quando o prefixo não tem `_lamp`.
- Entrada no ringue (sugestão de tempos e caminho): `fight_layout.arenas.arena_regional.entrance`; mockup `fase8a1_entrada_cinturao.png`.

## Cinturão do Vale (`by_data_id.belt_regional`)
| Sprite | Arquivo | Quadro | Q | Pivô | Uso |
|---|---|---|---|---|---|
| `belt_regional_big` | ui/belt_regional_big.png | 120x52 | 3 | 60,26 | tela de fim / conquista (6 fps, loop de brilho) |
| `belt_regional_raised` | fight/belt_regional_raised.png | 40x22 | 3 | 20,15 | cinturão erguido em escala de corpo; `grips` (15,15) e (25,15); pivô = meio de hand_front/hand_back do quadro de vitória |
| `icon_belt_regional` | ui/icon_belt_regional.png | 16x16 | 1 | 0,0 | resumo, carreira, `summary.belts` |
| `icon_belt_regional_9` | ui/icon_belt_regional_9.png | 9x9 | 1 | 0,0 | prévia "SE VENCER", mural, HUD |

## Cartaz da liga (`layout.gym_league_poster_spot` = [412,54] + `_info`)
| Sprite | Arquivo | Quadro | Uso |
|---|---|---|---|
| `wall_poster_league_regional_gym` | gym/wall_poster_league_regional_gym.png | 38x54 | parede da academia, em cima da porta, a partir de `regional_league_opened`; hover = `objects.regional_poster` |
| `ui_poster_league_regional_zoom` | ui/ui_poster_league_regional_zoom.png | 112x148 | opcional: cartaz grande na dica/janela |

A foto do James sai de `assets/sprites/opponents/portrait_opp_james.png` quando existir: **rodar o gerador de novo** depois do
Artista de Personagens (já feito em 2026-11-22: a foto é o retrato dele).

## Passivas dos adversários (`by_data_id.opp_passives`; `previa().opp_passive_icon` = id)
| id | 16x16 | 9x9 | Sinal (letreiro pequeno, pivô no meio, 2x sobre a cabeça dele) |
|---|---|---|---|
| `adv_iron_chin` | bigorna | `adv_iron_chin_9` | `ui_banner_opp_iron_chin` AGUENTOU! |
| `adv_wide_base` | base aberta, pés no cimento | `adv_wide_base_9` | `ui_banner_opp_wide_base` NÃO CAIU |
| `adv_slippery` | sabão com bolhas | `adv_slippery_9` | `ui_banner_opp_slippery` ESCAPOU! |
| `adv_blindado` | chapa de aço | `adv_blindado_9` | `ui_banner_guard_closed` GUARDA FECHADA (opcional) |
| `adv_blindado_open` | chapa aberta (depois de 5,33 s) | `adv_blindado_open_9` | `ui_banner_guard_open` A GUARDA ABRIU (ouro) |

Ícone 9x9 ao lado da vida dele, sugestão (346,17) (`opp_passives.hud`). Posição final: UI/UX.

## James no balão e no retrato (pedido do Diretor de Cutscenes)
| Peça | Onde |
|---|---|
| `ui_balloon_tag_steel` (ui/ui_balloon_tag_steel.png, 8x10, 9-slice 2, texto branco) | `speech_bubble.tag_by_speaker.rival = "steel"`, `tag_by_color.steel`, `tag_text_color.steel = "white"` |
| Moldura do retrato | `by_data_id.opp_james_portrait_frame.frame = "ui_portrait_frame_gold"` (a dourada que já existe; sem peça nova) |

## Mockups (`docs/arte/mockups/`)
`fase8a1_arena_regional.png`, `fase8a1_arena_regional_vazia.png`, `fase8a1_letreiros_arena.png`, `fase8a1_entrada_cinturao.png`,
`fase8a1_pecas_x4.png`, `fase8a1_cartaz_academia.png`, `fase8a1_cinturao_erguido.png`.

## Conferências do gerador (última rodada)
- faixa do HUD (y 0..45) fora do ink: **0 px**
- `arena_regional_ropes_side` dentro de x 200..440: **0 px**
- cartaz em (412,54): só parede embaixo (**0 px** de outra coisa)

## Ainda falta (outros papéis)
- Folhas do James e dos 3 regionais, retrato `portrait_opp_james` e a pose "passar entre as cordas": Artista de Personagens
  (registro no script dele; o produtor avisa para rodar). Depois: rodar `make_arte_fase8a1.gd` de novo (foto do cartaz) e os dois
  manifests.
- Ligar a arena, as camadas opcionais, o cartaz, os ícones, os sinais e o cinturão nas telas: UI/UX.
